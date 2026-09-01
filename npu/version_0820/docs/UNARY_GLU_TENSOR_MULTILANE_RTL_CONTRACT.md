# Unary/GLU FP32 多 lane 张量 RTL 合同

## 1. 状态、目标与冻结身份

本合同冻结 `TensorNpuUnaryGluTensorEngineMultiLane` 的首版多 lane reference
transaction。`LANES` 只允许 4 或 8；模块在一个时钟域中完成 command 接受、完整 tensor
capture 与 finite preflight、static-residue 多 lane scalar 调度、双 result bank 原子提交，及按
command 接受顺序输出成功数据或一个 empty error completion。

外部 command/input/output/diagnostic 接口逐位保持
`TensorNpuUnaryGluTensorEngine`（LANES=1）合同。多 lane 只改变 element compute 拓扑，不改变：

- 单 source staging owner；
- 两个 result bank 与 2-entry order FIFO；
- FIFO head-only output 和 held-output 全 bundle 稳定；
- `active_cycles = T_terminal - T_start + 1` 的独立 timestamp 定义；
- external nonfinite 完整 capture、error empty completion、零 partial output；
- invalid opcode/length 的 same-command-edge terminal；
- duplicate tag、same-edge FIFO pop/push 与 global reset 语义。

冻结输入：

- `docs/UNARY_GLU_F32_ORACLE_CONTRACT.md`；
- `docs/UNARY_GLU_ELEMENT_RTL_CONTRACT.md`；
- `docs/UNARY_GLU_TENSOR_RTL_CONTRACT.md`；
- canonical vectors SHA-256
  `0bc73dba6d65597a78d8b0d9451e787334a5feb81ca677407a7cb4aa61d1c908`；
- v34-v6 LANES=1 immutable receipt 与 current source manifest；
- `tmp/contracts/unary-glu-tensor-multilane-architecture-v1.md`。

本合同不证明 LMEM/GMEM adapter、descriptor/DMA、cache/coherency、GGML backend、Qwen、
CPU fallback、tokens/s、综合、STA、PPA、面积、频率或功耗。

## 2. 阶段 1：需求

### 2.1 参数与接口

```verilog
module TensorNpuUnaryGluTensorEngineMultiLane #(
    parameter integer MAX_ELEMS = 6144,
    parameter integer ELEMENT_TIMEOUT_CYCLES = 256,
    parameter integer LANES = 4
) (...LANES=1 的完整外部端口...);
```

硬参数边界：

```text
LANES in {4,8}
1 <= MAX_ELEMS <= 6144
ELEMENT_TIMEOUT_CYCLES > 0
```

非法参数配置不得产生 command/input/scalar/output credit。长度、element index 与所有 element
count 固定 13 bit，必须表达 `0..6144`。

所有端口属于 `clk_i`。`rst_i` 同步高有效；reset 周期 `cmd_ready_o=0`、
`in_ready_o=0`、`out_valid_o=0`，所有 child local reset 有效。

### 2.2 功能与性能边界

1. 合法 command 在 FREE bank 中预留 descriptor 并 push FIFO，随后严格 capture N 个 input beat。
2. 全部 N 个 external operand 已 capture 且 finite preflight 成功以前，所有 lane request valid 为 0。
3. lane `k` 只处理 `index=k+m*LANES`；每 lane 独占一份
   `TensorNpuUnaryGluElement`，每份 child 最多一个 resident transaction。
4. 每 lane 的 response retire 与下一 request 不做同拍 fall-through；成功 response 后最早下一拍
   request `old_index+LANES`。
5. 最后一组成功 response 在同一 edge 写 pending result/flags 并把 bank 原子提交为 READY_OK；
   第一个 output beat最早下一拍可见。
6. 多 lane compute 允许最多 `LANES` 个 scalar resident；capture 与 output 保持各一 beat/拍。
7. cross-config性能只使用无stall、`N=32`、`SIGMOID(x=1.0)`、`BYPASS=0`；TB分别记录
   command accept、capture complete、first child `req_fire`、last child `rsp_fire`、bank commit五个
   独立edge，compute metric固定为`LAST_RSP-FIRST_REQ+1`。L8 metric不得大于L4；不以理论固定
   倍数作oracle，bypass向量不得作为compute性能证据。

## 3. 阶段 2a：协议规则

### 3.1 外部 valid/ready

- command、input 与 output handshake 均为 `valid && ready`。
- FIFO full，即使同 edge 会 pop head，也不允许 command fall-through。
- source owner 未释放时不接受下一 command；older bank output 可与 younger capture/compute 并行。
- `out_valid_o && !out_ready_i` 时全部 301-bit output bundle、head bank 与 output index稳定。

### 3.2 Lane request/response

每 lane 的真实事件定义：

```text
req_fire[k] = lane_req_valid[k] && lane_req_ready[k]
rsp_fire[k] = lane_rsp_valid[k] && lane_rsp_ready[k]
rsp_ok[k]   = rsp_fire[k] && !lane_error[k]
rsp_bad[k]  = rsp_fire[k] &&  lane_error[k]
```

REQ 状态在反压期间保持 opcode、src0、src1、element index 与 generation。WAIT 状态独占该
lane response credit；其它 lane response 是 ghost/wrong-owner protocol fault。

父级只能从本拍事件归约 next 值：

```text
launch_next  = launch_q  + popcount(req_fire)
terminal_next = terminal_q + popcount(rsp_fire)
success_next = success_q + popcount(rsp_ok)
```

每类 primitive count 对 `rsp_fire[k] && child_call_mask[k][bit]` 做 popcount；aggregate call
mask OR 所有真实 terminal mask；SOFTPLUS bypass 只对
`rsp_ok[k] && child_call_mask[k]==0` 计数；flags 只 OR 成功 response。

同一 edge 同时存在 success 与 error response 时：

- 所有真实 request/response event 均计数；
- 所有真实 terminal actual call mask 均聚合；
- success result 可以写 pending bank，但错误 bank 永不可读；
- error 优先，禁止 READY_OK；
- first cause 选所有 bad response 中最小逻辑 element index；code 0 提升为 code 4；
- 未 terminal 的 resident participant 由 quarantine local reset 取消，允许 launch > terminal。

### 3.3 Fault 与同步清洗

parent/lane literal illegal state、owner/generation mismatch 与 ghost response 属于 protocol fault。
protocol fault 组合周期撤销所有正常 request/response credit。scalar error response edge必须先真实
handshake 并完成全 event 归约；不能用 combinational child reset 抹掉 `rsp_fire`。

lane-local protocol cause 必须先逐 physical lane 形成 `lane_fault_this[k]`：wrong-owner、generation
mismatch、residue/index越界、非法 lane state、`LANE_IDLE && owner_valid` 与 ghost response仅在实际违约
lane置位。`lane_fault_min` 只对这些置位 lane 的 `lane_index` 做最低逻辑index编码；合法低编号resident、
held REQ/WAIT或response participant不得进入该cause集合。同拍多lane fault报告实际fault集合中最低逻辑
index。

parent/controller-only illegal或lifecycle fault使用独立 `parent_participant_min`：active participant定义为
lane state非IDLE、owner有效或held response有效；存在participant时报告其最低逻辑index，否则回退到本拍
capture cursor。controller literal illegal时，合法resident只能进入participant集合，不能因为parent state非法
而被反向标成lane fault。若parent fault与真实lane-local fault同拍，真实lane fault cause优先。

fault/response edge锁存唯一 tensor error terminal（无 source owner ghost 不发布 completion）并进入
`CTRL_QUARANTINE`。紧随其后的完整注册周期：

- 所有 parent/lane command/request/response credit 为 0；
- 所有 participant child 的同步 local reset 为 1，并在下一采样 edge 清空；
- 不修改其它 READY/DRAIN bank 或 FIFO descriptor；
- 完整 quarantine 后回 IDLE，无需 global reset 即可 clean recovery。

## 4. 阶段 2b：状态机

### 4.1 Parent controller

| 状态 | 含义 | 正常转换 |
|---|---|---|
| `CTRL_IDLE` | 无 source owner；可按 bank/FIFO credit接 command | valid command→CAPTURE；bad command保持IDLE并生成READY_ERR |
| `CTRL_CAPTURE` | 单拍写 source staging并累计 finite preflight | last good→EXEC；last bad→IDLE+READY_ERR |
| `CTRL_EXEC` | lane-local REQ/WAIT 并行推进 | all success→IDLE+READY_OK；任意error/protocol fault→QUARANTINE+READY_ERR |
| `CTRL_QUARANTINE` | 完整注册 child reset/credit=0 周期 | 下一拍→IDLE |

非法 parent state 同拍撤销 credit；有 source owner时生成一次 code4 error terminal，无 owner时仅清洗。

### 4.2 Lane FSM

| 状态 | owner | 行为 | 转换 |
|---|---:|---|---|
| `LANE_IDLE` | 0 | 无 req/rsp credit | capture barrier通过且`k<N`→REQ |
| `LANE_REQ` | 0 | held request valid | `req_fire`→WAIT |
| `LANE_WAIT` | 1 | matching response ready | `rsp_ok && index+L<N`→REQ；tail success→IDLE；error→全局QUARANTINE |

`2'b11` 为非法 lane state。REQ/WAIT 中 index 必须 `<N`、`index % LANES == k` 且 generation 匹配。

### 4.3 Bank/FIFO

```text
FREE -> FILL -> READY_OK  -> DRAIN -> FREE
             -> READY_ERR --------> FREE
```

每个 accepted command push一次 bank id；每个 output transaction 的最后 handshake pop一次。
output 只解析 FIFO head。READY tail不得越过 FILL/held head。

### 4.4 同拍优先级

```text
global reset
  > parent/lane protocol fault（撤销credit、code4、quarantine）
  > scalar error response terminal（先归约真实event，再error/quarantine）
  > normal capture/lane/FIFO/output progress
```

output/FIFO 与 active tensor可位于不同 bank并行推进；global reset取消全部事务且不发布补偿completion。

## 5. 阶段 2c：不变量

1. `scalar_req_fire -> capture_count==length && !external_bad_seen && source_owner_valid`；违反会造成
   preflight side effect。
2. 对每个 live lane：`index<length && index%LANES==lane_id && generation==active_generation`；违反是code4，
   且只有违反该式或owner/state/ghost规则的lane能进入 `lane_fault_min`。
3. 每个逻辑 index最多一次 request handshake、最多一次 response handshake；不同 lane 同拍写 index互异。
4. `0 <= launch_count-terminal_count <= LANES`，且
   `success_count <= terminal_count <= launch_count <= length`；违反表明owner或event守恒破坏。
5. WAIT当且仅当 owner valid；IDLE/REQ无owner。matching WAIT之外的response为ghost/protocol fault。
6. READY_OK要求 `launch_next==terminal_next==success_next==length` 且response后全部lane IDLE。
7. READY_ERR只输出一个 `keep=0` completion；pending/partial result与per-element flags永不可见。
8. error completion保留terminal edge及此前所有真实 capture/launch/terminal/success/mask/primitive/bypass诊断；
   output result/flags/tensor flags为0。
9. `fifo_count == 非FREE bank数 <= 2`，每个非FREE bank在FIFO恰好一次，FILL bank最多一个。
10. output bank恒等于 FIFO head；READY/DRAIN bank不可写，FREE bank不可输出。
11. held output全部字段稳定；READY/DRAIN期间 terminal metadata与active snapshot稳定。
12. 每个 bank terminal snapshot满足 `wall_ts-start_ts+1`；output排队/反压不计入。
13. reset后 controller IDLE、lane全IDLE且owner=0、bank全FREE、FIFO=0、source free、所有credit/output为0。
14. quarantine完整周期所有lane req/rsp credit为0且所有 child local reset为1；随后新generation不消费stale response。
15. `lane_fault_min_valid -> lane_fault_mask[lane_fault_min_lane]`；任意合法低编号participant不能改变高编号
    actual fault的fail index。parent-only fault则要求 `!lane_fault_min_valid` 并独立选择最低active participant，
    无participant时才选择capture cursor。

## 6. 阶段 2d：数据通路约束

- source：一份 `src0_mem/src1_mem`，capture每拍一个写口；EXEC只读，不允许第三tensor覆盖。
- scalar：复制 `LANES` 份完整 `TensorNpuUnaryGluElement`，不存在跨lane primitive共享。
- lane work：每lane独立2-bit state、owner、13-bit index与generation。
- result：两份逻辑 bank，最多 `LANES` 个互异index同拍写；natural-order output按index 0..N-1串行gather。
- diagnostic：request/response event mask经最多8路加法树与OR树归约；protocol path由
  `lane_fault_this -> lane_fault_min` 与 `active participant -> parent_participant_min` 两棵互不复用的
  最低index优先编码器组成，terminal cause mux按fault来源选择。
- terminal：归约的next counters、lane-after-state与error优先级组合决定单一bank metadata snapshot。
- output：FIFO head选择bank metadata/result/flags；ready只控制head index推进与last pop。

最长 parent 组合路径预计为 child held response → event mask → popcount/primitive OR/min-fail →
terminal eligibility/metadata D-input。scalar内部EXP/LOG/DIV路径仍封装在每个 child内。

## 7. 阶段 2e：RTL 级拓扑与自审

1. **module/interface**：外部端口与LANES=1逐位相同；内部每lane一个req/rsp valid-ready接口；单时钟、同步高reset。
2. **状态寄存器**：parent state/source owner/active descriptor/timestamp/capture；每lane state/index/gen/owner；
   两bank state/descriptor/counters/output index；FIFO pointers/count；均由单个posedge块更新。
3. **组合块**：参数/command/capture predicate、逐lane actual-fault predicate、lane-fault最低index编码器、
   parent-participant最低index编码器、event next归约、terminal选择、head output mux。
4. **FSM**：parent/lane/bank三层状态机如§4；非法编码全部fail closed。
5. **pipeline/flow**：command→capture barrier→lane REQ/WAIT loops→bank terminal→FIFO head drain；
   input、lane child和output均各自有明确backpressure边界。
6. **reset/kill/stall优先级**：§4.4；scalar error edge先消费event，下一完整quarantine周期同步reset所有child。
7. **资源复制/共享**：scalar/primitive全复制；source、result store、FIFO、timestamp与output mux共享；
   每个共享资源均由active bank/FIFO head/lane index显式mux+enable控制。
8. **critical path**：response mask归约到bank terminal D-input；LANES最多8，首版不增加额外pipeline以保持terminal原子edge。
9. **function划分**：仅external-nonfinite等小型纯组合predicate可用function；FSM、握手、仲裁、
   popcount/min-index与bank/FIFO更新必须用显式`always @(*)`、`always @(posedge clk)`或子module。

自审结论：

- static residue保证多写index互异，tail lane不启动；
- last response的pending write与READY_OK同edge，组合output只能下一拍读到新state；
- scalar error不能组合回驱child reset，因为现有child `rsp_valid_o`受`rst_i`抑制；故错误edge先归约，
  registered quarantine随后提供完整同步清洗周期，避免组合环和假`rsp_fire`；
- command allocation只看edge前FREE bank，FIFO full不使用same-edge pop credit；
- output只读head bank，duplicate tag不参与owner/order/timestamp选择。

## 8. Testbench 与动态覆盖

`tests/tb_unary_glu_tensor_multilane.sv` 是唯一参数化raw-bit TB，分别以 `LANES=4`、`LANES=8`
fresh build/run。TB不使用real/shortreal/DPI/C++/host math；descriptor/timestamp/lane-owner scoreboard
只从公开或真实lane boundary handshake建立预期。

动态覆盖必须包括：

- 四opcode与长度 `1,L-1,L,L+1,2L+3`，normal/special/bypass/flags向量；
- MAX_ELEMS=6144、13-bit count、每index launch/terminal恰好一次、tail无spurious；
- capture barrier和first/middle/last nonfinite零launch；
- lane request stall/held payload、response hold、2..L个同拍response与max inflight=LANES；
- same-edge success+error、lowest fail index、完整真实diagnostic、零partial、quarantine与clean recovery；
- L4 lane3 wrong-owner、L8 lane7 generation mismatch、高lane非法FSM、高lane`LANE_IDLE && owner_valid`、
  高laneghost且低lane合法resident、同拍两个actual lane fault的最低真实index；parent literal illegal单独验证
  `!lane_fault_min_valid`与最低active participant；
- timeout及ownerless ghost清洗；
- 双bank/FIFO/order/full/no-fall-through/push+pop、duplicate tag、300-cycle output hold；
- reset在capture、REQ hold、WAIT、last multiresponse terminal、READY/output五阶段及两组clean pattern；
- 独立active timestamp exact与expected±1拒绝；production transaction与两个负向值调用同一4-state comparator，
  exact返回accept，`expected-1`、`expected+1`分别真实返回reject后才增加对应计数；
- L4/L8的non-bypass `SIGMOID(x=1.0),N=32` raw/flags/metadata/count/signature相同，
  `req_fire/rsp_fire`各32；五个时间点均被独立descriptor/event oracle观测，且
  `L8 (LAST_RSP-FIRST_REQ+1) <= L4 (LAST_RSP-FIRST_REQ+1)`。

精确marker：

```text
[NPU-UNARY-GLU-TENSOR-MULTILANE][LANES=4][PASS]
[NPU-UNARY-GLU-TENSOR-MULTILANE][LANES=8][PASS]
```

## 9. Verilator 与 fail-closed evidence

固定配置：

- `verilator --binary --timing --sv -O3 -Wall -Wno-fatal`；
- C++ `-O3 -DNDEBUG -march=native`；
- no assert、no trace、no coverage、no waveform、no core；
- 新RTL/TB warning/error为0；locked third_party warning只允许source-scoped waiver；
- build/log/cache/compiler只进入 `tmp/{build,logs,cache,compiler}/unary-glu-tensor-multilane`。

runner复用 `scripts/task-run-status.sh`：HUP/INT/TERM/early EXIT、native build/run rc、source/filelist/
config/binary/hash、exact-one marker、cleanup、receipt与final binding任一不完整都保持
`evidence_complete=0` 和 FAIL。固定design/config只执行一次；首个真实失败保留diagnostic与root cause，
修改设计输入后才启动新的唯一fresh evidence run。

每个repair-v2配置必须在compiler cleanup前保存原始 `__verFiles.dat` 及其SHA-256，并解析全部 `S` row：
路径按workspace root规范化，workspace外、missing、unknown suffix与duplicate均fail closed。canonical actual
membership与冻结`sources.f`递归解析得到的真实`.vi` include closure组成的canonical expected membership做
exact set equality，同时保存missing/extra diff和完整逐source SHA。membership self-test必须证明missing source、
extra source、替换top RTL三类mutation都被同一个exact-equality审计拒绝。raw membership、expected/actual、
diff、逐源SHA、command/config/filelist/waiver、binary、build/run/native rc、marker/status/cleanup必须进入最终
binding；只有两配置各自闭合后cross receipt才可写PASS。

## 10. Unknowns、假设与替代拓扑

- 假设每个既有 `TensorNpuUnaryGluElement` 继续满足其timeout/HOLD_RESPONSE/actual call-mask合同；
  本轮不重认证LANES=1内部数值单元。
- 假设事务duration小于`2^63`，与LANES=1 timestamp合同一致。
- flat result storage在综合工具中可能被实现为多端口flop阵列；bank-per-lane residue SRAM是未来PPA替代，
  本轮不运行综合/STA/PPA，不能声明物理面积或频率。
- 另一替代是共享scalar+arbiter，但会破坏每lane独占primitive与真实并行resident要求，因此不采用。
