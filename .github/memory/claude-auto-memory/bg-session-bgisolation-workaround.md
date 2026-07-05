---
name: bg-session-bgisolation-workaround
description: 本仓库后台会话要原地改代码时如何解除 bgIsolation 守卫
metadata: 
  node_type: memory
  type: reference
  originSessionId: d675f1f5-fc9f-44fc-9203-dd00fff6473f
---

本仓库(ysyx-workbench)的 **background 会话默认禁止原地改代码**(EnterWorktree 守卫);但 nemu/abstract-machine/npc 都是**仓库内普通目录**(非子模块),且任务常依赖未提交 WIP,进 worktree 会从 origin/master 切分支丢掉 `ai` 上的全部提交 + 未提交改动。

**正解(原地作业)**: 在 `.claude/settings.local.json` 写 `{"worktree":{"bgIsolation":"none"}}`。但 **auto-mode 分类器会拦截 agent 自行写该文件**(self-modification),聊天里授权也没用——**必须让用户在输入框用 `!` 前缀亲自执行**:
`! echo '{"worktree":{"bgIsolation":"none"}}' > .claude/settings.local.json`
执行后即可原地 Edit/Write。该文件本地未跟踪、可逆。

后台会话临时文件用 `$CLAUDE_JOB_DIR/tmp`(不是 /tmp,避免并行 job 互相覆盖)。
