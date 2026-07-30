# HIST-SER-QH-STOP-HOLD-DROP 独立 RTL 审查

## 结论

RV64 RTL 结论｜对象=`OooStopPendingSequencer.stop_pending_o`、
`OooFrontendRunGate.stop_pending_owner_w/orphan_stop_pending_o/
stop_pending_busy_o/can_run_o` 与
`evidence/stop-hold-matrix/summary.json`｜周期/配置=owner birth→C0/C1/C2，
四语义×assertion on/off｜TB/EDA 观测=8/8 compile-success；current 正向
闭合，historical-pre-T3U 被断言/真实 lane1 capture 拒绝｜范围=PASS（仅
bounded VD3）

审查合同：

- JSON：
  `.github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/subagent-contracts/hist-qh-stop-hold-final-review-v1.json`
- SHA-256：
  `f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`
- 模式：`read-only-review / workspace-files`

## 逐拍复核

- cycle 4 的真实 `head0_csr_dispatch_fire_w` 同拍建立
  `head0_csr_inflight_q` 与 `v9x_head0_csr_owner_birth_w`；日志该采样拍仍显示
  `stop=0,inflight=0`，与 NBA 拍后生效一致。
- current 随后 6 个 inflight 周期满足
  `stop_pending=1, owner=1, busy=1, can_run=0`，owner gap、stop drop、
  inflight run 与 lane1 overlap 均为 0。
- `OooPendingDrainResolveGate.backend_drained_o` 要求 ROB empty，故
  queue-head CSR inflight 期间 `ordinary_drain_root=0`。
- 正确 BNE resolve 的
  `branch_spec_resolve_valid=0, branch_resolve_untracked=0`，不是
  sequencer clear root。
- 两条 CSR 的 raw 事务总数为 C0 commit/barrier/CsrFile `2/2/2`、C1
  typed apply `2`、C2 quiet `2`，没有 `seen/reported` 去重。

## 四种 RTL 语义

| 语义 | assertion on/off | 审查结果 |
|---|---|---|
| current | rc 0/0 | gap/drop/run/overlap 全 0，`RAW-PASS` |
| drop-stop-hold | rc 0/0 | 同样全 0；只证明本 trace 的 successor RunGate owner，不能证明 production hold 可删除 |
| drop-RunGate-owner | rc 2/2 | cycle 5–6 `stop=1, orphan=1, busy=0, can_run=1`；cycle 6 捕获真实 `younger_pc=0x8000001c` lane1 CSR |
| historical-pre-T3U | rc 2/2 | cycle 5 owner gap/run；cycle 6 `stop=0, can_run=1, drain=0`；assertion-on 触发 T3U/V9X，assertion-off 到达真实 lane1 overlap |

两个 source transform 均为 exact-once 文本替换并保留接口：

- sequencer inflight hold diff：
  `757c8b76695a991e22d5a99347287d9e8d6a68daae1c860c1435fc647686aa47`
- RunGate inflight owner diff：
  `868056e814509e8ba87e92cf2121abd76a8b2effda25000a8686e914125b07cc`

组合版本应称为 current-topology `root-cone equivalent`，不能冒充历史提交的
逐字节 checkout。

## 证据与 ledger 判定

- 8/8 case 均 compile-success，negative case 由仿真 oracle 拒绝；
- compile receipt 均 `exists=true` 且 image 非空；
- summary、8 个 case log 与其中声明的 SHA 一致；
- replay 的 summary bytes、case logs 与 allocator-normalized VVP identity
  稳定；raw VVP bytes 不作为稳定 identity；
- 建议把 ledger 从 VD1 提升到 bounded VD3，并把根因修正为
  owner-state + owner-to-busy 双合同；
- ledger 必须注明当前 reconstruction 的 `drain=0` 与 orphan clear，删除
  “hold-only version 必须失败”的旧 required-backfill。

## 范围边界

- `successor_packet_cycles=0`，所以 hold-only survival 不能外推为 production
  删除资格。
- 不提升 VD4，不关闭 formal、full-system、architecture-stable、综合、STA、
  PPA 或 production hold 删除。
- exact historical source 结论需要新合同绑定历史 snapshot；当前 bounded VD3
  不需要扩展。

reviewer 已停止所有只读命令，无工程进程遗留，并明确归还唯一
Windows→WSL shell ownership。
