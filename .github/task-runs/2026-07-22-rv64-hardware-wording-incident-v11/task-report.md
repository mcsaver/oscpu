# 本地 RV64 RTL 措辞分层事件记录（V11）

## 事件边界

- 日期：2026-07-22（Asia/Shanghai）。
- 用户报告：在扩写 `npc/rv64/testbench/tests/tb_ooo_fetch_access_footprint.sv` 并运行本地
  Icarus Verilog 仿真期间，Codex 内容被自动风险分类暂停。
- 截图来源：用户提供
  `C:/Users/17279/AppData/Local/Temp/codex-clipboard-75ae319d-a51e-4da0-a106-839f7cf4c6bc.png`。
- 工作区保留副本：`evidence/platform-prompt.png`，SHA-256
  `5fb3292df509dcae25c148ade9743c7c25cc8333fb8136e82e33e3a25c4e25a2`。
- 受影响的本地 RTL 复核合同：
  `.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/subagent-contracts/v9i-ifu-access-coverage-review-v1.json`，
  原始 SHA-256 `a94b03c60d71178a2f018d854b9641dbef51b4ed2e520b67913b760d470d52a6`。
- 当前长期 RV64 OoO 目标保持 active；本事件不改变 RTL 语义、验证门槛或工程权限。

## 可证事实与推断边界

可证事实：

1. 被编辑文件是本地 RV64 取指 testbench；新增内容检查 2B instruction read、AXI RRESP、
   execute PMP、packet byte frontier、cache fill 与 lane owner。
2. 原始子 agent `supplied_material` 手工重复了结构化合同已经表达的外部来源边界，并在同一技术提示中
   密集出现 `default-deny`、设备地址过滤、RISC-V 特权级、fault、guard page、验证变体等多义词。
3. 原 canonical `language_policy` 还使用了
   `platform_check_bypass_is_not_an_objective` 这一不必要的否定式字段名。
4. 无法从截图获知分类器内部规则，因此不能断言某一个词是唯一触发原因，也不能保证任何自然语言写法
   永远不进入人工或自动复核。

最可信推断：真实硬件词本身并非问题；更可能是“RTL 多义术语密度 + 技术材料重复协调层否定说明 +
旧字段命名”的组合使通用分类器失去处理器上下文。修正目标是提高领域准确性，不是改变平台判定。

## 已固化修正

1. 新合同使用正向 `language_policy.wording_preserves_task_semantics=true`；历史合同的旧字段只保留
   validate 兼容，不再由 `create` 生成。
2. `goal/deliverables/success_criteria/supplied_material` 只允许本地 RV64 module、signal、transaction、
   pipeline level、cycle/config 与验证目的。协调层/平台层内容进入 JSON policy 或 dispatch log。
3. render 首屏只出现一次正向本地作用域；不把 JSON access 布尔字段改写成自然语言反复附加。
4. 真实 RTL 标识符、PMP、M/S/U 特权级、AXI RRESP、access fault、pipeline flush/kill、NoC、
   testbench 异常激励和 compile-success RTL 验证变体均保留；没有建立硬件术语黑名单。
5. 新 validator 对技术叙述混入协调层说明 fail closed；本次真实旧合同回放已稳定得到三条明确错误，
   指向 `账号`、`凭据`、`外部服务` 被放入 `supplied_material`。

## 当前验证证据

- `rtl_task_contract.py audit`：PASS。
- `rtl_task_contract.py self-test`：25 项 PASS；包含合法 CPU/RTL 术语、合法处理器 NoC、
  协调层措辞隔离、历史 language policy 兼容、实现/验证能力保留及负例拒绝。
- `rtl_task_contract.py cli-self-test`：20 项 PASS；create/validate/render、no-tools、legacy、
  command/mode/purpose 与仓库根绑定均通过。
- 当前 canonical config SHA-256：
  `a2f98e714783f21c436cd7d3c1991778da07038d421f82c9d1e727817d5f6326`；
  generator SHA-256：
  `bfad47e2119cd20bce90adcff492e87094d4b7547c5c0275697bb84e7fe720ba`。
- 本次真实旧合同 forward replay：预期 FAIL，三条错误均为技术材料包含协调层说明；证明新增门禁
  能捕获实际失误，而不仅是合成样本。

## 声明等级与剩余项

- 已达到：措辞分层规则、生成器正向字段、历史兼容、单元正反例和真实失败样本回放。
- 尚待：`agent-system` e2e、DB 索引、memory 发布与 strict guard；完成前不宣称工作流闭环。
- 本记录不证明平台不会再次复核，也不作为任何 RV64 功能、架构或 PPA GREEN 证据。
