# Evidence Index

| Evidence | Classification | Retention |
| --- | --- | --- |
| `.github/shujuku_aireview/` | 一次性 DB/AI review 展开材料 | 不作为 active source；由 `.gitignore` 忽略，本地保留或外置到 artifact store。 |
| `.github/archive/legacy-ai-dev-env-2026-06-13/outputs/` | 旧手工输出实体 | 不跟踪；Git 只保留 archive manifest/checksums/pointers。 |
| `.github/archive/legacy-ai-dev-env-2026-06-13/e2e-manual/` | 旧手工 e2e 证据实体 | 不跟踪；需要回查时走外部 artifact 或历史索引。 |
| `deliverables/ai-dev-env-commercial-v1/package/` | 旧商业生成包 | 不跟踪；新包生成到 `dist/ai-dev-env-commercial-v1/package/`。 |
