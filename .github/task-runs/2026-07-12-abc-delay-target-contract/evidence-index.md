# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-abc-delay-target-contract
- `task_slug`: abc-delay-target-contract
- `profile`: yosys-sta
- `asset_count`: 6
- `total_size_bytes`: 9842

## 证据资产

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/npc-sim-contract.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 13
- `sha256`: 07df703bcae3b6b323fa0a88643baaff9021c04b3682a9afa5d9f100a115bfd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=404 bytes; lines=13; PASS=22; tail=[npc] sim contract PASS npc/sim/Makefile PASS npc/sim/backends/single.mk PASS npc/sim/backends/rv64.mk PASS npc/sim/backends/soc.mk PASS npc/single/Makefile PASS npc/soc/Makefile PASS npc/rv64/Makefile PASS .github/e2e/profiles/npc-dev.tsv PASS .github/e2e/...

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/npc-single-contract.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 5
- `sha256`: 9d998f2fba2831128acf902dd6130d042f60ab2fa22c87422dc9e39dbf93c773
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=142 bytes; lines=5; PASS=8; tail=[npc-single] contract PASS npc/single/Makefile PASS npc/single/Kconfig PASS npc/single/vsrc/filelist.mk PASS npc/single/csrc/cpu/cpu-exec.cpp

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 5798
- `line_count`: 107
- `sha256`: f707f351087e9cc8a22a0421b03111ebb978ce52c81411ae4eee5afb25996ca8
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {"PASS": 198}
- `summary`: log evidence; size=5798 bytes; lines=107; PASS=198; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-12-abc-delay-target-contract/evidence/yosys-sta-contract.log

- `kind`: log
- `size_bytes`: 401
- `line_count`: 10
- `sha256`: 55f76842f5f00e4a265ad0ae6c67df65ec80d1f7fff4db928ebd93e3a741a657
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T17:49:25+00:00
- `markers`: {"PASS": 12, "WARN": 2}
- `summary`: log evidence; size=401 bytes; lines=10; WARN=2; PASS=12; tail=[yosys-sta] contract PASS yosys-sta/Makefile PASS yosys-sta/scripts/check_abc_delay_target_contract.py PASS .github/agents/yosys-sta.agent.md PASS .github/memory/modules/yosys-sta.md PASS abc-delay-target-contract delay_strategies=5 default=DELAY-4 [e2e] op...

## 定向动态烟测（ignored build artifact）

- `path`: `npc/rv64/build/sta-abc-target-contract/PipeStageReg-200MHz/yosys.log`
- `size_bytes`: 46537
- `sha256`: `06f8333ad59cca1b72cfeeab960f58317312bbe0f379592b088e112a9e45eb62`
- `markers`: `[INFO]: ABC DELAY TARGET 5000.0ps`; `&nf -D 5000.0`; `upsize -D 5000.0`; `dnsize -D 5000.0`; `End of script`; final `Found and reported 0 problems.`
- `scope`: 仅用于证明自定义 DELAY script 的实际占位替换，不复制 raw transcript 到 Markdown/DB fulltext。
