# AI Environment Layout

`.github/ai-env/` 保存 AI 开发环境的可审计 contract。旧的 `.github/agent-env-*.json` 只保留兼容 shim，真实 source-of-truth 位于 `contracts/`。

日常开工、单一真源选择和使用中反馈回流统一从仓库根 `AI_ENVIRONMENT.md` 进入；本目录 README 只解释 contract 布局，不承担第二套全局导航。

## 目录

- `contracts/`：Database / Skill / Agent 三层 contract、delivery contract、runtime artifact contract、branch-health、review routing 与本地 RTL 子任务契约。
- `../skills/`：live skill 规则。
- `../agents/`：agent profile shim 和 `AGENT_INDEX.md`。
- `../e2e/`：profile、模块说明和 e2e 调度资料。
- `../task-runs/templates/`：task-run 模板。

## Rehydrate

```bash
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/stored-snapshot --yes
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/task-runs --yes
```

## Gate

```bash
python3 scripts/github_index_db.py policy-audit
python3 scripts/github_index_db.py schema-audit
python3 scripts/github_index_db.py artifact-audit
python3 scripts/github_index_db.py delivery-audit
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-maintain.sh --mode check
```

## 产物边界

`deliverables/` 只放交付源文档、模板和验收定义。商业生成包写入 `dist/`。archive、runtime artifact、cache DB、重型 evidence 和一次性审计展开目录不作为 active source。
