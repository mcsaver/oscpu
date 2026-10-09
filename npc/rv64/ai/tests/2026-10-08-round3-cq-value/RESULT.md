# R3：同拍取消发布与 CQ 确值旁路

状态：**本轮完成。** 实现、功能/机制验证、两个完整基准、标准 STA 和补充物理诊断均已完成。联合 R3 未达到预设时序目标，判定不保留；工作树已精确恢复 B，候选与证据已归档。

## 目标与网页来源

本轮继续用户选择的“网页 Pro 负责架构设计、Codex 实现验证”工作流。
[网页会话](https://chatgpt.com/c/6ac75b60-4c68-83e8-a930-6b7172a0aec4)在收到完整拓扑和测量附件后，
提出联合 R3：`LOCAL_CANCEL_PUBLISH + CQ_VALUE_BYPASS`。
[完整原答](../2026-10-08-topology-handoff/response.txt)与[落地前源码核查](../2026-10-08-topology-handoff/LOCAL-REVIEW.md)
保留原始设计与实际接口修正。架构取舍由该网页会话提出；本地子代理用于实现和验证。

[实验约定](EXPERIMENT.md)：同一完整 R3 的两个完整基准均不退步且至少一项周期下降 0.5%；
setup WNS 改善至少 0.10 ns，setup TNS 与 hold 不恶化；真实消费者提前且功能合同正确。
这些是本轮实验条件，不能替代正式 1 ns 时序或 PPA 签核。

## 实现边界

- Commit 同边沿维护 `publish_q`，严格投影原 full-flush 条件，并与原公开控制输出逐拍对照；没有延后一拍 flush。
- 保留 canonical kill；将 pure partial 资格和候选行传到 LSU，由最终消费者组合全清和 partial，保留晚到响应 drain。
- birth 时保存目的凭据，经 LSQ/raw/full-forward/CQ 传递；只有普通、对齐、无错误、非副作用、非零 GPR load 可提供确值。
- CQ 的两路确值使用独立的完整 ROB 身份查询，不依赖 WB grant；接入 IQ 初始化/驻留 wake、DEFER_READY 与 RR 实际值快照/shift amount。
- 正常 WB、ROB done、PRF 写回与不可撤销副作用条件保持原语义。新增旁路不承诺正常完成，也不提前释放资源。

11 个 RTL 文件的精确前后差异见 [B→R3 补丁](candidate-vs-baseline.patch)与[改动清单](changed-rtl.json)。
声明状态增量含 269 bit ticket/publish 与 804 bit RR 数据/命中快照小计；最终物理成本必须由综合面积裁决。

## 已完成验证

[四配置机制报告](MECHANISM.md)：56 项完整 NEMU + R64_ASSERT 短测全部通过。
旧 B 与双关逐字段一致，仅取消发布与双关一致，仅值旁路与联合 R3 一致，带/不带 CQ profile 的联合候选一致。
load_chain 普通模式周期 114849→106656（下降 7.1337%）；8193 条主要依赖的 CQ front→issue 从 2 拍变为 1 拍。
load_shift 实际命中新 CQ 直接供值 32 次，背压模式 172 次；身份与数值错误为零。
这些短程序结果不代表完整基准成绩。

[Backend/原生模块报告](VALIDATION.md)：135 个默认模块、1 个 prepared 派生项、34 个配置矩阵项、12 个预期失败检查通过；
另有 2 个 CQ 启用定向测试和 1 个同值冲突预期失败。乘法器原始 60 秒宿主超时保留，同样 20000 向量重跑通过。

LSU 定向覆盖普通/两开关消融、两 lane、CQ 满/背压、skid、LSQ/tag 复用、kill 与 response 同边沿、full flush、
错误/IO/atomic/misaligned 排除、full-forward、store 与副作用边界。
[LSU 日志清单](../../../results/ai-r3-20261008/lsu-modules/logs.json)保留 20 份执行日志。
Commit 两模式对照均通过，启用模式逐拍核对全部原公开输出；见[模式 0](../../../results/ai-r3-20261008/commit-modules/mode-0.log)
和[模式 1](../../../results/ai-r3-20261008/commit-modules/mode-1.log)。

[整核软件汇总](../../../results/ai-r3-20261008/software/SUMMARY.json)：74 项 AM、177 项官方 ISA、101 项 ACT4 全部通过。
AM 的 CLINT 初跑 180 秒宿主超时；相同镜像、仿真器、NEMU 和周期上限，在 600 秒宿主时限下旧 B 与 R3 均通过。
[根因说明](../../../results/ai-r3-20261008/software/clint-investigation/DIAGNOSIS.md)证明这是程序与现有 timer 分频带来的约 100 万周期等待，
没有修改 DUT、oracle 或测试程序。

原生 system-lint 通过。旧文档中的 check-rtl-style/check-contract make 目标在当前入口不存在，未冒称其通过。
直接用真实 filelist 运行 style 脚本时有 13 个既有 multi-module-file 诊断；与 B 归一化逐项相同，新增诊断为零。
本轮没有运行完整 Ubuntu，也没有声称完成正式 release/PPA promotion。

## 完整基准和物理结果

同一固定镜像、完整 NEMU + R64_ASSERT、host threads=1：

| 指标 | 保留基线 B | 联合 R3 | 变化 |
|---|---:|---:|---:|
| CoreMark 10 次 cycles | 8,968,518 | 8,657,378 | −311,140 / −3.46925% |
| CoreMark retired | 3,218,537 | 3,218,537 | 相同 |
| CoreMark CPI | 2.786520 | 2.689849 | 下降 |
| Dhrystone 10000 次 cycles | 14,267,505 | 13,937,006 | −330,499 / −2.31645% |
| Dhrystone retired | 4,260,670 | 4,260,670 | 相同 |
| Dhrystone CPI | 3.348653 | 3.271083 | 下降 |
| setup WNS / ns | −2.119304419 | −2.127002716 | 退化 0.007698297 ns |
| setup TNS / ns | −137,753.000000 | −137,135.406250 | 改善 617.593750 ns |
| hold WNS / ns | −0.036660694 | −0.036660694 | 相同 |
| hold TNS / ns | −0.087889202 | −0.087889202 | 相同 |
| 负 hold 端点 | 3 | 3 | 语义集合相同，无新增 |
| 最终展平单元面积 / μm² | 3,144,021.999995 | 3,161,538.799995 | +17,516.800000 / +0.557% |

CoreMark 五项 CRC 完全相同。Dhrystone 正常完成，退休指令和读写事务数相同。
详见[完整基准对照](../../../results/ai-r3-20261008/BENCHMARK-COMPARISON.json)与
[标准 STA](../../../results/ai-r3-20261008/candidate-sta/R64SystemTop-1000MHz/timing-summary.json)。

面积必须比较两份最终 `sta_area.txt` 的相同口径。中途曾引用 R3 的层次统计 3,220,526.959999 μm²，
与 B 的最终展平统计直接相除得到 +2.433%，口径不一致，已更正；它不是最终可比面积增幅。

基线 B 为第一轮已保留的 response bypass；没有混入已淘汰的第二轮 fixed CQ。
候选基准与综合共用冻结 R3 RTL；STA 保持原 55 nm TT 1.2 V 25°C、1 ns、0.05 ns uncertainty、
原输入延迟/transition、ABC delay/fanout、真实数组及 ICG 检查，没有放宽 reset/flush 路径。
综合与 STA 实际执行完成；make rc=2 来自真实 timing FAIL，不是工具崩溃或缺失网表。
两版都未满足 1 ns。这是 pre-layout mapped STA，不能直接换算成签核 Fmax 或真实整机时间。

[完整物理诊断](PHYSICAL.md)覆盖原目标、内部 Q 起点、CQ→WB、新 CQ→RR/short-owner、publish D/广播和全局 32 个不同端点。

| 路径族最差 setup / ns | B | R3 | 变化 |
|---|---:|---:|---:|
| event_before 类输入 | −2.119304419 | −1.431677222 | 改善 687.627 ps |
| effect 输入 | −2.109362364 | −1.926045656 | 改善 183.317 ps |
| mem_issued 输入 | −2.059357882 | −1.919063687 | 改善 140.294 ps |
| CQ payload 输入 | −2.111715555 | −1.487379909 | 改善 624.336 ps |
| raw payload 输入 | −0.355279922 | −0.472993433 | 退化 117.714 ps |
| 同一 state[18][2] D | −1.855450273 | −2.127002716 | 退化 271.552 ps |

R3 的新全局路径为 `rst_i → full_flush → ROB cancel_candidates[9] → execute.lsu_fire[1] → LSU state[18][2] D`。
同一个状态位的 B 路径经过 cancel[15]，不能把两条路径的局部最大值任意拼接。
在两份实际路径中，lsu_fire[1] 的到达时间 2.224713087→2.072791338 ns，提前 151.922 ps；
其后到 state D 的尾段 0.546298266→0.970248222 ns，增加 423.950 ps。
这定位了抵消前段改善的物理尾段；仍不是某一 RTL 表达式独立造成全部退化的消融证明。

B 整个 state D 族最差为 −2.060335159 ns，距旧全局仅 58.969 ps；该族应作为下一轮明确的近最差约束。
需区分：全局 WNS 退化 **7.698 ps**、同一个 state 位退化 **271.552 ps**、目标 CQ 族改善 **624.336 ps**。
它们是不同范围的真实测量，不能互相替代。局部改进与全局目标未达同时成立。

## 本轮裁决与保留点

**联合 R3 不保留为当前实现。** 性能目标满足，真实消费者提前和完整程序收益均成立；
但 setup WNS 没有改善至少 0.10 ns，反而退化 7.698 ps，已经不满足事先约定的联合条件。
不能以 CoreMark/Dhrystone 的收益替代时序验收，也不能把本次结果表述为“没有性能收益”。

这轮只测一个完整物理设计点。值旁路、取消发布的单独模式只做了功能/短测消融，
不能从两项中挑一半宣称已完成独立整核 PPA 验证。
生产恢复只涉及本轮修改，保持第一轮成果和修改前用户已有内容。
11 个 RTL 与 6 个既有支持文件已恢复，5 个新增 R3 支持文件归档；全部 108 份 vsrc 与本轮前 B 快照逐文件相同。
完整 R3 的 [RTL 补丁](candidate-vs-baseline.patch)、[验证/观测补丁](candidate-support.patch)、
[实验边界](EXPERIMENT.md)、机制、原始命令和测量结果都保留，供后续网页设计使用。
[恢复记录](../../../results/ai-r3-20261008/RESTORE.json)记录了实际文件范围。两个归档补丁均通过 `git apply --check`，
可在该 B 上重新落地候选；检查只验证可重放，没有再次改变当前 B。

## 实测后的网页回访

本轮结果已于2026-10-08返回原网页Pro会话；完整复盘与本地核查见[回访报告](feedback/RESULT.md)。网页确认性能机制有效，承认原方案缺少近最差路径族上限检查与独立物理归因；建议先读现有尾段网表，再做最多三个受控物理点。本次回访未启动新RTL实验，不改变本轮裁决或当前B。
