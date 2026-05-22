`include "define.v"

/* verilator lint_off UNUSEDSIGNAL */

module ICache (
  input clk,
  input rst,
  input abort_i,
  input invalidate_i,

  input cpu_req_valid_i,
  output cpu_req_ready_o,
  input [`XLEN-1:0] cpu_req_addr_i,
  output cpu_rsp_valid_o,
  input cpu_rsp_ready_i,
  output [`XLEN-1:0] cpu_rsp_data_o,
  output cpu_rsp_error_o,

  output axi_arvalid_o,
  input axi_arready_i,
  output [`XLEN-1:0] axi_araddr_o,
  input axi_rvalid_i,
  output axi_rready_o,
  input [`XLEN-1:0] axi_rdata_i,
  input [1:0] axi_rresp_i
);

  localparam LINE_WORDS = `ICACHE_LINE_WORDS;
  localparam LINE_COUNT = `ICACHE_LINE_COUNT;
  localparam OFFSET_BITS = `ICACHE_OFFSET_BITS;
  localparam INDEX_BITS = `ICACHE_INDEX_BITS;
  localparam WORD_BITS = `ICACHE_WORD_BITS;
  localparam TAG_BITS = `XLEN - OFFSET_BITS - INDEX_BITS;
  localparam LINE_DATA_BITS = LINE_WORDS * `XLEN;
  localparam [WORD_BITS-1:0] WORD_STEP = {{(WORD_BITS-1){1'b0}}, 1'b1};

  localparam [2:0] S_IDLE = 3'd0;
  localparam [2:0] S_LOOKUP = 3'd1;
  localparam [2:0] S_FILL_AR = 3'd2;
  localparam [2:0] S_FILL_R = 3'd3;
  localparam [2:0] S_UNCACHED_AR = 3'd4;
  localparam [2:0] S_UNCACHED_R = 3'd5;
  localparam [2:0] S_RESP = 3'd6;

  reg [2:0] state_q;
  reg [`XLEN-1:0] req_addr_q;
  reg [`XLEN-1:0] fill_base_q;
  reg [INDEX_BITS-1:0] fill_index_q;
  reg [TAG_BITS-1:0] fill_tag_q;
  reg [WORD_BITS-1:0] fill_word_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg rsp_error_q;

  function cacheable_range4;
    input [`XLEN-1:0] addr;
    begin
      cacheable_range4 = (addr >= `CACHEABLE_BASE) && (addr <= `CACHEABLE_LAST);
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

  function [`XLEN-1:0] line_base;
    input [`XLEN-1:0] addr;
    begin
      line_base = {addr[`XLEN-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    end
  endfunction

  function [7:0] line_byte;
    input [LINE_DATA_BITS-1:0] line_data;
    input [OFFSET_BITS-1:0] byte_off;
    reg [`XLEN-1:0] word;
    begin
      word = line_data[{byte_off[OFFSET_BITS-1:2], 5'b00000} +: `XLEN];
      case (byte_off[1:0])
        2'b00: line_byte = word[7:0];
        2'b01: line_byte = word[15:8];
        2'b10: line_byte = word[23:16];
        default: line_byte = word[31:24];
      endcase
    end
  endfunction

  function [7:0] lookup_byte;
    input [`XLEN-1:0] base_addr;
    input [LINE_DATA_BITS-1:0] first_line;
    input [LINE_DATA_BITS-1:0] second_line;
    input [`XLEN-1:0] byte_addr;
    begin
      lookup_byte = (line_base(byte_addr) == line_base(base_addr)) ?
                    line_byte(first_line, byte_addr[OFFSET_BITS-1:0]) :
                    line_byte(second_line, byte_addr[OFFSET_BITS-1:0]);
    end
  endfunction

  function [LINE_DATA_BITS-1:0] line_word_mask;
    input [WORD_BITS-1:0] word;
    begin
      line_word_mask = {{(LINE_DATA_BITS-`XLEN){1'b0}}, {`XLEN{1'b1}}} << {word, 5'b00000};
    end
  endfunction

  function [LINE_DATA_BITS-1:0] line_word_data;
    input [WORD_BITS-1:0] word;
    input [`XLEN-1:0] data;
    begin
      line_word_data = {{(LINE_DATA_BITS-`XLEN){1'b0}}, data} << {word, 5'b00000};
    end
  endfunction

  wire [`XLEN-1:0] cur_last_addr_w = cpu_req_addr_i + 32'd3;
  wire cur_misaligned_w = cpu_req_addr_i[0];
  wire cur_cacheable_w = cacheable_range4(cpu_req_addr_i);
  wire cur_need_second_line_w = line_base(cpu_req_addr_i) != line_base(cur_last_addr_w);
  wire [INDEX_BITS-1:0] cur_first_index_w = line_index(cpu_req_addr_i);
  wire [TAG_BITS-1:0] cur_first_tag_w = line_tag(cpu_req_addr_i);
  wire [INDEX_BITS-1:0] cur_second_index_w = line_index(cur_last_addr_w);
  wire [TAG_BITS-1:0] cur_second_tag_w = line_tag(cur_last_addr_w);

  wire [`XLEN-1:0] req_last_addr_w = req_addr_q + 32'd3;
  wire req_misaligned_w = req_addr_q[0];
  wire req_cacheable_w = cacheable_range4(req_addr_q);
  wire need_second_line_w = line_base(req_addr_q) != line_base(req_last_addr_w);
  wire [INDEX_BITS-1:0] first_index_w = line_index(req_addr_q);
  wire [TAG_BITS-1:0] first_tag_w = line_tag(req_addr_q);
  wire [INDEX_BITS-1:0] second_index_w = line_index(req_last_addr_w);
  wire [TAG_BITS-1:0] second_tag_w = line_tag(req_last_addr_w);

  wire lookup_cur_w = (state_q == S_IDLE);
  wire [INDEX_BITS-1:0] sram_rd0_index_w = lookup_cur_w ? cur_first_index_w : first_index_w;
  wire [INDEX_BITS-1:0] sram_rd1_index_w = lookup_cur_w ? cur_second_index_w : second_index_w;
  wire valid_rd0_w;
  wire valid_rd1_w;
  wire [TAG_BITS-1:0] tag_rd0_w;
  wire [TAG_BITS-1:0] tag_rd1_w;
  wire [LINE_DATA_BITS-1:0] data_rd0_w;
  wire [LINE_DATA_BITS-1:0] data_rd1_w;

  wire cur_first_hit_w = valid_rd0_w && (tag_rd0_w == cur_first_tag_w);
  wire cur_second_hit_w = (~cur_need_second_line_w) ||
                          (valid_rd1_w && (tag_rd1_w == cur_second_tag_w));
  wire cur_lookup_hit_w = cur_first_hit_w && cur_second_hit_w;
  wire [`XLEN-1:0] cur_missing_line_addr_w = cur_first_hit_w ? cur_last_addr_w : cpu_req_addr_i;
  wire [`XLEN-1:0] cur_lookup_data_w = {
      lookup_byte(cpu_req_addr_i, data_rd0_w, data_rd1_w, cpu_req_addr_i + 32'd3),
      lookup_byte(cpu_req_addr_i, data_rd0_w, data_rd1_w, cpu_req_addr_i + 32'd2),
      lookup_byte(cpu_req_addr_i, data_rd0_w, data_rd1_w, cpu_req_addr_i + 32'd1),
      lookup_byte(cpu_req_addr_i, data_rd0_w, data_rd1_w, cpu_req_addr_i)
  };

  wire first_hit_w = valid_rd0_w && (tag_rd0_w == first_tag_w);
  wire second_hit_w = (~need_second_line_w) ||
                      (valid_rd1_w && (tag_rd1_w == second_tag_w));
  wire lookup_hit_w = first_hit_w && second_hit_w;
  wire [`XLEN-1:0] missing_line_addr_w = first_hit_w ? req_last_addr_w : req_addr_q;
  wire [`XLEN-1:0] lookup_data_w = {
      lookup_byte(req_addr_q, data_rd0_w, data_rd1_w, req_addr_q + 32'd3),
      lookup_byte(req_addr_q, data_rd0_w, data_rd1_w, req_addr_q + 32'd2),
      lookup_byte(req_addr_q, data_rd0_w, data_rd1_w, req_addr_q + 32'd1),
      lookup_byte(req_addr_q, data_rd0_w, data_rd1_w, req_addr_q)
  };

  wire [`XLEN-1:0] fill_req_addr_w =
      fill_base_q + {{(`XLEN-WORD_BITS-2){1'b0}}, fill_word_q, 2'b00};
  wire combo_rsp_valid_w = (state_q == S_IDLE) && cpu_req_valid_i &&
                           (cur_misaligned_w || (cur_cacheable_w && cur_lookup_hit_w));
  wire [`XLEN-1:0] combo_rsp_data_w = cur_misaligned_w ? {`XLEN{1'b0}} :
                                                         cur_lookup_data_w;
  wire combo_rsp_error_w = cur_misaligned_w;
  wire fill_rsp_fire_w = (state_q == S_FILL_R) && axi_rvalid_i && axi_rready_o;
  wire fill_rsp_ok_w = fill_rsp_fire_w && (axi_rresp_i == 2'b00);
  wire fill_last_word_w = (fill_word_q == {WORD_BITS{1'b1}});
  wire fill_done_w = fill_rsp_ok_w && fill_last_word_w;
  wire miss_start_w = (state_q == S_IDLE) && cpu_req_valid_i &&
                      !cur_misaligned_w && cur_cacheable_w && !cur_lookup_hit_w;

  wire valid_wr_en_w = miss_start_w || fill_done_w;
  wire [INDEX_BITS-1:0] valid_wr_addr_w = miss_start_w ?
                                          line_index(cur_missing_line_addr_w) :
                                          fill_index_q;
  wire valid_wr_data_w = fill_done_w;
  wire tag_wr_en_w = fill_done_w;
  wire data_wr_en_w = fill_rsp_ok_w;
  wire [LINE_DATA_BITS-1:0] data_wr_mask_w = line_word_mask(fill_word_q);
  wire [LINE_DATA_BITS-1:0] data_wr_data_w = line_word_data(fill_word_q, axi_rdata_i);

  assign cpu_req_ready_o = (state_q == S_IDLE);
  assign cpu_rsp_valid_o = combo_rsp_valid_w || (state_q == S_RESP);
  assign cpu_rsp_data_o = combo_rsp_valid_w ? combo_rsp_data_w : rsp_data_q;
  assign cpu_rsp_error_o = combo_rsp_valid_w ? combo_rsp_error_w : rsp_error_q;

  assign axi_arvalid_o = (state_q == S_FILL_AR) || (state_q == S_UNCACHED_AR);
  assign axi_araddr_o = (state_q == S_UNCACHED_AR) ? req_addr_q : fill_req_addr_w;
  assign axi_rready_o = (state_q == S_FILL_R) || (state_q == S_UNCACHED_R);

  Sram2R1W #(
    .DATA_WIDTH(1),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_valid_sram (
    .clk(clk),
    .clear_i(rst | invalidate_i),
    .rd0_en_i(1'b1),
    .rd0_addr_i(sram_rd0_index_w),
    .rd0_data_o(valid_rd0_w),
    .rd1_en_i(1'b1),
    .rd1_addr_i(sram_rd1_index_w),
    .rd1_data_o(valid_rd1_w),
    .wr_en_i(valid_wr_en_w),
    .wr_addr_i(valid_wr_addr_w),
    .wr_data_i(valid_wr_data_w),
    .wr_mask_i(1'b1)
  );

  Sram2R1W #(
    .DATA_WIDTH(TAG_BITS),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_tag_sram (
    .clk(clk),
    .clear_i(rst),
    .rd0_en_i(1'b1),
    .rd0_addr_i(sram_rd0_index_w),
    .rd0_data_o(tag_rd0_w),
    .rd1_en_i(1'b1),
    .rd1_addr_i(sram_rd1_index_w),
    .rd1_data_o(tag_rd1_w),
    .wr_en_i(tag_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(fill_tag_q),
    .wr_mask_i({TAG_BITS{1'b1}})
  );

  Sram2R1W #(
    .DATA_WIDTH(LINE_DATA_BITS),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(LINE_COUNT)
  ) u_data_sram (
    .clk(clk),
    .clear_i(rst),
    .rd0_en_i(1'b1),
    .rd0_addr_i(sram_rd0_index_w),
    .rd0_data_o(data_rd0_w),
    .rd1_en_i(1'b1),
    .rd1_addr_i(sram_rd1_index_w),
    .rd1_data_o(data_rd1_w),
    .wr_en_i(data_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(data_wr_data_w),
    .wr_mask_i(data_wr_mask_w)
  );

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      req_addr_q <= {`XLEN{1'b0}};
      fill_base_q <= {`XLEN{1'b0}};
      fill_index_q <= {INDEX_BITS{1'b0}};
      fill_tag_q <= {TAG_BITS{1'b0}};
      fill_word_q <= {WORD_BITS{1'b0}};
      rsp_data_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
    end else if (invalidate_i) begin
      state_q <= S_IDLE;
      rsp_error_q <= 1'b0;
    end else if (abort_i) begin
      state_q <= S_IDLE;
      rsp_error_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          if (cpu_req_valid_i) begin
            req_addr_q <= cpu_req_addr_i;
            if (cur_misaligned_w || (cur_cacheable_w && cur_lookup_hit_w)) begin
              if (!cpu_rsp_ready_i) begin
                rsp_data_q <= combo_rsp_data_w;
                rsp_error_q <= combo_rsp_error_w;
                state_q <= S_RESP;
              end else begin
                state_q <= S_IDLE;
              end
            end else if (!cur_cacheable_w) begin
              state_q <= S_UNCACHED_AR;
            end else begin
              fill_base_q <= line_base(cur_missing_line_addr_w);
              fill_index_q <= line_index(cur_missing_line_addr_w);
              fill_tag_q <= line_tag(cur_missing_line_addr_w);
              fill_word_q <= {WORD_BITS{1'b0}};
              state_q <= S_FILL_AR;
            end
          end
        end

        S_LOOKUP: begin
          if (req_misaligned_w) begin
            rsp_data_q <= {`XLEN{1'b0}};
            rsp_error_q <= 1'b1;
            state_q <= S_RESP;
          end else if (!req_cacheable_w) begin
            state_q <= S_UNCACHED_AR;
          end else if (lookup_hit_w) begin
            rsp_data_q <= lookup_data_w;
            rsp_error_q <= 1'b0;
            state_q <= S_RESP;
          end else begin
            fill_base_q <= line_base(missing_line_addr_w);
            fill_index_q <= line_index(missing_line_addr_w);
            fill_tag_q <= line_tag(missing_line_addr_w);
            fill_word_q <= {WORD_BITS{1'b0}};
            state_q <= S_FILL_AR;
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
              state_q <= S_LOOKUP;
            end else begin
              fill_word_q <= fill_word_q + WORD_STEP;
              state_q <= S_FILL_AR;
            end
          end
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

        S_RESP: begin
          if (cpu_rsp_ready_i) begin
            state_q <= S_IDLE;
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
