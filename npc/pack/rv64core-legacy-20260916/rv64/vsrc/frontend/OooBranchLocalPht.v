`include "define.v"
`include "common/OooBranchDirectionPredictorFacts.vh"

// 4096-entry local PHT 的 production child wrapper。16 个 bank 只导出 state Q
// 的 read-only view；两个完整 12-bit lookup 各在本层作一次纯组合 0-cycle
// flat select。update 仍在所选 bank 内完成 S1(old counter/taken/row)→S2 write。
module OooBranchLocalPht (
  input clk,
  input rst,
  input clear_i,

  input [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup0_idx_i,
  output lookup0_valid_o,
  output [1:0] lookup0_ctr_o,

  input [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup1_idx_i,
  output lookup1_valid_o,
  output [1:0] lookup1_ctr_o,

  input update_valid_i,
  input [`BPU_LOCAL_PHT_INDEX_W-1:0] update_idx_i,
  input update_taken_i
);

  localparam integer BANKS = `OOO_BPU_LOCAL_PHT_BANKS;
  localparam integer BANK_W = `OOO_BPU_LOCAL_PHT_BANK_W;
  localparam integer ROWS = `OOO_BPU_LOCAL_PHT_ROWS;
  localparam integer ROW_W = `OOO_BPU_LOCAL_PHT_ROW_W;

  wire [BANK_W-1:0] update_bank_w =
      update_idx_i[`BPU_LOCAL_PHT_INDEX_W-1:ROW_W];
  wire [ROW_W-1:0] update_row_w = update_idx_i[ROW_W-1:0];

  wire [(BANKS*ROWS)-1:0] flat_valid_view_w;
  wire [(2*BANKS*ROWS)-1:0] flat_counter_view_w;

  genvar bank_i;
  generate
    // 展开成 16 个 state/update owner；view slice 只是 bank-major Q 端连线。
    for (bank_i = 0; bank_i < BANKS; bank_i = bank_i + 1) begin : g_bank
      localparam [BANK_W-1:0] THIS_BANK = bank_i;
      OooBranchLocalPhtBank #(
        .BANK_ID(bank_i)
      ) u_bank (
        .clk(clk),
        .rst(rst),
        .clear_i(clear_i),
        .valid_view_o(flat_valid_view_w[(ROWS*bank_i)+:ROWS]),
        .counter_view_o(
            flat_counter_view_w[((2*ROWS)*bank_i)+:(2*ROWS)]),
        .update_valid_i(update_valid_i && (update_bank_w == THIS_BANK)),
        .update_row_i(update_row_w),
        .update_taken_i(update_taken_i)
      );
    end
  endgenerate

  // 每路各一条完整 index→flat Q view 选择；不得拆回 bank-local lane mux。
  assign lookup0_valid_o = flat_valid_view_w[lookup0_idx_i];
  assign lookup0_ctr_o =
      flat_counter_view_w[(lookup0_idx_i * 2) +: 2];
  assign lookup1_valid_o = flat_valid_view_w[lookup1_idx_i];
  assign lookup1_ctr_o =
      flat_counter_view_w[(lookup1_idx_i * 2) +: 2];

`ifdef OOO_ASSERT
  initial begin
    if ((BANKS != 16) || (BANK_W != 4) || (ROWS != 256) ||
        (ROW_W != 8) || (`BPU_LOCAL_PHT_INDEX_W != 12) ||
        (`BPU_LOCAL_PHT_PC_BITS != 4) || (`BPU_LOCAL_HISTORY_W != 8)) begin
      $error("[BPU-LPHT-PARAM] bank/index invariant drifted");
      $fatal;
    end
  end
`endif

endmodule

// 单个 256-row bank。valid/counter view 只由本 bank 的 state Q 驱动；bank
// 不拥有 lane 地址或 row-select。update_taken_i 只负载 16 个 bank-local S1
// 捕获点，不直接进入 4096-entry 公共写锥。非阻塞赋值有意保持
// read-before-write：连续同 row update 的新 S1 读取本沿前的 payload，
// 不旁路同沿 S2 写回。
module OooBranchLocalPhtBank #(
  parameter integer BANK_ID = 0
) (
  input clk,
  input rst,
  input clear_i,

  output [`OOO_BPU_LOCAL_PHT_ROWS-1:0] valid_view_o,
  output [(2*`OOO_BPU_LOCAL_PHT_ROWS)-1:0] counter_view_o,

  input update_valid_i,
  input [`OOO_BPU_LOCAL_PHT_ROW_W-1:0] update_row_i,
  input update_taken_i
);

  localparam integer ROWS = `OOO_BPU_LOCAL_PHT_ROWS;
  localparam integer ROW_W = `OOO_BPU_LOCAL_PHT_ROW_W;

  reg [ROWS-1:0] valid_q;
  reg [1:0] counter_q [0:ROWS-1];

  reg upd_valid_q;
  reg [ROW_W-1:0] upd_row_q;
  reg upd_taken_q;
  reg [1:0] upd_old_ctr_q;

  function [1:0] counter_train;
    input [1:0] counter;
    input taken;
    begin
      if (taken) begin
        counter_train = (counter == 2'd3) ? 2'd3 : (counter + 2'd1);
      end else begin
        counter_train = (counter == 2'd0) ? 2'd0 : (counter - 2'd1);
      end
    end
  endfunction

  wire [1:0] update_old_ctr_w = valid_q[update_row_i] ?
      counter_q[update_row_i] : `BPU_COUNTER_INIT;

  assign valid_view_o = valid_q;

  genvar row_i;
  generate
    // 展开成 256 组并行 Q 端两位连线；这里不生成 variable-row mux。
    for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin : g_counter_view
      assign counter_view_o[(2*row_i)+:2] = counter_q[row_i];
    end
  endgenerate

  always @(posedge clk) begin
    if (rst || clear_i) begin
      valid_q <= {ROWS{1'b0}};
      upd_valid_q <= 1'b0;
    end else begin
      // S1：bank select 已在 wrapper 收窄；在本 bank 捕获 taken/row/old ctr。
      upd_valid_q <= update_valid_i;
      if (update_valid_i) begin
        upd_row_q <= update_row_i;
        upd_taken_q <= update_taken_i;
        upd_old_ctr_q <= update_old_ctr_w;
      end

      // S2：下一沿饱和写回。lookup 与新 S1 都观察本沿前的 bank payload。
      if (upd_valid_q) begin
        valid_q[upd_row_q] <= 1'b1;
        counter_q[upd_row_q] <= counter_train(upd_old_ctr_q, upd_taken_q);
      end
    end
  end

  wire unused_bank_id_w = (BANK_ID == 0);

endmodule
