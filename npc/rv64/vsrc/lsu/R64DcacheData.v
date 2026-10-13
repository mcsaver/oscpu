// ECOS55 SRAM adaptation: the real 256x64 macro has one read/write port.
// Each bank keeps two merging byte-write entries so B/refill can overlap
// lookups. Byte masks expand to the macro's active-low bit enables. Accepted
// writes remain lookup-visible until drain; four reads bound write starvation.
module R64DcacheData #(
  parameter ADDR_W = 8,
  parameter WORDS = (1 << ADDR_W)
) (
  input clk_i,
  input rst_i,
  input read_i,
  output read_ready_o,
  input [ADDR_W-1:0] read_addr_i,
  output [63:0] read_data0_o,
  output [63:0] read_data1_o,
  input write_i,
  output write_ready_o,
  input probe_way_i,
  input [ADDR_W-1:0] probe_addr_i,
  output probe_ready_o,
  input write_way_i,
  input [ADDR_W-1:0] write_addr_i,
  input [63:0] write_data_i,
  input [7:0] write_mask_i,
  output idle_o,
  output forward_o
);
  reg [1:0] valid_q, way_q;
  reg [ADDR_W-1:0] index_q [0:1];
  reg [63:0] data_q [0:1];
  reg [7:0] mask_q [0:1];
  reg head_q;
  reg [2:0] read_run_q;
  wire dirty_w = |valid_q;
  wire read_fire_w = read_i && read_ready_o;
  wire begin_drain_w = dirty_w && !read_fire_w;
  wire macro_write_w = begin_drain_w;
  wire pop_w = macro_write_w;
  wire locked_w = begin_drain_w;
  wire [1:0] match_w = {
    valid_q[1] && way_q[1] == write_way_i && index_q[1] == write_addr_i,
    valid_q[0] && way_q[0] == write_way_i && index_q[0] == write_addr_i
  };
  wire match_any_w = |match_w;
  wire write_slot_w = match_any_w ? match_w[1] : valid_q[0];
  // write_i is the caller's accepted logical event. Its source has already
  // consumed B Q-credit or refill credit; do not requalify B with live lookup.
  wire write_fire_w = write_i;
  assign read_ready_o = !rst_i && !(dirty_w && read_run_q == 4);
  assign write_ready_o = !rst_i && (match_any_w ?
      !(locked_w && write_slot_w == head_q) : valid_q != 2'b11);
  // ECOS55 SRAM adaptation: B credit uses only FIFO Q and its registered
  // owner key. Freeze the occupied head even during a lookup; otherwise
  // lookup -> drain/lock -> B terminal recreates a cross-domain timing path.
  // Tail merge or a real empty slot is safe whether the old head drains or
  // reads win this cycle. Never borrow a slot from the same-edge drain.
  wire [1:0] probe_match_w = {
    valid_q[1] && way_q[1] == probe_way_i && index_q[1] == probe_addr_i,
    valid_q[0] && way_q[0] == probe_way_i && index_q[0] == probe_addr_i
  };
  assign probe_ready_o = !rst_i && ((|probe_match_w) ?
      probe_match_w[1] != head_q : valid_q != 2'b11);
  assign idle_o = !dirty_w;

  wire [63:0] macro_data_w[0:1];
  wire [63:0] full_write_w = data_q[head_q];
  wire [63:0] bit_enable_w;
  integer by;
  genvar bit_byte;
  generate
    for (bit_byte = 0; bit_byte < 8; bit_byte = bit_byte + 1) begin : g_mask
      assign bit_enable_w[bit_byte*8+:8] = {8{!mask_q[head_q][bit_byte]}};
    end
  endgenerate
  always @(posedge clk_i) begin
    if (rst_i) begin
      valid_q <= 0;
      head_q <= 0;
      read_run_q <= 0;
    end else begin
      if (!dirty_w || begin_drain_w) read_run_q <= 0;
      else if (read_fire_w && read_run_q != 4) read_run_q <= read_run_q + 1'b1;
      if (pop_w) begin
        valid_q[head_q] <= 0;
        head_q <= !head_q;
      end
      if (write_fire_w) begin
        valid_q[write_slot_w] <= 1;
        way_q[write_slot_w] <= write_way_i;
        index_q[write_slot_w] <= write_addr_i;
        mask_q[write_slot_w] <= (match_any_w ? mask_q[write_slot_w] : 8'b0) | write_mask_i;
        for (by = 0; by < 8; by = by + 1)
          if (write_mask_i[by]) data_q[write_slot_w][by*8+:8] <= write_data_i[by*8+:8];
        if (!dirty_w) head_q <= write_slot_w;
      end
    end
  end

  // Snapshot the byte overlay at the lookup edge. Maintenance may subsequently
  // change macro Q, so retain a completed lookup before its first such access.
  reg [7:0] overlay_mask_q [0:1];
  reg [63:0] overlay_data_q [0:1];
  reg [7:0] overlay_mask_w [0:1];
  reg [63:0] overlay_data_w [0:1];
  reg [63:0] held_q [0:1];
  reg macro_lookup_q;
  wire macro_access_w = read_fire_w || macro_write_w;
  wire [63:0] visible_w[0:1];
  integer w, e, j;
  always @* begin
    for (w = 0; w < 2; w = w + 1) begin
      overlay_mask_w[w] = 0;
      overlay_data_w[w] = 0;
      for (e = 0; e < 2; e = e + 1)
        if (valid_q[e] && way_q[e] == w[0] && index_q[e] == read_addr_i) begin
          overlay_mask_w[w] = mask_q[e];
          overlay_data_w[w] = data_q[e];
        end
      if (write_fire_w && write_way_i == w[0] && write_addr_i == read_addr_i)
        for (j = 0; j < 8; j = j + 1)
          if (write_mask_i[j]) begin
            overlay_mask_w[w][j] = 1;
            overlay_data_w[w][j*8+:8] = write_data_i[j*8+:8];
          end
    end
  end
  assign forward_o = read_fire_w && (|overlay_mask_w[0] || |overlay_mask_w[1]);
  genvar way, byte_lane;
  generate
    for (way = 0; way < 2; way = way + 1) begin : g_way
      wire maintenance_w = macro_write_w && way_q[head_q] == way;
      wire read_w = read_fire_w;
      wire write_w = macro_write_w && way_q[head_q] == way;
      wire [ADDR_W-1:0] addr_w = maintenance_w ? index_q[head_q] : read_addr_i;
      if (ADDR_W == 8 && WORDS == 256) begin : g_ecos
        ics55_ecos_sram_256x64_m4 macro (
          .CLK(clk_i), .CEB(rst_i || !(read_w || write_w)), .GWEB(!write_w),
          .A(addr_w), .D(full_write_w), .WEB(bit_enable_w), .Q(macro_data_w[way]),
          .MARE(1'b0), .MAR(4'b0)
        );
      end else begin : g_generic
        // Parameterized test geometries use the same real single-port protocol.
        reg [63:0] memory_q [0:WORDS-1];
        reg [63:0] output_q;
        integer byte_index;
        always @(posedge clk_i)
          if (!rst_i) begin
            if (write_w) begin
              for (byte_index = 0; byte_index < 8; byte_index = byte_index + 1)
                if (mask_q[head_q][byte_index]) begin
                  memory_q[addr_w][byte_index*8+:8] <= full_write_w[byte_index*8+:8];
                  output_q[byte_index*8+:8] <= full_write_w[byte_index*8+:8];
                end
            end else if (read_w) output_q <= memory_q[addr_w];
          end
        assign macro_data_w[way] = output_q;
      end
      for (byte_lane = 0; byte_lane < 8; byte_lane = byte_lane + 1) begin : g_byte
        assign visible_w[way][byte_lane*8+:8] = overlay_mask_q[way][byte_lane] ?
            overlay_data_q[way][byte_lane*8+:8] : macro_data_w[way][byte_lane*8+:8];
      end
      always @(posedge clk_i) begin
        if (read_fire_w) begin
          overlay_mask_q[way] <= overlay_mask_w[way];
          overlay_data_q[way] <= overlay_data_w[way];
        end
        if (macro_access_w && !read_fire_w && macro_lookup_q)
          held_q[way] <= visible_w[way];
      end
    end
  endgenerate
  always @(posedge clk_i)
    if (rst_i) macro_lookup_q <= 0;
    else if (macro_access_w) macro_lookup_q <= read_fire_w;
  assign read_data0_o = macro_lookup_q ? visible_w[0] : held_q[0];
  assign read_data1_o = macro_lookup_q ? visible_w[1] : held_q[1];
`ifdef R64_ASSERT
  always @(posedge clk_i)
    if (!rst_i) begin
      if (read_i && !read_ready_o) $fatal(1, "DCache data read without macro grant");
      if (write_i && !write_ready_o) $fatal(1, "DCache data write without FIFO credit");
      if (valid_q == 3 && way_q[0] == way_q[1] && index_q[0] == index_q[1])
        $fatal(1, "DCache data FIFO duplicated a word version");
      if (dirty_w && !valid_q[head_q]) $fatal(1, "DCache data FIFO lost oldest owner");
      if (read_fire_w && macro_write_w)
        $fatal(1, "DCache data single port overbooked");
    end
`endif
endmodule
