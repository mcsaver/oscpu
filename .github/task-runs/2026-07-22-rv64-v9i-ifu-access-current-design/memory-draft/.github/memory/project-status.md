# YSYX 项目状态总览

## 2026-07-22 RV64 IFU access current-design V9I

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮生产 `.v` RTL 未修改。
- `IFU-ACCESS-G1` 已由 V9I current-design 证据关闭：focused 4/4、module aggregate 109/109、PMEM 尾界 2B 读取、编译成功负向 RTL 变体 19/19、证据单测 10/10。
- 证据覆盖 4 个 instruction footprint、36 行 RRESP、14 行 2B EXEC PMP、`ARVALID && !ARREADY` 周期内的 `ARADDR/ARSIZE/ARPROT`、`ARPROT[2]` default-slave 选择，以及 12 行 lane0/lane1 PC/cause/tval owner 生命周期。
- result SHA-256 为 `9776d139c4d9b406187b17008b6657b8094e59600487ad29ee018c283f3c3898`；raw log SHA-256 为 `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。
- 九个 directed architecture gates 已按 DI-2 根依赖链重建并全 GREEN；full-core `architecture_freeze` 仍为 `GAP`、38 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 继续 active；下一轮优先处理仍为 `STALE_EVIDENCE` 的 P0 `IFU-TVAL-G1`，随后处理 `PTW-PMP-G1`，不把局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU fetch provenance V9H

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `IFU-FETCH-G2` 已由 V9H current-design 证据关闭：focused 2/2、module aggregate 109/109、current-source 可编译 RTL 验证变体 16/16、证据单测 10/10；生产 `.v` RTL 未修改。
- 覆盖 13 行 page-end 矩阵、9 条 F2/F4/F6 fault（5/3/1）、真实 invalid-PTE F0、两拍 response backpressure 事务 owner 保持、接受后两拍无年轻 instruction AR/cache fill/SRAM write，以及成功 packet 后无复位 stale-tail 反例。
- architecture directed gates 为 9/9 GREEN；公共验证入口变化触发的既有 CLOSED 证据已用 5 组 canonical 本地仿真重放恢复 current-design 绑定。
- full-core `architecture_freeze` 仍为 `GAP`，40 blockers；PPA 为 `UNQUALIFIED`，`promotion_eligible=false`。相较 V9G 的 41 blockers，净关闭一个架构债务条目。
- 长期 goal 继续 active；下一轮优先从仍为 `STALE_EVIDENCE` 的 P0（首选与本轮 IFU 数据流相邻的 `IFU-ACCESS-G1`）继续 current-design 重绑定，不把局部闭包外推为全核或 PPA 完成。
