# 2026-06-03 RV64 RTL Layout

## 目标

整理 `npc/rv64/vsrc` 中的 RV64 OoO/superscalar RTL：

- 按当前活动路径给乱序超标量模块分目录。
- 把可独立审计/优化的组合逻辑从臃肿的 `OooAluFetchCore` 中拆出。
- 把默认 RV64/OoO/Linux 构建不使用的旧顺序/缓存/流水线模块统一收进 legacy 目录。

## 实施

- 新增 `vsrc/ooo/README.md`，按 `frontend/backend/rename/issue/commit/regfile` 固化 OoO 分类。
- 新增 `vsrc/legacy/README.md`，说明 legacy 目录只保存旧顺序核、RV32 风格 cache/frontend/pipeline 等非默认路径模块，供历史 testbench 或对照分析使用。后续按用户反馈收敛为单层 `vsrc/legacy/`，不再在 legacy 下镜像 `cache/common/core/...` 子目录。
- 移动 OoO 文件：
  - `OooAluFetchCore` -> `ooo/frontend`
  - `OooAluCoreSlice/OooAluDecodeBackend/OooDispatchBackend/OooIntBackend` -> `ooo/backend`
  - `OooRenameMap/OooFreeList/OooBusyTable` -> `ooo/rename`
  - `OooIntIssueQueue` -> `ooo/issue`
  - `OooRob` -> `ooo/commit`
  - `OooPhysRegFile/OooArchRegFile` -> `ooo/regfile`
- 移动 legacy 文件：
  - `cache/*`、旧 `common/Sram*`、旧 `core/NpcCore/RegisterFile/PipelineControl`
  - 旧 `execute/Rv32Multiplier/Rv32Divider`
  - 旧 `frontend/IfStage/BranchPredictor`
  - 旧 `memory/MemoryStage*`
  - 旧 `pipeline/*PipeReg`
- 从 `OooAluFetchCore` 拆出：
  - `OooRvcDecompressor`: 16-bit RVC halfword -> 32-bit instruction，纯组合。
  - `OooFpDecode`: FP load/store、move/class/compare/convert/arithmetic 分类，纯组合，供 lane0/lane1 复用。
- 更新 `vsrc/filelist.mk`：
  - 新增 OoO 子目录变量。
  - 新增 legacy 子目录变量。
  - 新增 `RTL_OOO_FRONTEND_HELPERS` 聚合新前端 helper。
  - 保留旧 testbench 变量指向 legacy 位置。
- 更新 `npc/rv64/testbench/Makefile`：
  - 直接实例化 `OooAluFetchCore` 的 focused tests 显式加入 `RTL_OOO_FRONTEND_HELPERS`。

## 验证

- `git diff --check`: PASS
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j1`: PASS
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260603-rv64-rtl-layout/module-testbench ../perf/results/20260603-rv64-rtl-layout/module-testbench/logs/tb_ooo_fetch_trap_gate.log`: PASS
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260603-rv64-rtl-layout/module-testbench ../perf/results/20260603-rv64-rtl-layout/module-testbench/logs/tb_ooo_priv_system.log`: PASS

## 边界

- 本轮是结构整理与等价拆分，不新增 ISA/特权/设备能力。
- `tb_ooo_alu_fetch_core` 编译通过但行为仍失败，失败点与 `.github/memory/known-issues.md` known issue [33] 一致：该旧 testbench 仍按早期 RV32/OoO 语义断言 MRET、ECALL、访存和 lane1 行为。本轮不把当前 RV64 RTL 回退到旧断言。
