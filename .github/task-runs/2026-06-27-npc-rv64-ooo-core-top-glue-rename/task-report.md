# 任务报告

## 基本信息

- task_id: `2026-06-27-npc-rv64-ooo-core-top-glue-rename`
- 日期: `2026-06-27`
- 目标: 删除长期 RTL module/文件名 `OooAluFetchCore`，把已经拆空到无 `always` 的装配壳迁到 `core/OooCoreTopGlue.v`。
- 范围: `npc/rv64/vsrc/core`、`frontend/control/decode` 相关注释、filelist、focused testbench、边界 spec、memory。

## RTL 推导摘要

- 需求: 目录即架构边界；历史 ALU/fetch 巨石不能继续位于 `frontend/`，父模块只能作为 core 级 integration shell 存在。接口和行为必须等价，不能趁改名改 pending、redirect、FP commit 或 fetch packet 规则。
- 协议规则: `OooCoreTopGlue` 保持原 fetch req/rsp、mem0/mem1 req/rsp、commit/trap/exit/debug 端口协议；`NpcCoreTop`、focused TB 和 filelist 只替换 module/file/test 名称，不改变上下游 ready/valid 和 commit ready 关系。
- 状态机: 本切片无新增状态机。迁移前壳内已经无 `always` 状态块；迁移后仍要求 core glue 不持有新状态，所有时序状态继续由既有 frontend/control/execute/memory/writeback/regread_bypass sequencer/register owner 保存。
- 不变量: `OooCoreTopGlue` 不包含 `always`；旧 RTL 名称不再出现在源码/testbench 源/filelist；实例端口一一保持；`RTL_CORE_SRCS` 继续只包含一个 core glue 源；focused TB 覆盖旧父模块行为。
- 数据通路约束: 仅移动文件、改 module 名和构建变量名；wire、实例、assign、端口位宽和参数保持原结构。顶层 `NpcCoreTop` 仍在 fetch/memory AXI bridge 之间连接 core glue。

## 修改摘要

- `frontend/OooAluFetchCore.v` 移动并改名为 `core/OooCoreTopGlue.v`，module 名改为 `OooCoreTopGlue`。
- `NpcCoreTop`、`tb_ooo_fetch_trap_gate`、`tb_ooo_priv_system` 和父模块 focused TB 改为实例化 `OooCoreTopGlue`。
- `tb_ooo_alu_fetch_core.sv` 改名为 `tb_ooo_core_top_glue.sv`，Makefile 默认测试与源清单同步改名。
- `vsrc/filelist.mk` 将 `RTL_OOO_ALU_FETCH_CORE` 替换为 `RTL_OOO_CORE_TOP_GLUE`。
- 更新 `vsrc/README.md`、`control/README.md`、`legacy/README.md`、相关源码注释和 `ooo-core-top-glue.md`。

## 验证证据

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-core-top-glue-rename/focused TESTS="tb_ooo_core_top_glue tb_ooo_fetch_trap_gate tb_ooo_priv_system tb_ooo_fetch_head_pair_gate tb_ooo_pending_dispatch_arbiter tb_decode_unit" run`: 6/6 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-core-top-glue-rename/all run`: 103/103 PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- 源码/testbench/filelist 旧名残留扫描 `OooAluFetchCore|OooAluFetch|ooo_alu_fetch_core|RTL_OOO_ALU_FETCH_CORE|frontend/OooAluFetchCore`: 无输出。
- `Test-Path npc/rv64/vsrc/frontend/OooAluFetchCore.v` 和 `Test-Path npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv`: 均为 `False`。
- `OooCoreTopGlue.v` 中 `always` 数量: `0`。
- scoped `git diff --check`: PASS。

## 风险与边界

- 本切片只删除旧巨石 module/文件名并迁移装配层，不代表 `OooFrontend.v`/`OooControlPlane.v` wrapper 已经完成。
- `common/OooFetchPacketBus.vh`、`OooPendingOwnerBus.vh`、`OooCommitEventBus.vh` 仍是后续 bus 化目标；当前只沿用已有 `OooSlotFacts.vh` 和既有 helper 接线。
- 旧历史 specs/memory 中保留的旧名是历史记录，不作为当前 RTL 架构入口。
