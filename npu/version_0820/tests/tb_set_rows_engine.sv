`timescale 1ns/1ps
`default_nettype none

// Deterministic little-endian raw-bit GMEM oracle for the production 512-lane
// Qwen SET_ROWS profiles.  There is no real/shortreal, DPI, host FPU, assertion,
// waveform, or cardinality reduction in this testbench.
module tb_set_rows_engine;

    localparam integer VALUE_ELEMENTS = 512;
    localparam integer STALL_TIMEOUT_CYCLES = 8;
    localparam integer COMMAND_TIMEOUT_CYCLES = 50000;
    localparam [31:0] STALL_TIMEOUT_LAST = STALL_TIMEOUT_CYCLES - 1;
    localparam [31:0] COMMAND_TIMEOUT_LAST = COMMAND_TIMEOUT_CYCLES - 1;

    localparam [4:0] ST_INDEX_REQ   = 5'd3;
    localparam [4:0] ST_INDEX_WAIT  = 5'd4;
    localparam [4:0] ST_VALUE_REQ   = 5'd7;
    localparam [4:0] ST_VALUE_WAIT  = 5'd8;
    localparam [4:0] ST_WRITE_WAIT  = 5'd12;
    localparam [4:0] ST_GMEM_DRAIN  = 5'd13;

    localparam [4:0] ERR_HEADER          = 5'd1;
    localparam [4:0] ERR_PROFILE_SHAPE   = 5'd2;
    localparam [4:0] ERR_ALIGNMENT       = 5'd3;
    localparam [4:0] ERR_VALUES_BOUNDS   = 5'd4;
    localparam [4:0] ERR_INDICES_BOUNDS  = 5'd5;
    localparam [4:0] ERR_DEST_BOUNDS     = 5'd6;
    localparam [4:0] ERR_OVERLAP         = 5'd7;
    localparam [4:0] ERR_INDEX_PAYLOAD   = 5'd8;
    localparam [4:0] ERR_VALUE_DOMAIN    = 5'd9;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd10;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd11;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd12;

    localparam [63:0] GMEM_FLOOR = 64'h0000_0000_0000_1000;
    localparam [63:0] GMEM_LIMIT = 64'h0000_0000_0000_f000;
    localparam [63:0] VALUES_BASE = 64'h0000_0000_0000_2000;
    localparam [63:0] VALUES_SIZE = 64'h0000_0000_0000_1000;
    localparam [63:0] INDICES_BASE = 64'h0000_0000_0000_3000;
    localparam [63:0] INDICES_SIZE = 64'h0000_0000_0000_1000;
    localparam [63:0] DST_BASE = 64'h0000_0000_0000_5000;
    localparam [63:0] DST_SIZE = 64'h0000_0000_0000_2200;
    localparam integer VALUES_ADDR = 8192;
    localparam integer INDICES_ADDR = 12288;
    localparam integer DST_ADDR = 20480;
    localparam integer DST_BYTES = 8704;
    localparam integer DST_ELEMENTS = 4352;
    localparam integer ROOT_ADDR = 36864;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [1:0] profile_i;
    reg [31:0] cache_capacity_i;
    reg [31:0] physical_slot_i;
    reg [63:0] gmem_floor_i;
    reg [63:0] gmem_limit_i;
    reg [63:0] values_region_base_i;
    reg [63:0] values_region_size_i;
    reg [63:0] values_view_off_i;
    reg [63:0] indices_region_base_i;
    reg [63:0] indices_region_size_i;
    reg [63:0] indices_view_off_i;
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
    wire [31:0] indices_validated_o;
    wire [31:0] values_validated_o;
    wire [31:0] writes_completed_o;
    wire [31:0] bytes_written_o;
    wire [31:0] gmem_read_beats_o;
    wire [31:0] gmem_write_beats_o;
    wire [31:0] writes_accepted_o;
    wire [63:0] active_cycles_o;

    TensorNpuSetRowsEngine #(
        .VALUE_ELEMENTS(VALUE_ELEMENTS),
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(COMMAND_TIMEOUT_CYCLES)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .ready_o(ready_o),
        .busy_o(busy_o),
        .profile_i(profile_i),
        .cache_capacity_i(cache_capacity_i),
        .physical_slot_i(physical_slot_i),
        .gmem_floor_i(gmem_floor_i),
        .gmem_limit_i(gmem_limit_i),
        .values_region_base_i(values_region_base_i),
        .values_region_size_i(values_region_size_i),
        .values_view_off_i(values_view_off_i),
        .indices_region_base_i(indices_region_base_i),
        .indices_region_size_i(indices_region_size_i),
        .indices_view_off_i(indices_view_off_i),
        .dst_region_base_i(dst_region_base_i),
        .dst_region_size_i(dst_region_size_i),
        .dst_view_off_i(dst_view_off_i),
        .gmem_req_valid_o(gmem_req_valid_o),
        .gmem_req_ready_i(gmem_req_ready_i),
        .gmem_req_write_o(gmem_req_write_o),
        .gmem_req_addr_o(gmem_req_addr_o),
        .gmem_req_wdata_o(gmem_req_wdata_o),
        .gmem_req_wstrb_o(gmem_req_wstrb_o),
        .gmem_rsp_valid_i(gmem_rsp_valid_i),
        .gmem_rsp_ready_o(gmem_rsp_ready_o),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
        .gmem_rsp_error_i(gmem_rsp_error_i),
        .done_o(done_o),
        .error_o(error_o),
        .error_code_o(error_code_o),
        .indices_validated_o(indices_validated_o),
        .values_validated_o(values_validated_o),
        .writes_completed_o(writes_completed_o),
        .bytes_written_o(bytes_written_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .writes_accepted_o(writes_accepted_o),
        .active_cycles_o(active_cycles_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    // ------------------------------------------------------------------
    // Single-outstanding deterministic GMEM.  A write mutates private shadow
    // bytes at request acceptance; response error/reset only revokes command
    // eligibility, exactly as required by the parent COW contract.
    // ------------------------------------------------------------------
    reg [7:0] memory_q [0:65535];
    reg allow_requests_q;
    reg periodic_backpressure_q;
    reg pending_q;
    reg pending_write_q;
    reg [15:0] pending_addr_q;
    reg pending_error_q;
    reg pending_held_q;
    integer pending_countdown_q;
    integer response_delay_q;
    integer cycle_count;
    integer accepted_request_count;
    integer accepted_read_count;
    integer accepted_write_count;
    integer response_count;
    integer outstanding_count;
    integer max_outstanding;
    integer reset_cancel_count;
    reg inject_error_enable_q;
    integer inject_error_request_number_q;
    reg hold_request_enable_q;
    integer hold_request_number_q;
    reg release_held_response_q;
    reg late_response_error_q;

    wire periodic_ready_w;
    assign periodic_ready_w = !periodic_backpressure_q
                            || (cycle_count[1:0] != 2'b00);
    assign gmem_req_ready_i = !rst_i && allow_requests_q
                            && periodic_ready_w
                            && !pending_q && !gmem_rsp_valid_i;

    integer bus_lane;
    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (rst_i) begin
            reset_cancel_count <= reset_cancel_count + outstanding_count;
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_addr_q <= 16'b0;
            pending_error_q <= 1'b0;
            pending_held_q <= 1'b0;
            pending_countdown_q <= 0;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            outstanding_count <= 0;
        end else begin
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
                response_count <= response_count + 1;
                outstanding_count <= outstanding_count - 1;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_countdown_q != 0) begin
                    pending_countdown_q <= pending_countdown_q - 1;
                end else if (!pending_held_q || release_held_response_q) begin
                    gmem_rsp_rdata_i <= 64'b0;
                    if (!pending_write_q) begin
                        for (bus_lane = 0; bus_lane < 8;
                                bus_lane = bus_lane + 1) begin
                            gmem_rsp_rdata_i[(8*bus_lane) +: 8]
                                <= memory_q[{16'b0, pending_addr_q}
                                            + bus_lane];
                        end
                    end
                    gmem_rsp_error_i <= pending_error_q
                                      || late_response_error_q;
                    gmem_rsp_valid_i <= 1'b1;
                    pending_q <= 1'b0;
                end
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if ((outstanding_count != 0) || pending_q
                        || gmem_rsp_valid_i) begin
                    $fatal(1, "[NPU-SET-ROWS][FAIL] multiple outstanding GMEM");
                end
                if ((gmem_req_addr_o[63:16] != 48'b0)
                        || (gmem_req_addr_o[2:0] != 3'b000)
                        || (gmem_req_addr_o[15:0] > 16'hfff8)) begin
                    $fatal(1, "[NPU-SET-ROWS][FAIL] illegal GMEM address=%h",
                           gmem_req_addr_o);
                end
                if (!gmem_req_write_o
                        && ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0))) begin
                    $fatal(1, "[NPU-SET-ROWS][FAIL] read carried write payload");
                end
                if (gmem_req_write_o
                        && (gmem_req_wstrb_o != 8'h03)
                        && (gmem_req_wstrb_o != 8'h0c)
                        && (gmem_req_wstrb_o != 8'h30)
                        && (gmem_req_wstrb_o != 8'hc0)) begin
                    $fatal(1, "[NPU-SET-ROWS][FAIL] invalid F16 strobe=%h",
                           gmem_req_wstrb_o);
                end

                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o[15:0];
                pending_error_q <= inject_error_enable_q
                                && ((accepted_request_count + 1)
                                    == inject_error_request_number_q);
                pending_held_q <= hold_request_enable_q
                               && ((accepted_request_count + 1)
                                   == hold_request_number_q);
                pending_countdown_q <= response_delay_q;
                accepted_request_count <= accepted_request_count + 1;
                outstanding_count <= outstanding_count + 1;
                if ((outstanding_count + 1) > max_outstanding)
                    max_outstanding <= outstanding_count + 1;

                if (gmem_req_write_o) begin
                    accepted_write_count <= accepted_write_count + 1;
                    for (bus_lane = 0; bus_lane < 8;
                            bus_lane = bus_lane + 1) begin
                        if (gmem_req_wstrb_o[bus_lane]) begin
                            memory_q[{16'b0, gmem_req_addr_o[15:0]}
                                     + bus_lane]
                                <= gmem_req_wdata_o[(8*bus_lane) +: 8];
                        end
                    end
                end else begin
                    accepted_read_count <= accepted_read_count + 1;
                end
            end
        end
    end

    // Held-request and response-credit protocol monitors use only sampled RTL
    // signals; no simulator assertion machinery is enabled.
    reg held_request_q;
    reg [63:0] held_addr_q;
    reg held_write_q;
    reg [63:0] held_wdata_q;
    reg [7:0] held_wstrb_q;
    always @(posedge clk_i) begin
        if (rst_i) begin
            held_request_q <= 1'b0;
            held_addr_q <= 64'b0;
            held_write_q <= 1'b0;
            held_wdata_q <= 64'b0;
            held_wstrb_q <= 8'b0;
        end else begin
            if (held_request_q && gmem_req_valid_o
                    && ((gmem_req_addr_o != held_addr_q)
                        || (gmem_req_write_o != held_write_q)
                        || (gmem_req_wdata_o != held_wdata_q)
                        || (gmem_req_wstrb_o != held_wstrb_q))) begin
                $fatal(1, "[NPU-SET-ROWS][FAIL] request payload changed under backpressure");
            end
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                held_request_q <= 1'b1;
                held_addr_q <= gmem_req_addr_o;
                held_write_q <= gmem_req_write_o;
                held_wdata_q <= gmem_req_wdata_o;
                held_wstrb_q <= gmem_req_wstrb_o;
            end else begin
                held_request_q <= 1'b0;
            end
            if (gmem_rsp_ready_o && (outstanding_count != 1)) begin
                $fatal(1, "[NPU-SET-ROWS][FAIL] response credit without one outstanding");
            end
            if ((writes_accepted_o != 0)
                    && (values_validated_o != 32'd512)) begin
                $fatal(1, "[NPU-SET-ROWS][FAIL] write before complete value preflight");
            end
            if ((writes_accepted_o != 0)
                    && (((dut.profile_q == 2'd0)
                         && (indices_validated_o != 32'd1))
                        || ((dut.profile_q == 2'd1)
                            && (indices_validated_o != 32'd512)))) begin
                $fatal(1, "[NPU-SET-ROWS][FAIL] write before complete index preflight");
            end
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-SET-ROWS][FAIL] %s state=%0d err=%0d idx=%0d val=%0d accepted=%0d completed=%0d req=%0d outstanding=%0d active=%0d",
                     reason, dut.state_q, error_code_o,
                     indices_validated_o, values_validated_o,
                     writes_accepted_o, writes_completed_o,
                     accepted_request_count, outstanding_count,
                     active_cycles_o);
            $fatal(1, "[NPU-SET-ROWS][FAIL]");
        end
    endtask

    task automatic write_u32(input integer byte_addr,
                             input logic [31:0] value);
        integer lane;
        begin
            for (lane = 0; lane < 4; lane = lane + 1)
                memory_q[byte_addr + lane] = value[(8*lane) +: 8];
        end
    endtask

    task automatic write_u64(input integer byte_addr,
                             input logic [63:0] value);
        integer lane;
        begin
            for (lane = 0; lane < 8; lane = lane + 1)
                memory_q[byte_addr + lane] = value[(8*lane) +: 8];
        end
    endtask

    function automatic logic [15:0] read_u16(input integer byte_addr);
        begin
            read_u16 = {memory_q[byte_addr + 1], memory_q[byte_addr]};
        end
    endfunction

    function automatic logic [31:0] source_raw(input integer lane);
        begin
            case (lane & 7)
                0: source_raw = 32'h3f800000;
                1: source_raw = 32'hc0000000;
                2: source_raw = 32'h3f000000;
                3: source_raw = 32'h477fe000;
                4: source_raw = 32'h3f801000;
                5: source_raw = 32'h3f803000;
                6: source_raw = 32'h33800000;
                default: source_raw = 32'h80000000;
            endcase
        end
    endfunction

    function automatic logic [15:0] expected_half(input integer lane);
        begin
            case (lane & 7)
                0: expected_half = 16'h3c00;
                1: expected_half = 16'hc000;
                2: expected_half = 16'h3800;
                3: expected_half = 16'h7bff;
                4: expected_half = 16'h3c00;
                5: expected_half = 16'h3c02;
                6: expected_half = 16'h0001;
                default: expected_half = 16'h8000;
            endcase
        end
    endfunction

    task automatic set_default_command(input logic [1:0] profile);
        begin
            profile_i = profile;
            cache_capacity_i = 32'd8;
            physical_slot_i = 32'd3;
            gmem_floor_i = GMEM_FLOOR;
            gmem_limit_i = GMEM_LIMIT;
            values_region_base_i = VALUES_BASE;
            values_region_size_i = VALUES_SIZE;
            values_view_off_i = 64'b0;
            indices_region_base_i = INDICES_BASE;
            indices_region_size_i = INDICES_SIZE;
            indices_view_off_i = 64'b0;
            dst_region_base_i = DST_BASE;
            dst_region_size_i = DST_SIZE;
            dst_view_off_i = 64'b0;
        end
    endtask

    task automatic clear_fault_controls;
        begin
            allow_requests_q = 1'b1;
            periodic_backpressure_q = 1'b1;
            response_delay_q = 2;
            inject_error_enable_q = 1'b0;
            inject_error_request_number_q = -1;
            hold_request_enable_q = 1'b0;
            hold_request_number_q = -1;
            release_held_response_q = 1'b0;
            late_response_error_q = 1'b0;
        end
    endtask

    task automatic prepare_memory(input logic [1:0] profile);
        integer lane;
        integer byte_addr;
        logic [63:0] index_value;
        begin
            for (byte_addr = DST_ADDR;
                    byte_addr < (DST_ADDR + DST_BYTES);
                    byte_addr = byte_addr + 1)
                memory_q[byte_addr] = 8'ha5;
            for (byte_addr = ROOT_ADDR;
                    byte_addr < (ROOT_ADDR + 64);
                    byte_addr = byte_addr + 1)
                memory_q[byte_addr] = 8'h3c;
            for (lane = 0; lane < VALUE_ELEMENTS; lane = lane + 1)
                write_u32(VALUES_ADDR + (lane * 4), source_raw(lane));
            if (profile == 2'd0) begin
                write_u64(INDICES_ADDR, 64'd3);
            end else begin
                for (lane = 0; lane < VALUE_ELEMENTS; lane = lane + 1) begin
                    index_value = (lane * 8) + 3;
                    write_u64(INDICES_ADDR + (lane * 8),
                              index_value);
                end
            end
        end
    endtask

    task automatic check_root_canary(input string case_name);
        integer byte_addr;
        begin
            for (byte_addr = ROOT_ADDR;
                    byte_addr < (ROOT_ADDR + 64);
                    byte_addr = byte_addr + 1) begin
                if (memory_q[byte_addr] !== 8'h3c)
                    fail_case({case_name, ": active-root canary changed"});
            end
        end
    endtask

    task automatic check_shadow_pristine(input string case_name);
        integer byte_addr;
        begin
            for (byte_addr = DST_ADDR;
                    byte_addr < (DST_ADDR + DST_BYTES);
                    byte_addr = byte_addr + 1) begin
                if (memory_q[byte_addr] !== 8'ha5)
                    fail_case({case_name, ": shadow changed before writes"});
            end
        end
    endtask

    task automatic reset_engine;
        begin
            @(negedge clk_i);
            rst_i = 1'b1;
            start_i = 1'b0;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(negedge clk_i);
            if (!ready_o || busy_o || done_o || error_o
                    || gmem_req_valid_o || gmem_rsp_ready_o
                    || pending_q || gmem_rsp_valid_i
                    || (outstanding_count != 0)) begin
                fail_case("reset did not establish clean IDLE");
            end
        end
    endtask

    task automatic launch_command;
        begin
            while (!ready_o) @(negedge clk_i);
            start_i = 1'b1;
            @(negedge clk_i);
            start_i = 1'b0;
        end
    endtask

    task automatic wait_for_state(input logic [4:0] expected_state,
                                  input string case_name,
                                  input integer limit);
        integer waited;
        begin
            waited = 0;
            while (dut.state_q != expected_state) begin
                @(negedge clk_i);
                waited = waited + 1;
                if (done_o || error_o || (waited > limit))
                    fail_case({case_name, ": state wait failed"});
            end
        end
    endtask

    task automatic wait_for_done(input string case_name,
                                 input integer limit);
        integer waited;
        begin
            waited = 0;
            while (!done_o) begin
                @(negedge clk_i);
                waited = waited + 1;
                if (error_o || (waited > limit))
                    fail_case({case_name, ": DONE wait failed"});
            end
            if (error_code_o != 5'd0)
                fail_case({case_name, ": DONE carried error code"});
        end
    endtask

    task automatic wait_for_error(input string case_name,
                                  input logic [4:0] expected_error,
                                  input integer limit);
        integer waited;
        begin
            waited = 0;
            while (!error_o) begin
                @(negedge clk_i);
                waited = waited + 1;
                if (done_o || (waited > limit))
                    fail_case({case_name, ": ERROR wait failed"});
            end
            if (error_code_o != expected_error)
                fail_case({case_name, ": wrong error code"});
        end
    endtask

    task automatic finish_terminal;
        begin
            @(negedge clk_i);
            if (!ready_o || busy_o || done_o || error_o)
                fail_case("terminal was not a single cycle");
        end
    endtask

    task automatic check_canonical_shadow(input logic [1:0] profile,
                                          input string case_name);
        integer elem;
        integer lane;
        logic [15:0] expected;
        begin
            for (elem = 0; elem < DST_ELEMENTS; elem = elem + 1) begin
                expected = 16'ha5a5;
                if ((profile == 2'd0) && (elem >= (3 * 512))
                        && (elem < (4 * 512))) begin
                    lane = elem - (3 * 512);
                    expected = expected_half(lane);
                end else if ((profile == 2'd1) && (elem >= 3)
                        && (((elem - 3) % 8) == 0)
                        && (((elem - 3) / 8) < 512)) begin
                    lane = (elem - 3) / 8;
                    expected = expected_half(lane);
                end
                if (read_u16(DST_ADDR + (elem * 2)) !== expected)
                    fail_case({case_name, ": destination oracle mismatch"});
            end
            check_root_canary(case_name);
        end
    endtask

    integer positive_cases;
    integer negative_index_cases;
    integer value_domain_cases;
    integer preflight_cases;
    integer response_error_cases;
    integer drain_cases;
    integer recovery_cases;
    integer reset_cases;
    integer busy_start_cases;
    integer request_watchdog_cases;

    task automatic run_canonical(input logic [1:0] profile,
                                 input bit probe_busy_start,
                                 input string case_name);
        begin
            clear_fault_controls();
            set_default_command(profile);
            prepare_memory(profile);
            reset_engine();
            launch_command();
            if (probe_busy_start) begin
                wait_for_state(ST_VALUE_REQ, case_name, 200);
                physical_slot_i = 32'd7;
                profile_i = 2'd1;
                start_i = 1'b1;
                @(negedge clk_i);
                start_i = 1'b0;
                busy_start_cases = busy_start_cases + 1;
            end
            wait_for_done(case_name, 30000);
            if (indices_validated_o != ((profile == 2'd0) ? 32'd1 : 32'd512)
                    || (values_validated_o != 32'd512)
                    || (writes_completed_o != 32'd512)
                    || (bytes_written_o != 32'd1024)
                    || (gmem_read_beats_o
                        != ((profile == 2'd0) ? 32'd513 : 32'd1024))
                    || (gmem_write_beats_o != 32'd512)
                    || (writes_accepted_o != 32'd512)
                    || (active_cycles_o == 64'b0)) begin
                fail_case({case_name, ": canonical counters mismatch"});
            end
            check_canonical_shadow(profile, case_name);
            positive_cases = positive_cases + 1;
            finish_terminal();
        end
    endtask

    task automatic run_clean_recovery(input string case_name);
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            launch_command();
            wait_for_done(case_name, 30000);
            if ((indices_validated_o != 32'd1)
                    || (values_validated_o != 32'd512)
                    || (writes_completed_o != 32'd512)
                    || (writes_accepted_o != 32'd512))
                fail_case({case_name, ": recovery counters mismatch"});
            check_canonical_shadow(2'd0, case_name);
            recovery_cases = recovery_cases + 1;
            finish_terminal();
        end
    endtask

    task automatic run_index_error(input integer variant,
                                   input string case_name);
        logic [1:0] selected_profile;
        begin
            selected_profile = (variant == 0) ? 2'd0 : 2'd1;
            clear_fault_controls();
            set_default_command(selected_profile);
            prepare_memory(selected_profile);
            case (variant)
                0: write_u64(INDICES_ADDR, 64'd4);
                1: write_u64(INDICES_ADDR + (100 * 8), 64'd804);
                2: write_u64(INDICES_ADDR + (20 * 8),
                             64'hffff_ffff_ffff_ffff);
                default: write_u64(INDICES_ADDR + (20 * 8),
                                   64'd155);
            endcase
            reset_engine();
            launch_command();
            wait_for_error(case_name, ERR_INDEX_PAYLOAD, 10000);
            if ((writes_accepted_o != 32'b0)
                    || (values_validated_o != 32'b0))
                fail_case({case_name, ": index failure issued later phase"});
            check_shadow_pristine(case_name);
            check_root_canary(case_name);
            negative_index_cases = negative_index_cases + 1;
            finish_terminal();
        end
    endtask

    task automatic run_value_error(input logic [31:0] bad_raw,
                                   input string case_name);
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            write_u32(VALUES_ADDR + (17 * 4), bad_raw);
            reset_engine();
            launch_command();
            wait_for_error(case_name, ERR_VALUE_DOMAIN, 15000);
            if ((writes_accepted_o != 32'b0)
                    || (writes_completed_o != 32'b0))
                fail_case({case_name, ": value failure wrote shadow"});
            check_shadow_pristine(case_name);
            check_root_canary(case_name);
            value_domain_cases = value_domain_cases + 1;
            finish_terminal();
        end
    endtask

    task automatic run_preflight_error(input integer variant,
                                       input logic [4:0] expected_error,
                                       input string case_name);
        integer requests_before;
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            case (variant)
                0: profile_i = 2'd2;
                1: cache_capacity_i = 32'd0;
                2: physical_slot_i = 32'd8;
                3: gmem_limit_i = GMEM_FLOOR;
                4: values_view_off_i = 64'd2;
                5: indices_view_off_i = 64'd4;
                6: dst_view_off_i = 64'd1;
                7: values_region_size_i = 64'd2044;
                8: begin
                    values_region_base_i = 64'hffff_ffff_ffff_f000;
                    values_region_size_i = 64'h0000_0000_0000_2000;
                end
                9: begin
                    values_region_base_i = 64'h0000_0000_0000_2004;
                    values_region_size_i = 64'd2048;
                end
                10: indices_region_size_i = 64'd7;
                11: begin
                    indices_region_base_i = 64'hffff_ffff_ffff_f000;
                    indices_region_size_i = 64'h0000_0000_0000_2000;
                end
                12: dst_region_size_i = 64'd4094;
                13: begin
                    dst_region_base_i = 64'hffff_ffff_ffff_f000;
                    dst_region_size_i = 64'h0000_0000_0000_3000;
                end
                14: begin
                    profile_i = 2'd1;
                    dst_view_off_i = 64'd2;
                    gmem_limit_i = 64'h0000_0000_0000_6ffa;
                end
                15: indices_region_base_i = VALUES_BASE;
                16: begin
                    dst_region_base_i = VALUES_BASE;
                    dst_region_size_i = DST_SIZE;
                end
                default: begin
                    dst_region_base_i = INDICES_BASE;
                    dst_region_size_i = DST_SIZE;
                end
            endcase
            reset_engine();
            requests_before = accepted_request_count;
            launch_command();
            wait_for_error(case_name, expected_error, 100);
            if ((accepted_request_count != requests_before)
                    || (gmem_read_beats_o != 32'b0)
                    || (gmem_write_beats_o != 32'b0)
                    || (writes_accepted_o != 32'b0))
                fail_case({case_name, ": preflight emitted GMEM request"});
            check_shadow_pristine(case_name);
            check_root_canary(case_name);
            preflight_cases = preflight_cases + 1;
            finish_terminal();
        end
    endtask

    task automatic run_response_error(input integer relative_request,
                                      input string case_name);
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            reset_engine();
            inject_error_enable_q = 1'b1;
            inject_error_request_number_q = accepted_request_count
                                          + relative_request;
            launch_command();
            wait_for_error(case_name, ERR_GMEM_RESPONSE, 30000);
            if (done_o)
                fail_case({case_name, ": response error reported done"});
            check_root_canary(case_name);
            response_error_cases = response_error_cases + 1;
            finish_terminal();
            run_clean_recovery({case_name, ": clean recovery"});
        end
    endtask

    task automatic run_drain_case(input integer relative_request,
                                  input logic [4:0] timeout_cause,
                                  input bit late_error,
                                  input logic [4:0] expected_terminal,
                                  input logic [4:0] wait_state,
                                  input string case_name);
        reg [31:0] idx_snapshot;
        reg [31:0] val_snapshot;
        reg [31:0] accepted_snapshot;
        reg [31:0] completed_snapshot;
        reg [31:0] reads_snapshot;
        reg [31:0] writes_snapshot;
        reg [63:0] active_snapshot;
        reg [31:0] command_snapshot;
        reg [31:0] stall_snapshot;
        integer request_snapshot;
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            reset_engine();
            hold_request_enable_q = 1'b1;
            hold_request_number_q = accepted_request_count + relative_request;
            launch_command();
            wait_for_state(wait_state, case_name, 25000);
            while (!pending_q) @(negedge clk_i);
            if (timeout_cause == ERR_COMMAND_TIMEOUT) begin
                force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
                @(posedge clk_i);
                @(negedge clk_i);
                release dut.command_cycles_q;
            end
            wait_for_state(ST_GMEM_DRAIN, case_name, 100);
            if (gmem_req_valid_o || !gmem_rsp_ready_o
                    || !dut.outstanding_q
                    || (dut.drain_error_code_q != timeout_cause))
                fail_case({case_name, ": malformed drain entry"});
            idx_snapshot = indices_validated_o;
            val_snapshot = values_validated_o;
            accepted_snapshot = writes_accepted_o;
            completed_snapshot = writes_completed_o;
            reads_snapshot = gmem_read_beats_o;
            writes_snapshot = gmem_write_beats_o;
            active_snapshot = active_cycles_o;
            command_snapshot = dut.command_cycles_q;
            stall_snapshot = dut.stall_cycles_q;
            request_snapshot = accepted_request_count;
            repeat (3) begin
                @(negedge clk_i);
                if ((dut.state_q != ST_GMEM_DRAIN)
                        || gmem_req_valid_o || !gmem_rsp_ready_o
                        || (indices_validated_o != idx_snapshot)
                        || (values_validated_o != val_snapshot)
                        || (writes_accepted_o != accepted_snapshot)
                        || (writes_completed_o != completed_snapshot)
                        || (gmem_read_beats_o != reads_snapshot)
                        || (gmem_write_beats_o != writes_snapshot)
                        || (active_cycles_o != active_snapshot)
                        || (dut.command_cycles_q != command_snapshot)
                        || (dut.stall_cycles_q != stall_snapshot)
                        || (accepted_request_count != request_snapshot))
                    fail_case({case_name, ": drain did not freeze transaction"});
            end
            late_response_error_q = late_error;
            release_held_response_q = 1'b1;
            wait_for_error(case_name, expected_terminal, 100);
            check_root_canary(case_name);
            drain_cases = drain_cases + 1;
            finish_terminal();
            run_clean_recovery({case_name, ": clean recovery"});
        end
    endtask

    task automatic run_request_watchdog(input logic [4:0] cause,
                                        input string case_name);
        integer requests_before;
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            reset_engine();
            allow_requests_q = 1'b0;
            requests_before = accepted_request_count;
            launch_command();
            wait_for_state(ST_INDEX_REQ, case_name, 50);
            if (cause == ERR_STALL_TIMEOUT) begin
                while (dut.stall_cycles_q < STALL_TIMEOUT_LAST)
                    @(negedge clk_i);
                allow_requests_q = 1'b1;
            end else begin
                force dut.command_cycles_q = COMMAND_TIMEOUT_LAST;
                allow_requests_q = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                release dut.command_cycles_q;
            end
            wait_for_error(case_name, cause, 30);
            if (accepted_request_count != requests_before)
                fail_case({case_name, ": late ready accepted timed-out request"});
            check_shadow_pristine(case_name);
            request_watchdog_cases = request_watchdog_cases + 1;
            finish_terminal();
            run_clean_recovery({case_name, ": clean recovery"});
        end
    endtask

    task automatic run_reset_case(input integer relative_request,
                                  input logic [4:0] wait_state,
                                  input string case_name);
        begin
            clear_fault_controls();
            set_default_command(2'd0);
            prepare_memory(2'd0);
            reset_engine();
            hold_request_enable_q = 1'b1;
            hold_request_number_q = accepted_request_count + relative_request;
            launch_command();
            wait_for_state(wait_state, case_name, 25000);
            while (!pending_q) @(negedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b1;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            if (done_o || error_o || busy_o || gmem_req_valid_o
                    || gmem_rsp_ready_o || pending_q || gmem_rsp_valid_i
                    || (outstanding_count != 0))
                fail_case({case_name, ": reset leaked resident transaction"});
            rst_i = 1'b0;
            @(negedge clk_i);
            if (!ready_o || done_o || error_o || pending_q
                    || gmem_rsp_valid_i || (outstanding_count != 0))
                fail_case({case_name, ": reset did not reopen cleanly"});
            check_root_canary(case_name);
            if ((relative_request < 514) && (writes_accepted_o != 32'b0))
                fail_case({case_name, ": pre-write reset saw write acceptance"});
            reset_cases = reset_cases + 1;
            run_clean_recovery({case_name, ": clean recovery"});
        end
    endtask

    initial begin
        rst_i = 1'b1;
        start_i = 1'b0;
        set_default_command(2'd0);
        gmem_rsp_valid_i = 1'b0;
        gmem_rsp_rdata_i = 64'b0;
        gmem_rsp_error_i = 1'b0;
        allow_requests_q = 1'b1;
        periodic_backpressure_q = 1'b1;
        pending_q = 1'b0;
        pending_write_q = 1'b0;
        pending_addr_q = 16'b0;
        pending_error_q = 1'b0;
        pending_held_q = 1'b0;
        pending_countdown_q = 0;
        response_delay_q = 2;
        cycle_count = 0;
        accepted_request_count = 0;
        accepted_read_count = 0;
        accepted_write_count = 0;
        response_count = 0;
        outstanding_count = 0;
        max_outstanding = 0;
        reset_cancel_count = 0;
        inject_error_enable_q = 1'b0;
        inject_error_request_number_q = -1;
        hold_request_enable_q = 1'b0;
        hold_request_number_q = -1;
        release_held_response_q = 1'b0;
        late_response_error_q = 1'b0;
        held_request_q = 1'b0;
        held_addr_q = 64'b0;
        held_write_q = 1'b0;
        held_wdata_q = 64'b0;
        held_wstrb_q = 8'b0;
        positive_cases = 0;
        negative_index_cases = 0;
        value_domain_cases = 0;
        preflight_cases = 0;
        response_error_cases = 0;
        drain_cases = 0;
        recovery_cases = 0;
        reset_cases = 0;
        busy_start_cases = 0;
        request_watchdog_cases = 0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;

        run_canonical(2'd0, 1'b1, "native-k-canonical");
        run_canonical(2'd1, 1'b0, "transposed-v-canonical");

        run_index_error(0, "wrong-native-index");
        run_index_error(1, "wrong-transposed-index");
        run_index_error(2, "negative-transposed-index");
        run_index_error(3, "duplicate-transposed-index");

        run_value_error(32'h7fc00000, "quiet-nan");
        run_value_error(32'h7f800001, "signaling-nan");
        run_value_error(32'h7f800000, "positive-inf");
        run_value_error(32'hff800000, "negative-inf");
        run_value_error(32'h47800000, "finite-half-overflow");

        run_preflight_error(0, ERR_PROFILE_SHAPE, "invalid-profile");
        run_preflight_error(1, ERR_PROFILE_SHAPE, "zero-capacity");
        run_preflight_error(2, ERR_PROFILE_SHAPE, "slot-out-of-range");
        run_preflight_error(3, ERR_HEADER, "invalid-gmem-window");
        run_preflight_error(4, ERR_ALIGNMENT, "values-misaligned");
        run_preflight_error(5, ERR_ALIGNMENT, "indices-misaligned");
        run_preflight_error(6, ERR_ALIGNMENT, "destination-misaligned");
        run_preflight_error(7, ERR_VALUES_BOUNDS, "values-short-region");
        run_preflight_error(8, ERR_VALUES_BOUNDS, "values-128b-overflow");
        run_preflight_error(9, ERR_VALUES_BOUNDS, "values-aligned-overfetch");
        run_preflight_error(10, ERR_INDICES_BOUNDS, "indices-short-region");
        run_preflight_error(11, ERR_INDICES_BOUNDS, "indices-128b-overflow");
        run_preflight_error(12, ERR_DEST_BOUNDS, "destination-short-region");
        run_preflight_error(13, ERR_DEST_BOUNDS, "destination-128b-overflow");
        run_preflight_error(14, ERR_DEST_BOUNDS, "write-beat-window");
        run_preflight_error(15, ERR_OVERLAP, "values-indices-overlap");
        run_preflight_error(16, ERR_OVERLAP, "values-destination-overlap");
        run_preflight_error(17, ERR_OVERLAP, "indices-destination-overlap");

        run_response_error(1, "index-response-error");
        run_response_error(2, "value-response-error");
        run_response_error(514, "write-response-error");

        run_drain_case(1, ERR_STALL_TIMEOUT, 1'b0,
                       ERR_STALL_TIMEOUT, ST_INDEX_WAIT,
                       "index-wait-stall-drain");
        run_drain_case(2, ERR_STALL_TIMEOUT, 1'b0,
                       ERR_STALL_TIMEOUT, ST_VALUE_WAIT,
                       "value-wait-stall-drain");
        run_drain_case(514, ERR_STALL_TIMEOUT, 1'b0,
                       ERR_STALL_TIMEOUT, ST_WRITE_WAIT,
                       "write-wait-stall-drain");
        run_drain_case(1, ERR_COMMAND_TIMEOUT, 1'b0,
                       ERR_COMMAND_TIMEOUT, ST_INDEX_WAIT,
                       "index-wait-command-drain");
        run_drain_case(2, ERR_COMMAND_TIMEOUT, 1'b0,
                       ERR_COMMAND_TIMEOUT, ST_VALUE_WAIT,
                       "value-wait-command-drain");
        run_drain_case(514, ERR_COMMAND_TIMEOUT, 1'b0,
                       ERR_COMMAND_TIMEOUT, ST_WRITE_WAIT,
                       "write-wait-command-drain");
        run_drain_case(1, ERR_COMMAND_TIMEOUT, 1'b1,
                       ERR_GMEM_RESPONSE, ST_INDEX_WAIT,
                       "late-error-overrides-timeout");

        run_request_watchdog(ERR_STALL_TIMEOUT,
                             "request-stall-timeout-priority");
        run_request_watchdog(ERR_COMMAND_TIMEOUT,
                             "request-command-timeout-priority");

        run_reset_case(1, ST_INDEX_WAIT, "mid-index-reset");
        run_reset_case(2, ST_VALUE_WAIT, "mid-value-reset");
        run_reset_case(514, ST_WRITE_WAIT, "mid-write-reset");

        if (positive_cases != 2)
            fail_case("canonical case count mismatch");
        if (negative_index_cases != 4)
            fail_case("index-domain case count mismatch");
        if (value_domain_cases != 5)
            fail_case("value-domain case count mismatch");
        if (preflight_cases != 18)
            fail_case("preflight case count mismatch");
        if (response_error_cases != 3)
            fail_case("response-error case count mismatch");
        if (drain_cases != 7)
            fail_case("drain case count mismatch");
        if (request_watchdog_cases != 2)
            fail_case("request-watchdog case count mismatch");
        if (reset_cases != 3)
            fail_case("reset case count mismatch");
        if (busy_start_cases != 1)
            fail_case("busy-start case count mismatch");
        if (recovery_cases != 15)
            fail_case("clean-recovery case count mismatch");
        if (max_outstanding != 1)
            fail_case("max outstanding was not exactly one");
        if (accepted_request_count
                != (response_count + reset_cancel_count))
            fail_case("accepted response/reset conservation mismatch");
        if (accepted_write_count <= 0 || accepted_read_count <= 0)
            fail_case("GMEM traffic cardinality was empty");

        $display("[NPU-SET-ROWS][INFO] canonical=NATIVE_K(idx1/values512/writes512/bytes1024),TRANSPOSED_V(idx512/values512/writes512/bytes1024) negative_indices=%0d value_domain=%0d preflight=%0d response_errors=%0d drain=%0d recovery=%0d reset=%0d request_watchdog=%0d busy_start=%0d max_outstanding=%0d",
                 negative_index_cases, value_domain_cases, preflight_cases,
                 response_error_cases, drain_cases, recovery_cases,
                 reset_cases, request_watchdog_cases, busy_start_cases,
                 max_outstanding);
        $display("[NPU-SET-ROWS][INFO] raw_bits=512-per-command finite_only_rne_v1=1 active_root_canary=unchanged shadow_partial_requires_parent_discard=1 assertions=off waveform=off");
        $display("[NPU-SET-ROWS][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
