`timescale 1ns/1ps
`default_nettype none

module tb_ifu;

    localparam logic [31:0] RESET_PC = 32'h8000_0000;

    logic        clk_i;
    logic        rst_i;
    logic        redirect_valid_i;
    logic [31:0] redirect_pc_i;
    wire         redirect_ready_o;
    logic        inst_req_ready_i;
    wire         inst_req_valid_o;
    wire  [31:0] inst_req_pc_o;
    logic        inst_rsp_valid_i;
    logic [31:0] inst_rsp_inst_i;
    logic        inst_rsp_error_i;
    wire         inst_rsp_ready_o;
    logic        if_id_ready_i;
    wire         if_id_valid_o;
    wire  [31:0] if_id_pc_o;
    wire  [31:0] if_id_inst_o;
    wire         if_id_error_o;
    wire   [2:0] status;

    ifu #(
        .RESET_PC (RESET_PC),
        .EPOCH_W  (2)
    ) dut (
        .clk_i,
        .rst_i,
        .redirect_valid_i,
        .redirect_pc_i,
        .redirect_ready_o,
        .inst_req_ready_i,
        .inst_req_valid_o,
        .inst_req_pc_o,
        .inst_rsp_valid_i,
        .inst_rsp_inst_i,
        .inst_rsp_error_i,
        .inst_rsp_ready_o,
        .if_id_ready_i,
        .if_id_valid_o,
        .if_id_pc_o,
        .if_id_inst_o,
        .if_id_error_o,
        .status
    );

    always #5 clk_i = ~clk_i;

    task automatic check_true(
        input logic  condition,
        input string message
    );
        begin
            if (condition !== 1'b1) begin
                $display("TB_IFU_FAIL t=%0t: %s", $time, message);
                $fatal(1);
            end
        end
    endtask

    task automatic reset_dut;
        begin
            rst_i               = 1'b1;
            redirect_valid_i    = 1'b0;
            redirect_pc_i       = 32'd0;
            inst_req_ready_i    = 1'b0;
            inst_rsp_valid_i    = 1'b0;
            inst_rsp_inst_i     = 32'd0;
            inst_rsp_error_i    = 1'b0;
            if_id_ready_i       = 1'b0;

            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(posedge clk_i);
            #1;

            check_true(redirect_ready_o === 1'b1,
                       "redirect must be accepted after reset");
            check_true(inst_req_valid_o === 1'b1,
                       "request stage must prime after reset");
            check_true(inst_req_pc_o === RESET_PC,
                       "first request PC must equal RESET_PC");
            check_true(dut.outstanding_q === 5'd0,
                       "reset must clear outstanding count");
            check_true(if_id_valid_o === 1'b0,
                       "reset must clear IF/ID valid");
        end
    endtask

    task automatic test_redirect_while_request_stalled;
        logic [31:0] held_pc;
        logic [1:0]  held_epoch;
        localparam logic [31:0] REDIRECT_PC = 32'h8000_0100;
        begin
            $display("[TB] redirect while AXI request is stalled");
            reset_dut();

            held_pc    = inst_req_pc_o;
            held_epoch = dut.req_stage_epoch_q;

            // 调试 status 必须实时变化，但 AXI request payload 不得组合变化。
            inst_req_ready_i = 1'b1;
            #1;
            check_true(status[2] === 1'b1,
                       "status.req_fire must observe ready immediately");
            check_true(inst_req_pc_o === held_pc && inst_req_valid_o === 1'b1,
                       "AXI ready must not change request payload combinationally");
            inst_req_ready_i = 1'b0;
            #1;
            check_true(status[2] === 1'b0,
                       "status.req_fire must clear immediately");

            @(negedge clk_i);
            redirect_pc_i    = REDIRECT_PC;
            redirect_valid_i = 1'b1;
            #1;
            check_true(inst_req_pc_o === held_pc,
                       "redirect must not overwrite a stalled AXI request");

            @(posedge clk_i);
            #1;
            check_true(dut.active_epoch_q === 2'd1,
                       "redirect must advance active epoch");
            check_true(inst_req_valid_o === 1'b1
                       && inst_req_pc_o === held_pc
                       && dut.req_stage_epoch_q === held_epoch,
                       "stalled request PC/epoch/valid must remain stable");
            check_true(dut.next_pc_q === REDIRECT_PC,
                       "next_pc must remember pending redirect target");

            // 旧 request 完成握手；沿后才能展示新路径 request。
            @(negedge clk_i);
            redirect_valid_i = 1'b0;
            inst_req_ready_i = 1'b1;
            #1;
            check_true(status[2] === 1'b1 && inst_req_pc_o === held_pc,
                       "old stalled request must complete exactly once");
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd1,
                       "old request must enter owner FIFO");
            check_true(inst_req_valid_o === 1'b1
                       && inst_req_pc_o === REDIRECT_PC
                       && dut.req_stage_epoch_q === 2'd1,
                       "request stage must switch to redirect target/new epoch");

            // 切换 inst_rsp_valid 只能改变 status，不能反向改变 rsp_ready。
            @(negedge clk_i);
            inst_req_ready_i = 1'b0;
            inst_rsp_valid_i = 1'b0;
            #1;
            check_true(inst_rsp_ready_o === 1'b1,
                       "stale owner must be drainable");
            inst_rsp_inst_i  = 32'hdead_0000;
            inst_rsp_valid_i = 1'b1;
            #1;
            check_true(inst_rsp_ready_o === 1'b1 && status[1] === 1'b1,
                       "rsp_valid must not feed back into rsp_ready");
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd0,
                       "stale response must release request credit");
            check_true(dut.rsp_count_q === 5'd0 && if_id_valid_o === 1'b0,
                       "stale response must not enter delivery FIFO");

            // 发送 redirect target，并验证 response 到空 FIFO 时没有组合 fall-through。
            @(negedge clk_i);
            inst_rsp_valid_i = 1'b0;
            inst_req_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd1,
                       "redirect target request must be accepted");

            @(negedge clk_i);
            inst_req_ready_i = 1'b0;
            if_id_ready_i    = 1'b1;
            inst_rsp_inst_i  = 32'h1234_5678;
            inst_rsp_error_i = 1'b1;
            inst_rsp_valid_i = 1'b1;
            #1;
            check_true(if_id_valid_o === 1'b0 && status[0] === 1'b0,
                       "registered IF/ID valid must forbid response fall-through");
            @(posedge clk_i);
            #1;
            check_true(if_id_valid_o === 1'b1,
                       "live response must assert IF/ID valid after the edge");
            check_true(if_id_pc_o === REDIRECT_PC
                       && if_id_inst_o === 32'h1234_5678
                       && if_id_error_o === 1'b1,
                       "live response tuple must preserve PC/inst/error");

            // IF/ID 反压时，完整 payload 保持。
            @(negedge clk_i);
            inst_rsp_valid_i = 1'b0;
            if_id_ready_i    = 1'b0;
            inst_rsp_inst_i  = 32'haaaa_5555;
            repeat (2) begin
                @(posedge clk_i);
                #1;
                check_true(if_id_valid_o === 1'b1
                           && if_id_pc_o === REDIRECT_PC
                           && if_id_inst_o === 32'h1234_5678
                           && if_id_error_o === 1'b1,
                           "IF/ID payload must remain stable under backpressure");
            end

            @(negedge clk_i);
            if_id_ready_i = 1'b1;
            #1;
            check_true(status[0] === 1'b1,
                       "status.id_fire must observe ID ready immediately");
            @(posedge clk_i);
            #1;
            check_true(if_id_valid_o === 1'b0,
                       "ID handshake must consume the only delivery entry");
        end
    endtask

    task automatic test_double_redirect;
        localparam logic [31:0] PREDICT_PC = 32'h8000_0200;
        localparam logic [31:0] CORRECT_PC = 32'h8000_0300;
        begin
            $display("[TB] ID prediction followed by EX correction");
            reset_dut();

            @(negedge clk_i);
            redirect_valid_i = 1'b1;
            redirect_pc_i    = PREDICT_PC;
            @(posedge clk_i);
            #1;
            check_true(dut.active_epoch_q === 2'd1
                       && dut.next_pc_q === PREDICT_PC,
                       "first redirect must create epoch 1");

            // ready 始终为 1，下一周期可接受一个新的 correction transaction。
            @(negedge clk_i);
            redirect_pc_i = CORRECT_PC;
            @(posedge clk_i);
            #1;
            check_true(dut.active_epoch_q === 2'd2
                       && dut.next_pc_q === CORRECT_PC,
                       "second redirect must replace pending prediction with correction");
            check_true(inst_req_pc_o === RESET_PC
                       && dut.req_stage_epoch_q === 2'd0,
                       "twice-redirected stalled request must still remain unchanged");

            @(negedge clk_i);
            redirect_valid_i = 1'b0;
            inst_req_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            check_true(inst_req_pc_o === CORRECT_PC
                       && dut.req_stage_epoch_q === 2'd2,
                       "after old request handoff, only final correction target may issue");
        end
    endtask

    task automatic test_redirect_with_rsp_and_id_fire;
        localparam logic [31:0] REDIRECT_PC = 32'h8000_0400;
        begin
            $display("[TB] redirect simultaneous with rsp_fire and id_fire");
            reset_dut();

            // 请求 P0。
            @(negedge clk_i);
            inst_req_ready_i = 1'b1;
            @(posedge clk_i);
            #1;

            // 同拍请求 P1、返回 P0，使 delivery FIFO 中已有一项、owner 中仍有 P1。
            @(negedge clk_i);
            inst_rsp_valid_i = 1'b1;
            inst_rsp_inst_i  = 32'h0000_0001;
            if_id_ready_i    = 1'b0;
            @(posedge clk_i);
            #1;
            check_true(if_id_valid_o === 1'b1 && if_id_pc_o === RESET_PC,
                       "setup must buffer first live response");
            check_true(dut.outstanding_q === 5'd1,
                       "setup must retain one owner for simultaneous response");

            @(negedge clk_i);
            inst_req_ready_i = 1'b0;
            inst_rsp_inst_i  = 32'h0000_0002;
            if_id_ready_i    = 1'b1;
            redirect_valid_i = 1'b1;
            redirect_pc_i    = REDIRECT_PC;
            #1;
            check_true(status[1:0] === 2'b11,
                       "redirect cycle must expose raw rsp_fire/id_fire in status");
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd0,
                       "redirect-cycle response must still pop owner");
            check_true(dut.rsp_count_q === 5'd0 && if_id_valid_o === 1'b0,
                       "redirect must dominate delivery FIFO enqueue/pop updates");
            check_true(inst_req_pc_o === (RESET_PC + 32'd8),
                       "stalled request stage must not be overwritten by redirect");
            check_true(dut.next_pc_q === REDIRECT_PC,
                       "redirect target must remain pending behind stalled request");
        end
    endtask

    task automatic test_request_capacity_and_full_throughput;
        integer i;
        logic [31:0] expected_pc;
        begin
            $display("[TB] physical full re-prime and reservation-full throughput");
            reset_dut();
            inst_req_ready_i = 1'b1;
            if_id_ready_i    = 1'b1;

            // 无 response，连续接受 16 个请求，达到 O=16/S=0 的物理满状态。
            for (i = 0; i < 16; i = i + 1) begin
                @(negedge clk_i);
                expected_pc = RESET_PC + (i * 4);
                #1;
                check_true(inst_req_valid_o === 1'b1
                           && inst_req_pc_o === expected_pc,
                           $sformatf("accepted request %0d must preserve sequential PC", i));
                @(posedge clk_i);
                #1;
            end
            check_true(dut.outstanding_q === 5'd16
                       && inst_req_valid_o === 1'b0,
                       "16 accepted requests must produce physical-full O=16/S=0");

            // 物理满时，本响应周期请求输出仍为 0；沿后才重新装入 stage。
            @(negedge clk_i);
            inst_rsp_valid_i = 1'b1;
            inst_rsp_inst_i  = 32'h1000_0000;
            #1;
            check_true(inst_req_valid_o === 1'b0
                       && inst_rsp_ready_o === 1'b1
                       && status[2:1] === 2'b01,
                       "physical full must have one registered re-prime transition");
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd15
                       && inst_req_valid_o === 1'b1
                       && inst_req_pc_o === (RESET_PC + 32'd64),
                       "returned credit must re-prime request stage on the edge");
            check_true(if_id_valid_o === 1'b1 && if_id_pc_o === RESET_PC,
                       "first response must enter registered delivery FIFO");

            // O=15/S=1，req/rsp/id 每周期同时 fire，持续跨越环形指针回绕。
            for (i = 0; i < 20; i = i + 1) begin
                @(negedge clk_i);
                inst_rsp_valid_i = 1'b1;
                inst_rsp_inst_i  = 32'h1000_0001 + i;
                expected_pc      = RESET_PC + ((16 + i) * 4);
                #1;
                check_true(inst_req_valid_o === 1'b1
                           && inst_req_pc_o === expected_pc,
                           $sformatf("steady request %0d must be sequential", i));
                check_true(if_id_valid_o === 1'b1
                           && if_id_pc_o === (RESET_PC + (i * 4)),
                           $sformatf("steady delivery %0d must remain ordered", i));
                check_true(status === 3'b111,
                           "reservation-full steady state must fire req/rsp/id together");
                @(posedge clk_i);
                #1;
                check_true(dut.outstanding_q === 5'd15
                           && dut.req_stage_valid_q === 1'b1
                           && dut.rsp_count_q === 5'd1,
                           "reservation-full state must remain O=15/S=1/R=1");
            end
        end
    endtask

    task automatic test_full_delivery_fifo_redirect_drain;
        integer i;
        localparam logic [31:0] REDIRECT_PC = 32'h8000_0800;
        begin
            $display("[TB] redirect drains response while delivery FIFO is full");
            reset_dut();
            inst_req_ready_i = 1'b1;
            if_id_ready_i    = 1'b0;

            // Seed 一个 outstanding owner。
            @(negedge clk_i);
            @(posedge clk_i);
            #1;

            // 每拍 req+rsp，ID 停顿，使 delivery FIFO 填满；始终保留一个 owner。
            for (i = 0; i < 16; i = i + 1) begin
                @(negedge clk_i);
                inst_rsp_valid_i = 1'b1;
                inst_rsp_inst_i  = 32'h2000_0000 + i;
                #1;
                check_true(inst_rsp_ready_o === 1'b1,
                           $sformatf("delivery FIFO fill response %0d must be accepted", i));
                @(posedge clk_i);
                #1;
                check_true(dut.rsp_count_q === (i + 1),
                           $sformatf("delivery FIFO count must reach %0d", i + 1));
                check_true(dut.outstanding_q === 5'd1,
                           "one owner must remain while req/rsp run together");
            end
            check_true(dut.rsp_count_q === 5'd16,
                       "delivery FIFO must reach physical full");

            // FIFO 已满仍必须接受 redirect 同拍的旧 response，并清空 delivery FIFO。
            @(negedge clk_i);
            inst_req_ready_i = 1'b0;
            redirect_valid_i = 1'b1;
            redirect_pc_i    = REDIRECT_PC;
            inst_rsp_valid_i = 1'b1;
            inst_rsp_inst_i  = 32'h2fff_ffff;
            #1;
            check_true(inst_rsp_ready_o === 1'b1 && status[1] === 1'b1,
                       "redirect/drop path must bypass a full delivery FIFO");
            @(posedge clk_i);
            #1;
            check_true(dut.outstanding_q === 5'd0,
                       "full-FIFO redirect response must release its owner");
            check_true(dut.rsp_count_q === 5'd0 && if_id_valid_o === 1'b0,
                       "redirect must flush all buffered wrong-path responses");
            check_true(inst_req_valid_o === 1'b1
                       && inst_req_pc_o === (RESET_PC + 32'd68)
                       && dut.req_stage_epoch_q === 2'd0,
                       "old request stage must remain stable while request ready is low");
            check_true(dut.next_pc_q === REDIRECT_PC
                       && dut.active_epoch_q === 2'd1,
                       "new redirect target/epoch must be recorded behind old stage");
        end
    endtask

    initial begin
        clk_i             = 1'b0;
        rst_i             = 1'b1;
        redirect_valid_i  = 1'b0;
        redirect_pc_i     = 32'd0;
        inst_req_ready_i  = 1'b0;
        inst_rsp_valid_i  = 1'b0;
        inst_rsp_inst_i   = 32'd0;
        inst_rsp_error_i  = 1'b0;
        if_id_ready_i     = 1'b0;

        test_redirect_while_request_stalled();
        test_double_redirect();
        test_redirect_with_rsp_and_id_fire();
        test_request_capacity_and_full_throughput();
        test_full_delivery_fifo_redirect_drain();

        $display("TB_IFU_PASS");
        $finish;
    end

endmodule

`default_nettype wire
