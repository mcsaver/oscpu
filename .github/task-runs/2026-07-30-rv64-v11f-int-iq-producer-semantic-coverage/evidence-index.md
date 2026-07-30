# Evidence Index

## 基本信息

- `task_id`: 2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage
- `task_slug`: 
- `profile`: 
- `asset_count`: 873
- `total_size_bytes`: 185675273

## 证据资产

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/arch-stable-unittest.log

- `kind`: log
- `size_bytes`: 10964
- `line_count`: 84
- `sha256`: 775d6ff952a5d9857ee891c91fed8eeab3d76474e748154859e3451ec95c266f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 8, "PASS": 4}
- `summary`: log evidence; size=10964 bytes; lines=84; FAIL=8; PASS=4; tail=test_cli_require_stable_returns_two_for_current_gap (npc.rv64.eval.ppa.tests.test_arch_stable_freeze.CurrentWorkspaceTests.test_cli_require_stable_returns_two_for_current_gap) ... ok test_control_event_architecture_json_rejects_boundary_reference (npc.rv64....

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/commit-gate.log

- `kind`: log
- `size_bytes`: 302
- `line_count`: 4
- `sha256`: cfe838c02e265a7c1820e0afd25af9edc4e3f777e323a0616665a37fdaccc4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=302 bytes; lines=4; markers=<none>; tail=[V11F-COMMIT-GATE] branch=ai head=af027d1bce085bace474b748dcd89113145f8772 tracked_modified=253 untracked_files=1639 staged_entries=1 [V11F-COMMIT-GATE] preexisting_staged_paths: .github/e2e/profiles/rv64-systemd-contract.tsv [V11F-COMMIT-GATE] GAP mixed-or...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/final-identity.log

- `kind`: log
- `size_bytes`: 1974
- `line_count`: 22
- `sha256`: dc5fcf6c1151827491a031b43f82a63e63533519618af4fb7fe8177d8654d8be
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1974 bytes; lines=22; PASS=6; tail=.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh: OK npc/rv64/vsrc/scheduling/OooIntIssueQueue.v: OK npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v: OK npc/rv64/vsrc/include/define.v: OK npc/rv64/vsrc/fi...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/full-worktree-strict-guard.log

- `kind`: log
- `size_bytes`: 17524
- `line_count`: 6
- `sha256`: b04fbbcf01a5b94afb5167424cef003c6cf3d232414b0339d1c842256cf5c518
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: log evidence; size=17524 bytes; lines=6; FAIL=2; PASS=6; tail=[agent-e2e-guard] mode=strict changed_paths=1891 required_profiles=4 [agent-e2e-guard] PASS profile=agent-system evidence=.github/task-runs/2026-07-29-schema-aware-rtl-evidence-publication-receipt-closure-final reason=.github/agentic-hardware-blueprint.md;...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/evidence-tool-unit.log

- `kind`: log
- `size_bytes`: 1564
- `line_count`: 13
- `sha256`: 8a688c1b7e1cd0bce25fc5df437d59f8d0a64aa837f7b5d63922461e24ad0df2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=1564 bytes; lines=13; markers=<none>; tail=test_assert_release_width_matrix_is_exact (npc.rv64.eval.ppa.tests.test_int_iq_producer_semantic_evidence.IntIqProducerEvidenceTests.test_assert_release_width_matrix_is_exact) ... ok test_carrier_lifetime_and_knownness_mutations_are_present (npc.rv64.eval.p...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/iverilog.version

- `kind`: version
- `size_bytes`: 3294
- `line_count`: 73
- `sha256`: f9199cc8658f4afcec3edeb93f29f23bb2aebf66d3eeb217cdc728aaa692f946
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=3294 bytes; lines=73; markers=<none>; tail=Icarus Verilog version 12.0 (stable) () Copyright (c) 2000-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software F...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356170
- `line_count`: 34164
- `sha256`: 75766ff3a7d01772987f195546ecbd95f3a15bb54f9995f25852eafd41c071bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356170 bytes; lines=34164; markers=<none>; tail=ts, S_0x5a14bf968760; %join; %free S_0x5a14bf968760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a14bfb15460_0, v0x5a14bfb16090_0, &PV<v0x5a14bfb14eb0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: e5a88e9498620ba5121bd40ea13fb9bdc7ebfe462e34574be24ad8667e1a7d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4712
- `line_count`: 62
- `sha256`: 587ddd594ab9b7d4b91755a675e55bc809da985a3c07b298ee508b3abe2decff
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 110, "PASS": 10}
- `summary`: log evidence; size=4712 bytes; lines=62; FAIL=110; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=14 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356886
- `line_count`: 34164
- `sha256`: 0b2591851c14be70bdcdb5bf34a340f889b6e0a77f82173654c9127d6c1a101d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356886 bytes; lines=34164; markers=<none>; tail=ts, S_0x59c81757bfd0; %join; %free S_0x59c81757bfd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59c817729070_0, v0x59c817729ca0_0, &PV<v0x59c817728ac0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: 12c53603176da1dee34cc517469d7d80167f3ceaad07721dbc9e0d08b7aa142b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 8615
- `line_count`: 87
- `sha256`: 0faed97d6cbbad6906df58af68dbc4b2265cdcddfb9f6a26bcb827cae895b5b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 160, "PASS": 10}
- `summary`: log evidence; size=8615 bytes; lines=87; FAIL=160; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=34 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000018 expec...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 340
- `line_count`: 7
- `sha256`: 0f7071c9c8a33ba18acedff4fd14055960ca369b5bf266b9d6ac67ad7f895051
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=340 bytes; lines=7; markers=<none>; tail={ "case": "compaction-generation-zero", "mutant_sha256": "f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 113
- `line_count`: 1
- `sha256`: 3b0e86b7ef786dad1a19ade992cc17e12ae4988f887f6d398f9d5bcb122a224c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=113 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-generation-zero sha256=f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49848
- `line_count`: 1032
- `sha256`: af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49848 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355766
- `line_count`: 34158
- `sha256`: ed28c52339e8ced460d63b389f574ddb54f571664485633eda4203aa13d7f6a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355766 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x5b5d581ac250; %join; %free S_0x5b5d581ac250; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b5d58358bd0_0, v0x5b5d58359800_0, &PV<v0x5b5d58358620_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: f08a16e84b5c5768aced8a199c31160b843b7183d9c8b4eca703543de0d88c22
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6834
- `line_count`: 93
- `sha256`: 32c794e9ce4a630640a09eb56717422aa8d659b9f4ca28a1c407db39f916f2d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=6834 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold raw PID unk...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356484
- `line_count`: 34158
- `sha256`: d32929ba7c9c235c32f67d777046f7db44a5d39b6ade087c9c4b8837f7584c80
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356484 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x5b11afaacac0; %join; %free S_0x5b11afaacac0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b11afc59870_0, v0x5b11afc5a4a0_0, &PV<v0x5b11afc592c0_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: 81cfd34e6ae270b854f7740970a491d18759a801064143b2025e4a7f4a0645a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 8850
- `line_count`: 93
- `sha256`: ae229f412ee869269f6abe56d10a763ee093d7615b31f60b4238a50869d633e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=8850 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000000 expected=0000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 330
- `line_count`: 7
- `sha256`: 6e19b1d2f44baedfcc2a9945d54707cd7b9397703b74fcacaeba91d807659f09
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=330 bytes; lines=7; markers=<none>; tail={ "case": "compaction-pid-x", "mutant_sha256": "af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ce...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 103
- `line_count`: 1
- `sha256`: d559f13b26fe5ffc23194b38c6e7a84d193552e81628e083a470da2439e60eeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-pid-x sha256=af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356093
- `line_count`: 34161
- `sha256`: 50ad6c013f48c86f470f7bb1d1986e0bff04437055e84abf4408475fc81f7ca0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356093 bytes; lines=34161; markers=<none>; tail=_0x5f1e3ea2b1f0; %join; %free S_0x5f1e3ea2b1f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5f1e3ebd7bc0_0, v0x5f1e3ebd87f0_0, &PV<v0x5f1e3ebd7610_0, 0, 32>, v0x5f1...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: b9704d1c84fe40e04e1e06973821082d21dbd9ff31975433cc750fde06b51a74
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 1566
- `line_count`: 21
- `sha256`: b382c900af6a56b82fad16f1c6ce3983b06810a109bd57823240c3f1f000b0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1566 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=12 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=12 expected=13 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356809
- `line_count`: 34161
- `sha256`: e3bec1fe51191ccd12c6d21047908df3e45203ca6540896e65d0a406df063729
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356809 bytes; lines=34161; markers=<none>; tail=_0x5b73b2bd7a60; %join; %free S_0x5b73b2bd7a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b73b2d84930_0, v0x5b73b2d85560_0, &PV<v0x5b73b2d84380_0, 0, 32>, v0x5b7...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: d57687a26094e47209db9a29f86e8382b31efe2f81dfcc0b7d82ab6b843ae066
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 1902
- `line_count`: 21
- `sha256`: 9e1d7b15d58addc12d62ff3948952732cefb87d4b615f8675f6e78ac7be0f919
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1902 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=32 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=32 expected=53 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/mutator.json

- `kind`: json
- `size_bytes`: 345
- `line_count`: 7
- `sha256`: 74aaaf86435ce2cd4779b5d72b0b31edda382f225713ebfcca020923400892a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=345 bytes; lines=7; markers=<none>; tail={ "case": "compaction-uses-write-index-pid", "mutant_sha256": "94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/compaction-uses-write-index-pid/mutator.log

- `kind`: log
- `size_bytes`: 118
- `line_count`: 1
- `sha256`: 6032235f8ec24ef188339bf8b6a83e927a1e51ca6a22347c560ee2b09b6b8b17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=118 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-uses-write-index-pid sha256=94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356169
- `line_count`: 34164
- `sha256`: 09425c1dce07d37659e8ebc6a654e8014eeea4c52b57687df81f2a84c5f73523
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356169 bytes; lines=34164; markers=<none>; tail=uts, S_0x588dee3da760; %join; %free S_0x588dee3da760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x588dee587440_0, v0x588dee588070_0, &PV<v0x588dee586e90_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: f7fa756be05c3c239884aa970c83ba255a2d344f216e2ee4c51ed0737aa92742
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4387
- `line_count`: 57
- `sha256`: c1d4c54f2bd981183242735721bbe60553f6a019f0a6014a792f1bea25bf6f2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 100, "PASS": 10}
- `summary`: log evidence; size=4387 bytes; lines=57; FAIL=100; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100008 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356885
- `line_count`: 34164
- `sha256`: 6086ee9c48aba100dde78bb828dca82f8b5b0d3844bb92d190f5db4e018dde61
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356885 bytes; lines=34164; markers=<none>; tail=uts, S_0x5e62a57effd0; %join; %free S_0x5e62a57effd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5e62a599d030_0, v0x5e62a599dc60_0, &PV<v0x5e62a599ca80_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 5c7352497e44d00cbc5163818b62a44e77215b1015741d918bdbe3869435b84f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 9291
- `line_count`: 83
- `sha256`: 64dfd48c4d980e417ba7d4adc52c339e4d94502deaaf2db3c7629289fb71756d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 152, "PASS": 10}
- `summary`: log evidence; size=9291 bytes; lines=83; FAIL=152; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000008 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 8612d1610ab2e057f8fe0c8f2bda02934ffe76dad53b970848f2af30081bca38
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-generation-zero", "mutant_sha256": "f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: 8aa15918bcd50027498e550eea1675884808e8f21075aa4f3d19b7f988a941a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-generation-zero sha256=f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: c031bc65dfd2728dc8a636b77128752649236c01000397fe62707d5091af9315
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x566fc811c320; %join; %free S_0x566fc811c320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x566fc82c8db0_0, v0x566fc82c99e0_0, &PV<v0x566fc82c8800_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 7f8cc74e2cd0aea460a3609c22a61596f2c9bc946ee24336128baf9cd688238e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6712
- `line_count`: 90
- `sha256`: d1dc63f100296b77ab4b4d27f0b141825da36721c5e528fb4db01379f873d952
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=6712 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=xx expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: 0e523624da220a6067802efedc79358f9e65f6e618afb97a702390133ca618a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x5b1ccf068b90; %join; %free S_0x5b1ccf068b90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b1ccf215a90_0, v0x5b1ccf2166c0_0, &PV<v0x5b1ccf2154e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 5dbe46417a20bd93a77d1592ef5aaa3827b6ec3817b95a4ad907d6d97103b9fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9624
- `line_count`: 90
- `sha256`: 768292123b90aa255de63064d113db9aa6a0f62c170014d0e7806b0cdac3b132
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=9624 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: 68b0215960fc6ec71831f71254645934d3ce243687e2e9cdcc4271efbd106df6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-pid-x", "mutant_sha256": "8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch0-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 0816f96adc8c90027ba9ba8cc5802d1681f96538c73a0be94a0f3e4389542c83
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-pid-x sha256=8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: fa1506ad17ef2965dab6acc4d639bdaca46171a1026d73cc03c58c00aa99a56d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x5bf56a70e320; %join; %free S_0x5bf56a70e320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5bf56a8bad90_0, v0x5bf56a8bb9c0_0, &PV<v0x5bf56a8ba7e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: fde51b4d90bf708542a376a45cfe9341da6094a99bca928de6581d99b97ff1c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6648
- `line_count`: 89
- `sha256`: c94e11312bc94d676bebb73981fb9921e3d6f2425ee533bfea50d2469c8f26ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=6648 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=xx expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: a8027c03d48ab9f3c29f2214c07181bf7e77db38c5b2082bd5c8926a004d65a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x5af68b93bb90; %join; %free S_0x5af68b93bb90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5af68bae8a20_0, v0x5af68bae9650_0, &PV<v0x5af68bae8470_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 053c216dd4bf56a8cf0b38a1305baad4ae6d417ee506d0ff78c5f9ae2fd9c0f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9448
- `line_count`: 89
- `sha256`: fcd5bad1349db3949cd559b4db3d67221f97a839a1c565d81091c741d5d78c33
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=9448 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: b557037406e19a587d848ad87e6861f9437fa402124d314ebdf6f187078edfcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-pid-x", "mutant_sha256": "a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 9a8392f2ce27f9156a11cdd9a44c12f8e4ceae0c495f5212a553f308408187e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-pid-x sha256=a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356067
- `line_count`: 34161
- `sha256`: ab96e2b75569faba9bd049c66fbc82117c15af06c851921a5e5e2bf1379d01b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356067 bytes; lines=34161; markers=<none>; tail=puts, S_0x5eb40f45d1f0; %join; %free S_0x5eb40f45d1f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5eb40f609b50_0, v0x5eb40f60a780_0, &PV<v0x5eb40f6095a0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: 03a8c7f56511957f431ed8ea393f27991bb142c214d23bf68b50a5e97863f4f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 6536
- `line_count`: 85
- `sha256`: a15fa76fa942536fac5603f140ac9207cd18e1f3def72e20cea9661f73ba92e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=6536 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356783
- `line_count`: 34161
- `sha256`: c010801c1e168935d63f8376c8931326b2bafbd451bbcf5a51c6ed9e524e0fb5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356783 bytes; lines=34161; markers=<none>; tail=puts, S_0x57feb675ca60; %join; %free S_0x57feb675ca60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x57feb69098b0_0, v0x57feb690a4e0_0, &PV<v0x57feb6909300_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: 209692f878cee773507980248110bb94f78d17a11ff2210c62bcd4d6b143d39e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 9336
- `line_count`: 85
- `sha256`: 2434da3fc61fa8297b25fd979b4825207ed9add1044064e4e2f6c97488e6d794
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=9336 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=34 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/mutator.json

- `kind`: json
- `size_bytes`: 338
- `line_count`: 7
- `sha256`: 1f424896ea875728175752d1afc03a6fa0d7f3cfb3a627995e5e19c48c25aa28
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=338 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-uses-lane0-pid", "mutant_sha256": "0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/dispatch1-uses-lane0-pid/mutator.log

- `kind`: log
- `size_bytes`: 111
- `line_count`: 1
- `sha256`: bb534235ae9256560ed541ebd89b225f3aebbdc62f03fe85f73e8d9dc833637f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=111 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-uses-lane0-pid sha256=0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49840
- `line_count`: 1032
- `sha256`: f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49840 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: 93b553af173ec33180ff4f544a60ac652592f3fa84bfde1fd697390b8065dfe2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x55efd1c5a110; %join; %free S_0x55efd1c5a110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x55efd1e06a60_0, v0x55efd1e07690_0, &PV<v0x55efd1e064b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: c2d497dcb4a8ee3bde29078556a5532fee384141ee38f09c3635a97c5cccf3e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 1708
- `line_count`: 24
- `sha256`: 2796ceb605601b6ae45732ba5b7fdce648508638d51c7215dfb9c083a6a812d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=1708 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: 73247ceb2e19efe669b8cf08d9dc17c3ab164405b48448b3413b776cc0efb816
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x5f09b0d789a0; %join; %free S_0x5f09b0d789a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5f09b0f25780_0, v0x5f09b0f263b0_0, &PV<v0x5f09b0f251d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 611735909d8906713179fe62835903c3afccd6394df0b24a6b3c94a90ae7601b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 2044
- `line_count`: 24
- `sha256`: ab04c772767add3b9fab8f653fc1812d27370a3aea370aa35359028bff1277cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=2044 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: c1485e96a39ddc53cf40e40bf7d9bd17138a6c8a3bd6b7027d5996995a501f1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "flush-ignored", "mutant_sha256": "f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/flush-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: c9aec4167a6723841275cfb8f3ec6305f203e71a53d094962a4522a4b9680c17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=flush-ignored sha256=f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355756
- `line_count`: 34149
- `sha256`: 86b5663738aa42d30486ce3c30fcc4937caa88305d423d8f8599056e239cf196
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355756 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5bf681a212b0; %join; %free S_0x5bf681a212b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5bf681bcda30_0, v0x5bf681bce660_0, &PV<v0x5bf681bcd480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 70d749e50266f30f1b41db3add7efe91b1b265bff3b59623f53789027a3b1d67
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 2631
- `line_count`: 35
- `sha256`: b30d02788dc8601c99f1522e8169c5a8b9b71068a1928d4ec680649a70c59a3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=2631 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356472
- `line_count`: 34149
- `sha256`: 860bd38791c82f045799d5bccf24b2ce7f36cc95c95fb48fa16031f9ec29751e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356472 bytes; lines=34149; markers=<none>; tail=nputs, S_0x63026a37eb20; %join; %free S_0x63026a37eb20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x63026a52b6f0_0, v0x63026a52c320_0, &PV<v0x63026a52b140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 50bf851bad7c5f6c31468be5ce26d28678eb08e13817d6625fdbba69a52ad423
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 3079
- `line_count`: 35
- `sha256`: 3009bd3dea6af60c3c3f2f2dd2225af4f79fffd10f83fb8dd064a089dc42b514
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=3079 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 6f7b26ac779c1bf9c44addeacf5453181d64888e729b6747d5958f0a03df602e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-fire-not-removed", "mutant_sha256": "c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: d730e852f54888b5cbaa754c6f8a2eddaf5787deee1f381da83846e4033678e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-fire-not-removed sha256=c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: 69326cfd97acc861e0726554e0e7e86ead279f16f3fb8ccf086f9d5683b0880f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x5722af1a0760; %join; %free S_0x5722af1a0760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5722af34dd90_0, v0x5722af34e9c0_0, &PV<v0x5722af34d7e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: b7706ab884e7b07d42ec2e1e8bc3910e42a8f4a39f2f0eb42a33c81caa421dd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 806
- `line_count`: 12
- `sha256`: ecf09df0b8b679d485050007252c3137a898f4a8a6a7ad91a8c34de210b4bdc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=806 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID got=01 expected=11 [V11F-INT-IQ-ORACLE][FAIL] post-compaction issue0 is...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: 6989adb8465dd906f3a31d9157397a38653aa307eb1ea6599e5a513462ac0dd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x5b9dc7f39fd0; %join; %free S_0x5b9dc7f39fd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b9dc80e7910_0, v0x5b9dc80e8540_0, &PV<v0x5b9dc80e7360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 153fd3ac6efe79b5bd9eaf298eab0fa3bdbf12c42303bdc464a1693a110640df
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 13
- `sha256`: 18ee3ccb7576d967b96fdd7f0234f7e2e319125f4665e015f736f86136c254f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=877 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 PID got=06 expected=46 [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: ec65ccacfa43aba5bd53516fb28f55b703196f9793bc7a03dbc49aed4a3c38f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue0-generation-zero", "mutant_sha256": "90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 7629fd03fa15cfd2ab955a4bde8eea5c3d6cd7edf1554b6d6bb6a182365f06a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-generation-zero sha256=90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49847
- `line_count`: 1032
- `sha256`: eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49847 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356086
- `line_count`: 34161
- `sha256`: a0729d73916f29adaf43449f3981629d5a4172f41be6ede56775ed94706d0a23
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356086 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5b2c3bd2f2a0; %join; %free S_0x5b2c3bd2f2a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b2c3bedbea0_0, v0x5b2c3bedcad0_0, &PV<v0x5b2c3bedb8f0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: b6c344aebd1a36ffe758e9eab465d8a5e493bd0e465026332d1dfa0de318e4bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: 7bae1d941fce32967a137c5f925e870c1468d4537a4e3ebcc43229c8dd01292a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356802
- `line_count`: 34161
- `sha256`: 4303605dd123e9fb05accd59bbcb7510c26d8fadfded9a7d59bb43f75bb76567
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356802 bytes; lines=34161; markers=<none>; tail=nputs, S_0x627a9315fb10; %join; %free S_0x627a9315fb10; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x627a9330cb70_0, v0x627a9330d7a0_0, &PV<v0x627a9330c5c0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 0472db7793e27fc612863a7a0c80a09c9816f3cceee17f067bbfe759be8b69fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: db1568600ba65ed2d49101c916a7b5cc8d131b10e4dcd8eb15e3f5627d8a4b96
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 8eccc824b19a2f435139b8f44fd680774af3be945da0b71c6b0d4044656a0d4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-raw-index-entry0", "mutant_sha256": "eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue0-raw-index-entry0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 60ab23ada23fe2b9fa3c58f2c9cc9e7f0c9dc2d81c4b6584b71f38b90954ecce
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-raw-index-entry0 sha256=eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: 548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355759
- `line_count`: 34149
- `sha256`: dc405f75d5523fcd3c53efaba335d31cf29596fe8e5c0b004b133336f1abada8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355759 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5d7dce2cd2b0; %join; %free S_0x5d7dce2cd2b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d7dce479a30_0, v0x5d7dce47a660_0, &PV<v0x5d7dce479480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 2ec4e99d23846e28c652b21ce547e1093350d8690834b8787a9aa6c2bc0aebde
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 893
- `line_count`: 13
- `sha256`: 68f5e5ca7c1cc7df51d282eaa341a29974ac68bb657c0706fe4ad44e9a43b7c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=893 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=13 expected=04 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356475
- `line_count`: 34149
- `sha256`: 82f93939b9567f024caa3e923f2cb679cf35c95f9381aacc97c9cf99afb43275
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356475 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5713be9beb20; %join; %free S_0x5713be9beb20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5713beb6b6f0_0, v0x5713beb6c320_0, &PV<v0x5713beb6b140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: f1d02a3c6b7d8cecb370c9d53abdf59f200112ff4b020e996c66781fdbe7d0a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 1005
- `line_count`: 13
- `sha256`: 0f27dbd42e1771bb55f5f23deb8d724d40af42fa994dc9812ea2661f68648ace
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1005 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=53 expected=84 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 4a17a89fbba54d442f777dcd25af8cb877b42ab3ef8c361ea454ab1cfd865aa7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-fire-not-removed", "mutant_sha256": "548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 69abd44948e3a9375210907acfbf7d48f0365215a5f084bc62b5ac0bf2bf6335
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-fire-not-removed sha256=548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: b5d5c8b48cdd17f58f31a8ba2098d340ed87622932d96ad9f040681cbd062ee0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x59a8d9ef1760; %join; %free S_0x59a8d9ef1760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59a8da09ed90_0, v0x59a8da09f9c0_0, &PV<v0x59a8da09e7e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: bdaa0bcd3b8462a4bd2a44ef2ee421b74c60ac9a149beada3c9eff9619529728
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 753
- `line_count`: 11
- `sha256`: dfa5799b5c34c1b9dd5e27715de1488280d275a2cdfb42e65a6b5d3da3fa1775
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=753 bytes; lines=11; FAIL=8; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=14 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=12 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: e053ed4f70d168581a5551719981cab34c9f64c16ea5506dba61c9a8ddc1e14e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x5d4fc52cffd0; %join; %free S_0x5d4fc52cffd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d4fc547d910_0, v0x5d4fc547e540_0, &PV<v0x5d4fc547d360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 456110938c256d2c5803c232d07ef0511a315e3f65d5d3bb64e072a570e96aa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 816
- `line_count`: 12
- `sha256`: d5dc84d67de5acb0854ae3b0d5dc0002428285317f8ea28a95b0836b91b7987f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=816 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=34 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=32 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: f40c4f4f5d87315d92465080edece62fedc6a5732cca33571022fb7506de8f99
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue1-generation-zero", "mutant_sha256": "7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 76d32b3a68d1b90a559d01beab58c2dc0b71adde9486b0b040a1107b9efb5f30
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-generation-zero sha256=7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356085
- `line_count`: 34161
- `sha256`: 9fbae83a64b7cef771d4439afdc6faf8814374ab6355ae4acf3a9af080f93bcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356085 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5a32189e51f0; %join; %free S_0x5a32189e51f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a3218b91bf0_0, v0x5a3218b92820_0, &PV<v0x5a3218b91640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 950b851d14938ab7741e8c1ac4391d496de895b0a0b0fd8a6d1d53de5a17bb9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g1/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 34b5a22b5fb64bb05a3897ab9310bada5a2c9382ec53b2ae9788c23056fb3f06
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356801
- `line_count`: 34161
- `sha256`: afb8389c694a1e7097e38a5d695ea0e643bf6e592d658dc5b4d3f5ecbd8066f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356801 bytes; lines=34161; markers=<none>; tail=nputs, S_0x571333341a60; %join; %free S_0x571333341a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5713334ee920_0, v0x5713334ef550_0, &PV<v0x5713334ee370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 57f0bc83f808908ea392b73431795651c0d36f73066c3007689043dbdab7fc65
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g4/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 1ee68483112138b5ccdd5a48cd02662d4aaae79f3e04a66ccff20f551612cd90
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: c4af6c9e345974efa986ad6974b591f2a354ce0c157aeee247a64fa767244171
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-raw-index-issue0", "mutant_sha256": "75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: bd4a8404a3b21f1c7ece80e7618267f2aae5e35f1450cc5fb8d0047b81946f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-raw-index-issue0 sha256=75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49853
- `line_count`: 1032
- `sha256`: 36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49853 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356147
- `line_count`: 34165
- `sha256`: 59e17859069ee99d3ef6f66e743895a83222ee42e22b2f9aeb9dbae64efe15d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356147 bytes; lines=34165; markers=<none>; tail=nputs, S_0x5658d54501f0; %join; %free S_0x5658d54501f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5658d55fcbf0_0, v0x5658d55fd820_0, &PV<v0x5658d55fc640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 1ec726bf8df9c53af74391f94a255b9722fb3e97dd84ab7e0881300e87e1d334
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g1/sim.log

- `kind`: log
- `size_bytes`: 975
- `line_count`: 14
- `sha256`: 27f7ab2148a8f8e4d9cedc3f2851e8da2ee3b7b70fc7ea4f8b46cc7bcbdc6e76
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=975 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356863
- `line_count`: 34165
- `sha256`: 92cd6312b7c1f1a50b823f1bfd88118cb61784d686b3f501e8e8c9ee5cd3b576
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356863 bytes; lines=34165; markers=<none>; tail=nputs, S_0x570cb0e29a60; %join; %free S_0x570cb0e29a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x570cb0fd6920_0, v0x570cb0fd7550_0, &PV<v0x570cb0fd6370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: b8affa4d2956fdd9914d6cf17361487a5b95f0aec28b611962e122d3a6cdff01
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g4/sim.log

- `kind`: log
- `size_bytes`: 1199
- `line_count`: 14
- `sha256`: ec97ae2f6a9163b3b7a0b732c47b16f5b0f86541cfc3010ac519957cbb0a2920
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=1199 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 893a577bb69cf3c2e4246b7253126da141da14b4e0a525c7ce1b708b215ae967
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "kill-boundary-inclusive", "mutant_sha256": "36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/kill-boundary-inclusive/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: fbe99edf97f38d53d0a548df699c4612e445148beed2287cda1e7bfe71221078
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=kill-boundary-inclusive sha256=36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49868
- `line_count`: 1032
- `sha256`: 2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49868 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356102
- `line_count`: 34162
- `sha256`: f4bf393f91cae36f3745f13b892c158e0dc1f2f04453c11fd7a379d79b49ecde
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356102 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x56d540340400; %join; %free S_0x56d540340400; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56d5404ecee0_0, v0x56d5404edb10_0, &PV<v0x56d5404ec930_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g1/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: 268933a7dd22ff5e67a7bceea51038f2a97daab91b0fe6f09c108964b61489d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g1/sim.log

- `kind`: log
- `size_bytes`: 2472
- `line_count`: 31
- `sha256`: 25ac5432071a2f02e8a4bb428ba75022a1fe581a8f243012f2bd021dd8e99821
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 48, "PASS": 10}
- `summary`: log evidence; size=2472 bytes; lines=31; FAIL=48; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE]...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356818
- `line_count`: 34162
- `sha256`: 70078764a3d8e338caaf2c5bbf0cf07fdc098c4bc8f42b209494de5d88921037
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356818 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x5d40bb6fec70; %join; %free S_0x5d40bb6fec70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d40bb8abbe0_0, v0x5d40bb8ac810_0, &PV<v0x5d40bb8ab630_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g4/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: 4ac5d3bcd84066180665c4854eaaa06f3fd0f5312f6de0880e187a75902e647f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g4/sim.log

- `kind`: log
- `size_bytes`: 5644
- `line_count`: 34
- `sha256`: 613744e04db250a7370516678e1ff256a4928409ee75b9b87825f408c8439035
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 54, "PASS": 10}
- `summary`: log evidence; size=5644 bytes; lines=34; FAIL=54; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000000018 expected=0000000000000000000000000000000000000000000000000010000000080000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/mutator.json

- `kind`: json
- `size_bytes`: 332
- `line_count`: 7
- `sha256`: 595050c75bd696f3d1cb8221c9cf98c6913daf28b1be779ea2d8c4e4d4c553d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=332 bytes; lines=7; markers=<none>; tail={ "case": "mask-raw-rob-index", "mutant_sha256": "2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/mask-raw-rob-index/mutator.log

- `kind`: log
- `size_bytes`: 105
- `line_count`: 1
- `sha256`: f7b11cd8e1d5a618361ddf5b805ccc60696a036dcb10503889534fb0ac88d9af
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=105 bytes; lines=1; PASS=2; tail=PASS mutation=mask-raw-rob-index sha256=2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49941
- `line_count`: 1034
- `sha256`: a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49941 bytes; lines=1034; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356586
- `line_count`: 34184
- `sha256`: 17bbf9044b656dedb19e0291aef2f3d2c72b648708750d512c203dc797d40843
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356586 bytes; lines=34184; markers=<none>; tail=uts, S_0x5cff6dde7670; %join; %free S_0x5cff6dde7670; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5cff6df94300_0, v0x5cff6df94f30_0, &PV<v0x5cff6df93d50_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 6a46fbb0f4b9a551473ed08c59136c6f90576523b7b88618d5723c91d3c2056c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 9
- `sha256`: 708e3361c5efd9da0f9ea2a805d4366835b0b31df2ea2efc8f795973cea2aa45
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=615 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000 expected=00400080 [V11F-INT-IQ-PAIR-DEATH...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357302
- `line_count`: 34184
- `sha256`: 56cffaadbc6d345ef8fd0482db76d14b4d0b81c9ed95a2cdba196bea426b0276
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357302 bytes; lines=34184; markers=<none>; tail=uts, S_0x6103ad8acee0; %join; %free S_0x6103ad8acee0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x6103ada59f90_0, v0x6103ada5abc0_0, &PV<v0x6103ada599e0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 9f3fa1fd873e49414446b36421a1b80ab409741c9f36ae5e610b07fe9b10a44b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 727
- `line_count`: 9
- `sha256`: 72a6f1f87b2419a24f09d0938eb7a074554c28372c5465a9a2748f30ded7eed3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=727 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000000000000000000000000000000000000000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 4daf051589954571406bdb22ba9ac2092b5cc925b950b10e8738e7f33a45e72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "pair-fire-dies-early-mask", "mutant_sha256": "a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: bc6e07f1914ee903ea47aca0aed0a5a526b73ff8f181254e54e0bccdb0cab2ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=pair-fire-dies-early-mask sha256=a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49829
- `line_count`: 1032
- `sha256`: 76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49829 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355963
- `line_count`: 34155
- `sha256`: 0034422d593ad304cb185e7bad5679cd9cca6a0c0f2724ceb2aeb4e255ead150
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355963 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x5c186d73f040; %join; %free S_0x5c186d73f040; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5c186d8eb860_0, v0x5c186d8ec490_0, &PV<v0x5c186d8eb2b0_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: e29dae4cc2861a3467f190255d1d634a178863db556e5af1df6a9b932d8cbd63
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 943
- `line_count`: 13
- `sha256`: 663e77fc55d6bc02d0811bb7211f54b6e72be9952a19ac81feb49560c15ec2f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=943 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356679
- `line_count`: 34155
- `sha256`: 84e132e0f5af09b1f38da3775d12d4529122e57d5fceccc04f9fea21ef326129
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356679 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x631c470108b0; %join; %free S_0x631c470108b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x631c471bd530_0, v0x631c471be160_0, &PV<v0x631c471bcf80_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: 54e4aff1cb0647bac295b0df9e2d8ae4195b276b39b3e2b1d7675a01cad1af6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 1055
- `line_count`: 13
- `sha256`: 2652d2e9dcfefc4ff66d2cf2b6fcd3a25db4213efb6af0e4abbe4efe76cd99ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1055 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/mutator.json

- `kind`: json
- `size_bytes`: 334
- `line_count`: 7
- `sha256`: 737c806ca28eda312a4fe2a3fea8748ccf875f1cf3a0847e7d0d5ddac54d72ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=334 bytes; lines=7; markers=<none>; tail={ "case": "pair-pop-only-entry0", "mutant_sha256": "76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/pair-pop-only-entry0/mutator.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: e32d42fb51e25fe9a1c0a41189cc138df2f42b4664721234920fa6c86af12dc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=PASS mutation=pair-pop-only-entry0 sha256=76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 50031
- `line_count`: 1036
- `sha256`: ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=50031 bytes; lines=1036; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356903
- `line_count`: 34196
- `sha256`: 1688610e80e5b48d29aed83743b3505ef6c6084443a21260df2a8202647a87d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356903 bytes; lines=34196; markers=<none>; tail=, S_0x5a1d06f70bf0; %join; %free S_0x5a1d06f70bf0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a1d0711dc50_0, v0x5a1d0711e880_0, &PV<v0x5a1d0711d6a0_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: 8af57c1c86fd7b9015d88e55db29353df5643b9c41e4ee246698538197ffc4a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 9
- `sha256`: 928da65d0b64e177ead76be2fc561b1cc9f3516be2f3d5b88e0f033037a47c15
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=610 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=000c0000 expected=000e0000 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357619
- `line_count`: 34196
- `sha256`: 75665744dd38612fe4650b326c5481d6bc03d2125560e3b4929c963f619220e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357619 bytes; lines=34196; markers=<none>; tail=, S_0x5b9e9f057460; %join; %free S_0x5b9e9f057460; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b9e9f2048c0_0, v0x5b9e9f2054f0_0, &PV<v0x5b9e9f204310_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: f79cbc4beca68f248c9ca667cee7597934b6307e7adb5cbf49efb7d2f0fe8fc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 722
- `line_count`: 9
- `sha256`: e952e9a8022e7ed01b70b9129c8471d71b8aee22e19c3ae502b6bade637929ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=722 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=0000000000000000000000000000000000000000000800000004000000000000 expected=0000000000000000000000000000000000000000000800000004000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 342
- `line_count`: 7
- `sha256`: 97fc9592c7a04b44d30c1efad910408eb630e3aa86647cb20c7b2dbb1b1b3fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=342 bytes; lines=7; markers=<none>; tail={ "case": "regular-fire-dies-early-mask", "mutant_sha256": "ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/regular-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 115
- `line_count`: 1
- `sha256`: ef818dd13a8049e45ba7e8bffb031e318c51e731cdc80d32b869cc1ff46d3398
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=115 bytes; lines=1; PASS=2; tail=PASS mutation=regular-fire-dies-early-mask sha256=ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49844
- `line_count`: 1032
- `sha256`: 6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49844 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: fd9e1022377262d1514cbfed6fa4d98571f6620facb1bb772c8405580dcaa019
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x5c24d8c61110; %join; %free S_0x5c24d8c61110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5c24d8e0da60_0, v0x5c24d8e0e690_0, &PV<v0x5c24d8e0d4b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 665f035c29bdaaa36a67947bca6733acdff939e846928f2c43637225bbe09415
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 11645
- `line_count`: 152
- `sha256`: a140896dbe53a53f76cc0c855c7e68f3d0c3539657b4353ffc4aec6f711596fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=11645 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: d857a18ceee69cb35c5a57a733c719db7f0fe32dc13c90781a71891c6a5a6bed
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x64c1724b99a0; %join; %free S_0x64c1724b99a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x64c172666780_0, v0x64c1726673b0_0, &PV<v0x64c1726661d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: ce190b031fa739f267c7333345fdd0cdf059676973cbf0ca79e25fbeb9c9f493
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 13213
- `line_count`: 152
- `sha256`: 2781541c402c74c05a22d786b8b71699026f7e19a0159601f878f30faf7389c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=13213 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: b0ba90d98797a594e876d42b33a9df54a9068540030da30291a82cc9304c26a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "reset-ignored", "mutant_sha256": "6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/reset-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: 364f934bdde255f9061aadcd36b05bf331df7867fca116a5a753e0e0b485eb95
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=reset-ignored sha256=6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375009
- `line_count`: 34884
- `sha256`: b9163da318f37aca9a59731f5f9f191abfe0b1cf333c43973bdf014d0488fcca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375009 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x6325a2fc4ac0_0, 0, 1; %alloc S_0x6325a2e00070; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x6325a2e00070; %join; %free S_0x6325a2e00070; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g1/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: e0b24f28b3c5c5cc71eae024fd9c59c7ce3405108a1be6b70164dc148b0b7663
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375725
- `line_count`: 34884
- `sha256`: 79594dec27083c8c9921764176a60b47659c2d36bacd5dbfaf41c05b8ba85fe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375725 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x646b8bb11720_0, 0, 1; %alloc S_0x646b8b94c8e0; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x646b8b94c8e0; %join; %free S_0x646b8b94c8e0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g4/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: ac02f740cc4a81c113dffa774c6f6779844ae2df9081f5d6d1bf17e6a0ba5aad
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/assert-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34161
- `sha256`: 6751555287caae0f3e95bb568903884c5de8eb7fdb1cd26eaace13614f4c81d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x6361b891c8c0_0, 0, 1; %alloc S_0x6361b8773200; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x6361b8773200; %join; %free S_0x6361b8773200; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g1/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: aa141762e8b63286dd8a1a57e91fcece207639772d814d105348633c3aeaa051
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34161
- `sha256`: c62f3810ee924475d8c0d07c1fdc2e34e60f646e08119db4c75b9e3384d39e00
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x5b1506b7b5d0_0, 0, 1; %alloc S_0x5b15069d1a70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5b15069d1a70; %join; %free S_0x5b15069d1a70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g4/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: d393777e64f6b903dfed1fd33fe33794f9219c6962feabf4ae6f956863cac7ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/profiles/release-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/rtl-source-binding.post.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/rtl-source-binding.pre.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: a429d99de73331074dfe31a9d026fe04c5e3b588b0a7eefdd65ba2dee299cb54
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: a429d99de73331074dfe31a9d026fe04c5e3b588b0a7eefdd65ba2dee299cb54
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/summary.json

- `kind`: json
- `size_bytes`: 104280
- `line_count`: 1312
- `sha256`: 16fe2c288fd2cce2439f70ee4694c5b011347d764d5f4853f6ba891c17937459
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 1}
- `summary`: json evidence; size=104280 bytes; lines=1312; PASS=1; tail=er-semantic-coverage/evidence/int-iq-producer-attempt-1/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v", "compile_log": { "path": ".github/task-runs/2026-07-30-rv64-v11f-int-iq-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-1/vvp.version

- `kind`: version
- `size_bytes`: 814
- `line_count`: 18
- `sha256`: c9010a85df9399c2adb11b59115cdc285ea6f0a399802944367c3813c6772a42
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=814 bytes; lines=18; markers=<none>; tail=Icarus Verilog runtime version 12.0 (stable) () Copyright (c) 2001-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free So...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/evidence-tool-unit.log

- `kind`: log
- `size_bytes`: 1564
- `line_count`: 13
- `sha256`: 8a688c1b7e1cd0bce25fc5df437d59f8d0a64aa837f7b5d63922461e24ad0df2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=1564 bytes; lines=13; markers=<none>; tail=test_assert_release_width_matrix_is_exact (npc.rv64.eval.ppa.tests.test_int_iq_producer_semantic_evidence.IntIqProducerEvidenceTests.test_assert_release_width_matrix_is_exact) ... ok test_carrier_lifetime_and_knownness_mutations_are_present (npc.rv64.eval.p...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/iverilog.version

- `kind`: version
- `size_bytes`: 3294
- `line_count`: 73
- `sha256`: f9199cc8658f4afcec3edeb93f29f23bb2aebf66d3eeb217cdc728aaa692f946
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=3294 bytes; lines=73; markers=<none>; tail=Icarus Verilog version 12.0 (stable) () Copyright (c) 2000-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software F...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356170
- `line_count`: 34164
- `sha256`: a8dbd809c9c27837864ce40ee1f57d50cbc70f7eccf1ef799350a750d3da207f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356170 bytes; lines=34164; markers=<none>; tail=ts, S_0x6132884e5760; %join; %free S_0x6132884e5760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x613288692460_0, v0x613288693090_0, &PV<v0x613288691eb0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: a6c9db041617c61dfd79129b1ebcc0735e19b0d18c2cd842d6e1ddb71611ef63
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4712
- `line_count`: 62
- `sha256`: 587ddd594ab9b7d4b91755a675e55bc809da985a3c07b298ee508b3abe2decff
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 110, "PASS": 10}
- `summary`: log evidence; size=4712 bytes; lines=62; FAIL=110; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=14 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356886
- `line_count`: 34164
- `sha256`: 97ead890385d173de7b3c60ca2f3065a0418f0bd609f3f2c88550ef80825fde7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356886 bytes; lines=34164; markers=<none>; tail=ts, S_0x5f447b44ffd0; %join; %free S_0x5f447b44ffd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5f447b5fd070_0, v0x5f447b5fdca0_0, &PV<v0x5f447b5fcac0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: 2139765f1923063a386bacee483d2b079571cc0b184b9cb4066fb4be2318da5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 8615
- `line_count`: 87
- `sha256`: 0faed97d6cbbad6906df58af68dbc4b2265cdcddfb9f6a26bcb827cae895b5b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 160, "PASS": 10}
- `summary`: log evidence; size=8615 bytes; lines=87; FAIL=160; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=34 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000018 expec...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 340
- `line_count`: 7
- `sha256`: 0f7071c9c8a33ba18acedff4fd14055960ca369b5bf266b9d6ac67ad7f895051
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=340 bytes; lines=7; markers=<none>; tail={ "case": "compaction-generation-zero", "mutant_sha256": "f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 113
- `line_count`: 1
- `sha256`: 3b0e86b7ef786dad1a19ade992cc17e12ae4988f887f6d398f9d5bcb122a224c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=113 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-generation-zero sha256=f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49848
- `line_count`: 1032
- `sha256`: af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49848 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355766
- `line_count`: 34158
- `sha256`: 33d3c15c333a5bf2a8e6416ff27562aff5161ed6c448af9a79e0bd9529e308fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355766 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x614c9fd6e250; %join; %free S_0x614c9fd6e250; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x614c9ff1abd0_0, v0x614c9ff1b800_0, &PV<v0x614c9ff1a620_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: bb465fb2ee7db295748df6431613a4d68b9859cd3d89f798aea7f41bf4162afd
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6834
- `line_count`: 93
- `sha256`: 32c794e9ce4a630640a09eb56717422aa8d659b9f4ca28a1c407db39f916f2d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=6834 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold raw PID unk...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356484
- `line_count`: 34158
- `sha256`: 538ac848cd9f33d841361aee57ff37af87758f7de3f04f7f35ae2c13cab27d09
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356484 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x59c16b4dcac0; %join; %free S_0x59c16b4dcac0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59c16b689870_0, v0x59c16b68a4a0_0, &PV<v0x59c16b6892c0_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: 07459cb8f6f1d76b186c8ec6f04ef9d82dda7c9d33d33910f4d4e06244a68ecf
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 8850
- `line_count`: 93
- `sha256`: ae229f412ee869269f6abe56d10a763ee093d7615b31f60b4238a50869d633e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=8850 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000000 expected=0000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 330
- `line_count`: 7
- `sha256`: 6e19b1d2f44baedfcc2a9945d54707cd7b9397703b74fcacaeba91d807659f09
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=330 bytes; lines=7; markers=<none>; tail={ "case": "compaction-pid-x", "mutant_sha256": "af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ce...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 103
- `line_count`: 1
- `sha256`: d559f13b26fe5ffc23194b38c6e7a84d193552e81628e083a470da2439e60eeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-pid-x sha256=af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356093
- `line_count`: 34161
- `sha256`: 274f80ed4e6c52bc65fba3e8cbd6f9143612f0497efd19c1752807c38d136696
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356093 bytes; lines=34161; markers=<none>; tail=_0x607ba5d041f0; %join; %free S_0x607ba5d041f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x607ba5eb0bc0_0, v0x607ba5eb17f0_0, &PV<v0x607ba5eb0610_0, 0, 32>, v0x607...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: 4f0505d40446b150892b6acf1163e2d8bd753b97640be5632d0f6393577ae5ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 1566
- `line_count`: 21
- `sha256`: b382c900af6a56b82fad16f1c6ce3983b06810a109bd57823240c3f1f000b0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1566 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=12 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=12 expected=13 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356809
- `line_count`: 34161
- `sha256`: 1484471c60913e92aac8aefdae8f9c9b92a6af36747990def3b4eac8bba33087
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356809 bytes; lines=34161; markers=<none>; tail=_0x5e264f01fa60; %join; %free S_0x5e264f01fa60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5e264f1cc930_0, v0x5e264f1cd560_0, &PV<v0x5e264f1cc380_0, 0, 32>, v0x5e2...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: 9f77e05fb57fe6c3975ccc655c94dabae0b34966dcc7c541ea5224a424681496
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 1902
- `line_count`: 21
- `sha256`: 9e1d7b15d58addc12d62ff3948952732cefb87d4b615f8675f6e78ac7be0f919
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1902 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=32 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=32 expected=53 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/mutator.json

- `kind`: json
- `size_bytes`: 345
- `line_count`: 7
- `sha256`: 74aaaf86435ce2cd4779b5d72b0b31edda382f225713ebfcca020923400892a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=345 bytes; lines=7; markers=<none>; tail={ "case": "compaction-uses-write-index-pid", "mutant_sha256": "94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/compaction-uses-write-index-pid/mutator.log

- `kind`: log
- `size_bytes`: 118
- `line_count`: 1
- `sha256`: 6032235f8ec24ef188339bf8b6a83e927a1e51ca6a22347c560ee2b09b6b8b17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=118 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-uses-write-index-pid sha256=94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356169
- `line_count`: 34164
- `sha256`: e4324425e848906f7e7395c99ae3945c78a247cf851ba6f20729606862629310
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356169 bytes; lines=34164; markers=<none>; tail=uts, S_0x5b3467f0c760; %join; %free S_0x5b3467f0c760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b34680b9440_0, v0x5b34680ba070_0, &PV<v0x5b34680b8e90_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 45869cd43c1eb737c68311ceb8436ce5d5f15fc8463b1b19de615d48e950f111
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4387
- `line_count`: 57
- `sha256`: c1d4c54f2bd981183242735721bbe60553f6a019f0a6014a792f1bea25bf6f2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 100, "PASS": 10}
- `summary`: log evidence; size=4387 bytes; lines=57; FAIL=100; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100008 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356885
- `line_count`: 34164
- `sha256`: 8fc588f26117600498212ccb4c47f66d064ae1bd0a922d3f503ac227701cc74b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356885 bytes; lines=34164; markers=<none>; tail=uts, S_0x5d3b5d9d2fd0; %join; %free S_0x5d3b5d9d2fd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d3b5db80030_0, v0x5d3b5db80c60_0, &PV<v0x5d3b5db7fa80_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: f3e81dad6676def5b6ed14962fb22609c33c320e926b4027381c40dc2165f262
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 9291
- `line_count`: 83
- `sha256`: 64dfd48c4d980e417ba7d4adc52c339e4d94502deaaf2db3c7629289fb71756d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 152, "PASS": 10}
- `summary`: log evidence; size=9291 bytes; lines=83; FAIL=152; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000008 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 8612d1610ab2e057f8fe0c8f2bda02934ffe76dad53b970848f2af30081bca38
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-generation-zero", "mutant_sha256": "f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: 8aa15918bcd50027498e550eea1675884808e8f21075aa4f3d19b7f988a941a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-generation-zero sha256=f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: f42c68928c706e146d04bd70776f36775e0219167488f7b7ec49d7b5796aa4d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x63ca27c1c320; %join; %free S_0x63ca27c1c320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x63ca27dc8db0_0, v0x63ca27dc99e0_0, &PV<v0x63ca27dc8800_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: ee7588d985807bf853480a1efa44af4831f7ca82c765b9771fbcd6989abb9982
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6712
- `line_count`: 90
- `sha256`: d1dc63f100296b77ab4b4d27f0b141825da36721c5e528fb4db01379f873d952
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=6712 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=xx expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: 33724cfd2ee9bd4c237d24d3338f85628cb9498351bdd103cc16d7a63e41c610
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x563e95a66b90; %join; %free S_0x563e95a66b90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x563e95c13a90_0, v0x563e95c146c0_0, &PV<v0x563e95c134e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: fe5ad441222cde90027365e23d27283a7e671829ef6fdd4e262f68b7b062820e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9624
- `line_count`: 90
- `sha256`: 768292123b90aa255de63064d113db9aa6a0f62c170014d0e7806b0cdac3b132
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=9624 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: 68b0215960fc6ec71831f71254645934d3ce243687e2e9cdcc4271efbd106df6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-pid-x", "mutant_sha256": "8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch0-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 0816f96adc8c90027ba9ba8cc5802d1681f96538c73a0be94a0f3e4389542c83
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-pid-x sha256=8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: 886cd434dad2f6aa016a5aae269bbf6d82ff3e6b2179e446e649e4f3787aac76
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x566a30d22320; %join; %free S_0x566a30d22320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x566a30eced90_0, v0x566a30ecf9c0_0, &PV<v0x566a30ece7e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: c1f69d5c4fbc3fd8a15bd59d73ff9bee983e61baf41431d91811088f81e67389
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6648
- `line_count`: 89
- `sha256`: c94e11312bc94d676bebb73981fb9921e3d6f2425ee533bfea50d2469c8f26ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=6648 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=xx expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: 8344b37f36271c26e88b5076a8c0790594dc722d05bc01f0a05a15f19fbc5f2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x5f1419a4db90; %join; %free S_0x5f1419a4db90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5f1419bfaa20_0, v0x5f1419bfb650_0, &PV<v0x5f1419bfa470_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 5eb667ebbddfb72860f77b45444930eaf34f9a339e2faf1799c2317598c2878f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9448
- `line_count`: 89
- `sha256`: fcd5bad1349db3949cd559b4db3d67221f97a839a1c565d81091c741d5d78c33
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=9448 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: b557037406e19a587d848ad87e6861f9437fa402124d314ebdf6f187078edfcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-pid-x", "mutant_sha256": "a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 9a8392f2ce27f9156a11cdd9a44c12f8e4ceae0c495f5212a553f308408187e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-pid-x sha256=a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356067
- `line_count`: 34161
- `sha256`: 96944b600dd335a3455c0337b31e3cc294635e2e65382f70af832918fe9c8023
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356067 bytes; lines=34161; markers=<none>; tail=puts, S_0x566ad45c11f0; %join; %free S_0x566ad45c11f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x566ad476db50_0, v0x566ad476e780_0, &PV<v0x566ad476d5a0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: 0beee40c823b1f46eddea691e3258c3e84cf57c5a9127afe1c75a3d9173ac854
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 6536
- `line_count`: 85
- `sha256`: a15fa76fa942536fac5603f140ac9207cd18e1f3def72e20cea9661f73ba92e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=6536 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356783
- `line_count`: 34161
- `sha256`: 9f298fbde5e4162a6a95fccd4be94c27c534440fdf81fb092e1c9aacf999e518
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356783 bytes; lines=34161; markers=<none>; tail=puts, S_0x5bb2f6584a60; %join; %free S_0x5bb2f6584a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5bb2f67318b0_0, v0x5bb2f67324e0_0, &PV<v0x5bb2f6731300_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: 53bec53bb9d680773a89c98e832a3bed35e166b80a4f783a07d9cfc3ebb3bc46
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 9336
- `line_count`: 85
- `sha256`: 2434da3fc61fa8297b25fd979b4825207ed9add1044064e4e2f6c97488e6d794
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=9336 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=34 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/mutator.json

- `kind`: json
- `size_bytes`: 338
- `line_count`: 7
- `sha256`: 1f424896ea875728175752d1afc03a6fa0d7f3cfb3a627995e5e19c48c25aa28
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=338 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-uses-lane0-pid", "mutant_sha256": "0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/dispatch1-uses-lane0-pid/mutator.log

- `kind`: log
- `size_bytes`: 111
- `line_count`: 1
- `sha256`: bb534235ae9256560ed541ebd89b225f3aebbdc62f03fe85f73e8d9dc833637f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=111 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-uses-lane0-pid sha256=0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49840
- `line_count`: 1032
- `sha256`: f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49840 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: 64899b14d3e0a4263acae26305b4058e3e726b5fdd1d38b6dd595202803f2712
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x56c6013f3110; %join; %free S_0x56c6013f3110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56c60159fa60_0, v0x56c6015a0690_0, &PV<v0x56c60159f4b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 43dfda14e51d02806b4a24eea9634ad47d242ee625eec38fe1c1f8cd5e11662b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 1708
- `line_count`: 24
- `sha256`: 2796ceb605601b6ae45732ba5b7fdce648508638d51c7215dfb9c083a6a812d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=1708 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: 9390de6b213a82f0a11d1401e112362591f90d74daf0eeed57e2bad0757548af
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x64273a2819a0; %join; %free S_0x64273a2819a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x64273a42e780_0, v0x64273a42f3b0_0, &PV<v0x64273a42e1d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 8fcd0797a4e9f5ad5643be79a8efd869db73243bf7972bcf6c5eed1734a2e758
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 2044
- `line_count`: 24
- `sha256`: ab04c772767add3b9fab8f653fc1812d27370a3aea370aa35359028bff1277cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=2044 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: c1485e96a39ddc53cf40e40bf7d9bd17138a6c8a3bd6b7027d5996995a501f1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "flush-ignored", "mutant_sha256": "f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/flush-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: c9aec4167a6723841275cfb8f3ec6305f203e71a53d094962a4522a4b9680c17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=flush-ignored sha256=f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355756
- `line_count`: 34149
- `sha256`: caff77075aff05a790a809051c62ad91543af77efe71f552c9cc6faf3799bee1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355756 bytes; lines=34149; markers=<none>; tail=nputs, S_0x6306f642b2b0; %join; %free S_0x6306f642b2b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x6306f65d7a30_0, v0x6306f65d8660_0, &PV<v0x6306f65d7480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 0da076423caaa5127b70cd79d10c1e37512322a6199cd398bf8475b18e320967
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 2631
- `line_count`: 35
- `sha256`: b30d02788dc8601c99f1522e8169c5a8b9b71068a1928d4ec680649a70c59a3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=2631 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356472
- `line_count`: 34149
- `sha256`: 9ff02fd02b4780355540b52d0b342ac76547d6f88128a4093976b267a96d659a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356472 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5b9126d75b20; %join; %free S_0x5b9126d75b20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b9126f226f0_0, v0x5b9126f23320_0, &PV<v0x5b9126f22140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: c39a000cfe10e1284bd41443ad6a8df05339dc1b09dfa6af78e2b168a9a76ec5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 3079
- `line_count`: 35
- `sha256`: 3009bd3dea6af60c3c3f2f2dd2225af4f79fffd10f83fb8dd064a089dc42b514
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=3079 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 6f7b26ac779c1bf9c44addeacf5453181d64888e729b6747d5958f0a03df602e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-fire-not-removed", "mutant_sha256": "c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: d730e852f54888b5cbaa754c6f8a2eddaf5787deee1f381da83846e4033678e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-fire-not-removed sha256=c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: f6a54bae1373a4fd592d4f19a9a5708fdcf45b545954c537476a39446c82498d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x6028862d9760; %join; %free S_0x6028862d9760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x602886486d90_0, v0x6028864879c0_0, &PV<v0x6028864867e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 69f1aab196dd21be8950ddc80f37f1cfe24646f97f63579a7f97254b5692e49d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 806
- `line_count`: 12
- `sha256`: ecf09df0b8b679d485050007252c3137a898f4a8a6a7ad91a8c34de210b4bdc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=806 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID got=01 expected=11 [V11F-INT-IQ-ORACLE][FAIL] post-compaction issue0 is...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: c157e989475b38f6399f89042effe8c0e2369c54345989c80e3500649ff824e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x6361ab03bfd0; %join; %free S_0x6361ab03bfd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x6361ab1e9910_0, v0x6361ab1ea540_0, &PV<v0x6361ab1e9360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: f30f6c8dafff5adfdae730f0971d54a1b992f0cb1e55c3a1963ddbbcd6ac2e9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 13
- `sha256`: 18ee3ccb7576d967b96fdd7f0234f7e2e319125f4665e015f736f86136c254f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=877 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 PID got=06 expected=46 [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: ec65ccacfa43aba5bd53516fb28f55b703196f9793bc7a03dbc49aed4a3c38f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue0-generation-zero", "mutant_sha256": "90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 7629fd03fa15cfd2ab955a4bde8eea5c3d6cd7edf1554b6d6bb6a182365f06a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-generation-zero sha256=90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49847
- `line_count`: 1032
- `sha256`: eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49847 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356086
- `line_count`: 34161
- `sha256`: 8f3518c112258a382f06fe60e6098785dc49658f9ee50044158b90ccd30733e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356086 bytes; lines=34161; markers=<none>; tail=nputs, S_0x64bda1a5e2a0; %join; %free S_0x64bda1a5e2a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x64bda1c0aea0_0, v0x64bda1c0bad0_0, &PV<v0x64bda1c0a8f0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: bd1d67c8ed998a7e9b4d3d1b255487d77e43ea6821be318ec82dc88e2916be9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: 7bae1d941fce32967a137c5f925e870c1468d4537a4e3ebcc43229c8dd01292a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356802
- `line_count`: 34161
- `sha256`: 7268df6ce10c5670c0319379306297da10639316ea9a01b94dd79b044b0b6998
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356802 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5989c452cb10; %join; %free S_0x5989c452cb10; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5989c46d9b70_0, v0x5989c46da7a0_0, &PV<v0x5989c46d95c0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 176459dac68191d554b3b8c8affc9e425d9f4ca33b2e2d5ea290df00348ba083
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: db1568600ba65ed2d49101c916a7b5cc8d131b10e4dcd8eb15e3f5627d8a4b96
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 8eccc824b19a2f435139b8f44fd680774af3be945da0b71c6b0d4044656a0d4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-raw-index-entry0", "mutant_sha256": "eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue0-raw-index-entry0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 60ab23ada23fe2b9fa3c58f2c9cc9e7f0c9dc2d81c4b6584b71f38b90954ecce
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-raw-index-entry0 sha256=eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: 548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355759
- `line_count`: 34149
- `sha256`: 7145f8a821b72ac76e0a2299d92e1444d1e732bba74c1f5a17e402b8537fb732
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355759 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5e0ddf5792b0; %join; %free S_0x5e0ddf5792b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5e0ddf725a30_0, v0x5e0ddf726660_0, &PV<v0x5e0ddf725480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 1db36cee957840b3b20ed8967cda07431c86bd77502ffcb0a78187885607e317
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 893
- `line_count`: 13
- `sha256`: 68f5e5ca7c1cc7df51d282eaa341a29974ac68bb657c0706fe4ad44e9a43b7c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=893 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=13 expected=04 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356475
- `line_count`: 34149
- `sha256`: d25335eaefc19f730000a555f49732b14d108da72e0a90630bb3c772fc0b9c99
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356475 bytes; lines=34149; markers=<none>; tail=nputs, S_0x5d938b695b20; %join; %free S_0x5d938b695b20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d938b8426f0_0, v0x5d938b843320_0, &PV<v0x5d938b842140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: c2b8ea4704093154d10d852fbb5fffcfddd2ec9b16b517504adbe870ed5355a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 1005
- `line_count`: 13
- `sha256`: 0f27dbd42e1771bb55f5f23deb8d724d40af42fa994dc9812ea2661f68648ace
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1005 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=53 expected=84 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 4a17a89fbba54d442f777dcd25af8cb877b42ab3ef8c361ea454ab1cfd865aa7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-fire-not-removed", "mutant_sha256": "548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 69abd44948e3a9375210907acfbf7d48f0365215a5f084bc62b5ac0bf2bf6335
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-fire-not-removed sha256=548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: ad2464bfba08fbfaf6d2f80592a7f4a297dbe58eb351aad1aa680a1863f5bafc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x60d434115760; %join; %free S_0x60d434115760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x60d4342c2d90_0, v0x60d4342c39c0_0, &PV<v0x60d4342c27e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: f21d83381051f73a5e4a4b7e9db51dea0838d5f7e804375c8e9a7c0acec3fce6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 753
- `line_count`: 11
- `sha256`: dfa5799b5c34c1b9dd5e27715de1488280d275a2cdfb42e65a6b5d3da3fa1775
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=753 bytes; lines=11; FAIL=8; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=14 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=12 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: ebd97a166dc30a3ea33d749b7650d02d5d4361feff7a89fc9e3fc7b9adfeb29c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x5a38aca5afd0; %join; %free S_0x5a38aca5afd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a38acc08910_0, v0x5a38acc09540_0, &PV<v0x5a38acc08360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 67022e2a835689e1ab8061b6238288cb778443f55fa763afb0179d8ce01d29c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 816
- `line_count`: 12
- `sha256`: d5dc84d67de5acb0854ae3b0d5dc0002428285317f8ea28a95b0836b91b7987f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=816 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=34 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=32 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: f40c4f4f5d87315d92465080edece62fedc6a5732cca33571022fb7506de8f99
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue1-generation-zero", "mutant_sha256": "7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 76d32b3a68d1b90a559d01beab58c2dc0b71adde9486b0b040a1107b9efb5f30
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-generation-zero sha256=7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356085
- `line_count`: 34161
- `sha256`: 11f2b68339f09dc4ed68935387d357905cc93155c76292aa8dd190adc673599b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356085 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5ef42fddd1f0; %join; %free S_0x5ef42fddd1f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5ef42ff89bf0_0, v0x5ef42ff8a820_0, &PV<v0x5ef42ff89640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: fa9b56e990f0d7b665b75ac96db905fe3d425bf413af6b69b4e2185a8983abec
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g1/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 34b5a22b5fb64bb05a3897ab9310bada5a2c9382ec53b2ae9788c23056fb3f06
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356801
- `line_count`: 34161
- `sha256`: 131a40aaac5651beb6034345171269bc13d5f824c81ca20948421adaf889ad19
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356801 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5921e0836a60; %join; %free S_0x5921e0836a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5921e09e3920_0, v0x5921e09e4550_0, &PV<v0x5921e09e3370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: e2594618956b96533457bc0d800cedd2f174b3b9537adf2290b518107b5616a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g4/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 1ee68483112138b5ccdd5a48cd02662d4aaae79f3e04a66ccff20f551612cd90
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: c4af6c9e345974efa986ad6974b591f2a354ce0c157aeee247a64fa767244171
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-raw-index-issue0", "mutant_sha256": "75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: bd4a8404a3b21f1c7ece80e7618267f2aae5e35f1450cc5fb8d0047b81946f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-raw-index-issue0 sha256=75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49853
- `line_count`: 1032
- `sha256`: 36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49853 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356147
- `line_count`: 34165
- `sha256`: c528fce4937eb2271a319795212dea885a017639263270fdf6b446214fe02f90
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356147 bytes; lines=34165; markers=<none>; tail=nputs, S_0x5c64ae7851f0; %join; %free S_0x5c64ae7851f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5c64ae931bf0_0, v0x5c64ae932820_0, &PV<v0x5c64ae931640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: b838c31b4000933a1d2d6e791288e884582026838e984be36d6ae51d66111f34
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g1/sim.log

- `kind`: log
- `size_bytes`: 975
- `line_count`: 14
- `sha256`: 27f7ab2148a8f8e4d9cedc3f2851e8da2ee3b7b70fc7ea4f8b46cc7bcbdc6e76
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=975 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356863
- `line_count`: 34165
- `sha256`: 19fd2add7ea6b12b2428949ac97466987184d9f447c3c42dcaae0485d6920dcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356863 bytes; lines=34165; markers=<none>; tail=nputs, S_0x61a33b064a60; %join; %free S_0x61a33b064a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x61a33b211920_0, v0x61a33b212550_0, &PV<v0x61a33b211370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 71ceecb84e6a667ac042b5d955635f053bf6df2527535f963c582b61a1c7c874
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g4/sim.log

- `kind`: log
- `size_bytes`: 1199
- `line_count`: 14
- `sha256`: ec97ae2f6a9163b3b7a0b732c47b16f5b0f86541cfc3010ac519957cbb0a2920
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=1199 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 893a577bb69cf3c2e4246b7253126da141da14b4e0a525c7ce1b708b215ae967
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "kill-boundary-inclusive", "mutant_sha256": "36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/kill-boundary-inclusive/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: fbe99edf97f38d53d0a548df699c4612e445148beed2287cda1e7bfe71221078
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=kill-boundary-inclusive sha256=36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49868
- `line_count`: 1032
- `sha256`: 2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49868 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356102
- `line_count`: 34162
- `sha256`: 43622a5b565e9df2978bdbcc63fd0e035f80ac49632fa820ca3ac2d2a5137b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356102 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x59e3c69ac400; %join; %free S_0x59e3c69ac400; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59e3c6b58ee0_0, v0x59e3c6b59b10_0, &PV<v0x59e3c6b58930_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g1/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: 377bdd40c0816e533e66375d1360ee53f34ed86c1121d4a83e250d2627b131ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g1/sim.log

- `kind`: log
- `size_bytes`: 2472
- `line_count`: 31
- `sha256`: 25ac5432071a2f02e8a4bb428ba75022a1fe581a8f243012f2bd021dd8e99821
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 48, "PASS": 10}
- `summary`: log evidence; size=2472 bytes; lines=31; FAIL=48; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE]...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356818
- `line_count`: 34162
- `sha256`: daa1c33b7d34cea9f9dbc91b612c8c3c57c709873b3cfc108d788bedd5e67cda
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356818 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x570eca522c70; %join; %free S_0x570eca522c70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x570eca6cfbe0_0, v0x570eca6d0810_0, &PV<v0x570eca6cf630_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g4/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: 5c2763bae7a241e17edb26ee98c5b3ad3289cf1892021e143e9d1e11506362d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g4/sim.log

- `kind`: log
- `size_bytes`: 5644
- `line_count`: 34
- `sha256`: 613744e04db250a7370516678e1ff256a4928409ee75b9b87825f408c8439035
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 54, "PASS": 10}
- `summary`: log evidence; size=5644 bytes; lines=34; FAIL=54; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000000018 expected=0000000000000000000000000000000000000000000000000010000000080000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/mutator.json

- `kind`: json
- `size_bytes`: 332
- `line_count`: 7
- `sha256`: 595050c75bd696f3d1cb8221c9cf98c6913daf28b1be779ea2d8c4e4d4c553d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=332 bytes; lines=7; markers=<none>; tail={ "case": "mask-raw-rob-index", "mutant_sha256": "2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/mask-raw-rob-index/mutator.log

- `kind`: log
- `size_bytes`: 105
- `line_count`: 1
- `sha256`: f7b11cd8e1d5a618361ddf5b805ccc60696a036dcb10503889534fb0ac88d9af
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=105 bytes; lines=1; PASS=2; tail=PASS mutation=mask-raw-rob-index sha256=2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49941
- `line_count`: 1034
- `sha256`: a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49941 bytes; lines=1034; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356586
- `line_count`: 34184
- `sha256`: 3c8548d8cd40507008f518a6d4cf48ddd24f0fa8579b4355af0bbd9e2cab91ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356586 bytes; lines=34184; markers=<none>; tail=uts, S_0x57b63519c670; %join; %free S_0x57b63519c670; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x57b635349300_0, v0x57b635349f30_0, &PV<v0x57b635348d50_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 978f5568b535845fb26f0459d625ccbc01023c422dbbfb8c52cfaf6c49951928
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 9
- `sha256`: 708e3361c5efd9da0f9ea2a805d4366835b0b31df2ea2efc8f795973cea2aa45
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=615 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000 expected=00400080 [V11F-INT-IQ-PAIR-DEATH...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357302
- `line_count`: 34184
- `sha256`: 295782ea01af45484fde79e0ee6c89e107b00a8b86b1b01e052171cf4db68e55
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357302 bytes; lines=34184; markers=<none>; tail=uts, S_0x58c4c6ccaee0; %join; %free S_0x58c4c6ccaee0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x58c4c6e77f90_0, v0x58c4c6e78bc0_0, &PV<v0x58c4c6e779e0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: b1dbccbd43d87e6ac5892224eb35bb15e11387bc8e0e79193326c5e7e5ac2f39
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 727
- `line_count`: 9
- `sha256`: 72a6f1f87b2419a24f09d0938eb7a074554c28372c5465a9a2748f30ded7eed3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=727 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000000000000000000000000000000000000000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 4daf051589954571406bdb22ba9ac2092b5cc925b950b10e8738e7f33a45e72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "pair-fire-dies-early-mask", "mutant_sha256": "a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: bc6e07f1914ee903ea47aca0aed0a5a526b73ff8f181254e54e0bccdb0cab2ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=pair-fire-dies-early-mask sha256=a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49829
- `line_count`: 1032
- `sha256`: 76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49829 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355963
- `line_count`: 34155
- `sha256`: 1d2400d30393141b921f765d27e471715f19fd02ad1a9c15de51d05b41e9924f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355963 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x59c0665d5040; %join; %free S_0x59c0665d5040; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59c066781860_0, v0x59c066782490_0, &PV<v0x59c0667812b0_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: 24a698d9c77263cb9b667434cde1476eb907f2860d9322f5bdd54b9351a93ba1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 943
- `line_count`: 13
- `sha256`: 663e77fc55d6bc02d0811bb7211f54b6e72be9952a19ac81feb49560c15ec2f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=943 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356679
- `line_count`: 34155
- `sha256`: d6f24f8c70424a1afbedff2e0e4d9b7c0628efe29d3096305f1407c2f3e7d9f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356679 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x626762db48b0; %join; %free S_0x626762db48b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x626762f61530_0, v0x626762f62160_0, &PV<v0x626762f60f80_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: 946928c4b3430324abffa9a774be8371cb6bc8e47192a7dfd8aaaca9acd96650
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 1055
- `line_count`: 13
- `sha256`: 2652d2e9dcfefc4ff66d2cf2b6fcd3a25db4213efb6af0e4abbe4efe76cd99ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1055 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/mutator.json

- `kind`: json
- `size_bytes`: 334
- `line_count`: 7
- `sha256`: 737c806ca28eda312a4fe2a3fea8748ccf875f1cf3a0847e7d0d5ddac54d72ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=334 bytes; lines=7; markers=<none>; tail={ "case": "pair-pop-only-entry0", "mutant_sha256": "76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/pair-pop-only-entry0/mutator.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: e32d42fb51e25fe9a1c0a41189cc138df2f42b4664721234920fa6c86af12dc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=PASS mutation=pair-pop-only-entry0 sha256=76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 50031
- `line_count`: 1036
- `sha256`: ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=50031 bytes; lines=1036; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356903
- `line_count`: 34196
- `sha256`: f4284a4b6fa962dc2134f88a5cad510891986c49ab89eb48f22eb16cdc791362
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356903 bytes; lines=34196; markers=<none>; tail=, S_0x653a99be7bf0; %join; %free S_0x653a99be7bf0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x653a99d94c50_0, v0x653a99d95880_0, &PV<v0x653a99d946a0_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: 729abf8a7a67decca59925ba1544aa41468dbe57f762c68d3b9ab76a09b62282
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 9
- `sha256`: 928da65d0b64e177ead76be2fc561b1cc9f3516be2f3d5b88e0f033037a47c15
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=610 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=000c0000 expected=000e0000 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357619
- `line_count`: 34196
- `sha256`: 94ef05d3c946871d1ecdd3a7495fdfbf53911336e9f073ea30cde18cff625d29
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357619 bytes; lines=34196; markers=<none>; tail=, S_0x60c342a2a460; %join; %free S_0x60c342a2a460; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x60c342bd78c0_0, v0x60c342bd84f0_0, &PV<v0x60c342bd7310_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: ceb09b0d1dec59f3c13ee1435b513cbdd57947221fce471dfea18bf0e7a610e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 722
- `line_count`: 9
- `sha256`: e952e9a8022e7ed01b70b9129c8471d71b8aee22e19c3ae502b6bade637929ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=722 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=0000000000000000000000000000000000000000000800000004000000000000 expected=0000000000000000000000000000000000000000000800000004000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 342
- `line_count`: 7
- `sha256`: 97fc9592c7a04b44d30c1efad910408eb630e3aa86647cb20c7b2dbb1b1b3fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=342 bytes; lines=7; markers=<none>; tail={ "case": "regular-fire-dies-early-mask", "mutant_sha256": "ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/regular-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 115
- `line_count`: 1
- `sha256`: ef818dd13a8049e45ba7e8bffb031e318c51e731cdc80d32b869cc1ff46d3398
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=115 bytes; lines=1; PASS=2; tail=PASS mutation=regular-fire-dies-early-mask sha256=ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49844
- `line_count`: 1032
- `sha256`: 6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49844 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: e7275f454c77b77872f7a7b003c8fe77c22520dab08bf4a745d1339222050ee8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x5b1ca0cad110; %join; %free S_0x5b1ca0cad110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b1ca0e59a60_0, v0x5b1ca0e5a690_0, &PV<v0x5b1ca0e594b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 852d1894f2d4035c65fc7a417beb0bc4377b5085f1e4b1c693f7cb9f67da2747
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 11645
- `line_count`: 152
- `sha256`: a140896dbe53a53f76cc0c855c7e68f3d0c3539657b4353ffc4aec6f711596fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=11645 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: 776a318eff368270cfef2287e961521ea5701d8c49cf9c1645d4b3f40761f211
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x5b798d7079a0; %join; %free S_0x5b798d7079a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b798d8b4780_0, v0x5b798d8b53b0_0, &PV<v0x5b798d8b41d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: a5560b80144642e6f57c1664c62c5bf67caf71ea5eedffaab49291e1659c5ea0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 13213
- `line_count`: 152
- `sha256`: 2781541c402c74c05a22d786b8b71699026f7e19a0159601f878f30faf7389c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=13213 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: b0ba90d98797a594e876d42b33a9df54a9068540030da30291a82cc9304c26a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "reset-ignored", "mutant_sha256": "6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/reset-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: 364f934bdde255f9061aadcd36b05bf331df7867fca116a5a753e0e0b485eb95
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=reset-ignored sha256=6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375009
- `line_count`: 34884
- `sha256`: e2a8e6894928bad91aea58242ad58868d984eeb8883d4f161b9ac0e83447d1cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375009 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x56c6713f3ac0_0, 0, 1; %alloc S_0x56c67122f070; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x56c67122f070; %join; %free S_0x56c67122f070; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g1/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: 878ba0032f946a43d4e06077c047bcabd103d9d0e14445d18683cffcb7db1f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375725
- `line_count`: 34884
- `sha256`: f7bbb55e823ec5b25eaac85dceb099e2f1928ae988e0282227047c1eb7cb37d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375725 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x61887177e720_0, 0, 1; %alloc S_0x6188715b98e0; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x6188715b98e0; %join; %free S_0x6188715b98e0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g4/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: f87f4a6ecc086a0cab716185063b2f92ed2b1f5b695fb58fc61bab59bef82e25
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/assert-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34161
- `sha256`: e402dac765d18973f65bf2fbce291479f49c1b65e9f620ea219a3259cffecae0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x5f68464148c0_0, 0, 1; %alloc S_0x5f684626b200; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5f684626b200; %join; %free S_0x5f684626b200; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g1/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: 9b44a840bcc72b46fbe19bd7d1e191fdc19aa3ecac4daf2c0d647f610f318025
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34161
- `sha256`: bb2f3bc59782c77cf3d203958b0f0f29b1c288e6ce6d55591d47cf73dbe47ba6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x5b1d4780b5d0_0, 0, 1; %alloc S_0x5b1d47661a70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5b1d47661a70; %join; %free S_0x5b1d47661a70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g4/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: 6a7a4619d4566af84d75f598c6247bd8ad135cdac781bac4faa36f4521d4c85a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/profiles/release-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/rtl-source-binding.post.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/rtl-source-binding.pre.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: bf3575023ecb110548e22426e3633874dce60e89397fc3e29c167e4d4816b9e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: bf3575023ecb110548e22426e3633874dce60e89397fc3e29c167e4d4816b9e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/summary.json

- `kind`: json
- `size_bytes`: 104280
- `line_count`: 1312
- `sha256`: daa050c323d911545927c1f434e5ff2992a0d0ac574e7ff36b1fddbcc5d9a361
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 1}
- `summary`: json evidence; size=104280 bytes; lines=1312; PASS=1; tail=er-semantic-coverage/evidence/int-iq-producer-attempt-2/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v", "compile_log": { "path": ".github/task-runs/2026-07-30-rv64-v11f-int-iq-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-2/vvp.version

- `kind`: version
- `size_bytes`: 814
- `line_count`: 18
- `sha256`: c9010a85df9399c2adb11b59115cdc285ea6f0a399802944367c3813c6772a42
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=814 bytes; lines=18; markers=<none>; tail=Icarus Verilog runtime version 12.0 (stable) () Copyright (c) 2001-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free So...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/evidence-tool-unit.log

- `kind`: log
- `size_bytes`: 1564
- `line_count`: 13
- `sha256`: 8a688c1b7e1cd0bce25fc5df437d59f8d0a64aa837f7b5d63922461e24ad0df2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=1564 bytes; lines=13; markers=<none>; tail=test_assert_release_width_matrix_is_exact (npc.rv64.eval.ppa.tests.test_int_iq_producer_semantic_evidence.IntIqProducerEvidenceTests.test_assert_release_width_matrix_is_exact) ... ok test_carrier_lifetime_and_knownness_mutations_are_present (npc.rv64.eval.p...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/iverilog.version

- `kind`: version
- `size_bytes`: 3294
- `line_count`: 73
- `sha256`: f9199cc8658f4afcec3edeb93f29f23bb2aebf66d3eeb217cdc728aaa692f946
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=3294 bytes; lines=73; markers=<none>; tail=Icarus Verilog version 12.0 (stable) () Copyright (c) 2000-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software F...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356170
- `line_count`: 34164
- `sha256`: d0d9d523d2b96e14f0c9e56ff5fc2405de30fa28dfcaf56f68477ed7dcff37dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356170 bytes; lines=34164; markers=<none>; tail=ts, S_0x5a115508f760; %join; %free S_0x5a115508f760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a115523c460_0, v0x5a115523d090_0, &PV<v0x5a115523beb0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: 79260568feaff1d8f1a89501dbf5e3acdb20c3dcacc6eb52ec14442acb9c1038
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4712
- `line_count`: 62
- `sha256`: 587ddd594ab9b7d4b91755a675e55bc809da985a3c07b298ee508b3abe2decff
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 110, "PASS": 10}
- `summary`: log evidence; size=4712 bytes; lines=62; FAIL=110; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=14 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356886
- `line_count`: 34164
- `sha256`: d3f370642cb72233af328ed14e87023ddccd01a12ee1122652273af31a3c4847
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356886 bytes; lines=34164; markers=<none>; tail=ts, S_0x6014d0c60fd0; %join; %free S_0x6014d0c60fd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x6014d0e0e070_0, v0x6014d0e0eca0_0, &PV<v0x6014d0e0dac0_0, 0, 32>, v...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8642
- `line_count`: 31
- `sha256`: 36916d8d798a3f789ef7f1a9fe1807bdab5950c0082d357a14dbaaa7058089c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8642 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 8615
- `line_count`: 87
- `sha256`: 0faed97d6cbbad6906df58af68dbc4b2265cdcddfb9f6a26bcb827cae895b5b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 160, "PASS": 10}
- `summary`: log evidence; size=8615 bytes; lines=87; FAIL=160; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold PID[1] got=04 expected=34 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000018 expec...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 340
- `line_count`: 7
- `sha256`: 0f7071c9c8a33ba18acedff4fd14055960ca369b5bf266b9d6ac67ad7f895051
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=340 bytes; lines=7; markers=<none>; tail={ "case": "compaction-generation-zero", "mutant_sha256": "f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 113
- `line_count`: 1
- `sha256`: 3b0e86b7ef786dad1a19ade992cc17e12ae4988f887f6d398f9d5bcb122a224c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=113 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-generation-zero sha256=f91559400da7834bf62500fd8a8c7d01584bcf7598d010ff4237688050a10613

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49848
- `line_count`: 1032
- `sha256`: af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49848 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355766
- `line_count`: 34158
- `sha256`: 3900fb06aff9bd57ccf8d52c120360a404a1ecb35a1415254c270f89724cb4c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355766 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x592100b02250; %join; %free S_0x592100b02250; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x592100caebd0_0, v0x592100caf800_0, &PV<v0x592100cae620_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: 36cbcfaf93447a9d3e48653e05d3b36cbfe5bc700e9d1d6b54f315b58a0e63b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6834
- `line_count`: 93
- `sha256`: 32c794e9ce4a630640a09eb56717422aa8d659b9f4ca28a1c407db39f916f2d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=6834 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold raw PID unk...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356484
- `line_count`: 34158
- `sha256`: faae9ebb065f82cad9c6f812f1f91f42c2ac0a99e66b411c5f0713b5af20b8fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356484 bytes; lines=34158; markers=<none>; tail=clear_inputs, S_0x584e8f57dac0; %join; %free S_0x584e8f57dac0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x584e8f72a870_0, v0x584e8f72b4a0_0, &PV<v0x584e8f72a2c0_0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8069
- `line_count`: 30
- `sha256`: 8e8a0da9f94b1a58792bec7454056748008b516e7f4c2ae7b4d2f45fd935605f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8069 bytes; lines=30; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 8850
- `line_count`: 93
- `sha256`: ae229f412ee869269f6abe56d10a763ee093d7615b31f60b4238a50869d633e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 172, "PASS": 10}
- `summary`: log evidence; size=8850 bytes; lines=93; FAIL=172; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=0000000000000000000000000000000000000000000000000000000000000000 expected=0000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 330
- `line_count`: 7
- `sha256`: 6e19b1d2f44baedfcc2a9945d54707cd7b9397703b74fcacaeba91d807659f09
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=330 bytes; lines=7; markers=<none>; tail={ "case": "compaction-pid-x", "mutant_sha256": "af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ce...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 103
- `line_count`: 1
- `sha256`: d559f13b26fe5ffc23194b38c6e7a84d193552e81628e083a470da2439e60eeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-pid-x sha256=af3e6e257c5d34e8a37b30913e81c8901af3f360be39c9f1099b79658ecfacf3

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356093
- `line_count`: 34161
- `sha256`: 69c488e9dcf4c2391e56893ac99e17b7050602ace5a7e8ad5ed5ffb89085841d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356093 bytes; lines=34161; markers=<none>; tail=_0x6354165651f0; %join; %free S_0x6354165651f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x635416711bc0_0, v0x6354167127f0_0, &PV<v0x635416711610_0, 0, 32>, v0x635...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: 27060ca5263bd0585a940d4dfd3750bc57f467bb8f26a7e83b444cffbccd0a9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 1566
- `line_count`: 21
- `sha256`: b382c900af6a56b82fad16f1c6ce3983b06810a109bd57823240c3f1f000b0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1566 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=12 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=12 expected=13 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356809
- `line_count`: 34161
- `sha256`: d8b38be998007d03e80c58ca280fad50100edd98ea4ea1f1eac9387ddc283c67
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356809 bytes; lines=34161; markers=<none>; tail=_0x56f90cd87a60; %join; %free S_0x56f90cd87a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56f90cf34930_0, v0x56f90cf35560_0, &PV<v0x56f90cf34380_0, 0, 32>, v0x56f...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8802
- `line_count`: 31
- `sha256`: ec553c2bdef6e9ee0ccaf24aac80ca43eaeeea85bc17f9f84d5d51e8ae1d0572
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8802 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 1902
- `line_count`: 21
- `sha256`: 9e1d7b15d58addc12d62ff3948952732cefb87d4b615f8675f6e78ac7be0f919
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 28, "PASS": 10}
- `summary`: log evidence; size=1902 bytes; lines=21; FAIL=28; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[0] got=11 expected=32 [V11F-INT-IQ-ORACLE][FAIL] single fire plus replacements PID[1] got=32 expected=53 [V11F-INT-IQ-ORACLE][FA...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/mutator.json

- `kind`: json
- `size_bytes`: 345
- `line_count`: 7
- `sha256`: 74aaaf86435ce2cd4779b5d72b0b31edda382f225713ebfcca020923400892a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=345 bytes; lines=7; markers=<none>; tail={ "case": "compaction-uses-write-index-pid", "mutant_sha256": "94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/compaction-uses-write-index-pid/mutator.log

- `kind`: log
- `size_bytes`: 118
- `line_count`: 1
- `sha256`: 6032235f8ec24ef188339bf8b6a83e927a1e51ca6a22347c560ee2b09b6b8b17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=118 bytes; lines=1; PASS=2; tail=PASS mutation=compaction-uses-write-index-pid sha256=94affac70547c085f73ef0b68a98ec88c223a7e99e8677b00467ae429630242c

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356169
- `line_count`: 34164
- `sha256`: 22f24d94515de72eb2e4cec14f32bcbbceba90b5235096f67f5617e1bbbcc655
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356169 bytes; lines=34164; markers=<none>; tail=uts, S_0x5772c4bf3760; %join; %free S_0x5772c4bf3760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5772c4da0440_0, v0x5772c4da1070_0, &PV<v0x5772c4d9fe90_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 2fbba0710755e2c5da50f7df36a886e7e4be97907613782ab2f21fe2142972e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 4387
- `line_count`: 57
- `sha256`: c1d4c54f2bd981183242735721bbe60553f6a019f0a6014a792f1bea25bf6f2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 100, "PASS": 10}
- `summary`: log evidence; size=4387 bytes; lines=57; FAIL=100; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100008 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] READY-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356885
- `line_count`: 34164
- `sha256`: cbb1d9dc6d68af529653923c476313882c7b30ee90ba14756cafa43bcf8f2afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356885 bytes; lines=34164; markers=<none>; tail=uts, S_0x56d958ee6fd0; %join; %free S_0x56d958ee6fd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56d959094030_0, v0x56d959094c60_0, &PV<v0x56d959093a80_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: c10d3e109bf8df22a800b96b854aacfca7e6f79d818668e3a20dd712dad412fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 9291
- `line_count`: 83
- `sha256`: 64dfd48c4d980e417ba7d4adc52c339e4d94502deaaf2db3c7629289fb71756d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 152, "PASS": 10}
- `summary`: log evidence; size=9291 bytes; lines=83; FAIL=152; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[0] got=03 expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000008 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 8612d1610ab2e057f8fe0c8f2bda02934ffe76dad53b970848f2af30081bca38
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-generation-zero", "mutant_sha256": "f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: 8aa15918bcd50027498e550eea1675884808e8f21075aa4f3d19b7f988a941a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-generation-zero sha256=f5bcca5bc03564b77acbceadc126384c8a3977b0430020748307fa92f4e8ec81

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: 8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: da7471c0a2982eaa2048f8e50bd1c0c6c1232cdfaadb240b1af537b51cb140a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x64a7c5397320; %join; %free S_0x64a7c5397320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x64a7c5543db0_0, v0x64a7c55449e0_0, &PV<v0x64a7c5543800_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 7b791a4efcc935ebf2b245c71f63971a4d9af094776406b55e10a41ad1927fa9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6712
- `line_count`: 90
- `sha256`: d1dc63f100296b77ab4b4d27f0b141825da36721c5e528fb4db01379f873d952
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=6712 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00100000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=xx expected=13 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: 7edc9abe0de55610b5876072d764f2aa305275f962b28ef7b7120f9bf0d9ffd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x60ab68b1fb90; %join; %free S_0x60ab68b1fb90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x60ab68ccca90_0, v0x60ab68ccd6c0_0, &PV<v0x60ab68ccc4e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 45720fa7d69f17ae2ac24e7bcc6f2d3fe93276aeb5a7dc917f7acc56f1ed958d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9624
- `line_count`: 90
- `sha256`: 768292123b90aa255de63064d113db9aa6a0f62c170014d0e7806b0cdac3b132
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 166, "PASS": 10}
- `summary`: log evidence; size=9624 bytes; lines=90; FAIL=166; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=0 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000010000000000000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: 68b0215960fc6ec71831f71254645934d3ce243687e2e9cdcc4271efbd106df6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch0-pid-x", "mutant_sha256": "8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch0-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 0816f96adc8c90027ba9ba8cc5802d1681f96538c73a0be94a0f3e4389542c83
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch0-pid-x sha256=8025e7cb8cc77ae5557edd0251f813fefd462b2bc55c5af5d56c4722ad7ce3ba

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49849
- `line_count`: 1032
- `sha256`: a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49849 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356051
- `line_count`: 34161
- `sha256`: e1bbccbee185191b27ad7f99dfee226cc48bd295784053a8c8f4b83c373f46bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356051 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x5c2339ff7320; %join; %free S_0x5c2339ff7320; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5c233a1a3d90_0, v0x5c233a1a49c0_0, &PV<v0x5c233a1a37e0_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g1/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 98d80fb87bcf0c0c11a59597575e35f7a73ae5ad1abaf1e5603f7dbc74f0d57e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g1/sim.log

- `kind`: log
- `size_bytes`: 6648
- `line_count`: 89
- `sha256`: c94e11312bc94d676bebb73981fb9921e3d6f2425ee533bfea50d2469c8f26ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=6648 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=xx expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356769
- `line_count`: 34161
- `sha256`: 419dcd21fcd5eef3e3a50d39a0ea496c7b48cc874d77bc80152565f3421d148b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356769 bytes; lines=34161; markers=<none>; tail=.clear_inputs, S_0x629d827f1b90; %join; %free S_0x629d827f1b90; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x629d8299ea20_0, v0x629d8299f650_0, &PV<v0x629d8299e470_0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g4/compile.log

- `kind`: log
- `size_bytes`: 8290
- `line_count`: 31
- `sha256`: 89579828ce2f0f943fc1dd1bcfeab5d9f17add76635e0e49cd6d594e9e0ed870
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8290 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g4/sim.log

- `kind`: log
- `size_bytes`: 9448
- `line_count`: 89
- `sha256`: fcd5bad1349db3949cd559b4db3d67221f97a839a1c565d81091c741d5d78c33
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 164, "PASS": 10}
- `summary`: log evidence; size=9448 bytes; lines=89; FAIL=164; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new raw PID unknown idx=1 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=0000000000000000000000000000000000000000000000000010000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/mutator.json

- `kind`: json
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: b557037406e19a587d848ad87e6861f9437fa402124d314ebdf6f187078edfcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=329 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-pid-x", "mutant_sha256": "a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-pid-x/mutator.log

- `kind`: log
- `size_bytes`: 102
- `line_count`: 1
- `sha256`: 9a8392f2ce27f9156a11cdd9a44c12f8e4ceae0c495f5212a553f308408187e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=102 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-pid-x sha256=a92c0ceb6ad8847b4aff56371ef7812698ee43a61992358f1d67bd90938bff00

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356067
- `line_count`: 34161
- `sha256`: 8ad04d587b1e331a23318f032b65ade2bde8f910a60d7ea4f918d3f8f94dd5c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356067 bytes; lines=34161; markers=<none>; tail=puts, S_0x5d4e9064e1f0; %join; %free S_0x5d4e9064e1f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d4e907fab50_0, v0x5d4e907fb780_0, &PV<v0x5d4e907fa5a0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g1/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: aa406a8fbd0283c179a957e319e6318842e78209491ff717e127a3954e29f9ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g1/sim.log

- `kind`: log
- `size_bytes`: 6536
- `line_count`: 85
- `sha256`: a15fa76fa942536fac5603f140ac9207cd18e1f3def72e20cea9661f73ba92e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=6536 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00080000 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=13 expected=14 [V11F-INT-IQ-ORACLE][FAIL] dual b...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356783
- `line_count`: 34161
- `sha256`: 798e24cbc24b937dfc01fc4441d643cbe42900925b808b3a024cb5cb41874072
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356783 bytes; lines=34161; markers=<none>; tail=puts, S_0x5b59a800da60; %join; %free S_0x5b59a800da60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b59a81ba8b0_0, v0x5b59a81bb4e0_0, &PV<v0x5b59a81ba300_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g4/compile.log

- `kind`: log
- `size_bytes`: 8578
- `line_count`: 31
- `sha256`: bc1bea56c21c083744623a76ce639182bf5b5800219d7f53e74df20c71c96de6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8578 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g4/sim.log

- `kind`: log
- `size_bytes`: 9336
- `line_count`: 85
- `sha256`: 2434da3fc61fa8297b25fd979b4825207ed9add1044064e4e2f6c97488e6d794
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 156, "PASS": 10}
- `summary`: log evidence; size=9336 bytes; lines=85; FAIL=156; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new PID[1] got=13 expected=34 [V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000080000 expected=000000000000000000000000000000000000000000000000001000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/mutator.json

- `kind`: json
- `size_bytes`: 338
- `line_count`: 7
- `sha256`: 1f424896ea875728175752d1afc03a6fa0d7f3cfb3a627995e5e19c48c25aa28
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=338 bytes; lines=7; markers=<none>; tail={ "case": "dispatch1-uses-lane0-pid", "mutant_sha256": "0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/dispatch1-uses-lane0-pid/mutator.log

- `kind`: log
- `size_bytes`: 111
- `line_count`: 1
- `sha256`: bb534235ae9256560ed541ebd89b225f3aebbdc62f03fe85f73e8d9dc833637f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=111 bytes; lines=1; PASS=2; tail=PASS mutation=dispatch1-uses-lane0-pid sha256=0902fa8f574c95ecd75840521ea650d4e7dc9f965e5291a3eaea8b72785aa00e

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49840
- `line_count`: 1032
- `sha256`: f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49840 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: 1d31ca1751aa9394ca298d8eac7360ceee00e76a1124bc0f5fff923e92d8724a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x626345a34110; %join; %free S_0x626345a34110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x626345be0a60_0, v0x626345be1690_0, &PV<v0x626345be04b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 8c9fd43ae22069b122bb515c44416534f06bd72b79a5d338c481d778b1c2aa96
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 1708
- `line_count`: 24
- `sha256`: 2796ceb605601b6ae45732ba5b7fdce648508638d51c7215dfb9c083a6a812d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=1708 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: 49d9ca59edd7e1f4c3ff26022350467c812f3971a9a47050bbc6cecf8690e5c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x64074b7299a0; %join; %free S_0x64074b7299a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x64074b8d6780_0, v0x64074b8d73b0_0, &PV<v0x64074b8d61d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 4a85e7708c5bce6746e64cff879e9c13a9116a52e107702a8f7fc4bdf86f48ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 2044
- `line_count`: 24
- `sha256`: ab04c772767add3b9fab8f653fc1812d27370a3aea370aa35359028bff1277cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 34, "PASS": 10}
- `summary`: log evidence; size=2044 bytes; lines=24; FAIL=34; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] flush edge-new count got...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: c1485e96a39ddc53cf40e40bf7d9bd17138a6c8a3bd6b7027d5996995a501f1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "flush-ignored", "mutant_sha256": "f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/flush-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: c9aec4167a6723841275cfb8f3ec6305f203e71a53d094962a4522a4b9680c17
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=flush-ignored sha256=f0ece84f69693af1c907bcdc0bd74803c50eeb765b53844ad991d21f5e860632

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355756
- `line_count`: 34149
- `sha256`: 9208b575df0dc9aa8a8cb138ff5144255a7e6e66bff88c528fb37366edd7c1e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355756 bytes; lines=34149; markers=<none>; tail=nputs, S_0x59326e5452b0; %join; %free S_0x59326e5452b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x59326e6f1a30_0, v0x59326e6f2660_0, &PV<v0x59326e6f1480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: c5435798e74254d5b5216fde9d87339763399aed4a89325a956c6b3bef0dc280
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 2631
- `line_count`: 35
- `sha256`: b30d02788dc8601c99f1522e8169c5a8b9b71068a1928d4ec680649a70c59a3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=2631 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356472
- `line_count`: 34149
- `sha256`: 160e8ef3c5a2f5e68b1989659240111f25c85a9fc373b84a3349d555af44c87d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356472 bytes; lines=34149; markers=<none>; tail=nputs, S_0x568c195d7b20; %join; %free S_0x568c195d7b20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x568c197846f0_0, v0x568c19785320_0, &PV<v0x568c19784140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 38169fa1f5ec789aef999bd7618794e543654a4cf412974cf7c5657270a6d3b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 3079
- `line_count`: 35
- `sha256`: 3009bd3dea6af60c3c3f2f2dd2225af4f79fffd10f83fb8dd064a089dc42b514
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 56, "PASS": 10}
- `summary`: log evidence; size=3079 bytes; lines=35; FAIL=56; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new count got=2 expected=1 [V11F-INT-IQ-ORACLE][FAIL] overtake death edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] overtake de...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 6f7b26ac779c1bf9c44addeacf5453181d64888e729b6747d5958f0a03df602e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-fire-not-removed", "mutant_sha256": "c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: d730e852f54888b5cbaa754c6f8a2eddaf5787deee1f381da83846e4033678e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-fire-not-removed sha256=c2fc6aca04c1a03d8c36bc4a569b9f5c5c9a78f9fdf1f7688fafd598cdd2a59d

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: 70d823d7232cb1cf6f1672008ef9a1992eccff46724e6efcc9a5a1e6837fac74
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x60759ba54760; %join; %free S_0x60759ba54760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x60759bc01d90_0, v0x60759bc029c0_0, &PV<v0x60759bc017e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: bea56f58f95f818393be1c24fd4908b70414a64e4adc3101f6886bc073466ccd
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 806
- `line_count`: 12
- `sha256`: ecf09df0b8b679d485050007252c3137a898f4a8a6a7ad91a8c34de210b4bdc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=806 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID got=01 expected=11 [V11F-INT-IQ-ORACLE][FAIL] post-compaction issue0 is...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: 993d0de4953eabbfc12b7e2d367044ee79f45fbe102730a71b3d8268706166d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x58b577aebfd0; %join; %free S_0x58b577aebfd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x58b577c99910_0, v0x58b577c9a540_0, &PV<v0x58b577c99360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 7f8d0c5d9479f146f10abb0dd594a3d087891fd1353483d4d7e1a2d2c36bac6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 13
- `sha256`: 18ee3ccb7576d967b96fdd7f0234f7e2e319125f4665e015f736f86136c254f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=877 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue0 PID got=03 expected=13 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 PID got=06 expected=46 [V11F-INT-IQ-ORACLE][FAIL] single fire issue0 PID...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: ec65ccacfa43aba5bd53516fb28f55b703196f9793bc7a03dbc49aed4a3c38f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue0-generation-zero", "mutant_sha256": "90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 7629fd03fa15cfd2ab955a4bde8eea5c3d6cd7edf1554b6d6bb6a182365f06a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-generation-zero sha256=90817277a8047a9c2ed5a0c2175afbf55b7b93aa6f0b208f50d5e6ca2b9c8583

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49847
- `line_count`: 1032
- `sha256`: eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49847 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356086
- `line_count`: 34161
- `sha256`: c3ed3038af093d5b40d083dffabf2870f578412e2ce966565a422719e7549ca8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356086 bytes; lines=34161; markers=<none>; tail=nputs, S_0x573ed49aa2a0; %join; %free S_0x573ed49aa2a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x573ed4b56ea0_0, v0x573ed4b57ad0_0, &PV<v0x573ed4b568f0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 2b3ae545ed137d34b0e5978104167762278bae78d09700a27bb9e6519d896478
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: 7bae1d941fce32967a137c5f925e870c1468d4537a4e3ebcc43229c8dd01292a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356802
- `line_count`: 34161
- `sha256`: c6c8e7993897d38661a3cf7f2126438fff08aec7da1cdcafd4281121957673a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356802 bytes; lines=34161; markers=<none>; tail=nputs, S_0x609b88500b10; %join; %free S_0x609b88500b10; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x609b886adb70_0, v0x609b886ae7a0_0, &PV<v0x609b886ad5c0_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 4a4bcaa31217b43d0f6531535efe03abb961c82bb9967e8e4e42f605175bd69a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 9
- `sha256`: db1568600ba65ed2d49101c916a7b5cc8d131b10e4dcd8eb15e3f5627d8a4b96
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=601 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] overtake idx1 issue0 raw index got=5 expected=6 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 read...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 8eccc824b19a2f435139b8f44fd680774af3be945da0b71c6b0d4044656a0d4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue0-raw-index-entry0", "mutant_sha256": "eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue0-raw-index-entry0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 60ab23ada23fe2b9fa3c58f2c9cc9e7f0c9dc2d81c4b6584b71f38b90954ecce
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue0-raw-index-entry0 sha256=eb7ebdf427a8acb4cc96923c8d43cb31cbb6bf8f440557f8233d141fc210e269

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49859
- `line_count`: 1032
- `sha256`: 548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49859 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355759
- `line_count`: 34149
- `sha256`: 2c928c6ca0648b504ed29ea06f4b8927152a60c9f4b25ec22bc62bcbdab69c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355759 bytes; lines=34149; markers=<none>; tail=nputs, S_0x56c0b14212b0; %join; %free S_0x56c0b14212b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56c0b15cda30_0, v0x56c0b15ce660_0, &PV<v0x56c0b15cd480_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 354cde3de90e997f9eedf4620bbeb891334e83b7950002e4659064bb62dde3ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g1/sim.log

- `kind`: log
- `size_bytes`: 893
- `line_count`: 13
- `sha256`: 68f5e5ca7c1cc7df51d282eaa341a29974ac68bb657c0706fe4ad44e9a43b7c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=893 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=13 expected=04 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356475
- `line_count`: 34149
- `sha256`: fe72adf2ba891b98debe0912b03c1da82516952f2cfd379090ae946fd7f9ac1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356475 bytes; lines=34149; markers=<none>; tail=nputs, S_0x56dcb8ad9b20; %join; %free S_0x56dcb8ad9b20; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56dcb8c866f0_0, v0x56dcb8c87320_0, &PV<v0x56dcb8c86140_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 791fc92685a662db7ca287594e4a053d2c69f311a45352285ecbcfe97a20f25e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g4/sim.log

- `kind`: log
- `size_bytes`: 1005
- `line_count`: 13
- `sha256`: 0f27dbd42e1771bb55f5f23deb8d724d40af42fa994dc9812ea2661f68648ace
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1005 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PID[0] got=53 expected=84 [V11F-INT-IQ-ORACLE][FAIL] dual fire edge-new PI...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 4a17a89fbba54d442f777dcd25af8cb877b42ab3ef8c361ea454ab1cfd865aa7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-fire-not-removed", "mutant_sha256": "548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-fire-not-removed/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: 69abd44948e3a9375210907acfbf7d48f0365215a5f084bc62b5ac0bf2bf6335
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-fire-not-removed sha256=548af9801f5d709f6cde03043d6c9a6b55e040d2fb9ad048ba77b122aee69b12

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49907
- `line_count`: 1032
- `sha256`: 7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49907 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356324
- `line_count`: 34165
- `sha256`: 1fe2b1b5111e575e2bc9b937a47f40f563f7dccf623d7d93d95ae7fc0733dde2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356324 bytes; lines=34165; markers=<none>; tail=inputs, S_0x611051316760; %join; %free S_0x611051316760; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x6110514c3d90_0, v0x6110514c49c0_0, &PV<v0x6110514c37e0_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g1/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: f0fa1f3c46efca34b69c6d067172cde653cc4d7c67483455a4fb6c9b54c44ed7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g1/sim.log

- `kind`: log
- `size_bytes`: 753
- `line_count`: 11
- `sha256`: dfa5799b5c34c1b9dd5e27715de1488280d275a2cdfb42e65a6b5d3da3fa1775
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=753 bytes; lines=11; FAIL=8; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=14 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=12 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357034
- `line_count`: 34165
- `sha256`: e02cdd43ef4b1445e18b3e01650fa95a7e93753c204bd85835299c391c3ff9b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357034 bytes; lines=34165; markers=<none>; tail=inputs, S_0x5dfc22b84fd0; %join; %free S_0x5dfc22b84fd0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5dfc22d32910_0, v0x5dfc22d33540_0, &PV<v0x5dfc22d32360_0, 0, 32...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g4/compile.log

- `kind`: log
- `size_bytes`: 8514
- `line_count`: 31
- `sha256`: 83f2ec6bc9a962d5fac04bff09f5a621b317e62e6232a724cbd358845087ac55
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8514 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g4/sim.log

- `kind`: log
- `size_bytes`: 816
- `line_count`: 12
- `sha256`: d5dc84d67de5acb0854ae3b0d5dc0002428285317f8ea28a95b0836b91b7987f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=816 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 PID got=04 expected=34 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 PID got=02 expected=32 [V11F-INT-IQ-ORACLE][FAIL] post-compaction...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/mutator.json

- `kind`: json
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: f40c4f4f5d87315d92465080edece62fedc6a5732cca33571022fb7506de8f99
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=336 bytes; lines=7; markers=<none>; tail={ "case": "issue1-generation-zero", "mutant_sha256": "7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288899...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-generation-zero/mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: 76d32b3a68d1b90a559d01beab58c2dc0b71adde9486b0b040a1107b9efb5f30
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-generation-zero sha256=7e3cfa2cf66a408091cc474a7de2a3c8ab968b736888304a3ad9fb1717491593

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49851
- `line_count`: 1032
- `sha256`: 75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49851 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356085
- `line_count`: 34161
- `sha256`: 9c92b34d44588967df06f6077e9ca4a604966616eaaeffb5e4e0d8ce139ff00a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356085 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5c8be2c121f0; %join; %free S_0x5c8be2c121f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5c8be2dbebf0_0, v0x5c8be2dbf820_0, &PV<v0x5c8be2dbe640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 9f493923f5598207729181925b1586ed82462d7f2c8839b02f5c74e1a8eb623a
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g1/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 34b5a22b5fb64bb05a3897ab9310bada5a2c9382ec53b2ae9788c23056fb3f06
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356801
- `line_count`: 34161
- `sha256`: 6c1bd2875aaa07dd8d677bde4acebca208baf317e8c2fb637f1297de4c732337
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356801 bytes; lines=34161; markers=<none>; tail=nputs, S_0x5b73e0cc3a60; %join; %free S_0x5b73e0cc3a60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b73e0e70920_0, v0x5b73e0e71550_0, &PV<v0x5b73e0e70370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: b3fea96ce98ebbb2a62fbd5622423505c45669054488a0e011bce4331be88405
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g4/sim.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 12
- `sha256`: 1ee68483112138b5ccdd5a48cd02662d4aaae79f3e04a66ccff20f551612cd90
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=828 bytes; lines=12; FAIL=10; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth issue1 raw index got=3 expected=4 [V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire held peer issue1 raw index got=1 expected=2 [V11F-INT-IQ-ORACLE][FAIL] post-co...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: c4af6c9e345974efa986ad6974b591f2a354ce0c157aeee247a64fa767244171
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "issue1-raw-index-issue0", "mutant_sha256": "75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: bd4a8404a3b21f1c7ece80e7618267f2aae5e35f1450cc5fb8d0047b81946f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=issue1-raw-index-issue0 sha256=75279b41cb94eec2a5cd05e4024d7a136a76500271372b71968ae4e6251f2312

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49853
- `line_count`: 1032
- `sha256`: 36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49853 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356147
- `line_count`: 34165
- `sha256`: 9af686779786e61ff000ecb9b62eac51a003edf639effb7496e5dbf7d472555f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356147 bytes; lines=34165; markers=<none>; tail=nputs, S_0x5a8583db71f0; %join; %free S_0x5a8583db71f0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5a8583f63bf0_0, v0x5a8583f64820_0, &PV<v0x5a8583f63640_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g1/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: 22becad9922f3f937401fc1ae18a65bebec6a6a7e2c062038339b774b6e9e675
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g1/sim.log

- `kind`: log
- `size_bytes`: 975
- `line_count`: 14
- `sha256`: 27f7ab2148a8f8e4d9cedc3f2851e8da2ee3b7b70fc7ea4f8b46cc7bcbdc6e76
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=975 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356863
- `line_count`: 34165
- `sha256`: b4dbede67c2fd6d410062b8d8e5cd502e8179c74aeb5480ce895e430b234bc4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356863 bytes; lines=34165; markers=<none>; tail=nputs, S_0x5b8a7792da60; %join; %free S_0x5b8a7792da60; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5b8a77ada920_0, v0x5b8a77adb550_0, &PV<v0x5b8a77ada370_0, 0, 32>...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g4/compile.log

- `kind`: log
- `size_bytes`: 8546
- `line_count`: 31
- `sha256`: e74b6a23540fa4060169d114613f086c433b1453a64972391445135d62c3a80b
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8546 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g4/sim.log

- `kind`: log
- `size_bytes`: 1199
- `line_count`: 14
- `sha256`: ec97ae2f6a9163b3b7a0b732c47b16f5b0f86541cfc3010ac519957cbb0a2920
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 14, "PASS": 10}
- `summary`: log evidence; size=1199 bytes; lines=14; FAIL=14; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-ORACLE][FAIL] selective kill edge-new...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/mutator.json

- `kind`: json
- `size_bytes`: 337
- `line_count`: 7
- `sha256`: 893a577bb69cf3c2e4246b7253126da141da14b4e0a525c7ce1b708b215ae967
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=337 bytes; lines=7; markers=<none>; tail={ "case": "kill-boundary-inclusive", "mutant_sha256": "36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf4928889...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/kill-boundary-inclusive/mutator.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: fbe99edf97f38d53d0a548df699c4612e445148beed2287cda1e7bfe71221078
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=PASS mutation=kill-boundary-inclusive sha256=36b10a4ed54243f6ba43c64a4a5780978b80d9aa75c819e6f5d4315384f51867

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49868
- `line_count`: 1032
- `sha256`: 2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49868 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356102
- `line_count`: 34162
- `sha256`: 3f6b121644be0c0f95c54a73b8eeeeb3a75b1150b0c7c899304c80410a6fb1bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356102 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x5821da74a400; %join; %free S_0x5821da74a400; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5821da8f6ee0_0, v0x5821da8f7b10_0, &PV<v0x5821da8f6930_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g1/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: 57b73de38c4f839ab37997cc8887cd0373a4488ee1e10b61f089a8bb174d6874
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g1/sim.log

- `kind`: log
- `size_bytes`: 2472
- `line_count`: 31
- `sha256`: 25ac5432071a2f02e8a4bb428ba75022a1fe581a8f243012f2bd021dd8e99821
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 48, "PASS": 10}
- `summary`: log evidence; size=2472 bytes; lines=31; FAIL=48; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE][FAIL] recover hold mask got=00000018 expected=00180000 [V11F-INT-IQ-ORACLE]...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356818
- `line_count`: 34162
- `sha256`: e438a0aca86460ac8ad10c6e8905f04340a68a0a92aa357fe97444370691c597
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356818 bytes; lines=34162; markers=<none>; tail=ear_inputs, S_0x5d4089659c70; %join; %free S_0x5d4089659c70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5d4089806be0_0, v0x5d4089807810_0, &PV<v0x5d4089806630_0, 0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g4/compile.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 31
- `sha256`: d654ffe3fca77ca96124fb08b9a55d74a280c37aec69da965c01907519ea39b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g4/sim.log

- `kind`: log
- `size_bytes`: 5644
- `line_count`: 34
- `sha256`: 613744e04db250a7370516678e1ff256a4928409ee75b9b87825f408c8439035
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 54, "PASS": 10}
- `summary`: log evidence; size=5644 bytes; lines=34; FAIL=54; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dual birth edge-new mask got=0000000000000000000000000000000000000000000000000000000000000018 expected=0000000000000000000000000000000000000000000000000010000000080000 [V11F-INT-IQ-ORACLE][FAIL] READY-low hold mask got=00000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/mutator.json

- `kind`: json
- `size_bytes`: 332
- `line_count`: 7
- `sha256`: 595050c75bd696f3d1cb8221c9cf98c6913daf28b1be779ea2d8c4e4d4c553d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=332 bytes; lines=7; markers=<none>; tail={ "case": "mask-raw-rob-index", "mutant_sha256": "2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/mask-raw-rob-index/mutator.log

- `kind`: log
- `size_bytes`: 105
- `line_count`: 1
- `sha256`: f7b11cd8e1d5a618361ddf5b805ccc60696a036dcb10503889534fb0ac88d9af
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=105 bytes; lines=1; PASS=2; tail=PASS mutation=mask-raw-rob-index sha256=2d0905a24d9472aefc6b50de58e33c4da77c56c7b732eca67efa01657cfc1edb

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49941
- `line_count`: 1034
- `sha256`: a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49941 bytes; lines=1034; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356586
- `line_count`: 34184
- `sha256`: cc581b845a24ea38da31d7662ce22999853e60dd079a8825dd3d642646b051bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356586 bytes; lines=34184; markers=<none>; tail=uts, S_0x63bc16520670; %join; %free S_0x63bc16520670; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x63bc166cd300_0, v0x63bc166cdf30_0, &PV<v0x63bc166ccd50_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 73f0cffd3f2dd339f73f030310f87c596098b0df4345a9c7f5361fc916f81687
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 9
- `sha256`: 708e3361c5efd9da0f9ea2a805d4366835b0b31df2ea2efc8f795973cea2aa45
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=615 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000 expected=00400080 [V11F-INT-IQ-PAIR-DEATH...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357302
- `line_count`: 34184
- `sha256`: cdeb395d8d409424a2285d4c42f3bf1c4024e9dfa75011d8aed8de6edc473d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357302 bytes; lines=34184; markers=<none>; tail=uts, S_0x61cb722d6ee0; %join; %free S_0x61cb722d6ee0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x61cb72483f90_0, v0x61cb72484bc0_0, &PV<v0x61cb724839e0_0, 0, 32>,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8610
- `line_count`: 31
- `sha256`: 1ac06c667197b895783edc091579b471ad9103d04ce41933f7752e71f7313bbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8610 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 727
- `line_count`: 9
- `sha256`: 72a6f1f87b2419a24f09d0938eb7a074554c28372c5465a9a2748f30ded7eed3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=727 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 edge-old mask got=00000000000000000000000000000000000000000000000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 339
- `line_count`: 7
- `sha256`: 4daf051589954571406bdb22ba9ac2092b5cc925b950b10e8738e7f33a45e72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=339 bytes; lines=7; markers=<none>; tail={ "case": "pair-fire-dies-early-mask", "mutant_sha256": "a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49288...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: bc6e07f1914ee903ea47aca0aed0a5a526b73ff8f181254e54e0bccdb0cab2ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=PASS mutation=pair-fire-dies-early-mask sha256=a96c542b8a0a6436d7a4f18b5a8cd6fbb36c4d4808c37eb06b7742b31e694787

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49829
- `line_count`: 1032
- `sha256`: 76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49829 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355963
- `line_count`: 34155
- `sha256`: bf44468de5c0acc5a3534290d70d51c6677b6f436b74aee19a5ab76dc05c4f0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355963 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x56d1f6b4a040; %join; %free S_0x56d1f6b4a040; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56d1f6cf6860_0, v0x56d1f6cf7490_0, &PV<v0x56d1f6cf62b0_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g1/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: cf78c38e9c65ed67e9bb004d07642a90d1a03b4e61cdfa56546459b10fb60b16
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g1/sim.log

- `kind`: log
- `size_bytes`: 943
- `line_count`: 13
- `sha256`: 663e77fc55d6bc02d0811bb7211f54b6e72be9952a19ac81feb49560c15ec2f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=943 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356679
- `line_count`: 34155
- `sha256`: 6f8a64cd3a0a212186a46dac4bd65067ec742c30ddf8d3476ec5391d1031cf70
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356679 bytes; lines=34155; markers=<none>; tail=r_inputs, S_0x5618035718b0; %join; %free S_0x5618035718b0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x56180371e530_0, v0x56180371f160_0, &PV<v0x56180371df80_0, 0,...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g4/compile.log

- `kind`: log
- `size_bytes`: 8450
- `line_count`: 31
- `sha256`: 7d531fcdd21c854e3b54a4d71127e87641bd102795dba4d4d5ba9e309a4de4ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8450 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g4/sim.log

- `kind`: log
- `size_bytes`: 1055
- `line_count`: 13
- `sha256`: 2652d2e9dcfefc4ff66d2cf2b6fcd3a25db4213efb6af0e4abbe4efe76cd99ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=1055 bytes; lines=13; FAIL=12; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-ORACLE][FAIL] memory pair pop2 plus append count got=3 expected=2 [V11F-INT-IQ-ORACLE][FAIL] memory...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/mutator.json

- `kind`: json
- `size_bytes`: 334
- `line_count`: 7
- `sha256`: 737c806ca28eda312a4fe2a3fea8748ccf875f1cf3a0847e7d0d5ddac54d72ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=334 bytes; lines=7; markers=<none>; tail={ "case": "pair-pop-only-entry0", "mutant_sha256": "76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/pair-pop-only-entry0/mutator.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: e32d42fb51e25fe9a1c0a41189cc138df2f42b4664721234920fa6c86af12dc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=PASS mutation=pair-pop-only-entry0 sha256=76424d00e1cf9554c675c08efffaa85210e2dc8d35e2dffdc704e92ae937e222

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 50031
- `line_count`: 1036
- `sha256`: ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=50031 bytes; lines=1036; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356903
- `line_count`: 34196
- `sha256`: 4da101f5e59abdc38b418614dc9b9c28f5fa2bb7c77d09b0a8b787945852bdc5
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356903 bytes; lines=34196; markers=<none>; tail=, S_0x62c7b6a3dbf0; %join; %free S_0x62c7b6a3dbf0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x62c7b6beac50_0, v0x62c7b6beb880_0, &PV<v0x62c7b6bea6a0_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g1/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: 78b1f4da21a1b8bd16a1d3d6314dfa9a6bf0762f0505d4a597641c6e9604f847
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g1/sim.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 9
- `sha256`: 928da65d0b64e177ead76be2fc561b1cc9f3516be2f3d5b88e0f033037a47c15
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=610 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=000c0000 expected=000e0000 [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1357619
- `line_count`: 34196
- `sha256`: fac1f1c4cac004629349b6ea13168c709facdcf9d12cf5c3713a980963a2ead4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1357619 bytes; lines=34196; markers=<none>; tail=, S_0x57d9ab64a460; %join; %free S_0x57d9ab64a460; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x57d9ab7f78c0_0, v0x57d9ab7f84f0_0, &PV<v0x57d9ab7f7310_0, 0, 32>, v0x...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g4/compile.log

- `kind`: log
- `size_bytes`: 8706
- `line_count`: 31
- `sha256`: 319ab3755f3b03a8a956d3b08c5c6e535a7fd87605f1fd09ea7a6f7eac73a43d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8706 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g4/sim.log

- `kind`: log
- `size_bytes`: 722
- `line_count`: 9
- `sha256`: e952e9a8022e7ed01b70b9129c8471d71b8aee22e19c3ae502b6bade637929ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=722 bytes; lines=9; FAIL=4; PASS=10; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ORACLE][FAIL] single fire edge-old mask got=0000000000000000000000000000000000000000000800000004000000000000 expected=0000000000000000000000000000000000000000000800000004000000...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/mutator.json

- `kind`: json
- `size_bytes`: 342
- `line_count`: 7
- `sha256`: 97fc9592c7a04b44d30c1efad910408eb630e3aa86647cb20c7b2dbb1b1b3fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=342 bytes; lines=7; markers=<none>; tail={ "case": "regular-fire-dies-early-mask", "mutant_sha256": "ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf49...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/regular-fire-dies-early-mask/mutator.log

- `kind`: log
- `size_bytes`: 115
- `line_count`: 1
- `sha256`: ef818dd13a8049e45ba7e8bffb031e318c51e731cdc80d32b869cc1ff46d3398
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=115 bytes; lines=1; PASS=2; tail=PASS mutation=regular-fire-dies-early-mask sha256=ca8fad3bb02507a59cfdb0e2676cb5ce307bc11ec7cedb0feaaad17739887ee8

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/OooIntIssueQueue.v

- `kind`: v
- `size_bytes`: 49844
- `line_count`: 1032
- `sha256`: 6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: v evidence; size=49844 bytes; lines=1032; markers=<none>; tail=`include "define.v" // 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作： // 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。 // 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入 // 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BY...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34156
- `sha256`: 7ab4279e79a017d4c807c90dbe45ef7cbf68be0069220bcbbcdfdb9ee5f991d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x623c1897e110; %join; %free S_0x623c1897e110; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x623c18b2aa60_0, v0x623c18b2b690_0, &PV<v0x623c18b2a4b0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g1/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: 60e70c95bf30a8f13edeae84412dd4e732d40252e5493182f776ae427c8e2034
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g1/sim.log

- `kind`: log
- `size_bytes`: 11645
- `line_count`: 152
- `sha256`: a140896dbe53a53f76cc0c855c7e68f3d0c3539657b4353ffc4aec6f711596fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=11645 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34156
- `sha256`: 60cbcf0b54df6c480c6621d5b3a3d1ae41104ec1520a96a47da65a5f72ba3d3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34156; markers=<none>; tail=ue.clear_inputs, S_0x5cd4cddcd9a0; %join; %free S_0x5cd4cddcd9a0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}", v0x5cd4cdf7a780_0, v0x5cd4cdf7b3b0_0, &PV<v0x5cd4cdf7a1d0...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g4/compile.log

- `kind`: log
- `size_bytes`: 8226
- `line_count`: 31
- `sha256`: fd27fe5c35d9372b8db20b88a24fd47b6ea44e4c4ac7191cb8746d8da4ac576d
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=8226 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g4/sim.log

- `kind`: log
- `size_bytes`: 13213
- `line_count`: 152
- `sha256`: 2781541c402c74c05a22d786b8b71699026f7e19a0159601f878f30faf7389c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"FAIL": 290, "PASS": 10}
- `summary`: log evidence; size=13213 bytes; lines=152; FAIL=290; PASS=10; tail=[V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new count got=8 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[0] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset edge-new valid[1] got=1 expected=0 [V11F-INT-IQ-ORACLE][FAIL] dirty reset...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/mutator.json

- `kind`: json
- `size_bytes`: 327
- `line_count`: 7
- `sha256`: b0ba90d98797a594e876d42b33a9df54a9068540030da30291a82cc9304c26a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=327 bytes; lines=7; markers=<none>; tail={ "case": "reset-ignored", "mutant_sha256": "6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210", "production_path": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "production_sha256": "d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/reset-ignored/mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: 364f934bdde255f9061aadcd36b05bf331df7867fca116a5a753e0e0b485eb95
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=PASS mutation=reset-ignored sha256=6391ebe6b0a48e96476879dab7b1e437bcf559f1fa311f13b28f86a78060e210

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375009
- `line_count`: 34884
- `sha256`: 55406150f27fd2382c944789bb44b29201423957a74e627aaee1fb70c03a0eb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375009 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x599f5f34fac0_0, 0, 1; %alloc S_0x599f5f18b070; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x599f5f18b070; %join; %free S_0x599f5f18b070; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g1/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: 0fd604cd582a4ddf5f0e4a33ca38f50e71e9bf3ae841ef384c4eb689342b72d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375725
- `line_count`: 34884
- `sha256`: 3de267149d9b26bf0aa8545e6d29b48bfeb13ce658e5e8aff288f3b184993563
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375725 bytes; lines=34884; markers=<none>; tail=1; %store/vec4 v0x5a552075f720_0, 0, 1; %alloc S_0x5a552059a8e0; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5a552059a8e0; %join; %free S_0x5a552059a8e0; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g4/compile.log

- `kind`: log
- `size_bytes`: 4914
- `line_count`: 31
- `sha256`: ccba75ad884a665ceece98b5bc42743682c1eb9007ba59491838e43b3933ac60
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4914 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_que...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/assert-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g1/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1355968
- `line_count`: 34161
- `sha256`: efe681d328d80ee812e99c4bc16f6504948246f4cf9f0c56abcf2755a1aa52f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1355968 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x639c42fe68c0_0, 0, 1; %alloc S_0x639c42e3d200; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x639c42e3d200; %join; %free S_0x639c42e3d200; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g1/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: 618b46095f3d4a0a722c225d55a10f31d1a09a90aa5e39e85f0e06ef16a99b1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=1 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g1/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g1/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: d1ea06435c610dd5031d3496d3c8290c6dce4da4ffd1b89633f2ebb37e0b2582
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=1 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=1 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=1 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=1 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g1/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g4/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1356684
- `line_count`: 34161
- `sha256`: 31f7c65277853744da1a05817f5798d5e250819a608ab4ad82ea4b4af21f6e7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1356684 bytes; lines=34161; markers=<none>; tail=1; %store/vec4 v0x611eb28295d0_0, 0, 1; %alloc S_0x611eb267fa70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x611eb267fa70; %join; %free S_0x611eb267fa70; %delay 1, 0; %vpi_call/w 3 2535 "$display", "[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g4/compile.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 31
- `sha256`: 012a007fd6083236f83f17ff3851c9a0f4619cbc171078fa249755e940b0a9bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4902 bytes; lines=31; markers=<none>; tail=[V11F-COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_PRODUCER_GEN_W=4 -s tb_ooo_int_issue_queue -o /home/l...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g4/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g4/sim.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 7
- `sha256`: 8406cfdcd3d6073ed0f209d83dbf68dd5d7f6e87b1c9be64eab5fe23dec8851f
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=478 bytes; lines=7; PASS=12; tail=[V11F-INT-IQ-BIRTH-HOLD] GEN_W=4 dual/full/ready/recover/reset PASS [V11F-INT-IQ-ISSUE-COMPACTION] GEN_W=4 overtake/single/dual/replacement PASS [V11F-INT-IQ-PAIR-DEATH] GEN_W=4 ready-hold/pop2/append PASS [V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W=4 wrap/kill/fl...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/profiles/release-g4/sim.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/rtl-source-binding.post.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/rtl-source-binding.pre.json

- `kind`: json
- `size_bytes`: 17275
- `line_count`: 152
- `sha256`: 665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: json evidence; size=17275 bytes; lines=152; markers=<none>; tail={ "design_id": "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375", "rtl_files": { "npc/rv64/vsrc/bus/AxiClint.v": "c88d091f0a4caba5daf9407cfb73d8a504feb5ba2669da0934d324cbf577de24", "npc/rv64/vsrc/bus/AxiDefaultSlave.v": "aea1c8d1637d...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: a63a63c07fffde49be62ebcfeeb6f02d97fc5141d7b61c9e7bbdfbb2b47c7747
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 1900
- `line_count`: 16
- `sha256`: a63a63c07fffde49be62ebcfeeb6f02d97fc5141d7b61c9e7bbdfbb2b47c7747
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1900 bytes; lines=16; markers=<none>; tail=86dbb766db1c8f344016abb25968f23290e4a02e81f949dbc355965e6db4b074 .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b npc/rv64/vsrc/schedulin...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/summary.json

- `kind`: json
- `size_bytes`: 104280
- `line_count`: 1312
- `sha256`: 89eb9d8e126b81cf0441640320c1df9f47101c05cfd0e7754fb2deda886b41ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 1}
- `summary`: json evidence; size=104280 bytes; lines=1312; PASS=1; tail=er-semantic-coverage/evidence/int-iq-producer-attempt-3/mutations/issue1-raw-index-issue0/OooIntIssueQueue.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v", "compile_log": { "path": ".github/task-runs/2026-07-30-rv64-v11f-int-iq-...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/int-iq-producer-attempt-3/vvp.version

- `kind`: version
- `size_bytes`: 814
- `line_count`: 18
- `sha256`: c9010a85df9399c2adb11b59115cdc285ea6f0a399802944367c3813c6772a42
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: version evidence; size=814 bytes; lines=18; markers=<none>; tail=Icarus Verilog runtime version 12.0 (stable) () Copyright (c) 2001-2021 Stephen Williams (steve@icarus.com) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free So...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/module-regression/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1375631
- `line_count`: 34884
- `sha256`: e7ac3f984fe1487000238e6cd02c46275c54821b3992d501bba817aef055bfd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1375631 bytes; lines=34884; markers=<none>; tail=/vec4 1, 0, 1; %store/vec4 v0x5aae49a576d0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5aae49a576d0_0, 0, 1; %alloc S_0x5aae498928b0; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5aae498928b0; %join; %free S_0x5aae498928b0; %delay 1, 0; %...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/module-regression/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11586
- `line_count`: 96
- `sha256`: facd5cbd45fedb5850a6d842d9a243e8a18b6fb3fed0a8840420809f6e515cb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11586 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/scoped-strict-guard.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 3
- `sha256`: 44b830752ca25e70030a3a9ae8f8831e9fd986b861c8d16eed3115658238c545
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=752 bytes; lines=3; PASS=4; tail=[agent-e2e-guard] mode=strict changed_paths=8 required_profiles=1 [agent-e2e-guard] PASS profile=npc-dev evidence=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-30-integer-iq-producer-semantic-revtag-v11f reason=npc/rv64/testbench/tests/tb_ooo_int_is...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/semantic-coverage-ledger.json

- `kind`: json
- `size_bytes`: 82846
- `line_count`: 2336
- `sha256`: 5ce689d4feda3ab423df8b85695a036b3f030773161b6c9ed2a239718908e634
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {"PASS": 25}
- `summary`: json evidence; size=82846 bytes; lines=2336; PASS=25; tail=atches_live": false, "path": "npc/rv64/testbench/tests/tb_ooo_int_backend.sv", "role": "testbench" } ] }, "gap_classifications": [ "CANDIDATE_TESTBENCH_SOURCE_DRIFT", "CURRENT_PRODUCT_INSTANCE_REPLAY_GAP" ], "id": "v9y-terminal-rtl-match-tb-drift", "scope":...

### .github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/semantic-ledger-unit.log

- `kind`: log
- `size_bytes`: 4273
- `line_count`: 27
- `sha256`: 996d0814d8f60bf438d3b90a2fd007021355fe46d4534d7e977081c0c2746d47
- `encoding`: utf-8
- `indexed_at`: 2026-07-29T20:21:19+00:00
- `markers`: {}
- `summary`: log evidence; size=4273 bytes; lines=27; markers=<none>; tail=test_assert_release_width_matrix_is_exact (npc.rv64.eval.ppa.tests.test_int_iq_producer_semantic_evidence.IntIqProducerEvidenceTests.test_assert_release_width_matrix_is_exact) ... ok test_carrier_lifetime_and_knownness_mutations_are_present (npc.rv64.eval.p...
