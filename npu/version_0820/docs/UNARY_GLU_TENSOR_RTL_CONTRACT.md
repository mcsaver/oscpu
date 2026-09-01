# Unary/GLU FP32 LANES=1 张量 RTL 合同

## 1. 状态、目标与非目标

本合同冻结 `TensorNpuUnaryGluTensorEngine` 的 Phase B、`LANES=1` reference transaction。模块在一个
时钟域内完成：command 接受、全 tensor 输入 capture 与 finite preflight、逐 element 驱动已经冻结的
`TensorNpuUnaryGluElement`、双 result bank 原子提交，以及按 command 接受顺序输出成功数据或一个空错误
completion。

Phase B 的核心性质是：

- 整个 tensor 的全部 external operand 已经 capture 且 finite preflight 成功之前，scalar request 必须为 0；
- 任一 external nonfinite、scalar error、scalar timeout 或 scalar protocol fault 都使整个 tensor fail closed；
- 失败 tensor 不输出任何 partial result，成功 tensor 只在全部 element 成功后才允许第一个 output beat；
- 一个旧 result bank 输出时，可以用另一个 result bank capture/compute 下一 tensor；
- 两个 result bank 都占用时，不接受第三个 command；
- 输出只服务 2-entry order FIFO 的 head，不能扫描任意 READY bank；
- `active_cycles` 由 command/terminal event timestamp 定义，不从固定 child latency推测 parent bubble。

本合同不证明以下范围：

- `LANES=4/8`，多 lane outstanding、lane 间 abort/quarantine 或 tail keep；
- LMEM/GMEM adapter、descriptor/DMA、cache/coherency；
- GGML backend、Qwen required-op dispatch、CPU fallback=0、shell 对话或 tokens/s；
- 综合、STA、PPA、面积、频率或功耗。

数值和 scalar 事务绑定：

- `docs/UNARY_GLU_F32_ORACLE_CONTRACT.md`；
- `docs/UNARY_GLU_ELEMENT_RTL_CONTRACT.md`；
- canonical vectors SHA-256
  `0bc73dba6d65597a78d8b0d9451e787334a5feb81ca677407a7cb4aa61d1c908`；
- `TensorNpuUnaryGluElement` 的 terminal `child_call_mask_o` 必须是本 element 中实际发生过的 primitive
  request handshake OR mask，而不是 opcode 的 planned mask。

## 2. 参数与 module 接口

首版固定 `MAX_ELEMS=6144`、长度/element index/count 宽度 13 bit、tag 宽度 8 bit。13 bit 必须同时表达
地址 `0..6143` 与完成计数 `6144`；禁止使用 12 bit completion count。

```verilog
module TensorNpuUnaryGluTensorEngine #(
    parameter integer MAX_ELEMS = 6144,
    parameter integer ELEMENT_TIMEOUT_CYCLES = 256
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        cmd_valid_i,
    output wire        cmd_ready_o,
    input  wire [2:0]  cmd_opcode_i,
    input  wire [12:0] cmd_length_i,
    input  wire [7:0]  cmd_tag_i,
    output wire        busy_o,

    input  wire        in_valid_i,
    output wire        in_ready_o,
    input  wire [31:0] in_src0_bits_i,
    input  wire [31:0] in_src1_bits_i,

    output wire        out_valid_o,
    input  wire        out_ready_i,
    output wire        out_sop_o,
    output wire        out_last_o,
    output wire        out_keep_o,
    output wire [31:0] out_result_bits_o,
    output wire [4:0]  out_flags_o,
    output wire [12:0] out_elem_index_o,

    output wire [7:0]  out_tag_o,
    output wire [2:0]  out_opcode_o,
    output wire [12:0] out_length_o,
    output wire        out_error_o,
    output wire [3:0]  out_error_code_o,
    output wire [63:0] out_active_cycles_o,

    output wire [12:0] out_capture_count_o,
    output wire [12:0] out_scalar_launch_count_o,
    output wire [12:0] out_scalar_terminal_count_o,
    output wire [12:0] out_success_result_count_o,
    output wire [4:0]  out_child_call_mask_o,
    output wire [12:0] out_exp_req_count_o,
    output wire [12:0] out_add_req_count_o,
    output wire [12:0] out_div_req_count_o,
    output wire [12:0] out_log_req_count_o,
    output wire [12:0] out_mul_req_count_o,
    output wire [12:0] out_bypass_count_o,
    output wire [4:0]  out_tensor_flags_or_o,
    output wire        out_fail_elem_valid_o,
    output wire [12:0] out_fail_elem_index_o
);
```

所有端口属于 `clk_i` 时钟域。`rst_i` 为同步、高有效；reset 周期 `cmd_ready_o=0`、`in_ready_o=0`、
`out_valid_o=0`。

Opcode 与 `TensorNpuUnaryGluElement` 相同：0 SIGMOID、1 SOFTPLUS、2 SILU、3 SWIGLU，4..7 unsupported。

Error code 原样保留 scalar code：

| code | 张量层含义 |
|---:|---|
| `4'd0` | OK |
| `4'd1` | unsupported opcode、非法 length、external operand nonfinite，或防御性 scalar code1 |
| `4'd2` | scalar child error/NV/DZ/NaN |
| `4'd3` | scalar timeout |
| `4'd4` | scalar owner/protocol/illegal-state fault |

`out_fail_elem_valid_o` 区分 code1 的来源：external nonfinite 时为 1 并给出第一个坏 element index；
unsupported opcode/非法 length 时为 0。scalar code2/3/4 时为 1 并给出失败 element index。

## 3. 输入边界与 liveness 假设

`cmd_length_i` 是核心唯一的输入边界。Phase B core 不使用 `in_last` 或 `in_keep`；每个
`in_valid_i && in_ready_o` 都表示恰好一个 element。合法 command 必须满足：

```text
1 <= cmd_length_i <= MAX_ELEMS
```

接口硬假设：

```text
cmd_fire(op,N,tag)
  -> eventually exactly N input handshakes
  -> producer在第N个handshake后结束该command的数据事务
  -> producer不把旧command的held payload遗留到下一command
```

短包/长包/TLAST 重同步由未来的 LMEM/stream adapter验证，不由本 core 猜测。若生产者违反上述 liveness，
resident source/bank/FIFO 只能通过 global reset 恢复。

`cmd_length_i==0` 或大于 `MAX_ELEMS`、opcode 4..7 在 `cmd_fire` 同 edge 形成一个有序
`READY_ERR` descriptor：active cycles=1，不获取 source owner，不接受输入，不启动 scalar。

对合法 command：

- `cmd_fire` 同 edge 预留一个 FREE result bank并把其 bank id push 到 order FIFO；
- source owner从 `cmd_fire` 保持到 tensor terminal；
- capture 期间每个 `in_fire` 写一次 `src0_mem[index]`/`src1_mem[index]`；data array不逐 entry reset；
- 所有 opcode检查 `src0[30:23] != 8'hff`；只有 SWIGLU 还检查 `src1[30:23] != 8'hff`；
- sticky `external_bad_seen` 保存第一个坏 index；
- 第 N 个 `in_fire` 必须用 `bad_next = bad_seen || bad_this` 决定 terminal/EXEC，禁止读取旧 NBA 值而误进 EXEC；
- 即使 first/middle element 已 nonfinite，也继续 capture 恰好 N 个 element，但 scalar launch count保持 0。

## 4. Scalar 调度与 terminal 聚合

模块独占一个：

```verilog
TensorNpuUnaryGluElement #(
    .COMMAND_TIMEOUT_CYCLES(ELEMENT_TIMEOUT_CYCLES)
) u_element (...);
```

LANES=1 parent不重复判 child fault，不设置第二个 compute timeout，也不提供 tensor abort端口。硬 liveness：

```text
scalar_req_fire -> eventually exactly one held scalar terminal
```

该性质由 scalar 自身的 timeout、ABORT_RESET 与 HOLD_RESPONSE 合同提供。parent在有 live scalar transaction 时
持续提供 `rsp_ready`；result bank已经在 `cmd_fire` 预留，因此 output backpressure不能反压 scalar terminal。

parent controller非法编码是独立的防御性终止事件。若非法编码发生时 scalar resident，parent必须在同一
active edge撤销所有正常 request/response credit并把 `u_element` 置于局部同步reset；随后至少保持一个完整的
`QUARANTINE` active edge，且在退出 quarantine 前 `cmd_ready_o=0`。有 source owner时旧 tensor只发布一次有序
empty code4 completion；无 owner时只清理 scalar、不得凭空发布completion。quarantine结束后无需global reset
即可接受并完成clean tensor，旧scalar response不得跨代驻留。

调度顺序：

```text
CAPTURE_ALL
  -> EXEC_REQ(index 0)
  -> EXEC_WAIT
  -> EXEC_REQ(index 1)
  -> ...
  -> terminal
```

任一时刻最多一个 scalar transaction resident。

scalar terminal `error_o==0`：

- 写 `result_bits/flags` 到 active bank 的当前 index；
- `success_result_count++`，`tensor_flags_or |= flags`；
- 若仍有 element，下一周期才能发下一 request；
- 若是最后 element，同 edge把 bank置 `READY_OK` 并释放 source owner。

scalar terminal `error_o==1`：

- 原样保存 scalar `error_code_o`；
- `fail_elem_index=current index`；
- 不写成功 result、不启动后续 element；
- 所有已写 partial result对外不可见；
- 同 edge把 bank置 `READY_ERR` 并释放 source owner。

每个 scalar terminal，无论成功或失败，都必须：

- `scalar_terminal_count++`；
- 按 `child_call_mask_o[4:0]={MUL,LOG,DIV,ADD,EXP}` 的每个 bit分别累加 primitive request count；
- `out_child_call_mask_o` 是所有已接受 scalar terminal actual masks 的 OR；
- `status==OK && opcode==SOFTPLUS && child_call_mask==0` 时 `bypass_count++`。

删除 primitive response count：scalar terminal mask只能证明 request实际发生过，不能证明每个 primitive response
被逻辑接受。

## 5. Source、双 result bank 与 order FIFO

### 5.1 Source owner

唯一 source staging：

```text
src0_mem[0:MAX_ELEMS-1] 32 bit
src1_mem[0:MAX_ELEMS-1] 32 bit
```

source owner只能在以下事件释放：

- 第 N 个 input发现 external nonfinite并 terminal；
- 最后一个成功 scalar terminal；
- 第一个失败 scalar terminal；
- parent controller非法编码产生的code4 terminal；
- global reset。

不能在 capture完成或最后一个 scalar request launch时提前释放。因此只允许：

```text
older bank OUTPUT
并行
younger tensor CAPTURE/EXEC
```

不允许：

```text
tensor B EXEC
并行
tensor C CAPTURE
```

### 5.2 Result bank

两个 bank，每个 bank保存：

- `result_raw[MAX_ELEMS]` 与 `result_flags[MAX_ELEMS]`；
- state、tag、opcode、length、status、active-cycle snapshot；
- capture/launch/terminal/success counts；
- primitive request counts、aggregate call mask、bypass count、tensor flags OR；
- fail index valid/index；
- output index。

bank state：

```text
FREE -> FILL -> READY_OK  -> DRAIN -> FREE
             -> READY_ERR --------> FREE
```

data arrays不做逐 entry reset；只有 bank metadata/state决定数据资格。

### 5.3 2-entry order FIFO

每个 `cmd_fire` 必须把已分配 bank id push 一次；每个 output transaction 的最后 handshake pop 一次。

硬不变量：

```text
fifo_count == 非FREE bank数量
fifo_count <= 2
每个非FREE bank恰好出现在FIFO一次
active work bank必须在FIFO中
任意时刻最多一个FILL bank
```

`cmd_ready_o` 只在以下条件同时成立时为 1：

```text
!rst_i
&& controller_state == IDLE
&& !source_owner_valid
&& fifo_count < 2
&& exists FREE result bank
```

FIFO full时，即使同 edge将 retire head，也禁止新 command fall-through；下一周期再给 credit。

FIFO count=1时，允许 pop旧head与push另一个已经FREE的不同 bank同 edge发生；实现必须分别处理 push-only、
pop-only、push+pop，禁止同一个 bank同 edge既作为旧 output owner又被新 command写入。

## 6. 输出协议与顺序

输出只能解析 FIFO head bank：

```text
head_bank = order_fifo[rd_ptr]
out_valid = fifo_count != 0 && head_bank.state in {READY_OK, READY_ERR, DRAIN}
```

tail bank已经READY而head仍FILL时，`out_valid_o` 必须为 0。

成功 bank：

- 输出恰好 N 个 data beat，`out_keep_o=1`；
- index 0时 `out_sop_o=1`，index N-1时 `out_last_o=1`；
- raw/flags/index来自同一 head bank；
- 最后一个 `out_valid_o && out_ready_i && out_last_o` 同 edge pop FIFO并释放 bank。

错误 bank：

- 只输出一个 empty completion beat；
- `out_sop_o=1`、`out_last_o=1`、`out_keep_o=0`；
- `out_result_bits_o=0`、`out_flags_o=0`、`out_tensor_flags_or_o=0`；
- error code/counters/fail index仍来自 bank metadata；因此错误前已经真实完成的SOFTPLUS bypass、primitive
  request与scalar success诊断不得清零；
- 该 handshake pop FIFO并释放 bank。

`out_valid_o && !out_ready_i` 期间，所有 output data、metadata、counter、bank选择和index全位稳定。READY/DRAIN
期间禁止写 bank data/metadata，active cycles不再增加。output drain/backpressure不参与 tensor active cycles。

## 7. Active-cycle 时间戳合同

使用64-bit free-running `wall_ts_q` 与每个 command的 `start_ts`。所有 event以其 posedge观察到的同一
timestamp计数；transaction duration必须小于 `2^63` cycles。

Start event：

```text
T_start = cmd_fire edge timestamp
```

Terminal event：

- unsupported/bad length：`T_terminal=T_start`；
- external nonfinite：第 N 个 `in_fire` edge；
- success：最后一个 OK scalar terminal handshake edge；
- scalar error：第一个 error scalar terminal handshake edge。
- parent controller fault：TB literal注入非法编码且parent在该edge仍持有source owner的edge。

唯一权威公式：

```text
active_cycles = T_terminal - T_start + 1
```

该值自动包括 input stall、CAPTURE→EXEC bubble、scalar request-ready stall、scalar内部周期和 element间调度
bubble；自动排除 pre-accept等待、bank READY排队、head-of-line等待、output backpressure和output drain。

同 edge immediate error必须写死1或使用当前 `cmd_fire` timestamp，不能读取尚未NBA更新的旧 start timestamp。
每个 accepted command只能产生一个 terminal snapshot；bank READY/DRAIN后不得重新计算。

TB必须用自己的 posedge descriptor scoreboard，以公开端口的`cmd_valid_i && cmd_ready_o`独立记录start，并从
TB保存的opcode/length、input handshake/finite preflight和scalar boundary handshake独立推导上述terminal；
不得读取parent内部`cmd_fire`、`command_is_valid`或`tensor_terminal`。descriptor按接受顺序区分事务，不能假定
tag唯一。比较：

```text
out_active_cycles_o == terminal_ts[head_descriptor] - start_ts[head_descriptor] + 1
```

TB还必须用`expected-1`与`expected+1`负向比较证明oracle能拒绝terminal提前/延后一拍。

scalar 固定周期 63/58/2/63/67只作为独立 request→terminal handshake oracle；禁止将其与 parent scheduler
零 bubble假设混成 active counter定义。

## 8. Reset、优先级与不变量

global reset最高优先级并原子清除：

- controller/source owner/capture与execute index；
- scalar resident transaction；
- 两个 bank metadata/state；
- FIFO head/tail/count；
- output selected bank/index/valid；
- per-command counters与timestamps。

data arrays无需逐 entry reset。reset取消事务，不发布补偿性error completion；reset释放后必须能运行两个具有不同
raw pattern的clean tensor，且无 stale result/error/last/tag。

非global的controller-fault优先级为：非法编码检测/局部scalar reset与code4 snapshot，高于普通
CAPTURE/EXEC progress；其后完整`QUARANTINE` edge，高于command credit；最后返回IDLE。该路径不清空其它已完成
bank或order FIFO，故旧fault completion仍保持接受顺序。

关键不变量：

1. `scalar_req_fire -> capture_count==length && !external_bad_seen && source_owner_valid`。
2. capture完成前、external bad后，scalar request始终为0。
3. `scalar_launch_count - scalar_terminal_count` 始终属于 `{0,1}`。
4. scalar error terminal后，本 command不得再发 scalar request。
5. `READY_OK -> success_result_count==length`。
6. `READY_ERR -> out_keep==0`，partial result永不可见。
7. output bank必须等于FIFO head；READY/OUTPUT bank不可写，FREE bank不可输出。
8. `fifo_count==2 -> cmd_ready_o==0`。
9. output hold期间所有公开字段、selected bank和counter稳定。
10. bank terminal event snapshot满足timestamp公式，READY/DRAIN期间snapshot稳定。
11. 最后capture必须使用 `bad_next`，不能因NBA旧值启动scalar。
12. reset后 `fifo_count=0`、bank均FREE、source FREE、scalar request/response资格为0、`out_valid=0`。
13. controller非法编码时当拍scalar request/response credit均为0，`u_element`被局部reset；完整quarantine edge
    结束前`cmd_ready_o=0`，之后无需global reset可clean recovery。
14. 任意accepted descriptor的规范terminal前`out_valid_o=0`；该判定不得依赖DUT bank state或terminal predicate。

## 9. Testbench 与证据

新增 `tests/tb_unary_glu_tensor_engine.sv`，只使用 raw-bit常量；禁止 real/shortreal/DPI/C++/host math。

至少覆盖以下独立证据：

1. N=1 SIGMOID，逐 bit raw/flags、actual call counts与timestamp active cycle；
2. N=3 SOFTPLUS `{bypass,slow,bypass}`，natural-order output与bypass=2；
3. N=2 SWIGLU，逐 element flags、tensor flags OR与MUL count；
4. N=`MAX_ELEMS=6144` 的首/尾地址、13-bit count不wrap、atomic commit；
5. external nonfinite位于 first、SWIGLU src1 middle、last；三例均 capture=N且scalar launch=0；
6. unsupported opcode、length=0、length>`MAX_ELEMS`，active=1、零input/zero scalar；
7. input valid精确stall，timestamp active增加相同cycle，stall期间零scalar；
8. output hold至少300 cycle，全部字段稳定且active不增加；
9. older bank output held时 younger tensor capture/compute完成；输出顺序仍older→younger；
10. older分配bank1、younger分配bank0的wrap/order反例；禁止按bank号重排；
11. 两bank full时第三个cmd保持至少1000 cycle不握手；释放后下一周期才可接受；
12. FIFO count=1时不同bank的head pop + new command push同 edge守恒；
13. scalar code2/code3/code4各自原样传播、fail index正确、partial result不输出、actual call mask计入；
14. scalar deadline normal response得到code3 timeout，deadline fatal response得到code2 child error；parent不得重判；
15. source owner在EXEC期间阻止新command，后续 scalar operand仍等于旧 tensor staged raw；
16. reset分别注入CAPTURE、scalar resident、READY tail/head output hold、两bank full；reset后clean recovery。
17. 第一项success后延迟注入第二项scalar error，延迟窗口逐周期独立确认`out_valid_o=0`；另以SOFTPLUS第一项
    bypass成功、第二项scalar error确认empty error completion仍保存`bypass_count=1`。
18. scalar resident时literal写入非法parent controller编码，检查完整quarantine、唯一code4、无stale response，
    且不施加global reset即可完成clean tensor。
19. SWIGLU source-owner反例同时检查后续scalar的`src0`和`src1`仍来自旧staging；至少一组双bank命令复用相同tag，
    证明order/timestamp scoreboard不依赖tag唯一性。

若 fault fixture force层次信号，必须注入真实 scalar terminal字段或 compile-success mock；禁止 force parent最终
error谓词来替代 status传播路径。

TB marker：

```text
[NPU-UNARY-GLU-TENSOR][PASS]
```

Verilator固定配置：

- `verilator --binary --timing --sv -O3 -Wall -Wno-fatal`；
- C++ `-O3 -DNDEBUG -march=native`；
- 不定义 `NPU_ASSERT`，不使用 `--assert`；
- 不使用 `--trace/--trace-fst/--coverage`，不得生成 waveform；
- build/log/cache/compiler全部位于 `tmp/`；
- pinned third-party warning只能用 source-scoped waiver；新增 RTL/TB在未豁免 `-Wall` 下必须零 warning/error。

PASS必须同时满足数值、全tensor零side-effect preflight、双bank/FIFO owner、错误原子性、timestamp cycle、
reset/hold/liveness边界、build/run rc、精确marker、source identity和no-assert/no-wave/O3证据。即使本模块 PASS，
`LANES=4/8`、LMEM/backend、Qwen、CPU fallback=0和tokens/s仍为GAP。
