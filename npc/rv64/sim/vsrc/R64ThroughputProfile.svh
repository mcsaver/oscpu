// Simulation-only throughput diagnosis. No output drives production RTL.
// Head-kind and head-LSQ bins partition unfinished-head cycles separately;
// IQ-ready counts overlap those bins and are not additive stall causes.
`define TP_R `R64_SYSTEM_HIER.core.backend.rob
`define TP_L `R64_SYSTEM_HIER.core.memory.unit.lsu
`define TP_I `R64_SYSTEM_HIER.core.backend.execution.issue
reg [63:0] tp_head_kind [0:255];
reg [63:0] tp_head_lsq [0:14];
reg [63:0] tp_iq_ready [0:2];
reg [63:0] tp_no_issue_ready, tp_no_issue_wait, tp_no_issue_empty;
reg [63:0] tp_issue_width [0:2];
// Ordered existential filters partition zero-admission cycles, not causal savings:
// 0 flush, 1 empty, 2 cancel-only, 3 init-only, 4 operands, 5 older-serial,
// 6 serial-head, 7 serial-permission, 8 FU allow, 9 RR credit, 10 selection/cancel.
reg [63:0] tp_zero_reason [0:10];
reg [63:0] tp_zero_operand_head [0:255];
reg [63:0] tp_execute_width [0:2], tp_rr_occupancy [0:6], tp_rr_pending [0:6];
reg [63:0] tp_issue_pending_ops, tp_rr_direct_ops;
integer tp_row, tp_lane, tp_reason, tp_execute, tp_rr_count, tp_pending_count;
reg [6:0] tp_candidates;
// Observe the actual operand eligibility expression, including future real-value
// notices, rather than duplicating the scheduler's readiness policy here.
// Production CoreTop instantiates 16 IQ slots; keep this observer explicit
  // because Verilator disallows hierarchical width queries in generate bounds.
  localparam TP_ISSUE_SLOTS=16;
  initial if ($bits(`TP_I.valid_q)!=TP_ISSUE_SLOTS)
    $fatal(1,"throughput observer IQ width mismatch");
  wire [TP_ISSUE_SLOTS-1:0] tp_operand_qualified_w;
genvar tp_source_row;
generate
  for(tp_source_row=0;tp_source_row<TP_ISSUE_SLOTS;tp_source_row=tp_source_row+1) begin : gen_tp_operand
    assign tp_operand_qualified_w[tp_source_row]=`TP_I.gen_eligibility[tp_source_row].operands_w;
  end
endgenerate
integer tp_k, tp_slot, tp_stage, tp_ready, tp_width;
reg [8:0] tp_tag;
always @(posedge clk_i) begin
  if (rst_i) begin
    for (tp_k=0;tp_k<256;tp_k=tp_k+1) tp_head_kind[tp_k]=0;
    for (tp_k=0;tp_k<15;tp_k=tp_k+1) tp_head_lsq[tp_k]=0;
    for (tp_k=0;tp_k<3;tp_k=tp_k+1) begin
      tp_iq_ready[tp_k]=0;
      tp_issue_width[tp_k]=0;
    end
    for (tp_k=0;tp_k<11;tp_k=tp_k+1) tp_zero_reason[tp_k]=0;
    for (tp_k=0;tp_k<256;tp_k=tp_k+1) tp_zero_operand_head[tp_k]=0;
    for (tp_k=0;tp_k<3;tp_k=tp_k+1) tp_execute_width[tp_k]=0;
    for (tp_k=0;tp_k<7;tp_k=tp_k+1) begin
      tp_rr_occupancy[tp_k]=0;
      tp_rr_pending[tp_k]=0;
    end
    tp_issue_pending_ops=0;
    tp_rr_direct_ops=0;
    tp_candidates=0;
    tp_reason=0;
    tp_execute=0;
    tp_rr_count=0;
    tp_pending_count=0;
    tp_no_issue_ready=0;
    tp_no_issue_wait=0;
    tp_no_issue_empty=0;
    tp_tag=0;
    tp_slot=0;
    tp_stage=0;
    tp_ready=0;
    tp_width=0;
  end else if (run_i) begin
    tp_rr_direct_ops=tp_rr_direct_ops+64'($countones(`R64_SYSTEM_HIER.core.backend.execution.registers.direct_admit_w));
    tp_width=$countones(`R64_SYSTEM_HIER.core.backend.execution.issue_fire_w);
    tp_issue_width[tp_width]=tp_issue_width[tp_width]+1;
    tp_ready=$countones(`TP_I.common_w);
    tp_iq_ready[tp_ready>1?2:tp_ready]=tp_iq_ready[tp_ready>1?2:tp_ready]+1;
    tp_execute=$countones(`R64_SYSTEM_HIER.core.backend.execution.registers.out_fire_w);
    tp_execute_width[tp_execute]=tp_execute_width[tp_execute]+1;
    tp_rr_count=$countones(`R64_SYSTEM_HIER.core.backend.execution.registers.ingress_valid_q);
    tp_pending_count=0;
    for(tp_lane=0;tp_lane<2;tp_lane=tp_lane+1) begin
      if(`R64_SYSTEM_HIER.core.backend.execution.issue_fire_w[tp_lane] &&
         (|`R64_SYSTEM_HIER.core.backend.execution.issue_pending_w[tp_lane*3+:3]))
        tp_issue_pending_ops=tp_issue_pending_ops+1;
      tp_rr_count=tp_rr_count+int'(`R64_SYSTEM_HIER.core.backend.execution.registers.terminal_count_q[tp_lane]);
      if(`R64_SYSTEM_HIER.core.backend.execution.registers.ingress_valid_q[tp_lane] &&
         (|`R64_SYSTEM_HIER.core.backend.execution.registers.ingress_late_pending_q[tp_lane]))
        tp_pending_count=tp_pending_count+1;
      for(tp_row=0;tp_row<2;tp_row=tp_row+1)
        if((`R64_SYSTEM_HIER.core.backend.execution.registers.terminal_count_q[tp_lane]==2 ||
            (`R64_SYSTEM_HIER.core.backend.execution.registers.terminal_count_q[tp_lane]==1 &&
             int'(`R64_SYSTEM_HIER.core.backend.execution.registers.terminal_head_q[tp_lane])==tp_row)) &&
           !`R64_SYSTEM_HIER.core.backend.execution.registers.terminal_dead_q[tp_lane*2+tp_row] &&
           (|`R64_SYSTEM_HIER.core.backend.execution.registers.late_pending_q[tp_lane*2+tp_row]))
          tp_pending_count=tp_pending_count+1;
    end
    tp_rr_occupancy[tp_rr_count]=tp_rr_occupancy[tp_rr_count]+1;
    tp_rr_pending[tp_pending_count]=tp_rr_pending[tp_pending_count]+1;
    if(tp_width==0) begin
      tp_candidates=0;
      for(tp_row=0;tp_row<$bits(`TP_I.valid_q);tp_row=tp_row+1) begin
        if(`TP_I.live_w[tp_row]) begin
          tp_candidates[0]=1;
          if(`TP_I.INIT_CURRENT_READY != 0 || (!`TP_I.init0_w[tp_row] && !`TP_I.init1_w[tp_row])) begin
            tp_candidates[1]=1;
            if(tp_operand_qualified_w[tp_row]) begin
              tp_candidates[2]=1;
              if(!(|(`TP_I.serial_dependency_q[tp_row] & `TP_I.serial_active_i))) begin
                tp_candidates[3]=1;
                if(`TP_I.class_q[tp_row]!=3'd5 || `TP_I.age_w[tp_row]==0) begin
                  tp_candidates[4]=1;
                  if(`TP_I.class_q[tp_row]!=3'd5 || `TP_I.serial_allow_i) begin
                    tp_candidates[5]=1;
                    if(`TP_I.fu_allow_i[`TP_I.class_q[tp_row]]) tp_candidates[6]=1;
                  end
                end
              end
            end
          end
        end
      end
      if(`TP_I.flush_i) tp_reason=0;
      else if(!(|`TP_I.valid_q)) tp_reason=1;
      else if(!tp_candidates[0]) tp_reason=2;
      else if(!tp_candidates[1]) tp_reason=3;
      else if(!tp_candidates[2]) tp_reason=4;
      else if(!tp_candidates[3]) tp_reason=5;
      else if(!tp_candidates[4]) tp_reason=6;
      else if(!tp_candidates[5]) tp_reason=7;
      else if(!tp_candidates[6]) tp_reason=8;
      else if(!(|`R64_SYSTEM_HIER.core.backend.execution.read_credit_w)) tp_reason=9;
      else tp_reason=10;
      tp_zero_reason[tp_reason]=tp_zero_reason[tp_reason]+1;
      if(tp_reason==4 && `TP_R.count_q!=0 && `TP_R.valid_q[`TP_R.head_q] &&
         !`TP_R.done_q[`TP_R.head_q])
        tp_zero_operand_head[int'(`TP_R.meta_q[`TP_R.head_q][196+:8])]=
          tp_zero_operand_head[int'(`TP_R.meta_q[`TP_R.head_q][196+:8])]+1;

      if(tp_ready>0) tp_no_issue_ready=tp_no_issue_ready+1;
      else if (|`TP_I.valid_q) tp_no_issue_wait=tp_no_issue_wait+1;
      else tp_no_issue_empty=tp_no_issue_empty+1;
    end
    if(`TP_R.count_q!=0 && `TP_R.valid_q[`TP_R.head_q] && !`TP_R.done_q[`TP_R.head_q]) begin
      tp_k=int'(`TP_R.meta_q[`TP_R.head_q][196+:8]);
      tp_head_kind[tp_k]=tp_head_kind[tp_k]+1;
      tp_tag={`TP_R.generation_q[`TP_R.head_q],`TP_R.head_q};
      tp_stage=0;
      for(tp_slot=0;tp_slot<20;tp_slot=tp_slot+1)
        if(`TP_L.state_q[tp_slot]!=0 && `TP_L.tag_q[tp_slot]==tp_tag) begin
          if(!`TP_L.bound_q[tp_slot]) tp_stage=1;
          else if(!`TP_L.checked_q[tp_slot]) tp_stage=2;
          else case(`TP_L.state_q[tp_slot])
            1:tp_stage=3;
            2:tp_stage=`TP_L.tr_issued_q[tp_slot]?5:4;
            6:tp_stage=6;
            3:begin
              if((`TP_L.store_w[tp_slot] || `TP_L.atomic_w[tp_slot] ||
                  `TP_L.class_q[tp_slot]>=2 || `TP_L.misaligned_q[tp_slot]) &&
                 !`TP_L.effect_q[tp_slot]) tp_stage=7;
              else if(`TP_L.prepared_valid_q && `TP_L.prepared_tag_q==tp_tag) tp_stage=8;
              else tp_stage=9;
            end
            4:tp_stage=`TP_L.mem_issued_q[tp_slot]?11:10;
            5:tp_stage=12;
            7:tp_stage=13;
            default:tp_stage=14;
          endcase
        end
      tp_head_lsq[tp_stage]=tp_head_lsq[tp_stage]+1;
    end
  end
end
final begin
  for(tp_k=0;tp_k<11;tp_k=tp_k+1)
    $display("ZERO_ISSUE_PROFILE reason=%0d cycles=%0d",tp_k,tp_zero_reason[tp_k]);
  for(tp_k=0;tp_k<3;tp_k=tp_k+1)
    $display("ZERO_ISSUE_PROFILE execute_width=%0d cycles=%0d",tp_k,tp_execute_width[tp_k]);
  for(tp_k=0;tp_k<7;tp_k=tp_k+1) begin
    $display("ZERO_ISSUE_PROFILE rr_occupancy=%0d cycles=%0d",tp_k,tp_rr_occupancy[tp_k]);
    $display("ZERO_ISSUE_PROFILE rr_pending=%0d cycles=%0d",tp_k,tp_rr_pending[tp_k]);
  end
  for(tp_k=0;tp_k<256;tp_k=tp_k+1)
    if(tp_zero_operand_head[tp_k]!=0)
      $display("ZERO_ISSUE_PROFILE operand_wait_head_kind=%0d cycles=%0d",tp_k,tp_zero_operand_head[tp_k]);
  $display("ZERO_ISSUE_PROFILE rr_direct_ops=%0d",tp_rr_direct_ops);
  $display("ZERO_ISSUE_PROFILE issue_pending_ops=%0d",tp_issue_pending_ops);
  for(tp_k=0;tp_k<256;tp_k=tp_k+1)
    if(tp_head_kind[tp_k]!=0) $display("THROUGHPUT_PROFILE head_kind=%0d cycles=%0d",tp_k,tp_head_kind[tp_k]);
  for(tp_k=0;tp_k<15;tp_k=tp_k+1)
    $display("THROUGHPUT_PROFILE head_lsq_stage=%0d cycles=%0d",tp_k,tp_head_lsq[tp_k]);
  for(tp_k=0;tp_k<3;tp_k=tp_k+1) begin
    $display("THROUGHPUT_PROFILE ready_bin=%0d cycles=%0d",tp_k,tp_iq_ready[tp_k]);
    $display("THROUGHPUT_PROFILE issue_width=%0d cycles=%0d",tp_k,tp_issue_width[tp_k]);
  end
  $display("THROUGHPUT_PROFILE no_issue_ready=%0d no_issue_wait=%0d no_issue_empty=%0d",
           tp_no_issue_ready,tp_no_issue_wait,tp_no_issue_empty);
end
`undef TP_R
`undef TP_L
`undef TP_I


// Architectural recovery samples only: core.redirect is the authoritative
// publication; frontend.redirect_i is its registered inbox delivery. The
// frontend's prediction/repair stream_redirect_w must never start a sample.
// PC is the public dispatch R64_U_PC field (bits 63:0 in each R64_UOP_W lane).
// Births at publication/delivery are excluded by phase as well as the backend
// recovery fence. A newer publication supersedes the older sample even when
// both target PCs are identical. "Next Birth" is the next nonempty CLOCK EDGE,
// not the partner instruction of a dual Birth at the target's first edge.
localparam TP_REC_BINS=257;  // 0..255 exact cycles, 256 means >=256.
reg [63:0] tp_rec_hist[0:2][0:TP_REC_BINS-1];
reg [63:0] tp_rec_fill_hist[0:2][0:TP_REC_BINS-1];
reg [63:0] tp_rec_samples[0:2], tp_rec_sum[0:2], tp_rec_min[0:2], tp_rec_max[0:2];
reg [63:0] tp_rec_superseded[1:3];
reg [63:0] tp_rec_cycle, tp_rec_publications, tp_rec_local_matches, tp_rec_local_deliveries;
reg [63:0] tp_rec_completed, tp_rec_old_target_ignored;
reg [63:0] tp_rec_target, tp_rec_publication_edge, tp_rec_local_edge, tp_rec_first_edge;
// 0 idle, 1 wait local architectural delivery, 2 wait target Birth, 3 wait next Birth.
reg [1:0] tp_rec_phase;
reg [2:0] tp_rec_fill_seen;
wire tp_rec_fill_w = `R64_SYSTEM_HIER.core.frontend.access.u_cache.state_q == 2'd2;
wire tp_rec_target_birth_w =
    (`R64_SYSTEM_HIER.core.backend.birth_w[0] &&
     `R64_SYSTEM_HIER.core.backend.decode_uop_w[0+:64] == tp_rec_target) ||
    (`R64_SYSTEM_HIER.core.backend.birth_w[1] &&
     `R64_SYSTEM_HIER.core.backend.decode_uop_w[`R64_UOP_W+:64] == tp_rec_target);
integer tp_rec_metric, tp_rec_bin, tp_rec_phase_index;
reg [63:0] tp_rec_hist_sum, tp_rec_fill_sum;
reg [63:0] tp_rec_unfinished[0:2], tp_rec_metric_superseded[0:2], tp_rec_started[0:2];
task tp_rec_record;
  input integer metric;
  input [63:0] latency;
  input fill_seen;
  integer bin_index;
  begin
    bin_index=latency>=256 ? 256 : int'(latency);
    tp_rec_hist[metric][bin_index]=tp_rec_hist[metric][bin_index]+1;
    if(fill_seen)tp_rec_fill_hist[metric][bin_index]=tp_rec_fill_hist[metric][bin_index]+1;
    tp_rec_samples[metric]=tp_rec_samples[metric]+1;
    tp_rec_sum[metric]=tp_rec_sum[metric]+latency;
    if(latency<tp_rec_min[metric])tp_rec_min[metric]=latency;
    if(latency>tp_rec_max[metric])tp_rec_max[metric]=latency;
  end
endtask
always @(posedge clk_i)begin
  if(rst_i)begin
    tp_rec_cycle=0;tp_rec_publications=0;tp_rec_local_matches=0;tp_rec_local_deliveries=0;
    tp_rec_completed=0;tp_rec_old_target_ignored=0;tp_rec_phase=0;tp_rec_fill_seen=0;
    tp_rec_target=0;tp_rec_publication_edge=0;tp_rec_local_edge=0;tp_rec_first_edge=0;
    for(tp_rec_phase_index=1;tp_rec_phase_index<4;tp_rec_phase_index=tp_rec_phase_index+1)
      tp_rec_superseded[tp_rec_phase_index]=0;
    for(tp_rec_metric=0;tp_rec_metric<3;tp_rec_metric=tp_rec_metric+1)begin
      tp_rec_samples[tp_rec_metric]=0;tp_rec_sum[tp_rec_metric]=0;
      tp_rec_min[tp_rec_metric]=64'hffffffffffffffff;tp_rec_max[tp_rec_metric]=0;
      for(tp_rec_bin=0;tp_rec_bin<TP_REC_BINS;tp_rec_bin=tp_rec_bin+1)begin
        tp_rec_hist[tp_rec_metric][tp_rec_bin]=0;
        tp_rec_fill_hist[tp_rec_metric][tp_rec_bin]=0;
      end
    end
  end else begin
    tp_rec_cycle=tp_rec_cycle+1;
    if(run_i)begin
      if(`R64_SYSTEM_HIER.core.frontend.redirect_i)
        tp_rec_local_deliveries=tp_rec_local_deliveries+1;
      if(`R64_SYSTEM_HIER.core.redirect)begin
        if(tp_rec_phase!=0)tp_rec_superseded[tp_rec_phase]=tp_rec_superseded[tp_rec_phase]+1;
        tp_rec_publications=tp_rec_publications+1;
        tp_rec_target=`R64_SYSTEM_HIER.core.redirect_target;
        tp_rec_publication_edge=tp_rec_cycle;
        tp_rec_local_edge=0;tp_rec_first_edge=0;
        tp_rec_fill_seen={2'b0,tp_rec_fill_w};
        tp_rec_phase=1;
      end else if(tp_rec_phase!=0)begin
        // FILL is an observed overlap in each metric's own inclusive interval.
        // It does not assert that a refill caused any of this latency.
        if(tp_rec_fill_w)begin
          if(tp_rec_phase==1 || tp_rec_phase==2)tp_rec_fill_seen[0]=1;
          if(tp_rec_phase==2)tp_rec_fill_seen[1]=1;
          if(tp_rec_phase==3)tp_rec_fill_seen[2]=1;
        end
        case(tp_rec_phase)
          1:begin
            if(tp_rec_target_birth_w)tp_rec_old_target_ignored=tp_rec_old_target_ignored+1;
            if(`R64_SYSTEM_HIER.core.frontend.redirect_i &&
               `R64_SYSTEM_HIER.core.frontend.redirect_pc_i==tp_rec_target)begin
              tp_rec_local_matches=tp_rec_local_matches+1;
              tp_rec_local_edge=tp_rec_cycle;
              tp_rec_fill_seen[1]=tp_rec_fill_w;
              tp_rec_phase=2;
            end
          end
          2:if(tp_rec_target_birth_w)begin
            tp_rec_record(0,tp_rec_cycle-tp_rec_publication_edge,tp_rec_fill_seen[0]);
            tp_rec_record(1,tp_rec_cycle-tp_rec_local_edge,tp_rec_fill_seen[1]);
            tp_rec_first_edge=tp_rec_cycle;
            tp_rec_fill_seen[2]=tp_rec_fill_w;
            tp_rec_phase=3;
          end
          3:if(|`R64_SYSTEM_HIER.core.backend.birth_w)begin
            tp_rec_record(2,tp_rec_cycle-tp_rec_first_edge,tp_rec_fill_seen[2]);
            tp_rec_completed=tp_rec_completed+1;
            tp_rec_phase=0;
          end
          default:begin end
        endcase
      end
    end
  end
end
final begin
  tp_rec_started[0]=tp_rec_publications;
  tp_rec_started[1]=tp_rec_local_matches;
  tp_rec_started[2]=tp_rec_samples[0];
  tp_rec_unfinished[0]=64'(tp_rec_phase==1 || tp_rec_phase==2);
  tp_rec_unfinished[1]=64'(tp_rec_phase==2);
  tp_rec_unfinished[2]=64'(tp_rec_phase==3);
  tp_rec_metric_superseded[0]=tp_rec_superseded[1]+tp_rec_superseded[2];
  tp_rec_metric_superseded[1]=tp_rec_superseded[2];
  tp_rec_metric_superseded[2]=tp_rec_superseded[3];
  $display("RECOVERY_LATENCY_PROFILE metric_names=publication_to_target_birth,local_delivery_to_target_birth,target_birth_to_next_nonempty_birth overflow_bin=256");
  $display("RECOVERY_LATENCY_PROFILE publications=%0d local_deliveries=%0d local_matched=%0d completed=%0d superseded=%0d unfinished=%0d unfinished_phase=%0d old_target_birth_ignored=%0d",
    tp_rec_publications,tp_rec_local_deliveries,tp_rec_local_matches,tp_rec_completed,
    tp_rec_superseded[1]+tp_rec_superseded[2]+tp_rec_superseded[3],
    int'(tp_rec_phase!=0),tp_rec_phase,tp_rec_old_target_ignored);
  if(tp_rec_publications!=tp_rec_completed+tp_rec_superseded[1]+tp_rec_superseded[2]+
      tp_rec_superseded[3]+64'(tp_rec_phase!=0))
    $fatal(1,"recovery observer sample conservation failed");
  for(tp_rec_metric=0;tp_rec_metric<3;tp_rec_metric=tp_rec_metric+1)begin
    tp_rec_hist_sum=0;tp_rec_fill_sum=0;
    for(tp_rec_bin=0;tp_rec_bin<TP_REC_BINS;tp_rec_bin=tp_rec_bin+1)begin
      tp_rec_hist_sum=tp_rec_hist_sum+tp_rec_hist[tp_rec_metric][tp_rec_bin];
      tp_rec_fill_sum=tp_rec_fill_sum+tp_rec_fill_hist[tp_rec_metric][tp_rec_bin];
      if(tp_rec_fill_hist[tp_rec_metric][tp_rec_bin]>tp_rec_hist[tp_rec_metric][tp_rec_bin])
        $fatal(1,"recovery observer FILL subset failed");
      if(tp_rec_hist[tp_rec_metric][tp_rec_bin]!=0)
        $display("RECOVERY_LATENCY_PROFILE metric=%0d latency_bin=%0d samples=%0d fill_seen=%0d",
          tp_rec_metric,tp_rec_bin,tp_rec_hist[tp_rec_metric][tp_rec_bin],
          tp_rec_fill_hist[tp_rec_metric][tp_rec_bin]);
    end
    $display("RECOVERY_LATENCY_PROFILE metric=%0d started=%0d samples=%0d superseded=%0d unfinished=%0d min=%0d max=%0d sum=%0d fill_seen=%0d",
      tp_rec_metric,tp_rec_started[tp_rec_metric],tp_rec_samples[tp_rec_metric],
      tp_rec_metric_superseded[tp_rec_metric],tp_rec_unfinished[tp_rec_metric],
      tp_rec_samples[tp_rec_metric]==0 ? 64'd0 : tp_rec_min[tp_rec_metric],
      tp_rec_max[tp_rec_metric],tp_rec_sum[tp_rec_metric],tp_rec_fill_sum);
    if(tp_rec_hist_sum!=tp_rec_samples[tp_rec_metric] ||
       tp_rec_started[tp_rec_metric]!=tp_rec_samples[tp_rec_metric]+
       tp_rec_metric_superseded[tp_rec_metric]+tp_rec_unfinished[tp_rec_metric])
      $fatal(1,"recovery observer metric conservation failed");
  end
end
