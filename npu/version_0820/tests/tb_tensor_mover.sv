`timescale 1ns/1ps
`default_nettype none

module tb_tensor_mover;
    localparam integer GMEM_BYTES = 4096;
    localparam integer STALL_TIMEOUT_CYCLES = 8;
    localparam integer COMMAND_TIMEOUT_CYCLES = 256;
    localparam logic [31:0] STALL_TIMEOUT_LAST = 32'd7;
    localparam logic [31:0] COMMAND_TIMEOUT_LAST = 32'd255;

    localparam logic [3:0] ST_READ_REQ     = 4'd3;
    localparam logic [3:0] ST_READ_WAIT    = 4'd4;
    localparam logic [3:0] ST_WRITE_WAIT   = 4'd6;
    localparam logic [3:0] ST_GMEM_DRAIN   = 4'd7;

    localparam logic [4:0] ERR_HEADER          = 5'd1;
    localparam logic [4:0] ERR_SHAPE           = 5'd2;
    localparam logic [4:0] ERR_STRIDE_ALIGN    = 5'd3;
    localparam logic [4:0] ERR_SOURCE_BOUNDS   = 5'd4;
    localparam logic [4:0] ERR_DEST_BOUNDS     = 5'd5;
    localparam logic [4:0] ERR_OVERLAP         = 5'd6;
    localparam logic [4:0] ERR_GMEM_RESPONSE   = 5'd7;
    localparam logic [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam logic [4:0] ERR_COMMAND_TIMEOUT = 5'd9;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [1:0] opcode_i;

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
    wire [63:0] elements_done_o;
    wire [63:0] bytes_moved_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_write_beats_o;
    wire [63:0] writes_accepted_o;
    wire [63:0] active_cycles_o;

    TensorNpuTensorMover #(
        .STALL_TIMEOUT_CYCLES   (STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES (COMMAND_TIMEOUT_CYCLES)
    ) dut (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .start_i                (start_i),
        .ready_o                (ready_o),
        .busy_o                 (busy_o),
        .opcode_i               (opcode_i),
        .gmem_floor_i           (gmem_floor_i),
        .gmem_limit_i           (gmem_limit_i),
        .src0_region_base_i     (src0_region_base_i),
        .src0_region_size_i     (src0_region_size_i),
        .src0_view_off_i        (src0_view_off_i),
        .src0_ne0_i             (src0_ne0_i),
        .src0_ne1_i             (src0_ne1_i),
        .src0_ne2_i             (src0_ne2_i),
        .src0_ne3_i             (src0_ne3_i),
        .src0_nb0_i             (src0_nb0_i),
        .src0_nb1_i             (src0_nb1_i),
        .src0_nb2_i             (src0_nb2_i),
        .src0_nb3_i             (src0_nb3_i),
        .src1_region_base_i     (src1_region_base_i),
        .src1_region_size_i     (src1_region_size_i),
        .src1_view_off_i        (src1_view_off_i),
        .src1_ne0_i             (src1_ne0_i),
        .src1_ne1_i             (src1_ne1_i),
        .src1_ne2_i             (src1_ne2_i),
        .src1_ne3_i             (src1_ne3_i),
        .src1_nb0_i             (src1_nb0_i),
        .src1_nb1_i             (src1_nb1_i),
        .src1_nb2_i             (src1_nb2_i),
        .src1_nb3_i             (src1_nb3_i),
        .dst_region_base_i      (dst_region_base_i),
        .dst_region_size_i      (dst_region_size_i),
        .dst_view_off_i         (dst_view_off_i),
        .gmem_req_valid_o       (gmem_req_valid_o),
        .gmem_req_ready_i       (gmem_req_ready_i),
        .gmem_req_write_o       (gmem_req_write_o),
        .gmem_req_addr_o        (gmem_req_addr_o),
        .gmem_req_wdata_o       (gmem_req_wdata_o),
        .gmem_req_wstrb_o       (gmem_req_wstrb_o),
        .gmem_rsp_valid_i       (gmem_rsp_valid_i),
        .gmem_rsp_ready_o       (gmem_rsp_ready_o),
        .gmem_rsp_rdata_i       (gmem_rsp_rdata_i),
        .gmem_rsp_error_i       (gmem_rsp_error_i),
        .done_o                 (done_o),
        .error_o                (error_o),
        .error_code_o           (error_code_o),
        .elements_done_o        (elements_done_o),
        .bytes_moved_o          (bytes_moved_o),
        .gmem_read_beats_o      (gmem_read_beats_o),
        .gmem_write_beats_o     (gmem_write_beats_o),
        .writes_accepted_o      (writes_accepted_o),
        .active_cycles_o        (active_cycles_o)
    );

    always #5 clk_i <= ~clk_i;

    // ------------------------------------------------------------------
    // 纯 raw-byte、单 outstanding 的确定性 8B GMEM 模型。
    // ------------------------------------------------------------------
    /* verilator lint_off MULTIDRIVEN */
    reg [7:0] gmem_bytes [0:GMEM_BYTES-1];
    /* verilator lint_on MULTIDRIVEN */
    reg allow_requests_q;
    reg force_ready_now_q;
    integer read_response_delay_cfg;
    integer write_response_delay_cfg;
    reg inject_read_error_q;
    reg inject_write_error_q;

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
    reg [63:0] model_cycle_q;
    integer lane;

    integer expected_error_cases;
    integer preflight_error_cases;
    integer drain_error_cases;
    integer successful_recovery_cases;
    integer positive_cases;
    integer reset_recovery_cases;
    integer busy_start_cases;

    wire [31:0] model_request_addr_w;
    assign model_request_addr_w = {20'b0, gmem_req_addr_o[11:0]};

    assign gmem_req_ready_i = !rst_i && allow_requests_q
                            && !pending_q && !gmem_rsp_valid_i
                            && (force_ready_now_q
                                || (model_cycle_q[1:0] == 2'b00));

    function automatic [63:0] read_raw64(input integer byte_addr);
        integer read_lane;
        begin
            read_raw64 = 64'b0;
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
                read_raw64[(8*read_lane) +: 8] =
                    gmem_bytes[byte_addr + read_lane];
        end
    endfunction

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-TENSOR-MOVER][FAIL] %s", reason);
            $fatal(1);
        end
    endtask

    always @(posedge clk_i) begin
        model_cycle_q <= model_cycle_q + 64'd1;
        if (rst_i) begin
            if (outstanding_count != 0) begin
                // synchronous reset 明确取消 accepted transaction；它不产生 response。
                reset_cancelled_request_count <=
                    reset_cancelled_request_count + outstanding_count;
            end
            pending_q             <= 1'b0;
            pending_write_q       <= 1'b0;
            pending_addr_q        <= 0;
            pending_error_q       <= 1'b0;
            response_countdown_q  <= 0;
            gmem_rsp_valid_i      <= 1'b0;
            gmem_rsp_rdata_i      <= 64'b0;
            gmem_rsp_error_i      <= 1'b0;
            outstanding_count     <= 0;
        end else begin
            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i
                        || (outstanding_count != 0)) begin
                    fail_case("more than one GMEM request outstanding");
                end
                if ((gmem_req_addr_o[2:0] != 3'b000)
                        || (gmem_req_addr_o[63:12] != 52'b0)
                        || (gmem_req_addr_o[11:0] > 12'd4088)) begin
                    fail_case("GMEM request outside aligned model window");
                end
                if (!gmem_req_write_o
                        && ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0))) begin
                    fail_case("read request carried write payload");
                end
                if (gmem_req_write_o
                        && (gmem_req_wstrb_o != 8'h03)
                        && (gmem_req_wstrb_o != 8'h0c)
                        && (gmem_req_wstrb_o != 8'h30)
                        && (gmem_req_wstrb_o != 8'hc0)
                        && (gmem_req_wstrb_o != 8'h0f)
                        && (gmem_req_wstrb_o != 8'hf0)) begin
                    fail_case("write strobe touched non-element lanes");
                end

                pending_q       <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q  <= model_request_addr_w;
                pending_error_q <= gmem_req_write_o
                                 ? inject_write_error_q
                                 : inject_read_error_q;
                response_countdown_q <= gmem_req_write_o
                                      ? write_response_delay_cfg
                                      : read_response_delay_cfg;
                outstanding_count    <= outstanding_count + 1;
                accepted_request_count <= accepted_request_count + 1;
                if (gmem_req_write_o) begin
                    accepted_write_count <= accepted_write_count + 1;
                    // accepted write 可先污染 shadow；architectural root 不在此区间。
                    for (lane = 0; lane < 8; lane = lane + 1) begin
                        if (gmem_req_wstrb_o[lane]) begin
                            gmem_bytes[model_request_addr_w + lane] <=
                                gmem_req_wdata_o[(8*lane) +: 8];
                        end
                    end
                end else begin
                    accepted_read_count <= accepted_read_count + 1;
                end
                if (maximum_outstanding < (outstanding_count + 1))
                    maximum_outstanding <= outstanding_count + 1;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (response_countdown_q > 0) begin
                    response_countdown_q <= response_countdown_q - 1;
                end else begin
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_error_i <= pending_error_q;
                    gmem_rsp_rdata_i <= pending_write_q
                                      ? 64'b0 : read_raw64(pending_addr_q);
                end
            end

            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (outstanding_count != 1)
                    fail_case("response consumed without one outstanding beat");
                pending_q            <= 1'b0;
                gmem_rsp_valid_i     <= 1'b0;
                gmem_rsp_error_i     <= 1'b0;
                outstanding_count    <= outstanding_count - 1;
                response_count       <= response_count + 1;
            end
        end
    end

    // Procedural protocol monitors；本构建按合同不启用 assertion。
    reg request_hold_q;
    reg [63:0] held_addr_q;
    reg held_write_q;
    reg [63:0] held_wdata_q;
    reg [7:0] held_wstrb_q;
    reg previous_done_q;
    reg previous_error_q;

    always @(posedge clk_i) begin
        if (rst_i) begin
            request_hold_q <= 1'b0;
            held_addr_q    <= 64'b0;
            held_write_q   <= 1'b0;
            held_wdata_q   <= 64'b0;
            held_wstrb_q   <= 8'b0;
            previous_done_q  <= 1'b0;
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
            if (gmem_rsp_ready_o && (dut.state_q != ST_READ_WAIT)
                    && (dut.state_q != ST_WRITE_WAIT)
                    && (dut.state_q != ST_GMEM_DRAIN)) begin
                fail_case("response credit outside WAIT/DRAIN");
            end
            if (request_hold_q
                    && ((gmem_req_addr_o != held_addr_q)
                        || (gmem_req_write_o != held_write_q)
                        || (gmem_req_wdata_o != held_wdata_q)
                        || (gmem_req_wstrb_o != held_wstrb_q))) begin
                fail_case("request payload changed under backpressure");
            end
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                request_hold_q <= 1'b1;
                held_addr_q    <= gmem_req_addr_o;
                held_write_q   <= gmem_req_write_o;
                held_wdata_q   <= gmem_req_wdata_o;
                held_wstrb_q   <= gmem_req_wstrb_o;
            end else begin
                request_hold_q <= 1'b0;
            end
            previous_done_q  <= done_o;
            previous_error_q <= error_o;
        end
    end

    // ------------------------------------------------------------------
    // Raw-byte stimulus/check helpers。
    // ------------------------------------------------------------------
    task automatic write_raw16(input logic [15:0] byte_addr,
                               input logic [15:0] value);
        integer base_addr;
        begin
            base_addr = {16'b0, byte_addr};
            gmem_bytes[base_addr]     = value[7:0];
            gmem_bytes[base_addr + 1] = value[15:8];
        end
    endtask

    task automatic write_raw32(input logic [15:0] byte_addr,
                               input logic [31:0] value);
        integer base_addr;
        begin
            base_addr = {16'b0, byte_addr};
            gmem_bytes[base_addr]     = value[7:0];
            gmem_bytes[base_addr + 1] = value[15:8];
            gmem_bytes[base_addr + 2] = value[23:16];
            gmem_bytes[base_addr + 3] = value[31:24];
        end
    endtask

    function automatic [15:0] read_raw16(input logic [15:0] byte_addr);
        integer base_addr;
        begin
            base_addr = {16'b0, byte_addr};
            read_raw16 = {gmem_bytes[base_addr + 1],
                          gmem_bytes[base_addr]};
        end
    endfunction

    function automatic [31:0] read_raw32(input logic [15:0] byte_addr);
        integer base_addr;
        begin
            base_addr = {16'b0, byte_addr};
            read_raw32 = {gmem_bytes[base_addr + 3],
                          gmem_bytes[base_addr + 2],
                          gmem_bytes[base_addr + 1],
                          gmem_bytes[base_addr]};
        end
    endfunction

    task automatic fill_bytes(input logic [15:0] first_addr,
                              input integer byte_count,
                              input logic [7:0] value);
        integer fill_index;
        integer base_addr;
        begin
            base_addr = {16'b0, first_addr};
            for (fill_index = 0; fill_index < byte_count;
                    fill_index = fill_index + 1) begin
                gmem_bytes[base_addr + fill_index] = value;
            end
        end
    endtask

    task automatic check_raw16(input string case_name,
                               input logic [15:0] byte_addr,
                               input logic [15:0] expected);
        begin
            if (read_raw16(byte_addr) !== expected) begin
                $display("[NPU-TENSOR-MOVER][FAIL] %s addr=%0h expected=%04h got=%04h",
                         case_name, byte_addr, expected, read_raw16(byte_addr));
                $fatal(1);
            end
        end
    endtask

    task automatic check_raw32(input string case_name,
                               input logic [15:0] byte_addr,
                               input logic [31:0] expected);
        begin
            if (read_raw32(byte_addr) !== expected) begin
                $display("[NPU-TENSOR-MOVER][FAIL] %s addr=%0h expected=%08h got=%08h",
                         case_name, byte_addr, expected, read_raw32(byte_addr));
                $fatal(1);
            end
        end
    endtask

    task automatic check_root_canary(input string case_name);
        integer canary_index;
        begin
            for (canary_index = 32'h0000_0040;
                    canary_index < 32'h0000_0050;
                    canary_index = canary_index + 1) begin
                if (gmem_bytes[canary_index] !== 8'h5a)
                    fail_case({case_name, " modified active-root canary"});
            end
        end
    endtask

    task automatic set_default_command;
        begin
            start_i            = 1'b0;
            opcode_i           = 2'd0;
            gmem_floor_i       = 64'd0;
            gmem_limit_i       = 64'd4096;
            src0_region_base_i = 64'h0100;
            src0_region_size_i = 64'h0100;
            src0_view_off_i    = 64'd0;
            src0_ne0_i         = 32'd1;
            src0_ne1_i         = 32'd1;
            src0_ne2_i         = 32'd1;
            src0_ne3_i         = 32'd1;
            src0_nb0_i         = 64'd4;
            src0_nb1_i         = 64'd4;
            src0_nb2_i         = 64'd4;
            src0_nb3_i         = 64'd4;
            src1_region_base_i = 64'h0500;
            src1_region_size_i = 64'h0100;
            src1_view_off_i    = 64'd0;
            src1_ne0_i         = 32'd1;
            src1_ne1_i         = 32'd1;
            src1_ne2_i         = 32'd1;
            src1_ne3_i         = 32'd1;
            src1_nb0_i         = 64'd4;
            src1_nb1_i         = 64'd4;
            src1_nb2_i         = 64'd4;
            src1_nb3_i         = 64'd4;
            dst_region_base_i  = 64'h0800;
            dst_region_size_i  = 64'h0100;
            dst_view_off_i     = 64'd0;
            allow_requests_q   = 1'b1;
            force_ready_now_q  = 1'b0;
            read_response_delay_cfg  = 2;
            write_response_delay_cfg = 2;
            inject_read_error_q  = 1'b0;
            inject_write_error_q = 1'b0;
        end
    endtask

    task automatic reset_engine;
        begin
            start_i = 1'b0;
            rst_i   = 1'b1;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(posedge clk_i);
            @(negedge clk_i);
            if (!ready_o || busy_o || done_o || error_o
                    || gmem_req_valid_o || gmem_rsp_ready_o) begin
                fail_case("reset did not establish clean IDLE");
            end
        end
    endtask

    task automatic launch_command;
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!ready_o) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 40)
                    fail_case("launch waited too long for ready");
            end
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if (!busy_o || ready_o)
                fail_case("start handshake did not enter busy command");
        end
    endtask

    task automatic finish_done(input string case_name,
                               input integer max_wait_cycles);
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!done_o) begin
                if (error_o)
                    fail_case({case_name, " produced unexpected error"});
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " DONE timeout"});
            end
            if (error_o || ready_o || !busy_o
                    || (error_code_o != 5'd0)) begin
                fail_case({case_name, " malformed DONE terminal"});
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o)
                fail_case({case_name, " DONE was not one cycle"});
        end
    endtask

    task automatic finish_error(input string case_name,
                                input logic [4:0] expected_code,
                                input integer max_wait_cycles);
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!error_o) begin
                if (done_o)
                    fail_case({case_name, " produced unexpected DONE"});
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " ERROR timeout"});
            end
            if (done_o || ready_o || !busy_o
                    || (error_code_o != expected_code)) begin
                fail_case({case_name, " malformed ERROR terminal"});
            end
            expected_error_cases = expected_error_cases + 1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o)
                fail_case({case_name, " ERROR was not one cycle"});
        end
    endtask

    task automatic expect_preflight_error(input string case_name,
                                          input logic [4:0] expected_code);
        integer requests_before;
        begin
            requests_before = accepted_request_count;
            launch_command();
            finish_error(case_name, expected_code, 30);
            if ((accepted_request_count != requests_before)
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (elements_done_o != 64'b0)
                    || (bytes_moved_o != 64'b0)) begin
                fail_case({case_name, " preflight error leaked GMEM activity"});
            end
            preflight_error_cases = preflight_error_cases + 1;
        end
    endtask

    task automatic prepare_clean_one_element;
        begin
            set_default_command();
            src0_region_base_i = 64'h0700;
            src0_region_size_i = 64'h0040;
            dst_region_base_i  = 64'h0c00;
            dst_region_size_i  = 64'h0040;
            write_raw32(16'h0700, 32'hdead_beef);
            fill_bytes(16'h0c00, 8, 8'ha5);
        end
    endtask

    task automatic run_clean_recovery(input string case_name);
        begin
            prepare_clean_one_element();
            force_ready_now_q = 1'b1;
            launch_command();
            finish_done(case_name, 80);
            if ((elements_done_o != 64'd1)
                    || (bytes_moved_o != 64'd4)
                    || (gmem_read_beats_o != 64'd1)
                    || (gmem_write_beats_o != 64'd1)
                    || (writes_accepted_o != 64'd1)) begin
                fail_case({case_name, " recovery audit counters mismatch"});
            end
            check_raw32(case_name, 16'h0c00, 32'hdead_beef);
            check_root_canary(case_name);
            successful_recovery_cases = successful_recovery_cases + 1;
        end
    endtask

    task automatic wait_for_drain_error(
        input string case_name,
        input logic [4:0] expected_cause,
        input logic [4:0] expected_terminal,
        input integer max_wait_cycles
    );
        integer wait_cycles;
        integer accepted_at_drain;
        reg [63:0] elements_at_drain;
        reg [63:0] bytes_at_drain;
        reg [63:0] reads_at_drain;
        reg [63:0] writes_at_drain;
        reg [63:0] accepted_writes_at_drain;
        reg [63:0] active_at_drain;
        reg [63:0] flat_at_drain;
        reg [31:0] i0_at_drain;
        reg [31:0] command_at_drain;
        reg [31:0] stall_at_drain;
        begin
            wait_cycles = 0;
            while (dut.state_q != ST_GMEM_DRAIN) begin
                if (done_o || error_o)
                    fail_case({case_name, " terminated before drain"});
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " drain entry timeout"});
            end
            if (!busy_o || ready_o || done_o || error_o
                    || gmem_req_valid_o || !gmem_rsp_ready_o
                    || !pending_q || (outstanding_count != 1)
                    || (dut.drain_error_code_q != expected_cause)) begin
                fail_case({case_name, " malformed drain entry"});
            end

            accepted_at_drain        = accepted_request_count;
            elements_at_drain        = elements_done_o;
            bytes_at_drain           = bytes_moved_o;
            reads_at_drain           = gmem_read_beats_o;
            writes_at_drain          = gmem_write_beats_o;
            accepted_writes_at_drain = writes_accepted_o;
            active_at_drain          = active_cycles_o;
            flat_at_drain            = dut.flat_index_q;
            i0_at_drain              = dut.coord_i0_q;
            command_at_drain         = dut.command_cycles_q;
            stall_at_drain           = dut.stall_cycles_q;

            wait_cycles = 0;
            while (!error_o) begin
                if ((dut.state_q != ST_GMEM_DRAIN)
                        || gmem_req_valid_o || !gmem_rsp_ready_o
                        || (accepted_request_count != accepted_at_drain)
                        || (elements_done_o != elements_at_drain)
                        || (bytes_moved_o != bytes_at_drain)
                        || (gmem_read_beats_o != reads_at_drain)
                        || (gmem_write_beats_o != writes_at_drain)
                        || (writes_accepted_o != accepted_writes_at_drain)
                        || (active_cycles_o != active_at_drain)
                        || (dut.flat_index_q != flat_at_drain)
                        || (dut.coord_i0_q != i0_at_drain)
                        || (dut.command_cycles_q != command_at_drain)
                        || (dut.stall_cycles_q != stall_at_drain)) begin
                    fail_case({case_name, " drain changed resident result"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " late response timeout"});
            end
            if (error_code_o != expected_terminal)
                fail_case({case_name, " drain terminal code mismatch"});
            expected_error_cases = expected_error_cases + 1;
            drain_error_cases    = drain_error_cases + 1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (error_o || done_o || busy_o || !ready_o
                    || pending_q || gmem_rsp_valid_i
                    || (outstanding_count != 0)) begin
                fail_case({case_name, " drain did not reopen cleanly"});
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Directed positive raw-byte oracles。
    // ------------------------------------------------------------------
    task automatic run_strided_cpy_f32;
        begin
            set_default_command();
            opcode_i           = 2'd0;
            src0_region_base_i = 64'h0100;
            src0_region_size_i = 64'h0080;
            src0_view_off_i    = 64'd4;
            src0_ne0_i = 32'd3;
            src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd32;
            src0_nb3_i = 64'd32;
            dst_region_base_i = 64'h0800;
            dst_region_size_i = 64'h0080;
            write_raw32(16'h0104, 32'h0000_0000);
            write_raw32(16'h0108, 32'h8000_0000);
            write_raw32(16'h010c, 32'h7fc1_2345);
            write_raw32(16'h0114, 32'h3f80_0000);
            write_raw32(16'h0118, 32'hff80_0000);
            write_raw32(16'h011c, 32'h0000_0001);
            fill_bytes(16'h07f8, 40, 8'ha5);
            launch_command();
            finish_done("strided-cpy-f32", 180);
            check_raw32("strided-cpy-f32[0]", 16'h0800, 32'h0000_0000);
            check_raw32("strided-cpy-f32[1]", 16'h0804, 32'h8000_0000);
            check_raw32("strided-cpy-f32[2]", 16'h0808, 32'h7fc1_2345);
            check_raw32("strided-cpy-f32[3]", 16'h080c, 32'h3f80_0000);
            check_raw32("strided-cpy-f32[4]", 16'h0810, 32'hff80_0000);
            check_raw32("strided-cpy-f32[5]", 16'h0814, 32'h0000_0001);
            if ((gmem_bytes[12'h7ff] != 8'ha5)
                    || (gmem_bytes[12'h818] != 8'ha5)
                    || (elements_done_o != 64'd6)
                    || (bytes_moved_o != 64'd24)
                    || (gmem_read_beats_o != 64'd6)
                    || (gmem_write_beats_o != 64'd6)) begin
                fail_case("strided-cpy-f32 audit/canary mismatch");
            end
            $display("[NPU-TENSOR-MOVER][INFO] CPY_F32 elements=%0d bytes=%0d reads=%0d writes=%0d",
                     elements_done_o, bytes_moved_o,
                     gmem_read_beats_o, gmem_write_beats_o);
            positive_cases = positive_cases + 1;
        end
    endtask

    task automatic run_gate_cont_f32;
        begin
            set_default_command();
            opcode_i           = 2'd1;
            src0_region_base_i = 64'h0200;
            src0_region_size_i = 64'h0080;
            src0_view_off_i    = 64'd8;
            src0_ne0_i = 32'd2;
            src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd32;
            src0_nb3_i = 64'd32;
            dst_region_base_i = 64'h0880;
            dst_region_size_i = 64'h0040;
            write_raw32(16'h0208, 32'h3f00_0000);
            write_raw32(16'h020c, 32'hbf00_0000);
            write_raw32(16'h0218, 32'h7fc1_2345);
            write_raw32(16'h021c, 32'h8000_0000);
            fill_bytes(16'h0878, 32, 8'hc3);
            launch_command();
            finish_done("gate-cont-f32", 140);
            check_raw32("gate-cont-f32[0]", 16'h0880, 32'h3f00_0000);
            check_raw32("gate-cont-f32[1]", 16'h0884, 32'hbf00_0000);
            check_raw32("gate-cont-f32[2]", 16'h0888, 32'h7fc1_2345);
            check_raw32("gate-cont-f32[3]", 16'h088c, 32'h8000_0000);
            if ((gmem_bytes[12'h87f] != 8'hc3)
                    || (gmem_bytes[12'h890] != 8'hc3)
                    || (elements_done_o != 64'd4)
                    || (bytes_moved_o != 64'd16)
                    || (gmem_read_beats_o != 64'd4)
                    || (gmem_write_beats_o != 64'd4)) begin
                fail_case("gate-cont-f32 audit/canary mismatch");
            end
            $display("[NPU-TENSOR-MOVER][INFO] CONT_F32 elements=%0d bytes=%0d reads=%0d writes=%0d",
                     elements_done_o, bytes_moved_o,
                     gmem_read_beats_o, gmem_write_beats_o);
            positive_cases = positive_cases + 1;
        end
    endtask

    task automatic run_permuted_cont_f16;
        integer q;
        integer i0;
        integer i1;
        integer i2;
        reg [15:0] source_addr;
        reg [15:0] raw_value;
        begin
            set_default_command();
            opcode_i           = 2'd2;
            src0_region_base_i = 64'h0300;
            src0_region_size_i = 64'h0080;
            src0_view_off_i    = 64'd0;
            src0_ne0_i = 32'd3;
            src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd2;
            src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd10;
            src0_nb1_i = 64'd2;
            src0_nb2_i = 64'd32;
            src0_nb3_i = 64'd64;
            dst_region_base_i = 64'h0900;
            dst_region_size_i = 64'h0080;
            fill_bytes(16'h08f8, 48, 8'hd7);
            q = 0;
            for (i2 = 0; i2 < 2; i2 = i2 + 1) begin
                for (i1 = 0; i1 < 2; i1 = i1 + 1) begin
                    for (i0 = 0; i0 < 3; i0 = i0 + 1) begin
                        raw_value = 16'h4100 + q[15:0];
                        source_addr = 16'h0300
                                    + (i0[15:0] * 16'd10)
                                    + (i1[15:0] * 16'd2)
                                    + (i2[15:0] * 16'd32);
                        write_raw16(source_addr, raw_value);
                        q = q + 1;
                    end
                end
            end
            launch_command();
            finish_done("permuted-cont-f16", 240);
            for (q = 0; q < 12; q = q + 1)
                check_raw16("permuted-cont-f16",
                            16'h0900 + (q[15:0] << 1),
                            16'h4100 + q[15:0]);
            if ((gmem_bytes[12'h8ff] != 8'hd7)
                    || (gmem_bytes[12'h918] != 8'hd7)
                    || (elements_done_o != 64'd12)
                    || (bytes_moved_o != 64'd24)
                    || (gmem_read_beats_o != 64'd12)
                    || (gmem_write_beats_o != 64'd12)) begin
                fail_case("permuted-cont-f16 audit/canary mismatch");
            end
            $display("[NPU-TENSOR-MOVER][INFO] CONT_F16 elements=%0d bytes=%0d reads=%0d writes=%0d",
                     elements_done_o, bytes_moved_o,
                     gmem_read_beats_o, gmem_write_beats_o);
            positive_cases = positive_cases + 1;
        end
    endtask

    task automatic run_concat0_f32;
        begin
            set_default_command();
            opcode_i = 2'd3;
            src0_region_base_i = 64'h0400;
            src0_region_size_i = 64'h0080;
            src0_ne0_i = 32'd3;
            src0_ne1_i = 32'd2;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd32;
            src0_nb3_i = 64'd32;
            src1_region_base_i = 64'h0500;
            src1_region_size_i = 64'h0040;
            src1_ne0_i = 32'd1;
            src1_ne1_i = 32'd2;
            src1_ne2_i = 32'd1;
            src1_ne3_i = 32'd1;
            src1_nb0_i = 64'd4;
            src1_nb1_i = 64'd8;
            src1_nb2_i = 64'd16;
            src1_nb3_i = 64'd16;
            dst_region_base_i = 64'h0a00;
            dst_region_size_i = 64'h0080;
            write_raw32(16'h0400, 32'h0102_0304);
            write_raw32(16'h0404, 32'h1112_1314);
            write_raw32(16'h0408, 32'h2122_2324);
            write_raw32(16'h0410, 32'h3132_3334);
            write_raw32(16'h0414, 32'h4142_4344);
            write_raw32(16'h0418, 32'h5152_5354);
            write_raw32(16'h0500, 32'ha1a2_a3a4);
            write_raw32(16'h0508, 32'hb1b2_b3b4);
            fill_bytes(16'h09f8, 48, 8'he9);
            launch_command();
            finish_done("concat0-f32", 220);
            check_raw32("concat0[0]", 16'h0a00, 32'h0102_0304);
            check_raw32("concat0[1]", 16'h0a04, 32'h1112_1314);
            check_raw32("concat0[2]", 16'h0a08, 32'h2122_2324);
            check_raw32("concat0[3]", 16'h0a0c, 32'ha1a2_a3a4);
            check_raw32("concat0[4]", 16'h0a10, 32'h3132_3334);
            check_raw32("concat0[5]", 16'h0a14, 32'h4142_4344);
            check_raw32("concat0[6]", 16'h0a18, 32'h5152_5354);
            check_raw32("concat0[7]", 16'h0a1c, 32'hb1b2_b3b4);
            if ((gmem_bytes[12'h9ff] != 8'he9)
                    || (gmem_bytes[12'ha20] != 8'he9)
                    || (elements_done_o != 64'd8)
                    || (bytes_moved_o != 64'd32)
                    || (gmem_read_beats_o != 64'd8)
                    || (gmem_write_beats_o != 64'd8)) begin
                fail_case("concat0-f32 audit/canary mismatch");
            end
            $display("[NPU-TENSOR-MOVER][INFO] CONCAT0_F32 elements=%0d bytes=%0d reads=%0d writes=%0d",
                     elements_done_o, bytes_moved_o,
                     gmem_read_beats_o, gmem_write_beats_o);
            positive_cases = positive_cases + 1;
        end
    endtask

    task automatic run_empty_cpy;
        integer requests_before;
        begin
            set_default_command();
            opcode_i = 2'd0;
            src0_region_base_i = 64'h0600;
            src0_region_size_i = 64'h0020;
            src0_view_off_i    = 64'h0020;
            src0_ne0_i = 32'd4;
            src0_ne1_i = 32'd0;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_nb0_i = 64'd0;
            src0_nb1_i = 64'd0;
            src0_nb2_i = 64'd0;
            src0_nb3_i = 64'd0;
            dst_region_base_i = 64'h0b00;
            dst_region_size_i = 64'h0020;
            dst_view_off_i    = 64'h0020;
            fill_bytes(16'h0b00, 32, 8'h6d);
            requests_before = accepted_request_count;
            launch_command();
            finish_done("empty-cpy", 30);
            if ((accepted_request_count != requests_before)
                    || (elements_done_o != 64'b0)
                    || (bytes_moved_o != 64'b0)
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (writes_accepted_o != 64'b0)
                    || (gmem_bytes[12'hb00] != 8'h6d)
                    || (gmem_bytes[12'hb1f] != 8'h6d)) begin
                fail_case("empty-cpy was not exact zero-access retirement");
            end
            check_root_canary("empty-cpy");
            $display("[NPU-TENSOR-MOVER][INFO] EMPTY_CPY elements=0 bytes=0 reads=0 writes=0");
            positive_cases = positive_cases + 1;
        end
    endtask

    // ------------------------------------------------------------------
    // Fail-closed preflight、response error、timeout drain 与恢复。
    // ------------------------------------------------------------------
    task automatic run_preflight_errors;
        begin
            set_default_command();
            gmem_limit_i = 64'd0;
            expect_preflight_error("invalid-window-header", ERR_HEADER);

            set_default_command();
            opcode_i = 2'd1;
            src0_ne1_i = 32'd0;
            expect_preflight_error("cont-zero-shape", ERR_SHAPE);

            set_default_command();
            src0_ne0_i = 32'd65536;
            src0_ne1_i = 32'd65536;
            expect_preflight_error("shape-product-over-2p32", ERR_SHAPE);

            set_default_command();
            src0_nb0_i = 64'd6;
            expect_preflight_error("invalid-f32-stride", ERR_STRIDE_ALIGN);

            set_default_command();
            src0_region_base_i = 64'hffff_ffff_ffff_fff8;
            src0_region_size_i = 64'd16;
            gmem_limit_i       = 64'hffff_ffff_ffff_ffff;
            expect_preflight_error("source-128bit-overflow",
                                   ERR_SOURCE_BOUNDS);

            set_default_command();
            src0_ne0_i = 32'd2;
            src0_nb0_i = 64'd8;
            src0_region_size_i = 64'd8;
            expect_preflight_error("source-last-byte-bounds",
                                   ERR_SOURCE_BOUNDS);

            set_default_command();
            src0_region_base_i = 64'h0105;
            src0_region_size_i = 64'd8;
            src0_view_off_i    = 64'd3;
            expect_preflight_error("source-read-beat-overfetch",
                                   ERR_SOURCE_BOUNDS);

            set_default_command();
            dst_region_size_i = 64'd3;
            expect_preflight_error("destination-data-bounds",
                                   ERR_DEST_BOUNDS);

            set_default_command();
            dst_view_off_i = 64'd2;
            expect_preflight_error("destination-natural-alignment",
                                   ERR_STRIDE_ALIGN);

            set_default_command();
            dst_region_base_i = 64'h0800;
            gmem_limit_i      = 64'h0805;
            expect_preflight_error("destination-beat-overfetch",
                                   ERR_DEST_BOUNDS);

            set_default_command();
            src0_ne0_i = 32'd2;
            dst_region_base_i = 64'h0104;
            dst_region_size_i = 64'h0040;
            expect_preflight_error("source-destination-overlap", ERR_OVERLAP);

            set_default_command();
            opcode_i = 2'd3;
            src1_ne1_i = 32'd2;
            expect_preflight_error("concat-outer-shape-mismatch", ERR_SHAPE);

            set_default_command();
            opcode_i = 2'd3;
            src0_ne0_i = 32'hffff_ffff;
            src1_ne0_i = 32'd1;
            expect_preflight_error("concat-ne0-addition-overflow", ERR_SHAPE);

            set_default_command();
            opcode_i = 2'd3;
            src1_region_base_i = 64'h0500;
            dst_region_base_i  = 64'h0500;
            dst_region_size_i  = 64'h0040;
            expect_preflight_error("concat-src1-destination-overlap",
                                   ERR_OVERLAP);
            check_root_canary("preflight-errors");
        end
    endtask

    task automatic run_response_error_cases;
        begin
            prepare_clean_one_element();
            force_ready_now_q   = 1'b1;
            inject_read_error_q = 1'b1;
            launch_command();
            finish_error("read-response-error", ERR_GMEM_RESPONSE, 80);
            if ((gmem_read_beats_o != 64'd1)
                    || (gmem_write_beats_o != 64'd0)
                    || (elements_done_o != 64'd0)) begin
                fail_case("read-response-error audit mismatch");
            end
            check_root_canary("read-response-error");
            run_clean_recovery("read-error-clean-recovery");

            prepare_clean_one_element();
            force_ready_now_q    = 1'b1;
            inject_write_error_q = 1'b1;
            launch_command();
            finish_error("write-response-error", ERR_GMEM_RESPONSE, 80);
            if ((gmem_read_beats_o != 64'd1)
                    || (gmem_write_beats_o != 64'd1)
                    || (writes_accepted_o != 64'd1)
                    || (elements_done_o != 64'd0)
                    || (bytes_moved_o != 64'd0)) begin
                fail_case("write-response-error audit mismatch");
            end
            check_root_canary("write-response-error");
            run_clean_recovery("write-error-clean-recovery");
        end
    endtask

    task automatic wait_for_state(input logic [3:0] expected_state,
                                  input string case_name,
                                  input integer max_wait_cycles);
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (dut.state_q != expected_state) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " state wait timeout"});
            end
        end
    endtask

    task automatic run_drain_cases;
        begin
            prepare_clean_one_element();
            force_ready_now_q       = 1'b1;
            read_response_delay_cfg = 14;
            launch_command();
            wait_for_drain_error("read-wait-stall-drain",
                                 ERR_STALL_TIMEOUT,
                                 ERR_STALL_TIMEOUT, 80);
            check_root_canary("read-wait-stall-drain");
            run_clean_recovery("read-wait-clean-recovery");

            prepare_clean_one_element();
            force_ready_now_q        = 1'b1;
            read_response_delay_cfg  = 1;
            write_response_delay_cfg = 14;
            launch_command();
            wait_for_drain_error("write-wait-stall-drain",
                                 ERR_STALL_TIMEOUT,
                                 ERR_STALL_TIMEOUT, 100);
            check_root_canary("write-wait-stall-drain");
            run_clean_recovery("write-wait-clean-recovery");

            prepare_clean_one_element();
            force_ready_now_q       = 1'b1;
            read_response_delay_cfg = 20;
            launch_command();
            wait_for_state(ST_READ_WAIT, "read-command-timeout", 40);
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.command_cycles_q;
            wait_for_drain_error("read-wait-command-drain",
                                 ERR_COMMAND_TIMEOUT,
                                 ERR_COMMAND_TIMEOUT, 100);
            run_clean_recovery("command-drain-clean-recovery");

            prepare_clean_one_element();
            force_ready_now_q       = 1'b1;
            read_response_delay_cfg = 14;
            inject_read_error_q     = 1'b1;
            launch_command();
            wait_for_drain_error("late-error-overrides-timeout",
                                 ERR_STALL_TIMEOUT,
                                 ERR_GMEM_RESPONSE, 100);
            check_root_canary("late-error-overrides-timeout");
            run_clean_recovery("late-error-clean-recovery");
        end
    endtask

    task automatic run_request_watchdog_priority;
        integer requests_before;
        begin
            prepare_clean_one_element();
            allow_requests_q  = 1'b0;
            force_ready_now_q = 1'b1;
            requests_before   = accepted_request_count;
            launch_command();
            wait_for_state(ST_READ_REQ, "request-stall-timeout", 30);
            while (dut.stall_cycles_q < STALL_TIMEOUT_LAST) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            allow_requests_q = 1'b1;
            finish_error("request-stall-timeout", ERR_STALL_TIMEOUT, 20);
            if (accepted_request_count != requests_before)
                fail_case("stall timeout lost priority to same-cycle ready");
            run_clean_recovery("request-stall-clean-recovery");

            prepare_clean_one_element();
            allow_requests_q  = 1'b0;
            force_ready_now_q = 1'b1;
            requests_before   = accepted_request_count;
            launch_command();
            wait_for_state(ST_READ_REQ, "request-command-timeout", 30);
            force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
            allow_requests_q = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.command_cycles_q;
            finish_error("request-command-timeout",
                         ERR_COMMAND_TIMEOUT, 20);
            if (accepted_request_count != requests_before)
                fail_case("command timeout lost priority to same-cycle ready");
            run_clean_recovery("request-command-clean-recovery");
        end
    endtask

    task automatic run_busy_start_ignored;
        reg [15:0] alternate_addr;
        begin
            set_default_command();
            force_ready_now_q       = 1'b1;
            read_response_delay_cfg = 4;
            src0_region_base_i = 64'h0720;
            src0_region_size_i = 64'h0040;
            src0_ne0_i = 32'd2;
            src0_nb0_i = 64'd4;
            dst_region_base_i = 64'h0d00;
            dst_region_size_i = 64'h0040;
            write_raw32(16'h0720, 32'h1234_5678);
            write_raw32(16'h0724, 32'h89ab_cdef);
            fill_bytes(16'h0d00, 16, 8'h35);
            fill_bytes(16'h0e00, 16, 8'h7c);
            launch_command();
            wait_for_state(ST_READ_WAIT, "busy-start", 30);
            if (ready_o)
                fail_case("busy command exposed ready");
            alternate_addr = 16'h0e00;
            dst_region_base_i = {48'b0, alternate_addr};
            src0_region_base_i = 64'h0100;
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            finish_done("busy-start-ignored", 100);
            check_raw32("busy-start-original[0]", 16'h0d00, 32'h1234_5678);
            check_raw32("busy-start-original[1]", 16'h0d04, 32'h89ab_cdef);
            if ((gmem_bytes[alternate_addr[11:0]] != 8'h7c)
                    || (elements_done_o != 64'd2)) begin
                fail_case("busy start overwrote resident descriptor");
            end
            busy_start_cases = busy_start_cases + 1;
        end
    endtask

    task automatic run_mid_command_reset;
        integer wait_cycles;
        begin
            set_default_command();
            force_ready_now_q       = 1'b1;
            read_response_delay_cfg = 20;
            src0_ne0_i = 32'd2;
            dst_region_base_i = 64'h0d80;
            dst_region_size_i = 64'h0040;
            write_raw32(16'h0100, 32'h0101_0101);
            write_raw32(16'h0104, 32'h0202_0202);
            launch_command();
            wait_cycles = 0;
            while (outstanding_count == 0) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 40)
                    fail_case("mid-command reset never observed accepted beat");
            end
            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (ready_o || busy_o || done_o || error_o
                        || gmem_req_valid_o || gmem_rsp_ready_o) begin
                    fail_case("reset leaked command/terminal protocol state");
                end
            end
            rst_i = 1'b0;
            repeat (3) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (done_o || error_o || busy_o || !ready_o
                        || pending_q || gmem_rsp_valid_i
                        || (outstanding_count != 0)) begin
                    fail_case("reset deassert exposed stale transaction");
                end
            end
            run_clean_recovery("mid-reset-clean-recovery");
            reset_recovery_cases = reset_recovery_cases + 1;
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
        request_hold_q = 1'b0;
        held_addr_q = 64'b0;
        held_write_q = 1'b0;
        held_wdata_q = 64'b0;
        held_wstrb_q = 8'b0;
        previous_done_q = 1'b0;
        previous_error_q = 1'b0;
        expected_error_cases = 0;
        preflight_error_cases = 0;
        drain_error_cases = 0;
        successful_recovery_cases = 0;
        positive_cases = 0;
        reset_recovery_cases = 0;
        busy_start_cases = 0;
        for (init_index = 0; init_index < GMEM_BYTES;
                init_index = init_index + 1) begin
            gmem_bytes[init_index] = 8'h00;
        end
        fill_bytes(16'h0040, 16, 8'h5a);
        set_default_command();
        reset_engine();

        run_strided_cpy_f32();
        run_gate_cont_f32();
        run_permuted_cont_f16();
        run_concat0_f32();
        run_empty_cpy();

        run_preflight_errors();
        run_response_error_cases();
        run_drain_cases();
        run_request_watchdog_priority();
        run_busy_start_ignored();
        run_mid_command_reset();

        if (maximum_outstanding != 1)
            fail_case("single-outstanding maximum was not exactly one");
        if (accepted_request_count
                != (response_count + reset_cancelled_request_count))
            fail_case("accepted/response transaction conservation mismatch");
        check_root_canary("final");

        $display("[NPU-TENSOR-MOVER][INFO] positive=%0d negative=%0d preflight=%0d drain=%0d recovery=%0d reset_recovery=%0d busy_start=%0d",
                 positive_cases, expected_error_cases,
                 preflight_error_cases, drain_error_cases,
                 successful_recovery_cases, reset_recovery_cases,
                 busy_start_cases);
        $display("[NPU-TENSOR-MOVER][INFO] model reads=%0d writes=%0d responses=%0d reset_cancelled=%0d max_outstanding=%0d",
                 accepted_read_count, accepted_write_count,
                 response_count, reset_cancelled_request_count,
                 maximum_outstanding);
        $display("[NPU-TENSOR-MOVER][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
