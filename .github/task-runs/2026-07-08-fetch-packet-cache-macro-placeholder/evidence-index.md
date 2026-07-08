# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-fetch-packet-cache-macro-placeholder
- `task_slug`: 
- `profile`: 
- `asset_count`: 14
- `total_size_bytes`: 13499

## 证据资产

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/audit-db-first.log

- `kind`: log
- `size_bytes`: 124
- `line_count`: 1
- `sha256`: 277ec0a7d94478ed5bd88a5bef7ff7a71f43a45eb83aab3133e02c7296ec869d
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=124 bytes; lines=1; PASS=2; tail=PASS db-first-audit candidates=4670 stored=4692 materialized=4561 shims=13 backup_entries=4798 backup_dir=.github/db-backup

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/check-fetch-cache-macro-contract.log

- `kind`: log
- `size_bytes`: 223
- `line_count`: 3
- `sha256`: ed57289f07943d114bdec4af2d5e2cd4188accac06dacf989a5954af565209a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=223 bytes; lines=3; PASS=6; tail=PASS fetch-spec facts=14 PASS macro-boundary facts=8 PASS fetch cache macro placeholder contract fetch_spec=npc/rv64/design/specs/ooo-fetch-packet-cache.md macro_spec=npc/rv64/design/specs/yosys-macro-boundary-contracts.md

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/check-macro-contracts.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 9
- `sha256`: d8188a01effb3237ca7d556a8456813949319661979022e4328317dc1202a73d
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=848 bytes; lines=9; PASS=18; tail=PASS spec contract rows modules=4 path=npc/rv64/design/specs/yosys-macro-boundary-contracts.md PASS rtl module=OooFetchPacketCache file=npc/rv64/vsrc/cache/OooFetchPacketCache.v PASS rtl module=OooDataWordCache file=npc/rv64/vsrc/cache/OooDataWordCache.v PA...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/doctor.log

- `kind`: log
- `size_bytes`: 89
- `line_count`: 5
- `sha256`: 27c1f0e4e6f991b584d3a3b8d4bba29ccf05b1d488b3686057dec7f0b248c81d
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=89 bytes; lines=5; markers=<none>; tail=doctor=github-index blocking_drift=0 indexed=9573 skipped_binary=453 skipped_encoding=45

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/git-status-scope.log

- `kind`: log
- `size_bytes`: 6530
- `line_count`: 123
- `sha256`: 4313214ba00bcd4c700c5a18edf3a4f770e03e7689f8bb100f91d6491289d16b
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=6530 bytes; lines=123; markers=<none>; tail=M .github/db-backup/stored-snapshot/manifest.json M .github/db-backup/task-runs/manifest.json M .github/e2e/modules/toolchain.md M .github/e2e/modules/yosys-sta.md M .github/memory/claude-auto-memory/serialize-at-retire-flush-lsu-obstacle.md M .github/memor...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/profile-agent-system.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 5
- `sha256`: f98d8a2a666de23b990fb64503e6f6fea0fd0f6da70d32b5d287a5d834ccc5ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=404 bytes; lines=5; markers=<none>; tail=[agent-e2e] scenario-runtime-isolation profile=agent-system mode=integrated [agent-e2e] profile=agent-system [agent-e2e] run_dir=.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder-4 [agent-e2e] report=.github/task-runs/2026-07-08-fetch-packet...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/profile-npc-dev.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 8
- `sha256`: 03789afa5e1a2ed0066137fbf522ad0fe17bbf36d7c6b230afb31180c1c7bfb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=8; PASS=4; tail=[agent-e2e] profile-boundary=npc-dev mode=NPC-only [agent-e2e] PASS profile-boundary npc-dev NPC-only closure your 131072x1 screen size is bogus. expect trouble [agent-e2e] PASS scenario-runtime-isolation profile=npc-dev mode=npc policy=warn [agent-e2e] pro...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/profile-yosys-sta.log

- `kind`: log
- `size_bytes`: 398
- `line_count`: 5
- `sha256`: b1ffa0f87a577d9d616556ece91db6b4f09c5283da6abc8cbc58b7b1693f3ab4
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=398 bytes; lines=5; markers=<none>; tail=[agent-e2e] scenario-runtime-isolation profile=yosys-sta mode=integrated [agent-e2e] profile=yosys-sta [agent-e2e] run_dir=.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder-3 [agent-e2e] report=.github/task-runs/2026-07-08-fetch-packet-cache...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/py-compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/strict-guard.log

- `kind`: log
- `size_bytes`: 3079
- `line_count`: 6
- `sha256`: 12c2af38e2cd6b9469f0c9ba3adf4f68d0626d89f5c5d72f703b0b098fa9a0a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=3079 bytes; lines=6; PASS=10; tail=[agent-e2e-guard] mode=strict changed_paths=479 required_profiles=5 [agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder-4 reason=.github/e2e/modules/toolchain.md; .github/e2e/modules/yosys-s...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/tb-fetch-cache.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 12
- `sha256`: 6fc18dc7213815713d6b21acc80dbdd6f15faf5bad48ba6f2c58b5ca4f77a3ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=427 bytes; lines=12; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/tb-fetch-cache - tool: Icarus Verilog...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/tb-fetch-cache/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cd8480749ebac9d9cec775b636793659860f141bbae7ac053cb6f82c4ffa2414
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/tb-fetch-cache/summary.txt

- `kind`: txt
- `size_bytes`: 280
- `line_count`: 10
- `sha256`: f1c58b7aedaf2f89f2504e9b1d5cc4577b2b6558e81cc72839e566c6adc93248
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T23:30:16+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=280 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/tb-fetch-cache - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_fetch_packet_cache - total: 1 - pa...
