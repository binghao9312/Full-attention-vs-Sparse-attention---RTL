# Task 3 Fix Report: Architecture Visualization Updates

This report details the modifications applied to the interactive hardware architecture visualization (`sparse_attention_architecture.html`) to resolve FSM, stats counter, and signal gating mismatches identified by the reviewer.

---

## 1. FSM Transition Logic Mismatch (Softmax & Context)
* **Problem**: In the SVG FSM diagram, the transition path from the `OUTPUT` (S4) state went incorrectly to the `DIVIDE` (S3) state, whereas the actual RTL (`sparse_softmax_sv.v`) goes to `STATE_PREPARE` (S2) when the sequence is not done to reload division parameters.
* **Fix**: 
  - Modified the SVG path for the transition starting from `OUTPUT` to target `PREPARE` (S2) instead of `DIVIDE` (S3).
  - Used a curved cubic Bezier path (`M 145,295 C 185,335 245,335 285,295`) to prevent overlapping with the existing straight horizontal path going from `PREPARE` to `OUTPUT`.
  - Updated the text label to `ready & !done_seq (reload/divide next)` to precisely explain the hardware behavior.

## 2. FSM Transition Condition Inversion (Softmax & Context)
* **Problem**: The transition arrow from `UPDATE` (S1) back to `COLLECT` (S0) was incorrectly labeled `update_feat != LAST`. In the RTL, this transition occurs when `update_feature == LAST_FEATURE` (and scores are not done). If it is not the last feature, the FSM remains in `UPDATE`.
* **Fix**: Changed the label from `update_feat != LAST` to `update_feat == LAST` to reflect the correct hardware branch condition.

## 3. Stats Counter Trigger Mismatch (Stats & Result FIFO)
* **Problem**: The SVG diagram and explanation incorrectly stated that `cycle_count` unconditionally increments every clock cycle. However, in `stats_counter.v`, all three counters (`pair_count`, `cycle_count`, `mac_count`) are gated/triggered by `pair_valid`.
* **Fix**:
  - Updated the input signal label for `cycle_count` in the SVG diagram from `clk` to `pair_valid`.
  - Corrected the text explanation to state that `cycle_count` accumulates valid execution cycles and increments only when `pair_valid` is active.

## 4. Control Signal Line Gating (Dot Accumulator)
* **Problem**: The yellow control line branching for `clk`/`advance_ready` in the `Dot Accumulator` tab visually connected only to the last register (`product_reg[3]`), instead of showing connections to all pipeline registers.
* **Fix**:
  - Extended the vertical control line at Stage 1 from `M 537,420 L 537,365` to `M 537,420 L 537,110` so it spans all 4 product registers (`product_reg[0:3]`).
  - Added connection nodes (`<circle>` elements) at the intersection of the control line and the bottom of each intermediate register (`product_reg[3]`, `product_reg[2]`, `product_reg[1]`).
  - For visual consistency, also added a connection node at the bottom of the Stage 0 register (`stage0_k_feat_reg`) where the corresponding Stage 0 control line passes.

---

## Verification
* The HTML file was parsed programmatically with `html.parser` to verify structure and syntax correctness. The check passed successfully.
* Staged and committed changes in Git:
  - Commit SHA: `23d7165`
  - Message: `Fix FSM transitions, stats counter trigger condition, and control line gating in architecture SVG diagram`
