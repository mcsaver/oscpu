---
name: worktree-agent-base-fresh-gotcha
description: "历史 worktree base 问题；不再固定 origin/master 或 ai，只要求核实实际 HEAD、文件与 dirty state"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0f469065-9395-43a3-bc78-2c6ef32f80ca
---

> **历史 / superseded（2026-08-23）**：旧工具曾以 `fresh` 从 `origin/master` 创建 worktree，而当时
> rv64 实现在 `ai` 分支，导致隔离代理看到过期树。具体分支关系会变化，不能作为当前规则。

仍有效的工程教训是：派发或分析前核对实际 `git rev-parse HEAD`、目标文件是否存在以及 dirty worktree，
不要仅凭 worktree UI 的标签推断代码身份。发现上下文不对时先停止该子任务并选择包含当前用户修改的
正确工作树。

不得从本条目自动 `merge --ff-only ai`、切换分支或修改本地设置；这些动作必须由当前任务范围和真实仓库
状态决定。关联 [[bg-session-bgisolation-workaround]]，两者都只作历史工具故障说明。
