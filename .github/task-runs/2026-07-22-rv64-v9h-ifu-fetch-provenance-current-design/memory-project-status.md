# YSYX 项目状态总览

## 2026-07-22 RV64 IFU fetch provenance V9H

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `IFU-FETCH-G2` 已由 V9H current-design 证据关闭：focused 2/2、module aggregate 109/109、current-source 可编译 RTL 验证变体 16/16、证据单测 10/10；生产 `.v` RTL 未修改。
- 覆盖 13 行 page-end 矩阵、9 条 F2/F4/F6 fault（5/3/1）、真实 invalid-PTE F0、两拍 response backpressure 事务 owner 保持、接受后两拍无年轻 instruction AR/cache fill/SRAM write，以及成功 packet 后无复位 stale-tail 反例。
- architecture directed gates 为 9/9 GREEN；公共验证入口变化触发的既有 CLOSED 证据已用 5 组 canonical 本地仿真重放恢复 current-design 绑定。
- full-core `architecture_freeze` 仍为 `GAP`，40 blockers；PPA 为 `UNQUALIFIED`，`promotion_eligible=false`。相较 V9G 的 41 blockers，净关闭一个架构债务条目。
- 长期 goal 继续 active；下一轮优先从仍为 `STALE_EVIDENCE` 的 P0（首选与本轮 IFU 数据流相邻的 `IFU-ACCESS-G1`）继续 current-design 重绑定，不把局部闭包外推为全核或 PPA 完成。
