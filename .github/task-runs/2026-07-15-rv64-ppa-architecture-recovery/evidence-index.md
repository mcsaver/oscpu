# Evidence Index

## 基本信息

- `task_id`: 2026-07-15-rv64-ppa-architecture-recovery
- `task_slug`: 
- `profile`: 
- `asset_count`: 183
- `total_size_bytes`: 2470746

## 证据资产

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/candidate-live-negative.log

- `kind`: log
- `size_bytes`: 308
- `line_count`: 4
- `sha256`: 8a34854d66cd04017bd5a20f3f2650a5976e9ee9324fb170ddd4d80490f51c50
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=308 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/OooRob.v:548: [S2-Q2-V8A-CANDIDATE-LIVE] retire candidate lost live/done/recovery provenance @10 Time: 10 Scope: tb_ooo_rob.dut FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/OooRob.v:55...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/candidate-live-negative.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/check-contract.log

- `kind`: log
- `size_bytes`: 279
- `line_count`: 4
- `sha256`: 90a893f2f4346ac4494eeb4a01a425cf27f989fbe50afb72044cb0592b88316e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=279 bytes; lines=4; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=289 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 289≥89 ✓） make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/check-rtl-style.log

- `kind`: log
- `size_bytes`: 232
- `line_count`: 3
- `sha256`: 96c33fde944e1dfe18479810ebbb194ce79d090de0454e240cebdb1f88732078
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=232 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/checker-self-test.log

- `kind`: log
- `size_bytes`: 993
- `line_count`: 18
- `sha256`: aa111bad054263ef4593f71fa7c542ef15a1837e505931592b91ab5b83b11ae2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 36}
- `summary`: log evidence; size=993 bytes; lines=18; PASS=36; tail=[S2-Q2-V8A-SELFTEST][PASS] exact-instance-accepted [S2-Q2-V8A-SELFTEST][PASS] wrong-instance-map-killed [S2-Q2-V8A-SELFTEST][PASS] missing-context-permit-killed [S2-Q2-V8A-SELFTEST][PASS] missing-fencei-permit-killed [S2-Q2-V8A-SELFTEST][PASS] precommit-com...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/complete.marker

- `kind`: marker
- `size_bytes`: 330
- `line_count`: 5
- `sha256`: a8857560a35fb0ed4f9ee5dac4c06fc733d966f0f95930a5963383a2fb2daba8
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: marker evidence; size=330 bytes; lines=5; markers=<none>; tail=status=complete contract_schema=s2-q2-shadow-foundation-interface-v8a summary_sha256=1a41eefb6494a62cb237cc5a498097d4aea45c52b9a874ba0b57c1cc0affe697 evidence_inventory_sha256=02cd5aa59314451f09a09a6e34315cf50a0e990c09d89079b08577114f4f689a source_inventory...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-enabled.base.log

- `kind`: log
- `size_bytes`: 1080
- `line_count`: 10
- `sha256`: 5719ed259cdaf0b7e84e084ebc5d590b4fb4e383ce8088f98755930c28895487
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1080 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_rob -o /tmp/ysyx-v8a-green.B9ZSLr/csr-qh-enabled/build/t...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-enabled.log

- `kind`: log
- `size_bytes`: 409
- `line_count`: 6
- `sha256`: 79d88f900d92703ec510d021ebf3ec3a3839d11224cd226f9b97328be4f51f54
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=409 bytes; lines=6; PASS=6; tail=[S2-Q2-V8A-CSR-QH-PASS] explicit macro-enable behavior preserved [S2-Q2-V8A-DYNAMIC-PASS] candidate/identity/permit/retire-prefix/all-lane1-shadow coverage is non-vacuous [T3W-ROB-Q-RETIRE] dual writeback is absorbed before exact dual retirement [T4N-ROB-HE...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-enabled.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-explicit-zero.base.log

- `kind`: log
- `size_bytes`: 1086
- `line_count`: 10
- `sha256`: bef8309542f4e806f45a744b777cdb98878710892ade2ece079de413631d49a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1086 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=0 -s tb_ooo_rob -o /tmp/ysyx-v8a-green.B9ZSLr/csr-qh-explicit-zero/b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-explicit-zero.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 6
- `sha256`: ad0343b89a462f0ccc1cbe421f0042de63958860faf467e4bb35a72f777429d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=412 bytes; lines=6; PASS=6; tail=[S2-Q2-V8A-CSR-QH-ZERO-PASS] explicit numeric zero remains disabled [S2-Q2-V8A-DYNAMIC-PASS] candidate/identity/permit/retire-prefix/all-lane1-shadow coverage is non-vacuous [T3W-ROB-Q-RETIRE] dual writeback is absorbed before exact dual retirement [T4N-ROB...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/csr-qh-explicit-zero.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-candidate.base.log

- `kind`: log
- `size_bytes`: 208063
- `line_count`: 1512
- `sha256`: 47339aed133b3cdbb6482cd19cef7cd7df8928ae06ccd3310e1c28dc151505ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208063 bytes; lines=1512; PASS=2; tail=pChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-candidate.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-candidate.trace.gz

- `kind`: gz
- `size_bytes`: 20862
- `line_count`: 62
- `sha256`: ca555c366e22547a681f506692389e4eee217373eb964530be2612a16864148b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=20862 bytes; lines=62; markers=<none>; tail=� ��ݎ�̶��s�b���� 'qZZ �� $$ć8A ��݀� ,@�ݓr'�] #vj��?� ���|���ݳ ���� �o������������ �O�� �������� �'��?����. s �/?��o��E�� ��� ����?�]z��^�?ʋ�Ma�� ?:�C�8�/~� ������ߔO���|������ �������_� ��������� ��������o��/ �o���� \��?����Ͽ9���G��)W Wk� \�� �E���~�� �� \w�...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-reference.base.log

- `kind`: log
- `size_bytes`: 222652
- `line_count`: 1512
- `sha256`: 6f769a4356a36d06230dd0e6ea246a3e6bf01c9971c0f992202f8a6c6658742b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=222652 bytes; lines=1512; PASS=2; tail=reference/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /tmp/ysyx-v8a-green.B9ZSLr/reference/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-reference.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-ooo_assert-reference.trace.gz

- `kind`: gz
- `size_bytes`: 20862
- `line_count`: 62
- `sha256`: ca555c366e22547a681f506692389e4eee217373eb964530be2612a16864148b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=20862 bytes; lines=62; markers=<none>; tail=� ��ݎ�̶��s�b���� 'qZZ �� $$ć8A ��݀� ,@�ݓr'�] #vj��?� ���|���ݳ ���� �o������������ �O�� �������� �'��?����. s �/?��o��E�� ��� ����?�]z��^�?ʋ�Ma�� ?:�C�8�/~� ������ߔO���|������ �������_� ��������� ��������o��/ �o���� \��?����Ͽ9���G��)W Wk� \�� �E���~�� �� \w�...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-candidate.base.log

- `kind`: log
- `size_bytes`: 207509
- `line_count`: 1508
- `sha256`: 63e1f0bd19097ba6e80135b68c05605722db0fd842abd05d56128604b9b7afcf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=207509 bytes; lines=1508; PASS=2; tail=mory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-candidate.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-candidate.trace.gz

- `kind`: gz
- `size_bytes`: 20862
- `line_count`: 62
- `sha256`: ca555c366e22547a681f506692389e4eee217373eb964530be2612a16864148b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=20862 bytes; lines=62; markers=<none>; tail=� ��ݎ�̶��s�b���� 'qZZ �� $$ć8A ��݀� ,@�ݓr'�] #vj��?� ���|���ݳ ���� �o������������ �O�� �������� �'��?����. s �/?��o��E�� ��� ����?�]z��^�?ʋ�Ma�� ?:�C�8�/~� ������ߔO���|������ �������_� ��������� ��������o��/ �o���� \��?����Ͽ9���G��)W Wk� \�� �E���~�� �� \w�...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-reference.base.log

- `kind`: log
- `size_bytes`: 222062
- `line_count`: 1508
- `sha256`: a59eb11bc29fff2d690a6f4f56d21f61654bb45d0ef9f834860b32671ca18ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=222062 bytes; lines=1508; PASS=2; tail=B9ZSLr/reference/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /tmp/ysyx-v8a-green.B9ZSLr/reference/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_ad...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-reference.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-release-reference.trace.gz

- `kind`: gz
- `size_bytes`: 20862
- `line_count`: 62
- `sha256`: ca555c366e22547a681f506692389e4eee217373eb964530be2612a16864148b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=20862 bytes; lines=62; markers=<none>; tail=� ��ݎ�̶��s�b���� 'qZZ �� $$ć8A ��݀� ,@�ݓr'�] #vj��?� ���|���ݳ ���� �o������������ �O�� �������� �'��?����. s �/?��o��E�� ��� ����?�]z��^�?ʋ�Ma�� ?:�C�8�/~� ������ߔO���|������ �������_� ��������� ��������o��/ �o���� \��?����Ͽ9���G��)W Wk� \�� �E���~�� �� \w�...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/equivalence-summary.txt

- `kind`: txt
- `size_bytes`: 541
- `line_count`: 10
- `sha256`: 29dc444ae4cdcfc68d2fe5acc47acdfbf86144580184eb0aab547ac238761402
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=541 bytes; lines=10; PASS=4; tail=release_reference_lines=1036 release_reference_sha256=a7fe06e059e37f9053a9451749aec8eed3ee92478026e892126f1104abb5d98d release_candidate_lines=1036 release_candidate_sha256=a7fe06e059e37f9053a9451749aec8eed3ee92478026e892126f1104abb5d98d release_equivalence...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/evidence-check.log

- `kind`: log
- `size_bytes`: 3079
- `line_count`: 75
- `sha256`: 09e86da906ca7341254484ba1476bac9cc24fa799abde3df6e93a567dce63290
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=3079 bytes; lines=75; markers=<none>; tail=./candidate-live-negative.log: OK ./candidate-live-negative.rc: OK ./check-contract.log: OK ./check-rtl-style.log: OK ./checker-self-test.log: OK ./csr-qh-enabled.base.log: OK ./csr-qh-enabled.log: OK ./csr-qh-enabled.make.log: OK ./csr-qh-explicit-zero.bas...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/evidence.sha256

- `kind`: sha256
- `size_bytes`: 7729
- `line_count`: 75
- `sha256`: 02cd5aa59314451f09a09a6e34315cf50a0e990c09d89079b08577114f4f689a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=7729 bytes; lines=75; markers=<none>; tail=8a34854d66cd04017bd5a20f3f2650a5976e9ee9324fb170ddd4d80490f51c50 ./candidate-live-negative.log 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865 ./candidate-live-negative.rc 90a893f2f4346ac4494eeb4a01a425cf27f989fbe50afb72044cb0592b88316e ./c...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15728
- `line_count`: 95
- `sha256`: 5632e3841ee5ea1fd86cd64270eed24a4384223f10ba938a1a4fec426ca30082
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15728 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/buil...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_alu_core_slice.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15556
- `line_count`: 93
- `sha256`: 45f5b29cd6f5b116d4e40a979aec51dee838fedd764c3e94ff12ac0cec13655f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15556 bytes; lines=93; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_ass...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_alu_decode_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15792
- `line_count`: 69
- `sha256`: f29ef4b1eeba30e9af6c5cf5a546fb81c6f10ac917fdab6845254df2964aaebd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15792 bytes; lines=69; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/build/...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_core_top_glue.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5447
- `line_count`: 37
- `sha256`: 3e878a4b3bbd7fd45813dd1cafc8e736f91b0431e1032938ce2625e042a5fa16
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5447 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_dispatch_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18579
- `line_count`: 85
- `sha256`: db2c970741d8bf59a5046cdf1ed93ef46d4f43bede41e7ab79b12b774a72e269
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18579 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/bu...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_fetch_trap_gate.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13812
- `line_count`: 105
- `sha256`: b216b5c91559d1dd6aa974befdebfb3687770210b2d16eb8df419c6e79aa4c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"ERROR": 2, "PASS": 32}
- `summary`: log evidence; size=13812 bytes; lines=105; ERROR=2; PASS=32; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/build/tb_o...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_int_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15583
- `line_count`: 64
- `sha256`: 891fc93e2465cde2819d9503ab30a43fffa33432c056502dc2b33443cec465e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15583 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/build/tb_o...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_priv_system.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 10
- `sha256`: df4a535fde46e8fdc1f44fdbdf67d0e6ad93e1df972f9a2db305f19d7b82e914
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1061 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/ysyx-v8a-green.B9ZSLr/focused-ooo_assert/build/tb_ooo_rob.vvp /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-ooo_assert-tb_ooo_rob.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15174
- `line_count`: 91
- `sha256`: c26f09e963213bb7fd362e45302772dbcab45c8b41f6a0399a715aee1accbf8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15174 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_alu_core_slice -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_alu_cor...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_alu_core_slice.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15002
- `line_count`: 89
- `sha256`: 9ab6d0554082f100923eb40f6c96ac1ef6a59c5260bae6ad3decf4167acd303a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15002 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_alu_decode_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_alu_decode_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15238
- `line_count`: 65
- `sha256`: 833dcbeecbcee6c7691ecec652073dbd1406f3caa07f2ac811df84fe473e9480
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15238 bytes; lines=65; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_core_top_glue -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_core_top_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_core_top_glue.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5432
- `line_count`: 37
- `sha256`: fc2f0f31d8c21994b506a50743e883c50c78272429787dc27782382fd47e28fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5432 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_dispatch_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_dis...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_dispatch_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18025
- `line_count`: 81
- `sha256`: e5a4f543674b750ef84b62e0d64a55b9d5f7dbd98cf803b7d6d74208adde8d0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18025 bytes; lines=81; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_fetch_trap_gate -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_fetch...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_fetch_trap_gate.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13331
- `line_count`: 102
- `sha256`: 134c7ed368c9b1d68aebac22a10875d1eac7434a7cf526674a85befe62ec785e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"ERROR": 2, "PASS": 34}
- `summary`: log evidence; size=13331 bytes; lines=102; ERROR=2; PASS=34; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_int_backend -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_int_backend.v...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_int_backend.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15029
- `line_count`: 60
- `sha256`: 771ff2ac2907235e5d55074ca5ae780990f33578ef84a8e4ca86a4d239bf024e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15029 bytes; lines=60; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_priv_system -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_priv_system.v...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_priv_system.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1046
- `line_count`: 10
- `sha256`: 7bad7942c67da4a9f18d2bffdbf806c9dcf985ea15e49aa7f0bd2e889d53d24d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1046 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_rob -o /tmp/ysyx-v8a-green.B9ZSLr/focused-release/build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/focused-release-tb_ooo_rob.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/frozen-artifacts.sha256

- `kind`: sha256
- `size_bytes`: 1214
- `line_count`: 7
- `sha256`: f7e2af1520c11d1329184b5d75ba4abc42b2281a31ba36c5d85b6807f9808ba7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1214 bytes; lines=7; markers=<none>; tail=b0da714be24441ad53fcf28931bce10d5ad702b5839722432b5cd5a06cbaaf23 .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/s2-q2-shadow-foundation-v8a-contract.md 256fabfd26d1b6b11aab8d48c4253401c71af318bec839903484e53cee4b5bd2 .github/task-runs/2026-07-1...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/full-build.log

- `kind`: log
- `size_bytes`: 64165
- `line_count`: 691
- `sha256`: dc6c0815f24eb5f72b61a58ce78499b0114bb3939559d3a4c03c61470332f09c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=64165 bytes; lines=691; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/implementation-checker-self-test.log

- `kind`: log
- `size_bytes`: 333
- `line_count`: 6
- `sha256`: bf06524844bb9db6e7f0a15bbe3c46b915d86623525083e006c19c51b0280137
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=333 bytes; lines=6; PASS=12; tail=[S2-Q2-V8A-IMPL-SELFTEST][PASS] canonical-shape-accepted [S2-Q2-V8A-IMPL-SELFTEST][PASS] retire-prefix-drop-killed [S2-Q2-V8A-IMPL-SELFTEST][PASS] classifier-direct-gate-killed [S2-Q2-V8A-IMPL-SELFTEST][PASS] identity-recode-killed [S2-Q2-V8A-IMPL-SELFTEST]...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/implementation-readiness.log

- `kind`: log
- `size_bytes`: 1522
- `line_count`: 16
- `sha256`: a613198dfe19b8e777786ae3978784e18ecf046033bd34f27fa9b9c3f14801f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=1522 bytes; lines=16; PASS=2; tail=[S2-Q2-V8A-IMPL][CENSUS] npc/rv64/vsrc/core/NpcCoreTop.v:OooCoreTopGlue:u_ooo_core [S2-Q2-V8A-IMPL][CENSUS] npc/rv64/vsrc/core/OooCoreTopGlue.v:OooExecuteBackend:u_execute_backend [S2-Q2-V8A-IMPL][CENSUS] npc/rv64/vsrc/decode/OooAluDecodeBackend.v:OooIntBac...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-baseline-comparison.txt

- `kind`: txt
- `size_bytes`: 330
- `line_count`: 8
- `sha256`: 5cd33ce3f1878bd5ce0e72f169ba42d57774c2ebf924a3207bd828edf5a43e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=330 bytes; lines=8; PASS=2; tail=lint_gate=RED full_default_build_gate=RED warning_count_candidate=115 warning_count_pre_snapshot=115 warning_signature_breakdown=TIMESCALEMOD:108,PINCONNECTEMPTY:2,LATCH:4,UNOPTFLAT:1 normalized_warning_signature=MATCH nonfatal_parse_elaboration=PASS dispos...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-candidate.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-nonfatal-diagnostic.log

- `kind`: log
- `size_bytes`: 62583
- `line_count`: 685
- `sha256`: 9dbe89630ff044aaf81f9c068da60c277781c4754f838cfdc40658ce7cf9b712
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=62583 bytes; lines=685; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +def...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-pre-snapshot.log

- `kind`: log
- `size_bytes`: 53919
- `line_count`: 683
- `sha256`: 1d4ea938c1ad0988fd92d6d78a73ec50a944a0c035d7a6ae2dc03ce3027a9706
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=53919 bytes; lines=683; markers=<none>; tail=%Warning-PINCONNECTEMPTY: /tmp/ysyx-v8a-pre-ref-812fa351/npc/rv64/vsrc/execute/OooIntBackend.v:3931:6: Cell pin connected by name with empty reference: 'alloc1_ready_o' 3931 | .alloc1_ready_o(), | ^~~~~~~~~~~~~~ ... For warning description see https://veril...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/lint-pre-snapshot.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate-summary.txt

- `kind`: txt
- `size_bytes`: 3389
- `line_count`: 113
- `sha256`: b99cd990db027817f7a1c85429639a96fd629eef791441dfdf5c07eed2d468cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 208}
- `summary`: txt evidence; size=3389 bytes; lines=113; PASS=208; tail=# NPC single module testbench summary - result_dir: /tmp/ysyx-v8a-green.B9ZSLr/module-aggregate-result - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS tb_compare - PASS tb_immgen - PASS tb_wbu - PASS tb_lsu_cont...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate.log

- `kind`: log
- `size_bytes`: 3698
- `line_count`: 118
- `sha256`: a4e2c4524bfca6ea35fb51b21f4092ac3f11a54f7307cb0e70f6e5383e8afd74
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 210}
- `summary`: log evidence; size=3698 bytes; lines=118; PASS=210; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module test...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 370
- `line_count`: 5
- `sha256`: ee2fc8491d58cf098b86180188ca864cfde808b241b922b84593315784ce145c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=370 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/ysyx-v8a-module-all-build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: a2906a59fb61fbb361584b39518ea56fff032d80ab870254223256497be9badc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/ysyx-v8a-module-all-build/tb_axi_clint.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3502
- `line_count`: 28
- `sha256`: b46afbadfe38c47fce35e5af7dfcdb37270e6e824945dbf541320e20bd058d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3502 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/ysyx-v8a-module-all-build/tb_axi_exec_firewall....

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 6
- `sha256`: 22beac4bbda7775277ba25bdd221f9de5c24dbfe1952a2efaccd5c9af4d287a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/ysyx-v8a-module-all-build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 599
- `line_count`: 6
- `sha256`: feef0d99f920705fd694cab2f190aca8a098f503415c9623525ff39340c3014b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=599 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /tmp/ysyx-v8a-module-all-build/tb_axi_reset_syscon.vvp...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: 874090eeb046f22258f7d4173aefabd499ac2aeee08132bb82ddf078487f08ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/ysyx-v8a-module-all-build/tb_axi_to_uart.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3282
- `line_count`: 28
- `sha256`: 20400110e982178fa49a5e0b04fd46e6636f88dfa389cba27bfe8e892c44e138
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3282 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/ysyx-v8a-module-all-build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: 14024930aa08008787798c23eaece5125599588f871aaa4ccf8c378ae09382a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/ysyx-v8a-module-all-build/tb_compare.vvp /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: 3e501d6673e509a9c99454d9e32b8dc7b0a7bda2359ac86afd995482f343c104
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/ysyx-v8a-module-all-build/tb_csr_file.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 541
- `line_count`: 5
- `sha256`: b32484a1a9e2e0e7c9d39ada3621e463272324a1f20f6a109ed83df7f644d90e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=541 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/ysyx-v8a-module-all-build/tb_decode_stage.vvp /home/lyg/P...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 5
- `sha256`: 8ae0355cb285425752f12eb197fedfdc1632eacc69688063b505aaa80921b7d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=416 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/ysyx-v8a-module-all-build/tb_decode_unit.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 386
- `line_count`: 5
- `sha256`: 7abacc316f4a4671eca5e3becca2107e5085bb6a2b8cddb9ab8804eb2055b68a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=386 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/ysyx-v8a-module-all-build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/n...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 493
- `line_count`: 5
- `sha256`: af80a3863bc20594e69d8482f79646ff107f7545b430e2fda3c00975085169ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=493 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/ysyx-v8a-module-all-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 415
- `line_count`: 5
- `sha256`: d6b161c5f811f87d55f7281aa2a68b485e802fe198b7e24d1af2dc449dae8ada
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=415 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/ysyx-v8a-module-all-build/tb_lsu_control.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 421
- `line_count`: 5
- `sha256`: 96385f19010645adbad2122f92b6dabe4469efbc2cdca1d11375ebf61475c1cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=421 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/ysyx-v8a-module-all-build/tb_lsu_datapath.vvp /home/lyg/P...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15707
- `line_count`: 95
- `sha256`: 646c4583d2572aaf6800bf6de5f6479922e9f9f8ee21e84d8962a9bd0d2003b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15707 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/ysyx-v8a-module-all-build/tb_ooo_alu_core_sli...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15535
- `line_count`: 93
- `sha256`: ca06bc849e55701f925970c8f50eaedf6959f404622c29e728684a630e2dfd30
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15535 bytes; lines=93; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/ysyx-v8a-module-all-build/tb_ooo_alu_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 421
- `line_count`: 5
- `sha256`: 38d17f43625348d529da394bf4c1d8938cc00f72f3c955876339305b12693cba
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=421 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_amo_gate.vvp /home/lyg/P...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 5
- `sha256`: 3ded79702539bb96205a8bc32e09b52d742f18bd2c1674869d86afeb0f4395b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=500 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/ysyx-v8a-module-all-build/tb_oo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: cd4ff5ac892477432ba9cf9bbbd76f25fac91bff98ce1606213eb61f62352a6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_bitmanip_gate....

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 878
- `line_count`: 9
- `sha256`: fb241f8750fea860d0a7ed94c6050dc20abd2b9f36facd52b1f693a7790fa59c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=878 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/ysyx-v8a-module-all...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 833
- `line_count`: 9
- `sha256`: 132389dce53bf1405fa04675efea7bb0bfa8bc976c53bfad07749524212b9f05
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=833 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/ysyx-v8a-module-all-build/tb_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 616
- `line_count`: 5
- `sha256`: a56ba9e3cd59cd193b62c0e9dd28f4aebf251c98f13a2d5e808ea05dc69d87cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=616 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/ysyx-v8a-module-all-b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 888
- `line_count`: 9
- `sha256`: 4ea5631a20b496a93bbd5e194ed4c23e7e6e956234239e55086d7fc53bf5c8b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=888 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/ysyx-v8a-module-a...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 488
- `line_count`: 5
- `sha256`: d10870e6c9cdc36a6119ac0449c80eb9e4658c9ba1b49f135295262ff512447b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=488 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/ysyx-v8a-module-all-build/tb_ooo_br...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 6
- `sha256`: c3884708243265f463825c81ec8f3f4424627d18cc202016e2bf03bef0f0ae42
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/ysyx-v8a-module-all-build/tb_ooo_busy_table.vvp /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: f634a6befdf7e5f43c6f955be392f457911fff65efb9ce58b6a4a6996958cb67
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/ysyx-v8a-module-all-build/tb_ooo_clmul_unit.vvp /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 791
- `line_count`: 9
- `sha256`: bfb453a00c387c8cfb55c472e9eb1f4783502b3ca19b6bcc4b9042f694780627
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=791 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/ysyx-v8a-module-all-build/tb_ooo_commit...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 856
- `line_count`: 9
- `sha256`: 85c90fb07a03847df3315eaf06321cc2710a6487d35de53faacfb1175cce3a15
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=856 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/ysyx-v8a-module-all-build...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 843
- `line_count`: 9
- `sha256`: 08031cd32a606bed6c05c5883772ae2428dcb76f2357e90ce41d1d54a23a5622
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=843 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/ysyx-v8a-module-all-build/t...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15771
- `line_count`: 69
- `sha256`: 292c069e9b8c9549c087b71f24bdf1cc8dafbf558e4840168b80560f6403b40b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15771 bytes; lines=69; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/ysyx-v8a-module-all-build/tb_ooo_core_top_glue....

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: a11742fc8e5fa326f2437bf03744392dfc8065dd1bda9255eb7053f5b5d76785
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/ysyx-v8a-module-all-build/tb_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 507
- `line_count`: 5
- `sha256`: 3d147394a07d57e1c16351f48025b52e3af376ae905d3c18481147993fdb521e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=507 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/ysyx-v8a-module-all-build/tb_ooo_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 599
- `line_count`: 5
- `sha256`: 8bd91df3538a6b7e767b154069ea9d843686d6abd4c9b16d9933588f9d22ef7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=599 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/ysyx-v8a-module-all-build/tb_ooo_data_word_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 5
- `sha256`: ac0ae47c45e9888dfd193c7d308f83cdbfd265d1c5839b9d5335ce666079a583
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=529 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/ysyx-v8a-module-all-b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 523
- `line_count`: 5
- `sha256`: 7cbb9a120c6f925fc8bf44645663c9a21856cd3c853e3f8a8f3974015f2f70e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=523 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/ysyx-v8a-module-all-bui...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 523
- `line_count`: 5
- `sha256`: 2925eb3f23a39a65cdc0082eda58a4f8d88a97bba30dc14e9565c9fdf68ae920
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=523 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/ysyx-v8a-module-all-bui...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5426
- `line_count`: 37
- `sha256`: c64f889cdd49c3f545cdad1273e69355548ca91231b9a3176e3fc681ac5401b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5426 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/ysyx-v8a-module-all-build/tb_ooo_dispatch...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106890
- `line_count`: 846
- `sha256`: 849e4f17d797317f5aca8c953477058aacb1b033bed310bda1fc78a8573da1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106890 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103633
- `line_count`: 779
- `sha256`: f1d37cf2e8ec38932c2d75f184bcf2a8718e7c6a1818de00a7a80a934b588002
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103633 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104437
- `line_count`: 788
- `sha256`: cdc031ec443ad110be714fbb4e22e777d94853e1546c934789e1b67d37fde98d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104437 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106570
- `line_count`: 802
- `sha256`: 3120c573fdf6d8502f52a5a0e062242485a5b83146377ce148a0b87e36754d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106570 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: fcb64958553d2d501f385544d904714e664fd6499807f635394add15f4d7429d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fe...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: f08129662d2b36acbd041bd6fe0535afbd59d872af86c2bebb35c7c53665cb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fetc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 658
- `line_count`: 5
- `sha256`: 5de52df06e532665a3794dbc886cd4af33a02d84a7eed79dd2e43f98f1bb37a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=658 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/ysyx-v8a-module-all-build...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 710
- `line_count`: 5
- `sha256`: f6581d0534637a02c6c595472a6d220cd0c5e002f57501ae71b0e7f224b33bc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=710 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 619
- `line_count`: 5
- `sha256`: 1531d7c841147114b13f30b19be9f24a2c48779eea873bcc4e458d159590dfcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=619 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fetc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 6
- `sha256`: 459e6167270252667915acafd825930f3422b51cca2085fc277d06e88a98616a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fe...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 10
- `sha256`: bbf0f6f65d36be0d64d266faa25f442200d8574711a5cbb7e76607fa4e5207f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: f97789d0f15f9003d031086c38b3a43e9833e7179fa6aea0e3ea4f8df584f55b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/ysyx-v8a-module-all-build/tb_oo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: cf4fcb43c6470b4cc15e949a7e785be4cdb7e2f6a17194c12fc4e664e6d5ca21
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/ysyx-v8a-module-all-build/tb_oo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106432
- `line_count`: 802
- `sha256`: ece06f04b81e0d94c6b3d33534115f7f654ee083721bc44b069967669611f77d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106432 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 553
- `line_count`: 5
- `sha256`: 072b1c6146e214ef2f8189811381b6068383b5c95ce27a54daa8ea8f5a3a7d85
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=553 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/ysyx-v8a-modu...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: d8267de47964e47d8bfc26f413eb6e0ff3a281030bd29a6e87d0033d36c3ddc0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 988
- `line_count`: 10
- `sha256`: 4559d9bdb71ff12377c8897c0be1a8278781db5cef50fef3cb9b2ebe7c691547
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=988 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /tmp/ysyx-v8a-module-all-build/tb_oo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18558
- `line_count`: 85
- `sha256`: 7874d05e2cd7122460b0e4e6d21e039a988ac58f90f835d51cfed2d2991bca94
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18558 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fetch_trap...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 98f3565c53f423d4e9ffb68570d72916a6c66100fedabf06698ec8c1e63da09f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_arith_gate....

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: f6211494effdde24479553cf8561b28c26ea123d154e702b155e66df5c0f1d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_class...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 033d0bdd6c388aa233b9a25865009124006bfb6321d9e57df145ad6220e07fe4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_compare...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: 739c21b12ad2ff80c4a171061a193ed16051f8b8b22865e8a06dbe3888723211
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_convert...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3668
- `line_count`: 36
- `sha256`: 7f9553c0ce3b0cab2bf2cf510694096d742876a2b0444ff9bf2975dcaf62db75
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3668 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_issue_que...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: fe42c8e7ffb9dfc19afb14976c92508f63e553786faad76c3ffa4af897b12abd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_iter.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1644
- `line_count`: 14
- `sha256`: e90f4ee526fb73acb4ecf8f8d34408848b5dfa29ed2e64118b4f0d0c8d4d0ae9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1644 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/ysyx-v8a-module-all-bui...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 2a9dbadd7fa90eac6ecf9f8e106f867f297e28a7da4adbdd96e248abe07bef47
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_long_op...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1001
- `line_count`: 12
- `sha256`: 57e0d2e0d4e9ff119f7608f02e72b5f98bc60f43b27b0feb224be6cddacf6ea1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1001 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_phys_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 748
- `line_count`: 9
- `sha256`: 0a6c589557101a34acd7dd4049c5a2ead3475b4447831f3c19544a119a3ce64b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=748 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_reg_file.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 8568d8c63a3e7e3e0e02e5ce41cfc9fe9e2e0ae1350a45d111c2425823b2fd2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fp_sgnj_gate.vvp...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 436
- `line_count`: 5
- `sha256`: c6e6a068d539e0507a31c2777eab8377b5c7af1f6907320f775aaba6fb540733
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=436 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/ysyx-v8a-module-all-build/tb_ooo_free_list.vvp /home/ly...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: ab5fad5e8dee9cdd6c0d65a94c73164d9c66ca228e37b06670a3e535a98fd968
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 902
- `line_count`: 10
- `sha256`: c64f6de6e590759bf034ae2326dec7f55189d3ff0738785a6230f6b721afcf99
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=902 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/ysyx-v8a-module...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 814
- `line_count`: 7
- `sha256`: 7ca53c17f2b9fa3e5c2e04fb42c7b8417dc8af4b47c77ec9f489fafb59b398bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=814 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/ysyx-v8a-module-all-build/tb_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: 3bd0c0a621b4fae654493db76e850813d0fff0ca91a7ca551335a4ae7d1c2d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fronte...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 488
- `line_count`: 5
- `sha256`: 57240aeb513ce2339dee176d506f7de59ff0509a2e8448d85f0b7bbfda8bf8f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=488 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/ysyx-v8a-module-all-build/tb_ooo_fr...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3845
- `line_count`: 34
- `sha256`: 48c87db172966d676018f0319949ea0833c3a8eafe8ecb715ce4385c981ff48f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3845 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/ysyx-v8a-module-all-build/tb_oo...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13791
- `line_count`: 105
- `sha256`: 016a046adacfcac727c5259d0b0d5889f567063550a45b2e5916ef3de1fa684e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"ERROR": 2, "PASS": 32}
- `summary`: log evidence; size=13791 bytes; lines=105; ERROR=2; PASS=32; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/ysyx-v8a-module-all-build/tb_ooo_int_backend.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7853
- `line_count`: 77
- `sha256`: 785e52ae2047a7f2b1b890d8fd41004421473155cd921e142598fe1593927eb3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=7853 bytes; lines=77; PASS=12; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/ysyx-v8a-module-all-build/tb_ooo_int_issue_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 846
- `line_count`: 10
- `sha256`: 1cdb896c738f212ea86348f1fef11a995cf9ef46bc1e3cce1a888ea78af9e05a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=846 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /tmp/ysyx-v8a-module-all-build/tb_ooo_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71171
- `line_count`: 545
- `sha256`: 90e5dd859228fec5c41087fde536ebcb0ec681350f5daae12154f08626ca300a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=71171 bytes; lines=545; PASS=16; tail=: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1124
- `line_count`: 10
- `sha256`: b078195255fe8cf0911e3eec30fa06e2bc727600a36b36d086883325231eab2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1124 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /tmp/ysyx-v8a-module-all-build/tb_ooo_mem_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 946
- `line_count`: 8
- `sha256`: 023cafbcc62ac711bd9956890e0dbe98960b7bbfc41f81bf9283c65434b4be09
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=946 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_me...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 6
- `sha256`: 4cd8becb6c823f04f76114926415112e954ea11a454bfdca4b74df76a5263420
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=560 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /tmp/ysyx-v8a-module-all-build/tb_ooo_mmu_epoch_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 8f2319052559adccf5a05bfbda40d9668489a30d13a7d4cb3a971c3d5d60c271
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/ysyx-v8a-module-all-build/tb_ooo_muldiv_unit.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1170
- `line_count`: 12
- `sha256`: e107e78f266998e82dbcb92ad5bcd79ea9cffa420fc4ba666aef6eeb972a29e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1170 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/ysyx-v8a-module-all-build...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: 1faad8e689f7ee608c482e6b80de702a576a14a9308237523feb7ccac3070394
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /tmp/ysyx-v8a-module-all-b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 958
- `line_count`: 11
- `sha256`: ce0d3bd8b0fef285a48ccccbbc73e0ed090f7a1b305437b19ddbc322bb6555ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=958 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/ysyx-v8a-module-all-b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 852
- `line_count`: 9
- `sha256`: 7e6ffe1e239229a5d73682a16860d7fa5d6541d4a23d824cccc78a649a1a99b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=852 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/ysyx-v8a-module-all-build...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 5
- `sha256`: d40b69c543ee83ca03b35271b82f57078222f87f6e580a07406c8f2a4fe8cd3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=556 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/ysyx-v8a-module-all...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: ef3dccad9c216fac587f1842bffc12d5a41d852d9832a00756f74bc2d985fc41
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/ysyx-v8a-module-all-build/tb_ooo_phys_reg_file....

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 580
- `line_count`: 6
- `sha256`: cd1bc97bd93312652cb2a2c1080af46ce89e733366d4c54be771e55ee483a11a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=580 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /tmp/ysyx-v8a-module-all-build/tb_ooo_pma_checker.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15562
- `line_count`: 64
- `sha256`: a80e848293e292ad4b6a7732b1295aa02c4cffdba098feb0cd935fd9bb40e670
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15562 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/ysyx-v8a-module-all-build/tb_ooo_priv_system.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: ed06b73aac883f3cf8f659c9d79bf23b5456288b3b84297d5803866a58978cd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/ysyx-v8a-module-all-build/tb_ooo_ras_update...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 470
- `line_count`: 5
- `sha256`: b6d00d65e28d2b480efd5e5e7bc7961f05dd1785ec0d455ee77c4730086b1566
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=470 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/ysyx-v8a-module-all-build/tb_ooo_redirect...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 1416d2f48458dcea1089f3cfe36c4d215bd01a72384c4fea40afb04f4244240b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/ysyx-v8a-module-all-build/tb_ooo_rename_map.vvp /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1040
- `line_count`: 10
- `sha256`: e19ea024ab778f20ac738dd5aefd8f969827a8dfc6c37eaf31c060d4710c625a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1040 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/ysyx-v8a-module-all-build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 834
- `line_count`: 9
- `sha256`: 8a69ea3cd4124e4eab3b7d177fe7ec94a3293ea18a96fd7e94b0169d83407ae4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=834 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/ysyx-v8a-module-all-build/tb_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2484
- `line_count`: 23
- `sha256`: e42c09e8b86aafcdc16973c34cb11e6f5897ad77011c6f40ad960bc51cac45a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=2484 bytes; lines=23; PASS=16; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/ysyx-v8a-module-all-build/tb_ooo_store_queue.vvp /h...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 208028
- `line_count`: 1512
- `sha256`: c8b5be6d2a0fd1376aab67c10719a51f98a1d902d72daf7800496869bea87b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208028 bytes; lines=1512; PASS=2; tail=pChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 5
- `sha256`: 9280062e65cafc0cbaf4a3fd716613f6607e2263e2dfa1aaa2a0ba559627d063
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=500 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/ysyx-v8a-module-all-build/tb_ooo_tr...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: cd576a9c4cc9cf20ff8584cecb6c219241f1f4d35d69a0302d60b3165155f3b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/ysyx-v8a-module-all-b...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 600
- `line_count`: 6
- `sha256`: 2fca1e68340b0e3ba938a14951d217922da1dc21b306ffcf1cb49355ea596d69
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=600 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /tmp/ysyx-v8a-module-all-build/t...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: f811295b84d6838f6aa68f3369594f87592b4b9eef1b12bc1df8add85ca235c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/ysyx-v8a-module-all-build/tb_pipe_stage_reg.vvp /home...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17562
- `line_count`: 134
- `sha256`: 10541f392de5782b1a83596f1a6f8997d1e2729d0efea314e79b8f0b695667c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17562 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/ysyx-v8a-module-all-build/tb_pmp_checker.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 74468f40b08c3a3758e6b5a0d6beeafde94af5e2572479563593dc19b8bbb0f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/ysyx-v8a-module-all-build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 656626bafa11590c31f7850e224006100c92dcd485a2e892f67ac586cc0052fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/ysyx-v8a-module-all-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate/summary.txt

- `kind`: txt
- `size_bytes`: 3489
- `line_count`: 113
- `sha256`: 970d137dca744865b40480bd9df841a76e4e4c66cdd3e8e14e0f8f0cc04d0795
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 208}
- `summary`: txt evidence; size=3489 bytes; lines=113; PASS=208; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/module-aggregate - tool: Icarus Verilog version 12.0 (stable) () - PASS...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/readiness.log

- `kind`: log
- `size_bytes`: 132
- `line_count`: 1
- `sha256`: 217da9d727bb37da2e58b2096be9bdf35ed534bc5b78f4094bcc86211f38050d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=132 bytes; lines=1; PASS=2; tail=[S2-Q2-V8A-READINESS][PASS] neutral shadow foundation is structurally ready; deferred v8b P0 blockers and RTL behavior gates remain

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/sources-check.log

- `kind`: log
- `size_bytes`: 1988
- `line_count`: 24
- `sha256`: 922ce0a5db024deb01b68a9f1d014b2e64be5c18c86f086aa5428220796f842a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=1988 bytes; lines=24; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-shadow-foundation-v8a-green.sh: OK /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/check-s2-q2-shadow-foundation-v8a-im...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 3476
- `line_count`: 24
- `sha256`: 28ff5058d444d11987bb23b69a995c59e51529822d223b00092596ae0c28503c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3476 bytes; lines=24; markers=<none>; tail=be3419a28d95131181366dbd175607426c241517bb776b1ad22a607b1161063c /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-shadow-foundation-v8a-green.sh 3fb1780e555da76b5b029259cd5bdca236c74852da3796282e06416d416b803...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 3476
- `line_count`: 24
- `sha256`: 28ff5058d444d11987bb23b69a995c59e51529822d223b00092596ae0c28503c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3476 bytes; lines=24; markers=<none>; tail=be3419a28d95131181366dbd175607426c241517bb776b1ad22a607b1161063c /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-shadow-foundation-v8a-green.sh 3fb1780e555da76b5b029259cd5bdca236c74852da3796282e06416d416b803...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/sources.sha256

- `kind`: sha256
- `size_bytes`: 3476
- `line_count`: 24
- `sha256`: 28ff5058d444d11987bb23b69a995c59e51529822d223b00092596ae0c28503c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3476 bytes; lines=24; markers=<none>; tail=be3419a28d95131181366dbd175607426c241517bb776b1ad22a607b1161063c /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-shadow-foundation-v8a-green.sh 3fb1780e555da76b5b029259cd5bdca236c74852da3796282e06416d416b803...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/strict-lint.log

- `kind`: log
- `size_bytes`: 62652
- `line_count`: 687
- `sha256`: 9e3162a50f36035b89e31fd2819d4947e96b5d5b02287a65838d5eeee39339bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {}
- `summary`: log evidence; size=62652 bytes; lines=687; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_...

### .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/r5-s2-q2-shadow-foundation-v8a-green/summary.txt

- `kind`: txt
- `size_bytes`: 1012
- `line_count`: 20
- `sha256`: 1a41eefb6494a62cb237cc5a498097d4aea45c52b9a874ba0b57c1cc0affe697
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T19:00:09+00:00
- `markers`: {"PASS": 28}
- `summary`: txt evidence; size=1012 bytes; lines=20; PASS=28; tail=contract_schema=s2-q2-shadow-foundation-interface-v8a status=GREEN checker_self_test=PASS mutations=17 structural_readiness=PASS release+ooo_assert implementation_readiness=PASS commit-prefix,identity,scalar-ABI,census focused_tests=PASS variants=2 tests_pe...
