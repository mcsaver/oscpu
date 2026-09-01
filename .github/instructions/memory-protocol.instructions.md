---
description: "可选的持久化记忆协议。仅在任务需要历史召回、跨会话稳定事实或长期工程决定时使用；不作为普通分析、实现或验证的启动/完成门。"
applyTo: ".github/memory/**,.github/task-runs/**,scripts/dev_memory/**,scripts/github_index_db.py"
---

# 持久化记忆协议

memory 的职责是保存稳定、跨会话可复用的工程事实和决定。它不是工作日志、任务权限、完成证明或每轮
必经状态机。

## When to read memory

仅在下列情况读取 memory/DB：

- 用户询问历史状态、既有决定或为什么采用某方案；
- 当前问题跨模块，直接源码无法解释已有工程选择；
- 任务从过去会话继续，需要恢复已验证结论或长期未决项；
- 用户明确要求使用项目记忆。

普通局部 review、修 bug、实现、构建和验证先读取直接相关源码、spec、README、配置与测试。不要默认
加载 project-status、known-issues、所有 module memory、旧 task-run 或 blueprint。

需要历史召回时优先使用有界查询：

```bash
python3 scripts/github_index_db.py brief '<focus>' --profile <profile>
python3 scripts/github_index_db.py runs --profile <profile>
python3 scripts/github_index_db.py evidence --run-id <run-id>
```

只打开查询指向且确实影响当前决策的内容。历史记录是线索；实际 worktree、当前配置和本轮验证优先。

## What belongs in memory

适合保存：

- 已采用且仍有效的架构/接口决定与理由；
- 经验证的非显然 root cause 和可复用诊断入口；
- 跨会话 current 状态、明确 owner 或长期 GAP；
- 后续任务会依赖的稳定工程约束。

不保存：

- token-by-token 过程、完整终端日志或临时 debug 输出；
- 普通任务的每一步、todo 状态、marker/hash 数量；
- 未验证猜测、短期 workaround 或 agent 自创 permission gate；
- 已可从源码、测试或生成配置直接得到的重复事实。

task-run 用于显式跨会话长跑、release/security/forensic/publication 或用户要求的单次证据，不默认创建。
短任务的命令、返回码和结果直接在最终报告中说明即可。

## DB-backed stored documents

`.github/memory/` 中以 `# DB-backed ...` 开头的文件是兼容 shim，正文位于
`.github/cache/github-index.sqlite`。读取单份正文：

```bash
python3 scripts/github_index_db.py load --source stored --path <repo-relative-path>
```

只有决定写入稳定事实时才更新。`update-stored` 是整体替换，不是 append API；必须保持以下数据安全步骤：

1. 用 `load --source stored` 导出完整原文到临时文件；
2. 在临时文件中做最小编辑，并核对原有无关内容仍存在；
3. 用 `update-stored <path> --from-file <file> --refresh-shim` 整体写回；
4. 追加型更新确认写回字节数没有意外缩小。

禁止把“只有新条目的短文件”直接传给 `update-stored`，这会覆盖已有正文。发生意外缩水时停止写入，并从
已知有效 backup 恢复。子 agent 未被明确授权更新 memory 时，只返回建议条目，由 owner 统一写回。

这些步骤保护真实持久数据；它们只在选择写 memory 时生效，不要求普通任务建立 DB snapshot、manifest、
rehydrate 或 audit 链。`audit-db-first` 仅用于 DB 工具开发、迁移、恢复或显式 publication 检查。

## Completion and compaction

完成判定回到用户 objective 与 acceptance criteria：

- 长期路线图中的一个切片完成，不等于整体目标完成；
- 低层 smoke、单个 profile/node 或 verifier PASS 不得越级；
- 有未满足的用户明确要求时，报告已完成范围和剩余 GAP；
- memory 是否更新不会改变工程结果。

上下文压缩后按 objective、acceptance criteria、实际 worktree、hard constraints、当前 build/test evidence
恢复。过去 memory 中的流程建议、临时 gate、phase、marker 或单 shell 规则不会自动继承；只有仍对应
用户要求或真实 correctness/safety invariant 的约束继续有效。

## Writing style

新条目应短、可定位、可证伪，至少写清日期、工程对象、稳定结论、验证依据或代码入口、适用范围。不要
复制完整日志或本轮协调流水账。若事实仍不稳定，保留在当前任务报告中，不急于写入长期 memory。
