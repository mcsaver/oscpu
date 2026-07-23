# NPC (RTL CPU) 模块笔记

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
