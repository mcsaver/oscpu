# RV64 V14D P1 direct active-cone current rebind

- primary classification: `architecture`
- production RTL intent: read-only; no semantic modification
- current design-id target: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
- gates: `CONTROL-EVENT-G1`, `MIQ-FLUSH-G1`, `STORE-BRESP-G1`
- PPA: blocked until full Section13/arch-stable closure

## Evidence strategy

1. `MIQ-FLUSH-G1`: consume the already current-dynamic V14B focused MIQ log, current 146-file source binding and three compile-success MIQ mutations. Do not rerun the same current cohort.
2. `CONTROL-EVENT-G1`: rerun V9O C0/C1 focused/config matrix and 11 mutations plus V9R SQ-retry/holder matrix and five mutations because `OooLoadQueue.v`/`OooMemAxiBridge.v` are inside the direct active cone.
3. `STORE-BRESP-G1`: rerun V9N STORE/AMO next-edge owner residency with two mutations and V13R multi-cycle B holder/exact retirement with three mutations. This directly covers the gate contract without running the unrelated V8V OOO-3 aggregate.

Every dynamic suite must bind the current full-RTL design-id, preserve source pre/post identity, retain normalized logs only, delete transient compiled images, keep assertions enabled and reject compile-success RTL variants by their exact testbench marker. Canonical architecture/debt/historical ledgers remain read-only.

## Competing hypotheses

- H1: all three gates remain semantically valid under the current five-file RTL delta and can receive task-local `CURRENT_DYNAMIC_PASS` receipts.
- H2: CONTROL-EVENT SQ-query or registered AXI owner behavior drifted with `OooMemAxiBridge.v`; V9R positive or mutation oracles will fail.
- H3: STORE-BRESP owner/terminal/retirement behavior drifted with `OooStoreQueue.v` or Bridge; V9N/V13R will expose the first failing holder edge or marker.
- H4: the earlier V14B memory suite is sufficient only for MEM-ISSUE and its MIQ rows cannot be separately attributed; the exact debt IDs/log hashes must fail closed rather than be relabeled.
