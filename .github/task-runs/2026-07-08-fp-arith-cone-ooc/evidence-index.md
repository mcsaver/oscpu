# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-fp-arith-cone-ooc
- `task_slug`: 
- `profile`: 
- `asset_count`: 10
- `total_size_bytes`: 1848503

## 人工摘要

- 本轮 evidence 是 `OooFpArithGate` 三个输出锥的 task-run-only OOC 综合探针，不是生产 RTL filelist。
- 运行脚本：`run_cone_ooc.sh`，关键参数为 `STA_SYNTH_FLATTEN=1`、`STA_SYNTH_PUBLIC_AUTONAME=0`、`STA_CLK_FREQ_MHZ=100`、`make -B`。
- AddSub cone coarse PASS：`704 wires / 9939 wire bits / 628 cells`，含 `36 $alu`、`250 $mux`、`50 $sdff`、`2 $shl`。
- AddSub cone full PASS：area `15782.760000`，sequential area `3745.280000 (23.73%)`，Yosys time `15.60s`。
- Mul cone coarse PASS：`582 wires / 9362 wire bits / 533 cells`，含 `4 $macc_v2`、`176 $mux`、`34 $sdff`。
- Mul cone full 在 `600s` 内终止于 ABC `Extracting gate netlist of module \OooFpArithGateMulConeProbe`。
- FMA cone coarse PASS：`1127 wires / 35734 wire bits / 1087 cells`，含 `14 $macc_v2`、`407 $mux`、`78 $sdff`。
- FMA cone full 在 `600s` 内终止于 ABC `Extracting gate netlist of module \OooFpArithGateFmaConeProbe`。
- `git diff --check` PASS；`yosys-sta` profile PASS；`npc-dev` profile PASS；strict guard PASS。
- 结论：AddSub 不是当前 full stdcell 长尾；Mul/FMA 需要继续拆 multiplier/product、128-bit align/shift-jam、LZC、normalize、round/pack 或引入明确 macro/iterative 边界。

## 证据资产

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateAddSubConeProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 98684
- `line_count`: 418
- `sha256`: 94fdbd1f8579a5ebabe51ef2328cae3770533ab9513fad05e88f5ecb58cd94b4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=98684 bytes; lines=418; markers=<none>; tail=�f �Ze�l��i{�?5�OD7n�.� m��+��V�&�I����d3yJ\e�l^�̶�6�4� ۸Ѭ� ��f�ļ�6�L��W�&�IY�*�d3)�Vu�l�� 6n4�hZo�' ���]& ���]R�:��.����{�IPA���+ <�ڻ4W�۸�n��{�W.z��w��ͫ�w������% �y�2y-rݽˤ�a���+w#�ڻL"���]^� ���e�����2�Y�'!� ���O�~&�H� y���?y�Q�r o�3��<��"��� G.� �R�!2���>4...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateAddSubConeProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 309668
- `line_count`: 1235
- `sha256`: d5088d07010348f8a237245961ac5fc58301fa30cda76d140c2df254d446b7f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=309668 bytes; lines=1235; markers=<none>; tail=�h��,*����̉�) �bS �hq}��T%n��� +<e."�9uU��5j � G��I�~��� v �ǯ# �IpG_N�'� � d� H�8I�I�@���xj��>)��� R�� _ÆF��� �H ��\'-1�I��� ��� xr�t��6�, �%�r�|/��\T�9��Ú�-�H�^GM.�����I}����(�mi !� �E���q�j�N}J eȵ�v r�>IAyǮE�;��!=�@ < N��Ʈ �=������0uڂ�tr�Y �����NIEܶ�(n �...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateFmaConeProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 111305
- `line_count`: 418
- `sha256`: 38e34ddb61a8babc7bf073844f6149d9996c8d469d8ad3e27213be62bb79ff59
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=111305 bytes; lines=418; markers=<none>; tail=��ypD�� �� ��F��*ִ�ȸ��D7"no���H4�Ě����� r{#:���,:"np����΢#<��� !78��� ϲ#�E#�E#<��(��0���4:�x0�x0���"� #� ϓ#��"��"< ��� aL �nD � c� Oe#Q� k�w�T6�Sو�� Ft ��Fx* ;8�x0�S� Oe#b G M�S� Oe b � t* �l@�h��h@�� �� � � t* �l@�h��h�� E� F� �� t2 ��h@�h��h �b�Τ �, P�(��...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateFmaConeProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 747961
- `line_count`: 2907
- `sha256`: 869cb3445fce95a9554f61f6eee9d2fbe01f3618bd2b3579616de647b4b12bb3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=747961 bytes; lines=2907; markers=<none>; tail=�����lm^? ]s� ���S�W�ODל4�#k� 3W��ϔ�Ӑo��.��iHQ��b f�8�����{ i� ��1��E:�B����� �$��8���� | i�o �j�q #} U� �� $�mƁ��- �+H�# ��� 2ҷЊ� � v@ �f �H�B7���:� �l�q���f���T�=g+��ɚPW� @��\� ~��ҫ�V ��[�*ܞ��5x� {+ �5�4A� 3��*� ��u8H�c��^�� ^� ���ҫ�V �k�n ��tx� x+�'�k�g...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateMulConeProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 95894
- `line_count`: 371
- `sha256`: 6639d54a640f2c49ba44b32da50fc8b7270e1d35658e73c2e0b3fc88e15f696d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=95894 bytes; lines=371; markers=<none>; tail=��=� �� ��zp ��=� ���8������7?}�|��O����?��7�x��/���_ �������<|���������Ǜ���rw����o��˗?~���������ow?��[���֧��~�{|�~�G ]�0L�`E1�*a��zt����O��.? ����=�i}��W� l�0�k��� ��U��(�[���*���� ��'��E{ & �#fe1��a�u!Ąa^� � 1 �l�:�����>z k��؊ܢu7z"�dT��u��Z �MHF�^*�C���w...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/OooFpArithGateMulConeProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 476465
- `line_count`: 1919
- `sha256`: b09ef2f16becda698b1c69097dc8c4fecbe8ccad823b1a96ab9c48872af9ef9a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: gz evidence; size=476465 bytes; lines=1919; markers=<none>; tail=;�~�e�-^ � � u-.�l� ��. zA-U@ R ��� �R � ���o�[f� )�vY� j� ��NF�eYe� )�v2:B�*[< H ��� ZV�� Aʠ�Pw�� � R 턚���B�*1�G� jY%��Hz?-��X A���AT@�* ���緽�� �i�"�rYe�{����V)r/�U���� �i�"�rYe�{����V) �,�ly/ ��*Eb�e�-�%� z�6��dYe�{�����M$&YV��^B*��P����� (AJ��P���̖���@ u...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/agent-e2e-guard-strict.log

- `kind`: log
- `size_bytes`: 1795
- `line_count`: 4
- `sha256`: a5b4e7f049e1ca896cb1d8e4203c1ba103e0d9fb3e0d35e5fc5054c6cc954305
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1795 bytes; lines=4; PASS=6; tail=[agent-e2e-guard] mode=strict changed_paths=231 required_profiles=3 [agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-08-yosys-pmpchecker-range-share-agent-system reason=.github/e2e/modules/toolchain.md; .github/memory/modules/a...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/evidence/probes/OooFpArithGateConeProbes.v

- `kind`: v
- `size_bytes`: 5389
- `line_count`: 176
- `sha256`: 7deb772a5cb9691c54a1a01db2cbc42d189f0804f05bf5849269a0d75977fc20
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: v evidence; size=5389 bytes; lines=176; markers=<none>; tail=`include "define.v" module OooFpArithGateAddSubConeProbe ( input clk, input rst, input flush_i, input [`XLEN-1:0] frs1_value_i, input [`XLEN-1:0] frs2_value_i, input double_i, input sub_op_i, input [2:0] rm_i, output [`XLEN-1:0] value_o, output [4:0] fflags...

### .github/task-runs/2026-07-08-fp-arith-cone-ooc/run_cone_ooc.sh

- `kind`: sh
- `size_bytes`: 1342
- `line_count`: 48
- `sha256`: 98fb2c3026d7dfcd2318ff03c54196a5fb4f634b6c715f5159d3094998cd9e0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:22:09+00:00
- `markers`: {}
- `summary`: sh evidence; size=1342 bytes; lines=48; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail ROOT=/home/lyg/PA/ysyx-workbench TASK_DIR="$ROOT/.github/task-runs/2026-07-08-fp-arith-cone-ooc" PROBE="$TASK_DIR/evidence/probes/OooFpArithGateConeProbes.v" RTL="$ROOT/npc/rv64/vsrc/execute/OooFpArithGate.v $PROBE" run...
