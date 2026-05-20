`include "define.v"

/* verilator lint_off UNUSEDSIGNAL */

module DCache (
  input clk,
  input rst,
  input invalidate_i,

  input cpu_req_valid_i,
  output cpu_req_ready_o,
  input cpu_req_write_i,
  input [`XLEN-1:0] cpu_req_addr_i,
  input [`XLEN-1:0] cpu_req_wdata_i,
  input [3:0] cpu_req_wstrb_i,
  output cpu_rsp_valid_o,
  output [`XLEN-1:0] cpu_rsp_rdata_o,
  output cpu_rsp_error_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [3:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  input [`XLEN-1:0] mem_rsp_rdata_i,
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

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_LOOKUP = 4'd1;
  localparam [3:0] S_FILL_REQ = 4'd2;
  localparam [3:0] S_FILL_WAIT = 4'd3;
  localparam [3:0] S_STORE_REQ = 4'd4;
  localparam [3:0] S_STORE_WAIT = 4'd5;
  localparam [3:0] S_UNCACHED_REQ = 4'd6;
  localparam [3:0] S_UNCACHED_WAIT = 4'd7;
  localparam [3:0] S_RESP = 4'd8;

  reg [3:0] state_q;
  reg req_write_q;
  reg [`XLEN-1:0] req_addr_q;
  reg [`XLEN-1:0] req_wdata_q;
  reg [3:0] req_wstrb_q;
  reg [`XLEN-1:0] fill_base_q;
  reg [INDEX_BITS-1:0] fill_index_q;
  reg [TAG_BITS-1:0] fill_tag_q;
  reg [WORD_BITS-1:0] fill_word_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg rsp_error_q;
  reg store_update_hit_q;
  reg [DATA_INDEX_BITS-1:0] store_update_index_q;

  reg valid_q [0:LINE_COUNT-1];
  reg [TAG_BITS-1:0] tag_q [0:LINE_COUNT-1];
  reg [`XLEN-1:0] data_q [0:DATA_WORDS-1];

  integer i;

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

  wire req_cacheable_w = cacheable_word(req_addr_q);
  wire [INDEX_BITS-1:0] req_index_w = line_index(req_addr_q);
  wire [TAG_BITS-1:0] req_tag_w = line_tag(req_addr_q);
  wire [WORD_BITS-1:0] req_word_w = word_offset(req_addr_q);
  wire [DATA_INDEX_BITS-1:0] req_data_index_w = data_index(req_index_w, req_word_w);
  wire lookup_hit_w = valid_q[req_index_w] && (tag_q[req_index_w] == req_tag_w);
  wire [`XLEN-1:0] lookup_data_w = data_q[req_data_index_w];
  wire [`XLEN-1:0] fill_req_addr_w =
      fill_base_q + {{(`XLEN-WORD_BITS-2){1'b0}}, fill_word_q, 2'b00};

  assign cpu_req_ready_o = (state_q == S_IDLE);
  assign cpu_rsp_valid_o = (state_q == S_RESP);
  assign cpu_rsp_rdata_o = rsp_data_q;
  assign cpu_rsp_error_o = rsp_error_q;
  assign mem_req_valid_o = (state_q == S_FILL_REQ) ||
                           (state_q == S_STORE_REQ) ||
                           (state_q == S_UNCACHED_REQ);
  assign mem_req_write_o = (state_q == S_STORE_REQ);
  assign mem_req_addr_o = (state_q == S_FILL_REQ) ? fill_req_addr_w : req_addr_q;
  assign mem_req_wdata_o = req_wdata_q;
  assign mem_req_wstrb_o = (state_q == S_STORE_REQ) ? req_wstrb_q : 4'b0000;

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
      rsp_data_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      store_update_hit_q <= 1'b0;
      store_update_index_q <= {DATA_INDEX_BITS{1'b0}};
      for (i = 0; i < LINE_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
        tag_q[i] <= {TAG_BITS{1'b0}};
      end
    end else if (invalidate_i) begin
      state_q <= S_IDLE;
      rsp_error_q <= 1'b0;
      store_update_hit_q <= 1'b0;
      for (i = 0; i < LINE_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
      end
    end else begin
      case (state_q)
        S_IDLE: begin
          if (cpu_req_valid_i) begin
            req_write_q <= cpu_req_write_i;
            req_addr_q <= cpu_req_addr_i;
            req_wdata_q <= cpu_req_wdata_i;
            req_wstrb_q <= cpu_req_wstrb_i;
            state_q <= S_LOOKUP;
          end
        end

        S_LOOKUP: begin
          if (req_write_q) begin
            if (req_wstrb_q == 4'b0000) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              store_update_hit_q <= 1'b0;
              state_q <= S_RESP;
            end else begin
              store_update_hit_q <= req_cacheable_w && lookup_hit_w;
              store_update_index_q <= req_data_index_w;
              state_q <= S_STORE_REQ;
            end
          end else if (!req_cacheable_w) begin
            state_q <= S_UNCACHED_REQ;
          end else if (lookup_hit_w) begin
            rsp_data_q <= lookup_data_w;
            rsp_error_q <= 1'b0;
            state_q <= S_RESP;
          end else begin
            fill_base_q <= line_base(req_addr_q);
            fill_index_q <= req_index_w;
            fill_tag_q <= req_tag_w;
            fill_word_q <= {WORD_BITS{1'b0}};
            valid_q[req_index_w] <= 1'b0;
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
              data_q[data_index(fill_index_q, fill_word_q)] <= mem_rsp_rdata_i;
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

        S_STORE_REQ: begin
          if (mem_req_ready_i) begin
            state_q <= S_STORE_WAIT;
          end
        end

        S_STORE_WAIT: begin
          if (mem_rsp_valid_i) begin
            if (!mem_rsp_error_i && store_update_hit_q) begin
              if (req_wstrb_q[0]) data_q[store_update_index_q][7:0] <= req_wdata_q[7:0];
              if (req_wstrb_q[1]) data_q[store_update_index_q][15:8] <= req_wdata_q[15:8];
              if (req_wstrb_q[2]) data_q[store_update_index_q][23:16] <= req_wdata_q[23:16];
              if (req_wstrb_q[3]) data_q[store_update_index_q][31:24] <= req_wdata_q[31:24];
            end
            rsp_data_q <= {`XLEN{1'b0}};
            rsp_error_q <= mem_rsp_error_i;
            store_update_hit_q <= 1'b0;
            state_q <= S_RESP;
          end
        end

        S_UNCACHED_REQ: begin
          if (mem_req_ready_i) begin
            state_q <= S_UNCACHED_WAIT;
          end
        end

        S_UNCACHED_WAIT: begin
          if (mem_rsp_valid_i) begin
            rsp_data_q <= mem_rsp_rdata_i;
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
