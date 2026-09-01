# RV64 AxiCrossbar live 完整写对 target offer 本地候选契约

## 目标与单变量边界

实现 `axi-crossbar-live-pair-target-offer-v1`：当同一 crossbar master 的完整 AW/W pair 在本地
READY 上同拍真实 fire、译码到唯一 inactive target，且没有 edge-old 完整 holder或同 target
冲突时，同拍向 target 呈现 AW/W VALID/payload，不再先进入 holder、下一拍才 grant。

本候选只改变该最窄 live 完整写对：

```text
predecessor: C0 master fire/capture -> C1 held grant/target fire -> C2 registered B
candidate:   C0 master fire + target offer/fire              -> C1 registered B
```

master `AWREADY/WREADY` 继续只由本地 holder/busy Q决定。target READY只播种 edge上的 AW/W sent
位，不得进入 master READY、eligibility、decode、RR、owner选择或 B route。read path、地址译码、
store retirement、precise exception、flush后 escaped-write drain、cache maintenance和memory
ordering均不改变。

## 冻结 predecessor 与资格化

- exact predecessor：`dual-mem-arbiter-idle-write-admission-v1`；
- production design ID：
  `sha256:c50a0c61b76a314939fb8b79eadab15cfdc5f0053623021ec06425d3304528fc`
  （155个production RTL文件）；
- predecessor binary SHA-256：
  `6e9745e5313f3885dca51eae962594d220630053d9535a5bc2be012bc9ab623d`；
- CoreMark predecessor：ROI 4,570,581 / retired 3,183,617；完整
  4,649,043 / commits 3,218,532；
- Dhrystone predecessor：ROI 7,321,712 / retired 4,250,000；完整
  7,351,802 / commits 4,260,624；
- qualification run：
  `2026-09-01-rv64-axi-crossbar-live-pair-offer-qualification-a1`；
- fresh `live_narrow_eligible`：CoreMark 144,201，Dhrystone 600,000；两项均只见 target
  READY=11，但功能实现和验证必须覆盖完整READY四象限。

资格机会数只是local ceiling，禁止机械等同于端到端head-critical cycle；最终裁决只使用本候选
实现后的exact-predecessor workload A/B。

## 四态、冲突与 owner 合同

1. live pair要求 AWVALID/WVALID、holder/busy Q和payload全部精确已知；reset、unknown/illegal RR、
   unknown control或payload均fail closed。
2. edge-old完整holder全局优先；AW-only、W-only、active target与partial pair继续进入holder并走
   既有held-grant路径。
3. 两个master同拍指向同一target时live path action-quiet，两笔都捕获到holder，下一拍由既有
   RR选择；指向不同target时可各自原子取得唯一owner。
4. selected live edge必须原子锁存owner/AW/W payload/ID，分别播种AW/W sent，置master busy、
   更新target RR，并清掉generic capture产生的selected holder残留。
5. live offer拍不得路由或消费B；只有edge-old registered
   `active && aw_sent && w_sent && known owner`才可驱动`m_bvalid`与`s_bready`。
6. early B必须隐藏；B反压期间active/owner/payload/ID/RESP稳定，真实B terminal前busy不释放。
7. target READY X/Z在功能RTL中按no-fire并注册重试；当前`OOO_ASSERT`把target READY X/Z定义为
   非法环境hard failure，不把该情形描述为受支持的接口输入。

## 组合 DAG 合同

为禁止 live AW/W request 通过工具procedural scheduling假关联到response/READY输出：

- master `AWREADY/WREADY`由独立、只读holder/busy Q的组合过程驱动；
- `m_bvalid/m_bresp/m_bid/s_bready`由独立、只读registered active/owner/dual-sent Q和B通道输入的
  组合过程驱动；
- live request/target offer组合过程不得驱动上述两组输出。

该切分不得新增寄存器或协议拍；不得以抑制`UNOPTFLAT`警告代替真实DAG闭合。

## Acceptance criteria

1. xbar release与`OOO_ASSERT` focused TB覆盖live READY `11/10/01/00`、partial retry、payload
   poison、early B、selected holder清理和exactly-once，均PASS。
2. same-target双live冲突、different-target并行、older-holder阻断live、RR X/Z fail-closed、
   B-stall稳定与reset边界均有定向检查。
3. fetch-bridge+xbar integration在`OOO_ASSERT`下PASS；IFU A/D write同拍live offer后flush、B释放和
   LSU排队行为保持。
4. live eligibility被强制关闭的mutation必须被focused TB检测。
5. xbar及直接相关bus/memory的十项`OOO_ASSERT`回归全部PASS。
6. targeted release/assert Verilator lint与stats-on/off current full-top lint均exit 0，无
   `UNOPTFLAT`或error。
7. exact-predecessor CoreMark/Dhrystone均GOOD TRAP、DiffTest ON、code 0，功能输出和ROI retired
   保持；两项ROI不得回归，至少一项严格改善。
8. performance counter与SQ receipts complete/available/conserving，overflow/invalid/malformed为0。
9. fresh production RTL identity在构建后保持，`git diff --check`通过。

## 声明与回退

在same-identity mapped synthesis、STA、area和power前固定`PPA=UNQUALIFIED`、
`promotion_eligible=false`。本地CPI成功只允许保留为local exploratory candidate。

若后续physical timing或更广回归失败，回退边界只包括live-pair target offer、live edge的
owner/payload/sent/busy/RR播种、对应断言/TB，以及为闭合组合DAG做的READY/B-response过程隔离；
不得回退已保留的arbiter IDLE write admission、adapter fall-through或SQ fusion改动。
