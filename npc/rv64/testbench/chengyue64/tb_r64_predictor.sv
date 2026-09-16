`timescale 1ns/1ps
module tb_r64_predictor;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,invalidate=0,recover=0;
 reg [1:0] consume=0,fault=0;
 reg [127:0] pc=0;reg [63:0] inst=0;reg [7:0] length=8'h44;
 wire [127:0] predicted;wire [1:0] taken,divert;
 reg update=0,conditional=0,indirect=0,update_taken=0;
 reg [63:0] upc=0,target=0;
 // Direct numerical/RAS oracle: lookup preparation and confirmation are
 // connected at the same request boundary. The production FE separately tests
 // delayed journal/rollback ownership; this preserves all original 12000 cases.
 wire [341:0] preparation;
 wire [125:0] target_snapshot;
 wire [1:0] target_hit,direction_valid,direction;
 wire [5:0] write_index,post_pointer;
 wire [7:0] post_count;
 wire [1:0] ras_push;
 wire [127:0] return_pc;
 genvar prep_lane;
 generate for(prep_lane=0;prep_lane<2;prep_lane=prep_lane+1)begin:g_prepare
 R64PredictionPrepare prepare(.pc_i(pc[prep_lane*64+:64]),
 .inst_i(inst[prep_lane*32+:32]),.length_i(length[prep_lane*4+:4]),
 .fault_i(fault[prep_lane]),.planned_target_i(64'b0),
 .previous_pc_i(pc[63:0]),.previous_length_i(length[3:0]),
 .preparation_o(preparation[prep_lane*171+:171]));
 end endgenerate
 R64Predictor dut(.clk_i(clk),.rst_i(rst),.invalidate_i(invalidate),.recover_i(recover),
 .rollback_i(1'b0),.confirm_i(consume),.confirm_state_valid_i(2'b11),
 .confirm_push_i(ras_push),.confirm_index_i(write_index),
 .confirm_pointer_i(post_pointer),.confirm_count_i(post_count),
 .confirm_data_i({return_pc[127:65],return_pc[63:1]}),
 .journal_valid_i(4'b0),.journal_index_i(12'b0),.journal_data_i(252'b0),
 .write_index_o(write_index),.post_pointer_o(post_pointer),.post_count_o(post_count),
 .push_o(ras_push),.return_pc_o(return_pc),.planned_match_o(),
 .lookup_pc_i(pc),.lookup_target_o(target_snapshot),.lookup_target_hit_o(target_hit),
 .lookup_direction_valid_o(direction_valid),.lookup_direction_o(direction),
 .target_snapshot_i(target_snapshot),.target_hit_snapshot_i(target_hit),
 .direction_valid_snapshot_i(direction_valid),.direction_snapshot_i(direction),
 .preparation_i(preparation),.planned_target_i(64'b0),
 .consume_i(consume),.pc_i(pc),.inst_i(inst),.length_i(length),.fault_i(fault),
 .next_pc_o(predicted),.taken_o(taken),.divert_o(divert),.update_i(update),.update_pc_i(upc),
 .update_conditional_i(conditional),.update_indirect_i(indirect),.update_taken_i(update_taken),.update_target_i(target));
 reg [63:0] stack[0:7],scratch[0:7];
 integer count=0,scratch_count,n,lane,j,op,rd,rs,im,bytes,observed_returns=0,overflows=0,pops=0,pushes=0,holds=0,recovers=0;
 reg [31:0] random_q=32'hb71d369a,instruction;
 reg [63:0] address,next_expected,return_address;
 reg jump,indirect_op,push,pop,stack_predict,compressed;
 function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
 function [31:0] jal(input integer rd,offset);
 reg [20:0] v;begin v=offset;jal={v[20],v[10:1],v[11],v[19:12],5'(rd),7'h6f};end endfunction
 function [31:0] jalr(input integer rd,rs,offset);jalr={12'(offset),5'(rs),3'b0,5'(rd),7'h67};endfunction
 task tick;begin @(posedge clk);#1;end endtask
 task expect0(input [63:0] value,input take);
 begin #1;if(divert[0]!==(take&&value!=pc[63:0]+{60'b0,length[3:0]}))$fatal(1,"predictor discontinuity basic oracle");
 if(predicted[63:0]!==value||taken[0]!==take)$fatal(1,"predictor basic expected=%h/%b got=%h/%b",value,take,predicted[63:0],taken[0]);end endtask
 task model_lane(input integer which,input integer mutate);
 begin
  instruction=inst[which*32+:32];address=pc[which*64+:64];bytes=length[which*4+:4];
  compressed=bytes==2;jump=0;indirect_op=0;rd=0;rs=0;im=0;
  if(compressed)begin
    if(instruction[15:13]==4&&instruction[1:0]==2&&instruction[6:2]==0&&instruction[11:7]!=0)begin
      indirect_op=1;rd=instruction[12] ? 1:0;rs=instruction[11:7];
    end
  end else begin
    jump=instruction[6:0]==7'h6f;indirect_op=instruction[6:0]==7'h67;
    rd=instruction[11:7];rs=instruction[19:15];
    if(jump)im=$signed({instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0});
    if(indirect_op)im=$signed(instruction[31:20]);
  end
  push=(jump||indirect_op)&&(rd==1||rd==5)&&!fault[which];
  pop=indirect_op&&(rs==1||rs==5)&&(!(rd==1||rd==5)||rd!=rs)&&!fault[which];
  stack_predict=pop&&scratch_count>0&&im==0;
  next_expected=address+bytes;
  if(jump&&!fault[which])next_expected=address+im;
  if(stack_predict)next_expected=scratch[scratch_count-1];
  if(!mutate)begin
    if(divert[which]!==(((jump&&!fault[which])||stack_predict)&&next_expected!=address+bytes))
      $fatal(1,"predictor discontinuity RAS oracle");
    if(predicted[which*64+:64]!==next_expected||taken[which]!==((jump&&!fault[which])||stack_predict))
      $fatal(1,"RAS prediction lane=%0d op=%h count=%0d expected=%h got=%h",which,instruction,scratch_count,next_expected,predicted[which*64+:64]);
    if(stack_predict)observed_returns=observed_returns+1;
  end
  if(pop&&scratch_count>0)begin scratch_count=scratch_count-1;if(mutate)pops=pops+1;end
  if(push)begin
    if(scratch_count==8)begin
      for(j=0;j<7;j=j+1)scratch[j]=scratch[j+1];
      scratch_count=7;if(mutate)overflows=overflows+1;
    end
    scratch[scratch_count]=address+bytes;scratch_count=scratch_count+1;
    if(mutate)pushes=pushes+1;
  end
 end endtask
 initial begin
  tick();rst=0;
  pc={64'h104,64'h100};inst={32'h13,32'h00001463};
  expect0(64'h104,0);
  update=1;conditional=1;upc=64'h100;update_taken=1;tick();update=0;expect0(64'h108,1);
  update=1;update_taken=0;tick();tick();update=0;expect0(64'h104,0);
  conditional=0;indirect=1;upc=64'h100;target=64'h87654322;update=1;tick();update=0;
  inst[31:0]=jalr(0,8,0);expect0(target,1);
  invalidate=1;tick();invalidate=0;expect0(64'h104,0);
  indirect=0;
  for(n=0;n<12000;n=n+1)begin
    random_q=rng(random_q);consume=random_q[1:0]==3 ? 2:random_q[1:0];
    if(consume==0)holds=holds+1;
    recover=n%97==96;invalidate=n%701==700;
    fault={random_q[8:7]==3,random_q[6:5]==3};
    for(lane=0;lane<2;lane=lane+1)begin
      random_q=rng(random_q);op=random_q[3:0];rd=random_q[5] ? 1:5;rs=random_q[6] ? 1:5;
      pc[lane*64+:64]=64'h80000000+n*16+lane*4;length[lane*4+:4]=4;
      case(op)
        0,1,2,3:inst[lane*32+:32]=jal(rd,16);
        4:inst[lane*32+:32]=jal(0,8);
        5,6,7,8:inst[lane*32+:32]=jalr(0,rs,0);
        9:inst[lane*32+:32]=jalr(rd,rs,0);
        10:inst[lane*32+:32]=jalr(rd,8,0);
        11:inst[lane*32+:32]=jalr(0,rs,8);
        12,13:begin
          length[lane*4+:4]=2;
          inst[lane*32+:32]=32'h8002|(rs<<7)|((op==13)<<12);
        end
        default:inst[lane*32+:32]=32'h13;
      endcase
    end
    #1;scratch_count=count;for(j=0;j<8;j=j+1)scratch[j]=stack[j];
    model_lane(0,0);model_lane(1,0);
    scratch_count=count;for(j=0;j<8;j=j+1)scratch[j]=stack[j];
    if(consume>=1)model_lane(0,1);if(consume==2)model_lane(1,1);
    if(recover||invalidate)begin count=0;recovers=recovers+1;end
    else begin count=scratch_count;for(j=0;j<8;j=j+1)stack[j]=scratch[j];end
    tick();
  end
  if(observed_returns<500||overflows==0||holds<500||pops<500||pushes<500)$fatal(1,"insufficient RAS coverage");
  $display("[R64-PREDICTOR] lookups=24000 returns=%0d push=%0d pop=%0d overflow=%0d hold=%0d recovery=%0d hints/dual/fault=PASS",
    observed_returns,pushes,pops,overflows,holds,recovers);
  $display("[PASS] tb_r64_predictor");$finish;
 end
endmodule
