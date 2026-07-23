# v8m OOO-2 selective-scheduling atomic contract

## Scope and claim boundary

This task may promote only architecture gate `OOO-2 selective_scheduling` for the
current complete RV64 RTL source set.  It does not promote DI-1..DI-5, OOO-1,
OOO-3, OOO-4, the architecture-wide result, or any PPA result.  PPA work remains
out of scope while the architecture inventory is RED.

The task starts from a checker/root-cause mismatch, not from an assumption that
the RTL is defective.  `iq_issue0_ready_w == 0` while
`mem_issue_res_valid_q == 1` is the local admission rule for the occupied
Universal terminal.  It is not a global issue freeze if an independent
ALU-capable resident can still use the physical ALU terminal.

## Production dataflow contract

When a registered memory reservation owns the Universal terminal, all of the
following links are required:

1. `OooIntBackend.mem_issue_res_valid_q` drives
   `OooDispatchBackend.universal_owner_present_i`.
2. `OooDispatchBackend` forwards that registered owner fact to
   `OooIntIssueQueue.universal_owner_present_i`.
3. `OooIntIssueQueue` forwards the owner fact to `OooIntIssueSelect8`, masks
   only `issue0_valid_o`, and does not mask `issue1_valid_o` with the owner.
4. `OooIntIssueSelect8` selects `first_alu_onehot_w` / `first_alu_valid_w` for
   issue terminal 1 while the owner is present.
5. `OooIntBackend.issue1_ready_w` remains independent of
   `mem_issue_res_valid_q`; ordinary global recovery/WB-capacity gates remain
   legal.
6. The Universal reservation remains exclusive: no raw issue0 owner may overlap
   it, and a second memory-class uop must wait for the same resource.

The source gate must fail closed if any link is absent.  Comment text is not
evidence.  The existing prohibition on an arbitrary `older_valid_seen_r` memory
block remains unchanged.

## Directed behavior contract

A production-path backend test must establish `mem_issue_res_valid_q` from a
real dispatched memory uop while `mem_req_ready=0`; forcing the owner bit is not
accepted.  While that owner remains resident, the test must create all three
resident classes below:

- an older ALU uop whose source depends on the held load and is therefore not
  ready;
- a ready memory uop that competes for the occupied Universal resource;
- a younger ready independent ALU uop.

With ordinary recovery/WB gates open, the younger independent uop must be
selected and fire through issue terminal 1.  The dependent and same-resource
uops must remain resident, the reservation must remain valid, issue terminal 0
must remain exclusive, and the independent ALU must complete exactly once.
The observed fire must match the intended PC and full ProducerId; a different
uop, or a uop canceled by flush/kill/recovery, cannot satisfy the case.  A
separate owner-resident case must show that the oldest ready independent ALU is
not suppressed merely because an older-valid item or reservation exists.
The test reports these machine metrics:

- `blocked_dependents_only=true`;
- `younger_independent_issued=true`;
- `different_resource_issued=true`;
- `global_freeze_cycles=0`, where a freeze cycle is an observed cycle with the
  owner resident, a ready independent ALU presented to terminal 1, all legal
  terminal-1 global gates open, but no terminal-1 fire.

The existing standalone IQ registered-owner/sole-ALU case remains required as a
leaf-level proof.  Both release and `OOO_ASSERT` profiles must pass.

## Negative sensitivity

Compile-success mutations must demonstrate that the checks are not satisfied by
mere naming.  At minimum, the suite must detect removal or corruption of:

- backend owner binding;
- dispatch-to-IQ owner forwarding;
- selector owner-to-first-ALU routing;
- IQ terminal-1 validity independence;
- backend terminal-1 readiness independence.

At least one runtime mutation must make a real owner block terminal 1 and must
be rejected by the directed backend test.  Mutation sources live only in a
caller-owned temporary directory, and canonical source hashes must be identical
before and after the run.

## Evidence and durable entry point

The evidence producer must write a workspace-relative log containing exactly
one `[ARCH-GATE] selective_scheduling PASS` marker, bind its SHA-256 in
`npc/rv64/eval/ppa/evidence/architecture-current.json`, and bind that manifest
to the complete current RTL source-set digest used by
`architecture_hard_gates.py`.  The producer atomically merges the proven
`selective_scheduling` record and preserves existing records with the same
complete RTL design binding and schema.  Missing or stale records remain RED;
separately proven OOO-1 and DI-4 records may remain GREEN without broadening
OOO-2.

A stable `make -C npc/rv64 check-selective-scheduling` entry point must rerun the
focused release/assert tests, static checker self-tests, mutations, evidence
generation, and the architecture inventory.  Success requires OOO-2 GREEN,
permits only independently proven OOO-1 and DI-4 to remain GREEN, and keeps
architecture `OVERALL: RED` until the remaining clauses are independently
closed.
