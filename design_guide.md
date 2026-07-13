# Sparse Attention ASIC Design Guide

## 1. Scope

This document defines the chip-level interface and integration rules for the
TSMC T18 sparse-attention ASIC. The external interface uses an 8-bit shared
read/write data bus. AXI is not exposed at the package boundary.

The compute core now implements the complete sparse-attention data path:
sparse QK score generation, max-subtracted scaling, fixed-point softmax, and
weighted V accumulation. QK scores remain available as internal debug outputs;
the chip-level result FIFO returns the final context vector in Q8.8 format.

The fixed-point softmax uses an online stable update, a Q0.16 exponential
lookup table, and one final normalization divider. It does not store the dense
QK matrix: per-query state is limited to row maximum, exponential sum, and four
weighted-V accumulators. Before tapeout, these state arrays and the divider must
be mapped to area- and timing-appropriate implementations.

## 2. Design Objectives

- Fit within 38 available signal I/O pins, excluding power and ground pads.
- Use a simple synchronous register bus that is easy to drive from an FPGA or
  microcontroller.
- Share write and read data pins through `inout [7:0] data_io`.
- Keep tri-state logic at the chip/pad boundary only.
- Load Q, K, and V data through an auto-incrementing linear address.
- Preserve every generated result through FIFO storage and backpressure.
- Keep the compute core independent from the external bus implementation.

## 3. External Signal Interface

```verilog
module chip_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       req,
    input  wire       rw,        // 0: write, 1: read
    input  wire [5:0] addr,
    inout  wire [7:0] data_io,
    output wire       ready,
    output wire       irq_done
);
```

### 3.1 Pin Budget

| Signal | Width | Direction | Description |
| --- | ---: | --- | --- |
| `clk` | 1 | Input | Bus and core clock |
| `rst_n` | 1 | Input | Active-low asynchronous reset input |
| `req` | 1 | Input | Transaction request |
| `rw` | 1 | Input | `0`: write, `1`: read |
| `addr` | 6 | Input | Byte register address |
| `data_io` | 8 | Inout | Shared write/read data bus |
| `ready` | 1 | Output | Transaction completion/acceptance |
| `irq_done` | 1 | Output | Accelerator completion interrupt |
| **Total** | **20** | | Excludes power and ground pads |

The interface leaves 18 signal pins available for scan, test mode, debug, or
future control signals.

## 4. Shared Data Bus Implementation

`inout` and high impedance must be used only in the outermost chip wrapper.
All internal modules use separate input, output, and output-enable signals.

```verilog
wire [7:0] data_i;
wire [7:0] data_o;
wire       data_oe;

assign data_i  = data_io;
assign data_io = data_oe ? data_o : 8'hZZ;
```

At the pad-ring level, `data_i`, `data_o`, and `data_oe` must connect to the
bidirectional I/O pad cells provided by the selected T18 CBDK. Internal
tri-state buses must not be inferred.

Mandatory rules:

- `data_oe` is `0` during reset and whenever no read response is active.
- The host drives `data_io` only during a write transaction.
- The host releases `data_io` before requesting a read transaction.
- The ASIC drives `data_io` only while returning valid read data.
- A write/read direction change includes at least one idle turnaround cycle.

## 5. Bus Protocol

A transfer is accepted on a rising edge when both `req` and `ready` are high.
The host must hold `rw`, `addr`, and write data stable until the transfer is
accepted.

### 5.1 Write Transaction

1. The host sets `addr` and `rw = 0`.
2. The host drives the write byte onto `data_io`.
3. The host asserts `req`.
4. The ASIC asserts `ready` when it can accept the write.
5. The write is committed on the rising edge with `req && ready`.
6. The host deasserts `req` and releases `data_io`.

### 5.2 Read Transaction

1. The host releases `data_io` to high impedance.
2. The host sets `addr` and `rw = 1`.
3. The host asserts `req`.
4. The ASIC drives read data and asserts `ready` when the byte is valid.
5. The host samples `data_io` on the rising edge with `req && ready`.
6. The host deasserts `req`; the ASIC then releases `data_io`.

### 5.3 Direction Turnaround

```text
Cycle        req   rw   Host data_io   ASIC data_io
Idle          0    X         Z               Z
Write         1    0        DATA             Z
Turnaround    0    X         Z               Z
Read          1    1         Z              DATA
Idle          0    X         Z               Z
```

Back-to-back transfers in the same direction may be supported without an idle
cycle. A direction change always requires the turnaround cycle.

## 6. Register Map

All registers are 8 bits wide. Multi-byte values use little-endian byte order.

| Address | Name | Access | Description |
| ---: | --- | --- | --- |
| `0x00` | `CONTROL` | R/W | Start, mode, and result-clear control |
| `0x01` | `SEQ_LEN` | R/W | Active sequence length, `1` to `128` |
| `0x02` | `QKV_ADDR_L` | R/W | QKV linear address bits `[7:0]` |
| `0x03` | `QKV_ADDR_H` | R/W | QKV linear address bits `[10:8]` |
| `0x04` | `QKV_DATA` | W | Write byte and auto-increment QKV address |
| `0x05` | `STATUS` | R | Busy, done, FIFO, and error status |
| `0x08` | `RESULT_Q_IDX` | R | Q index at result FIFO front |
| `0x09` | `RESULT_FEATURE_IDX` | R | Context-vector feature index at FIFO front |
| `0x0A` | `RESULT_VALUE_0` | R | Q8.8 context value bits `[7:0]` |
| `0x0B` | `RESULT_VALUE_1` | R | Q8.8 context value bits `[15:8]` |
| `0x0C` | `RESULT_VALUE_2` | R | Reserved; reads as zero |
| `0x0D` | `RESULT_VALUE_3` | R | Reserved; reads as zero |
| `0x0E` | `RESULT_POP` | W | Write bit 0 as `1` to pop FIFO front |
| `0x10`-`0x13` | `PAIR_COUNT` | R | 32-bit pair count |
| `0x14`-`0x17` | `CYCLE_COUNT` | R | 32-bit elapsed cycle count |
| `0x18`-`0x1B` | `MAC_COUNT` | R | 32-bit accepted QK dot-product MAC count |

### 6.1 CONTROL Register

| Bit | Name | Description |
| ---: | --- | --- |
| 0 | `START` | Write-one pulse; starts the configured operation |
| 3:1 | `MODE` | `1`: sliding, `2`: dilated, `3`: sliding-global, `4`: butterfly |
| 4 | `CLEAR_RESULT` | Write-one pulse; clears result FIFO and sticky result errors |
| 7:5 | Reserved | Write as zero |

`START` is rejected while the accelerator is busy. Configuration and QKV
memory writes are allowed only while the accelerator is idle.

### 6.2 STATUS Register

| Bit | Name | Description |
| ---: | --- | --- |
| 0 | `BUSY` | Compute operation is active |
| 1 | `DONE` | Sticky completion flag; cleared by the next valid start |
| 2 | `RESULT_VALID` | Result FIFO is not empty |
| 3 | `RESULT_FULL` | Result FIFO cannot accept another entry |
| 4 | `RESULT_OVERFLOW` | Sticky flag indicating attempted result loss |
| 5 | `PROTOCOL_ERROR` | Sticky flag for an illegal bus/register operation |
| 7:6 | Reserved | Read as zero |

`irq_done` reflects the sticky `DONE` status unless the final implementation
defines a separate interrupt-enable register.

## 7. QKV Memory Addressing

The current configuration stores three planes of 128 tokens, four features per
token, and eight bits per feature:

```text
3 x 128 x 4 x 8 bits = 12,288 bits = 1,536 bytes
```

The 11-bit QKV linear address is mapped as follows:

| Address range | Plane | Byte count |
| --- | --- | ---: |
| `0x000`-`0x1FF` | Q | 512 |
| `0x200`-`0x3FF` | K | 512 |
| `0x400`-`0x5FF` | V | 512 |

Within each plane:

```text
plane_offset = linear_address % 512
token_index  = plane_offset / 4
feature_idx  = plane_offset % 4
```

After an accepted write to `QKV_DATA`, the wrapper increments the linear
address. This allows the host to set `QKV_ADDR_L/H` once and stream contiguous
feature bytes.

Writes outside `0x000` through `0x5FF`, writes while `BUSY = 1`, and an invalid
sequence length set `PROTOCOL_ERROR` and do not modify QKV memory.

## 8. Softmax and Weighted-V Data Path

Sparse score order is not row-contiguous in every mode. In particular,
sliding-global and butterfly patterns revisit a query in later phases. The
implementation therefore uses an online stable softmax update for every
accepted `{q_idx, k_idx, score}`:

1. Apply the default `1/sqrt(4)` scale to a score delta with a right shift.
2. If the score does not exceed the saved row maximum, add
   `exp(score - max)` to the denominator and weighted-V accumulators.
3. If the score becomes the new row maximum, rescale the saved denominator and
   accumulators by `exp(old_max - new_max)`, then add the new V vector.
4. After all scores are accepted, normalize each saved weighted sum and emit
   one Q8.8 context value for every `{q_idx, feature_idx}` pair.

Normalization uses a 16-cycle MSB-first shift/subtract divider per context
value. This avoids inferring a large single-cycle combinational divider; the
result remains the exact truncated integer quotient used by the golden model.

This update is independent of score arrival order and removes the need for a
`128 x 128 x 32` score buffer. With the default parameters, row state is about
32 Kbit instead of 524 Kbit.

Max subtraction prevents exponential overflow. Deltas above the lookup-table
range map to zero, which is the intended fixed-point underflow behavior.

## 9. Result Flow Control

The external 8-bit bus requires multiple cycles to read a context result, so
the final weighted-V output uses valid/ready backpressure and a result FIFO.

The integration must include a result FIFO and valid/ready backpressure:

```text
Sparse core context_valid/context_ready
                 |
                 v
   Result FIFO: q_idx, feature_idx, Q8.8 value
                 |
                 v
         Register bus readout
```

Required behavior:

- A FIFO entry contains `{q_idx, feature_idx, context_value}`.
- The compute pipeline advances a result only on
  `context_valid && context_ready`.
- FIFO full deasserts `context_ready` and stalls context emission without
  changing ordering or recomputing the held result.
- FIFO front data remains stable while the host reads the result bytes.
- Writing `1` to `RESULT_POP[0]` removes exactly one complete FIFO entry.
- Popping an empty FIFO sets `PROTOCOL_ERROR` and changes no FIFO state.
- `RESULT_OVERFLOW` must never assert during a valid backpressured operation.

A FIFO without core backpressure is insufficient unless it is sized for the
entire worst-case operation. Backpressure is the preferred implementation.

## 10. Core Integration Boundary

The bus wrapper translates register operations into the existing core ports:

```text
CONTROL.START       -> one-cycle core start pulse
CONTROL.MODE        -> core mode
SEQ_LEN             -> core cfg_seq_len
QKV_DATA write      -> qkv_we, qkv_sel, qkv_token_idx,
                       qkv_feature_idx, qkv_data_in
core context output -> result FIFO push interface
core counters       -> read-only register snapshots
core done           -> STATUS.DONE and irq_done
```

Counters exposed over the bus must be snapshotted when `done` asserts so that
all bytes of a multi-byte read belong to the same completed operation.

The current `cycle_count` implementation increments only when `pair_valid` is
high. Before tapeout it must either be renamed to `active_pair_cycles` or
changed to count actual elapsed cycles while `BUSY` is high.

## 11. Clock and Reset

- The first implementation uses the same `clk` for the bus controller and
  sparse-attention core. This avoids a clock-domain crossing.
- If an independent SPI or host clock is added later, requests and data must
  cross domains through a documented CDC handshake or asynchronous FIFO.
- External reset assertion may be asynchronous.
- Reset deassertion must be synchronized internally before enabling bus or core
  state machines.
- Reset clears bus output enable, busy state, FIFO state, interrupt state, and
  sticky error flags.

## 12. AXI Policy

AXI and AXI-Lite are not package-level interfaces for this design. Their raw
channel signals consume too many pins and add unnecessary verification scope.

If the accelerator is later integrated into a larger SoC, an internal
AXI-Lite-to-register-bus adapter may be added. The register map and compute core
can remain unchanged.

## 13. T18 Implementation Requirements

- Use the exact standard-cell and I/O libraries supplied for the selected T18
  run.
- Instantiate the required bidirectional signal pads, core/I/O power pads,
  corner pads, fillers, and ESD structures in the pad-level top.
- Confirm the 1.8 V core and 3.3 V I/O power domains against the selected CBDK.
- Include realistic input delay, output delay, output load, clock uncertainty,
  and I/O pad timing in STA.
- Do not treat the existing zero-delay SDC as tapeout signoff constraints.
- Re-run synthesis after the QKV memory, bus wrapper, FIFO, and backpressure
  logic are integrated.
- Determine whether QKV arrays infer registers or an approved SRAM/register-file
  macro. Combinational array reads may create large flip-flop and mux networks.
- Map the per-query max, denominator, and weighted-V state arrays to an approved
  register-file or SRAM implementation if synthesis does not meet area.
- Verify the 16-cycle normalization divider and its accumulator paths against
  the target clock after technology mapping; pipeline the accumulator
  multipliers if synthesis reports a critical-path violation.
- Complete floorplanning, pad-ring assembly, power planning, APR, CTS,
  post-layout STA, gate-level simulation with SDF, DRC, LVS, and antenna checks.

## 14. Verification Checklist

### Bus

- Reset leaves `data_io` undriven by the ASIC.
- Write data is accepted only on `req && ready && !rw`.
- Read data is driven only for a valid read response.
- Same-direction back-to-back transactions work.
- Write/read and read/write turnaround cycles have no contention or unknowns.
- A request held while `ready = 0` commits exactly once when accepted.
- Reserved and illegal addresses have defined behavior.

### QKV Loading

- Auto-increment works across byte and plane boundaries.
- Q, K, and V each receive exactly 512 bytes for the maximum configuration.
- Address `0x5FF` is valid and `0x600` is rejected.
- QKV writes while busy are rejected without memory corruption.

### Softmax and Result Path

- Max subtraction and `1/sqrt(d)` scaling match the fixed-point golden model.
- Softmax uses only sparse-selected keys and produces the expected Q0.16 weights.
- Weighted-V accumulation returns one Q8.8 result per query and feature.
- FIFO preserves Q/feature/value ordering under continuous stalls.
- FIFO full stalls context emission without dropping or duplicating results.
- FIFO front remains stable until `RESULT_POP` is accepted.
- Empty pop and overflow behavior set the documented status bits.
- Interrupt and done status are asserted and cleared as specified.

### End-to-End

- Load deterministic QKV data through the external bus, not hierarchical TB
  access.
- Start every supported sparse mode through the CONTROL register.
- Compare every internal Q/K score and every returned Q8.8 context value with
  the software golden model.
- Test sequence lengths 16, 32, 64, and 128 plus boundary and invalid values.
- Repeat bus and functional tests on RTL and SDF-annotated gate-level netlists.

## 15. Tapeout Readiness Criteria

The design is ready for a T18 submission only when all of the following are
true:

1. The 20-signal external interface and physical pad mapping are frozen.
2. Bus contention and turnaround tests pass.
3. Fixed-point Softmax and weighted-V results match the golden model.
4. Result backpressure is implemented and proven lossless.
5. Online Softmax state and normalization division use approved, timing-clean hardware.
6. Current RTL synthesis reports area and timing using the selected T18 kit.
7. APR confirms core and pad-ring fit at the required utilization.
8. Post-layout timing passes with real I/O constraints and extracted parasitics.
9. Gate-level simulation, DRC, LVS, and required foundry checks pass.
