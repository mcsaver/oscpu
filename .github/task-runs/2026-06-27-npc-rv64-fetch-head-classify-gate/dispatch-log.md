# 派发日志

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-fetch-head-classify-gate`
- `task_slug`: `npc-rv64-fetch-head-classify-gate`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-27] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户选择优先继续 RV64 RTL 工业化拆分。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、RV64 README/spec/vsrc 边界。
- `action`: 读取项目约束、近期 RV64 回归记录、源码体量和 `OooAluFetchCore` head 分类逻辑。
- `outputs`: 选择 `OooFetchHeadClassifyGate` 作为下一刀。
- `evidence`: 对话工具输出。
- `handoff_to`: `spec`
- `next_step`: 落项目内 spec 与实施计划。
- `notes`: 当前工作树已有大量非本轮变更，后续只路径限定编辑本任务相关文件。

### [2026-06-27] `spec` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求产物按项目规则放入工作区。
- `depends_on`: `recall`
- `inputs`: `OooAluFetchCore` head0/head1 分类源码。
- `action`: 将设计说明放入 `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`，并删除临时 `docs/superpowers` 草稿。
- `outputs`: 项目内正式 spec。
- `evidence`: `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`
- `handoff_to`: `plan`
- `next_step`: 编写 implementation plan。
- `notes`: spec 明确 classifier 内部持有 `OooFpDecode` 实例，父模块只保留时序 owner。

### [2026-06-27] `plan` - `completed`

- `owner_agent`: `codex`
- `trigger`: spec 已落盘，需要把执行步骤固定到项目 task-run。
- `depends_on`: `spec`
- `inputs`: `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`
- `action`: 写入 `implementation-plan.md`，按 TDD 顺序安排 RED test、classifier RTL、父模块接入、focused/full/official 验证和 memory 更新。
- `outputs`: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/implementation-plan.md`
- `evidence`: 文件已落盘。
- `handoff_to`: `test`
- `next_step`: 先写失败的 module TB。
- `notes`: 计划使用项目内路径，不再使用临时 `docs/superpowers` 草稿。

### [2026-06-27] `test` - `completed`

- `owner_agent`: `codex`
- `trigger`: TDD RED 阶段。
- `depends_on`: `plan`
- `inputs`: classifier spec 的协议规则与不变量。
- `action`: 新增 `tb_ooo_fetch_head_classify_gate.sv` 并登记 Makefile；覆盖普通 ALU、base illegal、FP illegal mask、FS-off FP、CSR/ECALL/EBREAK/semihost、MRET/SRET、TSR、supervisor fence/TVM、fetch fault。
- `outputs`: focused module TB。
- `evidence`: `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate" RESULT_DIR=../perf/results/20260627-fetch-head-classify/failing run` 因 `Unknown module type: OooFetchHeadClassifyGate` 失败，符合 RED 预期。
- `handoff_to`: `rtl`
- `next_step`: 实现 classifier RTL。
- `notes`: RED 失败原因是缺失目标模块，不是测试环境错误。

### [2026-06-27] `rtl` - `completed`

- `owner_agent`: `codex`
- `trigger`: RED 已确认。
- `depends_on`: `test`
- `inputs`: `OooAluFetchCore` head0/head1 内联分类逻辑与 `OooFpDecode` 接口。
- `action`: 新增 `frontend/OooFetchHeadClassifyGate.v`，在 `vsrc/filelist.mk` 登记，并用两个实例替换 `OooAluFetchCore` 中 head0/head1 的重复内联分类和 `u_head*_fp_decode`。
- `outputs`: classifier RTL、父模块接线、filelist/testbench 入口。
- `evidence`: `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate" RESULT_DIR=../perf/results/20260627-fetch-head-classify/classifier run` PASS。
- `handoff_to`: `focused-verify`
- `next_step`: 跑父模块聚焦回归。
- `notes`: 父模块继续保留 `head_fetch_fault1_w`、`head1_decode_valid_w`、pending owner、CSR side effect、fetch FIFO 和 precise recovery。

### [2026-06-27] `focused-verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: classifier 已接入父模块。
- `depends_on`: `rtl`
- `inputs`: 新 RTL 与父模块接线。
- `action`: 跑 focused testbench、lint 和主仿真 build。
- `outputs`: focused 验证证据。
- `evidence`: `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit" RESULT_DIR=../perf/results/20260627-fetch-head-classify/focused run` 3/3 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `handoff_to`: `regression`
- `next_step`: 跑 full module testbench 和 official smoke。
- `notes`: Verilator lint 输出中 `OooFetchHeadClassifyGate.v` 已由主 filelist 带入。

### [2026-06-27] `regression` - `completed`

- `owner_agent`: `codex`
- `trigger`: focused/lint/build 已通过。
- `depends_on`: `focused-verify`
- `inputs`: 新 RTL 与完整模块 TB 集合。
- `action`: 跑默认 module testbench 和 official `rv64ui/rv64mi/rv64si` smoke。
- `outputs`: 宽回归证据。
- `evidence`: `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-head-classify/full-module-testbench run` 101/101 PASS；`npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --riscv-tests --riscv-suites rv64ui --riscv-privileged --log-base npc/rv64/perf/results/20260627-fetch-head-classify/core-regress-official` `overall_rc=0`，run dir `npc/rv64/perf/results/20260627-fetch-head-classify/core-regress-official/20260627-122004-47373/`。
- `handoff_to`: `record`
- `next_step`: 更新 README、memory 和 task report。
- `notes`: official smoke 覆盖普通 RV64I、machine/supervisor privileged breakpoint/csr/illegal/fetch fault/WFI 等前端异常面。

### [2026-06-27] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证已闭合。
- `depends_on`: `regression`
- `inputs`: RTL 改动、验证证据、项目 memory 规范。
- `action`: 更新 `npc/rv64/vsrc/README.md`、`.github/memory/modules/npc.md`、`.github/memory/project-status.md`、task report 和 implementation plan。
- `outputs`: 项目记录闭环。
- `evidence`: 本 task-run 文件与 memory 文件更新。
- `handoff_to`: 无
- `next_step`: 下一轮继续选择低时序风险的纯组合边界，或转入 CPI 热点分析。
- `notes`: 当前工作树已有大量非本轮变更，本轮未执行 git stage/commit。
