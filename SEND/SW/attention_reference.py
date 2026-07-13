from __future__ import annotations

import argparse
import statistics
import time
from dataclasses import dataclass
from typing import Iterable


MODE_FULL = "full"
MODE_SLIDING = "sliding"
MODE_DILATED = "dilated"
MODE_SLIDING_GLOBAL = "sliding_global"
MODE_BUTTERFLY = "butterfly"
MODES = (MODE_FULL, MODE_SLIDING, MODE_DILATED, MODE_SLIDING_GLOBAL, MODE_BUTTERFLY)


@dataclass(frozen=True)
class AttentionConfig:
    seq_len: int = 16
    window_size: int = 4
    dilation: int = 2
    global_index: int = 0
    feature_dim: int = 4


def qk_score(q_idx: int, k_idx: int, cfg: AttentionConfig) -> int:
    score = 0
    for d in range(cfg.feature_dim):
        q_value = q_idx + d + 1
        k_value = k_idx + d + 2
        score += q_value * k_value
    return score


def score_checksum(pairs: list[tuple[int, int]], cfg: AttentionConfig) -> int:
    return sum(qk_score(q_idx, k_idx, cfg) for q_idx, k_idx in pairs)


def _block_start(index: int, window_size: int) -> int:
    return (index // window_size) * window_size


def _sliding_keys(q_idx: int, cfg: AttentionConfig) -> Iterable[int]:
    start = _block_start(q_idx, cfg.window_size)
    end = min(start + cfg.window_size, cfg.seq_len)
    return range(start, end)


def _dilated_keys(q_idx: int, cfg: AttentionConfig) -> Iterable[int]:
    start = _block_start(q_idx, cfg.window_size)
    end = min(start + cfg.window_size, cfg.seq_len)
    return range(start, end, cfg.dilation)


def generate_pairs(mode: str, cfg: AttentionConfig) -> list[tuple[int, int]]:
    pairs: list[tuple[int, int]] = []

    if mode == MODE_FULL:
        for q_idx in range(cfg.seq_len):
            for k_idx in range(cfg.seq_len):
                pairs.append((q_idx, k_idx))
        return pairs

    if mode == MODE_SLIDING:
        for q_idx in range(cfg.seq_len):
            for k_idx in _sliding_keys(q_idx, cfg):
                pairs.append((q_idx, k_idx))
        return pairs

    if mode == MODE_DILATED:
        for q_idx in range(cfg.seq_len):
            for k_idx in _dilated_keys(q_idx, cfg):
                pairs.append((q_idx, k_idx))
        return pairs

    if mode == MODE_SLIDING_GLOBAL:
        seen: set[tuple[int, int]] = set()
        for q_idx in range(cfg.seq_len):
            for k_idx in _sliding_keys(q_idx, cfg):
                pair = (q_idx, k_idx)
                seen.add(pair)
                pairs.append(pair)

        for q_idx in range(cfg.seq_len):
            pair = (q_idx, cfg.global_index)
            if pair not in seen:
                seen.add(pair)
                pairs.append(pair)

        for k_idx in range(cfg.seq_len):
            pair = (cfg.global_index, k_idx)
            if pair not in seen:
                seen.add(pair)
                pairs.append(pair)
        return pairs

    if mode == MODE_BUTTERFLY:
        stride = 1
        while stride < cfg.seq_len:
            for q_idx in range(cfg.seq_len):
                k_idx = q_idx ^ stride
                if k_idx < cfg.seq_len:
                    pairs.append((q_idx, k_idx))
            stride *= 2
        return pairs

    raise ValueError(f"unsupported mode: {mode}")


def benchmark(mode: str, cfg: AttentionConfig, repeats: int) -> tuple[list[tuple[int, int]], float]:
    samples = []
    pairs: list[tuple[int, int]] = []
    for _ in range(repeats):
        start = time.perf_counter()
        pairs = generate_pairs(mode, cfg)
        samples.append(time.perf_counter() - start)
    return pairs, statistics.mean(samples)


def main() -> None:
    parser = argparse.ArgumentParser(description="Sparse attention software golden reference")
    parser.add_argument("--seq-len", type=int, default=None)
    parser.add_argument("--seq-lens", default="16,32,64,128")
    parser.add_argument("--window-size", type=int, default=4)
    parser.add_argument("--dilation", type=int, default=2)
    parser.add_argument("--global-index", type=int, default=0)
    parser.add_argument("--feature-dim", type=int, default=4)
    parser.add_argument("--repeats", type=int, default=1000)
    parser.add_argument("--dump-pairs", action="store_true")
    args = parser.parse_args()

    if args.seq_len is not None:
        seq_lens = [args.seq_len]
    else:
        seq_lens = [int(item.strip()) for item in args.seq_lens.split(",") if item.strip()]

    print()
    print("-" * 86)
    print(
        f"{'seq_len':>7} {'mode':<15} {'pairs':>8} {'macs':>10} "
        f"{'checksum':>12} {'reduction':>10} {'runtime_us':>12}"
    )
    print("-" * 86)
    for seq_len in seq_lens:
        cfg = AttentionConfig(
            seq_len=seq_len,
            window_size=args.window_size,
            dilation=args.dilation,
            global_index=args.global_index,
            feature_dim=args.feature_dim,
        )
        print()
        full_count = len(generate_pairs(MODE_FULL, cfg))
        for mode in MODES:
            pairs, runtime_s = benchmark(mode, cfg, args.repeats)
            mac_count = len(pairs) * cfg.feature_dim
            checksum = score_checksum(pairs, cfg)
            reduction = 1.0 - (len(pairs) / full_count)
            print(
                f"{seq_len:7d} {mode:<15} {len(pairs):8d} {mac_count:10d} "
                f"{checksum:12d} {reduction:10.6f} {runtime_s * 1_000_000:12.3f}"
            )
            if args.dump_pairs:
                for q_idx, k_idx in pairs:
                    print(f"PAIR,{seq_len},{mode},{q_idx},{k_idx},{qk_score(q_idx, k_idx, cfg)}")


if __name__ == "__main__":
    main()
