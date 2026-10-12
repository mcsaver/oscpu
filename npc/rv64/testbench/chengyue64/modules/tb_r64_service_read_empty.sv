`timescale 1ns / 1ps
module tb_r64_service_read_empty #(parameter EMPTY_FLOW=1);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1;
  reg pv = 0;
  reg [13:0] pid = 0, cid = 0;
  reg [4:0] pt = 0;
  reg [63:0] pa = 0, pd = 0;
  reg [3:0] cop = 1;
  reg [1:0] cfast = 1;
  reg [1:0] cc=3, kre=0, krc=0;
  reg [5:0] ao=0;
  reg [191:0] ad=0, ax=0;
  reg [2:0] ac=7;
  wire [1:0] kfast;
  reg [1:0] cv = 0, crr = 3, kr = 3, krv = 0;
  reg [9:0] ct = 0;
  reg [127:0] ca = 0, cd = 0, krd = 0;
  reg [2:0] av = 0, arr = 7;
  reg [191:0] aa = 0;
  reg [ 13:0] krt = 0;
  wire [1:0] cr, crv, cre, kv, krr, kcache;
  wire [9:0] crt;
  wire [127:0] crd, ka, kd, kx;
  wire [2:0] ar, arv, are, arc;
  wire [191:0] ard;
  wire [13:0] kt;
  wire [3:0] ko;
  wire [5:0] kz;
  wire [15:0] ks;
  wire [9:0] km;
  wire idle;
  reg store_valid = 0, store_ready = 0, store_error = 0;
  reg [6:0] store_token = 0;
  wire store_return_valid, store_return_ready, store_return_error;
  wire [4:0] store_return_token;
  R64MemoryService #(
    .CPU_PREPARE_HINTS(1), .CPU_READ_EMPTY_FLOW(EMPTY_FLOW), .PREPARE_ID_W(14),
    .AUX  (3),
    .SRC_W(2)
  ) dut (
    .cpu_prepare_valid_i(pv), .cpu_prepare_id_i(pid), .cpu_identity_i(cid),
    .cpu_prepare_token_i(pt), .cpu_prepare_addr_i(pa), .cpu_prepare_data_i(pd),
    .cpu_prepare_size_i(3'd3), .cpu_prepare_strb_i(8'hff), .cpu_prepare_amo_i(5'd0),
    .cpu_fast_store_i(cfast), .cache_fast_store_o(kfast), .cpu_request_i(cv),
    .clk_i(clk),
    .rst_i(rst),
    .cpu_store_rsp_valid_o(store_return_valid),
    .cpu_store_rsp_ready_i(store_ready),
    .cpu_store_rsp_token_o(store_return_token),
    .cpu_store_rsp_error_o(store_return_error),
    .cache_store_rsp_valid_i(store_valid),
    .cache_store_rsp_ready_o(store_return_ready),
    .cache_store_rsp_token_i(store_token),
    .cache_store_rsp_error_i(store_error),
    .cpu_valid_i(cv),
    .cpu_ready_o(cr),
    .cpu_token_i(ct),
    .cpu_addr_i(ca),
    .cpu_data_i(cd),
    .cpu_op_i(cop),
    .cpu_cache_i(cc),
    .cpu_size_i(6'h1b),
    .cpu_strb_i(16'h00ff),
    .cpu_amo_i(10'b0),
    .cpu_rsp_valid_o(crv),
    .cpu_rsp_ready_i(crr),
    .cpu_rsp_token_o(crt),
    .cpu_rsp_data_o(crd),
    .cpu_rsp_error_o(cre),
    .aux_valid_i(av),
    .aux_ready_o(ar),
    .aux_addr_i(aa),
    .aux_data_i(ad),
    .aux_expected_i(ax),
    .aux_op_i(ao),
    .aux_cache_i(ac),
    .aux_size_i(9'hdb),
    .aux_strb_i(24'b0),
    .aux_rsp_valid_o(arv),
    .aux_rsp_ready_i(arr),
    .aux_rsp_data_o(ard),
    .aux_rsp_error_o(are),
    .aux_rsp_compare_o(arc),
    .cache_valid_o(kv),
    .cache_ready_i(kr),
    .cache_token_o(kt),
    .cache_addr_o(ka),
    .cache_data_o(kd),
    .cache_expected_o(kx),
    .cache_op_o(ko),
    .cache_cache_o(kcache),
    .cache_size_o(kz),
    .cache_strb_o(ks),
    .cache_amo_o(km),
    .cache_rsp_valid_i(krv),
    .cache_rsp_ready_o(krr),
    .cache_rsp_token_i(krt),
    .cache_rsp_data_i(krd),
    .cache_rsp_error_i(kre),
    .cache_rsp_compare_i(krc),
    .idle_o(idle)
  );
  localparam PW=219;
  wire [PW-1:0] cp[0:1],kp[0:1],ap[0:2];
  for(genvar p=0;p<2;p=p+1)begin
    assign cp[p]={2'b0,ct[p*5+:5],ca[p*64+:64],cd[p*64+:64],64'b0,
        cop[p*2+:2],cc[p],3'd3,(p==0?8'hff:8'h00),5'b0,cfast[p]};
    assign kp[p]={kt[p*7+:7],ka[p*64+:64],kd[p*64+:64],kx[p*64+:64],
        ko[p*2+:2],kcache[p],kz[p*3+:3],ks[p*8+:8],km[p*5+:5],kfast[p]};
  end
  for(genvar p=0;p<3;p=p+1)begin
    assign ap[p]={2'(p+1),5'b0,aa[p*64+:64],ad[p*64+:64],ax[p*64+:64],
        ao[p*2+:2],ac[p],3'd3,8'b0,5'b0,1'b0};
  end
  reg outstanding[0:127];
  reg [PW-1:0] expected[0:127],held_payload[0:1];
  integer born[0:127],accepted_edge[0:127],cache_edge[0:127];
  reg [1:0] held=0;
  integer cycle=0,accepted=0,cache_accepted=0,checks=0,fast_reads=0,prepared=0;
  integer held_checks=0,pair_cpu0=0,pair_cpu1=0,old_head=0,cold=0;
  integer qdepth, token;
  task check(input yes,input [639:0] why);
    begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s",why);end
  endtask
  always @(posedge clk) begin
    cycle=cycle+1;
    if(rst)begin
      held=0;
      for(integer n=0;n<128;n=n+1) outstanding[n]=0;
    end else begin
      for(integer l=0;l<2;l=l+1)if(cv[l]&&cr[l])begin
        token={2'b0,ct[l*5+:5]};
        check(!outstanding[token],"CPU token duplicated before cache acceptance");
        outstanding[token]=1;expected[token]=cp[l];born[token]=cycle;accepted_edge[token]=cycle;
        accepted=accepted+1;
      end
      for(integer a=0;a<3;a=a+1)if(av[a]&&ar[a])begin
        token=(a+1)*32;
        check(!outstanding[token],"aux token duplicated before cache acceptance");
        outstanding[token]=1;expected[token]=ap[a];born[token]=cycle;accepted_edge[token]=cycle;
        accepted=accepted+1;
      end
      for(integer l=0;l<2;l=l+1)begin
        if(held[l])begin
          check(kv[l]&&kp[l]===held_payload[l],"blocked cache offer changed owner/payload");
          held_checks=held_checks+1;
        end
        held[l]=kv[l]&&!kr[l];held_payload[l]=kp[l];
        if(kv[l]&&kr[l])begin
          token=kt[l*7+:7];
          check(outstanding[token],"cache accepted unowned/duplicate source token");
          check(kp[l]===expected[token],"cache payload differs from accepted CPU/aux payload");
          outstanding[token]=0;cache_edge[token]=cycle;cache_accepted=cache_accepted+1;
          if(token<32 && ko[l*2+:2]==0 && kcache[l] && cycle==born[token])
            fast_reads=fast_reads+1;
        end
      end
      if(dut.prepare_fire_w)prepared=prepared+1;
      #1;
      qdepth=int'(dut.valid_q[0][0])+int'(dut.valid_q[0][1])+
             int'(dut.valid_q[1][0])+int'(dut.valid_q[1][1]);
      check(accepted-cache_accepted==qdepth,"accepted-cache count differs from owned queue slots");
    end
  end
  task tick;begin @(posedge clk);#2;@(negedge clk);end endtask
  task clear;
    begin
      check(accepted==cache_accepted,"test reset would discard an accepted packet");
      rst=1;cv=0;av=0;pv=0;krv=0;kr=3;cop=0;cfast=0;cc=3;ao=0;ac=7;
      crr=3;arr=7;store_valid=0;store_ready=0;
      tick();rst=0;
    end
  endtask
  task cpu(input integer lane,id,input [63:0] address,input [1:0] op,input cacheable);
    begin
      ct[lane*5+:5]=5'(id);ca[lane*64+:64]=address;cd[lane*64+:64]=64'(id*123);
      cop[lane*2+:2]=op;cc[lane]=cacheable;cv[lane]=1;
    end
  endtask
  task drain;
    integer limit;
    begin
      cv=0;av=0;pv=0;kr=3;limit=0;
      while(accepted!=cache_accepted && limit<20)begin tick();limit=limit+1;end
      check(accepted==cache_accepted,"request queue failed to drain");
      tick();
    end
  endtask
  task paired(input integer cpu_lane);
    begin
      clear();tick(); // idle CPU turn advances to eligible aux0
      av=1;aa[63:0]=64'h80002000;
      cpu(0,10, cpu_lane==1?64'h80003000:64'h80003008,0,1);
      cpu(1,11,64'h80004008,0,1);
      #1;check(ar[0]&&cr==(cpu_lane==1?2:1),"aux/CPU original remapping changed");
      check(kv==(EMPTY_FLOW?2:0),"aux was bypassed or selected CPU was not exposed");
      if(EMPTY_FLOW)check(kt[7+:7]==7'(10+cpu_lane),"physical lane1 lost selected CPU token");
      tick();cv=0;av=0;
      if(cpu_lane==1)pair_cpu1=pair_cpu1+1;else pair_cpu0=pair_cpu0+1;
      drain();
      check(cache_edge[10+cpu_lane]-accepted_edge[10+cpu_lane]==(EMPTY_FLOW?0:1),
            "selected paired CPU cache acceptance edge");
      check(cache_edge[32]-accepted_edge[32]==1,"aux read bypassed its queue");
    end
  endtask
  initial begin
    for(integer n=0;n<128;n=n+1)begin
      outstanding[n]=0;expected[n]=0;born[n]=0;accepted_edge[n]=0;cache_edge[n]=0;
    end
    // Empty cached CPU reads on both same and different banks.
    for(integer bank=0;bank<2;bank=bank+1)begin
      clear();cpu(0,1,64'h80001000,0,1);cpu(1,2,64'h80001000+64'(bank*8),0,1);
      #1;check(cr==3,"empty dual CPU admission");
      check(kv==(EMPTY_FLOW?3:0),"empty dual CPU offer latency");
      tick();cv=0;drain();
      check(cache_edge[1]-accepted_edge[1]==(EMPTY_FLOW?0:1),"CPU0 empty-flow actual acceptance edge");
      check(cache_edge[2]-accepted_edge[2]==(EMPTY_FLOW?0:1),"CPU1 empty-flow actual acceptance edge");
      $display("SERVICE_READ_EDGE enabled=%0d bank=%0d gap0=%0d gap1=%0d",EMPTY_FLOW,bank,
          cache_edge[1]-accepted_edge[1],cache_edge[2]-accepted_edge[2]);
    end
    // A direct blocked offer must become the identical Q owner next edge.
    clear();kr=0;cpu(0,3,64'h80005000,0,1);cpu(1,4,64'h80005008,0,1);
    #1;check(cr==3,"blocked cache changed empty CPU Q-credit");
    tick();cv=0;ca=~128'b0;cd=~128'b0;ct=10'h3ff;cop=15;cc=0;
    repeat(4)begin check(kv==3,"blocked direct fallback lost queue owner");tick();end
    drain();
    // An occupied old head cannot be replaced by a current read or borrowed
    // as same-cycle credit. Fill both slots while Cache remains blocked.
    clear();kr=0;cpu(0,5,64'h80006000,0,1);tick();cv=0;
    cpu(0,6,64'h80007000,0,1);#1;
    check(kv[0]&&kt[6:0]==5,"new read replaced an old queue head");old_head=old_head+1;
    tick();cv=0;cpu(0,7,64'h80008000,0,1);kr=3;#1;
    check(!cr[0]&&kt[6:0]==5,"head pop borrowed Q-only upstream capacity");
    tick();#1;check(cr[0]&&kt[6:0]==6,"full queue drain did not retain older owner");
    tick();cv=0;drain();
    paired(0);paired(1);
    // Noncached reads, stores and atomics retain the original queue boundary.
    for(integer mode=0;mode<3;mode=mode+1)begin
      clear();cpu(0,12+mode,64'h80009000+64'(mode*8),2'(mode),mode!=0);
      #1;check(cr[0]&&!kv[0],"side-effect/NC request took ordinary read fast path");
      tick();cv=0;drain();
      check(cache_edge[12+mode]-accepted_edge[12+mode]==1,"cold operation queue edge changed");
      cold=cold+1;
    end
    // Simultaneous matched prepared store + ordinary lane1 read: the store
    // retains its independent identity proof and direct activation semantics.
    clear();pv=1;pid=14'h125;pt=15;pa=64'h8000a000;pd=1845;
    tick();cid=pid;cpu(0,15,pa,1,1);cpu(1,16,64'h8000a008,0,1);cfast=1;
    #1;check(cr==3&&dut.prepare_fire_w&&kv[0],"read flow disturbed prepared store activation");
    if(EMPTY_FLOW)check(kv==3&&kt[7+:7]==16,"prepared store suppressed independent lane1 read");
    tick();cv=0;pv=0;cfast=0;drain();
    check(cache_edge[15]==accepted_edge[15],"prepared store gained request queue");
    check(cache_edge[16]-accepted_edge[16]==(EMPTY_FLOW?0:1),"prepared-store paired read edge");
    // CPU response token/data/error remain lane-local and honor backpressure.
    clear();krt={7'd23,7'd22};krd={64'h2222,64'h1111};kre=1;krv=3;crr=1;#1;
    check(crv==3&&crt=={5'd23,5'd22}&&crd==krd&&cre==1&&krr==1,"CPU response routing changed");
    tick();crr=3;#1;check(krr==3,"CPU response pressure failed");tick();krv=0;
    // Three auxiliary sources each accept once; onebusy survives cache accept
    // and a held result until the client's actual response handshake.
    for(integer client=0;client<3;client=client+1)begin
      clear();tick();av=3'(1<<client);aa[client*64+:64]=64'h8000b000+64'(client*8);
      #1;check(ar[client]&&kv==0,"aux read bypassed queue");
      tick();av=0;drain();
      av=3'(1<<client);#1;check(!ar[client],"busy aux admitted second request");
      arr=0;krv=1;krt=14'((client+1)*32);krd=128'(64'hab00+64'(client));kre=1;krc=1;
      #1;check(krr[0],"empty aux response slot refused returned owner");
      tick();krv=0;
      check(arv==3'(1<<client)&&are[client]&&arc[client]&&ard[client*64+:64]==64'hab00+64'(client),
            "aux source/data/error/compare routing");
      repeat(3)begin tick();check(!ar[client]&&arv[client],"held aux result released busy");end
      av=0;arr=7;tick();check(arv==0,"aux response did not retire");
    end
    // Fast store terminal remains a separate source-zero transport.
    clear();store_valid=1;store_token=7'd19;store_error=1;store_ready=0;#1;
    check(store_return_valid&&!store_return_ready&&store_return_token==19&&store_return_error,
          "fast store response owner or pressure changed");
    store_ready=1;#1;check(store_return_ready,"fast store terminal did not accept");tick();store_valid=0;
    check(pair_cpu0==1&&pair_cpu1==1&&cold==3&&old_head==1&&held_checks>=8&&prepared==1,
          "required directed coverage missing");
    check(fast_reads==(EMPTY_FLOW?7:0),"empty read direct count differs from accepted-edge observations");
    $display("[PASS] tb_r64_service_read_empty enabled=%0d accepted=%0d cache=%0d fast=%0d held=%0d checks=%0d",
        EMPTY_FLOW,accepted,cache_accepted,fast_reads,held_checks,checks);
    $finish;
  end
  initial begin #30000;$fatal(1,"timeout");end
endmodule
