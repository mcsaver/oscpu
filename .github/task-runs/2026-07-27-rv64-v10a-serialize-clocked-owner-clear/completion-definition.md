# V10A completion definition

- verified design-id:
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`
- design state: `bounded_slice_pass`
- footprint:
  clocked serialized-owner verification，必要时最小 assertion/RTL correction
- complete when:
  - [x] pre-review confirms the bounded contract and counterexamples
  - [x] clocked arch-trap owner clear and exactly-once CSR/redirect evidence passes
  - [x] ECALL/IRQ/xRET/CSR/FENCE overlap is priority-defined or constructively unreachable
  - [x] compile-success RTL variants are dynamically rejected
  - [x] focused, module, functional and architecture evidence bind one current design-id
  - [x] independent final review resolves implementer/reviewer conflicts
  - [x] task-run, memory, DB/e2e and strict guard are published
- explicit non-completion:
  this slice alone does not close Linux terminal, simulation exit, all seven-kind
  cross-products, architecture-stable freeze, synthesis/STA/power, PPA or the long-term goal.

## Workflow closure

- `npc-dev`：
  `.github/task-runs/2026-07-27-pending-architectural-trap-clocked-owner-exactly-once-revtag-v10a/`，
  bounded recall complete，5/5 nodes PASS，canonical publication complete。
- `agent-system`：
  `.github/task-runs/2026-07-27-pending-architectural-trap-owner-clear-agent-system-revtag-v10a/`，
  bounded recall complete，11/11 nodes PASS，canonical publication complete。
- 当前 V10A task-run 的五份 Markdown 已由
  `archive-markdown --sync-task-run` 同步进 DB；coverage 观测为
  `live_evidence=0`，没有放宽 fail-closed gate。
- `strict-guard.log` 的最终观测为：
  `agent-system=PASS`、`npc-dev=PASS`、`difftest=PASS`、
  `github-index=PASS`、`rv64-linux=FAIL missing_evidence`。
- `rv64-linux` 是显式系统层证据 GAP：既有长时 rootfs 运行没有达到
  17/17 guest checks、natural poweroff、reset-syscon、`GOOD TRAP` 或完整
  terminal transaction。本切片不把该结果重分类为 RTL FAIL 或 Linux PASS，
  V10A bounded verdict 也不依赖该豁免。
