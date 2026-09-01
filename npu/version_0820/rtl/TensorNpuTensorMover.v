`timescale 1ns/1ps
`default_nettype none

// TensorNpuTensorMover — Phase A CPY/CONT/CONCAT0 raw-byte mover。
//
// 电路拓扑对应 TENSOR_MOVER_RTL_CONTRACT.md：
//   * resident descriptor 寄存器只在 IDLE 接受 start 时写入；busy start 被忽略；
//   * 128-bit preflight 组合网一次冻结 shape/span/aligned-beat/window/overlap；
//   * 单共享 8B GMEM 端口按 READ_REQ/WAIT -> WRITE_REQ/WAIT 串行复用；
//   * request payload 先写寄存器再进入 REQ，因而 valid&&!ready 时逐 bit 保持；
//   * reset > 非法状态/内部域错误 > command timeout > stall timeout > 正常推进；
//   * 已接受事务超时只进入 GMEM_DRAIN，冻结命令结果并消费唯一 matching response。
//
// 最长组合路径预计是 4D shape/span 乘加后接 region/window/overlap 比较；运行期
// 地址生成是四个 stride 乘加。没有 function 隐藏 FSM、仲裁、握手或状态更新。
module TensorNpuTensorMover #(
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        start_i,
    output wire        ready_o,
    output wire        busy_o,
    input  wire [1:0]  opcode_i,

    input  wire [63:0] gmem_floor_i,
    input  wire [63:0] gmem_limit_i,

    input  wire [63:0] src0_region_base_i,
    input  wire [63:0] src0_region_size_i,
    input  wire [63:0] src0_view_off_i,
    input  wire [31:0] src0_ne0_i,
    input  wire [31:0] src0_ne1_i,
    input  wire [31:0] src0_ne2_i,
    input  wire [31:0] src0_ne3_i,
    input  wire [63:0] src0_nb0_i,
    input  wire [63:0] src0_nb1_i,
    input  wire [63:0] src0_nb2_i,
    input  wire [63:0] src0_nb3_i,

    input  wire [63:0] src1_region_base_i,
    input  wire [63:0] src1_region_size_i,
    input  wire [63:0] src1_view_off_i,
    input  wire [31:0] src1_ne0_i,
    input  wire [31:0] src1_ne1_i,
    input  wire [31:0] src1_ne2_i,
    input  wire [31:0] src1_ne3_i,
    input  wire [63:0] src1_nb0_i,
    input  wire [63:0] src1_nb1_i,
    input  wire [63:0] src1_nb2_i,
    input  wire [63:0] src1_nb3_i,

    input  wire [63:0] dst_region_base_i,
    input  wire [63:0] dst_region_size_i,
    input  wire [63:0] dst_view_off_i,

    output wire        gmem_req_valid_o,
    input  wire        gmem_req_ready_i,
    output wire        gmem_req_write_o,
    output wire [63:0] gmem_req_addr_o,
    output wire [63:0] gmem_req_wdata_o,
    output wire [7:0]  gmem_req_wstrb_o,
    input  wire        gmem_rsp_valid_i,
    output wire        gmem_rsp_ready_o,
    input  wire [63:0] gmem_rsp_rdata_i,
    input  wire        gmem_rsp_error_i,

    output wire        done_o,
    output wire        error_o,
    output wire [4:0]  error_code_o,
    output wire [63:0] elements_done_o,
    output wire [63:0] bytes_moved_o,
    output wire [63:0] gmem_read_beats_o,
    output wire [63:0] gmem_write_beats_o,
    output wire [63:0] writes_accepted_o,
    output wire [63:0] active_cycles_o
);

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (STALL_TIMEOUT_CYCLES - 1);
    localparam [31:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 1) ? 32'd0
                                      : (COMMAND_TIMEOUT_CYCLES - 1);

    localparam [3:0] ST_IDLE         = 4'd0;
    localparam [3:0] ST_PREFLIGHT    = 4'd1;
    localparam [3:0] ST_ELEMENT_PREP = 4'd2;
    localparam [3:0] ST_READ_REQ     = 4'd3;
    localparam [3:0] ST_READ_WAIT    = 4'd4;
    localparam [3:0] ST_WRITE_REQ    = 4'd5;
    localparam [3:0] ST_WRITE_WAIT   = 4'd6;
    localparam [3:0] ST_GMEM_DRAIN   = 4'd7;
    localparam [3:0] ST_DONE         = 4'd8;
    localparam [3:0] ST_ERROR        = 4'd9;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_HEADER          = 5'd1;
    localparam [4:0] ERR_SHAPE           = 5'd2;
    localparam [4:0] ERR_STRIDE_ALIGN    = 5'd3;
    localparam [4:0] ERR_SOURCE_BOUNDS   = 5'd4;
    localparam [4:0] ERR_DEST_BOUNDS     = 5'd5;
    localparam [4:0] ERR_OVERLAP         = 5'd6;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd10;

    reg [3:0] state_q;

    // Resident command descriptor。所有字段只在 start_i&&ready_o 时采样。
    reg [1:0]  opcode_q;
    reg [63:0] gmem_floor_q;
    reg [63:0] gmem_limit_q;
    reg [63:0] src0_region_base_q;
    reg [63:0] src0_region_size_q;
    reg [63:0] src0_view_off_q;
    reg [31:0] src0_ne0_q;
    reg [31:0] src0_ne1_q;
    reg [31:0] src0_ne2_q;
    reg [31:0] src0_ne3_q;
    reg [63:0] src0_nb0_q;
    reg [63:0] src0_nb1_q;
    reg [63:0] src0_nb2_q;
    reg [63:0] src0_nb3_q;
    reg [63:0] src1_region_base_q;
    reg [63:0] src1_region_size_q;
    reg [63:0] src1_view_off_q;
    reg [31:0] src1_ne0_q;
    reg [31:0] src1_ne1_q;
    reg [31:0] src1_ne2_q;
    reg [31:0] src1_ne3_q;
    reg [63:0] src1_nb0_q;
    reg [63:0] src1_nb1_q;
    reg [63:0] src1_nb2_q;
    reg [63:0] src1_nb3_q;
    reg [63:0] dst_region_base_q;
    reg [63:0] dst_region_size_q;
    reg [63:0] dst_view_off_q;

    // Preflight 后固定的运行 shape 与 element 类型。
    reg [2:0]  element_bytes_q;
    reg [31:0] dst_ne0_q;
    reg [31:0] dst_ne1_q;
    reg [31:0] dst_ne2_q;
    reg [31:0] dst_ne3_q;
    reg [63:0] total_elements_q;

    // logical flat index 与 i0-fast 坐标只在成功 write response 后推进。
    reg [63:0] flat_index_q;
    reg [31:0] coord_i0_q;
    reg [31:0] coord_i1_q;
    reg [31:0] coord_i2_q;
    reg [31:0] coord_i3_q;

    // 单共享 GMEM request payload。REQ state 内这些寄存器不更新。
    reg [63:0] gmem_req_addr_q;
    reg [63:0] write_data_q;
    reg [7:0]  write_strb_q;
    reg [2:0]  source_lane_q;
    reg [63:0] destination_addr_q;
    reg        outstanding_q;

    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;
    reg [4:0]  drain_error_code_q;
    reg [4:0]  error_code_q;
    reg [63:0] elements_done_q;
    reg [63:0] bytes_moved_q;
    reg [63:0] gmem_read_beats_q;
    reg [63:0] gmem_write_beats_q;
    reg [63:0] writes_accepted_q;
    reg [63:0] active_cycles_q;

    wire start_fire_w;
    wire request_state_w;
    wire response_state_w;
    wire command_timeout_hit_w;
    wire stall_timeout_hit_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign start_fire_w = start_i && ready_o;

    assign request_state_w = (state_q == ST_READ_REQ)
                           || (state_q == ST_WRITE_REQ);
    assign response_state_w = (state_q == ST_READ_WAIT)
                            || (state_q == ST_WRITE_WAIT)
                            || (state_q == ST_GMEM_DRAIN);
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);
    assign stall_timeout_hit_w =
        (stall_cycles_q >= STALL_TIMEOUT_LAST);

    // Watchdog terminal 当拍撤销 valid，阻止 late ready 接受失去完成资格的请求。
    assign gmem_req_valid_o = !rst_i && request_state_w
                            && !command_timeout_hit_w
                            && !stall_timeout_hit_w;
    assign gmem_req_write_o = (state_q == ST_WRITE_REQ);
    assign gmem_req_addr_o  = gmem_req_addr_q;
    assign gmem_req_wdata_o = (state_q == ST_WRITE_REQ)
                            ? write_data_q : 64'b0;
    assign gmem_req_wstrb_o = (state_q == ST_WRITE_REQ)
                            ? write_strb_q : 8'b0;
    // outstanding_q 令 response credit 只对已接受的 matching transaction 生效。
    assign gmem_rsp_ready_o = !rst_i && response_state_w && outstanding_q;
    assign gmem_req_fire_w  = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w  = gmem_rsp_valid_i && gmem_rsp_ready_o;

    assign error_code_o         = error_code_q;
    assign elements_done_o      = elements_done_q;
    assign bytes_moved_o        = bytes_moved_q;
    assign gmem_read_beats_o    = gmem_read_beats_q;
    assign gmem_write_beats_o   = gmem_write_beats_q;
    assign writes_accepted_o    = writes_accepted_q;
    assign active_cycles_o      = active_cycles_q;

    // ------------------------------------------------------------------
    // 全命令 128-bit preflight 组合网。固定优先级不依赖后续 FSM 分支顺序。
    // ------------------------------------------------------------------
    reg         opcode_valid_w;
    reg [2:0]   element_bytes_w;
    reg         empty_cpy_w;
    reg [127:0] src0_count_w;
    reg [127:0] concat_ne0_sum_w;
    reg [127:0] total_elements_w;
    reg [127:0] total_bytes_w;
    reg [127:0] src0_region_end_w;
    reg [127:0] src1_region_end_w;
    reg [127:0] dst_region_end_w;
    reg [127:0] src0_last_rel_w;
    reg [127:0] src1_last_rel_w;
    reg [127:0] src0_abs_start_w;
    reg [127:0] src0_abs_end_w;
    reg [127:0] src1_abs_start_w;
    reg [127:0] src1_abs_end_w;
    reg [127:0] dst_rel_end_w;
    reg [127:0] dst_abs_start_w;
    reg [127:0] dst_abs_end_w;
    reg [127:0] src0_aligned_start_w;
    reg [127:0] src0_aligned_end_w;
    reg [127:0] src1_aligned_start_w;
    reg [127:0] src1_aligned_end_w;
    reg [127:0] dst_aligned_start_w;
    reg [127:0] dst_aligned_end_w;
    reg         header_ok_w;
    reg         shape_ok_w;
    reg         stride_align_ok_w;
    reg         source_bounds_ok_w;
    reg         destination_bounds_ok_w;
    reg         overlap_ok_w;
    reg         src0_stride_ok_w;
    reg         src1_stride_ok_w;
    reg         src0_natural_ok_w;
    reg         src1_natural_ok_w;
    reg         destination_natural_ok_w;
    reg         src0_empty_point_ok_w;
    reg         destination_empty_point_ok_w;
    reg [4:0]   preflight_error_w;

    always @(*) begin
        opcode_valid_w      = 1'b0;
        element_bytes_w     = 3'd0;
        case (opcode_q)
            2'd0: begin
                opcode_valid_w  = 1'b1;
                element_bytes_w = 3'd4;
            end
            2'd1: begin
                opcode_valid_w  = 1'b1;
                element_bytes_w = 3'd4;
            end
            2'd2: begin
                opcode_valid_w  = 1'b1;
                element_bytes_w = 3'd2;
            end
            2'd3: begin
                opcode_valid_w  = 1'b1;
                element_bytes_w = 3'd4;
            end
            default: begin
                opcode_valid_w  = 1'b0;
                element_bytes_w = 3'd0;
            end
        endcase

        empty_cpy_w = (opcode_q == 2'd0)
                    && ((src0_ne0_q == 32'b0)
                        || (src0_ne1_q == 32'b0)
                        || (src0_ne2_q == 32'b0)
                        || (src0_ne3_q == 32'b0));

        src0_count_w = {96'b0, src0_ne0_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne1_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne2_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne3_q};
        concat_ne0_sum_w = {96'b0, src0_ne0_q}
                         + {96'b0, src1_ne0_q};
        if (opcode_q == 2'd3) begin
            total_elements_w = concat_ne0_sum_w;
            total_elements_w = total_elements_w
                             * {96'b0, src0_ne1_q};
            total_elements_w = total_elements_w
                             * {96'b0, src0_ne2_q};
            total_elements_w = total_elements_w
                             * {96'b0, src0_ne3_q};
        end else begin
            total_elements_w = src0_count_w;
        end
        total_bytes_w = total_elements_w * {125'b0, element_bytes_w};

        src0_region_end_w = {64'b0, src0_region_base_q}
                          + {64'b0, src0_region_size_q};
        src1_region_end_w = {64'b0, src1_region_base_q}
                          + {64'b0, src1_region_size_q};
        dst_region_end_w  = {64'b0, dst_region_base_q}
                          + {64'b0, dst_region_size_q};

        src0_last_rel_w   = {64'b0, src0_view_off_q};
        src1_last_rel_w   = {64'b0, src1_view_off_q};
        if (!empty_cpy_w && (total_elements_w != 128'b0)) begin
            src0_last_rel_w = src0_last_rel_w
                            + ({96'b0, (src0_ne0_q - 32'd1)}
                               * {64'b0, src0_nb0_q})
                            + ({96'b0, (src0_ne1_q - 32'd1)}
                               * {64'b0, src0_nb1_q})
                            + ({96'b0, (src0_ne2_q - 32'd1)}
                               * {64'b0, src0_nb2_q})
                            + ({96'b0, (src0_ne3_q - 32'd1)}
                               * {64'b0, src0_nb3_q})
                            + {125'b0, element_bytes_w};
            if (opcode_q == 2'd3) begin
                src1_last_rel_w = src1_last_rel_w
                                + ({96'b0, (src1_ne0_q - 32'd1)}
                                   * {64'b0, src1_nb0_q})
                                + ({96'b0, (src1_ne1_q - 32'd1)}
                                   * {64'b0, src1_nb1_q})
                                + ({96'b0, (src1_ne2_q - 32'd1)}
                                   * {64'b0, src1_nb2_q})
                                + ({96'b0, (src1_ne3_q - 32'd1)}
                                   * {64'b0, src1_nb3_q})
                                + {125'b0, element_bytes_w};
            end
        end

        src0_abs_start_w = {64'b0, src0_region_base_q}
                         + {64'b0, src0_view_off_q};
        src0_abs_end_w   = {64'b0, src0_region_base_q}
                         + src0_last_rel_w;
        src1_abs_start_w = {64'b0, src1_region_base_q}
                         + {64'b0, src1_view_off_q};
        src1_abs_end_w   = {64'b0, src1_region_base_q}
                         + src1_last_rel_w;
        dst_rel_end_w    = {64'b0, dst_view_off_q} + total_bytes_w;
        dst_abs_start_w  = {64'b0, dst_region_base_q}
                         + {64'b0, dst_view_off_q};
        dst_abs_end_w    = {64'b0, dst_region_base_q} + dst_rel_end_w;

        src0_aligned_start_w = src0_abs_start_w;
        src0_aligned_start_w[2:0] = 3'b000;
        src0_aligned_end_w = src0_abs_end_w;
        src1_aligned_start_w = src1_abs_start_w;
        src1_aligned_start_w[2:0] = 3'b000;
        src1_aligned_end_w = src1_abs_end_w;
        dst_aligned_start_w = dst_abs_start_w;
        dst_aligned_start_w[2:0] = 3'b000;
        dst_aligned_end_w = dst_abs_end_w;
        if (!empty_cpy_w && (total_elements_w != 128'b0)) begin
            src0_aligned_end_w = src0_abs_end_w - 128'd1;
            src0_aligned_end_w[2:0] = 3'b000;
            src0_aligned_end_w = src0_aligned_end_w + 128'd8;
            if (opcode_q == 2'd3) begin
                src1_aligned_end_w = src1_abs_end_w - 128'd1;
                src1_aligned_end_w[2:0] = 3'b000;
                src1_aligned_end_w = src1_aligned_end_w + 128'd8;
            end
            dst_aligned_end_w = dst_abs_end_w - 128'd1;
            dst_aligned_end_w[2:0] = 3'b000;
            dst_aligned_end_w = dst_aligned_end_w + 128'd8;
        end

        header_ok_w = opcode_valid_w && (gmem_floor_q < gmem_limit_q);

        shape_ok_w = 1'b0;
        if (empty_cpy_w) begin
            shape_ok_w = 1'b1;
        end else if ((src0_ne0_q != 32'b0)
                && (src0_ne1_q != 32'b0)
                && (src0_ne2_q != 32'b0)
                && (src0_ne3_q != 32'b0)
                && (total_elements_w >= 128'd1)
                && (total_elements_w <= {96'b0, 32'hffff_ffff})) begin
            if (opcode_q == 2'd3) begin
                shape_ok_w = (src1_ne0_q != 32'b0)
                           && (src1_ne1_q != 32'b0)
                           && (src1_ne2_q != 32'b0)
                           && (src1_ne3_q != 32'b0)
                           && (src0_ne1_q == src1_ne1_q)
                           && (src0_ne2_q == src1_ne2_q)
                           && (src0_ne3_q == src1_ne3_q)
                           && (concat_ne0_sum_w[127:32] == 96'b0);
            end else begin
                shape_ok_w = 1'b1;
            end
        end

        src0_stride_ok_w = 1'b0;
        src1_stride_ok_w = 1'b0;
        src0_natural_ok_w = 1'b0;
        src1_natural_ok_w = 1'b0;
        destination_natural_ok_w = 1'b0;
        if (element_bytes_w == 3'd4) begin
            src0_stride_ok_w = (src0_nb0_q != 64'b0)
                             && (src0_nb1_q != 64'b0)
                             && (src0_nb2_q != 64'b0)
                             && (src0_nb3_q != 64'b0)
                             && (src0_nb0_q[1:0] == 2'b0)
                             && (src0_nb1_q[1:0] == 2'b0)
                             && (src0_nb2_q[1:0] == 2'b0)
                             && (src0_nb3_q[1:0] == 2'b0);
            src1_stride_ok_w = (src1_nb0_q != 64'b0)
                             && (src1_nb1_q != 64'b0)
                             && (src1_nb2_q != 64'b0)
                             && (src1_nb3_q != 64'b0)
                             && (src1_nb0_q[1:0] == 2'b0)
                             && (src1_nb1_q[1:0] == 2'b0)
                             && (src1_nb2_q[1:0] == 2'b0)
                             && (src1_nb3_q[1:0] == 2'b0);
            src0_natural_ok_w = (src0_abs_start_w[1:0] == 2'b0);
            src1_natural_ok_w = (src1_abs_start_w[1:0] == 2'b0);
            destination_natural_ok_w =
                (dst_abs_start_w[1:0] == 2'b0);
        end else if (element_bytes_w == 3'd2) begin
            src0_stride_ok_w = (src0_nb0_q != 64'b0)
                             && (src0_nb1_q != 64'b0)
                             && (src0_nb2_q != 64'b0)
                             && (src0_nb3_q != 64'b0)
                             && !src0_nb0_q[0]
                             && !src0_nb1_q[0]
                             && !src0_nb2_q[0]
                             && !src0_nb3_q[0];
            src1_stride_ok_w = (src1_nb0_q != 64'b0)
                             && (src1_nb1_q != 64'b0)
                             && (src1_nb2_q != 64'b0)
                             && (src1_nb3_q != 64'b0)
                             && !src1_nb0_q[0]
                             && !src1_nb1_q[0]
                             && !src1_nb2_q[0]
                             && !src1_nb3_q[0];
            src0_natural_ok_w = !src0_abs_start_w[0];
            src1_natural_ok_w = !src1_abs_start_w[0];
            destination_natural_ok_w = !dst_abs_start_w[0];
        end
        if (empty_cpy_w) begin
            stride_align_ok_w = 1'b1;
        end else begin
            stride_align_ok_w = src0_stride_ok_w
                              && src0_natural_ok_w
                              && destination_natural_ok_w
                              && ((opcode_q != 2'd3)
                                  || (src1_stride_ok_w
                                      && src1_natural_ok_w));
        end

        src0_empty_point_ok_w =
               (src0_view_off_q <= src0_region_size_q)
            && (src0_region_end_w[127:64] == 64'b0)
            && (src0_abs_start_w[127:64] == 64'b0)
            && (src0_abs_start_w[63:0] >= gmem_floor_q)
            && (src0_abs_start_w[63:0] <= gmem_limit_q);
        destination_empty_point_ok_w =
               (dst_view_off_q <= dst_region_size_q)
            && (dst_region_end_w[127:64] == 64'b0)
            && (dst_abs_start_w[127:64] == 64'b0)
            && (dst_abs_start_w[63:0] >= gmem_floor_q)
            && (dst_abs_start_w[63:0] <= gmem_limit_q);

        if (empty_cpy_w) begin
            source_bounds_ok_w      = src0_empty_point_ok_w;
            destination_bounds_ok_w = destination_empty_point_ok_w;
        end else begin
            source_bounds_ok_w =
                   (src0_view_off_q <= src0_region_size_q)
                && (src0_region_end_w[127:64] == 64'b0)
                && (src0_last_rel_w <= {64'b0, src0_region_size_q})
                && (src0_abs_start_w[127:64] == 64'b0)
                && (src0_abs_end_w[127:64] == 64'b0)
                && (src0_aligned_start_w[127:64] == 64'b0)
                && (src0_aligned_end_w[127:64] == 64'b0)
                && (src0_aligned_start_w[63:0] >= src0_region_base_q)
                && (src0_aligned_end_w <= src0_region_end_w)
                && (src0_aligned_start_w[63:0] >= gmem_floor_q)
                && (src0_aligned_end_w[63:0] <= gmem_limit_q);
            if (opcode_q == 2'd3) begin
                source_bounds_ok_w = source_bounds_ok_w
                    && (src1_view_off_q <= src1_region_size_q)
                    && (src1_region_end_w[127:64] == 64'b0)
                    && (src1_last_rel_w <= {64'b0, src1_region_size_q})
                    && (src1_abs_start_w[127:64] == 64'b0)
                    && (src1_abs_end_w[127:64] == 64'b0)
                    && (src1_aligned_start_w[127:64] == 64'b0)
                    && (src1_aligned_end_w[127:64] == 64'b0)
                    && (src1_aligned_start_w[63:0] >= src1_region_base_q)
                    && (src1_aligned_end_w <= src1_region_end_w)
                    && (src1_aligned_start_w[63:0] >= gmem_floor_q)
                    && (src1_aligned_end_w[63:0] <= gmem_limit_q);
            end

            destination_bounds_ok_w =
                   (dst_view_off_q <= dst_region_size_q)
                && (dst_region_end_w[127:64] == 64'b0)
                && (dst_rel_end_w <= {64'b0, dst_region_size_q})
                && (dst_abs_end_w <= dst_region_end_w)
                && (dst_abs_start_w[127:64] == 64'b0)
                && (dst_abs_end_w[127:64] == 64'b0)
                && (dst_aligned_start_w[127:64] == 64'b0)
                && (dst_aligned_end_w[127:64] == 64'b0)
                && (dst_abs_start_w[63:0] >= gmem_floor_q)
                && (dst_abs_end_w[63:0] <= gmem_limit_q)
                && (dst_aligned_start_w[63:0] >= gmem_floor_q)
                && (dst_aligned_end_w[63:0] <= gmem_limit_q);
        end

        overlap_ok_w = 1'b1;
        if (!empty_cpy_w && source_bounds_ok_w
                && destination_bounds_ok_w) begin
            if ((src0_abs_start_w < dst_abs_end_w)
                    && (dst_abs_start_w < src0_abs_end_w)) begin
                overlap_ok_w = 1'b0;
            end
            if ((opcode_q == 2'd3)
                    && (src1_abs_start_w < dst_abs_end_w)
                    && (dst_abs_start_w < src1_abs_end_w)) begin
                overlap_ok_w = 1'b0;
            end
        end

        // 固定错误优先级：HEADER→SHAPE→STRIDE/ALIGN→SOURCE→DEST→OVERLAP。
        if (!header_ok_w)
            preflight_error_w = ERR_HEADER;
        else if (!shape_ok_w)
            preflight_error_w = ERR_SHAPE;
        else if (!stride_align_ok_w)
            preflight_error_w = ERR_STRIDE_ALIGN;
        else if (!source_bounds_ok_w)
            preflight_error_w = ERR_SOURCE_BOUNDS;
        else if (!destination_bounds_ok_w)
            preflight_error_w = ERR_DEST_BOUNDS;
        else if (!overlap_ok_w)
            preflight_error_w = ERR_OVERLAP;
        else
            preflight_error_w = ERR_NONE;
    end

    // ------------------------------------------------------------------
    // 运行期 logical coordinate -> source/destination 地址生成组合网。
    // ------------------------------------------------------------------
    reg [127:0] current_src_addr_w;
    reg [127:0] current_dst_addr_w;
    reg [127:0] selected_i0_w;
    reg         current_addr_valid_w;

    always @(*) begin
        selected_i0_w = {96'b0, coord_i0_q};
        if ((opcode_q == 2'd3) && (coord_i0_q >= src0_ne0_q)) begin
            selected_i0_w = {96'b0, (coord_i0_q - src0_ne0_q)};
            current_src_addr_w = {64'b0, src1_region_base_q}
                               + {64'b0, src1_view_off_q}
                               + (selected_i0_w * {64'b0, src1_nb0_q})
                               + ({96'b0, coord_i1_q}
                                  * {64'b0, src1_nb1_q})
                               + ({96'b0, coord_i2_q}
                                  * {64'b0, src1_nb2_q})
                               + ({96'b0, coord_i3_q}
                                  * {64'b0, src1_nb3_q});
        end else begin
            current_src_addr_w = {64'b0, src0_region_base_q}
                               + {64'b0, src0_view_off_q}
                               + (selected_i0_w * {64'b0, src0_nb0_q})
                               + ({96'b0, coord_i1_q}
                                  * {64'b0, src0_nb1_q})
                               + ({96'b0, coord_i2_q}
                                  * {64'b0, src0_nb2_q})
                               + ({96'b0, coord_i3_q}
                                  * {64'b0, src0_nb3_q});
        end
        current_dst_addr_w = {64'b0, dst_region_base_q}
                           + {64'b0, dst_view_off_q}
                           + ({64'b0, flat_index_q}
                              * {125'b0, element_bytes_q});
        current_addr_valid_w =
               (current_src_addr_w[127:64] == 64'b0)
            && (current_dst_addr_w[127:64] == 64'b0);
    end

    // ------------------------------------------------------------------
    // 唯一时序块：resident descriptor、FSM、watchdog 与审计计数器。
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                <= ST_IDLE;
            opcode_q               <= 2'b0;
            gmem_floor_q           <= 64'b0;
            gmem_limit_q           <= 64'b0;
            src0_region_base_q     <= 64'b0;
            src0_region_size_q     <= 64'b0;
            src0_view_off_q        <= 64'b0;
            src0_ne0_q             <= 32'b0;
            src0_ne1_q             <= 32'b0;
            src0_ne2_q             <= 32'b0;
            src0_ne3_q             <= 32'b0;
            src0_nb0_q             <= 64'b0;
            src0_nb1_q             <= 64'b0;
            src0_nb2_q             <= 64'b0;
            src0_nb3_q             <= 64'b0;
            src1_region_base_q     <= 64'b0;
            src1_region_size_q     <= 64'b0;
            src1_view_off_q        <= 64'b0;
            src1_ne0_q             <= 32'b0;
            src1_ne1_q             <= 32'b0;
            src1_ne2_q             <= 32'b0;
            src1_ne3_q             <= 32'b0;
            src1_nb0_q             <= 64'b0;
            src1_nb1_q             <= 64'b0;
            src1_nb2_q             <= 64'b0;
            src1_nb3_q             <= 64'b0;
            dst_region_base_q      <= 64'b0;
            dst_region_size_q      <= 64'b0;
            dst_view_off_q         <= 64'b0;
            element_bytes_q        <= 3'b0;
            dst_ne0_q              <= 32'b0;
            dst_ne1_q              <= 32'b0;
            dst_ne2_q              <= 32'b0;
            dst_ne3_q              <= 32'b0;
            total_elements_q       <= 64'b0;
            flat_index_q           <= 64'b0;
            coord_i0_q             <= 32'b0;
            coord_i1_q             <= 32'b0;
            coord_i2_q             <= 32'b0;
            coord_i3_q             <= 32'b0;
            gmem_req_addr_q        <= 64'b0;
            write_data_q           <= 64'b0;
            write_strb_q           <= 8'b0;
            source_lane_q          <= 3'b0;
            destination_addr_q     <= 64'b0;
            outstanding_q          <= 1'b0;
            stall_cycles_q         <= 32'b0;
            command_cycles_q       <= 32'b0;
            drain_error_code_q     <= ERR_NONE;
            error_code_q           <= ERR_NONE;
            elements_done_q        <= 64'b0;
            bytes_moved_q          <= 64'b0;
            gmem_read_beats_q      <= 64'b0;
            gmem_write_beats_q     <= 64'b0;
            writes_accepted_q      <= 64'b0;
            active_cycles_q        <= 64'b0;
        end else begin
            // DRAIN 与 terminal state 冻结所有命令周期/结果审计计数。
            if ((state_q != ST_IDLE) && (state_q != ST_GMEM_DRAIN)
                    && (state_q != ST_DONE) && (state_q != ST_ERROR)) begin
                command_cycles_q <= command_cycles_q + 32'd1;
                active_cycles_q  <= active_cycles_q + 64'd1;
            end

            case (state_q)
                ST_IDLE: begin
                    outstanding_q    <= 1'b0;
                    stall_cycles_q   <= 32'b0;
                    command_cycles_q <= 32'b0;
                    if (start_fire_w) begin
                        opcode_q             <= opcode_i;
                        gmem_floor_q         <= gmem_floor_i;
                        gmem_limit_q         <= gmem_limit_i;
                        src0_region_base_q   <= src0_region_base_i;
                        src0_region_size_q   <= src0_region_size_i;
                        src0_view_off_q      <= src0_view_off_i;
                        src0_ne0_q           <= src0_ne0_i;
                        src0_ne1_q           <= src0_ne1_i;
                        src0_ne2_q           <= src0_ne2_i;
                        src0_ne3_q           <= src0_ne3_i;
                        src0_nb0_q           <= src0_nb0_i;
                        src0_nb1_q           <= src0_nb1_i;
                        src0_nb2_q           <= src0_nb2_i;
                        src0_nb3_q           <= src0_nb3_i;
                        src1_region_base_q   <= src1_region_base_i;
                        src1_region_size_q   <= src1_region_size_i;
                        src1_view_off_q      <= src1_view_off_i;
                        src1_ne0_q           <= src1_ne0_i;
                        src1_ne1_q           <= src1_ne1_i;
                        src1_ne2_q           <= src1_ne2_i;
                        src1_ne3_q           <= src1_ne3_i;
                        src1_nb0_q           <= src1_nb0_i;
                        src1_nb1_q           <= src1_nb1_i;
                        src1_nb2_q           <= src1_nb2_i;
                        src1_nb3_q           <= src1_nb3_i;
                        dst_region_base_q    <= dst_region_base_i;
                        dst_region_size_q    <= dst_region_size_i;
                        dst_view_off_q       <= dst_view_off_i;
                        element_bytes_q      <= 3'b0;
                        dst_ne0_q            <= 32'b0;
                        dst_ne1_q            <= 32'b0;
                        dst_ne2_q            <= 32'b0;
                        dst_ne3_q            <= 32'b0;
                        total_elements_q     <= 64'b0;
                        flat_index_q         <= 64'b0;
                        coord_i0_q           <= 32'b0;
                        coord_i1_q           <= 32'b0;
                        coord_i2_q           <= 32'b0;
                        coord_i3_q           <= 32'b0;
                        gmem_req_addr_q      <= 64'b0;
                        write_data_q         <= 64'b0;
                        write_strb_q         <= 8'b0;
                        source_lane_q        <= 3'b0;
                        destination_addr_q   <= 64'b0;
                        stall_cycles_q       <= 32'b0;
                        command_cycles_q     <= 32'b0;
                        drain_error_code_q   <= ERR_NONE;
                        error_code_q         <= ERR_NONE;
                        elements_done_q      <= 64'b0;
                        bytes_moved_q        <= 64'b0;
                        gmem_read_beats_q    <= 64'b0;
                        gmem_write_beats_q   <= 64'b0;
                        writes_accepted_q    <= 64'b0;
                        active_cycles_q      <= 64'b0;
                        state_q              <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    stall_cycles_q <= 32'b0;
                    // Header/domain failure 高于 watchdog，且此态没有 request。
                    if (preflight_error_w != ERR_NONE) begin
                        error_code_q <= preflight_error_w;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        element_bytes_q  <= element_bytes_w;
                        total_elements_q <= total_elements_w[63:0];
                        dst_ne0_q <= (opcode_q == 2'd3)
                                   ? concat_ne0_sum_w[31:0] : src0_ne0_q;
                        dst_ne1_q <= src0_ne1_q;
                        dst_ne2_q <= src0_ne2_q;
                        dst_ne3_q <= src0_ne3_q;
                        if (empty_cpy_w) begin
                            state_q <= ST_DONE;
                        end else begin
                            state_q <= ST_ELEMENT_PREP;
                        end
                    end
                end

                ST_ELEMENT_PREP: begin
                    stall_cycles_q <= 32'b0;
                    // 这些条件由 preflight 结构性保证；若 resident 状态损坏则
                    // internal fatal 高于任何 watchdog，且不会发新 request。
                    if ((total_elements_q == 64'b0)
                            || (flat_index_q >= total_elements_q)
                            || (dst_ne0_q == 32'b0)
                            || (dst_ne1_q == 32'b0)
                            || (dst_ne2_q == 32'b0)
                            || (dst_ne3_q == 32'b0)
                            || !current_addr_valid_w) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        gmem_req_addr_q    <= {
                            current_src_addr_w[63:3], 3'b000
                        };
                        source_lane_q      <= current_src_addr_w[2:0];
                        destination_addr_q <= current_dst_addr_w[63:0];
                        state_q            <= ST_READ_REQ;
                    end
                end

                ST_READ_REQ: begin
                    if ((gmem_req_addr_q[2:0] != 3'b000)
                            || outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q <= ERR_STALL_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        outstanding_q     <= 1'b1;
                        gmem_read_beats_q <= gmem_read_beats_q + 64'd1;
                        stall_cycles_q    <= 32'b0;
                        state_q           <= ST_READ_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_READ_WAIT: begin
                    if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        state_q       <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            error_code_q  <= ERR_COMMAND_TIMEOUT;
                            state_q       <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (stall_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            error_code_q  <= ERR_STALL_TIMEOUT;
                            state_q       <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (gmem_rsp_fire_w) begin
                        outstanding_q  <= 1'b0;
                        stall_cycles_q <= 32'b0;
                        gmem_req_addr_q <= {
                            destination_addr_q[63:3], 3'b000
                        };
                        if (element_bytes_q == 3'd4) begin
                            write_data_q <=
                                ((gmem_rsp_rdata_i
                                  >> (source_lane_q * 8))
                                 & 64'h0000_0000_ffff_ffff)
                                << (destination_addr_q[2:0] * 8);
                            write_strb_q <= 8'h0f
                                          << destination_addr_q[2:0];
                        end else begin
                            write_data_q <=
                                ((gmem_rsp_rdata_i
                                  >> (source_lane_q * 8))
                                 & 64'h0000_0000_0000_ffff)
                                << (destination_addr_q[2:0] * 8);
                            write_strb_q <= 8'h03
                                          << destination_addr_q[2:0];
                        end
                        state_q <= ST_WRITE_REQ;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_WRITE_REQ: begin
                    if ((gmem_req_addr_q[2:0] != 3'b000)
                            || (write_strb_q == 8'b0)
                            || outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q <= ERR_STALL_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        outstanding_q       <= 1'b1;
                        gmem_write_beats_q  <= gmem_write_beats_q + 64'd1;
                        writes_accepted_q   <= writes_accepted_q + 64'd1;
                        stall_cycles_q      <= 32'b0;
                        state_q             <= ST_WRITE_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_WRITE_WAIT: begin
                    if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        state_q       <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            error_code_q  <= ERR_COMMAND_TIMEOUT;
                            state_q       <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (stall_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            error_code_q  <= ERR_STALL_TIMEOUT;
                            state_q       <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (gmem_rsp_fire_w) begin
                        outstanding_q   <= 1'b0;
                        stall_cycles_q  <= 32'b0;
                        elements_done_q <= elements_done_q + 64'd1;
                        bytes_moved_q   <= bytes_moved_q
                                         + {61'b0, element_bytes_q};
                        if ((flat_index_q + 64'd1) == total_elements_q) begin
                            state_q <= ST_DONE;
                        end else begin
                            flat_index_q <= flat_index_q + 64'd1;
                            if ((coord_i0_q + 32'd1) < dst_ne0_q) begin
                                coord_i0_q <= coord_i0_q + 32'd1;
                            end else begin
                                coord_i0_q <= 32'b0;
                                if ((coord_i1_q + 32'd1) < dst_ne1_q) begin
                                    coord_i1_q <= coord_i1_q + 32'd1;
                                end else begin
                                    coord_i1_q <= 32'b0;
                                    if ((coord_i2_q + 32'd1) < dst_ne2_q) begin
                                        coord_i2_q <= coord_i2_q + 32'd1;
                                    end else begin
                                        coord_i2_q <= 32'b0;
                                        coord_i3_q <= coord_i3_q + 32'd1;
                                    end
                                end
                            end
                            state_q <= ST_ELEMENT_PREP;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_GMEM_DRAIN: begin
                    // 已接受事务只丢弃 semantic adoption，不丢 response credit。
                    if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (gmem_rsp_fire_w) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= gmem_rsp_error_i
                                       ? ERR_GMEM_RESPONSE
                                       : drain_error_code_q;
                        state_q       <= ST_ERROR;
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    state_q <= ST_IDLE;
                end

                default: begin
                    // 非法 state 且仍有 accepted request 时先恢复唯一 drain credit。
                    if (outstanding_q) begin
                        drain_error_code_q <= ERR_INTERNAL_STATE;
                        state_q            <= ST_GMEM_DRAIN;
                    end else begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
