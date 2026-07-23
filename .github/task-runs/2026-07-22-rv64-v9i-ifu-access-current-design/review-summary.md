# IFU-ACCESS-G1 当前设计终审材料

## RTL 范围

- 当前对象为 RV64 双发射 OoO 核的 `OooFetchAxiBridge`、`PmpChecker`、
  `AxiXbar`、`AxiDpiSlave`、fetch packet decoder 与 lane0/lane1 precise trap owner 链。
- production RTL design-id 为
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- 结论只覆盖 `IFU-ACCESS-G1`。`IFU-TVAL-G1`、`PTW-PMP-G1`、LSU 标准拆分、
  full-core architecture freeze 与 PPA promotion 保持独立。

## 冻结 transaction 合同

- 两条真实指令长度 `L0/L1∈{2,4}`，取指 footprint `N=L0+L1∈{4,6,8}`；
  miss path 只允许对 `offset<N` 的 halfword 形成 2B instruction read owner。
- execute PMP 或 instruction AXI `RRESP` 的首个失败 frontier
  `F∈{0,2,4,6}` 关闭 transaction；之后不得形成 younger PMP、AR、packet fill 或 SRAM write。
- PMP 架构判定使用当前注册地址、2B、EXEC；固定 4B checker 仅决定 cache candidate
  是否进入 exact slow path。
- instruction read 为 `ARSIZE=1, ARPROT=4`；PTE read 为 `ARSIZE=3, ARPROT=0`；
  ARVALID 反压期间 address/size/prot 由已锁存 owner 保持。
- 当 instruction read 的 `ARPROT[2]==1` 且 `SLAVE_EXEC_MASK[decoded]==0` 时，`AxiXbar` 在 slave
  仲裁前选择 default-error；device slave 无 AR handshake，`ARPROT[2]==0` 的 LSU data read 正控制
  仍命中原 device slave。
- `AxiDpiSlave` 将 AXI size 转换为精确 `nbytes`，并按 `ARADDR[2:0]` 放置标准 AXI byte lane。
- decoder 的 byte frontier 先选择 lane0/lane1 fetch-fault owner，再经 pair、dispatch barrier、
  pending capture、pending state 与 drain CSR request 保持同一 PC/cause/tval。

## 当前动态证据

- `tb_ooo_fetch_access_footprint`：
  `[ACCESS-G1-MATRIX] footprint=4 poison=4 alignment=16 rresp=36 rresp_owner=18/18 rresp_sources=12/12/12 walk=12 pmp=14 pmp_owner=6/6 lifecycle=2 sequence=1 PASS`。
  其中 PC lane 为 `0/2/4/6`，三种非 OK RRESP 各 12 行；所有 RRESP fault 行检查
  fill=0、SRAM write=0、younger AR=0 与 terminal 后 quiet window。
- 同一 TB 还覆盖 RRESP 仅在 RVALID/RREADY owner 上采样、older RRESP F0 优先于
  younger PMP F2，以及四 packet 无复位序列的 owner 清理。
- `tb_ooo_fetch_axi_access_attrs`：
  `[ACCESS-G1-ATTRS] instruction_size=1 instruction_prot=4 ptw_size=3 ptw_prot=0 stall_instruction=2 stall_ptw=2 PASS`。
- `tb_axi_exec_firewall`（验证 `ARPROT[2]` instruction 属性的 default-slave 选择及 AR 通道反压保持）：
  `[ACCESS-G1-FIREWALL] stall_cycles=4 ifu_redirect=1 uart_side_effect=0 default_error=2 lsu_data_control=1 PASS`。
- `tb_ooo_ifu_lane1_fault_owner` 保留原 9 行 terminal/squash/poison/pseudo 矩阵，并新增：
  `[ACCESS-G1-OWNER-MAP] rows=12 lane0=6 lane1=6 capture=12 pending=12 drain=12 PASS`。
  新矩阵直接连接 `OooFetchPacketDecode` 的 C/C、C/U、U/C、U/U byte frontier 到
  head fault、pending capture 与 drain output。
- sized DPI：`ifetch_lanes=4`，PMEM 尾界地址只声明并读取 `bytes=2`；相邻 host page 不可读的边界
  oracle 与 `AXI_DPI_SIZED_SUITE_PASS` 同时成立。
- focused 4/4 与 sized DPI suite 已从当前源码重新构建通过；production Verilog 未修改。

## Current-source 负向 RTL 变体

- 共 19 个变体，`compile_success=19`、`dynamic_rejected=19`、
  `source_unchanged=true`。
- source 分布：`OooFetchAxiBridge` 9、`AxiXbar` 3、`OooFetchHeadPairGate` 2，
  `PmpChecker`、packet decoder、frontend dispatch、lane1 capture、pending arbiter 各 1。
- 变体覆盖 instruction tail 多读、忽略或越过 RVALID/RREADY owner 采样 RRESP、错误 PMP
  access size/default policy、未完成 packet fill、instruction/PTW `ARSIZE/ARPROT`、
  `SLAVE_EXEC_MASK[decoded]` instruction 属性选择、反压周期错误使用 live `m_araddr_i`、buffered R
  在 master RREADY 前释放、lane1 visibility/barrier/capture/ROB-walk 以及 decoder lane start。
- 两个最初观测等价的 lane1 改写未计入结果；最终计数只包含编译成功且产生周期级 RED 的变体。

## 终审核对点

1. 检查 12 行 decoder owner matrix 是否把 F0/F2/F4/F6、C/32 长度与 lane0/lane1
   PC/cause/tval 一一对应，且不存在由安全 C.NOP 形状制造的错误 owner 结论。
2. 检查 RRESP、PMP 与 fill/SRAM monitor 的 phase 是否真正覆盖 accepted beat 之后的 quiet window。
3. 检查 19 个变体是否均为非等价、compile-success 且由相应动态 oracle 拒绝。
4. 只在上述事实可重建时允许 `IFU-ACCESS-G1=CLOSED`；其余 architecture/PPA 边界不得扩张。
