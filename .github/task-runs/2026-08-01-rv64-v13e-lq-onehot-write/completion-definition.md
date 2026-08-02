# V13E completion definition — OooLoadQueue onehot entry write

- Parent design-id：`sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`
- Parent `OooLoadQueue.v` SHA-256：
  `5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f`
- 状态：`NEGATIVE_CANDIDATE_ROLLED_BACK`；不进入 Pareto、canonical、architecture seed 或
  system promotion。

## 单机制假设

V13B 已产生 edge-old `alloc[01]_onehot_w`，但随后又编码成 binary index，再用动态 array index
写回 16 个 entry。V13D parent 的局部 mapped 路径显示 allocator/release 控制会进入整条 entry D
mux。候选保留两个 lowest-onehot grant，直接用同 index 的 onehot bit 限定 entry 写使能，删除
onehot→binary index→array decode 往返；预期减少组合 mux/decoder，并把 `alloc*_ready_o` 的全局
归约从 entry D 写入资格中移除。

## 周期与协议等价条件

1. `alloc_free_w` 仍只观察 edge-old `valid_q`；不借用同拍 release/recovery free。
2. `alloc0_ready_o=|alloc0_onehot_w`、`alloc1_ready_o=|alloc1_onehot_w` 不变。
3. lane0 entry fire 为 `alloc0_onehot_w[i] && alloc0_valid_i && !flush_valid_i`。
4. lane1 entry fire 为
   `alloc1_onehot_w[i] && alloc0_valid_i && alloc1_valid_i && !flush_valid_i`；第二 onehot 的存在已
   蕴含 lane0/lane1 ready，故与既有 prefix fire 等价。
5. 两个 onehot 在二态网络以及仿真 known-free overlay 中互斥；保留原 lane1-last 非阻塞赋值顺序，
   不改变非法别名时的 procedural priority。
6. 端口、参数、寄存状态、reset、full ProducerId、entry 生命周期、release/recovery/terminal 优先级
   与 assertion 集均不变。

## 分层验证与停止条件

1. 先运行 `tb_ooo_load_queue`（`OOO_ASSERT`）与 producer semantic
   `GEN_W=1/4 × OOO_ASSERT on/off`，验证双 alloc、prefix、unknown-valid backpressure、raw-Q edge model。
2. 功能成立后复用 V13D 同 source hash、同工具/配置的 local baseline，先跑 candidate coarse；
   coarse 无结构收益则回退并停止。
3. coarse 存活才跑 candidate mapped + 5 ns ideal-clock OpenSTA；area/timing 任一显著退化且无另一项
   足够补偿时，保留负证据后回退。
4. local Pareto 存活才运行真实 parent/DI-5/style；只有 local delta 值得传播时才考虑约 4 分钟的
   `NpcTop` coarse。full-core mapped/STA、power、system 和长时间回放不属于本切片。
5. 独立 reviewer 在交付前检查 onehot 蕴含关系、四态边界、同拍优先级、证据绑定和 PPA 声明等级。

实际停止点：coarse generic cells/mux 虽分别减少 `1,379/1,262`，但 mapped cells/area 增加
`909/1,024.24`，5 ns ideal-clock worst slack 退化 `0.104968071 ns`。标准单元 area 与 timing
同时被 parent 支配；候选已冻结，live RTL/spec 已恢复 parent 哈希。
