# V11H local RV64 LoadQueue producer semantic-coverage contract

## Classification

- Primary: `architecture`
- Secondary: `verification`, `tooling/workflow`,
  architecture-evidence publication
- Production RTL semantic delta: H2 confirmed; one stateful
  `terminal_seen_q[]` holder was added
- PPA promotion: prohibited; the whole architecture remains RED

## RV64 RTL scope

- Module: `OooLoadQueue`
- Stateful holder: `valid_q[]`, full `producer_id_q[]` and exact-terminal
  history `terminal_seen_q[]`
- Transactions: dual allocation, issue/launch, final-PA query,
  allow/replay, response/completion, normal or killed terminal, ROB release,
  selective/global recovery and killed-tombstone drain
- Current ledger unit: `load-queue-producers`

## Falsifiable hypotheses

- H1: production `OooLoadQueue.v` satisfies the existing retire-resident
  full-ProducerId lifecycle, while current evidence lacks a source-bound,
  assertion-independent raw-Q oracle.
- H2: a legal interface sequence exposes a production lifecycle or
  full-ProducerId defect.
- H3: the V8V nine-variant suite already proves raw identity, knownness and
  lifecycle sensitivity strongly enough to close the current semantic unit.

## Minimum discriminating experiment

Use a stimulus-owned four-entry edge model that does not derive expected state
from DUT snoop or mask outputs. Scan every raw `valid_q[]` and
`producer_id_q[]` after each directed edge. Run generation widths 1 and 4 with
`OOO_ASSERT` both enabled and disabled. Run compile-success RTL variants with
`OOO_ASSERT` disabled and require the independent testbench oracle to reject
each affected profile.

The holder RTL must also carry an assertion-enabled raw-Q contract:
`valid_q[i]` implies the complete `producer_id_q[i]` is known. A directed
unknown-generation probe must fail at `[V11H-LQ-PID-KNOWN]`; legal ordinary
LQ and parent-backend regression must not observe that marker.

The pre-fix legal-interface discriminator failed with
`count=1/live=1/killed=1` after normal terminal followed by recovery. H2 is
therefore selected. The minimum architecture repair records exact normal
terminal history, prevents issue/query/response after that terminal, and
clears rather than tombstones a terminal-seen entry on recovery. Duplicate
terminal events remain an assertion failure; no event deduplication is used.

The local/system boundary is a checked schema, not an ambiguous status
string: local `load-queue-producers` closure does not require a system rerun,
while system promotion does require one and that rerun has not executed.
Negative checker tests must reject omission or weakening of those fields.

## Cost and single-flight

- Expected focused runtime: minutes, not hours
- Windows-to-WSL engineering lane: one owner at a time
- Full Linux/A4 system run: `NOT_RUN`
- System-evidence boundary: the production core semantic delta now satisfies
  the user's full-rerun trigger. A new system run is required before
  system-level promotion, but this focused round does not auto-start that
  high-cost run.
