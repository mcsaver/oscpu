// Firmware-controlled raw DMA. One ordered read beat then masked write beat.
// No tensor formats or arithmetic: bytes are shifted only to align bus lanes.
// A request and its payload remain stable until ready; responses are drained
// before DONE. The caller validates disjoint, registered source/dst ranges.
module TensorNpuServiceDma(
    input wire clk, input wire rst,
    input wire start_i, input wire [63:0] src_i, dst_i, bytes_i,
    output wire busy_o, output reg done_o, output reg error_o,
    output wire req_valid_o, input wire req_ready_i,
    output wire req_write_o, output wire [63:0] req_addr_o,
    output wire [63:0] req_wdata_o, output wire [7:0] req_wstrb_o,
    input wire rsp_valid_i, output wire rsp_ready_o,
    input wire [63:0] rsp_rdata_i, input wire rsp_error_i
);
    localparam IDLE=0, READ_REQ=1, READ_RSP=2, WRITE_REQ=3, WRITE_RSP=4;
    reg [2:0] state_q;
    reg [63:0] src_q, dst_q, remaining_q, data_q;
    reg [3:0] chunk_q;
    wire [3:0] src_room=4'd8-{1'b0,src_q[2:0]};
    wire [3:0] dst_room=4'd8-{1'b0,dst_q[2:0]};
    wire [3:0] lane_room=src_room<dst_room ? src_room : dst_room;
    wire [3:0] chunk=remaining_q < {60'b0,lane_room} ? remaining_q[3:0] : lane_room;
    wire [7:0] lane_mask=8'hff >> (4'd8-chunk_q);
    assign busy_o=state_q!=IDLE;
    assign req_valid_o=state_q==READ_REQ || state_q==WRITE_REQ;
    assign req_write_o=state_q==WRITE_REQ;
    assign req_addr_o=state_q==WRITE_REQ ? {dst_q[63:3],3'b0} : {src_q[63:3],3'b0};
    assign req_wdata_o=state_q==WRITE_REQ ? data_q : 64'b0;
    assign req_wstrb_o=state_q==WRITE_REQ ? lane_mask << dst_q[2:0] : 8'b0;
    assign rsp_ready_o=state_q==READ_RSP || state_q==WRITE_RSP;
    always @(posedge clk) begin
        if(rst) begin
            state_q<=IDLE;done_o<=0;error_o<=0;src_q<=0;dst_q<=0;remaining_q<=0;data_q<=0;chunk_q<=0;
        end else case(state_q)
            IDLE: if(start_i) begin
                done_o<=0;error_o<=0;src_q<=src_i;dst_q<=dst_i;remaining_q<=bytes_i;
                if(bytes_i==0) done_o<=1;
                else if(src_i+bytes_i<src_i || dst_i+bytes_i<dst_i ||
                        (src_i<dst_i+bytes_i && dst_i<src_i+bytes_i)) begin
                    error_o<=1;done_o<=1;
                end else state_q<=READ_REQ;
            end
            READ_REQ: if(req_ready_i) begin chunk_q<=chunk;state_q<=READ_RSP;end
            READ_RSP: if(rsp_valid_i) begin
                if(rsp_error_i) begin error_o<=1;done_o<=1;state_q<=IDLE;end
                else begin
                    data_q<=(rsp_rdata_i >> {src_q[2:0],3'b0}) << {dst_q[2:0],3'b0};
                    state_q<=WRITE_REQ;
                end
            end
            WRITE_REQ: if(req_ready_i) state_q<=WRITE_RSP;
            WRITE_RSP: if(rsp_valid_i) begin
                if(rsp_error_i) begin error_o<=1;done_o<=1;state_q<=IDLE;end
                else if(remaining_q=={60'b0,chunk_q}) begin done_o<=1;state_q<=IDLE;end
                else begin
                    remaining_q<=remaining_q-{60'b0,chunk_q};
                    src_q<=src_q+{60'b0,chunk_q};dst_q<=dst_q+{60'b0,chunk_q};
                    state_q<=READ_REQ;
                end
            end
            default: begin state_q<=IDLE;done_o<=1;error_o<=1;end
        endcase
    end
endmodule
