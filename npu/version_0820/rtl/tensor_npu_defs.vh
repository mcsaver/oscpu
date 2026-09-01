`ifndef TENSOR_NPU_DEFS_VH
`define TENSOR_NPU_DEFS_VH

// PDF 统一使用 RISC-V custom-2 major opcode。
`define NPU_CUSTOM2_OPCODE       7'b1011011
`define NPU_FUNCT3_TENSOR        3'b011
`define NPU_FUNCT3_CONFIG        3'b100

`define NPU_OP_W                 6
`define NPU_OP_INVALID           6'd0
`define NPU_OP_CFG_SATU          6'd1
`define NPU_OP_CFG_PAD           6'd2
`define NPU_OP_CFG_INSRT         6'd3
`define NPU_OP_CFG_STENCIL       6'd4
`define NPU_OP_CFG_ROUND         6'd5
`define NPU_OP_CFG_RSQRT_ITER    6'd6
`define NPU_OP_CFG_DMAIDX        6'd7
`define NPU_OP_CFG_QUANT         6'd8
`define NPU_OP_CFG_KZP           6'd9
`define NPU_OP_TCR_CR            6'd10
`define NPU_OP_TCR_TR            6'd11
`define NPU_OP_TCR_GR            6'd12
`define NPU_OP_SYNC              6'd13
`define NPU_OP_MM2_NN            6'd20
`define NPU_OP_MM2_NT            6'd21
`define NPU_OP_MM2_TT            6'd22
`define NPU_OP_DMA_LD            6'd30
`define NPU_OP_DMA_ST            6'd31
`define NPU_OP_UNSUPPORTED       6'd63

`define NPU_ERROR_W              8
`define NPU_ERR_NONE             8'd0
`define NPU_ERR_ILLEGAL_ENCODING 8'd1
`define NPU_ERR_UNSUPPORTED      8'd2
`define NPU_ERR_DESC_ID          8'd3
`define NPU_ERR_DESC_WORD        8'd4
`define NPU_ERR_DESC_INCOMPLETE  8'd5
`define NPU_ERR_DESC_TYPE        8'd6
`define NPU_ERR_SHAPE            8'd7
`define NPU_ERR_LMEM_BOUNDS      8'd8
`define NPU_ERR_GMEM_ALIGN       8'd9
`define NPU_ERR_GMEM_RESPONSE    8'd10
`define NPU_ERR_SYNC_ENGINE      8'd11
`define NPU_ERR_INTERNAL_STATE   8'd12
// Parsed macro command / completion condensed failures.  The 32-bit ABI
// status is the zero-extension of these non-zero codes; error_class remains
// the ABI-level category carried on the macro completion sideband.
`define NPU_ERR_MACRO_ABI        8'd13
`define NPU_ERR_MACRO_CAPABILITY 8'd14
`define NPU_ERR_MACRO_LAYOUT     8'd15
`define NPU_ERR_MACRO_IOVA       8'd16
`define NPU_ERR_MACRO_TIMEOUT    8'd17
`define NPU_ERR_MACRO_PROTOCOL   8'd18

`define NPU_DESC_W               320
`define NPU_DESC_WORDS           5
`define NPU_TCR_COUNT            40

`endif
