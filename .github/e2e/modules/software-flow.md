# software-flow E2E module

`software-flow` 是显式检查 AI 软件工程合同的轻量 profile，不作为普通软件任务的前置门，也不被 NEMU、
NPC 或其它业务 profile 自动注入。普通开发直接围绕用户目标、调用链和 acceptance criteria 实现与验证。

## 可复用的方法

下面是诊断或跨模块任务的参考模式，不是固定阶段、文件数门禁或完成许可：

- bug：复现或读取直接证据 → 定位 root cause → 修复 → focused test；
- refactor：确认 callers/consumer contract → 修改 → consumer-focused test；
- hardware-aware software：明确 guest/ISA/device/system 可见语义 → 修改模型或工具 → 运行对应系统场景。

步骤可以合并、跳过或按失败新增。一个局部且清楚的修改不需要先生成 scope contract、design plan、review
record、task-run 或 memory 条目。

## 判定边界

- 构建通过足以支持“能够构建”的 criterion，但不能自动支持运行时行为 claim。
- 外层退出码、guest marker、GOOD/BAD TRAP、negative scan、日志或 trace 只在对应场景确实需要时检查。
- NEMU reference 不代表 NPC/RTL；focused case 不代表完整 Linux/Ubuntu 或全量回归。
- task-run、DB brief、memory 和独立 reviewer 只在跨会话长跑、release/security/forensic/publication、
  难恢复高风险动作或用户明确要求时启用。

`e2e_software_flow_contract` 只确认上述 outcome-first 合同仍可发现，不重验所有 agent、历史 memory 或旧
task-run，也不把方法论文字当作业务代码 PASS。
