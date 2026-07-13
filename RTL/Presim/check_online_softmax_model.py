FEATURE_DIM = 4
WINDOW_SIZE = 4
DILATION = 2
GLOBAL_INDEX = 0
EXP_ONE = 65535
EXP_LUT = (65535, 24109, 8869, 3263, 1200, 441, 162, 60, 22, 8, 3, 1)

MODES = ("sliding", "dilated", "sliding_global", "butterfly")


def q_value(token: int, feature: int) -> int:
    return ((token + 1) * (feature + 2)) % 251


def k_value(token: int, feature: int) -> int:
    return ((token + 3) * (feature + 1)) % 251


def v_value(token: int, feature: int) -> int:
    return (token + (feature * 7) + 5) % 251


def qk_score(q_idx: int, k_idx: int) -> int:
    return sum(
        q_value(q_idx, feature) * k_value(k_idx, feature)
        for feature in range(FEATURE_DIM)
    )


def exp_weight(delta: int) -> int:
    scaled_delta = delta >> 1
    return EXP_LUT[scaled_delta] if scaled_delta < len(EXP_LUT) else 0


def rtl_divide(numerator: int, denominator: int, width: int = 16) -> int:
    """Mirror the MSB-first fixed-width divider in sparse_softmax_sv.v."""
    remainder = numerator
    quotient = 0
    for bit in reversed(range(width)):
        shifted_divisor = denominator << bit
        if remainder >= shifted_divisor:
            remainder -= shifted_divisor
            quotient |= 1 << bit
    return quotient


def pair_stream(seq_len: int, mode: str):
    if mode in ("sliding", "dilated", "sliding_global"):
        step = DILATION if mode == "dilated" else 1
        for q_idx in range(seq_len):
            block_start = (q_idx // WINDOW_SIZE) * WINDOW_SIZE
            for offset in range(0, WINDOW_SIZE, step):
                k_idx = block_start + offset
                if k_idx < seq_len:
                    yield q_idx, k_idx

        if mode == "sliding_global":
            global_block = (GLOBAL_INDEX // WINDOW_SIZE) * WINDOW_SIZE
            for q_idx in range(seq_len):
                if (q_idx // WINDOW_SIZE) * WINDOW_SIZE != global_block:
                    yield q_idx, GLOBAL_INDEX
            for k_idx in range(seq_len):
                if (k_idx // WINDOW_SIZE) * WINDOW_SIZE != global_block:
                    yield GLOBAL_INDEX, k_idx
    else:
        stride = 1
        while stride < seq_len:
            for q_idx in range(seq_len):
                k_idx = q_idx ^ stride
                if k_idx < seq_len:
                    yield q_idx, k_idx
            stride <<= 1


def online_context(seq_len: int, mode: str):
    initialized = [False] * seq_len
    row_max = [0] * seq_len
    denominator = [0] * seq_len
    numerator = [[0] * FEATURE_DIM for _ in range(seq_len)]

    for q_idx, k_idx in pair_stream(seq_len, mode):
        score = qk_score(q_idx, k_idx)
        if not initialized[q_idx]:
            initialized[q_idx] = True
            row_max[q_idx] = score
            denominator[q_idx] = EXP_ONE
            for feature in range(FEATURE_DIM):
                numerator[q_idx][feature] = EXP_ONE * v_value(k_idx, feature)
        elif score > row_max[q_idx]:
            scale = exp_weight(score - row_max[q_idx])
            row_max[q_idx] = score
            denominator[q_idx] = ((denominator[q_idx] * scale) >> 16) + EXP_ONE
            for feature in range(FEATURE_DIM):
                numerator[q_idx][feature] = (
                    (numerator[q_idx][feature] * scale) >> 16
                ) + (EXP_ONE * v_value(k_idx, feature))
        else:
            weight = exp_weight(row_max[q_idx] - score)
            denominator[q_idx] += weight
            for feature in range(FEATURE_DIM):
                numerator[q_idx][feature] += weight * v_value(k_idx, feature)

    return [
        [
            rtl_divide(numerator[q_idx][feature] << 8, denominator[q_idx])
            if denominator[q_idx]
            else 0
            for feature in range(FEATURE_DIM)
        ]
        for q_idx in range(seq_len)
    ]


def batch_context(seq_len: int, mode: str):
    keys_by_query = [[] for _ in range(seq_len)]
    for q_idx, k_idx in pair_stream(seq_len, mode):
        keys_by_query[q_idx].append(k_idx)

    result = []
    for q_idx, keys in enumerate(keys_by_query):
        if not keys:
            result.append([0] * FEATURE_DIM)
            continue
        max_score = max(qk_score(q_idx, k_idx) for k_idx in keys)
        weights = [exp_weight(max_score - qk_score(q_idx, k_idx)) for k_idx in keys]
        denominator = sum(weights)
        result.append(
            [
                (
                    sum(
                        weight * v_value(k_idx, feature)
                        for weight, k_idx in zip(weights, keys)
                    )
                    << 8
                )
                // denominator
                for feature in range(FEATURE_DIM)
            ]
        )
    return result


def main() -> None:
    for denominator in (1, 3, EXP_ONE, EXP_ONE * 128):
        for quotient in (0, 1, 255, 256, 32768, 65280, 65535):
            for remainder in (0, denominator - 1):
                numerator = denominator * quotient + remainder
                if rtl_divide(numerator, denominator) != numerator // denominator:
                    raise AssertionError(
                        f"iterative divider mismatch: n={numerator}, d={denominator}"
                    )

    checked = 0
    for seq_len in (3, 16, 17, 32, 64, 128):
        for mode in MODES:
            online = online_context(seq_len, mode)
            batch = batch_context(seq_len, mode)
            if online != batch:
                raise AssertionError(f"online/batch mismatch: seq_len={seq_len}, mode={mode}")
            if len(online) != seq_len or any(len(row) != FEATURE_DIM for row in online):
                raise AssertionError(f"wrong output shape: seq_len={seq_len}, mode={mode}")
            if any(value < 0 or value > (255 << 8) for row in online for value in row):
                raise AssertionError(f"Q8.8 result out of range: seq_len={seq_len}, mode={mode}")
            checked += 1
    print(f"ONLINE_SOFTMAX_MODEL_PASS cases={checked}")


if __name__ == "__main__":
    main()
