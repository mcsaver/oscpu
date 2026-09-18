// Simulation-only occupancy/event counters. Predicates overlap; do not sum them as a stall breakdown.
// No connection drives production RTL, and the existing NEMU/retirement oracle is unchanged.
reg [63:0] profile_cycles_q;
always @(posedge clk_i)begin
 if(rst_i)profile_cycles_q<=0;
 else if(run_i && (1'b1))profile_cycles_q<=profile_cycles_q+64'd1;
end
final $display("CPI_PROFILE cycles=%0d",profile_cycles_q);
reg [63:0] profile_retire_zero_q;
always @(posedge clk_i)begin
 if(rst_i)profile_retire_zero_q<=0;
 else if(run_i && (event_trace_valid_o==0))profile_retire_zero_q<=profile_retire_zero_q+64'd1;
end
final $display("CPI_PROFILE retire_zero=%0d",profile_retire_zero_q);
reg [63:0] profile_retire_one_q;
always @(posedge clk_i)begin
 if(rst_i)profile_retire_one_q<=0;
 else if(run_i && (event_trace_valid_o==1 || event_trace_valid_o==2))profile_retire_one_q<=profile_retire_one_q+64'd1;
end
final $display("CPI_PROFILE retire_one=%0d",profile_retire_one_q);
reg [63:0] profile_retire_two_q;
always @(posedge clk_i)begin
 if(rst_i)profile_retire_two_q<=0;
 else if(run_i && (event_trace_valid_o==3))profile_retire_two_q<=profile_retire_two_q+64'd1;
end
final $display("CPI_PROFILE retire_two=%0d",profile_retire_two_q);
reg [63:0] profile_frontend_empty_q;
always @(posedge clk_i)begin
 if(rst_i)profile_frontend_empty_q<=0;
 else if(run_i && (!`R64_SYSTEM_HIER.core.fetch_valid[0]))profile_frontend_empty_q<=profile_frontend_empty_q+64'd1;
end
final $display("CPI_PROFILE frontend_empty=%0d",profile_frontend_empty_q);
reg [63:0] profile_frontend_full_q;
always @(posedge clk_i)begin
 if(rst_i)profile_frontend_full_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.frontend.count_q==4))profile_frontend_full_q<=profile_frontend_full_q+64'd1;
end
final $display("CPI_PROFILE frontend_full=%0d",profile_frontend_full_q);
reg [63:0] profile_decode_empty_q;
always @(posedge clk_i)begin
 if(rst_i)profile_decode_empty_q<=0;
 else if(run_i && (!`R64_SYSTEM_HIER.core.backend.decode_query_valid_w[0]))profile_decode_empty_q<=profile_decode_empty_q+64'd1;
end
final $display("CPI_PROFILE decode_empty=%0d",profile_decode_empty_q);
reg [63:0] profile_birth_zero_q;
always @(posedge clk_i)begin
 if(rst_i)profile_birth_zero_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.birth_w==0))profile_birth_zero_q<=profile_birth_zero_q+64'd1;
end
final $display("CPI_PROFILE birth_zero=%0d",profile_birth_zero_q);
reg [63:0] profile_birth_two_q;
always @(posedge clk_i)begin
 if(rst_i)profile_birth_two_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.birth_w==3))profile_birth_two_q<=profile_birth_two_q+64'd1;
end
final $display("CPI_PROFILE birth_two=%0d",profile_birth_two_q);
reg [63:0] profile_decode_rob_block_q;
always @(posedge clk_i)begin
 if(rst_i)profile_decode_rob_block_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.decode_query_valid_w[0] && !`R64_SYSTEM_HIER.core.backend.rob_credit_w[0]))profile_decode_rob_block_q<=profile_decode_rob_block_q+64'd1;
end
final $display("CPI_PROFILE decode_rob_block=%0d",profile_decode_rob_block_q);
reg [63:0] profile_decode_iq_block_q;
always @(posedge clk_i)begin
 if(rst_i)profile_decode_iq_block_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.decode_query_valid_w[0] && !`R64_SYSTEM_HIER.core.backend.issue_credit_w[0]))profile_decode_iq_block_q<=profile_decode_iq_block_q+64'd1;
end
final $display("CPI_PROFILE decode_iq_block=%0d",profile_decode_iq_block_q);
reg [63:0] profile_decode_prf_block_q;
always @(posedge clk_i)begin
 if(rst_i)profile_decode_prf_block_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.decode_query_valid_w[0] && !`R64_SYSTEM_HIER.core.backend.rename_credit_w[0]))profile_decode_prf_block_q<=profile_decode_prf_block_q+64'd1;
end
final $display("CPI_PROFILE decode_prf_block=%0d",profile_decode_prf_block_q);
reg [63:0] profile_decode_lsq_block_q;
always @(posedge clk_i)begin
 if(rst_i)profile_decode_lsq_block_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.lsu_reserve_want[0] && !`R64_SYSTEM_HIER.core.lsu_reserve_ready[0]))profile_decode_lsq_block_q<=profile_decode_lsq_block_q+64'd1;
end
final $display("CPI_PROFILE decode_lsq_block=%0d",profile_decode_lsq_block_q);
reg [63:0] profile_recover_q;
always @(posedge clk_i)begin
 if(rst_i)profile_recover_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.recover))profile_recover_q<=profile_recover_q+64'd1;
end
final $display("CPI_PROFILE recover=%0d",profile_recover_q);
reg [63:0] profile_branch_redirect_q;
always @(posedge clk_i)begin
 if(rst_i)profile_branch_redirect_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend_redirect))profile_branch_redirect_q<=profile_branch_redirect_q+64'd1;
end
final $display("CPI_PROFILE branch_redirect=%0d",profile_branch_redirect_q);
reg [63:0] profile_prediction_redirect_q;
always @(posedge clk_i)begin
 if(rst_i)profile_prediction_redirect_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.frontend.pending_redirect_w))profile_prediction_redirect_q<=profile_prediction_redirect_q+64'd1;
end
final $display("CPI_PROFILE prediction_redirect=%0d",profile_prediction_redirect_q);
reg [63:0] profile_icache_fill_q;
always @(posedge clk_i)begin
 if(rst_i)profile_icache_fill_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.frontend.u_cache.state_q==2))profile_icache_fill_q<=profile_icache_fill_q+64'd1;
end
final $display("CPI_PROFILE icache_fill=%0d",profile_icache_fill_q);
reg [63:0] profile_store_b_owner_q;
always @(posedge clk_i)begin
 if(rst_i)profile_store_b_owner_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.memory.unit.cache.store_active_q))profile_store_b_owner_q<=profile_store_b_owner_q+64'd1;
end
final $display("CPI_PROFILE store_b_owner=%0d",profile_store_b_owner_q);
reg [63:0] profile_rob_nonempty_notdone_q;
always @(posedge clk_i)begin
 if(rst_i)profile_rob_nonempty_notdone_q<=0;
 else if(run_i && (rob_count_o!=0 && !`R64_SYSTEM_HIER.core.rob_valid[0]))profile_rob_nonempty_notdone_q<=profile_rob_nonempty_notdone_q+64'd1;
end
final $display("CPI_PROFILE rob_nonempty_notdone=%0d",profile_rob_nonempty_notdone_q);
reg [63:0] profile_head_serial_q;
always @(posedge clk_i)begin
 if(rst_i)profile_head_serial_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.head_serial))profile_head_serial_q<=profile_head_serial_q+64'd1;
end
final $display("CPI_PROFILE head_serial=%0d",profile_head_serial_q);
reg [63:0] profile_issue_zero_q;
always @(posedge clk_i)begin
 if(rst_i)profile_issue_zero_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.issue_fire_w==0))profile_issue_zero_q<=profile_issue_zero_q+64'd1;
end
final $display("CPI_PROFILE issue_zero=%0d",profile_issue_zero_q);
reg [63:0] profile_issue_two_q;
always @(posedge clk_i)begin
 if(rst_i)profile_issue_two_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.backend.issue_fire_w==3))profile_issue_two_q<=profile_issue_two_q+64'd1;
end
final $display("CPI_PROFILE issue_two=%0d",profile_issue_two_q);
reg [63:0] profile_write_command_q;
always @(posedge clk_i)begin
 if(rst_i)profile_write_command_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.write_valid && `R64_SYSTEM_HIER.core.write_ready))profile_write_command_q<=profile_write_command_q+64'd1;
end
final $display("CPI_PROFILE write_command=%0d",profile_write_command_q);
reg [63:0] profile_write_wait_q;
always @(posedge clk_i)begin
 if(rst_i)profile_write_wait_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.write_valid && !`R64_SYSTEM_HIER.core.write_ready))profile_write_wait_q<=profile_write_wait_q+64'd1;
end
final $display("CPI_PROFILE write_wait=%0d",profile_write_wait_q);
reg [63:0] profile_load_bus_command_q;
always @(posedge clk_i)begin
 if(rst_i)profile_load_bus_command_q<=0;
 else if(run_i && (`R64_SYSTEM_HIER.core.read_valid[1] && `R64_SYSTEM_HIER.core.read_ready[1]))profile_load_bus_command_q<=profile_load_bus_command_q+64'd1;
end
final $display("CPI_PROFILE load_bus_command=%0d",profile_load_bus_command_q);
reg [63:0] profile_wb_backpressure_q;
always @(posedge clk_i)begin
 if(rst_i)profile_wb_backpressure_q<=0;
 else if(run_i && (|(`R64_SYSTEM_HIER.core.backend.local_valid_w & ~`R64_SYSTEM_HIER.core.backend.local_ready_w) || |(`R64_SYSTEM_HIER.core.external_valid & ~`R64_SYSTEM_HIER.core.external_ready)))profile_wb_backpressure_q<=profile_wb_backpressure_q+64'd1;
end
final $display("CPI_PROFILE wb_backpressure=%0d",profile_wb_backpressure_q);
