# F32 tensor ALU RTL contract

> **Tensor arithmetic Phase F32-A。** 本合同冻结 `TensorNpuF32TensorAlu`
> 对 GGML F32 `ADD`、`MUL`、`SUB` 与普通 `SCALE` 的单命令语义。模块从
> single-outstanding 64-bit GMEM 读取 strided source，以
> `TensorNpuFp32AddMul` 执行逐元素 RNE binary32 运算，并只写
> transaction-private contiguous shadow destination。`done_o` 只授予父级
> shadow commit eligibility；模块不修改 active root、不做 pointer swap，也不
> 实现 CPU fallback。

PASS 只覆盖本模块及其定向 raw-bit testbench；不证明 367-node exact graph
manifest、llama.cpp backend、1711-node graph、Qwen 执行、tokens/s、综合、STA、
PPA、Unary/GLU 或 third-party FPU 的独立正确性。

## 1. 阶段 1：需求冻结

### 1.1 功能目标

- `ADD`：`dst[i] = src0[i] + src1[i modulo src1.ne]`；
- `MUL`：`dst[i] = src0[i] * src1[i modulo src1.ne]`；
- `SUB`：只允许以 `src0 + {~src1.sign,src1[30:0]}` 驱动 ADD child；
- `SCALE`：只允许以 `src0 * op_params.scale` 驱动一次 MUL child，禁止额外 ADD、
  FMA 或 host 代算；
- source 地址按 GGML `ne0` fastest 的四维 modulo coordinate 与 `nb[4]` 计算；
  destination 必须是 contiguous F32 dup layout；
- 每条命令在首个 GMEM request 前完成全 descriptor 的 128-bit preflight；
- 成功 child response 的 `{NV,DZ,OF,UF,NX}` 按元素 sticky-OR；算术 flag 不是
  transaction error；
- fixed empty 只接受 `SCALE src0/dst ne=[0,1,1,1]` 且 scale/bias 均为
  `+0`，恰好一次 `done_o`，所有 GMEM/child/write 计数为0。

### 1.2 Module 端口

```verilog
module TensorNpuF32TensorAlu #(
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer CHILD_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576,
    parameter integer MAX_ELEMENTS           = 262144
) (
    input  wire        clk_i,
    input  wire        rst_i,                 // 同步、高有效
    input  wire        start_i,
    output wire        ready_o,
    output wire        busy_o,

    input  wire [2:0]  opcode_i,              // 0 ADD,1 MUL,2 SUB,3 SCALE
    input  wire [1:0]  dtype_i,               // 0 = F32，其他拒绝
    input  wire [3:0]  profile_i,             // 0 = RNE/gradual/after/qNaN+
    input  wire [31:0] reserved_i,            // 必须为0
    input  wire [63:0] op_params_i,           // {bias_bits,scale_bits}

    input  wire [63:0] gmem_floor_i,
    input  wire [63:0] gmem_limit_i,

    // src0/src1 各自：region_base/size/view_off + ne0..ne3 + nb0..nb3
    // dst：region_base/size/view_off + ne0..ne3 + nb0..nb3

    // held 64-bit single-outstanding GMEM request/response

    output wire        done_o,
    output wire        error_o,
    output wire [4:0]  error_code_o,
    output wire [4:0]  arithmetic_flags_o,
    output wire [63:0] elements_done_o,
    output wire [63:0] gmem_read_beats_o,
    output wire [63:0] gmem_pair_reuse_elements_o,
    output wire [63:0] gmem_write_beats_o,
    output wire [63:0] writes_accepted_o,
    output wire [63:0] child_requests_o,
    output wire [63:0] child_responses_o,
    output wire [63:0] active_cycles_o
);
```

全部端口属于 `clk_i` 时钟域。模块是多周期、逐元素串行实现，仍不承诺每拍吞吐；
最初 baseline 不承诺 beat reuse 的历史描述由 §14 的 registered pair-beat reuse
successor 取代。父级只在 `done_o` 单拍采纳 `arithmetic_flags_o` 与
shadow generation。失败命令可以在 shadow 留下 partial bytes，但没有 commit
eligibility。

### 1.3 明确 out-of-scope

- 不修改 `TensorNpuFp32AddMul`、`TensorNpuTensorMover`、
  `TensorNpuSetRowsEngine`、Unary/GLU 或 third-party；
- 不实现 active-root write、原子 pointer swap、overlay、LMEM/DMA、backend
  command ABI 或 graph census；
- 不运行或声称综合、STA、PPA、Qwen 或 strict graph PASS。

## 2. 阶段 2a：协议规则

### 2.1 Command handshake

- 仅 `start_i && ready_o` 锁存完整 descriptor；`ready_o` 只在 clean IDLE 为1；
- busy `start_i` 不采样，resident descriptor、坐标、结果和资格不得被覆盖；
- `done_o`/`error_o` 为互斥单拍 Moore terminal，下一拍进入 IDLE；
- reset 优先取消 resident command、request valid、accepted owner 与 terminal；
  reset 后不得发布 stale completion。

### 2.2 GMEM handshake

- request 只在 `gmem_req_valid_o && gmem_req_ready_i` 接受；
- `valid&&!ready` 时 write/address/data/strobe 逐 bit 保持；
- 任一周期最多一个 GMEM request outstanding；只有 matching WAIT 或 owner-tagged
  `DRAIN` 对 response 提供一个 credit；
- 4B F32 读取/写入使用 aligned 8B beat，lane 只能为0或4；write strobe 只能为
  `8'h0f` 或 `8'hf0`；
- read/write beat 在 request handshake 计数，`writes_accepted_o` 在 write
  handshake 计数，`elements_done_o` 只在成功 write response 后计数。

### 2.3 Child handshake 与 owner

- 模块独占一个 `TensorNpuFp32AddMul`；parent GMEM outstanding 与 child
  outstanding 不得并存；
- child request payload 先进入 resident `lhs_bits_q/rhs_bits_q`，在
  `CHILD_REQ` 背压期间稳定；
- child response 只在 `CHILD_WAIT` 或 child-owned `DRAIN` 消费；其它 active
  state 的 child response 是 ghost/wrong-owner protocol fault；
- `arithmetic_flags_q` 只在未命中 watchdog 的 matching child response
  handshake 做 OR；deadline 同拍 response 被消费但不进入成功 flags/result；
- normal matching child response 只生成一份 aligned shadow-write payload。GMEM
  ready-high 时，同一边沿清除旧 child owner、接受新 GMEM write owner 并直接进入
  `WRITE_WAIT`；ready-low 时仍消费 child response，把完全相同的 payload 捕获到既有
  GMEM request q，下一拍进入 `WRITE_REQ`；
- direct/fallback 的 `valid/address/data/strobe` 不得依赖 `gmem_req_ready_i`，ready
  只决定是否取得 GMEM credit；因此边沿前后都不允许 child 与 GMEM owner 并存；
- IDLE/DONE/ERROR 期间 reset child，隔离上一命令的任何 pipeline residue。

### 2.4 Watchdog 与 drain

逐拍优先级固定为：

```text
rst_i
  > illegal state / owner violation / GMEM response error
  > command timeout
  > request/response stall timeout（child WAIT 使用 CHILD timeout）
  > normal progress
```

- REQ watchdog 命中当拍组合撤销 valid；same-cycle late ready 不得接受新事务；
- accepted GMEM/child WAIT timeout 若同拍没有 matching response，锁存 cause 与
  owner，进入唯一 `ST_DRAIN`；
- `ST_DRAIN` 冻结坐标、结果、flags、命令/active cycle 与完成资格计数，只等待
  该 owner 的 matching response；child drain 实际消费 response 时只允许
  `child_responses_o` 这一诊断计数增加一次；
- GMEM late response 的 `gmem_rsp_error_i` 覆盖 timeout cause 为
  `ERR_GMEM_RESPONSE`；child drain completion 保留原 timeout/protocol cause；
- drain terminal 后无需 global reset 即可接受 clean retry。

## 3. 阶段 2b：状态机

| state | owner / 输出 | 正常转移 |
|---|---|---|
| `IDLE` | `ready_o=1`，child reset | start → `PREFLIGHT` |
| `PREFLIGHT` | 零 request，组合检查 resident descriptor | error → `ERROR`; empty → `DONE`; active → `ELEMENT_PREP` |
| `ELEMENT_PREP` | 4D modulo 地址网，寄存三个地址/lane | `SRC0_REQ` |
| `SRC0_REQ` | held GMEM read0 request | fire → `SRC0_WAIT` |
| `SRC0_WAIT` | GMEM owner | response → `SRC1_REQ` 或 `CHILD_REQ` |
| `SRC1_REQ` | held GMEM read1 request | fire → `SRC1_WAIT` |
| `SRC1_WAIT` | GMEM owner | response → `CHILD_REQ` |
| `CHILD_REQ` | held ADD/MUL request | fire → `CHILD_WAIT` |
| `CHILD_WAIT` | child owner；normal response 驱动唯一 shadow-write offer | ready-high direct fire → `WRITE_WAIT`（原子 owner handoff）；ready-low → `WRITE_REQ`（captured fallback） |
| `WRITE_REQ` | held fallback shadow write | fire → `WRITE_WAIT` |
| `WRITE_WAIT` | GMEM owner；等待期以 state-only selector 预计算下一元素 | successful non-last response → `SRC0_REQ`；last → `DONE` |
| `DRAIN` | owner-tagged response credit；所有结果冻结 | matching response → `ERROR` |
| `DONE` | 单拍 commit eligibility | `IDLE` |
| `ERROR` | 单拍 no-commit terminal | `IDLE` |

非法 state：若仍有唯一 accepted owner则携带 `ERR_INTERNAL_STATE` 进入 `DRAIN`；
否则直接 `ERROR`。GMEM response error 高于同拍 timeout。`ADD/MUL/SUB` 的 read
顺序固定 src0→src1；`SCALE` 不产生 src1 request。

## 4. 阶段 2c：不变量

| ID | 触发/表达式 | 违反后果 |
|---|---|---|
| I1 | `start` 只在 IDLE 采样；busy descriptor 不变 | owner/descriptor corruption |
| I2 | `PREFLIGHT` terminal 前 accepted GMEM/child count 为0 | 非资格访问 |
| I3 | GMEM outstanding ∈ `{0,1}`，child outstanding ∈ `{0,1}`，两者之和 ≤1 | owner corruption |
| I4 | request `valid&&!ready` 时 payload stable | bus/child protocol fault |
| I5 | response credit 只属于 matching WAIT/DRAIN owner | ghost adoption |
| I6 | 坐标只在成功 shadow write response 后推进 | result/address mismatch |
| I7 | `child_requests-child_responses` ∈ `{0,1}`；正常成功每元素恰好一次 | arithmetic cardinality fault |
| I8 | sticky flags只 OR 正常 matching child response；error/reset不发布成功 flags | false arithmetic result |
| I9 | `SUB` child op=ADD 且 rhs sign 恰好翻转一次 | SUB semantic mismatch |
| I10 | `SCALE` child op=MUL 且 rhs=`op_params[31:0]` | SCALE semantic mismatch |
| I11 | destination仅 contiguous shadow；模块没有 active-root port | architectural corruption |
| I12 | empty SCALE：done=1次且所有 request/write/child/element计数=0 | empty side effect |
| I13 | REQ timeout 当拍 valid=0；accepted timeout只可进入 `DRAIN` | orphan transaction |
| I14 | `DRAIN` 坐标/result/flags/completion counters/cycles frozen；只允许 matching child response diagnostic 加1 | timeout semantic adoption |
| I15 | `done_o && error_o == 0`，terminal 宽度恰好1拍 | ambiguous commit eligibility |
| I16 | accepted GMEM = responses + reset-cancelled；child同构 | transaction leak |

I2/I3/I4/I5/I6/I7/I12/I13/I14/I15/I16 由 testbench procedural monitor 与
scoreboard 定向观测；I1/I8/I9/I10/I11 还由结构性 RTL mux/port 边界保证。

## 5. 阶段 2d：数据通路约束

### 5.1 128-bit preflight

固定错误优先级：

```text
HEADER/PROFILE -> SHAPE/BROADCAST -> STRIDE/ALIGN
               -> SOURCE_BOUNDS -> DEST_BOUNDS -> OVERLAP
```

active command 必须证明：

1. opcode 仅0..3，`dtype=0`、`profile=0`、`reserved=0`；binary op 的
   `op_params=0`，SCALE 的 `bias_bits=+0`；
2. src0/dst 四维 shape 相同且全非零；binary src1 各维非零且
   `src0.ne[d] % src1.ne[d] == 0`；total elements 为
   `1..MAX_ELEMENTS`；
3. src0/src1 的 `nb[d]` 均为非零4B倍数；destination 精确满足
   `nb=[4,4*ne0,4*ne0*ne1,4*ne0*ne1*ne2]`；每个起始地址4B对齐；
4. 对每个实际 source：

   ```text
   semantic_end = base + view_off + sum((ne[d]-1)*nb[d]) + 4
   beat_start   = floor8(base+view_off)
   beat_end     = ceil8(semantic_end)
   ```

   region base+size、view/span、absolute address、aligned beat 与 GMEM 半开窗口均
   不溢出且在界内；
5. destination `semantic_end=base+view_off+total*4` 与 aligned beat window
   同样在 region/GMEM window 内；
6. destination aligned beat window 与每个实际 source aligned beat window 不
   overlap；SCALE 不检查、不访问 src1；
7. empty fixed case跳过 stride/dereference/overlap，允许 null base，但仍要求合法
   opcode/profile/window 与 exact zero scale/bias。

全部乘加、span、aligned window、contiguous stride 期望值使用128-bit组合中间值。

### 5.2 4D modulo walker

对 output 坐标 `(i0,i1,i2,i3)`：

```text
src0_addr = src0.base + src0.off + sum(i[d] * src0.nb[d])
src1_addr = src1.base + src1.off
          + sum((i[d] % src1.ne[d]) * src1.nb[d])
dst_addr  = dst.base + dst.off + flat_index*4
```

`i0` 最快；write response 成功后按 i0→i1→i2→i3 carry。`src1.nb0` 不限制为4，
也不使用 NumPy singleton-only broadcast。

### 5.3 Shared resource mux

- 唯一 GMEM request payload register 由 `ELEMENT_PREP/SRC0_WAIT/SRC1_WAIT/
  CHILD_WAIT` 以及 successful non-last `WRITE_WAIT` 依阶段装载；`CHILD_WAIT`
  ready-low fallback 捕获与 direct offer 完全相同的 payload，REQ state 不更新；
- 唯一 child mux：

  ```text
  child_op_mul = opcode==MUL || opcode==SCALE
  child_lhs    = captured src0
  child_rhs    = SUB ? {~captured_src1[31],captured_src1[30:0]}
               : SCALE ? op_params.scale : captured_src1
  ```

- child result 与 resident current-dst 只形成一份 aligned 8B write data/strobe 网络；
  ready-high 直接驱动 GMEM request，ready-low 同沿锁存后由 `WRITE_REQ` 持有；
- 预计最长运行组合路径是 modulo/stride 四项乘加；预计最长 preflight 路径是
  4D span/contiguous stride乘加→aligned window→bounds/overlap 比较。未做 PPA 声明。

## 6. 阶段 2e：RTL 级电路 topology（写 RTL 前冻结）

1. **module/interface**：单 `clk_i`、同步高有效 `rst_i`；command start/ready、
   held GMEM valid/ready、内部 child valid/ready、单拍 terminal，位宽见§1.2。
2. **state registers**：`state_q`、完整 resident descriptor、4D coords、flat index、
   total count、GMEM payload/lane、captured operands/result、GMEM/child outstanding、
   drain owner/cause、watchdogs、sticky flags和审计 counters；全部由唯一
   `always @(posedge clk_i)` 更新，reset值为0/IDLE。
3. **combinational blocks**：128-bit preflight、4D modulo address generator、
   timeout/handshake decode、owner-violation decode、child operand mux、公开输出 decode；
   所有 `always @(*)` 路径先赋默认值，不推 latch。
4. **FSM**：精确采用§3的14态 Moore/handshake状态机；非法态按 accepted owner
   选择 DRAIN 或 ERROR。
5. **pipeline/flow**：无多元素 pipeline；GMEM read response → captured operand →
   child response 后，ready-high 允许原子转交 GMEM write owner，ready-low 才经过
   captured write payload → `WRITE_REQ`；每个 backpressure 点仍由对应 REQ/WAIT
   state持有。
6. **priority**：`reset > protocol/response fatal > command timeout > phase timeout >
   normal`；busy start最低且被忽略；terminal下一拍才重新 ready。
7. **resource sharing**：一个64-bit GMEM端口和一个 `TensorNpuFp32AddMul` 共享于
   全部元素/四opcode；state+opcode提供显式 mux/enable，禁止隐式并行 owner。
8. **critical path**：preflight 的128-bit shape/span/bounds/overlap、运行时四维
   modulo+stride乘加，以及 child result/current-dst→shift/strobe/legality→GMEM
   output mux 都是候选；F32数值关键路径位于既有 child 内，本轮不测 STA。
9. **function划分**：RTL 不用 function 隐藏 FSM/仲裁/握手；只用显式
   `always @(*)` 地址/检查网络与 `always @(posedge clk_i)` 状态更新。TB function
   仅做 raw memory read helper，for-loop只用于展开 byte memory/model checker，
   不表示 production 时序控制。

Topology 自审结果：端口、owner、reset与terminal优先级闭合；registered accepted
GMEM/child owner互斥，direct 边沿只允许旧 child→新 GMEM 的原子 handoff；accepted
timeout存在唯一 drain；empty路径从 PREFLIGHT 直达 DONE；所有 source/destination
address在 request前由128-bit preflight覆盖。允许进入阶段3。

## 7. Error code

```text
0  NONE
1  HEADER_OR_PROFILE
2  SHAPE_OR_BROADCAST
3  STRIDE_OR_ALIGNMENT
4  SOURCE_BOUNDS
5  DESTINATION_BOUNDS
6  OVERLAP
7  GMEM_RESPONSE
8  STALL_TIMEOUT
9  COMMAND_TIMEOUT
10 CHILD_PROTOCOL_OR_OWNER
11 CHILD_TIMEOUT
12 INTERNAL_STATE
```

## 8. Raw-bit TB 与判定边界

`tests/tb_f32_tensor_alu.sv` 使用 little-endian byte GMEM 与冻结 raw constants；
禁止 `real`、`shortreal`、DPI、host FPU、assert、trace、coverage与wave。至少闭合：

- 四opcode raw result/flags、signed zero、canonical NaN、overflow、subnormal、
  tininess-after；SUB sign-inverted ADD 与 SCALE single-MUL cardinality；
- `[4,4,2,1]` 对 `[2,2,1,1]` modulo broadcast，rhs `nb0=8` sentinel；
  transpose-like rhs `ne=[1,4,1,1],nb=[16,4,...]`；
- fixed empty SCALE exact zero access；
- header/profile/op_params/shape/divisibility/stride/alignment/bounds/window/overlap
  在首个 request 前拒绝；
- src0/src1/write response error、REQ timeout、accepted READ/WRITE drain、late error
  override、deadline与ready同拍；
- child request/response backpressure、ghost/owner/timeout、deadline同拍 response；
- busy start、mid-preflight/read/child/write reset、active-root canary、clean retry；
- accepted/response/reset-cancelled conservation与 `max_outstanding=1`。

唯一固定配置：

```text
verilator --binary --timing --sv -O3 -Wall -Wno-fatal
C++: -O3 -DNDEBUG -march=native
top=tb_f32_tensor_alu, assertions/trace/coverage/waveform=off
```

固定 terminal marker：

```text
[NPU-F32-TENSOR-ALU][PASS]
```

本模块 PASS 仍保留 GAP：367-node exact multiplicity、strict backend manifest、
active-root commit/overlay、Qwen、综合、STA、PPA 均未执行或证明。

## 9. repair-v2 验证边界冻结

本节冻结 `tensor-f32-alu-repair-v2`。v1 的生产 RTL 不因失败 marker 自动判错：
v1 testbench 对组合别名 `dut.child_rsp_valid_w` 的 force 只改变该层可观察 net，
Verilator 展开后的生产 owner-fault predicate 仍直接消费 child resident
`dut.u_fp32_addmul.rsp_valid_q`，因此 v1 的 ghost fixture 没有真正命中
`child_response_owner_fault_w`。repair-v2 先根修 fault injection 与证据边界；只有
真实生产 predicate 被正确激励后仍出现 RTL 反例，才允许修改
`TensorNpuF32TensorAlu.v`。

### 9.1 阶段 1：需求、接口与禁止变化

- production interface、descriptor 格式、opcode、error code、FSM 编码、timeout
  计数、GMEM/child handshake 与 shadow-only write 均保持第 1--8 节冻结语义；
- ADD/MUL/SUB/SCALE、4D modulo broadcast、strided source、contiguous shadow、
  preflight、accepted drain、sticky flags 与 empty SCALE 不作功能扩展；
- repair-v2 的必要修改对象默认仅为 `tb_f32_tensor_alu.sv` 和本合同；未观察到
  production root cause 时，`rtl/TensorNpuF32TensorAlu.v` 必须字节不变；
- 每个层级 fault fixture 必须先证明 force/deposit 影响了生产消费点，不能只凭
  terminal `ERROR` 或 testbench-visible alias 宣称注入有效。

### 9.2 阶段 2a：事务生命周期冻结

1. 在注入采样边沿前先等待组合 settle；同时观察真实 source、生产
   `*_fault_w`/timeout predicate、owner credit 与 fire。
2. ghost/wrong-owner 必须满足 `u_fp32_addmul.rsp_valid_q=1`、
   `child_response_owner_fault_w=1`、`protocol_fault_w=1`，且
   `child_rsp_ready_w=0`、`child_rsp_fire_w=0`，不授予非法 response credit。
3. 采样边沿后检查唯一 error code、state/drain owner、descriptor/counter/coordinate/
   flags 快照及 shadow canary；随后释放注入源。
4. 已接受 GMEM/child transaction 只能进入相应唯一 drain；未接受 owner 的 ghost
   直接进入 `ST_ERROR`。drain 期间禁止新 request、DONE、partial commit。
5. terminal error retire 后必须在不施加 global reset 的情况下完成一次合法 clean
   retry，并逐 raw result/flag/counter 验证。

### 9.3 阶段 2b：状态转移冻结

```text
ST_PREFLIGHT + child ghost
    --predicate witnessed--> ST_ERROR(ERR_CHILD_PROTOCOL)

ST_SRC0_WAIT + GMEM outstanding + child wrong-owner
    --predicate witnessed--> ST_DRAIN(DRAIN_GMEM, ERR_CHILD_PROTOCOL)
    --matching GMEM response--> ST_ERROR(ERR_CHILD_PROTOCOL)

ST_CHILD_WAIT + child timeout + child outstanding
    --> ST_DRAIN(DRAIN_CHILD, ERR_CHILD_TIMEOUT)
    --matching child response--> ST_ERROR(ERR_CHILD_TIMEOUT)

ST_CHILD_WAIT + deadline-cycle matching child response
    --> ST_ERROR(ERR_CHILD_TIMEOUT)       // response consumed, no drain owner remains
```

所有边沿后断言使用状态 resident 值而非同边沿旧值；terminal `error_o` 只允许单拍，
相关 transaction 不得出现 `done_o`。

### 9.4 阶段 2c：控制不变量冻结

- `child_rsp_ready_w` 只有 `child_owner_expected_w` 才可为 1；ghost/wrong-owner
  即使 `rsp_valid` 为 1 也不得产生 credit/fire；
- force `stall_cycles_q`/`command_cycles_q` 的 fixture 必须在边沿前观察对应
  `phase_timeout_hit_w`/`command_timeout_hit_w=1`；force ready 的 fixture 必须观察
  production valid/ready/fire 三元组；
- accepted/response/reset-cancelled conservation、`max_outstanding=1`、零非法 GMEM
  request、零 partial write、零 DONE eligibility 在 fault transaction 全程成立；
- owner-fault/timeout 前后 `element_count_q`、`write_response_count_q`、坐标、
  tensor flags 及 shadow canary 保持冻结；只有 matching successful child response
  可以 sticky-OR flags；
- injection witness 计数必须与固定 fixture 数精确相等；未命中 predicate 的
  expected-error 测试本身视为 FAIL。

### 9.5 阶段 2d：验证数据路径冻结

- child ghost/wrong-owner 直接 force `dut.u_fp32_addmul.rsp_valid_q`；禁止再次以
  `dut.child_rsp_valid_w` 作为激励源；
- 边沿前读取 `child_response_owner_fault_w`、`protocol_fault_w`、
  `child_owner_expected_w`、`child_rsp_ready_w`、`child_rsp_fire_w`；边沿后读取
  `state_q`、`error_code_q`、`drain_owner_q`、`drain_error_code_q` 与快照；
- timeout/backpressure fixture 同样读取其生产 predicate/credit，而不是仅检查
  最终错误；
- raw arithmetic oracle、broadcast/stride address oracle、shadow byte canary 与
  counter oracle 继续作为数据面判定，host floating point 不进入 oracle。

### 9.6 阶段 2e：九项 topology 冻结

1. **请求源**：resident descriptor + 4D walker 仍是唯一 GMEM address 源。
2. **请求仲裁**：单一 GMEM owner 与单一 child owner 不增加旁路。
3. **响应归属**：matching owner 才授予 ready；wrong-owner 只触发 protocol fault。
4. **故障注入**：TB 直接驱动 elaboration 后真实 resident source，并以 production
   predicate 证明命中。
5. **timeout**：REQ、accepted WAIT、child WAIT 与 command timeout 各自绑定生产
   predicate；accepted owner 只进入唯一 drain。
6. **算术路径**：SUB 仍为 sign-inverted ADD，SCALE 仍为单 MUL，flags 仍只来自
   matching successful child response。
7. **写回**：目的地址仍只指向 contiguous shadow，error transaction 永不获得
   shadow commit eligibility。
8. **恢复**：terminal error 清除 resident transaction，clean retry 无需 global
   reset，active-root canary 不变。
9. **生产变更门槛**：只有真实 predicate witness 后出现可复现 RTL 反例才改生产
   RTL；否则 repair-v2 保持 production source hash 不变。

### 9.7 v1 不可变反例绑定

repair-v2 runner 在 build 前必须 fail-closed 复核下列 v1 产物，不得修改或追认：

```text
native-run.log sha256=e3143507d37321825bb3cc843d27d387f07806eecf373d4dc1d062411be132cf
run.status     sha256=3ac666e8d5ee811cd74faa27d8f64353e26be71e462b8eb27577ceaf9c037645
raw verFiles   sha256=22f7ed805cc74218fb3cf314f6a9776046448f99aef3cecb63fa4e0911697b9e
binary         sha256=e10f4ef4eb598ac52d845bc54e5399bafdbca431489a4a75edf84a4f3c02aee5
build log      sha256=2d88d5d230a3b2f550f5ae546cb7a8080268b9b2b250408f85cfd52b1f287037
status=FAIL rc=134 stage=native-run evidence_complete=0 cleanup_rc=0
marker=[NPU-F32-TENSOR-ALU][FAIL] child-ghost unexpected DONE cycle=1390 state=12
v1 expected source rows=14, raw S rows=16
```

v1 的两个未消费 `S` row 为 `/usr/share/verilator/include/verilated_std.sv` 与
`/usr/bin/verilator_bin`；这是 evidence membership 缺口，并不改变 native FAIL。

### 9.8 repair-v2 raw `S` row 四类闭包

repair-v2 对 `Vtb_f32_tensor_alu__verFiles.dat` 的每一条 `S` row 做 canonicalize
后必须恰好归入一类：

- **design/filelist source**：固定 filelist 展开的 primitive、child、production
  RTL 与 top TB；
- **transitive include**：Verilator 自动消费、但不在 design filelist 中的 include；
- **control**：驱动固定 compilation membership 的 response/filelist 控制文件；
- **tool**：本次 elaboration 实际执行的 Verilator tool identity。

四类各自去重且互斥；canonical union 必须与 raw `S` rows exact-match。
unknown/outside/duplicate/missing 必须非零拒绝。baseline 与 missing-source、
extra-source、top-replacement 三个 mutation 必须调用同一 production comparator；
后三者必须非零拒绝。只有 immutable v1 绑定、source/config identity、native rc0、
exact-one PASS/zero FAIL、source-scoped warning/error zero、四类 membership、mutation、
signal/EXIT/cleanup counterexample、artifact audit 与全部哈希均闭合后，runner 才能
写 `evidence_complete=1`。

## 10. repair-v3 busy-start oracle 冻结

本节冻结 `tensor-f32-alu-repair-v3`。repair-v2 已把 child ghost 与
wrong-owner 激励接到真实 resident source，且唯一 native run 运行越过四个 child
fault 及各自 clean retry；但它在随后 `busy-start` fixture fail-closed：

```text
marker=[NPU-F32-TENSOR-ALU][FAIL] busy-start unexpected ERROR cycle=1513 state=13
status=FAIL rc=134 stage=native-run evidence_complete=0 cleanup_rc=0
native-run.log sha256=0aa0a1ff8317948977a864c1603244a339d4731a1ca3e86a4aad0f14c7c748d7
run.status     sha256=3ac666e8d5ee811cd74faa27d8f64353e26be71e462b8eb27577ceaf9c037645
raw verFiles   sha256=cbcc098f5beece8c638bcd1f5860ab6ced6936d3ee83e499121242961734fc5d
binary         sha256=04eded7979ba0e60d43f23bde270625f991ed6084a62c51dd0b91ea1a788c3e3
build log      sha256=4766e9dbea515b95d2f639f0d3cc4c278a80a08eebbb62cbcfc75c0c548e907c
```

该首错不追认为 production RTL FAIL。TB 使用 `read_response_delay_cfg=6`，而
`STALL_TIMEOUT_CYCLES=8`；GMEM model 在 countdown 到零的边沿才注册
`gmem_rsp_valid_i`，DUT 到下一边沿才消费 response。因此 matching response 恰在
`stall_cycles_q==STALL_TIMEOUT_LAST` 的 deadline 边沿取得 credit，冻结的
`ST_SRC0_WAIT` 优先级正确选择 `ERR_STALL_TIMEOUT`，而 fixture 错误地期待 DONE。

### 10.1 阶段 1：需求与接口边界

- production module、端口、descriptor 编码、FSM、watchdog、GMEM/child owner、
  arithmetic 与 shadow write 语义完全不变；production RTL 必须保持 repair-v2 hash；
- `busy-start` 使用明显小于 8-cycle phase deadline 的固定 GMEM delay，并在第一个
  descriptor resident 且 GMEM owner accepted 时脉冲第二个 `start_i`；
- 第二个 start 必须在采样边沿前后均看到 `ready_o=0`、`start_fire_w=0`，不得覆盖
  resident descriptor、owner、walker、request payload 或 counters；
- 原两元素 ADD transaction 必须得到 raw `0x40000000`、`0x40400000`，alternate
  destination 的全部 preimage bytes 保持；
- 独立 REQ deadline、accepted WAIT timeout、child deadline/collision fixture 原样
  保留 timeout-wins oracle。禁止增加 timeout、弱化 collision 或调整 RTL 优先级。

### 10.2 阶段 2a：协议规则

1. 首个 start 只在 `ST_IDLE && ready_o` 取得 `start_fire_w`，一次性捕获完整
   128-bit-equivalent descriptor 输入集合。
2. 到达 `ST_SRC0_WAIT` 时已有唯一 GMEM owner；safe delay 必须满足
   `phase_timeout_hit_w=0` 且第二 start 边沿不出现 GMEM response credit。
3. 第二个 start 改变 input pins 但不改变 resident `*_q`；由于 `ready_o=0`，
   `start_fire_w=0`，FSM 保持 `ST_SRC0_WAIT`，既有 owner 与 payload 保持。
4. 第二 start 去除后，原 owner 的 matching response 正常推进 SRC0→SRC1→child→
   shadow write；不得产生第二 command、额外 request/response/write 或 child credit。
5. deadline fixtures 继续在 production timeout predicate 为 1 时撤销/否决正常推进；
   matching deadline response 可以被消费，但 transaction 仍无成功资格。

### 10.3 阶段 2b：状态机

```text
IDLE --first start_fire--> PREFLIGHT -> ELEMENT_PREP -> SRC0_REQ
SRC0_REQ --GMEM req_fire--> SRC0_WAIT(owner=GMEM)
SRC0_WAIT + second start_i + ready_o=0 + no timeout/response
    --> SRC0_WAIT(same resident descriptor, same owner, no new credit)
SRC0_WAIT --early matching response--> SRC1_REQ -> ... -> DONE

REQ/WAIT/child deadline predicate
    --> ST_ERROR or matching-owner ST_DRAIN according to existing sections
```

不新增状态或状态边；第二 start 只是 active transaction 期间被接口合同拒绝的输入。

### 10.4 阶段 2c：不变量

- **descriptor hold**：第二 start 边沿前后，header/profile/op_params、GMEM window、
  src0/src1/dst base/size/view、四维 `ne` 与四维 `nb` 的所有 resident q 相等；
- **owner hold**：`state_q==ST_SRC0_WAIT`、`gmem_outstanding_q=1`、
  `gmem_owner_expected_w=1`、`child_outstanding_q=0`；
- **admission reject**：`ready_o=0 && start_fire_w=0`，input descriptor 改变不构成
  resident update enable；
- **zero extra credit**：第二 start 边沿的 GMEM accepted/response、read/write、child
  accepted/response 与 DUT transaction counters 均保持 snapshot；
- **walker/payload hold**：`total_elements_q`、flat/coords、`gmem_req_addr_q`、
  `current_src1_word_q`、`current_dst_addr_q`、flags 与 elements 保持；
- **end-to-end cardinality**：两元素 binary op 恰好 4 read、2 write、2 child request、
  2 child response、2 elements；alternate target 16 bytes 不变；
- **deadline separation**：safe fixture 明确 witness `phase_timeout_hit_w=0`；独立
  deadline fixture 明确 witness timeout predicate 为 1 并取得 timeout error。

### 10.5 阶段 2d：验证数据路径

- busy-start 仍使用 little-endian raw GMEM；src0 `[1.0,2.0]` 与 src1 `[1.0,1.0]`
  经 resident OP_ADD 得到 `[2.0,3.0]`；
- alternate input descriptor 指向 src0 `0x3000`、dst `0x5000`，但仅作为被拒绝的
  pin-level反例；resident address walker 与写回仍指向原 `0x1000/0x2000/0x4000`；
- snapshot 比较直接读取 production resident q 与 owner/fire wires；不使用仅 TB
  可见的影子布尔量替代；
- host FP、real、shortreal 与 DPI 不进入 oracle。

### 10.6 阶段 2e：九项 RTL/TB topology

1. **module/接口**：`start_i/ready_o` admission 与 GMEM/child valid-ready 接口不变。
2. **状态寄存器**：所有 descriptor、walker、owner、counter q 仍只由 production
   单一 `always @(posedge clk_i)` 更新；TB 只读 snapshot。
3. **组合逻辑**：`start_fire_w=start_i&&ready_o`、timeout predicate、owner expected、
   request/response fire 网络不变。
4. **FSM**：不增加 busy-start 状态；active state 忽略未获 ready 的 start。
5. **pipeline/握手**：单 GMEM owner、单 child owner、无 combined outstanding overlap。
6. **优先级**：reset > protocol fault > response error > command timeout > phase timeout
   > normal matching response；safe fixture 避开 deadline，deadline fixture不变。
7. **资源共享**：GMEM request payload、ADD/MUL child 与 shadow write mux 不复制；
   第二 start 不获得任何 enable。
8. **关键路径（repair-v3 历史边界）**：当时 production arithmetic/address critical
   path 不变；新增逻辑仅存在于 TB snapshot 比较，不进入综合。该历史边界由 §11 的
   turnover 性能变换显式取代。
9. **function/显式硬件**：raw byte helper 保持纯 TB function/task；owner、FSM、timeout
   与 descriptor capture 继续是 production 显式时序/组合网络。

### 10.7 repair-v3 evidence identity

repair-v3 runner 必须在 build 前同时复核 v1 child-ghost FAIL 与 v2 busy-start FAIL，
并保持二者 immutable。固定 filelist 的 raw `S` rows 预期为 17：design 14、
transitive include 1、control 1、tool 1。actual baseline 与 missing-source、
extra-source、top-replacement、class-collision 四个 mutation 调用同一 comparator；
unknown/outside/duplicate/missing 与四个 mutation 均必须非零拒绝。只有 native
build/run rc0、PASS exact-one、FAIL zero、source diagnostics zero、完整 fixture/count
终局、membership/mutations、signal/EXIT/identity/cleanup、forbidden artifact 与所有
source/config/binary/log/status/receipt hash 全部闭合，才允许 `evidence_complete=1`。

## 11. non-last write-response turnover 性能合同

本节是 repair-v3 之后的有界性能变换；它只取代第 3、5.3、10.3、10.6 节中
“每个成功 write response 都回到 `ELEMENT_PREP`”及“production arithmetic/address
critical path 不变”的旧描述。repair-v2/v3 的 descriptor、owner、timeout、drain、
busy-start、raw-bit arithmetic 与 error-priority 合同继续有效。

### 11.1 状态、资源与 fail-closed 边界

- 第一元素仍经 `PREFLIGHT -> ELEMENT_PREP -> SRC0_REQ`。在整个 non-last
  `ST_WRITE_WAIT` 等待期，selector 只读取 registered state、flat/coords、shape/stride
  与 total；不得读取 response/request `valid`、`ready` 或 `fire`。
- i0→i1→i2→i3 successor/carry 只能有一份，current/next 选择后复用唯一 runtime
  modulo/stride/multiply/address-valid 网络；不得为 lookahead 复制第二套地址生成器。
- 优先级保持 `protocol fault > response error > command timeout > phase timeout >
  normal response`。只有 normal successful non-last response 才能清除旧 GMEM owner、
  记入刚完成的 `elements_done`、提交 next flat/coords 与 src0/src1/dst payload，并直接
  进入 `ST_SRC0_REQ`。
- current flat/coords、`next_flat > current_flat`、last 的 `next_flat==total`、non-last
  的真实 next selection 与 selected address-valid 全部 fail-closed。next invalid 时已经
  成功的 current element 仍计数且旧 owner 被回收，但 walker/payload 不得提交，随后以
  `ERR_INTERNAL_STATE` 结束。
- last response 只允许进入 `ST_DONE`，不得推进 walker 或覆盖 request payload。write
  response 同拍不得产生 next read request；最早在下一拍 registered `ST_SRC0_REQ`
  才可 request fire，故 GMEM accepted owner 上限继续为 1。

### 11.2 定向与系统 A/B 证据

`tb_f32_tensor_alu.sv` 的 `[2,2,2,2]`、16-element procedural oracle 冻结：

- 每条命令 `ELEMENT_PREP=1`、non-last turnover=`15`；每次 C0 的 next
  flat/四维坐标/src0/src1/dst 精确匹配软件 oracle；
- C0 `gmem_req_valid_o=0`，C1 直接为 `ST_SRC0_REQ` 且 resident payload 匹配 next
  element；last 不推进、不覆盖；write error、timeout、drain、reset 均不提交 lookahead；
- 正常 transaction 仍保持 owner max=1、16 elements、48 requests（32 read/16 write）
  与 raw F32 result exact-match。fresh 14-source Verilator `-O3` run PASS，观测为
  `prep=1/turnover=15`。

固定 RV64 direct-system workload 含 3 条合法 16-element macro，因此 executable
oracle 以 `3*(16-1)=45` 冻结精确节省。相对同源 retained baseline：

| 指标 | before | after |
|---|---:|---:|
| total cycles | 5337 | 5292 |
| pre-recovery / recovery | 1218 / 4119 | 1218 / 4074 |
| 3 macro issue→terminal 总和 | 557 | 512 |
| system serialize / clock-gated gap | 744 / 550 | 699 / 505 |

stats-off 与 stats-on 均在 5292 cycles PASS；ordered command/terminal/commit、
`cfg=91/91/0/91`、error=`1/1/0/1`、`issued=terminal=completion=95`、
`alloc_direct_issue=4`、active attribution `194`、GMEM `144=96 read+48 write` 逐项不变。
45 拍全部落入 macro critical interval 与 system serial region，因此保留该变换；
`45/5337≈0.843%` 只表示该固定 workload 的 cycle 改善。

### 11.3 identity 与 physical GAP

在仅完成 non-last turnover、尚未加入 §12 child-response direct write 的历史阶段，
production RTL/TB SHA-256 分别为
`8eecbba8a29b3482e3af7e12289fdd207829341e3323efacd8fe146569b645ca` 与
`2d45a0899cfd08ebd91d985ba8846f55bff37761ef1a6d15687924b506596ad6`。
若干历史 Qwen identity runner 仍硬编码旧 RTL hash
`641476144342ca5fbe3e3ea220ae97e50790920b14d6b40fc34f33e38fa33577`；它们是
repair-v3 历史证据，尚未针对本变换重新认证。未更新这些 runner、未运行其完整
identity/mutation 流程前，不得声称其当前 PASS。

新组合链可能是 carry→current/next mux→variable modulo→128-bit multiply/add→
address-valid/payload D，并在 `WRITE_WAIT` 投机翻转。源码只证明单份 successor 与
runtime 地址网，不证明综合器不会复制逻辑。本阶段未运行综合、STA、面积或功耗评估，
所以频率、面积、动态功耗及总体 PPA 全部保留为明确 GAP。

## 12. child-response→GMEM shadow-write direct 性能合同

本节是在 §11 turnover 之上的第二个有界性能变换，只消除 normal matching child
response 与 shadow write request 之间的注册气泡，并取代 §3、§5.3、§6 中所有 child
response 都先经过 registered `WRITE_REQ` 边界的历史描述。它不增加 state、queue、
owner credit 或 speculative scope；§2 的 reset/fault/watchdog/drain、shadow-only
commit、raw-bit arithmetic 与 §11 的 next-element turnover 合同继续有效。

### 12.1 原子 owner handoff、fallback 与 fail-closed 边界

- `child_result_bits_w` 与 registered `current_dst_addr_q` 只经过一份
  result-shift/address/strobe/legality 网络，形成 direct 与 fallback 共用的
  `child_write_{addr,data,strb}`；禁止为 ready-high 路径复制第二份 write payload。
- normal `child_rsp_fire` 且 payload legal 时，组合 direct offer 的
  `gmem_req_valid_o/write_o/addr_o/wdata_o/wstrb_o` 与 `gmem_req_ready_i` 无关。
  ready 只参与 `gmem_req_fire_w`：ready-high 在同一边沿把 edge-old child owner 清零、
  把 GMEM owner 置一并进入 `ST_WRITE_WAIT`，构成原子 child→GMEM owner handoff；
  accepted owner 总数始终不超过 1。
- ready-low 不延迟或重放 child response。该边沿清除 child owner、保持 GMEM owner
  为零，同时把同一 direct payload 捕获到既有 GMEM request q 并进入
  `ST_WRITE_REQ`；随后 `valid&&!ready` 期间 payload 逐 bit 保持，唯一 fire 后才进入
  `ST_WRITE_WAIT`。
- 控制优先级固定为
  `reset > protocol/owner fault > command timeout > phase timeout > normal response`。
  fault/deadline 同拍即使 child response 的 valid/ready 同时为真，也不得形成 direct
  offer、GMEM fire 或新 owner；timeout 仍按是否已消费旧 child owner选择
  `ERROR`/`DRAIN`。
- direct 与 registered 两条路径都执行 lane/address/strobe legality。illegal direct
  payload 必须抑制 GMEM valid/fire 与 owner birth；response payload 可以同沿捕获，
  但下一拍只能由 `ST_WRITE_REQ` 的 registered legality check 以
  `ERR_INTERNAL_STATE` fail-closed，禁止发出 partial/错 lane shadow write。
- GMEM write beat、`writes_accepted` 与 owner credit 只在 actual request fire 增加；
  child response 与 sticky flags仍只在唯一 matching child response 边沿计数/提交，
  direct 与 fallback 不得形成 duplicate accounting。

### 12.2 focused final3 与系统 A/B 证据

`tb_f32_tensor_alu.sv` 的 fresh 14-source Verilator `-O3` final3 run PASS，并冻结：

- 16-element `[2,2,2,2]` transaction 的 16 次 child response 全部在 GMEM
  ready-high 时 direct fire，`direct-elements=16`；
- 独立 ready-low case 消费 child response、捕获并持有同一 payload，随后恰好一次
  registered write fire，`fallback=1`；
- direct/fallback 的 ready probe、protocol fault、command deadline、held payload、
  counters、raw result 与 clean terminal 均通过，`max_owner=1`；最终 marker 为
  `child-write-direct=1 direct-elements=16 fallback=1`。

固定 RV64 direct-system workload 含 3 条合法 16-element macro，因此本变换在 §11
基础上再精确节省 `3*16=48` 拍；从 5337-cycle retained baseline 起，累计节省为
`3*(16-1) + 3*16 = 45 + 48 = 93`：

| 指标 | §11 turnover-only | + child direct | 相对 5337 baseline |
|---|---:|---:|---:|
| total cycles | 5292 | 5244 | `5337→5244`（-93） |
| pre-recovery / recovery | 1218 / 4074 | 1218 / 4026 | `1218 / 4119→1218 / 4026` |
| 3 macro issue→terminal 总和 | 512 | 464 | `557→464`（-93） |
| system serialize / clock-gated gap | 699 / 505 | 651 / 457 | `744 / 550→651 / 457` |

stats-off `rv64-direct-npu-system-20260831T235327-690143` 与 stats-on
`rv64-direct-npu-system-20260831T235327-690173` 均在 5244 cycles PASS；CONFIG/error
timing、95 条 ordered command/terminal/completion、`alloc_direct_issue=4`、active
attribution `194`、GMEM `144=96 read+48 write` 与所有 raw F32 结果不变。

`npc_tensor_npu_system_tb.cpp` 以累计公式冻结 executable oracle：

```text
kF32TurnoverSavedCycles         = 3 * (16 - 1) = 45
kF32ChildWriteDirectSavedCycles = 3 * 16       = 48
kF32SavedCycles                 = 45 + 48      = 93

macro issue->terminal = 557  - kF32SavedCycles = 464
recovery cycles        = 4119 - kF32SavedCycles = 4026
total cycles           = 5337 - kF32SavedCycles = 5244
system serialize       = 744  - kF32SavedCycles = 651
clock-gated gap        = 550  - kF32SavedCycles = 457
```

### 12.3 5244 性能阶段 identity、历史 runner 与 physical GAP

加入 child-response direct write 并取得 5244-cycle A/B 时，该性能阶段的 production
RTL/TB snapshot SHA-256 分别为
`b306baea35779b08877b7619dd0320b0ce61b056eb57fe926ab04bded99685dc` 与
`b1951f9d9a945d46dec65c29231f16d9f4a08705a206d3b2a5193d1292aa2e3d`。
§11.3 的两个 hash 只绑定 turnover-only 历史阶段；本节两个 hash 也只绑定 5244
性能快照，不阻止后续 correctness 修复以新 hash 和新证据追加认证记录。

历史 8 个 Qwen runner、9 处引用仍绑定 repair-v3 旧 RTL hash
`641476144342ca5fbe3e3ea220ae97e50790920b14d6b40fc34f33e38fa33577`；本变换没有
重新运行其完整 identity/mutation 流程，因此该 GAP 保持不变，不得借当前 focused
或 direct-system PASS 声称这些历史 runner 已重新认证。

expanded Verilator/lint 未出现由本变换引入的新 SCC，ready 也不反馈到 valid/payload；
但仍新增两条未经物理验证的组合锥：

```text
child result/current-dst -> shift/strobe/legality -> GMEM output mux
child response + protocol/timeout gates          -> direct valid/fire control
```

这些路径的 delay、fanout、布线、投机翻转及综合器是否复制 logic 均未由源码或功能
A/B 证明。本阶段未运行综合、STA、面积或功耗评估，因此 frequency、area、dynamic
power 与总体 PPA 继续保留为明确 physical GAP。

## 13. owned-response collision 修复与 SRC1→child direct 性能合同

本节追加在 §12 的 5244-cycle 性能快照之后：先修复 owned response 与另一接口
unsolicited response 同拍时可能丢失 owner credit 的 correctness 缺陷，再在该修复上
消除 normal successful `ST_SRC1_WAIT` response 与 child request 之间的注册气泡。
§11/§12 的 turnover、child-response direct write、descriptor、raw-bit arithmetic、
watchdog、drain 与 shadow-only commit 合同继续有效；§11/§12 的 hash 和日志只作为各自
历史快照保留，不由本节覆盖。

### 13.1 protocol-fault owned response hold-to-DRAIN

- `protocol_fault_w` 必须组合阻断 `gmem_rsp_ready_o` 与 `child_rsp_ready_w`。即使当前
  matching GMEM/child owner 已经持有 response，若同拍另一接口出现 unsolicited
  response，fault edge 上两路 response 的 ready/fire 都必须为 0；同拍也不得形成
  child/GMEM direct offer、request fire 或新 owner。
- fault edge 不消费 matching response、不清 `gmem_outstanding_q`/
  `child_outstanding_q`，而是把 edge-old owner 记入 `drain_owner_q` 并进入
  `ST_DRAIN`。因此原 owner credit 与遵守 valid/ready 的 held response 均被保留，
  不会出现“response 已消费、owner 仍为 1、DRAIN 永久等待”的丢 credit 状态。
- offending wrong-owner valid 撤销后，下一次 matching DRAIN handshake 才清除该 owner，
  且恰好消费一次；wrong-owner response 永不获得 ready。response/counter/terminal
  accounting 不得重复，随后 clean retry 必须成功。持续保持非法 wrong-owner valid
  的环境本身已违反本接口合同，不由 bounded-progress 合同兜底。
- DRAIN 中的 late GMEM error 只允许把 `ERR_COMMAND_TIMEOUT` 或
  `ERR_STALL_TIMEOUT` timeout cause 提升为 `ERR_GMEM_RESPONSE`；若 retained cause 是
  `ERR_PROTOCOL` 或 `ERR_INTERNAL_STATE`，matching response 的 error bit 不得覆盖 final
  code。这样 global priority `protocol > GMEM response error > timeout` 在 DRAIN
  completion 后仍成立，而不只是在 collision fault edge 成立。
- focused fixture 对称覆盖“owned child response + unsolicited GMEM response”、
  “owned GMEM success response + unsolicited child response”与“owned GMEM error
  response + unsolicited child response”，并同时探测 protocol、command、phase cause；
  三例均冻结 fault-edge ready/fire=0、DRAIN owner/credit 保留、next-DRAIN exact-once
  consume，第三例还冻结 final code 保持 protocol，marker 为
  `protocol-owned-response-collision=3`。

### 13.2 successful SRC1 response→child request elastic handoff

- 本 direct 只适用于实际经过 `ST_SRC1_WAIT` 的 binary ADD/MUL/SUB。`OP_SCALE` 的 RHS
  来自 registered `op_params_q`，继续由 `SRC0_WAIT -> CHILD_REQ` 的既有边界发射，
  禁止误入 SRC1 direct；focused `opcode-coverage=f` 同时覆盖三条 direct opcode 与
  SCALE exclusion。
- 只有 normal successful matching `gmem_rsp_fire_w` 才产生
  `src1_child_direct_offer_w`。child request 的 valid、op、registered LHS 与 RHS payload
  都不得读取 `child_req_ready_w`；ready 只决定该 offer 是否在本拍 fire。
- RHS 先在唯一 raw selector 中选择 direct 的 `selected_gmem_word_w` 或 fallback 的
  registered `rhs_bits_q`，再进行 opcode transform。SUB 只能在 selector 之后翻转一次
  sign bit；不得在 capture 与 child input 两处重复变换。MUL/ADD 保持原 raw RHS，
  SCALE 仍走上述排除路径。
- ready-high 时，在同一边沿清 edge-old GMEM owner、建立 child owner、增加唯一
  `child_requests` credit 并进入 `ST_CHILD_WAIT`，构成原子 GMEM→child owner handoff；
  accepted owner 总数始终不超过 1。
- ready-low 时仍消费该唯一 GMEM response、清 GMEM owner，并把同一个 **raw** RHS
  捕获到 `rhs_bits_q` 后进入 `ST_CHILD_REQ`；随后 request valid/payload 在 backpressure
  期间保持，eventual fire 才建立 child owner并增加一次 request credit。direct 与
  fallback 送入 child 的 op/LHS/transformed-RHS 必须逐 bit 相同。
- reset 具有全局最高优先级；正常状态内优先级固定为
  `protocol fault > GMEM response error > command timeout > phase timeout > normal direct`。
  任何高优先级 cause 都必须抑制 direct offer/fire 与 child owner birth。reset 同拍还
  必须把 GMEM ready/fire、direct valid/fire 与 child request valid/fire 全部压为 0。
  raw F32 的任意 32-bit pattern 本身仍是合法 arithmetic payload；这里的 fail-closed
  指既有 owner/state/response/lane 合法性不得被 bypass，且 §12 的 illegal shadow-write
  payload 仍不得 request fire 或建立 GMEM owner。

### 13.3 focused 与 5196-cycle 系统 A/B

fresh focused Verilator build/run 分别记录在
`/tmp/f32-protocol-finalcode-20260901-root/build.log` 与
`/tmp/f32-protocol-finalcode-20260901-root/run.log`，终局为 PASS，并冻结以下 marker：

```text
child-write-direct=1 direct-elements=16 fallback=1
protocol-owned-response-collision=3
src1-child-direct=1 direct-elements=16 fallback=1 opcode-coverage=f
child-write-invalid=1 command-phase-priority=1
production-force-witness=17
gmem_drain=7
max_owner=1
PASS
```

其中 SRC1 ready-high 16-element case 每元素 direct 一次；独立 ready-low case 捕获同一
raw RHS、保持 request 并 eventual fire 一次。opcode mask `f` 覆盖 ADD/MUL/SUB 与
SCALE exclusion；response error、protocol fault、command/phase deadline、illegal
shadow-write payload、reset、owner/counter cardinality 与 clean retry 均保持 fail-closed。

固定 RV64 direct-system workload 含 3 条合法 16-element binary macro，因此本变换在
§12 的 5244 上再精确节省 `3*16=48` 拍。相对 5337 retained baseline，三项累计节省为
`3*(16-1) + 3*16 + 3*16 = 45 + 48 + 48 = 141`：

| 指标 | §12 child-write direct | + SRC1→child direct | 相对 5337 baseline |
|---|---:|---:|---:|
| total cycles | 5244 | 5196 | `5337→5196`（-141） |
| pre-recovery / recovery | 1218 / 4026 | 1218 / 3978 | `1218 / 4119→1218 / 3978` |
| 3 macro issue→terminal 总和 | 464 | 416 | `557→416`（-141） |
| system serialize / clock-gated gap | 651 / 457 | 603 / 409 | `744 / 550→603 / 409` |
| active serialize | 194 | 194 | 不变 |
| GMEM request（read/write） | 144（96/48） | 144（96/48） | 不变 |

stats-off
`/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T003236-699936/run.log`
与 stats-on
`/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T003236-699973/run.log`
均为 5196-cycle PASS；pre-recovery/recovery 为 `1218/3978`，macro critical 总和为
`416`。stats-on 精确观测 `issued=terminal=completion=95`、active serialize `194`、
system serialize `603`、clock-gated gap `409`；CONFIG/error timing、ordered
command/terminal/commit、`alloc_direct_issue=4`、GMEM `144=96 read+48 write` 与 raw
F32 功能结果不变。

`npc_tensor_npu_system_tb.cpp` 的 executable oracle 冻结为：

```text
kF32TurnoverSavedCycles         = 3 * (16 - 1) = 45
kF32ChildWriteDirectSavedCycles = 3 * 16       = 48
kF32Src1ChildDirectSavedCycles  = 3 * 16       = 48
kF32SavedCycles                 = 45 + 48 + 48 = 141

macro issue->terminal = 557  - kF32SavedCycles = 416
recovery cycles        = 4119 - kF32SavedCycles = 3978
total cycles           = 5337 - kF32SavedCycles = 5196
system serialize       = 744  - kF32SavedCycles = 603
clock-gated gap        = 550  - kF32SavedCycles = 409
```

### 13.4 当前 identity 与 physical GAP

同时包含 §13.1 correctness repair 与 §13.2 direct handoff 的当前稳定快照 SHA-256 为：

```text
TensorNpuF32TensorAlu.v       eebe42af020eb9032bc3a7e917194f022f691819e34722d4467c8efca8f6fa62
tb_f32_tensor_alu.sv          ebced149d26cf57ab61bd7bb01a15e3713f992a46edb61b0ea30820ae7d93b84
npc_tensor_npu_system_tb.cpp  01a332f97f485bdd3d9b3743d0f0cdd95d34a9fa456f07ab3715512d0f26d370
```

§11 turnover-only、§12 5244-cycle 的 hashes/logs 继续分别绑定各自 historical
snapshot，不能用本节新 identity 覆盖。§12.3 所列历史 8 个 Qwen runner、9 处旧 hash
引用也没有重新运行或认证，其 identity GAP 原样保留。

在 §13.1 final-code repair 之前，SRC1 direct 的中间 RTL/TB identity
`d6ef10431cec6e649fc4997ac8a214a98eca7774900b0a4abd56f99696409efe` /
`5d750fc3355d589ab9ded2b2323932019f5ec047a22dc22525f4ba7d48c8312d`，以及 stats-off/on
`rv64-direct-npu-system-20260901T002325-697284` /
`rv64-direct-npu-system-20260901T002325-697237` 也只作为 pre-final-code historical
snapshot 保留；它们不认证三重 collision 或 protocol final-code 保持，不得替代上述
fresh focused 与 `003236` 双系统证据。

新增的主要物理组合锥为：

```text
GMEM rsp data/valid -> lane/raw-RHS mux -> optional SUB sign transform
                    -> fp_ext/FMA front-end capture
```

固定 workload 的 cycle 改善是 `48/5244≈0.915%`；若只比较执行时间，新的 clock period
最多只能恶化到 `5244/5196-1≈0.924%` 才仍有净收益。该 break-even 只是算术边界，
不是 timing 证据。本阶段没有运行综合、STA、面积或功耗评估，因此该长路径的 delay、
fanout、布线、投机翻转、frequency 与总体 PPA 全部保持明确 physical GAP；不得把
5196-cycle 功能 A/B 宣称为物理提速或 PPA promotion。

## 14. registered 双源 64-bit pair-beat reuse successor

本节是 §13 的后继阶段，不回写或覆盖 §13 冻结的 5196-cycle predecessor、其
`eebe42...` / `ebced...` identity、日志或更早历史证据。这里冻结的是 command-local、
registered、pair-only reuse；它不是独立的 per-source read suppression，也不是通用
cache-coherence 实现。

### 14.1 最小 RTL 合同、命中语义与优先级

实现只增加两个 command-local single-entry source cache：
`src0_beat_valid_q/src0_beat_tag_q[60:0]/src0_beat_data_q[63:0]` 与对应的 src1 三个 q。
每个 entry 恰好包含 valid、完整 aligned-beat tag `addr[63:3]` 与 64-bit raw response
data；因此新增 registered state 为 `2 * (1 + 61 + 64) = 252` bit。命中组合量为
`src0_beat_reuse_hit_w`、`src1_beat_reuse_hit_w`、二者 AND 后的
`gmem_pair_reuse_hit_w`，lane data 为两个 `src*_beat_reuse_word_w`。src0 与 src1 各自比较下一元素的
`selected_src0_addr_w[63:3]` / `selected_src1_addr_w[63:3]`，不能截短 tag，也不能以
index、低地址片段、当前地址或另一 source 的 tag 代替。地址计算、四维 coordinate、
modulo-broadcast 与任意合法 stride 仍由既有 selected-address 网络唯一决定；cache 只是
该网络结果的 consumer，不修改 selected address。

entry 只允许由 matching owner 的 clean successful source read response 填充：src0 仅在
正常 `SRC0_WAIT`，src1 仅在正常 `SRC1_WAIT`。response error、unsolicited/protocol fault、
timeout、reset/abort 或 `DRAIN` 中消费的 response 都不得填充或恢复 valid。新命令
admission 清空两个 valid；busy `start_i` 仍按既有合同忽略，不能刷新、继承或污染
resident command 的 cache。所有 reuse 还必须位于 descriptor/preflight 成功之后，且下一
地址继续通过既有 range、alignment、footprint 与 overflow 检查。

唯一 reuse 点是 successful `WRITE_WAIT` turnover 的下一元素，并且必须同时满足：当前
write response 正常、当前元素不是 last、下一元素地址合法、opcode 是需要两个 source 的
binary `ADD/MUL/SUB`、两个 entry 均 valid，且两个完整 tag 分别 exact-match 下一 src0/src1
aligned beat。此时才把两个 cache 的 raw lane 写入既有 operand q，进入既有 `CHILD_REQ`，并
令 `gmem_pair_reuse_elements_o` 加一；一个 hit element 恰好跳过两次 8B source read。任一
source 单 hit 都必须完整 fallback，按正常顺序重新读取并重新填充两个 source，不能消费
单个 cached operand、不能只省一次读取，也不能递增 pair counter。因而本实现不得使用
“modulo-broadcast 64→48”或“transpose-like 32→10”这类 per-source-independent 预算；在
pair-only 精确语义下，相应定向序列分别是 `64→64`（0 pair hit）与 `32→16`（8 pair hit）。

lane 只能由各自下一地址的 bit 2 选择：`addr[2]==0` 取 raw data `[31:0]`，`addr[2]==1`
取 `[63:32]`。这允许 upper/lower F32 共享同一 aligned beat，但不同完整 tag 绝不能 false
hit。src0 与 src1 可以 read-read alias，甚至 exact same beat；两个 entry 仍独立匹配并选
lane。`SUB` cache 中始终保存 raw RHS，既有 operand/child mux 只在统一位置翻转一次 sign；
cache fill 或 hit mux 不得预翻转，避免 direct 与 registered 路径双重处理。`SCALE` 没有
src1，必须永不命中且 pair counter 保持 0。

全局事件优先级继续冻结为：

```text
reset > protocol/owner fault > GMEM response error
      > command timeout > phase timeout > normal progress
```

在 normal successful `WRITE_WAIT` response 内，判定顺序冻结为：

```text
current-result/address invalid > last element > next-address invalid
                               > exact dual hit > full two-source fallback
```

因此 last 直接完成，不能投机计算 next；next-invalid 必须在 tag hit 之前 fail-closed；error、
timeout、protocol 与 drain 路径不能观察或使用 cache。任何未知/不完整 valid、tag、lane 或
地址合法性都不能当作 hit。preflight、broadcast、stride、upper/lower lane、跨 tag、src alias、
next-invalid 与 last 的上述规则共同适用，不能以“数据碰巧相同”放宽 exact-address identity。

pair hit 不增加 FSM state，不新建 GMEM/child owner，也不让 cache/tag/data mux 依赖
`gmem_req_ready_i` 或 `child_req_ready_i`。turnover edge 只注册既有 operand q，随后仍由
`CHILD_REQ` 的 held-valid handshake 建立唯一 child credit；valid/payload 与 ready 解耦，
不存在新 ready→valid/data dependency 或 SCC。任一周期全模块 accepted owner 总数仍必须
`<=1`，focused oracle 固定 `max_owner=1`。

### 14.2 command-scoped source read lease

registered reuse 的 correctness 前提不是“uncached”这个标签，而是一份正式的 command-scoped
source read lease。lease 从 command admission（`start_i && ready_o`）持续到唯一 terminal、
reset 或 abort 完成；在此期间，preflight 覆盖的全部 aligned 8B source footprint 必须同时：

- 内容稳定且重复读取幂等；
- 属于 nonvolatile、非 MMIO/side-effecting aperture；
- 不存在 CPU、DMA、device、另一 NPU command 或任何 alias mapping 的 writer；
- 地址翻译、权限与 alias identity 不得在 command 中途改变。

系统可以用独占 source aperture，或能证明上述性质的 coherent ownership/read lease 来满足
合同。若无法取得 lease，必须在潜在冲突写发生前可靠 invalidate 对应 reuse entry，或者在整条
命令禁用 reuse；仅靠软件约定、普通 uncached 映射或“通常不会写”不成立。src0 与 src1 允许
互相 alias，因为二者都在同一 read lease 内；dst 仍须与所有 source aligned-beat footprint
disjoint，不能用 lease 放宽 preflight 的 source/destination 隔离。

当前 direct-system wrapper 的独占 uncached aperture 足以承担已测 slice 的 lease；通用 CPU
cache、DMA/device writer、IOMMU alias 与多 NPU command coherence/enforcement 仍是系统 GAP，
不能由本节 focused PASS 外推关闭。

### 14.3 pair counter 与 Adapter 独立 byte accounting

`gmem_pair_reuse_elements_o` 是 64-bit command-local raw counter：只在 §14.1 的 exact dual
hit element 上递增一次，reset、新命令与 abort 按 command lifetime 清理；它不等于 read beat
counter，也不能从期望值反推实际 response。Adapter 必须独立按 clean successful read response
累计 actual bytes，每个实际 64-bit source response 加 8B，error、drain 与未接受 response 不得
计入成功字节。

成功 terminal 的 expected read bytes 使用扩宽中间量计算：

```text
binary logical baseline = total_elements << 4   // 两个 source，每元素逻辑 16B
SCALE  logical baseline = total_elements << 3   // 一个 source，每元素逻辑 8B
saved                  = binary ? (gmem_pair_reuse_elements << 4) : 0
expected               = logical baseline - saved
```

每个 pair-hit 元素因此精确减少 `2 * 8B = 16B` expected 与 actual source traffic。
baseline、shift、subtract 和 range check 必须保留足够宽度（当前合同为 68-bit 中间量），不能在
64-bit 截断后比较。以下任一条件都必须 fail-closed 为 accounting/protocol terminal error：
`SCALE`/无 src1 却出现非零 pair count、pair count 超过 total elements、saved 大于 logical
baseline（underflow）、或 expected 的扩宽高位非零/无法表示。fault 时不得用 wraparound expected
伪造 PASS；实现可输出全 1 sentinel 供诊断。actual response bytes 始终来自独立计数器，不能用
`baseline-(count<<4)` 合成 actual。

production runner 的 active oracle 同样必须升级：generic P00–P18 不能继续对所有 binary
profile 静态使用 `16*N` expected，也不能把 P00 的 `128B` 常量硬编码后外推。current oracle
必须独立读取每个 profile 的 source address sequence，以与 RTL 相同的 pair-only exact full-tag
规则做 cache-aware constexpr 推导；任一 single hit 都完整 fallback 并更新两 entry。该 oracle
必须与 DUT raw counter/actual-response counter 独立实现，避免共同错误自洽；sealed historical
runner、log 与 hash 不得为迁就 current oracle 而静默改写。

另有一个未闭合的 metadata identity GAP：
`scripts/qwen_f32_alu_profiles.py` 中现有 `read_bytes` 仍按旧 logical baseline
binary `16*N` / SCALE `8*N` 生成，并参与 canonical manifest hash。若该字段本意是 semantic
logical traffic，必须显式重命名或在 schema/consumer 中澄清其不是 raw completion physical
bytes；若本意是 raw completion physical bytes，则 pair-reuse successor 的 profile/manifest
requalification 尚未完成，旧 manifest 不能认证新 RTL 的 physical read count。本阶段不改该
script、manifest 或其 sealed hash，也不以 active system oracle 倒推其新含义。

旧 `QWEN_F32_ALU_OWNER_RTL_CONTRACT` 的 deadline/error ordering 还可能与本节冻结的
`protocol > GMEM response error > command timeout > phase timeout > normal` 冲突。它作为
historical contract GAP 保留；在逐条对齐并重新认证之前，不能静默改写旧合同，也不能让旧
deadline 文字覆盖当前 matching response-error 的优先级。

### 14.4 non-vacuous focused matrix 与 final evidence

focused TB 必须至少覆盖以下非真空矩阵，并在 raw result、traffic 与 owner 三个维度同时检查：

- 连续 16 个 binary 元素，使 src0 与 src1 各自都呈现 8 次 cold/fallback miss、8 次 exact
  same-tag next-element hit；必须得到 pair hit elements `8`、miss elements `8`、实际 source
  reads `16`，而不是只检查最终数值；
- 混合 dual-hit / src0-only-hit / src1-only-hit / dual-miss，证明两个 single-hit 分支都完整重读
  两个 source 且不增加 counter；
- upper/lower lane、完整 tag 差异和故意 low-bit/tag collision 的 false-hit oracle，证明 lane
  由 next `addr[2]` 选且完整 `[63:3]` tag 不 alias；
- reset 后 stale entry、error 后 clean retry、timeout/protocol→DRAIN 后 retry，证明 command epoch
  不继承 cache；matching response-error 不能 fill；
- `ADD/MUL/SUB` raw-bit result，特别是 cached SUB RHS 只翻 sign 一次；`SCALE` counter 必须为0；
- hit turnover backpressure、owned response collision 与 direct/fallback owner accounting，始终
  `max_owner=1`，terminal/response/counter 恰好一次。

当前 final focused evidence 冻结为：

```text
/tmp/f32-beat-cache-20260901-final/build.log
/tmp/f32-beat-cache-20260901-final/run.log

gmem-pair-reuse=1 hit-elements=8 miss-elements=8
physical-reads=16 tag-oracle=1
protocol-owned-response-collision=3
max_owner=1
PASS
```

对应 final snapshot SHA-256：

```text
TensorNpuF32TensorAlu.v  389b276ac1c2f59e56639ed6f5dbed8afd2803c5f3d80522dcc5df8d6b447e7d
tb_f32_tensor_alu.sv     a9fc495fb34c4faaf1fc5287cd58e58f0e910bd3819ba1d19f23b62f3e69eaf6
```

旧 5196 executable oracle 的只读 raw A/B 首先只因 cycle expectation 尚未更新而得到预期
失败：actual `5124`、macro `344`、recovery `3906`、GMEM req/rsp `96`（read `48`、
write `48`）；raw 功能结果与全部 95 个 ordered terminal 没有失败。更新 current executable
oracle 后，下列 stats-off / stats-on fresh run 均以 exact `5124` PASS：

```text
/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T005521-705668/run.log
/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T005521-705618/run.log
```

两者共同冻结 `pre=1218`、`recovery=3906`、`macro=344`、GMEM
`96=48 read+48 write`；stats-on 另冻结 `active=194`、`system serialize=531`、
`clock-gated gap=337`。每次 macro completion 为 read `128B`、write `64B`、elements `16`。
三个 macro 各有 8 个 pair-hit element；每个 hit 跳过两次 8B read，并相对完整两源读取路径
共省 3 cycles，因此新 beat 项为 `3 * 8 * 3 = 72` cycles：

```text
predecessor: 5196 -> successor: 5124 = -72
baseline:    5337 -> successor: 5124 = -213
saved total: 45 turnover + 48 child-write direct + 48 SRC1 direct + 72 pair reuse
macro:       416 -> 344
recovery:   3978 -> 3906
serialize:   603 -> 531
gap:         409 -> 337
GMEM: 144 = 96 read + 48 write -> 96 = 48 read + 48 write
```

### 14.5 identity、PPA/STA GAP 与历史证据边界

本阶段新增的主要物理对象是 252-bit cache state，以及
`next selected address -> full-tag compare -> lane/cache mux -> registered operand q` 组合锥。
pair hit 先写 operand q、下一状态才请求 child，因此没有新增 GMEM response→FPU 的组合路径，
也没有新增 ready feedback 或 SCC；这只是一项 RTL topology/correctness 陈述，不是 timing
closure。当前阶段没有运行综合、STA、面积或功耗评估，不能声称 frequency、area、energy 或
总体 PPA 收益。

固定 workload 的 cycle break-even clock-period degradation 为
`5196/5124 - 1 ≈ 1.405%`（而 cycle reduction 相对 5196 为约 `1.386%`）；它只是算术边界，
不是实测物理收益。252-bit state 的 clock/reset/fanout、两个 61-bit compare、lane mux、
selected-address fanout 与 operand-q setup 仍须由后续 synthesis/STA/power 关闭。

§13 的 5196 predecessor、§12/§11 以及所有更早日志与 hash 均继续作为 sealed historical
evidence 保留，不能静默改写为 5124 或用当前 identity 倒认证。历史 Qwen identity GAP 仍为
8 个 runner / 9 处旧 hash reference；本节没有重跑或重新认证它们。current active raw oracle
可以显式升级到 5124 以及新的 profile/address-sequence expected，但 sealed historical oracle、
日志与 snapshot 必须继续按原值、原身份可追溯；focused/system PASS 也不外推为 Qwen、综合、
STA 或 PPA PASS。

## 15. registered prepared pair-hit → child elastic direct successor

本节是 §14 的后继阶段，只冻结在 5124-cycle pair-beat reuse 上继续消除一个已证明气泡的
current implementation；§14 的 RTL/TB identity、日志、5124-cycle system oracle 与更早
历史证据继续 sealed 保留，不能用本节的新 hash 或 5100-cycle 结果倒认证。物理 source read
次数、pair-hit 语义、command-scoped read lease、Adapter accounting 与 P00–P18 active runner
oracle 均不改变。

### 15.1 prepare、commit 与最小状态合同

实现只新增一个 command-local bit `pair_reuse_prepared_q`，不新增 64-bit operand payload
register；下一元素的 raw LHS/RHS 继续复用既有 `lhs_bits_q/rhs_bits_q`。唯一 4D
coordinate/modulo/stride/address 网络在 `CHILD_WAIT` 与 `WRITE_WAIT` 间共享：前者以
`select_pair_prepare_element_w` 选择 successor，后者以 `select_next_element_w` 选择同一个
successor。两种选择都要求 non-last、element/address valid、binary op、两个 cache valid，且
src0/src1 各自完整 `addr[63:3]` tag exact-match；prepare witness 与原有 WRITE_WAIT live-hit
commit witness 保持为两个状态互斥的组合量。

只有 clean matching `CHILD_WAIT` response fire 才能 prepare，并且必须同时满足：没有 reset、
protocol fault、command timeout 或 phase timeout，当前 walker integrity 有效，child write
payload 有效，下一元素为 exact dual hit。该边沿先由 child response 的 registered result形成
当前元素 write payload，同时把下一元素 cache raw lane 写入既有 operand q，并置
`pair_reuse_prepared_q`。nonblocking 时序保证当前 child result 不会被新 operands 污染；从该
边沿到 write response 之间，walker、descriptor、opcode 与 cache state 均不变，所以 prepared
bit 与稍后的 WRITE_WAIT successor 是同一元素。若 prepare 不成立，bit 必须清零。

clean write response 的 normal commit 顺序冻结为：

```text
current-result/address invalid > last > next-address invalid
                               > registered prepared hit
                               > live exact dual-hit fallback
                               > full two-source read fallback
```

保留 live exact-hit fallback 是 fail-safe：若 candidate 没有 prepare，但 WRITE_WAIT 的同一完整
tag oracle 仍命中，就只走既有 registered `CHILD_REQ` reuse；它不能形成 direct。prepared 分支
无须把 live 4D address/tag/lane 网络重新串到 child valid，因为 descriptor/walker 稳定性已由
上述状态不变量和 commit 的 current/last/next-invalid 检查保证。

`pair_reuse_prepared_q` 必须在 reset、新命令 admission、protocol/owner fault、CHILD_WAIT
timeout、WRITE_REQ payload/owner fault 或 timeout、WRITE_WAIT response error/timeout/正常消费、
DRAIN、DONE、ERROR 与 default 全部清零。置位状态只能流向 WRITE_REQ/WRITE_WAIT；clean write
response进入 ready-low `CHILD_REQ` 前已经清零，所以 source/CHILD_REQ states 中不存在 prepared=1
的可达路径。busy start 继续忽略，不能刷新 resident command 的 prepared state。

### 15.2 elastic direct、owner 与 fault priority

在 `ST_WRITE_WAIT` 收到 clean matching write response 时，direct offer 只依赖 registered
`pair_reuse_prepared_q`、current integrity、non-last 以及 reset/protocol/error/deadline 的
fail-closed gates。child payload只来自既有 operand q；`child_req_ready_w` 仅控制 fire，不参与
offer、valid 或 payload。全局优先级保持：

```text
reset > protocol/owner fault > GMEM response error
      > command timeout > phase timeout > normal progress
```

- ready-high：同一个边沿消费唯一 GMEM write response、令 GMEM owner `1→0`，接受一次 child
  request、令 child owner `0→1`，`child_requests` 只加一次并直接进入 `CHILD_WAIT`；任一边沿
  前后 accepted owner 总数都不超过 1；
- ready-low：GMEM response仍必须消费一次，两个 owner 都变为 0，prepared bit清零并进入既有
  `CHILD_REQ`；q-based valid/payload跨 backpressure 保持，直到后续唯一 child request fire 才
  建立 owner 并增加 request counter；
- exact dual hit 在 successful write commit 处令 `gmem_pair_reuse_elements` 加一次，不因
  ready-low 再加，也不因 ready-high 提前或重复加；error、timeout、protocol、last、invalid 都
  不计 hit、不创建 successor child owner；
- cache 与 prepared operand 始终保存 raw RHS。pair direct 仍经过统一 child operand mux，SUB
  只在该处翻转一次 sign bit；ADD/MUL 不变，SCALE 永不进入 pair prepare。

`gmem_rsp_ready_o` 不依赖 child ready；child ready由 child 自身 registered inflight/response
状态决定。因而这里没有 child-ready→GMEM-ready feedback，也没有新增 ready SCC。与 §13 的
live GMEM-response→FPU 路径不同，本节的 successor address/tag/lane 工作在更早的 child-response
边沿落入 operand q；write-response direct path 不包含 4D modulo/stride/address/tag/cache-data
网络。

### 15.3 focused、独立终审与 5100-cycle system evidence

focused final 使用与 §14 相同的 14-source Verilator 集合，并增加非真空 prepared-direct
覆盖：连续 16 元素 ADD 得到 8 hit、8 miss、8 direct fire与16次 physical read；跨完整 tag
同 lane miss及 SUB raw/single-sign oracle；2元素 ready-low elastic fallback检查 offer/payload
与 ready 独立、write response只消费一次、payload保持、eventual child request恰好一次、last
不 prepare/direct；另外覆盖 held response上的 response error、command/phase deadline、rogue
child response protocol fault、current-integrity、reset与 ready toggle，及 invalid successor、
prepared write-response error、write-stall timeout→DRAIN 清除。

```text
/tmp/f32-pair-child-prepared-20260901-final/build.log
/tmp/f32-pair-child-prepared-20260901-final/run.log

production-force-witness=18
gmem-pair-reuse=1 hit-elements=8 miss-elements=8
pair-direct=8 physical-reads=16 tag-oracle=1 fallback=1
gmem reads=209 writes=115 responses=321
child_accept=121 child_response=120 child_reset_cancelled=1
max_owner=1
[NPU-F32-TENSOR-ALU][PASS]
```

final focused SHA-256：

```text
TensorNpuF32TensorAlu.v  e69fc4e517154638cd722781443be00907555b38068a5f04342f722439970ad1
tb_f32_tensor_alu.sv     899a7700d555fc5cdc68dc68c1b601216c1fb371537d622e36cf76b4fc4c38ad
build.log                cc3b940de4a98d8e66998f1b13408e20fb25f667e27a5a3d3c9c1168d6f311f6
run.log                  b1b6fcf08d048d3756303db5d9bcf16730b0b76901c74b8d7bf25b5a7121ded9
```

独立只读终审在上述两个 source hash 上逐项核对 candidate/commit identity、operand overwrite、
全部 clear path、ready-low counter/owner、last/invalid、SUB/full-tag 与 SCC，结论为
`RETAIN, must-fix=0`。终审指出的三个可选 TB 交叉加固点（WRITE_REQ 多拍 stall、prepared=true
的 command-timeout/protocol 跨边沿专测、自然不可达的 successor corruption 保持到 commit）
均不构成功能或协议 blocker；当前 RTL 不为这些冗余防御重新接入长组合路径。

更新 system oracle 前，保留旧 5124 expectation 的只读 raw A/B 只出现五个精确的 timing
failure（macro、serialize、gap、phase、total），实际功能、GMEM、completion 与 exact-once 全部
保持通过：

```text
npu/version_0820/tmp/rv64-direct-npu-system-20260901T013823-713146/run.log
SHA-256 65b35f0ab9fc3eb180d1145cd01ae1689aa7ade1bd93e7273e2fe4801c28e632
actual total=5100, macro=320, pre/recovery=1218/3882
GMEM req=96, issued/terminal/completion=95/95/95
```

current executable oracle 新增独立项
`kF32BeatPairChildDirectSavedCycles = 3*(16/2) = 24`，不从 DUT counter反推；更新后的
system C++ SHA-256 为
`bc108d6be399f3890cb1e4d3019f6ef28597623c5410956396cf6b19e751adc9`。fresh stats-off/on
均 exact PASS：

```text
stats-off:
npu/version_0820/tmp/rv64-direct-npu-system-20260901T013941-713687/run.log
SHA-256 8cd24341cbb6d84a6a36d65d767eade52f0f466e5014c1f79b7b0e89ceb28d1e

stats-on:
npu/version_0820/tmp/rv64-direct-npu-system-20260901T013941-713717/run.log
SHA-256 06202a64900ad31edd834c7a97a2b8b485a6f3e0679dabe41969dc700a15a74c
```

两次 run 共同冻结：`total=5100`、`pre/recovery=1218/3882`、`macro=320`、95 个
issued/terminal/completion、GMEM `96=48 read+48 write`；stats-on 另冻结 `active=194`、
`system serialize=507`、`clock-gated gap=313`。因此新增项与累计结果为：

```text
5124 -> 5100 = -24 = -(3 macros * 8 prepared hits * 1 cycle)
5337 -> 5100 = -237 = -(45 + 48 + 48 + 72 + 24)
macro:      344 -> 320
recovery:  3906 -> 3882
serialize:  531 -> 507
gap:        337 -> 313
GMEM and completion cardinality: unchanged
```

### 15.4 physical GAP 与历史边界

本节新增 registered state 只有一个 prepared bit，并复用两个既有 32-bit operand q；不增加
64-bit payload bank。准备边沿仍可能给既有 selected-address/cache→operand-q 路径增加状态
fanout与控制负载，write-response→child valid/data 的真实 delay、child front-end setup、clock
period、area、power 与 routing 都必须由后续 physical flow 证明。本阶段没有运行 synthesis、
STA、area 或 power，不能声称 frequency 或 PPA promotion。

相对直接 predecessor 的 cycle reduction 是 `24/5124≈0.468%`；固定 workload 只有在新 clock
period degradation 小于 `5124/5100-1≈0.471%` 时才有 execution-time 净收益。该 break-even
只是算术边界，不是 timing 证据。§14 的 5124、§13 的 5196 及更早 identity/log/oracle继续按
原值 sealed；P00 physical traffic未变化，所以 active profile-derived runner oracle仍有效，
但历史 Qwen manifest/read-bytes identity GAP、通用 coherence/lease enforcement、完整 Qwen、
综合、STA 与 PPA 均未被本节证据关闭。

## 16. admission-captured first-element preparation fold

本节是 §15 的 5100-cycle successor，只删除每条成功 F32 macro 首元素的一个纯准备状态拍。
§15 的 source hash、focused/system 日志、5100-cycle executable oracle 与所有更早 sealed evidence
继续按原身份保留，不能用本节的新 hash 或 5097-cycle 结果倒认证。pair cache、prepared-pair
direct、physical read、Adapter accounting、owner 数量与外部 GMEM/child endpoint 合同均不改变。

### 16.1 admission capture、preflight 与状态合同

首元素的四维坐标恒为全零，因此其三条地址只需要 `region_base + view_off`。在唯一
`start_fire_w` admission 边沿，RTL 用三条组合加法结果装入既有 payload q：

```text
src0: (src0_region_base_i + src0_view_off_i) >> 2
      -> gmem_req_addr_q + gmem_read_upper_q
src1: (src1_region_base_i + src1_view_off_i) >> 2
      -> current_src1_word_q
dst:   dst_region_base_i + dst_view_off_i
      -> current_dst_addr_q
```

没有新增 state bit 或 payload bank；source word显式为 62 bit，beat address与 lane由既有
`[61:1]` / `[0]` 拆分。64-bit input addition 的 wrap/truncation **不能**代替合法性证明：同一
admission 仍完整注册 descriptor，下一拍继续执行原有 128-bit absolute-start/end、region、shape、
stride、alignment、overlap 与 overflow preflight。只有该 preflight 已证明高位为零、地址在界、
格式合法且命令非 empty 时，这些投机 payload 才会通过 `ST_SRC0_REQ` 对外可见；任何 wrapped
candidate 在 preflight error 路径终止，不能发出 GMEM request。

successful non-empty `ST_PREFLIGHT` 现在写入 `total_elements_q` 并直接进入 `ST_SRC0_REQ`，不再
经过 `ST_ELEMENT_PREP`。preflight error仍优先于 command timeout，empty SCALE仍直接 DONE，
protocol/owner fault仍位于状态 case 之上；timeout、reset 与 terminal 语义均不变。
`ST_ELEMENT_PREP` 及其完整 selected-address/internal-state 防御仍保留，但正常合法 admission
不再可达它。busy `start_i` 不满足 `start_fire_w`，不能刷新 resident command payload；reset
仍清零相关 q。

capture 本身不创建 owner、不增加 request/read counter，也不驱动公开 valid。唯一 GMEM owner
仍只在后续实际 `gmem_req_valid_o && gmem_req_ready_i` fire 建立，ready-low 时既有
`ST_SRC0_REQ` payload保持与 watchdog 语义不变。故这一 fold 不需要同 endpoint response/request
credit swap，也不改变 accepted-owner `<=1` 与 exact-once 计数规则。

### 16.2 focused、raw A/B 与 5097-cycle system evidence

focused final 的 2×2×2×2 walker oracle在 admission 后的 `ST_PREFLIGHT` 直接检查首 payload为
src0 beat `0x1000`/upper lane、src1 word `0x800`、dst `0x4000`，同时要求 GMEM valid=0、owner=0；
下一状态必须是相同 payload 的首个 `ST_SRC0_REQ`，整条命令 `ST_ELEMENT_PREP` entry为0，后续15次
turnover、16次 direct write与16次 direct child保持原 cardinality。既有25项 preflight negative、
busy-start、reset、fault/DRAIN、deadline、pair hit/miss、ready-low fallback与 owner matrix继续全量通过：

```text
/tmp/f32-first-prep-fold-20260901-final/build.log
/tmp/f32-first-prep-fold-20260901-final/run.log

positive=31 scalar=20 broadcast=2 preflight=25
production-force-witness=18, busy-start-witness=1
first-prep-fold=1 prep=0 turnover=15
pair hit=8 miss=8 direct=8 physical-reads=16
gmem reads/writes/responses=209/115/321
child accept/response/cancelled=121/120/1, max_owner=1
[NPU-F32-TENSOR-ALU][PASS]
```

final focused/source SHA-256：

```text
TensorNpuF32TensorAlu.v  bb3312e3949b86960a7b86a349f14499f6ebdea92cb29887d0a6538506d46891
tb_f32_tensor_alu.sv     17a04c864c6c2f63033e5db5223a057491a4f7e7093568931cbbb9bd3a344758
build.log                4194545091fb55e9feb52849de9c0447783237d1d479d19e83c4e56b9ebc9dc7
run.log                  b83aeb9429ced486b1ebda20fa3b7f7acc47f3ea1f767b81927b6b7d828402fa
```

focused build只有 predecessor 已知的 third-party FPU warning classes：IMPORTSTAR 5、
UNUSEDPARAM 4、UNUSEDSIGNAL 12、UNOPTFLAT 4；没有 candidate-local WIDTHTRUNC，也没有新增 SCC。

独立只读终审在上述 RTL/TB hash 上得到 `RETAIN, must-fix=0`。终审核对了 64-bit admission
candidate 与 128-bit preflight 的 wrap/高位关系、start-fire唯一写入点、preflight/fault/deadline
优先级、SCALE/empty/busy/reset、公开 valid、owner/counter fire，以及旧/新 system ledger。
三个可选覆盖加固点是：另加 src1/dst 非零 view offset 的首地址 mutation、force 保留但正常不可达的
`ST_ELEMENT_PREP` 防御分支、逐 macro 打印1/1/1 savings；现有正确性不依赖这些冗余 witness，故均不
构成 blocker。

更新 executable oracle 前，以旧 5100 expectation运行新 RTL 的 raw A/B 恰好只出现 macro、
serialize、gap、phase、total 五个 timing failure；功能、GMEM、95个 ordered terminal、one-hot
attribution与 exact-once均保持：

```text
npu/version_0820/tmp/rv64-direct-npu-system-20260901T020254-717389/run.log
SHA-256 d166b0f29a2b174dbf93560e556c0fdaffca57706d53e91d732edd6d71676aeb
actual total=5097, macro=317, pre/recovery=1218/3879
active=194, serialize=504, gap=310, GMEM=96=(48 read+48 write)
```

current C++ oracle新增独立常量 `kF32FirstElementPrepFoldSavedCycles=3`；C++ SHA-256为
`61df1ac1a136b9ffab74181c64134204613aa1d32ababb7e89071ef94cb8bddd`。fresh stats-on/off
均 exact PASS：

```text
stats-on:
npu/version_0820/tmp/rv64-direct-npu-system-20260901T020406-717811/run.log
SHA-256 6115a1483d358ee38f4174c4e12f46e2e557998a53eae8500fcd62c280886ef7

stats-off:
npu/version_0820/tmp/rv64-direct-npu-system-20260901T020514-718607/run.log
SHA-256 11044e0a7ab89fa657b72e9b3e765ef4cdd3bb6501a0269a305f26ebc0e86003
```

两次 run共同冻结 `total=5097`、`pre/recovery=1218/3879`、`macro=317`、GMEM
`96=48 read+48 write` 与95个 issued/terminal/completion；stats-on另冻结 `active=194`、
`system serialize=504`、`clock-gated gap=310`。因此：

```text
5100 -> 5097 = -3 = -(3 successful macros * 1 first-prep cycle)
5337 -> 5097 = -240 = -(45 + 48 + 48 + 72 + 24 + 3)
macro:      320 -> 317
recovery:  3882 -> 3879
serialize:  507 -> 504
gap:        313 -> 310
pre-recovery, active serialize, GMEM and completion cardinality: unchanged
```

### 16.3 physical GAP 与本局部停止边界

本节不新增 register，只增加 command-admission D path上的三条 base+offset 计算及其 q fanout；真实
start-edge setup、clock period、area、power与routing仍需 physical flow证明。本阶段未运行
synthesis、STA、area或power，不能宣称频率或PPA promotion。相对 predecessor的周期降幅为
`3/5100≈0.058824%`，只有 clock-period degradation 小于
`5100/5097-1≈0.058858%` 才有固定 workload执行时间净收益；该值只是算术 break-even。

5100阶段的事件账本还可数出45个同一 GMEM endpoint 的 response→next-request边界，但当前
endpoint明确定义 `gmem_req_ready_i = stall_done && !gmem_rsp_valid_i`，所以 response有效时新
request不可能同拍 fire；保持合同的 direct offer固定收益为0。扩展为原子 credit swap将同时改变
engine、Adapter accounting与系统 endpoint，超出本局部 fold。另一个首 SRC0 preflight→GMEM
direct最多再省3拍，却会把128-bit preflight/valid锥接到公开 GMEM path，break-even同样仅约
0.059%；没有STA/PPA证据时不继续叠加。故5097是当前局部 registered、owner-safe优化的停止点，
下一阶段应转向更高收益的RV64 CPU pipeline/CPI热点，而不是继续拉长这一F32 admission路径。
