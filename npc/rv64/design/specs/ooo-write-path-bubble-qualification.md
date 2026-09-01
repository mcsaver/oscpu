# OOO 写路径固定空拍资格化

该 stats-only observer 区分三个相邻的 registered boundary：

```text
bridge AW/W
  -> dual-memory arbiter IDLE selection
  -> adapter legal aligned direct offer
  -> crossbar master AW/W holders
  -> crossbar held-pair grant / target owner
  -> target AW/W terminal
  -> registered B -> crossbar/adapter/bridge fall-through terminal
```

它只回答：arbiter selection cycle、crossbar held-pair grant cycle 与 live-pair capture domain 在冻结
workload 中是否频繁出现，以及这些边界各自的独立 AW/W READY 组合是什么。observer 作为诊断 bind
source 注入，并排除在 production RTL file list 之外。

observer 必须复用既有 fail-closed classifier 与 registered state。它可以观察但绝不能驱动 ready、
valid、payload、owner、state、retirement、SQ、cache 或 AXI 信号。输出为单个 versioned marker，
所有 matrix total 必须精确守恒；unknown 或 non-onehot observation 记为错误而不是机会。

任何计数都不等价于一比一 CPI：OoO overlap、双 memory bank、target backpressure 与 ROB-head
criticality 都可能隐藏本地删除的周期。若后续授权功能实现，必须另建 contract，覆盖 owner/partial
handshake focused test、exact-predecessor workload A/B、lint，并在 promotion 前补 fresh mapped PPA。
