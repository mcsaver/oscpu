# 派发日志

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-pending-dispatch-facts-bus`
- `task_slug`: `npc-rv64-ooo-pending-dispatch-facts-bus`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-27] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求继续推进。
- `depends_on`: 无
- `inputs`: 上一轮 `OooSlotFacts.vh`、`OooFetchHeadPairGate`、`OooPendingDispatchArbiter`。
- `action`: 选择 pending arbiter facts bus 接入作为下一刀。
- `outputs`: 范围限定为组合 alias 和父模块接线。
- `evidence`: 对话工具输出。
- `handoff_to`: `rtl`
- `next_step`: 修改 RTL 和 TB。

### [2026-06-27] `rtl` - `completed`

- `owner_agent`: `codex`
- `trigger`: 范围已明确。
- `depends_on`: `recall`
- `inputs`: `OooPendingDispatchArbiter.v`、`OooAluFetchCore.v`。
- `action`: 给 arbiter 增加 `dispatch0_facts_i/head1_facts_i`，内部建立 facts alias；父模块生成 `dispatch0_facts_w` 并连接 `head1_facts_w`。
- `outputs`: RTL 接线完成。
- `evidence`: `tb_ooo_pending_dispatch_arbiter` PASS。
- `handoff_to`: `test`
- `next_step`: focused 回归。

### [2026-06-27] `test` - `completed`

- `owner_agent`: `codex`
- `trigger`: 单测通过。
- `depends_on`: `rtl`
- `inputs`: 旧 pending arbiter stimulus。
- `action`: 在 `tb_ooo_pending_dispatch_arbiter` 中由旧标量 stimulus 自动构造 facts bus。
- `outputs`: focused TB 覆盖旧 case 在新 bus 主路径下的行为。
- `evidence`: focused `tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit` 5/5 PASS。
- `handoff_to`: `regression`
- `next_step`: 默认 module、lint、build。

### [2026-06-27] `regression` - `completed`

- `owner_agent`: `codex`
- `trigger`: focused 通过。
- `depends_on`: `test`
- `inputs`: 最新 RTL/TB。
- `action`: 运行默认 module testbench、Verilator lint 和整机构建。
- `outputs`: 集成验证证据。
- `evidence`: 默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `handoff_to`: `record`
- `next_step`: 更新项目记录。
- `notes`: WSL 桥接偶发只读输出错误不影响构建/测试结果。

### [2026-06-27] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `regression`
- `inputs`: 验证命令和改动文件。
- `action`: 更新 spec、README、memory 与本 task-run。
- `outputs`: 项目记录闭环。
- `evidence`: 相关 markdown 文件已更新。
- `handoff_to`: 无
- `next_step`: 后续可继续把旧散线从 pending arbiter 调用面删减，或抽 PendingCaptureGate。
