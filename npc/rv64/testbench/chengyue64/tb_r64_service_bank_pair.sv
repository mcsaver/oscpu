// CPU/PTE bank pairing through real R64PtePort + Service + Dcache.
// All requests keep their original owner until acceptance; returned data has
// an independent address/token scoreboard. No forced DUT state or cache RAM.
`timescale 1ns/1ps
module tb_r64_service_bank_pair;
 parameter REQUEST_HINTS=0;
 reg [1:0] empty_request_hint=3;
 wire [1:0] request_hint_w=$test$plusargs("bad-request-hint")?~cv:(cv!=0?cv:empty_request_hint);
 integer empty_aux_hint_cycles=0;
 always @(posedge clk)if(!rst&&REQUEST_HINTS!=0&&cv==0&&request_hint_w!=0&&(|av))
   empty_aux_hint_cycles=empty_aux_hint_cycles+1;
 localparam [63:0] BASE=64'h80000000;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;
 reg [1:0] cv=0,crr=3,cc=3;wire [1:0] cr,crv,cre;
 reg [9:0] ct=0;reg [127:0] ca=0,cd=0;reg [3:0] co=0;
 wire [9:0] crt;wire [127:0] crd;
 reg [2:0] pv=0,pcas=0,prr=7;wire [2:0] pr,prv,pe,pc,pidle;
 reg [167:0] pa=0;reg [191:0] pexpected=0,pmask=0;
 wire [191:0] pd;
 wire [2:0] av,ar,ac,arv,arr,ae,acompare;wire [191:0] aa,ad,ax,ard;
 wire [5:0] ao;
 genvar g;
 generate for(g=0;g<3;g=g+1)begin:pte
  R64PtePort port(
   .clk_i(clk),.rst_i(rst),.req_valid_i(pv[g]),.req_ready_o(pr[g]),
   .req_compare_or_i(pcas[g]),.req_addr_i(pa[g*56+:56]),
   .req_expected_i(pexpected[g*64+:64]),.req_or_mask_i(pmask[g*64+:64]),
   .rsp_valid_o(prv[g]),.rsp_ready_i(prr[g]),.rsp_data_o(pd[g*64+:64]),
   .rsp_error_o(pe[g]),.rsp_compare_o(pc[g]),
   .pmp_active_i(16'h1),.pmp_lower_i(896'b0),.pmp_upper_i({840'b0,56'hffffff_ffffffff}),
   .pmp_permission_i(64'h7),
   .service_valid_o(av[g]),.service_ready_i(ar[g]),.service_addr_o(aa[g*64+:64]),
   .service_data_o(ad[g*64+:64]),.service_expected_o(ax[g*64+:64]),
   .service_op_o(ao[g*2+:2]),.service_cache_o(ac[g]),
   .service_rsp_valid_i(arv[g]),.service_rsp_ready_o(arr[g]),.service_rsp_data_i(ard[g*64+:64]),
   .service_rsp_error_i(ae[g]),.service_rsp_compare_i(acompare[g]),.idle_o(pidle[g]));
 end endgenerate
 wire [1:0] kv,kr,krv,krr,ke,kcmp,kcached,kfast;
 wire [13:0] kt,krt;wire [127:0] ka,kd,kex,krd;
 wire [3:0] ko;wire [5:0] kz;wire [15:0] ks;wire [9:0] km;
 wire serviceidle,cacheidle;
 R64MemoryService #(.AUX(3),.SRC_W(2),.CPU_REQUEST_HINTS(REQUEST_HINTS)) service(
  .clk_i(clk),.rst_i(rst),.cpu_fast_store_i(2'b0),.cache_fast_store_o(kfast),
  .cpu_valid_i(cv),.cpu_request_i(request_hint_w),.cpu_ready_o(cr),.cpu_token_i(ct),.cpu_addr_i(ca),.cpu_data_i(cd),
  .cpu_op_i(co),.cpu_cache_i(cc),.cpu_size_i(6'h1b),.cpu_strb_i(16'hffff),.cpu_amo_i(10'b0),
  .cpu_rsp_valid_o(crv),.cpu_rsp_ready_i(crr),.cpu_rsp_token_o(crt),.cpu_rsp_data_o(crd),.cpu_rsp_error_o(cre),
  .aux_valid_i(av),.aux_ready_o(ar),.aux_addr_i(aa),.aux_data_i(ad),.aux_expected_i(ax),
  .aux_op_i(ao),.aux_cache_i(ac),.aux_size_i(9'hdb),.aux_strb_i(24'hffffff),
  .aux_rsp_valid_o(arv),.aux_rsp_ready_i(arr),.aux_rsp_data_o(ard),.aux_rsp_error_o(ae),.aux_rsp_compare_o(acompare),
  .cache_valid_o(kv),.cache_ready_i(kr),.cache_token_o(kt),.cache_addr_o(ka),.cache_data_o(kd),
  .cache_expected_o(kex),.cache_op_o(ko),.cache_cache_o(kcached),.cache_size_o(kz),.cache_strb_o(ks),.cache_amo_o(km),
  .cache_rsp_valid_i(krv),.cache_rsp_ready_o(krr),.cache_rsp_token_i(krt),.cache_rsp_data_i(krd),
  .cache_rsp_error_i(ke),.cache_rsp_compare_i(kcmp),.idle_o(serviceidle));
 wire rv,rr,br,wv,wr,wdv,wdr,bready;
 wire [63:0] ra,wa,wd;wire [7:0] rl,ws;wire [2:0] rz,wz;
 reg reading=0,aw=0,ww=0,bvalid=0;
 integer ri=0,left=0,wi=0,bcount=0,write_delay=0,read_countdown=0,read_delay=0;
 reg [63:0] wdata;reg [7:0] wstrb;
 reg [63:0] memory[0:255];
 wire bv=reading&&read_countdown==0;
 assign rr=!reading;assign wr=!aw&&!bvalid;assign wdr=!ww&&!bvalid;
 R64Dcache #(.SET_W(6),.TOKEN_W(7)) cache(
  .clk_i(clk),.rst_i(rst),.invalidate_i(1'b0),.reservation_clear_i(1'b0),
  .req_fast_store_i(kfast),.store_rsp_valid_o(),.store_rsp_ready_i(1'b1),.store_rsp_token_o(),.store_rsp_error_o(),
  .req_valid_i(kv),.req_ready_o(kr),.req_token_i(kt),.req_addr_i(ka),.req_data_i(kd),
  .req_expected_i(kex),.req_op_i(ko),.req_cache_i(kcached),.req_size_i(kz),.req_strb_i(ks),.req_amo_i(km),
  .rsp_valid_o(krv),.rsp_ready_i(krr),.rsp_token_o(krt),.rsp_data_o(krd),.rsp_error_o(ke),.rsp_compare_o(kcmp),
  .read_valid_o(rv),.read_ready_i(rr),.read_addr_o(ra),.read_len_o(rl),.read_size_o(rz),
  .beat_valid_i(bv),.beat_ready_o(br),.beat_data_i(memory[ri]),.beat_resp_i(2'b0),.beat_last_i(left==1),
  .write_valid_o(wv),.write_ready_i(wr),.write_addr_o(wa),.write_size_o(wz),
  .write_data_valid_o(wdv),.write_data_ready_i(wdr),.write_data_o(wd),.write_strb_o(ws),
  .write_rsp_valid_i(bvalid),.write_rsp_ready_o(bready),.write_resp_i(2'b0),
  .idle_o(cacheidle),.mutation_o(),.mutation_word_o());
 integer cycles=0,reads=0,writes=0,cpu_returns=0,pte_returns=0,held_cycles=0;
 integer pair_different=0,pair_same=0,dual_cache=0,bank_conflicts=0;
 integer wait_cpu[0:31],wait_pte[0:2],sum_cpu_wait=0,sum_pte_wait=0;
 reg [31:0] clive=0;reg [63:0] canswer[0:31];
 reg [2:0] plive=0,pmatch=0;reg [63:0] panswer[0:2];
 reg roi=0;reg [1:0] held=0;reg [218:0] held_payload[0:1];
 wire [218:0] payload[0:1];
 generate for(g=0;g<2;g=g+1)begin:hold_fields
  assign payload[g]={kt[g*7+:7],ka[g*64+:64],kd[g*64+:64],kex[g*64+:64],
    ko[g*2+:2],kcached[g],kz[g*3+:3],ks[g*8+:8],km[g*5+:5],kfast[g]};
 end endgenerate
 integer n,j,t,a;
 always @(posedge clk)if(!rst)begin
  cycles=cycles+1;
  if(reading&&read_countdown>0)read_countdown<=read_countdown-1;
  if(bv&&br)begin ri<=ri+1;left<=left-1;if(left==1)reading<=0;end
  if(rv&&rr)begin reading<=1;ri<=(ra-BASE)>>3;left<=rl+1;read_countdown<=read_delay;reads=reads+1;end
  if(wv&&wr)begin aw=1;wi=(wa-BASE)>>3;bcount=write_delay;end
  if(wdv&&wdr)begin ww=1;wdata=wd;wstrb=ws;end
  if(aw&&ww&&!bvalid)begin
   if(bcount>0)bcount=bcount-1;
   else begin
    bvalid<=1;writes=writes+1;
    for(j=0;j<8;j=j+1)if(wstrb[j])memory[wi][j*8+:8]=wdata[j*8+:8];
   end
  end
  if(bvalid&&bready)begin aw=0;ww=0;bvalid<=0;end
  for(n=0;n<2;n=n+1)begin
   if(held[n])begin
    if(!kv[n]||payload[n]!==held_payload[n])$fatal(1,"held Service request changed owner");
    held_cycles=held_cycles+1;
   end
   held[n]=kv[n]&&!kr[n];held_payload[n]=payload[n];
   if(cv[n]&&cr[n])begin
    t=ct[n*5+:5];if(clive[t])$fatal(1,"live CPU token reused");clive[t]=1;wait_cpu[t]=cycles;
   end
   if(crv[n]&&crr[n])begin
    t=crt[n*5+:5];
    if(!clive[t]||cre[n]||crd[n*64+:64]!==canswer[t])
     $fatal(1,"CPU response token/data mismatch token%0d got%h want%h",t,crd[n*64+:64],canswer[t]);
    clive[t]=0;cpu_returns=cpu_returns+1;
    if(roi)sum_cpu_wait=sum_cpu_wait+cycles-wait_cpu[t];
   end
  end
  for(n=0;n<3;n=n+1)begin
   if(pv[n]&&pr[n])begin
    if(plive[n])$fatal(1,"PTE owner reused");plive[n]=1;wait_pte[n]=cycles;
   end
   if(prv[n]&&prr[n])begin
    if(!plive[n]||pe[n]||pc[n]!==pmatch[n]||pd[n*64+:64]!==panswer[n])
     $fatal(1,"PTE response mismatch client%0d data%h want%h err%b",n,pd[n*64+:64],panswer[n],pe[n]);
    plive[n]=0;pte_returns=pte_returns+1;
    if(roi)sum_pte_wait=sum_pte_wait+cycles-wait_pte[n];
   end
   if(roi&&av[n]&&ar[n])for(j=0;j<2;j=j+1)if(cv[j]&&cr[j])begin
    if(ca[j*64+3]!=aa[n*64+3])pair_different=pair_different+1;
    else pair_same=pair_same+1;
   end
  end
  if(roi&&(kv&kr)==3)dual_cache=dual_cache+1;
  if(roi&&kv==3&&ko==0&&ka[3]==ka[67]&&(kv&kr)!=3)bank_conflicts=bank_conflicts+1;
 end
 task drain;
  integer budget;
  begin
   budget=0;
   while((clive!=0||plive!=0||!serviceidle||!cacheidle||pidle!=7)&&budget<500)begin
    @(negedge clk);budget=budget+1;
   end
   if(budget==500)$fatal(1,"owner drain timeout");
   repeat(3)@(negedge clk);
  end
 endtask
 task cpu_one;
  input [63:0] addr,data,answer;input [1:0] op;
  begin
   @(negedge clk);cv=1;ct=0;ca={64'b0,addr};cd={64'b0,data};co={2'b0,op};cc=3;canswer[0]=answer;
   do @(posedge clk);while(!cr[0]);
   @(negedge clk);cv=0;drain();
  end
 endtask
 integer round_id,start_cycle,total_cycles=0,first_cpu_mask,chosen_client;
 reg [1:0] taken;
 // mode0: CPU0 collides, CPU1 opposite. mode1: already opposite.
 // mode2: CPU0 absent. mode3: CPU0 NC (do not pass).
 // mode4: CPU0 store (do not pass). mode5: PTE CAS (no pair).
 task mixed_round;
  input integer mode,client,bank;
  reg [63:0] paddr,c0addr,c1addr;
  begin
   paddr=BASE+64'(bank*8);c0addr=BASE+64'((mode==1?(1-bank):bank)*8);
   c1addr=BASE+64'((1-bank)*8);
   @(negedge clk);pv=3'b1<<client;pa[client*56+:56]=paddr[55:0];pcas=0;pmatch=0;
   panswer[client]=memory[(paddr-BASE)>>3];
   if(mode==5)begin pcas[client]=1;pexpected[client*64+:64]=panswer[client];pmask[client*64+:64]=64'h4000;pmatch[client]=1;end
   if(!pr[client])$fatal(1,"PTE ingress not free");
   @(negedge clk);pv=0;
   if(!av[client])$fatal(1,"PTE protection did not produce request");
   cv=mode==2?2'b10:2'b11;ct={5'd1,5'd0};ca={c1addr,c0addr};co=0;cc=3;cd=0;
   canswer[0]=memory[(c0addr-BASE)>>3];canswer[1]=memory[(c1addr-BASE)>>3];
   if(mode==3)cc[0]=0;
   if(mode==4)begin co[1:0]=1;cd[63:0]=64'h5678;canswer[0]=0;end
   if(mode==5)begin
    canswer[0]=canswer[0]|64'h4000;
    // CPU1 uses the opposite word, so its expected data is unchanged.
   end
   #1;
   if(!ar[client])$fatal(1,"round-robin did not select offered PTE");
   first_cpu_mask=cv&cr;
   if(!$test$plusargs("baseline"))begin
    if((mode==0||mode==2)&&first_cpu_mask!=2)$fatal(1,"missing CPU1 bank-aware pair mode%0d",mode);
    if((mode==1||mode==3)&&first_cpu_mask!=1)$fatal(1,"changed CPU0 fallback mode%0d",mode);
    if((mode==4||mode==5)&&first_cpu_mask!=0)$fatal(1,"reordered special owner mode%0d",mode);
   end
   start_cycle=cycles;
   while(cv!=0)begin @(posedge clk);taken=cv&cr;@(negedge clk);cv=cv&~taken;end
   while(clive!=0||plive!=0)@(negedge clk);
   if(roi)total_cycles=total_cycles+cycles-start_cycle;
   drain();
  end
 endtask
 initial begin
  for(n=0;n<256;n=n+1)memory[n]=64'h1020304050600000+64'(n);
  repeat(4)@(negedge clk);rst=0;
  cpu_one(BASE,0,memory[0],0);
  roi=1;
  for(round_id=0;round_id<24;round_id=round_id+1)mixed_round(0,round_id%3,round_id%2);
  roi=0;
  $display("SERVICE_BANK_PAIR rounds=24 requests=72 roi_cycles=%0d different_pairs=%0d same_pairs=%0d dual_cache=%0d bank_conflicts=%0d cpu_wait=%0d pte_wait=%0d",
   total_cycles,pair_different,pair_same,dual_cache,bank_conflicts,sum_cpu_wait,sum_pte_wait);
  if(!$test$plusargs("baseline")&&(pair_different!=24||pair_same!=0||dual_cache<24))
   $fatal(1,"bank pairing benefit not exercised");
  for(round_id=1;round_id<=5;round_id=round_id+1)mixed_round(round_id,round_id%3,round_id%2);
  // A real slow miss retains downstream request holders across long pressure.
  read_delay=30;cpu_one(BASE+64'h200,0,memory[64],0);read_delay=0;
  // A pending write retains conflicting readers while an independent bank
   // may pass. Preserve every request payload across the remaining pressure.
  @(negedge clk);write_delay=25;cv=1;ct=5'd2;co=1;ca=BASE+64'h100;cd=64'habc;canswer[2]=0;
  do @(posedge clk);while(!cr[0]);
  @(negedge clk);cv=0;
  wait(cache.state_q==5||cache.store_active_q);
  mixed_round(0,0,0);write_delay=0;
  cpu_one(BASE+64'h100,0,64'habc,0);
  if(REQUEST_HINTS!=0)begin
   // Exercise each nonzero unused CPU request mask while a real PTE owner
   // traverses Service/Dcache. CPU has no VALID and must create no owner.
   for(round_id=1;round_id<=3;round_id=round_id+1)begin
    @(negedge clk);empty_request_hint=2'(round_id);cv=0;
    pv=1;pa[0+:56]=BASE[55:0];pcas=0;pmatch=0;panswer[0]=memory[0];
    if(!pr[0])$fatal(1,"aux-only PTE ingress not free");
    @(negedge clk);pv=0;drain();
   end
  end
  if(held_cycles<10)$fatal(1,"request hold coverage missing");
  if(cpu_returns!=63||pte_returns!=(REQUEST_HINTS!=0?33:30))$fatal(1,"final request/response accounting CPU=%0d PTE=%0d",cpu_returns,pte_returns);
  if(REQUEST_HINTS!=0&&(empty_aux_hint_cycles==0||service.CPU_REQUEST_HINTS!=1))
    $fatal(1,"empty CPU hints with active auxiliary coverage missing");
  $display("SERVICE_REQUEST_HINT enabled=%0d empty_aux_cycles=%0d",REQUEST_HINTS,empty_aux_hint_cycles);
  $display("[PASS] tb_r64_service_bank_pair real-PtePort bank-pair NC store CAS miss B-hold token data held=%0d",held_cycles);
  $finish;
 end
 initial begin #500000;$fatal(1,"timeout");end
endmodule
