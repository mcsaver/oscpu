# V9C INSTRET-G1 task report

## Implementer checkpoint

The local RV64 production RTL already implements the required single-source retirement path, so this slice makes no
production RTL change.  It closes the missing program-level and source-variant evidence:

- `tb_ooo_sv39_boot` proves two final exceptional lanes each add zero, one MRET, six SRET and one SFENCE.VMA each
  add exactly one, lane 1 is suppressed for every control pseudo-commit, and CsrFile applies 1052 prior-edge counts;
- `tb_ooo_commit_output_mux`, `tb_ooo_alu_core_slice` and `tb_csr_file` remain PASS;
- the same canonical command dynamically derives and passes the current 109/109 module inventory, and the evidence
  JSON binds every module log path and SHA-256 rather than trusting the summary count alone;
- three reconstructed current-source RTL variants compile successfully and are then dynamically rejected:
  exception filtering removed, final lane replaced by pre-mux lane 0, and CsrFile rewired to core-local count;
- the evidence builder and architecture-stable debt validator bind the exact current design, sources, logs, event
  inventory, canonical command and claim boundary.

Canonical command: `make -C npc/rv64 check-instret-retirement`.

## Current claim

`INSTRET-G1=CLOSED` for
`design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.  The refreshed
architecture audit remains GREEN for its nine directed gates, while the full-core architecture-stable audit remains
an honest GAP with 45 blockers.  This does not make the full core arch-stable: other P0/P1 debts, census,
same-design functional aggregate and freeze inputs remain unresolved.  `ppa=UNQUALIFIED` and
`promotion_eligible=false`.

## Reviewer checkpoint

The hash-bound self-contained no-tools review returned `VERDICT=PASS` with no P0/P1 finding.  Its three P2 residuals
are retained in `review-summary.md`: explicit program-level lane-1 exception non-vacuity, continued clarity of the
prior-edge sampling model, and the local evidence-provenance boundary of hash binding.  None expands the present
claim to WFI, program-level FENCE.I, inhibit switching, software `minstret` writes/overflow, full-core stability or
formal PPA.

## Workflow and retained-memory checkpoint

- The first `npc-dev` forward run,
  `.github/task-runs/2026-07-21-rv64-instret-retirement-closure-revtag-v9c/`, is intentionally retained as a
  blocked ordering counterexample.  Its five profile nodes passed, but startup recall correctly rejected the four
  task terms because no independent current non-history focus matched all four; an old task-run was not allowed to
  prove itself.
- The stable RV64 INSTRET facts were then published through `github_index_db.py update-stored` to DB-owned
  `project-status` and `modules/npc` memory.  The stable ordering rule was published to `modules/agent-system`:
  business evidence first, DB-owned module memory second, matching task-specific e2e third, strict guard last.
  The task-local updater is idempotent and its second execution reported all three documents unchanged.
- The exact positive CLI probe `brief "rv64 instret retirement" --profile npc-dev --focus-scope non-history`
  returned `ok=true`, `recall_status=complete` and selected the current `modules/npc` chunk.  The extra unmatched
  `closure` term remains a deliberate negative probe rather than being hidden or special-cased.
- Completed publications: `npc-dev` 5/5 at
  `.github/task-runs/2026-07-21-rv64-instret-retirement-revtag-v9c/`, final `agent-system` 10/10 at
  `.github/task-runs/2026-07-21-rtl-task-contract-revtag-v9d/`, and the post-snapshot `github-index` 1/1 at
  `.github/task-runs/2026-07-21-stored-memory-instret-retirement-revtag-v9d/`.
- `--validate-all-profiles` passed.  `snapshot-stored` reported 6782 documents; DB-first audit reported
  final `candidates=6898 stored=6940 materialized=6691 shims=25`, and Markdown coverage reported
  `active_md=9115 db_owned=6898 shims=25 live_evidence=0 live_rules=2`.

## Closeout gate

- `scripts/agent-e2e.sh --guard --guard-mode strict` passed all three inferred profiles against 1901 changed paths:
  `agent-system`, `npc-dev` and `github-index`.  The first strict attempt is retained as an ordering check: it
  correctly required a newer `agent-system` publication after the final module-memory update; the v9d publication
  closed that timing dependency without an exemption.
