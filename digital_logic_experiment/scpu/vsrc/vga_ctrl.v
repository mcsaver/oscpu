// VGA 控制器模块
// 中文说明：
// - 该模块基于像素时钟 `pclk` 生成 VGA 所需的水平/垂直时序（计数器、同步信号、可见区域判断），
//   并根据当前像素坐标输出 `h_addr`/`v_addr`，供显存（`vmem`）或像素源读取像素数据。
// - 输入：`vga_data` 为当前像素的 24-bit RGB 数据（{R,G,B} 各 8 位）。
// - 输出：`hsync`/`vsync` 为水平/垂直同步信号；`valid` 表示当前为可见视频区域；
//   `vga_r`/`vga_g`/`vga_b` 为实际输出到 VGA 的颜色通道。
// - 定时参数（parameter）使用常见的 640x480@60Hz 总时序（在此代码中以像素时钟计数为单位）：
//   计数范围为 1..h_total 和 1..v_total，代码通过比较计数器与这些参数生成同步与可见判断。
module vga_ctrl (
    input pclk,
    input reset,
    input [23:0] vga_data,
    output [9:0] h_addr,
    output [9:0] v_addr,
    output hsync,
    output vsync,
    output valid,
    output [7:0] vga_r,
    output [7:0] vga_g,
    output [7:0] vga_b
);

// 时序参数（数值含义请参考下方注释）
// - h_frontporch: 水平同步脉冲宽度（计数阈值）
// - h_active: 水平同步 + 回沿（back porch）结束位置（用于计算可见区域左边界）
// - h_backporch: 可见区域右边界在计数器中的位置（h_active + 640）
// - h_total: 一行的像素总数（包括同步脉冲、回沿、可见、前沿）
parameter h_frontporch = 96;
parameter h_active = 144;
parameter h_backporch = 784;
parameter h_total = 800;

// 垂直方向参数含义类似，于竖直方向计数
parameter v_frontporch = 2;
parameter v_active = 35;
parameter v_backporch = 515;
parameter v_total = 525;

// x_cnt/y_cnt: 水平/垂直计数器，基于像素时钟递增
reg [9:0] x_cnt;
reg [9:0] y_cnt;
// h_valid/v_valid: 分别表示水平/垂直方向是否落在“可见区域”内
wire h_valid;
wire v_valid;

always @(posedge pclk) begin
    if(reset == 1'b1) begin
        x_cnt <= 1;
        y_cnt <= 1;
    end
    else begin
        if(x_cnt == h_total)begin
            x_cnt <= 1;
            if(y_cnt == v_total) y_cnt <= 1;
            else y_cnt <= y_cnt + 1;
        end
        else x_cnt <= x_cnt + 1;
    end
end

// 计数器说明：
// - x_cnt 在 1..h_total 之间循环；当 x_cnt 到达 h_total 时清零并 y_cnt +1；
// - y_cnt 在 1..v_total 之间循环，形成帧时序。
// 这些计数值用来判断当前处于同步脉冲、回沿或可见像素区域。

// 生成同步信号（注意：输出极性取决于外围电路/显示器期望，代码里为直接比较产生的逻辑电平）
assign hsync = (x_cnt > h_frontporch);
assign vsync = (y_cnt > v_frontporch);

// 生成可见（非消隐）区域判断：
// - 水平可见：x_cnt 大于 h_active 且小于等于 h_backporch，长度应为 640（例如 784-144 = 640）
// - 垂直可见：y_cnt 大于 v_active 且小于等于 v_backporch，长度应为 480（例如 515-35 = 480）
assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
assign valid = h_valid & v_valid; // 当水平和垂直均在可见区时，像素数据有效

// 计算当前可见像素在帧缓冲（显存）中的地址（从 0 开始）
// - 这里使用 145 和 36：因为当 x_cnt==145 时对应 h_addr==0（即可见区起始）；
//   同理 y_cnt==36 对应 v_addr==0。值的来源是上面的参数组合（h_active+1, v_active+1）。
assign h_addr = h_valid ? (x_cnt - 10'd145) : 10'd0;
assign v_addr = v_valid ? (y_cnt - 10'd36) : 10'd0;

// 将来自显存的 24-bit 像素数据直接映射到 VGA 的 R/G/B 输出
assign {vga_r, vga_g, vga_b} = vga_data;

endmodule
