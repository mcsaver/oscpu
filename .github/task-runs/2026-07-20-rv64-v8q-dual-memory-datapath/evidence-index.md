# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8q-dual-memory-datapath
- `task_slug`: 
- `profile`: 
- `asset_count`: 64
- `total_size_bytes`: 363520

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/final.log

- `kind`: log
- `size_bytes`: 140
- `line_count`: 1
- `sha256`: 7d7504124b99669cffd65d5e3b3eb27cec67f4e4ed529903e1b837f64474c318
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=140 bytes; lines=1; PASS=2; tail=[V8Q-F0][PASS] run_id=v8q-f0-20260720T030925Z-849762 claim=dual_axi_miss_fabric_leaf_verified mutations=12 architecture=RED ppa=UNQUALIFIED

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 3740
- `line_count`: 12
- `sha256`: a5224f88892b4d1fa88fae03941f85cc045c34a636d547f70f101847034587ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=3740 bytes; lines=12; PASS=24; tail=[V8Q-MUTATION][PASS] run_id=v8q-f0-20260720T030925Z-849762 name=read_release_on_ar compile_success=true elaborated=true activated=true target_rejected=true source_sha256=1795ed8b48f78c5670d76553cdb740bd8212159f098ff421480babd5cf18d5da image_sha256=9f3705552...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/aw_seen_tieoff.compile.log

- `kind`: log
- `size_bytes`: 306
- `line_count`: 4
- `sha256`: 47a5c5377782256ce928e4fb028b19f372efbacf50ef6ad97c4997d65baf9a56
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=306 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/aw_seen_tieoff...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/aw_seen_tieoff.mutator.log

- `kind`: log
- `size_bytes`: 315
- `line_count`: 1
- `sha256`: 62d0e43686d44a4871bbb129b6175e4aaea7b298dbdb753e4b146ec5ad134d43
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=315 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:aw_seen_tieoff", "anchor_count": 1, "expected_rejection": "V8Q-MUT-AW-SEEN-TIEOFF", "mutant_sha256": "0a4ff4442dcf45efa0bfe2e1cf0c6504766ae285e3b1e27fc28060ea07786009", "mutation": "aw_seen_tieoff", "source_sha256": "f4b810ed5...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/aw_seen_tieoff.run.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 4
- `sha256`: 62245982b5f80f27c58f831f2a9b21269797b3270437d812c5f2c5d9f89fdb67
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=256 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:aw_seen_tieoff] [V8Q-MUT-AW-SEEN-TIEOFF] AW-first B isolation/stall mismatch @71000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 71000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_bvalid.compile.log

- `kind`: log
- `size_bytes`: 308
- `line_count`: 4
- `sha256`: 0eeb26ff1e8bfba5ed54e4d4c75b027b0464d2bb039a64eeb649f2609257fb7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=308 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/broadcast_bval...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_bvalid.mutator.log

- `kind`: log
- `size_bytes`: 321
- `line_count`: 1
- `sha256`: 1969028983320a550b3a28598ea136331d2a91a359045e1fe788bf7fff523a22
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=321 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:broadcast_bvalid", "anchor_count": 1, "expected_rejection": "V8Q-MUT-BROADCAST-BVALID", "mutant_sha256": "86615d9c48e421d30af581630765135f691e0ec7b3ce881e6f51866b53719a06", "mutation": "broadcast_bvalid", "source_sha256": "f4b...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_bvalid.run.log

- `kind`: log
- `size_bytes`: 262
- `line_count`: 4
- `sha256`: 291acb6dd1b8c0776f89c2ab6211d0dbd62094a11ed31dc0a8b930dfa234c527
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=262 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:broadcast_bvalid] [V8Q-MUT-BROADCAST-BVALID] lane1 B was broadcast or not accepted @71000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 71000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_rvalid.compile.log

- `kind`: log
- `size_bytes`: 308
- `line_count`: 4
- `sha256`: e62c92b1f3a338db4eefce233f3f3d64392a48517a1bed8e6d141dfefd57cfef
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=308 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/broadcast_rval...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_rvalid.mutator.log

- `kind`: log
- `size_bytes`: 321
- `line_count`: 1
- `sha256`: a34d08793d61fd3cacc62899fc8968513f1a2732f7ea276c0ec2ea385e721c9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=321 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:broadcast_rvalid", "anchor_count": 1, "expected_rejection": "V8Q-MUT-BROADCAST-RVALID", "mutant_sha256": "c323b24cd281ca87e938ee480426a9ca356c51dfaa3739d8be69848b3243857a", "mutation": "broadcast_rvalid", "source_sha256": "f4b...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/broadcast_rvalid.run.log

- `kind`: log
- `size_bytes`: 262
- `line_count`: 4
- `sha256`: dd79f4f7c6fcc7d902c4f3e057746212f56fa1cda693d8a70f38b24fbda4822c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=262 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:broadcast_rvalid] [V8Q-MUT-BROADCAST-RVALID] lane1 R was broadcast or not accepted @61000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 61000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/fixed_lane0_priority.compile.log

- `kind`: log
- `size_bytes`: 312
- `line_count`: 4
- `sha256`: 76a3cef233247c46fac47e95b29ecd4994ee89ed3dae5c3d464983f273bd5e22
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=312 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/fixed_lane0_pr...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/fixed_lane0_priority.mutator.log

- `kind`: log
- `size_bytes`: 333
- `line_count`: 1
- `sha256`: 86983f1818f605fc81f29cc8418ca509fd8c81a16f2041cfc220f714654b8594
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=333 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:fixed_lane0_priority", "anchor_count": 1, "expected_rejection": "V8Q-MUT-FIXED-LANE0-PRIORITY", "mutant_sha256": "285714b808bba47e93c00b6079ea90877a54ba6cbd9eb215b8b92e21cbef4a18", "mutation": "fixed_lane0_priority", "source_s...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/fixed_lane0_priority.run.log

- `kind`: log
- `size_bytes`: 286
- `line_count`: 4
- `sha256`: 2953a763c7526be6c0f8613eb5870ea210e9f20b1e45dacafc6dc091cc47f55c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=286 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:fixed_lane0_priority] [V8Q-MUT-FIXED-LANE0-PRIORITY] waiting lane1 did not win next dual-contender capture @76000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 76000 Scope: tb_ooo_dual_...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/idle_fallthrough.compile.log

- `kind`: log
- `size_bytes`: 308
- `line_count`: 4
- `sha256`: 77bfaf792751b56c59446052763db1cc8a15fb57305372cac6eb2578e936c753
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=308 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/idle_fallthrou...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/idle_fallthrough.mutator.log

- `kind`: log
- `size_bytes`: 321
- `line_count`: 1
- `sha256`: 1bd3a5b38349d4c43e3ee9140b044f9cba5edd3e47a7a7944c00d1adc64e219c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=321 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:idle_fallthrough", "anchor_count": 1, "expected_rejection": "V8Q-MUT-IDLE-FALLTHROUGH", "mutant_sha256": "fec222058386448b7af2961fa1e7426f1e9c7facaa4e20fc903a91db212fbaae", "mutation": "idle_fallthrough", "source_sha256": "f4b...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/idle_fallthrough.run.log

- `kind`: log
- `size_bytes`: 261
- `line_count`: 4
- `sha256`: 0570bda2e277211c8c4448ea59d715c05b6eac19ec406ac49025cc475ea6cc36
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=261 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:idle_fallthrough] [V8Q-MUT-IDLE-FALLTHROUGH] expected all handshake outputs quiet @41000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 41000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/read_release_on_ar.compile.log

- `kind`: log
- `size_bytes`: 310
- `line_count`: 4
- `sha256`: 568d8a42f40f382b0cec276fae0d700091838547bf6e4f93ca218026b69d74c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=310 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/read_release_o...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/read_release_on_ar.mutator.log

- `kind`: log
- `size_bytes`: 327
- `line_count`: 1
- `sha256`: b0ac49ab78fa0dc14a4a2d02aef5cbfb13e378cdd8d34e5c81364ac376007fa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=327 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:read_release_on_ar", "anchor_count": 1, "expected_rejection": "V8Q-MUT-READ-RELEASE-ON-AR", "mutant_sha256": "1795ed8b48f78c5670d76553cdb740bd8212159f098ff421480babd5cf18d5da", "mutation": "read_release_on_ar", "source_sha256"...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/read_release_on_ar.run.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 4
- `sha256`: 7bef778538a737760aa7dc0a096133a7acc4a3a7e076b5cba3d293da6d9e1ec8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=271 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:read_release_on_ar] [V8Q-MUT-READ-RELEASE-ON-AR] lane0 R isolation/READY selection mismatch @71000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 71000 Scope: tb_ooo_dual_mem_axi_arbiter...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/reset_owner_residue.compile.log

- `kind`: log
- `size_bytes`: 311
- `line_count`: 4
- `sha256`: b3233f544130ec21a29ee45829b5411d04e22c2050d3e489dff530b3aff64206
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=311 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/reset_owner_re...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/reset_owner_residue.mutator.log

- `kind`: log
- `size_bytes`: 330
- `line_count`: 1
- `sha256`: 67fcc3e8cab63af024f176fe6f91049670479ba6dab257d18119c4a91414a552
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=330 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:reset_owner_residue", "anchor_count": 1, "expected_rejection": "V8Q-MUT-RESET-OWNER-RESIDUE", "mutant_sha256": "0dfde32ddd6c90472ec50e2444fb2472d838fc2434a83727535607004b51a1da", "mutation": "reset_owner_residue", "source_sha2...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/reset_owner_residue.run.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 4
- `sha256`: 4b13a51477effb4d5b9d85c11879cf37b35cfefd323d92e0968d3046a5914e50
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=271 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:reset_owner_residue] [V8Q-MUT-RESET-OWNER-RESIDUE] reset did not establish cold-start state @26000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 26000 Scope: tb_ooo_dual_mem_axi_arbiter...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/rr_update_on_capture.compile.log

- `kind`: log
- `size_bytes`: 312
- `line_count`: 4
- `sha256`: b54c628300d39215d37f7e566511b632bee9d5165d120bb95195c43bec4ce004
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=312 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/rr_update_on_c...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/rr_update_on_capture.mutator.log

- `kind`: log
- `size_bytes`: 333
- `line_count`: 1
- `sha256`: e9644c4c1259a79a51a7a9ab6ba669a7e2a4ee4af8f09c73d1811209c406d278
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=333 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:rr_update_on_capture", "anchor_count": 1, "expected_rejection": "V8Q-MUT-RR-UPDATE-ON-CAPTURE", "mutant_sha256": "2b58f85c343c92591ff93e2ab5fd84b4bf67418e79ab3f7647ec4acc65f06c40", "mutation": "rr_update_on_capture", "source_s...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/rr_update_on_capture.run.log

- `kind`: log
- `size_bytes`: 289
- `line_count`: 4
- `sha256`: 5f70aec64d1eebc4145177b009003a032139cbf4f7a39d82fad34ceb838ba5ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=289 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:rr_update_on_capture] [V8Q-MUT-RR-UPDATE-ON-CAPTURE] round-robin state changed at capture instead of terminal @46000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 46000 Scope: tb_ooo_du...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/swap_rready.compile.log

- `kind`: log
- `size_bytes`: 303
- `line_count`: 4
- `sha256`: 3002c36fea0f4f08a26db708fab23a2419b215ac40ae95e8da95d8ef805b5675
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=303 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/swap_rready/Oo...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/swap_rready.mutator.log

- `kind`: log
- `size_bytes`: 306
- `line_count`: 1
- `sha256`: c59994255eba7cfd62da11f719d8e07c4f200e6d19471ed57880f99eef119fb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=306 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:swap_rready", "anchor_count": 1, "expected_rejection": "V8Q-MUT-SWAP-RREADY", "mutant_sha256": "dc672a2aec8b0480a3162e96ccdf813409cfa5e9d68399005ee2cff1c118ce1d", "mutation": "swap_rready", "source_sha256": "f4b810ed5ada6f68e9...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/swap_rready.run.log

- `kind`: log
- `size_bytes`: 257
- `line_count`: 4
- `sha256`: 0e41f8f055116bb1ab1bcb9869e56a91f110d239a6e9efdc1c3e12d1a9933298
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=257 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:swap_rready] [V8Q-MUT-SWAP-RREADY] lane0 R isolation/READY selection mismatch @71000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 71000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/w_seen_tieoff.compile.log

- `kind`: log
- `size_bytes`: 305
- `line_count`: 4
- `sha256`: f3eaa8d0ed4ba83fe552b692b0f14fc9b36884a9b8d3dd89405887ca2e7a1ea6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=305 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/w_seen_tieoff/...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/w_seen_tieoff.mutator.log

- `kind`: log
- `size_bytes`: 312
- `line_count`: 1
- `sha256`: 4903d530eb245580919f0a97df106b452f1dbb96ef1ebad86527f662fe1f44ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=312 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:w_seen_tieoff", "anchor_count": 1, "expected_rejection": "V8Q-MUT-W-SEEN-TIEOFF", "mutant_sha256": "a74bc0b78d60923f4d1bad7c75ad1c7e32f01ebd0dbbef0c13653e0066083b39", "mutation": "w_seen_tieoff", "source_sha256": "f4b810ed5ada...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/w_seen_tieoff.run.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 4
- `sha256`: c57bee5e3b6b55ec52c1ef6bbd20490e833a9334e46746c8c1565819e9fbf91b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=256 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:w_seen_tieoff] [V8Q-MUT-W-SEEN-TIEOFF] lane1 B was broadcast or not accepted @71000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 71000 Scope: tb_ooo_dual_mem_axi_arbiter.die

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_aw.compile.log

- `kind`: log
- `size_bytes`: 311
- `line_count`: 4
- `sha256`: ce384d44a0918fd8a9d47b92ce968b2067a25d7109078ac7a13f910ee090c78f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=311 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/write_release_...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_aw.mutator.log

- `kind`: log
- `size_bytes`: 330
- `line_count`: 1
- `sha256`: 2fea68aace8b0500fcc32b14daa4e5a23bac4a93f97167df9e4259186b8d3c00
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=330 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:write_release_on_aw", "anchor_count": 1, "expected_rejection": "V8Q-MUT-WRITE-RELEASE-ON-AW", "mutant_sha256": "0c4bdd76efc1638d61dbea367d80428a4790c7ca812f02e46035b8a593ddd604", "mutation": "write_release_on_aw", "source_sha2...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_aw.run.log

- `kind`: log
- `size_bytes`: 286
- `line_count`: 4
- `sha256`: 329032a5c98fc5dc13160ad4eb11ced6660da397040dbd94b1c46dab19211d4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=286 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:write_release_on_aw] [V8Q-MUT-WRITE-RELEASE-ON-AW] AW-first did not retain owner and accept W exactly once @61000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 61000 Scope: tb_ooo_dual_...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_w.compile.log

- `kind`: log
- `size_bytes`: 310
- `line_count`: 4
- `sha256`: a8e8aebdc45dc6110e768e43ba617f43c311906c84fb9390ab60ed27d90d4fcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=310 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /tmp/v8q-dual-mem-fabric.nt4Y5L/mutants/write_release_...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_w.mutator.log

- `kind`: log
- `size_bytes`: 327
- `line_count`: 1
- `sha256`: 1abb464741cdec76314cfd32e52319674f4c1ff15743689f67a3589a0b13599b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=327 bytes; lines=1; markers=<none>; tail={"activation": "V8Q-MUT-ACTIVE:write_release_on_w", "anchor_count": 1, "expected_rejection": "V8Q-MUT-WRITE-RELEASE-ON-W", "mutant_sha256": "56e508e9048b31fec465a387d20a62415433a868f265b13e0a6793d3fdf39faa", "mutation": "write_release_on_w", "source_sha256"...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/mutations/write_release_on_w.run.log

- `kind`: log
- `size_bytes`: 284
- `line_count`: 4
- `sha256`: 09f927dd523facb8d3941b92c296f2c07a7a0a6227ca884b292baa47a3a01040
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=284 bytes; lines=4; markers=<none>; tail=[V8Q-MUT-ACTIVE:write_release_on_w] [V8Q-MUT-WRITE-RELEASE-ON-W] W-first did not retain owner and accept AW exactly once @61000 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:182: Time: 61000 Scope: tb_ooo_dual_me...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profile-summary.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 3
- `sha256`: aeb3a46c54f7a0ddb414eee8f4035c353f3fbababefe2bc588cf0d36144cc2da
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=413 bytes; lines=3; PASS=6; tail=[V8Q-PROFILE][PASS] run_id=v8q-f0-20260720T030925Z-849762 profile=release image_sha256=4656af8cf4d07495c3229f548f04dd5c9b5b5905d292c85c874799bc17191c09 [V8Q-PROFILE][PASS] run_id=v8q-f0-20260720T030925Z-849762 profile=assert image_sha256=f5a0790c90c5a267276...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/assert-negative.compile.log

- `kind`: log
- `size_bytes`: 300
- `line_count`: 4
- `sha256`: a6010bcc32c94462432525e075147ce2a92acd1325ef3488d958b1eb200292d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=300 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooDu...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/assert-negative.run.log

- `kind`: log
- `size_bytes`: 351
- `line_count`: 4
- `sha256`: f7dda324eaf457ab086c5caf9b70c2f4bf9806e94d53b5c8a87e55fc6f8ce6ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=351 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v:383: [ARB-REQ-CLASS-ONEHOT] lane presents read and write together @0 Time: 45000 Scope: tb_ooo_dual_mem_axi_arbiter.dut FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/Oo...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/assert.compile.log

- `kind`: log
- `size_bytes`: 300
- `line_count`: 4
- `sha256`: a6010bcc32c94462432525e075147ce2a92acd1325ef3488d958b1eb200292d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=300 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooDu...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/assert.run.log

- `kind`: log
- `size_bytes`: 180
- `line_count`: 2
- `sha256`: 5dcfb64a832221161e7ebd02f94db841f0f4a471bf34b8398d7cc2fe69379919
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=180 bytes; lines=2; PASS=2; tail=[V8Q-F0-TB][PASS] release/assert directed transport matrix /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:720: $finish called at 1046000 (1ps)

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/release.compile.log

- `kind`: log
- `size_bytes`: 300
- `line_count`: 4
- `sha256`: a6010bcc32c94462432525e075147ce2a92acd1325ef3488d958b1eb200292d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=300 bytes; lines=4; markers=<none>; tail=warning: Some design elements have no explicit time unit and/or : time precision. This may cause confusing timing results. : Affected design elements are: : -- module OooDualMemAxiArbiter declared here: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooDu...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/profiles/release.run.log

- `kind`: log
- `size_bytes`: 180
- `line_count`: 2
- `sha256`: 9448d925346acaf52a7a3297880f965836603cb7c804d5632f42584c3582624c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=180 bytes; lines=2; PASS=2; tail=[V8Q-F0-TB][PASS] release/assert directed transport matrix /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv:720: $finish called at 1116000 (1ps)

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/result.json

- `kind`: json
- `size_bytes`: 748
- `line_count`: 26
- `sha256`: a7df9ebd263c58249d063345494afe2058a0372a8c438132381b607b5791e9d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 8}
- `summary`: json evidence; size=748 bytes; lines=26; PASS=8; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "claim": "dual_axi_miss_fabric_leaf_verified", "generated_at_utc": "2026-07-20T03:09:26.904370+00:00", "mutations": { "compile_success"...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/run-id.txt

- `kind`: txt
- `size_bytes`: 31
- `line_count`: 1
- `sha256`: c92142094ea517f7cb5aae4d12447b4a4bb4859dd9e896049f761fd7f840b741
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: txt evidence; size=31 bytes; lines=1; markers=<none>; tail=v8q-f0-20260720T030925Z-849762

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 2376
- `line_count`: 15
- `sha256`: d271ddf5fca6c6c8ef552fb1c1111b691e43e77714aeb51f3720dedbe18a5186
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2376 bytes; lines=15; markers=<none>; tail=760aae4bb98d1f8ce2ee776187c809b73fc4accfbe75d4dfe8455b3d4b54b606 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/contract.md 41537f024147b69b948ba401dc7c596df4c93fc1606762f4bc1eb11ac6af4eee /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 2376
- `line_count`: 15
- `sha256`: d271ddf5fca6c6c8ef552fb1c1111b691e43e77714aeb51f3720dedbe18a5186
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2376 bytes; lines=15; markers=<none>; tail=760aae4bb98d1f8ce2ee776187c809b73fc4accfbe75d4dfe8455b3d4b54b606 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/contract.md 41537f024147b69b948ba401dc7c596df4c93fc1606762f4bc1eb11ac6af4eee /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 53081
- `line_count`: 1218
- `sha256`: 2e255c8d6e93f76ce2e77828246dc40dfaad1236ea71b20550700f221c058b72
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=53081 bytes; lines=1218; PASS=16; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 401
- `line_count`: 11
- `sha256`: b4b2f5da2caf85d0edf77671d022cf25612ef2de2eafcbf836b7ec8650a022c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=401 bytes; lines=11; markers=<none>; tail=DI-1: RED (6 red checks) DI-2: RED (17 red checks) DI-3: GREEN (0 red checks) DI-4: GREEN (0 red checks) DI-5: RED (14 red checks) OOO-1: GREEN (0 red checks) OOO-2: GREEN (0 red checks) OOO-3: RED (13 red checks) OOO-4: RED (8 red checks) OVERALL: RED RESU...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 1225
- `line_count`: 15
- `sha256`: 2ba1b247bab6167cbb817e68cddde6462aa54061c8aff570bc718e0fe0e23518
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=1225 bytes; lines=15; markers=<none>; tail=test_canonical_instance_detection_ignores_comments (__main__.CheckerFailClosedTests.test_canonical_instance_detection_ignores_comments) ... ok test_comment_only_assertion_marker_fails (__main__.CheckerFailClosedTests.test_comment_only_assertion_marker_fails...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/leaf-checks.json

- `kind`: json
- `size_bytes`: 4153
- `line_count`: 178
- `sha256`: 7cfc7185ba0bcd932d12416e38bc0e5df77ef9bb49924420f8db7173d8ce2e0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: json evidence; size=4153 bytes; lines=178; markers=<none>; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED", "ppa_promotion": "forbidden" }, "checks": [ { "check_id": "source.one_nonempty_module", "detail": "module_count=1 stripped_bytes=18067", "passed": true }, { "check_id": "source.state.s_idl...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/leaf-checks.log

- `kind`: log
- `size_bytes`: 4153
- `line_count`: 178
- `sha256`: 7cfc7185ba0bcd932d12416e38bc0e5df77ef9bb49924420f8db7173d8ce2e0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=4153 bytes; lines=178; markers=<none>; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED", "ppa_promotion": "forbidden" }, "checks": [ { "check_id": "source.one_nonempty_module", "detail": "module_count=1 stripped_bytes=18067", "passed": true }, { "check_id": "source.state.s_idl...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/rtl-style.log

- `kind`: log
- `size_bytes`: 232
- `line_count`: 3
- `sha256`: 96c33fde944e1dfe18479810ebbb194ce79d090de0454e240cebdb1f88732078
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=232 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/verilator-assert.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused/static/verilator-release.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/smoke/assert.vvp

- `kind`: vvp
- `size_bytes`: 100716
- `line_count`: 3120
- `sha256`: 8d1982a68adbbc3be9a74005891c8d88cd2f83444311223ca914eda8181b9163
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=100716 bytes; lines=3120; FAIL=10; PASS=1; tail=n; %free S_0x615131295c50; %wait E_0x6151311b93b0; %pushi/vec4 0, 0, 1; %store/vec4 v0x615131297a50_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x6151312962c0_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x615131296fc0_0, 0, 1; %pushi/vec4 2874409542, 0, 33; %...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/smoke/checker.json

- `kind`: json
- `size_bytes`: 3508
- `line_count`: 163
- `sha256`: 499cf194e93e8dd53efebe64ffb6d0f9e92ea18f041ae88e075e4f6aedc5880c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {}
- `summary`: json evidence; size=3508 bytes; lines=163; markers=<none>; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED", "ppa_promotion": "forbidden" }, "checks": [ { "check_id": "source.one_nonempty_module", "detail": "module_count=1 stripped_bytes=18067", "passed": true }, { "check_id": "source.state.s_idl...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/smoke/neg.log

- `kind`: log
- `size_bytes`: 295
- `line_count`: 4
- `sha256`: bdf43def22b30a980b1fe37347ce09c41f9ce9c914665dd81d035fd88cf4bb39
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=295 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v:383: [ARB-REQ-CLASS-ONEHOT] lane presents read and write together @0 Time: 45000 Scope: tb_ooo_dual_mem_axi_arbiter.dut FATAL: npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v:384: Time: 45000 Scope: tb_ooo_dual...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/smoke/neg.vvp

- `kind`: vvp
- `size_bytes`: 93842
- `line_count`: 2912
- `sha256`: ec3391b65fe7131d56926d66ac291cb191a46915503f9a5c74cfb3869687c975
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"FAIL": 10}
- `summary`: vvp evidence; size=93842 bytes; lines=2912; FAIL=10; tail=e0, L_0x60386c20ab00, C4<>; S_0x60386c203f70 .scope autotask, "expect_quiet" "expect_quiet" 3 246, 3 246 0, S_0x60386c151420; .timescale -9 -12; v0x60386c204150_0 .var/str "marker"; TD_tb_ooo_dual_mem_axi_arbiter.expect_quiet ; %load/vec4 v0x60386c207880_0;...

### .github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/smoke/release.vvp

- `kind`: vvp
- `size_bytes`: 79364
- `line_count`: 2275
- `sha256`: bc22b748fa0c4390de0f7e284d349f3adf5c0762ec5db6ac48743dc21162e9db
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T03:14:42+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=79364 bytes; lines=2275; FAIL=10; PASS=1; tail=rready_i"; .port_info 39 /OUTPUT 64 "lane1_axi_rdata_o"; .port_info 40 /OUTPUT 2 "lane1_axi_rresp_o"; .port_info 41 /INPUT 1 "lane1_axi_awvalid_i"; .port_info 42 /OUTPUT 1 "lane1_axi_awready_o"; .port_info 43 /INPUT 64 "lane1_axi_awaddr_i"; .port_info 44 /I...
