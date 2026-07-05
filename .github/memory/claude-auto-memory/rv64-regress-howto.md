---
name: rv64-regress-howto
description: npc/rv64 跑回归/构建/测试的命令与环境陷阱(NPC_HOME 必须覆盖)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 76369d5c-65e7-46d2-ae43-bf343854733a
---

跑 npc/rv64 核回归的入口与陷阱:

**环境陷阱(必读)**: shell 环境里 `NPC_HOME=/home/lyg/PA/ysyx-workbench/npc`(指向单核后端)。`testsuites/scripts/npc-rv64-core-regress.sh` 用 `${NPC_HOME:-...}` 会沿用它 → 去 `npc/build` 找 sim(实际在 `npc/rv64/build`)→ 所有测试 exit=127。**跑 rv64 回归前必须 `export NPC_HOME=/home/lyg/PA/ysyx-workbench/npc/rv64`**。

**工具链**: `export PATH=/home/lyg/riscv-toolchain/riscv/bin:$PATH`(riscv64-unknown-elf-gcc)。

**riscv-tests 源**: `npc/rv64/testsuites/core-tests/src/riscv-tests`(submodule, 已填充)。脚本默认路径算错(找 `npc/testsuites` 漏 rv64),用 `--riscv-tests-dir <abs>` 显式指定。

**命令**:
- lint(秒级): `make -C npc/rv64 lint`(EXIT=0 即绿)
- build sim: `make -C npc/rv64 -j2`(Verilator, 约 1 分钟, 产 `build/NpcSimTop`)
- 单 module TB: `make -C npc/rv64/testbench build/logs/<tb>.log RESULT_DIR=build`(iverilog; 仅失败才打印明细, `[PASS]` = 全 check 过)
- 全 module TB: `make -k -C npc/rv64/testbench RESULT_DIR=<dir> run`(-k 不首错即停; 113 TB)
- 焦点 riscv-tests: `export NPC_HOME=.../npc/rv64; testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-am --skip-lint --skip-build --riscv-tests --riscv-tests-dir <abs> --riscv-suites rv64ui,rv64uc,rv64uf,rv64ud --riscv-privileged`(--riscv-privileged 追加 rv64mi,rv64si)

**已知 legacy TB 与 RV64 spec 冲突**: `tb_npc_core_mcycle` 测 RV32 时代的 mcycleh/cycleh(*h CSR), 与 RV64 下 *h 非法的正确实现冲突——属 legacy 死代码应删, 非 bug。详见 [[rv64core-audit-baseline]]。
