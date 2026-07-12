.entries = (
  (
    .entries
    | map(select(
        .path != ".github/memory/project-status.md" and
        .path != ".github/memory/modules/npc.md" and
        .path != ".github/memory/known-issues.md" and
        (.path | startswith(".github/task-runs/2026-07-12-rv64-ifu-access-g1") | not)
      ))
  ) + $selected[0]
  | sort_by(.path)
)
| .updated_at = "2026-07-13T00:55:00+08:00"
