module ps2_keyboard(clk,resetn,ps2_clk,ps2_data,bu,counter);
    input clk,resetn,ps2_clk,ps2_data;
    output [7:0] bu;
    output [7:0] counter;


    reg [9:0] buffer;        // ps2_data bits // 缓存接收到的数据（包含起始位、8位数据、校验位）
    reg [3:0] count;  // count ps2_data bits  // 计数器，记录当前接收到第几位
    reg [2:0] ps2_clk_sync; // 用于同步 ps2_clk 信号，消除亚稳态并检测边沿

    // 将异步的 ps2_clk 信号打两拍同步到系统时钟 clk 域
    always @(posedge clk) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

    // 检测 ps2_clk 的下降沿
    // sampling 为 1 表示检测到了下降沿。PS/2 协议规定设备在时钟下降沿输出数据，主机在下降沿采样
    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];


    reg [7:0] ps2_data_out_reg;
    reg is_break;
    reg [7:0] data_counter;
    assign counter = data_counter;

    always @(posedge clk) begin
        if (resetn == 0) begin // reset // 复位有效
            count <= 0;
            ps2_data_out_reg <= 0;
            is_break <= 0;
            data_counter <= 0;
        end
        else begin
            if (sampling) begin // 当检测到采样时刻（下降沿）
              if (count == 4'd10) begin // 此时正在接收第11位（停止位），前10位已存入 buffer
                if ((buffer[0] == 0) &&  // start bit // 检查起始位（buffer[0]）是否为0
                    (ps2_data)       &&  // stop bit  // 检查停止位（当前 ps2_data）是否为1
                    (^buffer[9:1])) begin      // odd  parity // 奇校验检查
                     //$display("receive %x", buffer[8:1]); // 打印接收到的8位数据（扫描码）
                    if (buffer[8:1] == 8'hF0) begin
                        is_break <= 1'b1;
                         data_counter <= data_counter + 1'b1;
                    end else begin
                        if (!is_break) begin
                            ps2_data_out_reg <= buffer[8:1];
                            //data_counter <= data_counter + 1'b1;
                        end else begin
                            ps2_data_out_reg <= 8'h00;  //f0代表没有数字传过来，因此不传输
                            is_break <= 1'b0;
                        end
                    end
                  end
                count <= 0;     // for next // 计数器清零，准备接收下一帧
              end else begin
                buffer[count] <= ps2_data;  // store ps2_data // 将当前位存入 buffer
                count <= count + 3'b1;      // 计数器加1
              end
            end
        end
    end




    assign bu = ps2_data_out_reg;

endmodule
