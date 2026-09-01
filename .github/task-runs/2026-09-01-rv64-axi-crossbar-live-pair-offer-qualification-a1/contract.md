# RV64 AxiCrossbar live 完整写对 target offer 资格化契约

## 目标与冻结身份

本任务只在 retained `dual-mem-arbiter-idle-write-admission-v1` 上确认下一项单变量候选
`axi-crossbar-live-pair-target-offer-v1` 的结构机会，不修改 production RTL。

- predecessor production design ID：
  `sha256:c50a0c61b76a314939fb8b79eadab15cfdc5f0053623021ec06425d3304528fc`
  （155 个 production RTL 文件）；
- diagnostic binary SHA-256：
  `0c69ca1b5053781335cc4b229c0c023d09d8dcf11e0e4d294b4c7bd5906b2e2a`；
- 探针由 `write-path-bubble.mk` 外部 bind 注入，只读取既有状态，不改变功能接口或 production
  design identity。

## Fresh live-pair 机会定义

对每个 crossbar master，仅当同拍同时满足以下条件时计一个 live complete pair：

```text
m_awvalid && m_awready && m_wvalid && m_wready
```

再按 decoded target 的 edge-old active 状态、更老完整 holder、同 target live/held conflict 分桶。
最窄资格机会为：target inactive、没有任何更老完整 holder、没有同 target conflict。资格化不授权
改变 holder、RR、owner、B route 或 target 输出。

所有参与分类的 state、VALID、READY、owner、target 与 holder bit 必须已知；任何 X/Z 均增加
`invalid`。计数必须满足：

- `live_pairs == live_master0 + live_master1`；
- `live_pairs == live_target_inactive + live_target_active`；
- probe complete/available，overflow=0、invalid=0、conservation=1；
- held-grant READY/master/target、arbiter source/READY/lane 账本同时守恒。

## Workload acceptance

使用 predecessor 相同镜像、PC ROI、DiffTest reference 与 runtime 参数：

- CoreMark：ROI `0x800017a8 -> 0x800017b0`，要求
  `cycles=4,570,581`、`retired=3,183,617`；
- Dhrystone：ROI `0x80000334 -> 0x8000047c`，要求
  `cycles=7,321,712`、`retired=4,250,000`；
- 两项均 GOOD TRAP、DiffTest ON、exit code 0，performance counters complete/available/conserving；
- fresh `live_narrow_eligible > 0`，且不得使用旧 design identity 的机会数代替。

## 功能候选授权边界

资格化通过后只授权研究：完整 live AW/W pair 被本地 master READY 接收的同一拍，向唯一 inactive
target 呈现 AW/W VALID/payload，并在该边沿原子建立 registered active/owner/payload/sent。

明确禁止：

- target READY 进入 master READY、eligibility、decode、RR、owner 或 B route；
- AW-only、W-only、staggered pair、active target、older complete holder、unknown/reset 路径 direct；
- live offer 拍路由 B，或在 registered active+dual-sent 前消费 B；
- selected transaction 在 holder 中残留并在 B 后重复发送；
- 改变 store precise terminal、BRESP 异常、flush drain 或 memory ordering。

fresh mapped synthesis/STA/area/power 未执行，PPA 固定为 `UNQUALIFIED`，不得据此 promotion。
