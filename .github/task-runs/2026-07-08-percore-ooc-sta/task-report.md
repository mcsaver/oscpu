# 任务报告：任务 1-4 批次——分模块 OOC STA 账本 + flush 单点化完成刀 + write-update + OpenSTA 全核

用户指令："1234 全部按顺序逐个完成，遇 bug 修 bug，要看到全核的综合结果"。四项全部完成。

## 任务 1：7 模块 OOC STA 账本（6 OOC + 1 全核语境）

@100MHz / icsprout55 typ / 占位宏 lib（non-signoff）：

| 模块 | OOC STA 结论 | 余量 |
| --- | --- | --- |
| OooRob | 全 slack MET | ~9.12ns |
| OooIntIssueQueue | 全 MET | ~8.43ns |
| OooFrontend | 全 MET | ~7.03ns |
| OooMemAxiBridge | 全 MET（20 路径） | rpt 在 evidence/ |
| OooFetchAxiBridge | 全 MET | 同上 |
| OooFpBackend | 全 MET | 同上 |
| OooIntBackend | OOC 单跑（含全子树一锅）2400s/5400s 两轮 timeout——账本行采用全核 keep 语境数字（95250 gates/197k area/delay 89，子模块另切）；其时序由 OpenSTA 全核报告覆盖 | — |

关键洞察：**各模块 OOC 皆 MET，但全核 WNS -10ns**——违例不在模块内部，在**跨模块巨型组合锥**（见任务 4）。

## 任务 2：flush 单点化完成刀（P4 收口）

见 `.github/task-runs/2026-07-09-redirect-arbiter-switch/`。OooRedirectArbiter 真源化，
双汇合点切单源，GAP-1 根治/GAP-2 年龄律修复；刀 0 探针前置零 fire、负测试 623 fire→0、
module TB 86/86、core-regress rc=0（OOO_ASSERT 全程）、CoreMark 持平。已提交。

## 任务 3：dcache write-update 恢复

2 拍 RMW + Sram4096x113 bit-write-mask：**dcache miss 139221→3770（-97.3%），
load hit 76.4%→99.30%（收复 SRAM 化前），CoreMark/MHz 0.966→0.980**；
顺手消灭 flush-drain 双 commit 隐患（RMW 化后会 1RW 违约）。已提交。

## 任务 4：OpenSTA 引入 + 全核综合/STA 最终结果（最终 RTL：含四刀全部改动）

- OpenSTA 3.1.0 源码编译落地（venv cmake/swig + 本地 eigen/CUDD + 系统 tcl 头；
  binary `scratchpad/OpenSTA/build/sta`，秒级完成全核 40 万 cell——对照 iEDA 3600s 不收敛）。
- **最终全核综合：5041.49s 完成**（keep_hierarchy 7 模块 + 四黑盒），ABC 10 块独立 mapping：

| 模块 | gates | area | delay(lev) |
| --- | --- | --- | --- |
| OooIntBackend | 95250 | 197k | **89** |
| OooFetchAxiBridge | 93412 | 175k | 50 |
| OooMemAxiBridge | 71381 | 147k | 48（RMW +5k） |
| NpcTop 剩余 | 59395 | 113k | 61 |
| OooFpBackend | 50545 | 107k | **90** |
| OooIntIssueQueue | 30656 | 55k | 27 |
| OooRob | 15230 | 46k | 14 |
| OooFrontend | 13785 | 26k | 42（切换刀 −0.7k） |
| PipeStageReg ×2 | 各 5 | ~11 | 2 |

- **最终全核 OpenSTA @100MHz：WNS -10.31ns / TNS -169177ns**；top10 违例终点全部
  `u_dcache.u_sram` 地址链；典型关键路径**穿 u_ooo_core 199 cell + fetch_bridge 30 +
  mem_bridge 9 ≈ 240 级组合**——顶层控制 FF→core 决策链→bridge→dcache 地址的
  跨模块巨型锥。**当前 RTL 实际 Fmax ≈ 50MHz（typ）**。功耗 45.5mW（无 activity 静态估计，
  宏 0 = 占位 lib 无功耗表）。
- 宏合同 checker 9 PASS（新网表实例检查含）+ iEDA 兼容 PASS。

## 审查者人格

- 全部时序/功耗数字在 **non-signoff 占位宏 lib** 语境（Sram/FP/BPU 时序弧为 1ns 占位）——
  但 -10ns 违例量级远超占位误差，跨模块组合锥是真实架构债；真实宏 lib（fakeram/工艺）
  接入后数字会修正、结论方向不变。
- 全核 iEDA STA 仍不收敛（工具性能墙），OpenSTA 为当前全核时序真源；分模块 iEDA
  可用（6 模块 rpt/pwr 在 evidence/）。
- 各模块 OOC MET 而全核违例 → **时序收敛的下一战场 = P5+ 重新流水化**
  （Decode→Rename→Dispatch / Issue→RegRead→EX 零寄存融合拍，本账本即数据依据）。
- 全状态 difftest 按用户策略仍推迟至重构整体收口。
