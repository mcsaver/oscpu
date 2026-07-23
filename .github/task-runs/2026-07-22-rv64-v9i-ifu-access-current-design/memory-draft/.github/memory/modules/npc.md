# NPC (RTL CPU) 模块笔记

## RV64 IFU access current design V9I

### 稳定合同

- `OooFetchAxiBridge` 只为 packet 内 `offset<N` 的 instruction halfword 建立 2B AR owner；`N=L0+L1` 为 4B、6B 或 8B。首个 PMP/RRESP failure frontier 后，不再形成 younger PMP、AR、packet fill 或 SRAM write。
- `PmpChecker` 对当前注册地址的相同 PA、2B access size 和 EXEC 权限判定；unmatched S-mode access 使用 default-deny，固定窗口 checker 只决定是否进入 exact slow path。
- instruction AR 为 `ARSIZE=1, ARPROT=4`，PTW PTE AR 为 `ARSIZE=3, ARPROT=0`；`ARVALID && !ARREADY` 周期内 `ARADDR/ARSIZE/ARPROT` 由锁存 transaction owner 保持。
- 当 `ARPROT[2]==1 && SLAVE_EXEC_MASK[decoded]==0` 时，`AxiXbar` 在 device slave 接受 AR 前选择 default-error；`ARPROT[2]==0` 的 LSU data read 保持原 device path。
- `AxiDpiSlave` 按 AXI size 读取精确 `nbytes` 并按 byte lane 放置；PMEM 尾界 2B oracle 排除读取相邻字节。
- decoder 按 lane0 实际长度决定 lane1 起点；instruction PF/AF 的 PC/cause/tval owner 经 pair、dispatch、capture、pending 与 drain 保持一致。

### V9I 当前证据

- canonical command：`make -C npc/rv64 check-ifu-access`。
- focused 4/4、module aggregate 109/109、负向 RTL 变体 19/19、证据单测 10/10；production source SHA 前后相同。
- footprint 4、invalid-tail 4、RRESP 36（lane 18/18，response 12/12/12）、PMP 14（lane 6/6）、lane owner map 12（lane 6/6）。
- result SHA-256 为 `9776d139c4d9b406187b17008b6657b8094e59600487ad29ee018c283f3c3898`；raw log SHA-256 为 `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。
- no-tools reviewer 合同 SHA-256 为 `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991`，限定材料结论 PASS；未随附逐变体 patch/marker 全文是审计粒度保留项，不扩展结论。

### 架构边界

- `IFU-ACCESS-G1` 已在 debt ledger 中 `CLOSED` 且 `current_design_bound=true`；`IFU-TVAL-G1`、`PTW-PMP-G1`、LSU split transaction、full-core freeze 和 PPA 保持独立。
- 共享冻结验证器变化时，直接绑定该工具的 CLOSED results 必须重跑 canonical；九个 directed records 从 DI-2 根入口按阶段依赖重建，不能从 DI-1 直接启动并越过 sibling inventory 合同。
- final full-core audit 为 GAP、38 blockers、PPA UNQUALIFIED、promotion false；所有 CLOSED debt 的当前 evidence binding 通过。

## RV64 IFU fetch provenance current design V9H

### 稳定合同

- `OooFetchAxiBridge` 用 3-bit `split` 保存跨页 packet 的 successful-prefix 长度；second-page page fault 只能保留 first-page 已成功返回的 byte，fault suffix 必须为零。
- `OooFetchPacketDecode` 按真实 RVC/32-bit instruction byte range 判定每槽是否触及 fault suffix；faulted slot 输出 page-fault 元数据并净化为 NOP，不能读取或传播被 fault byte。
- response backpressure 时，raw packet、response code 与 split 属于已锁存 fetch transaction owner；后来出现的 request candidate 不能改变它们。response 接受后不得继续为 fault transaction 发年轻 instruction AR、cache fill 或 SRAM write。
- F0 是零 successful-prefix 的真实边界：bridge raw packet 为零、split=0、instruction AR=0；decoder 两槽均为 page fault/NOP，`tval` 取 request PC。本合同不替代独立的 PMP/RRESP、物理 footprint、lane1 capture、fault-`tval` lifecycle 或 PTW write PMP 合同。

### V9H 当前证据

- canonical command：`make -C npc/rv64 check-ifu-fetch-provenance`。
- focused 2/2、动态派生 module aggregate 109/109、current-source 可编译 RTL 验证变体 16/16、fail-closed 单元测试 10/10。
- 13 行 page-end 矩阵包含 9 条 F2/F4/F6 fault（5/3/1）；每条 fault 两拍 response backpressure、接受后两拍静默。成功正控制观察到 instruction AR=4、cache fill=1、SRAM write=1。
- 成功 packet 后不复位再执行 F2 fault，证明 tail 清零不是 reset-vacuous；真实 invalid-PTE F0、decoder F0 与 fault-tail poison 分别锁定 bridge 和 decoder 两侧语义。
- result SHA-256 为 `316c990ca24e3f6a097e0d827158a4b70bc35519ee46011e8ff80d73599fb1b0`，raw log SHA-256 为 `d451a36815f23c4ef4f6bb582b7902e31f611613e8f5ed7aadb0c1d900b1cdc4`；生产 `.v` RTL 未修改，design_id 保持 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。

### 架构与协作边界

- `IFU-FETCH-G2` 已在 architecture debt ledger 中 `CLOSED` 且 `current_design_bound=true`；directed architecture hard gates 9/9 GREEN。
- 公共冻结验证器或 canonical 入口发生哈希变化时，既有 CLOSED 结果会 fail-closed。V9H 通过重放 FDG、XRET、memory lifecycle、IFU AXI、INSTRET 的 canonical 本地仿真恢复其 current-source 绑定，不用手工摘要制造假绿。
- full-core 仍为 `GAP`、40 blockers；PPA `UNQUALIFIED`、promotion false。独立无工具复核仅允许关闭本条目，不覆盖其余 IFU、全核冻结或 PPA 门。
- 本地 RTL 子 agent 使用 versioned task contract；no-tools reviewer 不持有工程 shell，主 agent 维持 Windows→WSL single-flight。术语按 module、signal、transaction、cycle 和 configuration 精确定义；措辞准确性不削弱必要推理、反例搜索或验证工具。

## RV64 IFU AXI current design V9G（保留）

- PTE A 位更新的 write owner 由 `state_q=S_AD_UPDATE` 持有；`aw_done_q`、`w_done_q` 独立记录 AW/W accepted，frontend flush 只 sticky-drop 旧 fetch 语义，不能取消已建立的 AXI write owner。
- `AxiXbar` 仅在 BVALID/BREADY fire 时释放 write owner；V9G current evidence 为 focused 3/3、module 109/109、current-source 可编译 RTL 验证变体 18/18，`IFU-AXI-G1` 保持 CLOSED。
