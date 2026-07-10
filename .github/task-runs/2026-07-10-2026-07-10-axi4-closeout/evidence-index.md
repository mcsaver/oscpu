# Evidence Index

## 基本信息

- `task_id`: 2026-07-10-2026-07-10-axi4-closeout
- `task_slug`: 2026-07-10-axi4-closeout
- `profile`: npc-dev
- `asset_count`: 7
- `total_size_bytes`: 8221

## 证据资产

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 6
- `sha256`: 17664962cd1567c20052fc78a70a50660d0c6219630a67f825e1ab8278230ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=155 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/history/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/npc-sim-contract.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 13
- `sha256`: 07df703bcae3b6b323fa0a88643baaff9021c04b3682a9afa5d9f100a115bfd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=404 bytes; lines=13; PASS=22; tail=[npc] sim contract PASS npc/sim/Makefile PASS npc/sim/backends/single.mk PASS npc/sim/backends/rv64.mk PASS npc/sim/backends/soc.mk PASS npc/single/Makefile PASS npc/soc/Makefile PASS npc/rv64/Makefile PASS .github/e2e/profiles/npc-dev.tsv PASS .github/e2e/...

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/npc-single-contract.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 5
- `sha256`: 9d998f2fba2831128acf902dd6130d042f60ab2fa22c87422dc9e39dbf93c773
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=142 bytes; lines=5; PASS=8; tail=[npc-single] contract PASS npc/single/Makefile PASS npc/single/Kconfig PASS npc/single/vsrc/filelist.mk PASS npc/single/csrc/cpu/cpu-exec.cpp

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/npc-soc-contract.log

- `kind`: log
- `size_bytes`: 137
- `line_count`: 5
- `sha256`: 7e9cc4329403286b27b637c2fa19497b19354ef41318be583c521f304b3444fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=137 bytes; lines=5; PASS=8; tail=[npc-soc] contract PASS npc/soc/Makefile PASS npc/soc/Kconfig PASS ysyxSoC/spec/cpu-interface.md PASS .github/memory/modules/ysyx-soc.md

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/nodes.tsv

- `kind`: tsv
- `size_bytes`: 996
- `line_count`: 5
- `sha256`: 8fad1f540099842d2fce52f58e9eb8c8babd676fccaae3d0b323ccfe25ed9fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=996 bytes; lines=5; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/evidence/software-flow-contract.log npc-sim-contract npc npc PASS npc/sim + backend man...

### .github/task-runs/2026-07-10-2026-07-10-axi4-closeout/run-manifest.json

- `kind`: json
- `size_bytes`: 3918
- `line_count`: 112
- `sha256`: 2ffe5ab3484a88b32428327d37f3b5ad21709767e5e1d023ec0c7082f93f87f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-10T08:44:43+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=3918 bytes; lines=112; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-10-2026-07-10-axi4-closeout/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-10-2026-07-10-axi4-closeout/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-07-10-2026-07-10-axi...
