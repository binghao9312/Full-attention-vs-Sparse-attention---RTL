from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "Rtl"
PRESIM = ROOT / "Presim"
POSTSIM = ROOT / "Postsim"
SYN = ROOT / "Syn"


def read(name: str) -> str:
    return (RTL / name).read_text(encoding="utf-8")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"missing {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        raise AssertionError(f"forbidden {label}: {needle}")


def main() -> None:
    sparse = read("sparse_attention_core.v")
    accumulator = read("qk_dot_accumulator.v")
    presim_tb = (PRESIM / "tb.v").read_text(encoding="utf-8")
    postsim_tb = (POSTSIM / "tb.v").read_text(encoding="utf-8")
    presim_tcl = (PRESIM / "Presim.tcl").read_text(encoding="utf-8")
    sparse_syn_tcl = (SYN / "sparse_attention" / "syn.tcl").read_text(encoding="utf-8")

    feature_mem_path = RTL / "qkv_feature_mem.v"
    if not feature_mem_path.exists():
        raise AssertionError("missing RTL/Rtl/qkv_feature_mem.v")
    feature_mem = feature_mem_path.read_text(encoding="utf-8")

    for port in (
        "qkv_we",
        "qkv_sel",
        "qkv_token_idx",
        "qkv_feature_idx",
        "qkv_data_in",
    ):
        require(sparse, port, "sparse_attention_core QKV load port")

    for signal in (
        "q_feature_vector",
        "k_feature_vector",
        "v_feature_vector",
    ):
        require(sparse, signal, "sparse_attention_core feature memory wiring")

    for memory in ("q_mem", "k_mem", "v_mem"):
        require(feature_mem, memory, "qkv_feature_mem storage")
    require(feature_mem, "q_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =\n                    {DATA_WIDTH{1'b0}}", "q_feature_mem explicit Q read else")
    require(feature_mem, "k_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =\n                    {DATA_WIDTH{1'b0}}", "q_feature_mem explicit K read else")
    require(feature_mem, "v_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =\n                    {DATA_WIDTH{1'b0}}", "q_feature_mem explicit V read else")
    require(feature_mem, "end else if (!qkv_we) begin", "q_feature_mem explicit no-write branch")
    require(feature_mem, "unsupported qkv_sel", "q_feature_mem explicit invalid select branch")

    require(accumulator, "q_feature_vector", "qk_dot_accumulator Q input vector")
    require(accumulator, "k_feature_vector", "qk_dot_accumulator K input vector")
    forbid(accumulator, "stage0_q_idx + d + 1", "pseudo Q value")
    forbid(accumulator, "stage0_k_idx + d + 2", "pseudo K value")

    for testbench_name, testbench in (("presim", presim_tb), ("postsim", postsim_tb)):
        require(testbench, "load_qkv_features", f"{testbench_name} QKV loading task")
        require(testbench, "write_qkv_feature(2'd0", f"{testbench_name} Q load")
        require(testbench, "write_qkv_feature(2'd1", f"{testbench_name} K load")
        require(testbench, "write_qkv_feature(2'd2", f"{testbench_name} V load")
        require(testbench, "expected_sparse_qk_score", f"{testbench_name} memory-backed sparse score check")
        require(testbench, "expected_full_qk_score", f"{testbench_name} full baseline score check")

    require(presim_tcl, "qkv_feature_mem.v", "presim filelist")
    require(sparse_syn_tcl, "qkv_feature_mem.v", "sparse synthesis filelist")


if __name__ == "__main__":
    main()
