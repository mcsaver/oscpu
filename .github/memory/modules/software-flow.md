# Software Flow 稳定事实

> 2026-08 operating-contract 重构后，本文件只保存当前可复用语义。2026-06 的静态图、固定前置节点、
> 方法论守门、task-run/marker 证明和逐次 profile 结果都是历史 campaign 证据，不能经 recall 恢复成当前
> permission gate 或默认执行顺序；需要复盘时按具体 task-run 查询。

## 当前模型

- `software-flow` 是可选的软件工程方法与显式 E2E profile，不是软件任务的默认路由、开工检查或完成门。
- 普通软件修复遵循 objective/acceptance → 调用链与 consumer contract → root-cause edit → focused test →
  result。任务复杂时可以借用设计、单测、集成和回归分层，但不要求固定图、固定阶段输出或 review-record。
- `nemu-dev*` 是 NEMU-only 工程入口，`npc-dev` 是 NPC-only 入口，`nemu-ubuntu-integrated` 才显式组合
  NEMU/NPC/RV64 Linux。业务 profile 不自动 include `software-flow`、discovery、memory 或 agent 存在性检查。
- NEMU 是软件实现的 ISA/设备/系统 reference。修改 C/C++/Python/Shell/Make/Kconfig 时，软件工程结果仍需
  与实际 claim 匹配：compile 只证明构建；ISA/CSR/MMU/device/guest 行为需要对应 directed test、marker、
  trace 或系统运行，且 QEMU/NEMU reference 不能冒充 NPC target。
- 外层 Windows 只用 PowerShell 启动 WSL；工程命令在 Ubuntu 内运行。具体工具环境按当前命令实际缺失时
  加载 `scripts/agent-env.sh`，不先运行环境 profile 来授权 build/test。

## 验证与留存

- 先运行能直接判断当前 acceptance criterion 的最短可信检查；结果矛盾、缺失或 verifier 异常时再定向
  深挖，不在每个软件任务前重验 runner、profile 或数据库。
- 只有显式跨栈 E2E、persistent/published 长跑、release/migration/security/forensic、真实跨会话交接或
  用户要求时，才创建 task-run、dispatch/profile 记录或更新长期 memory。
- 构建/测试返回码、FAIL/BAD TRAP/assert/guest marker 等都按各自 oracle 解释；低层 PASS 不越级声称完整
  Linux/Ubuntu、硬件 target、DiffTest 或 PPA 完成。
