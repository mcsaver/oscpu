RV64 RTL 结论｜对象=OooMemAxiBridge→OooDualMemAxiArbiter→OooLsuAxiLaneAdapter→AxiCrossbar→AxiDpiSlave AXI AW/W/B 事务链｜周期/配置=f72e 当前 E0-E4=4 cycles；adapter-input-aw-w-fall-through-v1 理想候选=3 cycles｜TB/EDA 观测=只读复核现有 RTL、f72e owner-timing/B-latency 证据；本节点未运行仿真、综合或 STA，新候选尚无定向 TB/5 ns STA｜范围=GAP

- Contract SHA-256: `a1ee37953d3a1117d8e9dd1c68c5b7ece22235426f2bd97758b65609af63fb20`

[V15W-OWNER-B-PATH-CURRENT-REVIEW][GAP_CANDIDATE_ONLY] design_id=sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42 prior_design_id=sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968 current_cycles=4 candidate_cycles=3 candidate=adapter-input-aw-w-fall-through-v1 adapter_sha256=6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22

- Production RTL change authorized: `false`
- PPA: `UNQUALIFIED`
- Promotion eligible: `false`

## E0-E4 当前事务链

- E0：`OooMemAxiBridge` 的 AW/W 经 `OooDualMemAxiArbiter` 与 adapter 上游同时握手；bridge 进入 `S_WRITE_RESP`，adapter 捕获完整逻辑写并进入 `S_W_SEND`。
- E1：adapter 下游 AW/W 在 `AxiCrossbar` master 端握手；crossbar 写入 AW/W holder，adapter 进入 `S_W_RESP`。
- E2：crossbar 从完整 AW/W holder 仲裁并登记 `wr_active_q`、`wr_owner_q` 与目标 payload。
- E3：`AxiDpiSlave` 接受两通道并寄存 `s_axi_bvalid_o/s_axi_bresp_o`；crossbar 记录两个 sent 位。
- E4：crossbar 按 `wr_owner_q` 路由 B；adapter 的 `final_b_fallthrough_w` 与 bridge 的 `data_store_b_response_fusion_w` 同拍形成精确 store terminal。上游反压时分别回落到 `S_B_RESP`/`S_RESP` holder。

CoreMark 的 144201 个 B terminal 与 Dhrystone10000 的 600000 个 B terminal 均观测到 `mean_completed_cycles=4.000000000000`。B-delay 由 0 增至 2 时两项 workload 的 write-response 都由 4 增至 6 cycles；这只证明 B 响应链的单位延迟敏感性，不是未实现候选的性能结果。当前 adapter SHA-256 与 V15P closure 一致，prior-stable 源文件及 f72e owner-timing、causal、sensitivity、selector 身份未漂移。

## Owner、holder 与 terminal

- `OooMemAxiBridge` 保存 active owner/token/MMU epoch；任一 AW/W fire 后的 escaped write 必须 drain 到唯一物理 B terminal。`lsu_axi_bready_o` 只由响应状态决定。
- `OooDualMemAxiArbiter` 用 `owner_q`、`aw_seen_q/w_seen_q` 锁定 transport owner，直到唯一 B terminal 才释放。
- `OooLsuAxiLaneAdapter` 用 AW/W holder、完整 command、独立 sent 位及 `S_W_SEND/S_W_RESP/S_B_RESP` 保存两通道状态；非最终 split B 不外泄，`sticky_resp` 保留首个非 OKAY BRESP。
- `AxiCrossbar` 独立捕获 master AW/W，再以 `wr_active_q/wr_owner_q` 登记目标 owner；只有 AW/W 都发送后才路由 B。
- `AxiDpiSlave` 独立接收 AW/W，仅在二者齐备时寄存 BVALID/BRESP。
- selective recovery 下，escaped write 只在 B 拍形成一次 drop；`nokill_q` 写仍以聚合 B 完成。候选不得改变 adapter 上游 READY 与 escaped-write 判定边界。

## 三周期候选边界与反例

候选 fast arm 仅允许 `S_IDLE` 中完整、合法、自然对齐的单拍写；upstream `AWREADY/WREADY` 必须继续只依赖本地 idle/holder。E0 的 downstream 接受矩阵必须精确处理 `00/01/10/11`：两通道都接受时进入 `S_W_RESP`；仅一通道接受时捕获完整 command 并只重发另一通道；均不接受时捕获完整 command 后保持两通道。invalid-size、sparse WSTRB、misaligned 与 split write 保持当前寄存路径。

必须增加以下定向反例：

- upstream AW/W 同拍、AW-first、W-first 与 downstream E0 四种接受组合；已接受通道不得重复，未接受 payload 必须稳定。
- 上游 B 反压、OKAY/SLVERR/DECERR、split-write sticky error 与 final-B exact-once。
- flush/selective recovery 位于逻辑命令未齐、E0 `00/01/10/11`、`S_W_RESP` 等 B 与 B 到达同拍。
- killed escaped write 只 drain/drop 一次；`nokill` 写只完成一次；reset 不产生新的 input fall-through VALID。
- 编译成功的负向 RTL 变体应覆盖关闭 input fall-through、AW/W sent 位互换与 READY 回返耦合，并由绝对三周期 oracle 检出。
- 候选同 design-id 的 fresh 5 ns mapped STA；历史 STA 只属于旧设计且 timing hard gate 已失败。

## Unknowns、替代假设与范围

新 fast arm 尚无 RTL，accepted-channel bookkeeping、flush 边界、组合环与 PPA 均未被证明；现有 adapter TB 没有候选 E0 接受矩阵。当前 causal probe 的 `2,4,7` 只证明已实现的 final-B fall-through，不证明新的 input fall-through。单 write owner 和 reservation/SQ-query 仍可能是共同瓶颈，因此 workload 收益不能由敏感性斜率直接外推。crossbar grant fall-through、target 同拍 B 或更多 outstanding write 属于其它微架构，不在本候选范围。

`scope_extension_request`：本次只读结论无需扩大范围。若进入实现，需新合同纳入候选 RTL、adapter E0 接受矩阵、bridge flush/nokill/drop 组合测试、全链 causal probe、编译成功负向变异及同设计 mapped STA。

`confidence_and_basis`：当前 E0-E4 映射与 source/hash 身份为高置信；三周期结构可行性为中等置信；协议、恢复语义与 5 ns PPA 资格仍为 GAP。
