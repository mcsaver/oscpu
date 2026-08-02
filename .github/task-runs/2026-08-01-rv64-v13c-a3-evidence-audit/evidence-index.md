# Evidence Index

## 基本信息

- `task_id`: 2026-08-01-rv64-v13c-a3-evidence-audit
- `task_slug`: 
- `profile`: 
- `asset_count`: 10
- `total_size_bytes`: 41298

## 证据资产

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/canonical-assets-check.log

- `kind`: log
- `size_bytes`: 26
- `line_count`: 2
- `sha256`: ab94c02e8c11421a5c8156f92946f87ee4b6aa4a2da89404f49c03a53b6bb3b5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {}
- `summary`: log evidence; size=26 bytes; lines=2; markers=<none>; tail=canonical_assets=9 bad=0

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/checker-unit.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 8
- `sha256`: c2c1bed719b5a0d523caf2a0896185e640aec43ad0c44d7ac1e27ecad66cd93f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=8; markers=<none>; tail=test_debug_text_is_not_a_bug_token (Linux.scripts.tests.test_npc_systemd_strict_check.StrictDmesgTokenTest.test_debug_text_is_not_a_bug_token) ... ok test_legacy_unbounded_mutation_reproduces_a3_false_red (Linux.scripts.tests.test_npc_systemd_strict_check.S...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/checksums.sha256

- `kind`: sha256
- `size_bytes`: 1400
- `line_count`: 9
- `sha256`: ae2bf002c4f036cea48115abcf1d9690196c78f8b777de514b45f8b16297519d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1400 bytes; lines=9; markers=<none>; tail=ab94c02e8c11421a5c8156f92946f87ee4b6aa4a2da89404f49c03a53b6bb3b5 .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/canonical-assets-check.log c2c1bed719b5a0d523caf2a0896185e640aec43ad0c44d7ac1e27ecad66cd93f .github/task-runs/2026-08-01-rv64-...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/currentness-stale-rejection.log

- `kind`: log
- `size_bytes`: 4834
- `line_count`: 62
- `sha256`: ab8cb2ba8c5986711c5efdf72011d59435316163d0abd02031c751a6cc9cc47d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"ERROR": 8}
- `summary`: log evidence; size=4834 bytes; lines=62; ERROR=8; tail=..EE.EE.. ====================================================================== ERROR: test_decision_keeps_full_system_gap (__main__.CurrentEvidenceTests.test_decision_keeps_full_system_gap) -----------------------------------------------------------------...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/fresh-base-replay.json

- `kind`: json
- `size_bytes`: 13834
- `line_count`: 308
- `sha256`: be2fe8133f83c4b4936d58d6302b0a14132fd67942e79d25c82b9beba67d124d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"FAIL": 6, "PANIC": 4, "PASS": 6, "symbolic": ["__NPC_CHECK_FAIL__"]}
- `summary`: json evidence; size=13834 bytes; lines=308; FAIL=6; PASS=6; PANIC=4; symbolic=__NPC_CHECK_FAIL__; tail={ "binding": { "design_id_post": "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594", "design_id_pre": "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594", "pre_post_pairs": { "guest_checker": { "post": "1b3cc4695...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/fresh-checker-replay.json

- `kind`: json
- `size_bytes`: 13466
- `line_count`: 285
- `sha256`: 0fa0720120f008abcd1cebe31b7018672ca2f41445c82a6ad2be3e95521d1173
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"FAIL": 6, "PANIC": 4, "PASS": 8, "symbolic": ["__NPC_CHECK_FAIL__"]}
- `summary`: json evidence; size=13466 bytes; lines=285; FAIL=6; PASS=8; PANIC=4; symbolic=__NPC_CHECK_FAIL__; tail={ "base_replay": { "binding": { "design_id_post": "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594", "design_id_pre": "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594", "pre_post_pairs": { "guest_checker": { "...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/fresh-embedded-checker.sh

- `kind`: sh
- `size_bytes`: 5470
- `line_count`: 201
- `sha256`: 83b6a5384bc92a0b6c4977832a5e882c06684de554a8a09e0391a7acff053f9a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"PANIC": 2, "symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_ROOT_MOUNT__", "__NPC_CHECK_ROOT_SOURCE__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CHECK_VDA_DRIVER__", "__NPC_CHECK_VIRTIO_IRQ_OWNER__", "__NPC_CHECK_VIRTIO_IRQ__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_POWEROFF_BEGIN__", "__NPC_SYSTEMD_POWEROFF_CMD_FAIL__", "__NPC_SYSTEMD_STRICT_BEGIN__", "__NPC_SYSTEMD_STRICT_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: sh evidence; size=5470 bytes; lines=201; PANIC=2; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_ROOT_MOUNT__,__NPC_CHECK_ROOT_SOURCE__,__NPC_CHECK_SYSTEMD_STATE__; tail=#!/bin/sh set +e set +u PATH=/usr/sbin:/usr/bin:/sbin:/bin export PATH poweroff_enable=0 marker_stage=uart while [ "$#" -gt 0 ]; do case "$1" in --poweroff) poweroff_enable=1 shift ;; --stage) [ "$#" -ge 2 ] || exit 2 marker_stage=$2 shift 2 ;; --stage=*) m...

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/fresh-replay.log

- `kind`: log
- `size_bytes`: 232
- `line_count`: 1
- `sha256`: 3b668efcf0dce96c09e6f6c46fbf77a0c7787a01c6580222e0972403525a258e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=232 bytes; lines=1; PASS=2; tail=[V10F-A3-CHECKER-REPLAY-V2] embedded_sha=83b6a5384bc92a0b6c4977832a5e882c06684de554a8a09e0391a7acff053f9a legacy_matches=2 current_matches=0 printk_debug=ACCEPT real_bug=REJECT terminal=6/6 cycles=5071521696 commits=1223536213 PASS

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/semantic-compare.log

- `kind`: log
- `size_bytes`: 40
- `line_count`: 1
- `sha256`: 4793b6dad24e44d99db1928885762eee24a321106b3fc94e3a7fcfdb2fbb0923
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=40 bytes; lines=1; PASS=2; tail=canonical_vs_fresh_semantic_fields=PASS

### .github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/evidence/source-input-check.log

- `kind`: log
- `size_bytes`: 1390
- `line_count`: 9
- `sha256`: e6a8aed88cac8210724275d783a587cb60f794d047baa23c656ead42b09a0e0d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T06:59:02+00:00
- `markers`: {}
- `summary`: log evidence; size=1390 bytes; lines=9; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3.status: OK /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-syste...
