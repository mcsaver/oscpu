`timescale 1ns/1ps
`default_nettype none

// TensorNpuSetRowsEngine -- Qwen single-token F32->F16 SET_ROWS engine.
//
// The command is deliberately split into three eligibility stages.  Every I64
// index is checked first, every F32 value is then converted and cached, and only
// a fully validated command may issue a shadow write.  Accepted GMEM requests
// own exactly one response credit; a WAIT watchdog therefore drains that credit
// before publishing ERROR, so a late response cannot escape into the next
// command.
//
// Topology:
//   resident descriptor -> 128-bit static preflight
//   -> 512x64 index buffer -> one shared raw-bit FP converter/512x16 half buffer
//   -> aligned two-byte shadow writes through one held 64-bit GMEM request.
// The longest combinational path is the transposed-V 511*C+p destination bound
// followed by region/window/overlap compares.  No function hides state,
// arbitration, handshake, reset, or resource ownership.
module TensorNpuSetRowsEngine #(
    parameter integer VALUE_ELEMENTS         = 512,
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        start_i,
    output wire        ready_o,
    output wire        busy_o,
    input  wire [1:0]  profile_i,
    input  wire [31:0] cache_capacity_i,
    input  wire [31:0] physical_slot_i,

    input  wire [63:0] gmem_floor_i,
    input  wire [63:0] gmem_limit_i,

    input  wire [63:0] values_region_base_i,
    input  wire [63:0] values_region_size_i,
    input  wire [63:0] values_view_off_i,
    input  wire [63:0] indices_region_base_i,
    input  wire [63:0] indices_region_size_i,
    input  wire [63:0] indices_view_off_i,
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
    output wire [31:0] indices_validated_o,
    output wire [31:0] values_validated_o,
    output wire [31:0] writes_completed_o,
    output wire [31:0] bytes_written_o,
    output wire [31:0] gmem_read_beats_o,
    output wire [31:0] gmem_write_beats_o,
    output wire [31:0] writes_accepted_o,
    output wire [63:0] active_cycles_o
);

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (STALL_TIMEOUT_CYCLES - 1);
    localparam [31:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 1) ? 32'd0
                                      : (COMMAND_TIMEOUT_CYCLES - 1);
    localparam [127:0] VALUES_SPAN_BYTES = VALUE_ELEMENTS * 4;
    localparam [127:0] NATIVE_INDEX_BYTES = 128'd8;
    localparam [127:0] TRANSPOSED_INDEX_BYTES = VALUE_ELEMENTS * 8;

    localparam [4:0] ST_IDLE         = 5'd0;
    localparam [4:0] ST_PREFLIGHT    = 5'd1;
    localparam [4:0] ST_INDEX_PREP   = 5'd2;
    localparam [4:0] ST_INDEX_REQ    = 5'd3;
    localparam [4:0] ST_INDEX_WAIT   = 5'd4;
    localparam [4:0] ST_INDEX_CHECK  = 5'd5;
    localparam [4:0] ST_VALUE_PREP   = 5'd6;
    localparam [4:0] ST_VALUE_REQ    = 5'd7;
    localparam [4:0] ST_VALUE_WAIT   = 5'd8;
    localparam [4:0] ST_VALUE_CHECK  = 5'd9;
    localparam [4:0] ST_WRITE_PREP   = 5'd10;
    localparam [4:0] ST_WRITE_REQ    = 5'd11;
    localparam [4:0] ST_WRITE_WAIT   = 5'd12;
    localparam [4:0] ST_GMEM_DRAIN   = 5'd13;
    localparam [4:0] ST_DONE         = 5'd14;
    localparam [4:0] ST_ERROR        = 5'd15;

    localparam [4:0] ERR_NONE            = 5'd0;
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
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd13;

    reg [4:0] state_q;

    // Resident command descriptor.  Busy start_i never writes these fields.
    reg [1:0]  profile_q;
    reg [31:0] cache_capacity_q;
    reg [31:0] physical_slot_q;
    reg [63:0] gmem_floor_q;
    reg [63:0] gmem_limit_q;
    reg [63:0] values_region_base_q;
    reg [63:0] values_region_size_q;
    reg [63:0] values_view_off_q;
    reg [63:0] indices_region_base_q;
    reg [63:0] indices_region_size_q;
    reg [63:0] indices_view_off_q;
    reg [63:0] dst_region_base_q;
    reg [63:0] dst_region_size_q;
    reg [63:0] dst_view_off_q;

    // Buffer data bits need no reset.  Current-command cursors and validated
    // counters make every stale entry ineligible until it is overwritten.
    reg [63:0] index_buffer_q [0:VALUE_ELEMENTS-1];
    reg [15:0] half_buffer_q  [0:VALUE_ELEMENTS-1];
    reg [8:0] index_cursor_q;
    reg [8:0] value_cursor_q;
    reg [8:0] write_cursor_q;
    reg [63:0] index_raw_q;
    reg [31:0] fp32_raw_q;

    // One shared held GMEM request and its sole response-credit bit.
    reg [63:0] gmem_req_addr_q;
    reg [63:0] gmem_req_wdata_q;
    reg [7:0]  gmem_req_wstrb_q;
    reg        outstanding_q;

    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;
    reg [4:0]  drain_error_code_q;
    reg [4:0]  error_code_q;
    reg [31:0] indices_validated_q;
    reg [31:0] values_validated_q;
    reg [31:0] writes_completed_q;
    reg [31:0] bytes_written_q;
    reg [31:0] gmem_read_beats_q;
    reg [31:0] gmem_write_beats_q;
    reg [31:0] writes_accepted_q;
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

    assign request_state_w = (state_q == ST_INDEX_REQ)
                           || (state_q == ST_VALUE_REQ)
                           || (state_q == ST_WRITE_REQ);
    assign response_state_w = (state_q == ST_INDEX_WAIT)
                            || (state_q == ST_VALUE_WAIT)
                            || (state_q == ST_WRITE_WAIT)
                            || (state_q == ST_GMEM_DRAIN);
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);
    assign stall_timeout_hit_w =
        (stall_cycles_q >= STALL_TIMEOUT_LAST);

    // Watchdog terminal wins over same-cycle late ready.  PREP registers hold
    // every payload bit, and no REQ state mutates those registers.
    assign gmem_req_valid_o = !rst_i && request_state_w && !outstanding_q
                            && !command_timeout_hit_w
                            && !stall_timeout_hit_w;
    assign gmem_req_write_o = (state_q == ST_WRITE_REQ);
    assign gmem_req_addr_o  = gmem_req_addr_q;
    assign gmem_req_wdata_o = (state_q == ST_WRITE_REQ)
                            ? gmem_req_wdata_q : 64'b0;
    assign gmem_req_wstrb_o = (state_q == ST_WRITE_REQ)
                            ? gmem_req_wstrb_q : 8'b0;
    assign gmem_rsp_ready_o = !rst_i && response_state_w && outstanding_q;
    assign gmem_req_fire_w  = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w  = gmem_rsp_valid_i && gmem_rsp_ready_o;

    assign error_code_o          = error_code_q;
    assign indices_validated_o   = indices_validated_q;
    assign values_validated_o    = values_validated_q;
    assign writes_completed_o    = writes_completed_q;
    assign bytes_written_o       = bytes_written_q;
    assign gmem_read_beats_o     = gmem_read_beats_q;
    assign gmem_write_beats_o    = gmem_write_beats_q;
    assign writes_accepted_o     = writes_accepted_q;
    assign active_cycles_o       = active_cycles_q;

    // ------------------------------------------------------------------
    // Whole-command static preflight.  All products and additions remain in
    // 128 bits until overflow, semantic bounds, aligned beats, and overlap are
    // proven.  Error selection below implements the contract's fixed order.
    // ------------------------------------------------------------------
    reg [127:0] values_region_end_w;
    reg [127:0] indices_region_end_w;
    reg [127:0] dst_region_end_w;
    reg [127:0] values_rel_end_w;
    reg [127:0] indices_span_bytes_w;
    reg [127:0] indices_rel_end_w;
    reg [127:0] values_abs_start_w;
    reg [127:0] values_abs_end_w;
    reg [127:0] indices_abs_start_w;
    reg [127:0] indices_abs_end_w;
    reg [127:0] values_aligned_start_w;
    reg [127:0] values_aligned_end_w;
    reg [127:0] indices_aligned_start_w;
    reg [127:0] indices_aligned_end_w;
    reg [127:0] dst_first_elem_w;
    reg [127:0] dst_last_elem_w;
    reg [127:0] dst_first_rel_w;
    reg [127:0] dst_rel_end_w;
    reg [127:0] dst_abs_start_w;
    reg [127:0] dst_first_abs_w;
    reg [127:0] dst_abs_end_w;
    reg [127:0] dst_aligned_start_w;
    reg [127:0] dst_aligned_end_w;
    reg         header_ok_w;
    reg         profile_shape_ok_w;
    reg         alignment_ok_w;
    reg         values_bounds_ok_w;
    reg         indices_bounds_ok_w;
    reg         destination_bounds_ok_w;
    reg         overlap_ok_w;
    reg [4:0]   preflight_error_w;

    always @(*) begin
        values_region_end_w = {64'b0, values_region_base_q}
                            + {64'b0, values_region_size_q};
        indices_region_end_w = {64'b0, indices_region_base_q}
                             + {64'b0, indices_region_size_q};
        dst_region_end_w = {64'b0, dst_region_base_q}
                         + {64'b0, dst_region_size_q};

        values_rel_end_w = {64'b0, values_view_off_q}
                         + VALUES_SPAN_BYTES;
        indices_span_bytes_w = (profile_q == 2'd0)
                             ? NATIVE_INDEX_BYTES
                             : TRANSPOSED_INDEX_BYTES;
        indices_rel_end_w = {64'b0, indices_view_off_q}
                          + indices_span_bytes_w;
        values_abs_start_w = {64'b0, values_region_base_q}
                           + {64'b0, values_view_off_q};
        values_abs_end_w = {64'b0, values_region_base_q}
                         + values_rel_end_w;
        indices_abs_start_w = {64'b0, indices_region_base_q}
                            + {64'b0, indices_view_off_q};
        indices_abs_end_w = {64'b0, indices_region_base_q}
                          + indices_rel_end_w;

        values_aligned_start_w = values_abs_start_w;
        values_aligned_start_w[2:0] = 3'b000;
        values_aligned_end_w = values_abs_end_w - 128'd1;
        values_aligned_end_w[2:0] = 3'b000;
        values_aligned_end_w = values_aligned_end_w + 128'd8;
        indices_aligned_start_w = indices_abs_start_w;
        indices_aligned_start_w[2:0] = 3'b000;
        indices_aligned_end_w = indices_abs_end_w - 128'd1;
        indices_aligned_end_w[2:0] = 3'b000;
        indices_aligned_end_w = indices_aligned_end_w + 128'd8;

        if (profile_q == 2'd0) begin
            dst_first_elem_w = {96'b0, physical_slot_q} * 128'd512;
            dst_last_elem_w = dst_first_elem_w + 128'd511;
        end else begin
            dst_first_elem_w = {96'b0, physical_slot_q};
            dst_last_elem_w = (128'd511
                              * {96'b0, cache_capacity_q})
                            + {96'b0, physical_slot_q};
        end
        dst_first_rel_w = {64'b0, dst_view_off_q}
                        + (dst_first_elem_w * 128'd2);
        dst_rel_end_w = {64'b0, dst_view_off_q}
                      + (dst_last_elem_w * 128'd2) + 128'd2;
        // The conservative overlap span starts at view_off, even when the
        // first semantic destination is a later native-K row.
        dst_abs_start_w = {64'b0, dst_region_base_q}
                        + {64'b0, dst_view_off_q};
        dst_first_abs_w = {64'b0, dst_region_base_q} + dst_first_rel_w;
        dst_abs_end_w = {64'b0, dst_region_base_q} + dst_rel_end_w;
        dst_aligned_start_w = dst_first_abs_w;
        dst_aligned_start_w[2:0] = 3'b000;
        dst_aligned_end_w = dst_abs_end_w - 128'd1;
        dst_aligned_end_w[2:0] = 3'b000;
        dst_aligned_end_w = dst_aligned_end_w + 128'd8;

        header_ok_w = (VALUE_ELEMENTS == 512)
                    && (STALL_TIMEOUT_CYCLES >= 1)
                    && (COMMAND_TIMEOUT_CYCLES >= 1)
                    && (gmem_floor_q < gmem_limit_q);
        profile_shape_ok_w = ((profile_q == 2'd0)
                           || (profile_q == 2'd1))
                          && (cache_capacity_q >= 32'd1)
                          && (physical_slot_q < cache_capacity_q);
        alignment_ok_w = (values_abs_start_w[1:0] == 2'b00)
                       && (indices_abs_start_w[2:0] == 3'b000)
                       && (dst_abs_start_w[0] == 1'b0);

        values_bounds_ok_w =
               (values_region_end_w[127:64] == 64'b0)
            && (values_rel_end_w[127:64] == 64'b0)
            && (values_abs_start_w[127:64] == 64'b0)
            && (values_abs_end_w[127:64] == 64'b0)
            && (values_aligned_start_w[127:64] == 64'b0)
            && (values_aligned_end_w[127:64] == 64'b0)
            && ({64'b0, values_view_off_q}
                <= {64'b0, values_region_size_q})
            && (values_rel_end_w <= {64'b0, values_region_size_q})
            && (values_aligned_start_w >= {64'b0, values_region_base_q})
            && (values_aligned_end_w <= values_region_end_w)
            && (values_aligned_start_w >= {64'b0, gmem_floor_q})
            && (values_aligned_end_w <= {64'b0, gmem_limit_q});

        indices_bounds_ok_w =
               (indices_region_end_w[127:64] == 64'b0)
            && (indices_rel_end_w[127:64] == 64'b0)
            && (indices_abs_start_w[127:64] == 64'b0)
            && (indices_abs_end_w[127:64] == 64'b0)
            && (indices_aligned_start_w[127:64] == 64'b0)
            && (indices_aligned_end_w[127:64] == 64'b0)
            && ({64'b0, indices_view_off_q}
                <= {64'b0, indices_region_size_q})
            && (indices_rel_end_w <= {64'b0, indices_region_size_q})
            && (indices_aligned_start_w >= {64'b0, indices_region_base_q})
            && (indices_aligned_end_w <= indices_region_end_w)
            && (indices_aligned_start_w >= {64'b0, gmem_floor_q})
            && (indices_aligned_end_w <= {64'b0, gmem_limit_q});

        destination_bounds_ok_w =
               (dst_region_end_w[127:64] == 64'b0)
            && (dst_first_rel_w[127:64] == 64'b0)
            && (dst_rel_end_w[127:64] == 64'b0)
            && (dst_abs_start_w[127:64] == 64'b0)
            && (dst_first_abs_w[127:64] == 64'b0)
            && (dst_abs_end_w[127:64] == 64'b0)
            && (dst_aligned_start_w[127:64] == 64'b0)
            && (dst_aligned_end_w[127:64] == 64'b0)
            && ({64'b0, dst_view_off_q} <= {64'b0, dst_region_size_q})
            && (dst_rel_end_w <= {64'b0, dst_region_size_q})
            && (dst_aligned_start_w >= {64'b0, gmem_floor_q})
            && (dst_aligned_end_w <= {64'b0, gmem_limit_q});

        overlap_ok_w = ((values_abs_end_w <= indices_abs_start_w)
                     || (indices_abs_end_w <= values_abs_start_w))
                    && ((values_abs_end_w <= dst_abs_start_w)
                     || (dst_abs_end_w <= values_abs_start_w))
                    && ((indices_abs_end_w <= dst_abs_start_w)
                     || (dst_abs_end_w <= indices_abs_start_w));

        preflight_error_w = ERR_NONE;
        if (!header_ok_w) begin
            preflight_error_w = ERR_HEADER;
        end else if (!profile_shape_ok_w) begin
            preflight_error_w = ERR_PROFILE_SHAPE;
        end else if (!alignment_ok_w) begin
            preflight_error_w = ERR_ALIGNMENT;
        end else if (!values_bounds_ok_w) begin
            preflight_error_w = ERR_VALUES_BOUNDS;
        end else if (!indices_bounds_ok_w) begin
            preflight_error_w = ERR_INDICES_BOUNDS;
        end else if (!destination_bounds_ok_w) begin
            preflight_error_w = ERR_DEST_BOUNDS;
        end else if (!overlap_ok_w) begin
            preflight_error_w = ERR_OVERLAP;
        end
    end

    // Current scan/write addresses are recomputed from the proven resident
    // command.  They remain expanded until PREP performs its internal guard.
    reg [127:0] index_expected_w;
    reg [127:0] index_addr_w;
    reg [127:0] value_addr_w;
    reg [127:0] write_element_w;
    reg [127:0] write_addr_w;
    reg [127:0] write_end_w;
    reg [127:0] write_aligned_end_w;
    reg [63:0]  write_data_w;
    reg [7:0]   write_strb_w;

    always @(*) begin
        if (profile_q == 2'd0) begin
            index_expected_w = {96'b0, physical_slot_q};
        end else begin
            index_expected_w = ({119'b0, index_cursor_q}
                               * {96'b0, cache_capacity_q})
                             + {96'b0, physical_slot_q};
        end
        index_addr_w = {64'b0, indices_region_base_q}
                     + {64'b0, indices_view_off_q}
                     + ({119'b0, index_cursor_q} * 128'd8);
        value_addr_w = {64'b0, values_region_base_q}
                     + {64'b0, values_view_off_q}
                     + ({119'b0, value_cursor_q} * 128'd4);

        if (profile_q == 2'd0) begin
            write_element_w = ({64'b0, index_buffer_q[0]} * 128'd512)
                            + {119'b0, write_cursor_q};
        end else begin
            write_element_w = {64'b0, index_buffer_q[write_cursor_q]};
        end
        write_addr_w = {64'b0, dst_region_base_q}
                     + {64'b0, dst_view_off_q}
                     + (write_element_w * 128'd2);
        write_end_w = write_addr_w + 128'd2;
        write_aligned_end_w = write_addr_w;
        write_aligned_end_w[2:0] = 3'b000;
        write_aligned_end_w = write_aligned_end_w + 128'd8;
        write_data_w = {48'b0, half_buffer_q[write_cursor_q]}
                     << ({4'b0, write_addr_w[2:0]} * 8);
        write_strb_w = 8'h03 << write_addr_w[2:0];
    end

    wire [15:0] fp16_bits_w;
    wire        fp16_finite_w;
    wire        fp16_overflow_w;
    wire        fp16_inexact_w;
    // inexact is audit metadata and is deliberately accepted in both arms.
    wire conversion_ok_w = fp16_finite_w && !fp16_overflow_w
                         && (fp16_inexact_w || !fp16_inexact_w);

    TensorNpuFp32ToFp16 u_fp32_to_fp16 (
        .fp32_bits_i (fp32_raw_q),
        .fp16_bits_o (fp16_bits_w),
        .finite_o    (fp16_finite_w),
        .overflow_o  (fp16_overflow_w),
        .inexact_o   (fp16_inexact_w)
    );

    // ------------------------------------------------------------------
    // Unique sequential owner for descriptors, FSM, credit, watchdogs, and
    // counters.  reset > fatal > command timeout > stall timeout > progress.
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                 <= ST_IDLE;
            profile_q               <= 2'b0;
            cache_capacity_q        <= 32'b0;
            physical_slot_q         <= 32'b0;
            gmem_floor_q            <= 64'b0;
            gmem_limit_q            <= 64'b0;
            values_region_base_q    <= 64'b0;
            values_region_size_q    <= 64'b0;
            values_view_off_q       <= 64'b0;
            indices_region_base_q   <= 64'b0;
            indices_region_size_q   <= 64'b0;
            indices_view_off_q      <= 64'b0;
            dst_region_base_q       <= 64'b0;
            dst_region_size_q       <= 64'b0;
            dst_view_off_q          <= 64'b0;
            index_cursor_q          <= 9'b0;
            value_cursor_q          <= 9'b0;
            write_cursor_q          <= 9'b0;
            index_raw_q             <= 64'b0;
            fp32_raw_q              <= 32'b0;
            gmem_req_addr_q         <= 64'b0;
            gmem_req_wdata_q        <= 64'b0;
            gmem_req_wstrb_q        <= 8'b0;
            outstanding_q           <= 1'b0;
            stall_cycles_q          <= 32'b0;
            command_cycles_q        <= 32'b0;
            drain_error_code_q      <= ERR_NONE;
            error_code_q            <= ERR_NONE;
            indices_validated_q     <= 32'b0;
            values_validated_q      <= 32'b0;
            writes_completed_q      <= 32'b0;
            bytes_written_q         <= 32'b0;
            gmem_read_beats_q       <= 32'b0;
            gmem_write_beats_q      <= 32'b0;
            writes_accepted_q       <= 32'b0;
            active_cycles_q         <= 64'b0;
        end else begin
            // DRAIN and terminal states freeze all result/watchdog counters.
            if ((state_q != ST_IDLE) && (state_q != ST_GMEM_DRAIN)
                    && (state_q != ST_DONE) && (state_q != ST_ERROR)) begin
                if (command_cycles_q != 32'hffff_ffff)
                    command_cycles_q <= command_cycles_q + 32'd1;
                if (active_cycles_q != 64'hffff_ffff_ffff_ffff)
                    active_cycles_q <= active_cycles_q + 64'd1;
            end

            case (state_q)
                ST_IDLE: begin
                    outstanding_q    <= 1'b0;
                    stall_cycles_q   <= 32'b0;
                    command_cycles_q <= 32'b0;
                    if (start_fire_w) begin
                        profile_q              <= profile_i;
                        cache_capacity_q       <= cache_capacity_i;
                        physical_slot_q        <= physical_slot_i;
                        gmem_floor_q           <= gmem_floor_i;
                        gmem_limit_q           <= gmem_limit_i;
                        values_region_base_q   <= values_region_base_i;
                        values_region_size_q   <= values_region_size_i;
                        values_view_off_q      <= values_view_off_i;
                        indices_region_base_q  <= indices_region_base_i;
                        indices_region_size_q  <= indices_region_size_i;
                        indices_view_off_q     <= indices_view_off_i;
                        dst_region_base_q      <= dst_region_base_i;
                        dst_region_size_q      <= dst_region_size_i;
                        dst_view_off_q         <= dst_view_off_i;
                        index_cursor_q         <= 9'b0;
                        value_cursor_q         <= 9'b0;
                        write_cursor_q         <= 9'b0;
                        index_raw_q            <= 64'b0;
                        fp32_raw_q             <= 32'b0;
                        gmem_req_addr_q        <= 64'b0;
                        gmem_req_wdata_q       <= 64'b0;
                        gmem_req_wstrb_q       <= 8'b0;
                        stall_cycles_q         <= 32'b0;
                        command_cycles_q       <= 32'd1;
                        drain_error_code_q     <= ERR_NONE;
                        error_code_q           <= ERR_NONE;
                        indices_validated_q    <= 32'b0;
                        values_validated_q     <= 32'b0;
                        writes_completed_q     <= 32'b0;
                        bytes_written_q        <= 32'b0;
                        gmem_read_beats_q      <= 32'b0;
                        gmem_write_beats_q     <= 32'b0;
                        writes_accepted_q      <= 32'b0;
                        active_cycles_q        <= 64'd1;
                        state_q                <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    stall_cycles_q <= 32'b0;
                    if (preflight_error_w != ERR_NONE) begin
                        error_code_q <= preflight_error_w;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        index_cursor_q <= 9'b0;
                        state_q        <= ST_INDEX_PREP;
                    end
                end

                ST_INDEX_PREP: begin
                    stall_cycles_q <= 32'b0;
                    if ((profile_q > 2'd1)
                            || ((profile_q == 2'd0)
                                && (index_cursor_q != 9'd0))
                            || (index_addr_w[127:64] != 64'b0)
                            || (index_addr_w[2:0] != 3'b000)) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        gmem_req_addr_q  <= index_addr_w[63:0];
                        gmem_req_wdata_q <= 64'b0;
                        gmem_req_wstrb_q <= 8'b0;
                        state_q          <= ST_INDEX_REQ;
                    end
                end

                ST_INDEX_REQ: begin
                    if (outstanding_q || (gmem_req_addr_q[2:0] != 3'b000)) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q <= ERR_STALL_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        outstanding_q      <= 1'b1;
                        gmem_read_beats_q  <= gmem_read_beats_q + 32'd1;
                        stall_cycles_q     <= 32'b0;
                        state_q            <= ST_INDEX_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_INDEX_WAIT: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        state_q       <= ST_ERROR;
                    end else if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
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
                        index_raw_q    <= gmem_rsp_rdata_i;
                        stall_cycles_q <= 32'b0;
                        state_q        <= ST_INDEX_CHECK;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_INDEX_CHECK: begin
                    stall_cycles_q <= 32'b0;
                    if ((index_expected_w[127:64] != 64'b0)
                            || (index_raw_q != index_expected_w[63:0])) begin
                        error_code_q <= ERR_INDEX_PAYLOAD;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        index_buffer_q[index_cursor_q] <= index_raw_q;
                        indices_validated_q <= indices_validated_q + 32'd1;
                        if (((profile_q == 2'd0)
                                && (index_cursor_q == 9'd0))
                                || ((profile_q == 2'd1)
                                    && (index_cursor_q == 9'd511))) begin
                            value_cursor_q <= 9'b0;
                            state_q        <= ST_VALUE_PREP;
                        end else begin
                            index_cursor_q <= index_cursor_q + 9'd1;
                            state_q        <= ST_INDEX_PREP;
                        end
                    end
                end

                ST_VALUE_PREP: begin
                    stall_cycles_q <= 32'b0;
                    if ((value_addr_w[127:64] != 64'b0)
                            || (value_addr_w[1:0] != 2'b00)) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        gmem_req_addr_q  <= {value_addr_w[63:3], 3'b000};
                        gmem_req_wdata_q <= 64'b0;
                        gmem_req_wstrb_q <= 8'b0;
                        state_q          <= ST_VALUE_REQ;
                    end
                end

                ST_VALUE_REQ: begin
                    if (outstanding_q || (gmem_req_addr_q[2:0] != 3'b000)) begin
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
                        gmem_read_beats_q <= gmem_read_beats_q + 32'd1;
                        stall_cycles_q    <= 32'b0;
                        state_q           <= ST_VALUE_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_VALUE_WAIT: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        state_q       <= ST_ERROR;
                    end else if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
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
                        outstanding_q <= 1'b0;
                        fp32_raw_q <= value_addr_w[2]
                                    ? gmem_rsp_rdata_i[63:32]
                                    : gmem_rsp_rdata_i[31:0];
                        stall_cycles_q <= 32'b0;
                        state_q        <= ST_VALUE_CHECK;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_VALUE_CHECK: begin
                    stall_cycles_q <= 32'b0;
                    if (!conversion_ok_w) begin
                        error_code_q <= ERR_VALUE_DOMAIN;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        half_buffer_q[value_cursor_q] <= fp16_bits_w;
                        values_validated_q <= values_validated_q + 32'd1;
                        if (value_cursor_q == 9'd511) begin
                            write_cursor_q <= 9'b0;
                            state_q        <= ST_WRITE_PREP;
                        end else begin
                            value_cursor_q <= value_cursor_q + 9'd1;
                            state_q        <= ST_VALUE_PREP;
                        end
                    end
                end

                ST_WRITE_PREP: begin
                    stall_cycles_q <= 32'b0;
                    if (((profile_q == 2'd0)
                            && (indices_validated_q != 32'd1))
                            || ((profile_q == 2'd1)
                                && (indices_validated_q != 32'd512))
                            || (values_validated_q != 32'd512)
                            || (write_addr_w[127:64] != 64'b0)
                            || (write_end_w[127:64] != 64'b0)
                            || write_addr_w[0]
                            || (write_addr_w[2:0] > 3'd6)
                            || (write_addr_w < {64'b0, dst_region_base_q})
                            || (write_end_w > dst_region_end_w)
                            || ({write_addr_w[127:3], 3'b000}
                                < {64'b0, gmem_floor_q})
                            || (write_aligned_end_w > {64'b0, gmem_limit_q})) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        gmem_req_addr_q  <= {write_addr_w[63:3], 3'b000};
                        gmem_req_wdata_q <= write_data_w;
                        gmem_req_wstrb_q <= write_strb_w;
                        state_q          <= ST_WRITE_REQ;
                    end
                end

                ST_WRITE_REQ: begin
                    if (outstanding_q || (gmem_req_addr_q[2:0] != 3'b000)
                            || (gmem_req_wstrb_q == 8'b0)) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q <= ERR_STALL_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        outstanding_q      <= 1'b1;
                        gmem_write_beats_q <= gmem_write_beats_q + 32'd1;
                        writes_accepted_q  <= writes_accepted_q + 32'd1;
                        stall_cycles_q     <= 32'b0;
                        state_q            <= ST_WRITE_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_WRITE_WAIT: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        outstanding_q <= 1'b0;
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        state_q       <= ST_ERROR;
                    end else if (!outstanding_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
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
                        outstanding_q      <= 1'b0;
                        stall_cycles_q     <= 32'b0;
                        writes_completed_q <= writes_completed_q + 32'd1;
                        bytes_written_q    <= bytes_written_q + 32'd2;
                        if (write_cursor_q == 9'd511) begin
                            state_q <= ST_DONE;
                        end else begin
                            write_cursor_q <= write_cursor_q + 9'd1;
                            state_q        <= ST_WRITE_PREP;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_GMEM_DRAIN: begin
                    // Accepted request lost semantic eligibility.  Keep only
                    // its matching response credit; every command counter and
                    // buffer cursor is frozen until that response is consumed.
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
                    // A corrupt state with an owned response must retain that
                    // credit; otherwise it can terminate immediately.
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
