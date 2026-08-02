# V13Z delivery guard result

- Command: `scripts/agent-e2e.sh --guard --guard-mode strict --paths-file .github/runtime-artifacts/agent-flow/rv64-v13z-di1-current-rebind-v1/paths.log --evidence-dir .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence`
- Result: `GAP`, rc=1.
- Exact marker: `[agent-e2e-guard] FAIL missing_evidence profile=npc-dev` for the four DI-1
  architecture/evidence tool and test paths.
- Scoped exemption: this architecture slice already ran fresh current-design assert/release frontend and
  Bridge 4/4, nine activated compile-success RTL source mutations 9/9, six adjacent `OOO_ASSERT` TB 6/6,
  and the complete affected evidence/architecture unit suite. Running the wider `npc-dev` profile would
  repeat unrelated gates without adding a DI-1 discriminator. The exemption does not convert the strict
  guard to PASS and does not authorize canonical architecture, CPI or PPA promotion.
- Memory writeback: `.github/memory/project-status.md` updated to 9716 bytes and
  `.github/memory/modules/npc.md` to 10619 bytes through whole-document `update-stored`.
- DB audit: `audit-db-first` remained global GAP because six older task-run retained documents are absent
  from stored state and backup hashes are already divergent for `known-issues.md`; the two intentionally
  updated memory documents also differ from the older backup snapshot. No unrelated DB/archive repair was
  performed in this DI-1 slice.
