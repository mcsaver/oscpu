# E2E Profiles

每个 `.tsv` 文件是一个可执行 profile。格式：

```text
node_id|module|function|owner_agent|inputs|outputs
```

特殊行：

```text
@include|profile-name||||
```

用于复用其它 profile 的节点，例如 `quick` 复用 `discovery`。

改动 profile 后先跑：

```bash
scripts/agent-e2e.sh --validate-all-profiles
```

该命令只检查 profile 展开和 `scripts/e2e/modules/*.sh` 函数绑定，不执行具体 gate。
