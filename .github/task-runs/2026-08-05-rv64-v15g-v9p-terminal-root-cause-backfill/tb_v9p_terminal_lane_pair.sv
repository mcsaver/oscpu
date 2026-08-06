`timescale 1ns/1ps

module tb_v9p_terminal_lane_pair;
  localparam integer INGRESS_N = 12;
`ifdef V9P_BANK1_PAIR
  localparam integer DROP_LANE = 4;
  localparam integer RETRY_LANE = 11;
`else
  localparam integer DROP_LANE = 2;
  localparam integer RETRY_LANE = 10;
`endif
  localparam [1:0] OWNER_KIND = 2'b00;
  localparam [4:0] OWNER_TOKEN = 5'd7;
  localparam [1:0] OWNER_EPOCH = 2'b01;

  reg clk;
  reg rst;
  reg [INGRESS_N-1:0] ingress_valid;
  reg [(INGRESS_N*2)-1:0] ingress_kind;
  reg [(INGRESS_N*5)-1:0] ingress_token;
  reg [(INGRESS_N*2)-1:0] ingress_epoch;
  reg [31:0] live_mask;
  reg [63:0] live_kind_table;
  reg [63:0] live_epoch_table;
  wire deq0_valid;
  wire [1:0] deq0_kind;
  wire [4:0] deq0_token;
  wire [1:0] deq0_epoch;
  wire deq1_valid;
  wire [1:0] deq1_kind;
  wire [4:0] deq1_token;
  wire [1:0] deq1_epoch;
  wire [31:0] pending_mask;
  wire [5:0] pending_count;

  OooMemOwnerTerminalCollector #(
    .INGRESS_N(INGRESS_N)
  ) dut (
    .clk(clk),
    .rst(rst),
    .ingress_valid_i(ingress_valid),
    .ingress_kind_i(ingress_kind),
    .ingress_token_i(ingress_token),
    .ingress_epoch_i(ingress_epoch),
    .live_mask_i(live_mask),
    .live_kind_table_i(live_kind_table),
    .live_epoch_table_i(live_epoch_table),
    .deq0_valid_o(deq0_valid),
    .deq0_kind_o(deq0_kind),
    .deq0_token_o(deq0_token),
    .deq0_epoch_o(deq0_epoch),
    .deq0_ready_i(1'b0),
    .deq1_valid_o(deq1_valid),
    .deq1_kind_o(deq1_kind),
    .deq1_token_o(deq1_token),
    .deq1_epoch_o(deq1_epoch),
    .deq1_ready_i(1'b0),
    .pending_mask_o(pending_mask),
    .pending_count_o(pending_count)
  );

  always #5 clk = ~clk;

  task automatic set_lane;
    input integer lane;
    begin
      ingress_kind[(lane*2) +: 2] = OWNER_KIND;
      ingress_token[(lane*5) +: 5] = OWNER_TOKEN;
      ingress_epoch[(lane*2) +: 2] = OWNER_EPOCH;
      ingress_valid[lane] = 1'b1;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    ingress_valid = {INGRESS_N{1'b0}};
    ingress_kind = {(INGRESS_N*2){1'b0}};
    ingress_token = {(INGRESS_N*5){1'b0}};
    ingress_epoch = {(INGRESS_N*2){1'b0}};
    live_mask = 32'b0;
    live_kind_table = 64'b0;
    live_epoch_table = 64'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    live_mask[OWNER_TOKEN] = 1'b1;
    live_kind_table[(OWNER_TOKEN*2) +: 2] = OWNER_KIND;
    live_epoch_table[(OWNER_TOKEN*2) +: 2] = OWNER_EPOCH;
    set_lane(DROP_LANE);
    set_lane(RETRY_LANE);
    $display("[V15G-V9P-LANE-PAIR-DRIVE] drop_lane=%0d retry_lane=%0d kind=%0d token=%0d epoch=%0d",
             DROP_LANE, RETRY_LANE, OWNER_KIND, OWNER_TOKEN, OWNER_EPOCH);
    @(posedge clk);
    #1;
    $display("[V15G-V9P-LANE-PAIR-ESCAPED][FAIL] collector did not stop");
    $fatal(1);
  end
endmodule
