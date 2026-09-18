// Physically tagged, two-way 8 KiB instruction cache (default geometry).
// 64-byte lines, synchronous 128-bit sector reads, one ordered refill owner.
// Hot hits accept and return one 16-byte packet each cycle. Misses use an
// eight-beat AXI read; any error rejects the entire line. Invalidation poisons
// an in-flight fill without cancelling its externally accepted transaction.
module R64ICache #(
  parameter integer SET_W=6,
  parameter PREPARED_PROTECTION=0,
  parameter integer SETS=(1<<SET_W),
  parameter integer TAG_W=64-SET_W-6
) (
  input clk_i,input rst_i,input invalidate_i,
  input req_valid_i,output req_ready_o,
  input [63:0] req_paddr_i,input req_uncached_i,
  input req_fault_i,input [4:0] req_cause_i,input [7:0] req_access_mask_i,
  input [129:0] req_protection_facts_i,
  output rsp_valid_o,input rsp_ready_i,
  output [127:0] rsp_data_o,
  output rsp_fault_o,output [4:0] rsp_cause_o,output [7:0] rsp_access_mask_o,
  output cmd_valid_o,input cmd_ready_i,
  output [63:0] cmd_addr_o,
  output [7:0] cmd_len_o,output [2:0] cmd_size_o,
  input beat_valid_i,output beat_ready_o,
  input [63:0] beat_data_i,input [1:0] beat_resp_i,input beat_last_i
);
  localparam [1:0] LOOKUP=0,SEND=1,FILL=2,RETURN=3;
  reg [1:0] state_q;
  reg [SETS-1:0] valid0_q,valid1_q,lru_q;
  reg [TAG_W-1:0] tag0_q[0:SETS-1],tag1_q[0:SETS-1];
  // Separate inferred synchronous memories; only fill writes touch payload.
  reg [127:0] data0_q[0:SETS*4-1],data1_q[0:SETS*4-1];
  // One explicit overflow owner preserves a newly accepted request when
  // invalidation or response backpressure prevents replacing the old lookup.
  // Empty Q credit accepts one request independently of hit/READY. Normal
  // hits dispatch directly into the existing synchronous lookup boundary.
  reg overflow_valid_q;
  reg [74:0] overflow_payload_q;
  wire [7:0] effective_mask_w;
  generate if(PREPARED_PROTECTION)begin:g_protection_finish
   // Facts keep their accepted physical slot through lookup or overflow.
   // Empty credit is Q-only; a third request cannot overwrite two live owners.
   reg [129:0] facts_q[0:1];
   reg tail_q,lookup_index_q;
   wire [7:0] slot_mask_w[0:1];
   genvar slot;
   for(slot=0;slot<2;slot=slot+1)begin:g_slot
    // Evaluate each fixed slot before the narrow owner select, so the new
    // index does not drive a wide facts mux followed by priority resolution.
    R64FetchProtectionFinish finish(.facts_i(facts_q[slot]),.fault_mask_o(slot_mask_w[slot]));
    always @(posedge clk_i)begin
     if(rst_i)begin
      // Preserve the former reset-visible request facts, without adding a
      // second wide reset. The other slot is unused until its real capture.
      if(slot==0)facts_q[slot]<=130'b0;
     end else if(req_fire_w&&tail_q==slot[0])
      facts_q[slot]<=req_protection_facts_i;
    end
   end
   assign effective_mask_w=slot_mask_w[lookup_index_q];
   always @(posedge clk_i)begin
    if(rst_i)begin tail_q<=0;lookup_index_q<=0;end
    else begin
     if(req_fire_w)tail_q<=!tail_q;
     if(dispatch_fire_w)lookup_index_q<=overflow_valid_q?!tail_q:tail_q;
    end
   end
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i)begin
    if(req_fire_w&&lookup_valid_q&&tail_q==lookup_index_q)
     $fatal(1,"ICache facts overwrote a live lookup owner");
    if(overflow_valid_q&&lookup_valid_q&&(!tail_q)==lookup_index_q)
     $fatal(1,"ICache facts lookup and overflow share a slot");
   end
`endif
  end else begin:g_legacy_protection
   assign effective_mask_w=request_mask_q;
  end endgenerate
  wire effective_fault_w=request_fault_q||(&effective_mask_w);
  wire [74:0] incoming_payload_w={req_paddr_i[63:4],req_uncached_i,
      req_fault_i,req_cause_i,req_access_mask_i};
  wire [74:0] dispatch_payload_w=overflow_valid_q?overflow_payload_q:incoming_payload_w;
  wire [59:0] dispatch_address_w;
  wire dispatch_uncached_w,dispatch_fault_w;
  wire [4:0] dispatch_cause_w;
  wire [7:0] dispatch_mask_w;
  assign {dispatch_address_w,dispatch_uncached_w,dispatch_fault_w,
      dispatch_cause_w,dispatch_mask_w}=dispatch_payload_w;
  reg lookup_valid_q;
  reg [63:4] address_q;
  reg request_fault_q,uncached_q;
  reg [4:0] request_cause_q;
  reg [7:0] request_mask_q,response_mask_q;
  reg v0_q,v1_q;
  reg [TAG_W-1:0] t0_q,t1_q;
  reg [127:0] d0_q,d1_q;
  reg response_valid_q,response_fault_q;
  reg [127:0] response_data_q;
  reg [4:0] response_cause_q;
  reg victim_q,poison_q,fill_error_q;
  reg [2:0] beat_q;
  reg [63:0] low_beat_q;
  reg [127:0] fill_result_q;

  wire [SET_W-1:0] set_w=address_q[SET_W+5:6];
  wire [SET_W-1:0] request_set_w=dispatch_address_w[SET_W+1:2];
  wire [SET_W+1:0] request_sector_w=dispatch_address_w[SET_W+1:0];
  wire [TAG_W-1:0] expected_tag_w=address_q[63:SET_W+6];
  wire hit0_w=v0_q&&t0_q==expected_tag_w&&!invalidate_i&&!uncached_q;
  wire hit1_w=v1_q&&t1_q==expected_tag_w&&!invalidate_i&&!uncached_q;
  wire terminal_w=effective_fault_w||hit0_w||hit1_w;
  wire victim_pick_w=!valid0_q[set_w]?1'b0:(!valid1_q[set_w]?1'b1:lru_q[set_w]);
  wire output_free_w=!response_valid_q||rsp_ready_i;
  wire lookup_ready_w=state_q==LOOKUP&&
                    (!lookup_valid_q||(terminal_w&&output_free_w));
  assign req_ready_o=!rst_i&&!overflow_valid_q;
  wire req_fire_w=req_valid_i&&req_ready_o;
  wire dispatch_fire_w=!rst_i&&lookup_ready_w&&(overflow_valid_q||req_fire_w);
  always @(posedge clk_i) begin
    if(rst_i) overflow_valid_q<=0;
    else begin
      if(overflow_valid_q&&dispatch_fire_w) overflow_valid_q<=0;
      if(req_fire_w&&!lookup_ready_w) begin
        overflow_valid_q<=1;
        overflow_payload_q<=incoming_payload_w;
      end
    end
  end
  assign rsp_valid_o=response_valid_q&&!rst_i;
  assign rsp_data_o=response_data_q;
  assign rsp_fault_o=response_fault_q;
  assign rsp_cause_o=response_cause_q;
  assign rsp_access_mask_o=response_mask_q;
  assign cmd_valid_o=state_q==SEND&&!rst_i;
  assign cmd_addr_o=uncached_q?{address_q,4'b0}:{address_q[63:6],6'b0};
  assign cmd_len_o=uncached_q?8'd1:8'd7;
  assign cmd_size_o=3'd3;
  assign beat_ready_o=state_q==FILL&&!rst_i;
  wire beat_fire_w=beat_valid_i&&beat_ready_o;
  wire last_beat_w=beat_q==(uncached_q?3'd1:3'd7);
  wire [SET_W+1:0] fill_sector_w={set_w,beat_q[2:1]};
  wire fill_bad_w=fill_error_q||(beat_resp_i!=0);
  wire [127:0] fill_data_w={beat_data_i,low_beat_q};

  // Prepare only while the old lookup can leave. Input VALID and reset
  // publish ownership independently of the tag/data read payload. The public
  // response keeps its existing reset/invalid-cycle value contract below.
  always @(posedge clk_i)if(lookup_ready_w)begin
    t0_q<=tag0_q[request_set_w];t1_q<=tag1_q[request_set_w];
    d0_q<=data0_q[request_sector_w];d1_q<=data1_q[request_sector_w];
  end

  always @(posedge clk_i) begin
    if(rst_i) begin
      state_q<=LOOKUP;valid0_q<=0;valid1_q<=0;lru_q<=0;
      lookup_valid_q<=0;address_q<=0;request_fault_q<=0;uncached_q<=0;request_cause_q<=0;
      request_mask_q<=0;response_mask_q<=0;
      v0_q<=0;v1_q<=0;
      response_valid_q<=0;response_fault_q<=0;response_data_q<=0;response_cause_q<=0;
      victim_q<=0;poison_q<=0;fill_error_q<=0;beat_q<=0;
    end else begin
      if(response_valid_q&&rsp_ready_i) response_valid_q<=0;
      if(invalidate_i) begin valid0_q<=0;valid1_q<=0;poison_q<=1;end
      case(state_q)
        LOOKUP: if(lookup_valid_q) begin
          if(terminal_w) begin
            if(output_free_w) begin
              response_valid_q<=1;
              response_data_q<=effective_fault_w?128'b0:(hit0_w?d0_q:d1_q);
              response_fault_q<=effective_fault_w;response_cause_q<=request_cause_q;response_mask_q<=effective_mask_w;
              lookup_valid_q<=0;
              if(!effective_fault_w) lru_q[set_w]<=hit0_w;
            end
          end else begin
            victim_q<=victim_pick_w;
            if(!uncached_q) begin
              if(victim_pick_w) valid1_q[set_w]<=0;
              else valid0_q[set_w]<=0;
            end
            poison_q<=invalidate_i;fill_error_q<=0;beat_q<=0;state_q<=SEND;
          end
        end
        SEND: if(cmd_ready_i) state_q<=FILL;
        FILL: if(beat_fire_w) begin
          fill_error_q<=fill_bad_w;
          low_beat_q<=beat_data_i;beat_q<=beat_q+1'b1;
          if(beat_q[0]) begin
            if(!uncached_q) begin
              if(victim_q) data1_q[fill_sector_w]<=fill_data_w;
              else data0_q[fill_sector_w]<=fill_data_w;
            end
            if(uncached_q||beat_q[2:1]==address_q[5:4]) fill_result_q<=fill_data_w;
          end
          if(last_beat_w) begin
            state_q<=RETURN;
            // Replace the tag only after a complete successful line, and
            // never resurrect a line invalidated during its refill.
            if(!uncached_q&&!fill_bad_w&&!poison_q&&!invalidate_i) begin
              if(victim_q) begin valid1_q[set_w]<=1;tag1_q[set_w]<=expected_tag_w;end
              else begin valid0_q[set_w]<=1;tag0_q[set_w]<=expected_tag_w;end
              lru_q[set_w]<=!victim_q;
            end
          end
        end
        RETURN: if(output_free_w) begin
          response_valid_q<=1;response_data_q<=fill_error_q?128'b0:fill_result_q;
          response_fault_q<=fill_error_q;response_cause_q<=5'd1;response_mask_q<=effective_mask_w;
          lookup_valid_q<=0;state_q<=LOOKUP;
        end
      endcase
      if(dispatch_fire_w) begin
        lookup_valid_q<=1;address_q<=dispatch_address_w;uncached_q<=dispatch_uncached_w;
        request_fault_q<=dispatch_fault_w||(!PREPARED_PROTECTION&&(&dispatch_mask_w));
        request_cause_q<=dispatch_fault_w?dispatch_cause_w:5'd1;request_mask_q<=dispatch_mask_w;
        v0_q<=valid0_q[request_set_w]&&!invalidate_i;
        v1_q<=valid1_q[request_set_w]&&!invalidate_i;
        
        
      end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i) begin
    if(req_fire_w&&!req_fault_i&&req_paddr_i[3:0]!=0)
      $fatal(1,"ICache request not sector aligned");
    if(beat_fire_w&&beat_last_i!=last_beat_w)
      $fatal(1,"ICache refill has incorrect length");
    if(overflow_valid_q&&req_fire_w) $fatal(1,"ICache overwrote overflow owner");
    if(dispatch_fire_w&&overflow_valid_q&&req_fire_w)
      $fatal(1,"ICache borrowed same-cycle overflow credit");
    if(hit0_w&&hit1_w&&lookup_valid_q) $fatal(1,"ICache duplicate physical tag");
  end
`endif
endmodule
