# Evidence Index

## 基本信息

- `task_id`: 2026-07-07-yosys-rv64-synth-probe-npc-dev
- `task_slug`: yosys-rv64-synth-probe-npc-dev
- `profile`: npc-dev
- `asset_count`: 7
- `total_size_bytes`: 8379

## 证据资产

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: f25dae3b82fa7f52843dba755b082c2278c2819912c7549825fe6a42fd89c4cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: log evidence; size=147 bytes; lines=6; FAIL=2; PASS=8; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md FAIL npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/npc-sim-contract.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 13
- `sha256`: 07df703bcae3b6b323fa0a88643baaff9021c04b3682a9afa5d9f100a115bfd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=404 bytes; lines=13; PASS=22; tail=[npc] sim contract PASS npc/sim/Makefile PASS npc/sim/backends/single.mk PASS npc/sim/backends/rv64.mk PASS npc/sim/backends/soc.mk PASS npc/single/Makefile PASS npc/soc/Makefile PASS npc/rv64/Makefile PASS .github/e2e/profiles/npc-dev.tsv PASS .github/e2e/...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/npc-single-contract.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 5
- `sha256`: 9d998f2fba2831128acf902dd6130d042f60ab2fa22c87422dc9e39dbf93c773
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=142 bytes; lines=5; PASS=8; tail=[npc-single] contract PASS npc/single/Makefile PASS npc/single/Kconfig PASS npc/single/vsrc/filelist.mk PASS npc/single/csrc/cpu/cpu-exec.cpp

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/npc-soc-contract.log

- `kind`: log
- `size_bytes`: 137
- `line_count`: 5
- `sha256`: 7e9cc4329403286b27b637c2fa19497b19354ef41318be583c521f304b3444fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=137 bytes; lines=5; PASS=8; tail=[npc-soc] contract PASS npc/soc/Makefile PASS npc/soc/Kconfig PASS ysyxSoC/spec/cpu-interface.md PASS .github/memory/modules/ysyx-soc.md

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/nodes.tsv

- `kind`: tsv
- `size_bytes`: 973
- `line_count`: 5
- `sha256`: e10293f12b285fe9be17f7cd783cbebca931373b9f17b9e6c1fd0d23c42f7e33
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: tsv evidence; size=973 bytes; lines=5; FAIL=2; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/evidence/software-flow-contract.log npc-sim-contract npc npc PASS npc/sim + backe...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/run-manifest.json

- `kind`: json
- `size_bytes`: 4107
- `line_count`: 113
- `sha256`: 272bf1e76d1e68c3943f656c7325049d3bc58d6fe32827f68f31d7600217c102
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:30:59+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: json evidence; size=4107 bytes; lines=113; FAIL=4; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-07-yosys-rv64-synth-probe-npc-dev/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-07-07-yo...
