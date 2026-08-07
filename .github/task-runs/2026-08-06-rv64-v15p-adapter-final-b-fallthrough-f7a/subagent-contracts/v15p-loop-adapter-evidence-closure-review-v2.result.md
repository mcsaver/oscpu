# V15P loop/adapter evidence-closure review v2

## Independent conclusion

`PASS`

对象：`OooLsuAxiLaneAdapter.final_b_fallthrough_w/u_axi_bvalid_o/u_axi_bresp_o` 与本地正、负向证据。

周期与配置：`S_W_RESP` 最终 B beat；Icarus `-g2012 -DOOO_ASSERT`；mapped 5 ns proxy。

TB/EDA 观测：正向 adapter TB PASS；禁用 fall-through 的编译成功负向 RTL 版本被绝对延迟 oracle 拒绝；5 ns timing hard gate 仍为 `FAIL`。

本 v2 独立闭合 v1 遗漏的 final-B 定向协议证据，但只支持保留可回退中间检查点。它不改写 v1 历史 `GAP`，也不构成 complete-design promotion。

## Identity binding

- Contract SHA-256: `4574ef5c89f71aeb143fc89f9734eb44332bb14b9b051826b5475ccfe9c0b266`.
- Current adapter SHA-256: `6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22`.
- Current adapter TB SHA-256: `b648ce4a00011f9ccebcd98b7d39ee69c81862f7c3d84c8b3451eb76c14ddbfd`.
- Current owner-timing causal-probe TB SHA-256: `b13ef4cfc4140c1c2471fb60b39b808854a2a9ed2f5b0f920ecf52b1ca9bf988`.
- Current module receipt design ID: `sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968`.
- Current module receipt reports `inputs.unchanged=true`, `status=PASS`, and `113/113`.
- Adapter module log SHA-256: `99f427762e80010dc437f1115c963f5657b961639aa30707f40c3d8e3a2e3554`; it contains `[PASS] tb_ooo_lsu_axi_lane_adapter`, the same design ID, and `[RESULT] PASS`.

## Final-B protocol observations

- `final_b_fallthrough_w` is qualified by non-reset, `S_W_RESP`, `d_axi_bvalid_i`, and absence of a later split beat.
- A ready upstream owner consumes the final B in the same cycle.
- A stalled upstream owner captures sticky BRESP into `u_bresp_q` on the same edge and then holds it through `S_B_RESP`.
- `d_axi_bready_o` remains state-only.
- The positive TB covers the no-register-bubble case, OKAY/SLVERR/DECERR, upstream backpressure holding, exactly-once behavior, reset masking, and suppression of a non-final split B response.

## Compile-success negative RTL version

- The diff forces `final_b_fallthrough_w` low and forces the final B through `S_B_RESP`.
- `COMPILE_SUCCESS=1`.
- Store terminal cycles move from the required `2/4/7` to `3/5/8`; peer admission cycles move from `4/6/9` to `5/7/10`.
- The directed oracle reports `adapter final-B fall-through absolute latency mismatch`.
- `MAKE_RC=2` and the inner `[RESULT] FAIL status=1` are the expected rejection; the outer mutation receipt is `RESULT=PASS` because the mutation was detected.
- This establishes one-cycle latency sensitivity; it does not claim fall-through is the only functionally valid implementation.

## Hard-gate boundary

- The mapped evidence workflow completed, but its decision remains `TIMING_HARD_GATE_FAIL_REWORK_OR_ROLLBACK` and `promotion_state=NOT_PROMOTABLE`.
- Candidate WNS: `-18.121620178 ns`.
- Candidate TNS: `-495447.71875 ns`.
- Reported violated paths: `40`.
- This result must not be described as a 5 ns timing PASS, Pareto/baseline/champion/release state, or complete-design promotion.

## Remaining caveat

The module receipt records the pre/post input-manifest hashes and `inputs.unchanged=true` but does not directly echo the adapter TB SHA. The reviewer independently hashed the current TB and bound it to the observed compile/log path. Reading both manifest bodies would be needed only for a future per-file cryptographic replay; this is not a blocker for the v2 contract's directed evidence-closure scope.

Confidence is high within this scoped evidence closure. No further scope extension is required for the reversible-checkpoint disposition.

All reviewer WSL read-only commands exited, no engineering process remained, and single-flight ownership was returned to the primary agent.
