# V10G local RV64 SERIALIZE-G1 current-design closure contract

## Classification and binding

- Slice: architecture-debt closure diagnostic.
- Branch / Git HEAD: `ai` / `af027d1bce085bace474b748dcd89113145f8772`.
- Live RV64 RTL source-set: `sha256:5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a`.
- Last fully replayed architecture source-set:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`.
- Exact source delta: only `npc/rv64/vsrc/sim/NpcSimTop.sv`; all
  synthesizable core, control, memory and writeback RTL inputs are byte-identical.
- Promotion state remains `architecture_freeze=GAP`, `ppa=UNQUALIFIED`,
  `promotion_eligible=false` until this contract is independently reviewed.

## Debt contract

`SERIALIZE-G1` covers the queue-head accepted SYSTEM/trap/exit owner lifecycle:

1. capture one lane0/lane1 owner and payload;
2. stop younger dispatch without losing the accepted owner;
3. drain older ROB/issue/memory owners;
4. authorize C0 only from the exact accepted memory-owner terminal condition;
5. apply the SYSTEM, architectural-trap or simulation-exit effect once;
6. clear holder/stop state on the edge and emit no repeated raw event at C1/C2.

The current product configuration uses queue-head serialization. Closing the
debt requires a normative ledger decision plus current-design evidence for
SYSTEM, architectural trap and simulation exit. Sticky terminal outputs or
host-side report suppression cannot prove raw-event exactly-once behavior.

## Hypotheses

- Primary: the live source-set delta is simulation-diagnostic-only and absent
  from the A3/A4 elaborated logic; current-design directed replay can therefore
  rebind the closed architecture records without a full system rerun, while
  A3 remains system-transaction evidence for the already elaborated design.
- Competing: a current SYSTEM/trap/exit cycle, assertion-disabled build, raw
  terminal-event path, or ledger closure requirement is not covered; in that
  case `SERIALIZE-G1` remains `P1 OPEN` with the precise missing owner/cycle
  observation.

## Experiment budget

1. Reconstruct both RTL source maps and fail unless the sole delta is
   `NpcSimTop.sv`.
2. Verify the frozen A3/A4 elaboration comparison, configuration, terminal
   transaction and post-hash evidence. Preserve A3 original FAIL and A4 TERM.
3. Replay the canonical current-design directed architecture/functional
   records needed by the debt ledger against the exact live source-set.
4. Independently inspect the current SYSTEM/trap/exit production topology,
   assertion-on/off focused evidence, compile-success RTL variants and raw
   C0/C1/C2 event scoreboard.
5. Close `SERIALIZE-G1` only if no missing cycle or false-green counterexample
   remains. Otherwise record a bounded GAP and the next falsifiable test.

No synthesis, STA, full-system rerun or PPA search belongs to this slice unless
the corresponding elaborated-RTL, simulator/device-model, configuration or
frozen-input trigger is actually observed.

## Non-claims

- A3 checker replay does not qualify architecture or PPA.
- Source normalization does not make two source hashes equal.
- Passing assertions do not substitute for assertion-disabled production
  behavior.
- No terminal-event deduplication or weakened assertion is permitted.

