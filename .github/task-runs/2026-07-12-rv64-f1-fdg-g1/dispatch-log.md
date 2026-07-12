# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-fdg-g1
- `task_slug`: rv64-f1-fdg-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `log_policy`: append-only

---

### [2026-07-12 10:06 +0800] `recall-contract` - PASS

- `owner_agent`: root + f1_backlog_audit
- `trigger`: 用户持续目标要求完整功能与 200 MHz 双门槛。
- `depends_on`: T0 5 ns target-driven baseline、F0 truthful regression。
- `inputs`: current snapshot、ROADMAP、FDG active spec、当前 RTL 与 testbench。
- `action`: 代码优先复核 `arch_trap` producer、dispatch gate 与 backend mux sink。
- `outputs`: 确认 FDG-G1 仍 OPEN，锁定漏门控的单一 root cause。
- `evidence`: task-report 的 root-cause 与接口契约冻结。
- `handoff_to`: red-path-matrix。
- `next_step`: 新增常驻整链 RED fixture。
- `notes`: 不把历史 directed marker 当成修复证据。

### [2026-07-12 10:06 +0800] `freeze-contract` - PASS

- `owner_agent`: root
- `trigger`: 任何 trap/跨模块 RTL 改动前的阶段 0 门槛。
- `depends_on`: recall-contract。
- `inputs`: SPEC-TEMPLATE、interface-contract-first、rtl-generation-workflow。
- `action`: 冻结握手/stall/flush/异常序/访存序/恢复六类合同与 RTL 拓扑。
- `outputs`: task-report「接口契约冻结」「RTL 推导摘要」与 active spec §2/§3 增补。
- `evidence`: task-report.md、ooo-frontend-dispatch-gate.md。
- `handoff_to`: red-path-matrix。
- `next_step`: 先 RED，后实现。
- `notes`: 填满所有受影响格子后才允许写 RTL。

### [2026-07-12 10:09 +0800] `red-path-matrix` - PASS

- `owner_agent`: root
- `depends_on`: recall-contract, freeze-contract。
- `action`: 新增 DecodeUnit→FP legality→classifier→ordinary admission 常驻 TB，并在旧 RTL 上运行。
- `outputs`: 四类非法 FP 均只失败于 backend-valid，`errors=4`、runner rc=1；合法正对照未被误伤。
- `evidence`: `evidence/red/logs/tb_ooo_fp_legality_dispatch_path.log`。
- `handoff_to`: implement-gate。

### [2026-07-12 10:12 +0800] `implement-gate` - PASS

- `owner_agent`: root
- `depends_on`: red-path-matrix, freeze-contract。
- `action`: 在唯一 ordinary backend-valid 方程加入 arch-trap 排除；父级加入 FDG-I1 立即断言。
- `outputs`: focused 4/4 PASS，合法 FADD.S 正对照 PASS。
- `evidence`: `evidence/focused-green/summary.txt`。
- `handoff_to`: assert-negative-probe, full-regression。

### [2026-07-12 10:14 +0800] `assert-negative-probe` - PASS

- `owner_agent`: root
- `action`: 用专用宏强制合同违约，并在目标断言采样后立即退出。
- `outputs`: `[FDG-CONTRACT FDG-I1]` 明确出现，runner 按预期 rc=1；无后续功能场景污染。
- `evidence`: `evidence/assert-negative/logs/tb_ooo_fetch_trap_gate.log`。
- `handoff_to`: full-regression。

### [2026-07-12 10:20 +0800] `full-regression` - PASS

- `owner_agent`: root
- `action`: 用 `scripts/agent-run.sh` 绑定仓库工具链跑 module/lint/build/AM/official；另跑 Difftest-ON AM。
- `outputs`: bundled run overall_rc=0；module 87/87、current-config AM 59/59、official 177/177；
  独立 Difftest-ON AM 59/59；六个配置文件哈希恢复。
- `evidence`: `evidence/core-regress-agent-env/20260712-101738-1337411/`、
  `evidence/am-difftest-on.log`、`evidence/config-restore.sha256`、
  `evidence/restored-config-rebuild.log`、`evidence/structural/`。
- `notes`: system Verilator 5.020 的首次 run overall_rc=1，明确隔离为环境失败，不采信其旧 binary 结果。
- `notes`: 配置文件恢复后另做 clean OFF rebuild + fresh AM smoke，消除 Difftest-ON 构建产物残留。
- `handoff_to`: record-review。

### [2026-07-12 10:40 +0800] `record-review` - PASS

- `owner_agent`: root + fdg_reviewer + fdg_evidence_audit
- `action`: 独立复核 root cause、证据非真空、配置恢复、active docs 与 task-run 一致性。
- `outputs`: RTL 功能 verdict PASS；structural、memory、evidence index、clean OFF artifact
  reconciliation、fresh npc-dev 与 strict guard 均 PASS。
- `evidence`: `evidence/structural/`、`evidence/restored-config-rebuild.log`、
  `evidence/strict-guard.log`、同级 `evidence-index.md`、final sibling task-run
  `2026-07-12-rv64-f1-fdg-g1-final-npc-dev/`。
- `next_step`: 阶段提交 FDG-G1，随后进入 IQ→EX stage 的 RED/合同冻结；200 MHz 总目标继续 active。
