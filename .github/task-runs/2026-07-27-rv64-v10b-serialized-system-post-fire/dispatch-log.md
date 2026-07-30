# V10B dispatch log

## 2026-07-27 root start

- RTL object:
  `OooPendingSystemSequencer` eight canonical kinds through
  `OooPendingDrainResolveGate`, `OooCsrAccessRequestMux`,
  `OooCsrTrapRequestMux`, `CsrFile`, frontend redirect and MMU action.
- cycle/config:
  C0 accepted fire → C1 state/side effect → C2 no-repeat；
  CSR additionally spans enqueue → exact ProducerId/PC commit。
- evidence:
  V10A design-id
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`
  is the parent checkpoint.
- scope:
  `SERIALIZE-G1=OPEN`，simulation exit/Linux/PPA are not promoted by this node.

## 2026-07-27 pre-reviewer-v1 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/pre-reviewer-v1.json`
- contract SHA-256:
  `fb88f47b1d59abf01ea637db7f3a57fee6e76fe58451946025ad40fdbcb84a5e`
- validation:
  canonical `create → validate → render` PASS。
- shell ownership:
  从本条开始移交给 `pre-reviewer-v1`。root 在 reviewer 返回前不运行
  Windows→WSL 工程命令；reviewer 只可执行合同列出的 `rg/sed/sha256sum`
  只读动作，结束后必须显式归还。
- expected output:
  八类 kind 的真实 signal/cycle/action 矩阵、最强 reachable counterexample、
  最小 clocked production-module TB 与 compile-success mutation 建议。

## 2026-07-27 pre-reviewer-v1 result

- RTL verdict:
  canonical kind、CSR exact PID/PC lease 与非 CSR holder/stop clear 的静态
  拓扑未发现已确认 production bug；八类 post-fire 总体为 `GAP`。
- blocking evidence gap:
  SATP/SFENCE/FENCEI MMU action、WFI/FENCE 零副作用和若干 C1/C2
  no-repeat 没有 production 顶层直接计数。
- strongest counterexample:
  切断 `OooMemoryAccess` 的 FENCEI MMU 输入可能仍保留既有 typed redirect
  绿灯；需要 compile-success mutation 动态确认。
- report:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/reviewer-report-v1.md`
- shell ownership:
  reviewer 已停止全部 WSL 工程命令；唯一 Windows→WSL shell ownership
  已归还 root。

## 2026-07-27 final-reviewer-v1 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/final-reviewer-v1.json`
- contract SHA-256:
  `35fdaa2c961b2158d45e9abe078ae7f3028135524fdaf9012ee3f7d5b56a9857`
- validation:
  canonical `create → validate → render` PASS；派发文本为
  `subagent-contracts/final-reviewer-v1.rendered.txt` 原文。
- bound evidence:
  module 113/113、functional PASS、architecture 9/9 GREEN 均绑定
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`；
  focused V2 为 14/14 compile-success RTL version 动态拒绝。
- shell ownership:
  从本条开始移交给 `final-reviewer-v1`。root 在 reviewer 返回前不运行
  Windows→WSL 工程命令；reviewer 只执行合同列出的只读
  `rg/sed/git status/git diff/git show/sha256sum`，结束后必须显式归还。
- review priority:
  raw C0/C1/C2 observation、CSR PID/PC lease、FENCE.I MMU→FPC consumer
  证据是否足够、变异 compile/result 身份、同源 design-id，以及任何
  bounded PASS 向 simulation exit/Linux/full-core arch-stable/PPA 的越界。

## 2026-07-27 final-reviewer-v1 result

- verdict:
  八类 bounded transaction 行为链未发现 production RTL 反例，但终审为
  `GAP`，不能签署证据闭合。
- retained counterevidence:
  `wfi-g1-exclusion.json` 仍绑定旧 design-id；reviewer v1 合同把真实
  `frontend/OooFetchAxiBridge.v` 误写为 `memory/OooFetchAxiBridge.v`；
  V2 matrix 未记录三个辅助 TB SHA 与显式 design-id。
- marker issue:
  `fencei-reason-to-serial` 的局部
  `[V10B-SYSTEM-MIXED] ... PASS` 可在先前 typed-reason
  `CHECK-FAIL` 后打印；最终 `[RESULT] FAIL` 正确，因此 14/14 rejection
  未假绿，但局部 marker 不可作为独立证据。
- strongest rejected RTL version:
  切断 `OooFetchAxiBridge.clear_i(mmu_flush_i)` 后，stale hit/response
  出现、AXI refetch 消失并返回旧 instruction packet；compile success，
  最终 `[RESULT] FAIL`。
- bounded reviewer conclusion:
  八类 transaction 可各自判 PASS；FENCE.I production MMU pulse、静态
  `NpcCoreTop` wiring 与 FPC consumer 动态 test 构成 bounded 组合证明，
  不等价于完整 self-modifying program、Linux 或系统级证明。
- shell ownership:
  reviewer 已停止全部 WSL 工程命令并归还唯一 lane。

## 2026-07-27 final-reviewer-v2 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/final-reviewer-v2.json`
- contract SHA-256:
  `47102bd84f587b9ff99e3d4edd63d66b7404fb829d0e232e828183a0e30a8420`
- validation:
  canonical `create → validate → render` PASS；v2 增加真实
  `frontend/OooFetchAxiBridge.v`、`DecodeUnit.v`、双 memory bridge、
  V3 matrix 与 module-current-v3。
- corrective evidence:
  四个 cohort exclusion 已经既有 fail-closed rebind 工具更新为
  `sha256:13d868...c951`；V3 为 3 baseline PASS、14/14
  compile-success version 动态拒绝；四个 TB SHA 与每 case oracle SHA
  已落入 summary；113/113 module 日志全部携带相同 design-id。
- retained broader GAP:
  full-core ledger updater 在
  `npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json`
  处 fail-closed；v2 不得把 bounded V10B PASS 外推为 full-core
  current ledger、simulation exit、Linux、arch-stable 或 PPA。
- shell ownership:
  从本条开始移交给 `final-reviewer-v2`；root 暂停 Windows→WSL 工程命令，
  reviewer 结束后必须显式归还。

## 2026-07-27 final-reviewer-v2 result

- standardized verdict:
  `APPROVED_FOR_CURRENT_SCOPE`。
- bounded RTL conclusion:
  `CSR / ECALL / XRET / WFI / SFENCE_FAMILY / FENCEI / FENCE / IRQ`
  的 C0 terminal → C1 clear → C2 no-repeat 合同在当前 design-id 上
  通过；CSR 另通过 enqueue → exact ProducerId/PC commit。
- v1 counterevidence closure:
  Fetch bridge 真实路径已直读；四份 cohort exclusion 已重绑；
  17 个 V3 case 的 testbench path/SHA 与当前四个 oracle 文件一致；
  typed-reason 负向版本的局部与最终 marker 均为 FAIL。
- strongest rejected version:
  切断 `OooFetchPacketCache.clear_i(mmu_flush_i)` 后仍编译成功，但出现
  stale response、无 AXI refetch 与旧 instruction packet，最终
  `[RESULT] FAIL status=1`。
- retained broader GAP:
  `fdg-arch-trap-current.json` 仍绑定旧 design-id/111-module inventory；
  `SERIALIZE-G1` 仍 OPEN。不得外推 simulation exit、Linux、
  architecture-stable、综合/STA/power/PPA。
- report:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/final-reviewer-report-v2.md`
- shell ownership:
  reviewer 已停止 WSL 工程命令并归还唯一 lane。
