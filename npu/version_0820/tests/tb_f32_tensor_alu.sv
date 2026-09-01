`timescale 1ns/1ps
`default_nettype none

module tb_f32_tensor_alu;
    localparam integer GMEM_BYTES = 65536;
    localparam integer STALL_TIMEOUT_CYCLES = 8;
    localparam integer CHILD_TIMEOUT_CYCLES = 8;
    localparam integer COMMAND_TIMEOUT_CYCLES = 4096;
    localparam logic [31:0] STALL_TIMEOUT_LAST = 32'd7;
    localparam logic [31:0] CHILD_TIMEOUT_LAST = 32'd7;
    localparam logic [31:0] COMMAND_TIMEOUT_LAST = 32'd4095;

    localparam logic [2:0] OP_ADD   = 3'd0;
    localparam logic [2:0] OP_MUL   = 3'd1;
    localparam logic [2:0] OP_SUB   = 3'd2;
    localparam logic [2:0] OP_SCALE = 3'd3;

    localparam logic [4:0] ST_PREFLIGHT = 5'd1;
    localparam logic [4:0] ST_ELEMENT_PREP = 5'd2;
    localparam logic [4:0] ST_SRC0_REQ  = 5'd3;
    localparam logic [4:0] ST_SRC0_WAIT = 5'd4;
    localparam logic [4:0] ST_SRC1_REQ  = 5'd5;
    localparam logic [4:0] ST_SRC1_WAIT = 5'd6;
    localparam logic [4:0] ST_CHILD_REQ = 5'd7;
    localparam logic [4:0] ST_CHILD_WAIT = 5'd8;
    localparam logic [4:0] ST_WRITE_REQ = 5'd9;
    localparam logic [4:0] ST_WRITE_WAIT = 5'd10;
    localparam logic [4:0] ST_DRAIN = 5'd11;
    localparam logic [4:0] ST_ERROR = 5'd13;

    localparam logic [1:0] DRAIN_NONE = 2'd0;
    localparam logic [1:0] DRAIN_GMEM = 2'd1;
    localparam logic [1:0] DRAIN_CHILD = 2'd2;

    localparam logic [4:0] ERR_HEADER_PROFILE = 5'd1;
    localparam logic [4:0] ERR_SHAPE_BROADCAST = 5'd2;
    localparam logic [4:0] ERR_STRIDE_ALIGNMENT = 5'd3;
    localparam logic [4:0] ERR_SOURCE_BOUNDS = 5'd4;
    localparam logic [4:0] ERR_DEST_BOUNDS = 5'd5;
    localparam logic [4:0] ERR_OVERLAP = 5'd6;
    localparam logic [4:0] ERR_GMEM_RESPONSE = 5'd7;
    localparam logic [4:0] ERR_STALL_TIMEOUT = 5'd8;
    localparam logic [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam logic [4:0] ERR_CHILD_PROTOCOL = 5'd10;
    localparam logic [4:0] ERR_CHILD_TIMEOUT = 5'd11;
    localparam logic [4:0] ERR_INTERNAL_STATE = 5'd12;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [2:0] opcode_i;
    reg [1:0] dtype_i;
    reg [3:0] profile_i;
    reg [31:0] reserved_i;
    reg [63:0] op_params_i;
    reg [63:0] gmem_floor_i;
    reg [63:0] gmem_limit_i;

    reg [63:0] src0_region_base_i;
    reg [63:0] src0_region_size_i;
    reg [63:0] src0_view_off_i;
    reg [31:0] src0_ne0_i;
    reg [31:0] src0_ne1_i;
    reg [31:0] src0_ne2_i;
    reg [31:0] src0_ne3_i;
    reg [63:0] src0_nb0_i;
    reg [63:0] src0_nb1_i;
    reg [63:0] src0_nb2_i;
    reg [63:0] src0_nb3_i;
    reg [63:0] src1_region_base_i;
    reg [63:0] src1_region_size_i;
    reg [63:0] src1_view_off_i;
    reg [31:0] src1_ne0_i;
    reg [31:0] src1_ne1_i;
    reg [31:0] src1_ne2_i;
    reg [31:0] src1_ne3_i;
    reg [63:0] src1_nb0_i;
    reg [63:0] src1_nb1_i;
    reg [63:0] src1_nb2_i;
    reg [63:0] src1_nb3_i;
    reg [63:0] dst_region_base_i;
    reg [63:0] dst_region_size_i;
    reg [63:0] dst_view_off_i;
    reg [31:0] dst_ne0_i;
    reg [31:0] dst_ne1_i;
    reg [31:0] dst_ne2_i;
    reg [31:0] dst_ne3_i;
    reg [63:0] dst_nb0_i;
    reg [63:0] dst_nb1_i;
    reg [63:0] dst_nb2_i;
    reg [63:0] dst_nb3_i;

    wire gmem_req_valid_o;
    wire gmem_req_ready_i;
    wire gmem_req_write_o;
    wire [63:0] gmem_req_addr_o;
    wire [63:0] gmem_req_wdata_o;
    wire [7:0] gmem_req_wstrb_o;
    reg gmem_rsp_valid_i;
    wire gmem_rsp_ready_o;
    reg [63:0] gmem_rsp_rdata_i;
    reg gmem_rsp_error_i;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [4:0] arithmetic_flags_o;
    wire [63:0] elements_done_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_pair_reuse_elements_o;
    wire [63:0] gmem_write_beats_o;
    wire [63:0] writes_accepted_o;
    wire [63:0] child_requests_o;
    wire [63:0] child_responses_o;
    wire [63:0] active_cycles_o;

    TensorNpuF32TensorAlu #(
        .STALL_TIMEOUT_CYCLES   (STALL_TIMEOUT_CYCLES),
        .CHILD_TIMEOUT_CYCLES   (CHILD_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES (COMMAND_TIMEOUT_CYCLES),
        .MAX_ELEMENTS           (262144)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o), .opcode_i(opcode_i),
        .dtype_i(dtype_i), .profile_i(profile_i), .reserved_i(reserved_i),
        .op_params_i(op_params_i), .gmem_floor_i(gmem_floor_i),
        .gmem_limit_i(gmem_limit_i),
        .src0_region_base_i(src0_region_base_i),
        .src0_region_size_i(src0_region_size_i), .src0_view_off_i(src0_view_off_i),
        .src0_ne0_i(src0_ne0_i), .src0_ne1_i(src0_ne1_i),
        .src0_ne2_i(src0_ne2_i), .src0_ne3_i(src0_ne3_i),
        .src0_nb0_i(src0_nb0_i), .src0_nb1_i(src0_nb1_i),
        .src0_nb2_i(src0_nb2_i), .src0_nb3_i(src0_nb3_i),
        .src1_region_base_i(src1_region_base_i),
        .src1_region_size_i(src1_region_size_i), .src1_view_off_i(src1_view_off_i),
        .src1_ne0_i(src1_ne0_i), .src1_ne1_i(src1_ne1_i),
        .src1_ne2_i(src1_ne2_i), .src1_ne3_i(src1_ne3_i),
        .src1_nb0_i(src1_nb0_i), .src1_nb1_i(src1_nb1_i),
        .src1_nb2_i(src1_nb2_i), .src1_nb3_i(src1_nb3_i),
        .dst_region_base_i(dst_region_base_i),
        .dst_region_size_i(dst_region_size_i), .dst_view_off_i(dst_view_off_i),
        .dst_ne0_i(dst_ne0_i), .dst_ne1_i(dst_ne1_i),
        .dst_ne2_i(dst_ne2_i), .dst_ne3_i(dst_ne3_i),
        .dst_nb0_i(dst_nb0_i), .dst_nb1_i(dst_nb1_i),
        .dst_nb2_i(dst_nb2_i), .dst_nb3_i(dst_nb3_i),
        .gmem_req_valid_o(gmem_req_valid_o), .gmem_req_ready_i(gmem_req_ready_i),
        .gmem_req_write_o(gmem_req_write_o), .gmem_req_addr_o(gmem_req_addr_o),
        .gmem_req_wdata_o(gmem_req_wdata_o), .gmem_req_wstrb_o(gmem_req_wstrb_o),
        .gmem_rsp_valid_i(gmem_rsp_valid_i), .gmem_rsp_ready_o(gmem_rsp_ready_o),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i), .gmem_rsp_error_i(gmem_rsp_error_i),
        .done_o(done_o), .error_o(error_o), .error_code_o(error_code_o),
        .arithmetic_flags_o(arithmetic_flags_o), .elements_done_o(elements_done_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_pair_reuse_elements_o(gmem_pair_reuse_elements_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .writes_accepted_o(writes_accepted_o), .child_requests_o(child_requests_o),
        .child_responses_o(child_responses_o), .active_cycles_o(active_cycles_o)
    );

    always #5 clk_i <= ~clk_i;

    // Deterministic little-endian byte GMEM；for-loop只展开TB byte lanes。
    /* verilator lint_off MULTIDRIVEN */
    reg [7:0] gmem_bytes [0:GMEM_BYTES-1];
    /* verilator lint_on MULTIDRIVEN */
    reg allow_requests_q;
    reg force_ready_now_q;
    integer read_response_delay_cfg;
    integer write_response_delay_cfg;
    reg [4:0] inject_error_state_q;
    reg pending_q;
    reg pending_write_q;
    integer pending_addr_q;
    reg pending_error_q;
    integer response_countdown_q;
    integer outstanding_count;
    integer accepted_request_count;
    integer accepted_read_count;
    integer accepted_write_count;
    integer response_count;
    integer reset_cancelled_request_count;
    integer maximum_outstanding;
    integer maximum_combined_outstanding;
    integer child_model_outstanding;
    integer child_accepted_count;
    integer child_response_count;
    integer child_reset_cancelled_count;
    reg [63:0] model_cycle_q;
    integer lane;

    integer positive_cases;
    integer scalar_cases;
    integer broadcast_cases;
    integer preflight_cases;
    integer gmem_fault_cases;
    integer gmem_drain_cases;
    integer child_fault_cases;
    integer reset_cases;
    integer clean_retry_cases;
    integer busy_start_cases;
    integer force_witness_cases;
    integer busy_start_witness_cases;
    integer lookahead_turnover_cases;
    integer child_write_direct_cases;
    integer child_write_fallback_cases;
    integer protocol_collision_cases;
    integer src1_child_direct_cases;
    integer src1_child_fallback_cases;
    integer child_write_invalid_cases;
    integer child_deadline_priority_cases;
    integer gmem_pair_reuse_cases;
    integer gmem_pair_tag_cases;
    integer gmem_pair_child_fallback_cases;
    reg [3:0] src1_child_opcode_coverage;

    // repair-v3：把完整 resident descriptor 与除自然递增 watchdog/cycle 外的
    // transaction state 打包为只读 TB snapshot；该网络不进入 production RTL。
    wire [1960:0] resident_descriptor_observe_w;
    wire [990:0] resident_transaction_observe_w;
    assign resident_descriptor_observe_w = {
        dut.opcode_q, dut.dtype_q, dut.profile_q, dut.reserved_q,
        dut.op_params_q, dut.gmem_floor_q, dut.gmem_limit_q,
        dut.src0_region_base_q, dut.src0_region_size_q, dut.src0_view_off_q,
        dut.src0_ne0_q, dut.src0_ne1_q, dut.src0_ne2_q, dut.src0_ne3_q,
        dut.src0_nb0_q, dut.src0_nb1_q, dut.src0_nb2_q, dut.src0_nb3_q,
        dut.src1_region_base_q, dut.src1_region_size_q, dut.src1_view_off_q,
        dut.src1_ne0_q, dut.src1_ne1_q, dut.src1_ne2_q, dut.src1_ne3_q,
        dut.src1_nb0_q, dut.src1_nb1_q, dut.src1_nb2_q, dut.src1_nb3_q,
        dut.dst_region_base_q, dut.dst_region_size_q, dut.dst_view_off_q,
        dut.dst_ne0_q, dut.dst_ne1_q, dut.dst_ne2_q, dut.dst_ne3_q,
        dut.dst_nb0_q, dut.dst_nb1_q, dut.dst_nb2_q, dut.dst_nb3_q
    };
    assign resident_transaction_observe_w = {
        dut.state_q, dut.total_elements_q, dut.flat_index_q,
        dut.coord_i0_q, dut.coord_i1_q, dut.coord_i2_q, dut.coord_i3_q,
        dut.gmem_req_addr_q, dut.gmem_req_wdata_q, dut.gmem_req_wstrb_q,
        dut.gmem_read_upper_q, dut.current_src1_word_q,
        dut.current_dst_addr_q, dut.lhs_bits_q, dut.rhs_bits_q,
        dut.gmem_outstanding_q, dut.child_outstanding_q,
        dut.drain_owner_q, dut.drain_error_code_q, dut.error_code_q,
        dut.arithmetic_flags_q, dut.elements_done_q,
        dut.gmem_read_beats_q, dut.gmem_write_beats_q,
        dut.writes_accepted_q, dut.child_requests_q, dut.child_responses_q
    };

    wire [15:0] model_request_addr_w;
    assign model_request_addr_w = gmem_req_addr_o[15:0];
    assign gmem_req_ready_i = !rst_i && allow_requests_q
                            && !pending_q && !gmem_rsp_valid_i
                            && (force_ready_now_q || model_cycle_q[0]);

    function automatic [63:0] read_raw64(input integer byte_addr);
        integer read_lane;
        begin
            read_raw64 = 64'b0;
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
                read_raw64[(8*read_lane) +: 8] = gmem_bytes[byte_addr + read_lane];
        end
    endfunction

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-F32-TENSOR-ALU][FAIL] %s cycle=%0d state=%0d",
                     reason, model_cycle_q, dut.state_q);
            $fatal(1);
        end
    endtask

    always @(posedge clk_i) begin
        model_cycle_q <= model_cycle_q + 64'd1;
        if (model_cycle_q >= 64'd200000)
            fail_case("global timeout");
        if (rst_i) begin
            if (outstanding_count != 0)
                reset_cancelled_request_count <= reset_cancelled_request_count
                                               + outstanding_count;
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_addr_q <= 0;
            pending_error_q <= 1'b0;
            response_countdown_q <= 0;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            outstanding_count <= 0;
        end else begin
            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i || (outstanding_count != 0))
                    fail_case("more than one GMEM request outstanding");
                if ((gmem_req_addr_o[63:16] != 48'b0)
                        || (gmem_req_addr_o[2:0] != 3'b000)
                        || (gmem_req_addr_o[15:0] > 16'hfff8))
                    fail_case("GMEM request outside aligned model window");
                if (!gmem_req_write_o
                        && ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0)))
                    fail_case("read request carried write payload");
                if (gmem_req_write_o
                        && (gmem_req_wstrb_o != 8'h0f)
                        && (gmem_req_wstrb_o != 8'hf0))
                    fail_case("write strobe was not one F32 lane");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= {16'b0, model_request_addr_w};
                pending_error_q <= (inject_error_state_q == dut.state_q)
                                 || (gmem_req_write_o
                                     && (inject_error_state_q
                                         == ST_WRITE_REQ));
                response_countdown_q <= gmem_req_write_o
                                      ? write_response_delay_cfg
                                      : read_response_delay_cfg;
                outstanding_count <= outstanding_count + 1;
                accepted_request_count <= accepted_request_count + 1;
                if (gmem_req_write_o) begin
                    accepted_write_count <= accepted_write_count + 1;
                    for (lane = 0; lane < 8; lane = lane + 1) begin
                        if (gmem_req_wstrb_o[lane])
                            gmem_bytes[{16'b0, model_request_addr_w} + lane] <=
                                gmem_req_wdata_o[(8*lane) +: 8];
                    end
                end else begin
                    accepted_read_count <= accepted_read_count + 1;
                end
                if (maximum_outstanding < (outstanding_count + 1))
                    maximum_outstanding <= outstanding_count + 1;
            end
            if (pending_q && !gmem_rsp_valid_i) begin
                if (response_countdown_q > 0)
                    response_countdown_q <= response_countdown_q - 1;
                else begin
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_error_i <= pending_error_q;
                    gmem_rsp_rdata_i <= pending_write_q
                                      ? 64'b0 : read_raw64(pending_addr_q);
                end
            end
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (outstanding_count != 1)
                    fail_case("GMEM response consumed without owner");
                pending_q <= 1'b0;
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
                outstanding_count <= outstanding_count - 1;
                response_count <= response_count + 1;
            end
        end
    end

    // Child transaction conservation scoreboard。
    always @(posedge clk_i) begin
        if (rst_i || dut.child_rst_w) begin
            if (child_model_outstanding != 0)
                child_reset_cancelled_count <= child_reset_cancelled_count
                                               + child_model_outstanding;
            child_model_outstanding <= 0;
        end else begin
            if (dut.child_req_fire_w) begin
                if (child_model_outstanding != 0)
                    fail_case("child accepted while outstanding");
                child_model_outstanding <= child_model_outstanding + 1;
                child_accepted_count <= child_accepted_count + 1;
            end
            if (dut.child_rsp_fire_w) begin
                if (child_model_outstanding != 1)
                    fail_case("child response consumed without owner");
                child_model_outstanding <= child_model_outstanding - 1;
                child_response_count <= child_response_count + 1;
            end
        end
        if (dut.gmem_outstanding_q && dut.child_outstanding_q)
            fail_case("GMEM and child owners overlapped");
        if ((dut.gmem_outstanding_q || dut.child_outstanding_q)
                && (maximum_combined_outstanding < 1))
            maximum_combined_outstanding <= 1;
    end

    // Procedural valid/ready payload monitors；不启用assertion构建。
    reg gmem_hold_q;
    reg [63:0] held_gmem_addr_q;
    reg held_gmem_write_q;
    reg [63:0] held_gmem_wdata_q;
    reg [7:0] held_gmem_wstrb_q;
    reg child_req_hold_q;
    reg held_child_mul_q;
    reg [31:0] held_child_lhs_q;
    reg [31:0] held_child_rhs_q;
    reg child_rsp_hold_q;
    reg [31:0] held_child_result_q;
    reg [4:0] held_child_flags_q;
    reg previous_done_q;
    reg previous_error_q;

    always @(posedge clk_i) begin
        if (rst_i) begin
            gmem_hold_q <= 1'b0;
            child_req_hold_q <= 1'b0;
            child_rsp_hold_q <= 1'b0;
            previous_done_q <= 1'b0;
            previous_error_q <= 1'b0;
        end else begin
            if (done_o && error_o)
                fail_case("done/error overlap");
            if (ready_o && busy_o)
                fail_case("ready/busy overlap");
            if (done_o && previous_done_q)
                fail_case("done wider than one cycle");
            if (error_o && previous_error_q)
                fail_case("error wider than one cycle");
            if (gmem_hold_q && ((gmem_req_addr_o != held_gmem_addr_q)
                    || (gmem_req_write_o != held_gmem_write_q)
                    || (gmem_req_wdata_o != held_gmem_wdata_q)
                    || (gmem_req_wstrb_o != held_gmem_wstrb_q)))
                fail_case("GMEM request payload changed under backpressure");
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                gmem_hold_q <= 1'b1;
                held_gmem_addr_q <= gmem_req_addr_o;
                held_gmem_write_q <= gmem_req_write_o;
                held_gmem_wdata_q <= gmem_req_wdata_o;
                held_gmem_wstrb_q <= gmem_req_wstrb_o;
            end else begin
                gmem_hold_q <= 1'b0;
            end
            if (child_req_hold_q && ((dut.child_op_mul_w != held_child_mul_q)
                    || (dut.lhs_bits_q != held_child_lhs_q)
                    || (dut.child_rhs_bits_w != held_child_rhs_q)))
                fail_case("child request payload changed under backpressure");
            if (dut.child_req_valid_w && !dut.child_req_ready_w) begin
                child_req_hold_q <= 1'b1;
                held_child_mul_q <= dut.child_op_mul_w;
                held_child_lhs_q <= dut.lhs_bits_q;
                held_child_rhs_q <= dut.child_rhs_bits_w;
            end else begin
                child_req_hold_q <= 1'b0;
            end
            if (child_rsp_hold_q
                    && ((dut.child_result_bits_w != held_child_result_q)
                        || (dut.child_flags_w != held_child_flags_q)))
                fail_case("child response payload changed under backpressure");
            if (dut.child_rsp_valid_w && !dut.child_rsp_ready_w) begin
                child_rsp_hold_q <= 1'b1;
                held_child_result_q <= dut.child_result_bits_w;
                held_child_flags_q <= dut.child_flags_w;
            end else begin
                child_rsp_hold_q <= 1'b0;
            end
            previous_done_q <= done_o;
            previous_error_q <= error_o;
        end
    end

    task automatic write_raw32(input logic [15:0] addr,
                               input logic [31:0] value);
        integer base;
        begin
            base = {16'b0, addr};
            gmem_bytes[base] = value[7:0];
            gmem_bytes[base+1] = value[15:8];
            gmem_bytes[base+2] = value[23:16];
            gmem_bytes[base+3] = value[31:24];
        end
    endtask

    function automatic [31:0] read_raw32(input logic [15:0] addr);
        integer base;
        begin
            base = {16'b0, addr};
            read_raw32 = {gmem_bytes[base+3], gmem_bytes[base+2],
                          gmem_bytes[base+1], gmem_bytes[base]};
        end
    endfunction

    task automatic fill_bytes(input logic [15:0] addr,
                              input integer count,
                              input logic [7:0] value);
        integer index;
        integer base;
        begin
            base = {16'b0, addr};
            for (index = 0; index < count; index = index + 1)
                gmem_bytes[base + index] = value;
        end
    endtask

    task automatic check_raw32(input string name,
                               input logic [15:0] addr,
                               input logic [31:0] expected);
        begin
            if (read_raw32(addr) !== expected)
                fail_case($sformatf("%s addr=%04x expected=%08x got=%08x",
                                    name, addr, expected, read_raw32(addr)));
        end
    endtask

    task automatic check_root_canary(input string name);
        integer index;
        begin
            for (index = 32'h00000100; index < 32'h00000120;
                    index = index + 1) begin
                if (gmem_bytes[index] !== 8'h5a)
                    fail_case({name, " modified active-root canary"});
            end
        end
    endtask

    task automatic set_default_command;
        begin
            start_i = 1'b0;
            opcode_i = OP_ADD;
            dtype_i = 2'b0;
            profile_i = 4'b0;
            reserved_i = 32'b0;
            op_params_i = 64'b0;
            gmem_floor_i = 64'd0;
            gmem_limit_i = 64'd65536;
            src0_region_base_i = 64'h1000;
            src0_region_size_i = 64'h0400;
            src0_view_off_i = 64'd0;
            src0_ne0_i = 32'd1; src0_ne1_i = 32'd1;
            src0_ne2_i = 32'd1; src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd4;
            src0_nb2_i = 64'd4; src0_nb3_i = 64'd4;
            src1_region_base_i = 64'h2000;
            src1_region_size_i = 64'h0400;
            src1_view_off_i = 64'd0;
            src1_ne0_i = 32'd1; src1_ne1_i = 32'd1;
            src1_ne2_i = 32'd1; src1_ne3_i = 32'd1;
            src1_nb0_i = 64'd4; src1_nb1_i = 64'd4;
            src1_nb2_i = 64'd4; src1_nb3_i = 64'd4;
            dst_region_base_i = 64'h4000;
            dst_region_size_i = 64'h0400;
            dst_view_off_i = 64'd0;
            dst_ne0_i = 32'd1; dst_ne1_i = 32'd1;
            dst_ne2_i = 32'd1; dst_ne3_i = 32'd1;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd4;
            dst_nb2_i = 64'd4; dst_nb3_i = 64'd4;
            allow_requests_q = 1'b1;
            force_ready_now_q = 1'b1;
            read_response_delay_cfg = 1;
            write_response_delay_cfg = 1;
            inject_error_state_q = 5'h1f;
        end
    endtask

    task automatic launch_command;
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!ready_o) begin
                @(posedge clk_i); @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 100)
                    fail_case("launch waited too long for ready");
            end
            start_i = 1'b1;
            @(posedge clk_i); @(negedge clk_i);
            start_i = 1'b0;
            if (!busy_o || ready_o)
                fail_case("start did not create resident command");
        end
    endtask

    task automatic wait_for_state(input logic [4:0] expected_state,
                                  input string name,
                                  input integer max_cycles);
        integer cycles;
        begin
            cycles = 0;
            while (dut.state_q != expected_state) begin
                if (done_o || error_o)
                    fail_case({name, " terminated before expected state"});
                @(posedge clk_i); @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case({name, " state timeout"});
            end
        end
    endtask

    task automatic finish_done(input string name, input integer max_cycles);
        integer cycles;
        begin
            cycles = 0;
            while (!done_o) begin
                if (error_o)
                    fail_case({name, " unexpected ERROR"});
                @(posedge clk_i); @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case({name, " DONE timeout"});
            end
            if (error_code_o != 5'b0)
                fail_case({name, " DONE carried error code"});
            @(posedge clk_i); @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o)
                fail_case({name, " DONE was not one cycle"});
        end
    endtask

    task automatic finish_error(input string name,
                                input logic [4:0] expected_code,
                                input integer max_cycles);
        integer cycles;
        begin
            cycles = 0;
            while (!error_o) begin
                if (done_o)
                    fail_case({name, " unexpected DONE"});
                @(posedge clk_i); @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case({name, " ERROR timeout"});
            end
            if ((error_code_o != expected_code) || (arithmetic_flags_o != 5'b0))
                fail_case({name, " malformed ERROR payload"});
            @(posedge clk_i); @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o)
                fail_case({name, " ERROR was not one cycle"});
        end
    endtask

    task automatic reset_engine;
        begin
            start_i = 1'b0;
            rst_i = 1'b1;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            repeat (2) begin
                @(posedge clk_i); @(negedge clk_i);
                if (!ready_o || busy_o || done_o || error_o
                        || gmem_req_valid_o || gmem_rsp_ready_o
                        || (gmem_pair_reuse_elements_o != 64'b0)
                        || dut.src0_beat_valid_q || dut.src1_beat_valid_q
                        || dut.pair_reuse_prepared_q)
                    fail_case("reset did not establish clean IDLE");
            end
        end
    endtask

    task automatic run_scalar(input string name,
                              input logic [2:0] op,
                              input logic [31:0] lhs,
                              input logic [31:0] rhs_or_scale,
                              input logic [31:0] expected,
                              input logic [4:0] expected_flags,
                              input integer count_as_retry);
        reg [31:0] expected_child_rhs;
        begin
            set_default_command();
            opcode_i = op;
            if (op == OP_SCALE) begin
                op_params_i = {32'b0, rhs_or_scale};
                src1_region_base_i = 64'b0;
                src1_region_size_i = 64'b0;
                src1_view_off_i = 64'b0;
                src1_ne0_i = 32'b0; src1_ne1_i = 32'b0;
                src1_ne2_i = 32'b0; src1_ne3_i = 32'b0;
                src1_nb0_i = 64'b0; src1_nb1_i = 64'b0;
                src1_nb2_i = 64'b0; src1_nb3_i = 64'b0;
            end else begin
                write_raw32(16'h2000, rhs_or_scale);
            end
            write_raw32(16'h1000, lhs);
            fill_bytes(16'h4000, 8, 8'ha5);
            launch_command();
            expected_child_rhs = (op == OP_SUB)
                               ? {~rhs_or_scale[31], rhs_or_scale[30:0]}
                               : rhs_or_scale;
            if (op == OP_SCALE) begin
                wait_for_state(ST_CHILD_REQ, {name, "-scale-child"}, 100);
                #0.1;
                if (dut.src1_child_direct_offer_w
                        || dut.src1_child_direct_fire_w
                        || !dut.child_req_valid_w
                        || !dut.child_req_ready_w
                        || !dut.child_req_fire_w
                        || !dut.child_op_mul_w
                        || (dut.lhs_bits_q !== lhs)
                        || (dut.child_rhs_raw_w !== rhs_or_scale)
                        || (dut.child_rhs_bits_w !== expected_child_rhs)
                        || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000)
                        || dut.gmem_outstanding_q
                        || dut.child_outstanding_q)
                    fail_case({name, " SCALE child boundary mismatch"});
                src1_child_opcode_coverage[OP_SCALE[1:0]] = 1'b1;
            end else begin
                wait_for_state(ST_SRC1_WAIT, {name, "-src1-direct"}, 100);
                while (!gmem_rsp_valid_i) begin
                    @(posedge clk_i); @(negedge clk_i);
                    if (dut.state_q != ST_SRC1_WAIT)
                        fail_case({name, " left SRC1_WAIT before response"});
                end
                #0.1;
                if (!gmem_rsp_ready_o || !dut.gmem_rsp_fire_w
                        || gmem_rsp_error_i || dut.protocol_fault_w
                        || dut.command_timeout_hit_w
                        || dut.phase_timeout_hit_w
                        || !dut.src1_child_direct_offer_w
                        || !dut.src1_child_direct_fire_w
                        || !dut.child_req_valid_w
                        || !dut.child_req_ready_w
                        || !dut.child_req_fire_w
                        || (dut.child_op_mul_w !== (op == OP_MUL))
                        || (dut.lhs_bits_q !== lhs)
                        || (dut.child_rhs_raw_w !== rhs_or_scale)
                        || (dut.child_rhs_bits_w !== expected_child_rhs)
                        || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000)
                        || !dut.gmem_outstanding_q
                        || dut.child_outstanding_q)
                    fail_case({name, " direct child payload/authority mismatch"});
                src1_child_opcode_coverage[op[1:0]] = 1'b1;
            end
            finish_done(name, 200);
            check_raw32(name, 16'h4000, expected);
            if ((elements_done_o != 64'd1)
                    || (gmem_read_beats_o != ((op == OP_SCALE) ? 64'd1 : 64'd2))
                    || (gmem_pair_reuse_elements_o != 64'b0)
                    || (gmem_write_beats_o != 64'd1)
                    || (writes_accepted_o != 64'd1)
                    || (child_requests_o != 64'd1)
                    || (child_responses_o != 64'd1)
                    || (arithmetic_flags_o != expected_flags))
                fail_case({name, " scalar counters/flags mismatch"});
            check_root_canary(name);
            scalar_cases = scalar_cases + 1;
            positive_cases = positive_cases + 1;
            if (count_as_retry != 0)
                clean_retry_cases = clean_retry_cases + 1;
        end
    endtask

    task automatic expect_preflight(input string name,
                                    input logic [4:0] expected_code);
        integer accepted_before;
        begin
            accepted_before = accepted_request_count;
            launch_command();
            finish_error(name, expected_code, 40);
            if ((accepted_request_count != accepted_before)
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (elements_done_o != 64'b0))
                fail_case({name, " preflight leaked transaction"});
            preflight_cases = preflight_cases + 1;
            check_root_canary(name);
        end
    endtask

    task automatic run_sticky_flags;
        begin
            set_default_command();
            opcode_i = OP_MUL;
            src0_ne0_i = 32'd2; src0_nb1_i = 64'd8;
            src0_nb2_i = 64'd8; src0_nb3_i = 64'd8;
            src1_ne0_i = 32'd2; src1_nb1_i = 64'd8;
            src1_nb2_i = 64'd8; src1_nb3_i = 64'd8;
            dst_ne0_i = 32'd2; dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd8; dst_nb3_i = 64'd8;
            write_raw32(16'h1000, 32'h00000000);
            write_raw32(16'h1004, 32'h00000001);
            write_raw32(16'h2000, 32'hff800000);
            write_raw32(16'h2004, 32'h3fc00000);
            fill_bytes(16'h4000, 16, 8'ha5);
            launch_command();
            finish_done("sticky-flags", 300);
            check_raw32("sticky-nv", 16'h4000, 32'h7fc00000);
            check_raw32("sticky-ufnx", 16'h4004, 32'h00000002);
            if ((arithmetic_flags_o != 5'h13)
                    || (elements_done_o != 64'd2)
                    || (gmem_read_beats_o != 64'd2)
                    || (gmem_pair_reuse_elements_o != 64'd1)
                    || (gmem_write_beats_o != 64'd2)
                    || (child_requests_o != 64'd2)
                    || (child_responses_o != 64'd2))
                fail_case("sticky flags/counters mismatch");
            positive_cases = positive_cases + 1;
            check_root_canary("sticky-flags");
        end
    endtask

    // Standard contiguous binary traversal: the first lane of every source
    // beat is a physical miss and the second lane reuses both registered
    // beats.  The clean child response prepares each exact pair hit in q;
    // the later write response transfers GMEM owner directly to child.
    task automatic run_gmem_pair_reuse_oracle;
        integer q;
        integer hit_elements;
        integer miss_elements;
        integer direct_miss_elements;
        integer pair_direct_elements;
        integer reads_before;
        reg [63:0] reuse_before;
        reg [63:0] child_requests_before;
        reg [31:0] expected_lhs;
        reg [31:0] expected_rhs;
        begin
            set_default_command();
            opcode_i = OP_ADD;
            src0_ne0_i = 32'd16;
            src0_nb1_i = 64'd64;
            src0_nb2_i = 64'd64;
            src0_nb3_i = 64'd64;
            src1_ne0_i = 32'd16;
            src1_nb1_i = 64'd64;
            src1_nb2_i = 64'd64;
            src1_nb3_i = 64'd64;
            dst_ne0_i = 32'd16;
            dst_nb1_i = 64'd64;
            dst_nb2_i = 64'd64;
            dst_nb3_i = 64'd64;
            for (q = 0; q < 16; q = q + 1) begin
                write_raw32(16'h1000 + {q[13:0], 2'b00},
                            q[0] ? 32'h40000000 : 32'h3f800000);
                write_raw32(16'h2000 + {q[13:0], 2'b00},
                            q[0] ? 32'h40800000 : 32'h40000000);
            end
            fill_bytes(16'h4000, 80, 8'ha5);
            hit_elements = 0;
            miss_elements = 1;
            direct_miss_elements = 0;
            pair_direct_elements = 0;
            reads_before = accepted_read_count;
            launch_command();
            if ((gmem_pair_reuse_elements_o != 64'b0)
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q
                    || dut.pair_reuse_prepared_q)
                fail_case("pair reuse start did not clear cache/counter");
            while (!done_o) begin
                @(negedge clk_i);
                if (error_o)
                    fail_case("pair reuse oracle unexpected ERROR");
                if ((dut.state_q == ST_SRC1_WAIT)
                        && dut.gmem_rsp_fire_w) begin
                    if (!dut.src1_child_direct_offer_w
                            || !dut.src1_child_direct_fire_w)
                        fail_case("pair reuse miss did not use SRC1 direct path");
                    direct_miss_elements = direct_miss_elements + 1;
                end
                if ((dut.state_q == ST_WRITE_WAIT)
                        && dut.gmem_rsp_fire_w
                        && !gmem_rsp_error_i
                        && (dut.flat_index_q < 64'd15)) begin
                    if (dut.gmem_pair_reuse_hit_w) begin
                        if (!dut.src0_beat_reuse_hit_w
                                || !dut.src1_beat_reuse_hit_w
                                || !dut.select_next_element_w
                                || !dut.selected_element_address_valid_w
                                || !dut.binary_op_w
                                || !dut.selected_src0_addr_w[2]
                                || !dut.selected_src1_addr_w[2]
                                || !dut.pair_reuse_prepared_q
                                || !dut.pair_reuse_child_direct_offer_w
                                || !dut.pair_reuse_child_direct_fire_w
                                || !dut.child_req_valid_w
                                || !dut.child_req_ready_w
                                || !dut.child_req_fire_w
                                || dut.src1_child_direct_offer_w
                                || dut.src1_child_direct_fire_w
                                || gmem_req_valid_o || dut.gmem_req_fire_w)
                            fail_case("pair reuse C0 direct offer mismatch");
                        expected_lhs = 32'h40000000;
                        expected_rhs = 32'h40800000;
                        if ((dut.lhs_bits_q !== expected_lhs)
                                || (dut.rhs_bits_q !== expected_rhs)
                                || (dut.child_rhs_raw_w !== expected_rhs)
                                || (dut.child_rhs_bits_w !== expected_rhs))
                            fail_case("pair reuse prepared payload mismatch");
                        reuse_before = gmem_pair_reuse_elements_o;
                        child_requests_before = child_requests_o;
                        @(posedge clk_i); @(negedge clk_i);
                        if ((dut.state_q != ST_CHILD_WAIT)
                                || dut.pair_reuse_prepared_q
                                || dut.pair_reuse_child_direct_offer_w
                                || dut.pair_reuse_child_direct_fire_w
                                || dut.src1_child_direct_offer_w
                                || dut.src1_child_direct_fire_w
                                || (dut.lhs_bits_q !== expected_lhs)
                                || (dut.rhs_bits_q !== expected_rhs)
                                || (dut.child_rhs_raw_w !== expected_rhs)
                                || (gmem_pair_reuse_elements_o
                                    != (reuse_before + 64'd1))
                                || (child_requests_o
                                    != (child_requests_before + 64'd1))
                                || dut.gmem_outstanding_q
                                || !dut.child_outstanding_q)
                            fail_case("pair reuse C1 direct owner mismatch");
                        hit_elements = hit_elements + 1;
                        pair_direct_elements = pair_direct_elements + 1;
                    end else begin
                        miss_elements = miss_elements + 1;
                    end
                end else if ((dut.state_q == ST_WRITE_WAIT)
                        && dut.gmem_rsp_fire_w
                        && !gmem_rsp_error_i
                        && (dut.flat_index_q == 64'd15)) begin
                    if (dut.select_next_element_w
                            || dut.pair_reuse_prepared_q
                            || dut.pair_reuse_child_direct_offer_w
                            || dut.pair_reuse_child_direct_fire_w)
                        fail_case("pair reuse last element exposed direct offer");
                end
            end
            if ((hit_elements != 8) || (miss_elements != 8)
                    || (direct_miss_elements != 8)
                    || (pair_direct_elements != 8))
                fail_case("pair reuse hit/miss/direct cardinality mismatch");
            finish_done("gmem-pair-reuse", 20);
            for (q = 0; q < 16; q = q + 1)
                check_raw32("gmem-pair-reuse",
                            16'h4000 + {q[13:0], 2'b00},
                            q[0] ? 32'h40c00000 : 32'h40400000);
            if ((elements_done_o != 64'd16)
                    || (gmem_read_beats_o != 64'd16)
                    || (gmem_pair_reuse_elements_o != 64'd8)
                    || (gmem_write_beats_o != 64'd16)
                    || (writes_accepted_o != 64'd16)
                    || (child_requests_o != 64'd16)
                    || (child_responses_o != 64'd16)
                    || ((accepted_read_count - reads_before) != 16)
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q
                    || (arithmetic_flags_o != 5'b0))
                fail_case("pair reuse final counters/result mismatch");
            gmem_pair_reuse_cases = gmem_pair_reuse_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("gmem-pair-reuse");
        end
    endtask

    // Two 2-element rows combine modulo broadcast with a 16-byte row stride.
    // The second element of each row hits; the row transition uses the same
    // lower lane but a different exact beat tag and therefore must miss.
    task automatic run_gmem_pair_tag_oracle;
        integer hit_elements;
        integer miss_elements;
        integer direct_miss_elements;
        integer pair_direct_elements;
        integer reads_before;
        reg [63:0] reuse_before;
        reg [63:0] child_requests_before;
        reg [31:0] expected_lhs_raw;
        reg [31:0] expected_rhs_raw;
        reg [31:0] expected_rhs_bits;
        begin
            set_default_command();
            opcode_i = OP_SUB;
            src0_ne0_i = 32'd2; src0_ne1_i = 32'd2;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd32; src0_nb3_i = 64'd32;
            src1_ne0_i = 32'd1; src1_ne1_i = 32'd2;
            src1_nb0_i = 64'd4; src1_nb1_i = 64'd16;
            src1_nb2_i = 64'd32; src1_nb3_i = 64'd32;
            dst_ne0_i = 32'd2; dst_ne1_i = 32'd2;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd16; dst_nb3_i = 64'd16;
            write_raw32(16'h1000, 32'h3f800000);
            write_raw32(16'h1004, 32'h40000000);
            write_raw32(16'h1010, 32'h40800000);
            write_raw32(16'h1014, 32'h41000000);
            write_raw32(16'h2000, 32'h3f800000);
            write_raw32(16'h2010, 32'h40000000);
            fill_bytes(16'h4000, 24, 8'ha5);
            hit_elements = 0;
            miss_elements = 1;
            direct_miss_elements = 0;
            pair_direct_elements = 0;
            reads_before = accepted_read_count;
            launch_command();
            if ((gmem_pair_reuse_elements_o != 64'b0)
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q
                    || dut.pair_reuse_prepared_q)
                fail_case("pair tag start retained prior command cache");
            while (!done_o) begin
                @(negedge clk_i);
                if (error_o)
                    fail_case("pair tag oracle unexpected ERROR");
                if ((dut.state_q == ST_SRC1_WAIT)
                        && dut.gmem_rsp_fire_w) begin
                    if (!dut.src1_child_direct_offer_w
                            || !dut.src1_child_direct_fire_w)
                        fail_case("pair tag miss did not use SRC1 direct path");
                    direct_miss_elements = direct_miss_elements + 1;
                end
                if ((dut.state_q == ST_WRITE_WAIT)
                        && dut.gmem_rsp_fire_w
                        && !gmem_rsp_error_i
                        && (dut.flat_index_q < 64'd3)) begin
                    reuse_before = gmem_pair_reuse_elements_o;
                    if (dut.gmem_pair_reuse_hit_w) begin
                        expected_lhs_raw = (dut.flat_index_q == 64'd0)
                                         ? 32'h40000000 : 32'h41000000;
                        expected_rhs_raw = (dut.flat_index_q == 64'd0)
                                         ? 32'h3f800000 : 32'h40000000;
                        expected_rhs_bits = {~expected_rhs_raw[31],
                                             expected_rhs_raw[30:0]};
                        if (!dut.src0_beat_reuse_hit_w
                                || !dut.src1_beat_reuse_hit_w
                                || !dut.selected_src0_addr_w[2]
                                || dut.selected_src1_addr_w[2]
                                || !dut.pair_reuse_prepared_q
                                || !dut.pair_reuse_child_direct_offer_w
                                || !dut.pair_reuse_child_direct_fire_w
                                || !dut.child_req_valid_w
                                || !dut.child_req_fire_w
                                || dut.src1_child_direct_offer_w
                                || (dut.lhs_bits_q !== expected_lhs_raw)
                                || (dut.rhs_bits_q !== expected_rhs_raw)
                                || (dut.child_rhs_raw_w !== expected_rhs_raw)
                                || (dut.child_rhs_bits_w
                                    !== expected_rhs_bits))
                            fail_case("pair tag hit predicate/lane mismatch");
                        child_requests_before = child_requests_o;
                        @(posedge clk_i); @(negedge clk_i);
                        if ((dut.state_q != ST_CHILD_WAIT)
                                || dut.pair_reuse_prepared_q
                                || dut.child_op_mul_w
                                || (dut.rhs_bits_q !== expected_rhs_raw)
                                || (dut.child_rhs_raw_w !== expected_rhs_raw)
                                || (dut.child_rhs_bits_w
                                    !== expected_rhs_bits)
                                || (gmem_pair_reuse_elements_o
                                    != (reuse_before + 64'd1))
                                || (child_requests_o
                                    != (child_requests_before + 64'd1))
                                || dut.gmem_outstanding_q
                                || !dut.child_outstanding_q)
                            fail_case("pair tag hit did not direct to child");
                        hit_elements = hit_elements + 1;
                        pair_direct_elements = pair_direct_elements + 1;
                    end else begin
                        if (dut.flat_index_q != 64'd1)
                            fail_case("pair tag unexpected non-hit turnover");
                        if (dut.selected_src0_addr_w[2]
                                || dut.selected_src1_addr_w[2]
                                || (dut.src0_beat_tag_q
                                    == dut.selected_src0_addr_w[63:3])
                                || (dut.src1_beat_tag_q
                                    == dut.selected_src1_addr_w[63:3]))
                            fail_case("same-lane cross-beat false-hit witness missing");
                        if (dut.pair_reuse_prepared_q
                                || dut.pair_reuse_child_direct_offer_w
                                || dut.pair_reuse_child_direct_fire_w)
                            fail_case("pair tag miss retained prepared direct");
                        @(posedge clk_i); @(negedge clk_i);
                        if ((dut.state_q != ST_SRC0_REQ)
                                || (gmem_pair_reuse_elements_o != reuse_before))
                            fail_case("pair tag miss did not take SRC0_REQ");
                        miss_elements = miss_elements + 1;
                    end
                end
            end
            if ((hit_elements != 2) || (miss_elements != 2)
                    || (direct_miss_elements != 2)
                    || (pair_direct_elements != 2))
                fail_case("pair tag hit/miss/direct cardinality mismatch");
            finish_done("gmem-pair-tag", 20);
            check_raw32("pair-tag-0", 16'h4000, 32'h00000000);
            check_raw32("pair-tag-1", 16'h4004, 32'h3f800000);
            check_raw32("pair-tag-2", 16'h4008, 32'h40000000);
            check_raw32("pair-tag-3", 16'h400c, 32'h40c00000);
            if ((elements_done_o != 64'd4)
                    || (gmem_read_beats_o != 64'd4)
                    || (gmem_pair_reuse_elements_o != 64'd2)
                    || (gmem_write_beats_o != 64'd4)
                    || (child_requests_o != 64'd4)
                    || (child_responses_o != 64'd4)
                    || ((accepted_read_count - reads_before) != 4)
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q)
                fail_case("pair tag final counters mismatch");
            gmem_pair_tag_cases = gmem_pair_tag_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("gmem-pair-tag");

            reset_engine();
            if ((gmem_pair_reuse_elements_o != 64'b0)
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q
                    || dut.pair_reuse_prepared_q)
                fail_case("pair cache reset retained stale state");
            run_scalar("pair-cache-reset-clean-retry", OP_ADD,
                       32'h3f800000, 32'h40000000,
                       32'h40400000, 5'b0, 0);
        end
    endtask

    // Two contiguous elements make the second element an exact pair hit.
    // Hold child ready low on the first write response to prove elastic
    // fallback: the response is consumed once, q remains stable in CHILD_REQ,
    // and the eventual child request is accepted exactly once.  The same held
    // response also supplies no-edge fail-closed probes for every direct gate.
    task automatic run_gmem_pair_child_fallback_oracle;
        reg [31:0] command_cycles_snapshot;
        reg [31:0] stall_cycles_snapshot;
        reg [31:0] coord_i0_snapshot;
        reg [31:0] held_lhs;
        reg [31:0] held_rhs_raw;
        reg [31:0] held_rhs_bits;
        reg [63:0] reuse_before;
        reg [63:0] child_requests_before;
        begin
            prepare_two_element_fault_command();
            opcode_i = OP_ADD;
            launch_command();

            // Observe the first child response before its edge.  The valid
            // successor is a dual-cache hit and must be the only prepare
            // candidate; an invalid successor suppresses preparation.
            wait_for_state(ST_CHILD_WAIT, "pair-child-prepare", 120);
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("pair child prepare left CHILD_WAIT");
            end
            #0.1;
            if (!dut.child_rsp_fire_w
                    || !dut.select_pair_prepare_element_w
                    || !dut.gmem_pair_reuse_prepare_hit_w
                    || !dut.pair_reuse_prepare_w
                    || dut.pair_reuse_prepared_q
                    || (dut.selected_flat_index_w != 64'd1)
                    || !dut.selected_src0_addr_w[2]
                    || !dut.selected_src1_addr_w[2])
                fail_case("pair child clean prepare candidate mismatch");
            force dut.selected_address_valid_w = 1'b0;
            #0.1;
            if (dut.selected_element_address_valid_w
                    || dut.gmem_pair_reuse_prepare_hit_w
                    || dut.pair_reuse_prepare_w)
                fail_case("invalid successor exposed pair preparation");
            force dut.selected_address_valid_w = 1'b1;
            #0.1;
            if (!dut.gmem_pair_reuse_prepare_hit_w
                    || !dut.pair_reuse_prepare_w)
                fail_case("pair preparation did not recover after invalid probe");
            release dut.selected_address_valid_w;

            @(posedge clk_i); @(negedge clk_i);
            wait_for_state(ST_WRITE_WAIT, "pair-child-write", 40);
            force dut.child_req_ready_w = 1'b0;
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_WRITE_WAIT)
                    fail_case("pair child fallback left WRITE_WAIT");
            end
            #0.1;
            held_lhs = dut.lhs_bits_q;
            held_rhs_raw = dut.child_rhs_raw_w;
            held_rhs_bits = dut.child_rhs_bits_w;
            reuse_before = gmem_pair_reuse_elements_o;
            child_requests_before = child_requests_o;
            if (!gmem_rsp_ready_o || !dut.gmem_rsp_fire_w
                    || gmem_rsp_error_i || dut.protocol_fault_w
                    || dut.command_timeout_hit_w
                    || dut.phase_timeout_hit_w
                    || !dut.current_element_integrity_ok_w
                    || !dut.gmem_pair_reuse_hit_w
                    || !dut.pair_reuse_prepared_q
                    || !dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || !dut.child_req_valid_w || dut.child_req_ready_w
                    || dut.child_req_fire_w
                    || (held_lhs !== 32'h40000000)
                    || (held_rhs_raw !== 32'h3f800000)
                    || (held_rhs_bits !== 32'h3f800000)
                    || !dut.gmem_outstanding_q
                    || dut.child_outstanding_q)
                fail_case("pair child elastic fallback C0 mismatch");

            // Error, watchdog, rogue child response, current-walker
            // corruption and reset all suppress offer/valid on this same
            // held response.  No probe crosses a clock edge.
            force gmem_rsp_error_i = 1'b1;
            #0.1;
            if (!dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("pair child GMEM error exposed direct request");
            force gmem_rsp_error_i = 1'b0;
            #0.1;
            release gmem_rsp_error_i;

            command_cycles_snapshot = dut.command_cycles_q;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            #0.1;
            if (!dut.command_timeout_hit_w || !dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("pair child command timeout exposed direct request");
            force dut.command_cycles_q = command_cycles_snapshot;
            #0.1;
            release dut.command_cycles_q;

            stall_cycles_snapshot = dut.stall_cycles_q;
            force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            #0.1;
            if (!dut.phase_timeout_hit_w || !dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("pair child phase timeout exposed direct request");
            force dut.stall_cycles_q = stall_cycles_snapshot;
            #0.1;
            release dut.stall_cycles_q;

            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            #0.1;
            if (!dut.protocol_fault_w
                    || !dut.child_response_owner_fault_w
                    || gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("pair child rogue response exposed direct request");
            force dut.u_fp32_addmul.rsp_valid_q = 1'b0;
            #0.1;
            release dut.u_fp32_addmul.rsp_valid_q;

            coord_i0_snapshot = dut.coord_i0_q;
            force dut.coord_i0_q = 32'd2;
            #0.1;
            if (dut.current_element_integrity_ok_w
                    || !dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("pair child current-integrity gate failed");
            force dut.coord_i0_q = coord_i0_snapshot;
            #0.1;
            release dut.coord_i0_q;

            rst_i = 1'b1;
            #0.1;
            if (gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("reset exposed prepared pair direct request");
            rst_i = 1'b0;
            #0.1;

            // Ready changes only fire.  Offer and the q-based payload remain
            // bit-identical with no clock edge between the two probes.
            force dut.child_req_ready_w = 1'b1;
            #0.1;
            if (!dut.pair_reuse_child_direct_offer_w
                    || !dut.pair_reuse_child_direct_fire_w
                    || !dut.child_req_valid_w || !dut.child_req_fire_w
                    || (dut.lhs_bits_q !== held_lhs)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits))
                fail_case("pair child payload depended on ready-high");
            force dut.child_req_ready_w = 1'b0;
            #0.1;
            if (!dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || !dut.child_req_valid_w || dut.child_req_fire_w
                    || (dut.lhs_bits_q !== held_lhs)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits))
                fail_case("pair child payload depended on ready-low");
            force_witness_cases = force_witness_cases + 1;

            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_CHILD_REQ)
                    || dut.pair_reuse_prepared_q
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || !dut.child_req_valid_w || dut.child_req_ready_w
                    || dut.child_req_fire_w
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || (dut.lhs_bits_q !== held_lhs)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits)
                    || (gmem_pair_reuse_elements_o
                        != (reuse_before + 64'd1))
                    || (elements_done_o != 64'd1)
                    || (child_requests_o != child_requests_before))
                fail_case("pair child fallback C1 capture/owner mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_CHILD_REQ)
                    || !dut.child_req_valid_w || dut.child_req_ready_w
                    || dut.child_req_fire_w || dut.child_outstanding_q
                    || (child_requests_o != child_requests_before)
                    || (dut.lhs_bits_q !== held_lhs)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits))
                fail_case("pair child fallback payload was not held");

            force dut.child_req_ready_w = 1'b1;
            #0.1;
            if (!dut.child_req_fire_w
                    || (dut.lhs_bits_q !== held_lhs)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits))
                fail_case("pair child fallback eventual request mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_CHILD_WAIT)
                    || dut.gmem_outstanding_q || !dut.child_outstanding_q
                    || (child_requests_o
                        != (child_requests_before + 64'd1)))
                fail_case("pair child fallback eventual owner mismatch");
            release dut.child_req_ready_w;

            // The second element is last: its child response must clear/not
            // set prepared, and its write response must never offer a child.
            wait_for_state(ST_WRITE_WAIT, "pair-child-last-write", 80);
            if (dut.select_next_element_w || dut.pair_reuse_prepared_q)
                fail_case("pair child last element retained preparation");
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_WRITE_WAIT)
                    fail_case("pair child last left WRITE_WAIT");
            end
            #0.1;
            if (!dut.gmem_rsp_fire_w
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w)
                fail_case("pair child last write exposed direct offer");

            finish_done("pair-child-fallback", 40);
            check_raw32("pair-child-fallback-0", 16'h4000, 32'h40400000);
            check_raw32("pair-child-fallback-1", 16'h4004, 32'h40400000);
            if ((elements_done_o != 64'd2)
                    || (gmem_read_beats_o != 64'd2)
                    || (gmem_pair_reuse_elements_o != 64'd1)
                    || (gmem_write_beats_o != 64'd2)
                    || (writes_accepted_o != 64'd2)
                    || (child_requests_o != 64'd2)
                    || (child_responses_o != 64'd2)
                    || dut.pair_reuse_prepared_q
                    || (arithmetic_flags_o != 5'b0))
                fail_case("pair child fallback final counters mismatch");
            gmem_pair_child_fallback_cases =
                gmem_pair_child_fallback_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("pair-child-fallback");
        end
    endtask

    task automatic run_modulo_broadcast;
        integer i0;
        integer i1;
        integer i2;
        integer q;
        reg [1:0] rhs_index;
        reg [31:0] rhs_value [0:3];
        begin
            set_default_command();
            opcode_i = OP_ADD;
            src0_region_size_i = 64'h0800;
            src0_ne0_i = 32'd4; src0_ne1_i = 32'd4;
            src0_ne2_i = 32'd2; src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd64; src0_nb3_i = 64'd128;
            src1_region_size_i = 64'h0800;
            src1_ne0_i = 32'd2; src1_ne1_i = 32'd2;
            src1_ne2_i = 32'd1; src1_ne3_i = 32'd1;
            src1_nb0_i = 64'd8; src1_nb1_i = 64'd24;
            src1_nb2_i = 64'd64; src1_nb3_i = 64'd64;
            dst_region_size_i = 64'h1000;
            dst_ne0_i = 32'd4; dst_ne1_i = 32'd4;
            dst_ne2_i = 32'd2; dst_ne3_i = 32'd1;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd16;
            dst_nb2_i = 64'd64; dst_nb3_i = 64'd128;
            rhs_value[0] = 32'h3f800000;
            rhs_value[1] = 32'h40000000;
            rhs_value[2] = 32'h40800000;
            rhs_value[3] = 32'h41000000;
            for (q = 0; q < 32; q = q + 1)
                write_raw32(16'h1000 + {q[13:0], 2'b00}, 32'h00000000);
            fill_bytes(16'h2000, 48, 8'hde);
            write_raw32(16'h2000, rhs_value[0]);
            write_raw32(16'h2008, rhs_value[1]);
            write_raw32(16'h2018, rhs_value[2]);
            write_raw32(16'h2020, rhs_value[3]);
            fill_bytes(16'h4000, 160, 8'ha5);
            launch_command();
            finish_done("modulo-broadcast", 2500);
            q = 0;
            for (i2 = 0; i2 < 2; i2 = i2 + 1) begin
                for (i1 = 0; i1 < 4; i1 = i1 + 1) begin
                    for (i0 = 0; i0 < 4; i0 = i0 + 1) begin
                        rhs_index = {i1[0], i0[0]};
                        check_raw32("modulo-broadcast",
                                    16'h4000 + {q[13:0], 2'b00},
                                    rhs_value[rhs_index]);
                        q = q + 1;
                    end
                end
            end
            if ((read_raw32(16'h2004) != 32'hdededede)
                    || (read_raw32(16'h200c) != 32'hdededede)
                    || (elements_done_o != 64'd32)
                    || (gmem_read_beats_o != 64'd64)
                    || (gmem_write_beats_o != 64'd32)
                    || (child_requests_o != 64'd32)
                    || (arithmetic_flags_o != 5'b0))
                fail_case("modulo broadcast sentinel/counters mismatch");
            broadcast_cases = broadcast_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("modulo-broadcast");
        end
    endtask

    task automatic run_transpose_like_broadcast;
        integer i0;
        integer i1;
        integer q;
        reg [31:0] expected;
        begin
            set_default_command();
            opcode_i = OP_MUL;
            src0_ne0_i = 32'd4; src0_ne1_i = 32'd4;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd64; src0_nb3_i = 64'd64;
            src1_ne0_i = 32'd1; src1_ne1_i = 32'd4;
            src1_nb0_i = 64'd16; src1_nb1_i = 64'd4;
            src1_nb2_i = 64'd32; src1_nb3_i = 64'd32;
            dst_ne0_i = 32'd4; dst_ne1_i = 32'd4;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd16;
            dst_nb2_i = 64'd64; dst_nb3_i = 64'd64;
            for (q = 0; q < 16; q = q + 1)
                write_raw32(16'h1000 + {q[13:0], 2'b00}, 32'h3f800000);
            write_raw32(16'h2000, 32'h3f800000);
            write_raw32(16'h2004, 32'h40000000);
            write_raw32(16'h2008, 32'h40800000);
            write_raw32(16'h200c, 32'h41000000);
            fill_bytes(16'h4000, 80, 8'ha5);
            launch_command();
            finish_done("transpose-like-broadcast", 1500);
            q = 0;
            for (i1 = 0; i1 < 4; i1 = i1 + 1) begin
                case (i1)
                    0: expected = 32'h3f800000;
                    1: expected = 32'h40000000;
                    2: expected = 32'h40800000;
                    default: expected = 32'h41000000;
                endcase
                for (i0 = 0; i0 < 4; i0 = i0 + 1) begin
                    check_raw32("transpose-like",
                                16'h4000 + {q[13:0], 2'b00}, expected);
                    q = q + 1;
                end
            end
            if ((elements_done_o != 64'd16)
                    || (gmem_read_beats_o != 64'd16)
                    || (gmem_pair_reuse_elements_o != 64'd8)
                    || (child_requests_o != 64'd16)
                    || (arithmetic_flags_o != 5'b0))
                fail_case("transpose-like counters mismatch");
            broadcast_cases = broadcast_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("transpose-like");
        end
    endtask

    // 2x2x2x2 procedural walker oracle。它先证明 admission 已注册首元素
    // payload、successful preflight 不再进入 ELEMENT_PREP，再逐个
    // successful write response 检查 C0 next-element lookahead 与 C1 的
    // registered SRC0 request，并覆盖 i0/i1/i2 carry 及最后一次 i3 carry。
    task automatic run_write_turnover_oracle;
        integer q;
        integer oracle_i0;
        integer oracle_i1;
        integer oracle_i2;
        integer oracle_i3;
        integer prep_entries;
        integer first_capture_samples;
        integer first_src0_req_samples;
        integer turnover_count;
        integer lookahead_wait_samples;
        integer direct_write_count;
        integer direct_child_count;
        reg [63:0] oracle_flat;
        reg [63:0] oracle_src0_addr;
        reg [63:0] oracle_src1_addr;
        reg [63:0] oracle_dst_addr;
        reg [63:0] oracle_write_addr;
        reg [63:0] oracle_write_data;
        reg [7:0] oracle_write_strb;
        reg [63:0] write_beats_before;
        reg [63:0] writes_accepted_before;
        reg [63:0] child_responses_before;
        reg [63:0] child_requests_before;
        reg [63:0] final_flat_snapshot;
        reg [31:0] final_i0_snapshot;
        reg [31:0] final_i1_snapshot;
        reg [31:0] final_i2_snapshot;
        reg [31:0] final_i3_snapshot;
        reg [63:0] final_req_addr_snapshot;
        reg        final_read_upper_snapshot;
        reg [61:0] final_src1_word_snapshot;
        reg [63:0] final_dst_addr_snapshot;
        begin
            set_default_command();
            opcode_i = OP_ADD;
            src0_region_size_i = 64'h0800;
            src0_view_off_i = 64'd4;
            src0_ne0_i = 32'd2; src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd2; src0_ne3_i = 32'd2;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd24;
            src0_nb2_i = 64'd96; src0_nb3_i = 64'd384;
            src1_region_size_i = 64'h0800;
            src1_view_off_i = 64'd0;
            src1_ne0_i = 32'd2; src1_ne1_i = 32'd2;
            src1_ne2_i = 32'd2; src1_ne3_i = 32'd2;
            src1_nb0_i = 64'd8; src1_nb1_i = 64'd32;
            src1_nb2_i = 64'd128; src1_nb3_i = 64'd512;
            dst_region_size_i = 64'h1000;
            dst_view_off_i = 64'd0;
            dst_ne0_i = 32'd2; dst_ne1_i = 32'd2;
            dst_ne2_i = 32'd2; dst_ne3_i = 32'd2;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd16; dst_nb3_i = 64'd32;
            read_response_delay_cfg = 2;
            write_response_delay_cfg = 2;
            fill_bytes(16'h4000, 80, 8'ha5);
            for (q = 0; q < 16; q = q + 1) begin
                oracle_i0 = q % 2;
                oracle_i1 = (q / 2) % 2;
                oracle_i2 = (q / 4) % 2;
                oracle_i3 = (q / 8) % 2;
                oracle_src0_addr = 64'h1004
                    + (oracle_i0 * 4) + (oracle_i1 * 24)
                    + (oracle_i2 * 96) + (oracle_i3 * 384);
                oracle_src1_addr = 64'h2000
                    + (oracle_i0 * 8) + (oracle_i1 * 32)
                    + (oracle_i2 * 128) + (oracle_i3 * 512);
                write_raw32(oracle_src0_addr[15:0], 32'h3f800000);
                write_raw32(oracle_src1_addr[15:0], 32'h3f800000);
            end

            prep_entries = 0;
            first_capture_samples = 0;
            first_src0_req_samples = 0;
            turnover_count = 0;
            lookahead_wait_samples = 0;
            direct_write_count = 0;
            direct_child_count = 0;
            launch_command();
            if ((dut.state_q != ST_PREFLIGHT) || gmem_req_valid_o
                    || dut.gmem_outstanding_q
                    || (dut.gmem_req_addr_q != 64'h1000)
                    || !dut.gmem_read_upper_q
                    || (dut.current_src1_word_q != 62'h800)
                    || (dut.current_dst_addr_q != 64'h4000))
                fail_case("first-element admission capture mismatch");
            first_capture_samples = first_capture_samples + 1;
            while (!done_o) begin
                @(negedge clk_i);
                if (error_o)
                    fail_case("turnover oracle unexpected ERROR");
                if (dut.state_q == ST_ELEMENT_PREP)
                    prep_entries = prep_entries + 1;
                if ((dut.state_q == ST_SRC0_REQ)
                        && (dut.flat_index_q == 64'b0)) begin
                    if ((dut.gmem_req_addr_q != 64'h1000)
                            || !dut.gmem_read_upper_q
                            || (dut.current_src1_word_q != 62'h800)
                            || (dut.current_dst_addr_q != 64'h4000))
                        fail_case("fused preflight first SRC0 payload mismatch");
                    if (first_src0_req_samples == 0)
                        first_src0_req_samples = first_src0_req_samples + 1;
                end

                if ((dut.state_q == ST_SRC1_WAIT)
                        && dut.gmem_rsp_fire_w) begin
                    if (gmem_rsp_error_i || dut.protocol_fault_w
                            || dut.command_timeout_hit_w
                            || dut.phase_timeout_hit_w
                            || !dut.src1_child_direct_offer_w
                            || !dut.src1_child_direct_fire_w
                            || !dut.child_req_valid_w
                            || !dut.child_req_ready_w
                            || !dut.child_req_fire_w
                            || dut.child_op_mul_w
                            || (dut.lhs_bits_q !== 32'h3f800000)
                            || (dut.child_rhs_raw_w !== 32'h3f800000)
                            || (dut.child_rhs_bits_w !== 32'h3f800000)
                            || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000)
                            || !dut.gmem_outstanding_q
                            || dut.child_outstanding_q)
                        fail_case("SRC1-child direct C0 payload/owner mismatch");
                    child_requests_before = child_requests_o;
                    @(posedge clk_i); @(negedge clk_i);
                    if ((dut.state_q != ST_CHILD_WAIT)
                            || dut.gmem_outstanding_q
                            || !dut.child_outstanding_q
                            || (dut.rhs_bits_q !== 32'h3f800000)
                            || (child_requests_o
                                != (child_requests_before + 64'd1)))
                        fail_case("SRC1-child direct C1 owner/counter mismatch");
                    direct_child_count = direct_child_count + 1;
                end

                if ((dut.state_q == ST_CHILD_WAIT)
                        && dut.child_rsp_fire_w) begin
                    oracle_flat = dut.flat_index_q;
                    oracle_dst_addr = 64'h4000 + (oracle_flat * 64'd4);
                    oracle_write_addr = {
                        oracle_dst_addr[63:3], 3'b000
                    };
                    oracle_write_data =
                        ({32'b0, 32'h40000000}
                         << {oracle_dst_addr[2:0], 3'b000});
                    oracle_write_strb = 8'h0f
                                       << oracle_dst_addr[2:0];
                    if (!dut.child_write_payload_valid_w
                            || !dut.child_write_direct_offer_w
                            || !dut.child_write_direct_fire_w
                            || !gmem_req_valid_o || !gmem_req_ready_i
                            || !dut.gmem_req_fire_w || !gmem_req_write_o
                            || (dut.child_write_addr_w
                                != oracle_write_addr)
                            || (dut.child_write_data_w
                                != oracle_write_data)
                            || (dut.child_write_strb_w
                                != oracle_write_strb)
                            || (gmem_req_addr_o != oracle_write_addr)
                            || (gmem_req_wdata_o != oracle_write_data)
                            || (gmem_req_wstrb_o != oracle_write_strb)
                            || !dut.child_outstanding_q
                            || dut.gmem_outstanding_q
                            || dut.protocol_fault_w
                            || dut.command_timeout_hit_w
                            || dut.phase_timeout_hit_w)
                        fail_case("child-write direct C0 payload/owner mismatch");
                    write_beats_before = gmem_write_beats_o;
                    writes_accepted_before = writes_accepted_o;
                    child_responses_before = child_responses_o;
                    @(posedge clk_i); @(negedge clk_i);
                    if ((dut.state_q != ST_WRITE_WAIT)
                            || dut.child_outstanding_q
                            || !dut.gmem_outstanding_q
                            || (gmem_write_beats_o
                                != (write_beats_before + 64'd1))
                            || (writes_accepted_o
                                != (writes_accepted_before + 64'd1))
                            || (child_responses_o
                                != (child_responses_before + 64'd1)))
                        fail_case("child-write direct C1 owner/counter mismatch");
                    direct_write_count = direct_write_count + 1;
                end

                if (dut.state_q == ST_WRITE_WAIT) begin
                    if (dut.flat_index_q < 64'd15) begin
                        oracle_flat = dut.flat_index_q + 64'd1;
                        oracle_i0 = oracle_flat[31:0] % 2;
                        oracle_i1 = (oracle_flat[31:0] / 2) % 2;
                        oracle_i2 = (oracle_flat[31:0] / 4) % 2;
                        oracle_i3 = (oracle_flat[31:0] / 8) % 2;
                        oracle_src0_addr = 64'h1004
                            + (oracle_i0 * 4) + (oracle_i1 * 24)
                            + (oracle_i2 * 96) + (oracle_i3 * 384);
                        oracle_src1_addr = 64'h2000
                            + (oracle_i0 * 8) + (oracle_i1 * 32)
                            + (oracle_i2 * 128) + (oracle_i3 * 512);
                        oracle_dst_addr = 64'h4000 + (oracle_flat * 4);
                        if (!dut.select_next_element_w
                                || !dut.selected_element_address_valid_w
                                || (dut.next_flat_index_w != oracle_flat)
                                || (dut.next_coord_i0_w != oracle_i0)
                                || (dut.next_coord_i1_w != oracle_i1)
                                || (dut.next_coord_i2_w != oracle_i2)
                                || (dut.next_coord_i3_w != oracle_i3)
                                || (dut.selected_flat_index_w != oracle_flat)
                                || (dut.selected_coord_i0_w != oracle_i0)
                                || (dut.selected_coord_i1_w != oracle_i1)
                                || (dut.selected_coord_i2_w != oracle_i2)
                                || (dut.selected_coord_i3_w != oracle_i3)
                                || (dut.selected_src0_addr_w
                                    != {64'b0, oracle_src0_addr})
                                || (dut.selected_src1_addr_w
                                    != {64'b0, oracle_src1_addr})
                                || (dut.selected_dst_addr_w
                                    != {64'b0, oracle_dst_addr}))
                            fail_case("turnover C0 lookahead oracle mismatch");
                        lookahead_wait_samples = lookahead_wait_samples + 1;
                    end else if (dut.select_next_element_w) begin
                        fail_case("last element incorrectly selected lookahead");
                    end

                    if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                        if (gmem_rsp_error_i || dut.command_timeout_hit_w
                                || dut.phase_timeout_hit_w
                                || dut.protocol_fault_w)
                            fail_case("turnover success edge was not clean");
                        if (dut.flat_index_q < 64'd15) begin
                            if (gmem_req_valid_o)
                                fail_case("response bypassed directly to request");
                            @(posedge clk_i); @(negedge clk_i);
                            if ((dut.state_q != ST_SRC0_REQ)
                                    || (dut.flat_index_q != oracle_flat)
                                    || (dut.coord_i0_q != oracle_i0)
                                    || (dut.coord_i1_q != oracle_i1)
                                    || (dut.coord_i2_q != oracle_i2)
                                    || (dut.coord_i3_q != oracle_i3)
                                    || (dut.gmem_req_addr_q
                                        != {oracle_src0_addr[63:3], 3'b000})
                                    || (dut.gmem_read_upper_q
                                        != oracle_src0_addr[2])
                                    || (dut.current_src1_word_q
                                        != oracle_src1_addr[63:2])
                                    || (dut.current_dst_addr_q
                                        != oracle_dst_addr)
                                    || (elements_done_o != oracle_flat))
                                fail_case("turnover C1 registered payload mismatch");
                            turnover_count = turnover_count + 1;
                        end else begin
                            final_flat_snapshot = dut.flat_index_q;
                            final_i0_snapshot = dut.coord_i0_q;
                            final_i1_snapshot = dut.coord_i1_q;
                            final_i2_snapshot = dut.coord_i2_q;
                            final_i3_snapshot = dut.coord_i3_q;
                            final_req_addr_snapshot = dut.gmem_req_addr_q;
                            final_read_upper_snapshot = dut.gmem_read_upper_q;
                            final_src1_word_snapshot = dut.current_src1_word_q;
                            final_dst_addr_snapshot = dut.current_dst_addr_q;
                            @(posedge clk_i); @(negedge clk_i);
                            if (!done_o || error_o
                                    || (dut.flat_index_q
                                        != final_flat_snapshot)
                                    || (dut.coord_i0_q != final_i0_snapshot)
                                    || (dut.coord_i1_q != final_i1_snapshot)
                                    || (dut.coord_i2_q != final_i2_snapshot)
                                    || (dut.coord_i3_q != final_i3_snapshot)
                                    || (dut.gmem_req_addr_q
                                        != final_req_addr_snapshot)
                                    || (dut.gmem_read_upper_q
                                        != final_read_upper_snapshot)
                                    || (dut.current_src1_word_q
                                        != final_src1_word_snapshot)
                                    || (dut.current_dst_addr_q
                                        != final_dst_addr_snapshot)
                                    || (elements_done_o != 64'd16))
                                fail_case("last response advanced lookahead payload");
                        end
                    end
                end
            end

            if ((prep_entries != 0) || (first_capture_samples != 1)
                    || (first_src0_req_samples != 1)
                    || (turnover_count != 15)
                    || (lookahead_wait_samples < 15)
                    || (direct_write_count != 16)
                    || (direct_child_count != 16))
                fail_case("fused-preflight/turnover/direct cardinality mismatch");
            finish_done("write-turnover-oracle", 20);
            for (q = 0; q < 16; q = q + 1)
                check_raw32("write-turnover-oracle",
                            16'h4000 + {q[13:0], 2'b00}, 32'h40000000);
            if ((gmem_read_beats_o != 64'd32)
                    || (gmem_pair_reuse_elements_o != 64'b0)
                    || (gmem_write_beats_o != 64'd16)
                    || (writes_accepted_o != 64'd16)
                    || (child_requests_o != 64'd16)
                    || (child_responses_o != 64'd16)
                    || (arithmetic_flags_o != 5'b0))
                fail_case("turnover command counters/flags mismatch");
            lookahead_turnover_cases = lookahead_turnover_cases + 1;
            child_write_direct_cases = child_write_direct_cases + 1;
            src1_child_direct_cases = src1_child_direct_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("write-turnover-oracle");
        end
    endtask

    // successful child response 在 GMEM ready-low 时仍被消费，并把同一
    // shadow-write payload 捕获到既有 q；registered fallback 只接受一次。
    task automatic run_child_write_fallback_oracle;
        integer hold_cycle;
        integer accepted_writes_before;
        reg [63:0] write_beats_before;
        reg [63:0] writes_accepted_before;
        reg [63:0] child_responses_before;
        reg [63:0] expected_addr;
        reg [63:0] expected_data;
        reg [7:0] expected_strb;
        reg [31:0] command_cycles_before;
        begin
            prepare_fault_command();
            write_raw32(16'h2000, 32'h3f800000);
            launch_command();
            wait_for_state(ST_CHILD_WAIT, "child-write-fallback", 100);
            allow_requests_q = 1'b0;
            force_ready_now_q = 1'b0;
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("fallback left CHILD_WAIT before response");
            end
            #0.1;
            expected_addr = 64'h4000;
            expected_data = 64'h0000000040000000;
            expected_strb = 8'h0f;
            if (!dut.child_rsp_fire_w || !dut.child_write_payload_valid_w
                    || !dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || !gmem_req_valid_o || gmem_req_ready_i
                    || dut.gmem_req_fire_w || !gmem_req_write_o
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb)
                    || (dut.child_write_addr_w != expected_addr)
                    || (dut.child_write_data_w != expected_data)
                    || (dut.child_write_strb_w != expected_strb)
                    || !dut.child_outstanding_q
                    || dut.gmem_outstanding_q)
                fail_case("fallback C0 ready-low payload mismatch");

            // command timeout 与 protocol fault 都必须压过同拍 normal response。
            command_cycles_before = dut.command_cycles_q;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            #0.1;
            if (!dut.command_timeout_hit_w || !dut.child_rsp_fire_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("command deadline exposed direct child write");
            force dut.command_cycles_q = command_cycles_before;
            #0.1;
            if (!dut.child_write_direct_offer_w || gmem_req_ready_i
                    || !gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("direct offer did not recover after deadline probe");
            release dut.command_cycles_q;

            force gmem_rsp_valid_i = 1'b1;
            #0.1;
            if (!dut.protocol_fault_w || dut.child_rsp_ready_w
                    || dut.child_rsp_fire_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("protocol fault consumed child response or exposed write");
            force gmem_rsp_valid_i = 1'b0;
            #0.1;
            if (!dut.child_write_direct_offer_w || gmem_req_ready_i
                    || !gmem_req_valid_o || dut.gmem_req_fire_w
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb))
                fail_case("direct payload did not recover after fault probe");
            release gmem_rsp_valid_i;

            // ready 只控制 fire，不得反向影响 valid/payload；不跨时钟翻转。
            allow_requests_q = 1'b1;
            force_ready_now_q = 1'b1;
            #0.1;
            if (!gmem_req_ready_i || !dut.child_write_direct_offer_w
                    || !dut.child_write_direct_fire_w
                    || !dut.gmem_req_fire_w
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb))
                fail_case("direct payload depended on ready-high probe");
            allow_requests_q = 1'b0;
            force_ready_now_q = 1'b0;
            #0.1;
            if (gmem_req_ready_i || !dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || !gmem_req_valid_o || dut.gmem_req_fire_w
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb))
                fail_case("direct payload depended on ready-low probe");

            write_beats_before = gmem_write_beats_o;
            writes_accepted_before = writes_accepted_o;
            child_responses_before = child_responses_o;
            accepted_writes_before = accepted_write_count;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_WRITE_REQ)
                    || dut.child_outstanding_q
                    || dut.gmem_outstanding_q
                    || (child_responses_o
                        != (child_responses_before + 64'd1))
                    || (gmem_write_beats_o != write_beats_before)
                    || (writes_accepted_o != writes_accepted_before)
                    || (accepted_write_count != accepted_writes_before)
                    || !dut.registered_write_payload_valid_w
                    || !gmem_req_valid_o || gmem_req_ready_i
                    || dut.gmem_req_fire_w || !gmem_req_write_o
                    || (dut.gmem_req_addr_q != expected_addr)
                    || (dut.gmem_req_wdata_q != expected_data)
                    || (dut.gmem_req_wstrb_q != expected_strb)
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb))
                fail_case("fallback C1 registered payload/counter mismatch");

            for (hold_cycle = 0; hold_cycle < 3;
                    hold_cycle = hold_cycle + 1) begin
                @(posedge clk_i); @(negedge clk_i);
                if ((dut.state_q != ST_WRITE_REQ)
                        || !gmem_req_valid_o || gmem_req_ready_i
                        || dut.gmem_req_fire_w
                        || (gmem_req_addr_o != expected_addr)
                        || (gmem_req_wdata_o != expected_data)
                        || (gmem_req_wstrb_o != expected_strb)
                        || (gmem_write_beats_o != write_beats_before)
                        || (writes_accepted_o != writes_accepted_before)
                        || (accepted_write_count != accepted_writes_before))
                    fail_case("fallback payload changed/repeated under stall");
            end

            allow_requests_q = 1'b1;
            force_ready_now_q = 1'b1;
            #1;
            if (!gmem_req_ready_i || !dut.gmem_req_fire_w
                    || !gmem_req_valid_o || !gmem_req_write_o
                    || (gmem_req_addr_o != expected_addr)
                    || (gmem_req_wdata_o != expected_data)
                    || (gmem_req_wstrb_o != expected_strb))
                fail_case("fallback accepted payload mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_WRITE_WAIT)
                    || dut.child_outstanding_q
                    || !dut.gmem_outstanding_q
                    || (gmem_write_beats_o
                        != (write_beats_before + 64'd1))
                    || (writes_accepted_o
                        != (writes_accepted_before + 64'd1))
                    || (accepted_write_count
                        != (accepted_writes_before + 1)))
                fail_case("fallback owner/counter transfer mismatch");

            finish_done("child-write-fallback", 100);
            check_raw32("child-write-fallback", 16'h4000,
                        32'h40000000);
            if ((elements_done_o != 64'd1)
                    || (gmem_read_beats_o != 64'd2)
                    || (gmem_write_beats_o != 64'd1)
                    || (writes_accepted_o != 64'd1)
                    || (child_requests_o != 64'd1)
                    || (child_responses_o != 64'd1)
                    || (arithmetic_flags_o != 5'b0))
                fail_case("fallback terminal counters/flags mismatch");
            child_write_fallback_cases = child_write_fallback_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("child-write-fallback");
        end
    endtask

    // Direct child-result writes must remain fail-closed for malformed write
    // payloads, and command timeout must stay above phase timeout when both
    // collide with an otherwise-successful held child response.
    task automatic run_child_write_fail_closed_oracles;
        reg [31:0] command_cycles_snapshot;
        reg [31:0] stall_cycles_snapshot;
        reg [63:0] child_responses_snapshot;
        integer child_model_responses_snapshot;
        integer accepted_writes_snapshot;
        begin
            // Hold a successful child response, corrupt only the resident
            // destination lane, and prove neither the direct nor registered
            // write path can expose a malformed request.
            prepare_fault_command();
            launch_command();
            wait_for_state(ST_CHILD_WAIT, "child-write-invalid", 100);
            force dut.child_rsp_ready_w = 1'b0;
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("invalid write left CHILD_WAIT before response");
            end
            child_responses_snapshot = child_responses_o;
            child_model_responses_snapshot = child_response_count;
            accepted_writes_snapshot = accepted_write_count;
            force dut.current_dst_addr_q = 64'h0000_0000_0000_4002;
            release dut.child_rsp_ready_w;
            #0.1;
            if (!dut.child_rsp_fire_w || dut.protocol_fault_w
                    || dut.command_timeout_hit_w || dut.phase_timeout_hit_w
                    || dut.child_write_payload_valid_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || !dut.child_outstanding_q
                    || dut.gmem_outstanding_q)
                fail_case("invalid child write escaped direct fail-closed gate");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_WRITE_REQ)
                    || dut.child_outstanding_q || dut.gmem_outstanding_q
                    || dut.registered_write_payload_valid_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || (child_responses_o
                        != (child_responses_snapshot + 64'd1))
                    || (child_response_count
                        != (child_model_responses_snapshot + 1))
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (accepted_write_count != accepted_writes_snapshot))
                fail_case("invalid child write fallback payload/credit mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (error_code_o != ERR_INTERNAL_STATE)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || (child_responses_o
                        != (child_responses_snapshot + 64'd1))
                    || (child_response_count
                        != (child_model_responses_snapshot + 1))
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (accepted_write_count != accepted_writes_snapshot)
                    || (elements_done_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("invalid child write did not terminate without side effect");
            release dut.current_dst_addr_q;
            finish_error("child-write-invalid", ERR_INTERNAL_STATE, 20);
            child_write_invalid_cases = child_write_invalid_cases + 1;

            // With protocol clear, both watchdogs and a normal held response
            // collide on one edge.  Command timeout wins, consumes the child
            // credit once, and cannot create a GMEM owner or write request.
            prepare_fault_command();
            launch_command();
            wait_for_state(ST_CHILD_WAIT, "child-deadline-priority", 100);
            force dut.child_rsp_ready_w = 1'b0;
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("deadline priority lost held child response");
            end
            command_cycles_snapshot = dut.command_cycles_q;
            stall_cycles_snapshot = dut.stall_cycles_q;
            child_responses_snapshot = child_responses_o;
            child_model_responses_snapshot = child_response_count;
            accepted_writes_snapshot = accepted_write_count;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            force dut.stall_cycles_q = CHILD_TIMEOUT_LAST;
            release dut.child_rsp_ready_w;
            #0.1;
            if (dut.protocol_fault_w || !dut.command_timeout_hit_w
                    || !dut.phase_timeout_hit_w || !dut.child_rsp_fire_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || !dut.child_outstanding_q
                    || dut.gmem_outstanding_q)
                fail_case("command/phase priority response witness mismatch");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (error_code_o != ERR_COMMAND_TIMEOUT)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || (child_responses_o
                        != (child_responses_snapshot + 64'd1))
                    || (child_response_count
                        != (child_model_responses_snapshot + 1))
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (accepted_write_count != accepted_writes_snapshot)
                    || (elements_done_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("command timeout lost phase/response priority");
            force dut.command_cycles_q = command_cycles_snapshot;
            force dut.stall_cycles_q = stall_cycles_snapshot;
            #0.1;
            release dut.command_cycles_q;
            release dut.stall_cycles_q;
            finish_error("child-deadline-priority", ERR_COMMAND_TIMEOUT, 20);
            child_deadline_priority_cases = child_deadline_priority_cases + 1;
            check_root_canary("child-write-fail-closed");
        end
    endtask

    task automatic run_empty_scale;
        integer accepted_before;
        integer child_before;
        begin
            set_default_command();
            opcode_i = OP_SCALE;
            op_params_i = 64'b0;
            src0_region_base_i = 64'b0; src0_region_size_i = 64'b0;
            src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd0; src0_ne1_i = 32'd1;
            src0_ne2_i = 32'd1; src0_ne3_i = 32'd1;
            src0_nb0_i = 64'b0; src0_nb1_i = 64'b0;
            src0_nb2_i = 64'b0; src0_nb3_i = 64'b0;
            src1_region_base_i = 64'b0; src1_region_size_i = 64'b0;
            src1_ne0_i = 32'b0; src1_ne1_i = 32'b0;
            src1_ne2_i = 32'b0; src1_ne3_i = 32'b0;
            src1_nb0_i = 64'b0; src1_nb1_i = 64'b0;
            src1_nb2_i = 64'b0; src1_nb3_i = 64'b0;
            dst_region_base_i = 64'b0; dst_region_size_i = 64'b0;
            dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd0; dst_ne1_i = 32'd1;
            dst_ne2_i = 32'd1; dst_ne3_i = 32'd1;
            dst_nb0_i = 64'b0; dst_nb1_i = 64'b0;
            dst_nb2_i = 64'b0; dst_nb3_i = 64'b0;
            accepted_before = accepted_request_count;
            child_before = child_accepted_count;
            launch_command();
            finish_done("empty-scale", 30);
            if ((accepted_request_count != accepted_before)
                    || (child_accepted_count != child_before)
                    || (elements_done_o != 64'b0)
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (arithmetic_flags_o != 5'b0))
                fail_case("empty SCALE was not zero-access retirement");
            positive_cases = positive_cases + 1;
            check_root_canary("empty-scale");
        end
    endtask

    task automatic run_preflight_matrix;
        begin
            set_default_command(); opcode_i = 3'd4;
            expect_preflight("bad-opcode", ERR_HEADER_PROFILE);
            set_default_command(); dtype_i = 2'd1;
            expect_preflight("bad-dtype", ERR_HEADER_PROFILE);
            set_default_command(); profile_i = 4'd1;
            expect_preflight("bad-profile", ERR_HEADER_PROFILE);
            set_default_command(); reserved_i = 32'd1;
            expect_preflight("bad-reserved", ERR_HEADER_PROFILE);
            set_default_command(); op_params_i = 64'd1;
            expect_preflight("binary-op-params", ERR_HEADER_PROFILE);
            set_default_command(); opcode_i = OP_SCALE; op_params_i = 64'h1_00000000;
            expect_preflight("scale-bias", ERR_HEADER_PROFILE);
            set_default_command(); src0_ne0_i = 32'd3; dst_ne0_i = 32'd3;
            dst_nb1_i = 64'd12; dst_nb2_i = 64'd12; dst_nb3_i = 64'd12;
            src1_ne0_i = 32'd2;
            expect_preflight("nondivisible", ERR_SHAPE_BROADCAST);
            set_default_command(); dst_ne0_i = 32'd2; dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd8; dst_nb3_i = 64'd8;
            expect_preflight("dst-shape", ERR_SHAPE_BROADCAST);
            set_default_command(); src0_ne0_i = 32'd0; dst_ne0_i = 32'd0;
            expect_preflight("binary-empty", ERR_SHAPE_BROADCAST);
            set_default_command(); opcode_i = OP_SCALE; op_params_i = 64'd1;
            src0_ne0_i = 32'd0; dst_ne0_i = 32'd0;
            expect_preflight("empty-scale-nonzero", ERR_SHAPE_BROADCAST);
            set_default_command(); src0_ne0_i = 32'd262145;
            dst_ne0_i = 32'd262145; dst_nb1_i = 64'd1048580;
            dst_nb2_i = 64'd1048580; dst_nb3_i = 64'd1048580;
            expect_preflight("element-limit", ERR_SHAPE_BROADCAST);
            set_default_command(); src0_nb0_i = 64'd6;
            expect_preflight("src0-stride", ERR_STRIDE_ALIGNMENT);
            set_default_command(); src1_nb0_i = 64'd6;
            expect_preflight("src1-stride", ERR_STRIDE_ALIGNMENT);
            set_default_command(); dst_nb0_i = 64'd8;
            expect_preflight("dst-contiguous", ERR_STRIDE_ALIGNMENT);
            set_default_command(); src0_region_base_i = 64'h1002;
            expect_preflight("src0-misalign", ERR_STRIDE_ALIGNMENT);
            set_default_command(); src0_region_base_i = 64'h1004;
            src0_region_size_i = 64'd4;
            expect_preflight("src0-beat-overfetch", ERR_SOURCE_BOUNDS);
            set_default_command(); src1_region_size_i = 64'd3;
            expect_preflight("src1-bounds", ERR_SOURCE_BOUNDS);
            set_default_command(); src0_region_base_i = 64'hffff_ffff_ffff_fff8;
            src0_region_size_i = 64'd16; gmem_limit_i = 64'hffff_ffff_ffff_ffff;
            expect_preflight("src0-overflow", ERR_SOURCE_BOUNDS);
            set_default_command(); gmem_floor_i = 64'h1004;
            expect_preflight("source-window", ERR_SOURCE_BOUNDS);
            set_default_command(); dst_region_size_i = 64'd3;
            expect_preflight("dst-bounds", ERR_DEST_BOUNDS);
            set_default_command(); dst_region_base_i = 64'h4004;
            dst_region_size_i = 64'd4;
            expect_preflight("dst-beat-overfetch", ERR_DEST_BOUNDS);
            set_default_command(); dst_region_base_i = 64'hffff_ffff_ffff_fff8;
            dst_region_size_i = 64'd16; gmem_limit_i = 64'hffff_ffff_ffff_ffff;
            expect_preflight("dst-overflow", ERR_DEST_BOUNDS);
            set_default_command(); gmem_limit_i = 64'h4004;
            expect_preflight("dst-window", ERR_DEST_BOUNDS);
            set_default_command(); dst_region_base_i = 64'h1000;
            expect_preflight("src0-overlap", ERR_OVERLAP);
            set_default_command(); dst_region_base_i = 64'h2000;
            expect_preflight("src1-overlap", ERR_OVERLAP);
        end
    endtask

    task automatic prepare_fault_command;
        begin
            set_default_command();
            write_raw32(16'h1000, 32'h3f800000);
            write_raw32(16'h2000, 32'h40000000);
            fill_bytes(16'h4000, 8, 8'ha5);
        end
    endtask

    task automatic prepare_two_element_fault_command;
        begin
            prepare_fault_command();
            src0_ne0_i = 32'd2;
            src0_nb1_i = 64'd8;
            src0_nb2_i = 64'd8;
            src0_nb3_i = 64'd8;
            src1_ne0_i = 32'd2;
            src1_nb1_i = 64'd8;
            src1_nb2_i = 64'd8;
            src1_nb3_i = 64'd8;
            dst_ne0_i = 32'd2;
            dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd8;
            dst_nb3_i = 64'd8;
            write_raw32(16'h1004, 32'h40000000);
            write_raw32(16'h2004, 32'h3f800000);
            fill_bytes(16'h4000, 16, 8'ha5);
        end
    endtask

    task automatic run_gmem_response_faults;
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [31:0] i1_snapshot;
        reg [31:0] i2_snapshot;
        reg [31:0] i3_snapshot;
        reg [63:0] req_addr_snapshot;
        reg read_upper_snapshot;
        reg [61:0] src1_word_snapshot;
        reg [63:0] dst_addr_snapshot;
        begin
            prepare_fault_command(); inject_error_state_q = ST_SRC0_REQ;
            launch_command();
            wait_for_state(ST_SRC0_WAIT, "src0-response-error", 100);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC0_WAIT)
                    fail_case("src0 error left WAIT before response");
            end
            #0.1;
            if (!gmem_rsp_error_i || !dut.gmem_rsp_fire_w
                    || dut.src0_beat_valid_q || dut.src1_beat_valid_q)
                fail_case("src0 response error cache precondition mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR) || dut.src0_beat_valid_q
                    || dut.src1_beat_valid_q)
                fail_case("src0 response error filled source cache");
            finish_error("src0-response-error", ERR_GMEM_RESPONSE, 20);
            if ((gmem_read_beats_o != 64'd1) || (child_requests_o != 64'b0))
                fail_case("src0 response error counters");
            gmem_fault_cases = gmem_fault_cases + 1;

            prepare_fault_command(); inject_error_state_q = ST_SRC1_REQ;
            launch_command();
            wait_for_state(ST_SRC1_WAIT, "src1-response-error", 100);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC1_WAIT)
                    fail_case("src1 error left WAIT before response");
            end
            #0.1;
            if (!gmem_rsp_error_i || !gmem_rsp_ready_o
                    || !dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w
                    || !dut.gmem_outstanding_q
                    || dut.child_outstanding_q
                    || !dut.src0_beat_valid_q || dut.src1_beat_valid_q)
                fail_case("src1 response error exposed direct child request");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR) || !dut.src0_beat_valid_q
                    || dut.src1_beat_valid_q)
                fail_case("src1 response error filled source cache");
            finish_error("src1-response-error", ERR_GMEM_RESPONSE, 120);
            if ((gmem_read_beats_o != 64'd2) || (child_requests_o != 64'b0))
                fail_case("src1 response error counters");
            gmem_fault_cases = gmem_fault_cases + 1;

            prepare_two_element_fault_command();
            inject_error_state_q = ST_WRITE_REQ;
            launch_command();
            wait_for_state(ST_WRITE_WAIT, "write-response-error", 160);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_WRITE_WAIT)
                    fail_case("write response error left WAIT before response");
            end
            #1;
            if (!gmem_rsp_ready_o || !dut.gmem_rsp_fire_w
                    || !gmem_rsp_error_i || !dut.select_next_element_w
                    || !dut.selected_element_address_valid_w
                    || !dut.gmem_pair_reuse_hit_w
                    || !dut.pair_reuse_prepared_q
                    || dut.pair_reuse_child_direct_offer_w
                    || dut.pair_reuse_child_direct_fire_w
                    || (dut.next_flat_index_w != 64'd1))
                fail_case("write response error lookahead witness mismatch");
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            req_addr_snapshot = dut.gmem_req_addr_q;
            read_upper_snapshot = dut.gmem_read_upper_q;
            src1_word_snapshot = dut.current_src1_word_q;
            dst_addr_snapshot = dut.current_dst_addr_q;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (dut.error_code_q != ERR_GMEM_RESPONSE)
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (dut.gmem_req_addr_q != req_addr_snapshot)
                    || (dut.gmem_read_upper_q != read_upper_snapshot)
                    || (dut.current_src1_word_q != src1_word_snapshot)
                    || (dut.current_dst_addr_q != dst_addr_snapshot)
                    || (gmem_pair_reuse_elements_o != 64'b0)
                    || dut.pair_reuse_prepared_q
                    || dut.child_req_valid_w || dut.child_req_fire_w
                    || (elements_done_o != 64'b0))
                fail_case("write response error committed lookahead state");
            finish_error("write-response-error", ERR_GMEM_RESPONSE, 20);
            if ((gmem_write_beats_o != 64'd1) || (writes_accepted_o != 64'd1)
                    || (elements_done_o != 64'b0) || (child_requests_o != 64'd1))
                fail_case("write response error counters");
            gmem_fault_cases = gmem_fault_cases + 1;
            check_root_canary("gmem-response-faults");
            run_scalar("gmem-fault-clean-retry", OP_ADD, 32'h3f800000,
                       32'h40000000, 32'h40400000, 5'b0, 1);
        end
    endtask

    task automatic finish_gmem_drain(input string name,
                                     input logic [4:0] expected_code,
                                     input integer max_cycles);
        integer cycles;
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [4:0] flags_snapshot;
        reg [63:0] elements_snapshot;
        reg [63:0] active_snapshot;
        reg [31:0] command_snapshot;
        begin
            if (dut.state_q != ST_DRAIN)
                fail_case({name, " did not enter DRAIN"});
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            active_snapshot = active_cycles_o;
            command_snapshot = dut.command_cycles_q;
            cycles = 0;
            while (!error_o) begin
                if ((dut.state_q != ST_DRAIN)
                        || (dut.flat_index_q != flat_snapshot)
                        || (dut.coord_i0_q != i0_snapshot)
                        || (arithmetic_flags_o != flags_snapshot)
                        || (elements_done_o != elements_snapshot)
                        || (active_cycles_o != active_snapshot)
                        || (dut.command_cycles_q != command_snapshot)
                        || gmem_req_valid_o)
                    fail_case({name, " DRAIN state changed result/eligibility"});
                @(posedge clk_i); @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case({name, " DRAIN response timeout"});
            end
            if ((error_code_o != expected_code) || (arithmetic_flags_o != 5'b0))
                fail_case({name, " drain terminal mismatch"});
            @(posedge clk_i); @(negedge clk_i);
            if (!ready_o || busy_o || error_o || pending_q || (outstanding_count != 0))
                fail_case({name, " drain did not recover cleanly"});
            gmem_drain_cases = gmem_drain_cases + 1;
        end
    endtask

    task automatic force_wait_timeout(input string name,
                                      input logic [4:0] wait_state,
                                      input logic [4:0] expected_code,
                                      input integer use_command_timeout);
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [31:0] i1_snapshot;
        reg [31:0] i2_snapshot;
        reg [31:0] i3_snapshot;
        reg [4:0] flags_snapshot;
        reg [63:0] elements_snapshot;
        reg [63:0] reads_snapshot;
        reg [63:0] writes_snapshot;
        reg [63:0] accepted_writes_snapshot;
        reg [63:0] child_requests_snapshot;
        reg [63:0] child_responses_snapshot;
        reg [31:0] shadow_snapshot;
        reg [63:0] req_addr_snapshot;
        reg read_upper_snapshot;
        reg [61:0] src1_word_snapshot;
        reg [63:0] dst_addr_snapshot;
        begin
            wait_for_state(wait_state, name, 200);
            if ((outstanding_count != 1) || !dut.gmem_outstanding_q
                    || !dut.gmem_owner_expected_w)
                fail_case({name, " missing accepted GMEM owner"});
            if ((wait_state == ST_WRITE_WAIT)
                    && (!dut.select_next_element_w
                        || !dut.selected_element_address_valid_w
                        || !dut.pair_reuse_prepared_q
                        || (dut.next_flat_index_w != 64'd1)))
                fail_case({name, " missing write lookahead witness"});
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            accepted_writes_snapshot = writes_accepted_o;
            child_requests_snapshot = child_requests_o;
            child_responses_snapshot = child_responses_o;
            shadow_snapshot = read_raw32(16'h4000);
            req_addr_snapshot = dut.gmem_req_addr_q;
            read_upper_snapshot = dut.gmem_read_upper_q;
            src1_word_snapshot = dut.current_src1_word_q;
            dst_addr_snapshot = dut.current_dst_addr_q;
            if (use_command_timeout != 0)
                force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            else
                force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            #1;
            if ((use_command_timeout != 0)
                    && !dut.command_timeout_hit_w)
                fail_case({name, " command-timeout predicate not witnessed"});
            if ((use_command_timeout == 0)
                    && !dut.phase_timeout_hit_w)
                fail_case({name, " phase-timeout predicate not witnessed"});
            if (!gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || dut.protocol_fault_w)
                fail_case({name, " timeout credit/predicate witness mismatch"});
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_GMEM)
                    || (dut.drain_error_code_q != expected_code)
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || error_o || gmem_req_valid_o
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != flags_snapshot)
                    || (elements_done_o != elements_snapshot)
                    || (gmem_read_beats_o != reads_snapshot)
                    || (gmem_write_beats_o != writes_snapshot)
                    || (writes_accepted_o != accepted_writes_snapshot)
                    || (child_requests_o != child_requests_snapshot)
                    || (child_responses_o != child_responses_snapshot)
                    || (dut.gmem_req_addr_q != req_addr_snapshot)
                    || (dut.gmem_read_upper_q != read_upper_snapshot)
                    || (dut.current_src1_word_q != src1_word_snapshot)
                    || (dut.current_dst_addr_q != dst_addr_snapshot)
                    || dut.pair_reuse_prepared_q
                    || (read_raw32(16'h4000) != shadow_snapshot))
                fail_case({name, " post-edge drain/quarantine mismatch"});
            if (use_command_timeout != 0)
                release dut.command_cycles_q;
            else
                release dut.stall_cycles_q;
            finish_gmem_drain(name, expected_code, 100);
        end
    endtask

    task automatic run_gmem_timeout_matrix;
        integer accepted_before;
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [31:0] i1_snapshot;
        reg [31:0] i2_snapshot;
        reg [31:0] i3_snapshot;
        reg [4:0] flags_snapshot;
        reg [63:0] elements_snapshot;
        reg [63:0] reads_snapshot;
        reg [63:0] writes_snapshot;
        reg [63:0] accepted_writes_snapshot;
        reg [63:0] child_requests_snapshot;
        reg [63:0] child_responses_snapshot;
        reg [31:0] shadow_snapshot;
        begin
            prepare_fault_command(); allow_requests_q = 1'b0;
            launch_command(); wait_for_state(ST_SRC0_REQ, "REQ-stall", 30);
            accepted_before = accepted_request_count;
            force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            allow_requests_q = 1'b1; force_ready_now_q = 1'b1;
            #1;
            if (!dut.phase_timeout_hit_w || dut.command_timeout_hit_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || dut.gmem_outstanding_q || dut.protocol_fault_w)
                fail_case("REQ-stall production witness mismatch");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (dut.error_code_q != ERR_STALL_TIMEOUT)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (elements_done_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("REQ-stall post-edge quarantine mismatch");
            release dut.stall_cycles_q;
            finish_error("REQ-stall", ERR_STALL_TIMEOUT, 20);
            if (accepted_request_count != accepted_before)
                fail_case("REQ stall deadline lost to same-cycle ready");
            gmem_fault_cases = gmem_fault_cases + 1;

            prepare_fault_command(); allow_requests_q = 1'b0;
            launch_command(); wait_for_state(ST_SRC0_REQ, "REQ-command", 30);
            accepted_before = accepted_request_count;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            allow_requests_q = 1'b1; force_ready_now_q = 1'b1;
            #1;
            if (!dut.command_timeout_hit_w || gmem_req_valid_o
                    || dut.gmem_req_fire_w || dut.gmem_outstanding_q
                    || dut.protocol_fault_w)
                fail_case("REQ-command production witness mismatch");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (dut.error_code_q != ERR_COMMAND_TIMEOUT)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (elements_done_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("REQ-command post-edge quarantine mismatch");
            release dut.command_cycles_q;
            finish_error("REQ-command", ERR_COMMAND_TIMEOUT, 20);
            if (accepted_request_count != accepted_before)
                fail_case("REQ command deadline lost to same-cycle ready");
            gmem_fault_cases = gmem_fault_cases + 1;

            prepare_fault_command(); read_response_delay_cfg = 20;
            launch_command();
            force_wait_timeout("read-stall-drain", ST_SRC0_WAIT,
                               ERR_STALL_TIMEOUT, 0);

            prepare_fault_command(); read_response_delay_cfg = 20;
            launch_command();
            force_wait_timeout("read-command-drain", ST_SRC0_WAIT,
                               ERR_COMMAND_TIMEOUT, 1);

            prepare_two_element_fault_command(); read_response_delay_cfg = 1;
            write_response_delay_cfg = 20;
            launch_command();
            force_wait_timeout("write-stall-drain", ST_WRITE_WAIT,
                               ERR_STALL_TIMEOUT, 0);

            prepare_fault_command(); read_response_delay_cfg = 20;
            inject_error_state_q = ST_SRC0_REQ;
            launch_command();
            wait_for_state(ST_SRC0_WAIT, "late-error", 40);
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            accepted_writes_snapshot = writes_accepted_o;
            child_requests_snapshot = child_requests_o;
            child_responses_snapshot = child_responses_o;
            shadow_snapshot = read_raw32(16'h4000);
            force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            #1;
            if (!dut.phase_timeout_hit_w || !dut.gmem_owner_expected_w
                    || !gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || gmem_rsp_valid_i || dut.protocol_fault_w)
                fail_case("late-error production witness mismatch");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_GMEM)
                    || (dut.drain_error_code_q != ERR_STALL_TIMEOUT)
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || error_o || gmem_req_valid_o
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != flags_snapshot)
                    || (elements_done_o != elements_snapshot)
                    || (gmem_read_beats_o != reads_snapshot)
                    || (gmem_write_beats_o != writes_snapshot)
                    || (writes_accepted_o != accepted_writes_snapshot)
                    || (child_requests_o != child_requests_snapshot)
                    || (child_responses_o != child_responses_snapshot)
                    || (read_raw32(16'h4000) != shadow_snapshot))
                fail_case("late-error post-edge drain/quarantine mismatch");
            release dut.stall_cycles_q;
            finish_gmem_drain("late-error", ERR_GMEM_RESPONSE, 100);

            check_root_canary("gmem-timeouts");
            run_scalar("gmem-drain-clean-retry", OP_MUL, 32'h3f800000,
                       32'h40000000, 32'h40000000, 5'b0, 1);
        end
    endtask

    task automatic run_child_backpressure;
        reg [31:0] held_result;
        reg [4:0] held_flags;
        reg [31:0] held_rhs_raw;
        reg [31:0] held_rhs_bits;
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [31:0] i1_snapshot;
        reg [31:0] i2_snapshot;
        reg [31:0] i3_snapshot;
        reg [63:0] child_requests_snapshot;
        reg [63:0] child_responses_snapshot;
        reg [31:0] command_cycles_snapshot;
        reg [31:0] stall_cycles_snapshot;
        begin
            prepare_fault_command();
            opcode_i = OP_SUB;
            launch_command();
            wait_for_state(ST_SRC1_WAIT, "child-req-backpressure", 100);
            force dut.child_req_ready_w = 1'b0;
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC1_WAIT)
                    fail_case("child fallback left SRC1_WAIT before response");
            end
            #0.1;
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            child_requests_snapshot = child_requests_o;
            held_rhs_raw = dut.child_rhs_raw_w;
            held_rhs_bits = dut.child_rhs_bits_w;
            if (!gmem_rsp_ready_o || !dut.gmem_rsp_fire_w
                    || gmem_rsp_error_i || dut.protocol_fault_w
                    || dut.command_timeout_hit_w
                    || dut.phase_timeout_hit_w
                    || !dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || !dut.child_req_valid_w || dut.child_req_ready_w
                    || dut.child_req_fire_w || dut.child_outstanding_q
                    || !dut.gmem_outstanding_q
                    || dut.child_op_mul_w
                    || (dut.lhs_bits_q !== 32'h3f800000)
                    || (held_rhs_raw !== 32'h40000000)
                    || (held_rhs_bits !== 32'hc0000000)
                    || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000))
                fail_case("child elastic fallback C0 mismatch");

            // Error/watchdog/protocol/reset all suppress the direct offer on
            // this same held response.  Restore forced procedural regs to
            // their snapshots before release so no probe crosses an edge.
            force gmem_rsp_error_i = 1'b1;
            #0.1;
            if (!dut.gmem_rsp_fire_w || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("SRC1 response error exposed direct child request");
            force gmem_rsp_error_i = 1'b0;
            #0.1;
            release gmem_rsp_error_i;

            command_cycles_snapshot = dut.command_cycles_q;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            #0.1;
            if (!dut.command_timeout_hit_w || !dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("SRC1 command deadline exposed direct child request");
            force dut.command_cycles_q = command_cycles_snapshot;
            #0.1;
            release dut.command_cycles_q;

            stall_cycles_snapshot = dut.stall_cycles_q;
            force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            #0.1;
            if (!dut.phase_timeout_hit_w || !dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("SRC1 phase deadline exposed direct child request");
            force dut.stall_cycles_q = stall_cycles_snapshot;
            #0.1;
            release dut.stall_cycles_q;

            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            #0.1;
            if (!dut.protocol_fault_w
                    || !dut.child_response_owner_fault_w
                    || gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("SRC1 protocol fault exposed direct child request");
            force dut.u_fp32_addmul.rsp_valid_q = 1'b0;
            #0.1;
            release dut.u_fp32_addmul.rsp_valid_q;

            rst_i = 1'b1;
            #0.1;
            if (gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("reset exposed direct child request");
            rst_i = 1'b0;
            #0.1;

            // Ready only controls fire.  The offer and complete child payload
            // must remain identical while ready is toggled without a clock.
            force dut.child_req_ready_w = 1'b1;
            #0.1;
            if (!dut.src1_child_direct_offer_w
                    || !dut.src1_child_direct_fire_w
                    || !dut.child_req_valid_w || !dut.child_req_fire_w
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits)
                    || (dut.lhs_bits_q !== 32'h3f800000)
                    || dut.child_op_mul_w
                    || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000))
                fail_case("direct child payload depended on ready-high probe");
            force dut.child_req_ready_w = 1'b0;
            #0.1;
            if (!dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || !dut.child_req_valid_w || dut.child_req_fire_w
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits)
                    || (dut.lhs_bits_q !== 32'h3f800000)
                    || dut.child_op_mul_w
                    || (dut.u_fp32_addmul.fp_fma_i.rm !== 3'b000))
                fail_case("direct child payload depended on ready-low probe");
            force_witness_cases = force_witness_cases + 1;

            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_CHILD_REQ)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || !dut.child_req_valid_w || dut.child_req_ready_w
                    || dut.child_req_fire_w
                    || (dut.rhs_bits_q !== held_rhs_raw)
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits)
                    || (child_requests_o != child_requests_snapshot))
                fail_case("child elastic fallback C1 capture/owner mismatch");
            repeat (2) begin
                @(posedge clk_i); @(negedge clk_i);
                if (!dut.child_req_valid_w || dut.child_req_ready_w
                        || dut.child_req_fire_w || dut.child_outstanding_q
                        || (child_requests_o != child_requests_snapshot)
                        || (dut.child_rhs_raw_w !== held_rhs_raw)
                        || (dut.child_rhs_bits_w !== held_rhs_bits)
                        || (dut.flat_index_q != flat_snapshot)
                        || (dut.coord_i0_q != i0_snapshot)
                        || (dut.coord_i1_q != i1_snapshot)
                        || (dut.coord_i2_q != i2_snapshot)
                        || (dut.coord_i3_q != i3_snapshot))
                    fail_case("child request changed/credited under backpressure");
            end
            force dut.child_req_ready_w = 1'b1;
            #0.1;
            if (!dut.child_req_fire_w
                    || (dut.child_rhs_raw_w !== held_rhs_raw)
                    || (dut.child_rhs_bits_w !== held_rhs_bits))
                fail_case("child fallback eventual request mismatch");
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_CHILD_WAIT)
                    || dut.gmem_outstanding_q || !dut.child_outstanding_q
                    || (child_requests_o != (child_requests_snapshot + 64'd1)))
                fail_case("child fallback eventual owner/counter mismatch");
            release dut.child_req_ready_w;
            wait_for_state(ST_CHILD_WAIT, "child-rsp-backpressure", 40);
            force dut.child_rsp_ready_w = 1'b0;
            #1;
            if (!dut.child_owner_expected_w || dut.child_rsp_ready_w
                    || dut.child_rsp_fire_w || dut.protocol_fault_w)
                fail_case("child response backpressure credit witness mismatch");
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
            end
            #1;
            if (!dut.child_rsp_valid_w || !dut.child_owner_expected_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || dut.protocol_fault_w)
                fail_case("child response backpressure valid witness mismatch");
            force_witness_cases = force_witness_cases + 1;
            held_result = dut.child_result_bits_w;
            held_flags = dut.child_flags_w;
            child_responses_snapshot = child_responses_o;
            repeat (2) begin
                @(posedge clk_i); @(negedge clk_i);
                if (!dut.child_rsp_valid_w
                        || (dut.child_result_bits_w != held_result)
                        || (dut.child_flags_w != held_flags)
                        || !dut.child_owner_expected_w
                        || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                        || !dut.child_outstanding_q
                        || (child_responses_o != child_responses_snapshot)
                        || (elements_done_o != 64'b0)
                        || (writes_accepted_o != 64'b0)
                        || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                    fail_case("child response changed under backpressure");
            end
            release dut.child_rsp_ready_w;
            finish_done("child-backpressure", 100);
            check_raw32("child-backpressure", 16'h4000, 32'hbf800000);
            if ((child_requests_o != 64'd1) || (child_responses_o != 64'd1))
                fail_case("child backpressure cardinality mismatch");
            src1_child_fallback_cases = src1_child_fallback_cases + 1;
            positive_cases = positive_cases + 1;
        end
    endtask

    task automatic finish_child_drain(input string name,
                                      input logic [4:0] expected_code,
                                      input integer max_cycles);
        integer cycles;
        reg [63:0] flat_snapshot;
        reg [63:0] elements_snapshot;
        reg [63:0] active_snapshot;
        begin
            if (dut.state_q != ST_DRAIN)
                fail_case({name, " did not enter child DRAIN"});
            flat_snapshot = dut.flat_index_q;
            elements_snapshot = elements_done_o;
            active_snapshot = active_cycles_o;
            cycles = 0;
            while (!error_o) begin
                if ((dut.state_q != ST_DRAIN)
                        || (dut.flat_index_q != flat_snapshot)
                        || (elements_done_o != elements_snapshot)
                        || (active_cycles_o != active_snapshot)
                        || (arithmetic_flags_o != 5'b0)
                        || dut.child_req_valid_w)
                    fail_case({name, " child DRAIN changed result"});
                @(posedge clk_i); @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case({name, " child DRAIN timeout"});
            end
            if (error_code_o != expected_code)
                fail_case({name, " child drain code mismatch"});
            @(posedge clk_i); @(negedge clk_i);
            if (!ready_o || busy_o || error_o)
                fail_case({name, " child drain did not recover"});
            child_fault_cases = child_fault_cases + 1;
        end
    endtask

    // Global protocol fault is evaluated before every per-state response
    // handler.  If an unrelated unsolicited response collides with the
    // currently owned response, the fault edge must suppress both ready/fire
    // handshakes; the held owned response is returned exactly once only after
    // the FSM has installed the matching DRAIN owner.
    task automatic run_protocol_fault_owned_response_collisions;
        reg [31:0] command_cycles_before;
        reg [31:0] stall_cycles_before;
        reg [63:0] child_responses_before;
        integer child_model_responses_before;
        integer gmem_responses_before;
        begin
            // Owned child response + unsolicited GMEM response.  Also force
            // both watchdog deadlines to prove protocol fault stays highest.
            prepare_fault_command();
            launch_command();
            wait_for_state(ST_CHILD_WAIT, "child-owned-protocol-collision", 100);
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("child collision lost owned response");
            end
            #0.1;
            command_cycles_before = dut.command_cycles_q;
            stall_cycles_before = dut.stall_cycles_q;
            child_responses_before = child_responses_o;
            child_model_responses_before = child_response_count;
            force gmem_rsp_valid_i = 1'b1;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            force dut.stall_cycles_q = CHILD_TIMEOUT_LAST;
            #0.1;
            if (!dut.protocol_fault_w
                    || !dut.gmem_response_owner_fault_w
                    || !dut.child_owner_expected_w
                    || !dut.child_rsp_valid_w
                    || dut.gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || !dut.command_timeout_hit_w
                    || !dut.phase_timeout_hit_w)
                fail_case("child collision fault edge consumed/exposed traffic");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_CHILD)
                    || (dut.drain_error_code_q != ERR_INTERNAL_STATE)
                    || dut.gmem_outstanding_q || !dut.child_outstanding_q
                    || !dut.child_rsp_valid_w
                    || (child_responses_o != child_responses_before)
                    || (child_response_count != child_model_responses_before)
                    || (elements_done_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0))
                fail_case("child collision did not preserve DRAIN credit");
            force gmem_rsp_valid_i = 1'b0;
            force dut.command_cycles_q = command_cycles_before;
            force dut.stall_cycles_q = stall_cycles_before;
            #0.1;
            release gmem_rsp_valid_i;
            release dut.command_cycles_q;
            release dut.stall_cycles_q;
            #0.1;
            if (dut.protocol_fault_w || !dut.child_rsp_valid_w
                    || !dut.child_rsp_ready_w || !dut.child_rsp_fire_w
                    || dut.gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || gmem_req_valid_o)
                fail_case("child collision DRAIN did not return held credit");
            finish_child_drain("child-owned-protocol-collision",
                               ERR_INTERNAL_STATE, 20);
            if ((child_responses_o != (child_responses_before + 64'd1))
                    || (child_response_count
                        != (child_model_responses_before + 1))
                    || (child_requests_o != 64'd1)
                    || (elements_done_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("child collision terminal/cardinality mismatch");
            protocol_collision_cases = protocol_collision_cases + 1;
            run_scalar("child-collision-clean-retry", OP_ADD,
                       32'h3f800000, 32'h40000000,
                       32'h40400000, 5'b0, 1);

            // Owned GMEM response + unsolicited child response.  The memory
            // model must retain its response until DRAIN_GMEM accepts it.
            prepare_fault_command();
            read_response_delay_cfg = 3;
            launch_command();
            wait_for_state(ST_SRC0_WAIT, "gmem-owned-protocol-collision", 40);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC0_WAIT)
                    fail_case("GMEM collision lost owned response");
            end
            #0.1;
            if (!gmem_rsp_ready_o || !dut.gmem_rsp_fire_w)
                fail_case("GMEM collision lacked clean pre-fault response");
            command_cycles_before = dut.command_cycles_q;
            stall_cycles_before = dut.stall_cycles_q;
            gmem_responses_before = response_count;
            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            force dut.stall_cycles_q = STALL_TIMEOUT_LAST;
            #0.1;
            if (!dut.protocol_fault_w
                    || !dut.child_response_owner_fault_w
                    || !dut.gmem_owner_expected_w
                    || !gmem_rsp_valid_i
                    || gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || !dut.command_timeout_hit_w
                    || !dut.phase_timeout_hit_w)
                fail_case("GMEM collision fault edge consumed/exposed traffic");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_GMEM)
                    || (dut.drain_error_code_q != ERR_CHILD_PROTOCOL)
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || !gmem_rsp_valid_i
                    || (response_count != gmem_responses_before)
                    || (elements_done_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0))
                fail_case("GMEM collision did not preserve DRAIN credit");
            force dut.u_fp32_addmul.rsp_valid_q = 1'b0;
            force dut.command_cycles_q = command_cycles_before;
            force dut.stall_cycles_q = stall_cycles_before;
            #0.1;
            release dut.u_fp32_addmul.rsp_valid_q;
            release dut.command_cycles_q;
            release dut.stall_cycles_q;
            #0.1;
            if (dut.protocol_fault_w || !gmem_rsp_valid_i
                    || !gmem_rsp_ready_o || !dut.gmem_rsp_fire_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || gmem_req_valid_o)
                fail_case("GMEM collision DRAIN did not return held credit");
            finish_gmem_drain("gmem-owned-protocol-collision",
                              ERR_CHILD_PROTOCOL, 20);
            if ((response_count != (gmem_responses_before + 1))
                    || (gmem_read_beats_o != 64'd1)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (elements_done_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("GMEM collision terminal/cardinality mismatch");
            protocol_collision_cases = protocol_collision_cases + 1;
            run_scalar("gmem-collision-clean-retry", OP_MUL,
                       32'h3f800000, 32'h40000000,
                       32'h40000000, 5'b0, 1);

            // Owned GMEM error response + unsolicited child response.  The
            // protocol cause selected on the collision edge must remain the
            // final terminal after DRAIN; late-error refinement is legal only
            // for timeout causes.
            prepare_fault_command();
            read_response_delay_cfg = 3;
            inject_error_state_q = ST_SRC0_REQ;
            launch_command();
            wait_for_state(ST_SRC0_WAIT,
                           "gmem-error-protocol-collision", 40);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC0_WAIT)
                    fail_case("GMEM error collision lost owned response");
            end
            #0.1;
            if (!gmem_rsp_error_i || !gmem_rsp_ready_o
                    || !dut.gmem_rsp_fire_w)
                fail_case("GMEM error collision lacked clean error response");
            gmem_responses_before = response_count;
            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            #0.1;
            if (!dut.protocol_fault_w
                    || !dut.child_response_owner_fault_w
                    || !dut.gmem_owner_expected_w
                    || !gmem_rsp_valid_i || !gmem_rsp_error_i
                    || gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("GMEM error collision fault edge priority mismatch");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_GMEM)
                    || (dut.drain_error_code_q != ERR_CHILD_PROTOCOL)
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || !gmem_rsp_valid_i || !gmem_rsp_error_i
                    || (response_count != gmem_responses_before)
                    || (elements_done_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0))
                fail_case("GMEM error collision did not preserve cause/credit");
            force dut.u_fp32_addmul.rsp_valid_q = 1'b0;
            #0.1;
            release dut.u_fp32_addmul.rsp_valid_q;
            #0.1;
            if (dut.protocol_fault_w || !gmem_rsp_valid_i
                    || !gmem_rsp_error_i || !gmem_rsp_ready_o
                    || !dut.gmem_rsp_fire_w || dut.child_rsp_ready_w
                    || dut.child_rsp_fire_w || gmem_req_valid_o)
                fail_case("GMEM error collision DRAIN credit mismatch");
            finish_gmem_drain("gmem-error-protocol-collision",
                              ERR_CHILD_PROTOCOL, 20);
            if ((response_count != (gmem_responses_before + 1))
                    || (gmem_read_beats_o != 64'd1)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (elements_done_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("GMEM error collision terminal/cardinality mismatch");
            protocol_collision_cases = protocol_collision_cases + 1;
        end
    endtask

    task automatic run_child_fault_matrix;
        integer accepted_before;
        reg [63:0] flat_snapshot;
        reg [31:0] i0_snapshot;
        reg [31:0] i1_snapshot;
        reg [31:0] i2_snapshot;
        reg [31:0] i3_snapshot;
        reg [4:0] flags_snapshot;
        reg [63:0] elements_snapshot;
        reg [63:0] reads_snapshot;
        reg [63:0] writes_snapshot;
        reg [63:0] accepted_writes_snapshot;
        reg [63:0] child_requests_snapshot;
        reg [63:0] child_responses_snapshot;
        reg [31:0] shadow_snapshot;
        begin
            prepare_fault_command();
            launch_command(); wait_for_state(ST_PREFLIGHT, "child-ghost", 10);
            accepted_before = accepted_request_count;
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            #1;
            if (!dut.u_fp32_addmul.rsp_valid_q || !dut.child_rsp_valid_w
                    || !dut.child_response_owner_fault_w
                    || !dut.protocol_fault_w || dut.child_owner_expected_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || dut.child_req_fire_w || gmem_req_valid_o
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || dut.gmem_outstanding_q || dut.child_outstanding_q)
                fail_case("child-ghost production predicate/credit not witnessed");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (dut.error_code_q != ERR_CHILD_PROTOCOL)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || !error_o || gmem_req_valid_o
                    || dut.child_req_valid_w || dut.child_rsp_ready_w
                    || (accepted_request_count != accepted_before)
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != 5'b0)
                    || (elements_done_o != 64'b0)
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (child_requests_o != 64'b0)
                    || (child_responses_o != 64'b0)
                    || (read_raw32(16'h4000) != 32'ha5a5a5a5))
                fail_case("child-ghost post-edge error/quarantine mismatch");
            release dut.u_fp32_addmul.rsp_valid_q;
            finish_error("child-ghost", ERR_CHILD_PROTOCOL, 20);
            child_fault_cases = child_fault_cases + 1;
            run_scalar("child-ghost-clean-retry", OP_ADD, 32'h3f800000,
                       32'h40000000, 32'h40400000, 5'b0, 1);

            prepare_fault_command(); read_response_delay_cfg = 12;
            launch_command(); wait_for_state(ST_SRC0_WAIT, "wrong-owner", 30);
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            accepted_writes_snapshot = writes_accepted_o;
            child_requests_snapshot = child_requests_o;
            child_responses_snapshot = child_responses_o;
            shadow_snapshot = read_raw32(16'h4000);
            force dut.u_fp32_addmul.rsp_valid_q = 1'b1;
            #1;
            if (!dut.u_fp32_addmul.rsp_valid_q || !dut.child_rsp_valid_w
                    || !dut.child_response_owner_fault_w
                    || !dut.protocol_fault_w || dut.child_owner_expected_w
                    || !dut.gmem_owner_expected_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || dut.child_req_fire_w || dut.gmem_rsp_fire_w
                    || gmem_rsp_ready_o || !dut.gmem_outstanding_q
                    || dut.child_outstanding_q)
                fail_case("wrong-owner production predicate/credit not witnessed");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_GMEM)
                    || (dut.drain_error_code_q != ERR_CHILD_PROTOCOL)
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || error_o || gmem_req_valid_o
                    || dut.child_req_valid_w || dut.child_rsp_ready_w
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != flags_snapshot)
                    || (elements_done_o != elements_snapshot)
                    || (gmem_read_beats_o != reads_snapshot)
                    || (gmem_write_beats_o != writes_snapshot)
                    || (writes_accepted_o != accepted_writes_snapshot)
                    || (child_requests_o != child_requests_snapshot)
                    || (child_responses_o != child_responses_snapshot)
                    || (read_raw32(16'h4000) != shadow_snapshot))
                fail_case("wrong-owner post-edge drain/quarantine mismatch");
            release dut.u_fp32_addmul.rsp_valid_q;
            finish_gmem_drain("wrong-owner", ERR_CHILD_PROTOCOL, 100);
            child_fault_cases = child_fault_cases + 1;
            run_scalar("wrong-owner-clean-retry", OP_MUL, 32'h3f800000,
                       32'h40000000, 32'h40000000, 5'b0, 1);

            prepare_fault_command();
            launch_command(); wait_for_state(ST_CHILD_WAIT, "child-timeout", 100);
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            accepted_writes_snapshot = writes_accepted_o;
            child_requests_snapshot = child_requests_o;
            child_responses_snapshot = child_responses_o;
            shadow_snapshot = read_raw32(16'h4000);
            force dut.child_rsp_ready_w = 1'b0;
            force dut.stall_cycles_q = CHILD_TIMEOUT_LAST;
            #1;
            if (!dut.phase_timeout_hit_w || !dut.child_owner_expected_w
                    || dut.child_rsp_ready_w || dut.child_rsp_fire_w
                    || !dut.child_outstanding_q || dut.protocol_fault_w
                    || dut.child_req_fire_w)
                fail_case("child-timeout production predicate/credit not witnessed");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_DRAIN)
                    || (dut.drain_owner_q != DRAIN_CHILD)
                    || (dut.drain_error_code_q != ERR_CHILD_TIMEOUT)
                    || dut.gmem_outstanding_q || !dut.child_outstanding_q
                    || done_o || error_o || gmem_req_valid_o
                    || dut.child_req_valid_w
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != flags_snapshot)
                    || (elements_done_o != elements_snapshot)
                    || (gmem_read_beats_o != reads_snapshot)
                    || (gmem_write_beats_o != writes_snapshot)
                    || (writes_accepted_o != accepted_writes_snapshot)
                    || (child_requests_o != child_requests_snapshot)
                    || (child_responses_o != child_responses_snapshot)
                    || (read_raw32(16'h4000) != shadow_snapshot))
                fail_case("child-timeout post-edge drain/quarantine mismatch");
            release dut.stall_cycles_q;
            release dut.child_rsp_ready_w;
            finish_child_drain("child-timeout", ERR_CHILD_TIMEOUT, 100);
            run_scalar("child-timeout-clean-retry", OP_SUB, 32'h3f800000,
                       32'h40000000, 32'hbf800000, 5'b0, 1);

            prepare_fault_command();
            launch_command(); wait_for_state(ST_CHILD_WAIT, "child-deadline", 100);
            force dut.child_rsp_ready_w = 1'b0;
            #1;
            if (!dut.child_owner_expected_w || dut.child_rsp_ready_w
                    || dut.child_rsp_fire_w || !dut.child_outstanding_q
                    || dut.protocol_fault_w)
                fail_case("child-deadline backpressure witness mismatch");
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
            end
            flat_snapshot = dut.flat_index_q;
            i0_snapshot = dut.coord_i0_q;
            i1_snapshot = dut.coord_i1_q;
            i2_snapshot = dut.coord_i2_q;
            i3_snapshot = dut.coord_i3_q;
            flags_snapshot = arithmetic_flags_o;
            elements_snapshot = elements_done_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            accepted_writes_snapshot = writes_accepted_o;
            child_requests_snapshot = child_requests_o;
            child_responses_snapshot = child_responses_o;
            shadow_snapshot = read_raw32(16'h4000);
            force dut.stall_cycles_q = CHILD_TIMEOUT_LAST;
            release dut.child_rsp_ready_w;
            #1;
            if (!dut.phase_timeout_hit_w || !dut.child_rsp_valid_w
                    || !dut.child_owner_expected_w || !dut.child_rsp_ready_w
                    || !dut.child_rsp_fire_w || !dut.child_outstanding_q
                    || dut.protocol_fault_w || dut.child_req_fire_w
                    || dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("child-deadline production predicate/credit not witnessed");
            force_witness_cases = force_witness_cases + 1;
            @(posedge clk_i); @(negedge clk_i);
            if ((dut.state_q != ST_ERROR)
                    || (dut.error_code_q != ERR_CHILD_TIMEOUT)
                    || (dut.drain_owner_q != DRAIN_NONE)
                    || dut.gmem_outstanding_q || dut.child_outstanding_q
                    || done_o || !error_o || gmem_req_valid_o
                    || dut.child_req_valid_w || dut.child_rsp_ready_w
                    || (dut.flat_index_q != flat_snapshot)
                    || (dut.coord_i0_q != i0_snapshot)
                    || (dut.coord_i1_q != i1_snapshot)
                    || (dut.coord_i2_q != i2_snapshot)
                    || (dut.coord_i3_q != i3_snapshot)
                    || (arithmetic_flags_o != 5'b0)
                    || (elements_done_o != elements_snapshot)
                    || (gmem_read_beats_o != reads_snapshot)
                    || (gmem_write_beats_o != writes_snapshot)
                    || (writes_accepted_o != accepted_writes_snapshot)
                    || (child_requests_o != child_requests_snapshot)
                    || (child_responses_o != (child_responses_snapshot + 64'd1))
                    || (read_raw32(16'h4000) != shadow_snapshot))
                fail_case("child-deadline post-edge error/quarantine mismatch");
            release dut.stall_cycles_q;
            finish_error("child-deadline", ERR_CHILD_TIMEOUT, 20);
            child_fault_cases = child_fault_cases + 1;
            run_scalar("child-deadline-clean-retry", OP_SCALE, 32'h80000000,
                       32'h40000000, 32'h80000000, 5'b0, 1);

            check_root_canary("child-faults");
        end
    endtask

    task automatic cancel_with_reset(input string name);
        begin
            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i); @(negedge clk_i);
                if (ready_o || busy_o || done_o || error_o
                        || gmem_req_valid_o || gmem_rsp_ready_o)
                    fail_case({name, " reset leaked protocol state"});
            end
            rst_i = 1'b0;
            repeat (3) begin
                @(posedge clk_i); @(negedge clk_i);
                if (!ready_o || busy_o || done_o || error_o
                        || pending_q || gmem_rsp_valid_i
                        || (outstanding_count != 0))
                    fail_case({name, " reset exposed stale completion"});
            end
            reset_cases = reset_cases + 1;
        end
    endtask

    task automatic run_reset_matrix;
        begin
            prepare_fault_command(); launch_command();
            wait_for_state(ST_PREFLIGHT, "reset-preflight", 10);
            cancel_with_reset("reset-preflight");

            prepare_fault_command(); read_response_delay_cfg = 20;
            launch_command(); wait_for_state(ST_SRC0_WAIT, "reset-read", 30);
            cancel_with_reset("reset-read");

            prepare_fault_command(); launch_command();
            wait_for_state(ST_SRC1_WAIT, "reset-src1-direct", 100);
            while (!gmem_rsp_valid_i) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_SRC1_WAIT)
                    fail_case("reset-src1 left WAIT before response");
            end
            #0.1;
            if (!dut.gmem_rsp_fire_w
                    || !dut.src1_child_direct_offer_w
                    || !dut.src1_child_direct_fire_w
                    || !dut.child_req_valid_w || !dut.child_req_fire_w)
                fail_case("reset-src1 missing pre-reset direct witness");
            rst_i = 1'b1;
            #0.1;
            if (gmem_rsp_ready_o || dut.gmem_rsp_fire_w
                    || dut.src1_child_direct_offer_w
                    || dut.src1_child_direct_fire_w
                    || dut.child_req_valid_w || dut.child_req_fire_w)
                fail_case("reset-src1 exposed direct child request");
            cancel_with_reset("reset-src1-direct");

            prepare_fault_command(); launch_command();
            wait_for_state(ST_CHILD_WAIT, "reset-child", 100);
            while (!dut.child_rsp_valid_w) begin
                @(posedge clk_i); @(negedge clk_i);
                if (dut.state_q != ST_CHILD_WAIT)
                    fail_case("reset-child left WAIT before response");
            end
            #1;
            if (!dut.child_rsp_fire_w || !dut.child_write_direct_offer_w
                    || !dut.child_write_direct_fire_w
                    || !gmem_req_valid_o || !dut.gmem_req_fire_w)
                fail_case("reset-child missing pre-reset direct witness");
            rst_i = 1'b1;
            #1;
            if (dut.child_write_direct_offer_w
                    || dut.child_write_direct_fire_w
                    || gmem_req_valid_o || dut.gmem_req_fire_w)
                fail_case("reset exposed direct child write");
            cancel_with_reset("reset-child");

            prepare_two_element_fault_command(); write_response_delay_cfg = 20;
            launch_command(); wait_for_state(ST_WRITE_WAIT, "reset-write", 120);
            if (!dut.select_next_element_w
                    || !dut.selected_element_address_valid_w
                    || (dut.flat_index_q != 64'b0)
                    || (dut.next_flat_index_w != 64'd1)
                    || (elements_done_o != 64'b0))
                fail_case("reset-write missing lookahead witness");
            cancel_with_reset("reset-write");
            if ((dut.flat_index_q != 64'b0)
                    || (dut.coord_i0_q != 32'b0)
                    || (dut.coord_i1_q != 32'b0)
                    || (dut.coord_i2_q != 32'b0)
                    || (dut.coord_i3_q != 32'b0)
                    || (dut.gmem_req_addr_q != 64'b0)
                    || (dut.current_src1_word_q != 62'b0)
                    || (dut.current_dst_addr_q != 64'b0)
                    || (elements_done_o != 64'b0))
                fail_case("reset-write committed stale lookahead state");

            check_root_canary("reset-matrix");
            run_scalar("reset-clean-retry", OP_SCALE, 32'h80000000,
                       32'h40000000, 32'h80000000, 5'b0, 1);
        end
    endtask

    task automatic run_busy_start;
        reg [1960:0] descriptor_snapshot;
        reg [990:0] transaction_snapshot;
        integer accepted_request_before_launch;
        integer accepted_read_before_launch;
        integer accepted_write_before_launch;
        integer response_before_launch;
        integer child_accepted_before_launch;
        integer child_response_before_launch;
        integer accepted_request_edge_snapshot;
        integer accepted_read_edge_snapshot;
        integer accepted_write_edge_snapshot;
        integer response_edge_snapshot;
        integer child_accepted_edge_snapshot;
        integer child_response_edge_snapshot;
        integer alternate_byte;
        begin
            set_default_command();
            src0_ne0_i = 32'd2; src0_nb1_i = 64'd8;
            src0_nb2_i = 64'd8; src0_nb3_i = 64'd8;
            src1_ne0_i = 32'd2; src1_nb1_i = 64'd8;
            src1_nb2_i = 64'd8; src1_nb3_i = 64'd8;
            dst_ne0_i = 32'd2; dst_nb1_i = 64'd8;
            dst_nb2_i = 64'd8; dst_nb3_i = 64'd8;
            // 明确早于8-cycle phase deadline；delay=6会让model response恰落
            // deadline，是repair-v2首错的错误oracle配置。
            read_response_delay_cfg = 1;
            write_raw32(16'h1000, 32'h3f800000);
            write_raw32(16'h1004, 32'h40000000);
            write_raw32(16'h2000, 32'h3f800000);
            write_raw32(16'h2004, 32'h3f800000);
            fill_bytes(16'h4000, 16, 8'ha5);
            fill_bytes(16'h5000, 16, 8'h7c);

            accepted_request_before_launch = accepted_request_count;
            accepted_read_before_launch = accepted_read_count;
            accepted_write_before_launch = accepted_write_count;
            response_before_launch = response_count;
            child_accepted_before_launch = child_accepted_count;
            child_response_before_launch = child_response_count;
            launch_command(); wait_for_state(ST_SRC0_WAIT, "busy-start", 30);

            if (ready_o || !busy_o || dut.start_fire_w
                    || dut.phase_timeout_hit_w || dut.protocol_fault_w
                    || !dut.gmem_owner_expected_w
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || (outstanding_count != 1) || !pending_q
                    || gmem_rsp_valid_i || dut.gmem_rsp_fire_w
                    || (response_countdown_q != 1))
                fail_case("busy-start unsafe pre-injection phase/owner");

            descriptor_snapshot = resident_descriptor_observe_w;
            transaction_snapshot = resident_transaction_observe_w;
            accepted_request_edge_snapshot = accepted_request_count;
            accepted_read_edge_snapshot = accepted_read_count;
            accepted_write_edge_snapshot = accepted_write_count;
            response_edge_snapshot = response_count;
            child_accepted_edge_snapshot = child_accepted_count;
            child_response_edge_snapshot = child_response_count;

            // 用明显不同的pin-level descriptor证明busy start不覆盖resident q。
            opcode_i = OP_MUL;
            dtype_i = 2'd1;
            profile_i = 4'hf;
            reserved_i = 32'hfeed_cafe;
            op_params_i = 64'h0123_4567_89ab_cdef;
            gmem_floor_i = 64'h0800;
            gmem_limit_i = 64'h6000;
            dst_region_base_i = 64'h5000;
            dst_region_size_i = 64'h0080;
            dst_view_off_i = 64'd16;
            dst_ne0_i = 32'd4; dst_ne1_i = 32'd2;
            dst_ne2_i = 32'd1; dst_ne3_i = 32'd1;
            dst_nb0_i = 64'd8; dst_nb1_i = 64'd32;
            dst_nb2_i = 64'd64; dst_nb3_i = 64'd64;
            src0_region_base_i = 64'h3000;
            src0_region_size_i = 64'h0080;
            src0_view_off_i = 64'd8;
            src0_ne0_i = 32'd4; src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd1; src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd8; src0_nb1_i = 64'd32;
            src0_nb2_i = 64'd64; src0_nb3_i = 64'd64;
            src1_region_base_i = 64'h3800;
            src1_region_size_i = 64'h0080;
            src1_view_off_i = 64'd12;
            src1_ne0_i = 32'd2; src1_ne1_i = 32'd2;
            src1_ne2_i = 32'd1; src1_ne3_i = 32'd1;
            src1_nb0_i = 64'd8; src1_nb1_i = 64'd24;
            src1_nb2_i = 64'd48; src1_nb3_i = 64'd48;
            start_i = 1'b1;

            #1;
            if (ready_o || !busy_o || dut.start_fire_w
                    || dut.phase_timeout_hit_w || dut.protocol_fault_w
                    || (dut.state_q != ST_SRC0_WAIT)
                    || !dut.gmem_owner_expected_w
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || gmem_rsp_valid_i || dut.gmem_rsp_fire_w
                    || dut.child_req_fire_w || dut.child_rsp_fire_w
                    || (resident_descriptor_observe_w !== descriptor_snapshot)
                    || (resident_transaction_observe_w !== transaction_snapshot)
                    || (accepted_request_count != accepted_request_edge_snapshot)
                    || (accepted_read_count != accepted_read_edge_snapshot)
                    || (accepted_write_count != accepted_write_edge_snapshot)
                    || (response_count != response_edge_snapshot)
                    || (child_accepted_count != child_accepted_edge_snapshot)
                    || (child_response_count != child_response_edge_snapshot))
                fail_case("busy-start pre-edge admission/snapshot mismatch");

            @(posedge clk_i); @(negedge clk_i);
            if (ready_o || !busy_o || dut.start_fire_w
                    || dut.phase_timeout_hit_w || dut.protocol_fault_w
                    || (dut.state_q != ST_SRC0_WAIT)
                    || !dut.gmem_owner_expected_w
                    || !dut.gmem_outstanding_q || dut.child_outstanding_q
                    || gmem_req_valid_o || dut.gmem_req_fire_w
                    || gmem_rsp_valid_i || dut.gmem_rsp_fire_w
                    || dut.child_req_fire_w || dut.child_rsp_fire_w
                    || (response_countdown_q != 0)
                    || (resident_descriptor_observe_w !== descriptor_snapshot)
                    || (resident_transaction_observe_w !== transaction_snapshot)
                    || (accepted_request_count != accepted_request_edge_snapshot)
                    || (accepted_read_count != accepted_read_edge_snapshot)
                    || (accepted_write_count != accepted_write_edge_snapshot)
                    || (response_count != response_edge_snapshot)
                    || (child_accepted_count != child_accepted_edge_snapshot)
                    || (child_response_count != child_response_edge_snapshot))
                fail_case("busy-start post-edge admission/snapshot mismatch");
            busy_start_witness_cases = busy_start_witness_cases + 1;
            start_i = 1'b0;
            finish_done("busy-start", 400);
            check_raw32("busy-original0", 16'h4000, 32'h40000000);
            check_raw32("busy-original1", 16'h4004, 32'h40400000);
            for (alternate_byte = 0; alternate_byte < 16;
                    alternate_byte = alternate_byte + 1) begin
                if (gmem_bytes[32'h0000_5000 + alternate_byte] != 8'h7c)
                    fail_case("busy start overwrote alternate target canary");
            end
            if ((elements_done_o != 64'd2)
                    || (gmem_read_beats_o != 64'd2)
                    || (gmem_pair_reuse_elements_o != 64'd1)
                    || (gmem_write_beats_o != 64'd2)
                    || (writes_accepted_o != 64'd2)
                    || (child_requests_o != 64'd2)
                    || (child_responses_o != 64'd2)
                    || (arithmetic_flags_o != 5'b0)
                    || ((accepted_request_count
                         - accepted_request_before_launch) != 4)
                    || ((accepted_read_count
                         - accepted_read_before_launch) != 2)
                    || ((accepted_write_count
                         - accepted_write_before_launch) != 2)
                    || ((response_count - response_before_launch) != 4)
                    || ((child_accepted_count
                         - child_accepted_before_launch) != 2)
                    || ((child_response_count
                         - child_response_before_launch) != 2))
                fail_case("busy-start end-to-end credit/cardinality mismatch");
            busy_start_cases = busy_start_cases + 1;
            positive_cases = positive_cases + 1;
            check_root_canary("busy-start");
        end
    endtask

    integer init_index;
    initial begin
        clk_i = 1'b0;
        rst_i = 1'b1;
        start_i = 1'b0;
        model_cycle_q = 64'b0;
        gmem_rsp_valid_i = 1'b0;
        gmem_rsp_rdata_i = 64'b0;
        gmem_rsp_error_i = 1'b0;
        pending_q = 1'b0;
        pending_write_q = 1'b0;
        pending_addr_q = 0;
        pending_error_q = 1'b0;
        response_countdown_q = 0;
        outstanding_count = 0;
        accepted_request_count = 0;
        accepted_read_count = 0;
        accepted_write_count = 0;
        response_count = 0;
        reset_cancelled_request_count = 0;
        maximum_outstanding = 0;
        maximum_combined_outstanding = 0;
        child_model_outstanding = 0;
        child_accepted_count = 0;
        child_response_count = 0;
        child_reset_cancelled_count = 0;
        positive_cases = 0;
        scalar_cases = 0;
        broadcast_cases = 0;
        preflight_cases = 0;
        gmem_fault_cases = 0;
        gmem_drain_cases = 0;
        child_fault_cases = 0;
        reset_cases = 0;
        clean_retry_cases = 0;
        busy_start_cases = 0;
        force_witness_cases = 0;
        busy_start_witness_cases = 0;
        lookahead_turnover_cases = 0;
        child_write_direct_cases = 0;
        child_write_fallback_cases = 0;
        protocol_collision_cases = 0;
        src1_child_direct_cases = 0;
        src1_child_fallback_cases = 0;
        child_write_invalid_cases = 0;
        child_deadline_priority_cases = 0;
        gmem_pair_reuse_cases = 0;
        gmem_pair_tag_cases = 0;
        gmem_pair_child_fallback_cases = 0;
        src1_child_opcode_coverage = 4'b0;
        gmem_hold_q = 1'b0;
        child_req_hold_q = 1'b0;
        child_rsp_hold_q = 1'b0;
        previous_done_q = 1'b0;
        previous_error_q = 1'b0;
        held_gmem_addr_q = 64'b0;
        held_gmem_write_q = 1'b0;
        held_gmem_wdata_q = 64'b0;
        held_gmem_wstrb_q = 8'b0;
        held_child_mul_q = 1'b0;
        held_child_lhs_q = 32'b0;
        held_child_rhs_q = 32'b0;
        held_child_result_q = 32'b0;
        held_child_flags_q = 5'b0;
        for (init_index = 0; init_index < GMEM_BYTES; init_index = init_index + 1)
            gmem_bytes[init_index] = 8'b0;
        fill_bytes(16'h0100, 32, 8'h5a);
        set_default_command();
        reset_engine();

        // Frozen scalar raw-bit oracle；无real/shortreal/DPI/host FP。
        run_scalar("add-ordinary", OP_ADD, 32'h3f800000, 32'h40000000,
                   32'h40400000, 5'h00, 0);
        run_scalar("add-invalid", OP_ADD, 32'h7f800000, 32'hff800000,
                   32'h7fc00000, 5'h10, 0);
        run_scalar("sub-ordinary", OP_SUB, 32'h3f800000, 32'h40000000,
                   32'hbf800000, 5'h00, 0);
        run_scalar("sub-zero", OP_SUB, 32'h00000000, 32'h00000000,
                   32'h00000000, 5'h00, 0);
        run_scalar("mul-zero-inf", OP_MUL, 32'h00000000, 32'hff800000,
                   32'h7fc00000, 5'h10, 0);
        run_scalar("mul-minsub-one", OP_MUL, 32'h00000001, 32'h3f800000,
                   32'h00000001, 5'h00, 0);
        run_scalar("mul-minnormal-tie", OP_MUL, 32'h00800000, 32'h3f7fffff,
                   32'h00800000, 5'h03, 0);
        run_scalar("mul-minsub-1p5", OP_MUL, 32'h00000001, 32'h3fc00000,
                   32'h00000002, 5'h03, 0);
        run_scalar("mul-overflow", OP_MUL, 32'h7f7fffff, 32'h40000000,
                   32'h7f800000, 5'h05, 0);
        run_scalar("scale-negative-zero", OP_SCALE, 32'h80000000, 32'h40000000,
                   32'h80000000, 5'h00, 0);
        run_sticky_flags();
        run_gmem_pair_reuse_oracle();
        run_gmem_pair_tag_oracle();
        run_gmem_pair_child_fallback_oracle();
        run_write_turnover_oracle();
        run_child_write_fallback_oracle();
        run_child_write_fail_closed_oracles();
        run_modulo_broadcast();
        run_transpose_like_broadcast();
        run_empty_scale();
        run_preflight_matrix();
        run_gmem_response_faults();
        run_gmem_timeout_matrix();
        run_child_backpressure();
        run_protocol_fault_owned_response_collisions();
        run_child_fault_matrix();
        run_busy_start();
        run_reset_matrix();

        if (maximum_outstanding != 1)
            fail_case("GMEM maximum outstanding was not exactly one");
        if (maximum_combined_outstanding != 1)
            fail_case("combined owner maximum was not exactly one");
        if (accepted_request_count
                != (response_count + reset_cancelled_request_count))
            fail_case("GMEM accepted/response/reset conservation mismatch");
        if (child_accepted_count
                != (child_response_count + child_reset_cancelled_count))
            fail_case("child accepted/response/reset conservation mismatch");
        if ((preflight_cases != 25) || (broadcast_cases != 2)
                || (gmem_fault_cases != 5) || (gmem_drain_cases != 7)
                || (child_fault_cases != 5) || (reset_cases != 5)
                || (busy_start_cases != 1) || (clean_retry_cases != 9)
                || (force_witness_cases != 18)
                || (busy_start_witness_cases != 1)
                || (lookahead_turnover_cases != 1)
                || (child_write_direct_cases != 1)
                || (child_write_fallback_cases != 1)
                || (protocol_collision_cases != 3)
                || (src1_child_direct_cases != 1)
                || (src1_child_fallback_cases != 1)
                || (child_write_invalid_cases != 1)
                || (child_deadline_priority_cases != 1)
                || (gmem_pair_reuse_cases != 1)
                || (gmem_pair_tag_cases != 1)
                || (gmem_pair_child_fallback_cases != 1)
                || (src1_child_opcode_coverage != 4'hf))
            fail_case("fixture class count mismatch");
        check_root_canary("final");
        $display("[NPU-F32-TENSOR-ALU][INFO] positive=%0d scalar=%0d broadcast=%0d preflight=%0d gmem_fault=%0d gmem_drain=%0d child_fault=%0d reset=%0d retry=%0d busy=%0d",
                 positive_cases, scalar_cases, broadcast_cases, preflight_cases,
                 gmem_fault_cases, gmem_drain_cases, child_fault_cases,
                 reset_cases, clean_retry_cases, busy_start_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] production-force-witness=%0d",
                 force_witness_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] busy-start-witness=%0d safe-delay=%0d",
                 busy_start_witness_cases, 1);
        $display("[NPU-F32-TENSOR-ALU][INFO] lookahead-turnover=%0d first-prep-fold=1 prep=0 turnover=15",
                 lookahead_turnover_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] child-write-direct=%0d direct-elements=16 fallback=%0d",
                 child_write_direct_cases, child_write_fallback_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] protocol-owned-response-collision=%0d",
                 protocol_collision_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] src1-child-direct=%0d direct-elements=16 fallback=%0d opcode-coverage=%x",
                 src1_child_direct_cases, src1_child_fallback_cases,
                 src1_child_opcode_coverage);
        $display("[NPU-F32-TENSOR-ALU][INFO] child-write-invalid=%0d command-phase-priority=%0d",
                 child_write_invalid_cases, child_deadline_priority_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] gmem-pair-reuse=%0d hit-elements=8 miss-elements=8 pair-direct=8 physical-reads=16 tag-oracle=%0d fallback=%0d",
                 gmem_pair_reuse_cases, gmem_pair_tag_cases,
                 gmem_pair_child_fallback_cases);
        $display("[NPU-F32-TENSOR-ALU][INFO] gmem reads=%0d writes=%0d responses=%0d reset_cancelled=%0d child_accept=%0d child_response=%0d child_reset_cancelled=%0d max_owner=%0d",
                 accepted_read_count, accepted_write_count, response_count,
                 reset_cancelled_request_count, child_accepted_count,
                 child_response_count, child_reset_cancelled_count,
                 maximum_combined_outstanding);
        $display("[NPU-F32-TENSOR-ALU][PASS]");

        $finish;
    end
endmodule

`default_nettype wire
