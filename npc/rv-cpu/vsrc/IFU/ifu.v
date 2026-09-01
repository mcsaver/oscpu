`timescale 1ns/1ps
`default_nettype none

// 设计约束：
// 1. AXI 输入不能通过组合逻辑直接影响 AXI 输出（status 是只读调试例外）。
// 2. 有可用 credit 时，请求通道可以每周期发送一个请求。
// 3. reservation 满载稳态（15 个 outstanding + 1 个 request stage）不产生气泡。
// 4. 请求与响应严格同序，PC 不覆盖、不乱序。
// 5. redirect 后，已被 AXI 接受的旧请求继续 drain，但旧响应不会交付给 ID。

module ifu #(
    parameter [31:0] RESET_PC = 32'h8000_0000,
    // 当前简单五级流水允许一次 ID 预测和一次 EX 修正重叠，因此使用 2-bit epoch。
    // 若未来允许更多 redirect 源连续触发，必须在 epoch 回绕前增加复用屏障。
    parameter integer EPOCH_W = 2
) (
    input  wire        clk_i,
    input  wire        rst_i,

    // 顶层仲裁后的最终 redirect。valid/ready 每次握手表示一次新的重定向事件。
    input  wire        redirect_valid_i,
    input  wire [31:0] redirect_pc_i,
    output wire        redirect_ready_o,

    // IFU -> 指令存储器：请求通道
    input  wire        inst_req_ready_i,
    output wire        inst_req_valid_o,
    output wire [31:0] inst_req_pc_o,

    // 指令存储器 -> IFU：响应通道
    input  wire        inst_rsp_valid_i,
    input  wire [31:0] inst_rsp_inst_i,
    input  wire        inst_rsp_error_i,
    output wire        inst_rsp_ready_o,

    // IFU -> ID：流水线交接
    input  wire        if_id_ready_i,
    output reg         if_id_valid_o,
    output wire [31:0] if_id_pc_o,
    output wire [31:0] if_id_inst_o,
    output wire        if_id_error_o,

    // debug-only：实时观察本周期三个边界上的物理握手。
    output wire [2:0]  status
);

    localparam integer FIFO_DEPTH = 16;

    //--------------------------------------------------------------------------
    // 边界握手事件
    //--------------------------------------------------------------------------
    wire req_fire;
    wire rsp_fire;
    wire id_fire;
    wire redirect_fire_w;

    assign req_fire         = inst_req_valid_o && inst_req_ready_i;
    assign rsp_fire         = inst_rsp_valid_i && inst_rsp_ready_o;
    assign id_fire          = if_id_valid_o && if_id_ready_i;
    assign redirect_ready_o = !rst_i;
    assign redirect_fire_w  = redirect_valid_i && redirect_ready_o;

    assign status = {req_fire, rsp_fire, id_fire};

    //--------------------------------------------------------------------------
    // Request output stage：所有 AXI 请求输出只来自寄存器
    //--------------------------------------------------------------------------
    reg                     req_stage_valid_q;
    reg [31:0]              req_stage_pc_q;
    reg [EPOCH_W-1:0]       req_stage_epoch_q;
    reg [31:0]              next_pc_q;
    reg [EPOCH_W-1:0]       active_epoch_q;

    wire [EPOCH_W-1:0] redirect_epoch_w;

    assign inst_req_valid_o = req_stage_valid_q;
    assign inst_req_pc_o    = req_stage_pc_q;
    assign redirect_epoch_w = active_epoch_q + 1'b1;

    //--------------------------------------------------------------------------
    // Request owner FIFO：保存已被 AXI 接受、尚未返回的 {PC, epoch}
    //--------------------------------------------------------------------------
    reg [31:0]        req_pc_fifo [0:FIFO_DEPTH-1];
    reg [EPOCH_W-1:0] req_epoch_fifo [0:FIFO_DEPTH-1];
    reg [3:0]         req_wr_ptr_q;
    reg [3:0]         req_rd_ptr_q;
    reg [4:0]         outstanding_q;
    reg [31:0]        req_head_pc_q;
    reg [EPOCH_W-1:0] req_head_epoch_q;

    wire [3:0] req_next_rd_ptr_w;
    wire       req_fifo_empty_w;
    wire [5:0] req_reserved_w;
    wire       req_stage_can_load_w;
    wire       req_credit_available_w;

    assign req_next_rd_ptr_w    = req_rd_ptr_q + 4'd1;
    assign req_fifo_empty_w     = (outstanding_q == 5'd0);
    assign req_reserved_w       = {1'b0, outstanding_q}
                                + (req_stage_valid_q ? 6'd1 : 6'd0);
    assign req_stage_can_load_w = !req_stage_valid_q || req_fire;

    // rsp_fire 归还的 credit 可以在同一时钟沿用于装载下一条 request stage。
    // 它只影响寄存器 D 端，不形成 AXI input -> AXI output 的同拍组合路径。
    assign req_credit_available_w = (req_reserved_w < 6'd16) || rsp_fire;

    // redirect 最高优先级，但不能覆盖一个 valid && !ready 的 AXI 请求。
    // 此时 next_pc_q 保存 redirect target；旧 request 完成握手后再装入新路径请求。
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_stage_valid_q <= 1'b0;
            req_stage_pc_q    <= 32'd0;
            req_stage_epoch_q <= {EPOCH_W{1'b0}};
            next_pc_q         <= RESET_PC;
            active_epoch_q    <= {EPOCH_W{1'b0}};
        end
        else if (redirect_fire_w) begin
            active_epoch_q <= redirect_epoch_w;
            next_pc_q      <= redirect_pc_i;

            if (req_stage_can_load_w) begin
                if (req_credit_available_w) begin
                    req_stage_valid_q <= 1'b1;
                    req_stage_pc_q    <= redirect_pc_i;
                    req_stage_epoch_q <= redirect_epoch_w;
                    next_pc_q         <= redirect_pc_i + 32'd4;
                end
                else begin
                    req_stage_valid_q <= 1'b0;
                end
            end
        end
        else if (req_stage_can_load_w) begin
            if (req_credit_available_w) begin
                req_stage_valid_q <= 1'b1;
                req_stage_pc_q    <= next_pc_q;
                req_stage_epoch_q <= active_epoch_q;
                next_pc_q         <= next_pc_q + 32'd4;
            end
            else begin
                req_stage_valid_q <= 1'b0;
            end
        end
    end

    // req_fire 发生时，stage 中的 PC 和 epoch 原子进入 owner FIFO。
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_wr_ptr_q <= 4'd0;
        end
        else if (req_fire) begin
            req_pc_fifo[req_wr_ptr_q]    <= req_stage_pc_q;
            req_epoch_fifo[req_wr_ptr_q] <= req_stage_epoch_q;
            req_wr_ptr_q                 <= req_wr_ptr_q + 4'd1;
        end
    end

    // outstanding 只追踪真实 AXI request/response 握手，redirect 不改变 ownership。
    always @(posedge clk_i) begin
        if (rst_i) begin
            outstanding_q <= 5'd0;
        end
        else begin
            case ({req_fire, rsp_fire})
                2'b10: outstanding_q <= outstanding_q + 5'd1;
                2'b01: outstanding_q <= outstanding_q - 5'd1;
                default: outstanding_q <= outstanding_q;
            endcase
        end
    end

    // 缓存 owner FIFO 队头，保证 PC 与 epoch 始终同步推进。
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_rd_ptr_q     <= 4'd0;
            req_head_pc_q    <= 32'd0;
            req_head_epoch_q <= {EPOCH_W{1'b0}};
        end
        else if (rsp_fire) begin
            req_rd_ptr_q <= req_rd_ptr_q + 4'd1;

            if (outstanding_q > 5'd1) begin
                req_head_pc_q    <= req_pc_fifo[req_next_rd_ptr_w];
                req_head_epoch_q <= req_epoch_fifo[req_next_rd_ptr_w];
            end
            else if (req_fire) begin
                // pop 最后一项并同拍 push 新项，新请求直接成为队头。
                req_head_pc_q    <= req_stage_pc_q;
                req_head_epoch_q <= req_stage_epoch_q;
            end
        end
        else if (req_fire && req_fifo_empty_w) begin
            req_head_pc_q    <= req_stage_pc_q;
            req_head_epoch_q <= req_stage_epoch_q;
        end
    end

    //--------------------------------------------------------------------------
    // Response delivery FIFO：只保存当前 epoch、尚未被 ID 接受的响应
    //--------------------------------------------------------------------------
    reg [31:0] rsp_pc_fifo [0:FIFO_DEPTH-1];
    reg [31:0] rsp_inst_fifo [0:FIFO_DEPTH-1];
    reg        rsp_error_fifo [0:FIFO_DEPTH-1];
    reg [3:0]  rsp_wr_ptr_q;
    reg [3:0]  rsp_rd_ptr_q;
    reg [4:0]  rsp_count_q;

    wire rsp_fifo_full_w;
    wire req_head_stale_w;
    wire rsp_drop_w;
    wire rsp_enqueue_w;

    assign rsp_fifo_full_w  = (rsp_count_q == 5'd16);
    assign req_head_stale_w = (req_head_epoch_q != active_epoch_q);

    // redirect 同拍返回的响应属于 redirect 之前的取指路径，也必须丢弃。
    assign rsp_drop_w    = redirect_fire_w || req_head_stale_w;
    assign rsp_enqueue_w = rsp_fire && !rsp_drop_w;

    // stale 响应不占 delivery FIFO，即使 FIFO 已满也必须继续接收并 drain。
    // 该组合逻辑不依赖 inst_rsp_valid_i，因此不存在 AXI input -> AXI output 路径。
    assign inst_rsp_ready_o = !req_fifo_empty_w
                            && (rsp_drop_w || !rsp_fifo_full_w || id_fire);

    assign if_id_pc_o    = rsp_pc_fifo[rsp_rd_ptr_q];
    assign if_id_inst_o  = rsp_inst_fifo[rsp_rd_ptr_q];
    assign if_id_error_o = rsp_error_fifo[rsp_rd_ptr_q];

    // redirect 只清空待交付给 ID 的年轻指令；owner FIFO 必须继续等待旧 AXI 响应。
    always @(posedge clk_i) begin
        if (rst_i || redirect_fire_w) begin
            rsp_wr_ptr_q  <= 4'd0;
            rsp_rd_ptr_q  <= 4'd0;
            rsp_count_q   <= 5'd0;
            if_id_valid_o <= 1'b0;
        end
        else begin
            if (rsp_enqueue_w) begin
                rsp_pc_fifo[rsp_wr_ptr_q]    <= req_head_pc_q;
                rsp_inst_fifo[rsp_wr_ptr_q]  <= inst_rsp_inst_i;
                rsp_error_fifo[rsp_wr_ptr_q] <= inst_rsp_error_i;
                rsp_wr_ptr_q                 <= rsp_wr_ptr_q + 4'd1;
            end

            if (id_fire) begin
                rsp_rd_ptr_q <= rsp_rd_ptr_q + 4'd1;
            end

            case ({rsp_enqueue_w, id_fire})
                2'b10: begin
                    rsp_count_q   <= rsp_count_q + 5'd1;
                    if_id_valid_o <= 1'b1;
                end
                2'b01: begin
                    rsp_count_q   <= rsp_count_q - 5'd1;
                    if_id_valid_o <= (rsp_count_q > 5'd1);
                end
                2'b11: begin
                    rsp_count_q   <= rsp_count_q;
                    if_id_valid_o <= 1'b1;
                end
                default: begin
                    rsp_count_q   <= rsp_count_q;
                    if_id_valid_o <= if_id_valid_o;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    // 局部结构不变量；系统级顺序性由 testbench scoreboard 验证。
    always @(posedge clk_i) begin
        if (!rst_i) begin
            if (req_reserved_w > 6'd16)
                $fatal(1, "IFU request credit overflow");
            if (outstanding_q > 5'd16)
                $fatal(1, "IFU outstanding overflow");
            if (rsp_count_q > 5'd16)
                $fatal(1, "IFU response FIFO overflow");
            if (if_id_valid_o != (rsp_count_q != 5'd0))
                $fatal(1, "IFU if_id_valid/count mismatch");
        end
    end
`endif

endmodule

`default_nettype wire
