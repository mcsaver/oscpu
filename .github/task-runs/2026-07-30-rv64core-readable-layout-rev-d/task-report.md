# RV64core interactive datasheet Rev D readability refresh

- Date: 2026-07-30
- Scope: `docs/rv64core/study/**`
- Production RTL mutation: none
- Task result: PASS within the static documentation/elaboration scope
- Browser dynamic rendering: GAP, intentionally not claimed

## Root cause

The screenshot-critical transaction cards used explicit 8–10 px labels and
11 px payload text.  Several other dense regions used similarly small
one-off values, so browser zoom was the only practical way to read the page.
The stylesheet also referenced `--ink-soft`, `--teal` and `--teal-dark`
without defining them, weakening intended emphasis and border styling.

## Implemented result

- Added one coherent typography scale instead of isolated pixel fixes.
  The delivered page defaults to the large profile: 16 px body text and
  12 px captions.  The standard, large and extra-large profiles scale the
  transaction cards, tables, Self-check answers and WaveDrom labels together.
- Added an accessible top-right font control.  It cycles
  `standard -> large -> xlarge`, updates its ARIA label and live status, and
  persists the choice in local storage with a fail-safe fallback.
- Retained the font control at narrow breakpoints after independent review
  found that hiding it below 640 px made the three-scale feature unreachable.
- Reworked long transaction pages as a top-to-bottom reading sequence with a
  reading key, `PHASE NN / TOTAL`, four explicit data/state fields per phase,
  larger handoff connectors and separately identified side paths.
- Increased the document width and responsive collapse breakpoint, while
  retaining local scrolling for genuinely wide tables and hierarchy diagrams.
- Defined the three missing color variables and added a fail-closed
  readability audit for undefined variables, explicit values below 11 px and
  a hidden font-scale control.
- Refreshed the elaborated topology from the current RV64 source before
  rebuilding the offline single-file document.  No production RTL was edited.

## Final artifact

- HTML: `docs/rv64core/study/index.html`
- Revision: `Rev. D`
- Size: 1,073,714 bytes
- SHA-256:
  `80ed008e3e00ac512d00962acbd7ad35448745f98417f67e114f9f488f8d7331`
- Source fingerprint:
  `80bd2b13543597e18091bdb387ff4d75793828de0368a260e23e0181a20a13cd`
- NpcTop elaboration SHA-256:
  `9eced7569f815ebf763de2a1647d1ccc264ea340f28826f72f600aff4cb79695`
- Static inventory: 150 files, 136 modules, 195 instances, 9 transactions,
  38 WaveDrom diagrams, 58 primary phases, 2 side paths, 240 explicit data
  fields, 975 Self-check answer slots, 1,219 sequential targets and 0 external
  resources.

## Validation boundary

The task proves current-source elaboration freshness, exact embedded CSS/JS,
the static responsive/readability contracts, offline single-file integrity and
fail-closed negative tests.  It does not claim pixel-level browser rendering,
real click behavior, RTL testbench/DiffTest, synthesis, STA or PPA PASS.

The scoped strict guard saw four scoped path groups, required no e2e profile
and passed.  The full-worktree strict guard saw 42 changed path groups and
failed only because unrelated concurrent V11I RTL/testbench/evidence paths
require fresh `npc-dev` evidence.  Running that profile would exceed this
docs-only task and could interfere with the concurrent RTL task, so the global
result remains an explicit GAP rather than being relabelled as this task's
failure or as an RTL/system PASS.
