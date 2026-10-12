`timescale 1ns / 1ps
module tb_r64_direction_capacity;
  parameter COMMIT=1, INDEX_W=10, COLD_STRONG=1;
  localparam ROWS=1<<INDEX_W;
  reg [1:0] train_valid=0,train_taken=0,held_valid=0,held_direction=0;
  reg [127:0] train_pc=0;
  reg capture_snapshot=1;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, invalidate = 0, recover = 0;
  reg [1:0] consume = 0, fault = 0;
  reg  [127:0] pc = 0;
  reg  [ 63:0] inst = 0;
  reg  [  7:0] length = 8'h44;
  wire [127:0] predicted;
  wire [1:0] taken, divert;
  reg update = 0, conditional = 0, indirect = 0, update_taken = 0;
  reg [63:0] upc = 0, target = 0;
  // Direct numerical/RAS oracle: lookup preparation and confirmation are
  // connected at the same request boundary. The production FE separately tests
  // delayed journal/rollback ownership; this preserves all original 12000 cases.
  wire [341:0] preparation;
  wire [125:0] target_snapshot;
  wire [1:0] target_hit, direction_valid, direction;
  wire [5:0] write_index, post_pointer;
  wire [  7:0] post_count;
  wire [  1:0] ras_push;
  wire [127:0] return_pc;
  genvar prep_lane;
  generate
    for (prep_lane = 0; prep_lane < 2; prep_lane = prep_lane + 1) begin : g_prepare
      R64PredictionPrepare prepare (
        .pc_i(pc[prep_lane*64+:64]),
        .inst_i(inst[prep_lane*32+:32]),
        .length_i(length[prep_lane*4+:4]),
        .fault_i(fault[prep_lane]),
        .planned_target_i(64'b0),
        .previous_pc_i(pc[63:0]),
        .previous_length_i(length[3:0]),
        .preparation_o(preparation[prep_lane*171+:171])
      );
    end
  endgenerate
  R64Predictor #(.DIRECTION_COMMIT_TRAIN(COMMIT),
    .DIRECTION_INDEX_W(INDEX_W),.DIRECTION_COLD_STRONG(COLD_STRONG)) dut (
    .direction_train_valid_i(train_valid),.direction_train_pc_i(train_pc),.direction_train_taken_i(train_taken),
    .clk_i(clk),
    .rst_i(rst),
    .invalidate_i(invalidate),
    .recover_i(recover),
    .rollback_i(1'b0),
    .confirm_i(consume),
    .confirm_state_valid_i(2'b11),
    .confirm_push_i(ras_push),
    .confirm_index_i(write_index),
    .confirm_pointer_i(post_pointer),
    .confirm_count_i(post_count),
    .confirm_data_i({return_pc[127:65], return_pc[63:1]}),
    .journal_valid_i(4'b0),
    .journal_index_i(12'b0),
    .journal_data_i(252'b0),
    .write_index_o(write_index),
    .post_pointer_o(post_pointer),
    .post_count_o(post_count),
    .push_o(ras_push),
    .return_pc_o(return_pc),
    .planned_match_o(),
    .lookup_pc_i(pc),
    .lookup_target_o(target_snapshot),
    .lookup_target_hit_o(target_hit),
    .lookup_direction_valid_o(direction_valid),
    .lookup_direction_o(direction),
    .target_snapshot_i(target_snapshot),
    .target_hit_snapshot_i(target_hit),
    .direction_valid_snapshot_i(held_valid),
    .direction_snapshot_i(held_direction),
    .preparation_i(preparation),
    .planned_target_i(64'b0),
    .consume_i(consume),
    .pc_i(pc),
    .inst_i(inst),
    .length_i(length),
    .fault_i(fault),
    .next_pc_o(predicted),
    .taken_o(taken),
    .divert_o(divert),
    .update_i(update),
    .update_pc_i(upc),
    .update_conditional_i(conditional),
    .update_indirect_i(indirect),
    .update_taken_i(update_taken),
    .update_target_i(target)
  );
  wire [  5:0] ref_write_index;
  wire [  5:0] ref_post_pointer;
  wire [  7:0] ref_post_count;
  wire [  1:0] ref_ras_push;
  wire [127:0] ref_return_pc;
  wire [125:0] ref_target_snapshot;
  wire [  1:0] ref_target_hit;
  wire [  1:0] ref_direction_valid;
  wire [  1:0] ref_direction;
  wire [127:0] ref_predicted;
  wire [  1:0] ref_taken;
  wire [  1:0] ref_divert;

  reg [ROWS-1:0] ref_valid=0;
  integer ref_counter[0:ROWS-1];
  reg [63:0] ref_target_valid=0;
  reg [15:0] ref_target_tag[0:63];
  reg [62:0] ref_target[0:63];
  integer checks=0,cycles=0,same_row=0,different_row=0,cold=0,old_capture=0,held=0;
  integer k,j,idx,delta;
  reg [31:0] random_q=32'h785492a1;
  reg [63:0] event_pc;
  reg event_taken,event_valid;
  task demand(input yes,input [511:0]why);
    begin checks+=1;if(yes!==1'b1)$fatal(1,"%0s",why);end
  endtask
  task tick;
    begin
      #1;
      if(!rst)for(integer l=0;l<2;l+=1)begin
        idx=int'(pc[l*64+1+:INDEX_W]);
        demand(direction_valid[l]===ref_valid[idx],"lookup validity is not old Q");
        if(ref_valid[idx])demand(direction[l]===(ref_counter[idx]>=2),"lookup did not preserve old counter");
      end
      if(rst)begin held_valid=0;held_direction=0;end
      else if(capture_snapshot)begin
        held_valid=direction_valid;held_direction=direction;
        if((COMMIT&&train_valid!=0)||(!COMMIT&&update&&conditional))old_capture+=1;
      end else if((COMMIT&&train_valid!=0)||(!COMMIT&&update&&conditional))held+=1;
      @(posedge clk);
      cycles+=1;
      if(rst||invalidate)begin ref_valid=0;ref_target_valid=0;end
      else begin
        for(integer l=0;l<2;l+=1)begin
          event_valid=COMMIT?train_valid[l]:(l==0&&update&&conditional);
          event_pc=COMMIT?train_pc[l*64+:64]:upc;
          event_taken=COMMIT?train_taken[l]:update_taken;
          if(event_valid)begin
            idx=int'(event_pc[INDEX_W:1]);delta=event_taken?1:-1;
            if(!ref_valid[idx])begin ref_counter[idx]=COLD_STRONG?(event_taken?3:0):(event_taken?2:1);cold+=1;end
            else begin
              ref_counter[idx]+=delta;
              if(ref_counter[idx]<0)ref_counter[idx]=0;
              if(ref_counter[idx]>3)ref_counter[idx]=3;
            end
            ref_valid[idx]=1;
          end
        end
        if(update&&indirect)begin
          idx=int'(upc[6:1]);ref_target_valid[idx]=1;
          ref_target_tag[idx]=upc[22:7];ref_target[idx]=target[63:1];
        end
        if(train_valid==3)begin
          if(train_pc[1+:INDEX_W]==train_pc[65+:INDEX_W])same_row+=1;else different_row+=1;
        end
      end
      #1;
      demand(dut.direction_valid_q===ref_valid,"direction valid update or invalidation mismatch");
      for(integer r=0;r<ROWS;r+=1)
        if(ref_valid[r])demand(dut.direction_q[r]===2'(ref_counter[r]),"lane-ordered saturation/reference mismatch");
      demand(dut.target_valid_q===ref_target_valid,"commit training changed indirect valid path");
      for(integer r=0;r<64;r+=1)
        if(ref_target_valid[r])demand(dut.target_tag_q[r]===ref_target_tag[r]&&
          dut.target_q[r]===ref_target[r],"commit training changed indirect target path");
      demand(taken===(held_valid&held_direction),"held prediction changed after current training");
      @(negedge clk);
    end
  endtask
  initial begin
    pc={64'h80000300,64'h80000100};
    inst={32'h00000463,32'h00000463};
    consume=0;conditional=1;
    tick();rst=0;
    // The model initializes only the first observation to weak/strong. The
    // second observation always applies the ordinary saturating increment.
    // Exercise both orders after independent invalidation, then lane1-only
    // at an index whose high bits distinguish the 1024-row implementation.
    for(j=0;j<2;j+=1)begin
      invalidate=1;train_valid=0;update=0;tick();invalidate=0;
      train_valid=3;train_pc={64'h80000100+64'(ROWS*2),64'h80000100};
      train_taken=j?2'b01:2'b10;update=1;upc=64'h80000100;update_taken=j[0];
      tick();
      if(COMMIT)demand(dut.direction_q[128]===2'(j?(COLD_STRONG?2:1):(COLD_STRONG?1:2)),
        "cold pair must initialize once then apply ordinary second step");
    end
    invalidate=1;train_valid=0;update=0;tick();invalidate=0;
    train_valid=2;train_pc={64'h80000400,64'h80000000};train_taken=2;pc=train_pc;tick();
    if(COMMIT)demand(direction_valid[1]&&direction[1]&&
       (INDEX_W<10||!direction_valid[0]),"lane1 high index training aliases/truncates");
    train_valid=0;update=0;tick();
    // Repeated same-row pairs also cover both saturation limits.
    for(j=0;j<16;j+=1)begin
      train_valid=3;train_pc={64'h80000100+64'(ROWS*2),64'h80000100};train_taken=2'(j);
      update=1;upc=64'h80000100;update_taken=j[0];
      tick();
    end
    // Only accepted resolves must train when OFF; only commit events when ON.
    train_valid=0;
    for(j=0;j<8;j+=1)begin update_taken=j[0];tick();end
    update=0;train_valid=3;train_taken=3;invalidate=1;tick();tick();
    invalidate=0;train_valid=0;tick();
    for(j=0;j<1600;j+=1)begin
      random_q={random_q[30:0],random_q[31]^random_q[21]^random_q[1]^random_q[0]};
      train_valid=random_q[1:0];train_taken=random_q[3:2];
      train_pc={64'h80000000+(64'(random_q[8+:INDEX_W])<<1),
                64'h80000000+(64'(random_q[18+:INDEX_W])<<1)};
      if(j%3==0)train_pc[127:64]=train_pc[63:0]+64'(ROWS*2);
      if(j%7==0)train_pc={64'h80000100+64'(ROWS*2),64'h80000100};
      update=random_q[4];conditional=random_q[5];indirect=random_q[6];
      update_taken=random_q[7];upc=train_pc[63:0];target={random_q,~random_q};
      capture_snapshot=j%4==0;
      invalidate=j%113==112;recover=random_q[24];
      tick();
    end
    demand(same_row>80&&different_row>80&&cold>200&&old_capture>(COMMIT?100:50)&&held>(COMMIT?300:100),
      "directed pair/capture/held coverage missing");
    $display("[PASS] tb_r64_direction_capacity commit=%0d width=%0d strong=%0d checks=%0d cycles=%0d same=%0d different=%0d cold=%0d old=%0d held=%0d",
      COMMIT,INDEX_W,COLD_STRONG,checks,cycles,same_row,different_row,cold,old_capture,held);
    $finish;
  end
endmodule
