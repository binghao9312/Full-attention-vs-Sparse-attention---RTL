from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "Rtl"
PRESIM = ROOT / "Presim"
SYN = ROOT / "Syn" / "sparse_attention"


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"missing {label}: {needle}")


def main() -> None:
    softmax_path = RTL / "sparse_softmax_sv.v"
    if not softmax_path.exists():
        raise AssertionError("missing RTL/Rtl/sparse_softmax_sv.v")

    softmax = softmax_path.read_text(encoding="utf-8")
    core = (RTL / "sparse_attention_core.v").read_text(encoding="utf-8")
    chip_top = (RTL / "chip_top.v").read_text(encoding="utf-8")
    pattern = (RTL / "pattern_controller.v").read_text(encoding="utf-8")
    streamer = (RTL / "qk_pair_streamer.v").read_text(encoding="utf-8")
    tb = (PRESIM / "tb.v").read_text(encoding="utf-8")
    postsim_tb = (ROOT / "Postsim" / "tb.v").read_text(encoding="utf-8")
    presim_tcl = (PRESIM / "Presim.tcl").read_text(encoding="utf-8")
    syn_tcl = (SYN / "syn.tcl").read_text(encoding="utf-8")

    for token in (
        "STATE_COLLECT",
        "STATE_UPDATE",
        "STATE_PREPARE",
        "STATE_DIVIDE",
        "FSM sequential block: state register only",
        "FSM combinational block: next-state logic only",
        "next_state = state;",
        "state <= next_state;",
        "row_initialized",
        "row_max",
        "row_exp_sum",
        "row_weighted_sum",
        "score_value - row_max[score_q_idx]",
        "incoming_weight = exp_lut(incoming_delta)",
        "rescaled_weighted_sum + one_weighted_v",
        "division_remainder >= shifted_divisor",
        "division_quotient[division_bit] <= 1'b1",
    ):
        require(softmax, token, "online softmax/SV stage")

    if "/ row_exp_sum" in softmax:
        raise AssertionError("context normalization must not infer a combinational divider")
    if softmax.count("state <=") != 3:
        raise AssertionError("state must only be assigned in the dedicated FSM state register block")

    for token in (
        "u_sparse_softmax_sv",
        "assign pipeline_ready = score_ready && softmax_score_ready;",
        ".score_valid(score_valid_pipe)",
        ".score_ready(softmax_score_ready)",
        ".v_read_idx(softmax_v_read_idx)",
        ".context_valid(context_valid)",
        ".done(context_done)",
    ):
        require(core, token, "core softmax/SV wiring")

    for token in (
        "ADDR_RESULT_FEATURE_IDX",
        "ADDR_RESULT_VALUE_0",
        "core_context_valid && core_context_ready",
        "{core_context_q_idx, core_context_feature_idx, core_context_value}",
    ):
        require(chip_top, token, "chip context result path")

    require(pattern, "pair_valid <= ((block_start + offset) < cfg_seq_len);", "partial final block guard")
    require(pattern, "((offset << 1) >= cfg_seq_len)", "non-power-of-two butterfly termination")
    require(streamer, "pair_valid && advance_ready", "line-buffer backpressure gating")

    for token in (
        "expected_context_q8_8",
        "check_context",
        "sparse_context_valid",
        "context_observed_count",
    ):
        require(tb, token, "pre-sim context golden check")
        require(postsim_tb, token, "post-sim context golden check")

    require(presim_tcl, "../Rtl/sparse_softmax_sv.v", "pre-sim file list")
    require(syn_tcl, '"../../Rtl/sparse_softmax_sv.v"', "synthesis file list")


if __name__ == "__main__":
    main()
