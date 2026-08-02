# Evidence Index

## 基本信息

- `task_id`: 2026-08-01-rv64-v13g-int-iq-onehot-popmask
- `task_slug`: 
- `profile`: 
- `asset_count`: 43
- `total_size_bytes`: 9247471

## 证据资产

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/candidate-g1-v11f.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 7
- `sha256`: ca918f35d868d60ee2c81fd85d10ee971fdf252085d44a8a5f49dafc06f03f72
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=431 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/candidate-g4-compile.log

- `kind`: log
- `size_bytes`: 3398
- `line_count`: 30
- `sha256`: a79bbc245811d3fef409b6f3445ba50c88a7be0bc930c8d3218e8f470db29661
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: log evidence; size=3398 bytes; lines=30; markers=<none>; tail=npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:539: warning: @* is sensitive to all 8 words in array 'valid_q'. npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:540: warning: @* is sensitive to all 8 words in array 'producer_id_q'. npc/rv64/vsrc/scheduling/OooIntIs...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/candidate-g4-full.log

- `kind`: log
- `size_bytes`: 6804
- `line_count`: 63
- `sha256`: bc38b45a2d1c1745b5da05b2976fa42ca8c35cb833e13e9f0c4814239f7b222c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=6804 bytes; lines=63; PASS=14; tail=[V8U-IQ-PAIR-PEEK] q_only_payload/ready_hold/atomic_pop2/full_pid PASS [R3P2-STALL] IQ valid held under ready=0 and drained after release PASS [T3Q-LANE1-NEG] class=0 lane0_pc=0000000081000004 lane1_pc=0000000081000000 count=3 [T3Q-LANE1-NEG] class=1 lane0_...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/candidate-g4-v11f.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 7
- `sha256`: 21cb498b79c4d1aa2a7ba2cc23b35191a6d9c3ae0491a639e8a48d73d0706f15
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=450 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/config-gap/README.md

- `kind`: md
- `size_bytes`: 630
- `line_count`: 10
- `sha256`: b647aba386adf394c26fe0935d5fd8fcb4802ea3278ab263c815ae8542b5c163
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: md evidence; size=630 bytes; lines=10; FAIL=2; PASS=2; tail=# GEN_W=1 通用 TB 配置 GAP `candidate-g1-full.log` 最初把整份通用 `tb_ooo_int_issue_queue` 与 `OOO_PRODUCER_GEN_W=1` 组合，旧 V8O 场景仍要求 dispatch generation “nonzero”，因此产生 12 个 mismatch。`parent-g1-full.log` 在冻结父 RTL 上逐项复现相同 12 个 mismatch，证明它不是 V13G 行为回退。 该宽度的有效 oracle 是 `+V...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/config-gap/candidate-g1-full.log

- `kind`: log
- `size_bytes`: 12483
- `line_count`: 113
- `sha256`: cc756cd9c188bcd975e6d7d47360110f8208ddc3245f08632c79079bb0c94d56
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"FAIL": 30, "PASS": 14}
- `summary`: log evidence; size=12483 bytes; lines=113; FAIL=30; PASS=14; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/config-gap/parent-g1-full.log

- `kind`: log
- `size_bytes`: 7561
- `line_count`: 76
- `sha256`: b697c91eee59cd79f83a5ac81c1e0bfb0e9cd83a1af50f1b5d81d5c47bc122f6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"FAIL": 26, "PASS": 12}
- `summary`: log evidence; size=7561 bytes; lines=76; FAIL=26; PASS=12; tail=[V8U-IQ-PAIR-PEEK] q_only_payload/ready_hold/atomic_pop2/full_pid PASS [R3P2-STALL] IQ valid held under ready=0 and drained after release PASS [T3Q-LANE1-NEG] class=0 lane0_pc=0000000081000004 lane1_pc=0000000081000000 count=3 [T3Q-LANE1-NEG] class=1 lane0_...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/integration/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 33450
- `line_count`: 220
- `sha256`: 37621b61c752c5bae929c4b682bcbc856aeff4ff8d555a5a0aee4f514cd881e7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=33450 bytes; lines=220; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/runtim...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/integration/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5810
- `line_count`: 40
- `sha256`: 55b116e4ecef20acb9aad860c92a713b895cc851007a7b79eccd405608030c0c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5810 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/runtime-ar...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/integration/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 28700
- `line_count`: 242
- `sha256`: 024baffd66755198e81db26f38a445df795b705d66e7195b8aa50cf2426c4aff
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=28700 bytes; lines=242; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/integration/summary.txt

- `kind`: txt
- `size_bytes`: 349
- `line_count`: 12
- `sha256`: 6f27543a41b940081b2a50c58d545b800bdbb3e8fa2e027decf7cf3530f1ae8c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=349 bytes; lines=12; PASS=6; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/integration - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_dispatch_backend - PAS...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/parent-g1-v11f.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 7
- `sha256`: b217ba9a65d3020bb3b9124d9f9b069616a6514fe9c1c691066ea8841dfafaf7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=450 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/functional/rtl-style.log

- `kind`: log
- `size_bytes`: 305
- `line_count`: 4
- `sha256`: f53131c53120ae51bb7e0d91729aa02bf171896a37ba14e3c85ff1587ee54b04
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=305 bytes; lines=4; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 扩展名、Verilog-2001 关键字和 module 命名均合规 [RTL-STYLE-NAMING][PASS] retired=AxiXbar rejected legal=L2XbarAdapter accepted make: Leaving directory '/home/lyg/PA/ysyx-work...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/identity/candidate-design-id.post.json

- `kind`: json
- `size_bytes`: 17279
- `line_count`: 152
- `sha256`: b4c9646ffab510f5beaa60887247cc512e93817f151fc4d61876e0fa009b8c9b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: json evidence; size=17279 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiCrossbar.v": "d86044c4a929e49d...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/identity/candidate-design-id.pre.json

- `kind`: json
- `size_bytes`: 17279
- `line_count`: 152
- `sha256`: b4c9646ffab510f5beaa60887247cc512e93817f151fc4d61876e0fa009b8c9b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: json evidence; size=17279 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiCrossbar.v": "d86044c4a929e49d...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/identity/v13b-parent-compare.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 4
- `sha256`: 63cbcaf87022d09eb6d8c14357916e324f55bb66985ec8e0a5ad94d6591f58a7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: log evidence; size=402 bytes; lines=4; markers=<none>; tail=BASELINE_DESIGN_ID=sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483 CURRENT_DESIGN_ID=sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44 RTL_MISMATCH_COUNT=1 MISMATCH npc/rv64/vsrc/scheduling/OooIntIssueQueue.v ba...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/full-core-candidate/console.log.gz

- `kind`: gz
- `size_bytes`: 4543410
- `line_count`: 16965
- `sha256`: 1fb8967c8a7439937bd85170e7e963795dd9c9d185dfecfda52403df38ff0a2d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: gz evidence; size=4543410 bytes; lines=16965; markers=<none>; tail=��,��P ˘#'�`�]@�3P!ΘJ� �e�� a� g�(-�}�����դB���� ��a �J �#� 3��9`�Q� �n��y Am g� ���c�wn��:P*�N��/GT�s�ۈ�� ��� W��3gL� D�b 9�W �E�l�� �G�+��E -،�� �:F���>-̻ C� �� �n3�)dNz���� 3� ��Of� � ����%��J@pw[}��A h�h��D-� ����x �����UMQ������ ����?vs��P[(N�z} 6;c�e...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/full-core-candidate/elapsed-seconds.txt

- `kind`: txt
- `size_bytes`: 7
- `line_count`: 1
- `sha256`: f37dc0fb59164e737505113b53f136bcc11894ccc7b21605bf42291c9923bbb1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=7 bytes; lines=1; markers=<none>; tail=235.22

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/full-core-candidate/runtime-cleanup.txt

- `kind`: txt
- `size_bytes`: 232
- `line_count`: 3
- `sha256`: ea42dceefad8a525413134ac9f951bc9938eb6ad2c5369e93b23e526f23f8894
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=232 bytes; lines=3; markers=<none>; tail=resolved_path=/home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13g-int-iq-onehot-popmask/full-core-coarse 228079766 /home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13g-int-iq-onehot-popmask/full-core-coarse 7

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/full-core-candidate/synth_check.txt

- `kind`: txt
- `size_bytes`: 7654
- `line_count`: 133
- `sha256`: e90ced29dba15b00e739982845bf75d4969b128643c5885a67eb3bd3d65ccf85
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=7654 bytes; lines=133; markers=<none>; tail=134. Executing CHECK pass (checking for obvious problems). Checking module $paramod$087166ba7b9eda3b7d23c45f1831c9de34cdff99\OooCoreTopGlue... Checking module $paramod\OooDataWordCache\ENABLE_PEER_INVALIDATE=s32'00000000000000000000000000000001... Checking...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/full-core-candidate/synth_stat.txt

- `kind`: txt
- `size_bytes`: 69715
- `line_count`: 2957
- `sha256`: d4ae55bb3bf3dd28e15264473b162c772847a8b07dd714c10d79c3cfcb445a4f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=69715 bytes; lines=2957; markers=<none>; tail=e bits 355 public wires 8093 public wire bits 34 ports 570 port bits 2138 cells 127 $alu 2 $and 36 $eq 116 $logic_and 121 $logic_not 63 $logic_or 16 $macc_v2 797 $mux 11 $ne 125 $not 155 $or 6 $pmux 75 $reduce_and 18 $reduce_bool 212 $reduce_or 191 $sdff 1...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/coarse-console.log.gz

- `kind`: gz
- `size_bytes`: 1273741
- `line_count`: 5532
- `sha256`: 2d7813756edc925d401ed37243869b98ce30c9196a53bced3c59d98938dcbc12
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: gz evidence; size=1273741 bytes; lines=5532; markers=<none>; tail=�n�̄ ���VO� �Å |q��K �+�6 \`7�*�9p��!�� d� @8h�l� � �AC� � W9΁ � i�t ;,��/O?*�"Q���z� u �i�5�|�4�ѧU��Z�b& �4� ��x���"wS1rž"f� �����#���s�� %o���(�ӏ � 0^ 4L���� �|4��ב�2v�A��#��U7�*�(�� � OaD9�9�rb0aa�E�� &c ~d�q U?g ��" �f���� ����� �p��{^}�}%4�yi�� �3 y�3�...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/coarse-synth-check.txt

- `kind`: txt
- `size_bytes`: 125
- `line_count`: 4
- `sha256`: 9e1d80f2f431643d186cf7f3c20305a24e058202f1f60da925dcf9804f9513a7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=125 bytes; lines=4; markers=<none>; tail=9. Executing CHECK pass (checking for obvious problems). Checking module OooIntIssueQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/coarse-synth-stat.txt

- `kind`: txt
- `size_bytes`: 587
- `line_count`: 32
- `sha256`: aa09c96995c915a1324b155f14eb120a31698d010f6f7de8023ace25ed4533d9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=587 bytes; lines=32; markers=<none>; tail=10. Printing statistics. === OooIntIssueQueue === +----------Local Count, excluding submodules. | 4485 wires 68747 wire bits 525 public wires 8424 public wire bits 112 ports 1894 port bits 4385 cells 43 $alu 46 $and 184 $eq 353 $logic_and 100 $logic_not 136...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/mapped-console.log.gz

- `kind`: gz
- `size_bytes`: 2774659
- `line_count`: 10202
- `sha256`: 1b8af64ba568f3da152620b035911b0ee0e057c8988afaa66b0a6335d8601422
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: gz evidence; size=2774659 bytes; lines=10202; markers=<none>; tail=g+� 8 �U� =HU/�O�z���oՃf ׆Vh ϣ��R � � O~�D��+� �x حi j ��%�ءB���� ��ѳ�A �m�� CӿO��̕�5��+{1� � �)ز�b���� Zz � ,�g:�*��GlU #>��V�Q��-� : < � WeۧW�C��kMO�č@�� K| ��VI��;QJRD ���lȂ�KI&�E�a{T˸�i 8���� g�D���D9�^_ i�x �%KlX��gLwA�VVΘ =wp;ӑ)� �~I?^��)Z��6��D��`...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/mapped-synth-check.txt

- `kind`: txt
- `size_bytes`: 126
- `line_count`: 4
- `sha256`: 0f43e11a57eb90f7b71d778473cec5e7ea71d77e8209bb9f012d2bfdea164970
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=126 bytes; lines=4; markers=<none>; tail=24. Executing CHECK pass (checking for obvious problems). Checking module OooIntIssueQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/mapped-synth-stat.txt

- `kind`: txt
- `size_bytes`: 4297
- `line_count`: 132
- `sha256`: fa3a093745b5e82c24da166e15afe9facad59392d15b394127a377fe88a95c92
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=4297 bytes; lines=132; markers=<none>; tail=25. Printing statistics. === OooIntIssueQueue === +----------Local Count, excluding submodules. | +-Local Area, excluding submodules. | | 34140 - wires 34140 - wire bits 34140 - public wires 34140 - public wire bits 1894 - ports 1894 - port bits 33284 7.49E...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/opensta-check-setup.txt

- `kind`: txt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: txt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/opensta-config.tcl

- `kind`: tcl
- `size_bytes`: 1273
- `line_count`: 11
- `sha256`: b46d5737723f56b0e4df6ef518b35871f635179637b1a95507849aecc9d61612
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1273 bytes; lines=11; markers=<none>; tail=read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib read_verilog /home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13g-int-iq-onehot-...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/ppa/local-candidate/opensta-top40.rpt

- `kind`: rpt
- `size_bytes`: 203698
- `line_count`: 2242
- `sha256`: e278159da3eda6b492ecad3e80fffb9693d76c8c04c5b766051cd9f80cfba82f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203698 bytes; lines=2242; markers=<none>; tail=0.081645407 0.081645407 ^ valid_q[5]_0__reg_p/Q (DFFQX1H7L) 0.101446830 0.183092237 ^ valid_q[5]_0__BUFX1P4H7L_A/Y (BUFX1P4H7L) 0.057384294 0.240476534 v fp_st_ready_q[5]_0__NOR2BX1P4H7L_B_Z_OR3X1H7L_B_A_NAND2BX0P5H7L_Y/Y (NAND2BX0P5H7L) 0.185779065 0.42625...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/candidate/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 50243
- `line_count`: 1035
- `sha256`: 08b32e2c69690f8dcd66aa69d1cd3001acdb343319f55348379c273ec7aab012
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: v evidence; size=50243 bytes; lines=1035; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/candidate/OooIntIssueSelect8.v

- `kind`: v
- `size_bytes`: 8718
- `line_count`: 210
- `sha256`: 845d5dc474d8c8b5ebdee54afb54deebf3d588841562743bb351348d6e0e4879
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: v evidence; size=8718 bytes; lines=210; markers=<none>; tail=// R3.3 整数 IQ 的固定 8 项平衡选择器。 // // 结构目的：把旧的 loop-carried oldest-first scan 改成三层并行前缀网络；不增加 // pipeline stage，也不改变 Universal/ALU terminal 的动态 capability steering。 // 本模块纯组合、无状态，request index 越小代表越老。 module OooIntIssueSelect8 ( input [7:0] valid_i, input [7:0]...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/candidate/ooo-int-issue-queue.md

- `kind`: md
- `size_bytes`: 30694
- `line_count`: 349
- `sha256`: 8f8f78cc9df4d982ab52dd4341878f0144f647c50913008bb680be6178b72220
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: md evidence; size=30694 bytes; lines=349; FAIL=2; PASS=8; tail=# 规范：整数发射队列 OooIntIssueQueue > 模块：`vsrc/scheduling/OooIntIssueQueue.v`(核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。 > 状态：已实现并验证。**T3M：整数 EX/MEM/long-op/FPWB 均 sticky-only**； > **T3H：FP wake0/1 resident select 均已 sticky-only**； > **2026-07-09 P5 刀 B:dispatch→issue...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/candidate/source-hashes.sha256

- `kind`: sha256
- `size_bytes`: 261
- `line_count`: 3
- `sha256`: 88144afb91f94bcfd46190c5daae39a1a09af5a5690991b04f02fe0229edc3c6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=261 bytes; lines=3; markers=<none>; tail=08b32e2c69690f8dcd66aa69d1cd3001acdb343319f55348379c273ec7aab012 OooIntIssueQueue.v 845d5dc474d8c8b5ebdee54afb54deebf3d588841562743bb351348d6e0e4879 OooIntIssueSelect8.v 8f8f78cc9df4d982ab52dd4341878f0144f647c50913008bb680be6178b72220 ooo-int-issue-queue.md

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/parent/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/parent/OooIntIssueSelect8.v

- `kind`: v
- `size_bytes`: 8718
- `line_count`: 210
- `sha256`: 845d5dc474d8c8b5ebdee54afb54deebf3d588841562743bb351348d6e0e4879
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: v evidence; size=8718 bytes; lines=210; markers=<none>; tail=// R3.3 整数 IQ 的固定 8 项平衡选择器。 // // 结构目的：把旧的 loop-carried oldest-first scan 改成三层并行前缀网络；不增加 // pipeline stage，也不改变 Universal/ALU terminal 的动态 capability steering。 // 本模块纯组合、无状态，request index 越小代表越老。 module OooIntIssueSelect8 ( input [7:0] valid_i, input [7:0]...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/parent/ooo-int-issue-queue.md

- `kind`: md
- `size_bytes`: 29964
- `line_count`: 341
- `sha256`: 597da002fad344017d1fae4028ca0456482c12206ac254019b1264f871dd6bab
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: md evidence; size=29964 bytes; lines=341; FAIL=2; PASS=8; tail=# 规范：整数发射队列 OooIntIssueQueue > 模块：`vsrc/scheduling/OooIntIssueQueue.v`(核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。 > 状态：已实现并验证。**T3M：整数 EX/MEM/long-op/FPWB 均 sticky-only**； > **T3H：FP wake0/1 resident select 均已 sticky-only**； > **2026-07-09 P5 刀 B:dispatch→issue...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/parent/source-hashes.sha256

- `kind`: sha256
- `size_bytes`: 261
- `line_count`: 3
- `sha256`: 996bf09b21ffca5547dbf97ccd8565b9b7fed96208fcfa38d1a0882557ccc16c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=261 bytes; lines=3; markers=<none>; tail=d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b OooIntIssueQueue.v 845d5dc474d8c8b5ebdee54afb54deebf3d588841562743bb351348d6e0e4879 OooIntIssueSelect8.v 597da002fad344017d1fae4028ca0456482c12206ac254019b1264f871dd6bab ooo-int-issue-queue.md

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/post-review-spec-status.md

- `kind`: md
- `size_bytes`: 1115
- `line_count`: 21
- `sha256`: b9a36e2c48f6a08194f3d6708ceea120ea954e273c0e8fddb222923735a97fff
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: md evidence; size=1115 bytes; lines=21; markers=<none>; tail=# Post-review specification status correction The independent reviewer found one stale status sentence at the top of `npc/rv64/design/specs/ooo-int-issue-queue.md`: R3.3 still said RTL/verification were pending, while the body and V13G evidence already desc...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/ppa-input-binding.md

- `kind`: md
- `size_bytes`: 702
- `line_count`: 10
- `sha256`: a9818b504b9a494a55cfed30a41a65ab1bd0782d50f7c3f3b2cf918db614cb7d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: md evidence; size=702 bytes; lines=10; markers=<none>; tail=# V13G local PPA input binding Local coarse/mapped/OpenSTA ran before the explanatory R3.3 comment and spec text were refreshed. The exact RTL byte stream used by those runs is reconstructed at `ppa-input-reconstructed/OooIntIssueQueue.v`; its SHA-256 must...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/ppa-input-reconstructed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 50128
- `line_count`: 1034
- `sha256`: 13bc5b6fee1c8c9a8c6ec877baaad24773a978c650c2ac5634348d0cc8c21e51
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: v evidence; size=50128 bytes; lines=1034; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/ppa-input-to-final.diff

- `kind`: diff
- `size_bytes`: 1161
- `line_count`: 16
- `sha256`: 973adfca1b41e33529ae0d7d4f1cb2f671a66d7c6be5b689d1e3c48042ae75f8
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:57:41+00:00
- `markers`: {}
- `summary`: diff evidence; size=1161 bytes; lines=16; markers=<none>; tail=--- .github/task-runs/2026-08-01-rv64-v13g-int-iq-onehot-popmask/evidence/source/ppa-input-reconstructed/OooIntIssueQueue.v 2026-08-01 16:31:13.089095079 +0800 +++ npc/rv64/vsrc/scheduling/OooIntIssueQueue.v 2026-08-01 16:20:03.441638667 +0800 @@ -236,9 +23...
