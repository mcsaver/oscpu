# 2026-05-29 OoO lane1/dual memory fast dispatch

## Intent

AM `cpu-tests/add` still spends most cycles around memory barriers. After lane0 memory can enter the backend before a full drain, the next visible waste is that packet lane1 memory is split into a second fetch/dispatch round. The `add` binary contains common pairs such as `lw/lw` and `addi/sw`.

## Four-phase design record

1. Study/context
   - Current `OooAluFetchCore` treats lane1 memory as a half-packet barrier.
   - `OooAluDecodeBackend` explicitly rejects lane1 memory.
   - `OooIntBackend` already has single memory issue machinery on issue0 and blocks issue1 memory from firing, so a lane1 memory can safely wait in the issue queue and later issue through issue0.
2. Root cause
   - Lane1 memory is not semantically unsupported, but the frontend forces it through the older precise-drain fallback. This loses the useful same-packet dispatch opportunity and repeats fetch/decode work.
3. Plan
   - Allow lane1 memory into the backend.
   - When a packet contains lane1 memory and no lane0 control/jump barrier, dispatch both lanes into the backend in one cycle.
   - Freeze the frontend until the dispatched memory group and older uops drain; resume at lane1 `next_pc`.
   - Keep the existing conservative single outstanding memory model and issue0-only memory execution.
4. Validation plan
   - Extend `tb_ooo_alu_fetch_core` to observe the lane1 memory fast path.
   - Run focused fetch-core test, full module regression, experimental AM `add`, and default-path build/run.

## Notes

- This is still not a real LSQ: no younger instructions are fetched past the memory group while it is pending.
- The change is scoped to the experimental OoO path.

## Result

- Implemented and kept.
- Lane1 memory is accepted by decode/backend when no lane1 control/fault barrier is present, and same-packet memory pairs can be dispatched together.
- A conservative pair-atomic dispatch readiness rule was added later so lane0 is not accepted alone when lane1 also needs resources and the pair cannot fit.
- Experimental AM `cpu-tests/add`: GOOD TRAP, `cycles=2489`, `commits=839`, `CPI=2.967`, log `/tmp/ysyx-ooo-lane1-mem-add.log`.
