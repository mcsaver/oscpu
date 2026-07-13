# T3J dispatch log

- task_id: `2026-07-13-rv64-t3j-fetch-read-window`
- graph_template: `rv64-timing-slice`
- log_policy: `append-only`

### [2026-07-13 16:35] root implementation - completed

- owner: `/root`
- trigger: T3I top1 request/fire→fetch payload SRAM enable `-9.377ns`。
- action: 拆 physical read window / semantic accept，更新 RTL/TB/facts/checker/spec。
- output: 三态读窗、两个 assertion marker、87 ratchet、focused GREEN。

### [2026-07-13 16:38] contract review - completed

- owner: `/root/t3j_contract_review`
- action: 审查 S_IDLE/S_RESP/S_LOOKUP、S_R0 fill、dummy、flush、live-PC address 反例。
- output: 找到两处 TB 迁移遗漏、S_RESP accept 缺口、陈旧 macro/e2e 文档与地址 source gate。

### [2026-07-13 16:40] verification design - completed

- owner: `/root/t3j_verification_design`
- action: source AST gate、1024-case proof、9 mutations、两个 dynamic negative runner。
- output: current/proof/mutation/negative 全 PASS；修复 window alias proof 与相对 OUT_DIR。

### [2026-07-13 16:42] synthesis/STA preparation - completed

- owner: `/root/t3j_sta_prepare`
- action: frozen synthesis、old/fresh focused、global 5ns、archive脚本；先用 T3I smoke。
- output: old结构 RED/old timing smoke、110-RTL wrapper 与 H7CL Tcl/checker。

### [2026-07-13 16:47] functional closure - completed

- owner: `/root`
- action: 96 module、lint/style/contract、full core/177 privileged、CoreMark protected run。
- output: 全绿且 CoreMark cycle-exact；用户 log SHA恢复一致。

### [2026-07-13 16:54] fresh synthesis - completed

- owner: `/root`
- action: current shared-worktree frozen-input 200MHz H7CL synthesis与hardened audit。
- output: netlist `e5ae3b37...8349a`、area 1574381.48、220/10/210、limited freeze=5。

### [2026-07-13 17:05] next-path reconnaissance - completed

- owner: `/root/t3k_pending_trap_recon`, `/root/t3k_csr_probe_design`
- action: 只读追踪旧 pending top族并设计 commit/probe CSR 双 view。
- output: 精确 EX→WB→ROB→CSR legality→pending tval 路径、五方案与T3K验证矩阵。

### [2026-07-13 17:18] evidence audit/hardening - completed

- owner: `/root/t3j_evidence_audit`, `/root/t3j_evidence_hardening`,
  `/root/t3j_synth_audit_harden`
- action: 反查 provenance、netlist alias、OpenSTA告警与target/archive假绿；真实 smoke 修正CK/Q参照系。
- output: state-only fanin、303/1861/1863闭集、独立target expected-RED、extended synth markers。

### [2026-07-13 17:30] final OpenSTA verdict - completed

- owner: `/root`
- action: `-final` old/fresh focused + fresh global H7CL 5ns。
- output: fetch-en路径消失；top40全pending；WNS/TNS=-8.840/-199477.67ns；target rc=1。

### [2026-07-13 17:42] archive - completed

- owner: `/root`, `/root/t3j_tmp_archive`
- action: fresh STA 60-member archive；精确归档本轮OS `/tmp`持久对象，源保留。
- output: 27,729,635-byte STA archive；1-entry/1650-byte tmp archive；全部 inventory/SHA PASS。
