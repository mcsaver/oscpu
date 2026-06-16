# 2026-05-29 OoO lane1 branch fast dispatch

## Intent

After memory streaming, AM `cpu-tests/add` reaches CPI 1.872. A short VCD profile shows 256 cycles in `stop_branch_old`, mostly from lane1 loop branches such as `addi; bne` packets.

## Four-phase design record

1. Study/context
   - Lane0 branches already dispatch as real backend uops and resolve through `OooIntBackend`.
   - `OooIntBackend` also exposes branch resolve for issue1.
   - `OooAluFetchCore` still treats lane1 branches as half-packet barriers and later resolves them through the old synthetic/drain path.
2. Root cause
   - Lane1 branch is artificially serialized even though the backend can execute/resolve it.
3. Plan
   - Detect lane1 branch packets when lane0 is not a control/jump stop.
   - Dispatch both lanes into the backend in one atomic packet.
   - Freeze the frontend until backend branch resolve arrives, then resume at resolved next PC.
   - Keep lane1 fetch fault, ebreak, and JALR on the precise barrier path.
4. Validation plan
   - Extend `tb_ooo_alu_fetch_core` to assert the lane1 branch fast path.
   - Run focused fetch-core test, full module regression, experimental AM `add`, and default-path build/run.

## Notes

- This remains non-predictive: no younger packet is fetched beyond the unresolved branch.
- It removes the old drain/synthetic branch overhead for lane1 branches only.

## Result

- Implemented and kept.
- Lane1 branch can dispatch with lane0 into the backend when no older packet-local barrier prevents it, and the backend lane1 branch resolve port drives the same pending-branch frontend recovery path.
- Experimental AM `cpu-tests/add`: GOOD TRAP, `cycles=1379`, `commits=839`, `CPI=1.644`, log `/tmp/ysyx-ooo-lane1-branch-add.log`.
- Limitation: still non-predictive; branch speculation remains the next major CPI blocker.
