// Two-bank 8 KiB physical read cache with precise write-through completion.
// PA bit 3 chooses a single-read data bank; two different-bank hits retire
// each cycle. Same-bank requests keep their producer owner until accepted.
// One read/refill owner may overlap one ordinary cached write awaiting B.
// Writes update a resident line only after successful B; errors preserve it.
// CAS and AMO exclude other requests from admission through B completion.
module R64Dcache #(
  parameter SET_W=6, parameter TOKEN_W=6, parameter SPLIT_STORE_OWNER=1
)(
  input clk_i,input rst_i,input invalidate_i,input reservation_clear_i,
  input [1:0] req_fast_store_i,
  output store_rsp_valid_o,input store_rsp_ready_i,
  output [TOKEN_W-1:0] store_rsp_token_o,output store_rsp_error_o,
  input [1:0] req_valid_i,output reg [1:0] req_ready_o,
  input [2*TOKEN_W-1:0] req_token_i,input [127:0] req_addr_i,
  input [3:0] req_op_i,input [1:0] req_cache_i,
  input [5:0] req_size_i,input [127:0] req_data_i,req_expected_i,
  input [15:0] req_strb_i,input [9:0] req_amo_i,
  output [1:0] rsp_valid_o,input [1:0] rsp_ready_i,
  output [2*TOKEN_W-1:0] rsp_token_o,output [127:0] rsp_data_o,
  output [1:0] rsp_error_o,rsp_compare_o,
  output read_valid_o,input read_ready_i,
  output [63:0] read_addr_o,output [7:0] read_len_o,output [2:0] read_size_o,
  input beat_valid_i,output beat_ready_o,input [63:0] beat_data_i,
  input [1:0] beat_resp_i,input beat_last_i,
  output write_valid_o,input write_ready_i,output [63:0] write_addr_o,
  output [2:0] write_size_o,output write_data_valid_o,input write_data_ready_i,
  output [63:0] write_data_o,output [7:0] write_strb_o,
  input write_rsp_valid_i,output write_rsp_ready_o,input [1:0] write_resp_i,
  output idle_o,
  output mutation_o,output [60:0] mutation_word_o
);
  localparam SETS=1<<SET_W,WORDS=SETS*4,TAG_W=64-6-SET_W;
  localparam IDLE=0,READ=1,REFILL=2,MODIFY=3,WRITE=4,BRESP=5,DELIVER=6,AMO_EXEC=7,AMO_FINISH=8;
  reg [3:0] state_q;
  // A detached ordinary store retains its bank stage (address/token/strb).
  // Refill may change the slow owner's way/data, so these store facts are
  // captured before releasing that owner. No second store is admitted.
  reg store_active_q,store_bank_q,store_way_q,store_hit_q,store_poison_q;
  reg [63:0] store_data_q;
  reg [TAG_W-1:0] tag0_q[0:SETS-1],tag1_q[0:SETS-1];
  reg [SETS-1:0] valid0_q,valid1_q,lru_q;
  // Separate arrays express real bank ports, without replicated data RAM.
  reg [63:0] bank00_q[0:WORDS-1],bank01_q[0:WORDS-1];
  reg [63:0] bank10_q[0:WORDS-1],bank11_q[0:WORDS-1];
  reg [1:0] stage_valid_q;
  reg [63:0] address_q[0:1],data_q[0:1],expected_q[0:1];
  reg [TOKEN_W-1:0] token_q[0:1];
  reg [1:0] op_q[0:1];
  reg [1:0] cache_q,fast_store_q;
  reg [2:0] size_q[0:1];
  reg [7:0] strb_q[0:1];
  reg [4:0] amo_q[0:1];
  reg [63:0] rd0_q[0:1],rd1_q[0:1];
  reg [TAG_W-1:0] tagrd0_q[0:1],tagrd1_q[0:1];
  reg [1:0] vrd0_q,vrd1_q;
  reg [1:0] out_valid_q,out_error_q,out_compare_q;
  reg [63:0] out_data_q[0:1];
  reg [TOKEN_W-1:0] out_token_q[0:1];
  wire [1:0] output_free_w=~out_valid_q|rsp_ready_i;
  // Keep one slow owner. Ordinary cached traffic in the other bank and a
  // different set may overlap a read/refill or an ordinary cached store B wait.
  // The write owner and its precise B/error remain live until consumption.
  wire read_overlap_w=(state_q==READ||state_q==REFILL)&&
    op_q[owner_q]==0&&cache_q[owner_q]&&!poison_q;
  wire store_overlap_w=state_q==BRESP&&op_q[owner_q]==1&&cache_q[owner_q]&&!poison_q;
  wire hit_overlap_w=read_overlap_w||store_overlap_w;
  wire [1:0] resident0_w,resident1_w,resident_w,hit0_w,hit1_w,hit_w,hit_complete_w;
  genvar g;
  generate for(g=0;g<2;g=g+1)begin:gen_hit
    assign resident0_w[g]=vrd0_q[g]&&tagrd0_q[g]==address_q[g][63:6+SET_W];
    assign resident1_w[g]=vrd1_q[g]&&tagrd1_q[g]==address_q[g][63:6+SET_W];
    assign resident_w[g]=resident0_w[g]||resident1_w[g];
    assign hit0_w[g]=cache_q[g]&&resident0_w[g];
    assign hit1_w[g]=cache_q[g]&&resident1_w[g];
    assign hit_w[g]=hit0_w[g]||hit1_w[g];
    assign hit_complete_w[g]=stage_valid_q[g]&&op_q[g]==0&&hit_w[g]&&output_free_w[g]&&
      (state_q==IDLE||(hit_overlap_w&&owner_q!=g&&
        address_q[g][6+:SET_W]!=address_q[owner_q][6+:SET_W]))&&!invalidate_i;
    assign rsp_token_o[g*TOKEN_W+:TOKEN_W]=out_token_q[g];
    assign rsp_data_o[g*64+:64]=out_data_q[g];
  end endgenerate
  assign rsp_valid_o=out_valid_q&{2{!rst_i}};
  assign rsp_error_o=out_error_q;assign rsp_compare_o=out_compare_q;
  wire [1:0] available_w=~stage_valid_q|hit_complete_w;
  wire special_wait_w=(stage_valid_q[0]&&op_q[0]!=0&&!((store_overlap_w&&owner_q==0)||(store_active_q&&store_bank_q==0)))||
    (stage_valid_q[1]&&op_q[1]!=0&&!((store_overlap_w&&owner_q==1)||(store_active_q&&store_bank_q==1)));
  wire empty_w=stage_valid_q==0&&out_valid_q==0;
  wire bank0_w=req_addr_i[3],bank1_w=req_addr_i[67];
  wire overlap_owner_w=store_active_q?store_bank_q:owner_q;
  wire [1:0] overlap_candidate_w;
  assign overlap_candidate_w[0]=req_op_i[1:0]==0&&req_cache_i[0]&&bank0_w!=overlap_owner_w&&
    req_addr_i[6+:SET_W]!=address_q[overlap_owner_w][6+:SET_W];
  assign overlap_candidate_w[1]=req_op_i[3:2]==0&&req_cache_i[1]&&bank1_w!=overlap_owner_w&&
    req_addr_i[70+:SET_W]!=address_q[overlap_owner_w][6+:SET_W];
  always @*begin
    req_ready_o=0;
    if(!rst_i&&!invalidate_i&&!special_wait_w)begin
      if(state_q==IDLE&&!store_active_q)begin
      if(req_op_i[1:0]!=0)req_ready_o[0]=empty_w;
      else req_ready_o[0]=available_w[bank0_w];
      if(req_op_i[3:2]==0&&!(req_valid_i[0]&&req_op_i[1:0]!=0))
        req_ready_o[1]=available_w[bank1_w]&&!(req_valid_i[0]&&req_ready_o[0]&&bank0_w==bank1_w);
      end else if(hit_overlap_w||(state_q==IDLE&&store_active_q&&!store_poison_q))begin
        req_ready_o[0]=overlap_candidate_w[0]&&available_w[bank0_w];
        req_ready_o[1]=overlap_candidate_w[1]&&available_w[bank1_w]&&
          !(req_valid_i[0]&&req_ready_o[0]&&bank0_w==bank1_w);
      end
    end
  end
  wire [1:0] take_w=req_valid_i&req_ready_o;
  wire start0_w=stage_valid_q[0]&&!hit_complete_w[0]&&output_free_w[0]&&!(store_active_q&&store_bank_q==0);
  wire start1_w=stage_valid_q[1]&&!hit_complete_w[1]&&output_free_w[1]&&!(store_active_q&&store_bank_q==1);
  wire start_w=state_q==IDLE&&!invalidate_i&&(start0_w||start1_w);
  wire selected_w=!start0_w;
  // Special admission requires both bank stages and response slots empty.
  // Thus an atomic owner has exactly one occupied stage. Its preparation
  // source depends on Q occupancy, not ordinary dual-load scheduling.
  wire arithmetic_candidate_w=!stage_valid_q[0];
  reg owner_q,way_q,allocate_q,error_q,compare_q,poison_q;
  reg [63:0] old_q,new_q;
  reg [2:0] beat_q;
  reg command_sent_q,data_sent_q;
  reg reservation_q;reg [61:0] reservation_addr_q;reg [2:0] reservation_size_q;
  wire [63:0] owner_address_w=address_q[owner_q];
  wire [SET_W-1:0] set_w=owner_address_w[6+:SET_W];
  wire [SET_W+1:0] word_index_w={set_w,owner_address_w[5:4]};
  wire [SET_W+1:0] fill_index_w={set_w,beat_q[2:1]};
  wire cache_hit_w=resident_w[owner_q];
  // Exactly one byte-enabled write port and one synchronous read port per
  // physical data bank/way. Refill and successful write-through share it.
  wire write_owner_w=store_active_q?store_bank_q:owner_q;
  wire [63:0] write_owner_address_w=address_q[write_owner_w];
  wire write_way_w=store_active_q?store_way_q:way_q;
  wire write_hit_w=store_active_q?store_hit_q:cache_hit_w;
  wire write_poison_w=store_active_q?store_poison_q:poison_q;
  wire [63:0] write_value_w=store_active_q?store_data_q:new_q;
  wire [SET_W+1:0] store_index_w={write_owner_address_w[6+:SET_W],write_owner_address_w[5:4]};
  wire store_write_w=write_response_fire_w&&write_resp_i==0&&write_hit_w&&!write_poison_w&&!invalidate_i;
  // B owns its cache update port. A colliding R beat stays in the read
  // adapter until the next cycle; BREADY never depends on this RREADY.
  wire fill_port_block_w=store_write_w&&state_q==REFILL&&allocate_q&&beat_q[0]==write_owner_w;
  wire fill_write_w=state_q==REFILL&&beat_valid_i&&beat_ready_o&&allocate_q;
  wire [1:0] data_write_w,data_way_w;
  wire [SET_W+1:0] data_index_w[0:1];
  wire [63:0] data_write_value_w[0:1];wire [7:0] data_write_mask_w[0:1];
  generate for(g=0;g<2;g=g+1)begin:gen_write_port
    wire fill_w=fill_write_w&&beat_q[0]==g;
    wire store_w=store_write_w&&write_owner_w==g;
    assign data_write_w[g]=fill_w||store_w;
    assign data_way_w[g]=fill_w?way_q:write_way_w;
    assign data_index_w[g]=fill_w?fill_index_w:store_index_w;
    assign data_write_value_w[g]=fill_w?beat_data_i:write_value_w;
    assign data_write_mask_w[g]=fill_w?8'hff:strb_q[write_owner_w];
  end endgenerate
  assign read_valid_o=state_q==READ&&!rst_i;
  assign read_addr_o=allocate_q?{owner_address_w[63:6],6'b0}:owner_address_w;
  assign read_len_o=allocate_q?8'd7:8'd0;
  assign read_size_o=allocate_q?3'd3:size_q[owner_q];
  assign beat_ready_o=state_q==REFILL&&!rst_i&&!fill_port_block_w;
  assign write_valid_o=state_q==WRITE&&!command_sent_q&&!rst_i;
  assign write_data_valid_o=state_q==WRITE&&!data_sent_q&&!rst_i;
  assign write_addr_o=owner_address_w;assign write_size_o=size_q[owner_q];
  assign write_data_o=new_q;assign write_strb_o=strb_q[owner_q];
  assign write_rsp_ready_o=!rst_i&&(store_active_q?
    (fast_store_q[store_bank_q]?store_rsp_ready_i:output_free_w[store_bank_q]):
    (state_q==BRESP&&(!fast_store_q[owner_q]||store_rsp_ready_i)));
  wire write_response_fire_w=write_rsp_valid_i&&write_rsp_ready_o;
  assign store_rsp_valid_o=(store_active_q||state_q==BRESP)&&fast_store_q[write_owner_w]&&write_rsp_valid_i&&!rst_i;
  assign store_rsp_token_o=token_q[write_owner_w];
  assign store_rsp_error_o=write_resp_i!=0;
  assign idle_o=state_q==IDLE&&empty_w&&!store_active_q;
  assign mutation_o=write_response_fire_w&&write_resp_i==0;
  assign mutation_word_o=write_owner_address_w[63:3];
  wire unused_last_w=beat_last_i;
  // Arithmetic AMOs retain the same single external owner across preparation
  // and execution. Ordinary hits/stores and LR/SC/CAS do not use this stage.
  reg [63:0] arithmetic_a_q,arithmetic_b_q;
  reg [4:0] arithmetic_op_q;
  reg arithmetic_word_q,arithmetic_upper_q;
  wire [31:0] arithmetic_word_a_w=arithmetic_upper_q?old_q[63:32]:old_q[31:0];
  wire [31:0] arithmetic_word_b_w=arithmetic_upper_q?arithmetic_b_q[63:32]:arithmetic_b_q[31:0];
  wire [99:0] arithmetic_parts_w;
  reg [99:0] arithmetic_parts_q;
  R64DcacheAmoParts arithmetic_parts(.a_i(arithmetic_a_q),.b_i(arithmetic_b_q),.parts_o(arithmetic_parts_w));
  wire arithmetic_unsigned_less_w=arithmetic_parts_q[99]?arithmetic_parts_q[97]:arithmetic_parts_q[98];
  wire arithmetic_signed_less_w=(arithmetic_a_q[63]^arithmetic_b_q[63])?arithmetic_a_q[63]:arithmetic_unsigned_less_w;
  wire [63:0] arithmetic_sum_w={arithmetic_parts_q[32]?arithmetic_parts_q[96:65]:arithmetic_parts_q[64:33],arithmetic_parts_q[31:0]};
  reg [63:0] arithmetic_value_w;
  always @*begin
    case(arithmetic_op_q)
      0:arithmetic_value_w=arithmetic_sum_w;1:arithmetic_value_w=arithmetic_b_q;
      4:arithmetic_value_w=arithmetic_a_q^arithmetic_b_q;
      8:arithmetic_value_w=arithmetic_a_q|arithmetic_b_q;
      12:arithmetic_value_w=arithmetic_a_q&arithmetic_b_q;
      16:arithmetic_value_w=arithmetic_signed_less_w?arithmetic_a_q:arithmetic_b_q;
      20:arithmetic_value_w=arithmetic_signed_less_w?arithmetic_b_q:arithmetic_a_q;
      24:arithmetic_value_w=arithmetic_unsigned_less_w?arithmetic_a_q:arithmetic_b_q;
      28:arithmetic_value_w=arithmetic_unsigned_less_w?arithmetic_b_q:arithmetic_a_q;
      default:arithmetic_value_w=arithmetic_b_q;
    endcase
  end
  wire [63:0] arithmetic_store_w=arithmetic_word_q?
    (arithmetic_upper_q?{arithmetic_value_w[31:0],old_q[31:0]}:{old_q[63:32],arithmetic_value_w[31:0]}):
    arithmetic_value_w;

  // Predecode each retained bank's set before slow-owner arbitration. Late
  // output credit only qualifies one erase mask; it cannot select a bank
  // address, re-read victim metadata, then decode a valid-array destination.
  wire [SETS-1:0] set_match_w[0:1];
  wire [SETS-1:0] victim1_state_w=valid0_q&(~valid1_q|lru_q);
  wire [1:0] victim_w;
  wire [1:0] erase_bank_w={
    start_w&&selected_w&&op_q[1]==0&&cache_q[1],
    start_w&&!selected_w&&op_q[0]==0&&cache_q[0]};
  wire install_w=state_q==REFILL&&beat_valid_i&&beat_ready_o&&allocate_q&&beat_q==7&&
    !error_q&&beat_resp_i==0&&!poison_q&&!invalidate_i;
  genvar vb,vs;
  generate
    for(vb=0;vb<2;vb=vb+1)begin:g_victim_bank
      assign victim_w[vb]=|(set_match_w[vb]&victim1_state_w);
      for(vs=0;vs<SETS;vs=vs+1)begin:g_match
        assign set_match_w[vb][vs]=address_q[vb][6+:SET_W]==SET_W'(vs);
      end
    end
    for(vs=0;vs<SETS;vs=vs+1)begin:g_valid_state
      wire erase_w=(erase_bank_w[0]&&set_match_w[0][vs])||
        (erase_bank_w[1]&&set_match_w[1][vs]);
      wire install_set_w=install_w&&set_w==SET_W'(vs);
      always @(posedge clk_i)begin
        if(rst_i||invalidate_i)begin valid0_q[vs]<=0;valid1_q[vs]<=0;end
        else begin
          valid0_q[vs]<=(valid0_q[vs]&&!(erase_w&&!victim1_state_w[vs]))||
            (install_set_w&&!way_q);
          valid1_q[vs]<=(valid1_q[vs]&&!(erase_w&&victim1_state_w[vs]))||
            (install_set_w&&way_q);
        end
      end
    end
  endgenerate
  // Each bank accepts the original single physical write event into a
  // one-cycle write buffer. A lookup sees that pending write through byte
  // forwarding, so tag install, B completion and all request timing stay exact.
  // Groups retain different histories and therefore have distinct payload Qs:
  // each bit drives at most 32 rows x 2 ways, not all 256 rows x 2 ways.
  localparam WRITE_ROWS=WORDS<32?WORDS:32,WRITE_GROUPS=WORDS/WRITE_ROWS;
  reg [1:0] pending_write_q,pending_way_q;
  reg [SET_W+1:0] pending_index_q[0:1];
  reg [7:0] pending_mask_q[0:1];
  reg [63:0] pending_data_q[0:1];
  wire [63:0] lookup_data0_w[0:1],lookup_data1_w[0:1];
  genvar wb,wg,wr,by;
  generate for(wb=0;wb<2;wb=wb+1)begin:g_write_bank
    always @(posedge clk_i)begin
      if(rst_i)pending_write_q[wb]<=0;
      else pending_write_q[wb]<=data_write_w[wb];
      if(data_write_w[wb])begin
        pending_way_q[wb]<=data_way_w[wb];
        pending_index_q[wb]<=data_index_w[wb];
        pending_mask_q[wb]<=data_write_mask_w[wb];
        pending_data_q[wb]<=data_write_value_w[wb];
      end
    end
    wire [63:0] raw0_w,raw1_w;
    if(wb==0)begin:g_low
      assign raw0_w=bank00_q[lookup_index_w[wb]];
      assign raw1_w=bank01_q[lookup_index_w[wb]];
    end else begin:g_high
      assign raw0_w=bank10_q[lookup_index_w[wb]];
      assign raw1_w=bank11_q[lookup_index_w[wb]];
    end
    wire pending_hit_w=pending_write_q[wb]&&pending_index_q[wb]==lookup_index_w[wb];
    for(by=0;by<8;by=by+1)begin:g_forward
      wire forward_w=pending_hit_w&&pending_mask_q[wb][by];
      assign lookup_data0_w[wb][by*8+:8]=forward_w&&!pending_way_q[wb] ?
        pending_data_q[wb][by*8+:8]:raw0_w[by*8+:8];
      assign lookup_data1_w[wb][by*8+:8]=forward_w&&pending_way_q[wb] ?
        pending_data_q[wb][by*8+:8]:raw1_w[by*8+:8];
    end
    for(wg=0;wg<WRITE_GROUPS;wg=wg+1)begin:g_group
      reg [63:0] payload_q;
      wire select_w=data_index_w[wb]/WRITE_ROWS==wg;
      always @(posedge clk_i)if(data_write_w[wb]&&select_w)
        payload_q<=data_write_value_w[wb];
      for(wr=0;wr<WRITE_ROWS;wr=wr+1)begin:g_row
        localparam [SET_W+1:0] ROW=wg*WRITE_ROWS+wr;
        wire write_w=pending_write_q[wb]&&pending_index_q[wb]==ROW;
        for(by=0;by<8;by=by+1)begin:g_byte
          if(wb==0)begin:g_low
            always @(posedge clk_i)if(!rst_i&&write_w&&pending_mask_q[wb][by])begin
              if(!pending_way_q[wb])bank00_q[ROW][by*8+:8]<=payload_q[by*8+:8];
              else bank01_q[ROW][by*8+:8]<=payload_q[by*8+:8];
            end
          end else begin:g_high
            always @(posedge clk_i)if(!rst_i&&write_w&&pending_mask_q[wb][by])begin
              if(!pending_way_q[wb])bank10_q[ROW][by*8+:8]<=payload_q[by*8+:8];
              else bank11_q[ROW][by*8+:8]<=payload_q[by*8+:8];
            end
          end
        end
      end
`ifdef R64_ASSERT
      always @(posedge clk_i)if(!rst_i&&pending_write_q[wb]&&
          pending_index_q[wb]/WRITE_ROWS==wg&&payload_q!==pending_data_q[wb])
        $fatal(1,"DCache grouped write payload lost the accepted bank owner");
`endif
    end
  end endgenerate
  integer b;

  wire [1:0] bank_take_w,input_lane_w,lookup_read_w;
  wire [SET_W-1:0] input_set_w[0:1];
  wire [SET_W+1:0] input_index_w[0:1],lookup_index_w[0:1];
  wire [SET_W-1:0] lookup_set_w[0:1];
  generate for(g=0;g<2;g=g+1)begin:gen_index
    assign bank_take_w[g]=(take_w[0]&&bank0_w==g)||(take_w[1]&&bank1_w==g);
    // Select a legally admissible candidate before response-ready. During
    // overlap, lane0 can be valid in this bank yet ineligible (NC or owner set).
    // Such a lane must not supply the payload of an accepted lane1 request.
    assign input_lane_w[g]=!(req_valid_i[0]&&bank0_w==g&&
      ((state_q==IDLE&&!store_active_q)||overlap_candidate_w[0]));
    assign input_set_w[g]=req_addr_i[input_lane_w[g]*64+6+:SET_W];
    assign input_index_w[g]={input_set_w[g],req_addr_i[input_lane_w[g]*64+4+:2]};
    // A held second-bank miss must observe the first owner's newly installed
    // tag/data; otherwise the same line could be allocated in both ways.
    assign lookup_read_w[g]=bank_take_w[g]||(state_q==DELIVER&&stage_valid_q[g]&&owner_q!=g);
    assign lookup_set_w[g]=(state_q==IDLE||hit_overlap_w)?input_set_w[g]:address_q[g][6+:SET_W];
    assign lookup_index_w[g]=(state_q==IDLE||hit_overlap_w)?input_index_w[g]:{lookup_set_w[g],address_q[g][5:4]};
  end endgenerate
  always @(posedge clk_i)begin
    if(rst_i)begin
      reservation_q<=0;reservation_addr_q<=0;reservation_size_q<=0;
      store_active_q<=0;store_bank_q<=0;store_way_q<=0;store_hit_q<=0;store_poison_q<=0;
      state_q<=IDLE;stage_valid_q<=0;out_valid_q<=0;out_error_q<=0;out_compare_q<=0;
      lru_q<=0;poison_q<=0;
      fast_store_q<=0;owner_q<=0;way_q<=0;allocate_q<=0;error_q<=0;compare_q<=0;
      beat_q<=0;command_sent_q<=0;data_sent_q<=0;vrd0_q<=0;vrd1_q<=0;cache_q<=0;
    end else begin
      for(b=0;b<2;b=b+1)begin
        if(out_valid_q[b]&&rsp_ready_i[b])out_valid_q[b]<=0;
        if(hit_complete_w[b])begin
          stage_valid_q[b]<=0;out_valid_q[b]<=1;out_error_q[b]<=0;out_compare_q[b]<=0;
          out_token_q[b]<=token_q[b];out_data_q[b]<=hit0_w[b]?rd0_q[b]:rd1_q[b];
          lru_q[address_q[b][6+:SET_W]]<=hit0_w[b];
        end
      end
      for(b=0;b<2;b=b+1)if(bank_take_w[b])begin
        fast_store_q[b]<=req_fast_store_i[input_lane_w[b]];
        stage_valid_q[b]<=1;address_q[b]<=req_addr_i[input_lane_w[b]*64+:64];
        data_q[b]<=req_data_i[input_lane_w[b]*64+:64];expected_q[b]<=req_expected_i[input_lane_w[b]*64+:64];
        token_q[b]<=req_token_i[input_lane_w[b]*TOKEN_W+:TOKEN_W];op_q[b]<=req_op_i[input_lane_w[b]*2+:2];
        size_q[b]<=req_size_i[input_lane_w[b]*3+:3];strb_q[b]<=req_strb_i[input_lane_w[b]*8+:8];
        amo_q[b]<=req_amo_i[input_lane_w[b]*5+:5];cache_q[b]<=req_cache_i[input_lane_w[b]];
      end
      for(b=0;b<2;b=b+1)if(lookup_read_w[b])begin
        tagrd0_q[b]<=tag0_q[lookup_set_w[b]];tagrd1_q[b]<=tag1_q[lookup_set_w[b]];
        vrd0_q[b]<=valid0_q[lookup_set_w[b]];vrd1_q[b]<=valid1_q[lookup_set_w[b]];
        rd0_q[b]<=lookup_data0_w[b];rd1_q[b]<=lookup_data1_w[b];
      end
      // Candidate payload may change only while there is no slow owner.
      // A true start is an IDLE edge, so it captures the exact selected packet.
      // Late request qualification changes ownership, not this payload credit.
      if(state_q==IDLE)begin
        arithmetic_b_q<=data_q[arithmetic_candidate_w];
        arithmetic_op_q<=amo_q[arithmetic_candidate_w];
        arithmetic_word_q<=size_q[arithmetic_candidate_w]==2;
        arithmetic_upper_q<=address_q[arithmetic_candidate_w][2];
      end
      if(start_w)begin
        owner_q<=selected_w;error_q<=0;compare_q<=0;poison_q<=0;beat_q<=0;
        way_q<=resident_w[selected_w]?resident1_w[selected_w]:victim_w[selected_w];
        allocate_q<=op_q[selected_w]==0&&cache_q[selected_w];
        if(op_q[selected_w]==3&&amo_q[selected_w]==3)begin
          reservation_q<=0;old_q<=64'd1;
          if(reservation_q&&!reservation_clear_i&&reservation_addr_q==address_q[selected_w][63:2]&&reservation_size_q==size_q[selected_w])begin
            old_q<=0;new_q<=data_q[selected_w];command_sent_q<=0;data_sent_q<=0;state_q<=WRITE;
          end else state_q<=DELIVER;
        end else if(op_q[selected_w]==1)begin
          new_q<=data_q[selected_w];old_q<=0;
          command_sent_q<=0;data_sent_q<=0;state_q<=WRITE;
        end else if(op_q[selected_w]!=0&&hit_w[selected_w])begin
          old_q<=hit0_w[selected_w]?rd0_q[selected_w]:rd1_q[selected_w];state_q<=MODIFY;
        end else begin
          state_q<=READ;

        end
      end
      if(state_q==READ&&read_ready_i)state_q<=REFILL;
      if(state_q==REFILL&&beat_valid_i&&beat_ready_o)begin
        error_q<=error_q||beat_resp_i!=0;
        if(!allocate_q||beat_q==owner_address_w[5:3])old_q<=beat_data_i;
        beat_q<=beat_q+1'b1;
        if(!allocate_q||beat_q==7)begin
          if(allocate_q&&!error_q&&beat_resp_i==0&&!poison_q&&!invalidate_i)begin
            if(!way_q)begin tag0_q[set_w]<=owner_address_w[63:6+SET_W];end
            else begin tag1_q[set_w]<=owner_address_w[63:6+SET_W];end
            lru_q[set_w]<=!way_q;
          end
          state_q<=op_q[owner_q]!=0&&!error_q&&beat_resp_i==0?MODIFY:DELIVER;
        end
      end
      if(state_q==MODIFY)begin
        compare_q<=op_q[owner_q]==2&&old_q==expected_q[owner_q];
        if(op_q[owner_q]==3&&amo_q[owner_q]==2)begin
          reservation_q<=!reservation_clear_i;reservation_addr_q<=owner_address_w[63:2];
          reservation_size_q<=size_q[owner_q];state_q<=DELIVER;
        end else if(op_q[owner_q]==2&&old_q!=expected_q[owner_q])state_q<=DELIVER;
        else if(op_q[owner_q]==2)begin
          new_q<=old_q|data_q[owner_q];
          command_sent_q<=0;data_sent_q<=0;state_q<=WRITE;
        end else begin
          arithmetic_a_q<=arithmetic_word_q?{{32{arithmetic_word_a_w[31]}},arithmetic_word_a_w}:old_q;
          arithmetic_b_q<=arithmetic_word_q?{{32{arithmetic_word_b_w[31]}},arithmetic_word_b_w}:arithmetic_b_q;
          state_q<=AMO_EXEC;
        end
      end
      if(state_q==AMO_EXEC)begin
        arithmetic_parts_q<=arithmetic_parts_w;state_q<=AMO_FINISH;
      end
      if(state_q==AMO_FINISH)begin
        new_q<=arithmetic_store_w;command_sent_q<=0;data_sent_q<=0;state_q<=WRITE;
      end
      if(state_q==WRITE)begin
        if(write_ready_i)command_sent_q<=1;
        if(write_data_ready_i)data_sent_q<=1;
        if((command_sent_q||write_ready_i)&&(data_sent_q||write_data_ready_i))begin
          if(SPLIT_STORE_OWNER!=0&&op_q[owner_q]==1&&cache_q[owner_q])begin
            store_active_q<=1;store_bank_q<=owner_q;store_way_q<=way_q;
            store_hit_q<=cache_hit_w;store_poison_q<=poison_q||invalidate_i;store_data_q<=new_q;
            state_q<=IDLE;
          end else state_q<=BRESP;
        end
      end
      if(write_response_fire_w)begin
        if(store_active_q)begin
          store_active_q<=0;stage_valid_q[store_bank_q]<=0;
          if(!fast_store_q[store_bank_q])begin
            out_valid_q[store_bank_q]<=1;out_token_q[store_bank_q]<=token_q[store_bank_q];
            out_data_q[store_bank_q]<=0;out_error_q[store_bank_q]<=write_resp_i!=0;out_compare_q[store_bank_q]<=0;
          end
        end else begin
          error_q<=write_resp_i!=0;
          if(fast_store_q[owner_q])begin stage_valid_q[owner_q]<=0;state_q<=IDLE;end
          else state_q<=DELIVER;
        end
      end
      if(state_q==DELIVER&&output_free_w[owner_q])begin
        stage_valid_q[owner_q]<=0;out_valid_q[owner_q]<=1;
        out_token_q[owner_q]<=token_q[owner_q];out_data_q[owner_q]<=old_q;
        out_error_q[owner_q]<=error_q;out_compare_q[owner_q]<=compare_q&&!error_q;
        state_q<=IDLE;
      end
      if(reservation_clear_i||(state_q==WRITE&&owner_address_w[63:3]==reservation_addr_q[61:1])||
         (mutation_o&&mutation_word_o==reservation_addr_q[61:1]))reservation_q<=0;
      if(invalidate_i)begin
        vrd0_q<=0;vrd1_q<=0;poison_q<=1;if(store_active_q)store_poison_q<=1;
      end
    end
  end
`ifdef R64_ASSERT
  integer check_set,check_bank;
  always @(posedge clk_i)if(!rst_i)begin
    for(check_bank=0;check_bank<2;check_bank=check_bank+1)begin
      if(bank_take_w[check_bank]&&input_lane_w[check_bank]!=!(take_w[0]&&bank0_w==check_bank[0]))
        $fatal(1,"R64Dcache candidate address disagrees with accepted owner");
      if(lookup_read_w[check_bank]&&!bank_take_w[check_bank]&&state_q!=DELIVER)
        $fatal(1,"R64Dcache lookup without accepted or refresh owner");
    end
    if(store_active_q&&(!stage_valid_q[store_bank_q]||op_q[store_bank_q]!=1||!cache_q[store_bank_q]))
      $fatal(1,"Dcache detached store lost its retained stage");
    if(store_active_q&&start_w&&(selected_w==store_bank_q||op_q[selected_w]!=0||!cache_q[selected_w]||
        address_q[selected_w][6+:SET_W]==address_q[store_bank_q][6+:SET_W]))
      $fatal(1,"Dcache read crossed detached store exclusion");
    if(fill_write_w&&store_write_w&&beat_q[0]==write_owner_w)
      $fatal(1,"Dcache physical bank write port collision");
    if(beat_valid_i&&beat_ready_o&&beat_last_i!=(!allocate_q||beat_q==7))
      $fatal(1,"R64Dcache wrong physical read length");
    if((take_w[0]&&req_size_i[2:0]>3)||(take_w[1]&&req_size_i[5:3]>3))
      $fatal(1,"R64Dcache unsupported access width");
    if((|(take_w&req_fast_store_i))&&req_op_i[1:0]!=1)$fatal(1,"R64Dcache fast completion must be plain store");
    if(take_w[1]&&req_op_i[3:2]!=0)$fatal(1,"R64Dcache side effect must occupy lane zero");
    if(take_w==3&&bank0_w==bank1_w)$fatal(1,"R64Dcache bank overbooked");
    for(check_set=0;check_set<SETS;check_set=check_set+1)
      if(valid0_q[check_set]&&valid1_q[check_set]&&tag0_q[check_set]==tag1_q[check_set])
        $fatal(1,"R64Dcache duplicate resident line");
  end
`endif
`ifdef R64_ASSERT
  always @(posedge clk_i)if(!rst_i&&start_w&&op_q[selected_w]==3)begin
    if(arithmetic_candidate_w!==selected_w || !(stage_valid_q==1||stage_valid_q==2))
      $fatal(1,"AMO preparation source disagrees with unique accepted owner");
  end
`endif
endmodule
