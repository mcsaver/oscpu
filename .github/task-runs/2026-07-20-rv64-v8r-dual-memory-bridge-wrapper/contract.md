# v8r/F1 合同：双 bridge/cache-hit wrapper 与 peer maintenance

## 1. 需求与声明边界

实现一个未接入 canonical core 的本地 RV64 可综合 Verilog-2001 wrapper，装配两份
`OooMemAxiBridge` 与已验证的 `OooDualMemAxiArbiter`。两条 bridge/cache hit 路径必须彼此
独立，只有 miss/PTW/store/A-D AXI 进入共享仲裁；任一已授权 store/A-D `B` terminal 必须向
peer cache 发 conservative valid-only invalidate。

本合同只授权 `dual_bridge_cache_hit_leaf_verified`。它不新增第二 MIQ、bank route、final-PA
SQ query、formal WB credit 或 canonical-core 实例，因此 DI-5、OOO-3、overall 均保持 RED；
复制两份 32KB D-cache 是 architecture prototype，PPA unqualified。

规范真源为 `npc/rv64/design/specs/ooo-dual-memory-datapath.md` §2.7、§3.3、§5.1。

## 2. 六类接口合同冻结

- 端口：wrapper 共享时钟/reset、flush/MMU/DMA 与 CSR/PMP context，暴露两组完整且独立的
  bridge request/identity/response/drop/query/idle 接口及一组 downstream raw AXI。内部固定实例
  `u_bridge0/u_bridge1/u_miss_arbiter`。
- 握手：laneN READY/response 只由 bridgeN 驱动，不合并；同拍两个 hot request 可同拍 fire，
  并在同一 cache 判决拍返回各自 kind/token/epoch/tval。peer maintenance 是无 ready 一拍事件。
- stall DAG：hit 在 arbiter 前终止；miss 才进入 registered F0 owner。F0 state/idle/downstream
  READY 禁止回灌另一 lane hit admission。peer event 只改 valid visibility，不是 SRAM owner。
- flush/recovery：共同 flush 各自执行 bridge exact-owner/drop 合同，F0 锁定 transport 继续 drain；
  killed escaped write 只有既有 captured maintenance authority 可广播；MMU flush 同拍清两 DTLB，
  DMA 同拍清两 D-cache，reset 同域冷启动且不重放维护。
- exception/order：producer event 逐拍等于既有 `dcache_store_commit_w` 与本地维护 address/wstrb，
  覆盖授权 B error、NC/IO、A/D 和 killed escaped terminal；peer 永远只失效、不 RMW。peer 与
  lookup 判决同拍命中 exact line 时必须强制 miss，不能先返回 stale data。
- owner 真源：bridgeN active/station/held response + laneN external expected/tracker/station 是事务
  identity；F0 lane bit只拥有 transport；peer payload只能来自 producer authorized local
  maintenance，wrapper 不重建 owner或合并 completion。

## 3. 缓存优先级与四段式结构结论

`OooDataWordCache` 新增默认关闭的 peer invalidate valid/address/wstrb sideband。参数打开时，
首 line 以及跨 8B 时次 line 只清 `valid_q`，不触碰 `Sram4096x113` 的 en/we/addr/wmask。
valid 优先级固定为 `rst > DMA > peer invalidate > local fill/store`；同地址 fill/RMW 即使写了宏，
peer clear 仍使其不可见；不同 index 的 local update不得被 peer 吞掉。lookup 使用锁存 tag/index
与 peer 首/次 line 做 exact compare，冲突拍组合屏蔽 `lookup_hit_o`；DMA 事件拍也沿用既有
DWC-I10 组合屏蔽两 lane hit。

维护地址冻结为原始 byte PA，合法 `wstrb` 只允许相对该地址的低位连续 1/2/4/8B mask
`01/03/0f/ff`，其它编码由 assertion拒绝；因此跨线公式才允许使用 popcount。`mmu_flush_i`
具有 wrapper carrying contract：断言前两 bridge 必须 idle；事件拍 DTLB `!clear_i` 命中门使旧
翻译不可消费，并压两 lane request READY。同步 reset 从首个采样沿起静默，不承诺异步瞬时清除。

`OooMemAxiBridge` 新增默认关闭的 peer input 参数和三个 maintenance output；output 直接来自
既有 local maintenance wires。wrapper 仅做 lane0->lane1、lane1->lane0 交叉连接，并将两组 raw
AXI 完整接入 F0。wrapper 本身不新增寄存状态。

## 4. 可执行硬门

- release 与 `OOO_ASSERT` focused TB 都必须 fresh 通过；
- 真实 miss/fill 后的同拍双 hit、双 metadata response；
- lane0 miss 锁持有下 lane1 hit 与反向角色；
- peer line 在 request/AW/W 与 B 反压期仍命中、只在 B terminal 后 miss；B/lookup 同拍
  stale-hit 阻断、跨线次行失效、不相关 lookup并行；
- DMA 双 cache、MMU 双 DTLB 结构连接；
- 参数关闭实例即使 peer input 拉高也保持 legacy hit/valid/SRAM-owner 行为；
- peer/local fill 三类 index 冲突矩阵、合法 mask/offset 全枚举、非法 mask assert-negative、
  非 idle MMU flush assert-negative 与 reset 重合矩阵；
- 至少十族 compile-success/elaborated/activated/target-rejected mutation：
  `disconnect_peer_valid`、`self_only_peer`、`swap_peer_addr`、`request_time_maintenance`、
  `b_ok_only_peer`、`drop_cross_line_peer`、`remove_same_cycle_hit_block`、`fill_wins_peer`、
  `gate_lane1_ready_on_arbiter_idle`、`merge_dual_response`；
- fail-closed source/claim checker、F0 permanent target、wrapper/bridge/cache/arbiter/TB/checker/
  mutator/spec/runner/filelist pre/post closure digest 全部闭合；
- checker 必须证明 wrapper 未在 `NpcCoreTop/NpcTop` 实例化，DI-5/OOO-3/overall RED，
  PPA unqualified。

独立 no-tools reviewer 只复核冻结材料中的 owner authority、same-cycle stale-hit、valid priority、
双 hit bypass、flush/reset 与声明边界；每个可操作反例都必须转为 spec/TB/mutation/checker，文本
意见本身不授权 PASS。
