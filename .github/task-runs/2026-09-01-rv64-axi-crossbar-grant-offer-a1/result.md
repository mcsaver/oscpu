# RV64 AxiCrossbar held-grant target offer：本地 retained 结果

保留 `axi-crossbar-held-grant-target-offer-v1` 作为 local exploratory candidate。候选在 crossbar
已经拥有完整 AW/W holder、target 空闲且 RR 已唯一选出 owner 时，直接向 target 呈现 holder Q；
grant 边沿仍注册 active/owner/payload，并用 target 的 AWREADY/WREADY 分别播种 sent 位。B route
继续严格依赖 edge-old registered active + dual-sent，不存在 ownerless 或 zero-cycle B terminal。

## 冻结 A/B

| workload | predecessor ROI cycles | candidate ROI cycles | delta | cycle reduction | speedup | ROI retired |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 4,785,064 | 4,667,639 | -117,425 | 2.4540% | 2.5157% | 3,183,617 / 3,183,617 |
| Dhrystone | 8,481,505 | 7,891,545 | -589,960 | 6.9558% | 7.4758% | 4,250,000 / 4,250,000 |

两项 speedup 的几何平均为 **4.9665%**。全程 cycles 分别为：

- CoreMark：4,868,641 → 4,747,345，减少 121,296；
- Dhrystone：8,512,990 → 7,921,677，减少 591,313。

两项均为 GOOD TRAP、DiffTest ON、终止码 0；SQ region receipt 均为
complete/available/conservation=1、overflow/malformed/invalid=0。CoreMark 的 seed、iterations、四项
CRC 及 ROI retired 完全一致，Dhrystone 的 ROI retired与功能 PASS保持。

CoreMark full commits 为 3,218,519 → 3,218,532，差异全部位于 ROI 之后。优化将
cycle-derived 报告时间从 4786 ms 改为 4668 ms，整数格式化路径因此多执行 13 条动态指令；ROI
边界 retired 完全一致，不能把这 13 条报告指令解释为体系结构差异。Dhrystone full commits
保持 4,260,624 完全相同。

## 因果归因

前置 write-path qualification 在同一 workload 上记录 CoreMark 144,201 次、Dhrystone 600,000 次
held-pair grant，target READY 全为 `11`。本候选的 ROI 减少分别兑现这些动态机会的 81.43% 与
98.33%；该比率只用于机会尺度，不能把每次 grant 机械等同于一个全局 head-critical 周期。

performance-counter-v4 给出更直接的阶段归因：

| workload | counter | predecessor | candidate | delta |
|---|---|---:|---:|---:|
| CoreMark | AXI write response | 414,216 | 276,554 | -137,662 |
| CoreMark | request outstanding | 874,620 | 746,240 | -128,380 |
| CoreMark | memory latency | 1,941,069 | 1,821,427 | -119,642 |
| Dhrystone | AXI write response | 1,770,000 | 1,180,002 | -589,998 |
| Dhrystone | request outstanding | 3,130,161 | 2,530,164 | -599,997 |
| Dhrystone | memory latency | 5,280,354 | 4,690,364 | -589,990 |

Dhrystone 的 write-response residency 几乎逐笔减少 600,000，ROI 同步减少 589,960；write-request
则为 1,279,998 → 1,270,001，没有被本候选错误归因为主要收益。CoreMark 的 OoO 覆盖和 ROI
边界效应更强，但 write-response、outstanding 与总 memory-latency 同向下降。证据符合“删除
held-pair grant 后 target 才看到 AW/W 的固定空拍”，而不是改变退休口径或提前接收无 owner B。

## Correctness evidence

- focused xbar 非真空覆盖 target READY `11/10/01/00`、direct holder payload、partial-only retry、
  poison live payload、grant-cycle early BVALID、same-target RR contention及 RR X/Z fail-closed/resume。
- 新增不同 target 并行 witness：target0→master0 的 registered stalled B 保持稳定时，target1→master1
  仍可 direct grant；target1 grant 拍 `m_bvalid=0/s_bready=0`，注册 owner 后才合法 terminal，两个
  target 的 owner/active互不干扰。
- `OOO_ASSERT` 锁定 master READY 本地公式、direct source/payload、per-channel fire→sent、registered
  B authorization、owner/active/busy稳定、per-master唯一 grant及多拍 B stall。
- xbar、exec firewall、UART、reset syscon、CLINT、PLIC、LSU adapter、memory bridge 共 8 项直接相关
  回归全部 PASS；dual-memory bridge wrapper PASS。
- targeted lint、stats-enabled 全量 lint与 stats-disabled 全量 lint全部 PASS，均无 `UNOPTFLAT`；独立
  RTL终审 must-fix=0，`git diff --check` PASS。

## 身份与声明边界

候选 production design ID 为
`sha256:24849eb786b11715023bb3d512519a0e3bda4c61765686d3c180890e2977572a`，candidate binary
SHA-256 为 `3c7899580a6d7cf03a3500beccfcb760aef5a1433f8d23c4eabd2f070b0e3eae`。focused parallel-B
增强只修改 TB，发生在 candidate binary 构建之后，不改变 production design identity。

本结果只建立功能与本地 CPI retained-point。新增组合锥为
`holder Q + registered RR/target grant → target AW/W VALID/payload`；尚未运行同身份、非 stats mapped
synthesis/STA/area/power，所以固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`，不宣称 5 ns
timing、面积或功耗合格。

当前 RV64 使用并已验证 `M_COUNT=2` 的显式四态 RR case。generic `M_COUNT!=2` 分支的四态 range
guard 尚未单独做综合可移植性资格化；这是 generic configuration gap，不是当前生产配置 blocker。
