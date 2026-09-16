# OooFetchPacketHeadMux Boundary Spec

> **T3V 状态**：response bypass 数据臂与 selector 已物理删除。模块现在是
> registered FIFO packet 的 dispatch-visible identity view；保留模块边界用于合同与测试，
> 但不应综合出 payload mux。

## 1. Requirement

`OooFrontend` 的 dispatch 只消费 `OooFetchPacketFifo` 的寄存 head entry。
`OooFetchPacketHeadMux` 保留稳定的 head-view 接口，将 FIFO validity 与完整 packet bundle
逐位暴露给下游，不拥有 response ready-valid、FIFO mutation、decode 或 recovery 状态。

## 2. Interface Contract

Inputs:

- `fifo_head_valid_i`: stored FIFO head validity;
- FIFO head packet fields：slot0/slot1 PC、next PC、instruction、response、预测元数据及
  T3V 静态预译码 bundle（`ctrl/rs1/rs2/rd/imm`），加 packet next PC。

Outputs:

- `head_has_packet_o`;
- selected slot0/slot1 PC、next PC、instruction、response、预测元数据与静态预译码 bundle；
- selected packet next PC.

The module does not pop or enqueue the FIFO, does not inspect instruction contents, and does not update
`next_fetch_pc`.

## 3. State Machine

There is no internal state.

Combinational rules:

1. `head_has_packet_o = fifo_head_valid_i`.
2. Every payload output is a direct bit-preserving view of its FIFO head input.

## 4. Invariants

- `head_has_packet_o` is true exactly when FIFO head is valid.
- The module preserves payload bit patterns exactly; it does not reinterpret
  response codes or RVC length.
- `inst` 与 `ctrl/rs1/rs2/rd/imm` 必须逐字段透传同一个 FIFO entry。

T3V 的译码所有权与时序切点见 `ooo-fetch-predecode-bundle.md`。
