# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-md-staleness-audit`
- `task_slug`: `md-staleness-audit`
- `graph_template`: `agent-env-refactor`
- `log_policy`: `append-only`

---

### [2026-05-19 17:06] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求修复项目中过时的 `.md`
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、相关模块笔记
- `action`: 读取工作区规则和长期记忆，定位当前状态型 Markdown。
- `outputs`: 识别出 NEMU GPU 高级 ABI、klib 格式化、NEMU `inst.c` X-macro 决策三类过时表述。
- `evidence`: `sed` 与 `rg` 输出显示 `known-issues.md` 仍把 NEMU devscan GPU 缺口列为活跃问题，模块笔记仍有旧状态。
- `handoff_to`: `audit-md`
- `next_step`: 用源码和后续记录确认哪些条目确实过时。
- `notes`: 当前工作区已有大量未提交改动，本轮只做精确 Markdown patch。

### [2026-05-19 17:06] `audit-md` - `completed`

- `owner_agent`: Codex
- `trigger`: `recall` 发现冲突条目
- `depends_on`: `recall`
- `inputs`: `abstract-machine/am/src/platform/nemu/ioe/ioe.c`、`abstract-machine/am/src/platform/nemu/ioe/gpu.c`、`abstract-machine/am/src/platform/gpu_soft.h`、`abstract-machine/klib/src/stdio.c`、`nemu/src/isa/riscv32/inst.c`
- `action`: 静态核对源码能力与 Markdown 当前描述。
- `outputs`: 确认 `AM_GPU_MEMCPY/AM_GPU_RENDER` 已注册并实现；`GPU_CONFIG` 当前报告高级能力；`kvsnprintf()` 已支持常用整数格式；`inst.c` 已不再使用 X-macro 表生成层。
- `evidence`: `rg -n "AM_GPU_MEMCPY|AM_GPU_RENDER|gpu_soft|kvsnprintf|X-macro"` 与对应源码读取。
- `handoff_to`: `patch-md`
- `next_step`: 更新 memory Markdown。
- `notes`: `scripts/am-regression.sh` 仍有旧 `KNOWN_ISSUE` 文案，但不属于本轮 Markdown 范围。

### [2026-05-19 17:06] `patch-md` - `completed`

- `owner_agent`: Codex
- `trigger`: `audit-md` 完成
- `depends_on`: `audit-md`
- `inputs`: 已确认的过时条目
- `action`: 修改 `known-issues.md`、`modules/abstract-machine.md`、`modules/am-kernels.md`、`modules/nemu.md`、`decisions.md`、`project-status.md`，并新增本 task-run 记录。
- `outputs`: 已解决问题从活跃区归档；模块笔记和设计决策不再把旧实现当当前事实。
- `evidence`: `apply_patch` 成功。
- `handoff_to`: `verify`
- `next_step`: 做静态检索验证。
- `notes`: 未删除历史流水账，只修正“当前状态”和“活跃问题”分类。

### [2026-05-19 17:06] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: `patch-md` 完成
- `depends_on`: `patch-md`
- `inputs`: 更新后的 Markdown
- `action`: 运行针对性 `rg` 检索和 `git diff -- .github/memory` 检查。
- `outputs`: 待最终回复汇总。
- `evidence`: 见本轮终端验证输出。
- `handoff_to`: 无
- `next_step`: 向用户说明改动与验证缺口。
- `notes`: 未运行完整构建或 AM 测试。
