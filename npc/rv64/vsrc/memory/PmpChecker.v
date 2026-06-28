`include "define.v"

module PmpChecker (
  input [`XLEN-1:0] paddr_i,
  input [3:0] access_size_i,
  input [1:0] priv_mode_i,
  input access_read_i,
  input access_write_i,
  input access_exec_i,
  input [`PMP_CFG_BUS_W-1:0] pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] pmpaddr_i,
  output fault_o
);

  function [7:0] pmpcfg_at;
    input [`PMP_CFG_BUS_W-1:0] cfg_bus;
    input integer entry_idx;
    begin
      pmpcfg_at = cfg_bus[entry_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W];
    end
  endfunction

  function [`XLEN-1:0] pmpaddr_at;
    input [`PMP_ADDR_BUS_W-1:0] addr_bus;
    input integer entry_idx;
    begin
      pmpaddr_at = addr_bus[entry_idx * `XLEN +: `XLEN];
    end
  endfunction

  function [5:0] napot_ones;
    input [`XLEN-1:0] encoded_addr;
    integer bit_idx;
    reg done;
    begin
      napot_ones = 6'd0;
      done = 1'b0;
      for (bit_idx = 0; bit_idx < (`XLEN - 2); bit_idx = bit_idx + 1) begin
        if (!done) begin
          if (encoded_addr[bit_idx])
            napot_ones = napot_ones + 6'd1;
          else
            done = 1'b1;
        end
      end
    end
  endfunction

  function [`XLEN-1:0] access_last_addr;
    input [`XLEN-1:0] paddr;
    input [3:0] size;
    reg [3:0] safe_size;
    begin
      safe_size = (size == 4'd0) ? 4'd1 : size;
      access_last_addr = paddr +
          {{(`XLEN-4){1'b0}}, safe_size} -
          {{(`XLEN-1){1'b0}}, 1'b1};
    end
  endfunction

  function napot_full_range;
    input [`XLEN-1:0] encoded_addr;
    reg [5:0] ones;
    begin
      ones = napot_ones(encoded_addr);
      napot_full_range = (ones >= (`XLEN - 3));
    end
  endfunction

  function [`XLEN-1:0] napot_lower_bound;
    input [`XLEN-1:0] encoded_addr;
    reg [5:0] ones;
    reg [`XLEN-1:0] mask;
    begin
      ones = napot_ones(encoded_addr);
      if (ones >= (`XLEN - 3)) begin
        napot_lower_bound = {`XLEN{1'b0}};
      end else begin
        mask = ~((64'h1 << (ones + 6'd1)) - 64'h1);
        napot_lower_bound = (encoded_addr & mask) << 2;
      end
    end
  endfunction

  function [`XLEN-1:0] napot_upper_last;
    input [`XLEN-1:0] encoded_addr;
    reg [5:0] ones;
    reg [`XLEN-1:0] region_size;
    begin
      ones = napot_ones(encoded_addr);
      if (ones >= (`XLEN - 3)) begin
        napot_upper_last = {`XLEN{1'b1}};
      end else begin
        region_size = 64'h1 << (ones + 6'd3);
        napot_upper_last = napot_lower_bound(encoded_addr) + region_size -
                           {{(`XLEN-1){1'b0}}, 1'b1};
      end
    end
  endfunction

  function range_overlap;
    input [`XLEN-1:0] start_addr;
    input [`XLEN-1:0] last_addr;
    input [`XLEN-1:0] lower_bound;
    input [`XLEN-1:0] upper_last;
    begin
      range_overlap = (start_addr <= upper_last) && (last_addr >= lower_bound);
    end
  endfunction

  function range_full_cover;
    input [`XLEN-1:0] start_addr;
    input [`XLEN-1:0] last_addr;
    input [`XLEN-1:0] lower_bound;
    input [`XLEN-1:0] upper_last;
    begin
      range_full_cover = (start_addr >= lower_bound) &&
                         (last_addr <= upper_last);
    end
  endfunction

  function entry_overlap;
    input integer entry_idx;
    input [`XLEN-1:0] start_addr;
    input [`XLEN-1:0] last_addr;
    input [`PMP_CFG_BUS_W-1:0] cfg_bus;
    input [`PMP_ADDR_BUS_W-1:0] addr_bus;
    reg [7:0] cfg;
    reg [`XLEN-1:0] lower_bound;
    reg [`XLEN-1:0] upper_bound;
    reg [`XLEN-1:0] upper_last;
    begin
      cfg = pmpcfg_at(cfg_bus, entry_idx);
      entry_overlap = 1'b0;
      case (cfg[`PMP_CFG_A_HI:`PMP_CFG_A_LO])
        `PMP_A_TOR: begin
          lower_bound = (entry_idx == 0) ? {`XLEN{1'b0}} :
                        (pmpaddr_at(addr_bus, entry_idx - 1) << 2);
          upper_bound = pmpaddr_at(addr_bus, entry_idx) << 2;
          if (upper_bound > lower_bound) begin
            upper_last = upper_bound - {{(`XLEN-1){1'b0}}, 1'b1};
            entry_overlap = range_overlap(start_addr, last_addr,
                                          lower_bound, upper_last);
          end
        end
        `PMP_A_NA4: begin
          lower_bound = pmpaddr_at(addr_bus, entry_idx) << 2;
          upper_last = lower_bound + 64'd3;
          entry_overlap = range_overlap(start_addr, last_addr,
                                        lower_bound, upper_last);
        end
        `PMP_A_NAPOT: begin
          lower_bound = napot_lower_bound(pmpaddr_at(addr_bus, entry_idx));
          upper_last = napot_upper_last(pmpaddr_at(addr_bus, entry_idx));
          entry_overlap = range_overlap(start_addr, last_addr,
                                        lower_bound, upper_last);
        end
        default: begin
          entry_overlap = 1'b0;
        end
      endcase
    end
  endfunction

  function entry_full_cover;
    input integer entry_idx;
    input [`XLEN-1:0] start_addr;
    input [`XLEN-1:0] last_addr;
    input [`PMP_CFG_BUS_W-1:0] cfg_bus;
    input [`PMP_ADDR_BUS_W-1:0] addr_bus;
    reg [7:0] cfg;
    reg [`XLEN-1:0] lower_bound;
    reg [`XLEN-1:0] upper_bound;
    reg [`XLEN-1:0] upper_last;
    begin
      cfg = pmpcfg_at(cfg_bus, entry_idx);
      entry_full_cover = 1'b0;
      case (cfg[`PMP_CFG_A_HI:`PMP_CFG_A_LO])
        `PMP_A_TOR: begin
          lower_bound = (entry_idx == 0) ? {`XLEN{1'b0}} :
                        (pmpaddr_at(addr_bus, entry_idx - 1) << 2);
          upper_bound = pmpaddr_at(addr_bus, entry_idx) << 2;
          if (upper_bound > lower_bound) begin
            upper_last = upper_bound - {{(`XLEN-1){1'b0}}, 1'b1};
            entry_full_cover = range_full_cover(start_addr, last_addr,
                                                lower_bound, upper_last);
          end
        end
        `PMP_A_NA4: begin
          lower_bound = pmpaddr_at(addr_bus, entry_idx) << 2;
          upper_last = lower_bound + 64'd3;
          entry_full_cover = range_full_cover(start_addr, last_addr,
                                              lower_bound, upper_last);
        end
        `PMP_A_NAPOT: begin
          lower_bound = napot_lower_bound(pmpaddr_at(addr_bus, entry_idx));
          upper_last = napot_upper_last(pmpaddr_at(addr_bus, entry_idx));
          entry_full_cover = range_full_cover(start_addr, last_addr,
                                              lower_bound, upper_last);
        end
        default: begin
          entry_full_cover = 1'b0;
        end
      endcase
    end
  endfunction

  // [简化 2026-06-29] 移除死代码 function napot_match(全仓无调用,仅函数体自引用;
  //   NAPOT 匹配实际走 entry_overlap/entry_full_cover 路径)。
  // [简化 2026-06-28] 移除死代码 function entry_match(全仓无调用;主逻辑用 entry_overlap/
  // entry_full_cover)。经 bug-hunt 核实未用,build 验证无回归。

  reg fault_r;
  reg match_found_r;
  reg match_full_r;
  reg [7:0] match_cfg_r;
  reg enforce_r;
  integer pmp_idx;

  wire access_req_w = access_read_i || access_write_i || access_exec_i;
  wire [`XLEN-1:0] access_last_addr_w =
      access_last_addr(paddr_i, access_size_i);
  wire access_wrap_w = access_req_w && (access_last_addr_w < paddr_i);

  always @* begin
    fault_r = 1'b0;
    match_found_r = 1'b0;
    match_full_r = 1'b0;
    match_cfg_r = 8'h00;
    enforce_r = 1'b0;

    for (pmp_idx = 0; pmp_idx < `PMP_ENTRY_COUNT; pmp_idx = pmp_idx + 1) begin
      if (!match_found_r &&
          entry_overlap(pmp_idx, paddr_i, access_last_addr_w,
                        pmpcfg_i, pmpaddr_i)) begin
        match_found_r = 1'b1;
        match_full_r = entry_full_cover(pmp_idx, paddr_i, access_last_addr_w,
                                        pmpcfg_i, pmpaddr_i);
        match_cfg_r = pmpcfg_at(pmpcfg_i, pmp_idx);
      end
    end

    if (access_wrap_w) begin
      fault_r = 1'b1;
    end else if (match_found_r) begin
      enforce_r = (priv_mode_i != `PRIV_M) || match_cfg_r[`PMP_CFG_L];
      fault_r = enforce_r &&
                (!match_full_r ||
                 (access_read_i && !match_cfg_r[`PMP_CFG_R]) ||
                 (access_write_i && !match_cfg_r[`PMP_CFG_W]) ||
                 (access_exec_i && !match_cfg_r[`PMP_CFG_X]));
    end else begin
      fault_r = (priv_mode_i != `PRIV_M) &&
                (access_read_i || access_write_i || access_exec_i);
    end
  end

  assign fault_o = fault_r;

endmodule
