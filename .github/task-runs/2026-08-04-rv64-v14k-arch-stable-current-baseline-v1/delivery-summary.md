# RV64 V14K methodology/config/workflow delivery summary

## Scope and immutable identity

- Scope: local RV64 dual-issue OoO RTL evidence and delivery workflow; production RTL is unchanged.
- RTL design-id: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
  over 146 Verilog/SystemVerilog files.
- Configuration SHA-256:
  - `.config`: `63ecfda4b377430c468116a77efb77345705c3fcf9aca499b641b287cc6da5ce`
  - `auto.conf`: `ed0f2ab770451d3ae640978407f6e2eef1e39ff9dc93a0d3e4f88dabf4b59df4`
  - `autoconf.h`: `ac5cd6496f3501c80b33f0ab4ee1e466805b526475d62a8ec7376b62935be5b9`
- Current historical-defect receipt SHA-256:
  `5b2bd2caebd8f2aa3c3f93f2de51ac24f0f3c8a05bd0ba2e63e8c663f500f343`.

## Tailored public methodology

- The local flow adopts public principles from ratified RISC-V specifications and ACT, Arm AMBA AXI Issue L,
  OpenTitan DV/signoff/DVSim, lowRISC style, OpenHW CORE-V, and public ISO/IEC/IEEE lifecycle summaries.
- This is a project-specific tailoring of public material. It does not claim vendor-internal process access,
  external certification, OpenTitan V3 signoff, or complete AXI/RISC-V compliance from bounded evidence.
- Review and analysis are zero-gate task classes. Development runs only affected-domain evidence. A deterministic
  delivery point runs C-selected integrated gates once, followed by an independent counterexample-oriented review.
- Evidence promotion is bound to design/configuration/tool/input identity. Original FAIL records remain immutable;
  replay PASS is a separate receipt. Negative RTL versions and fail-closed checkers are retained as contracts,
  while regenerated VVP images, mutation RTL and compiler sidefiles are removed after their results are captured.

## Configuration and workflow result

- `scripts/agent-flow.c` maps full production RTL, build controls, schemas, current receipts, ledgers, testbenches and
  retained V14G logs to the affected gates. Dependency normalization always places
  `rv64-architecture-debt-current` before `rv64-historical-defect-current`, including explicit gate selection.
- Candidate gate set: `rv64-soc-delivery-gates`, `rv64-architecture-debt-current`,
  `rv64-historical-defect-current`, and `flow-self-test`. Each candidate takes approximately 12 seconds. The
  authoritative final invocation/result is published in
  `.github/task-runs/2026-08-03-rv64-v14k-arch-stable-current-baseline-v1/agent-flow-result.md`; the UTC archive date
  and this local-date focused-evidence directory intentionally differ.
- Focused verification completed: historical receipt 29/29 tests, backfill 4/4, ARCH_STABLE 54/54, SoC delivery
  configuration 1 positive + 13 negative tests, and exit replay 2/2 baselines + 7/7 compile-success mutations.
- Independent review preserved two GAP rounds, converted them into tests and implementation fixes, then concluded
  PASS after exact compile/simulation argv and cross-scratch mutation-source rejection were demonstrated.

## Explicit non-promotions and audit gaps

- No full-system rerun, synthesis or STA was executed, and no PPA result was promoted.
- Historical-defect current binding is PASS only for its stated scope. `whole_architecture=RED` and
  `ppa=UNPROMOTED` remain authoritative.
- Explicit-path strict guard remained FAIL only because it requested broad `agent-system` and `npc-dev` profiles.
  They are task-scoped exemptions here: production RTL is unchanged and more precise methodology, configuration,
  flow, current-design and independent-review evidence already ran. The FAIL is preserved and is not rewritten as
  PASS; the exemption does not apply to later RTL/elaboration/simulator/PPA semantic changes.
- DB-first audit still reports six missing stored documents from two older 2026-08-01 task-runs plus backup hash
  mismatch for pre-existing `known-issues.md` and `modules/agent-system.md`. The two V14K-owned memory documents and
  their backups are synchronized; unrelated historical records were not rewritten during this task.

## Durable evidence pointers

- `npc/rv64/eval/ppa/evidence/historical-defect-current.json`
- `npc/rv64/design/arch/historical-defect-backfill-ledger.json`
- `.github/instructions/rv64-ppa-optimization-workflow.instructions.md`
- `.github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/dispatch-log.md`
- `.github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/evidence/historical-exit-current/summary.json`
