# V13D completion definition — OooLoadQueue release localization

- Parent design-id：`sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`
- Parent `OooLoadQueue.v` SHA-256：
  `5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f`
- 状态：`NEGATIVE_CANDIDATE_ROLLED_BACK`；不进入 Pareto、canonical、architecture seed 或 system promotion。

## 联合修改块

1. `release[01]_ready_hit_w[g]` 保持现有 full-PID、valid、registered completion 与 current-WB
   bypass 资格。
2. 新增每 entry `release[01]_fire_hit_w[g] = release[01]_ready_hit_w[g] &&
   release[01]_commit_i`。
3. 外部 `release[01]_fire_o = release[01]_valid_i && release[01]_ready_o &&
   release[01]_commit_i` 保持既有方程与四态可见语义；entry clear 直接消费本 entry fire bit，
   不再消费 global fire 后再次 CAM。
4. 增加 assertion-off duplicate-PID/unknown-hit 定向反例，证明 local clear 不借用其它 entry ready。

## 完成条件

- 端口、16-entry 状态、full-PID、Q-only pregrant、current-completion leaf bypass、recovery/terminal
  优先级均不变。
- focused LQ 正向与新增 raw-Q 反例 PASS；V11H producer semantic 四配置 PASS；真实 parent、
  DI-5 持续双 memory 与 RTL style PASS。
- baseline/candidate 局部 coarse、mapped、5 ns ideal-clock OpenSTA 可比；只有局部候选未被淘汰时
  才运行 current `NpcTop` coarse，确认没有层级外结构成本转移。
- 独立 reviewer 检查四态、duplicate invalid-state、同拍 completion/commit 与两 lane 互斥边界。

## 停止与回退

- 任一功能、断言、full-PID 或同拍优先级反例失败：整体回退本 slice。
- 局部或 `NpcTop` coarse 面积/mux 明显变差且无 timing 补偿：保留负候选证据后回退。
- full-core mapped/STA、31×2 mutation、完整功能/architecture/system cohort、重复综合与 qualified
  Power 不属于本切片；缺失时只能称 development checkpoint。

实际停止点：local mapped area `+699.44` 且最差 slack `-0.005892515 ns`，候选被 baseline 同时
支配；已保留负候选证据并恢复 parent RTL/TB/spec 哈希。
