`timescale 1ns/1ps
module tb_service_dma;
reg clk=0,rst=1,start=0;
reg [63:0] src=0,dst=0,bytes=0;
wire busy,done,error,rv,rw,rr;
wire [63:0] addr,data;
wire [7:0] mask;
reg rspvalid=0,rsperror=0;
reg [63:0] rspdata=0;
integer cycles=0, delay_count=0, requests=0, fault_request=-1;
reg pending=0, held=0;
reg [136:0] held_payload;
reg [7:0] memory[0:511];
reg [7:0] original[0:511];
wire ready=!pending && !rspvalid && cycles%3!=0;
always #5 clk=~clk;
TensorNpuServiceDma dut(clk,rst,start,src,dst,bytes,busy,done,error,
    rv,ready,rw,addr,data,mask,rspvalid,rr,rspdata,rsperror);
integer b;
always @(posedge clk) begin
    cycles<=cycles+1;
    if(rst) begin pending<=0;rspvalid<=0;held<=0;end
    else begin
        if(held && (!rv || {rw,addr,data,mask}!==held_payload))
            $fatal(1,"request payload changed under backpressure");
        held<=rv&&!ready;held_payload<={rw,addr,data,mask};
        if(rspvalid&&rr) begin rspvalid<=0;rsperror<=0;end
        if(pending) begin
            if(delay_count==0) begin rspvalid<=1;pending<=0;end
            else delay_count<=delay_count-1;
        end
        if(rv&&ready) begin
            if(addr[2:0]!=0 || addr>504) $fatal(1,"unaligned/out-of-range DMA request");
            pending<=1;delay_count<=cycles%4;requests<=requests+1;
            rsperror<=requests==fault_request;
            if(rw) begin
                if(mask==0) $fatal(1,"empty DMA write");
                if(requests!=fault_request)
                    for(b=0;b<8;b=b+1) if(mask[b]) memory[addr+b]<=data[8*b+:8];
                rspdata<=0;
            end else for(b=0;b<8;b=b+1) rspdata[8*b+:8]<=memory[addr+b];
        end
    end
end
task automatic run_copy(input integer so, input integer de, input integer n,
                         input integer expect_error, input integer fault);
integer i,limit;
begin
    @(negedge clk);
    for(i=0;i<512;i=i+1) begin memory[i]=(i*37+11)&255;original[i]=memory[i];end
    requests=0;fault_request=fault;
    src=so;dst=de;bytes=n;start=1;
    @(negedge clk);start=0;
    limit=0;
    while(!done) begin
        @(negedge clk);limit=limit+1;
        if(limit>4000) $fatal(1,"DMA timeout");
    end
    if(error!=expect_error || busy || pending || rspvalid) $fatal(1,"completion contract");
    if(!expect_error)
        for(i=0;i<512;i=i+1)
            if(memory[i] !== ((i>=de && i<de+n)?original[so+i-de]:original[i]))
                $fatal(1,"copy mismatch src=%0d dst=%0d n=%0d byte=%0d",so,de,n,i);
    @(negedge clk);
end
endtask
integer x,y,ncase;
initial begin
    repeat(3) @(negedge clk);rst=0;
    for(x=0;x<8;x=x+1) for(y=0;y<8;y=y+1) begin
        run_copy(16+x,256+y,1,0,-1);
        run_copy(16+x,256+y,4,0,-1);
        run_copy(16+x,256+y,9,0,-1);
        run_copy(16+x,256+y,37,0,-1);
    end
    run_copy(16,256,0,0,-1);
    run_copy(16,20,16,1,-1);
    run_copy(16,256,16,1,0);
    run_copy(16,256,16,1,1);
    $display("[NPU-SERVICE-DMA][PASS] alignments=64 lengths=4 backpressure=1 read_fault=1 write_fault=1 overlap_reject=1");
    $finish;
end
endmodule
