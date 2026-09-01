`timescale 1ns/1ps

`include "tensor_npu_defs.vh"

module tb_dma_engine;

  localparam integer LMEM_BYTES       = 64;
  localparam integer GMEM_MODEL_BYTES = 256;
  localparam [63:0]  GMEM_MODEL_BYTES_64 = 64'd256;

  reg clk;
  reg rst;

  reg                          start;
  reg  [`NPU_OP_W-1:0]         op;
  reg  [5:0]                   dst_id;
  reg  [319:0]                 dst_desc;
  reg  [4:0]                   dst_words_valid;
  reg  [5:0]                   src_id;
  reg  [319:0]                 src_desc;
  reg  [4:0]                   src_words_valid;

  wire                         busy;
  wire                         done;
  wire                         error;
  wire [`NPU_ERROR_W-1:0]      error_code;
  wire [63:0]                  cycles;
  wire [63:0]                  bytes_done;

  wire                         dma_lmem_rd_valid;
  wire [31:0]                  dma_lmem_rd_addr;
  wire [3:0]                   dma_lmem_rd_bytes;
  wire [63:0]                  lmem_rd0_data;
  wire                         lmem_rd0_oob;
  wire [63:0]                  unused_lmem_rd1_data;
  wire                         unused_lmem_rd1_oob;
  wire                         dma_lmem_wr_valid;
  wire [31:0]                  dma_lmem_wr_addr;
  wire [63:0]                  dma_lmem_wr_data;
  wire [7:0]                   dma_lmem_wr_strb;
  wire                         lmem_wr_oob;

  reg                          tb_lmem_rd_valid;
  reg  [31:0]                  tb_lmem_rd_addr;
  reg  [3:0]                   tb_lmem_rd_bytes;
  reg                          tb_lmem_wr_valid;
  reg  [31:0]                  tb_lmem_wr_addr;
  reg  [63:0]                  tb_lmem_wr_data;
  reg  [7:0]                   tb_lmem_wr_strb;

  wire                         lmem_rd0_valid;
  wire [31:0]                  lmem_rd0_addr;
  wire [3:0]                   lmem_rd0_bytes;
  wire                         lmem_wr_valid;
  wire [31:0]                  lmem_wr_addr;
  wire [63:0]                  lmem_wr_data;
  wire [7:0]                   lmem_wr_strb;

  // DMA owns LMEM for its complete active interval.  Testbench initialization
  // and inspection use exactly the same public port only while the engine is
  // idle; no hierarchical memory access is used.
  assign lmem_rd0_valid = busy ? dma_lmem_rd_valid : tb_lmem_rd_valid;
  assign lmem_rd0_addr  = busy ? dma_lmem_rd_addr  : tb_lmem_rd_addr;
  assign lmem_rd0_bytes = busy ? dma_lmem_rd_bytes : tb_lmem_rd_bytes;
  assign lmem_wr_valid  = busy ? dma_lmem_wr_valid : tb_lmem_wr_valid;
  assign lmem_wr_addr   = busy ? dma_lmem_wr_addr  : tb_lmem_wr_addr;
  assign lmem_wr_data   = busy ? dma_lmem_wr_data  : tb_lmem_wr_data;
  assign lmem_wr_strb   = busy ? dma_lmem_wr_strb  : tb_lmem_wr_strb;

  wire                         gmem_req_valid;
  wire                         gmem_req_ready;
  wire                         gmem_req_write;
  wire [63:0]                  gmem_req_addr;
  wire [63:0]                  gmem_req_wdata;
  wire [7:0]                   gmem_req_wstrb;
  reg                          gmem_rsp_valid;
  wire                         gmem_rsp_ready;
  reg  [63:0]                  gmem_rsp_rdata;
  reg                          gmem_rsp_error;

  TensorNpuDmaEngine #(
    .LMEM_BYTES(LMEM_BYTES)
  ) dut (
    .clk_i                  (clk),
    .rst_i                  (rst),
    .start_i                (start),
    .op_i                   (op),
    .dst_id_i               (dst_id),
    .dst_desc_i             (dst_desc),
    .dst_words_valid_i      (dst_words_valid),
    .src_id_i               (src_id),
    .src_desc_i             (src_desc),
    .src_words_valid_i      (src_words_valid),
    .busy_o                 (busy),
    .done_o                 (done),
    .error_o                (error),
    .error_code_o           (error_code),
    .cycles_o               (cycles),
    .bytes_done_o           (bytes_done),
    .lmem_rd_valid_o        (dma_lmem_rd_valid),
    .lmem_rd_addr_o         (dma_lmem_rd_addr),
    .lmem_rd_bytes_o        (dma_lmem_rd_bytes),
    .lmem_rd_data_i         (lmem_rd0_data),
    .lmem_rd_oob_i          (lmem_rd0_oob),
    .lmem_wr_valid_o        (dma_lmem_wr_valid),
    .lmem_wr_addr_o         (dma_lmem_wr_addr),
    .lmem_wr_data_o         (dma_lmem_wr_data),
    .lmem_wr_strb_o         (dma_lmem_wr_strb),
    .lmem_wr_oob_i          (lmem_wr_oob),
    .gmem_req_valid_o       (gmem_req_valid),
    .gmem_req_ready_i       (gmem_req_ready),
    .gmem_req_write_o       (gmem_req_write),
    .gmem_req_addr_o        (gmem_req_addr),
    .gmem_req_wdata_o       (gmem_req_wdata),
    .gmem_req_wstrb_o       (gmem_req_wstrb),
    .gmem_rsp_valid_i       (gmem_rsp_valid),
    .gmem_rsp_ready_o       (gmem_rsp_ready),
    .gmem_rsp_rdata_i       (gmem_rsp_rdata),
    .gmem_rsp_error_i       (gmem_rsp_error)
  );

  TensorNpuLocalMemory #(
    .LMEM_BYTES(LMEM_BYTES)
  ) lmem (
    .clk                    (clk),
    .rd0_valid_i            (lmem_rd0_valid),
    .rd0_addr_i             (lmem_rd0_addr),
    .rd0_bytes_i            (lmem_rd0_bytes),
    .rd0_data_o             (lmem_rd0_data),
    .rd0_oob_o              (lmem_rd0_oob),
    .rd1_valid_i            (1'b0),
    .rd1_addr_i             (32'd0),
    .rd1_bytes_i            (4'd0),
    .rd1_data_o             (unused_lmem_rd1_data),
    .rd1_oob_o              (unused_lmem_rd1_oob),
    .wr_valid_i             (lmem_wr_valid),
    .wr_addr_i              (lmem_wr_addr),
    .wr_data_i              (lmem_wr_data),
    .wr_strb_i              (lmem_wr_strb),
    .wr_oob_o               (lmem_wr_oob)
  );

  // ------------------------------------------------------------------------
  // Byte-addressed single-outstanding GMEM model
  // ------------------------------------------------------------------------

  reg [7:0] gmem_bytes [0:GMEM_MODEL_BYTES-1];
  reg       model_pending;
  reg       pending_write;
  reg [7:0]  pending_addr;
  reg [63:0] pending_wdata;
  reg [7:0]  pending_wstrb;
  reg        pending_error;
  reg        inject_response_error;
  integer    response_delay;
  integer    ready_delay;
  integer    outstanding;
  integer    maximum_outstanding;
  integer    request_count;
  integer    response_count;
  integer    stalled_request_cycles;
  integer    error_response_drains;
  integer    model_index;
  integer    lane;

  assign gmem_req_ready = (!model_pending) && (!gmem_rsp_valid) &&
                          (ready_delay == 0);

  function automatic [63:0] gmem_read64(input [7:0] byte_addr);
    integer i;
    begin
      gmem_read64 = 64'd0;
      for (i = 0; i < 8; i = i + 1)
        gmem_read64[(8*i) +: 8] =
          gmem_bytes[byte_addr[7:0] + i[7:0]];
    end
  endfunction

  function automatic [7:0] select_byte64(
    input [63:0] value,
    input integer byte_lane
  );
    begin
      select_byte64 = value[(8*byte_lane) +: 8];
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      model_pending          <= 1'b0;
      pending_write          <= 1'b0;
      pending_addr           <= 8'd0;
      pending_wdata          <= 64'd0;
      pending_wstrb          <= 8'd0;
      pending_error          <= 1'b0;
      response_delay         <= 0;
      ready_delay            <= 2;
      gmem_rsp_valid         <= 1'b0;
      gmem_rsp_rdata         <= 64'd0;
      gmem_rsp_error         <= 1'b0;
      outstanding            <= 0;
      maximum_outstanding    <= 0;
      request_count          <= 0;
      response_count         <= 0;
      stalled_request_cycles <= 0;
      error_response_drains  <= 0;
    end else begin
      if (gmem_req_valid && !gmem_req_ready) begin
        stalled_request_cycles <= stalled_request_cycles + 1;
        if ((!model_pending) && (!gmem_rsp_valid) && (ready_delay > 0))
          ready_delay <= ready_delay - 1;
      end

      if (gmem_req_valid && gmem_req_ready) begin
        if ((outstanding != 0) || model_pending || gmem_rsp_valid) begin
          $display("[NPU-DMA][FAIL] more than one request outstanding");
          $fatal(1);
        end
        if ((gmem_req_addr + 64'd7) >= GMEM_MODEL_BYTES_64) begin
          $display("[NPU-DMA][FAIL] GMEM model address out of range: %h",
                   gmem_req_addr);
          $fatal(1);
        end

        model_pending  <= 1'b1;
        pending_write  <= gmem_req_write;
        pending_addr   <= gmem_req_addr[7:0];
        pending_wdata  <= gmem_req_wdata;
        pending_wstrb  <= gmem_req_wstrb;
        pending_error  <= inject_response_error;
        response_delay <= 2;
        ready_delay    <= 1;
        outstanding    <= outstanding + 1;
        request_count  <= request_count + 1;
        if (maximum_outstanding < (outstanding + 1))
          maximum_outstanding <= outstanding + 1;
      end

      if (model_pending && !gmem_rsp_valid) begin
        if (response_delay > 0) begin
          response_delay <= response_delay - 1;
        end else begin
          gmem_rsp_valid <= 1'b1;
          gmem_rsp_error <= pending_error;
          if (pending_error) begin
            gmem_rsp_rdata <= 64'd0;
          end else if (pending_write) begin
            for (lane = 0; lane < 8; lane = lane + 1) begin
              if (pending_wstrb[lane])
                gmem_bytes[pending_addr + lane[7:0]] <=
                  pending_wdata[(8*lane) +: 8];
            end
            gmem_rsp_rdata <= 64'd0;
          end else begin
            gmem_rsp_rdata <= gmem_read64(pending_addr);
          end
        end
      end

      if (gmem_rsp_valid && gmem_rsp_ready) begin
        if (outstanding != 1) begin
          $display("[NPU-DMA][FAIL] response drained with outstanding=%0d",
                   outstanding);
          $fatal(1);
        end
        if (gmem_rsp_error)
          error_response_drains <= error_response_drains + 1;
        model_pending  <= 1'b0;
        gmem_rsp_valid <= 1'b0;
        gmem_rsp_error <= 1'b0;
        outstanding    <= outstanding - 1;
        response_count <= response_count + 1;
      end
    end
  end

  // Backpressured request payload must remain bit-for-bit stable and valid may
  // not be withdrawn before the handshake.
  reg        held_request_valid;
  reg        held_request_write;
  reg [63:0] held_request_addr;
  reg [63:0] held_request_wdata;
  reg [7:0]  held_request_wstrb;

  always @(posedge clk) begin
    if (rst) begin
      held_request_valid <= 1'b0;
      held_request_write <= 1'b0;
      held_request_addr  <= 64'd0;
      held_request_wdata <= 64'd0;
      held_request_wstrb <= 8'd0;
    end else begin
      if (gmem_req_valid && !gmem_req_ready) begin
        if (!held_request_valid) begin
          held_request_valid <= 1'b1;
          held_request_write <= gmem_req_write;
          held_request_addr  <= gmem_req_addr;
          held_request_wdata <= gmem_req_wdata;
          held_request_wstrb <= gmem_req_wstrb;
        end else if ((gmem_req_write !== held_request_write) ||
                     (gmem_req_addr  !== held_request_addr)  ||
                     (gmem_req_wdata !== held_request_wdata) ||
                     (gmem_req_wstrb !== held_request_wstrb)) begin
          $display("[NPU-DMA][FAIL] request payload changed under backpressure");
          $fatal(1);
        end
      end else if (gmem_req_valid && gmem_req_ready) begin
        if (held_request_valid &&
            ((gmem_req_write !== held_request_write) ||
             (gmem_req_addr  !== held_request_addr)  ||
             (gmem_req_wdata !== held_request_wdata) ||
             (gmem_req_wstrb !== held_request_wstrb))) begin
          $display("[NPU-DMA][FAIL] stalled payload changed on handshake");
          $fatal(1);
        end
        held_request_valid <= 1'b0;
      end else if (held_request_valid) begin
        $display("[NPU-DMA][FAIL] request valid withdrawn before handshake");
        $fatal(1);
      end
    end
  end

  // Terminal outputs are pulses.  A GMEM response error must become visible
  // precisely after the erroneous response handshake, never while outstanding.
  reg previous_done;
  reg previous_error;
  reg error_response_handshake_q;

  always @(posedge clk) begin
    if (rst) begin
      previous_done              <= 1'b0;
      previous_error             <= 1'b0;
      error_response_handshake_q <= 1'b0;
    end else begin
      if (done && previous_done) begin
        $display("[NPU-DMA][FAIL] done was wider than one cycle");
        $fatal(1);
      end
      if (error && previous_error) begin
        $display("[NPU-DMA][FAIL] error was wider than one cycle");
        $fatal(1);
      end
      if (done && error) begin
        $display("[NPU-DMA][FAIL] done and error asserted together");
        $fatal(1);
      end
      previous_done  <= done;
      previous_error <= error;
      error_response_handshake_q <=
        gmem_rsp_valid && gmem_rsp_ready && gmem_rsp_error;
    end
  end

  always @(negedge clk) begin
    if (!rst && error && (error_code == `NPU_ERR_GMEM_RESPONSE)) begin
      if (!error_response_handshake_q || (outstanding != 0) ||
          gmem_rsp_valid) begin
        $display("[NPU-DMA][FAIL] response error exposed before response drain");
        $fatal(1);
      end
    end
    if (!rst && error_response_handshake_q &&
        !(error && (error_code == `NPU_ERR_GMEM_RESPONSE))) begin
      $display("[NPU-DMA][FAIL] drained response error lacked terminal error");
      $fatal(1);
    end
  end

  // ------------------------------------------------------------------------
  // Descriptor and transaction helpers
  // ------------------------------------------------------------------------

  function automatic [319:0] make_tr_desc(
    input [31:0] base,
    input [15:0] dim_w,
    input [15:0] dim_h,
    input [15:0] dim_c,
    input [15:0] dim_n
  );
    reg [319:0] value;
    reg [31:0] stride_h;
    reg [31:0] stride_c;
    reg [31:0] stride_n;
    begin
      stride_h        = {16'd0, dim_w};
      stride_c        = {16'd0, dim_w} * {16'd0, dim_h};
      stride_n        = stride_c * {16'd0, dim_c};
      value          = 320'd0;
      value[31:0]    = base;
      value[55:52]   = 4'd1; // continuous
      value[63:60]   = 4'd0; // e8
      value[79:64]   = dim_w;
      value[95:80]   = dim_h;
      value[111:96]  = dim_c;
      value[127:112] = dim_n;
      value[159:128] = 32'd1;
      value[191:160] = stride_h;
      value[223:192] = stride_c;
      value[255:224] = stride_n;
      make_tr_desc    = value;
    end
  endfunction

  function automatic [319:0] make_gr_desc(
    input [47:0] base,
    input [31:0] dim_w,
    input [31:0] dim_h,
    input [15:0] dim_c,
    input [15:0] dim_n
  );
    reg [319:0] value;
    reg [31:0] stride_c;
    reg [31:0] stride_n;
    begin
      stride_c        = dim_w * dim_h;
      stride_n        = stride_c * {16'd0, dim_c};
      value          = 320'd0;
      value[47:0]    = base;
      value[55:52]   = 4'd1; // continuous
      value[63:60]   = 4'd0; // e8
      value[95:64]   = dim_w;
      value[127:96]  = dim_h;
      value[143:128] = dim_c;
      value[159:144] = dim_n;
      value[191:160] = 32'd1;
      value[223:192] = dim_w;
      value[255:224] = stride_c;
      value[287:256] = stride_n;
      make_gr_desc    = value;
    end
  endfunction

  task automatic drive_start;
    begin
      @(negedge clk);
      start = 1'b1;
      @(posedge clk);
      #1;
      start = 1'b0;
    end
  endtask

  task automatic wait_for_success;
    integer watchdog;
    begin
      watchdog = 0;
      while (!done && !error) begin
        @(posedge clk);
        #1;
        watchdog = watchdog + 1;
        if (watchdog > 400) begin
          $display("[NPU-DMA][FAIL] success transaction watchdog expired");
          $fatal(1);
        end
      end
      if (error || !done) begin
        $display("[NPU-DMA][FAIL] expected done, got error=%0b code=%0d",
                 error, error_code);
        $fatal(1);
      end
      if (bytes_done != 64'd16 || cycles == 64'd0 || busy) begin
        $display("[NPU-DMA][FAIL] terminal counters/status bytes=%0d cycles=%0d busy=%0b",
                 bytes_done, cycles, busy);
        $fatal(1);
      end
      @(posedge clk);
      #1;
      if (done || error) begin
        $display("[NPU-DMA][FAIL] success terminal pulse did not clear");
        $fatal(1);
      end
    end
  endtask

  task automatic expect_launch_error(
    input [`NPU_ERROR_W-1:0] expected_code
  );
    integer requests_before;
    begin
      requests_before = request_count;
      drive_start();
      if (!error || done || busy || (error_code != expected_code)) begin
        $display("[NPU-DMA][FAIL] launch error expected=%0d got error=%0b done=%0b busy=%0b code=%0d",
                 expected_code, error, done, busy, error_code);
        $fatal(1);
      end
      if ((request_count != requests_before) || gmem_req_valid ||
          (outstanding != 0)) begin
        $display("[NPU-DMA][FAIL] invalid descriptor leaked a GMEM request");
        $fatal(1);
      end
      @(posedge clk);
      #1;
      if (error || done) begin
        $display("[NPU-DMA][FAIL] launch-error pulse did not clear");
        $fatal(1);
      end
      if (request_count != requests_before) begin
        $display("[NPU-DMA][FAIL] delayed GMEM request after launch error");
        $fatal(1);
      end
    end
  endtask

  task automatic lmem_write64(
    input [31:0] byte_addr,
    input [63:0] value
  );
    begin
      if (busy) begin
        $display("[NPU-DMA][FAIL] TB attempted LMEM write while DMA busy");
        $fatal(1);
      end
      @(negedge clk);
      tb_lmem_wr_addr  = byte_addr;
      tb_lmem_wr_data  = value;
      tb_lmem_wr_strb  = 8'hff;
      tb_lmem_wr_valid = 1'b1;
      #1;
      if (lmem_wr_oob) begin
        $display("[NPU-DMA][FAIL] TB LMEM write unexpectedly OOB");
        $fatal(1);
      end
      @(posedge clk);
      #1;
      tb_lmem_wr_valid = 1'b0;
      tb_lmem_wr_strb  = 8'h00;
    end
  endtask

  task automatic lmem_read64(
    input  [31:0] byte_addr,
    output [63:0] value
  );
    begin
      if (busy) begin
        $display("[NPU-DMA][FAIL] TB attempted LMEM read while DMA busy");
        $fatal(1);
      end
      @(negedge clk);
      tb_lmem_rd_addr  = byte_addr;
      tb_lmem_rd_bytes = 4'd8;
      tb_lmem_rd_valid = 1'b1;
      #1;
      if (lmem_rd0_oob) begin
        $display("[NPU-DMA][FAIL] TB LMEM read unexpectedly OOB");
        $fatal(1);
      end
      value = lmem_rd0_data;
      tb_lmem_rd_valid = 1'b0;
      tb_lmem_rd_bytes = 4'd0;
    end
  endtask

  reg [63:0] observed_word0;
  reg [63:0] observed_word1;
  reg [7:0]  expected_byte;
  integer    requests_before;
  integer    responses_before;
  integer    drains_before;
  integer    test_i;
  integer    watchdog;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    for (model_index = 0; model_index < GMEM_MODEL_BYTES;
         model_index = model_index + 1)
      gmem_bytes[model_index] = 8'd0;

    rst                   = 1'b1;
    start                 = 1'b0;
    op                    = {`NPU_OP_W{1'b0}};
    dst_id                = 6'd0;
    dst_desc              = 320'd0;
    dst_words_valid       = 5'd0;
    src_id                = 6'd0;
    src_desc              = 320'd0;
    src_words_valid       = 5'd0;
    inject_response_error = 1'b0;
    tb_lmem_rd_valid      = 1'b0;
    tb_lmem_rd_addr       = 32'd0;
    tb_lmem_rd_bytes      = 4'd0;
    tb_lmem_wr_valid      = 1'b0;
    tb_lmem_wr_addr       = 32'd0;
    tb_lmem_wr_data       = 64'd0;
    tb_lmem_wr_strb       = 8'd0;

    repeat (4) @(posedge clk);
    #1;
    rst = 1'b0;
    repeat (2) @(posedge clk);
    #1;

    // 16-byte continuous e8 DMA_LD: GMEM[0x40..0x4f] -> LMEM[0x00..0x0f].
    for (test_i = 0; test_i < 16; test_i = test_i + 1)
      gmem_bytes[8'd64 + test_i[7:0]] = 8'h10 + test_i[7:0];

    op              = `NPU_OP_DMA_LD;
    dst_id          = 6'd8;
    dst_desc        = make_tr_desc(32'd0, 16'd16, 16'd1, 16'd1, 16'd1);
    dst_words_valid = 5'b0_1111;
    src_id          = 6'd32;
    src_desc        = make_gr_desc(48'h40, 32'd16, 32'd1, 16'd1, 16'd1);
    src_words_valid = 5'b1_1111;
    requests_before = request_count;
    responses_before = response_count;
    drive_start();
    wait_for_success();

    if (((request_count - requests_before) != 2) ||
        ((response_count - responses_before) != 2) ||
        (maximum_outstanding != 1) || (outstanding != 0) ||
        (stalled_request_cycles == 0)) begin
      $display("[NPU-DMA][FAIL] LD protocol counts req=%0d rsp=%0d max=%0d out=%0d stalls=%0d",
               request_count - requests_before,
               response_count - responses_before,
               maximum_outstanding, outstanding, stalled_request_cycles);
      $fatal(1);
    end

    lmem_read64(32'd0, observed_word0);
    lmem_read64(32'd8, observed_word1);
    for (test_i = 0; test_i < 8; test_i = test_i + 1) begin
      expected_byte = 8'h10 + test_i[7:0];
      if (observed_word0[(8*test_i) +: 8] !== expected_byte) begin
        $display("[NPU-DMA][FAIL] LD byte %0d expected=%02x got=%02x",
                 test_i, expected_byte,
                 observed_word0[(8*test_i) +: 8]);
        $fatal(1);
      end
      expected_byte = 8'h18 + test_i[7:0];
      if (observed_word1[(8*test_i) +: 8] !== expected_byte) begin
        $display("[NPU-DMA][FAIL] LD byte %0d expected=%02x got=%02x",
                 test_i + 8, expected_byte,
                 observed_word1[(8*test_i) +: 8]);
        $fatal(1);
      end
    end

    // 16-byte continuous e8 DMA_ST: LMEM[0x10..0x1f] -> GMEM[0x80..0x8f].
    lmem_write64(32'd16, 64'h8877_6655_4433_2211);
    lmem_write64(32'd24, 64'hffee_ddcc_bbaa_0099);
    op              = `NPU_OP_DMA_ST;
    dst_id          = 6'd32;
    dst_desc        = make_gr_desc(48'h80, 32'd16, 32'd1, 16'd1, 16'd1);
    dst_words_valid = 5'b1_1111;
    src_id          = 6'd8;
    src_desc        = make_tr_desc(32'd16, 16'd16, 16'd1, 16'd1, 16'd1);
    src_words_valid = 5'b0_1111;
    requests_before = request_count;
    responses_before = response_count;
    drive_start();
    wait_for_success();

    if (((request_count - requests_before) != 2) ||
        ((response_count - responses_before) != 2) ||
        (maximum_outstanding != 1) || (outstanding != 0)) begin
      $display("[NPU-DMA][FAIL] ST protocol counts req=%0d rsp=%0d max=%0d out=%0d",
               request_count - requests_before,
               response_count - responses_before,
               maximum_outstanding, outstanding);
      $fatal(1);
    end
    for (test_i = 0; test_i < 8; test_i = test_i + 1) begin
      expected_byte = select_byte64(64'h8877_6655_4433_2211, test_i);
      if (gmem_bytes[8'd128 + test_i[7:0]] !== expected_byte) begin
        $display("[NPU-DMA][FAIL] ST byte %0d expected=%02x got=%02x",
                 test_i, expected_byte,
                 gmem_bytes[8'd128 + test_i[7:0]]);
        $fatal(1);
      end
      expected_byte = select_byte64(64'hffee_ddcc_bbaa_0099, test_i);
      if (gmem_bytes[8'd136 + test_i[7:0]] !== expected_byte) begin
        $display("[NPU-DMA][FAIL] ST byte %0d expected=%02x got=%02x",
                 test_i + 8, expected_byte,
                 gmem_bytes[8'd136 + test_i[7:0]]);
        $fatal(1);
      end
    end

    // A valid LD with an injected response error must drain the accepted
    // request, report zero completed bytes, and issue no second request.
    op                    = `NPU_OP_DMA_LD;
    dst_id                = 6'd8;
    dst_desc              = make_tr_desc(32'd32, 16'd16, 16'd1, 16'd1, 16'd1);
    dst_words_valid       = 5'b0_1111;
    src_id                = 6'd32;
    src_desc              = make_gr_desc(48'h40, 32'd16, 32'd1, 16'd1, 16'd1);
    src_words_valid       = 5'b1_1111;
    inject_response_error = 1'b1;
    requests_before       = request_count;
    responses_before      = response_count;
    drains_before         = error_response_drains;
    drive_start();
    watchdog = 0;
    while (!done && !error) begin
      @(posedge clk);
      #1;
      watchdog = watchdog + 1;
      if (watchdog > 200) begin
        $display("[NPU-DMA][FAIL] response-error watchdog expired");
        $fatal(1);
      end
    end
    inject_response_error = 1'b0;
    if (!error || done || (error_code != `NPU_ERR_GMEM_RESPONSE) || busy ||
        (bytes_done != 64'd0) || (outstanding != 0) || gmem_rsp_valid ||
        ((request_count - requests_before) != 1) ||
        ((response_count - responses_before) != 1) ||
        ((error_response_drains - drains_before) != 1)) begin
      $display("[NPU-DMA][FAIL] bad response-error terminal state code=%0d busy=%0b bytes=%0d out=%0d req=%0d rsp=%0d drains=%0d",
               error_code, busy, bytes_done, outstanding,
               request_count - requests_before,
               response_count - responses_before,
               error_response_drains - drains_before);
      $fatal(1);
    end
    @(posedge clk);
    #1;
    if (error || done) begin
      $display("[NPU-DMA][FAIL] response-error pulse did not clear");
      $fatal(1);
    end

    // Descriptor incomplete: TR word3 absent.
    op              = `NPU_OP_DMA_LD;
    dst_id          = 6'd8;
    dst_desc        = make_tr_desc(32'd0, 16'd16, 16'd1, 16'd1, 16'd1);
    dst_words_valid = 5'b0_0111;
    src_id          = 6'd32;
    src_desc        = make_gr_desc(48'h40, 32'd16, 32'd1, 16'd1, 16'd1);
    src_words_valid = 5'b1_1111;
    expect_launch_error(`NPU_ERR_DESC_INCOMPLETE);

    // Shape mismatch: TR has 16 elements, GR has 8.
    dst_words_valid = 5'b0_1111;
    src_desc = make_gr_desc(48'h40, 32'd8, 32'd1, 16'd1, 16'd1);
    expect_launch_error(`NPU_ERR_SHAPE);

    // Unaligned GMEM base.
    src_desc = make_gr_desc(48'h42, 32'd16, 32'd1, 16'd1, 16'd1);
    expect_launch_error(`NPU_ERR_GMEM_ALIGN);

    // Aligned LMEM base 56 plus 16 bytes exceeds the 64-byte local memory.
    dst_desc = make_tr_desc(32'd56, 16'd16, 16'd1, 16'd1, 16'd1);
    src_desc = make_gr_desc(48'h40, 32'd16, 32'd1, 16'd1, 16'd1);
    expect_launch_error(`NPU_ERR_LMEM_BOUNDS);

    if (maximum_outstanding != 1 || outstanding != 0 ||
        held_request_valid) begin
      $display("[NPU-DMA][FAIL] final protocol state max=%0d out=%0d held=%0b",
               maximum_outstanding, outstanding, held_request_valid);
      $fatal(1);
    end

    $display("[NPU-DMA][PASS]");
    $finish;
  end

endmodule
