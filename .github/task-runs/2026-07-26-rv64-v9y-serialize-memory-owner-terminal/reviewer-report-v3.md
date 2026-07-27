# V9Y corrected-RTL independent review

## Verdict

`GAP` solely because the acceptance-mutation summary predated the final
testbench edit.

Object/configuration: `OooMemOwnerTerminalCollector.ingress_accept_o`,
`OooIntBackend.mem_owner_terminalized_o`, edge-old/current-edge/edge-new, and
`OOO_ASSERT=0/1`.

## RTL review

Both V2 blockers are closed in the current source:

- `ingress_accept_o` directly exports the collector's live, kind, epoch,
  duplicate, pending, and same-edge dequeue/re-enqueue validation result.
  `OooIntBackend` builds `mem_terminal_accept_mask_w` per lane; raw ingress no
  longer enters `v9y_terminal_transfer_mask_w`.
- The complete holder census, phase predicate, and sole assignment to
  `mem_owner_terminalized_o` are outside `OOO_ASSERT`. The macro now guards
  only shadow and fail-loud checks.

The reviewer confirmed:

- active/no-transfer blocks;
- exact accepted transfer and exact STORE release may terminalize the last
  holder on the current edge;
- collector-pending-only and full-idle permit progress;
- wrong-epoch and same-token duplicate raw ingress have acceptance zero and
  keep an active holder unterminated;
- SD and FSD exact SQ release pass in assertion-enabled and
  assertion-disabled base tests;
- the scalar propagates unchanged through the backend/core/control hierarchy;
- CSR and non-CSR consume it, while ordinary FENCE retains full
  `mem_idle_i`.

Current design ID:
`sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`.
Module 111/111, functional 111/111 + 177/177 + 59/59 with zero DiffTest
mismatches, and architecture 9/9 are current-design PASS.

## Evidence blocker at review time

The then-current acceptance-mutation summary recorded an older
`tb_ooo_int_backend.sv` SHA because the SD/FSD observation had been added
after the mutation run. All three mutations were rejected, but the summary
could not yet prove current-TB provenance. A fresh mutation run and bounded
hash review were requested.

The review did not close pending architectural trap, seven-kind serialized
exactly-once completion/retirement, `SERIALIZE-G1`, architecture-stable,
Linux flag-on, or PPA.

Contract SHA-256:
`f355bb9b617bbd2786d284e07b6f7614c53aba25347237b7be24891b14c427f0`.
The reviewer modified no file, left no process, and returned WSL command
ownership.
