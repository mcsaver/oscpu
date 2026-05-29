`include "define.v"

module OooMemAxiBridge (
  input clk,
  input rst,

  input mem0_req_valid_i,
  output mem0_req_ready_o,
  input mem0_req_write_i,
  input [`XLEN-1:0] mem0_req_addr_i,
  input [`XLEN-1:0] mem0_req_wdata_i,
  input [3:0] mem0_req_wstrb_i,
  output mem0_rsp_valid_o,
  input mem0_rsp_ready_i,
  output [`XLEN-1:0] mem0_rsp_rdata_o,
  output mem0_rsp_error_o,

  input mem1_req_valid_i,
  output mem1_req_ready_o,
  input mem1_req_write_i,
  input [`XLEN-1:0] mem1_req_addr_i,
  input [`XLEN-1:0] mem1_req_wdata_i,
  input [3:0] mem1_req_wstrb_i,
  output mem1_rsp_valid_o,
  input mem1_rsp_ready_i,
  output [`XLEN-1:0] mem1_rsp_rdata_o,
  output mem1_rsp_error_o,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [3:0] lsu_axi_wstrb_o,
  input lsu_axi_bvalid_i,
  output lsu_axi_bready_o,
  input [1:0] lsu_axi_bresp_i
);

  localparam [2:0] S_IDLE = 3'd0;
  localparam [2:0] S_READ_ADDR = 3'd1;
  localparam [2:0] S_READ_DATA = 3'd2;
  localparam [2:0] S_WRITE_REQ = 3'd3;
  localparam [2:0] S_WRITE_RESP = 3'd4;
  localparam [2:0] S_RESP = 3'd5;
  localparam DCACHE_INDEX_W = 10;
  localparam DCACHE_ENTRIES = (1 << DCACHE_INDEX_W);

  reg [2:0] state_q;
  reg active_port_q;
  reg write_q;
  reg [`XLEN-1:0] addr_q;
  reg [`XLEN-1:0] wdata_q;
  reg [3:0] wstrb_q;
  reg [`XLEN-1:0] rsp_rdata_q;
  reg rsp_error_q;
  reg aw_done_q;
  reg w_done_q;

  reg [DCACHE_ENTRIES-1:0] dcache_valid_q;
  reg [`XLEN-1:0] dcache_addr_q [0:DCACHE_ENTRIES-1];
  reg [`XLEN-1:0] dcache_data_q [0:DCACHE_ENTRIES-1];

  /* verilator lint_off UNUSEDSIGNAL */
  function [DCACHE_INDEX_W-1:0] dcache_index;
    input [`XLEN-1:0] addr;
    begin
      dcache_index = addr[DCACHE_INDEX_W+1:2];
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  function dcacheable_addr;
    input [`XLEN-1:0] addr;
    begin
      dcacheable_addr = ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
    end
  endfunction

  function [`XLEN-1:0] merge_wstrb;
    input [`XLEN-1:0] old_data;
    input [`XLEN-1:0] new_data;
    input [3:0] mask;
    integer byte_idx;
    begin
      merge_wstrb = old_data;
      for (byte_idx = 0; byte_idx < 4; byte_idx = byte_idx + 1) begin
        if (mask[byte_idx]) begin
          merge_wstrb[byte_idx*8 +: 8] = new_data[byte_idx*8 +: 8];
        end
      end
    end
  endfunction

  wire mem0_req_fire_w = mem0_req_valid_i && mem0_req_ready_o;
  wire mem1_req_fire_w = mem1_req_valid_i && mem1_req_ready_o;
  wire aw_fire_w = lsu_axi_awvalid_o && lsu_axi_awready_i;
  wire w_fire_w = lsu_axi_wvalid_o && lsu_axi_wready_i;
  wire rsp_ready_w = (active_port_q == 1'b0) ? mem0_rsp_ready_i : mem1_rsp_ready_i;
  wire req_slot_ready_w = (state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w);
  wire req_select_mem1_w = !mem0_req_valid_i && mem1_req_valid_i;
  wire req_write_w = req_select_mem1_w ? mem1_req_write_i : mem0_req_write_i;
  wire [`XLEN-1:0] req_addr_w =
      req_select_mem1_w ? mem1_req_addr_i : mem0_req_addr_i;
  wire [`XLEN-1:0] req_wdata_w =
      req_select_mem1_w ? mem1_req_wdata_i : mem0_req_wdata_i;
  wire [3:0] req_wstrb_w =
      req_select_mem1_w ? mem1_req_wstrb_i : mem0_req_wstrb_i;
  wire [DCACHE_INDEX_W-1:0] req_dcache_idx_w = dcache_index(req_addr_w);
  wire req_dcacheable_w = dcacheable_addr(req_addr_w);
  wire req_dcache_hit_w =
      req_dcacheable_w && dcache_valid_q[req_dcache_idx_w] &&
      (dcache_addr_q[req_dcache_idx_w] == req_addr_w);
  wire req_read_miss_fire_w =
      (mem0_req_fire_w || mem1_req_fire_w) && !req_write_w &&
      !req_dcache_hit_w;
  wire [DCACHE_INDEX_W-1:0] rsp_dcache_idx_w = dcache_index(addr_q);

  assign mem0_req_ready_o = req_slot_ready_w;
  assign mem1_req_ready_o = req_slot_ready_w && !mem0_req_valid_i;

  assign mem0_rsp_valid_o = (state_q == S_RESP) && (active_port_q == 1'b0);
  assign mem1_rsp_valid_o = (state_q == S_RESP) && (active_port_q == 1'b1);
  assign mem0_rsp_rdata_o = rsp_rdata_q;
  assign mem1_rsp_rdata_o = rsp_rdata_q;
  assign mem0_rsp_error_o = rsp_error_q;
  assign mem1_rsp_error_o = rsp_error_q;

  assign lsu_axi_arvalid_o = (state_q == S_READ_ADDR) ||
                             req_read_miss_fire_w;
  assign lsu_axi_araddr_o = req_read_miss_fire_w ? req_addr_w : addr_q;
  assign lsu_axi_rready_o = (state_q == S_READ_DATA);
  assign lsu_axi_awvalid_o = (state_q == S_WRITE_REQ) && !aw_done_q;
  assign lsu_axi_awaddr_o = addr_q;
  assign lsu_axi_wvalid_o = (state_q == S_WRITE_REQ) && !w_done_q;
  assign lsu_axi_wdata_o = wdata_q;
  assign lsu_axi_wstrb_o = wstrb_q;
  assign lsu_axi_bready_o = (state_q == S_WRITE_RESP);

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      active_port_q <= 1'b0;
      write_q <= 1'b0;
      addr_q <= {`XLEN{1'b0}};
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= 4'b0000;
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      dcache_valid_q <= {DCACHE_ENTRIES{1'b0}};
    end else begin
      case (state_q)
        S_IDLE: begin
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          if (mem0_req_fire_w) begin
            active_port_q <= 1'b0;
            write_q <= req_write_w;
            addr_q <= req_addr_w;
            wdata_q <= req_wdata_w;
            wstrb_q <= req_wstrb_w;
            if (req_write_w) begin
              if (req_dcache_hit_w) begin
                dcache_data_q[req_dcache_idx_w] <=
                    merge_wstrb(dcache_data_q[req_dcache_idx_w],
                                req_wdata_w, req_wstrb_w);
              end else if (req_dcacheable_w && (req_wstrb_w == 4'b1111)) begin
                dcache_valid_q[req_dcache_idx_w] <= 1'b1;
                dcache_addr_q[req_dcache_idx_w] <= req_addr_w;
                dcache_data_q[req_dcache_idx_w] <= req_wdata_w;
              end
              state_q <= S_WRITE_REQ;
            end else if (req_dcache_hit_w) begin
              rsp_rdata_q <= dcache_data_q[req_dcache_idx_w];
              rsp_error_q <= 1'b0;
              state_q <= S_RESP;
            end else begin
              state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
            end
          end else if (mem1_req_fire_w) begin
            active_port_q <= 1'b1;
            write_q <= req_write_w;
            addr_q <= req_addr_w;
            wdata_q <= req_wdata_w;
            wstrb_q <= req_wstrb_w;
            if (req_write_w) begin
              if (req_dcache_hit_w) begin
                dcache_data_q[req_dcache_idx_w] <=
                    merge_wstrb(dcache_data_q[req_dcache_idx_w],
                                req_wdata_w, req_wstrb_w);
              end else if (req_dcacheable_w && (req_wstrb_w == 4'b1111)) begin
                dcache_valid_q[req_dcache_idx_w] <= 1'b1;
                dcache_addr_q[req_dcache_idx_w] <= req_addr_w;
                dcache_data_q[req_dcache_idx_w] <= req_wdata_w;
              end
              state_q <= S_WRITE_REQ;
            end else if (req_dcache_hit_w) begin
              rsp_rdata_q <= dcache_data_q[req_dcache_idx_w];
              rsp_error_q <= 1'b0;
              state_q <= S_RESP;
            end else begin
              state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
            end
          end
        end

        S_READ_ADDR: begin
          if (lsu_axi_arready_i) begin
            state_q <= S_READ_DATA;
          end
        end

        S_READ_DATA: begin
          if (lsu_axi_rvalid_i) begin
            rsp_rdata_q <= lsu_axi_rdata_i;
            rsp_error_q <= (lsu_axi_rresp_i != 2'b00);
            if (dcacheable_addr(addr_q) && (lsu_axi_rresp_i == 2'b00)) begin
              dcache_valid_q[rsp_dcache_idx_w] <= 1'b1;
              dcache_addr_q[rsp_dcache_idx_w] <= addr_q;
              dcache_data_q[rsp_dcache_idx_w] <= lsu_axi_rdata_i;
            end
            state_q <= S_RESP;
          end
        end

        S_WRITE_REQ: begin
          if (aw_fire_w) begin
            aw_done_q <= 1'b1;
          end
          if (w_fire_w) begin
            w_done_q <= 1'b1;
          end
          if ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w)) begin
            state_q <= S_WRITE_RESP;
          end
        end

        S_WRITE_RESP: begin
          if (lsu_axi_bvalid_i) begin
            rsp_rdata_q <= {`XLEN{1'b0}};
            rsp_error_q <= (lsu_axi_bresp_i != 2'b00);
            state_q <= S_RESP;
          end
        end

        S_RESP: begin
          if (rsp_ready_w) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            if (mem0_req_fire_w) begin
              active_port_q <= 1'b0;
              write_q <= req_write_w;
              addr_q <= req_addr_w;
              wdata_q <= req_wdata_w;
              wstrb_q <= req_wstrb_w;
              if (req_write_w) begin
                if (req_dcache_hit_w) begin
                  dcache_data_q[req_dcache_idx_w] <=
                      merge_wstrb(dcache_data_q[req_dcache_idx_w],
                                  req_wdata_w, req_wstrb_w);
                end else if (req_dcacheable_w && (req_wstrb_w == 4'b1111)) begin
                  dcache_valid_q[req_dcache_idx_w] <= 1'b1;
                  dcache_addr_q[req_dcache_idx_w] <= req_addr_w;
                  dcache_data_q[req_dcache_idx_w] <= req_wdata_w;
                end
                state_q <= S_WRITE_REQ;
              end else if (req_dcache_hit_w) begin
                rsp_rdata_q <= dcache_data_q[req_dcache_idx_w];
                rsp_error_q <= 1'b0;
                state_q <= S_RESP;
              end else begin
                state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
              end
            end else if (mem1_req_fire_w) begin
              active_port_q <= 1'b1;
              write_q <= req_write_w;
              addr_q <= req_addr_w;
              wdata_q <= req_wdata_w;
              wstrb_q <= req_wstrb_w;
              if (req_write_w) begin
                if (req_dcache_hit_w) begin
                  dcache_data_q[req_dcache_idx_w] <=
                      merge_wstrb(dcache_data_q[req_dcache_idx_w],
                                  req_wdata_w, req_wstrb_w);
                end else if (req_dcacheable_w && (req_wstrb_w == 4'b1111)) begin
                  dcache_valid_q[req_dcache_idx_w] <= 1'b1;
                  dcache_addr_q[req_dcache_idx_w] <= req_addr_w;
                  dcache_data_q[req_dcache_idx_w] <= req_wdata_w;
                end
                state_q <= S_WRITE_REQ;
              end else if (req_dcache_hit_w) begin
                rsp_rdata_q <= dcache_data_q[req_dcache_idx_w];
                rsp_error_q <= 1'b0;
                state_q <= S_RESP;
              end else begin
                state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
              end
            end else begin
              state_q <= S_IDLE;
            end
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

  wire unused_write_q_w = write_q;

endmodule
