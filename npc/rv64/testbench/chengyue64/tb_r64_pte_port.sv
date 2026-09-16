module tb_r64_pte_port;
 reg clk=0;always #5 clk=~clk;reg rst=1;
 reg qv=0,cas=0,rr=0,sready=0,sv=0,se=0,sc=0;
 reg [55:0] addr=56'h80001000;reg [63:0] expected=0,mask=0,sdata=0;
 reg [15:0] active=0;reg [895:0] lower=0,upper=0;reg [63:0] permission=0;
 wire qr,rv,re,rc,v,sr,cached,idle;wire [63:0] data,sa,sd,sx;wire [1:0] op;
 R64PtePort dut(.clk_i(clk),.rst_i(rst),.req_valid_i(qv),.req_ready_o(qr),
 .req_compare_or_i(cas),.req_addr_i(addr),.req_expected_i(expected),.req_or_mask_i(mask),
 .rsp_valid_o(rv),.rsp_ready_i(rr),.rsp_data_o(data),.rsp_error_o(re),.rsp_compare_o(rc),
 .pmp_active_i(active),.pmp_lower_i(lower),.pmp_upper_i(upper),.pmp_permission_i(permission),
 .service_valid_o(v),.service_ready_i(sready),.service_addr_o(sa),.service_data_o(sd),
 .service_expected_o(sx),.service_op_o(op),.service_cache_o(cached),.service_rsp_valid_i(sv),
 .service_rsp_ready_o(sr),.service_rsp_data_i(sdata),.service_rsp_error_i(se),
 .service_rsp_compare_i(sc),.idle_o(idle));
 task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
 task request(input bit compare,input [55:0] address);
 begin qv=1;cas=compare;addr=address;expected=64'h2000000f;mask=64'hc0;
 if(!qr)$fatal(1,"PTE request lacked credit");tick();qv=0;end endtask
 task denied;begin
 if(!rv||!re||v||!idle===1'bx)$fatal(1,"denied PTE did not terminate locally");
 repeat(3)begin tick();if(!rv||!re||v)$fatal(1,"fault response changed under hold");end
 rr=1;tick();rr=0;if(!idle)$fatal(1,"fault owner did not release");
 end endtask
 integer count=0;
 initial begin
 repeat(3)tick();rst=0;#1;
 request(0,56'h80001000);denied();count=count+1;
 active=1;lower[55:0]=56'h80000000;upper[55:0]=56'h8fffffff;permission[3:0]=4'b0011;
 request(1,56'h80001000);
 // Later configuration and producer pins cannot rewrite an accepted command.
 permission=0;addr=0;expected=0;mask=0;
 repeat(4)begin
 if(!v||sa!=64'h80001000||sd!=64'hc0||sx!=64'h2000000f||op!=2||!cached)$fatal(1,"held PTE ownership changed");
 tick();end
 sready=1;tick();sready=0;if(v||qr)$fatal(1,"PTE owner not retained through response");
 sdata=64'h2000000f;sc=1;sv=1;#1;
 repeat(3)begin if(!rv||re||!rc||data!=sdata||sr)$fatal(1,"PTE completion corrupt");tick();end
 rr=1;tick();rr=0;sv=0;count=count+1;
 permission[3:0]=1;request(1,56'h80001000);denied();count=count+1;
 request(0,56'h80001001);denied();count=count+1;
 lower[55:0]=0;upper[55:0]=56'hffffffffffffff;permission[3:0]=3;
 request(0,56'h02000000);denied();count=count+1;
 request(0,56'h80001000);sready=1;tick();sready=0;se=1;sv=1;rr=1;#1;
 if(!rv||!re||!sr)$fatal(1,"PTE memory error lost");
 tick();sv=0;rr=0;count=count+1;
 $display("PTE physical requests checked=%0d",count);$display("[PASS] tb_r64_pte_port");$finish;
 end
 initial begin #10000;$fatal(1,"PTE port timeout");end
endmodule
