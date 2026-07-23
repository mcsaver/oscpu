# v8q/F0 合同：双桥共享 AXI miss fabric

## 1. 需求与非目标

实现一个本地 RV64 可综合 Verilog-2001 叶模块，使未来两份独立 memory bridge 能在
cache-hit 路径之后安全共享现有单 AXI LSU 端口。模块必须按完整 read/write transaction
锁住 lane owner，并正确处理 AW/W 独立反压。

本合同不接入 canonical core，不声明 DI-5/OOO-3 GREEN，不发布 PPA，也不修改现有
bridge/backend 语义。规范真源为
`npc/rv64/design/specs/ooo-dual-memory-datapath.md` 的 F0 部分。

## 2. 六类接口合同冻结

- 端口：两个同构 upstream AXI master 子集、一个 downstream AXI master 子集；64-bit
  data/address、8-bit strobe、4-bit ID、8-bit LEN、3-bit SIZE/PROT、2-bit BURST/RESP。
- 握手：IDLE 沿捕获；read 锁到 R fire；write 锁到 AW 与 W 都 fire 后的 B fire；
  `valid&&!ready` payload 稳定。
- stall DAG：request Q/FSM -> registered owner -> downstream mux -> ready -> phase Q ->
  response demux -> lane ready -> terminal；禁止 response-ready 回到 request selection。
- flush/recovery：F0 无 flush；锁定的 transaction 必须 drain。`rst` 是上下游同域的全系统
  同步 reset，允许共同放弃 reset 前事务；`rst=1` 时所有握手输出静默，沿上清 FSM/owner/
  type/rr/seen，解除后冷启动且不得消费孤儿 response。
- exception/order：RESP 逐位透传；AR/AW/W fire 均非 architectural terminal；B 才是 write
  terminal。模块无 ProducerId/token 权限。
- owner 真源：`owner_q/is_write_q/aw_seen_q/w_seen_q/rr_q`；live priority、地址位和
  response ready 均不得替代。

## 3. 状态与优先级

五态：`IDLE -> READ_ADDR -> READ_RESP -> IDLE` 或
`IDLE -> WRITE_DATA -> WRITE_RESP -> IDLE`。两 lane 同时请求时按 `rr_q`，仅一 lane
请求时直接选择；`rr_q` 只在 R/B terminal 后指向另一 lane。非法 read+write 同现不捕获，
且任一 lane 违规时全局不捕获、不更新任何状态、不产生 fire；assert profile 报错。

公平只在明确 progress 假设下按事务计界：两 lane 每个 IDLE 点持续竞争，且当前 owner
最终形成 R/B terminal 时，等待 lane 必须在下一个 IDLE 捕获点获选；无固定周期承诺。

## 4. 产物与硬门

- `npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v`
- `npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv`
- fail-closed checker、compile-success mutation、focused runner、evidence manifest；
- release 与 `OOO_ASSERT` 独立通过；
- 全系统 reset 在五态及 AW-only/W-only 子状态的定向恢复通过；
- 十二个固定 compile-success/elaborated/activated/target-rejected mutation 各有专属失败码；
- 同次运行绑定 RTL/TB/checker/build/mutator digest，pre/post source closure 相同，唯一总 PASS
  只能在全部子门通过后写出；claim checker 证明 F0 未实例化且未发布任何架构 GREEN；
- 独立 no-tools reviewer 必须检查 owner hold、AW/W skew、response isolation、fairness、
  reset/非法输入和 claim boundary；可操作反例必须转成 executable evidence。

验收只授权 `dual_axi_miss_fabric_leaf_verified`。DI-5、OOO-3、overall 和 PPA 均保持 RED。
