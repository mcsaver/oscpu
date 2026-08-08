RV64 RTL 结论｜对象=`OooMemAxiBridge`→`OooDualMemAxiArbiter`→`OooLsuAxiLaneAdapter`→`AxiCrossbar`→`AxiDpiSlave` B-response/owner terminal｜周期/配置=ca37 当前 E0→E4=4 cycles；候选 ideal=3 cycles、仅 legal naturally aligned single-beat write｜TB/EDA 观测=ca37 workload 均值 4.000000000000；本节点未运行仿真/综合；旧 337de8 mapped 5ns hard gate FAIL｜范围=GAP

- Contract: `.github/task-runs/2026-08-07-rv64-v15w-owner-b-response-candidate-analysis-ca37-a1/subagent-contracts/v15w-owner-b-path-current-review-v1.json`
- Contract SHA-256: `0ca270cf0457008c49f8e4373d6284143b053fe9c5471e33179d885471a878df`

`[V15W-OWNER-B-PATH-CURRENT-REVIEW][GAP_CANDIDATE_ONLY] design_id=sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f prior_design_id=sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968 current_cycles=4 candidate_cycles=3 candidate=adapter-input-aw-w-fall-through-v1 adapter_sha256=6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22`

- Production RTL change authorized: `false`
- PPA: `UNQUALIFIED`
- Promotion eligible: `false`

当前四周期路径可确认：

- E0：bridge AW/W 经 `OooDualMemAxiArbiter.S_WRITE_DATA` 与 adapter 握手；adapter 捕获完整命令并进入 `S_W_SEND`，bridge/arbiter 分别进入 B 等待态。
- E1：adapter 的 `d_axi_awvalid_o/d_axi_wvalid_o` 与 crossbar master 口握手，crossbar 写入 `wr_aw_hold_q/wr_w_hold_q`。
- E2：crossbar 由 hold 状态产生 grant，登记 `wr_active_q/wr_owner_q`。
- E3：crossbar 向 target 呈现 AW/W；`AxiDpiSlave.write_complete_w` 登记 `s_axi_bvalid_o/s_axi_bresp_o`。
- E4：crossbar 按 `wr_owner_q` 路由 B；adapter 的 `final_b_fallthrough_w` 直接产生 upstream B；bridge 的 `data_store_b_response_fusion_w` 同拍形成 store terminal。

Owner/terminal 语义由当前源码支持：arbiter 在 `b_fire_w` 前保持 `owner_q`；crossbar 在 B fire 前保持 `wr_owner_q/wr_active_q`；bridge 在 backend 反压时进入 `S_RESP` 快照。flush/selective recovery 后，escaped write 仍等待真实 B，并只产生一次 exact drop/maintenance terminal；`nokill_q` store 保持写必达和唯一正常响应。

三周期候选尚未实现。当前 adapter 的 downstream VALID 仍严格限定于 `state_q == S_W_SEND`。候选只可覆盖合法、自然对齐、单 beat 写，并必须验证：upstream AW-only/W-only 不产生 downstream side effect；downstream AW-only/W-only acceptance 精确捕获完整 payload 与 accepted-channel bit；B backpressure 精确转入一次 `S_B_RESP`；OKAY/SLVERR/DECERR 逐位保持；split sticky error 不被覆盖；flush/selective recovery 覆盖每个 partial-send 边界；escaped-write 与 nokill completion 各只终结一次。

证据边界：当前 adapter/TB 哈希与旧 final-B closure 相符，ca37 owner-timing/sensitivity receipt 支持四周期观测；但旧 closure 与 mapped STA 绑定 `sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968`，其工程判定为 `TIMING_HARD_GATE_FAIL_REWORK_OR_ROLLBACK`、`NOT_PROMOTABLE`。合同范围内没有 ca37 三周期候选实现、定向反例回执或 fresh mapped 5ns STA，因此只能定义候选，不能授权 production RTL。

`scope_extension_request`：关闭 GAP 需要候选 RTL、AW/W partial-accept/flush/escaped-write 定向 TB、ca37 candidate receipt，以及同一新 design-id 的 fresh mapped 5ns STA。
