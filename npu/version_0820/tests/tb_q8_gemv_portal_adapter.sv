`timescale 1ns/1ps
`default_nettype none

// Self-checking transport and numerical-oracle test for the Row-SIMD Q8 GEMV
// portal adapter.  The testbench performs no floating-point arithmetic.  Its
// activation oracle is a real TensorNpuQ8ReferenceQuantizer and its row oracle
// is exactly four real TensorNpuQ8ScaleAccumulator instances.
module tb_q8_gemv_portal_adapter #(
    parameter integer TILE_FUNCTIONAL_ENABLE = 0
);

    // The model intentionally keeps architectural addresses at 64 bits while
    // indexing a bounded local byte array, and uses blocking temporaries in a
    // clocked testbench process.  These are verification-model conventions,
    // not DUT datapath truncations or sequential RTL assignments.
    /* verilator lint_off WIDTHTRUNC */
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off BLKSEQ */
    /* verilator lint_off PINCONNECTEMPTY */

    localparam integer ROW_LANES = 4;
    localparam integer MAC_LANES = 32;
    localparam integer MEM_BYTES = 16384;
    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = MEM_BASE + 64'(MEM_BYTES);
    localparam logic [31:0] KERNEL_ID = 32'h514e0002;

    localparam logic [63:0] ACT_WIN   = 64'h0000_0000_0000_1000;
    localparam logic [63:0] ACT_BASE  = 64'h0000_0000_0000_1104;
    localparam logic [63:0] WT_WIN    = 64'h0000_0000_0000_1800;
    localparam logic [63:0] WT_BASE   = 64'h0000_0000_0000_1802;
    localparam logic [63:0] DST_WIN   = 64'h0000_0000_0000_2000;
    localparam logic [63:0] DST_BASE  = 64'h0000_0000_0000_2104;
    localparam logic [63:0] WT_STRIDE = 64'd72;
    localparam logic [63:0] DST_STRIDE = 64'd4;
    localparam integer POS_ROWS = 5;
    localparam integer POS_BLOCKS = 2;

    localparam logic [4:0] ST_DRAIN       = 5'd15;
    localparam logic [4:0] ERR_WEIGHT_WIN = 5'd3;
    localparam logic [4:0] ERR_ALIAS      = 5'd5;
    localparam logic [4:0] ERR_GMEM       = 5'd8;
    localparam logic [4:0] ERR_STALL      = 5'd9;
    localparam logic [4:0] ERR_PORTAL_RSP = 5'd12;
    localparam logic [4:0] ERR_PORTAL_MASK = 5'd13;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [63:0] command_id_i;
    reg dst_shadow_private_i;
    reg windows_generation_valid_i;
    reg [63:0] activation_base_i;
    reg [63:0] weight_base_i;
    reg [63:0] dst_base_i;
    reg [31:0] row_count_i;
    reg [31:0] block_count_i;
    reg [63:0] weight_row_stride_i;
    reg [63:0] dst_row_stride_i;
    reg [63:0] activation_window_base_i;
    reg [63:0] activation_window_bytes_i;
    reg activation_window_read_i;
    reg activation_window_write_i;
    reg [63:0] weight_window_base_i;
    reg [63:0] weight_window_bytes_i;
    reg weight_window_read_i;
    reg weight_window_write_i;
    reg [63:0] dst_window_base_i;
    reg [63:0] dst_window_bytes_i;
    reg dst_window_read_i;
    reg dst_window_write_i;

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

    wire portal_req_valid_o;
    wire portal_req_ready_i;
    wire [ROW_LANES-1:0] portal_req_mask_o;
    wire [(ROW_LANES*64)-1:0] portal_req_addr_o;
    reg portal_rsp_valid_i;
    wire portal_rsp_ready_o;
    reg [ROW_LANES-1:0] portal_rsp_mask_i;
    reg [(ROW_LANES*272)-1:0] portal_rsp_blocks_i;
    reg portal_rsp_error_i;

    wire completion_valid_o;
    wire dst_commit_o;
    wire [63:0] completion_command_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_row_count_o;
    wire [31:0] completion_block_count_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [7:0] child_error_code_o;
    wire [31:0] activation_words_accepted_o;
    wire [63:0] weight_blocks_accepted_o;
    wire [31:0] rows_written_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_read_beats_completed_o;
    wire [63:0] gmem_read_bytes_o;
    wire [63:0] activation_payload_bytes_o;
    wire [63:0] weight_payload_bytes_o;
    wire [31:0] gmem_write_beats_o;
    wire [31:0] writes_completed_o;
    wire [63:0] write_bytes_o;
    wire [63:0] child_active_cycles_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;
    wire [63:0] portal_request_groups_o;
    wire [63:0] portal_response_groups_o;
    wire [63:0] portal_blocks_o;
    wire [63:0] portal_bytes_o;
    wire portal_outstanding_o;

    TensorNpuQ8GemvPortalAdapter #(
        .MAX_ROWS              (248320),
        .MAX_BLOCKS            (128),
        .ROW_LANES             (ROW_LANES),
        .MAC_LANES             (MAC_LANES),
        .TILE_FUNCTIONAL_ENABLE(TILE_FUNCTIONAL_ENABLE),
        .STALL_TIMEOUT_CYCLES  (32'd512),
        .COMMAND_TIMEOUT_CYCLES(64'd200000)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .ready_o(ready_o),
        .busy_o(busy_o),
        .command_id_i(command_id_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .activation_base_i(activation_base_i),
        .weight_base_i(weight_base_i),
        .dst_base_i(dst_base_i),
        .row_count_i(row_count_i),
        .block_count_i(block_count_i),
        .weight_row_stride_i(weight_row_stride_i),
        .dst_row_stride_i(dst_row_stride_i),
        .activation_window_base_i(activation_window_base_i),
        .activation_window_bytes_i(activation_window_bytes_i),
        .activation_window_read_i(activation_window_read_i),
        .activation_window_write_i(activation_window_write_i),
        .weight_window_base_i(weight_window_base_i),
        .weight_window_bytes_i(weight_window_bytes_i),
        .weight_window_read_i(weight_window_read_i),
        .weight_window_write_i(weight_window_write_i),
        .dst_window_base_i(dst_window_base_i),
        .dst_window_bytes_i(dst_window_bytes_i),
        .dst_window_read_i(dst_window_read_i),
        .dst_window_write_i(dst_window_write_i),
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
        .portal_req_valid_o(portal_req_valid_o),
        .portal_req_ready_i(portal_req_ready_i),
        .portal_req_mask_o(portal_req_mask_o),
        .portal_req_addr_o(portal_req_addr_o),
        .portal_rsp_valid_i(portal_rsp_valid_i),
        .portal_rsp_ready_o(portal_rsp_ready_o),
        .portal_rsp_mask_i(portal_rsp_mask_i),
        .portal_rsp_blocks_i(portal_rsp_blocks_i),
        .portal_rsp_error_i(portal_rsp_error_i),
        .completion_valid_o(completion_valid_o),
        .dst_commit_o(dst_commit_o),
        .completion_command_id_o(completion_command_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_row_count_o(completion_row_count_o),
        .completion_block_count_o(completion_block_count_o),
        .done_o(done_o),
        .error_o(error_o),
        .error_code_o(error_code_o),
        .child_error_code_o(child_error_code_o),
        .activation_words_accepted_o(activation_words_accepted_o),
        .weight_blocks_accepted_o(weight_blocks_accepted_o),
        .rows_written_o(rows_written_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_beats_completed_o(gmem_read_beats_completed_o),
        .gmem_read_bytes_o(gmem_read_bytes_o),
        .activation_payload_bytes_o(activation_payload_bytes_o),
        .weight_payload_bytes_o(weight_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .writes_completed_o(writes_completed_o),
        .write_bytes_o(write_bytes_o),
        .child_active_cycles_o(child_active_cycles_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .portal_request_groups_o(portal_request_groups_o),
        .portal_response_groups_o(portal_response_groups_o),
        .portal_blocks_o(portal_blocks_o),
        .portal_bytes_o(portal_bytes_o),
        .portal_outstanding_o(portal_outstanding_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    integer global_cycles;
    integer scenario_count;
    integer completion_pulses;
    integer commit_pulses;
    reg drain_seen_q;

    function automatic logic [31:0] load_u32(input logic [63:0] addr);
        begin
            load_u32 = {gmem[(addr-MEM_BASE)+3],
                        gmem[(addr-MEM_BASE)+2],
                        gmem[(addr-MEM_BASE)+1],
                        gmem[(addr-MEM_BASE)+0]};
        end
    endfunction

    function automatic logic [63:0] load_u64(input logic [63:0] addr);
        begin
            load_u64 = {gmem[(addr-MEM_BASE)+7],
                        gmem[(addr-MEM_BASE)+6],
                        gmem[(addr-MEM_BASE)+5],
                        gmem[(addr-MEM_BASE)+4],
                        gmem[(addr-MEM_BASE)+3],
                        gmem[(addr-MEM_BASE)+2],
                        gmem[(addr-MEM_BASE)+1],
                        gmem[(addr-MEM_BASE)+0]};
        end
    endfunction

    function automatic logic [271:0] load_q8_block(
        input logic [63:0] addr);
        integer block_byte;
        begin
            load_q8_block = 272'b0;
            for (block_byte = 0; block_byte < 34;
                 block_byte = block_byte + 1) begin
                load_q8_block[(block_byte*8) +: 8]
                    = gmem[(addr-MEM_BASE)+block_byte];
            end
        end
    endfunction

    task automatic store_u32(
        input logic [63:0] addr,
        input logic [31:0] bits);
        begin
            gmem[(addr-MEM_BASE)+0] = bits[7:0];
            gmem[(addr-MEM_BASE)+1] = bits[15:8];
            gmem[(addr-MEM_BASE)+2] = bits[23:16];
            gmem[(addr-MEM_BASE)+3] = bits[31:24];
        end
    endtask

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-GEMV-PORTAL][FAIL] %s cycle=%0d state=%0d err=%0d child=%0h raw_out=%0b portal_out=%0b",
                     reason, global_cycles, dut.state_q, error_code_o,
                     child_error_code_o, gmem_outstanding_o,
                     portal_outstanding_o);
            $display("[NPU-Q8-GEMV-PORTAL][EVIDENCE] act=%0d weight=%0d rows=%0d raw=%0d/%0d portal_groups=%0d/%0d portal_blocks=%0d portal_bytes=%0d writes=%0d/%0d commit=%0d",
                     activation_words_accepted_o,
                     weight_blocks_accepted_o, rows_written_o,
                     gmem_read_beats_o, gmem_read_beats_completed_o,
                     portal_request_groups_o, portal_response_groups_o,
                     portal_blocks_o, portal_bytes_o,
                     gmem_write_beats_o, writes_completed_o, commit_pulses);
            $fatal(1);
        end
    endtask

    integer init_index;
    integer init_row;
    integer init_block;
    integer init_q;
    logic [63:0] init_addr;
    logic [15:0] init_scale;
    task automatic initialize_memory;
        begin
            for (init_index = 0; init_index < MEM_BYTES;
                 init_index = init_index + 1)
                gmem[init_index] = 8'ha5;

            for (init_index = 0; init_index < (POS_BLOCKS*32);
                 init_index = init_index + 1) begin
                case (init_index & 3)
                    0: store_u32(ACT_BASE + init_index*4, 32'h3f800000);
                    1: store_u32(ACT_BASE + init_index*4, 32'hbf800000);
                    2: store_u32(ACT_BASE + init_index*4, 32'h3f000000);
                    default:
                       store_u32(ACT_BASE + init_index*4, 32'hbe800000);
                endcase
            end

            for (init_row = 0; init_row < POS_ROWS;
                 init_row = init_row + 1) begin
                for (init_block = 0; init_block < POS_BLOCKS;
                     init_block = init_block + 1) begin
                    init_addr = WT_BASE + init_row*WT_STRIDE
                              + init_block*34;
                    init_scale = ((init_row + init_block) & 1)
                               ? 16'h3800 : 16'h3c00;
                    gmem[(init_addr-MEM_BASE)+0] = init_scale[7:0];
                    gmem[(init_addr-MEM_BASE)+1] = init_scale[15:8];
                    for (init_q = 0; init_q < 32; init_q = init_q + 1)
                        gmem[(init_addr-MEM_BASE)+2+init_q]
                            = (init_row*29 + init_block*11
                               + init_q*7 + 3) & 8'hff;
                end
            end

            for (init_index = 0; init_index < 512;
                 init_index = init_index + 1)
                gmem[(DST_WIN-MEM_BASE)+init_index] = 8'h5a;
        end
    endtask

    // ------------------------------------------------------------------
    // Raw GMEM model with deterministic request backpressure and response
    // latency.  Writes become visible only on a successful response.
    // ------------------------------------------------------------------
    reg raw_pending_q;
    reg raw_pending_write_q;
    reg [63:0] raw_pending_addr_q;
    reg [63:0] raw_pending_wdata_q;
    reg [7:0] raw_pending_wstrb_q;
    reg raw_pending_error_q;
    integer raw_pending_delay_q;
    integer raw_req_hold_count_q;
    integer raw_req_backpressure_cycles;
    integer raw_rsp_latency_cycles;
    integer accepted_raw_reads;
    integer accepted_raw_writes;
    reg inject_raw_error_q;

    reg raw_hold_active_q;
    reg raw_held_write_q;
    reg [63:0] raw_held_addr_q;
    reg [63:0] raw_held_wdata_q;
    reg [7:0] raw_held_wstrb_q;

    assign gmem_req_ready_i = !rst_i
                            && !raw_pending_q
                            && !gmem_rsp_valid_i
                            && (raw_req_hold_count_q >= 2);

    // ------------------------------------------------------------------
    // Portal byte-copy model.  It does not dequantize, dot, add, or inspect a
    // destination.  The request checker independently proves tile/block/lane
    // order and exact addresses seen at the boundary.
    // ------------------------------------------------------------------
    reg portal_pending_q;
    reg [ROW_LANES-1:0] portal_pending_mask_q;
    reg [(ROW_LANES*272)-1:0] portal_pending_blocks_q;
    reg portal_pending_error_q;
    reg portal_pending_wrong_mask_q;
    integer portal_pending_delay_q;
    integer portal_req_hold_count_q;
    integer portal_req_backpressure_cycles;
    integer portal_rsp_backpressure_cycles;
    integer accepted_portal_requests;
    reg inject_wrong_mask_q;
    reg inject_portal_error_q;
    reg inject_portal_stall_q;

    reg portal_hold_active_q;
    reg [ROW_LANES-1:0] portal_held_mask_q;
    reg [(ROW_LANES*64)-1:0] portal_held_addr_q;
    reg portal_rsp_hold_active_q;
    reg [ROW_LANES-1:0] portal_rsp_held_mask_q;
    reg [(ROW_LANES*272)-1:0] portal_rsp_held_blocks_q;
    reg portal_rsp_held_error_q;

    assign portal_req_ready_i = !rst_i
                              && !portal_pending_q
                              && !portal_rsp_valid_i
                              && (portal_req_hold_count_q >= 3);

    integer model_lane;
    integer model_byte;
    integer model_tile;
    integer model_block;
    integer apply_byte;
    reg [ROW_LANES-1:0] expected_portal_mask_r;
    reg [63:0] expected_portal_addr_r;

    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (rst_i) begin
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            raw_pending_q <= 1'b0;
            raw_pending_write_q <= 1'b0;
            raw_pending_addr_q <= 64'b0;
            raw_pending_wdata_q <= 64'b0;
            raw_pending_wstrb_q <= 8'b0;
            raw_pending_error_q <= 1'b0;
            raw_pending_delay_q <= 0;
            raw_req_hold_count_q <= 0;
            raw_req_backpressure_cycles <= 0;
            raw_rsp_latency_cycles <= 0;
            accepted_raw_reads <= 0;
            accepted_raw_writes <= 0;
            raw_hold_active_q <= 1'b0;

            portal_rsp_valid_i <= 1'b0;
            portal_rsp_mask_i <= {ROW_LANES{1'b0}};
            portal_rsp_blocks_i <= {(ROW_LANES*272){1'b0}};
            portal_rsp_error_i <= 1'b0;
            portal_pending_q <= 1'b0;
            portal_pending_mask_q <= {ROW_LANES{1'b0}};
            portal_pending_blocks_q <= {(ROW_LANES*272){1'b0}};
            portal_pending_error_q <= 1'b0;
            portal_pending_wrong_mask_q <= 1'b0;
            portal_pending_delay_q <= 0;
            portal_req_hold_count_q <= 0;
            portal_req_backpressure_cycles <= 0;
            portal_rsp_backpressure_cycles <= 0;
            accepted_portal_requests <= 0;
            portal_hold_active_q <= 1'b0;
            portal_rsp_hold_active_q <= 1'b0;
            completion_pulses <= 0;
            commit_pulses <= 0;
            drain_seen_q <= 1'b0;
        end else begin
            if (completion_valid_o)
                completion_pulses <= completion_pulses + 1;
            if (dst_commit_o)
                commit_pulses <= commit_pulses + 1;
            if (dut.state_q == ST_DRAIN)
                drain_seen_q <= 1'b1;

            // Outgoing raw request must remain stable for its complete stall.
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                raw_req_backpressure_cycles
                    <= raw_req_backpressure_cycles + 1;
                if (!raw_hold_active_q) begin
                    raw_hold_active_q <= 1'b1;
                    raw_held_write_q <= gmem_req_write_o;
                    raw_held_addr_q <= gmem_req_addr_o;
                    raw_held_wdata_q <= gmem_req_wdata_o;
                    raw_held_wstrb_q <= gmem_req_wstrb_o;
                end else if ((raw_held_write_q != gmem_req_write_o)
                             || (raw_held_addr_q != gmem_req_addr_o)
                             || (raw_held_wdata_q != gmem_req_wdata_o)
                             || (raw_held_wstrb_q != gmem_req_wstrb_o)) begin
                    fail_case("raw request payload changed under backpressure");
                end
            end else if (raw_hold_active_q) begin
                if (!(gmem_req_valid_o && gmem_req_ready_i))
                    fail_case("raw request valid retracted before acceptance");
                raw_hold_active_q <= 1'b0;
            end

            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                if (raw_req_hold_count_q < 2)
                    raw_req_hold_count_q <= raw_req_hold_count_q + 1;
            end else if (gmem_req_valid_o && gmem_req_ready_i) begin
                raw_req_hold_count_q <= 0;
            end else begin
                raw_req_hold_count_q <= 0;
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if ((gmem_req_addr_o < MEM_BASE)
                    || ((gmem_req_addr_o + 64'd8) > MEM_LIMIT))
                    fail_case("raw request outside test memory");
                raw_pending_q <= 1'b1;
                raw_pending_write_q <= gmem_req_write_o;
                raw_pending_addr_q <= gmem_req_addr_o;
                raw_pending_wdata_q <= gmem_req_wdata_o;
                raw_pending_wstrb_q <= gmem_req_wstrb_o;
                raw_pending_delay_q <= gmem_req_write_o ? 3 : 2;
                raw_rsp_latency_cycles <= raw_rsp_latency_cycles
                                        + (gmem_req_write_o ? 3 : 2);
                if (gmem_req_write_o) begin
                    expected_portal_addr_r = DST_BASE
                                           + accepted_raw_writes*DST_STRIDE;
                    expected_portal_addr_r[2:0] = 3'b000;
                    if ((gmem_req_addr_o != expected_portal_addr_r)
                        || ((gmem_req_wstrb_o != 8'h0f)
                            && (gmem_req_wstrb_o != 8'hf0)))
                        fail_case("result write address/strobe order mismatch");
                    accepted_raw_writes <= accepted_raw_writes + 1;
                    raw_pending_error_q <= 1'b0;
                end else begin
                    if ((gmem_req_addr_o < ACT_WIN)
                        || ((gmem_req_addr_o + 64'd8)
                            > (ACT_WIN + 64'h400))) begin
                        fail_case("non-activation raw read observed");
                    end
                    raw_pending_error_q
                        <= inject_raw_error_q && (accepted_raw_reads == 0);
                    accepted_raw_reads <= accepted_raw_reads + 1;
                end
            end

            if (raw_pending_q && !gmem_rsp_valid_i) begin
                if (raw_pending_delay_q > 0)
                    raw_pending_delay_q <= raw_pending_delay_q - 1;
                else begin
                    raw_pending_q <= 1'b0;
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_error_i <= raw_pending_error_q;
                    gmem_rsp_rdata_i <= raw_pending_write_q
                                     ? 64'b0
                                     : load_u64(raw_pending_addr_q);
                end
            end
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (!gmem_rsp_error_i && raw_pending_write_q) begin
                    for (apply_byte = 0; apply_byte < 8;
                         apply_byte = apply_byte + 1) begin
                        if (raw_pending_wstrb_q[apply_byte])
                            gmem[(raw_pending_addr_q-MEM_BASE)+apply_byte]
                                <= raw_pending_wdata_q[(apply_byte*8) +: 8];
                    end
                end
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
            end

            // Outgoing portal request hold and exact address/order checks.
            if (portal_req_valid_o && !portal_req_ready_i) begin
                portal_req_backpressure_cycles
                    <= portal_req_backpressure_cycles + 1;
                if (!portal_hold_active_q) begin
                    portal_hold_active_q <= 1'b1;
                    portal_held_mask_q <= portal_req_mask_o;
                    portal_held_addr_q <= portal_req_addr_o;
                end else if ((portal_held_mask_q != portal_req_mask_o)
                             || (portal_held_addr_q != portal_req_addr_o)) begin
                    fail_case("portal request payload changed under backpressure");
                end
            end else if (portal_hold_active_q) begin
                if (!(portal_req_valid_o && portal_req_ready_i))
                    fail_case("portal request valid retracted before acceptance");
                portal_hold_active_q <= 1'b0;
            end

            if (portal_req_valid_o && !portal_req_ready_i) begin
                if (portal_req_hold_count_q < 3)
                    portal_req_hold_count_q <= portal_req_hold_count_q + 1;
            end else if (portal_req_valid_o && portal_req_ready_i) begin
                portal_req_hold_count_q <= 0;
            end else begin
                portal_req_hold_count_q <= 0;
            end

            if (portal_req_valid_o && portal_req_ready_i) begin
                model_tile = accepted_portal_requests / POS_BLOCKS;
                model_block = accepted_portal_requests % POS_BLOCKS;
                expected_portal_mask_r = {ROW_LANES{1'b0}};
                portal_pending_blocks_q <= {(ROW_LANES*272){1'b0}};
                for (model_lane = 0; model_lane < ROW_LANES;
                     model_lane = model_lane + 1) begin
                    if ((model_tile*ROW_LANES + model_lane) < POS_ROWS) begin
                        expected_portal_mask_r[model_lane] = 1'b1;
                        expected_portal_addr_r = WT_BASE
                            + (model_tile*ROW_LANES + model_lane)*WT_STRIDE
                            + model_block*34;
                        if (portal_req_addr_o[(model_lane*64) +: 64]
                            != expected_portal_addr_r) begin
                            fail_case("portal lane address/order mismatch");
                        end
                        portal_pending_blocks_q[(model_lane*272) +: 272]
                            <= load_q8_block(expected_portal_addr_r);
                    end else if (portal_req_addr_o[(model_lane*64) +: 64]
                                 != 64'b0) begin
                        fail_case("inactive portal lane address not zero");
                    end
                end
                if (portal_req_mask_o != expected_portal_mask_r)
                    fail_case("portal request tail mask mismatch");
                portal_pending_q <= 1'b1;
                portal_pending_mask_q <= portal_req_mask_o;
                portal_pending_error_q
                    <= inject_portal_error_q
                       && (accepted_portal_requests == 0);
                portal_pending_wrong_mask_q
                    <= inject_wrong_mask_q
                       && (accepted_portal_requests == 0);
                portal_pending_delay_q <= inject_portal_stall_q ? 540 : 1;
                accepted_portal_requests <= accepted_portal_requests + 1;
            end

            if (portal_pending_q && !portal_rsp_valid_i) begin
                if (portal_pending_delay_q > 0)
                    portal_pending_delay_q <= portal_pending_delay_q - 1;
                else begin
                    portal_pending_q <= 1'b0;
                    portal_rsp_valid_i <= 1'b1;
                    portal_rsp_mask_i <= portal_pending_wrong_mask_q
                                       ? (portal_pending_mask_q
                                          ^ {{(ROW_LANES-2){1'b0}}, 2'b10})
                                       : portal_pending_mask_q;
                    portal_rsp_blocks_i <= portal_pending_blocks_q;
                    portal_rsp_error_i <= portal_pending_error_q;
                end
            end

            // The byte-copy source also proves its response payload remains
            // stable while the adapter withholds credit.
            if (portal_rsp_valid_i && !portal_rsp_ready_o) begin
                portal_rsp_backpressure_cycles
                    <= portal_rsp_backpressure_cycles + 1;
                if (!portal_rsp_hold_active_q) begin
                    portal_rsp_hold_active_q <= 1'b1;
                    portal_rsp_held_mask_q <= portal_rsp_mask_i;
                    portal_rsp_held_blocks_q <= portal_rsp_blocks_i;
                    portal_rsp_held_error_q <= portal_rsp_error_i;
                end else if ((portal_rsp_held_mask_q != portal_rsp_mask_i)
                             || (portal_rsp_held_blocks_q
                                 != portal_rsp_blocks_i)
                             || (portal_rsp_held_error_q
                                 != portal_rsp_error_i)) begin
                    fail_case("portal response payload changed under backpressure");
                end
            end else if (portal_rsp_hold_active_q) begin
                if (!(portal_rsp_valid_i && portal_rsp_ready_o))
                    fail_case("portal response valid retracted before acceptance");
                portal_rsp_hold_active_q <= 1'b0;
            end

            if (portal_rsp_valid_i && portal_rsp_ready_o) begin
                portal_rsp_valid_i <= 1'b0;
                portal_rsp_error_i <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Independent public RTL numerical oracle.
    // ------------------------------------------------------------------
    reg oracle_rst_q;
    reg oracle_quant_start_q;
    wire oracle_quant_ready_w;
    reg oracle_quant_valid_q;
    wire oracle_quant_input_ready_w;
    reg [31:0] oracle_quant_bits_q;
    wire oracle_quant_done_w;
    wire oracle_quant_error_w;
    wire [3:0] oracle_quant_error_code_w;
    wire [271:0] oracle_quant_block_w;
    reg [271:0] oracle_activation_block_q [0:POS_BLOCKS-1];

    TensorNpuQ8ReferenceQuantizer u_oracle_quantizer (
        .clk_i(clk_i),
        .rst_i(oracle_rst_q),
        .start_i(oracle_quant_start_q),
        .ready_o(oracle_quant_ready_w),
        .busy_o(),
        .input_valid_i(oracle_quant_valid_q),
        .input_ready_o(oracle_quant_input_ready_w),
        .input_bits_i(oracle_quant_bits_q),
        .done_o(oracle_quant_done_w),
        .error_o(oracle_quant_error_w),
        .error_code_o(oracle_quant_error_code_w),
        .block_o(oracle_quant_block_w),
        .active_cycles_o()
    );

    reg [ROW_LANES-1:0] oracle_acc_start_q;
    wire [ROW_LANES-1:0] oracle_acc_ready_w;
    reg [ROW_LANES-1:0] oracle_acc_block_valid_q;
    wire [ROW_LANES-1:0] oracle_acc_block_ready_w;
    reg [(ROW_LANES*272)-1:0] oracle_acc_x_q;
    reg [(ROW_LANES*272)-1:0] oracle_acc_y_q;
    wire [ROW_LANES-1:0] oracle_acc_done_w;
    wire [ROW_LANES-1:0] oracle_acc_error_w;
    wire [(ROW_LANES*4)-1:0] oracle_acc_error_code_w;
    wire [(ROW_LANES*32)-1:0] oracle_acc_result_w;
    reg [31:0] oracle_result_q [0:POS_ROWS-1];

    genvar oracle_lane;
    generate
        for (oracle_lane = 0; oracle_lane < ROW_LANES;
             oracle_lane = oracle_lane + 1) begin : gen_oracle_accumulator
            TensorNpuQ8ScaleAccumulator #(
                .MAC_LANES(MAC_LANES)
            ) u_accumulator (
                .clk_i(clk_i),
                .rst_i(oracle_rst_q),
                .start_i(oracle_acc_start_q[oracle_lane]),
                .ready_o(oracle_acc_ready_w[oracle_lane]),
                .busy_o(),
                .block_count_i(POS_BLOCKS),
                .block_valid_i(oracle_acc_block_valid_q[oracle_lane]),
                .block_ready_o(oracle_acc_block_ready_w[oracle_lane]),
                .x_block_i(oracle_acc_x_q[(oracle_lane*272) +: 272]),
                .y_block_i(oracle_acc_y_q[(oracle_lane*272) +: 272]),
                .done_o(oracle_acc_done_w[oracle_lane]),
                .error_o(oracle_acc_error_w[oracle_lane]),
                .error_code_o(oracle_acc_error_code_w[
                    (oracle_lane*4) +: 4]),
                .result_bits_o(oracle_acc_result_w[
                    (oracle_lane*32) +: 32])
            );
        end
    endgenerate

    integer oracle_block;
    integer oracle_word;
    integer oracle_tile;
    integer oracle_row;
    integer oracle_drive_lane;
    reg [ROW_LANES-1:0] oracle_active_mask_r;
    task automatic build_rtl_oracle;
        begin
            oracle_rst_q = 1'b1;
            oracle_quant_start_q = 1'b0;
            oracle_quant_valid_q = 1'b0;
            oracle_quant_bits_q = 32'b0;
            oracle_acc_start_q = {ROW_LANES{1'b0}};
            oracle_acc_block_valid_q = {ROW_LANES{1'b0}};
            oracle_acc_x_q = {(ROW_LANES*272){1'b0}};
            oracle_acc_y_q = {(ROW_LANES*272){1'b0}};
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            oracle_rst_q = 1'b0;

            for (oracle_block = 0; oracle_block < POS_BLOCKS;
                 oracle_block = oracle_block + 1) begin
                while (!oracle_quant_ready_w) @(negedge clk_i);
                oracle_quant_start_q = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                oracle_quant_start_q = 1'b0;
                for (oracle_word = 0; oracle_word < 32;
                     oracle_word = oracle_word + 1) begin
                    while (!oracle_quant_input_ready_w) @(negedge clk_i);
                    oracle_quant_bits_q = load_u32(
                        ACT_BASE + (oracle_block*32 + oracle_word)*4);
                    oracle_quant_valid_q = 1'b1;
                    @(posedge clk_i);
                    @(negedge clk_i);
                    oracle_quant_valid_q = 1'b0;
                end
                while (!oracle_quant_done_w && !oracle_quant_error_w)
                    @(negedge clk_i);
                if (oracle_quant_error_w) begin
                    fail_case("public activation oracle failed");
                end
                oracle_activation_block_q[oracle_block]
                    = oracle_quant_block_w;
                @(posedge clk_i);
                @(negedge clk_i);
            end

            for (oracle_tile = 0; oracle_tile < 2;
                 oracle_tile = oracle_tile + 1) begin
                oracle_active_mask_r = (oracle_tile == 0) ? 4'b1111
                                                          : 4'b0001;
                while ((oracle_acc_ready_w & oracle_active_mask_r)
                       != oracle_active_mask_r)
                    @(negedge clk_i);
                oracle_acc_start_q = oracle_active_mask_r;
                @(posedge clk_i);
                @(negedge clk_i);
                oracle_acc_start_q = {ROW_LANES{1'b0}};

                for (oracle_block = 0; oracle_block < POS_BLOCKS;
                     oracle_block = oracle_block + 1) begin
                    while ((oracle_acc_block_ready_w & oracle_active_mask_r)
                           != oracle_active_mask_r)
                        @(negedge clk_i);
                    for (oracle_drive_lane = 0;
                         oracle_drive_lane < ROW_LANES;
                         oracle_drive_lane = oracle_drive_lane + 1) begin
                        oracle_row = oracle_tile*ROW_LANES
                                   + oracle_drive_lane;
                        if (oracle_active_mask_r[oracle_drive_lane]) begin
                            oracle_acc_x_q[(oracle_drive_lane*272) +: 272]
                                = load_q8_block(WT_BASE
                                    + oracle_row*WT_STRIDE
                                    + oracle_block*34);
                            oracle_acc_y_q[(oracle_drive_lane*272) +: 272]
                                = oracle_activation_block_q[oracle_block];
                        end
                    end
                    oracle_acc_block_valid_q = oracle_active_mask_r;
                    @(posedge clk_i);
                    @(negedge clk_i);
                    oracle_acc_block_valid_q = {ROW_LANES{1'b0}};
                end

                while ((oracle_acc_done_w & oracle_active_mask_r)
                       != oracle_active_mask_r)
                    @(negedge clk_i);
                if ((oracle_acc_error_w & oracle_active_mask_r)
                    != {ROW_LANES{1'b0}})
                    fail_case("public scale-accumulator oracle failed");
                for (oracle_drive_lane = 0;
                     oracle_drive_lane < ROW_LANES;
                     oracle_drive_lane = oracle_drive_lane + 1) begin
                    oracle_row = oracle_tile*ROW_LANES + oracle_drive_lane;
                    if (oracle_active_mask_r[oracle_drive_lane])
                        oracle_result_q[oracle_row]
                            = oracle_acc_result_w[
                                (oracle_drive_lane*32) +: 32];
                end
                @(posedge clk_i);
                @(negedge clk_i);
            end
        end
    endtask

    task automatic set_valid_descriptor(input logic [63:0] command_id);
        begin
            command_id_i = command_id;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            activation_base_i = ACT_BASE;
            weight_base_i = WT_BASE;
            dst_base_i = DST_BASE;
            row_count_i = POS_ROWS;
            block_count_i = POS_BLOCKS;
            weight_row_stride_i = WT_STRIDE;
            dst_row_stride_i = DST_STRIDE;
            activation_window_base_i = ACT_WIN;
            activation_window_bytes_i = 64'h400;
            activation_window_read_i = 1'b1;
            activation_window_write_i = 1'b0;
            weight_window_base_i = WT_WIN;
            weight_window_bytes_i = 64'h200;
            weight_window_read_i = 1'b1;
            weight_window_write_i = 1'b0;
            dst_window_base_i = DST_WIN;
            dst_window_bytes_i = 64'h200;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic reset_transaction;
        begin
            @(negedge clk_i);
            rst_i = 1'b1;
            start_i = 1'b0;
            inject_raw_error_q = 1'b0;
            inject_wrong_mask_q = 1'b0;
            inject_portal_error_q = 1'b0;
            inject_portal_stall_q = 1'b0;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            while (!ready_o) @(negedge clk_i);
        end
    endtask

    task automatic launch_command;
        begin
            while (!ready_o) @(negedge clk_i);
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if (!busy_o)
                fail_case("command was not accepted");
        end
    endtask

    task automatic wait_terminal(input integer max_cycles);
        integer wait_count;
        begin
            wait_count = 0;
            while (!completion_valid_o && (wait_count < max_cycles)) begin
                @(negedge clk_i);
                wait_count = wait_count + 1;
            end
            if (!completion_valid_o)
                fail_case("terminal timeout");
            if (gmem_outstanding_o || portal_outstanding_o)
                fail_case("terminal exposed before transport drain");
        end
    endtask

    integer check_row;
    integer check_byte;
    task automatic run_positive;
        begin
            scenario_count = scenario_count + 1;
            reset_transaction();
            set_valid_descriptor(64'h0123_4567_89ab_cdef);
            launch_command();

            // Busy-start mutation must not alter resident identity or spans.
            command_id_i = 64'hdead_beef_dead_beef;
            activation_base_i = 64'hffff_ffff_ffff_fffc;
            weight_base_i = 64'hffff_ffff_ffff_fffe;
            dst_base_i = 64'hffff_ffff_ffff_fffc;
            row_count_i = 32'hffff_ffff;
            block_count_i = 32'hffff_ffff;
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            set_valid_descriptor(64'h0123_4567_89ab_cdef);

            wait_terminal(200000);
            if (!done_o || error_o || !dst_commit_o)
                fail_case("positive command did not commit exactly once");
            if ((completion_command_id_o != 64'h0123_4567_89ab_cdef)
                || (completion_kernel_id_o != KERNEL_ID)
                || (completion_row_count_o != POS_ROWS)
                || (completion_block_count_o != POS_BLOCKS))
                fail_case("completion identity mutated while busy");
            for (check_row = 0; check_row < POS_ROWS;
                 check_row = check_row + 1) begin
                if (load_u32(DST_BASE + check_row*DST_STRIDE)
                    !== oracle_result_q[check_row])
                    fail_case("raw destination bits differ from RTL oracle");
            end
            if ((activation_words_accepted_o != 64)
                || (weight_blocks_accepted_o != 10)
                || (rows_written_o != 5)
                || (activation_payload_bytes_o != 256)
                || (weight_payload_bytes_o != 340)
                || (gmem_read_beats_o != gmem_read_beats_completed_o)
                || (gmem_read_bytes_o != (gmem_read_beats_o*8))
                || (gmem_write_beats_o != 5)
                || (writes_completed_o != 5)
                || (write_bytes_o != 20)
                || (portal_request_groups_o != 4)
                || (portal_response_groups_o != 4)
                || (portal_blocks_o != 10)
                || (portal_bytes_o != 340))
                fail_case("positive exact counter closure failed");
            if ((raw_req_backpressure_cycles == 0)
                || (portal_req_backpressure_cycles == 0)
                || ((TILE_FUNCTIONAL_ENABLE == 0)
                    && (portal_rsp_backpressure_cycles == 0))
                || (raw_rsp_latency_cycles == 0))
                fail_case("required transport backpressure/latency absent");
            if ((child_active_cycles_o == 0)
                || (active_cycles_o < child_active_cycles_o))
                fail_case("positive terminal/cycle accounting mismatch");
            $display("[NPU-Q8-GEMV-PORTAL][POSITIVE] rows=5 blocks=2 tail_mask=1 unaligned_weight=1 raw=%0d/%0d portal=%0d/%0d portal_bp=%0d write_bp=%0d",
                     gmem_read_beats_o, gmem_read_beats_completed_o,
                     portal_request_groups_o, portal_response_groups_o,
                     portal_rsp_backpressure_cycles,
                     raw_req_backpressure_cycles);
            @(posedge clk_i);
            @(negedge clk_i);
            if ((completion_pulses != 1) || (commit_pulses != 1)
                || completion_valid_o || !ready_o)
                fail_case("positive terminal was not an exact one-cycle pulse");
        end
    endtask

    task automatic run_error_case(
        input integer mode,
        input logic [4:0] expected_error,
        input string case_name);
        logic [31:0] dst_before [0:POS_ROWS-1];
        begin
            scenario_count = scenario_count + 1;
            for (check_row = 0; check_row < POS_ROWS;
                 check_row = check_row + 1) begin
                store_u32(DST_BASE + check_row*DST_STRIDE, 32'h5a5a5a5a);
                dst_before[check_row]
                    = load_u32(DST_BASE + check_row*DST_STRIDE);
            end
            reset_transaction();
            set_valid_descriptor(64'h1000_0000_0000_0000 + mode);
            case (mode)
                0: inject_wrong_mask_q = 1'b1;
                1: inject_portal_error_q = 1'b1;
                2: inject_raw_error_q = 1'b1;
                3: weight_window_bytes_i = 64'h100;
                4: begin
                    dst_base_i = WT_BASE + 64'd2;
                    dst_window_base_i = WT_WIN;
                    dst_window_bytes_i = 64'h200;
                end
                5: inject_portal_stall_q = 1'b1;
                default: fail_case("unknown negative-test mode");
            endcase
            launch_command();
            wait_terminal(200000);
            if (!error_o || done_o || dst_commit_o
                || (error_code_o != expected_error))
                fail_case({"negative case mismatch: ", case_name});
            if ((completion_command_id_o
                 != (64'h1000_0000_0000_0000 + mode))
                || (completion_kernel_id_o != KERNEL_ID))
                fail_case({"negative identity/publication mismatch: ",
                           case_name});
            if ((mode != 4)) begin
                for (check_row = 0; check_row < POS_ROWS;
                     check_row = check_row + 1) begin
                    if (load_u32(DST_BASE + check_row*DST_STRIDE)
                        !== dst_before[check_row])
                        fail_case({"private destination changed before error: ",
                                   case_name});
                end
            end
            if ((mode == 5) && !drain_seen_q)
                fail_case("portal stall timeout skipped error drain");
            $display("[NPU-Q8-GEMV-PORTAL][NEGATIVE] case=%s error=%0d drain=%0b raw=%0d/%0d portal=%0d/%0d commit=0",
                     case_name, error_code_o, drain_seen_q,
                     gmem_read_beats_o, gmem_read_beats_completed_o,
                     portal_request_groups_o, portal_response_groups_o);
            @(posedge clk_i);
            @(negedge clk_i);
            if ((completion_pulses != 1) || (commit_pulses != 0)
                || completion_valid_o || !ready_o)
                fail_case({"negative terminal pulse mismatch: ", case_name});
        end
    endtask

    initial begin
        global_cycles = 0;
        scenario_count = 0;
        rst_i = 1'b1;
        start_i = 1'b0;
        oracle_rst_q = 1'b1;
        oracle_quant_start_q = 1'b0;
        oracle_quant_valid_q = 1'b0;
        oracle_quant_bits_q = 32'b0;
        oracle_acc_start_q = {ROW_LANES{1'b0}};
        oracle_acc_block_valid_q = {ROW_LANES{1'b0}};
        oracle_acc_x_q = {(ROW_LANES*272){1'b0}};
        oracle_acc_y_q = {(ROW_LANES*272){1'b0}};
        inject_raw_error_q = 1'b0;
        inject_wrong_mask_q = 1'b0;
        inject_portal_error_q = 1'b0;
        inject_portal_stall_q = 1'b0;
        set_valid_descriptor(64'b0);
        initialize_memory();
        build_rtl_oracle();
        run_positive();
        run_error_case(0, ERR_PORTAL_MASK, "wrong_response_mask");
        run_error_case(1, ERR_PORTAL_RSP, "portal_response_error");
        run_error_case(2, ERR_GMEM, "raw_response_error");
        run_error_case(3, ERR_WEIGHT_WIN, "weight_capability_oob");
        run_error_case(4, ERR_ALIAS, "destination_source_alias");
        run_error_case(5, ERR_STALL, "portal_timeout_drain");
        if (scenario_count != 7)
            fail_case("scenario accounting mismatch");
        $display("[NPU-Q8-GEMV-PORTAL][PASS] scenarios=7 row_lanes=4 mac_lanes=32 oracle_quantizer=1 oracle_accumulators=4 tail_tile=1 unaligned_weight=1 portal_drain=1 no_host_fp=1");
        $finish;
    end

    /* verilator lint_on PINCONNECTEMPTY */
    /* verilator lint_on BLKSEQ */
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */

endmodule

`default_nettype wire
