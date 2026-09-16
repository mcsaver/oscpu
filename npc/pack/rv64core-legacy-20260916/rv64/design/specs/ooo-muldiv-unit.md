# 规范：整数乘除单元 OooMulDivUnit

> 模块：`vsrc/execute/OooMulDivUnit.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：**已实现并验证**（含 iter-mul shift-add、iter2 radix-4、iter5 CLZ 早终止、
> 刀X mul-radix4+CLZ 早退出+swap，2026-07-09）。

## 1. 目的与范围
执行 RV64 M 扩展：MUL/MULH/MULHU/MULHSU/MULW（多周期迭代乘法）与
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

时序：MUL 进入 `MUL_RUN`，radix-4 每拍处理 2 个 multiplier bit（CLZ 早退出，
迭代数 = (64−clz_even)/2；任一操作数幅值为 0 时装载拍直进 RESP），完成后进入 RESP。
DIV 多拍：IDLE→DIV_RUN×K→RESP。**MUL/DIV 延迟均为数据依赖变量**，由 ready/valid
长延迟协议吸收，消费方不得有拍数假设。

## 3. 乘法（radix-4 无符号数字迭代 + CLZ 早退出 + swap，刀X 2026-07-09）
乘法不推断一拍 128-bit 大乘法器。迭代域是**纯无符号幅值乘法**（符号在装载拍剥离、
末拍取补恢复），**显式非 Booth**——无负数字/补码尾差/与早退出的交互陷阱。

装载拍（IDLE，MUL 臂）：
- 取绝对值后 **swap 选边**：小幅值当 multiplier、大幅值当 multiplicand
  （`op1_abs < op2_abs` 无符号比较，与 clz 比较单调等价；`mul_neg=op1_neg^op2_neg`
  与角色无关，MULHSU 的非对称符号提取在 swap 之前完成——swap 符号代价为零）。
- **两侧零特判**：`(op1_abs==0 || op2_abs==0)` 直进 RESP 出 0（全变体正确）。
  ★必须查两侧：只查固定一侧在 op1=0+swap 场景漏判 → count_init=0 绕回 ~64 拍，
  结果仍正确、全门禁假 pass（MD-I7 拍数断言是唯一解药）。
- CLZ 打在选出的 multiplier 上：`count_init = 64 − clz_even`（向下取偶保 2-bit 组对齐）。
- `mul_m3_q = 3×multiplicand` 装载拍预算寄存（镜像 div_d3_q，移出迭代环）。

```
每拍(radix-4):
  digit         = multiplier[1:0]                  // 无符号数字 0..3
  addend        = {0, M, M<<1(布线), 3M(寄存)}[digit]
  acc'          = acc + addend                     // 同一条 128 位加法器
  multiplicand' = multiplicand << 2 ; m3' = m3 << 2  // 3M<<2=3×(M<<2),×3 关系保持
  multiplier'   = multiplier >> 2
  count -= 2 ; 当 count==2 时本拍即末拍产生完整 128-bit 幅值积
```
早退出正确性：k 组迭代后 `acc = M × multiplier[2k−1:0]`；剩余位全 0 ⇒ acc 已是精确
128 位幅值积 ⇒ **高 64 位切片（MULH/MULHU/MULHSU）与低 64 位同时精确**。
末拍按 `mul_neg` 二补数恢复，按 funct3 切片，`MULW` 低 32 位符号扩展。
MULW 免费收益：word 操作数 sext 后幅值 ≤2^31 → CLZ 自动 ≤16+2 拍。

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
 IDLE --req&!div&幅值非零--> MUL_RUN --(count==2)--> RESP
 IDLE --req&!div&任一幅值 0--> RESP               (积恒 0,禁走绕回)
 IDLE --req&div---> DIV_RUN --(count==2)--> RESP
 IDLE --req&div special--> RESP                  (除零/溢出/被除数 0)
 RESP --resp_ready--> IDLE
 任意 --flush--> IDLE
```

## 6. 不变量
- **MD-I1**：迭代后 `0 ≤ rem < divisor`，`quotient×divisor + rem == |dividend|`。
- **MD-I2**：CLZ 定位等价于 full-width 除法（多出的前导 0 位只产生前导商 0）。
- **MD-I3**：count 恒为偶且 ≥2（op1≠0 保证），DIV_RUN 必在 count==2 收尾，不会越界。
- **MD-I4**：flush 当拍回 IDLE，不产生悬挂响应。
- **MD-I5**：MUL_RUN 与 DIV_RUN 一样属于在飞状态；flush 或 mispredict-kill 命中时必须清空并不得吐出旧响应。
- **MD-I6**（刀X）：MUL 早退出结果与行为乘法金标准逐位等价——OOO_ASSERT 下装载拍用
  `*` 一步算出最终期望 resp_data（含 negate+切片+sext）寄存，RESP 消费拍等值比对。
- **MD-I7**（刀X）：MUL 非零装载的 `count_init` 恒偶且 ≥2（两侧零特判保证）；
  MUL_RUN 总拍数必须恰为 `count_init/2`——早退出被放宽/绕回即 fire。

## 7. 关键路径与权衡
- 乘法从一拍大组合乘法器改为 128-bit 加法器 + shift register，显著降低 Yosys/ABC 门级综合压力；
  刀X 后延迟 = 2+ceil(有效位/2) 拍（eff=8→6、16→10、64→34），由既有 ready/valid 长延迟协议吸收。
  迭代拍组合深度较 radix-2 仅 +1 级 mux（4:1 addend 选择），加法器不变；装载拍新增
  swap 比较+CLZ+3M 预算两条链（DIV 装载拍已有同形先例）。
- 架构定位：本单元的 CPI 放大器不在延迟本身，而在**消费方结构**——IQ oldest-first
  select 不感知 muldiv busy（最老 ready 的 MUL 在 busy 期间恒占 issue0 半阻塞）+
  单 outstanding（背靠背 MUL 串行）。拍数收复缩短阴影长度但不消除阻塞结构；
  下一级演进=第二 outstanding 或 IQ busy 感知（契约变更，另立 spec），
  终极形态=2-4 拍流水阵列乘法器（触发条件=CoreMark 剖析 MUL 仍在 top 桶）。
- radix-4 的商位选择需 3 个 (XLEN+2) 比较器 + 选择；CLZ 定位含优先级编码 + 变量左移(桶形)。
  二者均在**装载拍/迭代步组合**，非跨模块长链，但相对 radix-2 增加了组合深度——
  属 **CPI↔Fmax 权衡**，待综合后在时序阶段评估是否需要切流水或降基数。
- 收益(cycles)：iter2 word/radix-4 使 div 测试 −44~47%；iter5 CLZ 使 shuixianhua −55%/prime −59%，
  shuixianhua 累计自原始基线 −86%。

## 8. 验证
- riscv-tests `rv64um`(div/divu/divw/divuw/rem/remu/remw/remuw/mul/mulw) 全过——
  覆盖 signed/unsigned、word/dword、INT_MIN/-1 溢出、除零、边界操作数。
- AM `div`/数论类(shuixianhua/prime/wanshu/goldbach) GOOD TRAP。
- 模块 TB `tb_ooo_muldiv_unit` 覆盖 4 类 64-bit multiply、MULW、div/rem、busy、flush。
- 2026-07-08 iter-mul 验证：`tb_ooo_muldiv_unit` PASS；`OooMulDivUnit` OOC full stdcell PASS，
  `synth_check` 0 problems，area `18944.80`；`NpcTop + OooFetchPacketCache blackbox` 顶层综合
  从旧版停在 `OooMulDivUnit` 推进到 `OooFpArithGate`，证明 blocker 已转移。

## 9. 变更记录
- iter2(2026-06-28)：word 32 拍 + radix-4 16 拍。
- iter5(2026-06-28)：CLZ 早终止(按有效位数定位) + op1==0 特例。
- 本规范(2026-06-28)：逆向文档化当前算法与不变量。
- iter-mul(2026-07-08)：乘法由一拍 `*` 改为 64-step shift-add，降低 stdcell 综合压力。
- 刀X(2026-07-09)：MUL radix-4 无符号数字（3M 装载拍寄存）+CLZ 早退出+swap+两侧零特判；
  MD-I6/I7 断言落 RTL；TB 扩 64×64 穷举×4 变体+随机 500×5+kill 三用例+MUL flush；
  mutation 手测 MD-I7 fire→复原。**顺手修复 muldiv_killed 函数形态在 iverilog 下
  hidden dependency 潜伏 bug**（函数体引用模块级 kill 信号不进连续赋值敏感列表，
  kill 脉冲被无视——展开为显式 wire；函数体引用模块级变量禁令家族新成员，
  大节点 Verilator 路径不受影响）。spec 依据 `../arch/knife-x-mul-latency-recovery.md`。
