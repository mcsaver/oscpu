# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4
- `task_slug`: 2026-07-08-iverilog14-tb-gate-restore
- `profile`: difftest
- `asset_count`: 9
- `total_size_bytes`: 15508

## 证据资产

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/abstract-machine-contract.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 7
- `sha256`: 9018983feab116e6b0c2da111dd09836c1017d250a7041c2318d4492d835408d
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=277 bytes; lines=7; PASS=12; tail=[abstract-machine] contract PASS abstract-machine/Makefile PASS abstract-machine/am/include/am.h PASS abstract-machine/am/include/amdev.h PASS abstract-machine/scripts/riscv32-nemu.mk PASS abstract-machine/scripts/riscv32-npc.mk PASS .github/memory/modules/...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/difftest-contract.log

- `kind`: log
- `size_bytes`: 156
- `line_count`: 5
- `sha256`: 6a44b7bccd144459c2b227368465b564133be84d945c999fbcfad07a9e9f0fe7
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=156 bytes; lines=5; PASS=8; tail=[difftest] contract PASS nemu/tools/spike-diff/Makefile PASS npc/sim/Makefile PASS .github/memory/modules/difftest.md PASS .github/agents/difftest.agent.md

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/nemu-add-smoke.log

- `kind`: log
- `size_bytes`: 201
- `line_count`: 2
- `sha256`: c33f8c24a70e09ff71763b65509d013e9b774c08ed9adb6ad775b6e85e221acc
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=201 bytes; lines=2; SKIP=2; tail=[nemu] SKIP: nemu/.config isa=riscv64 target=NATIVE_ELF，不是 CONFIG_TARGET_AM=y [nemu] next: 需要 AM smoke 时先切 riscv32-am_defconfig/riscv64-am_defconfig，或设置 AGENT_E2E_FORCE_SMOKE=1

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/nemu-config-probe.log

- `kind`: log
- `size_bytes`: 255
- `line_count`: 8
- `sha256`: 645a9655f6527b8ae4410a96a9aa1fa324afadfae1733fdbf91967ade493c9a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=255 bytes; lines=8; PASS=12; tail=[nemu] config summary nemu/.config isa=riscv64 target=NATIVE_ELF PASS nemu/Kconfig PASS nemu/Makefile PASS nemu/configs/riscv32-am_defconfig PASS nemu/configs/riscv64-am_defconfig PASS nemu/configs/riscv64-linux_defconfig PASS nemu/src/device/filelist.mk

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 92
- `sha256`: 3d32a4d0a2aa34f0edf7030c55c46d4d72f920271cff5d1bcbb5590fb44db0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 168}
- `summary`: log evidence; size=4823 bytes; lines=92; PASS=168; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2637
- `line_count`: 41
- `sha256`: 689c1d0186568a32558ef4cad25d98fa6641cdbb98eaaa95060a6de90dd86373
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2637 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1586
- `line_count`: 7
- `sha256`: fe783c8d0ee8e5addf62b0ca17b68704b0b1a2ec198b0430d1197558a2a71dfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 14, "SKIP": 4}
- `summary`: tsv evidence; size=1586 bytes; lines=7; SKIP=4; PASS=14; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS a...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/run-manifest.json

- `kind`: json
- `size_bytes`: 5083
- `line_count`: 131
- `sha256`: 74bf896c034b1a67536627d6425c9f54a3ce0b24751708c520adc097aa2139c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:40:41+00:00
- `markers`: {"PASS": 16, "SKIP": 8}
- `summary`: json evidence; size=5083 bytes; lines=131; SKIP=8; PASS=16; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-4/dispatch-log.md", "evidence_dir": ".github/task-...
