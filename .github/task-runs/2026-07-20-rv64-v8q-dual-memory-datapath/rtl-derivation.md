# v8q/F0 RTL 四段式推导

## A. 需求语言

未来两条独立 DTLB/D-cache 通路必须能共享当前唯一外部 LSU AXI 口；共享只影响 miss，
不能广播响应、交错事务、在 AW/W 半完成时换 owner，或把 lane bit误当 architectural owner。

## B. 结构语言

在两 bridge 与既有 `OooLsuAxiLaneAdapter` 之间放一个 registered-owner arbiter。IDLE
只采样 contender，不做 fall-through；read 和 write 使用不同 phase，write 用两个 seen bit
吸收 AW/W 任意顺序。response 根据 registered owner 做 1-to-2 demux。

资源共享：单 downstream AXI；寄存状态 3-bit FSM + owner/type/rr + AW/W seen。关键路径是
owner Q 后 2:1 mux，不含 live contender priority。无 flush、无 ProducerId/token/class 状态。

## C. RTL 语言

- `.v` 使用 `always @(*)`、`always @(posedge clk)`、非阻塞时序赋值；不使用
  `always_comb/always_ff` 或 SVA。
- 组合默认值先全置零，再按 state/owner赋值；非 owner READY/VALID by construction 为零。
- IDLE 计算 `laneN_read_present`、`laneN_write_present`、合法 XOR 与 round-robin winner；
  任一 lane dual-type 时全局不捕获；否则时钟沿锁存 owner/type并进入 request state。
- WRITE_DATA 用 `aw_seen_q || aw_fire` 与 `w_seen_q || w_fire` 决定转移；seen 后不再展示
  对应 VALID。
- R/B terminal 同沿回 IDLE并更新 `rr_q=~owner_q`；其余拍 owner/type冻结。
- `rst` 作为全系统同步 reset：组合输出优先静默，沿上清 FSM/owner/type/rr/seen；五态和
  AW-only/W-only reset 后均从冷启动接收新事务，不保留局部 orphan。
- `OOO_ASSERT` 只用过程式 `$error/$fatal`，并保存必要的上一拍 owner/payload shadow。

## D. 行为与声明语言

必须观测 read/write 单 lane、双 lane争用、AR/R/AW/W/B 反压、AW/W 两种错位和 terminal
后公平。定向变异需保持可编译且被专属 oracle 检出。即使 F0 全过，结论也只能是已验证叶构件；
未接入的模块不能让 architecture checker 将 DI-5 置绿，不能产生 PPA promotion 资格。
