# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-xret-g1
- `task_slug`: rv64-f1-xret-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `log_policy`: append-only

---

### [2026-07-12 10:43 +0800] `recall-contract` - PASS

- `owner_agent`: root + xret_f1_slice
- `inputs`: current snapshot、ROADMAP、classifier/CsrFile spec、真实 RTL。
- `action`: 追踪 DecodeUnit、classifier、head0/lane1 pending capture 与 CsrFile request 边界。
- `outputs`: 定位两个漏判谓词，确认 CsrFile 不复查 current mode。
- `handoff_to`: freeze-contract, red-matrix。

### [2026-07-12 10:45 +0800] `freeze-contract` - PASS

- `owner_agent`: xret_f1_slice + root
- `action`: 冻结六类合同、合法性矩阵、arch-trap over system 优先级和无状态 RTL 拓扑。
- `outputs`: active classifier/CsrFile spec 与本 task-report。
- `handoff_to`: implement-classifier。

### [2026-07-12 10:47 +0800] `red-matrix` - PASS

- `owner_agent`: xret_f1_slice
- `action`: 在旧 RTL 上运行 current-mode ISA 矩阵。
- `outputs`: MRET@S/U、SRET@U 精确 6 fail，runner rc=1；正对照不受影响。
- `evidence`: `npc/rv64/perf/results/20260712-xret-g1/red/logs/tb_ooo_fetch_head_classify_gate.log`。
- `handoff_to`: implement-classifier。

### [2026-07-12 10:49 +0800] `implement-classifier` - PASS

- `owner_agent`: xret_f1_slice
- `action`: 在唯一 privileged-illegal 汇合点加入 MRET/SRET current-mode 谓词。
- `outputs`: classifier focused GREEN；无端口、状态机或 CsrFile RTL 变化。
- `handoff_to`: integration-green, full-regression。

### [2026-07-12 10:57 +0800] `integration-green` - PASS

- `owner_agent`: root
- `trigger`: 独立 reviewer 指出缺真实编码贯穿 pending/CsrFile 的常驻覆盖。
- `action`: 扩展 `tb_ooo_priv_system`，加入 S-mode lane0 MRET 与 U-mode lane1 SRET。
- `outputs`: cause/pc/tval、handler/return、no illegal-xRET commit 全部通过；focused 5/5 PASS。
- `evidence`: `evidence/focused-green/`。
- `handoff_to`: reviewer-rerun, record-review。

### [2026-07-12 10:58 +0800] `full-regression` - PASS

- `owner_agent`: root
- `action`: 用 bundled toolchain 跑 core-regress + privileged official suites。
- `outputs`: Verilator 5.051，module/lint/build/AM/official 子层与 `overall_rc=0` 一致。
- `evidence`: `evidence/core-regress/20260712-105358-1383799/`。
- `notes`: core-regress 的 module 子层发生在 integration TB 增补前，因此另跑 final module sweep。
- `handoff_to`: record-review。

### [2026-07-12 11:14 +0800] `reviewer-rerun` - PASS

- `owner_agent`: xret_review + root
- `action`: reviewer 主动构造 arch-trap/system 双 owner 被 CsrFile trap 优先级掩蔽的假绿反例；
  实现者增加 direct CsrFile mret/sret request sticky，并复跑 focused 与 current module。
- `outputs`: focused 5/5、module 87/87；sticky 对非法 fault PC 恒 0；reviewer 无剩余 blocker。
- `evidence`: `evidence/focused-green/`、`evidence/module-final-current/`。
- `handoff_to`: record-review。

### [2026-07-12 11:14 +0800] `difftest-artifact-reconcile` - PASS

- `owner_agent`: root
- `action`: 临时启用 default_defconfig 跑 Difftest-ON AM；trap 恢复六配置；随后 clean rebuild OFF。
- `outputs`: ON/reference 各 59、AM 59/59；六配置 MATCH；fresh OFF add 1/1；style/contract/lint PASS。
- `evidence`: `evidence/am-difftest-on.log`、`evidence/config-restore.sha256`、
  `evidence/restored-config-rebuild.log`、`evidence/structural/`。
- `handoff_to`: record-review。

### [2026-07-12 11:16 +0800] `record-review` - PASS

- `owner_agent`: root + xret_review
- `action`: 更新 active docs、DB-backed project/NPC memory、1002 raw asset DB 索引与 bounded
  evidence index；运行 fresh npc-dev、strict guard 与 DB/artifact audits。
- `outputs`: XRET-G1 CLOSED；reviewer 无 blocker；npc-dev/strict guard/DB-first/coverage/artifact 全 PASS。
- `evidence`: `evidence/strict-guard.log`、同级 `evidence-index.md`、sibling task-run
  `2026-07-12-rv64-f1-xret-g1-final-npc-dev/`。
- `next_step`: 提交本独立 slice；T3 禁止 naive FIFO，先冻结 liveness-safe memory station 拓扑。
