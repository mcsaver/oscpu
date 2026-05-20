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
  output [`XLEN-1:0] cpu_rsp_data_o,
  output cpu_rsp_error_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output [`XLEN-1:0] mem_req_addr_o,
  input mem_rsp_valid_i,
  input [`XLEN-1:0] mem_rsp_data_i,
  input mem_rsp_error_i
);

  localparam LINE_WORDS = 16;
  localparam LINE_COUNT = 64;
  localparam OFFSET_BITS = 6;
  localparam INDEX_BITS = 6;
  localparam WORD_BITS = 4;
  localparam TAG_BITS = `XLEN - OFFSET_BITS - INDEX_BITS;
  localparam DATA_WORDS = LINE_COUNT * LINE_WORDS;
  localparam DATA_INDEX_BITS = INDEX_BITS + WORD_BITS;

  localparam [2:0] S_IDLE = 3'd0;
  localparam [2:0] S_LOOKUP = 3'd1;
  localparam [2:0] S_FILL_REQ = 3'd2;
  localparam [2:0] S_FILL_WAIT = 3'd3;
  localparam [2:0] S_UNCACHED_REQ = 3'd4;
  localparam [2:0] S_UNCACHED_WAIT = 3'd5;
  localparam [2:0] S_RESP = 3'd6;

  reg [2:0] state_q;
  reg [`XLEN-1:0] req_addr_q;
  reg [`XLEN-1:0] fill_base_q;
  reg [INDEX_BITS-1:0] fill_index_q;
  reg [TAG_BITS-1:0] fill_tag_q;
  reg [WORD_BITS-1:0] fill_word_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg rsp_error_q;

  reg valid_q [0:LINE_COUNT-1];
  reg [TAG_BITS-1:0] tag_q [0:LINE_COUNT-1];
  reg [`XLEN-1:0] data_q [0:DATA_WORDS-1];

  integer i;

  function cacheable_range4;
    input [`XLEN-1:0] addr;
    begin
      cacheable_range4 = (addr >= 32'h8000_0000) && (addr <= 32'h87ff_fffc);
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

  function [7:0] cache_byte;
    input [`XLEN-1:0] addr;
    reg [`XLEN-1:0] word;
    begin
      word = data_q[data_index(line_index(addr), word_offset(addr))];
      case (addr[1:0])
        2'b00: cache_byte = word[7:0];
        2'b01: cache_byte = word[15:8];
        2'b10: cache_byte = word[23:16];
        default: cache_byte = word[31:24];
      endcase
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
  wire cur_first_hit_w = valid_q[cur_first_index_w] && (tag_q[cur_first_index_w] == cur_first_tag_w);
  wire cur_second_hit_w = (~cur_need_second_line_w) ||
                          (valid_q[cur_second_index_w] && (tag_q[cur_second_index_w] == cur_second_tag_w));
  wire cur_lookup_hit_w = cur_first_hit_w && cur_second_hit_w;
  wire [`XLEN-1:0] cur_missing_line_addr_w = cur_first_hit_w ? cur_last_addr_w : cpu_req_addr_i;
  wire [`XLEN-1:0] cur_lookup_data_w = {
      cache_byte(cpu_req_addr_i + 32'd3),
      cache_byte(cpu_req_addr_i + 32'd2),
      cache_byte(cpu_req_addr_i + 32'd1),
      cache_byte(cpu_req_addr_i)
  };

  wire [`XLEN-1:0] req_last_addr_w = req_addr_q + 32'd3;
  wire req_misaligned_w = req_addr_q[0];
  wire req_cacheable_w = cacheable_range4(req_addr_q);
  wire need_second_line_w = line_base(req_addr_q) != line_base(req_last_addr_w);
  wire [INDEX_BITS-1:0] first_index_w = line_index(req_addr_q);
  wire [TAG_BITS-1:0] first_tag_w = line_tag(req_addr_q);
  wire [INDEX_BITS-1:0] second_index_w = line_index(req_last_addr_w);
  wire [TAG_BITS-1:0] second_tag_w = line_tag(req_last_addr_w);
  wire first_hit_w = valid_q[first_index_w] && (tag_q[first_index_w] == first_tag_w);
  wire second_hit_w = (~need_second_line_w) ||
                      (valid_q[second_index_w] && (tag_q[second_index_w] == second_tag_w));
  wire lookup_hit_w = first_hit_w && second_hit_w;
  wire [`XLEN-1:0] missing_line_addr_w = first_hit_w ? req_last_addr_w : req_addr_q;
  wire [`XLEN-1:0] lookup_data_w = {
      cache_byte(req_addr_q + 32'd3),
      cache_byte(req_addr_q + 32'd2),
      cache_byte(req_addr_q + 32'd1),
      cache_byte(req_addr_q)
  };
  wire [`XLEN-1:0] fill_req_addr_w =
      fill_base_q + {{(`XLEN-WORD_BITS-2){1'b0}}, fill_word_q, 2'b00};
  wire combo_rsp_valid_w = (state_q == S_IDLE) && cpu_req_valid_i &&
                           (cur_misaligned_w || (cur_cacheable_w && cur_lookup_hit_w));

  assign cpu_req_ready_o = (state_q == S_IDLE);
  assign cpu_rsp_valid_o = combo_rsp_valid_w || (state_q == S_RESP);
  assign cpu_rsp_data_o = combo_rsp_valid_w ?
                          (cur_misaligned_w ? {`XLEN{1'b0}} : cur_lookup_data_w) :
                          rsp_data_q;
  assign cpu_rsp_error_o = combo_rsp_valid_w ? cur_misaligned_w : rsp_error_q;
  assign mem_req_valid_o = (state_q == S_FILL_REQ) || (state_q == S_UNCACHED_REQ);
  assign mem_req_addr_o = (state_q == S_UNCACHED_REQ) ? req_addr_q : fill_req_addr_w;

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
      for (i = 0; i < LINE_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
        tag_q[i] <= {TAG_BITS{1'b0}};
      end
    end else if (invalidate_i) begin
      state_q <= S_IDLE;
      rsp_error_q <= 1'b0;
      for (i = 0; i < LINE_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
      end
    end else if (abort_i) begin
      if ((state_q == S_FILL_REQ) || (state_q == S_FILL_WAIT)) begin
        valid_q[fill_index_q] <= 1'b0;
      end
      state_q <= S_IDLE;
      rsp_error_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          if (cpu_req_valid_i) begin
            req_addr_q <= cpu_req_addr_i;
            if (cur_misaligned_w || (cur_cacheable_w && cur_lookup_hit_w)) begin
              state_q <= S_IDLE;
            end else if (!cur_cacheable_w) begin
              state_q <= S_UNCACHED_REQ;
            end else begin
              fill_base_q <= line_base(cur_missing_line_addr_w);
              fill_index_q <= line_index(cur_missing_line_addr_w);
              fill_tag_q <= line_tag(cur_missing_line_addr_w);
              fill_word_q <= {WORD_BITS{1'b0}};
              // 首次 miss 不再多等 LOOKUP 状态，下一拍直接向 RAM 发起 line fill。
              valid_q[line_index(cur_missing_line_addr_w)] <= 1'b0;
              state_q <= S_FILL_REQ;
            end
          end
        end

        S_LOOKUP: begin
          if (req_misaligned_w) begin
            rsp_data_q <= {`XLEN{1'b0}};
            rsp_error_q <= 1'b1;
            state_q <= S_RESP;
          end else if (!req_cacheable_w) begin
            state_q <= S_UNCACHED_REQ;
          end else if (lookup_hit_w) begin
            rsp_data_q <= lookup_data_w;
            rsp_error_q <= 1'b0;
            state_q <= S_RESP;
          end else begin
            fill_base_q <= line_base(missing_line_addr_w);
            fill_index_q <= line_index(missing_line_addr_w);
            fill_tag_q <= line_tag(missing_line_addr_w);
            fill_word_q <= {WORD_BITS{1'b0}};
            valid_q[line_index(missing_line_addr_w)] <= 1'b0;
            state_q <= S_FILL_REQ;
          end
        end

        S_FILL_REQ: begin
          if (mem_req_ready_i) begin
            state_q <= S_FILL_WAIT;
          end
        end

        S_FILL_WAIT: begin
          if (mem_rsp_valid_i) begin
            if (mem_rsp_error_i) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b1;
              state_q <= S_RESP;
            end else begin
              data_q[data_index(fill_index_q, fill_word_q)] <= mem_rsp_data_i;
              if (fill_word_q == {WORD_BITS{1'b1}}) begin
                valid_q[fill_index_q] <= 1'b1;
                tag_q[fill_index_q] <= fill_tag_q;
                fill_word_q <= {WORD_BITS{1'b0}};
                state_q <= S_LOOKUP;
              end else begin
                fill_word_q <= fill_word_q + 4'd1;
                state_q <= S_FILL_REQ;
              end
            end
          end
        end

        S_UNCACHED_REQ: begin
          if (mem_req_ready_i) begin
            state_q <= S_UNCACHED_WAIT;
          end
        end

        S_UNCACHED_WAIT: begin
          if (mem_rsp_valid_i) begin
            rsp_data_q <= mem_rsp_data_i;
            rsp_error_q <= mem_rsp_error_i;
            state_q <= S_RESP;
          end
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
