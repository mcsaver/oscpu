# 规范：AXI4 总线（完整 AXI4 化战役 + AxiXbar 契约）

> 状态：**single-beat AXI4 主干已落地；IFU-ACCESS-G1 于 2026-07-13 补齐 read
> ARSIZE/ARPROT 的 slave-side owner 与 execute-device firewall**。原始战役侦查存
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
| ARSIZE | IFU instruction halfword=`3'b001`，IFU PTW=`3'b011`；mem 按事务（对齐读/walk=3'b011，跨线窗口读=log2(size)） | **替代 arstrb**（信息量超集）；与 address/prot/owner 一起锁存到 slave |
| AWSIZE | 恒 3'b011，WSTRB 仍是字节权威 | AXI4 合法 |
| ARBURST/AWBURST | 恒 2'b01 (INCR) | 单 beat 下无义 |
| WLAST/RLAST | 恒 1'b1 | 单 beat |
| ARPROT[2] | **替代 aruser**（ifetch=0 表 instruction access 按 AXI 定义 bit2=1 为 instruction——取 AXI 语义：instruction=1） | DPI slave 判据同构替换；ysyxSoC 接口无 user 线 |
| 多 outstanding/interleave | 不支持；xbar per-master busy 记账原样 | 结构不动 |

DATA_W 保持 64（ysyxSoC 32-bit 的降宽桥属 SoC 对接刀，xbar 参数勿写死）。

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
| bpend_q 与单 ID 写保序 | 低 | xbar busy+!bpend_q 双保证；AXI4 同 ID 保序覆盖将来放宽 |

## 5. 落地记录（2026-07-10 同日，S1-S5 全部完成）

- **架构定型**：主干（master 桥↔NpcAxiBus↔AxiXbar master 口）=完整 AXI4
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

- `AxiXbar` 的 read grant 同时锁存 `ARADDR/ARSIZE/ARPROT/ARID/owner`；slave
  `ARREADY=0` 时，master 即使撤销 VALID 并改变 payload，slave 侧四拍保持原事务。
- `SLAVE_EXEC_MASK` 默认全 1 以保持通用例化兼容。`NpcTop` 只允许 SRAM、MROM、FLASH、
  PSRAM、SDRAM 与 CHIPLINK_MEM 成为 instruction read 目标；其余 device/MMIO 在仲裁前
  重定向到既有 default-error slave。被拒绝设备永远看不到 ARVALID，因此 UART RBR、
  PLIC claim 等 read side effect 不会发生。
- `AxiDpiSlave` 对 execute narrow read 使用标准 AXI byte lanes：DPI 返回 exact-address
  low window，slave 按 `ARADDR[2:0]` 左移到 RDATA lane；IFU bridge按同一 lane 抽取。
  PTW 保持 aligned 8B data read。
- LSU data read 暂保 exact-address/low-window 兼容扩展，因为当前 mem bridge 仍会发
  offset5,size4 这类跨 8B lane 的 single beat。它不是 AXI4 signoff 声明；拆分事务属于
  后续 LSU slice。
- sized DPI 的 PMEM 路径只验证并读取声明的 `nbytes`，IFETCH 不回落 MMIO；合法的
  PMEM-end 2B fetch 不再被宿主 8B load 扩张。execute firewall 与 DPI IFETCH 拒绝形成
  两层无设备副作用边界。
- 验证：xbar stall/firewall、bridge attributes、LSU control 与 focused integration 8/8；
  module 93/93；真实 guard-page suite PASS；Difftest-ON AM 59/59 + official 177/177。
  该证据关闭功能 owner，不替代 fresh STA 或外部物理 wrapper 接口审查。

## 6. 变更记录

- 2026-07-10：spec 冻结（最小合规子集+方案 B 自吞+六步实施）。
- 2026-07-10（同日）：S1-S5 落地+difftest 收口（§5）。
- 2026-07-13：IFU-ACCESS-G1 补齐 slave `ARSIZE`、read payload stall owner、动态
  instruction/PTW attributes、standard instruction lanes、sized DPI 与 execute allowlist。
