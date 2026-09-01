# E2E Profiles

每个 `.tsv` 文件是一个显式可执行 profile。格式：

```text
node_id|module|function|owner_agent|inputs|outputs
```

`@include|profile-name||||` 用于有意复用另一 profile 的工程节点。业务 profile 不应自动 include
`discovery`、`software-flow` 或 memory/agent 文件存在性检查；只有 AI 环境合同本身可以这样组合。

修改 profile 后可运行：

```bash
scripts/agent-e2e.sh --validate-all-profiles
```

该命令只检查 TSV 展开、场景边界和函数绑定，不执行 workload，也不是普通业务任务的前置条件。

profile 默认生成 compact 直接结果，不刷新 DB、不做 recall、不发布 SHA/manifest。只有明确的
release/security/forensic/publication 才追加 `--publish`；hash 与 durable task-run 只保护该持久化边界。

重型 NEMU Ubuntu 性能采样可显式运行：

```bash
AGENT_E2E_NEMU_PROFILE_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-profile
```

该 profile 是 NEMU-only 的高成本诊断，不得自动加入 NPC-only 或普通修改。opcode mix、stop detail、
decode-cache、RVC detail、host perf 和 guest-counter 等额外采样都应按当前性能假设显式打开；历史数值与
负实验保留在对应 task-run/性能报告中，不作为新任务的固定前置或永久基线。
