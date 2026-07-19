# Evidence Index

## 基本信息

- `task_id`: 2026-07-19-rv64-v8d-int-ex-completion-kill-cut
- `task_slug`: 
- `profile`: 
- `asset_count`: 149
- `total_size_bytes`: 1309518

## 证据资产

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/check-contract.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 4
- `sha256`: 383669104782035acf10431c28fe9b7a6d32cc980a3c667b54a7684b21a77742
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=273 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=295 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 295≥89 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/check-rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/assert.make.log

- `kind`: log
- `size_bytes`: 603
- `line_count`: 16
- `sha256`: 6b00499abbfd7bbe09adfd1bfe366d62289e9ed4759b7ce7da67d85e55eafc8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=603 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10911
- `line_count`: 65
- `sha256`: ee2c0d87745c68dbd28e254de19e3c74625ee10e871312fef164d8050ea0dc6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=10911 bytes; lines=65; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-assert/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/assert/summary.txt

- `kind`: txt
- `size_bytes`: 288
- `line_count`: 10
- `sha256`: 317ca1ad16a584138e4b3be7a211c789f9f50ce9e65520375a992d269d569294
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=288 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/assert - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/current-sources.sha256

- `kind`: sha256
- `size_bytes`: 661
- `line_count`: 5
- `sha256`: 420348fc0d5c2efea52541043371e4cfb6e1ac817a313355a23f2c8e0a530442
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=661 bytes; lines=5; markers=<none>; tail=a140dbf148a342990cc8d5b615a2b144e10aa6b9165ded06f6a42304544099a9 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v d210f6c84c32d52bf3dda49be4f9420076527637ae38ea62e83ac5eb41a5828c /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_i...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/green-summary.txt

- `kind`: txt
- `size_bytes`: 946
- `line_count`: 14
- `sha256`: 9ec32d27a6fcde830e6684c33e14d65e2f83e6b78e2b098727ed737197a7be1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 28}
- `summary`: txt evidence; size=946 bytes; lines=14; PASS=28; tail=[PASS] release exact focused GREEN [PASS] assert exact focused GREEN [PASS] compile-success semantic mutation detected: ex1-mask-removed [PASS] compile-success semantic mutation detected: ex0-equal-killed [PASS] compile-success semantic mutation detected: e...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-dispatch-wb1-fanout-raw.make.log

- `kind`: log
- `size_bytes`: 527
- `line_count`: 7
- `sha256`: 0686c71f7a8ae62c7515170eeb1b34191f65d5c1f911b5b421367a66aa7fec38
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=527 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-dispatch-wb1-fanout-raw/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11454
- `line_count`: 72
- `sha256`: 106d05cf9651a12c71d4190f9631ce246aeaaf1f7ecac15d314653535cf13049
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 10, "PASS": 2}
- `summary`: log evidence; size=11454 bytes; lines=72; FAIL=10; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-dispatch-wb1-fanout-raw/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex0-equal-killed.make.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 7
- `sha256`: f03b6af9966bbafddc07f0726a87be7d04ea8b2d338662be59d5016e3b5616ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=520 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex0-equal-killed/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11699
- `line_count`: 78
- `sha256`: b1d3ddc533891eab18cb35cb146cd2a489e67026141d04869358da63fdfb5845
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 16, "PASS": 2}
- `summary`: log evidence; size=11699 bytes; lines=78; FAIL=16; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex0-equal-killed/tb_ooo_int_backend.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex0-global-mispredict-mask.make.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 7
- `sha256`: 38c4fe9e869007e217d6518c2bafb897fd13b2024b2fb16ba453fadf78955291
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=530 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex0-global-mispredict-mask/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11730
- `line_count`: 78
- `sha256`: c0220daf76499d69a83d50d0293a6dd6e28c0e678f8109177576f50a5ff68bfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 16, "PASS": 2}
- `summary`: log evidence; size=11730 bytes; lines=78; FAIL=16; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex0-global-mispredict-mask/tb_ooo_int_backend.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-forward-mask-removed.make.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 7
- `sha256`: 57930067c469bb28874b0f8eb2541e83ba44bab2ce3037b09ce8be5b1eab1072
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=528 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-forward-mask-removed/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11204
- `line_count`: 71
- `sha256`: 4585d5f160155892304b337f3bda55387fcf69528591ed28f96e4a3df929fa0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: log evidence; size=11204 bytes; lines=71; FAIL=8; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex1-forward-mask-removed/tb_ooo_int_backend.vvp /home/l...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-mask-removed.make.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 7
- `sha256`: 4aa5c34d25726844795d83aaac7fe455acabf9d3565f4ad0e3ad07c0f215d6fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=520 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-mask-removed/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12455
- `line_count`: 88
- `sha256`: 2e4fb0771a6e5091fba603efdd50234e19ce8d6b1fa9fe4015b0d4fdd53e3870
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 36, "PASS": 2}
- `summary`: log evidence; size=12455 bytes; lines=88; FAIL=36; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex1-mask-removed/tb_ooo_int_backend.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-prf-mask-removed.make.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 7
- `sha256`: 645479b874144949646b98eb3bec132a84f567acb8ed758bc70975c031c8f877
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=524 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-prf-mask-removed/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11689
- `line_count`: 77
- `sha256`: cfe07c9740cc01d4740dbdb658109b61ffc88b5c496c580a9599675f5ce5ccaa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 6, "FAIL": 10, "PASS": 2}
- `summary`: log evidence; size=11689 bytes; lines=77; FAIL=10; ERROR=6; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex1-prf-mask-removed/tb_ooo_int_backend.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-raw-index-compare.make.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 7
- `sha256`: 11e192b9a79c2d4585065f824209f7b1f286748196892c912728b51b51e1530c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=525 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-raw-index-compare/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11431
- `line_count`: 74
- `sha256`: e1037457cc0183416f55af3f5ba0b2a0aae6773959b7f440f30d31e46030ff9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: log evidence; size=11431 bytes; lines=74; FAIL=14; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex1-raw-index-compare/tb_ooo_int_backend.vvp /home/lyg/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-wrong-owner.make.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 7
- `sha256`: 852543eac15d2f54c00f2efe6f500ec8253908b5965b3e1bed783e059d192d2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=519 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-ex1-wrong-owner/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12364
- `line_count`: 87
- `sha256`: 4bc50fe828cf121addd32697be9d885c6a9bbac4cfaf088465016df74c6103d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 34, "PASS": 2}
- `summary`: log evidence; size=12364 bytes; lines=87; FAIL=34; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-ex1-wrong-owner/tb_ooo_int_backend.vvp /home/lyg/PA/ysy...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-fp-iq-wake1-fanout-raw.make.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 7
- `sha256`: 643c32975ff103242f0302632c5bd9494b931f54f632ddb85b3babb4d19b1534
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=526 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-fp-iq-wake1-fanout-raw/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11439
- `line_count`: 74
- `sha256`: 18940949e435b32f6a01341b2739ed7354be1d53e5714e44aaa9d6d4b2c1639a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 8, "PASS": 2}
- `summary`: log evidence; size=11439 bytes; lines=74; FAIL=8; ERROR=4; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-fp-iq-wake1-fanout-raw/tb_ooo_int_backend.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-killed-ex0-blocks-muldiv.make.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 7
- `sha256`: 8d55ca5cfc958ebff9c30d8172ef4f03b8e93c6e79b1672c000c58719126041a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=528 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-killed-ex0-blocks-muldiv/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11355
- `line_count`: 73
- `sha256`: 44515a0056238a1fe905a04dea700ff7ae254b9a149f86e6b06a2946b5a525c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: log evidence; size=11355 bytes; lines=73; FAIL=12; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-killed-ex0-blocks-muldiv/tb_ooo_int_backend.vvp /home/l...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-killed-ex1-blocks-muldiv.make.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 7
- `sha256`: 4207056d86c71e3e5add3eb3f2564a0dec66b05fd9a2bf877744a95a51cf6923
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=528 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:300: /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/mutation-killed-ex1-blocks-muldiv/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11283
- `line_count`: 72
- `sha256`: fe5dd3f313f41565fe1c24fdb4404316fb236bc7ef1caabb2bdbb4b937bcd992
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: log evidence; size=11283 bytes; lines=72; FAIL=10; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-mutation-killed-ex1-blocks-muldiv/tb_ooo_int_backend.vvp /home/l...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/release.make.log

- `kind`: log
- `size_bytes`: 604
- `line_count`: 16
- `sha256`: dae69b52e0ac60d44059babea454b040862f6a56e3ef19fb9aa92df16f991110
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=604 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10360
- `line_count`: 61
- `sha256`: 8dfc80d02a83b356ebfb534618c059463d75e7de69152cf6c65eb89f72107fc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=10360 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DINT_EX_KILL_CUT_FOCUSED -s tb_ooo_int_backend -o /tmp/v8d-int-ex-kill.4EV4Om/build-release/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/exec...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/release/summary.txt

- `kind`: txt
- `size_bytes`: 289
- `line_count`: 10
- `sha256`: 283fae087b9ff2899a54dd3d9bdb7f7c4443ca2fed6a2510c3a2cbcdc69d27ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=289 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/focused-replay/release - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - tota...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/full-lint.log

- `kind`: log
- `size_bytes`: 62643
- `line_count`: 687
- `sha256`: 234fd4ee7058c151b6194a9d5167369f4eedbbfc8b70349d9875c0fb4ffc6917
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: log evidence; size=62643 bytes; lines=687; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/full-lint.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/full-lint.sha256

- `kind`: sha256
- `size_bytes`: 161
- `line_count`: 1
- `sha256`: 08e28437346e4d808d101f7bef5268bef193737066bd36546150a9cbbb19d564
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=161 bytes; lines=1; markers=<none>; tail=414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/full-lint.normalized

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused-r2/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10901
- `line_count`: 65
- `sha256`: 893d9271f67327cf2670ff5c9a1272590ed6eee9e70eae77067044c2dac6960d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=10901 bytes; lines=65; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DINT_EX_KILL_CUT_FOCUSED -s tb_ooo_int_backend -o build-v8d-int-ex-kill-green-r2/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/ex...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused-r2/summary.txt

- `kind`: txt
- `size_bytes`: 283
- `line_count`: 10
- `sha256`: 2728819a3eb062a5111a95a01f7cc0d0bf1543200e42fd47445dfc1c6e6f058f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=283 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused-r2 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total: 1 -...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10851
- `line_count`: 64
- `sha256`: b2ab0fe2c252e6ab6e7c5c5815f84ec502bfe7ef52af33b291d3113164432879
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=10851 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DINT_EX_KILL_CUT_FOCUSED -s tb_ooo_int_backend -o build-v8d-int-ex-kill-green/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execu...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused/summary.txt

- `kind`: txt
- `size_bytes`: 280
- `line_count`: 10
- `sha256`: d43a1fa34b6095cde831fc36c501758fb0d5c26fdd8ce4c3acf0c5d88f5d01e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=280 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/green-focused - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total: 1 - pa...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/evidence.sha256

- `kind`: sha256
- `size_bytes`: 528
- `line_count`: 3
- `sha256`: 3ef5a55ef4b7626ac3b9fbea344fbc370288e07b7a75eae0d191637f25fe5f39
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=528 bytes; lines=3; markers=<none>; tail=b4f3929832f7e277e474c55010146f679f335e5a4f83ceb6060aa2c6b17642e1 .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/summary.txt f253637d2df8488ff801cd46595009de45c1084cb5a36252722963366859d822 .github/task-runs/2026-07-...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 296
- `line_count`: 5
- `sha256`: 10f367d24310ec95fc171b6faa2dc48468fe95135861b20cba1052fddbd6e327
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=296 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build-v8d-module-current/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/tb_alu.sv [PASS] tb_alu common/tb_common.svh:32: $...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 328
- `line_count`: 5
- `sha256`: 94890c96b0e8a5ca1c838d0108f6549073cf6a88bdf6f30afd1579b238dbd50a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=328 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build-v8d-module-current/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiClint.v tests/tb_axi_clint.sv [PASS] tb_axi_c...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3428
- `line_count`: 28
- `sha256`: f540901a5d8e3753137290deeaf6c46087b4136445e90d6a9af03393ede9adce
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3428 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build-v8d-module-current/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiDefaultSlave.v /home/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 436
- `line_count`: 6
- `sha256`: ccdb7220818701fc837595656114a318bc58ec9f0541e145ddab169f455ab2b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=436 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build-v8d-module-current/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiPlic.v tests/tb_axi_plic.sv [T4D-PLIC-PRIORITY-W...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 6
- `sha256`: bb7831c4fd97b17008c399b3039d7f17f5b189d4550bbde1abb278462bbe0f6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o build-v8d-module-current/tb_axi_reset_syscon.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiResetSyscon.v tests/tb_a...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 392
- `line_count`: 5
- `sha256`: 6b4e83602892962152bf121d1aa00d02f16ca6525ae94e859a9a0e7509ab06fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=392 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build-v8d-module-current/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiToUart.v /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3208
- `line_count`: 28
- `sha256`: 41dce58a23bf2bd0c9bae8a50bd7ed9af04560125fb8e4a9e7cbbb0cc6e4ad2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3208 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build-v8d-module-current/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiXbar.v tests/tb_axi_xbar.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 323
- `line_count`: 5
- `sha256`: 902d9e1221c79c7db8faef4962097084e6f472a17d3bee336e867d7766d840eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=323 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build-v8d-module-current/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/CompareUnit.v tests/tb_compare.sv [PASS] tb_compar...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 323
- `line_count`: 5
- `sha256`: a7836e180d49721b11dcd49c3a0e8dd047c4afbef5167c1058817b3b0e6e506c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=323 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build-v8d-module-current/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v tests/tb_csr_file.sv [PASS] tb_csr_file...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: e5fb893ce0aaa30005f453dbc6a55848d326bc8542f885a0c0860339ea8f5d83
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build-v8d-module-current/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/DecodeStage.v /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 5
- `sha256`: 27232563e89cd0e5163d44158b88c0aa2cd76a40ba4d61541f97f94d37ebdc66
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=342 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build-v8d-module-current/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/DecodeUnit.v tests/tb_decode_unit.sv [P...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 312
- `line_count`: 5
- `sha256`: 6f2e967ff016af84cde0d0dc5447902c052742472b94c44cd1b2d2b9ed9d663d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=312 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build-v8d-module-current/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGen.v tests/tb_immgen.sv [PASS] tb_immgen common/tb...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 0dfb7011e7003c1a3c2ab284637c29346f2c058b804ff137653a872a69dff654
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build-v8d-module-current/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSUContr...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 341
- `line_count`: 5
- `sha256`: 443d6711fbcb1bee15f66f44643b4c1c51e088695890889ba47e36de8458620e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=341 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build-v8d-module-current/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSUControl.v tests/tb_lsu_control.sv [P...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 5
- `sha256`: d318e151ca1d1b3a4faa2946b2323aea533b78a220f229cccb74c3b8aae902d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=347 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build-v8d-module-current/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSUDataPath.v tests/tb_lsu_datapath....

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15633
- `line_count`: 95
- `sha256`: d10d44af2c6b51f426862db7da6235537be630ce56bb4733d8f266316fd1ef2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15633 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build-v8d-module-current/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/DecodeStage.v /hom...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15461
- `line_count`: 93
- `sha256`: 5563ab4f3c0b6fabb864636a47be5d1c86cc52337b2c9fe2de13e4b4f9a02e14
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15461 bytes; lines=93; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build-v8d-module-current/tb_ooo_alu_decode_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/Decode...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 5
- `sha256`: 1d0ed30fe55b4c376105087b4f1145901faeb7f916cf4001a0ffa1139b5ffd40
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=347 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build-v8d-module-current/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooAmoGate.v tests/tb_ooo_amo_gate....

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 7f36429b49018b003c6f78e0825dc20637d1a5f3660a9d305f33d8c0fa40993f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build-v8d-module-current/tb_ooo_backend_drain_tracker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/fron...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 379
- `line_count`: 5
- `sha256`: bc36ba9ea52c15ee519cb070fc62f3e089a7c6c8d151857c8179138e5aa641eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=379 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build-v8d-module-current/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooBitmanipGate.v te...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 804
- `line_count`: 9
- `sha256`: db6eab4972dccf5138bb360c49748074272d872ba39dec6f3ca7602a1e60f97b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=804 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-v8d-module-current/tb_ooo_branch_append_dispatch_gate.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 759
- `line_count`: 9
- `sha256`: 967c0f4d23f794f1840d601d3117e060ae08d72bbf9657aea62280af14f88c6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=759 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build-v8d-module-current/tb_ooo_branch_bpu_update_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/f...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 542
- `line_count`: 5
- `sha256`: 6f2af910084705d1dd65228f242d4d34741146469673ef997f1b63f9a6362f39
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=542 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build-v8d-module-current/tb_ooo_branch_direction_predictor.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 814
- `line_count`: 9
- `sha256`: 736f732f100c4ed5bd3d476e17617ac68b82a50f02441b1f652117f4ea02d20a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=814 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build-v8d-module-current/tb_ooo_branch_resolve_recovery_gate.vvp /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 414
- `line_count`: 5
- `sha256`: 1d25f312e7b296dbed530810f3326fd0479c28c0281d7a822d4be45bd43fa26e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=414 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build-v8d-module-current/tb_ooo_branch_spec_tracker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/O...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 6
- `sha256`: 3d0ee44f9412e67ccedf05203caf748fe969fa7e26e8576ddb93ae4ce6999ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build-v8d-module-current/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooBusyTable.v tests/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: 61f9ccb3f26ed23bb3b8a5f5db83cb6083fa528013bcd7ac785a10090aa3f374
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-v8d-module-current/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v tests/tb_ooo_c...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 9
- `sha256`: d473c133b678a6a31da07b58e1ee6a7256ac64b17360290b09f831e7caccefef
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=717 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build-v8d-module-current/tb_ooo_commit_output_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/OooCom...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 782
- `line_count`: 9
- `sha256`: ee3844325c6ba4ba92fa143243282e3c2ff9e3865d93c718493c43c64580baeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=782 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build-v8d-module-current/tb_ooo_control_commit_sequencer.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 769
- `line_count`: 9
- `sha256`: e42586b2a0328186c514c22b37f84ba21ad7e0a08a14051484ba6020e244ef7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=769 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build-v8d-module-current/tb_ooo_control_flush_sequencer.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15697
- `line_count`: 69
- `sha256`: eda1034a9a0df516f8f11d5778e42ffe64db7a03edfa56d30029a1d0fc9a9904
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15697 bytes; lines=69; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-v8d-module-current/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlFlushSeque...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 447
- `line_count`: 5
- `sha256`: 72977a437927ae4502f35b93a315529d8cc5b810c0c09524151eb217fe687e06
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=447 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build-v8d-module-current/tb_ooo_csr_access_request_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/c...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: e20b12b1513b7d98354b6b37503e7b3ec94f37138c849572b0487d30298c0b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build-v8d-module-current/tb_ooo_csr_trap_request_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: 8fb09aeb46430d91cb90cee7cc8332dc804db9c6051d9e481bea2517cb375850
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build-v8d-module-current/tb_ooo_data_word_cache.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: c1f44daca837ae4f2726ec9026bc991fdaf68f600906e13f17879cf7c4ca7058
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build-v8d-module-current/tb_ooo_direct_branch_resolve_gate.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: f600f485a5c2d5304f9998303ad689d3c512ed22e2462c5b63656c1fb4b26e46
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build-v8d-module-current/tb_ooo_direct_branch_wait_buffer.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 70483c47e63f31c253b227ec2cce92af8e7e11ca2a2517b88258deedfe08283e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build-v8d-module-current/tb_ooo_direct_ras_candidate_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5352
- `line_count`: 37
- `sha256`: 5e78385c8df59dc087ad01fa60cb9d4d04c2a1cae169c6cb3b6842ef2652fdd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5352 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build-v8d-module-current/tb_ooo_dispatch_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/Ooo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106816
- `line_count`: 846
- `sha256`: 86b5fcd2484fa59a4e36126e59e806733f9026f58a3f1c064f4db93fbccc6fc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106816 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103559
- `line_count`: 779
- `sha256`: d6f9a9b331e0bc45df9e92920569e4bd69c7ffc6f8321828f395895d68ea5a1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103559 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104363
- `line_count`: 788
- `sha256`: 8e7e793dab84c83a282a492408af37bf3e874fc1408cb997f6461564f5b5babf
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104363 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106496
- `line_count`: 802
- `sha256`: fdfda98bd35b2fe44337706cdfa187cf47fa8e5ab1e2181435101525a2498308
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106496 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 5
- `sha256`: 3c39a6a474623eeb4233b47f88f0636a5f6012713047011a7c7eeb18d39409fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=416 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build-v8d-module-current/tb_ooo_fetch_branch_target.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/O...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 408
- `line_count`: 5
- `sha256`: 1cf78fa702bc41b28faea946844b39517f3724eff6bc38a50fe4a105cb30e8e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=408 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-v8d-module-current/tb_ooo_fetch_flow_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooF...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 584
- `line_count`: 5
- `sha256`: 8ca6cf3e2fc8e8c85e26e8f955bcad242205ea3a78fc677a84f2c0e890ae1507
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=584 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build-v8d-module-current/tb_ooo_fetch_head_classify_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 636
- `line_count`: 5
- `sha256`: aba8dee79ac134470f5cce460e34f8d7787fd59bbe442fd86bdbedde07851a1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=636 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build-v8d-module-current/tb_ooo_fetch_head_pair_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 95c781e71958499482ca16cdebebaf2f9130ad390164bd315531645536116696
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build-v8d-module-current/tb_ooo_fetch_packet_cache.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooFetc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 6
- `sha256`: 7350eb7f3e96dd4a83a92502c4d37c430592370671c16790a89cd8ebc00fa1f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=556 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build-v8d-module-current/tb_ooo_fetch_packet_decode.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/Ooo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 735
- `line_count`: 10
- `sha256`: 444efbb036252da6064b3355f8c13cccba2bc5847e8a5b29d3d132e1446f4900
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=735 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-v8d-module-current/tb_ooo_fetch_packet_fifo.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 424
- `line_count`: 5
- `sha256`: a9d8df8093e345bf9e853cccef460a7a25f2ac33e5f24ea1968e8db853418f55
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=424 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-v8d-module-current/tb_ooo_fetch_packet_head_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/fron...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 425
- `line_count`: 5
- `sha256`: 69f8de6ab133d926130342767ec5d06e5db13694d10ec8354a7b73a1829c41e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=425 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-v8d-module-current/tb_ooo_fetch_packet_seed_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/fron...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106358
- `line_count`: 802
- `sha256`: f5942beeb457e069a63117743a26e2fbcd187c153314d094781173f4774de410
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106358 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 6f61291246b1789e7392f7535feed7839e07f5fd9cc31dee92ce08cc7d387a0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-v8d-module-current/tb_ooo_fetch_pc_outstanding_sequencer.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: 748da8d815c51e413070e3b8239d6eef5bd899dc80dceca50d056e3b87e1344a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build-v8d-module-current/tb_ooo_fetch_request_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 914
- `line_count`: 10
- `sha256`: 3ab4b40a8513bfaca09f887419d6f2ea267e409682ac67a486007a1332fe0a02
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=914 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o build-v8d-module-current/tb_ooo_fetch_static_classify.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/deco...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18484
- `line_count`: 85
- `sha256`: 64def8d5cdb1dcc8b5f43869fc10f66bd310ae5abd35ba78a45a3fe9b8352ca0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18484 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build-v8d-module-current/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlFlus...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 5
- `sha256`: 8799069f26651e3d51bd8a5644c57ba296dea69cef194eb07e2473e94e810ff5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=378 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-v8d-module-current/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v tes...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 395
- `line_count`: 5
- `sha256`: 50cfedcbbf0f12aef8f3bf4fb004edac90a02aff79c10db5e4806fde74c9a522
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=395 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build-v8d-module-current/tb_ooo_fp_classify_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpClassi...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: 7e54f71de6a72a8c2ab5c054cb1b9d6518dd8104ad7bd07b3a4064a6dea8f025
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build-v8d-module-current/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpCompareGa...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 0090442fd00aaab321998b1070ac22be089f7d93bea048e0e88de5576e5e37d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build-v8d-module-current/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpConvertGa...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3594
- `line_count`: 36
- `sha256`: 8fb55c63aca4d838748169c46e344521c36098829cc5f6b41c74f955a295851b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3594 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build-v8d-module-current/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueu...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: a551c489114eb416bc689e5db05eba5a2481ea5085959821d63aabf9ef2caade
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build-v8d-module-current/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpDivIter.v /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1570
- `line_count`: 14
- `sha256`: 357d1aca747c2303ba6f4b28d7ea53f80a8881bbc741b458f06f40a55f0c7e47
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1570 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build-v8d-module-current/tb_ooo_fp_legality_dispatch_path.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: c12b3d9906cdb6770b0132d602a8d2bc47bd1f54ab95869f30071392433b1a96
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build-v8d-module-current/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpDivIter.v...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 927
- `line_count`: 12
- `sha256`: 94ab7dc11915ab4bfe1786c5ba3f8fc617c144a11dd22d1708e99531e9164443
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=927 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build-v8d-module-current/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/regread_bypass/OooF...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 674
- `line_count`: 9
- `sha256`: 8dfe74dc3bb084246cc22c88bcb97d20e583870b61c370b38fc0425dd510a5c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=674 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build-v8d-module-current/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/regread_bypass/OooFpRegFile.v test...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 370
- `line_count`: 5
- `sha256`: 034060a08e932f7ccbcc77fa3898b5d8f8705f05aa2141da741f35b99b57e5c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=370 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build-v8d-module-current/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpSgnjGate.v tests/t...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: 8a3b5a1f245e0826c0b10e26e7278983bda3d67e33b2f676c7cdcb954ece80bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build-v8d-module-current/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooFreeList.v tests/tb_o...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 420
- `line_count`: 5
- `sha256`: 7ce2130db69e80b1993158a8c16260fe4c53e5726e8d1db4750584705f51a474
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=420 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build-v8d-module-current/tb_ooo_frontend_action_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/fronten...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 10
- `sha256`: 4ce151dca4fa234334f4889ac6921e5cdfcadbfdb8a1042660827954d17a3919
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=828 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build-v8d-module-current/tb_ooo_frontend_backend_dispatch_mux.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 740
- `line_count`: 7
- `sha256`: 7b743123533d3ff30e6f84e14b45c8c5373fc4ef174a12da16446b750813a0d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=740 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build-v8d-module-current/tb_ooo_frontend_dispatch_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/f...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: b9f8627927a49fefbb87231f6760cd4a94de84ac0231a8ac9588f08acc4403c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-v8d-module-current/tb_ooo_frontend_run_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFron...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 414
- `line_count`: 5
- `sha256`: bd62ba735f406db82ab4f83d8f89b71796159088253820952e1c64d2b15d00ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=414 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build-v8d-module-current/tb_ooo_frontend_uop_safety.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/O...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3771
- `line_count`: 34
- `sha256`: 2a09083209a4cd3b1050fa07faf0925c2128068654c8ca5f3afc77169cc9e21e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3771 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build-v8d-module-current/tb_ooo_ifu_lane1_fault_owner.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cont...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13717
- `line_count`: 105
- `sha256`: 18f59f121428bd7eae91466bb0846806035ec5159d68ad87e0b5c13ed68c6350
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"ERROR": 2, "PASS": 32}
- `summary`: log evidence; size=13717 bytes; lines=105; ERROR=2; PASS=32; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build-v8d-module-current/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7779
- `line_count`: 77
- `sha256`: 70bf0f0c1b242d80c3b0b228437d03e8421698a3040011b3eba7c192ff190132
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=7779 bytes; lines=77; PASS=12; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build-v8d-module-current/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssue...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 772
- `line_count`: 10
- `sha256`: 1a62f70dc2cdabebde3362b997dbb23f3ce49e96d4fa39280af192f5d8c21624
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=772 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o build-v8d-module-current/tb_ooo_lsu_axi_lane_adapter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71097
- `line_count`: 545
- `sha256`: 7553eae4bcf031b8c30180ad3e8d8019e98c3c3433527a2ddc41e512093a75a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=71097 bytes; lines=545; PASS=16; tail=: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1050
- `line_count`: 10
- `sha256`: b656066bad9f03927851cd00794ecf9a75fb72d1e5c44d17bc501c62af56b01c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1050 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o build-v8d-module-current/tb_ooo_mem_inflight_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMem...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 872
- `line_count`: 8
- `sha256`: d17f5b633996de2768c0aa387893efc3600e231e17add42340df69169698b482
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=872 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build-v8d-module-current/tb_ooo_memory_request_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/Ooo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 8
- `sha256`: 9934b674a55b277b2cac49e9b811d356e891b0dc59f7a4bd8b933c4112b61e1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=627 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o build-v8d-module-current/tb_ooo_mmu_epoch_owner.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMmuEpochOwne...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 370
- `line_count`: 5
- `sha256`: a009f7ba3277a576abe212637736d6403a66bfa5e112f2f781de8f5f3eff6605
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=370 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build-v8d-module-current/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooMulDivUnit.v tests/tb_o...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1096
- `line_count`: 12
- `sha256`: 10d9ab924ba9ec7db42aaf76cb8d3025f7250677c54136302566c887e61c2d60
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1096 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build-v8d-module-current/tb_ooo_pending_dispatch_arbiter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: 6189c3ca1c705c8a7619b6db74279d0ef09400a350a72f1af9eba03cd37ac862
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build-v8d-module-current/tb_ooo_pending_drain_resolve_gate.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 884
- `line_count`: 11
- `sha256`: c4020e3bcbe057d1540da23e9246dc237fe558f626e361647b7654ff69fdd340
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=884 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build-v8d-module-current/tb_ooo_pending_lane1_capture_gate.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 778
- `line_count`: 9
- `sha256`: 9d7a87776c68b56be65c5fc371022ce9782313423e35ae5c4f63ce4bcb726959
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=778 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build-v8d-module-current/tb_ooo_pending_system_sequencer.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: ecba1844e6c9657faf3686cf2352279730b31bdac2d453558f9af8cab4300f8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build-v8d-module-current/tb_ooo_pending_trap_exit_sequencer.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 5
- `sha256`: 08103c9f609cc98832cd6d0d24dbb109f10a47cbe029b8e546d1d3d191694cc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=384 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build-v8d-module-current/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/regread_bypass/OooPhysRegFil...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 6
- `sha256`: d8b1458244b61cfe0d7b67cd9afb9cf82ebaa5468c1d5e0ff045ac05d1abdac6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=506 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o build-v8d-module-current/tb_ooo_pma_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooPmaChecker.v /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15488
- `line_count`: 64
- `sha256`: dabbcb301f2ed675b0d2a6bff3ab45dc8ca5d500ce411760a758126e0c103fe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15488 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build-v8d-module-current/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlFlushSequencer.v...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: af00a754405254d81ef0f2c5f1a211701cf4a7fcaead4f5b5883245de2076b1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build-v8d-module-current/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooRasUpdateG...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 00ad9509f2d947b26fa51b1878d4c277d4a54f5dc021adbd94a5a04182996ba5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build-v8d-module-current/tb_ooo_redirect_arbiter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooRedirect...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 368
- `line_count`: 5
- `sha256`: 5c68253a6acc3c87ebd5b1fa9116848de61429c97d7fa0b3602cbd7d67e632a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=368 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build-v8d-module-current/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooRenameMap.v tests/...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 966
- `line_count`: 10
- `sha256`: 0f0f60c4752d70ae1866e176819bc4372cc5e7249538a76ee0a5c01e0a8d68c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=966 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build-v8d-module-current/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCsrTrapRequestMux.v /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 760
- `line_count`: 9
- `sha256`: 69bf4b87730671e676070a81fb4179da458bc85233f06e1dfcac8faa416dd920
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=760 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build-v8d-module-current/tb_ooo_stop_pending_sequencer.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/c...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2410
- `line_count`: 23
- `sha256`: 5e4d4388146852dfd6a665140af210fb69af788e5eb89be78a257d7155bd91c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=2410 bytes; lines=23; PASS=16; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build-v8d-module-current/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v tests/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 207954
- `line_count`: 1512
- `sha256`: 83964a075135d709b0f4013f5b0e9f011b6decc6a82958684c7fdcf59317d081
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=207954 bytes; lines=1512; PASS=2; tail=pChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 5acf8be465ea67cdf6c5d1dea2e919e72a2ed27a14d5ff209b338ddfcef0902a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build-v8d-module-current/tb_ooo_trap_exit_event_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/Oo...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: a7ca226438a3ffabb014b89d8c5b1538db3bc611df0199463f8782c52b81e52a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build-v8d-module-current/tb_ooo_trap_exit_output_sequencer.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 6
- `sha256`: fc97b1d8121ba83c5bb00cffb1712770897b5331ba9c8cfb5a56e27683a8f4ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=526 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o build-v8d-module-current/tb_ooo_typed_memory_classifier.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: 2e11ba8b0fa6d8840c079f95474e080020e9ea8e6ac3b2d115a57c085d9320fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build-v8d-module-current/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/pipeline/PipeStageReg.v tests/tb_pipe...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17488
- `line_count`: 134
- `sha256`: 3b2fa5fcf8df96875410bc3adcc4a932274a58c19945a37e40ced89871c99116
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17488 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build-v8d-module-current/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v tests/tb_pmp_checker.sv /h...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 299
- `line_count`: 5
- `sha256`: 36d5b8297fdaf5fd1d2696df8ebdfb658664d2fe76c376118b71afbccd50c84f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=299 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build-v8d-module-current/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/tb_uart.sv [PASS] tb_uart common/tb_common.svh:32:...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 297
- `line_count`: 5
- `sha256`: 5a839b723241cb8b8ed0097afd0d6d26714dc0c33e10244a0da568126d15f010
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=297 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build-v8d-module-current/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests/tb_wbu.sv [PASS] tb_wbu common/tb_common.svh:32:...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/production-sources.sha256

- `kind`: sha256
- `size_bytes`: 15134
- `line_count`: 140
- `sha256`: f253637d2df8488ff801cd46595009de45c1084cb5a36252722963366859d822
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=15134 bytes; lines=140; markers=<none>; tail=c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24 npc/rv64/vsrc/bus/AxiClint.v aea1c8d1637d436efe9b7af5b875a72915d8e0887d39d612585f5fd9f768041e npc/rv64/vsrc/bus/AxiDefaultSlave.v 3141814d0a81d52556d193ef8c23facb7926a88dbd804cb9f312538b5897fa...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/summary.txt

- `kind`: txt
- `size_bytes`: 3455
- `line_count`: 113
- `sha256`: b4f3929832f7e277e474c55010146f679f335e5a4f83ceb6060aa2c6b17642e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"PASS": 208}
- `summary`: txt evidence; size=3455 bytes; lines=113; PASS=208; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu -...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/module-current/testbench-sources.sha256

- `kind`: sha256
- `size_bytes`: 13171
- `line_count`: 112
- `sha256`: 8fc72ba4197a9d1143cb3e7aa436707edbe50913cda3196486dc286f9c4ed947
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=13171 bytes; lines=112; markers=<none>; tail=63e012507ddce0f885443d840a3cfe53335d25c7cc3d5e42ffaa02c3915cd26e npc/rv64/testbench/Makefile 4f304dc71e654a523bdaa5f511afc2b7a28769f04c9bd0043fd5164cbb6f6d01 npc/rv64/testbench/common/rv32_encode.svh b63f96dbbcd30ecd96b2b3d21f9b56a0f18879a17800d20c0ae6a2b40...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/pre-fix-r2/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11323
- `line_count`: 73
- `sha256`: 2d200ae370daf633a22362dd83eb4e871df07e82add8e9e58cd1747efc82a2a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: log evidence; size=11323 bytes; lines=73; FAIL=14; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DINT_EX_KILL_CUT_FOCUSED -s tb_ooo_int_backend -o build-v8d-int-ex-kill-pre-r2/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/exec...

### .github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/pre-fix/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10973
- `line_count`: 65
- `sha256`: 81da726cf0eb530885803fc1eb99c408d62c81e22f789514a476c212de5213fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T03:40:04+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=10973 bytes; lines=65; FAIL=2; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DINT_EX_KILL_CUT_FOCUSED -s tb_ooo_int_backend -o build-v8d-int-ex-kill-pre/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute...
