# ysyx AI Hardware 开发环境便携包

这个目录是从 ysyx-workbench 中抽出的 AI 硬件工程师开发环境模板，目标是让另一套工作区快速复刻同一套工作流：

1. 先明确工程目标：开发一颗可验证的 RV32 CPU / SoC。
2. 让 AI 写 RTL 时同步建立 module testbench。
3. 用 module testbench、Verilator、NEMU、DiffTest、trace/log 形成反馈标准。
4. 把稳定规则写入 `instructions`，把长期事实写入 `memory`，把单次任务证据写入 `task-runs`。
5. 通过根目录 shim 让 Copilot、Codex、Claude、Gemini、Cursor、Windsurf 等入口回到同一套规范。

## 目录说明

```text
.github/
  AGENTS.md                         # 跨 agent 总入口
  copilot-instructions.md            # Copilot/Copilot Chat 入口
  agentic-hardware-blueprint.md      # 硬件 agent 图任务蓝图
  agents/*.agent.md                  # 各模块 agent 岗位说明
  instructions/*.instructions.md     # 可复用工程纪律
  memory/                            # 长期项目记忆，已做路径/学号占位符脱敏
  task-runs/templates/               # 单次任务记录模板

.cursor/rules/agents.mdc             # Cursor 入口
AGENTS.md                            # 通用 agent shim
CLAUDE.md / GEMINI.md                # Claude/Gemini 入口 shim
CONVENTIONS.md / .windsurfrules      # 其他工具入口 shim
docs/                                # 复刻环境所需的工程入口文档
examples/env.example.sh              # 环境变量示例
```

## 使用方式

1. 把本目录内容复制到目标仓库根目录。
2. 根据自己的机器修改 `examples/env.example.sh`，并把变量写入 shell 启动脚本或项目环境脚本。
3. 全局替换模板占位符：
   - `<YSYX_ID_TOP>`：你的 ysyx CPU 顶层名，例如 `ysyx_XXXXXXXX`
   - `<YSYX_ID_NUM>`：你的数字学号或 marchid
   - `${YSYX_HOME}`：目标 workbench 根目录
   - `${LOCAL_BIN}`：本机用户级工具目录
   - `${RISCV_TOOLCHAIN_ROOT}`：RISC-V 工具链根目录
4. 在目标仓库让任意 AI 入口先读取 `AGENTS.md`，确认它能继续追到 `.github/AGENTS.md`。
5. 跑第一轮 smoke：先 module testbench，再 NPC/NEMU/DiffTest，再把结果写入 `.github/task-runs/<date-task>/`。

## 打包策略

这个包默认没有携带历史 `.github/task-runs/YYYY-*` 任务记录，只保留模板；历史任务记录适合私有迁移，不适合直接发送给别人。

包内已做机械脱敏，但接收方仍应在使用前检查 `memory/` 中的工程事实是否适合自己的项目阶段。
