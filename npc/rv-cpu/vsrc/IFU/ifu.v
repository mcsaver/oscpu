//严格axi：axi输入不能通过组合逻辑直接影响axi输出
//axi可满吞吐的时，每周期发送一个请求
//请求FIFO满载稳态不产生气泡
//pc不被覆盖且保持顺序

module ifu (
    input         clk_i,
    input         rst_i,

    // IFU → 指令存储器：请求通道
    input         inst_req_ready_i,//axi有能力向ifu接受事物请求
    output        inst_req_valid_o,//ifu有能力向axi发出事物请求
    output [31:0] inst_req_pc_o,

    // 指令存储器 → IFU：响应通道
    input         inst_rsp_valid_i,//axi有能力向ifu发出事物
    input  [31:0] inst_rsp_inst_i,
    input         inst_rsp_error_i,
    output        inst_rsp_ready_o,//ifu有能力向axi接受事物

    // IFU → ID：流水线交接
    input         if_id_ready_i,//idu有能力向ifu接受事物
    output reg if_id_valid_o,//ifu有能力向idu发出事物
    output [31:0] if_id_pc_o,
    output [31:0] if_id_inst_o,
    output        if_id_error_o,

    output [2:0] status//观察信号
);

// valid：发送方当前提供一个有效事务，并在反压时保持 payload。
// ready：接收方当前有容量在本时钟沿接收事务。
// valid && ready：本时钟沿完成一次模块边界上的事务交接。

    //reg [1:0] state;
    //wire [2:0] status;//req_fire/rsp_fire/id_fire一共三种事物，因此共8种情况

    //debug-only:实时观察本周期握手，不参与控制
    assign status = {req_fire, rsp_fire, id_fire};//理想流水线满载情况应该是status = 3'b111

    //reg [1:0] next_state;

    wire req_fire;
    wire rsp_fire;
    wire id_fire;

    reg req_stage_valid_q;//还有一条已经准备好，可能随时被axi接受的请求
    reg [31:0] req_stage_pc_q;//发出的要取的下一条指令的pc

    assign inst_req_valid_o = req_stage_valid_q;
    assign inst_req_pc_o = req_stage_pc_q;

    assign req_fire = inst_req_valid_o && inst_req_ready_i;//request握手信号
    assign rsp_fire = inst_rsp_valid_i && inst_rsp_ready_o;//response握手信号
    assign id_fire = if_id_valid_o && if_id_ready_i;//ifid握手信号

    //assign inst_req_pc_o = next_pc_q;//发出的要取的下一条指令的pc

    //-----------------------请求通道
    reg [31:0] next_pc_q;//下一条要请求的PC
    reg [31:0] req_pc_fifo [0:15];//记录已发出但尚未返回的PC
    reg [4:0] outstanding_q;//记录未返回请求数量
    reg [31:0] req_head_pc_q;//队头pc寄存器
    //reg [31:0] if_id_inst_fifo [0:15];//保存已经返回但ID尚未接受的指令

    reg [3:0] req_wr_ptr_q;//req,write,pointer,q
    reg [3:0] req_rd_ptr_q;//req,read,pointer,q

    wire [3:0] req_next_rd_ptr_w = req_rd_ptr_q + 4'd1;
    wire req_pc_fifo_full;
    wire req_pc_fifo_empty;

    wire [5:0] req_reserved_w;//已预留请求数量
    wire req_stage_can_load_w;//判断请求槽能否装入新PC
    wire req_credit_available_w;//如果当前有剩余credit，或者本周期归还一个credit，可以装载

    assign req_reserved_w = {1'b0, outstanding_q} + (req_stage_valid_q ? 6'd1 : 6'd0);
    assign req_stage_can_load_w = !req_stage_valid_q || req_fire;
    assign req_credit_available_w =
            (req_reserved_w < 6'd16) ||
            rsp_fire;

    assign req_pc_fifo_full = (outstanding_q == 5'd16);
    assign req_pc_fifo_empty = (outstanding_q == 5'd0);

    //assign inst_req_valid_o = !req_pc_fifo_full || rsp_fire;
    //assign inst_req_pc_o = next_pc_q;

    //------------------更新请求槽和next PC
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_stage_valid_q <= 1'b0;
            req_stage_pc_q <= 32'd0;
            next_pc_q <= `RESET_PC;
        end
        else if (req_stage_can_load_w) begin
            if (req_credit_available_w) begin
                req_stage_valid_q <= 1'b1;
                req_stage_pc_q <= next_pc_q;
                next_pc_q <= next_pc_q + 32'd4;
            end
            else begin
                req_stage_valid_q <= 1'b0;
            end
        end
    end

    //-----------请求pc fifo写入来源
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_wr_ptr_q <= 4'd0;
        end
        else if (req_fire) begin
            req_pc_fifo[req_wr_ptr_q] <= req_stage_pc_q;
            req_wr_ptr_q <= req_wr_ptr_q + 1'b1;
        end
    end

    //------------------记录未返回请求数量，被压在fifo中的pc数量的更新逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            outstanding_q <= 5'd0;
        end
        else begin
            case ({req_fire, rsp_fire})
                2'b10: outstanding_q <= outstanding_q + 1'b1;
                2'b01: outstanding_q <= outstanding_q - 1'b1;

                default: outstanding_q <= outstanding_q;
            endcase
        end
    end

    //------------------维护队头pc，保证同一拍读写且取得旧pc
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_rd_ptr_q <= 4'd0;
            req_head_pc_q <= 32'd0;
        end
        else begin
            if (rsp_fire) begin
                req_rd_ptr_q <= req_rd_ptr_q + 1'b1;
                //有一未返回的请求
                if (outstanding_q > 5'd1) begin
                    req_head_pc_q <= req_pc_fifo[req_next_rd_ptr_w];
                end
                //当请求握手成功，头指针指向请求槽
                else if (req_fire) begin
                    req_head_pc_q <= req_stage_pc_q;
                end
            end
            //fifo为空的情况
            else if (req_fire && req_pc_fifo_empty) begin
                req_head_pc_q <= req_stage_pc_q;
            end
        end
    end

    //------------------响应（取到值）->ID响应FIFO

    reg [31:0] rsp_pc_fifo [0:15];
    reg [31:0] rsp_inst_fifo [0:15];
    reg rsp_error_fifo [0:15];

    reg [3:0] rsp_wr_ptr_q;//下一个给AXI响应应该写入哪个fifo槽位
    reg [3:0] rsp_rd_ptr_q;//下一条给ID的指令位于哪个槽位
    reg [4:0] rsp_count_q; //需要表示0~16

    wire rsp_fifo_empty = (rsp_count_q == 5'd0);
    wire rsp_fifo_full = (rsp_count_q == 5'd16);

    //FIFO头部直接连接ID
    //assign if_id_valid_o = !rsp_fifo_empty;
    assign if_id_pc_o = rsp_pc_fifo[rsp_rd_ptr_q];
    assign if_id_inst_o = rsp_inst_fifo[rsp_rd_ptr_q];
    assign if_id_error_o = rsp_error_fifo[rsp_rd_ptr_q];

    //wire id_fire = if_id_valid_o && if_id_ready_i;
    //AXI响应到达的时候写入FIFO
    //FIFO未满的时候可以接受响应
    //即使FIFO当前满了，只要ID本周期取走一项，也可以同时写入新响应
    assign inst_rsp_ready_o =
        !req_pc_fifo_empty &&
        (!rsp_fifo_full || id_fire);//fifo中的pc没满了，返回的inst没满，idfire代表一定可以放一个走，因此下一个周期更新可以给出请求


    //更新逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_wr_ptr_q <= 4'd0;
            rsp_rd_ptr_q <= 4'd0;
            rsp_count_q <= 5'd0;
            if_id_valid_o <= 1'b0;
        end
        else begin
            //AXI返回一条指令，压入响应FIFO
            if (rsp_fire) begin
                rsp_pc_fifo[rsp_wr_ptr_q] <= req_head_pc_q;
                rsp_inst_fifo[rsp_wr_ptr_q] <= inst_rsp_inst_i;
                rsp_error_fifo[rsp_wr_ptr_q] <= inst_rsp_error_i;
                rsp_wr_ptr_q <= rsp_wr_ptr_q + 1'b1;
            end
            //id完成握手后，当前指令已经被ID接受，下一个周期改为输出FIFO的下一条
            if (id_fire) begin
                rsp_rd_ptr_q <= rsp_rd_ptr_q + 1'b1;
            end

            case ({rsp_fire, id_fire})
                2'b10: begin
                    //FIFO从空变成非空，或者继续增加
                    rsp_count_q <= rsp_count_q + 5'd1;
                    if_id_valid_o <= 5'b1;
                end
                2'b01: begin
                    rsp_count_q <= rsp_count_q - 5'd1;

                    //原来只有一项时，本拍消费后变空
                    if_id_valid_o <= (rsp_count_q > 5'd1);
                end
                2'b11: begin
                    //同拍弹出旧头，压入新尾，占用数不变
                    rsp_count_q <= rsp_count_q;
                    if_id_valid_o <= 1'b1;
                end
                default: begin
                    rsp_count_q <= rsp_count_q;
                    if_id_valid_o <= if_id_valid_o;
                end
            endcase
        end
    end
    

endmodule
