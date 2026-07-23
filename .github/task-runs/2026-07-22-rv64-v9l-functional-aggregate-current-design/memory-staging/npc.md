# NPC (RTL CPU) 模块笔记

## RV64 V9L memory ownership and current functional aggregate

### 稳定微架构合同

- `rob_head_launch_open_o` 只授权新的 AMO/SQ request launch，包含 flush/recovery quiet 条件；`rob_head_owner_open_o` 表示当前 exact ROB head 仍 valid 且 unfinished，供已经 launch 的事务在 recovery 期间保持 owner。两者不能互换，post-launch owner 检查必须使用后者并同时比较 ROB index 与 full ProducerId。
- `OooMemAxiBridge` 的 station allow 与 lookup 必须由同一 `rsp_ready_w` response credit 决定；没有 response credit 时不得发起 lookup。retry bank 与 station 可以保存不同 token，禁止项仅是同一 exact retry token 同时出现在 retry Q 与 active/station owner 中。
- 对应生产断言为 `[V9L-SQ-POST-LAUNCH-OWNER]`、`[V9L-SQ-LOOKAHEAD-CREDIT]` 与 `[V9L-RETRY-OWNER-DISJOINT]`；V9L 四个 current-source 编译成功 RTL 变体分别切断这些合同并全部被动态拒绝。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。canonical functional aggregate 为模块 `109/109`、official `177/177`、AM `59/59`、DiffTest mismatch `0`、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000，F0 evidence mutations `11/11`。
- `npc/sim/Makefile` 的递归 backend 调用显式传递 `NPC_HOME=$(BACKEND_DIR)`；外层 AM/NPC 环境中的 platform-root `NPC_HOME` 不再污染 rv64 backend 子 make。该修正属于构建入口绑定，不改变处理器 RTL。
- V8L holder evidence 在 assert/release 共 `8/8` 基线及 `9/9` 编译成功 RTL 变体上通过；汇总产物只替换 runner 自有随机临时目录，并经连续两轮 SHA 文件 `cmp` 验证确定性。producer-holder census 仍保留 `instance_graph_complete=false`、`semantic_complete=false` 和非 GREEN 状态，局部动态证据不提升整核 census。
- 九个 directed architecture gates 为当前 design-id 全 GREEN，arch-stable 审计 `134/134` 单测通过；完整冻结仍为 `GAP`、39 blockers，PPA `UNQUALIFIED`。长期 goal 继续 active。

## RV64 PTW PTE WRITE PMP current design V9K

### 稳定合同

- IFU 隐式 PTE A-bit write checker tuple 为 `(walk_pte_addr_q, 8B, PRIV_S, WRITE)`，LSU load-A/store-D checker tuple 为 `(walk_pte_addr_w, 8B, PRIV_S, WRITE)`；PTE READ grant 不能替代独立 PTE WRITE grant，只覆盖 PTE 前 4B 的 PMP entry 必须对 8B write fail closed。
- grant 后 IFU `AWADDR=walk_pte_addr_q`、`WDATA=ad_pte_q`；LSU `S_AD_UPDATE` 中 `AWADDR=walk_pte_addr_w`、`WDATA=ad_pte_q`。`AWVALID&&!AWREADY` 和 `WVALID&&!WREADY` 期间 payload 保持，AW/W 可以任意合法顺序各接受一次，同一 PTE owner 保持到 AW、W、B 均完成。
- deny 不进入 `S_AD_UPDATE`；IFU 形成 exact `resp0_bytes=F` 与 instruction access fault，LSU 形成原 load/store 的 access fault 而非 page fault。LSU response 反压期间 owner kind/token/MMU epoch/original VA `fault_tval` 和 fault class 保持，deny 到 response handshake 闭区间不得建立 PTE AW/W owner。
- PTW-PMP-G1 的 IFU 边界终止于 bridge successful-prefix/access-fault；lane owner、fault PC 与 `tval` 由 current-design `IFU-ACCESS-G1`/`IFU-TVAL-G1` 独立闭合。本地 PTE WRITE 接口无 `AWPROT` port，不虚构该字段。

### V9K 当前证据

- canonical command：`make -C npc/rv64 check-ptw-pmp`。
- focused 2/2、module aggregate 109/109、schema `npc-rv64-ptw-pmp-evidence-v4`、current-source compile-success RTL variants 28/28 动态拒绝、fail-closed 证据测试 13/13；production RTL SHA 前后一致。
- IFU allow 行阻塞 AW/W 两拍并以 AW-first 分离接受；LSU load-A 为 W-first、store-D 为 AW-first。每行直接检查 checker address-to-`AWADDR`、`AWSIZE=3`、`WDATA/WSTRB` 保持、accepted channel 不重发和 B-after-both。
- IFU deny 覆盖 F=0/2/4/6 与 8B partial-cover；LSU deny 覆盖 load-A readonly、store-D readonly、load-A partial8，在 response READY 延迟 0/1/2/3/5 下共 15 行、33 个 stalled-response 周期，逐拍检查 owner/fault/quiet tuple。
- 12 个 IFU 与 16 个 LSU 变体覆盖 checker WRITE/address/privilege/width、deny/grant polarity、fault class、deny-cycle AW/W、A/D `AWADDR`、split-handshake 后 pending channel 撤回、LSU response token 改接 live input，以及第三个 stalled-response 周期脉冲 AW、W 或 AW+W。
- 任意长 response stall 安全性由完整状态译码证书闭合：AW/W VALID 解码仅包含 `S_WRITE_REQ`/`S_AD_UPDATE`，deny 进入并自保持 `S_RESP` 直到 `rsp_ready_w` 或精确 drop terminal；将 `S_RESP` 加入 AWVALID 的证据变体会使证书 fail closed。response liveness 不从该 safety 证书外推。
- result SHA-256 为 `54d39545dea4a43310501499ad7a1e5d84c1af5e8244c859b0d868fb7774fc49`；raw log SHA-256 为 `1947a4c5f3ae713f28fcf0b19d29155955ee4f8cab5f086f0538877336611ea9`；V5 reviewer 合同 SHA-256 为 `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`，在同一 design_id 的限定范围内 PASS。

### 架构与协作边界

- `PTW-PMP-G1` 在 debt ledger 中为 `CLOSED` 且 `current_design_bound=true`；V9K-V4 字节证明来源重绑只改一份 LSU bridge TB 的 provenance，不改对应 directed record 的非来源语义。
- 共享 freeze validator 已纳入 IFU-TVAL 与 PTW-PMP 证据单测；所有相关 CLOSED result 经 canonical 本地 RTL 仿真重放，final 130 tests PASS。full-core audit 仍为 `GAP`、36 blockers，PPA `UNQUALIFIED`、promotion false。
- 长期 goal 继续 active；下一个直接架构项为 `F0-G1` current functional aggregate，继续使用 versioned RTL task contract 与 Windows→WSL single-flight。

## RV64 IFU precise tval current design V9J

### 稳定合同

- `OooFetchPacketDecode` 以实际 instruction footprint 产生 lane0/lane1 的 instruction PF/AF `fault_tval`；压缩 lane0 后 lane1 owner 为 `PC+2`，若 lane1 的 32-bit instruction 在后半字触及 fault frontier，则 `xEPC=PC+2`、`tval=PC+4`。
- `OooFrontend` 从 FIFO head 投影 lane owner 元数据，`OooFrontendDispatchGate` 只在对应 dispatch READY 接受时形成 barrier fire；READY 低周期不能提前 capture、stop 或写入 cause/PC/tval。
- capture 后 cause/PC/tval payload 由精确 trap owner 路径保持到 pending/drain；`OooStopPendingSequencer` 只传递 stop pending 控制，branch squash 必须清除该控制，不能作为 payload owner。
- 证据解析器要求 24 行联合生命周期清单的顺序、字段和值同时匹配；独立总计数不再足以满足门禁。初始 AXI/PMP/PMEM fault detection 仍由 IFU-ACCESS/IFU-FETCH 等独立合同约束。

### V9J 当前证据

- canonical command：`make -C npc/rv64 check-ifu-tval`。
- focused 8/8、module aggregate 109/109、current-source 可编译 RTL 变体 12/12 动态拒绝、fail-closed 单元测试 12/12；production source SHA 前后相同。
- lifecycle rows 24/24、dispatch READY stall rows 1/1、compressed-control rows 6/6；lane1 PF stall 直接观察 blocked、accepted、pending、drain 四阶段及 `xEPC=PC+2`、`tval=PC+4`。
- result SHA-256 为 `cb26a1d249554758b110725536d3f0291668033dc2b8e58d91139957f8e304da`；raw log SHA-256 为 `7f6c32a09a86388636de3346942cd72a60e0fdc8fa9370b033b03ce03dc5192f`；design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- V1 reviewer 的四项 GAP（frontend head 投影、dispatch READY、stop sequencer 角色、24 行联合清单）均已形成直接证据；V2 限定材料复审 PASS。V2 合同 SHA-256 为 `ccc091eaa009c44e934e2ed310f1527312ad9083b8adde505a31f1741e04378b`。
