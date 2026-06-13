# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-nemu-npc-feature-parity`
- `task_slug`: `nemu-npc-feature-parity`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

---

### [2026-05-22 20:35] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求补齐 NEMU 并跑 difftest
- `depends_on`: 无
- `inputs`: AGENTS、copilot instructions、project memory、NPC study
- `action`: 读取规则、模块记忆与相关规范摘要
- `outputs`: 约束清单与参考闭环目标
- `evidence`: 已读取 `.github/memory/modules/{npc,nemu,difftest,abstract-machine}.md`
- `handoff_to`: `compare-npc-nemu`
- `next_step`: 对比 NPC/NEMU 源码差距
- `notes`: 使用中文、先定位 root cause、完成后写 memory/task-runs

### [2026-05-22 20:45] `compare-npc-nemu` - `completed`

- `owner_agent`: Codex
- `trigger`: RECALL 完成
- `depends_on`: `recall`
- `inputs`: NPC `CsrFile.v/AxiLiteClint.v/NpcSimTop.sv`，NEMU `inst.c/intr.c/paddr.c`
- `action`: 搜索并阅读 CSR、CLINT、interrupt、difftest 相关路径
- `outputs`: 缺口定位：identity CSR、cycle CSR、CLINT MMIO、真实 `isa_query_intr()`、AM `_zifencei`
- `evidence`: NEMU 原 `isa_query_intr()`/`dev_raise_intr()` 为空，`csr_read/write` 未覆盖新增 CSR，`paddr` 无 CLINT 特例
- `handoff_to`: `implement-reference`
- `next_step`: 修改 NEMU/AM
- `notes`: CLINT 需在 paddr 层直连，避免 reference so 未 init_device 时访问失败

### [2026-05-22 21:05] `implement-reference` - `completed`

- `owner_agent`: Codex
- `trigger`: 缺口清单确认
- `depends_on`: `compare-npc-nemu`
- `inputs`: NEMU CSR/trap/physical memory files，AM riscv-nemu ISA script
- `action`: 补齐 NEMU CSR/CLINT/interrupt；补 `_zifencei`
- `outputs`: 修改 `nemu/include/isa.h`、`nemu/src/**`、`abstract-machine/scripts/isa/riscv-nemu-ext.mk`
- `evidence`: `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j4` PASS
- `handoff_to`: `build-ref`
- `next_step`: 构建 NPC difftest reference so
- `notes`: `mtime/mcycle` 采用指令级近似

### [2026-05-22 21:15] `build-ref` - `completed`

- `owner_agent`: Codex
- `trigger`: NEMU build PASS
- `depends_on`: `implement-reference`
- `inputs`: 修改后的 NEMU
- `action`: 运行 `make -C npc/single difftest-ref`
- `outputs`: `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so`
- `evidence`: reference so 构建 PASS
- `handoff_to`: `verify`
- `next_step`: 跑 NEMU 与 NPC difftest 回归
- `notes`: 构建脚本仍提示既有未跟踪嵌套仓库 `ysyxSoC/`

### [2026-05-22 21:35] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: reference so 构建完成
- `depends_on`: `build-ref`
- `inputs`: NEMU/NPC/AM 修改
- `action`: 运行 NEMU cpu-tests、NPC difftest cpu-tests、静态检查
- `outputs`: `/tmp/nemu-cputests.log`、`/tmp/npc-difftest-cputests.log`
- `evidence`: NEMU cpu-tests 38/38 PASS；NPC cpu-tests `--diff=default --no-progress -m 0` 38/38 PASS 且 `Difftest: ON`；`git diff --check` PASS
- `handoff_to`: `record`
- `next_step`: 写 memory/task-run
- `notes`: 初次 NEMU cpu-tests 因缺 `AM_HOME` 全 FAIL；补环境后发现 `fence-i` 缺 `_zifencei` 并已修复

### [2026-05-22 21:45] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证闭合
- `depends_on`: `verify`
- `inputs`: 修改清单与验证证据
- `action`: 更新 project status、NEMU/difftest/AM 模块记忆和 task-run
- `outputs`: `.github/memory/**` 与本目录记录
- `evidence`: memory 与 task-run 文件已更新
- `handoff_to`: 无
- `next_step`: 交付总结
- `notes`: 保留风险说明：timer/counter 非 cycle-exact
