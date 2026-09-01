# RV64 adapter input AW/W fall-through：本地 retained 结果

## 结论

保留 `adapter-input-aw-w-fall-through-v1`。它删除完整、合法、自然对齐 single-beat write
在 LSU AXI lane adapter 入口的固定一拍，同时 focused、causal、mutation 与全核 A/B 都没有
观测到 owner、response、split-write 或退休语义回退。

这是 **retained local exploratory A/B**，不是 promotion evidence。每个 design/workload 仅一轮，
未运行 fresh mapped synthesis、STA、area 或 power；因此固定为 `PPA=UNQUALIFIED`、
`promotion_eligible=false`。

## A/B 身份

两边共享当前源码树、`.config`、generated config、冻结镜像、ROI、DiffTest、stats build 与 runtime
参数；唯一有效 RTL source 差异是 `OooLsuAxiLaneAdapter.v`：

| 项目 | exact HEAD predecessor | candidate |
| --- | --- | --- |
| adapter SHA256 | `6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22` | `0199aa2fd75a6ce6b2a087ea6ca2a509cdba11db287224fc4e2be0cdda79b421` |
| virtual/current design ID | `sha256:5220635d6213fbcdfcce8722e6cfcfde290802ecd1b36cc4248e5522fd2f3175` | `sha256:2ebe2537fd1e58a86288506c993f3b321dc7bc2359731751c168f96f9f21291e` |
| binary SHA256 | `7db77c7c27de8d71fb5b84135b1ad6373faca9ced4523a3d21bdb86327e87644` | `5a7ceb0d08355b4b7ced28c1114b11e6e936225dfaa694fbb6d361ac72fa4c26` |
| Verilator manifest SHA256 | `3e3802ccce9f4f9bee371402d8abe2f2cd5cf0a36dda9cd2f3f9d7a86cbeb14f` | `4ccfbd3a992936c2e719b459dc5a90dc3ba17e71b9393c7aef8b3b17c5fc7cb0` |

共同输入：`.config` `63ecfda4...`，`auto.conf` `ed0f2ab...`，`autoconf.h`
`ac5cd649...`，product defaults `7b3b4b57...`，warning override `50d667e4...`。
CoreMark/Dhrystone 冻结镜像分别为 `a7117f74...`、`56c6f020...`。

## 全核结果

| workload | exact ROI cycles / retired / CPI | candidate ROI cycles / retired / CPI | ROI delta | whole-run cycles delta |
| --- | --- | --- | --- | --- |
| CoreMark | `5,262,868 / 3,183,617 / 1.653109655` | `5,141,086 / 3,183,617 / 1.614856938` | `-121,782`，`-2.313985%` | `5,349,799 -> 5,226,858`，`-2.298049%` |
| Dhrystone | `9,751,462 / 4,250,000 / 2.294461647` | `9,151,522 / 4,250,000 / 2.153299294` | `-599,940`，`-6.152308%` | `9,784,102 -> 9,184,130`，`-6.132111%` |

两边都 `HIT GOOD TRAP`、ebreak code 0、DiffTest on；ROI retired 与 whole-run commits 逐项相同。
`COUNTERS_FINAL` 两边均满足 `complete=1`、`available=1`、`overflow=0`、
`invalid_events=0`、`conservation=1`。CoreMark 的 ROI phase 两边对齐。Dhrystone 冻结 ROI
两边都为 `start_lane=1,end_lane=0,phase_aligned=0`，且所有 unknown bucket 为零，因此把它作为
共同边界属性显式声明，而不是伪装成 phase-aligned 证据。

写等待归因与变换一致：CoreMark 的 AXI write-response cycles 从 `551,102` 降至 `412,096`
（`-139,006`）；Dhrystone 从 `2,370,000` 降至 `1,770,000`（`-600,000`）。这支持“write
transport admission 少一拍”的局部因果解释，但不单独证明频率、面积或功耗。

## 正确性与因果证据

- Adapter focused TB：PASS；E0 downstream-ready `11/10/01/00 = 1/1/1/1`；upstream
  `same/AW-first/W-first = 2/1/1`；每个 logical write 的 AW/W 各 fire 一次；reset、invalid、
  sparse、misaligned、split、B response 与 backpressure 均保留。E0 `10/00` 在 admission 后立即
  poison 上游 live payload，fallback 仍逐位使用原始 adapter q；独立 `AWSIZE>3` case 静默阻断
  downstream AW/W 并只返回一次 DECERR。
- Causal probe：candidate `store_terminal=1/3/6`、`peer_admission=3/5/8`；关闭变换的 exact
  predecessor 为 `2/4/7`、`4/6/9`。`peer_b_block=1/3/6`、B-delay unit slope 与 zero early
  peer admission 不变，说明移动的是入口拍，不是 B terminal 或 peer ordering。
- Compile-success mutation：关闭 input fall-through 的 mutation 被动态 oracle 捕获；既有
  final-B fall-through mutation 在更新后的 causal marker 下仍被捕获；两者均恢复 production
  source hash。
- Targeted RTL style、Verilator lint、两个 mutation runner 的 `bash -n` 与 `git diff --check`
  通过。workspace-wide style 只因既存且无关的 `OooBranchLocalPht.v` multiple-modules 规则失败。

## 证据位置

- focused：`evidence/focused/tb_ooo_lsu_axi_lane_adapter.log`
- causal：`evidence/causal/candidate.log` 与
  `evidence/causal/exact-predecessor-expected-fail.log`
- mutations：`evidence/mutations/`
- candidate full-core：`evidence/full-core/candidate/`
- exact predecessor full-core：`evidence/full-core/exact-predecessor/`

关键 raw log SHA256 已写入 `result.json`。exact predecessor adapter 源与双方 Verilator source
manifest 也随证据保存，避免仅凭任务描述重建 A/B 身份。

## 已声明缺口与回退边界

- 单轮结果只够保留候选，不够晋级；promotion 仍需规定的重复顺序与完整 system signoff。
- 没有 fresh mapped STA/synthesis/area/power，因此不得宣称 5 ns timing 或 PPA 合格。
- candidate CoreMark 的 shell-wrapper exit code 没有单独持久化；raw log 内部仍有
  `termination_rc=0`、GOOD TRAP、ebreak code 0 与完整守恒 counter。
- 若以后 mapped timing 或重复 A/B 超预算，只回退 input AW/W fall-through；不得回退 T4I
  lane/split 与 T4N precise-B-terminal 语义。

## 独立审计

独立只读审计结论为 `RETAIN`、`must-fix=0`。审计逐项核对 E0 四矩阵、exact-once、
direct-to-q、invalid/split 排除、B/error/backpressure、flush escaped-write owner 与 READY
组合环，并复核 canonical A/B。完整结论见 `independent-audit.md`。

审计留下的四项非阻断硬化建议中，E0 后 poison live payload、final-B mutation 绝对向量匹配、
write `AWSIZE>3` 三项已在审计后补齐并重跑 PASS。剩余一项是 flush 与 E0 direct handshake
同边沿的 system witness；它不改变本轮 retained 结论，但 promotion 前应补。
