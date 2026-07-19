---
name: prepare-rtl-task-contract
description: 为本地 RV64 Verilog/SystemVerilog 设计、只读审查、验证或 PPA 子任务生成并校验最小权限任务契约。主 agent 准备派发子 agent、并行 RTL 复核、限定文件/命令/输出、记录平台 review_pending 事件，或需要减少跨领域歧义且保持原始 RTL 语义时使用。
---

# Prepare RTL Task Contract

在派发本地 RTL 子任务前，先把目标、路径、权限、命令、产物和成功条件收敛为机器可校验的 JSON，再把同一份契约渲染成子 agent 提示。详细规则以
`.github/instructions/rtl-agent-task-contract.instructions.md` 为准。

## 工作流

1. 只给子任务所需的最小上下文；不得把整轮历史、账号信息或无关日志一并传入。
2. 用脚本创建契约。只读复核使用 `read-only-review`，落盘实现使用 `implementation`，验证与 PPA 分别使用 `verification`、`ppa-analysis`。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<可验证目标>' \
  --allow-path npc/rv64/vsrc/<path> \
  --allow-read-command rg \
  --allow-read-command sed \
  --required-context npc/rv64/design/specs/<spec>.md \
  --deliverable '<输出内容>' \
  --success-criterion '<客观成功条件>' \
  --out .github/task-runs/<run-id>/subagent-contracts/<task-id>.json
```

3. 校验并渲染；把渲染结果原样放进子 agent 提示，不要另写一份可能漂移的边界说明。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate <contract.json>
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render <contract.json>
```

命令权限不是自由文本。`--allow-read-command` 与 `--allow-write-command` 只接收 canonical `COMMAND`；
生成器从 JSON catalog 填入固定的 `mode/purpose` 枚举和中文标签，任务不能自定义 purpose。详细意图写在
`goal/deliverables/success_criteria`，不会扩大命令权限。只读任务只允许 canonical 只读命令类，写型命令必须同时声明最小 `write_paths`。工具的 repo realpath 固定为本 skill 所在工作区，
`--repo-root` 不能改绑到其它目录。

4. 在 `dispatch-log.md` 记录契约路径和 SHA-256。子 agent 返回后，对照契约检查越界读取、未授权写入、外部访问和缺失产物；需扩展范围时生成新版本契约，不在原提示后模糊追加权限。
5. 若平台暂不展示或不处理某个合法 RTL 子任务，只把该子任务记为 `review_pending`，保留原始请求、契约哈希、时间和平台提示；不得通过改变 RTL 语义来重试，也不得据此关闭长期父目标。

## 边界

- 工程领域固定为本地 RV64 Verilog/SystemVerilog 数字电路设计、验证或 PPA。
- 网络、账号、凭据和外部服务默认且必须为禁止；确需外部资料时拆成独立研究节点，不复用本契约扩大权限。
- 真实 RTL 标识符保持代码格式；正文使用流水取消、分支恢复、完成资格、生产者归属、事务标签、定向变异与独立反例复核等准确硬件语义。
- 本 skill 只规范任务边界和证据，不替代 RTL 四段式、接口契约、功能回归、综合/STA 或 PPA hard gate。

## 自检

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py audit
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py self-test
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py cli-self-test
```
