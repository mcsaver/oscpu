# YSYX AI Dev Environment Commercial v1

这是当前工作区 agent operating contract 与可选支撑工具的可交付面。核心行为是：从用户目标、可观察
acceptance criteria 和实际 worktree 出发，直接完成安全、本地、可逆的工程动作，并用最小充分证据报告
结果。DB、memory、agent-flow、task-run、E2E profile 和发布索引都是按需设施，不是普通任务的前置阶段。

## 交付定位

本包提供一个轻量的根合同、领域路由、专项 correctness 规则和显式 release 工具：

- `.github/AGENTS.md` 是通用行为真源；入口文件保持薄 shim。
- 领域 instruction 保留 RTL、DiffTest、Linux、综合、STA、PPA 等真实工程边界。
- `agent-flow`、memory 和 E2E 可在持久长跑、跨会话协作或正式发布时显式选用。
- runtime artifact boundary 把源码、索引与重型 payload 分开。
- commercial release 由单一维护入口完成合同、发布和 package 检查。

## 快速验证

```bash
scripts/agent-maintain.sh --mode release
```

## 打包

```bash
scripts/package-ai-dev-env.sh
```

生成目录：

```text
dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/
```

旧手工产物已经归档到 `.github/archive/legacy-ai-dev-env-2026-06-13/`，不再作为 active delivery surface。
