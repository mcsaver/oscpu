# axi-crossbar-live-pair-target-offer-v1 本地 A/B 结果

## 裁决

`RETAIN_LOCAL_EXPLORATORY`。

候选在exact predecessor `dual-mem-arbiter-idle-write-admission-v1`上同时改善CoreMark与
Dhrystone，功能终止、DiffTest、benchmark输出、ROI retired、完整commits、performance-counter
守恒和SQ receipts全部闭合。fresh production RTL design ID为
`sha256:7aa84e32f7f00330c66e225d482aa6dd35c9e350dac21e7c70c1ef702eb00ccf`，155个production RTL
文件；候选模拟器SHA-256为
`6dd4998bcc5842af10aaf5fe2af7ea65998748ce88d15a20eb4f492f2a0aaec6`。

该裁决只证明功能与本地确定性CPI；没有fresh mapped synthesis、STA、area或power，因此
`PPA=UNQUALIFIED`、`promotion_eligible=false`。

## Exact-predecessor workload A/B

| workload | predecessor ROI cycles | candidate ROI cycles | delta | cycle reduction | speedup | ROI retired |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 4,570,581 | 4,455,744 | -114,837 | 2.512525% | 2.577280% | 3,183,617 = 3,183,617 |
| Dhrystone | 7,321,712 | 6,781,815 | -539,897 | 7.373917% | 7.960951% | 4,250,000 = 4,250,000 |

两项speedup的几何平均为 **5.234694%**。CoreMark回收量为qualification最窄机会的
79.636757%，Dhrystone为89.982833%；这里只报告观测比值，不把机会事件机械宣称为所有
head-critical cycle。

两项均满足：

- `HIT GOOD TRAP`恰好一次、DiffTest `ON`、ebreak termination code 0；
- CoreMark 10 iterations，seed/四项CRC/final CRC `0xfcaf`与PASS输出保持；
- Dhrystone 10,000 runs与PASS输出保持；
- ROI retired精确不变；
- counter `complete=1`、`available=1`、`overflow=0`、`invalid_events=0`、
  `conservation=1`；
- SQ region/final receipt均complete、available、conserving，malformed/invalid/overflow为0。

完整运行cycles/commits也保持语义并严格改善：CoreMark
4,649,043/3,218,532 → 4,533,483/3,218,532；Dhrystone
7,351,802/4,260,624 → 6,811,860/4,260,624。

## Counter attribution

| workload / ROI residency counter | predecessor | candidate | delta |
|---|---:|---:|---:|
| CoreMark memory latency | 1,707,431 | 1,580,518 | -126,913 |
| CoreMark request outstanding | 621,783 | 497,638 | -124,145 |
| CoreMark AXI write request | 163,386 | 163,806 | +420 |
| CoreMark AXI write response | 277,651 | 139,357 | -138,294 |
| Dhrystone memory latency | 4,080,445 | 3,540,506 | -539,939 |
| Dhrystone request outstanding | 1,930,173 | 1,360,178 | -569,995 |
| Dhrystone AXI write request | 669,986 | 679,986 | +10,000 |
| Dhrystone AXI write response | 1,180,002 | 600,000 | -580,002 |

这些字段是ROB-head生命周期的residency cycle，不是AXI transaction计数。候选把常见完整写对提前
一拍送入target，因此大幅减少write-response和outstanding residency；write-request分类的小幅
增加不表示新增真实写事务，完整commits、功能输出与ROI retired均未变化。尤其Dhrystone的
write-response减少580,002、端到端ROI减少539,897，与600,000次fresh live机会方向一致，但仍不
声称一一因果等同。

## 实现与组合 DAG 闭合

`AxiCrossbar`只对精确已知的完整live AW/W pair启用同拍target offer：

- master READY仍只读本地holder/busy Q；live predicate用精确四态
  `{AWVALID,WVALID,AW_HOLD_Q,W_HOLD_Q,BUSY_Q} === 5'b11000`，并要求payload已知；
- edge-old完整holder全局优先；同target双live冲突action-quiet并进入holder/RR fallback，不同
  target可并行取得独立owner；
- live edge原子锁存owner/AW/W payload/ID，按target READY分别播种sent，置busy并更新RR，同时
  清除selected pair的generic holder capture；
- READY `11/10/01/00`后只从registered payload重试缺失channel，accepted channel不重复；
- live offer拍的early B严格隐藏，B仍只由registered active+dual-sent owner授权。

首次full-top lint暴露了monolithic组合过程产生的`UNOPTFLAT`：live request输入被工具调度图
保守关联到同块驱动的master READY/B response，再经IFU A/D completion、peer cache lookup、bridge
ARVALID、dual-memory arbiter回到LSU AWVALID。把live predicate改成Q-only后，路径只从
`m_awready`迁移到同一大块的`m_bvalid`，因此Q-only-alone方案被明确反证。

最终DAG cut不增加寄存器或协议拍：

1. master `AWREADY/WREADY`搬到独立、只读holder/busy Q的组合过程；
2. `m_bvalid/m_bresp/m_bid/s_bready`搬到独立、只读registered active/owner/dual-sent Q和B通道
   输入的组合过程；
3. live request/target offer过程不再驱动上述输出。

stats-on/off full-top lint随后都exit 0且无`UNOPTFLAT`。`OOO_ASSERT`的unpacked shadow arrays只在
checker always中使用，所有检查之后以blocking assignment采样，既避开Verilator
`BLKLOOPINIT`限制，又不改变功能RTL或checker的edge-old观测语义。

## 验证闭环

通过项包括：

- final release xbar与`OOO_ASSERT` xbar focused TB；
- live READY `11/10/01/00`、held fallback READY `11/10/01/00`、partial retry、payload poison、
  early B隐藏、B反压与selected holder清理；
- same-target双live冲突后holder/RR顺序、different-target同拍并行、older complete holder阻断
  新live、sequential target并行、RR X/Z fail-closed与reset；
- `tb_ooo_fetch_axi_bridge_xbar`在`OOO_ASSERT`下确认IFU A/D write同拍live target fire，后续flush、
  delayed B release与LSU排队不变；
- 强制live eligibility为false的独立mutation正常编译，但focused TB以多项live oracle和最终
  `[RESULT] FAIL`检测到；
- xbar、exec firewall、UART/reset syscon/CLINT/PLIC、fetch integration、lane adapter、memory
  bridge、dual-memory wrapper共10项`OOO_ASSERT`回归全部PASS；
- targeted release/assert Verilator lint、stats-on/off full-top lint、JSON/receipt一致性与
  `git diff --check`；
- 两份独立审查未发现functional must-fix，架构审查确认READY+B-response过程隔离是最小正确
  无寄存器DAG cut。

target READY X/Z的当前政策也已固定：功能RTL按no-fire并从registered payload重试，但
`OOO_ASSERT`把target READY X/Z视为非法环境hard failure；本结果不把该输入描述为受支持的
fail-closed测试场景。

## 证据、物理边界与本轮停止

- 机器可读结果：`result.json`；
- SQ receipts：`coremark-sq-receipt.json`、`dhrystone-sq-receipt.json`；
- qualification rich receipts位于相邻qualification任务目录；
- exact source/evidence SHA-256已写入`result.json`；
- candidate raw logs位于
  `/tmp/xbar-live-offer-20260901-a1/full-core/{coremark,dhrystone}.log`；
- candidate binary位于
  `/tmp/xbar-live-offer-20260901-a1/candidate-build/NpcSimTop`。

若后续physical timing或更广回归不合格，回退只限live-pair target offer、live edge
owner/payload/sent/busy/RR播种、对应断言/TB与READY/B-response组合过程隔离；不得回退predecessor
已保留优化。

按本轮用户指定，本最小候选记录闭合后立即中止当前持续优化goal；没有资格化、设计或开启下一项
优化候选。
