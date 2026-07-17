`timescale 1ns/1ps

module tb_s2_g1_terminal_collector_negative #(
  parameter integer CASE_ID = 0
);
  localparam integer INGRESS_N = 6;

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
  reg deq0_ready;
  wire deq1_valid;
  wire [1:0] deq1_kind;
  wire [4:0] deq1_token;
  wire [1:0] deq1_epoch;
  reg deq1_ready;
  wire [31:0] pending_mask;
  wire [5:0] pending_count;

  OooMemOwnerTerminalCollector #(
    .INGRESS_N(INGRESS_N)
  ) dut (
    .clk(clk), .rst(rst),
    .ingress_valid_i(ingress_valid),
    .ingress_kind_i(ingress_kind),
    .ingress_token_i(ingress_token),
    .ingress_epoch_i(ingress_epoch),
    .live_mask_i(live_mask),
    .live_kind_table_i(live_kind_table),
    .live_epoch_table_i(live_epoch_table),
    .deq0_valid_o(deq0_valid), .deq0_kind_o(deq0_kind),
    .deq0_token_o(deq0_token), .deq0_epoch_o(deq0_epoch),
    .deq0_ready_i(deq0_ready),
    .deq1_valid_o(deq1_valid), .deq1_kind_o(deq1_kind),
    .deq1_token_o(deq1_token), .deq1_epoch_o(deq1_epoch),
    .deq1_ready_i(deq1_ready),
    .pending_mask_o(pending_mask), .pending_count_o(pending_count)
  );

  always #5 clk = ~clk;

  task clear_ingress;
    begin
      ingress_valid = 0;
      ingress_kind = 0;
      ingress_token = 0;
      ingress_epoch = 0;
    end
  endtask

  task set_ingress;
    input integer lane;
    input [1:0] kind;
    input [4:0] token;
    input [1:0] epoch;
    begin
      ingress_valid[lane] = 1'b1;
      ingress_kind[(lane*2) +: 2] = kind;
      ingress_token[(lane*5) +: 5] = token;
      ingress_epoch[(lane*2) +: 2] = epoch;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_ingress();
    live_mask = 0;
    live_kind_table = 0;
    live_epoch_table = 0;
    deq0_ready = 1'b0;
    deq1_ready = 1'b0;
    live_mask[5] = 1'b1;
    live_kind_table[(5*2) +: 2] = 2'b01;
    live_epoch_table[(5*2) +: 2] = 2'b10;
    live_mask[6] = 1'b1;
    live_kind_table[(6*2) +: 2] = 2'b10;
    live_epoch_table[(6*2) +: 2] = 2'b01;

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    if (CASE_ID == 0) begin
      set_ingress(0, 2'b11, 5'd5, 2'b10);
      @(posedge clk);
    end else if (CASE_ID == 1) begin
      set_ingress(0, 2'b00, 5'd9, 2'b00);
      @(posedge clk);
    end else if (CASE_ID == 2) begin
      set_ingress(0, 2'b00, 5'd5, 2'b10);
      @(posedge clk);
    end else if (CASE_ID == 3) begin
      set_ingress(0, 2'b01, 5'd5, 2'b11);
      @(posedge clk);
    end else if (CASE_ID == 4) begin
      set_ingress(0, 2'b01, 5'd5, 2'b10);
      set_ingress(1, 2'b01, 5'd5, 2'b10);
      @(posedge clk);
    end else if (CASE_ID == 5) begin
      set_ingress(0, 2'b01, 5'd5, 2'b10);
      @(posedge clk);
      @(negedge clk);
      // The exact event remains valid while the token is already pending.
      @(posedge clk);
    end else begin
      set_ingress(0, 2'b10, 5'd6, 2'b01);
      @(posedge clk);
      @(negedge clk);
      clear_ingress();
      @(posedge clk);
      #1;
      if (!deq0_valid || deq0_token != 6) begin
        $display("[S2-G1-TCOLL-NEG][FAIL] setup did not reach registered output");
        $fatal(1);
      end
      @(negedge clk);
      deq0_ready = 1'b1;
      set_ingress(0, 2'b10, 5'd6, 2'b01);
      @(posedge clk);
    end

    #1;
    $display("[S2-G1-TCOLL-NEG][FAIL] CASE_ID=%0d did not trigger assertion",
             CASE_ID);
    $fatal(1);
  end
endmodule
