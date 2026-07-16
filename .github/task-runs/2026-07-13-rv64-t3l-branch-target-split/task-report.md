# T3L — 13-bit B-imm 与 4KiB 分裂分支目标

## 目标与当前物理根因

T3K fresh H7CL 5ns 的 top40 已全部迁移到同族前端路径：
`OooFetchAxiBridge.pc_q` 经 ITLB/PMP/cache-hit/raw payload、RVC/packet decode、B-imm、
branch target 后，同拍写 `OooFetchPcOutstandingSequencer` 与 `OooFetchPacketFifo`。
最差 arrival 约 13.688ns、slack -8.716ns；网表中 `dec1_bimm_o[12]` 的生成 cell
单体延迟 5.128ns，并向 `dec1_bimm_o[63:13]` 形成 51 个符号 alias。

本切片只消除无语义的 wide B-imm ABI，并把 `PC + signextend(B-imm13)` 改写为 4KiB
页内低位加法 + 页号 `carry-sign` 修正。它不改变 response/预测/入队/PC 状态时序；只有
fresh synthesis/STA 能决定该最小切片是否足够，不能预先宣称 200MHz。

## 接口契约冻结（写 RTL 前）

### 需求与边界

- `OooFetchPacketDecode.dec{0,1}_bimm_o` 从 XLEN 收窄为原始 B-type 13 位：
  `{inst[31],inst[7],inst[30:25],inst[11:8],1'b0}`；非 branch 输出 13'b0。
- 新纯组合 `OooFetchBranchTarget` 输入 `pc[63:0]` 与 `bimm[12:0]`，输出必须逐位等价于
  `pc + {{51{bimm[12]}},bimm}`（模 2^64）。
- predictor static fallback 的唯一真源从 `bimm[XLEN-1]` 改为 `bimm[12]`；两 lane 不串线。
- `fetch_pred_next_pc` 的既有优先级保持：lane0 taken > lane1 taken > packet fall-through。
- out of scope：response 打拍、多 outstanding、BPU lookup latency/GHR snapshot、FIFO 字段、
  flush/redirect owner、false/multicycle path、PMP/ITLB/cache-hit 语义。

### 六类跨模块合同

| 类别 | T3L 冻结合同 |
| --- | --- |
| 握手 | PacketDecode 与 BranchTarget 都是 0-cycle 组合 view，无 valid/ready、无 payload hold；既有 fetch response valid/ready/fire 不变。 |
| stall/backpressure | 不新增 occupancy 或 stall；FIFO reserve、response enqueue/bypass、request ready 的 producer 与 DAG 完全不变。 |
| flush/redirect | 新模块不存状态，因此无清/保持项；既有全序 `trap/exit > CSR/xRET > branch > prediction > sequential` 不变。target 只替换同一预测 payload。 |
| 异常序 | fault slot 仍由 `resp==OK` gate 禁止预测；decoder 的 fault NOP 净化与 lane owner 不变。BranchTarget 不产生异常。 |
| 访存序 | 不接 AXI/cache/PMP/CSR/store；不得改变 request、response 或 committed side effect。 |
| 投机恢复/单一真源 | 每 lane 只有一个 13-bit B-imm 真源；bit12 供 static fallback，完整 13 位只供该 lane target。禁止重新制造 XLEN sign-extended cross-module bus。 |

### 状态、时序、stall 与优先级

- PacketDecode/BranchTarget 无寄存器、FSM、reset state 或 enable state；当前 response 拍仍组合
  decode、predict、target，拍尾仍由原 FIFO/sequencer owner 落账。
- reset/stall/flush 不在新模块捕获中间值。若 response 未被既有 gate 消费，组合 target 没有架构语义。
- lane0 taken 继续使 slot1 无效；只有 lane0 not-taken 且 lane1 branch/taken 时才选 lane1 target；
  两者均不 taken 时用 `packet_next_pc`。
- 任何 fault、discard、full/backpressure、redirect 与 same-cycle request/response 交叠真值表均不改。

### 数学数据流

令 `H=pc[63:12]`、`p=pc[11:0]`、`s=bimm[12]`、`u=bimm[11:0]`：

```text
low_sum = {1'b0,p} + {1'b0,u}
low      = low_sum[11:0]
high     = H + zero_extend(low_sum[12]) - zero_extend(s)   (52-bit modulo)
target   = {high,low}
```

因为 signed B-imm `I = u - s*4096`，且
`p+u = low + low_sum[12]*4096`，所以上式对任意 64-bit PC、全部合法偶数
`I∈[-4096,4094]` 都等价于 `(pc+signextend(I)) mod 2^64`。PC 不要求对齐；52-bit
页号自然保留高位 wrap。

### 必须可执行的不变量与 RED

1. decoder 输出宽度精确 13，两个 lane 的 bit-field 与解压后 inst 一致，非 branch 为零。
2. split target 与独立 wide-reference 逐位等价；立即断言必须由 deliberate arithmetic
   mutation 精确触发，不能只靠同实现测试。
3. 穷举所有 4096 个 `pc[11:0]` × 4096 个合法 B-imm 编码，共 16777216 cases；另外覆盖
   high=0/1/max-1/max 的 wrap 样本。
4. mutation 至少覆盖：漏减 sign、sign 改加、漏 carry、carry 边界 `>=` 写错、把 bit11 当符号、
   lane0/1 cross-wire、恢复 XLEN output。
5. source/netlist 检查必须拒绝 full-width B-imm 和 51 个 sign alias，同时证明 target 模块、
   13-bit pin 与非空 PC/imm→target→FIFO/outstanding 路径仍存在；空对象集合失败。
6. 旧 T3K 网表冒充 fresh 必须精确 RED；fresh global 5ns 仍以 WNS>=0 为唯一 T-PRE 完成线。

## 拓扑审查

- producer：`OooFetchPacketDecode`，唯一从解压后指令提取每 lane 13-bit B-imm。
- consumers：对应 lane 的 `OooFetchBranchTarget` 与 predictor `static_taken` bit12；无第三消费者。
- state owners：`OooFetchPacketFifo`、`OooFetchPcOutstandingSequencer` 保持原端口/事件/优先级。
- 组合边界：decoder sign 只跨一个 1-bit module pin；高页号修正只把 carry/sign 当单 bit
  加减量，不把 sign 复制成 51-bit operand bus。
- 预期物理作用：删除 decoder output sign alias 与跨模块高电容；是否回收全核 WNS 必须由
  current-source fresh A/B 裁决。

Topology review：接口、所有权、状态、flush/stall 与优先级已经冻结，可以进入 RTL。
