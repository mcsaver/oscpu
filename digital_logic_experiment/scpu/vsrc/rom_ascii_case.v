// rom_ascii_case.v
module rom_ascii_case #(
    parameter DATA_WIDTH = 8
)(
    input  wire [7:0] keycode,   // 键码输入
    input  wire       shift,     // Shift键状态 (1:按下, 输出大写/符号; 0:松开, 输出小写/数字)
    output reg  [DATA_WIDTH-1:0] ascii // 映射输出
);
    always @* begin
        ascii = 8'h00; // 默认空
        case (keycode)
            // 数字 1-9, 0 (Shift下为符号)
            8'h16: ascii = shift ? 8'h21 : 8'h31; // 1 !
            8'h1E: ascii = shift ? 8'h40 : 8'h32; // 2 @
            8'h26: ascii = shift ? 8'h23 : 8'h33; // 3 #
            8'h25: ascii = shift ? 8'h24 : 8'h34; // 4 $
            8'h2E: ascii = shift ? 8'h25 : 8'h35; // 5 %
            8'h36: ascii = shift ? 8'h5E : 8'h36; // 6 ^
            8'h3D: ascii = shift ? 8'h26 : 8'h37; // 7 &
            8'h3E: ascii = shift ? 8'h2A : 8'h38; // 8 *
            8'h46: ascii = shift ? 8'h28 : 8'h39; // 9 (
            8'h45: ascii = shift ? 8'h29 : 8'h30; // 0 )

            // 字母 A-Z (Shift下为大写，否则为小写)
            8'h1C: ascii = shift ? 8'h41 : 8'h61; // A a
            8'h32: ascii = shift ? 8'h42 : 8'h62; // B b
            8'h21: ascii = shift ? 8'h43 : 8'h63; // C c
            8'h23: ascii = shift ? 8'h44 : 8'h64; // D d
            8'h24: ascii = shift ? 8'h45 : 8'h65; // E e
            8'h2B: ascii = shift ? 8'h46 : 8'h66; // F f
            8'h34: ascii = shift ? 8'h47 : 8'h67; // G g
            8'h33: ascii = shift ? 8'h48 : 8'h68; // H h
            8'h43: ascii = shift ? 8'h49 : 8'h69; // I i
            8'h3B: ascii = shift ? 8'h4A : 8'h6A; // J j
            8'h42: ascii = shift ? 8'h4B : 8'h6B; // K k
            8'h4B: ascii = shift ? 8'h4C : 8'h6C; // L l
            8'h3A: ascii = shift ? 8'h4D : 8'h6D; // M m
            8'h31: ascii = shift ? 8'h4E : 8'h6E; // N n
            8'h44: ascii = shift ? 8'h4F : 8'h6F; // O o
            8'h4D: ascii = shift ? 8'h50 : 8'h70; // P p
            8'h15: ascii = shift ? 8'h51 : 8'h71; // Q q
            8'h2D: ascii = shift ? 8'h52 : 8'h72; // R r
            8'h1B: ascii = shift ? 8'h53 : 8'h73; // S s
            8'h2C: ascii = shift ? 8'h54 : 8'h74; // T t
            8'h3C: ascii = shift ? 8'h55 : 8'h75; // U u
            8'h2A: ascii = shift ? 8'h56 : 8'h76; // V v
            8'h1D: ascii = shift ? 8'h57 : 8'h77; // W w
            8'h22: ascii = shift ? 8'h58 : 8'h78; // X x
            8'h35: ascii = shift ? 8'h59 : 8'h79; // Y y
            8'h1A: ascii = shift ? 8'h5A : 8'h7A; // Z z

            // 其他常见键
            8'h29: ascii = 8'h20; // Space
            8'h5A: ascii = 8'h0D; // Enter
            8'h66: ascii = 8'h08; // Backspace

            default: ascii = 8'h00; // 未匹配保持空
        endcase
    end
endmodule
