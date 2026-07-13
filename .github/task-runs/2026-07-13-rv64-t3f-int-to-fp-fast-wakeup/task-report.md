# RV64 T3F：Integer→FP sticky 时序边界

## 基本信息

- `task_id`: 2026-07-13-rv64-t3f-int-to-fp-fast-wakeup
- `status`: completed（T3F 结构切片；父目标仍 active）
- `profile`: npc-dev
- `base_commit`: eb9bd3b28（叠加 T3B/T3C/T3D/T3E 工作树）
- `trigger`: T3E fresh OpenSTA loops=0 后 WNS=-17.23 ns，top40 全为同一 integer→FP 跨域长路径族
- `parent_goal`: active；完整功能与 physical 200 MHz 尚未闭合

## 根因与决策

FP IQ 把 integer formal WB 同时用作 resident same-cycle select 和 sticky state，integer
PRF read8 又保留 formal write-through，因此 branch kill→WB winner/tag 可继续回穿
FP IQ/PRF/convert。完整契约见 `ooo-int-to-fp-sticky-wakeup.md`。

Reviewer 先否决了只拆 full/fast select 的较弱方案：EX/MEM fast-select 仍会留下
DCache→FpConvert 约 12–15 ns 真跨域路径。冻结方案是所有 integer→FP resident
wake 只在沿上落 sticky，read8 只读已落账 `regs_q`。

## RED 证据

- `tb_ooo_fp_issue_queue`：旧 RTL 在 full-only resident wake 的 N 拍错误
  `issue_valid=1`，其余环境和 N+1 sticky 检查正常。
- `tb_ooo_phys_reg_file`：旧 RTL 在 full-only write0、双写同址、mixed full-only
  lane1 三个场景中均使 read8 沿前误见新值。
- RED 日志已存入 `evidence/red/`，未通过的检查均精准对应本刀合同。

## 接受门禁

1. resident GPR-dependent FP uop 必须 N 不 issue、N+1 用正确 `regs_q` issue；
2. dispatch collision、kill survivor、双 wake lane 不丢单拍 pulse；
3. focused/negative/module/full/ISA/privileged/FP/CoreMark 功能通过；
4. fresh OpenSTA 保持 loops=0，top40 移除 integer wake/read8→FP execute 路径；
5. 只根据 fresh WNS/TNS/PPA 裁决保留，不越级声称 200 MHz。

## 实现者证据

- FpIQ RED 唯一失败为 full-only resident 在 N 拍误 issue；PRF RED 唯三处失败为
  read8 在 full-only write0/双写/mixed lane1 沿前误见新值。GREEN 均精准转绿。
- `OooFpIssueQueue` resident GPR ready 只读 `gpr_ready_q`；formal wake 仅用于
  dispatch lookahead 和时序 sticky。`OooPhysRegFile.read8` 只读 x0-zero/
  `regs_q`。`OooIntBackend` 以同一 `gpr_wb*_write_valid_w` 驱动 PRF write 和 FP
  formal wake，过滤 p0 completion。
- focused 覆盖 wake0/wake1 resident N→N+1、dispatch collision、lane1+wake1、kill
  survivor/younger squash、recover 多拍吸收、flush+dispatch+wake 清空、无关 wake、preg0
  正向和 read8 64-bit 高半，全部 PASS。
- 断言非真空：`[FP-IQ-INT-STICKY-ONLY]`、`[PRF-READ8-STORED-ONLY]`、
  `[FP-INT-WAKE-WRITE]` lane0/lane1 各精准触发 1 次，无其他 ERROR/CHECK-FAIL。
- reviewer 补洞后的最终 module suite `94/94`；Verilator 5.051 clean full build；
  lint/style/contract PASS，断言
  `81 >= 59`。
- core regression `overall_rc=0`：NPC build PASS、AM cpu-tests PASS、official
  RV64I/M/A/C/F/D/Zb + M/S privileged `177/177`。
- CoreMark10 与 T3E 逐周期一致：`2,937,909 cycles / 3,218,573 commits`，
  CPI `0.913`、CRC `fcaf`、CoreMark/MHz `3.474`、GOOD TRAP。
- fresh 5 ns synthesis完成：Yosys `105/105` 有效 ABC mapping、check `0 problems`，
  netlist SHA256 `ed05a3609ff3c23109d3417506768511438bac00eb79f95d20e4fccc24f87654`；
  面积 `1,572,786.04`，较 T3E 增 `0.094%`，OpenSTA power 约 `0.120 W`。
- fresh OpenSTA `loops=0`、WNS `-12.838 ns`、TNS `-284551.97 ns`；相对 T3E
  WNS 改善 `4.392 ns`、TNS 改善 `7118.34 ns`。top40 的旧
  `wb/fast_wb/int_wake -> FP execute` 路径族清零。
- 定向 fanout 进一步证明 `int_wake0/1` 各自仅到达 FP IQ 的 11 个状态触发器
  D/E 端点，没有 FP exec-stage 端点。合法残余路径中，FpIQ state→FpPRF→
  FpConvert→exec 最差 `-3.484 ns`；DCache→FP exec 最差 `-8.058 ns`，属于
  未由 T3F 处理的 FP-load/self-wake 或全局 kill/control 家族。

## 审查者反例与裁决

- 已证明只新增 EX/MEM fast-select 不能满足 5 ns 目标，改用全 sticky 边界。
- 本刀后仍可能暴露 DCache→FetchPacketCache 等约 15 ns 路径，父目标必须保持 active。
- 源码审查未发现 P0；P1 覆盖洞已用 recover/flush/lane1 directed TB 补齐，
  marker 已统一为 `[FP-IQ-INT-STICKY-ONLY]`。fresh top40 与 wake fanout 均确认
  本刀结构边界成立。
- 审查者拒绝越级结论：当前 top40 `40/40` 都从 DCache SRAM 发起，top1 到
  FetchPacketCache SRAM enable，WNS 仍为 `-12.838 ns`，因此 physical 200 MHz
  未达到，父目标保持 active。下一刀应把 integer MEM completion 从 fast
  wake/bypass 降为 formal-only，保留 EX-only fast。
