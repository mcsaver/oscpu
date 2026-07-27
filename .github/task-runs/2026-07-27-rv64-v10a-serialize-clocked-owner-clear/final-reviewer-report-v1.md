# V10A final-reviewer-v1

RV64 RTL 结论｜对象=`OooCsrTrapRequestMux`、pending owner/stop
sequencers、`CsrFile` 与本地 V10A 证据｜周期/配置=C0 fire→C1
clear→C2 no-repeat，`OOO_ASSERT=1/0`｜TB/EDA 观测=pre-fix RED、
focused 双配置 GREEN、6/6 变异检出、113/113 module、
functional/architecture 同 design-id｜范围=PASS（V10A pending
architectural-trap 子切片）；GAP（记录层与更宽目标）

## 逐项裁决

- request priority：PASS。`drained_pending_control_w` 显式包含
  `!core_commit_exception_trap_o`，commit trap 同拍只产生
  `trap_mem_valid_o`；`CsrFile` 保留 `mem > ex > irq` 单记录选择。
  pre-fix 日志以 4 个 `[CHECK-FAIL]`、`status=1` 形成 RED；修复后出现
  `[V10A-COMMIT-TRAP-PRIORITY-PASS]`。
- same-edge birth onehot：PASS。IRQ、head0 architectural trap、lane1
  architectural trap 与 SYSTEM capture 的组合排除项成立，日志出现
  `[V10A-BIRTH-ONEHOT-PASS]`。
- live-owner 对 ECALL/IRQ/xRET/CSR/FENCE：PASS。
  `pending_arch_trap → stop_pending_busy → !can_run → !capture_base_w`
  构成生产逻辑互斥；五类均被动态阻止并出现
  `[V10A-LIVE-OWNER-OVERLAP-PASS]`。
- C0/C1/C2：PASS。C0 exact terminal 产生一次 `trap_ex_valid`；同沿
  `drain_clear_w` 清 architectural-trap holder，
  `OooStopPendingSequencer` 清 stop，`CsrFile` 采样 PC/tval；C1
  owner/stop/request 均为 0；C2 raw request 与 CsrFile sample 计数保持
  1。日志 marker 为 `[V10A-CLOCKED-EXACTLY-ONCE-PASS]`。
- assert-on/off：两份 focused 日志分别带/不带 `-DOOO_ASSERT`，均有
  `[PASS]` 和 `[RESULT] PASS`。
- 负向版本：`mutations/summary.json` 的 6 个变体均
  `compile_rc=0`、`simulation_rc=1`、预期 marker 命中，覆盖 commit
  mask、head0/lane1 birth exclusion、IRQ priority、owner clear、stop
  clear。
- SHA：合同 SHA 精确匹配
  `77074762c9f75b693fee68f89a166db2bc7b27887220dcd93ee041e7ae0b9a97`；
  当前 9 个生产模块与 TB 哈希均匹配 mutation summary，
  `OooControlPlane.v=1eb6c311…f9997d` 也匹配 architecture provenance。
- 聚合证据：module 为 113/113；functional 为 PASS/exit 0、official
  177/177、AM 59/59、DiffTest mismatch 0；architecture hard gates 为
  `overall_status=GREEN`、exit 0。functional 与 architecture 共用
  `design_id=sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。

## 记录与覆盖 GAP

- 终审时 `task-report.md` 仍是 `IN_PROGRESS`，且入口 design-id 是旧
  `bbb9c951…`；主节点必须在正式收口前更新。
- focused/noassert 原始日志没有 `[RTL-DESIGN-ID]`，其当前源码绑定依赖
  mutation summary 的逐文件 SHA 与 functional aggregate。
- pre-fix RED 日志未嵌入完整源码/TB 快照哈希，因此是有效行为 RED，但不是
  完整加密绑定的历史快照。
- focused TB 未直接计数 `priv_predictor_boundary`/最终 frontend redirect；
  当前 RTL 可由 `trap_ex_valid_o` 的组合 OR 静态推出单次边界脉冲，
  113-module/functional 提供外围回归，但这不是独立的 clocked redirect
  计数。
- 未运行新的综合、STA 或 Power。

可以关闭 V10A pending architectural-trap clocked exactly-once 子切片；
不能据此关闭完整 `SERIALIZE-G1`、八类 pending SYSTEM post-fire 生命周期、
simulation exit/Linux terminal、architecture-stable promotion 或 PPA。
`scope_extension_request=无`；置信度为高（子切片），证据记录完整性为中高。

reviewer 已停止全部 WSL 工程命令并归还唯一 Windows→WSL shell ownership。
