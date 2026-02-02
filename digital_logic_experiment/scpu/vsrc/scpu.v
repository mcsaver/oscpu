module scpu(
    input  clk,
    input  reset,
    input  en,
    output [31:0]data
);

//定义16个32位寄存器，访问时用r[0]、r[1]就可以
reg [31 : 0] r [15 : 0];//reg
wire [31 : 0] rom [10 : 0];//rom
assign rom[0] = 32'h00100093;
assign rom[1] = 32'h00208093;
assign rom[2] = 32'h00308093;
assign rom[3] = 32'h00408093;
assign rom[4] = 32'h00508093;
assign rom[5] = 32'h00608093;
assign rom[6] = 32'h00708093;
assign rom[7] = 32'h00808093;
assign rom[8] = 32'h00908093;
assign rom[9] = 32'h00a08093;
assign rom[10] = 32'b0;//out x1

reg [31:0] inst_reg;
parameter addi = 2'b11, out = 2'b10;
wire [1:0] type_in;
//reg [5:0] pc = 0;
integer  pc;
//reg o_x1;
reg [31:0] data_reg;
always @(posedge clk) begin
    if (reset) begin
        pc <= 0;
        inst_reg <= 32'h0;
        //o_x1 <= 0;
    end else begin
        if (pc > 10) begin
            pc <= 0;
            //o_x1 <= 0;
        end
        else if (en) pc <= pc + 1;
        inst_reg <= rom[pc];

        if (type_in == addi)
            r[rd[3:0]] <= r[rs1[3:0]] + imm32;
        if (type_in == out)
            //o_x1 <= 1;
            data_reg <= r[1];
    end
end

assign data = data_reg;

wire [31 : 0] inst;
//wire [31:20] imm;
wire [31:0] imm32;
wire [4:0] rs1;
wire [2:0] funct3;
wire [4:0] rd;
wire [6: 0] op;
assign inst = inst_reg;
//assign imm = inst[31:20];
assign imm32 = {{20{inst[31]}}, inst[31:20]}; // 12位立即数符号扩展到32位
assign rs1 = inst[19:15];
assign funct3 = inst[14:12];
assign rd = inst[11:7];
assign op = inst[6:0];

assign type_in = ((op == 7'b10011) && (funct3 == 3'b0)) ? addi :
                 ((op == 7'b0000000) && (funct3 == 3'b0)) ? out :
                 2'b00;


endmodule
