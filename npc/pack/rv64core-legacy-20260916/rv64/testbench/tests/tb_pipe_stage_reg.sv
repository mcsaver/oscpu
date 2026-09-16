`include "define.v"

// PipeStageReg 原语 focused TB：装载/反压冻结/背靠背/flush/kill/满反压。
// OOO_ASSERT 下 PSR-HOLD/PSR-FLUSH-EMPTY 断言全程使能。
module tb_pipe_stage_reg;
  `include "tb_common.svh"

  localparam WIDTH = 40;

  reg clk;
  reg rst;
  reg flush;
  reg kill;
  reg up_valid;
  wire up_ready;
  reg [WIDTH-1:0] up_payload;
  wire down_valid;
  reg down_ready;
  wire [WIDTH-1:0] down_payload;

  PipeStageReg #(
    .WIDTH(WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_i(kill),
    .up_valid_i(up_valid),
    .up_ready_o(up_ready),
    .up_payload_i(up_payload),
    .down_valid_o(down_valid),
    .down_ready_i(down_ready),
    .down_payload_o(down_payload)
  );

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      kill = 1'b0;
      up_valid = 1'b0;
      up_payload = {WIDTH{1'b0}};
      down_ready = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs;
    `TB_TICK(clk)
    `TB_TICK(clk)
    rst = 1'b0;
    #1;

    // 1. 复位后空且可装载
    tb_check1("reset empty down_valid", down_valid, 1'b0);
    tb_check1("reset empty up_ready", up_ready, 1'b1);

    // 2. 装载一拍后 down_valid=1 且 payload 正确
    up_valid = 1'b1;
    up_payload = 40'hA5_1234_5678;
    `TB_TICK(clk)
    up_valid = 1'b0;
    #1;
    tb_check1("loaded down_valid", down_valid, 1'b1);
    tb_check32("loaded payload lo", down_payload[31:0], 32'h1234_5678);
    tb_check32("loaded payload hi", {24'b0, down_payload[39:32]}, 32'h0000_00A5);

    // 3. 反压冻结：down_ready=0 多拍，valid/payload 保持，up_ready=0(满)
    down_ready = 1'b0;
    tb_check1("full up_ready low", up_ready, 1'b0);
    `TB_TICK(clk)
    `TB_TICK(clk)
    #1;
    tb_check1("stall hold valid", down_valid, 1'b1);
    tb_check32("stall hold payload", down_payload[31:0], 32'h1234_5678);

    // 4. 下游消费：down_ready=1 一拍后空
    down_ready = 1'b1;
    #1;
    tb_check1("drain ready passthrough", up_ready, 1'b1);
    `TB_TICK(clk)
    down_ready = 1'b0;
    #1;
    tb_check1("drained empty", down_valid, 1'b0);

    // 5. 背靠背流：占用 + down_ready=1 + 新 up 同拍 fire，payload 换新
    up_valid = 1'b1;
    up_payload = 40'h11_1111_1111;
    `TB_TICK(clk)
    up_payload = 40'h22_2222_2222;
    down_ready = 1'b1;
    #1;
    tb_check1("b2b up_ready", up_ready, 1'b1);
    `TB_TICK(clk)
    up_valid = 1'b0;
    down_ready = 1'b0;
    #1;
    tb_check1("b2b still valid", down_valid, 1'b1);
    tb_check32("b2b new payload", down_payload[31:0], 32'h2222_2222);

    // 6. flush：占用态 flush 一拍后空(PSR-FLUSH-EMPTY 断言同步核查)
    flush = 1'b1;
    `TB_TICK(clk)
    flush = 1'b0;
    #1;
    tb_check1("flush empties", down_valid, 1'b0);

    // 7. flush 压过同拍装载：up fire 与 flush 同拍 → 仍空
    up_valid = 1'b1;
    up_payload = 40'h33_3333_3333;
    flush = 1'b1;
    `TB_TICK(clk)
    up_valid = 1'b0;
    flush = 1'b0;
    #1;
    tb_check1("flush beats same-cycle load", down_valid, 1'b0);

    // 8. kill：装载后 kill 一拍清空
    up_valid = 1'b1;
    up_payload = 40'h44_4444_4444;
    `TB_TICK(clk)
    up_valid = 1'b0;
    #1;
    tb_check1("pre-kill valid", down_valid, 1'b1);
    kill = 1'b1;
    `TB_TICK(clk)
    kill = 1'b0;
    #1;
    tb_check1("kill empties", down_valid, 1'b0);

    `TB_TICK(clk)
    tb_finish("tb_pipe_stage_reg");
  end
endmodule
