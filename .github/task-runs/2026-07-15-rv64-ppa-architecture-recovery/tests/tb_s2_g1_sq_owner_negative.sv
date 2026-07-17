`timescale 1ns/1ps
`include "define.v"

module tb_s2_g1_sq_owner_negative #(
  parameter CASE_ID = 1
);
  reg clk;
  reg rst;
  reg alloc0_valid;
  reg alloc1_valid;
  reg owner_bind_valid;
  reg [3:0] owner_bind_rob;
  reg [1:0] owner_bind_kind;
  reg [4:0] owner_bind_token;
  reg [1:0] owner_bind_epoch;
  reg [63:0] owner_bind_tval;
  reg fill0_valid;
  reg [1:0] fill0_kind;
  reg [4:0] fill0_token;
  reg [1:0] fill0_epoch;
  reg [63:0] fill0_tval;
  reg terminal_valid;
  reg [1:0] terminal_kind;
  reg [4:0] terminal_token;
  reg [1:0] terminal_epoch;
  reg [63:0] terminal_tval;
  reg terminal1_valid;
  reg release_valid;
  wire req_valid;
  wire [63:0] req_fault_tval;
  wire release_ready;
  wire release_fire;
  wire [31:0] owner_release_mask;
  wire [2:0] count;

  OooStoreQueue dut (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(1'b0),
    .flush_all_i(1'b0),
    .flush_rob_head_i(4'b0),
    .flush_boundary_rob_i(4'b0),
    .rob_head_valid_i(1'b1),
    .rob_head_idx_i(4'd3),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_rob_idx_i(4'd3),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_rob_idx_i(4'd4),
    .owner_bind_valid_i(owner_bind_valid),
    .owner_bind_rob_idx_i(owner_bind_rob),
    .owner_bind_kind_i(owner_bind_kind),
    .owner_bind_token_i(owner_bind_token),
    .owner_bind_mmu_epoch_i(owner_bind_epoch),
    .owner_bind_fault_tval_i(owner_bind_tval),
    .fill0_valid_i(fill0_valid),
    .fill0_rob_idx_i(4'd3),
    .fill0_owner_kind_i(fill0_kind),
    .fill0_owner_token_i(fill0_token),
    .fill0_mmu_epoch_i(fill0_epoch),
    .fill0_fault_tval_i(fill0_tval),
    .fill0_vaddr_i(64'h1000),
    .fill0_paddr_i(64'h8000_1000),
    .fill0_attr_valid_i(1'b1),
    .fill0_class_i(`OOO_MEM_CLASS_CACHED),
    .fill0_cacheable_i(1'b1),
    .fill0_data_i(64'h55aa),
    .fill0_strb_i(8'hff),
    .fill1_valid_i(1'b0),
    .fill1_rob_idx_i(4'b0),
    .fill1_owner_kind_i(2'b01),
    .fill1_owner_token_i(5'b0),
    .fill1_mmu_epoch_i(2'b0),
    .fill1_fault_tval_i(64'b0),
    .fill1_vaddr_i(64'b0),
    .fill1_paddr_i(64'b0),
    .fill1_attr_valid_i(1'b0),
    .fill1_class_i(`OOO_MEM_CLASS_RSVD),
    .fill1_cacheable_i(1'b0),
    .fill1_data_i(64'b0),
    .fill1_strb_i(8'b0),
    .terminal_valid_i(terminal_valid),
    .terminal_rob_idx_i(4'd3),
    .terminal_owner_kind_i(terminal_kind),
    .terminal_owner_token_i(terminal_token),
    .terminal_mmu_epoch_i(terminal_epoch),
    .terminal_fault_tval_i(terminal_tval),
    .terminal1_valid_i(terminal1_valid),
    .terminal1_rob_idx_i(4'd3),
    .terminal1_owner_kind_i(2'b01),
    .terminal1_owner_token_i(5'd3),
    .terminal1_mmu_epoch_i(2'b11),
    .terminal1_fault_tval_i(64'h1000),
    .release_valid_i(release_valid),
    .release_rob_idx_i(4'd3),
    .release_ready_o(release_ready),
    .release_fire_o(release_fire),
    .req_valid_o(req_valid),
    .req_fault_tval_o(req_fault_tval),
    .req_fire_i(1'b0),
    .owner_release_mask_o(owner_release_mask),
    .count_o(count)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    owner_bind_valid = 1'b0;
    owner_bind_rob = 4'd3;
    owner_bind_kind = 2'b01;
    owner_bind_token = 5'd3;
    owner_bind_epoch = 2'b11;
    owner_bind_tval = 64'h1000;
    fill0_valid = 1'b0;
    fill0_kind = 2'b01;
    fill0_token = 5'd3;
    fill0_epoch = 2'b11;
    fill0_tval = 64'h1000;
    terminal_valid = 1'b0;
    terminal_kind = 2'b01;
    terminal_token = 5'd3;
    terminal_epoch = 2'b11;
    terminal_tval = 64'h1000;
    terminal1_valid = 1'b0;
    release_valid = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    alloc0_valid = 1'b1;
    alloc1_valid = (CASE_ID == 11);
    @(posedge clk);
    @(negedge clk);
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;

    if (CASE_ID == 10) begin
      owner_bind_kind = 2'b11;
      owner_bind_valid = 1'b1;
      @(posedge clk);
    end else begin
      owner_bind_valid = 1'b1;
      @(posedge clk);
      @(negedge clk);
      owner_bind_valid = 1'b0;

      if (CASE_ID >= 1 && CASE_ID <= 4) begin
        if (CASE_ID == 1) fill0_kind = 2'b00;
        if (CASE_ID == 2) fill0_token = 5'd2;
        if (CASE_ID == 3) fill0_epoch = 2'b10;
        if (CASE_ID == 4) fill0_tval = 64'h1001;
        fill0_valid = 1'b1;
        @(posedge clk);
        #1;
        if (CASE_ID <= 3) begin
          if (req_valid) begin
            $display("[S2-G1-SQ-NEG][FAIL] wrong identity fill mutated state case=%0d", CASE_ID);
            $fatal(1);
          end
        end else begin
          if (!req_valid || req_fault_tval != 64'h1000) begin
            $display("[S2-G1-SQ-NEG][FAIL] tval echo blocked fill or replaced capture");
            $fatal(1);
          end
        end
      end else if (CASE_ID >= 5 && CASE_ID <= 8) begin
        if (CASE_ID == 5) terminal_kind = 2'b00;
        if (CASE_ID == 6) terminal_token = 5'd2;
        if (CASE_ID == 7) terminal_epoch = 2'b10;
        if (CASE_ID == 8) terminal_tval = 64'h1001;
        terminal_valid = 1'b1;
        #1;
        if (CASE_ID <= 7) begin
          // release_valid intentionally remains low: this is a pure readiness
          // observation, so the assert run reaches exactly the owner mismatch.
          if (release_ready) begin
            $display("[S2-G1-SQ-NEG][FAIL] wrong identity terminal authorized release case=%0d", CASE_ID);
            $fatal(1);
          end
        end else if (!release_ready) begin
          $display("[S2-G1-SQ-NEG][FAIL] tval-only drift blocked exact terminal");
          $fatal(1);
        end
        @(posedge clk);
        if (CASE_ID == 8) begin
          @(negedge clk);
          terminal_valid = 1'b0;
          release_valid = 1'b1;
          #1;
          if (!release_ready || !release_fire || owner_release_mask != 32'h0000_0008) begin
            $display("[S2-G1-SQ-NEG][FAIL] tval-only terminal lost bound token release");
            $fatal(1);
          end
          @(posedge clk);
          #1;
          if (count != 3'd0) begin
            $display("[S2-G1-SQ-NEG][FAIL] tval-only terminal did not release entry");
            $fatal(1);
          end
        end
      end else if (CASE_ID == 9) begin
        owner_bind_valid = 1'b1;
        @(posedge clk);
      end else if (CASE_ID == 11) begin
        owner_bind_valid = 1'b1;
        owner_bind_rob = 4'd4;
        owner_bind_token = 5'd3;
        @(posedge clk);
      end else begin
        terminal_valid = 1'b1;
        terminal1_valid = 1'b1;
        @(posedge clk);
      end
    end

    #1;
    if ((CASE_ID == 4) || (CASE_ID == 8))
      $display("[S2-G1-SQ-TVAL][PASS] captured provenance accepted case=%0d count=%0d", CASE_ID, count);
    else
      $display("[S2-G1-SQ-NEG][PASS] identity fail-closed case=%0d count=%0d", CASE_ID, count);
    $finish;
  end
endmodule
