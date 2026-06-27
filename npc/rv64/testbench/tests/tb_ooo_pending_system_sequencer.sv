`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_system_sequencer;
  reg clk;
  reg rst;
  reg clear;
  reg clear_dispatched;
  reg dispatch_fire;
  reg capture_irq;
  reg [`XLEN-1:0] capture_irq_pc;
  reg [`TRAP_CAUSE_W-1:0] capture_irq_cause;
  reg capture_head0;
  reg capture_head0_csr;
  reg capture_head0_ecall;
  reg capture_head0_mret;
  reg capture_head0_wfi;
  reg capture_head0_sfence;
  reg [`XLEN-1:0] capture_head0_pc;
  reg [`INST_W-1:0] capture_head0_inst;
  reg [`XLEN-1:0] capture_head0_next_pc;
  reg [`XLEN-1:0] capture_head0_csr_rdata;
  reg capture_lane1;
  reg capture_lane1_csr;
  reg capture_lane1_ecall;
  reg capture_lane1_mret;
  reg capture_lane1_wfi;
  reg capture_lane1_sfence;
  reg [`XLEN-1:0] capture_lane1_pc;
  reg [`INST_W-1:0] capture_lane1_inst;
  reg [`XLEN-1:0] capture_lane1_next_pc;
  reg [`XLEN-1:0] capture_lane1_csr_rdata;

  wire valid;
  wire dispatched;
  wire csr;
  wire ecall;
  wire mret;
  wire wfi;
  wire sfence;
  wire irq;
  wire [`XLEN-1:0] pc;
  wire [`INST_W-1:0] inst;
  wire [`XLEN-1:0] next_pc;
  wire [`XLEN-1:0] csr_rdata;
  wire [`TRAP_CAUSE_W-1:0] irq_cause;

  integer errors;

  OooPendingSystemSequencer dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .dispatch_fire_i(dispatch_fire),
    .capture_irq_i(capture_irq),
    .capture_irq_pc_i(capture_irq_pc),
    .capture_irq_cause_i(capture_irq_cause),
    .capture_head0_i(capture_head0),
    .capture_head0_csr_i(capture_head0_csr),
    .capture_head0_ecall_i(capture_head0_ecall),
    .capture_head0_mret_i(capture_head0_mret),
    .capture_head0_wfi_i(capture_head0_wfi),
    .capture_head0_sfence_i(capture_head0_sfence),
    .capture_head0_pc_i(capture_head0_pc),
    .capture_head0_inst_i(capture_head0_inst),
    .capture_head0_next_pc_i(capture_head0_next_pc),
    .capture_head0_csr_rdata_i(capture_head0_csr_rdata),
    .capture_lane1_i(capture_lane1),
    .capture_lane1_csr_i(capture_lane1_csr),
    .capture_lane1_ecall_i(capture_lane1_ecall),
    .capture_lane1_mret_i(capture_lane1_mret),
    .capture_lane1_wfi_i(capture_lane1_wfi),
    .capture_lane1_sfence_i(capture_lane1_sfence),
    .capture_lane1_pc_i(capture_lane1_pc),
    .capture_lane1_inst_i(capture_lane1_inst),
    .capture_lane1_next_pc_i(capture_lane1_next_pc),
    .capture_lane1_csr_rdata_i(capture_lane1_csr_rdata),
    .valid_o(valid),
    .dispatched_o(dispatched),
    .csr_o(csr),
    .ecall_o(ecall),
    .mret_o(mret),
    .wfi_o(wfi),
    .sfence_o(sfence),
    .irq_o(irq),
    .pc_o(pc),
    .inst_o(inst),
    .next_pc_o(next_pc),
    .csr_rdata_o(csr_rdata),
    .irq_cause_o(irq_cause)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tb_check1;
    input [255:0] name;
    input actual;
    input expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0b expected=%0b", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check64;
    input [255:0] name;
    input [`XLEN-1:0] actual;
    input [`XLEN-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%016h expected=0x%016h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check_inst;
    input [255:0] name;
    input [`INST_W-1:0] actual;
    input [`INST_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%08h expected=0x%08h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      clear = 1'b0;
      clear_dispatched = 1'b0;
      dispatch_fire = 1'b0;
      capture_irq = 1'b0;
      capture_irq_pc = 64'h0000_0000_8000_1000;
      capture_irq_cause = 64'h8000_0000_0000_0007;
      capture_head0 = 1'b0;
      capture_head0_csr = 1'b0;
      capture_head0_ecall = 1'b0;
      capture_head0_mret = 1'b0;
      capture_head0_wfi = 1'b0;
      capture_head0_sfence = 1'b0;
      capture_head0_pc = 64'h0000_0000_8000_2000;
      capture_head0_inst = 32'h3050_9073;
      capture_head0_next_pc = 64'h0000_0000_8000_2004;
      capture_head0_csr_rdata = 64'h1111_2222_3333_4444;
      capture_lane1 = 1'b0;
      capture_lane1_csr = 1'b0;
      capture_lane1_ecall = 1'b0;
      capture_lane1_mret = 1'b0;
      capture_lane1_wfi = 1'b0;
      capture_lane1_sfence = 1'b0;
      capture_lane1_pc = 64'h0000_0000_8000_3002;
      capture_lane1_inst = 32'h1020_0073;
      capture_lane1_next_pc = 64'h0000_0000_8000_3006;
      capture_lane1_csr_rdata = 64'h5555_6666_7777_8888;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic expect_idle;
    input [255:0] name;
    begin
      tb_check1({name, " valid"}, valid, 1'b0);
      tb_check1({name, " dispatched"}, dispatched, 1'b0);
      tb_check1({name, " csr"}, csr, 1'b0);
      tb_check1({name, " ecall"}, ecall, 1'b0);
      tb_check1({name, " mret"}, mret, 1'b0);
      tb_check1({name, " wfi"}, wfi, 1'b0);
      tb_check1({name, " sfence"}, sfence, 1'b0);
      tb_check1({name, " irq"}, irq, 1'b0);
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_idle("reset");
    tb_check64("reset pc", pc, {`XLEN{1'b0}});
    tb_check_inst("reset inst", inst, {`INST_W{1'b0}});

    clear_inputs();
    capture_irq = 1'b1;
    capture_irq_pc = 64'h0000_0000_8000_1234;
    capture_irq_cause = 64'h8000_0000_0000_000b;
    tick();
    tb_check1("irq valid", valid, 1'b1);
    tb_check1("irq dispatched", dispatched, 1'b0);
    tb_check1("irq flag", irq, 1'b1);
    tb_check1("irq csr clear", csr, 1'b0);
    tb_check64("irq pc", pc, 64'h0000_0000_8000_1234);
    tb_check_inst("irq inst zero", inst, {`INST_W{1'b0}});
    tb_check64("irq next pc", next_pc, 64'h0000_0000_8000_1234);
    tb_check64("irq csr rdata zero", csr_rdata, {`XLEN{1'b0}});
    tb_check64("irq cause", irq_cause, 64'h8000_0000_0000_000b);

    clear_inputs();
    dispatch_fire = 1'b1;
    clear_dispatched = 1'b1;
    tick();
    tb_check1("dispatch wins over clear dispatched", dispatched, 1'b1);
    tb_check64("dispatch preserves pc", pc, 64'h0000_0000_8000_1234);

    clear_inputs();
    clear_dispatched = 1'b1;
    tick();
    tb_check1("clear dispatched only", valid, 1'b1);
    tb_check1("clear dispatched bit", dispatched, 1'b0);

    clear_inputs();
    clear = 1'b1;
    tick();
    expect_idle("clear");
    tb_check64("clear keeps ignored payload", pc, 64'h0000_0000_8000_1234);

    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_csr = 1'b1;
    capture_head0_mret = 1'b1;
    capture_head0_sfence = 1'b1;
    tick();
    tb_check1("head0 valid", valid, 1'b1);
    tb_check1("head0 csr", csr, 1'b1);
    tb_check1("head0 mret", mret, 1'b1);
    tb_check1("head0 sfence", sfence, 1'b1);
    tb_check1("head0 irq clear", irq, 1'b0);
    tb_check64("head0 pc", pc, 64'h0000_0000_8000_2000);
    tb_check_inst("head0 inst", inst, 32'h3050_9073);
    tb_check64("head0 csr rdata", csr_rdata, 64'h1111_2222_3333_4444);

    clear_inputs();
    capture_irq = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_csr = 1'b1;
    tick();
    tb_check1("irq priority valid", valid, 1'b1);
    tb_check1("irq priority flag", irq, 1'b1);
    tb_check1("irq priority csr", csr, 1'b0);
    tb_check64("irq priority pc", pc, 64'h0000_0000_8000_1000);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_csr = 1'b1;
    capture_lane1_ecall = 1'b1;
    capture_lane1_wfi = 1'b1;
    tick();
    tb_check1("lane1 valid", valid, 1'b1);
    tb_check1("lane1 csr", csr, 1'b1);
    tb_check1("lane1 ecall", ecall, 1'b1);
    tb_check1("lane1 wfi", wfi, 1'b1);
    tb_check1("lane1 dispatched reset", dispatched, 1'b0);
    tb_check64("lane1 pc", pc, 64'h0000_0000_8000_3002);
    tb_check_inst("lane1 inst", inst, 32'h1020_0073);
    tb_check64("lane1 next pc", next_pc, 64'h0000_0000_8000_3006);

    clear_inputs();
    dispatch_fire = 1'b1;
    tick();
    tb_check1("lane1 dispatched", dispatched, 1'b1);
    clear_inputs();
    capture_head0 = 1'b1;
    dispatch_fire = 1'b1;
    tick();
    tb_check1("capture clears dispatched", dispatched, 1'b0);
    tb_check64("capture over dispatch pc", pc, 64'h0000_0000_8000_2000);

    clear_inputs();
    clear = 1'b1;
    capture_head0 = 1'b1;
    tick();
    expect_idle("clear wins over capture");

    if (errors == 0) begin
      $display("PASS tb_ooo_pending_system_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_pending_system_sequencer errors=%0d", errors);
    $finish(1);
  end
endmodule
