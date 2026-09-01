`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

// Tensor NPU continuous-layout DMA engine.
//
// This first functional-simulation implementation deliberately supports one
// 64-bit GMEM transaction at a time.  A request which has been accepted is
// always drained through the matching response before done/error is exposed.
// Descriptor errors and LMEM out-of-bounds indications are normal fail-closed
// outcomes; they are not simulation assertions.
module TensorNpuDmaEngine #(
  parameter integer LMEM_BYTES = 4096
) (
  input  wire         clk_i,
  input  wire         rst_i,

  input  wire         start_i,
  input  wire [`NPU_OP_W-1:0] op_i,
  input  wire [5:0]   dst_id_i,
  input  wire [`NPU_DESC_W-1:0] dst_desc_i,
  input  wire [4:0]   dst_words_valid_i,
  input  wire [5:0]   src_id_i,
  input  wire [`NPU_DESC_W-1:0] src_desc_i,
  input  wire [4:0]   src_words_valid_i,

  output reg          busy_o,
  output reg          done_o,
  output reg          error_o,
  output reg  [`NPU_ERROR_W-1:0] error_code_o,
  output reg  [63:0]  cycles_o,
  output reg  [63:0]  bytes_done_o,

  output reg          lmem_rd_valid_o,
  output reg  [31:0]  lmem_rd_addr_o,
  output reg  [3:0]   lmem_rd_bytes_o,
  input  wire [63:0]  lmem_rd_data_i,
  input  wire         lmem_rd_oob_i,

  output reg          lmem_wr_valid_o,
  output reg  [31:0]  lmem_wr_addr_o,
  output reg  [63:0]  lmem_wr_data_o,
  output reg  [7:0]   lmem_wr_strb_o,
  input  wire         lmem_wr_oob_i,

  output reg          gmem_req_valid_o,
  input  wire         gmem_req_ready_i,
  output reg          gmem_req_write_o,
  output reg  [63:0]  gmem_req_addr_o,
  output reg  [63:0]  gmem_req_wdata_o,
  output reg  [7:0]   gmem_req_wstrb_o,

  input  wire         gmem_rsp_valid_i,
  output reg          gmem_rsp_ready_o,
  input  wire [63:0]  gmem_rsp_rdata_i,
  input  wire         gmem_rsp_error_i
);

  localparam [3:0] LAYOUT_CONTINUOUS = 4'd1;
  localparam [3:0] TEEW_E8           = 4'd0;
  localparam [3:0] TEEW_E16          = 4'd1;
  localparam [3:0] TEEW_E32          = 4'd2;

  localparam [3:0] ST_IDLE         = 4'd0;
  localparam [3:0] ST_LD_REQ       = 4'd1;
  localparam [3:0] ST_LD_RSP       = 4'd2;
  localparam [3:0] ST_LD_LMEM_WR   = 4'd3;
  localparam [3:0] ST_ST_LMEM_REQ  = 4'd4;
  localparam [3:0] ST_ST_LMEM_CAP  = 4'd5;
  localparam [3:0] ST_ST_REQ       = 4'd6;
  localparam [3:0] ST_ST_RSP       = 4'd7;

  reg [3:0]  state_r;
  reg [31:0] lmem_base_r;
  reg [63:0] gmem_base_r;
  reg [63:0] total_bytes_r;
  reg [63:0] byte_offset_r;
  reg [63:0] ld_data_r;
  reg [63:0] st_data_r;

  wire op_is_ld_w;
  wire op_is_st_w;
  wire op_supported_w;
  // The continuous MVP consumes base/type/shape only.  PDF reserved fields
  // and explicit strides are intentionally ignored until FREE_MODE support.
  /* verilator lint_off UNUSEDSIGNAL */
  wire [`NPU_DESC_W-1:0] tr_desc_w;
  wire [`NPU_DESC_W-1:0] gr_desc_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire [4:0] tr_words_valid_w;
  wire [4:0] gr_words_valid_w;
  wire [5:0] tr_id_w;
  wire [5:0] gr_id_w;

  // DMA LD uses dst=TR and src=GR; DMA ST reverses those roles.
  assign op_is_ld_w       = (op_i == `NPU_OP_DMA_LD);
  assign op_is_st_w       = (op_i == `NPU_OP_DMA_ST);
  assign op_supported_w   = op_is_ld_w | op_is_st_w;
  assign tr_desc_w        = op_is_ld_w ? dst_desc_i : src_desc_i;
  assign gr_desc_w        = op_is_ld_w ? src_desc_i : dst_desc_i;
  assign tr_words_valid_w = op_is_ld_w ? dst_words_valid_i : src_words_valid_i;
  assign gr_words_valid_w = op_is_ld_w ? src_words_valid_i : dst_words_valid_i;
  assign tr_id_w          = op_is_ld_w ? dst_id_i : src_id_i;
  assign gr_id_w          = op_is_ld_w ? src_id_i : dst_id_i;

  // PDF-defined tensor-register descriptor fields.
  wire [31:0] tr_base_w;
  wire [3:0]  tr_layout_w;
  wire [3:0]  tr_teew_w;
  wire [15:0] tr_dim_w_w;
  wire [15:0] tr_dim_h_w;
  wire [15:0] tr_dim_c_w;
  wire [15:0] tr_dim_n_w;

  assign tr_base_w   = tr_desc_w[31:0];
  assign tr_layout_w = tr_desc_w[55:52];
  assign tr_teew_w   = tr_desc_w[63:60];
  assign tr_dim_w_w  = tr_desc_w[79:64];
  assign tr_dim_h_w  = tr_desc_w[95:80];
  assign tr_dim_c_w  = tr_desc_w[111:96];
  assign tr_dim_n_w  = tr_desc_w[127:112];

  // PDF-defined global-register descriptor fields.
  wire [47:0] gr_base_w;
  wire [3:0]  gr_layout_w;
  wire [3:0]  gr_teew_w;
  wire [31:0] gr_dim_w_w;
  wire [31:0] gr_dim_h_w;
  wire [15:0] gr_dim_c_w;
  wire [15:0] gr_dim_n_w;

  assign gr_base_w   = gr_desc_w[47:0];
  assign gr_layout_w = gr_desc_w[55:52];
  assign gr_teew_w   = gr_desc_w[63:60];
  assign gr_dim_w_w  = gr_desc_w[95:64];
  assign gr_dim_h_w  = gr_desc_w[127:96];
  assign gr_dim_c_w  = gr_desc_w[143:128];
  assign gr_dim_n_w  = gr_desc_w[159:144];

  // Width-expanded products avoid silently truncating large malformed shapes.
  reg [127:0] tr_elements_wide;
  reg [127:0] gr_elements_wide;
  reg [127:0] total_bytes_wide;
  reg [127:0] lmem_end_wide;
  localparam [31:0] LMEM_BYTES_U32 = LMEM_BYTES;

  always @* begin
    tr_elements_wide = {{112{1'b0}}, tr_dim_w_w};
    tr_elements_wide = tr_elements_wide * {{112{1'b0}}, tr_dim_h_w};
    tr_elements_wide = tr_elements_wide * {{112{1'b0}}, tr_dim_c_w};
    tr_elements_wide = tr_elements_wide * {{112{1'b0}}, tr_dim_n_w};

    gr_elements_wide = {{96{1'b0}}, gr_dim_w_w};
    gr_elements_wide = gr_elements_wide * {{96{1'b0}}, gr_dim_h_w};
    gr_elements_wide = gr_elements_wide * {{112{1'b0}}, gr_dim_c_w};
    gr_elements_wide = gr_elements_wide * {{112{1'b0}}, gr_dim_n_w};

    total_bytes_wide = tr_elements_wide << tr_teew_w;
    lmem_end_wide    = {{96{1'b0}}, tr_base_w} + total_bytes_wide;
  end

  reg       launch_ok_w;
  reg [7:0] launch_error_w;

  // Launch checking is ordered so one malformed command has one deterministic
  // architectural error.  No GMEM request is observable until every check has
  // passed.
  always @* begin
    launch_ok_w    = 1'b0;
    launch_error_w = `NPU_ERR_NONE;

    if (!op_supported_w) begin
      launch_error_w = `NPU_ERR_UNSUPPORTED;
    end else if ((tr_id_w < 6'd8) || (tr_id_w > 6'd31) ||
                 (gr_id_w < 6'd32) || (gr_id_w > 6'd39)) begin
      launch_error_w = `NPU_ERR_DESC_ID;
    end else if ((tr_words_valid_w != 5'b01111) ||
                 (gr_words_valid_w != 5'h1f)) begin
      launch_error_w = `NPU_ERR_DESC_INCOMPLETE;
    end else if ((tr_layout_w != LAYOUT_CONTINUOUS) ||
                 (gr_layout_w != LAYOUT_CONTINUOUS) ||
                 (tr_teew_w != gr_teew_w) ||
                 ((tr_teew_w != TEEW_E8) &&
                  (tr_teew_w != TEEW_E16) &&
                  (tr_teew_w != TEEW_E32))) begin
      launch_error_w = `NPU_ERR_DESC_TYPE;
    end else if ((tr_elements_wide == 128'd0) ||
                 (tr_elements_wide != gr_elements_wide)) begin
      launch_error_w = `NPU_ERR_SHAPE;
    end else if ((gr_base_w[2:0] != 3'b000) ||
                 (total_bytes_wide[2:0] != 3'b000)) begin
      launch_error_w = `NPU_ERR_GMEM_ALIGN;
    end else if ((tr_base_w[2:0] != 3'b000) ||
                 (total_bytes_wide[127:64] != 64'd0) ||
                 (lmem_end_wide[127:32] != 96'd0) ||
                 (lmem_end_wide[31:0] > LMEM_BYTES_U32)) begin
      launch_error_w = `NPU_ERR_LMEM_BOUNDS;
    end else begin
      launch_ok_w    = 1'b1;
      launch_error_w = `NPU_ERR_NONE;
    end
  end

  // Bus and local-memory controls are state-derived.  All GMEM request fields
  // depend only on registers while valid is asserted, so backpressure cannot
  // alter an unaccepted payload.
  always @* begin
    lmem_rd_valid_o   = 1'b0;
    lmem_rd_addr_o    = lmem_base_r + byte_offset_r[31:0];
    lmem_rd_bytes_o   = 4'd8;
    lmem_wr_valid_o   = 1'b0;
    lmem_wr_addr_o    = lmem_base_r + byte_offset_r[31:0];
    lmem_wr_data_o    = ld_data_r;
    lmem_wr_strb_o    = 8'hff;

    gmem_req_valid_o  = 1'b0;
    gmem_req_write_o  = 1'b0;
    gmem_req_addr_o   = gmem_base_r + byte_offset_r;
    gmem_req_wdata_o  = 64'd0;
    gmem_req_wstrb_o  = 8'h00;
    gmem_rsp_ready_o  = 1'b0;

    case (state_r)
      ST_LD_REQ: begin
        gmem_req_valid_o = 1'b1;
      end

      ST_LD_RSP: begin
        gmem_rsp_ready_o = 1'b1;
      end

      ST_LD_LMEM_WR: begin
        lmem_wr_valid_o = 1'b1;
      end

      ST_ST_LMEM_REQ,
      ST_ST_LMEM_CAP: begin
        lmem_rd_valid_o = 1'b1;
      end

      ST_ST_REQ: begin
        gmem_req_valid_o = 1'b1;
        gmem_req_write_o = 1'b1;
        gmem_req_wdata_o = st_data_r;
        gmem_req_wstrb_o = 8'hff;
      end

      ST_ST_RSP: begin
        gmem_rsp_ready_o = 1'b1;
      end

      default: begin
      end
    endcase
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      state_r       <= ST_IDLE;
      lmem_base_r   <= 32'd0;
      gmem_base_r   <= 64'd0;
      total_bytes_r <= 64'd0;
      byte_offset_r <= 64'd0;
      ld_data_r     <= 64'd0;
      st_data_r     <= 64'd0;
      busy_o        <= 1'b0;
      done_o        <= 1'b0;
      error_o       <= 1'b0;
      error_code_o  <= `NPU_ERR_NONE;
      cycles_o      <= 64'd0;
      bytes_done_o  <= 64'd0;
    end else begin
      done_o  <= 1'b0;
      error_o <= 1'b0;

      if (busy_o)
        cycles_o <= cycles_o + 64'd1;

      case (state_r)
        ST_IDLE: begin
          busy_o <= 1'b0;
          if (start_i) begin
            cycles_o     <= 64'd0;
            bytes_done_o <= 64'd0;
            error_code_o <= `NPU_ERR_NONE;
            if (!launch_ok_w) begin
              error_o      <= 1'b1;
              error_code_o <= launch_error_w;
            end else begin
              lmem_base_r   <= tr_base_w;
              gmem_base_r   <= {16'd0, gr_base_w};
              total_bytes_r <= total_bytes_wide[63:0];
              byte_offset_r <= 64'd0;
              busy_o        <= 1'b1;
              state_r       <= op_is_ld_w ? ST_LD_REQ : ST_ST_LMEM_REQ;
            end
          end
        end

        ST_LD_REQ: begin
          if (gmem_req_valid_o && gmem_req_ready_i)
            state_r <= ST_LD_RSP;
        end

        ST_LD_RSP: begin
          if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
            if (gmem_rsp_error_i) begin
              busy_o       <= 1'b0;
              error_o      <= 1'b1;
              error_code_o <= `NPU_ERR_GMEM_RESPONSE;
              state_r      <= ST_IDLE;
            end else begin
              ld_data_r <= gmem_rsp_rdata_i;
              state_r   <= ST_LD_LMEM_WR;
            end
          end
        end

        ST_LD_LMEM_WR: begin
          if (lmem_wr_oob_i) begin
            busy_o       <= 1'b0;
            error_o      <= 1'b1;
            error_code_o <= `NPU_ERR_LMEM_BOUNDS;
            state_r      <= ST_IDLE;
          end else begin
            bytes_done_o <= bytes_done_o + 64'd8;
            if ((byte_offset_r + 64'd8) >= total_bytes_r) begin
              busy_o       <= 1'b0;
              done_o       <= 1'b1;
              error_code_o <= `NPU_ERR_NONE;
              state_r      <= ST_IDLE;
            end else begin
              byte_offset_r <= byte_offset_r + 64'd8;
              state_r       <= ST_LD_REQ;
            end
          end
        end

        ST_ST_LMEM_REQ: begin
          // Keep the read request alive for a complete cycle.  The following
          // capture state therefore works with either combinational or
          // one-cycle registered LMEM read data.
          state_r <= ST_ST_LMEM_CAP;
        end

        ST_ST_LMEM_CAP: begin
          if (lmem_rd_oob_i) begin
            busy_o       <= 1'b0;
            error_o      <= 1'b1;
            error_code_o <= `NPU_ERR_LMEM_BOUNDS;
            state_r      <= ST_IDLE;
          end else begin
            st_data_r <= lmem_rd_data_i;
            state_r   <= ST_ST_REQ;
          end
        end

        ST_ST_REQ: begin
          if (gmem_req_valid_o && gmem_req_ready_i)
            state_r <= ST_ST_RSP;
        end

        ST_ST_RSP: begin
          if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
            if (gmem_rsp_error_i) begin
              busy_o       <= 1'b0;
              error_o      <= 1'b1;
              error_code_o <= `NPU_ERR_GMEM_RESPONSE;
              state_r      <= ST_IDLE;
            end else begin
              bytes_done_o <= bytes_done_o + 64'd8;
              if ((byte_offset_r + 64'd8) >= total_bytes_r) begin
                busy_o       <= 1'b0;
                done_o       <= 1'b1;
                error_code_o <= `NPU_ERR_NONE;
                state_r      <= ST_IDLE;
              end else begin
                byte_offset_r <= byte_offset_r + 64'd8;
                state_r       <= ST_ST_LMEM_REQ;
              end
            end
          end
        end

        default: begin
          // Corrupt control state is contained as a terminal fail-closed
          // result; no further request can be launched from this state.
          busy_o       <= 1'b0;
          error_o      <= 1'b1;
          error_code_o <= `NPU_ERR_INTERNAL_STATE;
          state_r      <= ST_IDLE;
        end
      endcase
    end
  end

endmodule
