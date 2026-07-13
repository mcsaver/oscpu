# T3H FP sticky barrier 任务报告

- task_id: `2026-07-13-rv64-t3h-fp-sticky-barrier`
- baseline: `bd9bfe3bc`
- status: `RTL/function/定向时序 GREEN；fresh 5 ns WNS=-10.10 ns，未达 200 MHz`
- parent goal: full functionality plus fresh 5 ns WNS `>= 0`；仍 active。

## 根因与冻结切点

T3G 已把 integer MEM completion 从 fast select 移除，但 fresh top1 改由
`DCache -> fpld_wb/fp_wake1 -> IntIQ FP-store same-cycle select ->
integer execute/control -> FetchPacketCache en_i` 驱动；同时 DCache→FP exec1
仍为 `-8.149 ns`，FpIQ Q→FP exec1 为 `-3.484 ns`。

T3H 原子切三处消费边界：FpIQ resident fs1/fs2/fs3 与 IntIQ resident
FP-store 只消费 sticky ready，`OooFpPhysRegFile` R0–R3 只读已落账
`regs_q`。wake0/1 仍在 N 沿完成正式写回和 sticky 更新，dependent consumer
最早 N+1 发射；completion/ROB/fflags/commit owner 不变。

## RED 与审查反例

- FpIQ 旧 RTL 在五个 resident wake 场景的 N 拍提前 issue；FP PRF 旧 RTL
  在 write0/write1/同址双写/preg0 的四读口产生 16 个 write-through 失败。
  证据：`evidence/red/fpiq-prf/`。
- IntIQ wake1 旧 RTL 在 N 拍提前发射，证据 `evidence/red/intiq/`。
- 队列级 raw dispatch ready=0 + wake collision 暴露 IntIQ insertion 隐式依赖
  上游 query；证据 `evidence/red/intiq-dispatch-collision/`。
- 独立审查进一步发现整数 `wakeup_match` 会过滤 preg0，不能复用于真实 f0。
  lane0/wake0/p0 与 lane1/wake1/p0 精确 RED，非零两象限继续通过；证据
  `evidence/red/intiq-dispatch-preg0/`。修复为无零过滤的 `fp_wakeup_match`。

## 实现与 GREEN

- `OooFpIssueQueue` 的 resident select 只读 `fs1/2/3_ready_q`；dispatch 两 lane
  仍显式吸收 wake0/1 collision；新增 `[FP-IQ-FP-STICKY-ONLY]`。
- `OooIntIssueQueue` 的 FP-store resident select 只读 `fp_st_ready_q`；两个
  dispatch lane 在 IQ 内显式 OR `fp_wakeup_match`，不依赖上游 query，并保留
  f0/preg0 语义；`[IQ-FP-WAKE-STICKY-ONLY]` 覆盖 issue0/1。
- `OooFpPhysRegFile` 四读口只读 `regs_q`，无 x0 特判；双写同址仍由时序写
  保持 write1 后写覆盖；新增 `[FP-PRF-STORED-ONLY]`。
- focused GREEN 覆盖 fs1/fs2/fs3、wake0/1、dual-source/dual-wake、preg0、
  两 IQ 的 dispatch collision，以及 FP wake 的 kill survivor/recover/flush。
  最终 focused 日志位于 `evidence/green/`。

## 负变异与结构门禁

- FpIQ、FP PRF、IntIQ issue0、IntIQ issue1 四个 negative 各自都只有
  `1 ERROR:` 与 `1` 个目标 marker；见 `evidence/negative/`。
- 全量 module TB：`95/95`，见 `evidence/module-tests-final/summary.txt`。
- Verilator lint、`check-rtl-style`、`git diff --check` PASS。
- `check-contract` 当前/基线均为 `85/85`；baseline 从 59 显式 ratchet 到 85。

## 整核功能与性能

- 系统 Verilator 5.020 首轮因既有 `PROCASSINIT` lint code 不识别失败，未冒充
  代码失败或成功；把 workspace OSS-CAD 5.051 置于 PATH 后重跑。
- 最新源码整核证据：`evidence/core-regress/20260713-135611-2330166/`，
  module/lint/build/AM 全 PASS，official + privileged ISA `177/177`，
  `overall_rc=0`。
- CoreMark 10 iter：GOOD TRAP、CRC `0xfcaf`、`3,020,147 cycles`、
  `3,218,532 commits`、CPI `0.938`、`3.379/MHz`；与 T3G cycle-exact。
  证据 `evidence/coremark-iter10.log`。
- 运行后用户 `build/linux-logs/npc-linux.log` 已由 `/tmp` 副本恢复，SHA-256
  仍为 `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`。

## Fresh 200 MHz 状态

- 综合输入冻结闭合：110 个 synth RTL、128 个 vsrc 与 5 个 flow/config 项的
  pre/post hash 均一致。Yosys 正常结束，三次 check 为零问题；两轮 ABC 均为
  `110 candidates - 5 empty = 105 effective`；网表 `110 module / 110 endmodule`。
- fresh 网表 SHA-256 `f27b937f50fcccec453a5823983de6c26f0efc13baac6823373ea5ad3af2a8f7`，
  已知标准单元面积 `1,572,550.00`，比 T3G 少 `806.12`（`0.051236%`）。四个
  placeholder macro 面积未知，面积与 STA 都不是 physical signoff。
- 独立 OpenSTA 5 ns：`loops=0`、WNS `-10.10 ns`、TNS `-201564.20 ns`、
  功耗代理 `0.120 W`；相对 T3G 的 `-12.979/-287092.31` 改善，但未达 200 MHz。
- 旧 T3G 网表的 17 个集合全部精确命中且 checker RED。fresh 中三个 DCache
  短控制 residual 为 `+1.468/+1.373/+0.155 ns`；检查合同据此修正为“必须存在且
  全部 MET”，避免把合法资源控制弧误判为 write-through。20 个真正 forbidden
  wake/write-through path 全为 `NO_TIMING_PATH`，六类 fanout 只落 owner state，
  checker GREEN。证据见 `evidence/opensta-red-preflight-t3g/`、
  `evidence/opensta-fresh/` 与 `evidence/opensta-focused-fresh/`。
- FpIQ Q→FP exec1 为 `-3.516 ns`；全局新 top 转为 EX0 state→integer fast
  wake/select→PRF fast bypass→ALU/ROB/redirect→Fetch SRAM `en_i`，最差
  `-10.097 ns`。top40 40/40 同起于 `ex0_valid_q`：FPC payload SRAM 1 条，
  fetch outstanding 21 条，CSR 18 条；共同前缀到 ROB 已累计 `11.860 ns`，
  证明并非只有 SRAM setup 假象。父目标继续 active，下一轮优先切 integer EX
  同拍快广播长链。

## 归档与持久化

- fresh synth 的网表、sim 网表、ABC SDC、check/stat、756 MB Yosys 日志、输入
  manifests 与 provenance 已打包为
  `tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/NpcTop-200MHz-t3h-fp-sticky-barrier.tar.zst`
  （22,142,979 bytes），zstd/tar/SHA 全 PASS。
- `/tmp` 相关增量按 T3B–T3H 与 OooIntBackend-A 基线拆成八个 archive，70 个
  顶层对象、754 个 tar entries，单 blob 最大 27,019,588 bytes；NUL source list、
  inventory 与 SHA 均留档。用户日志抽取 hash 仍为 `3d66ffa3…d15`。
- DB-backed project-status、NPC、Yosys-STA、known-issues 均用完整原文
  `update-stored` 追加，写回 bytes 均大于原值；`audit-db-first` PASS。
- `npc-dev` 结构化 profile PASS；strict guard 在 profile 前按预期拒绝缺证据，
  profile 证据包位于
  `.github/task-runs/2026-07-13-rv64-t3h-fp-sticky-barrier-final/`。

## 审查者裁决（当前）

preg0 matcher 与 issue1 negative 两个反例已关闭；T3H 意图内的功能与定向时序合同
均闭合。审查者未把显著改善冒充达标：全局 WNS 仍为负，且 top40 已暴露 integer
EX fast 广播跨越 IQ/PRF/ALU/ROB/redirect 的下一根因。T3H 可作为独立 checkpoint
保留，父目标必须进入下一轮架构切片。
