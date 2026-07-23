# Task-slug review resolution

The first terminal-version heuristic was not accepted. Its provisional no-tools review identified
`SLUG-G01` and `SLUG-G02`, and the dispatch itself lacked a pre-bound JSON contract, so it is retained
only as gap discovery rather than final provenance.

Resolution:

- Replace all shape-only deletion with the controlled adjacent fragment
  `revtag-v<digits><optional letters>`.
- Reject malformed or repeated `revtag` fragments.
- Remove the declared revision before stopword/numeric filtering, de-duplication, and the eight-term
  bound.
- Preserve every undeclared `v8`, `v2ray`, or internal `v8a` term.
- Keep the original task slug unchanged in report, manifest, and DB publication.
- Add positive and negative regression cases for empty lifecycle input, malformed metadata, business
  version terms, internal architecture phases, and the eight-term boundary.

The final review was re-dispatched from a validated canonical `self-contained-no-tools` JSON contract;
its result is recorded in `task-slug-review-result.json`.
