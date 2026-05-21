`include "define.v"

/* verilator lint_off UNUSEDSIGNAL */

module DCache (
  input clk,
  input rst,
  input invalidate_i,
  input flush_i,
  output flush_done_o,

  input cpu_req_valid_i,
  output cpu_req_ready_o,
  input cpu_req_write_i,
  input [`XLEN-1:0] cpu_req_addr_i,
  input [`XLEN-1:0] cpu_req_wdata_i,
  input [3:0] cpu_req_wstrb_i,
  output cpu_rsp_valid_o,
  output [`XLEN-1:0] cpu_rsp_rdata_o,
  output cpu_rsp_error_o,

  output axi_arvalid_o,
  input axi_arready_i,
  output [`XLEN-1:0] axi_araddr_o,
  input axi_rvalid_i,
  output axi_rready_o,
  input [`XLEN-1:0] axi_rdata_i,
  input [1:0] axi_rresp_i,

  output axi_awvalid_o,
  input axi_awready_i,
  output [`XLEN-1:0] axi_awaddr_o,
  output axi_wvalid_o,
  input axi_wready_i,
  output [`XLEN-1:0] axi_wdata_o,
  output [3:0] axi_wstrb_o,
  input axi_bvalid_i,
  output axi_bready_o,
  input [1:0] axi_bresp_i
);

  localparam LINE_WORDS = 16;
  localparam LINE_COUNT = 64;
  localparam OFFSET_BITS = 6;
  localparam INDEX_BITS = 6;
  localparam WORD_BITS = 4;
  localparam TAG_BITS = `XLEN - OFFSET_BITS - INDEX_BITS;
  localparam DATA_WORDS = LINE_COUNT * LINE_WORDS;
  localparam DATA_INDEX_BITS = INDEX_BITS + WORD_BITS;
  // flush 扫描步进随 index 宽度参数化，避免后续容量调整时留下硬编码常量。
  localparam [INDEX_BITS-1:0] INDEX_STEP = {{(INDEX_BITS-1){1'b0}}, 1'b1};

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_LOOKUP = 4'd1;
  localparam [3:0] S_WB_AW = 4'd2;
  localparam [3:0] S_WB_B = 4'd3;
  localparam [3:0] S_FILL_AR = 4'd4;
  localparam [3:0] S_FILL_R = 4'd5;
  localparam [3:0] S_STORE_ALLOC_UPDATE = 4'd6;
  localparam [3:0] S_UNCACHED_AR = 4'd7;
  localparam [3:0] S_UNCACHED_R = 4'd8;
  localparam [3:0] S_UNCACHED_AW = 4'd9;
  localparam [3:0] S_UNCACHED_B = 4'd10;
  localparam [3:0] S_RESP = 4'd11;
  localparam [3:0] S_FLUSH_SCAN = 4'd12;
  localparam [3:0] S_FLUSH_WB_AW = 4'd13;
  localparam [3:0] S_FLUSH_WB_B = 4'd14;
  localparam [3:0] S_FLUSH_DONE = 4'd15;

  reg [3:0] state_q;
  reg req_write_q;
  reg [`XLEN-1:0] req_addr_q;
  reg [`XLEN-1:0] req_wdata_q;
  reg [3:0] req_wstrb_q;
  reg [`XLEN-1:0] fill_base_q;
  reg [INDEX_BITS-1:0] fill_index_q;
  reg [TAG_BITS-1:0] fill_tag_q;
  reg [WORD_BITS-1:0] fill_word_q;
  reg [INDEX_BITS-1:0] victim_index_q;
  reg [TAG_BITS-1:0] victim_tag_q;
  reg [WORD_BITS-1:0] wb_word_q;
  reg [INDEX_BITS-1:0] flush_index_q;
  reg [WORD_BITS-1:0] flush_word_q;
  reg axi_aw_done_q;
  reg axi_w_done_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg rsp_error_q;

  function cacheable_word;
    input [`XLEN-1:0] addr;
    begin
      cacheable_word = (addr >= 32'h8000_0000) && (addr <= 32'h87ff_fffc);
    end
  endfunction

  function [INDEX_BITS-1:0] line_index;
    input [`XLEN-1:0] addr;
    begin
      line_index = addr[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
    end
  endfunction

  function [TAG_BITS-1:0] line_tag;
    input [`XLEN-1:0] addr;
    begin
      line_tag = addr[`XLEN-1:OFFSET_BITS + INDEX_BITS];
    end
  endfunction

  function [WORD_BITS-1:0] word_offset;
    input [`XLEN-1:0] addr;
    begin
      word_offset = addr[OFFSET_BITS-1:2];
    end
  endfunction

  function [DATA_INDEX_BITS-1:0] data_index;
    input [INDEX_BITS-1:0] index;
    input [WORD_BITS-1:0] word;
    begin
      data_index = {index, word};
    end
  endfunction

  function [`XLEN-1:0] line_base;
    input [`XLEN-1:0] addr;
    begin
      line_base = {addr[`XLEN-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    end
  endfunction

  function [`XLEN-1:0] byte_mask32;
    input [3:0] wstrb;
    begin
      byte_mask32 = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};
    end
  endfunction

  wire req_cacheable_w = cacheable_word(req_addr_q);
  wire [INDEX_BITS-1:0] req_index_w = line_index(req_addr_q);
  wire [TAG_BITS-1:0] req_tag_w = line_tag(req_addr_q);
  wire [WORD_BITS-1:0] req_word_w = word_offset(req_addr_q);
  wire [DATA_INDEX_BITS-1:0] req_data_index_w = data_index(req_index_w, req_word_w);

  wire cur_req_cacheable_w = cacheable_word(cpu_req_addr_i);
  wire [INDEX_BITS-1:0] cur_req_index_w = line_index(cpu_req_addr_i);
  wire [TAG_BITS-1:0] cur_req_tag_w = line_tag(cpu_req_addr_i);
  wire [WORD_BITS-1:0] cur_req_word_w = word_offset(cpu_req_addr_i);
  wire [DATA_INDEX_BITS-1:0] cur_req_data_index_w = data_index(cur_req_index_w, cur_req_word_w);

  wire flush_meta_read_w = (state_q == S_FLUSH_SCAN) ||
                           (state_q == S_FLUSH_WB_AW) ||
                           (state_q == S_FLUSH_WB_B) ||
                           (state_q == S_FLUSH_DONE);
  wire lookup_cur_w = (state_q == S_IDLE) && !flush_i;
  wire idle_cpu_accept_w = (state_q == S_IDLE) && !flush_i;
  wire [INDEX_BITS-1:0] meta_rd_index_w = lookup_cur_w ? cur_req_index_w : req_index_w;
  wire [INDEX_BITS-1:0] meta_rd_index_sel_w = flush_meta_read_w ? flush_index_q :
                                              meta_rd_index_w;
  wire [DATA_INDEX_BITS-1:0] lookup_data_index_w = lookup_cur_w ? cur_req_data_index_w : req_data_index_w;
  wire [DATA_INDEX_BITS-1:0] wb_data_index_w = data_index(victim_index_q, wb_word_q);
  wire [DATA_INDEX_BITS-1:0] flush_data_index_w = data_index(flush_index_q, flush_word_q);
  wire [DATA_INDEX_BITS-1:0] data_rd_index_w =
      ((state_q == S_WB_AW) || (state_q == S_WB_B)) ? wb_data_index_w :
      ((state_q == S_FLUSH_WB_AW) || (state_q == S_FLUSH_WB_B)) ? flush_data_index_w :
      lookup_data_index_w;

  wire valid_rd_w;
  wire dirty_rd_w;
  wire [TAG_BITS-1:0] tag_rd_w;
  wire [`XLEN-1:0] data_rd_w;

  wire lookup_hit_w = valid_rd_w && (tag_rd_w == req_tag_w);
  wire cur_req_lookup_hit_w = valid_rd_w && (tag_rd_w == cur_req_tag_w);
  wire cur_load_hit_w = idle_cpu_accept_w && cpu_req_valid_i && !cpu_req_write_i &&
                        cur_req_cacheable_w && cur_req_lookup_hit_w;
  wire cur_store_hit_w = idle_cpu_accept_w && cpu_req_valid_i && cpu_req_write_i &&
                         (cpu_req_wstrb_i != 4'b0000) &&
                         cur_req_cacheable_w && cur_req_lookup_hit_w;
  wire cur_store_nop_w = idle_cpu_accept_w && cpu_req_valid_i && cpu_req_write_i &&
                         (cpu_req_wstrb_i == 4'b0000);
  wire store_lookup_hit_w = (state_q == S_LOOKUP) && req_write_q &&
                            (req_wstrb_q != 4'b0000) && req_cacheable_w && lookup_hit_w;
  wire store_alloc_update_w = (state_q == S_STORE_ALLOC_UPDATE);
  wire store_update_w = cur_store_hit_w || store_lookup_hit_w || store_alloc_update_w;

  wire [`XLEN-1:0] store_update_wdata_w = cur_store_hit_w ? cpu_req_wdata_i : req_wdata_q;
  wire [3:0] store_update_wstrb_w = cur_store_hit_w ? cpu_req_wstrb_i : req_wstrb_q;
  wire [DATA_INDEX_BITS-1:0] store_update_index_w = cur_store_hit_w ?
                                                    cur_req_data_index_w :
                                                    req_data_index_w;
  wire [`XLEN-1:0] store_update_mask_w = byte_mask32(store_update_wstrb_w);
  wire [`XLEN-1:0] store_update_data_w =
      (data_rd_w & ~store_update_mask_w) | (store_update_wdata_w & store_update_mask_w);

  wire [`XLEN-1:0] fill_req_addr_w =
      fill_base_q + {{(`XLEN-WORD_BITS-2){1'b0}}, fill_word_q, 2'b00};
  wire [`XLEN-1:0] wb_base_addr_w =
      {victim_tag_q, victim_index_q, {OFFSET_BITS{1'b0}}};
  wire [`XLEN-1:0] wb_req_addr_w =
      wb_base_addr_w + {{(`XLEN-WORD_BITS-2){1'b0}}, wb_word_q, 2'b00};
  wire [`XLEN-1:0] flush_base_addr_w =
      {tag_rd_w, flush_index_q, {OFFSET_BITS{1'b0}}};
  wire [`XLEN-1:0] flush_req_addr_w =
      flush_base_addr_w + {{(`XLEN-WORD_BITS-2){1'b0}}, flush_word_q, 2'b00};
  wire fill_rsp_fire_w = (state_q == S_FILL_R) && axi_rvalid_i && axi_rready_o;
  wire fill_rsp_ok_w = fill_rsp_fire_w && (axi_rresp_i == 2'b00);
  wire fill_last_word_w = (fill_word_q == {WORD_BITS{1'b1}});
  wire fill_done_w = fill_rsp_ok_w && fill_last_word_w;
  wire line_wb_state_w = (state_q == S_WB_B) || (state_q == S_FLUSH_WB_B);
  wire line_wb_b_fire_w = line_wb_state_w && axi_bvalid_i && axi_bready_o;
  wire line_wb_b_ok_w = line_wb_b_fire_w && (axi_bresp_i == 2'b00);
  wire wb_last_word_w = (wb_word_q == {WORD_BITS{1'b1}});
  wire flush_last_word_w = (flush_word_q == {WORD_BITS{1'b1}});
  wire flush_last_index_w = (flush_index_q == {INDEX_BITS{1'b1}});
  wire wb_done_line_w = (state_q == S_WB_B) && line_wb_b_ok_w && wb_last_word_w;
  wire flush_wb_done_line_w = (state_q == S_FLUSH_WB_B) &&
                              line_wb_b_ok_w && flush_last_word_w;

  wire data_wr_en_w = fill_rsp_ok_w || store_update_w;
  wire [DATA_INDEX_BITS-1:0] data_wr_addr_w = fill_rsp_ok_w ?
                                               data_index(fill_index_q, fill_word_q) :
                                               store_update_index_w;
  wire [`XLEN-1:0] data_wr_data_w = fill_rsp_ok_w ? axi_rdata_i : store_update_data_w;
  wire [`XLEN-1:0] data_wr_mask_w = fill_rsp_ok_w ? {`XLEN{1'b1}} : store_update_mask_w;

  wire valid_wr_en_w = fill_done_w;
  wire tag_wr_en_w = fill_done_w;
  wire dirty_wr_en_w = fill_done_w || wb_done_line_w ||
                       flush_wb_done_line_w || store_update_w;
  wire [INDEX_BITS-1:0] dirty_wr_addr_w = store_update_w ?
                                           (cur_store_hit_w ? cur_req_index_w : req_index_w) :
                                           (wb_done_line_w ? victim_index_q :
                                            (flush_wb_done_line_w ? flush_index_q : fill_index_q));
  wire dirty_wr_data_w = store_update_w;

  wire axi_write_state_w = (state_q == S_WB_AW) ||
                           (state_q == S_UNCACHED_AW) ||
                           (state_q == S_FLUSH_WB_AW);
  wire axi_aw_fire_w = axi_awvalid_o && axi_awready_i;
  wire axi_w_fire_w = axi_wvalid_o && axi_wready_i;
  wire axi_write_done_w = axi_write_state_w &&
                          (axi_aw_done_q || axi_aw_fire_w) &&
                          (axi_w_done_q || axi_w_fire_w);
  wire wb_axi_write_fire_w = ((state_q == S_WB_AW) ||
                              (state_q == S_FLUSH_WB_AW)) && axi_write_done_w;

  assign flush_done_o = (state_q == S_FLUSH_DONE);
  assign cpu_req_ready_o = idle_cpu_accept_w;
  assign cpu_rsp_valid_o = cur_load_hit_w || cur_store_hit_w || cur_store_nop_w ||
                           (state_q == S_RESP);
  assign cpu_rsp_rdata_o = cur_load_hit_w ? data_rd_w : rsp_data_q;
  assign cpu_rsp_error_o = (cur_load_hit_w || cur_store_hit_w || cur_store_nop_w) ? 1'b0 :
                           rsp_error_q;

  assign axi_arvalid_o = (state_q == S_FILL_AR) || (state_q == S_UNCACHED_AR);
  assign axi_araddr_o = (state_q == S_UNCACHED_AR) ? req_addr_q : fill_req_addr_w;
  assign axi_rready_o = (state_q == S_FILL_R) || (state_q == S_UNCACHED_R);

  assign axi_awvalid_o = axi_write_state_w && !axi_aw_done_q;
  assign axi_awaddr_o = (state_q == S_UNCACHED_AW) ? req_addr_q :
                         (state_q == S_FLUSH_WB_AW) ? flush_req_addr_w :
                         wb_req_addr_w;
  assign axi_wvalid_o = axi_write_state_w && !axi_w_done_q;
  assign axi_wdata_o = (state_q == S_UNCACHED_AW) ? req_wdata_q : data_rd_w;
  assign axi_wstrb_o = (state_q == S_UNCACHED_AW) ? req_wstrb_q : 4'b1111;
  assign axi_bready_o = (state_q == S_WB_B) ||
                        (state_q == S_UNCACHED_B) ||
                        (state_q == S_FLUSH_WB_B);

  Sram1Rw #(
    .DATA_WIDTH(1),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_valid_sram (
    .clk(clk),
    .clear_i(rst | invalidate_i | flush_done_o),
    .rd_en_i(1'b1),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(valid_rd_w),
    .wr_en_i(valid_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(1'b1),
    .wr_mask_i(1'b1)
  );

  Sram1Rw #(
    .DATA_WIDTH(1),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_dirty_sram (
    .clk(clk),
    .clear_i(rst | invalidate_i | flush_done_o),
    .rd_en_i(1'b1),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(dirty_rd_w),
    .wr_en_i(dirty_wr_en_w),
    .wr_addr_i(dirty_wr_addr_w),
    .wr_data_i(dirty_wr_data_w),
    .wr_mask_i(1'b1)
  );

  Sram1Rw #(
    .DATA_WIDTH(TAG_BITS),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_tag_sram (
    .clk(clk),
    .clear_i(rst),
    .rd_en_i(1'b1),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(tag_rd_w),
    .wr_en_i(tag_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(fill_tag_q),
    .wr_mask_i({TAG_BITS{1'b1}})
  );

  Sram1Rw #(
    .DATA_WIDTH(`XLEN),
    .ADDR_WIDTH(DATA_INDEX_BITS),
    .DEPTH(DATA_WORDS)
  ) u_data_sram (
    .clk(clk),
    .clear_i(rst),
    .rd_en_i(1'b1),
    .rd_addr_i(data_rd_index_w),
    .rd_data_o(data_rd_w),
    .wr_en_i(data_wr_en_w),
    .wr_addr_i(data_wr_addr_w),
    .wr_data_i(data_wr_data_w),
    .wr_mask_i(data_wr_mask_w)
  );

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      req_write_q <= 1'b0;
      req_addr_q <= {`XLEN{1'b0}};
      req_wdata_q <= {`XLEN{1'b0}};
      req_wstrb_q <= 4'b0000;
      fill_base_q <= {`XLEN{1'b0}};
      fill_index_q <= {INDEX_BITS{1'b0}};
      fill_tag_q <= {TAG_BITS{1'b0}};
      fill_word_q <= {WORD_BITS{1'b0}};
      victim_index_q <= {INDEX_BITS{1'b0}};
      victim_tag_q <= {TAG_BITS{1'b0}};
      wb_word_q <= {WORD_BITS{1'b0}};
      flush_index_q <= {INDEX_BITS{1'b0}};
      flush_word_q <= {WORD_BITS{1'b0}};
      axi_aw_done_q <= 1'b0;
      axi_w_done_q <= 1'b0;
      rsp_data_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
    end else if (invalidate_i) begin
      state_q <= S_IDLE;
      fill_word_q <= {WORD_BITS{1'b0}};
      wb_word_q <= {WORD_BITS{1'b0}};
      flush_index_q <= {INDEX_BITS{1'b0}};
      flush_word_q <= {WORD_BITS{1'b0}};
      axi_aw_done_q <= 1'b0;
      axi_w_done_q <= 1'b0;
      rsp_error_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          if (flush_i) begin
            flush_index_q <= {INDEX_BITS{1'b0}};
            flush_word_q <= {WORD_BITS{1'b0}};
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_SCAN;
          end else if (cpu_req_valid_i) begin
            req_write_q <= cpu_req_write_i;
            req_addr_q <= cpu_req_addr_i;
            req_wdata_q <= cpu_req_wdata_i;
            req_wstrb_q <= cpu_req_wstrb_i;
            state_q <= (cur_load_hit_w || cur_store_hit_w || cur_store_nop_w) ? S_IDLE : S_LOOKUP;
          end
        end

        S_LOOKUP: begin
          if (req_write_q) begin
            if (req_wstrb_q == 4'b0000) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              state_q <= S_RESP;
            end else if (!req_cacheable_w) begin
              axi_aw_done_q <= 1'b0;
              axi_w_done_q <= 1'b0;
              state_q <= S_UNCACHED_AW;
            end else if (lookup_hit_w) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              state_q <= S_RESP;
            end else begin
              fill_base_q <= line_base(req_addr_q);
              fill_index_q <= req_index_w;
              fill_tag_q <= req_tag_w;
              fill_word_q <= {WORD_BITS{1'b0}};
              victim_index_q <= req_index_w;
              victim_tag_q <= tag_rd_w;
              wb_word_q <= {WORD_BITS{1'b0}};
              axi_aw_done_q <= 1'b0;
              axi_w_done_q <= 1'b0;
              state_q <= (valid_rd_w && dirty_rd_w) ? S_WB_AW : S_FILL_AR;
            end
          end else if (!req_cacheable_w) begin
            state_q <= S_UNCACHED_AR;
          end else if (lookup_hit_w) begin
            rsp_data_q <= data_rd_w;
            rsp_error_q <= 1'b0;
            state_q <= S_RESP;
          end else begin
            fill_base_q <= line_base(req_addr_q);
            fill_index_q <= req_index_w;
            fill_tag_q <= req_tag_w;
            fill_word_q <= {WORD_BITS{1'b0}};
            victim_index_q <= req_index_w;
            victim_tag_q <= tag_rd_w;
            wb_word_q <= {WORD_BITS{1'b0}};
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= (valid_rd_w && dirty_rd_w) ? S_WB_AW : S_FILL_AR;
          end
        end

        S_WB_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_WB_B;
          end
        end

        S_WB_B: begin
          if (axi_bvalid_i) begin
            if (axi_bresp_i != 2'b00) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b1;
              state_q <= S_RESP;
            end else if (wb_last_word_w) begin
              wb_word_q <= {WORD_BITS{1'b0}};
              state_q <= S_FILL_AR;
            end else begin
              wb_word_q <= wb_word_q + 4'd1;
              state_q <= S_WB_AW;
            end
          end
        end

        S_FILL_AR: begin
          if (axi_arready_i) begin
            state_q <= S_FILL_R;
          end
        end

        S_FILL_R: begin
          if (axi_rvalid_i) begin
            if (axi_rresp_i != 2'b00) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b1;
              state_q <= S_RESP;
            end else if (fill_last_word_w) begin
              fill_word_q <= {WORD_BITS{1'b0}};
              state_q <= req_write_q ? S_STORE_ALLOC_UPDATE : S_LOOKUP;
            end else begin
              fill_word_q <= fill_word_q + 4'd1;
              state_q <= S_FILL_AR;
            end
          end
        end

        S_STORE_ALLOC_UPDATE: begin
          rsp_data_q <= {`XLEN{1'b0}};
          rsp_error_q <= 1'b0;
          state_q <= S_RESP;
        end

        S_UNCACHED_AR: begin
          if (axi_arready_i) begin
            state_q <= S_UNCACHED_R;
          end
        end

        S_UNCACHED_R: begin
          if (axi_rvalid_i) begin
            rsp_data_q <= axi_rdata_i;
            rsp_error_q <= (axi_rresp_i != 2'b00);
            state_q <= S_RESP;
          end
        end

        S_UNCACHED_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_UNCACHED_B;
          end
        end

        S_UNCACHED_B: begin
          if (axi_bvalid_i) begin
            rsp_data_q <= {`XLEN{1'b0}};
            rsp_error_q <= (axi_bresp_i != 2'b00);
            state_q <= S_RESP;
          end
        end

        S_FLUSH_SCAN: begin
          flush_word_q <= {WORD_BITS{1'b0}};
          if (valid_rd_w && dirty_rd_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_WB_AW;
          end else if (flush_last_index_w) begin
            state_q <= S_FLUSH_DONE;
          end else begin
            flush_index_q <= flush_index_q + INDEX_STEP;
          end
        end

        S_FLUSH_WB_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_WB_B;
          end
        end

        S_FLUSH_WB_B: begin
          if (axi_bvalid_i) begin
            if (axi_bresp_i != 2'b00) begin
              state_q <= S_FLUSH_DONE;
            end else if (flush_last_word_w) begin
              flush_word_q <= {WORD_BITS{1'b0}};
              if (flush_last_index_w) begin
                state_q <= S_FLUSH_DONE;
              end else begin
                flush_index_q <= flush_index_q + INDEX_STEP;
                state_q <= S_FLUSH_SCAN;
              end
            end else begin
              flush_word_q <= flush_word_q + 4'd1;
              state_q <= S_FLUSH_WB_AW;
            end
          end
        end

        S_FLUSH_DONE: begin
          state_q <= flush_i ? S_FLUSH_DONE : S_IDLE;
        end

        S_RESP: begin
          state_q <= S_IDLE;
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
