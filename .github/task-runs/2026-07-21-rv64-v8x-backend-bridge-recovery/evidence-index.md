# Evidence Index

## 基本信息

- `task_id`: 2026-07-21-rv64-v8x-backend-bridge-recovery
- `task_slug`: 
- `profile`: 
- `asset_count`: 10
- `total_size_bytes`: 444049

## 证据资产

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/README.md

- `kind`: md
- `size_bytes`: 457
- `line_count`: 8
- `sha256`: 3286de81cdbcc6d5e971241140b9cb182a7fb2c532b246d0447873c15af84edb
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 2}
- `summary`: md evidence; size=457 bytes; lines=8; PASS=2; tail=# V8X evidence 此目录只保存本轮命令、日志、哈希、变异摘要和独立审查产物。未生成的证据不得在 task report 中写成 PASS。 权威入口为 `make -C npc/rv64 check-backend-bridge-recovery`。它串行执行 focused 正例、两项 compile-success RTL 验证变异、五项相邻回归、`check-contract`、scoped diff check 和 SHA-256 manifest。审查结论只解释这些本地 RV64 RTL...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/check-contract.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 9
- `sha256`: 37d72c3306bcb216fa43a284f5c21109f988e729f2f307405a98a60cfcda6b8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=9; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 13 tests in 3.539s OK [PRODUCER-HOLDER-CENSUS] PASS direct=20 packed=5 token_q=15 generation=1 契约立即断言（$error）计数：当前=...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/focused/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log

- `kind`: log
- `size_bytes`: 158678
- `line_count`: 1166
- `sha256`: c510705ccb71623552c8c03ebc65fefb9e92f86d04e8d1a56420cbd61ec4c3d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=158678 bytes; lines=1166; PASS=3; tail=v64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/regressions/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24970
- `line_count`: 137
- `sha256`: a69649b455b64c42160c44f67773b9bf954fbbf47ee267893335ed9946254821
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24970 bytes; lines=137; PASS=10; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8x-regression-build/tb_ooo_core_top_glue.vvp /...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/regressions/logs/tb_ooo_dual_mem_bridge_wrapper.log

- `kind`: log
- `size_bytes`: 138484
- `line_count`: 1039
- `sha256`: f173255a16a9432105325c748d072503518a6bdf777800bae94a6688974d7e1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=138484 bytes; lines=1039; PASS=4; tail=sitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/regressions/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26254
- `line_count`: 222
- `sha256`: 689edf588d45d06807ecee95857ea58fd7b704f99175dce265260f97290c7e0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"ERROR": 2, "PASS": 94}
- `summary`: log evidence; size=26254 bytes; lines=222; ERROR=2; PASS=94; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8x-regression-build/tb_ooo_int_backend.vvp /home/l...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/regressions/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 20737
- `line_count`: 135
- `sha256`: 6e0aa3bf996fcf29712ae8fc7c18c27e9cf6b3f028820b23664149045b17001a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=20737 bytes; lines=135; PASS=8; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/regressions/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71746
- `line_count`: 555
- `sha256`: 525a73d4e4fc242badf29b055db553f4cd5823b94882e2772bb97004c47caec4
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=71746 bytes; lines=555; PASS=26; tail=ry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in ar...

### .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/evidence/sha256-manifest.txt

- `kind`: txt
- `size_bytes`: 2273
- `line_count`: 14
- `sha256`: 705ec7374ccec0b57c90b306f0d5de48e7aa9baf6609806172421c3009056001
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T06:29:31+00:00
- `markers`: {}
- `summary`: txt evidence; size=2273 bytes; lines=14; markers=<none>; tail=772960e9e14622ab8e551e9b9fb28d7ee26c0e1e65120fcba6cc89cbf81c0cee /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v 6d3bed55ae4b00fe28400877ff85246cb40681a965b05c938687565849232174 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBri...
