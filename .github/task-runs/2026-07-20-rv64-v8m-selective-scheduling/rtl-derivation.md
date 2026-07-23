# v8m selective-scheduling derivation

## Root cause

The architecture checker currently recognizes this expression in
`OooIntBackend.v`:

```verilog
mem_issue_res_valid_q ? 1'b0 : ...
```

inside `iq_issue0_ready_w` and concludes that a single reservation freezes all
raw issue.  That conclusion treats the logical IQ output named `issue0` as the
whole issue machine.  In the current implementation it denotes the Universal
terminal only.

## Registered-owner path

```text
mem_issue_res_valid_q
  -> OooDispatchBackend.universal_owner_present_i
  -> OooIntIssueQueue.universal_owner_present_i
  -> OooIntIssueSelect8.universal_owner_present_i
       owner=1: issue0_onehot=0
                issue1_onehot=first_alu_onehot
  -> OooIntIssueQueue.issue1_valid_o
  -> OooIntBackend.issue1_valid_w
  -> issue1_fire_w (issue1_ready_w has no reservation dependency)
```

Thus the Universal terminal's local `ready=0` is required to preserve exclusive
ownership, while the independent ALU terminal remains available.  The correct
static property is the conjunction of the full owner/steering/readiness chain,
not the absence of that local ternary.

## Missing proof before v8m

The standalone IQ test already drives `universal_owner_present_i=1` and proves a
sole ALU drains through terminal 1.  It does not prove that a production memory
uop establishes the registered owner, that the owner survives real memory
backpressure, or that dependent and same-resource work remain while younger
independent work advances.  No design-bound `selective_scheduling` evidence
record currently exists, so OOO-2 must remain RED until those gaps are closed.

## Intended implementation footprint

No functional RTL edit is planned unless the production-path directed test
finds a real defect.  Expected changes are limited to the architecture checker
and its negative tests, a focused backend test branch, a reproducible evidence
runner/mutator, a durable make target, the OOO-2 evidence manifest, and task-run
documentation.  Any discovered RTL defect reopens this derivation and prevents
promotion until separately repaired and reviewed.

