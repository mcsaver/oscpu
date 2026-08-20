# FP arithmetic production-child split independent review v2

- Contract SHA-256: `9c8d1642d8f537a4f60f39b6ca181dc29798c2b34ecf9313f4a2d3d3489392d7`
- Verdict: `FIX / GAP`.
- Source reachability: `CLOSED` for
  `NpcTop.u_core -> u_ooo_core -> u_execute_backend -> u_core_slice ->
  u_decode_backend -> u_int_backend -> u_fp_backend -> u_fp_arith`.
- Local RTL review found no new five-cycle, throughput, transaction-owner,
  mixed-precision, kill/flush, full-mag jam or fused-rounding counterexample.
- Current elaboration and mapped receipts remain `GAP_STALE_DESIGN`.

The functional receipt is not fail-closed because its final-input and dependency
manifests omit five actual focused/mutation dependencies:

1. `npc/rv64/vsrc/include/define.v`
2. `npc/rv64/testbench/common/tb_common.svh`
3. `npc/rv64/vsrc/execute/OooFpPredicates.v`
4. `npc/rv64/vsrc/execute/OooFpRound.v`
5. `npc/rv64/testbench/scripts/check_tb_result.py`

The next input-bound attempt must also bind the raw
`tb_ooo_fp_arith_gate.log`, add independent Mul S4/S5 alignment,
wrapper-helper-owner and ProducerId corruption mutations, and retain physical
status as `UNMEASURED/GAP`.

No simulation, mutation, Registry command, synthesis or STA was run by the
reviewer. All read-only commands ended and WSL shell ownership was returned.
