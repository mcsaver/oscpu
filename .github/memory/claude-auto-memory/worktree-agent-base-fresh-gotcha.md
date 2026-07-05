---
name: worktree-agent-base-fresh-gotcha
description: "worktree 隔离代理默认从 origin/master(fresh) 分叉,缺 ai 分支近期工作;须先 ff 到 ai 或核实 HEAD"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0f469065-9395-43a3-bc78-2c6ef32f80ca
---

Agent(isolation:"worktree") 与 EnterWorktree 默认 `worktree.baseRef=fresh` → 从 **origin/master** 分叉建 worktree。本仓库 `ai` 分支领先 master 数百 commit(整个 rv64 OoO 核都在 ai 上),所以 fresh worktree **不含 rv64 核文件**,派进去的代理会在空树上分析、结论全错。

**Why:** 死硅删除/RTL 改动类 worktree 代理必须在当前 `ai` HEAD 上工作;fresh base 缺料会让"死活判断"参照远古代码而失效。

**How to apply:**
- 给 worktree 代理的 prompt 里显式加一步:开工前若发现 rv64 核缺失,先 `git merge --ff-only ai` 快进到当前 HEAD(聪明代理会自己做,但别指望)。
- 或在 `.claude/settings.local.json` 的 `worktree` 段加 `"baseRef":"head"` 让 worktree 从本地 HEAD 分叉(需确认设置生效)。
- **判断 worktree 实际 base 用 `git -C <wt> rev-parse HEAD`,不要信 `git worktree list` 的显示列**——后者可能显示分叉基点而非快进后的实际 HEAD,我曾据此误杀 3 个有效代理。

关联 [[bg-session-bgisolation-workaround]](同为本仓库 worktree/后台会话的环境坑家族)。
