`timescale 1ns/1ps
`default_nettype none

module tb_ordered_sum_rows;
    localparam integer FULL_NE0  = 128;
    localparam integer FULL_ROWS = 2048;
    localparam integer FULL_MEM_BYTES = 2097152;
    localparam logic [63:0] FULL_DST_BASE  = 64'h0000_0000_0018_0000;
    localparam logic [255:0] VECTOR_SHA256 =
        256'h3dc7c2e5e97748b0b03c0e1df2128c60f56afb9760ea852c5e7cbd4cd211c1b5;

    localparam integer SMALL_NE0  = 4;
    localparam integer SMALL_NE1  = 2;
    localparam integer SMALL_NE2  = 1;
    localparam integer SMALL_NE3  = 1;
    localparam integer SMALL_MEM_BYTES = 4096;
    localparam integer SMALL_STALL_TIMEOUT = 8;
    localparam integer SMALL_COMMAND_TIMEOUT = 512;
    localparam integer SMALL_DRAIN_TIMEOUT = 12;
    localparam integer SMALL_ABORT_HOLD_TIMEOUT = 6;
    // Keep the directed pre-deadline sampling point in the same 64-bit domain
    // as the production watchdog.  One frozen value is shared by all four
    // fixtures so the fixed-12 edge semantics remain bit-for-bit identical.
    localparam logic [63:0] SMALL_STALL_TIMEOUT_LAST =
        64'(SMALL_STALL_TIMEOUT) - 64'd1;
    localparam logic [63:0] SMALL_SRC_BASE = 64'h0000_0000_0000_0000;
    localparam logic [63:0] SMALL_DST_BASE = 64'h0000_0000_0000_0100;
    localparam logic [63:0] SMALL_ALT_BASE = 64'h0000_0000_0000_0180;

    localparam logic [4:0] ST_IDLE             = 5'd0;
    localparam logic [4:0] ST_PREFLIGHT        = 5'd1;
    localparam logic [4:0] ST_ROW_READ_REQ     = 5'd3;
    localparam logic [4:0] ST_ROW_READ_WAIT    = 5'd4;
    localparam logic [4:0] ST_WIDEN_REQ        = 5'd5;
    localparam logic [4:0] ST_WIDEN_WAIT       = 5'd6;
    localparam logic [4:0] ST_ADD_REQ          = 5'd7;
    localparam logic [4:0] ST_ADD_WAIT         = 5'd8;
    localparam logic [4:0] ST_NARROW_REQ       = 5'd9;
    localparam logic [4:0] ST_NARROW_WAIT      = 5'd10;
    localparam logic [4:0] ST_PUBLISH_PREP     = 5'd11;
    localparam logic [4:0] ST_PUBLISH_REQ      = 5'd12;
    localparam logic [4:0] ST_PUBLISH_WAIT     = 5'd13;
    localparam logic [4:0] ST_GMEM_DRAIN       = 5'd14;
    localparam logic [4:0] ST_CHILD_QUARANTINE = 5'd15;
    localparam logic [4:0] ST_DONE              = 5'd16;
    localparam logic [4:0] ST_ERROR             = 5'd17;
    localparam logic [4:0] ST_POISON_ERROR      = 5'd18;
    localparam logic [4:0] ST_POISON            = 5'd19;
    // Fixed-19 exact terminal topology is counted by the post-NBA monitor,
    // never by helper/task call sites: 47 recoverable ERROR pulses, one legacy
    // drain POISON_ERROR pulse, and four reset-only POISON entries.
    localparam integer EXPECTED_RECOVERABLE_ERROR_STATE_WITNESSES = 47;
    localparam integer EXPECTED_POISON_ERROR_STATE_WITNESSES = 1;
    localparam integer EXPECTED_POISON_STATE_WITNESSES = 4;
    localparam logic [4:0] ST_STRAY_GMEM_DROP   = 5'd20;

    localparam logic [2:0] FAULT_RESOURCE_CONTROL = 3'd0;
    localparam logic [2:0] FAULT_RESOURCE_GMEM    = 3'd1;
    localparam logic [2:0] FAULT_RESOURCE_WIDEN   = 3'd2;
    localparam logic [2:0] FAULT_RESOURCE_ADD     = 3'd3;
    localparam logic [2:0] FAULT_RESOURCE_NARROW  = 3'd4;
    localparam logic [2:0] OWNER_NONE       = 3'd0;
    localparam logic [2:0] OWNER_GMEM_READ  = 3'd1;
    localparam logic [2:0] OWNER_GMEM_WRITE = 3'd2;
    localparam logic [2:0] OWNER_WIDEN      = 3'd3;
    localparam logic [2:0] OWNER_ADD        = 3'd4;
    localparam logic [2:0] OWNER_NARROW     = 3'd5;

    localparam logic [4:0] ERR_HEADER          = 5'd1;
    localparam logic [4:0] ERR_PROFILE_POLICY = 5'd2;
    localparam logic [4:0] ERR_OP_PARAMS       = 5'd3;
    localparam logic [4:0] ERR_SHAPE           = 5'd4;
    localparam logic [4:0] ERR_STRIDE_ALIGN    = 5'd5;
    localparam logic [4:0] ERR_SOURCE_BOUNDS   = 5'd6;
    localparam logic [4:0] ERR_DEST_BOUNDS     = 5'd7;
    localparam logic [4:0] ERR_OVERLAP         = 5'd8;
    localparam logic [4:0] ERR_GMEM_RESPONSE   = 5'd9;
    localparam logic [4:0] ERR_PROTOCOL_OWNER  = 5'd10;
    localparam logic [4:0] ERR_CHILD_RESPONSE  = 5'd11;
    localparam logic [4:0] ERR_STALL_TIMEOUT   = 5'd12;
    localparam logic [4:0] ERR_INTERNAL_STATE  = 5'd14;
    localparam logic [4:0] ERR_POISONED        = 5'd15;

    // Fixed-16 uses one elaborated design for production and all three
    // independent-oracle mutations.  The selector is parsed once at time 0
    // and never changes, so every mode retains the same warning-clean source
    // graph and consumes all terminal-state localparams.
    localparam integer ORACLE_MODE_PRODUCTION         = 0;
    localparam integer ORACLE_MODE_WRONG_COORDINATE   = 1;
    localparam integer ORACLE_MODE_WRONG_GMEM_ADDRESS = 2;
    localparam integer ORACLE_MODE_WRONG_EVENT_DELTA  = 3;
    integer oracle_runtime_mode_q;
    integer oracle_mode_plusarg_rc;
    string  oracle_runtime_mode_arg;

    logic clk_i;
    logic full_rst_i;
    logic full_start_i;
    wire  full_ready_o;
    wire  full_busy_o;
    wire  full_req_valid_o;
    wire  full_req_ready_i;
    wire  full_req_write_o;
    wire [63:0] full_req_addr_o;
    wire [63:0] full_req_wdata_o;
    wire [7:0]  full_req_wstrb_o;
    logic full_rsp_valid_i;
    wire  full_rsp_ready_o;
    logic [63:0] full_rsp_rdata_i;
    logic full_rsp_error_i;
    wire  full_done_o;
    wire  full_error_o;
    wire [4:0] full_error_code_o;
    wire [4:0] full_flags_o;
    wire full_poisoned_o;
    wire full_fault_valid_o;
    wire [63:0] full_first_fault_cycle_o;
    wire [127:0] full_first_fault_coordinate_o;
    wire [63:0] full_first_fault_gmem_addr_o;
    wire [4:0] full_first_fault_flags_o;
    wire [63:0] full_first_fault_request_events_o;
    wire [63:0] full_first_fault_response_events_o;
    wire [31:0] full_first_fault_txn_tag_o;
    wire full_first_fault_generation_o;
    wire [2:0] full_first_fault_resource_o;
    wire [2:0] full_first_fault_owner_type_o;
    wire full_first_fault_owner_valid_o;
    wire full_first_fault_owner_generation_o;
    wire [31:0] full_first_fault_owner_row_o;
    wire [31:0] full_first_fault_owner_index_o;
    wire [63:0] full_rows_reduced_o;
    wire [63:0] full_elements_processed_o;
    wire [63:0] full_gmem_read_requests_o;
    wire [63:0] full_gmem_read_responses_o;
    wire [63:0] full_gmem_write_requests_o;
    wire [63:0] full_gmem_write_responses_o;
    wire [63:0] full_widen_requests_o;
    wire [63:0] full_widen_responses_o;
    wire [63:0] full_add_requests_o;
    wire [63:0] full_add_responses_o;
    wire [63:0] full_narrow_requests_o;
    wire [63:0] full_narrow_responses_o;
    wire [63:0] full_active_cycles_o;

    TensorNpuOrderedSumRows u_full_dut (
        .clk_i                    (clk_i),
        .rst_i                    (full_rst_i),
        .start_i                  (full_start_i),
        .txn_tag_i                (32'hf001_0001),
        .ready_o                  (full_ready_o),
        .busy_o                   (full_busy_o),
        .dtype_i                  (8'h01),
        .profile_i                (8'h01),
        .rounding_mode_i          (3'b000),
        .denormal_mode_i          (2'b00),
        .nan_policy_i             (2'b00),
        .dst_shadow_private_i     (1'b1),
        .reserved_i               (32'b0),
        .op_params_i              (128'b0),
        .gmem_floor_i             (64'h0),
        .gmem_limit_i             (64'h0000_0000_0020_0000),
        .src_region_base_i        (64'h0),
        .src_region_size_i        (64'h0000_0000_0010_0000),
        .src_view_off_i           (64'h0),
        .src_ne0_i                (32'd128),
        .src_ne1_i                (32'd128),
        .src_ne2_i                (32'd16),
        .src_ne3_i                (32'd1),
        .src_nb0_i                (64'd4),
        .src_nb1_i                (64'd512),
        .src_nb2_i                (64'd65536),
        .src_nb3_i                (64'd1048576),
        .dst_region_base_i        (FULL_DST_BASE),
        .dst_region_size_i        (64'h0000_0000_0000_2000),
        .dst_view_off_i           (64'h0),
        .dst_ne0_i                (32'd1),
        .dst_ne1_i                (32'd128),
        .dst_ne2_i                (32'd16),
        .dst_ne3_i                (32'd1),
        .dst_nb0_i                (64'd4),
        .dst_nb1_i                (64'd4),
        .dst_nb2_i                (64'd512),
        .dst_nb3_i                (64'd8192),
        .gmem_req_valid_o         (full_req_valid_o),
        .gmem_req_ready_i         (full_req_ready_i),
        .gmem_req_write_o         (full_req_write_o),
        .gmem_req_addr_o          (full_req_addr_o),
        .gmem_req_wdata_o         (full_req_wdata_o),
        .gmem_req_wstrb_o         (full_req_wstrb_o),
        .gmem_rsp_valid_i         (full_rsp_valid_i),
        .gmem_rsp_ready_o         (full_rsp_ready_o),
        .gmem_rsp_rdata_i         (full_rsp_rdata_i),
        .gmem_rsp_error_i         (full_rsp_error_i),
        .done_o                   (full_done_o),
        .error_o                  (full_error_o),
        .error_code_o             (full_error_code_o),
        .flags_o                  (full_flags_o),
        .poisoned_o               (full_poisoned_o),
        .fault_valid_o            (full_fault_valid_o),
        .first_fault_cycle_o      (full_first_fault_cycle_o),
        .first_fault_coordinate_o (full_first_fault_coordinate_o),
        .first_fault_gmem_addr_o  (full_first_fault_gmem_addr_o),
        .first_fault_flags_o      (full_first_fault_flags_o),
        .first_fault_request_events_o
                                  (full_first_fault_request_events_o),
        .first_fault_response_events_o
                                  (full_first_fault_response_events_o),
        .first_fault_txn_tag_o    (full_first_fault_txn_tag_o),
        .first_fault_generation_o (full_first_fault_generation_o),
        .first_fault_resource_o   (full_first_fault_resource_o),
        .first_fault_owner_type_o (full_first_fault_owner_type_o),
        .first_fault_owner_valid_o(full_first_fault_owner_valid_o),
        .first_fault_owner_generation_o
                                  (full_first_fault_owner_generation_o),
        .first_fault_owner_row_o  (full_first_fault_owner_row_o),
        .first_fault_owner_index_o(full_first_fault_owner_index_o),
        .rows_reduced_o           (full_rows_reduced_o),
        .elements_processed_o     (full_elements_processed_o),
        .gmem_read_requests_o     (full_gmem_read_requests_o),
        .gmem_read_responses_o    (full_gmem_read_responses_o),
        .gmem_write_requests_o    (full_gmem_write_requests_o),
        .gmem_write_responses_o   (full_gmem_write_responses_o),
        .widen_requests_o         (full_widen_requests_o),
        .widen_responses_o        (full_widen_responses_o),
        .add_requests_o           (full_add_requests_o),
        .add_responses_o          (full_add_responses_o),
        .narrow_requests_o        (full_narrow_requests_o),
        .narrow_responses_o       (full_narrow_responses_o),
        .active_cycles_o          (full_active_cycles_o)
    );

    // Small production-RTL instance used only to make protocol and fault paths
    // bounded.  It has the same FSM/owner datapath as the default instance.
    logic small_rst_i;
    logic small_start_i;
    logic [31:0] small_txn_tag_i;
    wire  small_ready_o;
    wire  small_busy_o;
    logic [7:0] small_dtype_i;
    logic [7:0] small_profile_i;
    logic [2:0] small_rounding_mode_i;
    logic [1:0] small_denormal_mode_i;
    logic [1:0] small_nan_policy_i;
    logic small_dst_shadow_private_i;
    logic [31:0] small_reserved_i;
    logic [127:0] small_op_params_i;
    logic [63:0] small_gmem_floor_i;
    logic [63:0] small_gmem_limit_i;
    logic [63:0] small_src_region_base_i;
    logic [63:0] small_src_region_size_i;
    logic [63:0] small_src_view_off_i;
    logic [31:0] small_src_ne0_i;
    logic [31:0] small_src_ne1_i;
    logic [31:0] small_src_ne2_i;
    logic [31:0] small_src_ne3_i;
    logic [63:0] small_src_nb0_i;
    logic [63:0] small_src_nb1_i;
    logic [63:0] small_src_nb2_i;
    logic [63:0] small_src_nb3_i;
    logic [63:0] small_dst_region_base_i;
    logic [63:0] small_dst_region_size_i;
    logic [63:0] small_dst_view_off_i;
    logic [31:0] small_dst_ne0_i;
    logic [31:0] small_dst_ne1_i;
    logic [31:0] small_dst_ne2_i;
    logic [31:0] small_dst_ne3_i;
    logic [63:0] small_dst_nb0_i;
    logic [63:0] small_dst_nb1_i;
    logic [63:0] small_dst_nb2_i;
    logic [63:0] small_dst_nb3_i;
    wire small_req_valid_o;
    wire small_req_ready_i;
    wire small_req_write_o;
    wire [63:0] small_req_addr_o;
    wire [63:0] small_req_wdata_o;
    wire [7:0] small_req_wstrb_o;
    wire  small_rsp_valid_i;
    logic small_rsp_valid_model_q;
    logic small_rsp_valid_ghost_q;
    wire small_rsp_ready_o;
    logic [63:0] small_rsp_rdata_i;
    logic small_rsp_error_i;
    wire small_done_o;
    wire small_error_o;
    wire [4:0] small_error_code_o;
    wire [4:0] small_flags_o;
    wire small_poisoned_o;
    wire small_fault_valid_o;
    wire [63:0] small_first_fault_cycle_o;
    wire [127:0] small_first_fault_coordinate_o;
    wire [63:0] small_first_fault_gmem_addr_o;
    wire [4:0] small_first_fault_flags_o;
    wire [63:0] small_first_fault_request_events_o;
    wire [63:0] small_first_fault_response_events_o;
    wire [31:0] small_first_fault_txn_tag_o;
    wire small_first_fault_generation_o;
    wire [2:0] small_first_fault_resource_o;
    wire [2:0] small_first_fault_owner_type_o;
    wire small_first_fault_owner_valid_o;
    wire small_first_fault_owner_generation_o;
    wire [31:0] small_first_fault_owner_row_o;
    wire [31:0] small_first_fault_owner_index_o;
    wire [63:0] small_rows_reduced_o;
    wire [63:0] small_elements_processed_o;
    wire [63:0] small_gmem_read_requests_o;
    wire [63:0] small_gmem_read_responses_o;
    wire [63:0] small_gmem_write_requests_o;
    wire [63:0] small_gmem_write_responses_o;
    wire [63:0] small_widen_requests_o;
    wire [63:0] small_widen_responses_o;
    wire [63:0] small_add_requests_o;
    wire [63:0] small_add_responses_o;
    wire [63:0] small_narrow_requests_o;
    wire [63:0] small_narrow_responses_o;
    wire [63:0] small_active_cycles_o;

    TensorNpuOrderedSumRows #(
        .NE0                    (SMALL_NE0),
        .NE1                    (SMALL_NE1),
        .NE2                    (SMALL_NE2),
        .NE3                    (SMALL_NE3),
        .STALL_TIMEOUT_CYCLES   (SMALL_STALL_TIMEOUT),
        .COMMAND_TIMEOUT_CYCLES (SMALL_COMMAND_TIMEOUT),
        .DRAIN_TIMEOUT_CYCLES   (SMALL_DRAIN_TIMEOUT),
        .ABORT_HOLD_TIMEOUT_CYCLES
                                  (SMALL_ABORT_HOLD_TIMEOUT)
    ) u_small_dut (
        .clk_i                    (clk_i),
        .rst_i                    (small_rst_i),
        .start_i                  (small_start_i),
        .txn_tag_i                (small_txn_tag_i),
        .ready_o                  (small_ready_o),
        .busy_o                   (small_busy_o),
        .dtype_i                  (small_dtype_i),
        .profile_i                (small_profile_i),
        .rounding_mode_i          (small_rounding_mode_i),
        .denormal_mode_i          (small_denormal_mode_i),
        .nan_policy_i             (small_nan_policy_i),
        .dst_shadow_private_i     (small_dst_shadow_private_i),
        .reserved_i               (small_reserved_i),
        .op_params_i              (small_op_params_i),
        .gmem_floor_i             (small_gmem_floor_i),
        .gmem_limit_i             (small_gmem_limit_i),
        .src_region_base_i        (small_src_region_base_i),
        .src_region_size_i        (small_src_region_size_i),
        .src_view_off_i           (small_src_view_off_i),
        .src_ne0_i                (small_src_ne0_i),
        .src_ne1_i                (small_src_ne1_i),
        .src_ne2_i                (small_src_ne2_i),
        .src_ne3_i                (small_src_ne3_i),
        .src_nb0_i                (small_src_nb0_i),
        .src_nb1_i                (small_src_nb1_i),
        .src_nb2_i                (small_src_nb2_i),
        .src_nb3_i                (small_src_nb3_i),
        .dst_region_base_i        (small_dst_region_base_i),
        .dst_region_size_i        (small_dst_region_size_i),
        .dst_view_off_i           (small_dst_view_off_i),
        .dst_ne0_i                (small_dst_ne0_i),
        .dst_ne1_i                (small_dst_ne1_i),
        .dst_ne2_i                (small_dst_ne2_i),
        .dst_ne3_i                (small_dst_ne3_i),
        .dst_nb0_i                (small_dst_nb0_i),
        .dst_nb1_i                (small_dst_nb1_i),
        .dst_nb2_i                (small_dst_nb2_i),
        .dst_nb3_i                (small_dst_nb3_i),
        .gmem_req_valid_o         (small_req_valid_o),
        .gmem_req_ready_i         (small_req_ready_i),
        .gmem_req_write_o         (small_req_write_o),
        .gmem_req_addr_o          (small_req_addr_o),
        .gmem_req_wdata_o         (small_req_wdata_o),
        .gmem_req_wstrb_o         (small_req_wstrb_o),
        .gmem_rsp_valid_i         (small_rsp_valid_i),
        .gmem_rsp_ready_o         (small_rsp_ready_o),
        .gmem_rsp_rdata_i         (small_rsp_rdata_i),
        .gmem_rsp_error_i         (small_rsp_error_i),
        .done_o                   (small_done_o),
        .error_o                  (small_error_o),
        .error_code_o             (small_error_code_o),
        .flags_o                  (small_flags_o),
        .poisoned_o               (small_poisoned_o),
        .fault_valid_o            (small_fault_valid_o),
        .first_fault_cycle_o      (small_first_fault_cycle_o),
        .first_fault_coordinate_o (small_first_fault_coordinate_o),
        .first_fault_gmem_addr_o  (small_first_fault_gmem_addr_o),
        .first_fault_flags_o      (small_first_fault_flags_o),
        .first_fault_request_events_o
                                  (small_first_fault_request_events_o),
        .first_fault_response_events_o
                                  (small_first_fault_response_events_o),
        .first_fault_txn_tag_o    (small_first_fault_txn_tag_o),
        .first_fault_generation_o (small_first_fault_generation_o),
        .first_fault_resource_o   (small_first_fault_resource_o),
        .first_fault_owner_type_o (small_first_fault_owner_type_o),
        .first_fault_owner_valid_o(small_first_fault_owner_valid_o),
        .first_fault_owner_generation_o
                                  (small_first_fault_owner_generation_o),
        .first_fault_owner_row_o  (small_first_fault_owner_row_o),
        .first_fault_owner_index_o(small_first_fault_owner_index_o),
        .rows_reduced_o           (small_rows_reduced_o),
        .elements_processed_o     (small_elements_processed_o),
        .gmem_read_requests_o     (small_gmem_read_requests_o),
        .gmem_read_responses_o    (small_gmem_read_responses_o),
        .gmem_write_requests_o    (small_gmem_write_requests_o),
        .gmem_write_responses_o   (small_gmem_write_responses_o),
        .widen_requests_o         (small_widen_requests_o),
        .widen_responses_o        (small_widen_responses_o),
        .add_requests_o           (small_add_requests_o),
        .add_responses_o          (small_add_responses_o),
        .narrow_requests_o        (small_narrow_requests_o),
        .narrow_responses_o       (small_narrow_responses_o),
        .active_cycles_o          (small_active_cycles_o)
    );

    // Timing-only clock with one procedural writer.  Keeping initialization
    // and toggling in the same process avoids sequential-RTL assignment rules.
    initial begin
        clk_i = 1'b0;
        forever begin
            #5 clk_i = ~clk_i;
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-ORDERED-SUM-ROWS][FAIL] %s", reason);
            $fatal(1);
        end
    endtask

    task automatic reject_oracle_mutation;
        begin
            case (oracle_runtime_mode_q)
                ORACLE_MODE_WRONG_COORDINATE:
                    $display("[NPU-ORDERED-SUM-ROWS][ORACLE-MUTATION][REJECT] kind=wrong-coordinate");
                ORACLE_MODE_WRONG_GMEM_ADDRESS:
                    $display("[NPU-ORDERED-SUM-ROWS][ORACLE-MUTATION][REJECT] kind=wrong-gmem-address");
                ORACLE_MODE_WRONG_EVENT_DELTA:
                    $display("[NPU-ORDERED-SUM-ROWS][ORACLE-MUTATION][REJECT] kind=wrong-event-delta");
                default:
                    fail_case("production mode reached mutation reject");
            endcase
            $fatal(1, "controlled independent-oracle mutation rejection");
        end
    endtask

    // ------------------------------------------------------------------
    // Independent little-endian GMEM models.
    // ------------------------------------------------------------------
    /* verilator lint_off MULTIDRIVEN */
    logic [7:0] full_mem [0:FULL_MEM_BYTES-1];
    logic [7:0] small_mem [0:SMALL_MEM_BYTES-1];
    /* verilator lint_on MULTIDRIVEN */

    logic full_pending_q;
    logic full_pending_write_q;
    logic [20:0] full_pending_addr_q;
    integer full_read_accept_count;
    integer full_write_accept_count;
    integer full_response_count;
    integer full_done_count;
    integer full_lane;

    assign full_req_ready_i = !full_rst_i && !full_pending_q
                            && !full_rsp_valid_i;

    function automatic [63:0] full_read64(input logic [31:0] address);
        integer read_lane;
        begin
            full_read64 = 64'b0;
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
                full_read64[(read_lane * 8) +: 8] =
                    full_mem[address + read_lane];
        end
    endfunction

    always @(posedge clk_i) begin
        if (full_rst_i) begin
            full_pending_q       <= 1'b0;
            full_pending_write_q <= 1'b0;
            full_pending_addr_q  <= 21'b0;
            full_rsp_valid_i     <= 1'b0;
            full_rsp_rdata_i     <= 64'b0;
            full_rsp_error_i     <= 1'b0;
        end else begin
            if (full_req_valid_o && full_req_ready_i) begin
                if ((full_req_addr_o[2:0] != 3'b000)
                        || (full_req_addr_o[63:21] != 43'b0))
                    fail_case("full GMEM address/alignment");
                if (full_pending_q || full_rsp_valid_i)
                    fail_case("full GMEM more than one outstanding");
                full_pending_q       <= 1'b1;
                full_pending_write_q <= full_req_write_o;
                full_pending_addr_q  <= full_req_addr_o[20:0];
                if (full_req_write_o) begin
                    if (full_req_addr_o != ((FULL_DST_BASE
                            + (full_write_accept_count * 64'd4))
                            & 64'hffff_ffff_ffff_fff8))
                        fail_case("full publish address order");
                    if ((((FULL_DST_BASE
                            + (full_write_accept_count * 64'd4)) & 64'd4) == 0
                            && full_req_wstrb_o != 8'h0f)
                            || (((FULL_DST_BASE
                            + (full_write_accept_count * 64'd4)) & 64'd4) != 0
                            && full_req_wstrb_o != 8'hf0))
                        fail_case("full publish F32 strobe");
                    for (full_lane = 0; full_lane < 8;
                            full_lane = full_lane + 1)
                        if (full_req_wstrb_o[full_lane])
                            full_mem[{11'b0, full_req_addr_o[20:0]} + full_lane]
                                <= full_req_wdata_o[(full_lane * 8) +: 8];
                    full_write_accept_count <= full_write_accept_count + 1;
                end else begin
                    if (full_req_addr_o != (full_read_accept_count * 64'd8))
                        fail_case("full read did not consume i0-fast rows");
                    if ((full_req_wdata_o != 64'b0)
                            || (full_req_wstrb_o != 8'b0))
                        fail_case("full read carried write payload");
                    full_read_accept_count <= full_read_accept_count + 1;
                end
            end

            if (full_pending_q && !full_rsp_valid_i) begin
                full_rsp_valid_i <= 1'b1;
                full_rsp_error_i <= 1'b0;
                full_rsp_rdata_i <= full_pending_write_q
                                  ? 64'b0
                                  : full_read64({11'b0, full_pending_addr_q});
            end
            if (full_rsp_valid_i && full_rsp_ready_o) begin
                full_rsp_valid_i <= 1'b0;
                full_pending_q   <= 1'b0;
                full_response_count <= full_response_count + 1;
            end
            if (full_done_o)
                full_done_count <= full_done_count + 1;
        end
    end

    // Independent fixed-15 first-fault oracle.  Every edge-local value is
    // supplied by the fixture before the sampling edge; the only live inputs
    // used to form totals are public completion counters.  This block never
    // derives an expected value from a DUT state, selector, owner or payload.
    logic         small_expected_fault_valid_q;
    logic [63:0]  small_expected_fault_cycle_q;
    logic [127:0] small_expected_fault_coordinate_q;
    logic [63:0]  small_expected_fault_gmem_addr_q;
    logic [4:0]   small_expected_fault_flags_q;
    logic [63:0]  small_expected_fault_request_events_q;
    logic [63:0]  small_expected_fault_response_events_q;
    logic [31:0]  small_expected_fault_txn_tag_q;
    logic         small_expected_fault_generation_q;
    logic [2:0]   small_expected_fault_resource_q;
    logic [2:0]   small_expected_fault_owner_type_q;
    logic         small_expected_fault_owner_valid_q;
    logic         small_expected_fault_owner_generation_q;
    logic [31:0]  small_expected_fault_owner_row_q;
    logic [31:0]  small_expected_fault_owner_index_q;
    logic         small_fault_expect_arm_q;
    logic [63:0]  small_fault_expect_cycle_q;
    logic [127:0] small_fault_expect_coordinate_q;
    logic [63:0]  small_fault_expect_gmem_addr_q;
    logic [4:0]   small_fault_expect_flags_q;
    logic [63:0]  small_fault_expect_request_events_q;
    logic [63:0]  small_fault_expect_response_events_q;
    logic [31:0]  small_fault_expect_txn_tag_q;
    logic         small_fault_expect_generation_q;
    logic [2:0]   small_fault_expect_resource_q;
    logic [2:0]   small_fault_expect_owner_type_q;
    logic         small_fault_expect_owner_valid_q;
    logic         small_fault_expect_owner_generation_q;
    logic [31:0]  small_fault_expect_owner_row_q;
    logic [31:0]  small_fault_expect_owner_index_q;
    logic         small_tb_generation_q;
    logic [31:0]  small_tb_txn_tag_q;
    integer fault_output_capture_count;
    integer fault_output_stability_checks;
    integer success_fault_zero_check_count;

    always @(posedge clk_i) begin
        if (small_rst_i) begin
            small_expected_fault_valid_q          <= 1'b0;
            small_expected_fault_cycle_q          <= 64'b0;
            small_expected_fault_coordinate_q     <= 128'b0;
            small_expected_fault_gmem_addr_q      <= 64'b0;
            small_expected_fault_flags_q          <= 5'b0;
            small_expected_fault_request_events_q <= 64'b0;
            small_expected_fault_response_events_q <= 64'b0;
            small_expected_fault_txn_tag_q        <= 32'b0;
            small_expected_fault_generation_q     <= 1'b0;
            small_expected_fault_resource_q       <= 3'b0;
            small_expected_fault_owner_type_q     <= 3'b0;
            small_expected_fault_owner_valid_q    <= 1'b0;
            small_expected_fault_owner_generation_q <= 1'b0;
            small_expected_fault_owner_row_q      <= 32'b0;
            small_expected_fault_owner_index_q    <= 32'b0;
            small_tb_generation_q                 <= 1'b0;
            small_tb_txn_tag_q                    <= 32'b0;
        end else begin
            if (small_start_i && small_ready_o) begin
                small_expected_fault_valid_q          <= 1'b0;
                small_expected_fault_cycle_q          <= 64'b0;
                small_expected_fault_coordinate_q     <= 128'b0;
                small_expected_fault_gmem_addr_q      <= 64'b0;
                small_expected_fault_flags_q          <= 5'b0;
                small_expected_fault_request_events_q <= 64'b0;
                small_expected_fault_response_events_q <= 64'b0;
                small_expected_fault_txn_tag_q        <= 32'b0;
                small_expected_fault_generation_q     <= 1'b0;
                small_expected_fault_resource_q       <= 3'b0;
                small_expected_fault_owner_type_q     <= 3'b0;
                small_expected_fault_owner_valid_q    <= 1'b0;
                small_expected_fault_owner_generation_q <= 1'b0;
                small_expected_fault_owner_row_q      <= 32'b0;
                small_expected_fault_owner_index_q    <= 32'b0;
                small_tb_generation_q                 <= ~small_tb_generation_q;
                small_tb_txn_tag_q                    <= small_txn_tag_i;
            end
            // FIXED15_EXPECTED_ORACLE_BEGIN
            // Capture enable and every expected field are owned by the
            // directed fixture.  One immutable runtime selector perturbs
            // exactly one field; the compiled graph is identical in all four
            // runs and no expected value is sourced from a DUT internal.
            if (small_fault_expect_arm_q
                    && !small_expected_fault_valid_q) begin
                small_expected_fault_valid_q <= 1'b1;
                small_expected_fault_cycle_q
                    <= small_fault_expect_cycle_q;
                small_expected_fault_coordinate_q
                    <= (oracle_runtime_mode_q
                            == ORACLE_MODE_WRONG_COORDINATE)
                       ? (small_fault_expect_coordinate_q ^ 128'd1)
                       : small_fault_expect_coordinate_q;
                small_expected_fault_gmem_addr_q
                    <= (oracle_runtime_mode_q
                            == ORACLE_MODE_WRONG_GMEM_ADDRESS)
                       ? (small_fault_expect_gmem_addr_q ^ 64'd8)
                       : small_fault_expect_gmem_addr_q;
                small_expected_fault_flags_q
                    <= small_fault_expect_flags_q;
                small_expected_fault_request_events_q
                    <= (oracle_runtime_mode_q
                            == ORACLE_MODE_WRONG_EVENT_DELTA)
                       ? (small_fault_expect_request_events_q + 64'd1)
                       : small_fault_expect_request_events_q;
                small_expected_fault_response_events_q
                    <= small_fault_expect_response_events_q;
                small_expected_fault_txn_tag_q
                    <= small_fault_expect_txn_tag_q;
                small_expected_fault_generation_q
                    <= small_fault_expect_generation_q;
                small_expected_fault_resource_q
                    <= small_fault_expect_resource_q;
                small_expected_fault_owner_type_q
                    <= small_fault_expect_owner_type_q;
                small_expected_fault_owner_valid_q
                    <= small_fault_expect_owner_valid_q;
                small_expected_fault_owner_generation_q
                    <= small_fault_expect_owner_generation_q;
                small_expected_fault_owner_row_q
                    <= small_fault_expect_owner_row_q;
                small_expected_fault_owner_index_q
                    <= small_fault_expect_owner_index_q;
                fault_output_capture_count <= fault_output_capture_count + 1;
            end
            // FIXED15_EXPECTED_ORACLE_END
        end
    end

    wire small_fault_common_match_w = small_fault_valid_o
        && (small_first_fault_cycle_o == small_expected_fault_cycle_q)
        && (small_first_fault_flags_o == small_expected_fault_flags_q)
        && (small_first_fault_response_events_o
            == small_expected_fault_response_events_q)
        && (small_first_fault_txn_tag_o
            == small_expected_fault_txn_tag_q)
        && (small_first_fault_generation_o
            == small_expected_fault_generation_q)
        && (small_first_fault_resource_o
            == small_expected_fault_resource_q)
        && (small_first_fault_owner_type_o
            == small_expected_fault_owner_type_q)
        && (small_first_fault_owner_valid_o
            == small_expected_fault_owner_valid_q)
        && (small_first_fault_owner_generation_o
            == small_expected_fault_owner_generation_q)
        && (small_first_fault_owner_row_o
            == small_expected_fault_owner_row_q)
        && (small_first_fault_owner_index_o
            == small_expected_fault_owner_index_q);
    wire small_fault_coordinate_match_w =
        small_first_fault_coordinate_o == small_expected_fault_coordinate_q;
    wire small_fault_gmem_addr_match_w =
        small_first_fault_gmem_addr_o == small_expected_fault_gmem_addr_q;
    wire small_fault_request_events_match_w =
        small_first_fault_request_events_o
            == small_expected_fault_request_events_q;

    // Sampling on the opposite edge observes all parent NBAs and continuously
    // proves stability through quarantine, drain, terminal and post-terminal
    // IDLE.  An invalid record must drive every payload bit to zero.
    always @(negedge clk_i) begin
        if (!small_rst_i) begin
            if (small_expected_fault_valid_q) begin
                case (oracle_runtime_mode_q)
                    ORACLE_MODE_PRODUCTION: begin
                        if (!small_fault_common_match_w
                                || !small_fault_coordinate_match_w
                                || !small_fault_gmem_addr_match_w
                                || !small_fault_request_events_match_w)
                            fail_case("first-fault diagnostic output changed");
                    end
                    ORACLE_MODE_WRONG_COORDINATE: begin
                        if (small_fault_common_match_w
                                && !small_fault_coordinate_match_w
                                && small_fault_gmem_addr_match_w
                                && small_fault_request_events_match_w)
                            reject_oracle_mutation();
                        else
                            fail_case("wrong-coordinate mutation did not isolate coordinate");
                    end
                    ORACLE_MODE_WRONG_GMEM_ADDRESS: begin
                        if (small_fault_common_match_w
                                && small_fault_coordinate_match_w
                                && !small_fault_gmem_addr_match_w
                                && small_fault_request_events_match_w)
                            reject_oracle_mutation();
                        else
                            fail_case("wrong-gmem-address mutation did not isolate address");
                    end
                    ORACLE_MODE_WRONG_EVENT_DELTA: begin
                        if (small_fault_common_match_w
                                && small_fault_coordinate_match_w
                                && small_fault_gmem_addr_match_w
                                && !small_fault_request_events_match_w)
                            reject_oracle_mutation();
                        else
                            fail_case("wrong-event-delta mutation did not isolate event total");
                    end
                    default:
                        fail_case("invalid runtime oracle mode in comparator");
                endcase
                fault_output_stability_checks <=
                    fault_output_stability_checks + 1;
            end else if (small_fault_valid_o
                    || (small_first_fault_cycle_o != 64'b0)
                    || (small_first_fault_coordinate_o != 128'b0)
                    || (small_first_fault_gmem_addr_o != 64'b0)
                    || (small_first_fault_flags_o != 5'b0)
                    || (small_first_fault_request_events_o != 64'b0)
                    || (small_first_fault_response_events_o != 64'b0)
                    || (small_first_fault_txn_tag_o != 32'b0)
                    || small_first_fault_generation_o
                    || (small_first_fault_resource_o != 3'b0)
                    || (small_first_fault_owner_type_o != 3'b0)
                    || small_first_fault_owner_valid_o
                    || small_first_fault_owner_generation_o
                    || (small_first_fault_owner_row_o != 32'b0)
                    || (small_first_fault_owner_index_o != 32'b0)) begin
                fail_case("invalid first-fault diagnostic was nonzero");
            end
        end
        if (!full_rst_i && (full_fault_valid_o
                || (full_first_fault_cycle_o != 64'b0)
                || (full_first_fault_coordinate_o != 128'b0)
                || (full_first_fault_gmem_addr_o != 64'b0)
                || (full_first_fault_flags_o != 5'b0)
                || (full_first_fault_request_events_o != 64'b0)
                || (full_first_fault_response_events_o != 64'b0)
                || (full_first_fault_txn_tag_o != 32'b0)
                || full_first_fault_generation_o
                || (full_first_fault_resource_o != 3'b0)
                || (full_first_fault_owner_type_o != 3'b0)
                || full_first_fault_owner_valid_o
                || full_first_fault_owner_generation_o
                || (full_first_fault_owner_row_o != 32'b0)
                || (full_first_fault_owner_index_o != 32'b0)))
            fail_case("full success exposed first-fault diagnostic");
    end

    logic small_allow_requests_q;
    logic small_hold_responses_q;
    logic small_inject_read_error_q;
    logic small_inject_write_error_q;
    integer small_response_delay_q;
    logic small_pending_q;
    logic small_pending_write_q;
    logic [11:0] small_pending_addr_q;
    logic small_pending_error_q;
    integer small_response_countdown_q;
    integer small_accept_count;
    integer small_read_accept_count;
    integer small_write_accept_count;
    integer small_response_count;
    integer small_done_count;
    integer small_error_count;
    integer terminal_error_state_witness_count;
    integer terminal_poison_error_state_witness_count;
    integer terminal_poison_state_witness_count;
    integer collision_poison_witness_count;
    integer abort_hold_poison_witness_count;
    integer drain_poison_witness_count;
    logic [4:0] small_previous_state_q;
    integer small_lane;

    assign small_rsp_valid_i = small_rsp_valid_model_q
                             || small_rsp_valid_ghost_q;
    assign small_req_ready_i = !small_rst_i && small_allow_requests_q
                             && !small_pending_q;

    function automatic [63:0] small_read64(input logic [31:0] address);
        integer read_lane;
        begin
            small_read64 = 64'b0;
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
                small_read64[(read_lane * 8) +: 8] =
                    small_mem[address + read_lane];
        end
    endfunction

    always @(posedge clk_i) begin
        if (small_rst_i) begin
            small_pending_q             <= 1'b0;
            small_pending_write_q       <= 1'b0;
            small_pending_addr_q        <= 12'b0;
            small_pending_error_q       <= 1'b0;
            small_response_countdown_q  <= 0;
            small_rsp_valid_model_q     <= 1'b0;
            small_rsp_rdata_i           <= 64'b0;
            small_rsp_error_i           <= 1'b0;
        end else begin
            if (small_req_valid_o && small_req_ready_i) begin
                if ((small_req_addr_o[2:0] != 3'b000)
                        || (small_req_addr_o[63:12] != 52'b0))
                    fail_case("small GMEM address/alignment");
                if (small_pending_q || small_rsp_valid_model_q)
                    fail_case("small GMEM more than one outstanding");
                small_pending_q       <= 1'b1;
                small_pending_write_q <= small_req_write_o;
                small_pending_addr_q  <= small_req_addr_o[11:0];
                small_pending_error_q <= small_req_write_o
                                       ? small_inject_write_error_q
                                       : small_inject_read_error_q;
                small_response_countdown_q <= small_response_delay_q;
                small_accept_count <= small_accept_count + 1;
                if (small_req_write_o) begin
                    if ((small_req_wstrb_o != 8'h0f)
                            && (small_req_wstrb_o != 8'hf0))
                        fail_case("small write strobe");
                    for (small_lane = 0; small_lane < 8;
                            small_lane = small_lane + 1)
                        if (small_req_wstrb_o[small_lane])
                            small_mem[{20'b0, small_req_addr_o[11:0]}
                                      + small_lane]
                                <= small_req_wdata_o[(small_lane * 8) +: 8];
                    small_write_accept_count <= small_write_accept_count + 1;
                end else begin
                    if ((small_req_wdata_o != 64'b0)
                            || (small_req_wstrb_o != 8'b0))
                        fail_case("small read carried write payload");
                    small_read_accept_count <= small_read_accept_count + 1;
                end
            end

            if (small_pending_q && !small_rsp_valid_model_q) begin
                if (small_response_countdown_q > 0)
                    small_response_countdown_q
                        <= small_response_countdown_q - 1;
                else if (!small_hold_responses_q) begin
                    small_rsp_valid_model_q <= 1'b1;
                    small_rsp_error_i <= small_pending_error_q;
                    small_rsp_rdata_i <= small_pending_write_q
                                      ? 64'b0
                                      : small_read64(
                                          {20'b0, small_pending_addr_q});
                end
            end
            if (small_rsp_valid_model_q && small_rsp_ready_o) begin
                small_rsp_valid_model_q <= 1'b0;
                small_rsp_error_i <= 1'b0;
                small_pending_q   <= 1'b0;
                small_response_count <= small_response_count + 1;
            end
            if (small_done_o)
                small_done_count <= small_done_count + 1;
            if (small_error_o)
                small_error_count <= small_error_count + 1;
        end
    end

    // Fixture-derived terminal topology.  The falling edge observes the
    // registered parent state after all rising-edge NBAs.  Consequently every
    // counter is tied to a real output/state witness rather than to a task's
    // expectation or control-flow path.
    always @(negedge clk_i) begin
        if (small_rst_i) begin
            small_previous_state_q <= ST_IDLE;
        end else begin
            if (small_error_o) begin
                if ((u_small_dut.state_q == ST_ERROR)
                        && !small_poisoned_o && !small_done_o
                        && (small_error_code_o != ERR_POISONED)) begin
                    terminal_error_state_witness_count <=
                        terminal_error_state_witness_count + 1;
                end else if ((u_small_dut.state_q == ST_POISON_ERROR)
                        && small_poisoned_o && !small_done_o
                        && (small_error_code_o == ERR_POISONED)) begin
                    terminal_poison_error_state_witness_count <=
                        terminal_poison_error_state_witness_count + 1;
                end else begin
                    fail_case("terminal error output/state topology");
                end
            end
            if ((u_small_dut.state_q == ST_POISON)
                    && (small_previous_state_q != ST_POISON)) begin
                if (!small_poisoned_o || small_error_o || small_done_o
                        || small_ready_o || small_rsp_ready_o)
                    fail_case("persistent poison output/state topology");
                $display("[NPU-ORDERED-SUM-ROWS][TERMINAL-POISON-ENTRY] ordinal=%0d collision=%0d abort=%0d first_resource=%0d first_owner=%0d error_code=%0d",
                         terminal_poison_state_witness_count + 1,
                         u_small_dut.collision_poison_q,
                         u_small_dut.abort_hold_poison_q,
                         small_first_fault_resource_o,
                         small_first_fault_owner_type_o,
                         small_error_code_o);
                terminal_poison_state_witness_count <=
                    terminal_poison_state_witness_count + 1;
            end
            small_previous_state_q <= u_small_dut.state_q;
        end
    end

    // Held-request and terminal one-shot monitors for both instances.
    logic full_hold_q;
    logic [136:0] full_held_payload_q;
    logic small_hold_q;
    logic [136:0] small_held_payload_q;
    logic small_widen_hold_q;
    logic [31:0] small_widen_held_payload_q;
    logic small_add_hold_q;
    logic [127:0] small_add_held_payload_q;
    logic small_narrow_hold_q;
    logic [63:0] small_narrow_held_payload_q;
    logic full_previous_done_q;
    logic full_previous_error_q;
    logic small_previous_done_q;
    logic small_previous_error_q;

    always @(posedge clk_i) begin
        if (full_rst_i) begin
            full_hold_q           <= 1'b0;
            full_held_payload_q   <= 137'b0;
            full_previous_done_q  <= 1'b0;
            full_previous_error_q <= 1'b0;
        end else begin
            if (full_done_o && full_error_o)
                fail_case("full done/error overlap");
            if (full_previous_done_q && full_done_o)
                fail_case("full done wider than one cycle");
            if (full_previous_error_q && full_error_o)
                fail_case("full error wider than one cycle");
            if (full_hold_q && !full_req_valid_o)
                fail_case("full held GMEM request withdrew valid");
            if (full_hold_q && ({full_req_write_o, full_req_addr_o,
                    full_req_wdata_o, full_req_wstrb_o}
                    != full_held_payload_q))
                fail_case("full held GMEM request changed");
            full_hold_q <= full_req_valid_o && !full_req_ready_i;
            if (full_req_valid_o && !full_req_ready_i)
                full_held_payload_q <= {full_req_write_o, full_req_addr_o,
                                        full_req_wdata_o, full_req_wstrb_o};
            full_previous_done_q  <= full_done_o;
            full_previous_error_q <= full_error_o;
        end

        if (small_rst_i) begin
            small_hold_q           <= 1'b0;
            small_held_payload_q   <= 137'b0;
            small_widen_hold_q     <= 1'b0;
            small_widen_held_payload_q <= 32'b0;
            small_add_hold_q       <= 1'b0;
            small_add_held_payload_q <= 128'b0;
            small_narrow_hold_q    <= 1'b0;
            small_narrow_held_payload_q <= 64'b0;
            small_previous_done_q  <= 1'b0;
            small_previous_error_q <= 1'b0;
        end else begin
            if (small_done_o && small_error_o)
                fail_case("small done/error overlap");
            if (small_previous_done_q && small_done_o)
                fail_case("small done wider than one cycle");
            if (small_previous_error_q && small_error_o)
                fail_case("small error wider than one cycle");
            if (small_hold_q && !small_req_valid_o)
                fail_case("small held GMEM request withdrew valid");
            if (small_hold_q && ({small_req_write_o, small_req_addr_o,
                    small_req_wdata_o, small_req_wstrb_o}
                    != small_held_payload_q))
                fail_case("small held GMEM request changed");
            small_hold_q <= small_req_valid_o && !small_req_ready_i;
            if (small_req_valid_o && !small_req_ready_i)
                small_held_payload_q <= {small_req_write_o,
                    small_req_addr_o, small_req_wdata_o, small_req_wstrb_o};
            if (small_widen_hold_q && !u_small_dut.widen_req_valid_w)
                fail_case("held widen request withdrew valid");
            if (small_widen_hold_q
                    && (u_small_dut.row_buffer_q[
                            u_small_dut.element_array_index_w]
                        != small_widen_held_payload_q))
                fail_case("held widen request changed payload");
            if (small_add_hold_q && !u_small_dut.add_req_valid_w)
                fail_case("held add request withdrew valid");
            if (small_add_hold_q
                    && ({u_small_dut.accumulator_q,
                         u_small_dut.widened_term_q}
                        != small_add_held_payload_q))
                fail_case("held add request changed payload");
            if (small_narrow_hold_q && !u_small_dut.narrow_req_valid_w)
                fail_case("held narrow request withdrew valid");
            if (small_narrow_hold_q
                    && (u_small_dut.accumulator_q
                        != small_narrow_held_payload_q))
                fail_case("held narrow request changed payload");
            small_widen_hold_q <= u_small_dut.widen_req_valid_w
                               && !u_small_dut.widen_req_ready_w;
            if (u_small_dut.widen_req_valid_w
                    && !u_small_dut.widen_req_ready_w)
                small_widen_held_payload_q <= u_small_dut.row_buffer_q[
                    u_small_dut.element_array_index_w];
            small_add_hold_q <= u_small_dut.add_req_valid_w
                             && !u_small_dut.add_req_ready_w;
            if (u_small_dut.add_req_valid_w && !u_small_dut.add_req_ready_w)
                small_add_held_payload_q <= {
                    u_small_dut.accumulator_q, u_small_dut.widened_term_q};
            small_narrow_hold_q <= u_small_dut.narrow_req_valid_w
                                && !u_small_dut.narrow_req_ready_w;
            if (u_small_dut.narrow_req_valid_w
                    && !u_small_dut.narrow_req_ready_w)
                small_narrow_held_payload_q <= u_small_dut.accumulator_q;
            small_previous_done_q  <= small_done_o;
            small_previous_error_q <= small_error_o;
        end
    end

    // Raw memory helpers.  No real/shortreal/DPI/host-FPU expected path exists.
    task automatic full_put_word(
        input integer row,
        input integer element,
        input logic [31:0] raw
    );
        integer address;
        begin
            address = ((row * FULL_NE0) + element) * 4;
            full_mem[address]     = raw[7:0];
            full_mem[address + 1] = raw[15:8];
            full_mem[address + 2] = raw[23:16];
            full_mem[address + 3] = raw[31:24];
        end
    endtask

    task automatic full_fill_row(
        input integer row,
        input logic [31:0] raw
    );
        integer element;
        begin
            for (element = 0; element < FULL_NE0; element = element + 1)
                full_put_word(row, element, raw);
        end
    endtask

    task automatic full_run_raw(
        input integer row,
        input integer first,
        input integer count,
        input logic [31:0] raw
    );
        integer element;
        begin
            for (element = first; element < (first + count);
                    element = element + 1)
                full_put_word(row, element, raw);
        end
    endtask

    function automatic [31:0] full_get_word(input integer address);
        begin
            full_get_word = {full_mem[address + 3], full_mem[address + 2],
                             full_mem[address + 1], full_mem[address]};
        end
    endfunction

    task automatic small_put_word(
        input integer address,
        input logic [31:0] raw
    );
        begin
            small_mem[address]     = raw[7:0];
            small_mem[address + 1] = raw[15:8];
            small_mem[address + 2] = raw[23:16];
            small_mem[address + 3] = raw[31:24];
        end
    endtask

    function automatic [31:0] small_get_word(input integer address);
        begin
            small_get_word = {small_mem[address + 3], small_mem[address + 2],
                              small_mem[address + 1], small_mem[address]};
        end
    endfunction

    logic [31:0] full_expected_result [0:FULL_ROWS-1];
    logic [4:0]  full_expected_flags [0:FULL_ROWS-1];

    task automatic prepare_full_vectors;
        integer row;
        integer address;
        begin
            for (address = 0; address < 1048576; address = address + 1)
                full_mem[address] = 8'h00;
            for (address = 0; address < 8192; address = address + 1)
                full_mem[1572864 + address] = 8'hc3;
            for (address = 0; address < 8192; address = address + 1)
                full_mem[1703936 + address] = 8'ha5;
            for (row = 0; row < FULL_ROWS; row = row + 1) begin
                full_expected_result[row] = 32'h0000_0000;
                full_expected_flags[row]  = 5'h00;
            end

            // The first 60 rows are a direct raw-bit transcription of the
            // canonical JSONL bound by VECTOR_SHA256.  Remaining rows are +0.
            full_fill_row(1, 32'h8000_0000);
            full_put_word(2, 0,   32'h8000_0000);
            full_put_word(3, 127, 32'h8000_0000);
            full_put_word(4, 0,   32'h3f80_0000);
            full_put_word(5, 127, 32'h3f80_0000);
            full_put_word(6, 0,   32'hbf80_0000);
            full_put_word(6, 127, 32'h3f80_0000);
            full_put_word(7, 0,   32'h3f80_0000);
            full_put_word(7, 127, 32'hbf80_0000);
            full_put_word(8, 0,   32'h0000_0001);
            full_put_word(9, 0,   32'h8000_0001);
            full_fill_row(10, 32'h0000_0001);
            full_run_raw(11, 0, 127, 32'h0000_0001);
            full_put_word(12, 0, 32'h0080_0000);
            full_put_word(13, 0, 32'h0080_0000);
            full_put_word(13, 1, 32'h8000_0001);
            full_put_word(14, 0, 32'h007f_ffff);
            full_put_word(14, 1, 32'h0000_0001);
            full_put_word(15, 0, 32'h0000_0001);
            full_put_word(15, 1, 32'h8000_0001);
            full_put_word(16, 0, 32'h0080_0000);
            full_put_word(16, 1, 32'h807f_ffff);
            full_put_word(17, 0, 32'h007f_ffff);
            full_put_word(17, 1, 32'h007f_ffff);
            full_put_word(18, 0, 32'h4b80_0000);
            full_put_word(18, 1, 32'h3f80_0000);
            full_put_word(18, 2, 32'h3f80_0000);
            full_put_word(19, 0, 32'h4b80_0000);
            full_put_word(19, 1, 32'h3f80_0000);
            full_put_word(19, 2, 32'hcb80_0000);
            full_put_word(20, 0, 32'hcb80_0000);
            full_put_word(20, 1, 32'hbf80_0000);
            full_put_word(20, 2, 32'hbf80_0000);
            full_put_word(21, 0, 32'h3f80_0000);
            full_put_word(21, 1, 32'h3380_0000);
            full_put_word(21, 2, 32'h3380_0000);
            full_put_word(22, 0, 32'h3f80_0000);
            full_put_word(22, 1, 32'h3380_0000);
            full_put_word(23, 0, 32'h3f80_0000);
            full_put_word(23, 1, 32'h3440_0000);
            full_put_word(24, 0, 32'h4b80_0000);
            full_put_word(24, 1, 32'h3f80_0000);
            full_put_word(25, 0, 32'h4b80_0000);
            full_put_word(25, 1, 32'h4040_0000);
            full_put_word(26, 0, 32'hcb80_0000);
            full_put_word(26, 1, 32'hbf80_0000);
            full_put_word(27, 0, 32'hcb80_0000);
            full_put_word(27, 1, 32'hc040_0000);
            full_put_word(28, 0, 32'h7180_0000);
            full_put_word(28, 1, 32'h3f80_0000);
            full_put_word(28, 2, 32'hf180_0000);
            full_put_word(29, 0, 32'h7180_0000);
            full_put_word(29, 1, 32'hf180_0000);
            full_put_word(29, 2, 32'h3f80_0000);
            full_put_word(30, 0, 32'h7180_0000);
            full_put_word(30, 1, 32'h3f80_0000);
            full_put_word(30, 2, 32'hf180_0000);
            full_put_word(30, 3, 32'h3f80_0000);
            full_put_word(31, 0, 32'h7180_0000);
            full_put_word(31, 1, 32'h5700_0000);
            full_put_word(31, 2, 32'hf180_0000);
            full_put_word(32, 0, 32'h7180_0000);
            full_put_word(32, 1, 32'h5780_0000);
            full_put_word(32, 2, 32'h5700_0000);
            full_put_word(32, 3, 32'hf180_0000);
            full_put_word(33, 0, 32'h7180_0000);
            full_put_word(33, 1, 32'h56ff_ffff);
            full_put_word(33, 2, 32'hf180_0000);
            full_put_word(34, 0, 32'h7180_0000);
            full_put_word(34, 1, 32'h5700_0001);
            full_put_word(34, 2, 32'hf180_0000);
            full_put_word(35, 0, 32'hf180_0000);
            full_put_word(35, 1, 32'hd700_0000);
            full_put_word(35, 2, 32'h7180_0000);
            full_put_word(36, 0, 32'hf180_0000);
            full_put_word(36, 1, 32'hd780_0000);
            full_put_word(36, 2, 32'hd700_0000);
            full_put_word(36, 3, 32'h7180_0000);
            full_put_word(37, 0, 32'h7180_0000);
            full_put_word(37, 1, 32'h5700_0000);
            full_put_word(37, 2, 32'h5700_0000);
            full_put_word(37, 3, 32'hf180_0000);
            full_put_word(38, 0, 32'h7f7f_ffff);
            full_put_word(39, 0, 32'h7f7f_ffff);
            full_put_word(39, 1, 32'h72ff_ffff);
            full_put_word(40, 0, 32'h7f7f_ffff);
            full_put_word(40, 1, 32'h7300_0000);
            full_put_word(41, 0, 32'h7f7f_ffff);
            full_put_word(41, 1, 32'h7300_0001);
            full_put_word(42, 0, 32'h7f7f_ffff);
            full_put_word(42, 1, 32'h7f7f_ffff);
            full_put_word(43, 0, 32'hff7f_ffff);
            full_put_word(43, 1, 32'hf2ff_ffff);
            full_put_word(44, 0, 32'hff7f_ffff);
            full_put_word(44, 1, 32'hf300_0000);
            full_put_word(45, 0, 32'h7f7f_ffff);
            full_put_word(45, 1, 32'h7300_0000);
            full_put_word(45, 2, 32'hf300_0000);
            full_put_word(46, 0, 32'h7f7f_ffff);
            full_put_word(46, 1, 32'h7f7f_ffff);
            full_put_word(46, 2, 32'hff7f_ffff);
            full_put_word(47, 0, 32'h7f80_0000);
            full_put_word(48, 0, 32'hff80_0000);
            full_put_word(49, 0, 32'h7f80_0000);
            full_put_word(49, 1, 32'hff80_0000);
            full_put_word(50, 0, 32'h7f80_0000);
            full_put_word(50, 1, 32'h7f80_0000);
            full_put_word(51, 0, 32'h7fc1_2345);
            full_put_word(52, 0, 32'hffc1_2345);
            full_put_word(53, 0, 32'h7f80_0001);
            full_put_word(54, 0, 32'hff80_0001);
            full_put_word(55, 0,   32'h7fc1_2345);
            full_put_word(55, 127, 32'h7f80_0001);
            full_put_word(56, 0,   32'h7f80_0000);
            full_put_word(56, 127, 32'hff80_0000);
            full_put_word(57, 0,   32'h7f80_0000);
            full_put_word(57, 127, 32'h7f80_0001);
            full_put_word(58, 0,   32'h7180_0000);
            full_put_word(58, 1,   32'h3f80_0000);
            full_put_word(58, 127, 32'h7f80_0001);
            full_put_word(59, 0, 32'h7180_0000);
            full_put_word(59, 1, 32'h5700_0000);
            full_put_word(59, 2, 32'hf180_0000);
            full_put_word(59, 3, 32'h5700_0000);

            full_expected_result[4]  = 32'h3f80_0000;
            full_expected_result[5]  = 32'h3f80_0000;
            full_expected_result[8]  = 32'h0000_0001;
            full_expected_result[9]  = 32'h8000_0001;
            full_expected_result[10] = 32'h0000_0080;
            full_expected_result[11] = 32'h0000_007f;
            full_expected_result[12] = 32'h0080_0000;
            full_expected_result[13] = 32'h007f_ffff;
            full_expected_result[14] = 32'h0080_0000;
            full_expected_result[16] = 32'h0000_0001;
            full_expected_result[17] = 32'h00ff_fffe;
            full_expected_result[18] = 32'h4b80_0001;
            full_expected_result[19] = 32'h3f80_0000;
            full_expected_result[20] = 32'hcb80_0001;
            full_expected_result[21] = 32'h3f80_0001;
            full_expected_result[22] = 32'h3f80_0000;
            full_expected_result[23] = 32'h3f80_0002;
            full_expected_result[24] = 32'h4b80_0000;
            full_expected_result[25] = 32'h4b80_0002;
            full_expected_result[26] = 32'hcb80_0000;
            full_expected_result[27] = 32'hcb80_0002;
            full_expected_result[29] = 32'h3f80_0000;
            full_expected_result[30] = 32'h3f80_0000;
            full_expected_result[32] = 32'h5800_0000;
            full_expected_result[34] = 32'h5780_0000;
            full_expected_result[36] = 32'hd800_0000;
            full_expected_result[38] = 32'h7f7f_ffff;
            full_expected_result[39] = 32'h7f7f_ffff;
            full_expected_result[40] = 32'h7f80_0000;
            full_expected_result[41] = 32'h7f80_0000;
            full_expected_result[42] = 32'h7f80_0000;
            full_expected_result[43] = 32'hff7f_ffff;
            full_expected_result[44] = 32'hff80_0000;
            full_expected_result[45] = 32'h7f7f_ffff;
            full_expected_result[46] = 32'h7f7f_ffff;
            full_expected_result[47] = 32'h7f80_0000;
            full_expected_result[48] = 32'hff80_0000;
            full_expected_result[49] = 32'h7fc0_0000;
            full_expected_result[50] = 32'h7f80_0000;
            full_expected_result[51] = 32'h7fc0_0000;
            full_expected_result[52] = 32'h7fc0_0000;
            full_expected_result[53] = 32'h7fc0_0000;
            full_expected_result[54] = 32'h7fc0_0000;
            full_expected_result[55] = 32'h7fc0_0000;
            full_expected_result[56] = 32'h7fc0_0000;
            full_expected_result[57] = 32'h7fc0_0000;
            full_expected_result[58] = 32'h7fc0_0000;
            full_expected_result[59] = 32'h5700_0000;

            for (row = 22; row <= 28; row = row + 1)
                full_expected_flags[row] = 5'h01;
            full_expected_flags[29] = 5'h00;
            for (row = 30; row <= 37; row = row + 1)
                full_expected_flags[row] = 5'h01;
            full_expected_flags[39] = 5'h01;
            full_expected_flags[40] = 5'h05;
            full_expected_flags[41] = 5'h05;
            full_expected_flags[42] = 5'h05;
            full_expected_flags[43] = 5'h01;
            full_expected_flags[44] = 5'h05;
            full_expected_flags[49] = 5'h10;
            for (row = 53; row <= 57; row = row + 1)
                full_expected_flags[row] = 5'h10;
            full_expected_flags[58] = 5'h11;
            full_expected_flags[59] = 5'h01;
        end
    endtask

    // Strict-order witnesses are sampled from true production handshakes.
    always @(posedge clk_i) begin
        if (!full_rst_i) begin
            if (u_full_dut.widen_req_fire_w
                    && (u_full_dut.element_index_q == 32'b0)
                    && (u_full_dut.accumulator_q != 64'b0))
                fail_case("full row did not use binary64 +0 seed");
            if (u_full_dut.add_req_fire_w
                    && ((u_full_dut.add_owner_valid_q != 1'b0)
                        || (u_full_dut.element_index_q >= 32'd128)))
                fail_case("full ADD owner/order before request");
            if (u_full_dut.narrow_req_fire_w
                    && ((u_full_dut.element_index_q != 32'd127)
                        || (u_full_dut.add_responses_q
                            != (({32'b0, u_full_dut.row_index_q} + 64'd1)
                                * 64'd128))))
                fail_case("full narrow before the 128th ordered ADD");
            if (({1'b0, u_full_dut.widen_owner_valid_q}
                    + {1'b0, u_full_dut.add_owner_valid_q}
                    + {1'b0, u_full_dut.narrow_owner_valid_q}) > 2'd1)
                fail_case("more than one child owner active");
        end
    end

    task automatic pulse_full_start;
        begin
            while (!full_ready_o)
                @(negedge clk_i);
            full_start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            full_start_i = 1'b0;
        end
    endtask

    task automatic run_full_success;
        integer cycles;
        integer row;
        integer address;
        logic [4:0] expected_sticky;
        begin
            pulse_full_start();
            cycles = 0;
            while (!full_done_o && !full_error_o && (cycles < 4000000)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (full_error_o)
                fail_case($sformatf("full profile error code=%0d",
                                    full_error_code_o));
            if (!full_done_o)
                fail_case("full profile terminal timeout");
            if (full_poisoned_o || !full_busy_o)
                fail_case("full terminal/poison visibility");
            if (full_fault_valid_o
                    || (full_first_fault_cycle_o != 64'b0)
                    || (full_first_fault_coordinate_o != 128'b0)
                    || (full_first_fault_gmem_addr_o != 64'b0)
                    || (full_first_fault_flags_o != 5'b0)
                    || (full_first_fault_request_events_o != 64'b0)
                    || (full_first_fault_response_events_o != 64'b0)
                    || (full_first_fault_txn_tag_o != 32'b0)
                    || full_first_fault_generation_o
                    || (full_first_fault_resource_o != 3'b0)
                    || (full_first_fault_owner_type_o != 3'b0)
                    || full_first_fault_owner_valid_o
                    || full_first_fault_owner_generation_o
                    || (full_first_fault_owner_row_o != 32'b0)
                    || (full_first_fault_owner_index_o != 32'b0))
                fail_case("full success first-fault output was not zero");

            expected_sticky = 5'b0;
            for (row = 0; row < FULL_ROWS; row = row + 1) begin
                address = 1572864 + (row * 4);
                if (full_get_word(address) !== full_expected_result[row])
                    fail_case($sformatf(
                        "full raw row=%0d actual=%08x expected=%08x",
                        row, full_get_word(address), full_expected_result[row]));
                expected_sticky = expected_sticky | full_expected_flags[row];
            end
            if (expected_sticky != 5'h15)
                fail_case("TB canonical sticky flag construction");
            if (full_flags_o !== expected_sticky)
                fail_case("full sticky arithmetic flags");
            if ((full_rows_reduced_o != 64'd2048)
                    || (full_elements_processed_o != 64'd262144)
                    || (full_gmem_read_requests_o != 64'd131072)
                    || (full_gmem_read_responses_o != 64'd131072)
                    || (full_gmem_write_requests_o != 64'd2048)
                    || (full_gmem_write_responses_o != 64'd2048)
                    || (full_widen_requests_o != 64'd262144)
                    || (full_widen_responses_o != 64'd262144)
                    || (full_add_requests_o != 64'd262144)
                    || (full_add_responses_o != 64'd262144)
                    || (full_narrow_requests_o != 64'd2048)
                    || (full_narrow_responses_o != 64'd2048))
                fail_case("full success cardinality");
            if ((full_read_accept_count != 131072)
                    || (full_write_accept_count != 2048)
                    || (full_response_count != 133120)
                    || (full_active_cycles_o == 64'b0))
                fail_case("full independent model cardinality");
            $display("[NPU-ORDERED-SUM-ROWS][CARDINALITY] rows=%0d elements=%0d gmem_read_req=%0d gmem_read_rsp=%0d widen_req=%0d widen_rsp=%0d add_req=%0d add_rsp=%0d narrow_req=%0d narrow_rsp=%0d shadow_write_req=%0d shadow_write_ack=%0d",
                     full_rows_reduced_o, full_elements_processed_o,
                     full_gmem_read_requests_o, full_gmem_read_responses_o,
                     full_widen_requests_o, full_widen_responses_o,
                     full_add_requests_o, full_add_responses_o,
                     full_narrow_requests_o, full_narrow_responses_o,
                     full_gmem_write_requests_o,
                     full_gmem_write_responses_o);
            for (address = 0; address < 8192; address = address + 1)
                if (full_mem[1703936 + address] !== 8'ha5)
                    fail_case("full active-root canary changed");
            @(negedge clk_i);
            if (!full_ready_o || full_done_o || full_error_o
                    || (full_done_count != 1))
                fail_case("full terminal was not exactly one cycle");
        end
    endtask

    task automatic set_small_descriptor;
        begin
            small_dtype_i              = 8'h01;
            small_profile_i            = 8'h01;
            small_rounding_mode_i      = 3'b000;
            small_denormal_mode_i      = 2'b00;
            small_nan_policy_i         = 2'b00;
            small_dst_shadow_private_i = 1'b1;
            small_reserved_i           = 32'b0;
            small_op_params_i          = 128'b0;
            small_gmem_floor_i         = 64'h0;
            small_gmem_limit_i         = 64'h0000_0000_0000_1000;
            small_src_region_base_i    = SMALL_SRC_BASE;
            small_src_region_size_i    = 64'd32;
            small_src_view_off_i       = 64'd0;
            small_src_ne0_i            = 32'd4;
            small_src_ne1_i            = 32'd2;
            small_src_ne2_i            = 32'd1;
            small_src_ne3_i            = 32'd1;
            small_src_nb0_i            = 64'd4;
            small_src_nb1_i            = 64'd16;
            small_src_nb2_i            = 64'd32;
            small_src_nb3_i            = 64'd32;
            small_dst_region_base_i    = SMALL_DST_BASE;
            small_dst_region_size_i    = 64'd16;
            small_dst_view_off_i       = 64'd0;
            small_dst_ne0_i            = 32'd1;
            small_dst_ne1_i            = 32'd2;
            small_dst_ne2_i            = 32'd1;
            small_dst_ne3_i            = 32'd1;
            small_dst_nb0_i            = 64'd4;
            small_dst_nb1_i            = 64'd4;
            small_dst_nb2_i            = 64'd8;
            small_dst_nb3_i            = 64'd8;
        end
    endtask

    task automatic prepare_small_memory;
        integer address;
        begin
            for (address = 0; address < SMALL_MEM_BYTES;
                    address = address + 1)
                small_mem[address] = 8'h00;
            small_put_word(0,  32'h3f80_0000);
            small_put_word(4,  32'h4000_0000);
            small_put_word(8,  32'h4040_0000);
            small_put_word(12, 32'h4080_0000);
            small_put_word(16, 32'h3f80_0000);
            small_put_word(20, 32'hbf80_0000);
            small_put_word(24, 32'h4000_0000);
            small_put_word(28, 32'hc000_0000);
            for (address = 0; address < 16; address = address + 1) begin
                small_mem[256 + address] = 8'hc3;
                small_mem[384 + address] = 8'h5a;
            end
            for (address = 0; address < 32; address = address + 1)
                small_mem[768 + address] = 8'ha5;
        end
    endtask

    task automatic wait_small_ready;
        integer cycles;
        begin
            cycles = 0;
            while (!small_ready_o && (cycles < 128)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_ready_o)
                fail_case("small instance did not return ready");
        end
    endtask

    task automatic arm_fault_oracle(
        input logic [2:0] resource,
        input logic [2:0] owner_type,
        input logic owner_valid,
        input logic owner_generation,
        input logic [31:0] owner_row,
        input logic [31:0] owner_index,
        input logic [31:0] coordinate_row,
        input logic [31:0] coordinate_read_beat,
        input logic [31:0] coordinate_element,
        input logic [31:0] coordinate_publish,
        input logic [63:0] expected_gmem_addr,
        input logic [63:0] request_event_delta,
        input logic [63:0] response_event_delta,
        input logic [4:0] flag_delta
    );
        begin
            if (small_fault_expect_arm_q)
                fail_case("fault oracle armed twice before sampling edge");
            small_fault_expect_resource_q = resource;
            small_fault_expect_owner_type_q = owner_type;
            small_fault_expect_owner_valid_q = owner_valid;
            small_fault_expect_owner_generation_q = owner_generation;
            small_fault_expect_owner_row_q = owner_row;
            small_fault_expect_owner_index_q = owner_index;
            small_fault_expect_coordinate_q = {
                coordinate_row,
                coordinate_read_beat,
                coordinate_element,
                coordinate_publish
            };
            small_fault_expect_cycle_q = small_active_cycles_o + 64'd1;
            small_fault_expect_gmem_addr_q = expected_gmem_addr;
            small_fault_expect_flags_q = small_flags_o | flag_delta;
            small_fault_expect_request_events_q =
                  small_gmem_read_requests_o
                + small_gmem_write_requests_o
                + small_widen_requests_o
                + small_add_requests_o
                + small_narrow_requests_o
                + request_event_delta;
            small_fault_expect_response_events_q =
                  small_gmem_read_responses_o
                + small_gmem_write_responses_o
                + small_widen_responses_o
                + small_add_responses_o
                + small_narrow_responses_o
                + response_event_delta;
            small_fault_expect_txn_tag_q = small_tb_txn_tag_q;
            small_fault_expect_generation_q = small_tb_generation_q;
            small_fault_expect_arm_q = 1'b1;
        end
    endtask

    task automatic disarm_fault_oracle;
        begin
            small_fault_expect_arm_q = 1'b0;
        end
    endtask

    task automatic pulse_small_start;
        begin
            wait_small_ready();
            small_txn_tag_i = small_txn_tag_i + 32'd1;
            small_start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            small_start_i = 1'b0;
        end
    endtask

    task automatic wait_small_terminal(
        input logic expect_error,
        input logic [4:0] expected_code,
        input string label
    );
        integer cycles;
        begin
            cycles = 0;
            while (!small_done_o && !small_error_o && (cycles < 4096)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_done_o && !small_error_o)
                fail_case($sformatf("%s terminal timeout", label));
            if (expect_error) begin
                if (!small_error_o || small_done_o
                        || (small_error_code_o != expected_code))
                    fail_case($sformatf("%s error actual=%0d expected=%0d",
                        label, small_error_code_o, expected_code));
                if (!small_fault_valid_o)
                    fail_case($sformatf("%s error missing fault metadata", label));
                if (expected_code == ERR_POISONED) begin
                    if ((u_small_dut.state_q !== ST_POISON_ERROR)
                            || !small_error_o || !small_poisoned_o
                            || small_done_o || small_ready_o)
                        fail_case($sformatf(
                            "%s poison-error terminal state/output", label));
                end else begin
                    if ((u_small_dut.state_q !== ST_ERROR)
                            || small_poisoned_o)
                        fail_case($sformatf(
                            "%s recoverable terminal state actual=%0d expected=%0d",
                            label, u_small_dut.state_q, ST_ERROR));
                end
            end else if (!small_done_o || small_error_o) begin
                fail_case($sformatf("%s unexpectedly failed code=%0d",
                                    label, small_error_code_o));
            end else begin
                if (small_fault_valid_o
                        || (small_first_fault_cycle_o != 64'b0)
                        || (small_first_fault_coordinate_o != 128'b0)
                        || (small_first_fault_gmem_addr_o != 64'b0)
                        || (small_first_fault_flags_o != 5'b0)
                        || (small_first_fault_request_events_o != 64'b0)
                        || (small_first_fault_response_events_o != 64'b0)
                        || (small_first_fault_txn_tag_o != 32'b0)
                        || small_first_fault_generation_o
                        || (small_first_fault_resource_o != 3'b0)
                        || (small_first_fault_owner_type_o != 3'b0)
                        || small_first_fault_owner_valid_o
                        || small_first_fault_owner_generation_o
                        || (small_first_fault_owner_row_o != 32'b0)
                        || (small_first_fault_owner_index_o != 32'b0))
                    fail_case($sformatf(
                        "%s success exposed fault metadata", label));
                success_fault_zero_check_count =
                    success_fault_zero_check_count + 1;
            end
            small_fault_expect_arm_q = 1'b0;
        end
    endtask

    integer positive_fixture_count;
    integer preflight_fixture_count;
    integer gmem_fault_fixture_count;
    integer child_fault_fixture_count;
    integer child_fault_edge_witness_count;
    integer overlap_fault_fixture_count;
    integer terminal_cleanup_fixture_count;
    integer reset_fixture_count;
    integer busy_start_fixture_count;
    integer persistent_ledger_killer_count;
    integer held_gmem_killer_count;
    integer held_child_killer_count;
    integer retired_late_ghost_killer_count;
    integer deadline_fire_witness_count;
    integer first_fault_address_killer_count;

    logic        child_fault_generation_snapshot;
    logic [127:0] child_fault_coordinate_snapshot;
    logic [194:0] child_fault_owner_tag_snapshot;
    logic [4:0]   child_fault_flags_snapshot;
    logic [127:0] child_fault_progress_snapshot;
    logic [63:0]  child_fault_request_credit_snapshot;
    logic [63:0]  child_fault_response_credit_snapshot;
    integer       child_fault_gmem_accept_snapshot;
    logic         child_fault_gmem_owner_snapshot;
    logic [2:0]   child_fault_child_owner_snapshot;

    task automatic run_small_positive(input string label);
        integer address;
        begin
            set_small_descriptor();
            small_allow_requests_q      = 1'b1;
            small_hold_responses_q      = 1'b0;
            small_inject_read_error_q   = 1'b0;
            small_inject_write_error_q  = 1'b0;
            small_response_delay_q      = 0;
            for (address = 0; address < 16; address = address + 1)
                small_mem[256 + address] = 8'hc3;
            pulse_small_start();
            wait_small_terminal(1'b0, 5'b0, label);
            if ((small_get_word(256) !== 32'h4120_0000)
                    || (small_get_word(260) !== 32'h0000_0000))
                fail_case($sformatf("%s raw result", label));
            if ((small_flags_o != 5'b0)
                    || (small_rows_reduced_o != 64'd2)
                    || (small_elements_processed_o != 64'd8)
                    || (small_gmem_read_requests_o != 64'd4)
                    || (small_gmem_read_responses_o != 64'd4)
                    || (small_gmem_write_requests_o != 64'd2)
                    || (small_gmem_write_responses_o != 64'd2)
                    || (small_widen_requests_o != 64'd8)
                    || (small_widen_responses_o != 64'd8)
                    || (small_add_requests_o != 64'd8)
                    || (small_add_responses_o != 64'd8)
                    || (small_narrow_requests_o != 64'd2)
                    || (small_narrow_responses_o != 64'd2)
                    || (small_active_cycles_o == 64'b0))
                fail_case($sformatf("%s success cardinality", label));
            positive_fixture_count = positive_fixture_count + 1;
            @(negedge clk_i);
        end
    endtask

    task automatic run_preflight_error(
        input logic [4:0] expected_code,
        input string label
    );
        integer accepted_before;
        integer done_before;
        integer error_before;
        begin
            accepted_before = small_accept_count;
            done_before = small_done_count;
            error_before = small_error_count;
            pulse_small_start();
            if (u_small_dut.state_q != ST_PREFLIGHT)
                fail_case($sformatf("%s did not expose preflight edge", label));
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            wait_small_terminal(1'b1, expected_code, label);
            if (small_accept_count != accepted_before)
                fail_case($sformatf("%s issued request before preflight", label));
            if ((small_gmem_read_requests_o != 64'b0)
                    || (small_gmem_write_requests_o != 64'b0)
                    || (small_widen_requests_o != 64'b0)
                    || (small_add_requests_o != 64'b0)
                    || (small_narrow_requests_o != 64'b0))
                fail_case($sformatf("%s nonzero preflight counters", label));
            preflight_fixture_count = preflight_fixture_count + 1;
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case($sformatf("%s terminal delta", label));
            set_small_descriptor();
        end
    endtask

    task automatic wait_small_state(
        input logic [4:0] wanted,
        input string label
    );
        integer cycles;
        begin
            cycles = 0;
            while ((u_small_dut.state_q != wanted) && (cycles < 2048)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (u_small_dut.state_q != wanted)
                fail_case($sformatf("%s did not reach state %0d", label, wanted));
        end
    endtask

    task automatic run_request_timeout;
        integer accepted_before;
        integer done_before;
        integer error_before;
        logic [136:0] held_payload;
        begin
            set_small_descriptor();
            accepted_before = small_accept_count;
            done_before = small_done_count;
            error_before = small_error_count;
            small_allow_requests_q = 1'b0;
            small_hold_responses_q = 1'b1;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_REQ, "held GMEM read request setup");
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            if (!small_req_valid_o || small_req_ready_i
                    || u_small_dut.gmem_req_fire_w)
                fail_case("held GMEM request timeout predicate");
            held_payload = {small_req_write_o, small_req_addr_o,
                            small_req_wdata_o, small_req_wstrb_o};
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if (!u_small_dut.fault_latched_q || !u_small_dut.abort_hold_q
                    || (u_small_dut.state_q != ST_ROW_READ_REQ)
                    || !small_req_valid_o || small_req_ready_i
                    || ({small_req_write_o, small_req_addr_o,
                         small_req_wdata_o, small_req_wstrb_o} != held_payload)
                    || (small_accept_count != accepted_before))
                fail_case("held GMEM request fault withdrew request");
            @(negedge clk_i);
            small_allow_requests_q = 1'b1;
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || u_small_dut.abort_hold_q
                    || !u_small_dut.gmem_owner_valid_q
                    || (small_gmem_read_requests_o != 64'd1)
                    || (small_accept_count != (accepted_before + 1)))
                fail_case("held GMEM request did not fire exactly once");
            small_hold_responses_q = 1'b0;
            wait_small_terminal(1'b1, ERR_STALL_TIMEOUT,
                                "GMEM REQ timeout held-fire cleanup");
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            held_gmem_killer_count = held_gmem_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][HELD-GMEM-REQ-FAULT] phase=read held=1 stable=1 fire=1 owner=1 count=1 drain=1");
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case("GMEM REQ timeout terminal delta");
        end
    endtask

    task automatic run_gmem_response_error(
        input logic on_write,
        input string label
    );
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            set_small_descriptor();
            small_inject_read_error_q  = !on_write;
            small_inject_write_error_q = on_write;
            pulse_small_start();
            while (!(small_rsp_valid_model_q
                    && u_small_dut.gmem_owner_match_w
                    && small_rsp_error_i))
                @(negedge clk_i);
            arm_fault_oracle(FAULT_RESOURCE_GMEM,
                on_write ? OWNER_GMEM_WRITE : OWNER_GMEM_READ,
                1'b0, small_tb_generation_q, 32'b0, 32'b0,
                on_write ? 32'd1 : 32'b0,
                32'b0, on_write ? 32'd3 : 32'b0, 32'b0,
                on_write
                    ? ((small_dst_region_base_i + small_dst_view_off_i)
                       & 64'hffff_ffff_ffff_fff8)
                    : (small_src_region_base_i + small_src_view_off_i),
                64'b0, 64'd1, 5'b0);
            wait_small_terminal(1'b1, ERR_GMEM_RESPONSE, label);
            if (small_done_o)
                fail_case($sformatf("%s gained commit eligibility", label));
            small_inject_read_error_q  = 1'b0;
            small_inject_write_error_q = 1'b0;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case($sformatf("%s terminal delta", label));
        end
    endtask

    task automatic run_accepted_drain(
        input logic late_error,
        input string label
    );
        logic [63:0] frozen_read_responses;
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            set_small_descriptor();
            small_hold_responses_q     = 1'b1;
            small_inject_read_error_q  = late_error;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_WAIT, label);
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            arm_fault_oracle(FAULT_RESOURCE_CONTROL,
                OWNER_GMEM_READ, 1'b1, small_tb_generation_q,
                32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            wait_small_state(ST_GMEM_DRAIN, label);
            if (!u_small_dut.gmem_owner_valid_q)
                fail_case($sformatf("%s lost accepted drain owner", label));
            frozen_read_responses = small_gmem_read_responses_o;
            small_hold_responses_q = 1'b0;
            wait_small_terminal(1'b1, ERR_STALL_TIMEOUT, label);
            // The late response is transport credit even though it cannot
            // change semantic data or the immutable first-fault cause.
            if (small_gmem_read_responses_o
                    != (frozen_read_responses + 64'd1))
                fail_case($sformatf("%s lost drain response credit", label));
            if ((u_small_dut.error_code_q != ERR_STALL_TIMEOUT)
                    || !u_small_dut.fault_latched_q)
                fail_case($sformatf("%s changed first-fault cause", label));
            small_inject_read_error_q = 1'b0;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case($sformatf("%s terminal delta", label));
        end
    endtask

    task automatic run_drain_poison;
        integer done_before;
        integer error_before;
        integer poison_state_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            poison_state_before = terminal_poison_state_witness_count;
            set_small_descriptor();
            small_hold_responses_q = 1'b1;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_WAIT, "bounded drain poison setup");
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            arm_fault_oracle(FAULT_RESOURCE_CONTROL,
                OWNER_GMEM_READ, 1'b1, small_tb_generation_q,
                32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            wait_small_terminal(1'b1, ERR_POISONED, "bounded drain poison");
            if (!small_poisoned_o || small_ready_o)
                fail_case("poison did not prohibit descriptor reuse");
            @(posedge clk_i);
            @(negedge clk_i);
            if ((u_small_dut.state_q !== ST_POISON)
                    || !small_poisoned_o || small_error_o
                    || small_done_o || small_ready_o)
                fail_case("poison was not reset-only persistent");
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case("bounded drain poison terminal delta");
            drain_poison_witness_count = drain_poison_witness_count + 1;
            // The independent negedge monitor and this fixture are separate
            // processes.  Do not assert synchronous reset in the same active
            // region as the first ST_POISON observation: a reset-first process
            // ordering would hide the real state entry from the monitor.
            #1;
            if (terminal_poison_state_witness_count
                    != (poison_state_before + 1))
                fail_case("bounded drain poison post-NBA state witness");
            $display("[NPU-ORDERED-SUM-ROWS][DRAIN-POISON-ENTRY] post_nba=1 reset_low=1 witness_delta=1");
            small_rst_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            small_rst_i = 1'b0;
            small_hold_responses_q = 1'b0;
            @(negedge clk_i);
            if (!small_ready_o || small_poisoned_o)
                fail_case("global reset did not clear poison");
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
        end
    endtask

    task automatic reset_small_reset_only_poison(input string label);
        begin
            small_start_i = 1'b0;
            small_rsp_valid_ghost_q = 1'b0;
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b0;
            disarm_fault_oracle();
            small_rst_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (small_req_valid_o || small_rsp_ready_o || small_done_o
                    || small_error_o || small_poisoned_o || small_ready_o)
                fail_case($sformatf("%s reset edge visibility", label));
            @(negedge clk_i);
            small_rst_i = 1'b0;
            #1;
            if (!small_ready_o || small_busy_o || small_poisoned_o
                    || small_fault_valid_o || small_done_o || small_error_o
                    || (small_gmem_read_requests_o != 64'b0)
                    || (small_gmem_read_responses_o != 64'b0)
                    || (small_gmem_write_requests_o != 64'b0)
                    || (small_gmem_write_responses_o != 64'b0))
                fail_case($sformatf("%s reset did not clear poison", label));
            @(negedge clk_i);
        end
    endtask

    // Same-edge ownerless response + real read request.  The request is a
    // true transport fire and is therefore ledgered, while the untagged old
    // response is forbidden from becoming DRAIN credit for that new owner.
    task automatic run_ownerless_read_request_collision;
        integer accepted_before;
        integer response_before;
        integer done_before;
        integer error_before;
        integer capture_before;
        logic resident_generation;
        logic [31:0] row0_before;
        logic [31:0] row1_before;
        logic [31:0] row2_before;
        logic [31:0] row3_before;
        logic [31:0] result0_before;
        logic [31:0] result1_before;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b1;
            small_rsp_valid_ghost_q = 1'b0;
            accepted_before = small_accept_count;
            response_before = small_response_count;
            done_before = small_done_count;
            error_before = small_error_count;
            capture_before = fault_output_capture_count;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_REQ,
                             "ownerless read request collision setup");
            if (u_small_dut.gmem_owner_valid_q || small_pending_q
                    || !small_req_valid_o || !small_req_ready_i
                    || small_req_write_o)
                fail_case("ownerless read collision precondition");
            row0_before = u_small_dut.row_buffer_q[0];
            row1_before = u_small_dut.row_buffer_q[1];
            row2_before = u_small_dut.row_buffer_q[2];
            row3_before = u_small_dut.row_buffer_q[3];
            result0_before = u_small_dut.result_buffer_q[0];
            result1_before = u_small_dut.result_buffer_q[1];
            small_rsp_valid_ghost_q = 1'b1;
            #1;
            if (!u_small_dut.gmem_req_fire_w
                    || !u_small_dut.gmem_owner_fault_w
                    || !u_small_dut.gmem_ownerless_request_collision_w
                    || small_rsp_ready_o)
                fail_case("ownerless read collision predicate");
            arm_fault_oracle(FAULT_RESOURCE_GMEM, OWNER_GMEM_READ,
                1'b1, small_tb_generation_q, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'd1, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || !u_small_dut.collision_poison_q
                    || !u_small_dut.fault_latched_q
                    || (u_small_dut.error_code_q != ERR_PROTOCOL_OWNER)
                    || !u_small_dut.gmem_owner_valid_q
                    || u_small_dut.gmem_owner_write_q
                    || (small_gmem_read_requests_o != 64'd1)
                    || (small_gmem_read_responses_o != 64'b0)
                    || (small_accept_count != (accepted_before + 1))
                    || (fault_output_capture_count != (capture_before + 1))
                    || !small_poisoned_o || small_error_o || small_done_o
                    || small_rsp_ready_o)
                fail_case("ownerless read collision post-fire accounting");
            if ((u_small_dut.row_buffer_q[0] != row0_before)
                    || (u_small_dut.row_buffer_q[1] != row1_before)
                    || (u_small_dut.row_buffer_q[2] != row2_before)
                    || (u_small_dut.row_buffer_q[3] != row3_before)
                    || (u_small_dut.result_buffer_q[0] != result0_before)
                    || (u_small_dut.result_buffer_q[1] != result1_before))
                fail_case("ownerless read collision changed semantic buffers");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_POISON)
                    || !u_small_dut.gmem_owner_valid_q
                    || small_rsp_ready_o || !small_rsp_valid_ghost_q
                    || (small_gmem_read_responses_o != 64'b0))
                fail_case("ownerless read collision did not bypass drain");
            @(negedge clk_i);
            small_hold_responses_q = 1'b0;
            @(posedge clk_i);
            #1;
            if (!small_rsp_valid_model_q || !small_rsp_valid_i
                    || small_rsp_ready_o
                    || (small_response_count != response_before)
                    || (small_gmem_read_responses_o != 64'b0)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before)
                    || (u_small_dut.row_buffer_q[0] != row0_before)
                    || (u_small_dut.row_buffer_q[1] != row1_before)
                    || (u_small_dut.row_buffer_q[2] != row2_before)
                    || (u_small_dut.row_buffer_q[3] != row3_before))
                fail_case("ownerless read collision ghost/late response credit");
            resident_generation = u_small_dut.generation_q;
            small_start_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (small_ready_o || u_small_dut.start_fire_w
                    || (u_small_dut.generation_q != resident_generation)
                    || (u_small_dut.state_q != ST_POISON)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("ownerless read collision accepted new command");
            @(negedge clk_i);
            small_start_i = 1'b0;
            collision_poison_witness_count =
                collision_poison_witness_count + 1;
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=COLLISION_READ resource=GMEM owner=GMEM_READ addr=%016x req_delta=1",
                     small_first_fault_gmem_addr_o);
            $display("[NPU-ORDERED-SUM-ROWS][OWNERLESS-REQ-COLLISION] channel=read fire=1 request_credit=1 ghost_credit=0 late_credit=0 semantic_write=0 terminal=0 poison=1 reset_only=1");
            reset_small_reset_only_poison("ownerless read collision");
            run_small_positive("clean retry after ownerless read collision");
        end
    endtask

    // Publish-channel twin of the read collision.  The accepted write may
    // update only the transaction-private destination shadow on its real fire;
    // all later ghost/response levels are denied semantic and terminal credit.
    task automatic run_ownerless_publish_request_collision;
        integer accepted_before;
        integer response_before;
        integer done_before;
        integer error_before;
        integer capture_before;
        logic resident_generation;
        logic [31:0] result0_after_fire;
        logic [31:0] result1_after_fire;
        logic [31:0] dst0_after_fire;
        logic [31:0] dst1_after_fire;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b0;
            small_rsp_valid_ghost_q = 1'b0;
            accepted_before = small_accept_count;
            response_before = small_response_count;
            done_before = small_done_count;
            error_before = small_error_count;
            capture_before = fault_output_capture_count;
            pulse_small_start();
            wait_small_state(ST_PUBLISH_PREP,
                             "ownerless publish collision prep");
            small_allow_requests_q = 1'b0;
            small_hold_responses_q = 1'b1;
            wait_small_state(ST_PUBLISH_REQ,
                             "ownerless publish request collision setup");
            if (u_small_dut.gmem_owner_valid_q || small_pending_q
                    || !small_req_valid_o || small_req_ready_i
                    || !small_req_write_o)
                fail_case("ownerless publish collision precondition");
            accepted_before = small_accept_count;
            response_before = small_response_count;
            small_rsp_valid_ghost_q = 1'b1;
            small_allow_requests_q = 1'b1;
            #1;
            if (!u_small_dut.gmem_req_fire_w
                    || !u_small_dut.gmem_owner_fault_w
                    || !u_small_dut.gmem_ownerless_request_collision_w
                    || small_rsp_ready_o)
                fail_case("ownerless publish collision predicate");
            arm_fault_oracle(FAULT_RESOURCE_GMEM, OWNER_GMEM_WRITE,
                1'b1, small_tb_generation_q, 32'b0, 32'b0,
                32'd1, 32'b0, 32'd3, 32'b0,
                (small_dst_region_base_i + small_dst_view_off_i)
                    & 64'hffff_ffff_ffff_fff8,
                64'd1, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            result0_after_fire = u_small_dut.result_buffer_q[0];
            result1_after_fire = u_small_dut.result_buffer_q[1];
            dst0_after_fire = small_get_word(256);
            dst1_after_fire = small_get_word(260);
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || !u_small_dut.collision_poison_q
                    || !u_small_dut.fault_latched_q
                    || (u_small_dut.error_code_q != ERR_PROTOCOL_OWNER)
                    || !u_small_dut.gmem_owner_valid_q
                    || !u_small_dut.gmem_owner_write_q
                    || (small_gmem_write_requests_o != 64'd1)
                    || (small_gmem_write_responses_o != 64'b0)
                    || (small_accept_count != (accepted_before + 1))
                    || (fault_output_capture_count != (capture_before + 1))
                    || !small_poisoned_o || small_error_o || small_done_o
                    || small_rsp_ready_o)
                fail_case("ownerless publish collision post-fire accounting");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_POISON)
                    || !u_small_dut.gmem_owner_valid_q
                    || small_rsp_ready_o || !small_rsp_valid_ghost_q
                    || (small_gmem_write_responses_o != 64'b0))
                fail_case("ownerless publish collision did not bypass drain");
            @(negedge clk_i);
            small_hold_responses_q = 1'b0;
            @(posedge clk_i);
            #1;
            if (!small_rsp_valid_model_q || !small_rsp_valid_i
                    || small_rsp_ready_o
                    || (small_response_count != response_before)
                    || (small_gmem_write_responses_o != 64'b0)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before)
                    || (u_small_dut.result_buffer_q[0]
                        != result0_after_fire)
                    || (u_small_dut.result_buffer_q[1]
                        != result1_after_fire)
                    || (small_get_word(256) != dst0_after_fire)
                    || (small_get_word(260) != dst1_after_fire))
                fail_case("ownerless publish collision ghost/late response credit");
            resident_generation = u_small_dut.generation_q;
            small_start_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (small_ready_o || u_small_dut.start_fire_w
                    || (u_small_dut.generation_q != resident_generation)
                    || (u_small_dut.state_q != ST_POISON)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("ownerless publish collision accepted new command");
            @(negedge clk_i);
            small_start_i = 1'b0;
            collision_poison_witness_count =
                collision_poison_witness_count + 1;
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=COLLISION_PUBLISH resource=GMEM owner=GMEM_WRITE addr=%016x req_delta=1",
                     small_first_fault_gmem_addr_o);
            $display("[NPU-ORDERED-SUM-ROWS][OWNERLESS-REQ-COLLISION] channel=publish fire=1 request_credit=1 ghost_credit=0 late_credit=0 semantic_write=0 terminal=0 poison=1 reset_only=1");
            reset_small_reset_only_poison("ownerless publish collision");
            run_small_positive("clean retry after ownerless publish collision");
        end
    endtask

    // Normal REQ timeout first latches the immutable cause.  The independent
    // abort watchdog then asserts poison on the sixth complete held cycle
    // without withdrawing valid/payload.  A later ghost+real fire proves that
    // collision poison remains independent of the already-resident cause.
    task automatic run_abort_hold_read_watchdog;
        integer held_cycle;
        integer accepted_before;
        integer done_before;
        integer error_before;
        integer capture_before;
        logic [136:0] held_payload;
        logic [63:0] frozen_active_cycles;
        logic [63:0] first_cycle_snapshot;
        logic [63:0] first_request_snapshot;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b0;
            small_hold_responses_q = 1'b1;
            small_rsp_valid_ghost_q = 1'b0;
            accepted_before = small_accept_count;
            done_before = small_done_count;
            error_before = small_error_count;
            capture_before = fault_output_capture_count;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_REQ,
                             "abort-hold read watchdog setup");
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            held_payload = {small_req_write_o, small_req_addr_o,
                            small_req_wdata_o, small_req_wstrb_o};
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if (!u_small_dut.fault_latched_q || !u_small_dut.abort_hold_q
                    || u_small_dut.abort_hold_poison_q
                    || (u_small_dut.state_q != ST_ROW_READ_REQ)
                    || !small_req_valid_o || small_req_ready_i
                    || ({small_req_write_o, small_req_addr_o,
                         small_req_wdata_o, small_req_wstrb_o} != held_payload)
                    || (small_accept_count != accepted_before)
                    || (fault_output_capture_count != (capture_before + 1)))
                fail_case("abort-hold read timeout capture");
            first_cycle_snapshot = small_first_fault_cycle_o;
            first_request_snapshot = small_first_fault_request_events_o;
            for (held_cycle = 0;
                    held_cycle < SMALL_ABORT_HOLD_TIMEOUT;
                    held_cycle = held_cycle + 1) begin
                @(posedge clk_i);
                #1;
                if ((u_small_dut.state_q != ST_ROW_READ_REQ)
                        || !u_small_dut.abort_hold_q
                        || !small_req_valid_o || small_req_ready_i
                        || ({small_req_write_o, small_req_addr_o,
                             small_req_wdata_o, small_req_wstrb_o}
                            != held_payload)
                        || (small_accept_count != accepted_before)
                        || (small_done_count != done_before)
                        || (small_error_count != error_before))
                    fail_case("abort-hold read valid/payload stability");
                if ((held_cycle < (SMALL_ABORT_HOLD_TIMEOUT - 1))
                        && (u_small_dut.abort_hold_poison_q
                            || small_poisoned_o))
                    fail_case("abort-hold read watchdog fired early");
                if ((held_cycle == (SMALL_ABORT_HOLD_TIMEOUT - 1))
                        && (!u_small_dut.abort_hold_poison_q
                            || !small_poisoned_o
                            || (small_error_code_o != ERR_STALL_TIMEOUT)))
                    fail_case("abort-hold read watchdog missed bound");
            end
            abort_hold_poison_witness_count =
                abort_hold_poison_witness_count + 1;
            frozen_active_cycles = small_active_cycles_o;
            repeat (2) begin
                @(posedge clk_i);
                #1;
                if ((small_active_cycles_o != frozen_active_cycles)
                        || !small_poisoned_o || small_error_o || small_done_o
                        || !small_req_valid_o || small_req_ready_i
                        || (u_small_dut.state_q != ST_ROW_READ_REQ))
                    fail_case("abort-hold read post-bound stability");
            end
            @(negedge clk_i);
            small_rsp_valid_ghost_q = 1'b1;
            small_allow_requests_q = 1'b1;
            #1;
            if (!u_small_dut.gmem_req_fire_w
                    || !u_small_dut.gmem_owner_fault_w
                    || !u_small_dut.gmem_ownerless_request_collision_w)
                fail_case("abort-hold read late collision predicate");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || u_small_dut.abort_hold_q
                    || !u_small_dut.abort_hold_poison_q
                    || !u_small_dut.collision_poison_q
                    || !u_small_dut.gmem_owner_valid_q
                    || (small_gmem_read_requests_o != 64'd1)
                    || (small_accept_count != (accepted_before + 1))
                    || (fault_output_capture_count != (capture_before + 1))
                    || (small_first_fault_cycle_o != first_cycle_snapshot)
                    || (small_first_fault_request_events_o
                        != first_request_snapshot)
                    || (small_first_fault_resource_o
                        != FAULT_RESOURCE_CONTROL)
                    || (small_first_fault_owner_type_o != OWNER_NONE)
                    || small_first_fault_owner_valid_o
                    || small_error_o || small_done_o)
                fail_case("abort-hold read late fire/first-cause accounting");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_POISON)
                    || small_rsp_ready_o
                    || (small_gmem_read_responses_o != 64'b0)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("abort-hold read collision terminal isolation");
            @(negedge clk_i);
            small_hold_responses_q = 1'b0;
            @(posedge clk_i);
            #1;
            if (!small_rsp_valid_model_q || small_rsp_ready_o
                    || (small_gmem_read_responses_o != 64'b0)
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("abort-hold read late response gained credit");
            collision_poison_witness_count =
                collision_poison_witness_count + 1;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][ABORT-HOLD-WATCHDOG] channel=read bound=6 held_valid=1 payload_stable=1 poison=1 terminal=0 late_fire=1 fire_count=1 collision=1 first_cause_stable=1");
            reset_small_reset_only_poison("abort-hold read watchdog");
            run_small_positive("clean retry after abort-hold read watchdog");
        end
    endtask

    // Publish-channel watchdog twin: request ready remains permanently low
    // through the bound and reset, proving bounded poison without any fire.
    task automatic run_abort_hold_publish_watchdog;
        integer held_cycle;
        integer accepted_before;
        integer done_before;
        integer error_before;
        integer capture_before;
        logic [136:0] held_payload;
        logic [63:0] frozen_active_cycles;
        logic resident_generation;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b0;
            small_rsp_valid_ghost_q = 1'b0;
            accepted_before = small_accept_count;
            done_before = small_done_count;
            error_before = small_error_count;
            capture_before = fault_output_capture_count;
            pulse_small_start();
            wait_small_state(ST_PUBLISH_PREP,
                             "abort-hold publish watchdog prep");
            small_allow_requests_q = 1'b0;
            small_hold_responses_q = 1'b1;
            wait_small_state(ST_PUBLISH_REQ,
                             "abort-hold publish watchdog setup");
            accepted_before = small_accept_count;
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            held_payload = {small_req_write_o, small_req_addr_o,
                            small_req_wdata_o, small_req_wstrb_o};
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'd1, 32'b0, 32'd3, 32'b0,
                (small_dst_region_base_i + small_dst_view_off_i)
                    & 64'hffff_ffff_ffff_fff8,
                64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if (!u_small_dut.fault_latched_q || !u_small_dut.abort_hold_q
                    || u_small_dut.abort_hold_poison_q
                    || (u_small_dut.state_q != ST_PUBLISH_REQ)
                    || !small_req_valid_o || small_req_ready_i
                    || ({small_req_write_o, small_req_addr_o,
                         small_req_wdata_o, small_req_wstrb_o} != held_payload)
                    || (small_accept_count != accepted_before)
                    || (fault_output_capture_count != (capture_before + 1)))
                fail_case("abort-hold publish timeout capture");
            for (held_cycle = 0;
                    held_cycle < SMALL_ABORT_HOLD_TIMEOUT;
                    held_cycle = held_cycle + 1) begin
                @(posedge clk_i);
                #1;
                if ((u_small_dut.state_q != ST_PUBLISH_REQ)
                        || !u_small_dut.abort_hold_q
                        || !small_req_valid_o || small_req_ready_i
                        || ({small_req_write_o, small_req_addr_o,
                             small_req_wdata_o, small_req_wstrb_o}
                            != held_payload)
                        || (small_accept_count != accepted_before)
                        || (small_done_count != done_before)
                        || (small_error_count != error_before))
                    fail_case("abort-hold publish valid/payload stability");
                if ((held_cycle < (SMALL_ABORT_HOLD_TIMEOUT - 1))
                        && (u_small_dut.abort_hold_poison_q
                            || small_poisoned_o))
                    fail_case("abort-hold publish watchdog fired early");
                if ((held_cycle == (SMALL_ABORT_HOLD_TIMEOUT - 1))
                        && (!u_small_dut.abort_hold_poison_q
                            || !small_poisoned_o
                            || (small_error_code_o != ERR_STALL_TIMEOUT)))
                    fail_case("abort-hold publish watchdog missed bound");
            end
            abort_hold_poison_witness_count =
                abort_hold_poison_witness_count + 1;
            frozen_active_cycles = small_active_cycles_o;
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if ((small_active_cycles_o != frozen_active_cycles)
                        || !small_poisoned_o || small_error_o || small_done_o
                        || !small_req_valid_o || small_req_ready_i
                        || (u_small_dut.state_q != ST_PUBLISH_REQ)
                        || (small_gmem_write_requests_o != 64'b0)
                        || (small_accept_count != accepted_before))
                    fail_case("abort-hold publish ready-low stability");
            end
            resident_generation = u_small_dut.generation_q;
            small_start_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (small_ready_o || u_small_dut.start_fire_w
                    || (u_small_dut.generation_q != resident_generation)
                    || (u_small_dut.state_q != ST_PUBLISH_REQ)
                    || !small_req_valid_o || small_req_ready_i
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("abort-hold publish accepted command/withdrew valid");
            @(negedge clk_i);
            small_start_i = 1'b0;
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][ABORT-HOLD-WATCHDOG] channel=publish bound=6 held_valid=1 payload_stable=1 poison=1 terminal=0 ready_low=1 fire_count=0 reset_cancel=1");
            reset_small_reset_only_poison("abort-hold publish watchdog");
            run_small_positive("clean retry after abort-hold publish watchdog");
        end
    endtask

    task automatic finish_child_fault(input string label);
        integer cycles;
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            @(negedge clk_i);
            if (u_small_dut.state_q != ST_CHILD_QUARANTINE)
                fail_case($sformatf("%s missed registered quarantine", label));
            cycles = 0;
            while (!small_error_o && !small_done_o && (cycles < 128)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_error_o || (small_error_code_o != ERR_CHILD_RESPONSE)
                    || small_done_o || small_poisoned_o)
                fail_case($sformatf("%s terminal", label));
            if (u_small_dut.gmem_owner_valid_q
                    || u_small_dut.widen_owner_valid_q
                    || u_small_dut.add_owner_valid_q
                    || u_small_dut.narrow_owner_valid_q)
                fail_case($sformatf("%s terminal owner cleanup", label));
            child_fault_fixture_count = child_fault_fixture_count + 1;
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case($sformatf("%s terminal delta", label));
        end
    endtask

    task automatic finish_protocol_fault(input string label);
        integer cycles;
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            @(negedge clk_i);
            if (u_small_dut.state_q != ST_CHILD_QUARANTINE)
                fail_case($sformatf("%s missed registered quarantine", label));
            cycles = 0;
            while (!small_error_o && !small_done_o && (cycles < 128)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_error_o
                    || (small_error_code_o != ERR_PROTOCOL_OWNER)
                    || small_done_o || small_poisoned_o)
                fail_case($sformatf("%s protocol terminal", label));
            if (u_small_dut.gmem_owner_valid_q
                    || u_small_dut.widen_owner_valid_q
                    || u_small_dut.add_owner_valid_q
                    || u_small_dut.narrow_owner_valid_q)
                fail_case($sformatf("%s protocol owner cleanup", label));
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case($sformatf("%s protocol terminal delta", label));
        end
    endtask

    task automatic capture_child_fault_snapshot;
        begin
            child_fault_generation_snapshot = u_small_dut.generation_q;
            child_fault_coordinate_snapshot = {
                u_small_dut.row_index_q,
                u_small_dut.read_beat_q,
                u_small_dut.element_index_q,
                u_small_dut.publish_index_q
            };
            child_fault_owner_tag_snapshot = {
                u_small_dut.widen_owner_generation_q,
                u_small_dut.widen_owner_row_q,
                u_small_dut.widen_owner_element_q,
                u_small_dut.add_owner_generation_q,
                u_small_dut.add_owner_row_q,
                u_small_dut.add_owner_element_q,
                u_small_dut.narrow_owner_generation_q,
                u_small_dut.narrow_owner_row_q,
                u_small_dut.narrow_owner_element_q
            };
            child_fault_flags_snapshot = small_flags_o;
            child_fault_progress_snapshot = {
                small_rows_reduced_o, small_elements_processed_o
            };
            child_fault_request_credit_snapshot =
                  small_gmem_read_requests_o
                + small_gmem_write_requests_o
                + small_widen_requests_o
                + small_add_requests_o
                + small_narrow_requests_o;
            child_fault_response_credit_snapshot =
                  small_gmem_read_responses_o
                + small_gmem_write_responses_o
                + small_widen_responses_o
                + small_add_responses_o
                + small_narrow_responses_o;
            child_fault_gmem_accept_snapshot = small_accept_count;
            child_fault_gmem_owner_snapshot =
                u_small_dut.gmem_owner_valid_q;
            child_fault_child_owner_snapshot = {
                u_small_dut.widen_owner_valid_q,
                u_small_dut.add_owner_valid_q,
                u_small_dut.narrow_owner_valid_q
            };
        end
    endtask

    task automatic check_child_fault_post_edge(
        input string label,
        input logic [4:0] expected_error_code,
        input integer expected_total_request_event_delta,
        input integer expected_response_delta,
        input integer expected_gmem_accept_delta,
        input logic expected_gmem_owner,
        input logic [2:0] expected_child_owner
    );
        begin
            // Called one time unit after the sampling posedge.  All parent
            // nonblocking assignments are therefore observable while the
            // production fault source is still forced.
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || (u_small_dut.error_code_q != expected_error_code))
                fail_case($sformatf("%s post-NBA quarantine/code", label));
            if (!small_busy_o || small_ready_o || small_done_o || small_error_o)
                fail_case($sformatf("%s post-NBA visibility", label));
            if (small_req_valid_o || small_rsp_ready_o
                    || u_small_dut.widen_req_valid_w
                    || u_small_dut.add_req_valid_w
                    || u_small_dut.narrow_req_valid_w
                    || u_small_dut.widen_rsp_ready_w
                    || u_small_dut.add_rsp_ready_w
                    || u_small_dut.narrow_rsp_ready_w
                    || u_small_dut.gmem_req_fire_w
                    || u_small_dut.gmem_rsp_fire_w
                    || u_small_dut.widen_req_fire_w
                    || u_small_dut.widen_rsp_fire_w
                    || u_small_dut.add_req_fire_w
                    || u_small_dut.add_rsp_fire_w
                    || u_small_dut.narrow_req_fire_w
                    || u_small_dut.narrow_rsp_fire_w)
                fail_case($sformatf("%s post-NBA credit revoke", label));
            if (u_small_dut.gmem_owner_valid_q
                    != expected_gmem_owner)
                fail_case($sformatf("%s post-NBA GMEM owner ledger", label));
            if ({u_small_dut.widen_owner_valid_q,
                 u_small_dut.add_owner_valid_q,
                 u_small_dut.narrow_owner_valid_q}
                    != expected_child_owner)
                fail_case($sformatf("%s post-NBA child owner ledger", label));
            if (expected_gmem_owner && !child_fault_gmem_owner_snapshot
                    && (!u_small_dut.gmem_owner_valid_q
                        || u_small_dut.gmem_owner_write_q
                        || (u_small_dut.gmem_owner_generation_q
                            != u_small_dut.generation_q)
                        || (u_small_dut.gmem_owner_row_q
                            != u_small_dut.row_index_q)
                        || (u_small_dut.gmem_owner_index_q
                            != u_small_dut.read_beat_q)))
                fail_case($sformatf("%s post-NBA GMEM owner identity", label));
            if ((u_small_dut.generation_q
                        != child_fault_generation_snapshot)
                    || ({u_small_dut.row_index_q,
                         u_small_dut.read_beat_q,
                         u_small_dut.element_index_q,
                         u_small_dut.publish_index_q}
                        != child_fault_coordinate_snapshot)
                    || ((expected_child_owner
                            == child_fault_child_owner_snapshot)
                        && ({u_small_dut.widen_owner_generation_q,
                             u_small_dut.widen_owner_row_q,
                             u_small_dut.widen_owner_element_q,
                             u_small_dut.add_owner_generation_q,
                             u_small_dut.add_owner_row_q,
                             u_small_dut.add_owner_element_q,
                             u_small_dut.narrow_owner_generation_q,
                             u_small_dut.narrow_owner_row_q,
                             u_small_dut.narrow_owner_element_q}
                            != child_fault_owner_tag_snapshot))
                    || (small_flags_o != child_fault_flags_snapshot)
                    || ({small_rows_reduced_o, small_elements_processed_o}
                        != child_fault_progress_snapshot)
                    || ((small_gmem_read_requests_o
                         + small_gmem_write_requests_o
                         + small_widen_requests_o
                        + small_add_requests_o
                        + small_narrow_requests_o)
                        != (child_fault_request_credit_snapshot
                            + 64'(expected_total_request_event_delta)))
                    || ((small_gmem_read_responses_o
                         + small_gmem_write_responses_o
                         + small_widen_responses_o
                        + small_add_responses_o
                        + small_narrow_responses_o)
                        != (child_fault_response_credit_snapshot
                            + 64'(expected_response_delta)))
                    || (small_accept_count
                        != (child_fault_gmem_accept_snapshot
                            + expected_gmem_accept_delta)))
                fail_case($sformatf("%s post-NBA snapshot", label));
            if (expected_child_owner[2]
                    && !child_fault_child_owner_snapshot[2]
                    && ((u_small_dut.widen_owner_generation_q
                            != u_small_dut.generation_q)
                        || (u_small_dut.widen_owner_row_q
                            != u_small_dut.row_index_q)
                        || (u_small_dut.widen_owner_element_q
                            != u_small_dut.element_index_q)))
                fail_case($sformatf("%s post-NBA widen owner identity", label));
            if (expected_child_owner[1]
                    && !child_fault_child_owner_snapshot[1]
                    && ((u_small_dut.add_owner_generation_q
                            != u_small_dut.generation_q)
                        || (u_small_dut.add_owner_row_q
                            != u_small_dut.row_index_q)
                        || (u_small_dut.add_owner_element_q
                            != u_small_dut.element_index_q)))
                fail_case($sformatf("%s post-NBA add owner identity", label));
            if (!small_fault_valid_o
                    || !small_expected_fault_valid_q
                    || (small_first_fault_cycle_o
                        != small_expected_fault_cycle_q)
                    || (small_first_fault_coordinate_o
                        != small_expected_fault_coordinate_q)
                    || (small_first_fault_gmem_addr_o
                        != small_expected_fault_gmem_addr_q)
                    || (small_first_fault_flags_o
                        != small_expected_fault_flags_q)
                    || (small_first_fault_request_events_o
                        != small_expected_fault_request_events_q)
                    || (small_first_fault_response_events_o
                        != small_expected_fault_response_events_q)
                    || (small_first_fault_txn_tag_o
                        != small_expected_fault_txn_tag_q)
                    || (small_first_fault_generation_o
                        != small_expected_fault_generation_q)
                    || (small_first_fault_resource_o
                        != small_expected_fault_resource_q)
                    || (small_first_fault_owner_type_o
                        != small_expected_fault_owner_type_q)
                    || (small_first_fault_owner_valid_o
                        != small_expected_fault_owner_valid_q)
                    || (small_first_fault_owner_generation_o
                        != small_expected_fault_owner_generation_q)
                    || (small_first_fault_owner_row_o
                        != small_expected_fault_owner_row_q)
                    || (small_first_fault_owner_index_o
                        != small_expected_fault_owner_index_q))
                fail_case($sformatf("%s post-fire first-fault ledger", label));
            small_fault_expect_arm_q = 1'b0;
            child_fault_edge_witness_count =
                child_fault_edge_witness_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FAULT-EDGE] label=%s predicate=1 quarantine=1 total_request_delta=%0d gmem_accept_delta=%0d response_delta=%0d snapshot=1",
                     label, expected_total_request_event_delta,
                     expected_gmem_accept_delta, expected_response_delta);
        end
    endtask

    task automatic run_child_ghost;
        begin
            set_small_descriptor();
            small_src_region_base_i = 64'h0000_0000_0000_0200;
            // fixed-7 deliberately overlaps the ghost with a real GMEM request
            // fire.  The request must be accepted and acquire an owner even
            // though semantic read progress is suppressed by the fault.
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b1;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_REQ, "widen ghost setup");
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w
                    || u_small_dut.widen_rsp_ready_w
                    || !u_small_dut.gmem_req_fire_w)
                fail_case("widen ghost did not reach production predicate");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN,
                OWNER_GMEM_READ, 1'b1, small_tb_generation_q,
                32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'd1, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "widen-ghost+gmem-fire", ERR_CHILD_RESPONSE,
                1, 0, 1, 1'b1, 3'b000);
            if (small_first_fault_gmem_addr_o
                    != (small_src_region_base_i + small_src_view_off_i))
                fail_case("cross-fire first-fault GMEM address");
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=CROSS-FIRE resource=WIDEN owner=GMEM_READ addr=%016x req_delta=1",
                     small_first_fault_gmem_addr_o);
            release u_small_dut.widen_rsp_valid_w;
            small_hold_responses_q = 1'b0;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            finish_child_fault("widen ghost");
        end
    endtask

    task automatic run_widen_wrong_owner;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_WIDEN_WAIT, "widen wrong-owner setup");
            force u_small_dut.widen_owner_element_q = 32'hffff_ffff;
            #1;
            if (!u_small_dut.widen_owner_fault_w
                    || u_small_dut.widen_rsp_ready_w)
                fail_case("widen wrong-owner predicate/credit");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN, OWNER_WIDEN,
                1'b1, small_tb_generation_q, 32'b0, 32'hffff_ffff,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "widen-wrong-owner", ERR_CHILD_RESPONSE,
                0, 0, 0, 1'b0, child_fault_child_owner_snapshot);
            release u_small_dut.widen_owner_element_q;
            finish_child_fault("widen wrong owner");
        end
    endtask

    task automatic run_add_wrong_owner;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_ADD_WAIT, "add wrong-owner setup");
            force u_small_dut.add_owner_generation_q =
                ~u_small_dut.generation_q;
            #1;
            if (!u_small_dut.add_owner_fault_w || u_small_dut.add_rsp_ready_w)
                fail_case("add wrong-owner predicate/credit");
            arm_fault_oracle(FAULT_RESOURCE_ADD, OWNER_ADD,
                1'b1, ~small_tb_generation_q, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "add-wrong-owner", ERR_CHILD_RESPONSE,
                0, 0, 0, 1'b0, child_fault_child_owner_snapshot);
            release u_small_dut.add_owner_generation_q;
            finish_child_fault("add wrong owner");
        end
    endtask

    task automatic run_narrow_wrong_owner;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_NARROW_WAIT, "narrow wrong-owner setup");
            force u_small_dut.narrow_owner_row_q = 32'hffff_ffff;
            #1;
            if (!u_small_dut.narrow_owner_fault_w
                    || u_small_dut.narrow_rsp_ready_w)
                fail_case("narrow wrong-owner predicate/credit");
            arm_fault_oracle(FAULT_RESOURCE_NARROW, OWNER_NARROW,
                1'b1, small_tb_generation_q, 32'hffff_ffff, 32'd4,
                32'b0, 32'b0, 32'd3, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "narrow-wrong-owner", ERR_CHILD_RESPONSE,
                0, 0, 0, 1'b0, child_fault_child_owner_snapshot);
            release u_small_dut.narrow_owner_row_q;
            finish_child_fault("narrow wrong owner");
        end
    endtask

    task automatic run_child_fault_with_existing_gmem_owner;
        begin
            set_small_descriptor();
            small_src_region_base_i = 64'h0000_0000_0000_0200;
            small_hold_responses_q = 1'b1;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_WAIT,
                             "child fault existing GMEM owner setup");
            if (!u_small_dut.gmem_owner_valid_q)
                fail_case("existing GMEM owner setup lost owner");
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w
                    || u_small_dut.gmem_rsp_fire_w)
                fail_case("child fault existing GMEM owner predicate");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN,
                OWNER_GMEM_READ, 1'b1, small_tb_generation_q,
                32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "child-fault+existing-gmem-owner", ERR_CHILD_RESPONSE,
                0, 0, 0, 1'b1, child_fault_child_owner_snapshot);
            if (small_first_fault_gmem_addr_o
                    != (small_src_region_base_i + small_src_view_off_i))
                fail_case("owned first-fault GMEM address");
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=OWNED resource=WIDEN owner=GMEM_READ addr=%016x req_delta=0",
                     small_first_fault_gmem_addr_o);
            release u_small_dut.widen_rsp_valid_w;
            small_hold_responses_q = 1'b0;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            finish_child_fault("child fault existing GMEM owner");
        end
    endtask

    task automatic run_gmem_ghost_with_child_request;
        integer model_response_before;
        logic   model_pending_before;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_WIDEN_REQ,
                             "GMEM ghost child request setup");
            if (small_rsp_valid_model_q || small_rsp_valid_ghost_q
                    || small_rsp_valid_i || small_pending_q)
                fail_case("GMEM ghost driver setup was not idle");
            model_response_before = small_response_count;
            model_pending_before  = small_pending_q;
            small_rsp_valid_ghost_q = 1'b1;
            #1;
            if (!small_rsp_valid_ghost_q || !small_rsp_valid_i
                    || small_rsp_valid_model_q
                    || !u_small_dut.gmem_owner_fault_w
                    || u_small_dut.gmem_rsp_ready_o
                    || !u_small_dut.widen_req_fire_w)
                fail_case("GMEM ghost child request predicate/fire");
            arm_fault_oracle(FAULT_RESOURCE_GMEM, OWNER_WIDEN,
                1'b1, small_tb_generation_q, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'd1, 64'b0, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "gmem-ghost+widen-request", ERR_PROTOCOL_OWNER,
                1, 0, 0, 1'b0, 3'b100);
            if (small_first_fault_gmem_addr_o != 64'b0)
                fail_case("ownerless ghost first-fault GMEM address");
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=OWNERLESS resource=GMEM owner=WIDEN addr=%016x req_delta=1",
                     small_first_fault_gmem_addr_o);
            small_rsp_valid_ghost_q = 1'b0;
            #1;
            if (small_rsp_valid_ghost_q || small_rsp_valid_i
                    || small_rsp_valid_model_q
                    || (small_pending_q != model_pending_before)
                    || (small_response_count != model_response_before))
                fail_case("GMEM ghost overlay did not return cleanly to zero");
            gmem_fault_fixture_count = gmem_fault_fixture_count + 1;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            finish_protocol_fault("GMEM ghost child request");
            if ((small_pending_q != model_pending_before)
                    || (small_response_count != model_response_before))
                fail_case("GMEM ghost changed model pending/response count");
            run_small_positive("clean retry after GMEM ghost child request");
            $display("[NPU-ORDERED-SUM-ROWS][GMEM-GHOST-DRIVER] pre=1 post=0 model=0 predicate=1 ready=0 child_req_fire=1 response_delta=0 retry_clean=1");
        end
    endtask

    task automatic run_matching_child_response_with_other_ghost;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_ADD_WAIT,
                             "matching add response overlap setup");
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w
                    || !u_small_dut.add_rsp_fire_w)
                fail_case("matching child response overlap predicate/fire");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN, OWNER_ADD,
                1'b0, small_tb_generation_q, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'd1, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "add-response+widen-ghost", ERR_CHILD_RESPONSE,
                0, 1, 0, 1'b0, 3'b000);
            if (small_elements_processed_o
                    != child_fault_progress_snapshot[63:0])
                fail_case("fault edge committed matching ADD semantics");
            release u_small_dut.widen_rsp_valid_w;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            finish_child_fault("matching child response overlap");
        end
    endtask

    task automatic run_final_shadow_ack_with_child_ghost;
        integer cycles;
        integer model_response_before;
        integer done_before;
        logic [63:0] write_response_before;
        logic [63:0] expected_gmem_address;
        begin
            set_small_descriptor();
            pulse_small_start();
            expected_gmem_address = (small_dst_region_base_i
                                     + small_dst_view_off_i + 64'd4)
                                    & 64'hffff_ffff_ffff_fff8;
            cycles = 0;
            while (!((u_small_dut.state_q == ST_PUBLISH_WAIT)
                    && (u_small_dut.publish_index_q == 32'd1)
                    && u_small_dut.gmem_owner_valid_q
                    && u_small_dut.gmem_owner_write_q
                    && small_pending_q)
                    && (cycles < 2048)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((u_small_dut.state_q != ST_PUBLISH_WAIT)
                    || (u_small_dut.publish_index_q != 32'd1)
                    || !u_small_dut.gmem_owner_valid_q
                    || !u_small_dut.gmem_owner_write_q
                    || !small_pending_q
                    || (u_small_dut.gmem_req_addr_q
                        != expected_gmem_address)
                    || (u_small_dut.gmem_owner_generation_q
                        != u_small_dut.generation_q)
                    || (u_small_dut.gmem_owner_row_q != 32'd1)
                    || (u_small_dut.gmem_owner_index_q != 32'd1))
                fail_case("final shadow ack overlap setup");
            // WAIT/owner/pending become visible one cycle before the normal
            // model produces response valid.  Wait for the real matching
            // response fire rather than assuming it at the first WAIT edge.
            cycles = 0;
            while (!(small_rsp_valid_model_q
                    && u_small_dut.gmem_rsp_fire_w)
                    && (cycles < 32)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((u_small_dut.state_q != ST_PUBLISH_WAIT)
                    || (u_small_dut.publish_index_q != 32'd1)
                    || !u_small_dut.gmem_owner_valid_q
                    || !u_small_dut.gmem_owner_write_q
                    || !small_pending_q
                    || !small_rsp_valid_model_q
                    || !small_rsp_valid_i
                    || !u_small_dut.gmem_rsp_fire_w
                    || (u_small_dut.gmem_req_addr_q
                        != expected_gmem_address))
                fail_case("final shadow ack matching response wait");
            model_response_before = small_response_count;
            write_response_before = small_gmem_write_responses_o;
            done_before = small_done_count;
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w
                    || !u_small_dut.gmem_rsp_fire_w)
                fail_case("final shadow ack overlap predicate/fire");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN,
                OWNER_GMEM_WRITE, 1'b0, small_tb_generation_q,
                32'd1, 32'd1, 32'd1, 32'b0, 32'd3, 32'd1,
                expected_gmem_address, 64'b0, 64'd1, 5'b0);
            capture_child_fault_snapshot();
            @(posedge clk_i);
            #1;
            check_child_fault_post_edge(
                "final-shadow-ack+widen-ghost", ERR_CHILD_RESPONSE,
                0, 1, 0, 1'b0, 3'b000);
            if (small_done_o || (u_small_dut.state_q == ST_DONE)
                    || (small_done_count != done_before)
                    || (small_response_count
                        != (model_response_before + 1))
                    || (small_gmem_write_responses_o
                        != (write_response_before + 64'd1))
                    || small_pending_q || small_rsp_valid_model_q
                    || u_small_dut.gmem_owner_valid_q)
                fail_case("final fault edge gained commit eligibility");
            release u_small_dut.widen_rsp_valid_w;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            finish_child_fault("final shadow ack overlap");
            if (small_done_count != done_before)
                fail_case("final shadow ack fault gained terminal commit");
            run_small_positive("clean retry after final shadow ack fault");
            $display("[NPU-ORDERED-SUM-ROWS][FINAL-SHADOW-ACK-EVENT] wait_seen=1 pending_seen=1 model_valid=1 owner_match=1 ack_fire=1 child_fault=1 post_quarantine=1 commit_delta=0 response_delta=1 retry_clean=1");
        end
    endtask

    task automatic run_idle_start_with_child_ghost;
        logic resident_generation;
        integer done_before;
        integer error_before;
        integer cycles;
        begin
            set_small_descriptor();
            wait_small_ready();
            resident_generation = u_small_dut.generation_q;
            done_before = small_done_count;
            error_before = small_error_count;
            small_start_i = 1'b1;
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w || small_ready_o
                    || u_small_dut.start_fire_w)
                fail_case("IDLE ghost did not revoke command credit");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || (u_small_dut.generation_q != resident_generation)
                    || u_small_dut.fault_latched_q
                    || !u_small_dut.cleanup_suppress_terminal_q)
                fail_case("IDLE ghost sampled descriptor or missed cleanup");
            release u_small_dut.widen_rsp_valid_w;
            small_start_i = 1'b0;
            cycles = 0;
            while (!small_ready_o && (cycles < 32)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_ready_o || small_done_o || small_error_o
                    || small_fault_valid_o
                    || (small_done_count != done_before)
                    || (small_error_count != error_before))
                fail_case("IDLE ghost fabricated transaction completion");
            child_fault_edge_witness_count =
                child_fault_edge_witness_count + 1;
            overlap_fault_fixture_count = overlap_fault_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FAULT-EDGE] label=idle-start+widen-ghost predicate=1 quarantine=1 total_request_delta=0 gmem_accept_delta=0 response_delta=0 snapshot=0 suppressed=1");
            $display("[NPU-ORDERED-SUM-ROWS][RETIRED-CLEANUP] source=idle-child completion_delta=0 diagnostic=zero ready=1");
        end
    endtask

    task automatic run_terminal_ghost_cleanup;
        integer cycles;
        integer done_before;
        integer error_before;
        begin
            set_small_descriptor();
            done_before = small_done_count;
            error_before = small_error_count;
            pulse_small_start();
            wait_small_terminal(1'b0, 5'b0, "terminal ghost setup");
            if (u_small_dut.state_q != ST_DONE)
                fail_case("terminal ghost setup did not hold DONE pulse");
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!small_done_o || small_error_o || small_ready_o
                    || !u_small_dut.widen_owner_fault_w)
                fail_case("terminal ghost withdrew visible completion");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || small_done_o || small_error_o
                    || !u_small_dut.cleanup_suppress_terminal_q)
                fail_case("terminal ghost post-NBA quarantine");
            release u_small_dut.widen_rsp_valid_w;
            cycles = 0;
            while (!small_ready_o && (cycles < 32)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_ready_o || small_done_o || small_error_o
                    || (small_done_count != (done_before + 1))
                    || (small_error_count != error_before))
                fail_case("terminal ghost completion was repeated/revoked");
            terminal_cleanup_fixture_count =
                terminal_cleanup_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][TERMINAL-CLEANUP] held=1 quarantine=1 repeated=0");
        end
    endtask

    task automatic run_child_timeout;
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(ST_WIDEN_WAIT, "child timeout setup");
            force u_small_dut.widen_rsp_valid_w = 1'b0;
            while (u_small_dut.stall_cycles_q
                    < SMALL_STALL_TIMEOUT_LAST)
                @(negedge clk_i);
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_WIDEN,
                1'b1, small_tb_generation_q, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            wait_small_state(ST_CHILD_QUARANTINE, "child timeout");
            release u_small_dut.widen_rsp_valid_w;
            @(posedge clk_i);
            @(negedge clk_i);
            if (!small_error_o || (small_error_code_o != ERR_STALL_TIMEOUT)
                    || small_done_o || small_poisoned_o)
                fail_case("child timeout terminal");
            disarm_fault_oracle();
            child_fault_fixture_count = child_fault_fixture_count + 1;
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case("child timeout terminal delta");
        end
    endtask

    task automatic run_persistent_ledger_corruption;
        integer done_before;
        integer error_before;
        begin
            done_before = small_done_count;
            error_before = small_error_count;
            set_small_descriptor();
            small_hold_responses_q = 1'b1;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_WAIT,
                             "persistent ledger corruption setup");
            if (!u_small_dut.gmem_owner_valid_q
                    || (small_gmem_read_requests_o != 64'd1)
                    || (small_gmem_read_responses_o != 64'd0))
                fail_case("persistent ledger corruption owner setup");
            force u_small_dut.gmem_read_responses_q = 64'd2;
            #1;
            if (!u_small_dut.ledger_corrupt_w
                    || !u_small_dut.internal_fault_w)
                fail_case("persistent ledger corruption predicate");
            arm_fault_oracle(FAULT_RESOURCE_CONTROL,
                OWNER_GMEM_READ, 1'b1, small_tb_generation_q,
                32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
                small_src_region_base_i + small_src_view_off_i,
                64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || !u_small_dut.fault_latched_q
                    || (u_small_dut.error_code_q != ERR_INTERNAL_STATE)
                    || !u_small_dut.ledger_corrupt_w)
                fail_case("persistent ledger fault did not enter quarantine");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_GMEM_DRAIN)
                    || !u_small_dut.gmem_owner_valid_q
                    || !u_small_dut.ledger_corrupt_w)
                fail_case("persistent ledger level preempted cleanup");
            release u_small_dut.gmem_read_responses_q;
            small_hold_responses_q = 1'b0;
            wait_small_terminal(1'b1, ERR_INTERNAL_STATE,
                                "persistent ledger bounded cleanup");
            persistent_ledger_killer_count =
                persistent_ledger_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][PERSISTENT-LEDGER-CORRUPT] predicate=1 quarantine=1 drain=1 terminal=1 livelock=0");
            @(negedge clk_i);
            if ((small_done_count != done_before)
                    || (small_error_count != (error_before + 1)))
                fail_case("persistent ledger terminal delta");
            run_small_positive("clean retry after persistent ledger fault");
        end
    endtask

    task automatic run_held_child_request_fault(
        input logic [4:0] request_state,
        input string label
    );
        logic [63:0] request_events_before;
        logic [2:0] expected_owner_bits;
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(request_state, label);
            case (request_state)
                ST_WIDEN_REQ:
                    force u_small_dut.widen_req_ready_w = 1'b0;
                ST_ADD_REQ:
                    force u_small_dut.add_req_ready_w = 1'b0;
                ST_NARROW_REQ:
                    force u_small_dut.narrow_req_ready_w = 1'b0;
                default: fail_case("held child request unknown state");
            endcase
            repeat (2) begin
                @(posedge clk_i);
                #1;
                if ((u_small_dut.state_q != request_state)
                        || ((request_state == ST_WIDEN_REQ)
                            && !u_small_dut.widen_req_valid_w)
                        || ((request_state == ST_ADD_REQ)
                            && !u_small_dut.add_req_valid_w)
                        || ((request_state == ST_NARROW_REQ)
                            && !u_small_dut.narrow_req_valid_w))
                    fail_case($sformatf("%s did not hold valid", label));
                @(negedge clk_i);
            end
            request_events_before = small_widen_requests_o
                                  + small_add_requests_o
                                  + small_narrow_requests_o;
            small_rsp_valid_ghost_q = 1'b1;
            #1;
            if (!u_small_dut.gmem_owner_fault_w
                    || u_small_dut.gmem_rsp_ready_o)
                fail_case($sformatf("%s GMEM ghost predicate", label));
            arm_fault_oracle(FAULT_RESOURCE_GMEM, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'b0, 32'b0,
                (request_state == ST_NARROW_REQ) ? 32'd3 : 32'b0,
                32'b0, 64'b0, 64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if (!u_small_dut.abort_hold_q
                    || (u_small_dut.state_q != request_state)
                    || !u_small_dut.fault_latched_q)
                fail_case($sformatf("%s fault withdrew held request", label));
            @(negedge clk_i);
            small_rsp_valid_ghost_q = 1'b0;
            case (request_state)
                ST_WIDEN_REQ:
                    release u_small_dut.widen_req_ready_w;
                ST_ADD_REQ:
                    release u_small_dut.add_req_ready_w;
                ST_NARROW_REQ:
                    release u_small_dut.narrow_req_ready_w;
                default: begin end
            endcase
            @(posedge clk_i);
            #1;
            expected_owner_bits = (request_state == ST_WIDEN_REQ) ? 3'b100
                                : (request_state == ST_ADD_REQ) ? 3'b010
                                : 3'b001;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || u_small_dut.abort_hold_q
                    || ({u_small_dut.widen_owner_valid_q,
                         u_small_dut.add_owner_valid_q,
                         u_small_dut.narrow_owner_valid_q}
                        != expected_owner_bits)
                    || ((small_widen_requests_o + small_add_requests_o
                         + small_narrow_requests_o)
                        != (request_events_before + 64'd1)))
                fail_case($sformatf("%s fire/owner/count", label));
            disarm_fault_oracle();
            held_child_killer_count = held_child_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][HELD-CHILD-REQ-FAULT] phase=%s held_cycles=2 stable=1 fire=1 owner=1 count=1", label);
            finish_protocol_fault(label);
            run_small_positive($sformatf("clean retry after %s", label));
        end
    endtask

    task automatic run_held_publish_request_fault;
        logic [136:0] held_payload;
        logic [63:0] write_requests_before;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b0;
            pulse_small_start();
            wait_small_state(ST_PUBLISH_PREP,
                             "held publish request prep");
            small_allow_requests_q = 1'b0;
            small_hold_responses_q = 1'b1;
            wait_small_state(ST_PUBLISH_REQ,
                             "held publish request setup");
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            if (!small_req_valid_o || small_req_ready_i
                    || !small_req_write_o)
                fail_case("held publish request did not remain exposed");
            held_payload = {small_req_write_o, small_req_addr_o,
                            small_req_wdata_o, small_req_wstrb_o};
            write_requests_before = small_gmem_write_requests_o;
            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w)
                fail_case("held publish child ghost predicate");
            arm_fault_oracle(FAULT_RESOURCE_WIDEN, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'd1, 32'b0, 32'd3, 32'b0,
                (small_dst_region_base_i + small_dst_view_off_i)
                    & 64'hffff_ffff_ffff_fff8,
                64'b0, 64'b0, 5'b0);
            @(posedge clk_i);
            #1;
            if (!u_small_dut.abort_hold_q
                    || (u_small_dut.state_q != ST_PUBLISH_REQ)
                    || !small_req_valid_o
                    || ({small_req_write_o, small_req_addr_o,
                         small_req_wdata_o, small_req_wstrb_o} != held_payload))
                fail_case("held publish fault withdrew request");
            @(negedge clk_i);
            release u_small_dut.widen_rsp_valid_w;
            small_allow_requests_q = 1'b1;
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || !u_small_dut.gmem_owner_valid_q
                    || !u_small_dut.gmem_owner_write_q
                    || (small_gmem_write_requests_o
                        != (write_requests_before + 64'd1)))
                fail_case("held publish fire/owner/count");
            if (small_first_fault_gmem_addr_o
                    != ((small_dst_region_base_i + small_dst_view_off_i)
                        & 64'hffff_ffff_ffff_fff8))
                fail_case("held first-fault GMEM address");
            first_fault_address_killer_count =
                first_fault_address_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=HELD resource=WIDEN owner=NONE addr=%016x req_delta=0",
                     small_first_fault_gmem_addr_o);
            disarm_fault_oracle();
            small_hold_responses_q = 1'b0;
            held_gmem_killer_count = held_gmem_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][HELD-GMEM-REQ-FAULT] phase=publish held=1 stable=1 fire=1 owner=1 count=1 drain=1");
            finish_child_fault("held publish child fault");
            run_small_positive("clean retry after held publish fault");
        end
    endtask

    task automatic run_post_error_late_ghost_cleanup;
        integer done_before;
        integer error_before;
        integer capture_before;
        integer response_before;
        integer cycles;
        integer done_delta;
        integer error_delta;
        integer capture_delta;
        integer model_response_delta;
        logic witness_state_idle;
        logic witness_ready;
        logic witness_done;
        logic witness_error;
        logic witness_overlay_low;
        logic witness_owner_fault;
        logic witness_next_idle;
        logic witness_no_reentry;
        logic fire_edge_state_stray;
        logic fire_edge_stray_fire;
        logic fire_edge_ghost_overlay;
        logic fire_edge_model_low;
        logic post_nba_model_low;
        begin
            set_small_descriptor();
            small_dtype_i = 8'h02;
            pulse_small_start();
            arm_fault_oracle(FAULT_RESOURCE_CONTROL, OWNER_NONE,
                1'b0, 1'b0, 32'b0, 32'b0,
                32'b0, 32'b0, 32'b0, 32'b0,
                64'b0, 64'b0, 64'b0, 5'b0);
            wait_small_terminal(1'b1, ERR_HEADER,
                                "late ghost predecessor error");
            @(negedge clk_i);
            if (!small_ready_o || !small_fault_valid_o)
                fail_case("late ghost predecessor did not retire to IDLE");
            done_before = small_done_count;
            error_before = small_error_count;
            capture_before = fault_output_capture_count;
            response_before = small_response_count;

            force u_small_dut.widen_rsp_valid_w = 1'b1;
            #1;
            if (!u_small_dut.widen_owner_fault_w || small_ready_o)
                fail_case("post-error child late ghost predicate");
            @(posedge clk_i);
            #1;
            if ((u_small_dut.state_q != ST_CHILD_QUARANTINE)
                    || !u_small_dut.cleanup_suppress_terminal_q)
                fail_case("post-error child late ghost cleanup entry");
            release u_small_dut.widen_rsp_valid_w;
            cycles = 0;
            while (!small_ready_o && (cycles < 32)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!small_ready_o || small_done_o || small_error_o)
                fail_case("post-error child late ghost fabricated terminal");

            small_rsp_valid_ghost_q = 1'b1;
            #1;
            if (!u_small_dut.gmem_owner_fault_w || small_ready_o)
                fail_case("post-error GMEM late ghost predicate");
            @(posedge clk_i);
            cycles = 0;
            while (!((u_small_dut.state_q == ST_STRAY_GMEM_DROP)
                    && u_small_dut.gmem_rsp_fire_w)
                    && (cycles < 16)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((u_small_dut.state_q != ST_STRAY_GMEM_DROP)
                    || !u_small_dut.gmem_rsp_fire_w)
                fail_case("post-error GMEM late ghost was not dropped");
            @(posedge clk_i);

            // Snapshot the sampling edge in the active region, before either
            // production or model NBAs can update.  This isolates the ghost
            // overlay from the normal single-writer GMEM response model.
            fire_edge_state_stray =
                (u_small_dut.state_q == ST_STRAY_GMEM_DROP);
            fire_edge_stray_fire = u_small_dut.gmem_stray_rsp_fire_w;
            fire_edge_ghost_overlay = small_rsp_valid_ghost_q;
            fire_edge_model_low = !small_rsp_valid_model_q;
            if (!fire_edge_state_stray)
                fail_case("post-error late ghost fire-edge state");
            if (!fire_edge_stray_fire)
                fail_case("post-error late ghost fire-edge stray fire");
            if (!fire_edge_ghost_overlay)
                fail_case("post-error late ghost fire-edge overlay");
            if (!fire_edge_model_low)
                fail_case("post-error late ghost fire-edge model isolation");

            // One nanosecond is strictly below the five-nanosecond half-cycle
            // and cannot coincide with the next clock edge.
            #1;
            post_nba_model_low = !small_rsp_valid_model_q;

            // The real stray-response fire has now crossed the production
            // sampling edge, but the overlay deliberately remains asserted.
            // Check registered state and every transaction credit separately
            // before changing the combinational response source.
            if (u_small_dut.state_q != ST_IDLE)
                fail_case("post-error late ghost post-NBA state");
            if (!small_rsp_valid_ghost_q)
                fail_case("post-error late ghost overlay withdrew at fire");
            if (!post_nba_model_low)
                fail_case("post-error late ghost post-NBA model isolation");
            if (!u_small_dut.gmem_owner_fault_w)
                fail_case("post-error late ghost post-NBA owner predicate");
            if (small_done_o)
                fail_case("post-error late ghost post-NBA done pulse");
            if (small_error_o)
                fail_case("post-error late ghost post-NBA error pulse");
            if (small_done_count != done_before)
                fail_case("post-error late ghost post-NBA done credit");
            if (small_error_count != error_before)
                fail_case("post-error late ghost post-NBA error credit");
            if (fault_output_capture_count != capture_before)
                fail_case("post-error late ghost post-NBA capture credit");
            if (small_response_count != response_before)
                fail_case("post-error late ghost post-NBA model response credit");

            // Clearing the overlay changes a continuous path through
            // gmem_owner_fault_w to ready_o.  Yield one bounded sub-cycle
            // settle interval before observing that path; this is not a
            // registered cleanup delay and cannot hide a next-edge re-entry.
            small_rsp_valid_ghost_q = 1'b0;
            #1;
            witness_state_idle = (u_small_dut.state_q == ST_IDLE);
            witness_ready = small_ready_o;
            witness_done = small_done_o;
            witness_error = small_error_o;
            witness_overlay_low = !small_rsp_valid_ghost_q
                                && !small_rsp_valid_model_q
                                && !small_rsp_valid_i;
            witness_owner_fault = u_small_dut.gmem_owner_fault_w;
            done_delta = small_done_count - done_before;
            error_delta = small_error_count - error_before;
            capture_delta = fault_output_capture_count - capture_before;
            model_response_delta = small_response_count - response_before;

            if (!witness_state_idle)
                fail_case("post-error late ghost settled state");
            if (!witness_overlay_low)
                fail_case("post-error late ghost settled overlay/model input");
            if (witness_owner_fault)
                fail_case("post-error late ghost settled owner predicate");
            if (!witness_ready)
                fail_case("post-error late ghost settled ready credit");
            if (witness_done)
                fail_case("post-error late ghost settled done pulse");
            if (witness_error)
                fail_case("post-error late ghost settled error pulse");
            if (done_delta != 0)
                fail_case("post-error late ghost settled done count");
            if (error_delta != 0)
                fail_case("post-error late ghost settled error count");
            if (capture_delta != 0)
                fail_case("post-error late ghost settled capture count");
            if (model_response_delta != 0)
                fail_case("post-error late ghost settled model response count");

            // Cross exactly one further sampling edge with the overlay low.
            // A persistent/re-entered cleanup would be visible here rather
            // than being hidden behind an arbitrary multi-cycle delay.
            @(posedge clk_i);
            #1;
            witness_next_idle = (u_small_dut.state_q == ST_IDLE);
            witness_no_reentry = (u_small_dut.state_q
                                  != ST_CHILD_QUARANTINE)
                               && !u_small_dut.cleanup_suppress_terminal_q;
            if (!witness_next_idle)
                fail_case("post-error late ghost next-edge state");
            if (!witness_no_reentry)
                fail_case("post-error late ghost cleanup re-entry");
            if (!small_ready_o || u_small_dut.gmem_owner_fault_w)
                fail_case("post-error late ghost next-edge ready/owner");
            if (small_done_o || small_error_o)
                fail_case("post-error late ghost next-edge terminal");
            if (small_done_count != done_before)
                fail_case("post-error late ghost next-edge done credit");
            if (small_error_count != error_before)
                fail_case("post-error late ghost next-edge error credit");
            if (fault_output_capture_count != capture_before)
                fail_case("post-error late ghost next-edge capture credit");
            if (small_response_count != response_before)
                fail_case("post-error late ghost next-edge model response credit");

            run_small_positive("clean retry after post-error late ghosts");
            retired_late_ghost_killer_count =
                retired_late_ghost_killer_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][POST-ERROR-LATE-GHOST] fire_state=%0d stray_fire=%0d ghost=%0d model_pre_low=%0d model_post_low=%0d settle_ns=1 post_nba_idle=1 overlay_low=%0d owner_fault=%0d state=%0d ready=%0d done=%0d error=%0d done_delta=%0d error_delta=%0d capture_delta=%0d model_response_delta=%0d next_idle=%0d no_reentry=%0d retry=1",
                fire_edge_state_stray, fire_edge_stray_fire,
                fire_edge_ghost_overlay, fire_edge_model_low,
                post_nba_model_low, witness_overlay_low, witness_owner_fault,
                witness_state_idle, witness_ready, witness_done,
                witness_error, done_delta, error_delta, capture_delta,
                model_response_delta, witness_next_idle,
                witness_no_reentry);
        end
    endtask

    task automatic deadline_fire_once(
        input logic [4:0] wanted_state,
        input logic expect_request,
        input string label
    );
        logic [63:0] request_before;
        logic [63:0] response_before;
        integer cycles;
        begin
            cycles = 0;
            while (!((u_small_dut.state_q == wanted_state)
                    && u_small_dut.phase_fire_w) && (cycles < 4096)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((u_small_dut.state_q != wanted_state)
                    || !u_small_dut.phase_fire_w)
                fail_case($sformatf("%s missing matching fire", label));
            request_before = small_gmem_read_requests_o
                           + small_gmem_write_requests_o
                           + small_widen_requests_o
                           + small_add_requests_o
                           + small_narrow_requests_o;
            response_before = small_gmem_read_responses_o
                            + small_gmem_write_responses_o
                            + small_widen_responses_o
                            + small_add_responses_o
                            + small_narrow_responses_o;
            force u_small_dut.stall_cycles_q = 64'd7;
            #1;
            if (!u_small_dut.phase_fire_w || u_small_dut.fault_detect_w
                    || u_small_dut.stall_timeout_hit_w
                    || u_small_dut.command_timeout_hit_w)
                fail_case($sformatf("%s fire lost to deadline", label));
            @(posedge clk_i);
            #1;
            release u_small_dut.stall_cycles_q;
            force u_small_dut.stall_cycles_q = 64'd0;
            release u_small_dut.stall_cycles_q;
            if (u_small_dut.fault_latched_q
                    || (expect_request
                        && ((small_gmem_read_requests_o
                             + small_gmem_write_requests_o
                             + small_widen_requests_o
                             + small_add_requests_o
                             + small_narrow_requests_o)
                            != (request_before + 64'd1)))
                    || (!expect_request
                        && ((small_gmem_read_responses_o
                             + small_gmem_write_responses_o
                             + small_widen_responses_o
                             + small_add_responses_o
                             + small_narrow_responses_o)
                            != (response_before + 64'd1))))
                fail_case($sformatf("%s deadline fire accounting", label));
            deadline_fire_witness_count = deadline_fire_witness_count + 1;
            @(negedge clk_i);
        end
    endtask

    task automatic deadline_command_fire_final_publish;
        logic [63:0] response_before;
        integer cycles;
        begin
            cycles = 0;
            while (!((u_small_dut.state_q == ST_PUBLISH_WAIT)
                    && (u_small_dut.publish_index_q == 32'd1)
                    && u_small_dut.gmem_rsp_fire_w)
                    && (cycles < 4096)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((u_small_dut.state_q != ST_PUBLISH_WAIT)
                    || (u_small_dut.publish_index_q != 32'd1)
                    || !u_small_dut.gmem_rsp_fire_w)
                fail_case("final publish command deadline missing fire");
            response_before = small_gmem_read_responses_o
                            + small_gmem_write_responses_o
                            + small_widen_responses_o
                            + small_add_responses_o
                            + small_narrow_responses_o;
            force u_small_dut.command_cycles_q = 64'd511;
            #1;
            if (!u_small_dut.gmem_rsp_fire_w
                    || u_small_dut.command_timeout_hit_w
                    || u_small_dut.fault_detect_w)
                fail_case("final publish fire lost to command deadline");
            @(posedge clk_i);
            #1;
            release u_small_dut.command_cycles_q;
            force u_small_dut.command_cycles_q = 64'd0;
            release u_small_dut.command_cycles_q;
            if ((u_small_dut.state_q != ST_DONE)
                    || u_small_dut.fault_latched_q
                    || ((small_gmem_read_responses_o
                         + small_gmem_write_responses_o
                         + small_widen_responses_o
                         + small_add_responses_o
                         + small_narrow_responses_o)
                        != (response_before + 64'd1)))
                fail_case("final publish command-deadline accounting");
            deadline_fire_witness_count = deadline_fire_witness_count + 1;
            @(negedge clk_i);
        end
    endtask

    task automatic run_deadline_fire_wins;
        integer address;
        begin
            set_small_descriptor();
            small_allow_requests_q = 1'b1;
            small_hold_responses_q = 1'b0;
            small_response_delay_q = 0;
            for (address = 0; address < 16; address = address + 1)
                small_mem[256 + address] = 8'hc3;
            pulse_small_start();
            deadline_fire_once(ST_ROW_READ_REQ, 1'b1,
                               "GMEM read request deadline");
            deadline_fire_once(ST_ROW_READ_WAIT, 1'b0,
                               "GMEM read response deadline");
            deadline_fire_once(ST_WIDEN_REQ, 1'b1,
                               "widen request deadline");
            deadline_fire_once(ST_WIDEN_WAIT, 1'b0,
                               "widen response deadline");
            deadline_fire_once(ST_ADD_REQ, 1'b1,
                               "add request deadline");
            deadline_fire_once(ST_ADD_WAIT, 1'b0,
                               "add response deadline");
            deadline_fire_once(ST_NARROW_REQ, 1'b1,
                               "narrow request deadline");
            deadline_fire_once(ST_NARROW_WAIT, 1'b0,
                               "narrow response deadline");
            deadline_fire_once(ST_PUBLISH_REQ, 1'b1,
                               "GMEM write request deadline");
            deadline_fire_once(ST_PUBLISH_WAIT, 1'b0,
                               "GMEM write response deadline");
            deadline_command_fire_final_publish();
            wait_small_terminal(1'b0, 5'b0,
                                "deadline matching fires transaction");
            if ((small_get_word(256) !== 32'h4120_0000)
                    || (small_get_word(260) !== 32'h0000_0000))
                fail_case("deadline matching fires raw result");
            positive_fixture_count = positive_fixture_count + 1;
            $display("[NPU-ORDERED-SUM-ROWS][DEADLINE-FIRE-WINS] stall_gmem_req=2 stall_gmem_rsp=2 widen=2 add=2 narrow=2 command_gmem_rsp=1 total=11");
            @(negedge clk_i);
        end
    endtask

    task automatic run_busy_start;
        logic resident_generation;
        logic [127:0] resident_params;
        integer address;
        begin
            set_small_descriptor();
            for (address = 0; address < 16; address = address + 1) begin
                small_mem[256 + address] = 8'hc3;
                small_mem[384 + address] = 8'h5a;
            end
            small_response_delay_q = 2;
            pulse_small_start();
            wait_small_state(ST_ROW_READ_WAIT, "busy start setup");
            resident_generation = u_small_dut.generation_q;
            resident_params = u_small_dut.op_params_q;
            small_dst_region_base_i = SMALL_ALT_BASE;
            small_op_params_i = 128'h1;
            small_start_i = 1'b1;
            #1;
            if (small_ready_o)
                fail_case("busy second start was ready");
            @(posedge clk_i);
            @(negedge clk_i);
            small_start_i = 1'b0;
            if ((u_small_dut.dst_region_base_q != SMALL_DST_BASE)
                    || (u_small_dut.generation_q != resident_generation)
                    || (u_small_dut.op_params_q != resident_params))
                fail_case("busy start overwrote resident descriptor/epoch");
            wait_small_terminal(1'b0, 5'b0, "busy start original command");
            if ((small_get_word(256) !== 32'h4120_0000)
                    || (small_get_word(260) !== 32'h0000_0000))
                fail_case("busy start changed original destination");
            for (address = 0; address < 16; address = address + 1)
                if (small_mem[384 + address] !== 8'h5a)
                    fail_case("busy start touched alternate destination");
            small_response_delay_q = 0;
            set_small_descriptor();
            busy_start_fixture_count = busy_start_fixture_count + 1;
            @(negedge clk_i);
        end
    endtask

    task automatic run_reset_phase(
        input logic [4:0] wanted_state,
        input string label
    );
        begin
            set_small_descriptor();
            pulse_small_start();
            wait_small_state(wanted_state, label);
            small_rst_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (small_done_o || small_error_o || small_ready_o)
                fail_case($sformatf("%s reset edge visibility", label));
            small_rst_i = 1'b0;
            #1;
            if (!small_ready_o || small_busy_o
                    || (small_gmem_read_requests_o != 64'b0)
                    || (small_widen_requests_o != 64'b0))
                fail_case($sformatf("%s reset did not clear state", label));
            @(posedge clk_i);
            @(negedge clk_i);
            if (small_done_o || small_error_o || small_rsp_valid_i)
                fail_case($sformatf("%s stale completion after reset", label));
            reset_fixture_count = reset_fixture_count + 1;
        end
    endtask

    task automatic check_small_root_canary;
        integer address;
        begin
            for (address = 0; address < 32; address = address + 1)
                if (small_mem[768 + address] !== 8'ha5)
                    fail_case("small active-root canary changed");
        end
    endtask

    integer vector_file;
    integer vector_line_rc;
    integer vector_line_count;
    string vector_line;
    integer init_index;

    initial begin
        oracle_runtime_mode_q = ORACLE_MODE_PRODUCTION;
        oracle_runtime_mode_arg = "production";
        oracle_mode_plusarg_rc =
            $value$plusargs("ORACLE_MODE=%s", oracle_runtime_mode_arg);
        if (oracle_mode_plusarg_rc != 0) begin
            case (oracle_runtime_mode_arg)
                "production":
                    oracle_runtime_mode_q = ORACLE_MODE_PRODUCTION;
                "wrong-coordinate":
                    oracle_runtime_mode_q = ORACLE_MODE_WRONG_COORDINATE;
                "wrong-gmem-address":
                    oracle_runtime_mode_q = ORACLE_MODE_WRONG_GMEM_ADDRESS;
                "wrong-event-delta":
                    oracle_runtime_mode_q = ORACLE_MODE_WRONG_EVENT_DELTA;
                default:
                    fail_case($sformatf("invalid ORACLE_MODE=%s",
                                        oracle_runtime_mode_arg));
            endcase
        end
        $display("[NPU-ORDERED-SUM-ROWS][ORACLE-MODE] kind=%s",
                 oracle_runtime_mode_arg);

        full_rst_i = 1'b1;
        full_start_i = 1'b0;
        full_rsp_valid_i = 1'b0;
        full_rsp_rdata_i = 64'b0;
        full_rsp_error_i = 1'b0;
        full_pending_q = 1'b0;
        full_pending_write_q = 1'b0;
        full_pending_addr_q = 21'b0;
        full_read_accept_count = 0;
        full_write_accept_count = 0;
        full_response_count = 0;
        full_done_count = 0;

        small_rst_i = 1'b1;
        small_start_i = 1'b0;
        small_txn_tag_i = 32'h5100_0000;
        small_rsp_valid_model_q = 1'b0;
        small_rsp_valid_ghost_q = 1'b0;
        small_rsp_rdata_i = 64'b0;
        small_rsp_error_i = 1'b0;
        small_allow_requests_q = 1'b1;
        small_hold_responses_q = 1'b0;
        small_inject_read_error_q = 1'b0;
        small_inject_write_error_q = 1'b0;
        small_response_delay_q = 0;
        small_pending_q = 1'b0;
        small_pending_write_q = 1'b0;
        small_pending_addr_q = 12'b0;
        small_pending_error_q = 1'b0;
        small_response_countdown_q = 0;
        small_accept_count = 0;
        small_read_accept_count = 0;
        small_write_accept_count = 0;
        small_response_count = 0;
        small_done_count = 0;
        small_error_count = 0;
        positive_fixture_count = 0;
        preflight_fixture_count = 0;
        gmem_fault_fixture_count = 0;
        child_fault_fixture_count = 0;
        child_fault_edge_witness_count = 0;
        overlap_fault_fixture_count = 0;
        terminal_cleanup_fixture_count = 0;
        reset_fixture_count = 0;
        busy_start_fixture_count = 0;
        persistent_ledger_killer_count = 0;
        held_gmem_killer_count = 0;
        held_child_killer_count = 0;
        retired_late_ghost_killer_count = 0;
        deadline_fire_witness_count = 0;
        first_fault_address_killer_count = 0;
        terminal_error_state_witness_count = 0;
        terminal_poison_error_state_witness_count = 0;
        terminal_poison_state_witness_count = 0;
        collision_poison_witness_count = 0;
        abort_hold_poison_witness_count = 0;
        drain_poison_witness_count = 0;
        small_previous_state_q = ST_IDLE;
        small_expected_fault_valid_q = 1'b0;
        small_expected_fault_cycle_q = 64'b0;
        small_expected_fault_coordinate_q = 128'b0;
        small_expected_fault_gmem_addr_q = 64'b0;
        small_expected_fault_flags_q = 5'b0;
        small_expected_fault_request_events_q = 64'b0;
        small_expected_fault_response_events_q = 64'b0;
        small_expected_fault_txn_tag_q = 32'b0;
        small_expected_fault_generation_q = 1'b0;
        small_expected_fault_resource_q = 3'b0;
        small_expected_fault_owner_type_q = 3'b0;
        small_expected_fault_owner_valid_q = 1'b0;
        small_expected_fault_owner_generation_q = 1'b0;
        small_expected_fault_owner_row_q = 32'b0;
        small_expected_fault_owner_index_q = 32'b0;
        small_fault_expect_arm_q = 1'b0;
        small_fault_expect_cycle_q = 64'b0;
        small_fault_expect_coordinate_q = 128'b0;
        small_fault_expect_gmem_addr_q = 64'b0;
        small_fault_expect_flags_q = 5'b0;
        small_fault_expect_request_events_q = 64'b0;
        small_fault_expect_response_events_q = 64'b0;
        small_fault_expect_txn_tag_q = 32'b0;
        small_fault_expect_generation_q = 1'b0;
        small_fault_expect_resource_q = 3'b0;
        small_fault_expect_owner_type_q = 3'b0;
        small_fault_expect_owner_valid_q = 1'b0;
        small_fault_expect_owner_generation_q = 1'b0;
        small_fault_expect_owner_row_q = 32'b0;
        small_fault_expect_owner_index_q = 32'b0;
        fault_output_capture_count = 0;
        fault_output_stability_checks = 0;
        success_fault_zero_check_count = 0;
        set_small_descriptor();
        if (oracle_runtime_mode_q == ORACLE_MODE_PRODUCTION)
            prepare_full_vectors();
        prepare_small_memory();

        // Raw oracle file membership is checked independently of the hardcoded
        // arithmetic expected path; evidence later binds its SHA byte-for-byte.
        vector_line_count = 0;
        if (oracle_runtime_mode_q == ORACLE_MODE_PRODUCTION) begin
            vector_file = $fopen(
                "npu/version_0820/tests/vectors/ordered_sum_rows_vectors.jsonl", "r");
            if (vector_file == 0)
                fail_case("cannot open canonical ordered SUM_ROWS vectors");
            for (init_index = 0; init_index < 60;
                    init_index = init_index + 1) begin
                vector_line_rc = $fgets(vector_line, vector_file);
                if (vector_line_rc == 0)
                    fail_case("canonical vector file has fewer than 60 rows");
                if (vector_line.len() == 0)
                    fail_case("canonical vector file has an empty read row");
                vector_line_count = vector_line_count + 1;
            end
            vector_line_rc = $fgets(vector_line, vector_file);
            if (vector_line_rc != 0)
                fail_case("canonical vector file has unexpected extra rows");
            $fclose(vector_file);
            if (vector_line_count != 60)
                fail_case("canonical vector cardinality");
            $display("[NPU-ORDERED-SUM-ROWS][ORACLE] rows=%0d sha256=%064x",
                     vector_line_count, VECTOR_SHA256);
        end

        repeat (3) @(posedge clk_i);
        if (oracle_runtime_mode_q == ORACLE_MODE_PRODUCTION) begin
            @(negedge clk_i);
            full_rst_i = 1'b0;
            run_full_success();
        end

        // The full/default target is complete before the bounded fault target
        // leaves reset, so neither GMEM model can alias another transaction.
        @(negedge clk_i);
        small_rst_i = 1'b0;
        run_small_positive("small baseline");

        // 27 preflight fixtures: every one must terminate before first request.
        set_small_descriptor(); small_dtype_i = 8'h02;
        run_preflight_error(ERR_HEADER, "bad dtype");
        if ((small_first_fault_resource_o != FAULT_RESOURCE_CONTROL)
                || (small_first_fault_owner_type_o != OWNER_NONE)
                || (small_first_fault_gmem_addr_o != 64'b0))
            fail_case("stale GMEM address crossed into preflight fault");
        first_fault_address_killer_count =
            first_fault_address_killer_count + 1;
        $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-ADDR] class=STALE resource=CONTROL owner=NONE addr=%016x req_delta=0",
                 small_first_fault_gmem_addr_o);
        small_gmem_floor_i = 64'h1000;
        small_gmem_limit_i = 64'h1000;
        run_preflight_error(ERR_HEADER, "bad GMEM header window");
        small_profile_i = 8'h02;
        run_preflight_error(ERR_PROFILE_POLICY, "bad profile");
        small_rounding_mode_i = 3'b001;
        run_preflight_error(ERR_PROFILE_POLICY, "bad rounding");
        small_denormal_mode_i = 2'b01;
        run_preflight_error(ERR_PROFILE_POLICY, "bad denormal mode");
        small_nan_policy_i = 2'b01;
        run_preflight_error(ERR_PROFILE_POLICY, "bad NaN policy");
        small_dst_shadow_private_i = 1'b0;
        run_preflight_error(ERR_PROFILE_POLICY, "non-private destination");
        small_reserved_i = 32'h1;
        run_preflight_error(ERR_OP_PARAMS, "reserved bits");
        small_op_params_i = 128'h1;
        run_preflight_error(ERR_OP_PARAMS, "op params");
        small_src_ne0_i = 32'd5;
        run_preflight_error(ERR_SHAPE, "source ne0");
        small_src_ne1_i = 32'd3;
        run_preflight_error(ERR_SHAPE, "source ne1");
        small_src_ne2_i = 32'd2;
        run_preflight_error(ERR_SHAPE, "source ne2");
        small_dst_ne0_i = 32'd2;
        run_preflight_error(ERR_SHAPE, "destination ne0");
        small_dst_ne1_i = 32'd3;
        run_preflight_error(ERR_SHAPE, "destination ne1");
        small_src_nb0_i = 64'd8;
        run_preflight_error(ERR_STRIDE_ALIGN, "source nb0");
        small_src_nb1_i = 64'd24;
        run_preflight_error(ERR_STRIDE_ALIGN, "source nb1");
        small_src_nb2_i = 64'd40;
        run_preflight_error(ERR_STRIDE_ALIGN, "source nb2");
        small_src_nb3_i = 64'd40;
        run_preflight_error(ERR_STRIDE_ALIGN, "source nb3");
        small_dst_nb0_i = 64'd8;
        run_preflight_error(ERR_STRIDE_ALIGN, "destination nb0");
        small_dst_nb2_i = 64'd16;
        run_preflight_error(ERR_STRIDE_ALIGN, "destination nb2");
        small_dst_nb3_i = 64'd16;
        run_preflight_error(ERR_STRIDE_ALIGN, "destination nb3");
        small_src_view_off_i = 64'd4;
        run_preflight_error(ERR_STRIDE_ALIGN, "source 8B alignment");
        small_dst_view_off_i = 64'd2;
        run_preflight_error(ERR_STRIDE_ALIGN, "destination 4B alignment");
        small_src_region_size_i = 64'd31;
        run_preflight_error(ERR_SOURCE_BOUNDS, "source region bound");
        small_dst_region_size_i = 64'd7;
        run_preflight_error(ERR_DEST_BOUNDS, "destination region bound");
        small_src_region_base_i = 64'hffff_ffff_ffff_fff8;
        small_src_region_size_i = 64'd32;
        run_preflight_error(ERR_SOURCE_BOUNDS, "source 128-bit overflow");
        small_dst_region_base_i = 64'h0;
        small_dst_region_size_i = 64'd32;
        run_preflight_error(ERR_OVERLAP, "aligned window overlap");
        if (preflight_fixture_count != 27)
            fail_case("preflight fixture cardinality");

        run_request_timeout();
        run_gmem_response_error(1'b0, "read response error");
        run_gmem_response_error(1'b1, "write response error");
        run_accepted_drain(1'b0, "accepted wait drain");
        run_accepted_drain(1'b1, "late error preserves first cause");
        run_small_positive("clean retry after GMEM drains");
        run_persistent_ledger_corruption();
        run_drain_poison();
        run_small_positive("clean retry after poison reset");
        run_ownerless_read_request_collision();
        run_ownerless_publish_request_collision();
        run_abort_hold_read_watchdog();
        run_abort_hold_publish_watchdog();

        run_child_ghost();
        run_small_positive("clean retry after child ghost");
        run_widen_wrong_owner();
        run_small_positive("clean retry after widen owner fault");
        run_add_wrong_owner();
        run_small_positive("clean retry after add owner fault");
        run_narrow_wrong_owner();
        run_small_positive("clean retry after narrow owner fault");
        run_child_fault_with_existing_gmem_owner();
        run_small_positive("clean retry after cross-resource GMEM drain");
        run_gmem_ghost_with_child_request();
        run_matching_child_response_with_other_ghost();
        run_small_positive("clean retry after matching response overlap");
        run_final_shadow_ack_with_child_ghost();
        run_held_publish_request_fault();
        run_idle_start_with_child_ghost();
        run_small_positive("clean retry after IDLE ghost");
        run_held_child_request_fault(ST_WIDEN_REQ,
                                     "held widen request");
        run_held_child_request_fault(ST_ADD_REQ,
                                     "held add request");
        run_held_child_request_fault(ST_NARROW_REQ,
                                     "held narrow request");
        run_child_timeout();
        run_small_positive("clean retry after child timeout");

        run_terminal_ghost_cleanup();
        run_post_error_late_ghost_cleanup();
        run_deadline_fire_wins();

        run_busy_start();
        run_reset_phase(ST_PREFLIGHT, "reset preflight");
        run_reset_phase(ST_ROW_READ_WAIT, "reset read");
        run_reset_phase(ST_WIDEN_WAIT, "reset widen");
        run_reset_phase(ST_ADD_WAIT, "reset add");
        run_reset_phase(ST_NARROW_WAIT, "reset narrow");
        run_reset_phase(ST_PUBLISH_REQ, "reset publish");
        run_small_positive("final clean retry");
        check_small_root_canary();

        if ((gmem_fault_fixture_count != 11)
                || (child_fault_fixture_count != 9)
                || (child_fault_edge_witness_count != 9)
                || (overlap_fault_fixture_count != 6)
                || (terminal_cleanup_fixture_count != 1)
                || (reset_fixture_count != 6)
                || (busy_start_fixture_count != 1)
                || (positive_fixture_count != 25)
                || (persistent_ledger_killer_count != 1)
                || (held_gmem_killer_count != 2)
                || (held_child_killer_count != 3)
                || (retired_late_ghost_killer_count != 1)
                || (deadline_fire_witness_count != 11)
                || (first_fault_address_killer_count != 7)
                || (collision_poison_witness_count != 3)
                || (abort_hold_poison_witness_count != 2)
                || (drain_poison_witness_count != 1))
            fail_case("fault/recovery fixture cardinality");
        if ((small_done_count != (positive_fixture_count
                                  + busy_start_fixture_count
                                  + terminal_cleanup_fixture_count))
                || (small_error_count != 48)
                || (small_read_accept_count <= 0)
                || (small_write_accept_count <= 0)
                || (small_response_count <= 0))
            fail_case("independent small model final cardinality");
        if ((fault_output_capture_count != 52)
                || (success_fault_zero_check_count != 27)
                || (fault_output_stability_checks < 52))
            fail_case("first-fault output fixture cardinality");
        $display("[NPU-ORDERED-SUM-ROWS][TERMINAL-STATE-DIAGNOSTIC] error=%0d poison_error=%0d poison=%0d expected=47/1/4 small_error=%0d captures=%0d collision=%0d abort=%0d drain=%0d previous_state=%0d current_state=%0d",
                 terminal_error_state_witness_count,
                 terminal_poison_error_state_witness_count,
                 terminal_poison_state_witness_count,
                 small_error_count,
                 fault_output_capture_count,
                 collision_poison_witness_count,
                 abort_hold_poison_witness_count,
                 drain_poison_witness_count,
                 small_previous_state_q,
                 u_small_dut.state_q);
        if ((terminal_error_state_witness_count
                != EXPECTED_RECOVERABLE_ERROR_STATE_WITNESSES)
                || (terminal_poison_error_state_witness_count
                    != EXPECTED_POISON_ERROR_STATE_WITNESSES)
                || (terminal_poison_state_witness_count
                    != EXPECTED_POISON_STATE_WITNESSES))
            fail_case($sformatf(
                "terminal state witness cardinality actual=%0d/%0d/%0d expected=%0d/%0d/%0d",
                terminal_error_state_witness_count,
                terminal_poison_error_state_witness_count,
                terminal_poison_state_witness_count,
                EXPECTED_RECOVERABLE_ERROR_STATE_WITNESSES,
                EXPECTED_POISON_ERROR_STATE_WITNESSES,
                EXPECTED_POISON_STATE_WITNESSES));

        $display("[NPU-ORDERED-SUM-ROWS][FAULT-OUTPUT] captures=52 success_zero=27 stable=1 identity_fields=8");
        $display("[NPU-ORDERED-SUM-ROWS][FIRST-FAULT-IDENTITY] txn_tag=1 generation=1 resource=1 owner_type=1 owner_valid=1 owner_generation=1 owner_row=1 owner_index=1 independent_oracle=1");
        $display("[NPU-ORDERED-SUM-ROWS][TERMINAL-STATE-WITNESS] error=%0d poison_error=%0d poison=%0d",
                 terminal_error_state_witness_count,
                 terminal_poison_error_state_witness_count,
                 terminal_poison_state_witness_count);
        $display("[NPU-ORDERED-SUM-ROWS][TERMINAL-TOPOLOGY] recoverable_error=47 poison_error=1 poison_state=4 collision_poison=3 abort_hold_poison=2 drain_poison=1 done=27 fault_captures=52");

        if (oracle_runtime_mode_q != ORACLE_MODE_PRODUCTION)
            fail_case("runtime oracle mutation escaped independent comparator");

        $display("[NPU-ORDERED-SUM-ROWS][PASS] full_rows=2048 elements=262144 oracle_rows=60 preflight=%0d gmem_fault=%0d child_fault=%0d overlap=%0d terminal_cleanup=%0d reset=%0d busy=%0d",
                 preflight_fixture_count, gmem_fault_fixture_count,
                 child_fault_fixture_count, overlap_fault_fixture_count,
                 terminal_cleanup_fixture_count, reset_fixture_count,
                 busy_start_fixture_count);
        $finish;
    end

endmodule

`default_nettype wire
