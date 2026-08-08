# Case Selection and Claim Coding Protocol

## 1. Scope and snapshot

- Evidence window: 2026-04-01 through 2026-08-07.
- Repository HEAD observed during the major revision:
  `ac877a1e857154d70744fd0fd7e994309f2e2ee8`.
- Claim map: `docs/research-paper/claim-evidence-map.tsv`.
- Frozen claim-map SHA-256 used by the paper:
  `45f77e90a75ec126c88b46291134090cdf3b0e88321d470cf09d203fb40d8ec7`.
- The map contains 30 claim units. It is a purposive coded set, not a random
  or exhaustive sample of every dated task-run directory.

The read-only inventory reports 8, 137, 1246, and 756 top-level dated
workflow-event directories for April through July. A directory is not an
independent task, successful run, or experimental replicate.

## 2. Analysis unit

A **task episode** is a continuous engineering event with:

1. one explicit objective;
2. at least one candidate or object under judgment;
3. one recoverable set of gates or acceptance conditions; and
4. one recoverable terminal decision: accept, reject, rollback, `GAP`,
   `UNQUALIFIED`, interrupted, or missing.

One episode may span multiple directories. One directory may contain only a
workflow node. One episode may yield a bounded weak claim and a contradicted
strong claim; A3/C22-C23 is the canonical example.

## 3. Inclusion criteria

A claim enters the coded set only when all of the following hold:

1. It can be written as an explicit completion or readiness claim.
2. At least one exact source path is recoverable.
3. At least two of design/configuration, command, raw status, or metric are
   recoverable.
4. An acceptance, rejection, rollback, `GAP`, or `UNQUALIFIED` boundary is
   visible.
5. The claim is relevant to at least one registered mismatch class:
   unsupported functionality, local-to-system overclaim, stale/cross-design
   evidence, oracle blindness, unqualified proxy, or incomplete publication.

## 4. Exclusion and deduplication

Exclude:

- progress prose with no raw pointer;
- records that do not distinguish target from reference;
- cross-configuration numbers without a comparable baseline;
- duplicate reports/publications of the same fact; and
- transient logs from which no decision boundary can be recovered.

Duplicate publications are merged into one episode. Different claims from the
same episode remain separate only when their strength or evidence boundary is
different.

## 5. Coding states

- `SUPPORTED`: exact object, source evidence, and boundary support the wording.
- `PARTIALLY_SUPPORTED`: a mechanism or result exists, but strength, denominator,
  identity, or causal attribution is incomplete.
- `OBSERVATIONAL_ONLY`: only coexistence or longitudinal change is supported.
- `CONTRADICTED`: raw evidence directly rejects the strong wording.
- `MISSING`: the current material cannot answer the claim.

Path existence never upgrades a state by itself. A `PASS` token is not
sufficient without identity, configuration, oracle scope, and publication
state.

## 6. Independent review sample

The second, isolated Agent reviewer receives no authority to edit files. The
stratified sample is fixed before review:

`C01, C02, C03, C04, C07, C10, C11, C14, C15, C22, C23, C30`

This is 12/30 claim units (40%). It covers every coding state, all four main
paper cases, identity mismatch, mutation, structural/timing proxy qualification,
and the strongest promotion-boundary counterclaims.

For each row the reviewer must check:

1. state;
2. primary source and raw evidence path;
3. numeric fields and return codes;
4. rollback or rejection decision; and
5. the non-entailment boundary.

Any disagreement on state, number, path, or boundary is blocking. The final
resolution and rationale are written to `independent-claim-review.tsv`.

## 7. Interpretation boundary

The review is performed by an isolated Agent, not a second human coder. It can
detect transcription and evidence-boundary errors, but it does not establish
human inter-rater reliability. The paper therefore reports the procedure and
disagreements, but does not use agreement as evidence that the workflow is
generally effective.
