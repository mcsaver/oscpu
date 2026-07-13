# Agent Brief

- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: FP issue queue integer wake fast select cross domain timing
- `token_estimate`: 1209 / 2400
- `command`: `python3 scripts/github_index_db.py brief "FP issue queue integer wake fast select cross domain timing" --profile npc-dev`

## Bounded recall result

DB-first 查询命中 `npc-dev`（score 8），回召 root/`.github` AGENTS 契约、
Copilot instructions、project-status、known-issues、e2e README 与 `npc-dev.tsv`。
数据库未找到更细的 NPC module memory，因此 T3F 根因与切点使用 T3E fresh
netlist/OpenSTA top40 与 live RTL 进行有界分析。

Profile 可执行入口为 `scripts/agent-e2e.sh --profile npc-dev`。
