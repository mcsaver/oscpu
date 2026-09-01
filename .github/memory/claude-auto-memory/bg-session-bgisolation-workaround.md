---
name: bg-session-bgisolation-workaround
description: 历史 Claude BG isolation 环境问题；已 superseded，不是当前授权或用户操作要求
metadata: 
  node_type: memory
  type: reference
  originSessionId: d675f1f5-fc9f-44fc-9203-dd00fff6473f
---

> **历史 / superseded（2026-08-23）**：以下问题描述旧 Claude 工具环境，不能作为当前 write 权限、
> branch 选择或二次授权依据。

旧环境曾出现 background session 被 `bgIsolation` 阻止原地写入、隔离 worktree 又看不到当时 WIP 的问题，
因此留下了修改 `.claude/settings.local.json` 并要求用户执行 `!` 命令的 workaround。该 workaround 已废弃：
不得预设 BG 会话无权编辑，不得要求用户先改 setting，也不得把工具分类器当作工程 permission gate。

当前稳定原则只有两条：先核对实际 worktree/HEAD 并保护未提交修改；只有会竞争同一 build 目录、数据库、
端口、设备等真实共享可变资源时才隔离或串行。若当前工具真的拒绝写入，应报告具体错误并按现有能力
选择安全 worktree，而不是从本条历史记录推导授权限制。
