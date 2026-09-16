# 规范：AXI4 总线（完整 AXI4 化战役 + AxiCrossbar 契约）

> 状态：**single-beat AXI4 主干已落地；IFU-ACCESS-G1 于 2026-07-13 补齐 read
> ARSIZE/ARPROT 的 slave-side owner 与 execute-device firewall；T4I 已关闭 LSU
> exact-window 外泄，并把 AWSIZE 铺到 slave/external 端；T4R 已把 AxiCrossbar read
> response 收口为严格非穿透的 per-master registered slice**。原始战役侦查存
> `.github/task-runs/2026-07-10-axi4-campaign/evidence/`。
> 动机：现总线是自定义 single-beat AXI-like（带非标 arstrb/aruser/abort 边带，缺
> ID/LEN/SIZE/BURST/LAST），用户要求升级完整 AXI4 并改名 AxiLite*→Axi*；
> 亦是接 ysyxSoC（完整 AXI4，32-bit 数据宽）的前置。

## 1. 目标协议：最小 AXI4 合规子集（零行为变化）

| 信号 | 取值 | 论证 |
| --- | --- | --- |
| ARID/AWID | IFU 恒 4'd0，LSU 恒 4'd1 | xbar 端口本位已区分，ID 陪跑（RV32 legacy NpcSoCAxiBridge 同形态先例） |
| RID/BID | slave 回环；xbar 按 owner 记账路由（现 rd/wr_owner_q 即等价物） | 记账结构不变 |
| ARLEN/AWLEN | 恒 8'd0（单 beat） | 现协议即单 beat；**本刀只搭协议不启用 burst**，SoC 对接刀再做 64→32 降宽+len=1 |
| ARSIZE | IFU instruction halfword=`3'b001`，IFU PTW=`3'b011`；LSU cache line/walk=`3'b011`，uncached 原访问按 1/2/4/8B，misaligned 经 adapter 拆为 byte | **替代 arstrb**；与 address/prot/owner 一起锁存到 slave |
| AWSIZE | IFU PTE write=`3'b011`；LSU aligned 按 1/2/4/8B，misaligned 微写=`3'b000` | 与 WSTRB 一致并锁存到 slave/external 端 |
| ARBURST/AWBURST | 恒 2'b01 (INCR) | 单 beat 下无义 |
| WLAST/RLAST | 恒 1'b1 | 单 beat |
| ARPROT[2] | **替代 aruser**（ifetch=0 表 instruction access 按 AXI 定义 bit2=1 为 instruction——取 AXI 语义：instruction=1） | DPI slave 判据同构替换；ysyxSoC 接口无 user 线 |
| 多 outstanding/interleave | 不支持；xbar per-master busy 记账原样 | 结构不动 |

DATA_W 保持 64。当前 NpcTop 64-bit external slave 端必须真实消费 ARSIZE/AWSIZE；若未来连接
ysyxSoC 32-bit master，仍需独立 64→32 降宽桥，不能拿本轮同宽 lane adapter 越级证明。

## 2. 非标信号消化

- **arstrb 删除**：唯一真消费者 UART 的 RBR pop 判据（`reg_read_strb_i[0]`）改
  「araddr 对齐块覆盖 offset0」——现行 mem 桥对不跨线读恒发"对齐地址+全 1 strb"，
  lane 信息本已丢失，新判据逐位等价。DPI slave 本就无该端口（恒整 8B 读）。
- **aruser→ARPROT[2]**：AxiDpiSlave 的 ifetch/mem_read 选择判据搬迁；virtio 端口
  的 user 吸收线删除。IFU page-table walk 必须是 data (`3'b000`)，instruction data
  必须是 execute (`3'b100`)。
- **abort 边带删除（方案 B：master 自吞）**：
  - mem 桥已有 `drop_rsp_q` 先例——flush 读路径（S_WALK_R/S_READ_DATA）从"立即回
    IDLE 靠 xbar 吞 R"改走既有 drop_rsp_q 等 R 自吞路径；
  - **fetch 桥新增 discard 记账（本战役唯一实质新逻辑）**：mmu_flush 时若 AR 已
    fire 而 R 未回，置 discard 标志、rready 保持、吞完 R 才回 IDLE 接受新请求
    ——吞 R 期间 `fetch_req_ready` 必须压住（防新请求与残 R 串包，最高风险点）；
  - xbar 删 `m_read_abort_i` 与全部 4 处 drop 臂；**"master 暂不 ready 也先收 R
    进 buffer 防 IFU 阻塞 LSU 死锁"的反死锁逻辑必须原样保住**（与 abort 清理
    解耦时的雷区）。

## 3. 实施步骤（每步 module TB+lint+大节点 tohost；S5 后一次性 difftest）

- S1 master 自吞：fetch 桥 discard 记账+mem 桥 flush 读自吞（abort 边带与记账
  双保险并存过渡）；桥 TB 先行（fetch 桥新增"mmu_flush 期在飞 R 吞收"用例；
  mem 桥 `inflight_read_flush_abort` 契约反转=改写点）。
- S2 删 abort：xbar 去边带与 drop 臂；xbar TB 改写。
- S3 换 arstrb/aruser：AR 加 SIZE/PROT；UART/DpiSlave 判据搬迁+等价性用例。
- S4 铺 AXI4 常量位：ID/LEN/BURST/LAST+ID 回环+协议立即断言（AR fire 时
  LEN==0、RID 匹配等——总线模块现状零断言，本刀补齐）。
- S5 改名收口：AxiLite*→Axi*（Xbar/ToUart/Clint/Plic/VirtioBlk），filelist.mk/
  testbench Makefile/NpcSimTop XMR/文档一次收口；顺手清 NpcSimTop L533
  `active_port_q` 悬空引用（现存 bug，CONFIG_NPC_DEBUG_PORTS 下编译失败）。
- 验证收口：difftest（NEMU ref）+riscv 177+AM+CoreMark 10 迭代。

## 4. 风险表

| 风险 | 级 | 缓解 |
| --- | --- | --- |
| fetch 桥 discard 新 FSM 行为（mmu_flush 频繁：sfence/satp/fence.i） | 高 | 吞 R 期 ready 压住；参照 mem 桥 drop_rsp_q+core 侧 discard_fetch_rsp_q 双先例；定向 TB |
| xbar 反死锁逻辑与 abort 清理耦合 | 中 | S2 删臂时逐行核对 L341-348 buffer 释放路径 |
| NpcSimTop XMR 探针族（debug_bus 引 xbar 内部记账） | 低 | 编译期暴露；同步改写 |
| UART RBR pop 判据搬迁 | 低 | 等价性用例 |
| split write 被后续 read 越过 | 高 | lane adapter 单 owner 串行；bridge 所有 store 等聚合 B；xbar 锁 owner 至 B |

## 5. 落地记录（2026-07-10 同日，S1-S5 全部完成）

- **架构定型**：主干（master 桥↔NpcAxiBus↔AxiCrossbar master 口）=完整 AXI4
  （ID/LEN/SIZE/BURST/PROT/LAST 全信号集，单 beat 常量位）；xbar slave 口与
  外设保持 single-beat 子集（read address 侧保留 ARSIZE/ARPROT；简单内部外设可忽略，
  DPI/memory slave 必须消费）。外设文件名 AxiClint/AxiPlic/AxiToUart/AxiVirtioBlk
  已随战役去 Lite 前缀。
- S1（`6db4acedd`）：fetch 桥 S_DRAIN+mem 桥 drop_rsp_q 持械自吞；
  S2（`5d79a0fdf`）：xbar 删 abort 边带与 drop 臂（反死锁 buffer 保留），
  顺手修 NpcSimTop active_port_q 悬空引用；S3-S5（`e3352c7fe`）：arstrb→ARSIZE
  /aruser→ARPROT[2]/常量协议位/RID-BID 回环/UART RBR 判据等价搬迁/全链改名。
- **验证**：module TB 86/86、lint 零告警、check-contract 32；CoreMark
  **cycle-exact（3342044 拍与战役前逐拍一致，零行为变化承诺兑现）** 0xfcaf；
  difftest 收口（NEMU ref）riscv 177/177+AM+CoreMark 全零 mismatch。
- 后续（SoC 对接刀）：64→32 降宽桥+len=1 burst；S4 协议断言（AR fire 时
  LEN==0/RID 匹配）未随刀补，留小刀。

## 5.1 IFU-ACCESS-G1 read owner 与设备执行防火墙（2026-07-13）

- `AxiCrossbar` 的 read grant 同时锁存 `ARADDR/ARSIZE/ARPROT/ARID/owner`；slave
  `ARREADY=0` 时，master 即使撤销 VALID 并改变 payload，slave 侧四拍保持原事务。
- `SLAVE_EXEC_MASK` 默认全 1 以保持通用例化兼容。`NpcTop` 只允许 SRAM、MROM、FLASH、
  PSRAM、SDRAM 与 CHIPLINK_MEM 成为 instruction read 目标；其余 device/MMIO 在仲裁前
  重定向到既有 default-error slave。被拒绝设备永远看不到 ARVALID，因此 UART RBR、
  PLIC claim 等 read side effect 不会发生。
- `AxiDpiSlave` 对 execute narrow read 使用标准 AXI byte lanes：DPI 返回 exact-address
  low window，slave 按 `ARADDR[2:0]` 左移到 RDATA lane；IFU bridge按同一 lane 抽取。
  PTW 保持 aligned 8B data read。
- 本小节当时的 LSU exact-address/low-window 扩展已由 T4I 取代：它现在只存在
  `OooLsuAxiLaneAdapter` 上游的 core-private ABI，不再出现于 xbar/slave/对外端口。
- sized DPI 的 PMEM 路径只验证并读取声明的 `nbytes`，IFETCH 不回落 MMIO；合法的
  PMEM-end 2B fetch 不再被宿主 8B load 扩张。execute firewall 与 DPI IFETCH 拒绝形成
  两层无设备副作用边界。
- 验证：xbar stall/firewall、bridge attributes、LSU control 与 focused integration 8/8；
  module 93/93；真实 guard-page suite PASS；Difftest-ON AM 59/59 + official 177/177。
  该证据关闭功能 owner，不替代 fresh STA 或外部物理 wrapper 接口审查。

## 5.2 T4I LSU standard lane / split（2026-07-14，已落地）

- `OooMemAxiBridge` 保留内部 logical low-window ABI，但只有 cacheable、非跨线 miss 才允许
  aligned 8B line read/fill；uncacheable read 使用 exact PA 与原访问 ARSIZE，不再扩读设备；
- `OooLsuAxiLaneAdapter` 在 NpcCoreTop master 边界把 aligned read/write 映射到标准 byte lane，
  只对完整范围已通过 translation/PMP/PMA 的普通 PMEM misaligned 访问拆成
  byte 微事务并聚合 R/B；MMIO/PTE misaligned 本地 DECERR、零下游副作用；
- bridge 的上游 AW/W fire 现在只代表 adapter capture，因此删除旧
  `bpend_q/store_decouple` 早完成路，所有 store 等待聚合 B；
- AxiCrossbar/NpcAxiBus/NpcTop 将 AWSIZE 与 owner/address 同步锁存并送到 external 端；
- UART/CLINT/PLIC、DPI memory 与 virtio 仿真 wrapper 统一消费标准 lane。旧 exact-window 扩展
  只存在 adapter 上游，不再泄漏到 xbar/slave/physical ABI；
- ysyxSoC 32-bit 降宽仍是明确范围外的另一层 adapter，本切片只关闭当前 NpcTop 64-bit ABI。
- 定向证据：adapter、bridge、xbar、UART/CLINT/PLIC、DPI guard 均 PASS；
  完整 module **100/100** PASS。系统软件与 fresh 5ns STA 由 T4I task-run 给出最终结论。

## 5.3 T4R AxiCrossbar registered R response slice（2026-07-15，已落地）

- 每个 master 各有一组 `rd_resp_valid/data/resp/id_q`，slave R 不再组合穿透到
  `m_rvalid/rdata/rresp/rid`。只有对应 master 的 response slice 为空时，xbar 才向其
  当前 owner slave 拉高 `s_rready`。
- slave 侧 `s_rvalid && s_rready` 握手在时钟沿无条件捕获完整 R payload，并同时释放
  `rd_active/rd_ar_sent` slave owner；捕获不依赖当拍 `m_rready`，也不存在 ready 时旁路。
  因此从 slave R fire 到最早 master R fire 固定增加 **1 cycle**，不是可选 fall-through。
- 捕获后的下一拍起，master 侧只由寄存切片驱动 R valid/payload。`m_rready=0` 时
  valid/data/resp/id 必须逐拍稳定；只有 buffered `m_rvalid && m_rready` 握手才清 slice，
  并释放对应 `rd_master_busy`，在此之前该 master 不接受下一笔 AR。
- slave owner 在 capture 沿即释放，而 stalled master 的 payload 留在自己的 slice；因此该
  master 的反压不会继续占住原 slave，其他 master 仍可按各自 owner/slice 推进。该性质与
  per-master single-outstanding 记账共同构成 read-response 的保序与反死锁边界。

## 6. 变更记录

- 2026-07-10：spec 冻结（最小合规子集+方案 B 自吞+六步实施）。
- 2026-07-10（同日）：S1-S5 落地+difftest 收口（§5）。
- 2026-07-13：IFU-ACCESS-G1 补齐 slave `ARSIZE`、read payload stall owner、动态
  instruction/PTW attributes、standard instruction lanes、sized DPI 与 execute allowlist。
- 2026-07-14（T4I contract）：冻结 LSU logical-window→standard-lane adapter、misaligned byte
  split、uncached exact read 与 slave/external AWSIZE owner。
- 2026-07-14（T4I implementation）：上述 RTL/连接/设备/DPI 收口，删除旧
  PMEM AW/W-fire 早完成路；验证状态见 §5.2。
- 2026-07-15（T4R）：AxiCrossbar R 通道改为 per-master strict registered response slice；
  slave R fire 捕获并释放 slave，master R fire 才释放 slice/master busy，返回固定增加 1 拍且
  反压期间 payload 稳定。
- 2026-07-31：生产 module/file/instance 从 `AxiXbar/AxiXbar.v/u_xbar` 统一为
  `AxiCrossbar/AxiCrossbar.v/u_crossbar`；端口、参数、owner/FSM、周期行为和逻辑拓扑不变。
  历史 test 名与日志 marker 保留原字样，避免改写已冻结证据。
