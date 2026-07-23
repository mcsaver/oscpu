# YSYX 项目状态总览

## 2026-07-22 RV64 V9L functional aggregate and memory ownership

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。本轮生产 RTL 修正了三项同一内存所有权合同：ROB head 的“可发射”与“发射后仍持有精确 owner”分离；SQ 的 AMO post-launch 检查在 recovery 期间继续要求 exact head/full ProducerId owner；AXI bridge 的 station lookup 只在当前 response credit 可前进时允许，并把 retry residency 限定为同一 exact token，而不是禁止同 bank 的不同 token 同时驻留。
- `F0-G1` 已在当前 design-id 关闭：模块测试 `109/109`、official `177/177`、AM cpu-tests `59/59` 且 DiffTest mismatch `0`、CoreMark `ITERATIONS=10`/CRC `0xfcaf`/GOOD TRAP、Dhrystone `mainargs=10000`/GOOD TRAP；功能证据变体 `11/11` 编译并被拒绝。functional result/aggregate SHA-256 分别为 `3e632a4a8f00ab8d69fc880c8a1e3e8fbf0cbedf240b25a400a8a06f0c25f296` 与 `c09c03742fc26dd99ff638baaf2848496328ee264340f8c9f05f08a5df202793`。
- V9L current-source RTL 验证变体 `4/4` 编译成功并被对应断言拒绝；V8L holder 生命周期 `8/8` 正向基线和 `9/9` 编译成功 RTL 变体通过。V8L 汇总只规范化 runner 自有 `/tmp/v8l-global-lease.*` 路径，两次从零重放的 lifecycle/mutation 产物字节一致，SHA-256 分别为 `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97` 与 `494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`。
- 九个 directed architecture gates 已按当前清单重放并全 GREEN；`architecture-current.json` 与 hard-gate result SHA-256 分别为 `a364e78b6e7fbc92619cb8c09ee33e3732ad7186f84597db6f4c24d8c357c6b1`、`2e501a4cb367d02b77cecdfbb14f439ba8e02cf2707fab24aa2f721226e0ba70`。arch-stable 审计 `134/134` 单测通过，当前结果仍为诚实 `GAP`、`39` blockers、PPA `UNQUALIFIED`、`promotion_eligible=false`；其 SHA-256 为 `784b4953c1db766e4e8efa5a4189d770a6b88d886e86eecdd09e51a741966b00`。
- 12 个已关闭架构债务均已重绑当前 design-id；仍开放的是明确记录的架构语义/范围决策、完整 census、cohort inventory 与 freeze inputs。长期 goal 保持 active，不能把 F0 或 9 个定向门外推为 `ARCH_STABLE` 或 PPA 晋级。

## 2026-07-22 RV64 PTW PTE WRITE PMP current-design V9K

- 当前 RV64 双发射 OoO 生产 RTL design_id 保持 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮只增强 testbench、evidence parser、freeze validator 与当前源码负向变体，生产 `.v` RTL 未修改。
- `PTW-PMP-G1` 已由 V9K schema `npc-rv64-ptw-pmp-evidence-v4` current-design 证据关闭：focused 2/2、module aggregate 109/109、compile-success RTL variants 28/28 动态拒绝、fail-closed 证据测试 13/13。
- WRITE grant 证据把 PMP checker 的 registered PTE physical address 逐位绑定到 `AWADDR`；IFU 以 AW-first、LSU load-A 以 W-first、LSU store-D 以 AW-first 覆盖独立 READY/VALID，stall 期间保持 address/size/data/strobe，每个 channel 恰好接受一次并在 AW/W 均完成后等待 B。
- WRITE deny 证据覆盖 IFU F=0/2/4/6 exact successful prefix，以及 LSU load-A readonly、store-D readonly、load-A partial8 在 response READY 延迟 0/1/2/3/5 下的 15 行、33 个 stalled-response 周期；owner kind/token/MMU epoch/original VA `fault_tval` 与 access-fault class 保持到 response handshake，全区间 `AWVALID=WVALID=0`。
- 任意长 response stall 的安全性由完整状态译码证书独立闭合：生产 RTL 的 AW/W VALID 解码仅包含 `S_WRITE_REQ`/`S_AD_UPDATE`，deny 进入 `S_RESP`，并在 `rsp_ready_w` 之前自保持；3 个额外 LSU 变体在第三个 stalled-response 周期脉冲 AW、W 或 AW+W，均被动态拒绝。response liveness 不从该 safety 证书外推。
- result SHA-256 为 `54d39545dea4a43310501499ad7a1e5d84c1af5e8244c859b0d868fb7774fc49`；raw log SHA-256 为 `1947a4c5f3ae713f28fcf0b19d29155955ee4f8cab5f086f0538877336611ea9`；来源重绑 V4 审计 SHA-256 为 `6e852a89183f9078a101cf834b50a3ce721a99c4c4691d6a82e0960c9e1c02e9`，`pre=RED`、`post=GREEN`且 semantic projection 不变。
- V1/V2/V3/V4 限定材料复核逐步发现 current-source、F=2/4/6、owner snapshot、checker-to-`AWADDR`、split-ready、held-response、第三个 stall 周期与有界长度问题；这些问题均转化为可执行 TB、RTL 断言、compile-success variant 或状态证书。V5 在同一 design_id 的限定范围内 PASS，合同 SHA-256 为 `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`。
- 共享 freeze validator 变更后，所有相关 CLOSED result 已用 canonical 本地 RTL 仿真重放；final audit 的 130 个测试通过。`architecture-current.json` SHA-256 为 `a99bfa190f63ed6edac1e025e668e6a82db91321de746d8171e499e47c844fa4`，`arch-stable-current.json` SHA-256 为 `20a6be5a4e73035792004ccc0ef343866da43edbbc04766c4e8d37e910495912`；full-core `ARCH_STABLE` 仍为诚实 `GAP`、36 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 保持 active；下一个直接架构任务为 P1 `F0-G1` current functional aggregate，不把 PTW-PMP 局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU precise tval current-design V9J

- 当前 RV64 双发射 OoO 生产 RTL design_id 保持 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮只增强 testbench、证据提取器、验证变体与冻结门禁，生产 `.v` RTL 未修改。
- `IFU-TVAL-G1` 已由 V9J current-design 证据关闭：focused 8/8、module aggregate 109/109、current-source 可编译 RTL 变体 12/12 动态拒绝、fail-closed 证据单测 12/12。
- 精确证据包括按顺序解析的 24 行 `cause/layout/F/owner/xepc/tval/capture/pending/drain` 联合清单，以及 lane1 instruction page fault 在 `dispatch1_ready=0` 时不接受、READY 拉高后以 `xEPC=PC+2`、`tval=PC+4` 进入 capture/pending/drain 的直接周期行。
- 三个新增 RTL 变体分别切断 `OooFrontend` head `fault_tval` 投影、`OooFrontendDispatchGate` READY 接受条件和 `OooStopPendingSequencer` branch-squash 清除语义；均由对应 full-core/定向 oracle 动态拒绝。stop sequencer 的端口审计确认其只传递 stop pending，不携带 cause/PC/tval payload。
- result SHA-256 为 `cb26a1d249554758b110725536d3f0291668033dc2b8e58d91139957f8e304da`；raw log SHA-256 为 `7f6c32a09a86388636de3346942cd72a60e0fdc8fa9370b033b03ce03dc5192f`。V1 限定材料复核发现的四个证据缺口均已转为可执行证据；V2 复审 PASS，合同 SHA-256 为 `ccc091eaa009c44e934e2ed310f1527312ad9083b8adde505a31f1741e04378b`。
- 所有已关闭架构条目的 result/raw 哈希已重放并通过账本 `MATCH`；full-core `architecture_freeze` 仍为 `GAP`、37 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 继续 active；下一项 P0 为 `PTW-PMP-G1`，目标是把 PTE WRITE allow/deny、deny 时不产生 AXI `AW/W`、以及 current-source RTL 变体绑定到同一 design_id，不把 IFU-TVAL 局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU access current-design V9I

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮生产 `.v` RTL 未修改。
- `IFU-ACCESS-G1` 已由 V9I current-design 证据关闭：focused 4/4、module aggregate 109/109、PMEM 尾界 2B 读取、编译成功负向 RTL 变体 19/19、证据单测 10/10。
- 证据覆盖 4 个 instruction footprint、36 行 RRESP、14 行 2B EXEC PMP、`ARVALID && !ARREADY` 周期内的 `ARADDR/ARSIZE/ARPROT`、`ARPROT[2]` default-slave 选择，以及 12 行 lane0/lane1 PC/cause/tval owner 生命周期。
- result SHA-256 为 `bf6a81358d70d4b19e6a4ab5431d6e51d12f5c3bca61863d675e9c67f15c56ec`；raw log SHA-256 为 `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。
- 九个 directed architecture gates 已按 DI-2 根依赖链重建并全 GREEN；full-core `architecture_freeze` 仍为 `GAP`、38 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 继续 active；下一轮优先处理仍为 `STALE_EVIDENCE` 的 P0 `IFU-TVAL-G1`，随后处理 `PTW-PMP-G1`，不把局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU fetch provenance V9H

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `IFU-FETCH-G2` 已由 V9H current-design 证据关闭：focused 2/2、module aggregate 109/109、current-source 可编译 RTL 验证变体 16/16、证据单测 10/10；生产 `.v` RTL 未修改。
- 覆盖 13 行 page-end 矩阵、9 条 F2/F4/F6 fault（5/3/1）、真实 invalid-PTE F0、两拍 response backpressure 事务 owner 保持、接受后两拍无年轻 instruction AR/cache fill/SRAM write，以及成功 packet 后无复位 stale-tail 反例。
- architecture directed gates 为 9/9 GREEN；公共验证入口变化触发的既有 CLOSED 证据已用 5 组 canonical 本地仿真重放恢复 current-design 绑定。
- full-core `architecture_freeze` 仍为 `GAP`，40 blockers；PPA 为 `UNQUALIFIED`，`promotion_eligible=false`。相较 V9G 的 41 blockers，净关闭一个架构债务条目。
- 长期 goal 继续 active；下一轮优先从仍为 `STALE_EVIDENCE` 的 P0（首选与本轮 IFU 数据流相邻的 `IFU-ACCESS-G1`）继续 current-design 重绑定，不把局部闭包外推为全核或 PPA 完成。
