# 规范：整数乘除单元 OooMulDivUnit

> 模块：`vsrc/execute/OooMulDivUnit.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：**已实现并验证**（含 iter2 radix-4、iter5 CLZ 早终止）。

## 1. 目的与范围
执行 RV64 M 扩展：MUL/MULH/MULHU/MULHSU/MULW（单周期乘法）与
DIV/DIVU/REM/REMU 及 W 变体（多周期 restoring 除法）。带 ready/valid 握手与 flush。
不负责操作数前递/调度（由发射/旁路网络处理）。

## 2. 接口契约（要点）
| 信号 | 方向 | 含义 |
| --- | --- | --- |
| `req_valid_i/req_ready_o` | in/out | 请求握手；`req_ready_o = (state==IDLE)` |
| `req_inst_i` | in | 用 funct3/funct7 区分 mul/div、signed、rem、high |
| `req_word_i` | in | W 变体(32 位) |
| `req_src1_i/req_src2_i` | in | 操作数 |
| `resp_valid_o/resp_ready_i` | out/in | 结果握手 |
| `resp_data_o/resp_rob_idx_o/resp_pdest_o` | out | 结果与去向 |
| `flush_i` | in | 冲刷，回 IDLE |

时序：MUL 在 IDLE 当拍算完→RESP（1 拍可见）。DIV 多拍：IDLE→DIV_RUN×K→RESP。

## 3. 乘法（单周期）
`mul_result()` 组合函数按 inst 选 MULW/MULH 系列，signed/unsigned 扩展后取高/低 64 位。
无迭代，IDLE 当拍写 `resp_data_q`→RESP。

## 4. 除法（多周期 restoring，radix-4 + CLZ 早终止）

### 4.1 预处理
- 取绝对值 `op1_abs/op2_abs`（signed 时按符号），记录商/余符号 `quot_neg/rem_neg`。
- 特例直接出结果→RESP：除零(`op2==0`)、有符号溢出(`INT_MIN/-1`)、**被除数为 0**(0/d=0,0%d=0)。

### 4.2 CLZ 定位（iter5）—— 跳过前导零
设 `clz = 前导零数(op1_abs)`，`clz_even = clz 向下取偶`（保 radix-4 的 2-bit 组对齐）：
```
       63                              0
op1_abs |0..0| significant bits |        (clz 个前导零)
左移 clz_even 后：
       63                              0
dividend | MSB.................. |0..0|   (有效位顶到 bit63)
迭代数 count = 64 - clz_even   (偶数)
```
小操作数(如 n%10, n 仅 ~7 位)→ count 很小，迭代大幅减少。

### 4.3 radix-4 迭代（iter2）—— 每拍 2 商位
```
每拍:
  partial = {rem[63:0], dividend[63:62]}          // 带入高 2 位，宽 XLEN+2
  比较 partial 与 {1,2,3}×divisor，选商位 q∈{0,1,2,3}
  rem'  = partial - q×divisor                     // 恒 < divisor
  quot' = {quot[61:0], q}                          // 左移 2 拼商位
  dividend' = {dividend[61:0], 2'b0}               // 左移 2
  count -= 2 ; 当 count==2 时本拍即末拍→RESP
```
word(≤32 有效位): ≤16 拍；dword: ≤32 拍；小操作数更少。

### 4.4 后处理
按 `rem_result` 选商或余，按符号取反，`word` 时 `sign_extend_word(result[31:0])`。

## 5. 状态机
```
 IDLE --req&!div--> RESP                         (乘法/除法特例)
 IDLE --req&div---> DIV_RUN --(count==2)--> RESP
 RESP --resp_ready--> IDLE
 任意 --flush--> IDLE
```

## 6. 不变量
- **MD-I1**：迭代后 `0 ≤ rem < divisor`，`quotient×divisor + rem == |dividend|`。
- **MD-I2**：CLZ 定位等价于 full-width 除法（多出的前导 0 位只产生前导商 0）。
- **MD-I3**：count 恒为偶且 ≥2（op1≠0 保证），DIV_RUN 必在 count==2 收尾，不会越界。
- **MD-I4**：flush 当拍回 IDLE，不产生悬挂响应。

## 7. 关键路径与权衡
- radix-4 的商位选择需 3 个 (XLEN+2) 比较器 + 选择；CLZ 定位含优先级编码 + 变量左移(桶形)。
  二者均在**装载拍/迭代步组合**，非跨模块长链，但相对 radix-2 增加了组合深度——
  属 **CPI↔Fmax 权衡**，待综合后在时序阶段评估是否需要切流水或降基数。
- 收益(cycles)：iter2 word/radix-4 使 div 测试 −44~47%；iter5 CLZ 使 shuixianhua −55%/prime −59%，
  shuixianhua 累计自原始基线 −86%。

## 8. 验证
- riscv-tests `rv64um`(div/divu/divw/divuw/rem/remu/remw/remuw/mul/mulw) 全过——
  覆盖 signed/unsigned、word/dword、INT_MIN/-1 溢出、除零、边界操作数。
- AM `div`/数论类(shuixianhua/prime/wanshu/goldbach) GOOD TRAP。
- 模块 TB `tb_ooo_muldiv_unit`/`tb_divider`/`tb_multiplier`。

## 9. 变更记录
- iter2(2026-06-28)：word 32 拍 + radix-4 16 拍。
- iter5(2026-06-28)：CLZ 早终止(按有效位数定位) + op1==0 特例。
- 本规范(2026-06-28)：逆向文档化当前算法与不变量。
