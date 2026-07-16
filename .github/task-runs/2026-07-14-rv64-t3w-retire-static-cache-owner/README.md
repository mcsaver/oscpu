# RV64 T3W — registered retirement, stored static facts, speculative cache lookup

目标：针对 T3V fresh 5.0 ns OpenSTA 及逐层 what-if 暴露的五条真实长链做架构切分，
同时保持完整功能：

1. D-cache SRAM response / internal lookup state 经 WB-to-ROB-head bypass 直达 CSR/trap；
2. FIFO head instruction经 `OooFpDecode`、frontend/backend ready 回路返回取指；
3. staged load 的 DTLB/PMP 授权树串行驱动 D-cache SRAM `addr_i/en_i`。
4. FIFO `head_q` 经动态 MUX4 读取完整 packet，再穿过 classify/RAS/backend-ready/
   flow-control 到 fetch response owner D；
5. IFU `pc_q` 经 ITLB、PC+4 PMP、cache-hit predicate 到 `inst0_q/inst1_q` D。

T3W 的五个对应边界为：

- ROB retirement 的 valid 与全部 payload 只读 ROB Q；WB 仍同拍写 PRF/wakeup，
  completion-to-retire 增加一拍，双写回/双退休稳态吞吐不变；
- 每槽 18-bit instruction-only static facts 在 fault-sanitized response 侧生成，
  与预译码 bundle 原子进入 FIFO，head 侧只结合动态 privilege/mstatus/frm/fault；
- read 在 DTLB/PMP 检查并行时投机读取内部 D-cache SRAM，只有授权通过才进入
  `S_LOOKUP` 并消费结果；fault/walk/miss 不得产生成功响应、外部 AXI 访问或 cache 更新。
- 完整 fetch packet 由一个 registered head shadow 原子呈现；empty enqueue 与单项
  pop+enqueue 直接装新 bundle，count>1 pop 从旧 `head+1` 装载，不增加首包延迟或气泡；
- IFU 在 S_CACHE_READ 拍尾锁存 ITLB hit/permission/translated-or-bare PA，S_LOOKUP 的
  两个 fast PMP checker 只消费 registered PA 与 PA+4；cache SRAM cadence 不变。

## 必须通过的功能证据

- static unit、42-bit legacy differential、FIFO/HeadMux 原子性、lane1 fault owner；
- ROB 双 WB 延后一拍双退、head1 精确异常+trap/GPR side-effect gate、recover survivor；
- 双 WB 同 live ROB idx 的 owner-collision mutation-negative；
- PMP deny、DTLB permission fault 与 TLB miss 在 speculative cache hit 时仍保持精确
  fault/walk owner，无 data AXI AR/hit fusion/cache side effect；
- FIFO empty/one/full pop+push、hold、clear、wrap 完整 bundle；IFU S_CACHE_READ 单拍
  mmu_flush 丢弃 lookup 与 temporal checker owner；
- 全模块回归、Verilator lint/style、NPC build、AM cpu-tests、177 ISA/privileged；
- 受保护 `build/linux-logs/npc-linux.log` 前后 SHA-256 不变。

## 200 MHz sign-off

探索性 what-if 只用于确定下一条路径，不能作为达标证据。必须从本轮冻结 RTL 做 fresh
synthesis，输入前后哈希一致，再以 exact 5.0 ns global OpenSTA 得到：

- `WNS >= 0 ns`；
- `TNS >= 0 ns`；
- combinational loops = 0；
- 结构审计确认 D-cache/ROB WB 到 commit/CSR/trap 不存在旁路 timing path，且
  D-cache response 到 ROB state-D 的真实 5 ns 路径仍受约束；IFU fast PMP 只消费
  registered PA，FIFO 所有生产 head 输出只消费 shadow Q。

未同时满足以上条件时，只记录阶段状态，不宣称 200 MHz 完成。

## 审查补强：static facts 数据面

针对 T3W 审查发现的三个证据洞，增加两条可复现 runner，且不修改正式 RTL：

- `run-static-facts-review-focused.sh`：验证 fetch access fault 的 raw lane1
  `FMV.X.W` 确有非零 18-bit static pack，而 PacketDecode enqueue 与 FIFO head
  白盒观测到的 fault-sanitized NOP static pack 均为全零；同时跨 FIFO 物理回卷
  逐个读回 E/F/G，检查 static/decode/prediction 字段仍为同一原子 entry；
- `run-static-facts-coherence-mutation-negative.sh`：只在 `tmp/` 临时副本中翻转
  lane1 fault entry 的 stored static bit，要求
  `[T3W-STATIC-FACTS-COHERENCE]` 断言命中、测试结果为 `FAIL`、make 返回非零，
  并记录正式 `OooFrontend.v` 运行前后 SHA-256 相同。

对应证据分别落在：

- `evidence/static-facts-review-focused-v1/`
- `evidence/static-facts-coherence-mutation-negative-v1/`

## 审查补强：owner 与 timing cut

- `run-rob-wb-collision-negative.sh`：正向 ROB TB 通过后，以 plusarg 注入两个 WB
  同拍完成同一 live idx，要求 `[T3W-ROB-WB-OWNER-COLLISION]` 命中且仿真非零退出；
- `audit-t3w-structural.py`：fail-closed 检查 ROB Q-only retirement、IFU fast PMP Q owner、
  FIFO packed head shadow 与 D-cache speculative read owner，并在内存中注入三类结构 mutation，
  要求均被审计器捕获；
- `evidence/mem-spec-fault-owner-v1/`：DTLB permission-fault hot-line 与 stale-row TLB miss；
- `evidence/head1-exception-q-retire-v2/`：正常 head0 + load-access-fault head1 的 Q-only
  双退休、lane1 trap 精确选择与异常 lane GPR 写抑制；
- `evidence/boundary-shadow-assert-v2/`：FIFO shadow 与 IFU S_CACHE_READ one-shot flush。
