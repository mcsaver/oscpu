`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_system_sequencer;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;
  localparam [PRODUCER_ID_W-1:0] PID_A = 32'h0000_0035;
  localparam [PRODUCER_ID_W-1:0] PID_B = 32'h0000_002a;

  reg clk;
  reg rst;
  reg clear;
  reg clear_dispatched;
  reg dispatch_fire;
  reg producer_death;
  reg [PRODUCER_ID_W-1:0] dispatch_producer_id;
  reg capture_irq;
  reg [`XLEN-1:0] capture_irq_pc;
  reg [`TRAP_CAUSE_W-1:0] capture_irq_cause;
  reg capture_head0;
  reg capture_head0_csr;
  reg capture_head0_ecall;
  reg capture_head0_mret;
  reg capture_head0_wfi;
  reg capture_head0_sfence;
  reg capture_head0_fencei;
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
  reg capture_lane1_fencei;
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
  wire fencei;
  wire fence;
  wire irq;
  wire [`XLEN-1:0] pc;
  wire [`INST_W-1:0] inst;
  wire [`XLEN-1:0] next_pc;
  wire [`XLEN-1:0] csr_rdata;
  wire [`TRAP_CAUSE_W-1:0] irq_cause;
  wire producer_valid;
  wire [PRODUCER_ID_W-1:0] producer_id;

  integer errors;
  integer lane_idx;
  integer kind_idx;

  OooPendingSystemSequencer #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .refresh_rdata_i(1'b0),
    .refresh_rdata_value_i({`XLEN{1'b0}}),
    .dispatch_fire_i(dispatch_fire),
    .producer_death_i(producer_death),
    .dispatch_producer_id_i(dispatch_producer_id),
    .capture_irq_i(capture_irq),
    .capture_irq_pc_i(capture_irq_pc),
    .capture_irq_cause_i(capture_irq_cause),
    .capture_head0_i(capture_head0),
    .capture_head0_csr_i(capture_head0_csr),
    .capture_head0_ecall_i(capture_head0_ecall),
    .capture_head0_mret_i(capture_head0_mret),
    .capture_head0_wfi_i(capture_head0_wfi),
    .capture_head0_sfence_i(capture_head0_sfence),
    .capture_head0_fencei_i(capture_head0_fencei),
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
    .capture_lane1_fencei_i(capture_lane1_fencei),
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
    .fencei_o(fencei),
    .fence_o(fence),
    .irq_o(irq),
    .pc_o(pc),
    .inst_o(inst),
    .next_pc_o(next_pc),
    .csr_rdata_o(csr_rdata),
    .irq_cause_o(irq_cause),
    .producer_valid_o(producer_valid),
    .producer_id_o(producer_id)
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

  task automatic tb_check_cause;
    input [255:0] name;
    input [`TRAP_CAUSE_W-1:0] actual;
    input [`TRAP_CAUSE_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%0h expected=0x%0h",
                 name, actual, expected);
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
      producer_death = 1'b0;
      dispatch_producer_id = {PRODUCER_ID_W{1'b0}};
      capture_irq = 1'b0;
      capture_irq_pc = 64'h0000_0000_8000_1000;
      capture_irq_cause = 5'd7;
      capture_head0 = 1'b0;
      capture_head0_csr = 1'b0;
      capture_head0_ecall = 1'b0;
      capture_head0_mret = 1'b0;
      capture_head0_wfi = 1'b0;
      capture_head0_sfence = 1'b0;
      capture_head0_fencei = 1'b0;
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
      capture_lane1_fencei = 1'b0;
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
      tb_check1({name, " fencei"}, fencei, 1'b0);
      tb_check1({name, " fence"}, fence, 1'b0);
      tb_check1({name, " irq"}, irq, 1'b0);
      tb_check1({name, " producer valid"}, producer_valid, 1'b0);
    end
  endtask

  localparam [3:0] TEST_KIND_CSR = 4'd1;
  localparam [3:0] TEST_KIND_ECALL = 4'd2;
  localparam [3:0] TEST_KIND_XRET = 4'd3;
  localparam [3:0] TEST_KIND_WFI = 4'd4;
  localparam [3:0] TEST_KIND_SFENCE = 4'd5;
  localparam [3:0] TEST_KIND_FENCEI = 4'd6;
  localparam [3:0] TEST_KIND_FENCE = 4'd7;
  integer kind_matrix_cases;

  task automatic capture_kind_case;
    input integer lane;
    input [3:0] kind;
    reg [`INST_W-1:0] selected_inst;
    begin
      clear_inputs();
      case (kind)
        TEST_KIND_CSR: begin
          selected_inst = 32'h3050_9073;
          if (lane == 0)
            capture_head0_csr = 1'b1;
          else
            capture_lane1_csr = 1'b1;
        end
        TEST_KIND_ECALL: begin
          selected_inst = 32'h0000_0073;
          if (lane == 0)
            capture_head0_ecall = 1'b1;
          else
            capture_lane1_ecall = 1'b1;
        end
        TEST_KIND_XRET: begin
          selected_inst = 32'h3020_0073;
          if (lane == 0)
            capture_head0_mret = 1'b1;
          else
            capture_lane1_mret = 1'b1;
        end
        TEST_KIND_WFI: begin
          selected_inst = 32'h1050_0073;
          if (lane == 0)
            capture_head0_wfi = 1'b1;
          else
            capture_lane1_wfi = 1'b1;
        end
        TEST_KIND_SFENCE: begin
          selected_inst = 32'h1200_0073;
          if (lane == 0)
            capture_head0_sfence = 1'b1;
          else
            capture_lane1_sfence = 1'b1;
        end
        TEST_KIND_FENCEI: begin
          selected_inst = 32'h0000_100f;
          if (lane == 0)
            capture_head0_fencei = 1'b1;
          else
            capture_lane1_fencei = 1'b1;
        end
        default: begin
          selected_inst = 32'h0ff0_000f;
        end
      endcase
      if (lane == 0) begin
        capture_head0 = 1'b1;
        capture_head0_inst = selected_inst;
      end else begin
        capture_lane1 = 1'b1;
        capture_lane1_inst = selected_inst;
      end
      tick();
      tb_check1("matrix valid", valid, 1'b1);
      tb_check1("matrix csr", csr, kind == TEST_KIND_CSR);
      tb_check1("matrix ecall", ecall, kind == TEST_KIND_ECALL);
      tb_check1("matrix xret", mret, kind == TEST_KIND_XRET);
      tb_check1("matrix wfi", wfi, kind == TEST_KIND_WFI);
      tb_check1("matrix sfence", sfence, kind == TEST_KIND_SFENCE);
      tb_check1("matrix fencei", fencei, kind == TEST_KIND_FENCEI);
      tb_check1("matrix fence", fence, kind == TEST_KIND_FENCE);
      tb_check1("matrix irq clear", irq, 1'b0);
      tb_check1("matrix pre-ROB lease clear", producer_valid, 1'b0);

      clear_inputs();
      tick();
      tb_check1("matrix hold valid", valid, 1'b1);
      tb_check_inst("matrix hold instruction", inst, selected_inst);
      tb_check1("matrix hold csr", csr, kind == TEST_KIND_CSR);
      tb_check1("matrix hold ecall", ecall, kind == TEST_KIND_ECALL);
      tb_check1("matrix hold xret", mret, kind == TEST_KIND_XRET);
      tb_check1("matrix hold wfi", wfi, kind == TEST_KIND_WFI);
      tb_check1("matrix hold sfence", sfence, kind == TEST_KIND_SFENCE);
      tb_check1("matrix hold fencei", fencei, kind == TEST_KIND_FENCEI);
      tb_check1("matrix hold fence", fence, kind == TEST_KIND_FENCE);

      clear = 1'b1;
      tick();
      expect_idle("matrix clear");
      kind_matrix_cases = kind_matrix_cases + 1;
    end
  endtask

  initial begin
    errors = 0;
    kind_matrix_cases = 0;
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
    capture_irq_cause = 5'd11;
    tick();
    tb_check1("irq valid", valid, 1'b1);
    tb_check1("irq dispatched", dispatched, 1'b0);
    tb_check1("irq flag", irq, 1'b1);
    tb_check1("irq csr clear", csr, 1'b0);
    tb_check64("irq pc", pc, 64'h0000_0000_8000_1234);
    tb_check_inst("irq inst zero", inst, {`INST_W{1'b0}});
    tb_check64("irq next pc", next_pc, 64'h0000_0000_8000_1234);
    tb_check64("irq csr rdata zero", csr_rdata, {`XLEN{1'b0}});
    tb_check_cause("irq cause code", irq_cause, 5'd11);

    tb_check1("irq has no producer lease", producer_valid, 1'b0);

    clear_inputs();
    clear = 1'b1;
    tick();
    expect_idle("clear");
    tb_check64("clear keeps ignored payload", pc, 64'h0000_0000_8000_1234);

    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_csr = 1'b1;
    tick();
    tb_check1("head0 valid", valid, 1'b1);
    tb_check1("head0 csr", csr, 1'b1);
    tb_check1("head0 mret clear", mret, 1'b0);
    tb_check1("head0 sfence clear", sfence, 1'b0);
    tb_check1("head0 fencei clear", fencei, 1'b0);
    tb_check1("head0 irq clear", irq, 1'b0);
    tb_check64("head0 pc", pc, 64'h0000_0000_8000_2000);
    tb_check_inst("head0 inst", inst, 32'h3050_9073);
    tb_check64("head0 csr rdata", csr_rdata, 64'h1111_2222_3333_4444);
    tb_check1("head0 pre-ROB has no lease", producer_valid, 1'b0);

    clear_inputs();
    dispatch_fire = 1'b1;
    dispatch_producer_id = PID_A;
    tick();
    tb_check1("head0 dispatched", dispatched, 1'b1);
    tb_check1("head0 lease born", producer_valid, 1'b1);
    if (producer_id !== PID_A) begin
      $display("FAIL head0 lease pid actual=%0h expected=%0h", producer_id, PID_A);
      errors = errors + 1;
    end

    clear_inputs();
    tick();
    tb_check1("head0 lease holds", producer_valid, 1'b1);
    tb_check64("head0 live payload holds", pc, 64'h0000_0000_8000_2000);

    clear_inputs();
    producer_death = 1'b1;
    clear = 1'b1;
    tick();
    expect_idle("head0 exact producer death wins ordinary clear cross");

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_csr = 1'b1;
    tick();
    tb_check1("lane1 valid", valid, 1'b1);
    tb_check1("lane1 csr", csr, 1'b1);
    tb_check1("lane1 ecall clear", ecall, 1'b0);
    tb_check1("lane1 wfi clear", wfi, 1'b0);
    tb_check1("lane1 fencei clear", fencei, 1'b0);
    tb_check1("lane1 dispatched reset", dispatched, 1'b0);
    tb_check1("lane1 pre-ROB has no lease", producer_valid, 1'b0);
    tb_check64("lane1 pc", pc, 64'h0000_0000_8000_3002);
    tb_check_inst("lane1 inst", inst, 32'h1020_0073);
    tb_check64("lane1 next pc", next_pc, 64'h0000_0000_8000_3006);

    clear_inputs();
    dispatch_fire = 1'b1;
    dispatch_producer_id = PID_B;
    tick();
    tb_check1("lane1 dispatched", dispatched, 1'b1);
    tb_check1("lane1 lease born", producer_valid, 1'b1);
    if (producer_id !== PID_B) begin
      $display("FAIL lane1 lease pid actual=%0h expected=%0h", producer_id, PID_B);
      errors = errors + 1;
    end

    // Backend-global flush is the only non-commit death witness.  The parent
    // drives this reset from the exact same core_local_flush used by the ROB.
    clear_inputs();
    rst = 1'b1;
    tick();
    expect_idle("backend flush reset kills lease");
    rst = 1'b0;
    tick();

    // Non-CSR pending controls remain pre-ROB and never manufacture a PID.
    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_ecall = 1'b1;
    tick();
    tb_check1("ecall pending valid", valid, 1'b1);
    tb_check1("ecall flag", ecall, 1'b1);
    tb_check1("ecall has no producer lease", producer_valid, 1'b0);

    clear_inputs();
    clear = 1'b1;
    tick();
    expect_idle("ordinary clear remains pre-ROB only");

    // Every non-IRQ kind must classify identically from lane0 and lane1,
    // remain stable while held, and clear without manufacturing a ProducerId.
    for (lane_idx = 0; lane_idx < 2; lane_idx = lane_idx + 1) begin
      for (kind_idx = TEST_KIND_CSR;
           kind_idx <= TEST_KIND_FENCE;
           kind_idx = kind_idx + 1) begin
        capture_kind_case(lane_idx, kind_idx);
      end
    end
    tb_check64("canonical kind matrix case count",
               kind_matrix_cases, 64'd14);

    // Empty capture priority is preserved without permitting recapture of a
    // non-empty owner.
    clear_inputs();
    capture_irq = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_csr = 1'b1;
    tick();
    tb_check1("empty irq priority flag", irq, 1'b1);
    tb_check1("empty irq priority csr clear", csr, 1'b0);
    tb_check1("empty irq priority no lease", producer_valid, 1'b0);

    clear_inputs();
    clear = 1'b1;
    tick();
    expect_idle("priority capture ordinary clear");

    if (errors == 0) begin
      $display("[V9W-SERIAL-KIND-MATRIX] kinds=8 lane-cases=14 onehot=1 hold=1 clear=1 lease-scope=csr-only PASS");
      $display("PASS tb_ooo_pending_system_sequencer");
      $finish;
    end
    $fatal(1, "FAIL tb_ooo_pending_system_sequencer errors=%0d", errors);
  end
endmodule
