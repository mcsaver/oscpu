`timescale 1ns/1ps
module tb_r64_service_cache_hot;
 parameter CACHE_SET_W=6;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;
 reg [1:0] cv=0;wire [1:0] cr,crv,cre;reg [1:0] crr=3;
 reg [9:0] ct=0;wire [9:0] crt;
 reg [127:0] ca=0,cd=0;wire [127:0] crd;reg [3:0] co=0;reg [1:0] cc=3;
 reg [5:0] cz={3'd3,3'd3};reg [15:0] cs=16'hffff;reg [9:0] cm=0;
 reg [3:0] av=0;wire [3:0] ar,arv,are,arc;reg [3:0] arr=15;
 reg [255:0] aa=0,ad=0,ae=0;wire [255:0] ard;
 reg [7:0] ao=0;reg [3:0] ac=15;reg [11:0] az={4{3'd3}};reg [31:0] ast=32'hffffffff;
 wire [1:0] kv,kr,krv,krr,ke,kcmp,kcached;
 wire [15:0] kt,krt;wire [127:0] ka,kd,kex,krd;wire [3:0] ko;wire [5:0] kz;wire [15:0] ks;wire [9:0] km;
 wire serviceidle,cacheidle,mutation;wire [60:0] mutationword;
 R64MemoryService service(
  .clk_i(clk),.rst_i(rst),.cpu_fast_store_i(2'b0),.cache_fast_store_o(),
  .cpu_valid_i(cv),.cpu_ready_o(cr),.cpu_token_i(ct),
  .cpu_addr_i(ca),.cpu_data_i(cd),.cpu_op_i(co),.cpu_cache_i(cc),.cpu_size_i(cz),
  .cpu_strb_i(cs),.cpu_amo_i(cm),.cpu_rsp_valid_o(crv),.cpu_rsp_ready_i(crr),
  .cpu_rsp_token_o(crt),.cpu_rsp_data_o(crd),.cpu_rsp_error_o(cre),
  .aux_valid_i(av),.aux_ready_o(ar),.aux_addr_i(aa),.aux_data_i(ad),.aux_expected_i(ae),
  .aux_op_i(ao),.aux_cache_i(ac),.aux_size_i(az),.aux_strb_i(ast),
  .aux_rsp_valid_o(arv),.aux_rsp_ready_i(arr),.aux_rsp_data_o(ard),.aux_rsp_error_o(are),.aux_rsp_compare_o(arc),
  .cache_valid_o(kv),.cache_ready_i(kr),.cache_token_o(kt),.cache_addr_o(ka),.cache_data_o(kd),
  .cache_expected_o(kex),.cache_op_o(ko),.cache_cache_o(kcached),.cache_size_o(kz),.cache_strb_o(ks),.cache_amo_o(km),
  .cache_rsp_valid_i(krv),.cache_rsp_ready_o(krr),.cache_rsp_token_i(krt),.cache_rsp_data_i(krd),
  .cache_rsp_error_i(ke),.cache_rsp_compare_i(kcmp),.idle_o(serviceidle));
 wire rv,br,wv,wdv,bready;wire [63:0] ra,wa,wd;wire [7:0] rl,ws;wire [2:0] rz,wz;
 reg reading=0;integer ri=0,left=0;wire bv=reading;wire [63:0] bd;
 reg aw=0,ww=0,bvalid=0;integer wi=0;reg [63:0] wdata;reg [7:0] wstrb;
 wire rr=!reading,wr=!aw&&!bvalid,wdr=!ww&&!bvalid;
 reg error_write=0;reg [1:0] bresp=0;
 reg [63:0] memory[0:255];
 assign bd=memory[ri];
 R64Dcache #(.SET_W(CACHE_SET_W),.TOKEN_W(8)) cache(
  .clk_i(clk),.rst_i(rst),.invalidate_i(1'b0),.reservation_clear_i(1'b0),
  .req_fast_store_i(2'b0),.store_rsp_valid_o(),.store_rsp_ready_i(1'b1),.store_rsp_token_o(),.store_rsp_error_o(),
  .req_valid_i(kv),.req_ready_o(kr),.req_token_i(kt),.req_addr_i(ka),.req_data_i(kd),
  .req_expected_i(kex),.req_op_i(ko),.req_cache_i(kcached),.req_size_i(kz),.req_strb_i(ks),.req_amo_i(km),
  .rsp_valid_o(krv),.rsp_ready_i(krr),.rsp_token_o(krt),.rsp_data_o(krd),.rsp_error_o(ke),.rsp_compare_o(kcmp),
  .read_valid_o(rv),.read_ready_i(rr),.read_addr_o(ra),.read_len_o(rl),.read_size_o(rz),
  .beat_valid_i(bv),.beat_ready_o(br),.beat_data_i(bd),.beat_resp_i(2'b0),.beat_last_i(left==1),
  .write_valid_o(wv),.write_ready_i(wr),.write_addr_o(wa),.write_size_o(wz),
  .write_data_valid_o(wdv),.write_data_ready_i(wdr),.write_data_o(wd),.write_strb_o(ws),
  .write_rsp_valid_i(bvalid),.write_rsp_ready_o(bready),.write_resp_i(bresp),
  .idle_o(cacheidle),.mutation_o(mutation),.mutation_word_o(mutationword));
 integer accept_cycle[0:31];integer min_hot=999,max_hot=0,hot_pair=0,hot_i;reg hot_active=0;
 integer cycles=0,writes=0,reads=0,cpu_returns=0,aux_returns=0,n,j;
 reg [31:0] clive=0;reg [63:0] cexpected[0:31];reg [31:0] cerror=0;
 reg [3:0] alive=0,aerror=0,acompare=0;reg [63:0] aexpected[0:3];
 reg [3:0] ahold=0;reg [255:0] helddata;reg [3:0] helderror,heldcompare;
 reg [1:0] ctaken;reg [3:0] ataken;
 always @(posedge clk)if(!rst)begin
  cycles=cycles+1;
  if(bv&&br)begin ri<=ri+1;left<=left-1;if(left==1)reading<=0;end
  if(rv&&rr)begin reading<=1;ri<=ra>>3;left<=rl+1;reads=reads+1;end
  if(wv&&wr)begin aw=1;wi=wa>>3;end
  if(wdv&&wdr)begin ww=1;wdata=wd;wstrb=ws;end
  if(aw&&ww&&!bvalid)begin
   bvalid<=1;bresp<=error_write?2:0;writes=writes+1;
   if(!error_write)for(j=0;j<8;j=j+1)if(wstrb[j])memory[wi][8*j+:8]=wdata[8*j+:8];
  end
  if(bvalid&&bready)begin aw=0;ww=0;bvalid<=0;end
  for(n=0;n<2;n=n+1)begin
   if(cv[n]&&cr[n])begin if(clive[ct[n*5+:5]])$fatal(1,"CPU token reuse");clive[ct[n*5+:5]]=1;accept_cycle[ct[n*5+:5]]=cycles;end
   if(crv[n]&&crr[n])begin
    if(!clive[crt[n*5+:5]]||cre[n]!==cerror[crt[n*5+:5]]||
      (!cre[n]&&crd[n*64+:64]!==cexpected[crt[n*5+:5]]))$fatal(1,"CPU coherent response mismatch");
    if(hot_active)begin
     if(cycles-accept_cycle[crt[n*5+:5]]<min_hot)min_hot=cycles-accept_cycle[crt[n*5+:5]];
     if(cycles-accept_cycle[crt[n*5+:5]]>max_hot)max_hot=cycles-accept_cycle[crt[n*5+:5]];
    end
    clive[crt[n*5+:5]]=0;cpu_returns=cpu_returns+1;
   end
  end
  for(n=0;n<4;n=n+1)begin
   if(ahold[n]&&(!arv[n]||ard[n*64+:64]!==helddata[n*64+:64]||are[n]!==helderror[n]||arc[n]!==heldcompare[n]))
    $fatal(1,"aux response changed while stalled");
   if(av[n]&&ar[n])begin if(alive[n])$fatal(1,"aux owner reused");alive[n]=1;end
   if(arv[n]&&arr[n])begin
    if(!alive[n]||are[n]!==aerror[n]||arc[n]!==acompare[n]||
      (!are[n]&&ard[n*64+:64]!==aexpected[n]))$fatal(1,"aux%0d coherent response mismatch value%h expected%h",n,ard[n*64+:64],aexpected[n]);
    alive[n]=0;aux_returns=aux_returns+1;
   end
   ahold[n]=arv[n]&&!arr[n];
  end
  helddata=ard;helderror=are;heldcompare=arc;
 end
 task cpu;
  input [63:0] address,value,answer;input [1:0] op;input [4:0] amo;
  begin
   @(negedge clk);cv=1;ca={64'b0,address};cd={64'b0,value};co={2'b0,op};cm={5'b0,amo};ct=0;
   cexpected[0]=answer;cerror[0]=0;
   do @(posedge clk);while(!cr[0]);
   @(negedge clk);cv=0;while(clive!=0)@(negedge clk);
  end
 endtask
 task aux;
  input integer client;input [63:0] address,value,compare,answer;input [1:0] op;input error,match;
  begin
   @(negedge clk);av=1<<client;aa[client*64+:64]=address;ad[client*64+:64]=value;ae[client*64+:64]=compare;
   ao[client*2+:2]=op;aexpected[client]=answer;aerror[client]=error;acompare[client]=match;
   do @(posedge clk);while(!ar[client]);
   @(negedge clk);av=0;while(alive!=0)@(negedge clk);
  end
 endtask
 initial begin
  for(n=0;n<256;n=n+1)memory[n]=64'h1000+n;
  repeat(4)@(negedge clk);rst=0;
  cpu(0,0,64'h1000,0,0);
  // CPU store, then a walker compare-and-OR; the CPU hit must see the result.
  cpu(0,64'h2345,0,1,0);
  aux(0,0,64'h80,64'h2345,64'h2345,2,0,1);
  cpu(0,0,64'h23c5,0,0);
  // Failed compare performs no external write.
  aux(1,0,64'h100,64'h2345,64'h23c5,2,0,0);
  if(writes!=2)$fatal(1,"failed compare wrote memory");
  // Tensor writes invalidate a CPU LR reservation at the same physical owner.
  cpu(0,0,64'h23c5,3,2);
  aux(3,0,64'hbeef,0,0,1,0,0);
  cpu(0,64'hdead,1,3,3);
  cpu(0,0,64'hbeef,0,0);
  // An A/D write bus error is returned to that walker and preserves resident data.
  error_write=1;aux(2,0,64'h10000,64'hbeef,0,2,1,0);error_write=0;
  cpu(0,0,64'hbeef,0,0);
  // Every walker can hold a response independently while others progress.
  @(negedge clk);av=15;arr=0;
  for(n=0;n<4;n=n+1)begin aa[n*64+:64]=0;ao[n*2+:2]=0;aexpected[n]=64'hbeef;aerror[n]=0;acompare[n]=0;end
  while(av!=0)begin @(posedge clk);ataken=av&ar;@(negedge clk);av=av&~ataken;end
  wait(arv==15);repeat(5)@(negedge clk);arr=15;
  while(alive!=0)@(negedge clk);
  repeat(3)@(negedge clk);
  if(!serviceidle||!cacheidle||clive!=0||writes!=4)$fatal(1,"shared owner leak/accounting");
  // Real resident opposite-bank loads; complete owner/response checker above remains active.
  @(negedge clk);hot_active=1;cv=3;co=0;cc=3;ca={64'd8,64'd0};ct={5'd1,5'd0};
  cd=0;cs=16'hffff;cm=0;
  for(hot_i=0;hot_i<240;hot_i=hot_i+1)begin
   cexpected[ct[4:0]]=64'hbeef;cexpected[ct[9:5]]=64'h1001;cerror=0;
   @(posedge clk);ctaken=cv&cr;
   if(hot_i>=30&&hot_i<230)begin
    if(ctaken!=3||(crv&crr)!=3)$fatal(1,"resident opposite-bank steady dual throughput lost");
    hot_pair=hot_pair+1;
   end
   @(negedge clk);
   if(ctaken[0])ct[4:0]=ct[4:0]+5'd2;
   if(ctaken[1])ct[9:5]=ct[9:5]+5'd2;
  end
  cv=0;
  while(clive!=0)@(negedge clk);
  repeat(2)@(negedge clk);
  if(!serviceidle||!cacheidle||hot_pair!=200||min_hot!=3||max_hot!=3)
   $fatal(1,"resident latency/drain mismatch min=%0d max=%0d",min_hot,max_hot);
  $display("[PASS] tb_r64_service_cache_hot hot_pairs=%0d resident_min=%0d resident_max=%0d CPU=%0d reads=%0d writes=%0d",
   hot_pair,min_hot,max_hot,cpu_returns,reads,writes);
  $finish;
 end
 initial begin #500000;$fatal(1,"timeout");end
endmodule
