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

  // [简化 2026-06-29] 移除死代码 function napot_match/entry_match。当前主逻辑统一走
  // per-entry range 解码，每个 entry 的 range 推导只算一次后共享给 overlap/full-cover。

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

  wire [7:0] entry_cfg_w [0:`PMP_ENTRY_COUNT-1];
  wire [`XLEN-1:0] entry_addr_w [0:`PMP_ENTRY_COUNT-1];
  wire [`PMP_ENTRY_COUNT-1:0] entry_overlap_w;
  wire [`PMP_ENTRY_COUNT-1:0] entry_full_cover_w;

  genvar entry_gen_idx;
  generate
    for (entry_gen_idx = 0; entry_gen_idx < `PMP_ENTRY_COUNT;
         entry_gen_idx = entry_gen_idx + 1) begin : gen_entry_range
      assign entry_cfg_w[entry_gen_idx] =
          pmpcfg_i[entry_gen_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W];
      assign entry_addr_w[entry_gen_idx] =
          pmpaddr_i[entry_gen_idx * `XLEN +: `XLEN];

      reg entry_active_r;
      reg [`XLEN-1:0] lower_bound_r;
      reg [`XLEN-1:0] upper_bound_r;
      reg [`XLEN-1:0] upper_last_r;
      reg [`XLEN-1:0] napot_select_mask_r;

      always @(*) begin
        entry_active_r = 1'b0;
        lower_bound_r = {`XLEN{1'b0}};
        upper_bound_r = {`XLEN{1'b0}};
        upper_last_r = {`XLEN{1'b0}};
        napot_select_mask_r = {`XLEN{1'b0}};
        case (entry_cfg_w[entry_gen_idx][`PMP_CFG_A_HI:`PMP_CFG_A_LO])
          `PMP_A_TOR: begin
            lower_bound_r = (entry_gen_idx == 0) ? {`XLEN{1'b0}} :
                            (entry_addr_w[entry_gen_idx - 1] << 2);
            upper_bound_r = entry_addr_w[entry_gen_idx] << 2;
            if (upper_bound_r > lower_bound_r) begin
              upper_last_r = upper_bound_r - {{(`XLEN-1){1'b0}}, 1'b1};
              entry_active_r = 1'b1;
            end
          end
          `PMP_A_NA4: begin
            lower_bound_r = entry_addr_w[entry_gen_idx] << 2;
            upper_last_r = lower_bound_r + 64'd3;
            entry_active_r = 1'b1;
          end
          `PMP_A_NAPOT: begin
            // NAPOT low-one run can be converted to the selector mask by
            // x^(x+1): for k low ones this yields (1<<(k+1))-1.  This avoids
            // synthesizing a per-entry trailing-one counter and variable shifts.
            napot_select_mask_r =
                entry_addr_w[entry_gen_idx] ^
                (entry_addr_w[entry_gen_idx] + {{(`XLEN-1){1'b0}}, 1'b1});
            entry_active_r = 1'b1;
            lower_bound_r =
                (entry_addr_w[entry_gen_idx] & ~napot_select_mask_r) << 2;
            upper_last_r =
                ((entry_addr_w[entry_gen_idx] | napot_select_mask_r) << 2) |
                {{(`XLEN-2){1'b0}}, 2'b11};
          end
          default: begin
            entry_active_r = 1'b0;
          end
        endcase
      end

      assign entry_overlap_w[entry_gen_idx] =
          entry_active_r &&
          range_overlap(paddr_i, access_last_addr_w, lower_bound_r, upper_last_r);
      assign entry_full_cover_w[entry_gen_idx] =
          entry_active_r &&
          range_full_cover(paddr_i, access_last_addr_w,
                           lower_bound_r, upper_last_r);
    end
  endgenerate

  always @* begin
    fault_r = 1'b0;
    match_found_r = 1'b0;
    match_full_r = 1'b0;
    match_cfg_r = 8'h00;
    enforce_r = 1'b0;

    // 综合为 16 路 entry range 解码 + first-overlap 优先选择器；每个 entry 的
    // bounds/NAPOT 推导只做一次，再共享给 overlap/full-cover 判定。
    for (pmp_idx = 0; pmp_idx < `PMP_ENTRY_COUNT; pmp_idx = pmp_idx + 1) begin
      if (!match_found_r && entry_overlap_w[pmp_idx]) begin
        match_found_r = 1'b1;
        match_full_r = entry_full_cover_w[pmp_idx];
        match_cfg_r = entry_cfg_w[pmp_idx];
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
