# OooClmulUnit — 进位无关乘法单元 Spec

> 目标模块:`vsrc/execute/OooClmulUnit.v`(137 行)。实现 RISC-V Zbc(进位无关乘法)
> 的 `clmul`/`clmulh`/`clmulr`。本 spec 补齐"每模块有 spec"覆盖(2026-06-28)。

## 1. 目的与范围
进位无关乘法 = 把整数乘法的"加"换成"异或"(GF(2) 多项式乘),无进位传播。用于 CRC、GCM、
纠错码等。本单元是**多周期迭代**(64 拍)实现,挂在整数后端(`OooIntBackend` 实例化),
与 ALU/MulDiv 等并列,通过 valid/ready 握手收发。

## 2. 接口
- 请求:`req_valid_i`/`req_ready_o`、`req_rob_idx_i`、`req_pdest_i`、`req_op_i[1:0]`、
  `req_src1_i`/`req_src2_i`。
- 响应:`resp_valid_o`/`resp_ready_i`、`resp_rob_idx_o`、`resp_pdest_o`、`resp_data_o`。
- `flush_i`:与 rst 同效,复位到 IDLE(乱序 flush 时丢弃在算请求,安全;rob_idx 已随请求锁存,
  flush 后该请求不再 commit)。

### op 编码(`req_op_i`)
| 值 | 名 | 语义 |
|---|---|---|
| 0 `CLMUL_OP_LOW` | clmul | 进位无关积的**低** 64 位 |
| 1 `CLMUL_OP_HIGH` | clmulh | 进位无关积的**高** 64 位 |
| 2 `CLMUL_OP_REV` | clmulr | 位反转进位无关积(clmulr,= bitrev(clmul(bitrev(a),bitrev(b)))) |

## 3. 状态机(3 态)
```
IDLE --req_fire--> RUN --(64 拍, iter 0..63)--> [iter==63] --> RESP --resp_ready--> IDLE
```
- **IDLE**:`req_ready_o=1`;req_fire 时锁存 op/rob_idx/pdest,初始化移位寄存器,转 RUN。
- **RUN**:每拍做一次 GF(2) 部分积累加(异或),移位,iter+1;iter==63 拍把结果写 `resp_data_q` 转 RESP。
- **RESP**:`resp_valid_o=1`;resp_ready 时返回 IDLE。

## 4. 算法(迭代 XOR-移位)
每拍:`acc ^= step_bit ? partial : 0`,共 64 拍覆盖 64 个 src2 位。
- **LOW(clmul)**:`step_bit=rhs_shift[0]`、`partial=lhs_shift`;每拍 `lhs<<=1`、`rhs>>=1`。
  即 acc = Σ_i (src2[i] ? src1<<i : 0),取低 64 位(高位在 lhs 左移出后自然丢弃)。
- **HIGH(clmulh)**:`step_bit=rhs_shift[63]`(MSB)、`partial=rhs_right_shift`(初值=src1);
  每拍 `rhs<<=1`、`rhs_right_shift>>=1`。从高位累加,得积的高 64 位。
- **REV(clmulr)**:同 HIGH 路径,但 `rhs_right_shift` 初值=`{1'b0, src1[63:1]}`(src1>>1),
  对应 clmulr 的位反转语义。

## 5. 不变量
- **CLMUL-I1 时延固定**:每个请求恒 64 拍 RUN(无早终止),iter 7 位计数 0→63。
- **CLMUL-I2 单请求在飞**:IDLE 才 `req_ready`,RESP 才 `resp_valid`;一次只算一个,无重叠。
- **CLMUL-I3 flush 安全**:flush_i 即复位 IDLE,在算请求丢弃(其 rob_idx 不 commit,与核 flush 语义一致)。
- **CLMUL-I4 GF(2) 正确**:用异或非加法,无进位;LOW 取低位、HIGH/REV 从 MSB 累加取高位。

## 6. 验证
- 模块 TB `tb_ooo_clmul_unit` 定向:clmul/clmulh/clmulr 已知向量、全 0/全 1、单 bit。
- 系统级:`bitmanip` AM 测(含 Zbc)经 GOOD TRAP;`bitmanip` 已在 difftest 子集逐指令对照 NEMU。
- 对抗审查(2026-06-28 bug-hunt 覆盖整数后端):迭代/移位/握手未见 bug。

## 7. 变更记录
- 2026-06-28:建立 spec(补齐模块 spec 覆盖;描述 3 op、3 态 FSM、迭代 XOR-移位算法与不变量)。
