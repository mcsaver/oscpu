# S2-Q0 local bridge registered-fact idle checkpoint

## Scope and non-claims

This checkpoint adds one behavior-neutral fact at the current single-owner
`mem0` bridge boundary: `mem0_idle_o` is a zero-latency conjunction of local
registered ownership facts. It is an **intermediate Q0 correctness point**.
It does not implement the MMU epoch owner, context lock/grant, effective-value
classification, selective squash, a second memory lane, global memory quiet,
or a 200 MHz/PPA qualification.

`NpcCoreTop` only receives the fact on a local wire. No control path consumes
it in Q0, so the live architecture behavior is unchanged.

## Implemented contract

`mem0_idle_o` is true only when all of these local facts are empty:

- bridge FSM is `S_IDLE`;
- request station is empty;
- no dropped-response drain, nokill active transaction, partial AW or partial W
  ownership remains;
- the D-cache registered RMW tail is clear;
- the exact-owner residency mask is zero.

The output is combinational over those registered facts. It is deliberately
not another register: a registered idle output would remain incorrectly high
for one cycle after request fire. The expression contains no request/response
READY, fire, owner equality, live context input, or context-lock/grant input,
so it cannot create the later `quiet -> lock -> ready -> quiet` loop.

Immediate `OOO_ASSERT` checks enforce both directions:

1. safety: asserted idle cannot coexist with any local owner, response/drop,
   AXI output ownership, or macro tail;
2. completeness: completely empty registered state must report idle, preventing
   a sticky-low barrier deadlock.

## Focused and integration evidence

Evidence root: `evidence/r4-s2-q0-bridge-idle-green/`.

The focused case exercises normal protocol trajectories for request station,
stalled AR, R drain, held `S_RESP`, partial AW then W, aggregate B wait,
reachable cache RMW, and PTW A/D escaped-write drain. A short hierarchical
RMW pulse only isolates the registered macro-tail term; it is not presented as
reachability evidence. The real store-RMW sequence supplies that evidence.

Results:

- release and `OOO_ASSERT` positive runs: `2/2 PASS`;
- state-only idle mutation: exactly one
  `[S2-Q0-BRG-IDLE-SAFETY]` fatal;
- stuck-low idle mutation: exactly one
  `[S2-Q0-BRG-IDLE-LIVENESS]` fatal;
- prior bridge exact-owner/effective-kill runner: PASS after rerun;
- wrapper source-bound runner, including `NpcCoreTop`: PASS after rerun.

All three manifests were rechecked against live files:

- Q0 focused: 15/15 SHA-256 entries OK;
- bridge compatibility: 18/18 SHA-256 entries OK;
- wrapper integration: 133/133 SHA-256 entries OK.

## `/tmp` preservation

All ten Q0/bridge/wrapper work directories, including failed runner attempts
and the final wrapper main work directory, were
copied with metadata into:

`tmp/2026-07-15-rv64-ppa-architecture-recovery/s2-mmu-epoch/q0-bridge-idle/system-tmp/`

The archive checker compared source and copy path-for-path, including type,
size, SHA-256, and symlink target. It passed with 10 top-level objects, 66 files,
17 directories, 0 links, and 146,778,084 file bytes. The durable compressed
archive is `system-tmp.tar.zst`, 7,987,446 bytes, 84 members, SHA-256:

`57ebc9ec18527051081131b359eb38f2745daf9e0f4d9af41bf8ba4e49af3ccb`.

The system `/tmp` originals were not deleted.

## Gate status

Q0 local bridge-idle is GREEN. The full R4-S1-ID/S2 epoch checkpoint remains
RED. In particular, `mem0_idle_o` cannot be used alone as `mem_context_quiet`,
and the current bridge is still a single outstanding mem0 path. The next
atomic slice is the standalone `OooMmuEpochOwner` FSM with focused
RED-to-GREEN evidence; integration into CSR/trap/ROB state changes remains a
later atomic set.
