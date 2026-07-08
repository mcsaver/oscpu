# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-fp-arith-macro-decision-yosys-sta
- `task_slug`: agent-e2e-yosys-sta
- `profile`: yosys-sta
- `asset_count`: 8
- `total_size_bytes`: 14480

## 证据资产

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/npc-sim-contract.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 13
- `sha256`: 07df703bcae3b6b323fa0a88643baaff9021c04b3682a9afa5d9f100a115bfd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=404 bytes; lines=13; PASS=22; tail=[npc] sim contract PASS npc/sim/Makefile PASS npc/sim/backends/single.mk PASS npc/sim/backends/rv64.mk PASS npc/sim/backends/soc.mk PASS npc/single/Makefile PASS npc/soc/Makefile PASS npc/rv64/Makefile PASS .github/e2e/profiles/npc-dev.tsv PASS .github/e2e/...

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/npc-single-contract.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 5
- `sha256`: 9d998f2fba2831128acf902dd6130d042f60ab2fa22c87422dc9e39dbf93c773
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=142 bytes; lines=5; PASS=8; tail=[npc-single] contract PASS npc/single/Makefile PASS npc/single/Kconfig PASS npc/single/vsrc/filelist.mk PASS npc/single/csrc/cpu/cpu-exec.cpp

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 92
- `sha256`: 3d32a4d0a2aa34f0edf7030c55c46d4d72f920271cff5d1bcbb5590fb44db0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 168}
- `summary`: log evidence; size=4823 bytes; lines=92; PASS=168; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/yosys-sta-contract.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 8
- `sha256`: 313a6d056d62714993aa0bf0f1966261d68cced96d32d43f25c99e36e2883817
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 8, "WARN": 2}
- `summary`: log evidence; size=277 bytes; lines=8; WARN=2; PASS=8; tail=[yosys-sta] contract PASS yosys-sta/Makefile PASS .github/agents/yosys-sta.agent.md PASS .github/memory/modules/yosys-sta.md [e2e] optional tools PASS yosys /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys WARN iEDA <missing>

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1281
- `line_count`: 6
- `sha256`: f506fc690b4aa3aefa53555c758c290700875701e29ae7a182e9c2d89a1092fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 12}
- `summary`: tsv evidence; size=1281 bytes; lines=6; PASS=12; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-e...

### .github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/run-manifest.json

- `kind`: json
- `size_bytes`: 4456
- `line_count`: 121
- `sha256`: b574cd8fb76a95a520f92cc2cae0a89190b7e1dc147c9f36b5b2d311aef8bf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T00:01:05+00:00
- `markers`: {"PASS": 14}
- `summary`: json evidence; size=4456 bytes; lines=121; PASS=14; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-08-fp-arith-macro-decision-yosys-sta/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-07...
