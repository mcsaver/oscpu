# 派发日志

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-slot-facts-bus`
- `task_slug`: `npc-rv64-ooo-slot-facts-bus`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-27] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求继续优化。
- `depends_on`: 无
- `inputs`: 用户路线图、上一轮结构参数统一结果、现有 `OooFetchHeadClassifyGate/OooFetchHeadPairGate`。
- `action`: 选择“把 common/ 用起来”的最小等价切片：先建立 packed slot facts bus。
- `outputs`: 本轮范围限定为 common header、facts bus alias、父模块接线和 alias 测试。
- `evidence`: 对话工具输出。
- `handoff_to`: `spec`
- `next_step`: 写设计说明。

### [2026-06-27] `spec` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 前完成协议和不变量说明。
- `depends_on`: `recall`
- `inputs`: fetch head 散线 facts、pair gate 局部组合逻辑。
- `action`: 新增 `npc/rv64/design/specs/ooo-slot-facts-bus.md`。
- `outputs`: 需求、范围、协议、状态机、不变量、验证计划和验证结果。
- `evidence`: spec 文件已落盘。
- `handoff_to`: `rtl`
- `next_step`: 修改 RTL 和 header。

### [2026-06-27] `rtl` - `completed`

- `owner_agent`: `codex`
- `trigger`: spec 已明确。
- `depends_on`: `spec`
- `inputs`: `OooFetchHeadClassifyGate.v`、`OooFetchHeadPairGate.v`、`OooAluFetchCore.v`、`filelist.mk`。
- `action`: 新增 `common/OooSlotFacts.vh`；classifier 输出 `facts_o`；pair gate 输出 `head0_facts_o/head1_facts_o` 并改用 bus bit 做局部组合判断；父模块连接 facts bus；filelist 登记 header。
- `outputs`: RTL 接线完成。
- `evidence`: focused classifier/pair gate 2/2 PASS。
- `handoff_to`: `test`
- `next_step`: 加强 alias 断言并跑父模块 focused。

### [2026-06-27] `test` - `completed`

- `owner_agent`: `codex`
- `trigger`: facts bus 有 bit 错位和 JAL/JALR 语义漂移风险。
- `depends_on`: `rtl`
- `inputs`: classifier/pair gate TB。
- `action`: 给 classifier TB 增加 facts alias 检查；给 pair gate TB 增加 head facts、JAL/JALR、branch-spec、FS-off FP 检查。
- `outputs`: focused TB 更新。
- `evidence`: focused `tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit` 4/4 PASS。
- `handoff_to`: `regression`
- `next_step`: 跑默认 module、lint 和 build。

### [2026-06-27] `regression` - `completed`

- `owner_agent`: `codex`
- `trigger`: focused 通过。
- `depends_on`: `test`
- `inputs`: 最新 RTL/TB。
- `action`: 运行默认 module testbench、Verilator lint 和整机构建。
- `outputs`: 集成验证证据。
- `evidence`: 默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 README 和 memory。
- `notes`: 期间 WSL 桥接偶发 `0x8007274c` 只发生在只读输出读取，所有验证命令均已成功闭合。

### [2026-06-27] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `regression`
- `inputs`: 验证命令和改动文件。
- `action`: 更新 `npc/rv64/vsrc/README.md`、`.github/memory/project-status.md`、`.github/memory/modules/npc.md` 和本 task-run。
- `outputs`: 项目记录闭环。
- `evidence`: 相关 markdown 文件已更新。
- `handoff_to`: 无
- `next_step`: 下一轮可继续把 pending capture/owner arbiter 迁移为 facts bus 消费者。
