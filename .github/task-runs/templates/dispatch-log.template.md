# 派发日志

## 基本信息

- `task_id`:
- `task_slug`:
- `graph_template`:
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [YYYY-MM-DD HH:MM] `node_id` - `status`

- `owner_agent`:
- `trigger`:
- `depends_on`:
- `inputs`:
- `task_contract`: `<subagent-contracts/<id>.json + sha256 | 不适用>`
- `access_boundary`: `<read-only | explicit-write-paths | 不适用>`
- `action`:
- `outputs`:
- `evidence`:
- `handoff_to`:
- `next_step`:
- `notes`:
