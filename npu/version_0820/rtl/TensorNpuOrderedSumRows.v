`timescale 1ns/1ps
`default_nettype none

// Fixed-profile ordered F32 row reduction.
//
// Each row is first buffered locally, then evaluated as the exact serial DAG
//
//   acc[-1] = binary64 +0
//   term[i] = FCVT.D.S(x[i]); acc[i] = FADD.D.RNE(acc[i-1], term[i])
//   y       = FCVT.S.D.RNE(acc[NE0-1])
//
// Intermediate values never reach GMEM.  All rows enter result_buffer_q before
// any transaction-private shadow write is issued.  done_o is therefore only
// commit eligibility for the parent; this module has no active-root write port.
module TensorNpuOrderedSumRows #(
    parameter integer NE0                    = 128,
    parameter integer NE1                    = 128,
    parameter integer NE2                    = 16,
    parameter integer NE3                    = 1,
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 8388608,
    parameter integer DRAIN_TIMEOUT_CYCLES   = 1024,
    // A faulted request must remain exposed until a real fire, but the
    // transaction must still become observably fail-closed when ready never
    // returns.  Zero and one both mean "poison on the first complete held
    // cycle"; N>1 poisons on the Nth complete held cycle.
    parameter integer ABORT_HOLD_TIMEOUT_CYCLES = DRAIN_TIMEOUT_CYCLES
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    input  wire [31:0]  txn_tag_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [7:0]   dtype_i,
    input  wire [7:0]   profile_i,
    input  wire [2:0]   rounding_mode_i,
    input  wire [1:0]   denormal_mode_i,
    input  wire [1:0]   nan_policy_i,
    input  wire         dst_shadow_private_i,
    input  wire [31:0]  reserved_i,
    input  wire [127:0] op_params_i,

    input  wire [63:0]  gmem_floor_i,
    input  wire [63:0]  gmem_limit_i,

    input  wire [63:0]  src_region_base_i,
    input  wire [63:0]  src_region_size_i,
    input  wire [63:0]  src_view_off_i,
    input  wire [31:0]  src_ne0_i,
    input  wire [31:0]  src_ne1_i,
    input  wire [31:0]  src_ne2_i,
    input  wire [31:0]  src_ne3_i,
    input  wire [63:0]  src_nb0_i,
    input  wire [63:0]  src_nb1_i,
    input  wire [63:0]  src_nb2_i,
    input  wire [63:0]  src_nb3_i,

    input  wire [63:0]  dst_region_base_i,
    input  wire [63:0]  dst_region_size_i,
    input  wire [63:0]  dst_view_off_i,
    input  wire [31:0]  dst_ne0_i,
    input  wire [31:0]  dst_ne1_i,
    input  wire [31:0]  dst_ne2_i,
    input  wire [31:0]  dst_ne3_i,
    input  wire [63:0]  dst_nb0_i,
    input  wire [63:0]  dst_nb1_i,
    input  wire [63:0]  dst_nb2_i,
    input  wire [63:0]  dst_nb3_i,

    output wire         gmem_req_valid_o,
    input  wire         gmem_req_ready_i,
    output wire         gmem_req_write_o,
    output wire [63:0]  gmem_req_addr_o,
    output wire [63:0]  gmem_req_wdata_o,
    output wire [7:0]   gmem_req_wstrb_o,
    input  wire         gmem_rsp_valid_i,
    output wire         gmem_rsp_ready_o,
    input  wire [63:0]  gmem_rsp_rdata_i,
    input  wire         gmem_rsp_error_i,

    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [4:0]   flags_o,
    output wire         poisoned_o,
    output wire         fault_valid_o,
    output wire [63:0]  first_fault_cycle_o,
    output wire [127:0] first_fault_coordinate_o,
    output wire [63:0]  first_fault_gmem_addr_o,
    output wire [4:0]   first_fault_flags_o,
    output wire [63:0]  first_fault_request_events_o,
    output wire [63:0]  first_fault_response_events_o,
    output wire [31:0]  first_fault_txn_tag_o,
    output wire         first_fault_generation_o,
    output wire [2:0]   first_fault_resource_o,
    output wire [2:0]   first_fault_owner_type_o,
    output wire         first_fault_owner_valid_o,
    output wire         first_fault_owner_generation_o,
    output wire [31:0]  first_fault_owner_row_o,
    output wire [31:0]  first_fault_owner_index_o,
    output wire [63:0]  rows_reduced_o,
    output wire [63:0]  elements_processed_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  widen_requests_o,
    output wire [63:0]  widen_responses_o,
    output wire [63:0]  add_requests_o,
    output wire [63:0]  add_responses_o,
    output wire [63:0]  narrow_requests_o,
    output wire [63:0]  narrow_responses_o,
    output wire [63:0]  active_cycles_o
);

    localparam integer ROWS       = NE1 * NE2 * NE3;
    localparam integer READ_BEATS = NE0 / 2;
    localparam integer ELEMENT_ARRAY_WIDTH = (NE0 <= 1) ? 1 : $clog2(NE0);
    localparam integer ROW_ARRAY_WIDTH = (ROWS <= 1) ? 1 : $clog2(ROWS);

    localparam [31:0] NE0_U32       = NE0;
    localparam [31:0] NE1_U32       = NE1;
    localparam [31:0] NE2_U32       = NE2;
    localparam [31:0] NE3_U32       = NE3;
    localparam [31:0] ROWS_U32      = ROWS;
    localparam [31:0] READ_BEATS_U32 = READ_BEATS;

    // Enter the watchdog domain through an explicitly sized cast.  Keeping the
    // integer parameter out of a concatenation preserves its nonnegative value
    // while making the 64-bit comparison width part of the expression itself.
    localparam [63:0] STALL_TIMEOUT_VALUE = 64'(STALL_TIMEOUT_CYCLES);
    localparam [63:0] COMMAND_TIMEOUT_VALUE = 64'(COMMAND_TIMEOUT_CYCLES);
    localparam [63:0] DRAIN_TIMEOUT_VALUE = 64'(DRAIN_TIMEOUT_CYCLES);
    localparam [63:0] ABORT_HOLD_TIMEOUT_VALUE =
        64'(ABORT_HOLD_TIMEOUT_CYCLES);
    localparam [63:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_VALUE <= 64'd1) ? 64'd0
                                      : (STALL_TIMEOUT_VALUE - 64'd1);
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_VALUE <= 64'd1) ? 64'd0
                                        : (COMMAND_TIMEOUT_VALUE - 64'd1);
    localparam [63:0] DRAIN_TIMEOUT_LAST =
        (DRAIN_TIMEOUT_VALUE <= 64'd1) ? 64'd0
                                      : (DRAIN_TIMEOUT_VALUE - 64'd1);
    localparam [63:0] ABORT_HOLD_TIMEOUT_LAST =
        (ABORT_HOLD_TIMEOUT_VALUE <= 64'd1) ? 64'd0
                                           : (ABORT_HOLD_TIMEOUT_VALUE - 64'd1);

    localparam [4:0] ST_IDLE              = 5'd0;
    localparam [4:0] ST_PREFLIGHT         = 5'd1;
    localparam [4:0] ST_ROW_READ_PREP     = 5'd2;
    localparam [4:0] ST_ROW_READ_REQ      = 5'd3;
    localparam [4:0] ST_ROW_READ_WAIT     = 5'd4;
    localparam [4:0] ST_WIDEN_REQ         = 5'd5;
    localparam [4:0] ST_WIDEN_WAIT        = 5'd6;
    localparam [4:0] ST_ADD_REQ           = 5'd7;
    localparam [4:0] ST_ADD_WAIT          = 5'd8;
    localparam [4:0] ST_NARROW_REQ        = 5'd9;
    localparam [4:0] ST_NARROW_WAIT       = 5'd10;
    localparam [4:0] ST_PUBLISH_PREP      = 5'd11;
    localparam [4:0] ST_PUBLISH_REQ       = 5'd12;
    localparam [4:0] ST_PUBLISH_WAIT      = 5'd13;
    localparam [4:0] ST_GMEM_DRAIN        = 5'd14;
    localparam [4:0] ST_CHILD_QUARANTINE  = 5'd15;
    localparam [4:0] ST_DONE              = 5'd16;
    localparam [4:0] ST_ERROR             = 5'd17;
    localparam [4:0] ST_POISON_ERROR      = 5'd18;
    localparam [4:0] ST_POISON            = 5'd19;
    localparam [4:0] ST_STRAY_GMEM_DROP   = 5'd20;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_HEADER          = 5'd1;
    localparam [4:0] ERR_PROFILE_POLICY  = 5'd2;
    localparam [4:0] ERR_OP_PARAMS       = 5'd3;
    localparam [4:0] ERR_SHAPE           = 5'd4;
    localparam [4:0] ERR_STRIDE_ALIGN    = 5'd5;
    localparam [4:0] ERR_SOURCE_BOUNDS   = 5'd6;
    localparam [4:0] ERR_DEST_BOUNDS     = 5'd7;
    localparam [4:0] ERR_OVERLAP         = 5'd8;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd9;
    localparam [4:0] ERR_PROTOCOL_OWNER  = 5'd10;
    localparam [4:0] ERR_CHILD_RESPONSE  = 5'd11;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd12;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd13;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd14;
    localparam [4:0] ERR_POISONED        = 5'd15;

    localparam [2:0] FAULT_RESOURCE_CONTROL = 3'd0;
    localparam [2:0] FAULT_RESOURCE_GMEM    = 3'd1;
    localparam [2:0] FAULT_RESOURCE_WIDEN   = 3'd2;
    localparam [2:0] FAULT_RESOURCE_ADD     = 3'd3;
    localparam [2:0] FAULT_RESOURCE_NARROW  = 3'd4;

    localparam [2:0] OWNER_NONE       = 3'd0;
    localparam [2:0] OWNER_GMEM_READ  = 3'd1;
    localparam [2:0] OWNER_GMEM_WRITE = 3'd2;
    localparam [2:0] OWNER_WIDEN      = 3'd3;
    localparam [2:0] OWNER_ADD        = 3'd4;
    localparam [2:0] OWNER_NARROW     = 3'd5;

    reg [4:0] state_q;

    // Resident descriptor: only start_i && ready_o writes these registers.
    reg [7:0]   dtype_q;
    reg [7:0]   profile_q;
    reg [2:0]   rounding_mode_q;
    reg [1:0]   denormal_mode_q;
    reg [1:0]   nan_policy_q;
    reg         dst_shadow_private_q;
    reg [31:0]  reserved_q;
    reg [127:0] op_params_q;
    reg [63:0]  gmem_floor_q;
    reg [63:0]  gmem_limit_q;
    reg [63:0]  src_region_base_q;
    reg [63:0]  src_region_size_q;
    reg [63:0]  src_view_off_q;
    reg [31:0]  src_ne0_q;
    reg [31:0]  src_ne1_q;
    reg [31:0]  src_ne2_q;
    reg [31:0]  src_ne3_q;
    reg [63:0]  src_nb0_q;
    reg [63:0]  src_nb1_q;
    reg [63:0]  src_nb2_q;
    reg [63:0]  src_nb3_q;
    reg [63:0]  dst_region_base_q;
    reg [63:0]  dst_region_size_q;
    reg [63:0]  dst_view_off_q;
    reg [31:0]  dst_ne0_q;
    reg [31:0]  dst_ne1_q;
    reg [31:0]  dst_ne2_q;
    reg [31:0]  dst_ne3_q;
    reg [63:0]  dst_nb0_q;
    reg [63:0]  dst_nb1_q;
    reg [63:0]  dst_nb2_q;
    reg [63:0]  dst_nb3_q;
    reg [31:0]  txn_tag_q;
    reg         generation_q;

    // Runtime coordinates and private storage.
    reg [31:0] row_index_q;
    reg [31:0] read_beat_q;
    reg [31:0] element_index_q;
    reg [31:0] publish_index_q;
    reg [31:0] row_buffer_q [0:NE0-1];
    reg [31:0] result_buffer_q [0:ROWS-1];
    reg [63:0] accumulator_q;
    reg [63:0] widened_term_q;
    wire [ELEMENT_ARRAY_WIDTH-1:0] read_beat_array_index_w;
    wire [ELEMENT_ARRAY_WIDTH-1:0] read_even_array_index_w;
    wire [ELEMENT_ARRAY_WIDTH-1:0] read_odd_array_index_w;
    wire [ELEMENT_ARRAY_WIDTH-1:0] element_array_index_w;
    wire [ROW_ARRAY_WIDTH-1:0] row_array_index_w;
    wire [ROW_ARRAY_WIDTH-1:0] publish_array_index_w;

    // Form both lane indices entirely in the bounded array-index domain.  The
    // shift supplies the explicit even low bit, and the sized OR supplies the
    // odd low bit, so no unused wide 2*beat intermediate exists.
    assign read_beat_array_index_w =
        read_beat_q[ELEMENT_ARRAY_WIDTH-1:0];
    assign read_even_array_index_w = read_beat_array_index_w << 1;
    assign read_odd_array_index_w =
        (read_beat_array_index_w << 1)
        | {{(ELEMENT_ARRAY_WIDTH-1){1'b0}}, 1'b1};
    assign element_array_index_w =
        element_index_q[ELEMENT_ARRAY_WIDTH-1:0];
    assign row_array_index_w = row_index_q[ROW_ARRAY_WIDTH-1:0];
    assign publish_array_index_w = publish_index_q[ROW_ARRAY_WIDTH-1:0];

    // Shared held GMEM payload and accepted-owner ledger.
    reg [63:0] gmem_req_addr_q;
    reg [63:0] gmem_req_wdata_q;
    reg [7:0]  gmem_req_wstrb_q;
    reg        gmem_req_write_q;
    reg        gmem_owner_valid_q;
    reg [63:0] gmem_owner_addr_q;
    reg        gmem_owner_write_q;
    reg        gmem_owner_generation_q;
    reg [31:0] gmem_owner_row_q;
    reg [31:0] gmem_owner_index_q;

    // Independent child owners.  The metadata is intentionally visible to the
    // directed TB so forced corruption reaches the production fault predicate.
    reg        widen_owner_valid_q;
    reg        widen_owner_generation_q;
    reg [31:0] widen_owner_row_q;
    reg [31:0] widen_owner_element_q;
    reg        add_owner_valid_q;
    reg        add_owner_generation_q;
    reg [31:0] add_owner_row_q;
    reg [31:0] add_owner_element_q;
    reg        narrow_owner_valid_q;
    reg        narrow_owner_generation_q;
    reg [31:0] narrow_owner_row_q;
    reg [31:0] narrow_owner_element_q;

    reg [63:0] stall_cycles_q;
    reg [63:0] command_cycles_q;
    reg [63:0] drain_cycles_q;
    reg [63:0] abort_hold_cycles_q;
    reg [4:0]  error_code_q;
    reg [4:0]  flags_q;
    reg [63:0] rows_reduced_q;
    reg [63:0] elements_processed_q;
    reg [63:0] gmem_read_requests_q;
    reg [63:0] gmem_read_responses_q;
    reg [63:0] gmem_write_requests_q;
    reg [63:0] gmem_write_responses_q;
    reg [63:0] widen_requests_q;
    reg [63:0] widen_responses_q;
    reg [63:0] add_requests_q;
    reg [63:0] add_responses_q;
    reg [63:0] narrow_requests_q;
    reg [63:0] narrow_responses_q;
    reg [63:0] active_cycles_q;

    // A single first-fault ledger is resident until cleanup and the terminal
    // pulse complete.  The snapshots intentionally contain the post-fire view
    // of the fault edge, so a real handshake cannot disappear behind fault
    // arbitration.
    reg         fault_latched_q;
    reg         txn_active_q;
    reg         abort_hold_q;
    // These causes are reset-only.  In particular, a same-channel ownerless
    // response/request-fire collision cannot be made recoverable without a
    // response transaction tag, and an indefinitely held faulted request
    // cannot silently remain busy forever.
    reg         collision_poison_q;
    reg         abort_hold_poison_q;
    reg         cleanup_suppress_terminal_q;
    reg [63:0]  first_fault_cycle_q;
    reg [127:0] first_fault_coordinate_q;
    reg [63:0]  first_fault_gmem_addr_q;
    reg [4:0]   first_fault_flags_q;
    reg [63:0]  first_fault_request_events_q;
    reg [63:0]  first_fault_response_events_q;
    reg [31:0]  first_fault_txn_tag_q;
    reg         first_fault_generation_q;
    reg [2:0]   first_fault_resource_q;
    reg [2:0]   first_fault_owner_type_q;
    reg         first_fault_owner_valid_q;
    reg         first_fault_owner_generation_q;
    reg [31:0]  first_fault_owner_row_q;
    reg [31:0]  first_fault_owner_index_q;

    wire start_fire_w;
    wire operational_state_w;
    wire gmem_request_state_w;
    wire command_timeout_hit_w;
    wire stall_timeout_hit_w;
    wire drain_timeout_hit_w;
    wire child_rst_w;
    wire ingress_owner_fault_w;
    wire phase_fire_w;
    wire terminal_state_w;
    wire request_hold_state_w;
    wire held_request_fire_w;
    wire abort_hold_timeout_hit_w;
    wire reset_only_poison_w;

    // An IDLE ghost revokes command credit combinationally.  The descriptor is
    // therefore never sampled on the same edge as an unowned response.
    assign ready_o    = !rst_i && (state_q == ST_IDLE)
                      && !ingress_owner_fault_w;
    assign busy_o     = !rst_i && (state_q != ST_IDLE);
    assign done_o     = !rst_i && (state_q == ST_DONE);
    assign error_o    = !rst_i && ((state_q == ST_ERROR)
                                 || (state_q == ST_POISON_ERROR));
    assign reset_only_poison_w = collision_poison_q
                               || abort_hold_poison_q;
    assign poisoned_o = !rst_i && (((state_q == ST_POISON_ERROR)
                                  || (state_q == ST_POISON))
                                  || reset_only_poison_w);
    // The diagnostic record is part of the real completion interface rather
    // than verification-only state.  It remains stable through cleanup,
    // terminal and the following IDLE hold; reset or a clean command capture
    // is the only operation that invalidates it.
    assign fault_valid_o = !rst_i && fault_latched_q;
    assign first_fault_cycle_o = fault_valid_o
                               ? first_fault_cycle_q : 64'b0;
    assign first_fault_coordinate_o = fault_valid_o
                                    ? first_fault_coordinate_q : 128'b0;
    assign first_fault_gmem_addr_o = fault_valid_o
                                   ? first_fault_gmem_addr_q : 64'b0;
    assign first_fault_flags_o = fault_valid_o
                               ? first_fault_flags_q : 5'b0;
    assign first_fault_request_events_o = fault_valid_o
                                        ? first_fault_request_events_q
                                        : 64'b0;
    assign first_fault_response_events_o = fault_valid_o
                                         ? first_fault_response_events_q
                                         : 64'b0;
    assign first_fault_txn_tag_o = fault_valid_o
                                 ? first_fault_txn_tag_q : 32'b0;
    assign first_fault_generation_o = fault_valid_o
                                    ? first_fault_generation_q : 1'b0;
    assign first_fault_resource_o = fault_valid_o
                                  ? first_fault_resource_q : 3'b0;
    assign first_fault_owner_type_o = fault_valid_o
                                    ? first_fault_owner_type_q : 3'b0;
    assign first_fault_owner_valid_o = fault_valid_o
                                     ? first_fault_owner_valid_q : 1'b0;
    assign first_fault_owner_generation_o = fault_valid_o
                                          ? first_fault_owner_generation_q
                                          : 1'b0;
    assign first_fault_owner_row_o = fault_valid_o
                                   ? first_fault_owner_row_q : 32'b0;
    assign first_fault_owner_index_o = fault_valid_o
                                     ? first_fault_owner_index_q : 32'b0;
    // The new reset-only poison causes retain the immutable first cause.  The
    // legacy drain-exhaustion path still reports ERR_POISONED.
    assign error_code_o = (reset_only_poison_w
                        || (state_q == ST_ERROR)
                        || (state_q == ST_POISON_ERROR)
                        || (state_q == ST_POISON)) ? error_code_q : ERR_NONE;
    assign flags_o                 = flags_q;
    assign rows_reduced_o          = rows_reduced_q;
    assign elements_processed_o    = elements_processed_q;
    assign gmem_read_requests_o    = gmem_read_requests_q;
    assign gmem_read_responses_o   = gmem_read_responses_q;
    assign gmem_write_requests_o   = gmem_write_requests_q;
    assign gmem_write_responses_o  = gmem_write_responses_q;
    assign widen_requests_o        = widen_requests_q;
    assign widen_responses_o       = widen_responses_q;
    assign add_requests_o          = add_requests_q;
    assign add_responses_o         = add_responses_q;
    assign narrow_requests_o       = narrow_requests_q;
    assign narrow_responses_o      = narrow_responses_q;
    assign active_cycles_o         = active_cycles_q;
    assign start_fire_w            = start_i && ready_o;

    assign terminal_state_w = (state_q == ST_DONE)
                            || (state_q == ST_ERROR)
                            || (state_q == ST_POISON_ERROR);
    assign request_hold_state_w = (state_q == ST_ROW_READ_REQ)
                                || (state_q == ST_PUBLISH_REQ)
                                || (state_q == ST_WIDEN_REQ)
                                || (state_q == ST_ADD_REQ)
                                || (state_q == ST_NARROW_REQ);

    assign operational_state_w = (state_q != ST_IDLE)
                               && (state_q != ST_DONE)
                               && (state_q != ST_ERROR)
                               && (state_q != ST_POISON_ERROR)
                               && (state_q != ST_POISON)
                               && (state_q != ST_GMEM_DRAIN)
                               && (state_q != ST_CHILD_QUARANTINE)
                               && (state_q != ST_STRAY_GMEM_DROP);
    assign command_timeout_hit_w = operational_state_w
                                 && (command_cycles_q >= COMMAND_TIMEOUT_LAST)
                                 && !phase_fire_w;
    assign stall_timeout_hit_w = operational_state_w
                               && (stall_cycles_q >= STALL_TIMEOUT_LAST)
                               && !phase_fire_w;
    assign drain_timeout_hit_w = ((state_q == ST_GMEM_DRAIN)
                               || (state_q == ST_STRAY_GMEM_DROP))
                               && (drain_cycles_q >= DRAIN_TIMEOUT_LAST);
    assign abort_hold_timeout_hit_w = abort_hold_q
                                    && !held_request_fire_w
                                    && (abort_hold_cycles_q
                                        >= ABORT_HOLD_TIMEOUT_LAST);
    // Keep every child in reset while an accepted GMEM owner is drained.  The
    // quarantine state itself lasts a complete registered cycle before drain.
    assign child_rst_w = rst_i || (state_q == ST_CHILD_QUARANTINE)
                       || (state_q == ST_GMEM_DRAIN)
                       || (state_q == ST_STRAY_GMEM_DROP);

    // ------------------------------------------------------------------
    // 128-bit whole-descriptor preflight.
    // ------------------------------------------------------------------
    reg [127:0] expected_src_nb1_w;
    reg [127:0] expected_src_nb2_w;
    reg [127:0] expected_src_nb3_w;
    reg [127:0] expected_dst_nb2_w;
    reg [127:0] expected_dst_nb3_w;
    reg [127:0] source_count_w;
    reg [127:0] row_count_w;
    reg [127:0] source_bytes_w;
    reg [127:0] destination_bytes_w;
    reg [127:0] source_region_end_w;
    reg [127:0] destination_region_end_w;
    reg [127:0] source_relative_end_w;
    reg [127:0] destination_relative_end_w;
    reg [127:0] source_absolute_start_w;
    reg [127:0] source_absolute_end_w;
    reg [127:0] destination_absolute_start_w;
    reg [127:0] destination_absolute_end_w;
    reg [127:0] source_aligned_start_w;
    reg [127:0] source_aligned_end_w;
    reg [127:0] destination_aligned_start_w;
    reg [127:0] destination_aligned_end_w;
    reg         header_ok_w;
    reg         profile_policy_ok_w;
    reg         op_params_ok_w;
    reg         shape_ok_w;
    reg         stride_alignment_ok_w;
    reg         source_bounds_ok_w;
    reg         destination_bounds_ok_w;
    reg         overlap_ok_w;
    reg [4:0]   preflight_error_w;

    always @(*) begin
        expected_src_nb1_w = {96'b0, NE0_U32} * 128'd4;
        expected_src_nb2_w = expected_src_nb1_w * {96'b0, NE1_U32};
        expected_src_nb3_w = expected_src_nb2_w * {96'b0, NE2_U32};
        expected_dst_nb2_w = {96'b0, NE1_U32} * 128'd4;
        expected_dst_nb3_w = expected_dst_nb2_w * {96'b0, NE2_U32};

        source_count_w = {96'b0, NE0_U32};
        source_count_w = source_count_w * {96'b0, NE1_U32};
        source_count_w = source_count_w * {96'b0, NE2_U32};
        source_count_w = source_count_w * {96'b0, NE3_U32};
        row_count_w = {96'b0, NE1_U32};
        row_count_w = row_count_w * {96'b0, NE2_U32};
        row_count_w = row_count_w * {96'b0, NE3_U32};
        source_bytes_w = source_count_w * 128'd4;
        destination_bytes_w = row_count_w * 128'd4;

        source_region_end_w = {64'b0, src_region_base_q}
                            + {64'b0, src_region_size_q};
        destination_region_end_w = {64'b0, dst_region_base_q}
                                 + {64'b0, dst_region_size_q};
        source_relative_end_w = {64'b0, src_view_off_q} + source_bytes_w;
        destination_relative_end_w = {64'b0, dst_view_off_q}
                                   + destination_bytes_w;
        source_absolute_start_w = {64'b0, src_region_base_q}
                                + {64'b0, src_view_off_q};
        source_absolute_end_w = {64'b0, src_region_base_q}
                              + source_relative_end_w;
        destination_absolute_start_w = {64'b0, dst_region_base_q}
                                     + {64'b0, dst_view_off_q};
        destination_absolute_end_w = {64'b0, dst_region_base_q}
                                   + destination_relative_end_w;

        source_aligned_start_w = source_absolute_start_w;
        source_aligned_start_w[2:0] = 3'b000;
        source_aligned_end_w = source_absolute_end_w + 128'd7;
        source_aligned_end_w[2:0] = 3'b000;
        destination_aligned_start_w = destination_absolute_start_w;
        destination_aligned_start_w[2:0] = 3'b000;
        destination_aligned_end_w = destination_absolute_end_w + 128'd7;
        destination_aligned_end_w[2:0] = 3'b000;

        header_ok_w = (dtype_q == 8'h01)
                    && (gmem_floor_q < gmem_limit_q);
        profile_policy_ok_w = (profile_q == 8'h01)
                            && (rounding_mode_q == 3'b000)
                            && (denormal_mode_q == 2'b00)
                            && (nan_policy_q == 2'b00)
                            && dst_shadow_private_q;
        op_params_ok_w = (reserved_q == 32'b0)
                       && (op_params_q == 128'b0);
        shape_ok_w = (NE0 >= 2) && ((NE0 % 2) == 0)
                   && (NE1 >= 1) && (NE2 >= 1) && (NE3 >= 1)
                   && (src_ne0_q == NE0_U32)
                   && (src_ne1_q == NE1_U32)
                   && (src_ne2_q == NE2_U32)
                   && (src_ne3_q == NE3_U32)
                   && (dst_ne0_q == 32'd1)
                   && (dst_ne1_q == NE1_U32)
                   && (dst_ne2_q == NE2_U32)
                   && (dst_ne3_q == NE3_U32)
                   && (source_count_w != 128'b0)
                   && (row_count_w != 128'b0)
                   && (source_count_w[127:64] == 64'b0)
                   && (row_count_w[127:64] == 64'b0);
        stride_alignment_ok_w = (src_nb0_q == 64'd4)
                              && ({64'b0, src_nb1_q} == expected_src_nb1_w)
                              && ({64'b0, src_nb2_q} == expected_src_nb2_w)
                              && ({64'b0, src_nb3_q} == expected_src_nb3_w)
                              && (dst_nb0_q == 64'd4)
                              && (dst_nb1_q == 64'd4)
                              && ({64'b0, dst_nb2_q} == expected_dst_nb2_w)
                              && ({64'b0, dst_nb3_q} == expected_dst_nb3_w)
                              && (source_absolute_start_w[2:0] == 3'b000)
                              && (destination_absolute_start_w[1:0] == 2'b00);
        source_bounds_ok_w = (source_region_end_w[127:64] == 64'b0)
                           && (source_relative_end_w[127:64] == 64'b0)
                           && (source_absolute_start_w[127:64] == 64'b0)
                           && (source_absolute_end_w[127:64] == 64'b0)
                           && (source_aligned_end_w[127:64] == 64'b0)
                           && (source_relative_end_w
                               <= {64'b0, src_region_size_q})
                           && (source_aligned_start_w
                               >= {64'b0, src_region_base_q})
                           && (source_aligned_end_w <= source_region_end_w)
                           && (source_aligned_start_w >= {64'b0, gmem_floor_q})
                           && (source_aligned_end_w <= {64'b0, gmem_limit_q});
        destination_bounds_ok_w =
                              (destination_region_end_w[127:64] == 64'b0)
                           && (destination_relative_end_w[127:64] == 64'b0)
                           && (destination_absolute_start_w[127:64] == 64'b0)
                           && (destination_absolute_end_w[127:64] == 64'b0)
                           && (destination_aligned_end_w[127:64] == 64'b0)
                           && (destination_relative_end_w
                               <= {64'b0, dst_region_size_q})
                           && (destination_aligned_start_w
                               >= {64'b0, dst_region_base_q})
                           && (destination_aligned_end_w
                               <= destination_region_end_w)
                           && (destination_aligned_start_w
                               >= {64'b0, gmem_floor_q})
                           && (destination_aligned_end_w
                               <= {64'b0, gmem_limit_q});
        overlap_ok_w = (source_aligned_end_w <= destination_aligned_start_w)
                    || (destination_aligned_end_w <= source_aligned_start_w);

        if (!header_ok_w)
            preflight_error_w = ERR_HEADER;
        else if (!profile_policy_ok_w)
            preflight_error_w = ERR_PROFILE_POLICY;
        else if (!op_params_ok_w)
            preflight_error_w = ERR_OP_PARAMS;
        else if (!shape_ok_w)
            preflight_error_w = ERR_SHAPE;
        else if (!stride_alignment_ok_w)
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
    // Child instances and explicit owner matching.
    // ------------------------------------------------------------------
    wire        widen_req_ready_w;
    wire        widen_rsp_valid_w;
    wire [63:0] widen_result_w;
    wire [4:0]  widen_flags_w;
    wire        add_req_ready_w;
    wire        add_rsp_valid_w;
    wire [63:0] add_result_w;
    wire [4:0]  add_flags_w;
    wire        narrow_req_ready_w;
    wire        narrow_rsp_valid_w;
    wire [31:0] narrow_result_w;
    wire [4:0]  narrow_flags_w;

    wire widen_req_valid_w;
    wire add_req_valid_w;
    wire narrow_req_valid_w;
    wire widen_owner_match_w;
    wire add_owner_match_w;
    wire narrow_owner_match_w;
    wire widen_rsp_ready_w;
    wire add_rsp_ready_w;
    wire narrow_rsp_ready_w;
    wire widen_req_fire_w;
    wire add_req_fire_w;
    wire narrow_req_fire_w;
    wire widen_rsp_fire_w;
    wire add_rsp_fire_w;
    wire narrow_rsp_fire_w;

    // A held request is not withdrawn merely because its deadline counter has
    // reached the comparison value.  A real fire on that edge is accounted and
    // outranks timeout in the single fault selector below.
    assign widen_req_valid_w = !rst_i && (state_q == ST_WIDEN_REQ);
    assign add_req_valid_w = !rst_i && (state_q == ST_ADD_REQ);
    assign narrow_req_valid_w = !rst_i && (state_q == ST_NARROW_REQ);

    assign widen_owner_match_w = (state_q == ST_WIDEN_WAIT)
                               && widen_owner_valid_q
                               && (widen_owner_generation_q == generation_q)
                               && (widen_owner_row_q == row_index_q)
                               && (widen_owner_element_q == element_index_q);
    assign add_owner_match_w = (state_q == ST_ADD_WAIT)
                             && add_owner_valid_q
                             && (add_owner_generation_q == generation_q)
                             && (add_owner_row_q == row_index_q)
                             && (add_owner_element_q == element_index_q);
    assign narrow_owner_match_w = (state_q == ST_NARROW_WAIT)
                                && narrow_owner_valid_q
                                && (narrow_owner_generation_q == generation_q)
                                && (narrow_owner_row_q == row_index_q)
                                && (narrow_owner_element_q == NE0_U32);

    assign widen_rsp_ready_w = !rst_i && widen_owner_match_w;
    assign add_rsp_ready_w = !rst_i && add_owner_match_w;
    assign narrow_rsp_ready_w = !rst_i && narrow_owner_match_w;
    assign widen_req_fire_w = widen_req_valid_w && widen_req_ready_w;
    assign add_req_fire_w = add_req_valid_w && add_req_ready_w;
    assign narrow_req_fire_w = narrow_req_valid_w && narrow_req_ready_w;
    assign widen_rsp_fire_w = widen_rsp_valid_w && widen_rsp_ready_w;
    assign add_rsp_fire_w = add_rsp_valid_w && add_rsp_ready_w;
    assign narrow_rsp_fire_w = narrow_rsp_valid_w && narrow_rsp_ready_w;

    TensorNpuFp32ToFp64Ieee u_widen (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (widen_req_valid_w),
        .req_ready_o (widen_req_ready_w),
        .operand_i   (row_buffer_q[element_array_index_w]),
        .rsp_valid_o (widen_rsp_valid_w),
        .rsp_ready_i (widen_rsp_ready_w),
        .result_o    (widen_result_w),
        .flags_o     (widen_flags_w)
    );

    TensorNpuFp64AddIeee u_add (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (add_req_valid_w),
        .req_ready_o (add_req_ready_w),
        .operand_a_i (accumulator_q),
        .operand_b_i (widened_term_q),
        .rsp_valid_o (add_rsp_valid_w),
        .rsp_ready_i (add_rsp_ready_w),
        .result_o    (add_result_w),
        .flags_o     (add_flags_w)
    );

    TensorNpuFp64ToFp32Ieee u_narrow (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (narrow_req_valid_w),
        .req_ready_o (narrow_req_ready_w),
        .operand_i   (accumulator_q),
        .rsp_valid_o (narrow_rsp_valid_w),
        .rsp_ready_i (narrow_rsp_ready_w),
        .result_o    (narrow_result_w),
        .flags_o     (narrow_flags_w)
    );

    // A true production predicate sampled before the fault edge.  The TB uses
    // these wires as witnesses; it does not infer injection from terminal state.
    wire widen_owner_fault_w;
    wire add_owner_fault_w;
    wire narrow_owner_fault_w;
    wire child_owner_fault_w;
    assign widen_owner_fault_w = widen_rsp_valid_w
                               && (state_q != ST_CHILD_QUARANTINE)
                               && (state_q != ST_GMEM_DRAIN)
                               && (state_q != ST_POISON_ERROR)
                               && (state_q != ST_POISON)
                               && (state_q != ST_STRAY_GMEM_DROP)
                               && !widen_owner_match_w;
    assign add_owner_fault_w = add_rsp_valid_w
                             && (state_q != ST_CHILD_QUARANTINE)
                             && (state_q != ST_GMEM_DRAIN)
                             && (state_q != ST_POISON_ERROR)
                             && (state_q != ST_POISON)
                             && (state_q != ST_STRAY_GMEM_DROP)
                             && !add_owner_match_w;
    assign narrow_owner_fault_w = narrow_rsp_valid_w
                                && (state_q != ST_CHILD_QUARANTINE)
                                && (state_q != ST_GMEM_DRAIN)
                                && (state_q != ST_POISON_ERROR)
                                && (state_q != ST_POISON)
                                && (state_q != ST_STRAY_GMEM_DROP)
                                && !narrow_owner_match_w;
    assign child_owner_fault_w = widen_owner_fault_w
                               || add_owner_fault_w
                               || narrow_owner_fault_w;

    // ------------------------------------------------------------------
    // Shared GMEM request and owner matching.
    // ------------------------------------------------------------------
    wire gmem_owner_match_w;
    wire gmem_owner_fault_w;
    wire gmem_fatal_match_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;
    wire gmem_owner_rsp_fire_w;
    wire gmem_stray_rsp_fire_w;
    wire gmem_ownerless_request_collision_w;

    assign gmem_request_state_w = (state_q == ST_ROW_READ_REQ)
                                || (state_q == ST_PUBLISH_REQ);
    assign gmem_req_valid_o = !rst_i && gmem_request_state_w;
    assign gmem_req_write_o = gmem_req_write_q;
    assign gmem_req_addr_o  = gmem_req_addr_q;
    assign gmem_req_wdata_o = gmem_req_wdata_q;
    assign gmem_req_wstrb_o = gmem_req_wstrb_q;
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;

    assign gmem_owner_match_w = gmem_owner_valid_q
                              && (gmem_owner_generation_q == generation_q)
                              && (((state_q == ST_ROW_READ_WAIT)
                                   && !gmem_owner_write_q
                                   && (gmem_owner_row_q == row_index_q)
                                   && (gmem_owner_index_q == read_beat_q))
                               || ((state_q == ST_PUBLISH_WAIT)
                                   && gmem_owner_write_q
                                   && (gmem_owner_row_q == publish_index_q)
                                   && (gmem_owner_index_q == publish_index_q))
                               || ((state_q == ST_GMEM_DRAIN)
                                   && ((!gmem_owner_write_q
                                        && (gmem_owner_row_q == row_index_q)
                                        && (gmem_owner_index_q == read_beat_q))
                                       || (gmem_owner_write_q
                                           && (gmem_owner_row_q
                                               == publish_index_q)
                                           && (gmem_owner_index_q
                                               == publish_index_q)))));

    // A matching response is always credited, including on the deadline edge.
    // An error response is selected ahead of a successful response by the
    // first-fault arbiter; timeout is selected only when no phase fire exists.
    assign gmem_rsp_ready_o = !rst_i
                            && (gmem_owner_match_w
                                || (state_q == ST_STRAY_GMEM_DROP));
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;
    assign gmem_owner_rsp_fire_w = gmem_rsp_valid_i
                                 && gmem_owner_match_w;
    assign gmem_stray_rsp_fire_w = gmem_rsp_valid_i
                                 && (state_q == ST_STRAY_GMEM_DROP);
    assign gmem_fatal_match_w = gmem_rsp_valid_i
                              && gmem_owner_match_w
                              && gmem_rsp_error_i;
    assign gmem_owner_fault_w = gmem_rsp_valid_i
                              && (state_q != ST_GMEM_DRAIN)
                              && (state_q != ST_CHILD_QUARANTINE)
                              && (state_q != ST_POISON_ERROR)
                              && (state_q != ST_POISON)
                              && (state_q != ST_STRAY_GMEM_DROP)
                              && !gmem_owner_match_w;
    // The response ABI has no transaction tag.  If an old ownerless response
    // is sampled on the same edge as a real request fire, transport accounting
    // must retain the new request while the old level is permanently denied
    // semantic/DRAIN credit until reset.  This event is intentionally
    // independent of fault_capture_event_w: a prior first cause may already be
    // resident when an abort-held request eventually collides with a ghost.
    assign gmem_ownerless_request_collision_w = txn_active_q
                                              && gmem_request_state_w
                                              && !gmem_owner_valid_q
                                              && gmem_req_fire_w
                                              && gmem_owner_fault_w;
    assign ingress_owner_fault_w = gmem_owner_fault_w
                                 || child_owner_fault_w;

    // ------------------------------------------------------------------
    // Single first-fault selector and post-fire ledger view.
    // ------------------------------------------------------------------
    wire state_legal_w;
    wire [1:0] child_owner_count_w;
    wire ledger_corrupt_w;
    wire internal_fault_w;
    wire [4:0] flags_after_events_w;
    wire [63:0] request_events_after_w;
    wire [63:0] response_events_after_w;
    wire [63:0] active_cycles_after_w;
    wire [63:0] fault_gmem_addr_w;
    wire        fault_capture_event_w;
    wire        retired_cleanup_event_w;
    wire        fault_enters_abort_hold_w;
    reg         fault_detect_w;
    reg [4:0]   fault_code_w;
    reg [2:0]   fault_resource_w;
    reg [2:0]   fault_owner_type_w;
    reg         fault_owner_valid_w;
    reg         fault_owner_generation_w;
    reg [31:0]  fault_owner_row_w;
    reg [31:0]  fault_owner_index_w;

    assign phase_fire_w = gmem_req_fire_w || gmem_rsp_fire_w
                        || widen_req_fire_w || widen_rsp_fire_w
                        || add_req_fire_w || add_rsp_fire_w
                        || narrow_req_fire_w || narrow_rsp_fire_w;
    assign held_request_fire_w = ((state_q == ST_ROW_READ_REQ)
                                  || (state_q == ST_PUBLISH_REQ))
                               ? gmem_req_fire_w
                               : ((state_q == ST_WIDEN_REQ)
                                  ? widen_req_fire_w
                                  : ((state_q == ST_ADD_REQ)
                                     ? add_req_fire_w
                                     : ((state_q == ST_NARROW_REQ)
                                        ? narrow_req_fire_w : 1'b0)));
    assign state_legal_w = (state_q == ST_IDLE)
                         || (state_q == ST_PREFLIGHT)
                         || (state_q == ST_ROW_READ_PREP)
                         || (state_q == ST_ROW_READ_REQ)
                         || (state_q == ST_ROW_READ_WAIT)
                         || (state_q == ST_WIDEN_REQ)
                         || (state_q == ST_WIDEN_WAIT)
                         || (state_q == ST_ADD_REQ)
                         || (state_q == ST_ADD_WAIT)
                         || (state_q == ST_NARROW_REQ)
                         || (state_q == ST_NARROW_WAIT)
                         || (state_q == ST_PUBLISH_PREP)
                         || (state_q == ST_PUBLISH_REQ)
                         || (state_q == ST_PUBLISH_WAIT)
                         || (state_q == ST_GMEM_DRAIN)
                         || (state_q == ST_CHILD_QUARANTINE)
                         || (state_q == ST_DONE)
                         || (state_q == ST_ERROR)
                         || (state_q == ST_POISON_ERROR)
                         || (state_q == ST_POISON)
                         || (state_q == ST_STRAY_GMEM_DROP);
    assign child_owner_count_w = {1'b0, widen_owner_valid_q}
                               + {1'b0, add_owner_valid_q}
                               + {1'b0, narrow_owner_valid_q};
    assign ledger_corrupt_w = (gmem_read_responses_q
                                > gmem_read_requests_q)
                           || (gmem_write_responses_q
                                > gmem_write_requests_q)
                           || (widen_responses_q > widen_requests_q)
                           || (add_responses_q > add_requests_q)
                           || (narrow_responses_q > narrow_requests_q)
                           || (child_owner_count_w > 2'd1);
    assign internal_fault_w = !state_legal_w || ledger_corrupt_w;

    assign flags_after_events_w = flags_q
                                | (widen_rsp_fire_w ? widen_flags_w : 5'b0)
                                | (add_rsp_fire_w ? add_flags_w : 5'b0)
                                | (narrow_rsp_fire_w ? narrow_flags_w : 5'b0);
    assign request_events_after_w = gmem_read_requests_q
                                  + gmem_write_requests_q
                                  + widen_requests_q
                                  + add_requests_q
                                  + narrow_requests_q
                                  + ((gmem_req_fire_w
                                      && !gmem_req_write_q) ? 64'd1 : 64'd0)
                                  + ((gmem_req_fire_w
                                      && gmem_req_write_q) ? 64'd1 : 64'd0)
                                  + (widen_req_fire_w ? 64'd1 : 64'd0)
                                  + (add_req_fire_w ? 64'd1 : 64'd0)
                                  + (narrow_req_fire_w ? 64'd1 : 64'd0);
    assign response_events_after_w = gmem_read_responses_q
                                   + gmem_write_responses_q
                                   + widen_responses_q
                                   + add_responses_q
                                   + narrow_responses_q
                                   + ((gmem_owner_rsp_fire_w
                                       && !gmem_owner_write_q)
                                      ? 64'd1 : 64'd0)
                                   + ((gmem_owner_rsp_fire_w
                                       && gmem_owner_write_q)
                                      ? 64'd1 : 64'd0)
                                   + (widen_rsp_fire_w ? 64'd1 : 64'd0)
                                   + (add_rsp_fire_w ? 64'd1 : 64'd0)
                                   + (narrow_rsp_fire_w ? 64'd1 : 64'd0);
    assign active_cycles_after_w = active_cycles_q
                                 + (((state_q != ST_IDLE)
                                     && (state_q != ST_DONE)
                                     && (state_q != ST_ERROR)
                                     && (state_q != ST_POISON_ERROR)
                                     && (state_q != ST_POISON))
                                    ? 64'd1 : 64'd0);

    // A diagnostic address may only come from a live GMEM obligation.  An
    // exposed request (including a request firing on the fault edge) has
    // priority over an already accepted owner.  With neither obligation,
    // stale payload left by an earlier transaction is deliberately hidden.
    assign fault_gmem_addr_w = gmem_request_state_w
                             ? gmem_req_addr_q
                             : (gmem_owner_valid_q
                                ? gmem_owner_addr_q : 64'b0);

    assign fault_capture_event_w = fault_detect_w
                                 && txn_active_q
                                 && !fault_latched_q
                                 && !terminal_state_w;
    assign retired_cleanup_event_w = ingress_owner_fault_w
                                   && (!txn_active_q || terminal_state_w);
    assign fault_enters_abort_hold_w = fault_capture_event_w
                                     && request_hold_state_w
                                     && !held_request_fire_w;

    always @(*) begin
        fault_detect_w   = 1'b0;
        fault_code_w     = ERR_NONE;
        fault_resource_w = FAULT_RESOURCE_CONTROL;
        if (!rst_i && internal_fault_w) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = ERR_INTERNAL_STATE;
            fault_resource_w = FAULT_RESOURCE_CONTROL;
        end else if (!rst_i && gmem_owner_fault_w) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = ERR_PROTOCOL_OWNER;
            fault_resource_w = FAULT_RESOURCE_GMEM;
        end else if (!rst_i && child_owner_fault_w) begin
            fault_detect_w = 1'b1;
            fault_code_w   = ERR_CHILD_RESPONSE;
            if (widen_owner_fault_w)
                fault_resource_w = FAULT_RESOURCE_WIDEN;
            else if (add_owner_fault_w)
                fault_resource_w = FAULT_RESOURCE_ADD;
            else
                fault_resource_w = FAULT_RESOURCE_NARROW;
        end else if (!rst_i && gmem_fatal_match_w
                && (state_q != ST_GMEM_DRAIN)) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = ERR_GMEM_RESPONSE;
            fault_resource_w = FAULT_RESOURCE_GMEM;
        end else if (!rst_i && (state_q == ST_PREFLIGHT)
                && (preflight_error_w != ERR_NONE)) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = preflight_error_w;
            fault_resource_w = FAULT_RESOURCE_CONTROL;
        end else if (!rst_i && command_timeout_hit_w
                && !phase_fire_w) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = ERR_COMMAND_TIMEOUT;
            fault_resource_w = FAULT_RESOURCE_CONTROL;
        end else if (!rst_i && stall_timeout_hit_w
                && !phase_fire_w) begin
            fault_detect_w   = 1'b1;
            fault_code_w     = ERR_STALL_TIMEOUT;
            fault_resource_w = FAULT_RESOURCE_CONTROL;
        end
    end

    // Post-fire owner identity for the first-fault record.  A response fire
    // reports the consumed owner type/identity with owner-valid cleared; a
    // request fire reports the newly established owner.
    always @(*) begin
        fault_owner_type_w       = OWNER_NONE;
        fault_owner_valid_w      = 1'b0;
        fault_owner_generation_w = 1'b0;
        fault_owner_row_w        = 32'b0;
        fault_owner_index_w      = 32'b0;
        if (gmem_req_fire_w) begin
            fault_owner_type_w = gmem_req_write_q
                               ? OWNER_GMEM_WRITE : OWNER_GMEM_READ;
            fault_owner_valid_w = 1'b1;
            fault_owner_generation_w = generation_q;
            fault_owner_row_w = gmem_req_write_q
                              ? publish_index_q : row_index_q;
            fault_owner_index_w = gmem_req_write_q
                                ? publish_index_q : read_beat_q;
        end else if (gmem_owner_rsp_fire_w) begin
            fault_owner_type_w = gmem_owner_write_q
                               ? OWNER_GMEM_WRITE : OWNER_GMEM_READ;
            fault_owner_generation_w = gmem_owner_generation_q;
            fault_owner_row_w = gmem_owner_row_q;
            fault_owner_index_w = gmem_owner_index_q;
        end else if (widen_req_fire_w) begin
            fault_owner_type_w       = OWNER_WIDEN;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = generation_q;
            fault_owner_row_w        = row_index_q;
            fault_owner_index_w      = element_index_q;
        end else if (widen_rsp_fire_w) begin
            fault_owner_type_w       = OWNER_WIDEN;
            fault_owner_generation_w = widen_owner_generation_q;
            fault_owner_row_w        = widen_owner_row_q;
            fault_owner_index_w      = widen_owner_element_q;
        end else if (add_req_fire_w) begin
            fault_owner_type_w       = OWNER_ADD;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = generation_q;
            fault_owner_row_w        = row_index_q;
            fault_owner_index_w      = element_index_q;
        end else if (add_rsp_fire_w) begin
            fault_owner_type_w       = OWNER_ADD;
            fault_owner_generation_w = add_owner_generation_q;
            fault_owner_row_w        = add_owner_row_q;
            fault_owner_index_w      = add_owner_element_q;
        end else if (narrow_req_fire_w) begin
            fault_owner_type_w       = OWNER_NARROW;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = generation_q;
            fault_owner_row_w        = row_index_q;
            fault_owner_index_w      = NE0_U32;
        end else if (narrow_rsp_fire_w) begin
            fault_owner_type_w       = OWNER_NARROW;
            fault_owner_generation_w = narrow_owner_generation_q;
            fault_owner_row_w        = narrow_owner_row_q;
            fault_owner_index_w      = narrow_owner_element_q;
        end else if (gmem_owner_valid_q) begin
            fault_owner_type_w = gmem_owner_write_q
                               ? OWNER_GMEM_WRITE : OWNER_GMEM_READ;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = gmem_owner_generation_q;
            fault_owner_row_w        = gmem_owner_row_q;
            fault_owner_index_w      = gmem_owner_index_q;
        end else if (widen_owner_valid_q) begin
            fault_owner_type_w       = OWNER_WIDEN;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = widen_owner_generation_q;
            fault_owner_row_w        = widen_owner_row_q;
            fault_owner_index_w      = widen_owner_element_q;
        end else if (add_owner_valid_q) begin
            fault_owner_type_w       = OWNER_ADD;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = add_owner_generation_q;
            fault_owner_row_w        = add_owner_row_q;
            fault_owner_index_w      = add_owner_element_q;
        end else if (narrow_owner_valid_q) begin
            fault_owner_type_w       = OWNER_NARROW;
            fault_owner_valid_w      = 1'b1;
            fault_owner_generation_w = narrow_owner_generation_q;
            fault_owner_row_w        = narrow_owner_row_q;
            fault_owner_index_w      = narrow_owner_element_q;
        end
    end

    // A progress pulse is only watchdog accounting.  Semantic counters below
    // are always driven directly by their matching handshakes.
    wire progress_w;
    wire [63:0] publish_byte_address_w;
    assign publish_byte_address_w = dst_region_base_q + dst_view_off_q
                                  + ({32'b0, publish_index_q} * 64'd4);
    assign progress_w = (state_q == ST_PREFLIGHT)
                      || (state_q == ST_ROW_READ_PREP)
                      || (state_q == ST_PUBLISH_PREP)
                      || gmem_req_fire_w
                      || gmem_rsp_fire_w
                      || widen_req_fire_w
                      || widen_rsp_fire_w
                      || add_req_fire_w
                      || add_rsp_fire_w
                      || narrow_req_fire_w
                      || narrow_rsp_fire_w;

    // ------------------------------------------------------------------
    // Parent state, owners, buffers, counters and terminal pulses.
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                    <= ST_IDLE;
            dtype_q                    <= 8'b0;
            profile_q                  <= 8'b0;
            rounding_mode_q            <= 3'b0;
            denormal_mode_q            <= 2'b0;
            nan_policy_q               <= 2'b0;
            dst_shadow_private_q       <= 1'b0;
            reserved_q                 <= 32'b0;
            op_params_q                <= 128'b0;
            gmem_floor_q               <= 64'b0;
            gmem_limit_q               <= 64'b0;
            src_region_base_q          <= 64'b0;
            src_region_size_q          <= 64'b0;
            src_view_off_q             <= 64'b0;
            src_ne0_q                  <= 32'b0;
            src_ne1_q                  <= 32'b0;
            src_ne2_q                  <= 32'b0;
            src_ne3_q                  <= 32'b0;
            src_nb0_q                  <= 64'b0;
            src_nb1_q                  <= 64'b0;
            src_nb2_q                  <= 64'b0;
            src_nb3_q                  <= 64'b0;
            dst_region_base_q          <= 64'b0;
            dst_region_size_q          <= 64'b0;
            dst_view_off_q             <= 64'b0;
            dst_ne0_q                  <= 32'b0;
            dst_ne1_q                  <= 32'b0;
            dst_ne2_q                  <= 32'b0;
            dst_ne3_q                  <= 32'b0;
            dst_nb0_q                  <= 64'b0;
            dst_nb1_q                  <= 64'b0;
            dst_nb2_q                  <= 64'b0;
            dst_nb3_q                  <= 64'b0;
            txn_tag_q                  <= 32'b0;
            generation_q               <= 1'b0;
            row_index_q                <= 32'b0;
            read_beat_q                <= 32'b0;
            element_index_q            <= 32'b0;
            publish_index_q            <= 32'b0;
            accumulator_q              <= 64'b0;
            widened_term_q             <= 64'b0;
            gmem_req_addr_q             <= 64'b0;
            gmem_req_wdata_q            <= 64'b0;
            gmem_req_wstrb_q            <= 8'b0;
            gmem_req_write_q            <= 1'b0;
            gmem_owner_valid_q          <= 1'b0;
            gmem_owner_addr_q           <= 64'b0;
            gmem_owner_write_q          <= 1'b0;
            gmem_owner_generation_q     <= 1'b0;
            gmem_owner_row_q            <= 32'b0;
            gmem_owner_index_q          <= 32'b0;
            widen_owner_valid_q         <= 1'b0;
            widen_owner_generation_q    <= 1'b0;
            widen_owner_row_q           <= 32'b0;
            widen_owner_element_q       <= 32'b0;
            add_owner_valid_q           <= 1'b0;
            add_owner_generation_q      <= 1'b0;
            add_owner_row_q             <= 32'b0;
            add_owner_element_q         <= 32'b0;
            narrow_owner_valid_q        <= 1'b0;
            narrow_owner_generation_q   <= 1'b0;
            narrow_owner_row_q          <= 32'b0;
            narrow_owner_element_q      <= 32'b0;
            stall_cycles_q              <= 64'b0;
            command_cycles_q            <= 64'b0;
            drain_cycles_q              <= 64'b0;
            abort_hold_cycles_q          <= 64'b0;
            error_code_q                <= ERR_NONE;
            flags_q                     <= 5'b0;
            rows_reduced_q              <= 64'b0;
            elements_processed_q        <= 64'b0;
            gmem_read_requests_q        <= 64'b0;
            gmem_read_responses_q       <= 64'b0;
            gmem_write_requests_q       <= 64'b0;
            gmem_write_responses_q      <= 64'b0;
            widen_requests_q            <= 64'b0;
            widen_responses_q           <= 64'b0;
            add_requests_q              <= 64'b0;
            add_responses_q             <= 64'b0;
            narrow_requests_q           <= 64'b0;
            narrow_responses_q          <= 64'b0;
            active_cycles_q             <= 64'b0;
            fault_latched_q             <= 1'b0;
            txn_active_q                <= 1'b0;
            abort_hold_q                <= 1'b0;
            collision_poison_q           <= 1'b0;
            abort_hold_poison_q          <= 1'b0;
            cleanup_suppress_terminal_q <= 1'b0;
            first_fault_cycle_q         <= 64'b0;
            first_fault_coordinate_q    <= 128'b0;
            first_fault_gmem_addr_q     <= 64'b0;
            first_fault_flags_q         <= 5'b0;
            first_fault_request_events_q <= 64'b0;
            first_fault_response_events_q <= 64'b0;
            first_fault_txn_tag_q        <= 32'b0;
            first_fault_generation_q     <= 1'b0;
            first_fault_resource_q       <= FAULT_RESOURCE_CONTROL;
            first_fault_owner_type_q     <= OWNER_NONE;
            first_fault_owner_valid_q    <= 1'b0;
            first_fault_owner_generation_q <= 1'b0;
            first_fault_owner_row_q      <= 32'b0;
            first_fault_owner_index_q    <= 32'b0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (state_q != ST_POISON_ERROR)
                    && (state_q != ST_POISON)
                    && !reset_only_poison_w)
                active_cycles_q <= active_cycles_q + 64'd1;

            if (operational_state_w) begin
                command_cycles_q <= command_cycles_q + 64'd1;
                if (progress_w)
                    stall_cycles_q <= 64'b0;
                else
                    stall_cycles_q <= stall_cycles_q + 64'd1;
            end

            if ((state_q == ST_GMEM_DRAIN)
                    || (state_q == ST_STRAY_GMEM_DROP))
                drain_cycles_q <= drain_cycles_q + 64'd1;

            // Retired/no-active ghosts are cleanup events, never a new
            // transaction fault.  They preserve the prior diagnostic record
            // and cannot create another terminal pulse.
            if (retired_cleanup_event_w) begin
                state_q                     <= ST_CHILD_QUARANTINE;
                cleanup_suppress_terminal_q <= 1'b1;
                txn_active_q                <= 1'b0;
                abort_hold_q                <= 1'b0;
                abort_hold_cycles_q         <= 64'b0;
                stall_cycles_q              <= 64'b0;
                drain_cycles_q              <= 64'b0;
            // Only the first active-transaction edge captures the fault.  A
            // held request remains in its request state until a true fire.
            end else if (fault_capture_event_w) begin
                fault_latched_q  <= 1'b1;
                error_code_q     <= fault_code_w;
                abort_hold_q     <= fault_enters_abort_hold_w;
                abort_hold_cycles_q <= 64'b0;
                stall_cycles_q   <= 64'b0;
                drain_cycles_q   <= 64'b0;
                first_fault_cycle_q <= active_cycles_after_w;
                first_fault_coordinate_q <= {
                    row_index_q,
                    read_beat_q,
                    element_index_q,
                    publish_index_q
                };
                first_fault_gmem_addr_q <= fault_gmem_addr_w;
                first_fault_flags_q <= flags_after_events_w;
                first_fault_request_events_q <= request_events_after_w;
                first_fault_response_events_q <= response_events_after_w;
                first_fault_txn_tag_q <= txn_tag_q;
                first_fault_generation_q <= generation_q;
                first_fault_resource_q <= fault_resource_w;
                first_fault_owner_type_q <= fault_owner_type_w;
                first_fault_owner_valid_q <= fault_owner_valid_w;
                first_fault_owner_generation_q
                    <= fault_owner_generation_w;
                first_fault_owner_row_q <= fault_owner_row_w;
                first_fault_owner_index_q <= fault_owner_index_w;
                if (!fault_enters_abort_hold_w)
                    state_q <= ST_CHILD_QUARANTINE;
            // Once abort is latched, watchdogs cannot cancel the exposed
            // request.  The exact real fire is accounted by the common
            // transport writer below before quarantine begins.
            end else if (abort_hold_q) begin
                stall_cycles_q   <= stall_cycles_q;
                command_cycles_q <= command_cycles_q;
                if (held_request_fire_w) begin
                    abort_hold_q   <= 1'b0;
                    abort_hold_cycles_q <= 64'b0;
                    state_q        <= ST_CHILD_QUARANTINE;
                    stall_cycles_q <= 64'b0;
                    drain_cycles_q <= 64'b0;
                end else if (!abort_hold_poison_q
                        && abort_hold_timeout_hit_w) begin
                    // Poison visibility is bounded, but poison is not request
                    // cancellation: state and the complete held payload remain
                    // unchanged until a real fire or reset.
                    abort_hold_poison_q <= 1'b1;
                    abort_hold_cycles_q <= abort_hold_cycles_q;
                end else if (!abort_hold_poison_q) begin
                    abort_hold_cycles_q <= abort_hold_cycles_q + 64'd1;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        stall_cycles_q   <= 64'b0;
                        command_cycles_q <= 64'b0;
                        drain_cycles_q   <= 64'b0;
                        abort_hold_cycles_q <= 64'b0;
                        error_code_q     <= ERR_NONE;
                        if (start_fire_w) begin
                            dtype_q                <= dtype_i;
                            profile_q              <= profile_i;
                            rounding_mode_q        <= rounding_mode_i;
                            denormal_mode_q        <= denormal_mode_i;
                            nan_policy_q           <= nan_policy_i;
                            dst_shadow_private_q   <= dst_shadow_private_i;
                            reserved_q             <= reserved_i;
                            op_params_q            <= op_params_i;
                            gmem_floor_q           <= gmem_floor_i;
                            gmem_limit_q           <= gmem_limit_i;
                            src_region_base_q      <= src_region_base_i;
                            src_region_size_q      <= src_region_size_i;
                            src_view_off_q         <= src_view_off_i;
                            src_ne0_q              <= src_ne0_i;
                            src_ne1_q              <= src_ne1_i;
                            src_ne2_q              <= src_ne2_i;
                            src_ne3_q              <= src_ne3_i;
                            src_nb0_q              <= src_nb0_i;
                            src_nb1_q              <= src_nb1_i;
                            src_nb2_q              <= src_nb2_i;
                            src_nb3_q              <= src_nb3_i;
                            dst_region_base_q      <= dst_region_base_i;
                            dst_region_size_q      <= dst_region_size_i;
                            dst_view_off_q         <= dst_view_off_i;
                            dst_ne0_q              <= dst_ne0_i;
                            dst_ne1_q              <= dst_ne1_i;
                            dst_ne2_q              <= dst_ne2_i;
                            dst_ne3_q              <= dst_ne3_i;
                            dst_nb0_q              <= dst_nb0_i;
                            dst_nb1_q              <= dst_nb1_i;
                            dst_nb2_q              <= dst_nb2_i;
                            dst_nb3_q              <= dst_nb3_i;
                            txn_tag_q              <= txn_tag_i;
                            generation_q           <= ~generation_q;
                            txn_active_q            <= 1'b1;
                            abort_hold_q            <= 1'b0;
                            abort_hold_cycles_q     <= 64'b0;
                            row_index_q            <= 32'b0;
                            read_beat_q            <= 32'b0;
                            element_index_q        <= 32'b0;
                            publish_index_q        <= 32'b0;
                            accumulator_q          <= 64'b0;
                            widened_term_q         <= 64'b0;
                            gmem_owner_valid_q     <= 1'b0;
                            gmem_owner_addr_q      <= 64'b0;
                            widen_owner_valid_q    <= 1'b0;
                            add_owner_valid_q      <= 1'b0;
                            narrow_owner_valid_q   <= 1'b0;
                            flags_q                 <= 5'b0;
                            rows_reduced_q          <= 64'b0;
                            elements_processed_q   <= 64'b0;
                            gmem_read_requests_q   <= 64'b0;
                            gmem_read_responses_q  <= 64'b0;
                            gmem_write_requests_q  <= 64'b0;
                            gmem_write_responses_q <= 64'b0;
                            widen_requests_q       <= 64'b0;
                            widen_responses_q      <= 64'b0;
                            add_requests_q         <= 64'b0;
                            add_responses_q        <= 64'b0;
                            narrow_requests_q      <= 64'b0;
                            narrow_responses_q     <= 64'b0;
                            active_cycles_q        <= 64'b0;
                            fault_latched_q        <= 1'b0;
                            cleanup_suppress_terminal_q <= 1'b0;
                            first_fault_cycle_q    <= 64'b0;
                            first_fault_coordinate_q <= 128'b0;
                            first_fault_gmem_addr_q <= 64'b0;
                            first_fault_flags_q    <= 5'b0;
                            first_fault_request_events_q <= 64'b0;
                            first_fault_response_events_q <= 64'b0;
                            first_fault_txn_tag_q   <= 32'b0;
                            first_fault_generation_q <= 1'b0;
                            first_fault_resource_q <= FAULT_RESOURCE_CONTROL;
                            first_fault_owner_type_q <= OWNER_NONE;
                            first_fault_owner_valid_q <= 1'b0;
                            first_fault_owner_generation_q <= 1'b0;
                            first_fault_owner_row_q <= 32'b0;
                            first_fault_owner_index_q <= 32'b0;
                            state_q                 <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        stall_cycles_q <= 64'b0;
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q      <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else begin
                            row_index_q     <= 32'b0;
                            read_beat_q     <= 32'b0;
                            element_index_q <= 32'b0;
                            state_q         <= ST_ROW_READ_PREP;
                        end
                    end

                    ST_ROW_READ_PREP: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else begin
                            gmem_req_addr_q <= src_region_base_q
                                             + src_view_off_q
                                             + ({32'b0, row_index_q}
                                                * src_nb1_q)
                                             + ({32'b0, read_beat_q}
                                                * 64'd8);
                            gmem_req_wdata_q <= 64'b0;
                            gmem_req_wstrb_q <= 8'b0;
                            gmem_req_write_q <= 1'b0;
                            stall_cycles_q   <= 64'b0;
                            state_q          <= ST_ROW_READ_REQ;
                        end
                    end

                    ST_ROW_READ_REQ: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else if (gmem_req_fire_w) begin
                            gmem_owner_valid_q      <= 1'b1;
                            gmem_owner_write_q      <= 1'b0;
                            gmem_owner_generation_q <= generation_q;
                            gmem_owner_row_q        <= row_index_q;
                            gmem_owner_index_q      <= read_beat_q;
                            gmem_read_requests_q    <= gmem_read_requests_q
                                                     + 64'd1;
                            stall_cycles_q          <= 64'b0;
                            state_q                 <= ST_ROW_READ_WAIT;
                        end
                    end

                    ST_ROW_READ_WAIT: begin
                        if (command_timeout_hit_w) begin
                            error_code_q   <= ERR_COMMAND_TIMEOUT;
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q   <= ERR_STALL_TIMEOUT;
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (gmem_rsp_fire_w) begin
                            row_buffer_q[read_even_array_index_w]
                                <= gmem_rsp_rdata_i[31:0];
                            row_buffer_q[read_odd_array_index_w]
                                <= gmem_rsp_rdata_i[63:32];
                            gmem_owner_valid_q    <= 1'b0;
                            gmem_read_responses_q <= gmem_read_responses_q
                                                   + 64'd1;
                            stall_cycles_q        <= 64'b0;
                            if (read_beat_q == (READ_BEATS_U32 - 32'd1)) begin
                                read_beat_q     <= 32'b0;
                                element_index_q <= 32'b0;
                                accumulator_q   <= 64'b0;
                                state_q         <= ST_WIDEN_REQ;
                            end else begin
                                read_beat_q <= read_beat_q + 32'd1;
                                state_q     <= ST_ROW_READ_PREP;
                            end
                        end
                    end

                    ST_WIDEN_REQ: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (widen_req_fire_w) begin
                            widen_owner_valid_q      <= 1'b1;
                            widen_owner_generation_q <= generation_q;
                            widen_owner_row_q        <= row_index_q;
                            widen_owner_element_q    <= element_index_q;
                            widen_requests_q         <= widen_requests_q + 64'd1;
                            stall_cycles_q           <= 64'b0;
                            state_q                  <= ST_WIDEN_WAIT;
                        end
                    end

                    ST_WIDEN_WAIT: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (widen_rsp_fire_w) begin
                            widen_owner_valid_q <= 1'b0;
                            widened_term_q      <= widen_result_w;
                            flags_q             <= flags_q | widen_flags_w;
                            widen_responses_q   <= widen_responses_q + 64'd1;
                            stall_cycles_q      <= 64'b0;
                            state_q             <= ST_ADD_REQ;
                        end
                    end

                    ST_ADD_REQ: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (add_req_fire_w) begin
                            add_owner_valid_q      <= 1'b1;
                            add_owner_generation_q <= generation_q;
                            add_owner_row_q        <= row_index_q;
                            add_owner_element_q    <= element_index_q;
                            add_requests_q         <= add_requests_q + 64'd1;
                            stall_cycles_q         <= 64'b0;
                            state_q                <= ST_ADD_WAIT;
                        end
                    end

                    ST_ADD_WAIT: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (add_rsp_fire_w) begin
                            add_owner_valid_q    <= 1'b0;
                            accumulator_q        <= add_result_w;
                            flags_q              <= flags_q | add_flags_w;
                            add_responses_q      <= add_responses_q + 64'd1;
                            elements_processed_q <= elements_processed_q + 64'd1;
                            stall_cycles_q       <= 64'b0;
                            if (element_index_q == (NE0_U32 - 32'd1)) begin
                                state_q <= ST_NARROW_REQ;
                            end else begin
                                element_index_q <= element_index_q + 32'd1;
                                state_q         <= ST_WIDEN_REQ;
                            end
                        end
                    end

                    ST_NARROW_REQ: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (narrow_req_fire_w) begin
                            narrow_owner_valid_q      <= 1'b1;
                            narrow_owner_generation_q <= generation_q;
                            narrow_owner_row_q        <= row_index_q;
                            narrow_owner_element_q    <= NE0_U32;
                            narrow_requests_q         <= narrow_requests_q + 64'd1;
                            stall_cycles_q            <= 64'b0;
                            state_q                   <= ST_NARROW_WAIT;
                        end
                    end

                    ST_NARROW_WAIT: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_CHILD_QUARANTINE;
                        end else if (narrow_rsp_fire_w) begin
                            narrow_owner_valid_q       <= 1'b0;
                            result_buffer_q[row_array_index_w]
                                <= narrow_result_w;
                            flags_q                    <= flags_q | narrow_flags_w;
                            narrow_responses_q         <= narrow_responses_q + 64'd1;
                            rows_reduced_q             <= rows_reduced_q + 64'd1;
                            stall_cycles_q             <= 64'b0;
                            if (row_index_q == (ROWS_U32 - 32'd1)) begin
                                publish_index_q <= 32'b0;
                                state_q         <= ST_PUBLISH_PREP;
                            end else begin
                                row_index_q     <= row_index_q + 32'd1;
                                read_beat_q     <= 32'b0;
                                element_index_q <= 32'b0;
                                state_q         <= ST_ROW_READ_PREP;
                            end
                        end
                    end

                    ST_PUBLISH_PREP: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else begin
                            gmem_req_addr_q <= publish_byte_address_w
                                             & 64'hffff_ffff_ffff_fff8;
                            if (publish_byte_address_w[2]) begin
                                gmem_req_wdata_q <= {
                                    result_buffer_q[publish_array_index_w],
                                    32'b0};
                                gmem_req_wstrb_q <= 8'hf0;
                            end else begin
                                gmem_req_wdata_q <= {
                                    32'b0,
                                    result_buffer_q[publish_array_index_w]};
                                gmem_req_wstrb_q <= 8'h0f;
                            end
                            gmem_req_write_q <= 1'b1;
                            stall_cycles_q   <= 64'b0;
                            state_q          <= ST_PUBLISH_REQ;
                        end
                    end

                    ST_PUBLISH_REQ: begin
                        if (command_timeout_hit_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else if (gmem_req_fire_w) begin
                            gmem_owner_valid_q      <= 1'b1;
                            gmem_owner_write_q      <= 1'b1;
                            gmem_owner_generation_q <= generation_q;
                            gmem_owner_row_q        <= publish_index_q;
                            gmem_owner_index_q      <= publish_index_q;
                            gmem_write_requests_q   <= gmem_write_requests_q
                                                     + 64'd1;
                            stall_cycles_q          <= 64'b0;
                            state_q                 <= ST_PUBLISH_WAIT;
                        end
                    end

                    ST_PUBLISH_WAIT: begin
                        if (command_timeout_hit_w) begin
                            error_code_q   <= ERR_COMMAND_TIMEOUT;
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q   <= ERR_STALL_TIMEOUT;
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (gmem_rsp_fire_w) begin
                            gmem_owner_valid_q     <= 1'b0;
                            gmem_write_responses_q <= gmem_write_responses_q
                                                    + 64'd1;
                            stall_cycles_q         <= 64'b0;
                            if (publish_index_q == (ROWS_U32 - 32'd1)) begin
                                state_q <= ST_DONE;
                            end else begin
                                publish_index_q <= publish_index_q + 32'd1;
                                state_q         <= ST_PUBLISH_PREP;
                            end
                        end
                    end

                    ST_GMEM_DRAIN: begin
                        // All semantic coordinates/counters stay frozen here.
                        if (gmem_owner_rsp_fire_w) begin
                            gmem_owner_valid_q <= 1'b0;
                            if (reset_only_poison_w) begin
                                // A late real response may retire transport for
                                // an abort-held request, but it cannot restore
                                // normal/error/done eligibility before reset.
                                state_q      <= ST_POISON;
                                txn_active_q <= 1'b0;
                            end else if (cleanup_suppress_terminal_q) begin
                                state_q                     <= ST_IDLE;
                                error_code_q                <= ERR_NONE;
                                cleanup_suppress_terminal_q <= 1'b0;
                            end else begin
                                state_q <= ST_ERROR;
                            end
                        end else if (drain_timeout_hit_w) begin
                            if (reset_only_poison_w) begin
                                state_q      <= ST_POISON;
                                txn_active_q <= 1'b0;
                            end else begin
                                error_code_q <= ERR_POISONED;
                                state_q      <= cleanup_suppress_terminal_q
                                              ? ST_POISON : ST_POISON_ERROR;
                            end
                        end
                    end

                    ST_CHILD_QUARANTINE: begin
                        // child_rst_w is high for this complete registered
                        // cycle.  Only after this edge may cleanup drain a
                        // GMEM owner or expose a terminal.
                        widen_owner_valid_q  <= 1'b0;
                        add_owner_valid_q    <= 1'b0;
                        narrow_owner_valid_q <= 1'b0;
                        if (collision_poison_q) begin
                            // With no GMEM response tag, DRAIN would let the
                            // pre-existing response level impersonate the new
                            // owner.  Preserve the owner ledger for diagnosis,
                            // deny all response credit, and wait only for reset.
                            state_q      <= ST_POISON;
                            txn_active_q <= 1'b0;
                        end else if (gmem_owner_valid_q) begin
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (abort_hold_poison_q) begin
                            state_q      <= ST_POISON;
                            txn_active_q <= 1'b0;
                        end else if (cleanup_suppress_terminal_q
                                && gmem_rsp_valid_i) begin
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_STRAY_GMEM_DROP;
                        end else if (cleanup_suppress_terminal_q) begin
                            state_q                     <= ST_IDLE;
                            error_code_q                <= ERR_NONE;
                            cleanup_suppress_terminal_q <= 1'b0;
                        end else begin
                            state_q <= ST_ERROR;
                        end
                    end

                    ST_DONE: begin
                        state_q        <= ST_IDLE;
                        txn_active_q   <= 1'b0;
                        error_code_q   <= ERR_NONE;
                        stall_cycles_q <= 64'b0;
                        cleanup_suppress_terminal_q <= 1'b0;
                    end

                    ST_ERROR: begin
                        state_q        <= ST_IDLE;
                        txn_active_q   <= 1'b0;
                        error_code_q   <= ERR_NONE;
                        stall_cycles_q <= 64'b0;
                        cleanup_suppress_terminal_q <= 1'b0;
                    end

                    ST_POISON_ERROR: begin
                        error_code_q <= ERR_POISONED;
                        txn_active_q <= 1'b0;
                        state_q      <= ST_POISON;
                    end

                    ST_POISON: begin
                        if (!reset_only_poison_w)
                            error_code_q <= ERR_POISONED;
                        txn_active_q <= 1'b0;
                        state_q      <= ST_POISON;
                    end

                    ST_STRAY_GMEM_DROP: begin
                        // This response has no active-transaction owner and is
                        // deliberately excluded from semantic/event counters.
                        if (gmem_stray_rsp_fire_w) begin
                            cleanup_suppress_terminal_q <= 1'b0;
                            drain_cycles_q              <= 64'b0;
                            state_q                     <= ST_IDLE;
                        end else if (!gmem_rsp_valid_i) begin
                            // A nonconforming pulse may disappear before
                            // credit; cleanup still remains bounded and emits
                            // no transaction completion.
                            cleanup_suppress_terminal_q <= 1'b0;
                            drain_cycles_q              <= 64'b0;
                            state_q                     <= ST_IDLE;
                        end else if (drain_timeout_hit_w) begin
                            error_code_q <= ERR_POISONED;
                            state_q      <= ST_POISON;
                        end
                    end

                    default: begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        if (gmem_owner_valid_q) begin
                            drain_cycles_q <= 64'b0;
                            state_q        <= ST_GMEM_DRAIN;
                        end else if (widen_owner_valid_q
                                || add_owner_valid_q
                                || narrow_owner_valid_q) begin
                            state_q <= ST_CHILD_QUARANTINE;
                        end else begin
                            state_q <= ST_ERROR;
                        end
                    end
                endcase
            end

            // Transport accounting is deliberately last in the parent writer.
            // These assignments override any identical normal-path updates and
            // also survive a fault-path state decision.  Semantic buffers and
            // coordinates remain exclusively in the normal FSM cases above.
            if (gmem_req_fire_w) begin
                gmem_owner_valid_q      <= 1'b1;
                gmem_owner_addr_q       <= gmem_req_addr_q;
                gmem_owner_write_q      <= gmem_req_write_q;
                gmem_owner_generation_q <= generation_q;
                gmem_owner_row_q        <= gmem_req_write_q
                                           ? publish_index_q : row_index_q;
                gmem_owner_index_q      <= gmem_req_write_q
                                           ? publish_index_q : read_beat_q;
                if (gmem_req_write_q)
                    gmem_write_requests_q <= gmem_write_requests_q + 64'd1;
                else
                    gmem_read_requests_q <= gmem_read_requests_q + 64'd1;
            end
            if (gmem_owner_rsp_fire_w) begin
                gmem_owner_valid_q <= 1'b0;
                gmem_owner_addr_q  <= 64'b0;
                if (gmem_owner_write_q)
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                else
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
            end

            if (widen_req_fire_w) begin
                widen_owner_valid_q      <= 1'b1;
                widen_owner_generation_q <= generation_q;
                widen_owner_row_q        <= row_index_q;
                widen_owner_element_q    <= element_index_q;
                widen_requests_q         <= widen_requests_q + 64'd1;
            end
            if (widen_rsp_fire_w) begin
                widen_owner_valid_q <= 1'b0;
                widen_responses_q   <= widen_responses_q + 64'd1;
                flags_q             <= flags_after_events_w;
            end

            if (add_req_fire_w) begin
                add_owner_valid_q      <= 1'b1;
                add_owner_generation_q <= generation_q;
                add_owner_row_q        <= row_index_q;
                add_owner_element_q    <= element_index_q;
                add_requests_q         <= add_requests_q + 64'd1;
            end
            if (add_rsp_fire_w) begin
                add_owner_valid_q <= 1'b0;
                add_responses_q   <= add_responses_q + 64'd1;
                flags_q           <= flags_after_events_w;
            end

            if (narrow_req_fire_w) begin
                narrow_owner_valid_q      <= 1'b1;
                narrow_owner_generation_q <= generation_q;
                narrow_owner_row_q        <= row_index_q;
                narrow_owner_element_q    <= NE0_U32;
                narrow_requests_q         <= narrow_requests_q + 64'd1;
            end
            if (narrow_rsp_fire_w) begin
                narrow_owner_valid_q <= 1'b0;
                narrow_responses_q   <= narrow_responses_q + 64'd1;
                flags_q              <= flags_after_events_w;
            end

            // This writer is deliberately outside the first-fault branch.
            // A collision after an earlier fault must still poison the
            // transaction while leaving the original diagnostic record intact.
            if (gmem_ownerless_request_collision_w)
                collision_poison_q <= 1'b1;
        end
    end

endmodule

`default_nettype wire
