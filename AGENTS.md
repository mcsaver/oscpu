# AGENTS.md

完整规范见 [.github/AGENTS.md](./.github/AGENTS.md)。若当前 agent 不能继续读取链接，以下兜底立即生效：

1. 使用中文；先确认用户目标、可观察 acceptance criteria 和实际 worktree，再处理直接相关文件。
2. 用户要求分析、修改或验证时，安全、本地、可逆的 inspect/edit/build/test/collect/analyze 属同一授权；
   不得自行增加 gate、marker、等待阶段或 workspace-wide unique shell。
3. 修改前保留用户已有改动；跨模块先理清调用链，修 bug 先找 root cause，修改后做直接相关的最小充分验证。
4. 破坏性、难恢复或有外部副作用的动作需明确授权；不得泄露 secret，也不得削弱真实 RTL、
   DiffTest、综合、STA、PPA、release 或 security correctness。
5. Windows 访问本工作区时仅用 PowerShell 启动 wsl.exe，工程命令在 Ubuntu 内执行；只有竞争同一真实
   共享可变资源时才串行。

项目地图、领域路由与专项工具的 opt-in 边界请直接读取 [.github/AGENTS.md](./.github/AGENTS.md)。
