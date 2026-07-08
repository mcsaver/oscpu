# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-fp-arith-internal-cones
- `task_slug`: 
- `profile`: 
- `asset_count`: 14
- `total_size_bytes`: 2014911

## 人工摘要

- 本轮 evidence 是 `OooFpArithGate` Mul/FMA 内部 standalone cone 的 task-run-only OOC 综合探针，不是生产 RTL filelist。
- 运行脚本：`run_internal_ooc.sh`，关键参数为 `STA_SYNTH_FLATTEN=1`、`STA_SYNTH_PUBLIC_AUTONAME=0`、`STA_CLK_FREQ_MHZ=100`、`make -B`。
- 5 个 coarse probe 均 PASS 且 `synth_check` 0 problems：Mul product、Mul normalize/round、FMA ref/shift、FMA 128-bit align/add、FMA normalize/round。
- `OooFpMulProductProbe` full PASS：ABC `19488` gates，area `41726.44`，delay `35.00`，Yosys `80.47s`。
- `OooFpMulNormRoundProbe` full PASS：ABC `5345` gates，area `9883.16`，delay `46.00`，Yosys `16.67s`。
- `OooFpFmaRefProbe` full PASS：ABC `3284` gates，area `6006.00`，delay `38.00`，Yosys `8.34s`。
- `OooFpFmaAlignAddProbe` full PASS：ABC `12001` gates，area `22277.92`，delay `48.00`，Yosys `62.82s`。
- `OooFpFmaNormRoundProbe` full PASS：ABC `5635` gates，area `11052.44`，delay `43.00`，Yosys `23.19s`。
- `git diff --check` PASS；`yosys-sta` profile PASS；`npc-dev` profile PASS；strict guard PASS。
- 结论：Mul/FMA output cone timeout 不是单个内部 helper 不可综合，而是完整宽 datapath、double/single 双路径、normalize/round 与 output mux 累计后的 ABC 长尾。
- 后续生产 RTL 拆分必须配合 `debug/common` spec 语义审核，尤其是 B-FP meta、kill age、redirect/facts 与 value/fflags 对齐。

## 证据资产

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaAlignAddProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 14227
- `line_count`: 77
- `sha256`: 8928e0b01be2ca9eefa8d42f4e8a8c670f99c731d242f439ec276491df7d4f1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=14227 bytes; lines=77; markers=<none>; tail=� paMj OooFpFmaAlignAddProbe-coarse.log �]�o�F��� Q H�����| ��3\g �|���H G�h[ �Ғ�[ �ǿK��D�bx��Uä�.�hf�s瞙{9璓���Qp gQ2����(� �4� �����7���:�ݦ�� �:M>~���u/� zɍ� &��-� �v�ަGi֧1>R��h ��d��|4 ��c��t�x�x�? �����U2� qƞ?�� \O�l0n ��&z� Ͳ����_���h�Β�<S*x�]���W��z����...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaAlignAddProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 550752
- `line_count`: 2376
- `sha256`: ac7896a9aace7320e47ba82480206933621362876960c4849a39b15ac057596b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=550752 bytes; lines=2376; markers=<none>; tail=ƺL �@#�#���ܢ�W� � A���ּ1,�ҽ[��j�@ �� ��qQ7c�� Dg�#9�s�(O3F��:|�J���X���߸5�Ej��h��fA o�s )�V�"}��(W �����6 {۠ �l�@)p9��6�"�CP��VU���m� 7*϶G��� �F o�� ., � -Td� ^�^��Z���V-��A 8�&� u�"��� )��wS*�L=`���,�u8�o��, �vCn�A� �|� s�a9]8� ��� T��gL��'��| ,�ǳA �a � [�...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaNormRoundProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 25311
- `line_count`: 98
- `sha256`: 75ea81bcc0084099d4224a1fdd1be79ac9aad6cb3a4758df4b9aed5bad4281fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=25311 bytes; lines=98; markers=<none>; tail=� paMj OooFpFmaNormRoundProbe-coarse.log �]{o�F��_�� 8AV�~��m '(�98� {o ȁBq(�� rBrd+� ��戜!%�,�٫ ؅�)v=������<� ?w��2Γ�&y �Y~�<ۿ������b����uq�e�s� :���r?]D����>ۙ��'�7� �Yq]� e c|�g���s ��g�d6݇ ��fًŋy�&����2��˳�x� ���;qt�9e4�uԕ �E�'����2Q�u �$Q�ȳe�y���n {r���...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaNormRoundProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 286966
- `line_count`: 1042
- `sha256`: 8ab6882b45a62b5f25edd34d967de599e949dffd659c7c91967c241ca667f5f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=286966 bytes; lines=1042; markers=<none>; tail=�u uKe�� GF��q � AG�?iV��ư �r. e���5 �� �@ L�0(WYXm����r�Y8�l["S>J;o �+k�I���X�g�E�aE~�� �o�bk�l� 4�6�CwC�2�G!dy�?��������Lw�� !@KQ��+�s5�- �@��ÐBsT�A �Q��y� E��=�3�Mw�{ 뢇�. �א�h p �U &�� e)H�� �(��5 �(��7c ���Hd� � �% ]�f� %�� B �� o2�R� ~:J� �� RH��М܀�b$...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaRefProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 8905
- `line_count`: 34
- `sha256`: 8f71fb1b844155e73f294b0d85ae5f6885e9a224c57e0d2b87ce33d0f3d51216
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=8905 bytes; lines=34; markers=<none>; tail=� oaMj OooFpFmaRefProbe-coarse.log �]ms�8���� �)Ue���� �t]m�ϑ7�� �㹝)g�CS�� EjIʉ��� ^H��(��E�� f ��~��� �h������(�p D�` $���� �:z�'�(|�?�89zJ�� ~��/�8� ��� �<"������� � �O�a�yD� � NA �G�� ��G ��lz6�.��E ��C]����q��� d~�Q�\�Q�'�4K�/C�nY0 �t�ĳ B���MR��A�0�=ʼ��...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpFmaRefProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 167455
- `line_count`: 693
- `sha256`: 3e74d39cdd0bc1270532e6617ce371b0cd905a4ae937839c3e5ebbbdf7aa075b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=167455 bytes; lines=693; markers=<none>; tail=�q�� ��%L%�O:�Q� ԕ���D�7�^r� �ݸ�k(�%�x�����z ����ϝ9� "� �ή� W�Z$Uy6�"k6��J��u��d�J`B�Q�Q0�լ���S5��t[�D5� �6 ���-M���?�ЉMw8d 9�Sp�:� :��{� ��{ :���\��"*�> �1�>8��|i�؂�{�(���v��mk��ݚ���n� ~�K؉�'���mo ���9� خ`�q� F�*�7�8{��2�<]��#�͒ɂ Q�� E��\��x gZ#�U��s Z��ݯx...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpMulNormRoundProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 19099
- `line_count`: 97
- `sha256`: d31e77437b289acca894b9d61b52dfba8d5d25f6445a0a01dbbb5365b6de56ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=19099 bytes; lines=97; markers=<none>; tail=� oaMj OooFpMulNormRoundProbe-coarse.log �]{o�8��?�B � f� ���� 2�mq�Bڽ; w�Ql%�֖<��6��� IY��ǉl � v��$�� � �Cj ~�^Z�I eqrmM�,� ivg�8�I����������]~���[�}�����I���d�.}q4g�G�7� wi~� �E�����X� K����2�MOXǓ i�j�n9{�f�t�L?f�et�l���?���Mj �ٽ��\��,^ 9��a�o��V<� Y�, ��...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpMulNormRoundProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 222509
- `line_count`: 833
- `sha256`: dbb3ea74c3314cb4ef6ccb2b5e45e3c7f93a76c9379a35de706b2ccf609e536d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=222509 bytes; lines=833; markers=<none>; tail=w$F �O� 8Q�y� ��R�� ~ �v�i� 1��}b � )T1|�) 0| D 0��M� w R� �K Q���dz��C1h�� `А6| ����ˌ* �|j�A +�26���P���H Pl � ��z�4h ��R �O� ���� t���+�V� q��a����!n�JW }Y^ ��v����A��#�#krҽ *w�J ފZ � �� #��b���>�l�i<��V� �� ���a�rKr �f�$l��G 4�j�a�-h� K�� eˁ � � �� H�=��...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpMulProductProbe-coarse.log.gz

- `kind`: gz
- `size_bytes`: 2755
- `line_count`: 9
- `sha256`: cc04a727bbe5defd063db11ed90701b8de146020535e841e4f279b05eaa0119a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=2755 bytes; lines=9; markers=<none>; tail=� oaMj OooFpMulProductProbe-coarse.log � kO���� Ũ�T��yA D���&N�]B�$l�JE'�$���z�@���{�� ? � �+� �3����M/X�h�`��,�a�L ��"o+K�f k���ڕ _]�W� 1c���8�^�/��o �Ծ� ���+�rA � � �#?B�2 L˨ `e�=o X#�5 ]�� Sk�������K�n݊3��u�� �� n rb����@4 ���m�� S,�YEP~����+�j��V���:�T�...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/OooFpMulProductProbe-full.log.gz

- `kind`: gz
- `size_bytes`: 701390
- `line_count`: 2678
- `sha256`: 343dc2bcbe0b14a3aff1064829f0013ff7786b224a3911dfad90d075b543cb55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: gz evidence; size=701390 bytes; lines=2678; markers=<none>; tail=����� ( �h ��� �}�� ~�nE<Ďz�����(:��j b@`�W͵ �ލ3��`c��5>��� �z� �� ���3�] VF��� �u��q{7 { y�`��{�&��Z0��Ї�RM��%M��q�q����ш� f��?$Y����P���E U�m�TG����{G_q`<D�n ��l ���? ��|cl������ ���e �azdG��� 1!�c�cO �~���K�� �� j����B9�x �e� N��Ղ0<w� �=-*�F�< b ��� �!Sd...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/agent-e2e-guard-strict.log

- `kind`: log
- `size_bytes`: 1801
- `line_count`: 4
- `sha256`: 3aea1cea5a4893bc440016b4c8bbbe43100af6dbdfc736807584b61cad151ecf
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1801 bytes; lines=4; PASS=6; tail=[agent-e2e-guard] mode=strict changed_paths=250 required_profiles=3 [agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-08-yosys-pmpchecker-range-share-agent-system reason=.github/e2e/modules/toolchain.md; .github/memory/modules/a...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-fp-arith-internal-cones/evidence/probes/OooFpArithInternalConeProbes.v

- `kind`: v
- `size_bytes`: 12069
- `line_count`: 376
- `sha256`: db588bd59be72569043251fe755a00f743d9f30d52c7c6b411adbbe4e08d7442
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: v evidence; size=12069 bytes; lines=376; markers=<none>; tail=`include "define.v" module OooFpMulProductProbe ( input [52:0] sig_d_a_i, input [52:0] sig_d_b_i, input [23:0] sig_s_a_i, input [23:0] sig_s_b_i, output [105:0] product_d_o, output [47:0] product_s_o ); assign product_d_o = sig_d_a_i * sig_d_b_i; assign pro...

### .github/task-runs/2026-07-08-fp-arith-internal-cones/run_internal_ooc.sh

- `kind`: sh
- `size_bytes`: 1672
- `line_count`: 57
- `sha256`: 58371d4eaaa591a3dfca71ff6279d1c462af4ccbd705bbba2a3e06c7df157246
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T20:39:06+00:00
- `markers`: {}
- `summary`: sh evidence; size=1672 bytes; lines=57; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail ROOT=/home/lyg/PA/ysyx-workbench TASK_DIR="$ROOT/.github/task-runs/2026-07-08-fp-arith-internal-cones" PROBE="$TASK_DIR/evidence/probes/OooFpArithInternalConeProbes.v" run_one() { local design="$1" local stop_after_coar...
