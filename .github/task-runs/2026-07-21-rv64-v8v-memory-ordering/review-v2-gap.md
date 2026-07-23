# OOO-3 independent RTL review v2

- contract: `subagent-contracts/v8v-ooo3-final-review-v2.json`
- contract SHA-256: `55117ebea8a696ca40013c85902a4286e366e7ccb1ea2f90ed802c1e75ed4928`
- verdict: `GAP (P1)`

## Counterexample

1. A normal load is resident in ROB/IQ/LQ but has not launched.
2. `checkpoint_restore_i=1` while `flush_i=0`.
3. LQ, MIQ, reservation and retry state recover, while the Dispatch backend and ROB/IQ previously observed only
   `flush_i`.
4. The surviving ROB/IQ load can be selected again but no longer has an LQ entry, so `lq_issue*_open_w=0`
   permanently prevents completion and retirement.

The launched form has the same owner split: transport/LQ tombstone state drains while a live ROB owner remains with
no completion path.  The prior focused test injected exact bridge drops and reset immediately after LQ drain, so it
did not test ROB/IQ continuation.

## Required closure

- define one recovery domain for ROB/IQ/rename/PRF/FP and every memory owner;
- test both unlaunched and launched load/store lifecycles with `flush_i=0`;
- after exact terminal drain, redispatch and retire without reset;
- make source gates and compile-success mutations reject independent cuts of the recovery domain;
- keep overall architecture RED and PPA UNQUALIFIED until their separate gates close.

## Evidence boundary

The reviewed 11 OOO-3 metrics, 9 LQ mutations and fixed source/provenance hashes prove their local properties, but
the prior `ghost_after_flush=0` basis did not cover a surviving ROB/IQ owner.  No same-design synthesis, STA or power
evidence was present.  The review was read-only and used only contract-authorized RTL/spec/TB/evidence inputs.
