# Evidence Index

## 基本信息

- `task_id`: 2026-08-01-rv64-v13d-lq-release-localization
- `task_slug`: 
- `profile`: 
- `asset_count`: 37
- `total_size_bytes`: 4273413

## 证据资产

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/focused/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 1148
- `line_count`: 13
- `sha256`: 91a9375ad618602f5f2cec46354e91ab0d16232d1e0c115e2d68b5724f6aad7f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1148 bytes; lines=13; PASS=14; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /tmp/rv64-v13d-focused-build/tb_ooo_load_queue.vvp /home/l...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/integration/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 308147
- `line_count`: 2310
- `sha256`: 7573486516e8ab898542b2927f12ddad251745eebd6f7cdc1ae633543dfe5b2c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=308147 bytes; lines=2310; PASS=2; tail=sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warnin...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/integration/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 28618
- `line_count`: 242
- `sha256`: 2f30760572db73d7102f056a69f712f5f92cd7715752956a9ca62ab9284334f3
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=28618 bytes; lines=242; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/rv64-v13d-integration-build/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/logs/baseline-release-locality-negative.log

- `kind`: log
- `size_bytes`: 1022
- `line_count`: 11
- `sha256`: 862f9df26f40e41debb4054e0aed029e30decbe05343b7d038cee42f0b8a94ae
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"FAIL": 12}
- `summary`: log evidence; size=1022 bytes; lines=11; FAIL=12; tail=[COMPILE] iverilog -g2012 -Wall -I npc/rv64/vsrc -I npc/rv64/vsrc/include -I npc/rv64/testbench/common -s tb_ooo_load_queue baseline-OooLoadQueue.v live-tb .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/OooLoadQueue....

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/logs/candidate-release-locality.log

- `kind`: log
- `size_bytes`: 658
- `line_count`: 7
- `sha256`: 0e8984cb7d1378817a42895a6c8d1141ad5c44277fc6ad1c1cf59e75a8b62bf5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=658 bytes; lines=7; PASS=6; tail=[COMPILE] iverilog -g2012 -Wall -I npc/rv64/vsrc -I npc/rv64/vsrc/include -I npc/rv64/testbench/common -s tb_ooo_load_queue live-OooLoadQueue.v live-tb assertion=off npc/rv64/vsrc/memory/OooLoadQueue.v:310: warning: @* is sensitive to all 4 words in array '...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/coarse-console.log.gz

- `kind`: gz
- `size_bytes`: 326827
- `line_count`: 1244
- `sha256`: e200a2849b0c42ae0c76705cefefc8c157215463c3866aa611a707a8d0414f1a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: gz evidence; size=326827 bytes; lines=1244; markers=<none>; tail=ml&�Y/��� �z��ͤ �66� s g3Y�z����b�K�l s� �f0���l 3~ �fjQ�֒ ��2^��Z~ ���!�z���'�^�q��K5:|œ�z�F��X� �R� �����jt� E��R� _�Lr�T��W4ʭ�jt� ���R� _�8�^���+���^*z �d�K5:|����R� ���P/uݶ�륲����z����X �^�am �R�\�}E��z����`�\/�}1��W���>@a�X� ň�R k_� �^��������R�}/J�� �z...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/coarse-synth-check.txt

- `kind`: txt
- `size_bytes`: 121
- `line_count`: 4
- `sha256`: aa625b047150ade58313fe405524e334cd65a312314bc117959f77a9158c1db9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=121 bytes; lines=4; markers=<none>; tail=8. Executing CHECK pass (checking for obvious problems). Checking module OooLoadQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/coarse-synth-stat.txt

- `kind`: txt
- `size_bytes`: 506
- `line_count`: 28
- `sha256`: 7ba7cba3e2cfa5770ad2189c741b63cc98c55c82f2ff62203afcd357f0f7c731
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=506 bytes; lines=28; markers=<none>; tail=9. Printing statistics. === OooLoadQueue === +----------Local Count, excluding submodules. | 4441 wires 41922 wire bits 129 public wires 1176 public wire bits 76 ports 601 port bits 4568 cells 66 $alu 18 $and 353 $eq 1292 $logic_and 132 $logic_not 226 $logi...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/mapped-console.log.gz

- `kind`: gz
- `size_bytes`: 1463743
- `line_count`: 4565
- `sha256`: 77a70d88e24d114412980df07f809be872bbedd5a4b343996aabafd2efb12db7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: gz evidence; size=1463743 bytes; lines=4565; markers=<none>; tail=�1"�� ���*�k�Dv�FOET�(2��~ � ���l�j �*.?N� ��<PTY T� ]eNҋB�*�zպ�� � � Y -H��; ��z� ��� �����hF��1A�5��j%�x� ��-%���+ë6�� E ��'' .�w t��1 �6OmZ�c�� ��t} �v,��ӦZE �����$U��#�H� s@��N���E� �S-���)�Z vm�7�S. ��6�픓l*���ΆSN�V�0��4l�1�� �I *Q+ka{l$� JRb'�|n2v�� �...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/mapped-synth-check.txt

- `kind`: txt
- `size_bytes`: 122
- `line_count`: 4
- `sha256`: 63eee49a55ce075d7be21e4041a8fc292a0c7978dac7a3288b24bb6cd051377a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=122 bytes; lines=4; markers=<none>; tail=23. Executing CHECK pass (checking for obvious problems). Checking module OooLoadQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/mapped-synth-stat.txt

- `kind`: txt
- `size_bytes`: 4509
- `line_count`: 139
- `sha256`: f6727cc38f00f0c8caebc5f1b7c2b17613ea8ba7df38f72ddb309fa1ba351296
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=4509 bytes; lines=139; markers=<none>; tail=24. Printing statistics. === OooLoadQueue === +----------Local Count, excluding submodules. | +-Local Area, excluding submodules. | | 19305 - wires 19305 - wire bits 19305 - public wires 19305 - public wire bits 601 - ports 601 - port bits 18979 4.41E+04 ce...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/opensta-check-setup.txt

- `kind`: txt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-baseline/opensta-top40.rpt

- `kind`: rpt
- `size_bytes`: 136272
- `line_count`: 1762
- `sha256`: 96396c9a0260fa3397d25da996117c9fbbc8d2d518ffb169a3fbb460d7ebe5f6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: rpt evidence; size=136272 bytes; lines=1762; markers=<none>; tail=P5H7L) 0.000000000 1.479175925 v paddr_q[6]_36__reg_p/D (DFFQX1H7L) 1.479175925 data arrival time 5.000000000 5.000000000 clock core_clock (rise edge) 0.000000000 5.000000000 clock network delay (ideal) 0.000000000 5.000000000 clock reconvergence pessimism...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/coarse-console.log.gz

- `kind`: gz
- `size_bytes`: 321033
- `line_count`: 1256
- `sha256`: e70394e823c82dba825f1996712350deaed074b629fd1280be4b5dc23d3268bb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: gz evidence; size=321033 bytes; lines=1256; markers=<none>; tail=�� �L � s�H� q��x. � �U�S �~u_�� ���F�T%A 1ۍ��F�8�_^��,�#�w�����ł8B g��$�#�q�i΃8B��$B я�L+ �q��h�� � �6X1�󙕩�I�o� )�\�� A� �8�} �q*��l��T��,��T�aD��T��D��T� <��T��L��T�Q4��T��� ǩ�s� �S��$A ��O%B ���`A �} �8�}M �q*�2 �q*� "�q*�J ��N�עA ��ǰ�˔= R^�� � /�8r-6�Qc...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/coarse-synth-check.txt

- `kind`: txt
- `size_bytes`: 121
- `line_count`: 4
- `sha256`: aa625b047150ade58313fe405524e334cd65a312314bc117959f77a9158c1db9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=121 bytes; lines=4; markers=<none>; tail=8. Executing CHECK pass (checking for obvious problems). Checking module OooLoadQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/coarse-synth-stat.txt

- `kind`: txt
- `size_bytes`: 506
- `line_count`: 28
- `sha256`: 39e155b1fc9c3e43f91b6886a51b2bcad06f2657d85784f5390ff45462f13f6c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=506 bytes; lines=28; markers=<none>; tail=9. Printing statistics. === OooLoadQueue === +----------Local Count, excluding submodules. | 4411 wires 41922 wire bits 131 public wires 1208 public wire bits 76 ports 601 port bits 4568 cells 66 $alu 18 $and 353 $eq 1292 $logic_and 132 $logic_not 226 $logi...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/mapped-console.log.gz

- `kind`: gz
- `size_bytes`: 1434281
- `line_count`: 7709
- `sha256`: 23bf9e5321bd30abbbb029952d1ea741952d22b47ea36a23db1b93a9bf5c1054
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: gz evidence; size=1434281 bytes; lines=7709; markers=<none>; tail=J �^� ���� c�t֐�8 =i�Ϣ�� �Z�^L� � ��M�׷��������[˱ϲ�G�]�Q��I�mX�lV~9�pmS�?� � u ) � y<��P ��|ŮR;L� "���q�T&<;N�+{� �GW �2O�FقG �gNQ�k . � � ���ry s8�q} � ; ��( [��[ Ci� Bv�*U� ��D/Ԃ* ��ڑ= ՞�����Pm ���<� W��xo ���,����o�3��)i� mӜc�1k ��* ����v8'w8��ѝE � ��D|�...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/mapped-synth-check.txt

- `kind`: txt
- `size_bytes`: 122
- `line_count`: 4
- `sha256`: 63eee49a55ce075d7be21e4041a8fc292a0c7978dac7a3288b24bb6cd051377a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=122 bytes; lines=4; markers=<none>; tail=23. Executing CHECK pass (checking for obvious problems). Checking module OooLoadQueue... Found and reported 0 problems.

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/mapped-synth-stat.txt

- `kind`: txt
- `size_bytes`: 4645
- `line_count`: 143
- `sha256`: 1a88664a77900054f7b25268e8a96b4eb6bbd0bcf923061df5c73a16fd2babae
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=4645 bytes; lines=143; markers=<none>; tail=24. Printing statistics. === OooLoadQueue === +----------Local Count, excluding submodules. | +-Local Area, excluding submodules. | | 19598 - wires 19598 - wire bits 19598 - public wires 19598 - public wire bits 601 - ports 601 - port bits 19272 4.48E+04 ce...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/opensta-check-setup.txt

- `kind`: txt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: txt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/ppa/local-candidate/opensta-top40.rpt

- `kind`: rpt
- `size_bytes`: 117045
- `line_count`: 1762
- `sha256`: 4c1b2b97db5be1db37505f3e1c511484ccbf71054fd2e36835290473cbefa669
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: rpt evidence; size=117045 bytes; lines=1762; markers=<none>; tail=4H7L) 0.052078564 1.161632776 ^ strb_q[7]_6__NOR2BX1H7L_AN_B_NOR2X0P5H7L_B/Y (NOR2X0P5H7L) 0.125094607 1.286727428 ^ strb_q[7]_6__NOR2BX1H7L_AN_B_NOR2X0P5H7L_B_Y_BUFX1P4H7L_A/Y (BUFX1P4H7L) 0.119242065 1.405969501 ^ paddr_q[7]_9__NAND4BX0P5H7L_C_D_BUFX3H7L_...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/raw-q/assert-g1.log

- `kind`: log
- `size_bytes`: 756
- `line_count`: 10
- `sha256`: cc15e76586044bd42b62a8f1198781a7a99f31b36bf5f6ecd2ae11f6d94833ff
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=756 bytes; lines=10; PASS=12; tail=npc/rv64/vsrc/memory/OooLoadQueue.v:310: warning: @* is sensitive to all 4 words in array 'valid_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:312: warning: @* is sensitive to all 4 words in array 'producer_id_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:505: warning:...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/raw-q/assert-g4.log

- `kind`: log
- `size_bytes`: 756
- `line_count`: 10
- `sha256`: b606e3e81cfdc4ebdc9a7c4634edc7fcea2c7d129c011d7403b86fad9096d5ae
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=756 bytes; lines=10; PASS=12; tail=npc/rv64/vsrc/memory/OooLoadQueue.v:310: warning: @* is sensitive to all 4 words in array 'valid_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:312: warning: @* is sensitive to all 4 words in array 'producer_id_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:505: warning:...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/raw-q/release-g1.log

- `kind`: log
- `size_bytes`: 655
- `line_count`: 9
- `sha256`: 26fe1e9c9b0c7d0d70bdb678d21fbfa44699aeb88b84d033fd3de238d08c7615
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=655 bytes; lines=9; PASS=12; tail=npc/rv64/vsrc/memory/OooLoadQueue.v:310: warning: @* is sensitive to all 4 words in array 'valid_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:312: warning: @* is sensitive to all 4 words in array 'producer_id_q'. [V11H-LQ-BIRTH-CAM] GEN_W=1 dual/full-P/query/res...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/raw-q/release-g4.log

- `kind`: log
- `size_bytes`: 655
- `line_count`: 9
- `sha256`: 627cee6f9d4e9f9649f422f45c094171d7ca6eabe6e4477c6c8ade48b99d07ac
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=655 bytes; lines=9; PASS=12; tail=npc/rv64/vsrc/memory/OooLoadQueue.v:310: warning: @* is sensitive to all 4 words in array 'valid_q'. npc/rv64/vsrc/memory/OooLoadQueue.v:312: warning: @* is sensitive to all 4 words in array 'producer_id_q'. [V11H-LQ-BIRTH-CAM] GEN_W=4 dual/full-P/query/res...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/rollback/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 1149
- `line_count`: 13
- `sha256`: 704f473d78d25ba0cec57e3b46da9d68c70e377628799a0b92476f94e7609047
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1149 bytes; lines=13; PASS=14; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /tmp/rv64-v13d-rollback-build/tb_ooo_load_queue.vvp /home/...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/OooLoadQueue.v

- `kind`: v
- `size_bytes`: 26205
- `line_count`: 628
- `sha256`: 5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: v evidence; size=26205 bytes; lines=628; markers=<none>; tail=`include "define.v" // Shared retire-resident load ordering queue. // // The two per-bank OooMemInflightQueue instances remain transport FIFOs. This // queue owns the architectural lifetime of every ordinary integer/FP load from // dispatch through exact RO...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/parent-live-restored.sha256

- `kind`: sha256
- `size_bytes`: 320
- `line_count`: 3
- `sha256`: 57964f1fa41548a8fec8ecdd31bd4d239beebd88d8931b0a5cee56090670d8b1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=320 bytes; lines=3; markers=<none>; tail=5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f npc/rv64/vsrc/memory/OooLoadQueue.v 1779aa1a56cfbf21409d093f5db92f264d8a76b3f8c6c316960ca83fade27a74 npc/rv64/testbench/tests/tb_ooo_load_queue.sv e2d5f60dac01588bc2b8da1367142ebea67ae1afbbf10...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/pre-rtl-inputs.sha256

- `kind`: sha256
- `size_bytes`: 320
- `line_count`: 3
- `sha256`: 6c6066b6b19958753dc77718070775f392511306f7272d1ccf5318233e024445
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=320 bytes; lines=3; markers=<none>; tail=5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f npc/rv64/vsrc/memory/OooLoadQueue.v 1779aa1a56cfbf21409d093f5db92f264d8a76b3f8c6c316960ca83fade27a74 npc/rv64/testbench/tests/tb_ooo_load_queue.sv cc6ca6200b0ec203d1b4006c04c724b77f6807d0f2a28...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/snapshots.sha256

- `kind`: sha256
- `size_bytes`: 344
- `line_count`: 2
- `sha256`: f4c97a2b2c51033d8fab88e6049d1f5238e92a8f0041a5e3eda4afda0d2bbcea
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=344 bytes; lines=2; markers=<none>; tail=5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/OooLoadQueue.v 1779aa1a56cfbf21409d093f5db92f264d8a76b3f8c6c316960ca83fade27a74 .github/task-runs/2026-0...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/baseline/tb_ooo_load_queue.sv

- `kind`: sv
- `size_bytes`: 17893
- `line_count`: 573
- `sha256`: 1779aa1a56cfbf21409d093f5db92f264d8a76b3f8c6c316960ca83fade27a74
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"FAIL": 2, "PASS": 12}
- `summary`: sv evidence; size=17893 bytes; lines=573; FAIL=2; PASS=12; tail=`include "define.v" // v8v focused LQ test: dual allocation, full ProducerId ownership, final-PA // disposition, dual formal completion/retirement, wrap-safe selective recovery // and fired-load drain tombstones. module tb_ooo_load_queue; `include "tb_commo...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/candidate/OooLoadQueue.v

- `kind`: v
- `size_bytes`: 26429
- `line_count`: 633
- `sha256`: b51b23fcfa269ace90daed7f01f5a5aa7b1d9951ebea26deb6aec8e1108ed13f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: v evidence; size=26429 bytes; lines=633; markers=<none>; tail=`include "define.v" // Shared retire-resident load ordering queue. // // The two per-bank OooMemInflightQueue instances remain transport FIFOs. This // queue owns the architectural lifetime of every ordinary integer/FP load from // dispatch through exact RO...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/candidate/ooo-load-queue.md

- `kind`: md
- `size_bytes`: 22780
- `line_count`: 302
- `sha256`: b99e72aad779dc7dc071942f0ff3725e49bfe7d9203ff176f0f6a6ddee5fb792
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"FAIL": 6, "PASS": 4}
- `summary`: md evidence; size=22780 bytes; lines=302; FAIL=6; PASS=4; tail=# OooLoadQueue：retire-resident Load Queue > 状态：v8v OOO-3 active RTL。共享 LQ 已接入 `OooIntBackend` 的双 dispatch、双 memory > reservation、双 MIQ launch、最终 PA/SQ ordering query、双 response、formal WB、memory > terminal、双 ROB retirement 与 recovery 路径。该模块规范不单独构成 overall ar...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/candidate/source-hashes.sha256

- `kind`: sha256
- `size_bytes`: 519
- `line_count`: 3
- `sha256`: c554d19fa500122be94fd78fa06620e31c252ee2397f5abf7a2dba4018cf69d6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=519 bytes; lines=3; markers=<none>; tail=b51b23fcfa269ace90daed7f01f5a5aa7b1d9951ebea26deb6aec8e1108ed13f .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/candidate/OooLoadQueue.v c0463e593ad3391d5bdf9f3f576c9268f8b8aace2b9e6e94a61af8db523e5716 .github/task-runs/2026-...

### .github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/source/candidate/tb_ooo_load_queue.sv

- `kind`: sv
- `size_bytes`: 24486
- `line_count`: 739
- `sha256`: c0463e593ad3391d5bdf9f3f576c9268f8b8aace2b9e6e94a61af8db523e5716
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T08:00:03+00:00
- `markers`: {"FAIL": 4, "PASS": 14}
- `summary`: sv evidence; size=24486 bytes; lines=739; FAIL=4; PASS=14; tail=`include "define.v" // v8v focused LQ test: dual allocation, full ProducerId ownership, final-PA // disposition, dual formal completion/retirement, wrap-safe selective recovery // and fired-load drain tombstones. module tb_ooo_load_queue; `include "tb_commo...
