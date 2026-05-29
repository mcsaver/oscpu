# 2026-05-29 OoO memory streaming dispatch

## Intent

The lane1 memory packet fast path only reduces AM `cpu-tests/add` from CPI 2.977 to 2.967. The remaining dominant cost is that every lane0 memory still freezes the frontend until that memory and older uops retire.

## Four-phase design record

1. Study/context
   - `OooIntBackend` already models memory as a real ROB/IQ uop with one outstanding request.
   - While `mem_pending_q` is set, issue is blocked, but dispatch/rename can still accept younger uops into ROB/IQ.
   - ROB retirement stays in program order, so completed younger uops do not become architectural before older memory.
2. Root cause
   - `OooAluFetchCore` classifies memory as a frontend stop condition and uses `pending_mem_q` to resume later, serializing fetch around every load/store.
3. Plan
   - Remove memory from the frontend stop/flush path.
   - Let lane0/lane1 memory use the normal two-lane dispatch path when no lane1 control/fault barrier is present.
   - Keep lane1 branch/JALR/fetch-fault/ebreak as precise half-packet barriers.
   - Keep backend single-memory issue unchanged.
4. Validation plan
   - Adjust fetch-core tests to assert memory streams without `stop_pending_q`.
   - Run focused fetch-core test, full module regression, experimental AM `add`, and default-path build/run.

## Notes

- This is still a conservative memory model: only one memory request can be outstanding in the backend.
- Backend commit exceptions are still a known experimental limitation for this OoO shell; AM `add` does not exercise memory faults.

## Result

- Implemented and kept.
- Memory uops no longer act as frontend stop barriers in the common path; younger non-control packets may continue through dispatch/rename while the backend enforces one outstanding memory request and in-order ROB retirement.
- Focused fetch-core and full module regressions passed after the pair-atomic dispatch fix.
- Experimental AM `cpu-tests/add`: GOOD TRAP, `cycles=1571`, `commits=839`, `CPI=1.872`, log `/tmp/ysyx-ooo-mem-stream-fix-add.log`.
