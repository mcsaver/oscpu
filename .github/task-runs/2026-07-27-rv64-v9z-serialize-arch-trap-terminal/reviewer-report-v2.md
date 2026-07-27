# Reviewer v2 report

RV64 RTL conclusion: the V9Z minimal combinational boundary is `PASS`; the
wider post-fire and overlap scope remains `GAP`.

## Final Boolean boundary

Reviewed path:

```text
OooPendingDrainResolveGate.pending_serialized_mem_terminal_w
  -> drain_complete_o
  -> OooCsrTrapRequestMux.pending_arch_trap_fire_o
```

The final expression is:

```verilog
!(pending_system_i || pending_arch_trap_i) ||
mem_owner_terminalized_i
```

It correctly:

- blocks active-holder/no-transfer architectural-trap fire;
- accepts exact accepted transfer, collector-pending-only, and full idle;
- stays true for unrelated control cycles with neither serialized owner;
- retains the separate ordinary-FENCE
  `!pending_system_fence_i || mem_idle_i` condition.

No register, deduplication state, or collector event filter was added.

## Evidence identity

- Reviewer contract SHA-256:
  `66f6519d35e690f5b93555e2abbed76ffd6c0683a584a452d86f1a29bd1b8ce2`.
- Current design ID:
  `sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`.
- Gate SHA-256:
  `6318e792ebd9bf5fdd27fbe5f8f2bedded83c705d32926ee7e48c6a16d98269f`.
- Trap mux SHA-256:
  `3d1a9e2b712b15c1af7247ba5d4863e23e38e0136af28af837a42acf61a5a6a8`.
- Integration TB SHA-256:
  `7d8f60b80c07e2321fcd0c048f5301a4b1815c08e09806d37256791c10b6f7ef`.

The reviewer matched the gate, mux, `OooControlPlane`,
`OooPendingDispatchArbiter`, `OooStopPendingSequencer`, and
`OooTrapExitEventMux` hashes against the 146-file architecture manifest.

Observed evidence:

- pre-fix RED: drain, arch fire, trap request, and predictor boundary all
  asserted early;
- focused assertion-on: three tests PASS;
- focused assertion-off: gate and gate-to-mux tests PASS;
- compile-success mutations: 4/4 dynamically rejected;
- module: 112/112;
- functional: PASS, official 177/177, AM 59/59, DiffTest mismatch 0;
- architecture: 9/9 GREEN.

The original pre-fix RED log does not bind a pre-fix source hash.  The later
`drop-arch-trap-terminal-term` mutation is a separate reproducible,
hash-bound equivalent negative version and must not be presented as the
original source capture.

## Remaining counterexamples and unknowns

1. The gate-to-mux TB is combinational.  If `pending_arch_trap_i` remains
   high, fire remains high; no clocked observation proves owner clear or
   exactly-once side effects on the next edge.
2. `OooPendingDispatchArbiter.drain_clear_w` produces the expected clear
   request, but the contract did not include
   `OooPendingTrapExitSequencer.v`, so its NBA priority and registered state
   transition were not reviewed.
3. The mux TB permits architectural trap and ECALL fire together while only
   checking architectural payload priority.  IRQ, xRET, CSR, and FENCE
   overlaps lack onehot side-effect, replay, or constructive-unreachability
   evidence.
4. The integration TB drives the reduced scalar; exact transfer versus
   collector-pending-only production remains inherited from the same-design
   backend/collector evidence rather than independently regenerated here.
5. The collector RTL was outside the v2 contract.  Module PASS is indirect
   evidence that its fail-loud behavior was not weakened, not a fresh source
   audit.

## Scope extension request

To close the wider GAP, add these inputs to a versioned contract:

- `OooPendingTrapExitSequencer.v`;
- `OooPendingSystemSequencer.v`;
- `OooControlEventApplySequencer.v`;
- the production `CsrFile.v` path and corresponding testbenches.

Add a clocked gate-to-owner-to-CSR test for next-edge clear, no repeated side
effect without a new capture, and architectural-trap overlap with
ECALL/IRQ/xRET/CSR/FENCE.

Confidence is high for the V9Z combinational fix and its current-design
evidence; confidence is insufficient for post-fire exactly-once and overlap
closure.

The reviewer made no file changes, left no process running, and explicitly
returned the unique Windows-to-WSL command ownership to root.

