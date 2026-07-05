---
name: fp-arith-multicycle-pipeline
description: "FP arith (FADD/FMUL/FMA) is now multi-cycle pipelined (FADD 3 / FMUL 3 / FMA 5 stages, unified latency 5), no longer single-cycle — was the true Fmax cap"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7634f6a6-7c5f-44da-b5f3-2632c19481d2
---

`OooFpArithGate.v` (rv64 OOO core) was rewritten 2026-06-29 from single-cycle pure-combinational to **internally multi-cycle pipelined**. FADD/FSUB = 3 stages, FMUL = 3 stages, FMADD-family = 5 stages, unified `FP_ARITH_LATENCY = 5` (the gate is now sequential: `clk/rst/flush_i/start_i` in, `done_o` out).

**Why:** FP arith was the real Fmax cap — FMA 173 levels / 36.5ns ≫ dispatch 39 / 7.95ns (known-issues [T1]). After pipelining the worst FP arith stage is **31 levels / 6.3ns < dispatch**, so FP arith no longer caps Fmax (dispatch does). 5.6× shallower.

**How it works (key facts for future work):**
- FP is **fully serialized** (one op at a time at the `OooPendingFpSequencer` boundary, backend drained), and operands `frsN` stay stable the whole pending window. So it's *multi-cycle*, NOT a throughput pipeline — no hazard/bypass logic, and shorter ops' outputs stay valid until the unified `done` tick.
- Control: `compute_start` → gate `done_o` (latency counter) → `OooFpPendingExec.compute_ready_o` → `OooPendingFpSequencer` gates the `compute_done` latch. Blast radius = 4 execute-subsystem files; drain-gate/control-plane/glue unchanged (they already wait on `compute_done`).
- **bit-exact preserved by construction** — same arithmetic lines, only pipeline registers inserted. value+fflags merged per op.
- Getting FMUL/FMA below dispatch required narrowing `exp_z`/`e_biased` from `integer` (32-bit) to `signed [13:0]` (values fit [-1021,3072]) to halve the exponent-arithmetic CARRY4 chains; FADD's exp was already narrow. Also: split subnormal-shift from normalize (FMUL), and round from normalize (all ops).

FP arith now takes 3–5 cycles instead of 1; CPI impact negligible (FP serialized + rare: AM is soft-float, only Linux libm/libc uses HW FP). Validated bit-exact: rv64uf/ud golden 23/23 (incl fmadd), FP smoke 13/13, difftest vs NEMU softfloat. Spec: `npc/rv64/design/specs/ooo-fp-arith-pipeline.md`. Related: [[fp2-fma-fused-fix]] (the fused FMA datapath that's now pipelined), [[rtl-coding-standard]], [[verilog-not-systemverilog-for-synth]].
