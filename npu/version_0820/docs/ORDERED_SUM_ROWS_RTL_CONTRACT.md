# Ordered SUM_ROWS RTL contract

> **固定图切片。** 本合同冻结 `TensorNpuOrderedSumRows` 和三个全 IEEE
> binary32/binary64 child 的模块语义。PASS 只覆盖固定
> `ne=[128,128,16,1]`、36 个同构 `GGML_OP_SUM_ROWS` descriptor；不覆盖
> backend dispatch、active-root swap、Qwen 整图、综合、STA 或 PPA。

## 1. 阶段 1：可验证需求

### 1.1 算术 DAG

每个 logical row 恰有 128 个 F32 元素，并严格执行：

```text
acc[-1] = 64'h0000000000000000
for i0 = 0 .. 127:
    term[i0], widen_flags[i0] = FCVT.D.S(raw_f32[i0])
    acc[i0], add_flags[i0] = FADD.D.RNE(acc[i0-1], term[i0])
result, narrow_flags = FCVT.S.D.RNE(acc[127])
```

每行是 128 次而不是 127 次 F64 ADD。禁止用 `x[0]` 作 seed、F32
accumulator、tree/pairwise reduction、重排、Kahan、early-NaN exit 或中间 F32
narrow。全部真正 matching child response 的 flags 以
`{NV,DZ,OF,UF,NX}` sticky-OR；NaN/Inf/OF/UF/NX 都是可提交算术结果，不是
transaction failure。

默认参数：

```text
NE0=128, NE1=128, NE2=16, NE3=1
ROWS=2048, ELEMENTS=262144
src nb=[4,512,65536,1048576]
dst nb=[4,4,512,8192], dst ne=[1,128,16,1]
```

default/full-profile 成功事件基数固定为：

| event | count |
|---|---:|
| logical elements selected | 262144 |
| 64-bit GMEM read req/rsp | 131072 / 131072 |
| widen req/rsp | 262144 / 262144 |
| F64 add req/rsp | 262144 / 262144 |
| narrow req/rsp | 2048 / 2048 |
| rows reduced | 2048 |
| shadow write req/ack | 2048 / 2048 |
| `done_o` | exactly one |

### 1.2 三个 IEEE child

新增且不修改旧有限域 wrapper：

- `TensorNpuFp32ToFp64Ieee`：所有 F32 raw bits 均合法；finite exact widen，
  signed zero/Inf 保持，NaN canonicalize 为 `64'h7ff8000000000000`，sNaN
  置 NV。
- `TensorNpuFp64AddIeee`：所有 F64 raw bits 均合法；固定 add、RNE、
  tininess-after、gradual-underflow，NaN canonicalize。
- `TensorNpuFp64ToFp32Ieee`：所有 F64 raw bits 均合法；固定 RNE、
  tininess-after、gradual-underflow，NaN canonicalize 为 `32'h7fc00000`。

每个 child 是同步高有效 reset 的 EMPTY/FULL single-outstanding wrapper。
request handshake 当拍把组合 HardFloat result/flags 写 holding slot；FULL 时
payload保持且 `req_ready_o=0`。response retire 当拍不接新 request。reset 取消
resident response，deassert 后不得出现 stale completion。

### 1.3 顶层端口和 descriptor ABI

`TensorNpuOrderedSumRows` 是单时钟、同步高有效 reset、single-outstanding
64-bit GMEM engine。参数允许 fault TB 用缩小 profile，但 production default
必须是上述完整 profile。

控制/header：

```text
start_i, ready_o, busy_o
dtype_i[7:0]            expected 8'h01 (F32)
profile_i[7:0]          expected 8'h01 (ORDERED_SUM_ROWS_V1)
rounding_mode_i[2:0]    expected 000 (RNE)
denormal_mode_i[1:0]    expected 00 (gradual, no FTZ/DAZ)
nan_policy_i[1:0]       expected 00 (RISC-V canonical)
dst_shadow_private_i    expected 1
reserved_i[31:0]        expected all zero
op_params_i[127:0]      expected all zero
```

src/dst 各自提供 `region_base[63:0]`、`region_size[63:0]`、
`view_off[63:0]`、`ne0..ne3[31:0]`、`nb0..nb3[63:0]`，另有半开
`gmem_floor_i/gmem_limit_i`。GMEM request 端口是 held
`valid/ready/write/addr/wdata/wstrb`；response 端口是
`valid/ready/rdata/error`。

terminal/counter：

```text
done_o, error_o, error_code_o[4:0], flags_o[4:0]
fault_valid_o
first_fault_cycle_o[63:0], first_fault_coordinate_o[127:0]
first_fault_gmem_addr_o[63:0], first_fault_flags_o[4:0]
first_fault_request_events_o[63:0], first_fault_response_events_o[63:0]
rows_reduced_o, elements_processed_o
gmem_read_requests_o, gmem_read_responses_o
gmem_write_requests_o, gmem_write_responses_o
widen_requests_o, widen_responses_o
add_requests_o, add_responses_o
narrow_requests_o, narrow_responses_o
active_cycles_o
```

`done_o` 仅授予父级对 transaction-private shadow 的 commit eligibility；模块
没有 active-root 写端口。`error_o`、reset 或 poisoned transaction 永远没有
commit资格。

### 1.4 out-of-scope

不修改旧 `TensorNpuFp32ToFp64`、`TensorNpuFp64Add`、
`TensorNpuFp64ToFp32`、`TensorNpuFp64ToFp32Finite`、third_party、mover、
Unary/GLU/F32 Tensor ALU。不使用 DPI/host FPU/`real`/`shortreal` 计算expected，
不运行综合、STA、PPA、Qwen，不声称strict graph闭合。

## 2. 阶段 2a：协议规则

1. `start_i&&ready_o` 是唯一 descriptor capture；busy start不采样任何字段。
2. 全descriptor先驻留，再在独立 `PREFLIGHT` 周期用128-bit组合网一次性检查；
   该周期及所有失败路径均无GMEM/child request。
3. GMEM request只在 `valid&&ready`计数/建立owner；REQ反压时
   `write/addr/wdata/wstrb`逐bit保持。最多一个GMEM owner。
4. response credit只给对应WAIT/DRAIN中的唯一matching owner。ghost、owner/
   generation/row/beat不匹配在采样边沿前形成protocol-fault predicate，且不给非法
   credit。
5. 三个child各自最多一个owner；request/response计数只来自真实handshake。
   response只有state、owner-valid、generation、row和element全部matching才获得
   ready/credit。ghost/wrong-owner/illegal state进入完整注册quarantine。
6. 每行先读64个8B beat到128-entry `row_buffer_q`；随后一个元素一个元素严格
   WIDEN→ADD feedback；最后ADD matching response之后才能NARROW。
7. 全部row先写2048-entry `result_buffer_q`；只有所有row完成后才逐项向private
   shadow发4B strobe write并等待ack。
8. REQ timeout只锁存 first cause/`abort_hold_q`；已暴露的valid与完整
   payload必须保持到真实fire或reset。独立`ABORT_HOLD_TIMEOUT_CYCLES`
   watchdog在ready永久为低时有界置`abort_hold_poison_q`；该poison不取消
   request，不产生DONE/ERROR，只允许reset恢复。
9. WAIT timeout在无matching response fire时进入`GMEM_DRAIN`。DRAIN只给
   原accepted owner传输credit，冻结semantic coordinate/buffer/counter，且
   late error不能改写已锁存first cause。deadline同拍任何matching
   request/response fire均先记账；matching error response作为fatal cause，正常
   matching response采用payload并推进。timeout只在无`phase_fire_w`时命中。
10. ownerless GMEM response与`ROW_READ_REQ`/`PUBLISH_REQ`真实request
    fire同拍时，request owner/counter与first-fault post-fire identity均保留；
    `collision_poison_q`独立于first-fault锁存，下一完整quarantine后直达
    reset-only `POISON`。旧ghost与后到真实response均不能获得新owner的
    DRAIN/semantic/terminal credit。
11. `done_o`/`error_o`各单拍；ERROR前若由child fault到达，必须先经过一个完整
    `CHILD_QUARANTINE`周期同步reset三个child。

`FIXED19_NORMATIVE_PRIORITY_BEGIN`
活动transaction的唯一规范优先级（retired/no-active cleanup是独立生命
周期，不参与本表仲裁）：

```text
reset
  > internal/owner/protocol/GMEM-response fatal capture
      (same-edge real transport fires still use the exact last writer)
  > matching request/response fire at its deadline
  > command timeout with no phase fire
  > stall timeout with no phase fire
  > ordinary progress
```
`FIXED19_NORMATIVE_PRIORITY_END`

## 3. 阶段 2b：FSM

| state | Moore输出/owner | 正常转移 |
|---|---|---|
| `IDLE` | `ready=1`，无credit | start→`PREFLIGHT` |
| `PREFLIGHT` | zero request | fail→`ERROR`；pass→`ROW_READ_PREP` |
| `ROW_READ_PREP` | 形成并寄存held read payload | →`ROW_READ_REQ` |
| `ROW_READ_REQ` | read valid | fire→`ROW_READ_WAIT` |
| `ROW_READ_WAIT` | matching GMEM credit | rsp→store两F32；row满→`WIDEN_REQ`，否则prep |
| `WIDEN_REQ` | held widen valid | fire→`WIDEN_WAIT` |
| `WIDEN_WAIT` | matching widen credit | rsp→latch term/flags→`ADD_REQ` |
| `ADD_REQ` | held add valid `(acc,term)` | fire→`ADD_WAIT` |
| `ADD_WAIT` | matching add credit | rsp→feedback；element127→`NARROW_REQ`，否则next widen |
| `NARROW_REQ` | held narrow valid | fire→`NARROW_WAIT` |
| `NARROW_WAIT` | matching narrow credit | rsp→result buffer；last row→`PUBLISH_PREP`，否则next row read |
| `PUBLISH_PREP` | 形成4B aligned write payload | →`PUBLISH_REQ` |
| `PUBLISH_REQ` | write valid | fire→`PUBLISH_WAIT` |
| `PUBLISH_WAIT` | matching GMEM credit | ack；last→`DONE`，否则next publish |
| `GMEM_DRAIN` | only retained owner transport credit; semantic frozen | rsp→`ERROR`；reset-only cause→`POISON`；deadline→`POISON_ERROR/POISON` |
| `CHILD_QUARANTINE` | child reset=1，全部child credit=0 | collision→`POISON`；GMEM owner→`GMEM_DRAIN`；abort poison→`POISON`；否则→`ERROR` |
| `DONE` | `done=1` one cycle | →`IDLE` |
| `ERROR` | `error=1` one cycle | →`IDLE` |
| `POISON_ERROR` | legacy drain timeout: `error=1, poisoned=1` one cycle | →`POISON` |
| `POISON` | `poisoned=1, done=0, error=0, ready=0` | reset only |
| `STRAY_GMEM_DROP` | retired/no-active unowned response drop; no transaction credit | fire/disappear→`IDLE`；deadline→`POISON` |

非法FSM：若有GMEM owner先进入DRAIN；若有child resident/owner先进入quarantine；
否则直接ERROR。任何路径都不能产生DONE。

## 4. 阶段 2c：不变量

| ID | 触发条件与表达式 | 违反后果 |
|---|---|---|
| I1 | `ready_o -> state==IDLE`；`done_o/error_o`互斥且单拍 | protocol fatal |
| I2 | busy期间resident descriptor/generation不变 | wrong transaction owner |
| I3 | preflight fail时所有GMEM/child req/rsp/write计数为0 | 非法访问/commit |
| I4 | `gmem_outstanding_q`只能0/1；accepted=req-rsp-reset-cancel | owner conservation failure |
| I5 | `req_valid&&!req_ready`时GMEM payload保持 | held-protocol failure |
| I6 | child owner只能由matching request fire建立、matching response fire清除 | ghost/wrong-owner |
| I7 | `element_index_q`只在matching ADD response后推进 | strict-order破坏 |
| I8 | 每行 `add_rsp_count-row_base == 128`，seed固定+0 | 127-add/x0-seed错误 |
| I9 | flags只OR真实matching widen/add/narrow response | ghost flag污染 |
| I10 | publish前全部 `result_buffer_q` 已完成；成功write ack前不增write response | partial publish |
| I11 | ERROR/quarantine/drain期间 `done_o=0`，所有semantic counters冻结 | 错误事务误提交 |
| I12 | child fault边沿非法credit=0；下一完整周期child reset=1 | stale response跨事务 |
| I13 | reset后state/owner/valid/terminal/counters清零 | stale completion |
| I14 | source与active-root无写路径；wstrb只覆盖目标F32的四byte lane | canary破坏 |

## 5. 阶段 2d：数据通路

- descriptor/generation：只在start fire更新的一组resident寄存器。
- preflight：128-bit count、span、region-end、absolute-start/end、aligned-beat
  start/end与overlap比较器；固定错误优先级，不复用运行期截断值作安全证明。
- row buffer：`NE0 x 32`，每个successful read response向相邻偶/奇entry各写一次。
- accumulator：64-bit `acc_q`，每行read完成后明确写binary64 `+0`；ADD response
  是唯一feedback更新点。
- result buffer：`ROWS x 32`，每行唯一narrow response写一个entry；publish只读。
- GMEM：一套共享held payload寄存器，由read-prep或publish-prep mux写入；REQ态
  禁止更新。
- child：三份独立HardFloat组合运算+EMPTY/FULL holding slot，不共享FMA/multiplier。
- owner：GMEM owner保存kind/generation/row/beat；每个child owner保存
  generation/row/element。比较器在ready生成前检查全字段。
- 关键组合路径：PREFLIGHT的128-bit乘加/范围/overlap；运行期最长数值路径在
  `addRecFN(11,53)`的align→add→normalize→RNE。二者均在寄存器边界结束。

## 6. 阶段 2e：RTL级九项topology冻结

1. **module边界**：三个child各一组valid-ready request/response；parent一组
   start-ready和一组single-outstanding GMEM。全部同一`clk_i`、同步高有效reset。
2. **状态寄存器**：`state_q`、resident descriptor、generation、row/beat/element/
   publish indices、GMEM payload/owner、三个child owner、acc/term/flags、watchdogs、
   counters、error/drain cause、row/result arrays；全部只在一个parent
   `always @(posedge clk_i)`更新。
3. **组合逻辑块**：128-bit preflight、GMEM/child owner-match与protocol-fault、
   request/response fire、watchdog hit、地址/strobe生成；所有组合reg有默认赋值。
4. **FSM**：精确使用§3状态和转移，不把握手/timeout/仲裁隐藏在function。
5. **pipeline/valid-ready**：parent每次只激活一个GMEM或一个child阶段；child内部
   HardFloat组合路径在request edge采样到FULL holding register，response可背压。
6. **优先级**：只引用阶段2a的
   `FIXED19_NORMATIVE_PRIORITY_BEGIN/END`；child fault后注册quarantine，
   GMEM accepted timeout后drain，abort-held request使用独立有界watchdog。
7. **资源共享/复制**：GMEM端口共享，显式read/publish mux；row/result buffer各一；
   widen/add/narrow primitive各复制一份且不共享。控制mux来源仅为parent FSM。
8. **critical path**：preflight 128-bit stride/span；F64 add的指数比较、对齐、加法、
   LZC/normalize与RNE。没有GMEM→HardFloat跨拍组合直通。
9. **function划分**：production RTL不使用function实现FSM/owner/arbiter；小型地址
   lane选择也直接组合表达。数组初始化不依赖软件循环；TB/oracle可用纯组合/raw
   helper，任何RTL `for`若出现必须注明展开的并行硬件。

拓扑自审结论：descriptor在首个request前完整驻留；GMEM和三个child owner互不
冒充credit；row/result两级buffer阻断中间状态进入shadow；quarantine/drain都位于
terminal之前；default full-profile计数在64-bit counter内，preflight中间值为
128-bit。该拓扑允许进入阶段3 RTL。

## 7. Preflight与错误码

preflight依序检查：header/profile/policy/private-shadow、op_params/reserved、shape、
canonical stride/alignment、128-bit count/span/region overflow、source bounds、
destination bounds/window/aligned beat、source/destination aligned-window overlap。
任一失败均zero request。

```text
0 NONE
1 HEADER
2 PROFILE_POLICY
3 OP_PARAMS_RESERVED
4 SHAPE
5 STRIDE_ALIGNMENT
6 SOURCE_BOUNDS
7 DESTINATION_BOUNDS
8 OVERLAP
9 GMEM_RESPONSE
10 PROTOCOL_OWNER
11 CHILD_RESPONSE
12 STALL_TIMEOUT
13 COMMAND_TIMEOUT
14 INTERNAL_STATE
15 POISONED
```

first-fault code只写一次，从capture穿过abort hold/quarantine/drain/terminal/
reset-only poison均保持。DRAIN late error只是已accepted owner的真实传输
response，不能改写timeout或任何早先cause。

## 8. 验证与证据边界

- `tb_ordered_sum_rows_ieee.sv`只用raw bits覆盖三个child的signed zero、
  subnormal、finite、Inf、qNaN、sNaN、tie、overflow、FULL hold和reset recovery。
- `ordered_sum_rows_oracle.py`禁止Python float/NumPy/libc math；用整数dyadic与通用
  RNE pack生成43+ canonical rows、逐步identity和错误模型witness。
- `tb_ordered_sum_rows.sv`必须实际执行default 2048-row transaction并逐项核对
  262144 inputs、2048 outputs、flags、owner顺序和完整cardinality；小参数实例覆盖
  preflight、backpressure、GMEM drain、child quarantine、busy-start和reset矩阵。
- 两个冻结target各只有一次Verilator O3 build/run身份；状态必须由
  `task-run-status.sh`的explicit evidence-complete授权。完整raw `__verFiles.dat`
  S-row按design/filelist source、transitive include、control、tool四类exact消费，
  mutation失败不能被PASS receipt吞掉。

## 9. 已知边界与替代解释

- 本轮不提供active-root pointer写口；private shadow中的失败partial bytes不可见，
  由父级generation丢弃。若未来需要模块内root swap，必须建立新ABI与commit FSM。
- accepted GMEM response由环境保证最终返回；当前有限fault TB必须给late response以
  证明drain。若系统不能保证最终返回，需要增加显式poisoned-reset-only系统合同，
  不能假装clean retry。
- HardFloat组合critical path未做综合/STA；功能PASS不外推时序或面积。

## 10. fixed-4 source-scoped repair identity

`ordered-sum-rows-fixed-4`只根修fixed-3完整engine在动态执行前暴露的六项
新源码warning；合同JSON SHA-256为
`ae3d113be60508b9c7e456c996ff6589ec83df9571068e46d49723f602fab5bf`。

- 三个integer timeout参数先进入显式32-bit localparam，再与显式32-bit零拼成
  64-bit watchdog值；deadline数值、优先级与状态转移不变。
- odd row-buffer地址由已经bounded的`read_even_array_index_w`加同宽常量1形成，
  删除没有语义消费者的32-bit odd intermediate；地址仍严格为`2*beat+1`。
- full-profile TB对每次成功`$fgets`实际检查`vector_line.len()`，同时保留恰好
  60行及EOF检查；clock初始化和翻转合并到一个timing-only process。
- fixed-3 IEEE child PASS作为immutable predecessor使用而不重跑；fixed-3 engine
  `FAIL rc=73 stage=engine-warning-audit`作为反例绑定。fixed-4只允许一个fresh
  engine O3 build/run，且不增加production RTL/TB waiver。

这些修改不触及算术DAG、resident descriptor、GMEM/child owner、timeout命中规则、
drain/quarantine、sticky flags、result buffer或private-shadow publish eligibility。
# fixed-5 source-width repair and evidence identity

The fixed-4 full-engine build completed elaboration but stopped fail-closed at
`engine-warning-audit` with `rc=74`; its binary was never executed.  That build
isolated four production-source diagnostics: three `WIDTHCONCAT` warnings on
the watchdog timeout constants and one `UNUSEDSIGNAL` warning on the high bits
of the 32-bit even row-buffer index.  fixed-5 binds that immutable failure, the
fixed-3 engine `rc=73` failure, and the fixed-3 IEEE-child PASS instead of
rerunning any predecessor target.

`TensorNpuOrderedSumRows` now enters each watchdog comparison through an
explicit 64-bit SystemVerilog sized cast.  No integer-derived timeout value is
concatenated, and the deadline values, comparisons, and response-over-timeout
priority remain unchanged.  Even and odd row-buffer indices are formed only in
the bounded `ELEMENT_ARRAY_WIDTH` domain from the low resident beat bits; the
wide intermediate and its unconsumed high bits no longer exist.  The fixed-4
full testbench remains byte-identical.

The fixed-5 evidence identity is bound to
`tmp/contracts/ordered-sum-rows-fixed-5.json` with SHA-256
`f74e23630f9a1d8d829c1e62158466035b5629b5ec37994ea4fc4fd8b9c243a3`.
Only a fresh full-engine O3 build whose actual four-class membership, exact
locked-warning census, source-scoped zero-warning gate, predecessor bindings,
and mutation checks all pass may execute its binary once.  PASS remains gated
on the exact 2048-row/262144-element cardinality marker, 60 raw-oracle rows,
the bounded fault/reset/retry matrix, source post-hash, cleanup, immutable
receipt, and final-status binding.
# fixed-6 child-fault post-NBA witness repair

The fixed-5 full-engine run proved the complete 60-row raw oracle and exact
2048-row/262144-element cardinality, then stopped fail-closed with `rc=134` at
`widen ghost missed registered quarantine`.  Its pre-edge production
`widen_owner_fault_w` witness was asserted, but the testbench released the
forced source in the same active region as the DUT sampling posedge.  That
ordering was a testbench race, not a production-predicate counterexample.

fixed-6 holds each of the four child ghost/wrong-owner forces through the DUT
sampling edge.  One time unit after the edge, while the force is still active,
the TB checks the registered `ST_CHILD_QUARANTINE`, `ERR_CHILD_RESPONSE`, owner
revocation, disabled GMEM/child request and response credits, and an unchanged
resident coordinate/owner-tag/counter/flags snapshot.  Only then is the force
released.  The ghost fixture also backpressures GMEM during its fault edge so
that no unrelated request can be accepted without a production owner ledger.
The existing child-timeout fixture already holds its force through registered
quarantine and is unchanged.

The fixed-6 evidence identity is bound to
`tmp/contracts/ordered-sum-rows-fixed-6.json` with SHA-256
`d9f631cc1287e4169a51714a508d997d79e6505269f506433af1ea0208d8126a`.
Production `TensorNpuOrderedSumRows` remains byte-identical to fixed-5 SHA-256
`10439093b5315fa360ab774f45a9ce32d9a47eb68a44e1648fb3cb3eefa4f495`.
PASS still requires a unique fresh full-engine O3 build/run, exact actual
four-class membership and warning census, all four post-NBA fault witnesses,
all five child fault fixtures and clean retries, the complete bounded matrix,
source post-hash, cleanup, receipt and final-status binding.

# fixed-7 first-fault/event-ledger repair

`ordered-sum-rows-fixed-7` binds the immutable fixed-6 full-engine PASS and the
static-review counterexamples to contract JSON SHA-256
`fce1a5871bf1ed1d46526c3f809fc1a910068024c98877a06d0ae8ac0110ee51`.
The repair changes transaction lifecycle arbitration, not the ordered numeric
DAG or descriptor policy.

## fixed-7 phase 1: contract and observable boundary

Every externally accepted GMEM request/response and every accepted IEEE-child
request/response is a real event even when an independent protocol fault is
sampled at that same edge.  Such an event must update its owner and cardinality
ledger exactly once, but a fault edge must not update row data, accumulator,
result buffer, publish index, `rows_reduced_o`, `elements_processed_o`, or
commit eligibility.  The first fault captures the post-event ledger view and
is immutable through cleanup.  `done_o`/`error_o` remain irrevocable one-cycle
completion pulses because this module has no completion-ready input; a ghost
sampled during that pulse starts post-terminal cleanup without withdrawing the
already visible completion or issuing a second terminal pulse.

## fixed-7 phase 2a--2e freeze

- **2a state:** resident descriptor and arithmetic coordinates remain the
  semantic state.  Accepted-owner bits plus their generation/row/index tags are
  the transport state.  `fault_latched_q`, first-fault cycle/coordinate/address,
  post-event counter snapshots, and `cleanup_suppress_terminal_q` form one
  transaction-local fault ledger.
- **2b events:** GMEM/child `valid && ready` fires are computed independently of
  the fault arbiter.  Their owner/count next values are applied once after the
  semantic FSM decision, so a simultaneous fault cannot erase a real fire.
  Matching responses at a watchdog deadline outrank timeout; error responses
  outrank successful responses.
- **2c first-fault arbitration:** synchronous reset > owner/ghost/corruption >
  matching GMEM error response > command timeout > phase stall timeout > normal
  semantic progress.  The first matching cause alone writes the fault ledger.
- **2d cleanup:** every nonterminal fault enters one complete registered
  `ST_CHILD_QUARANTINE` cycle.  Child request/response credit is revoked during
  that cycle and throughout `ST_GMEM_DRAIN`.  After quarantine, any accepted
  GMEM owner is drained by its saved tag; error completion is not published
  until both resource classes are clean.  Drain exhaustion alone enters the
  reset-only poison boundary.
- **2e terminal/IDLE:** owner faults combinationally gate `ready_o`, so an IDLE
  descriptor cannot fire on the same edge as a ghost.  A fault coincident with
  the last narrow or shadow-ack success suppresses semantic success.  A fault
  observed while an already visible DONE/ERROR pulse is held initiates cleanup
  with terminal suppression, preserving that pulse and delaying the next
  `ready_o` until cleanup completes.

## fixed-7 nine-item topology

1. Module ports and the three immutable IEEE children are unchanged.
2. The existing single parent sequential process remains the sole writer of
   FSM, owners, snapshots, buffers, and counters.
3. Combinational logic is split into owner match/fault, phase fire, watchdog,
   first-fault selection, and post-event next-ledger expressions.
4. `ST_CHILD_QUARANTINE` always precedes optional `ST_GMEM_DRAIN` for a new
   fault; neither state permits semantic progress.
5. GMEM and child held-request payloads remain stable until fire; deadline
   arbitration never deasserts a valid solely because the counter reached its
   limit.
6. First-fault precedence is exactly the 2c ordering above and is shared by all
   operational states, IDLE, and terminal states.
7. The row/result buffers and all arithmetic resources are unchanged; only the
   transport/fault owner muxing changes.
8. No new arithmetic critical path is introduced.  The added path is bounded
   control OR/compare logic ending at owner/counter/fault registers.
9. Production control remains explicit RTL without a hidden task/function;
   directed TB hierarchical witnesses observe the actual predicates, fires,
   registered quarantine, saved owner, and post-event snapshots.

The fixed-7 evidence identity is new and may execute exactly one fresh O3
full-engine build/run only after source/config/runner/membership/warning and
predecessor preflight gates pass.  It must add overlap witnesses for both
directions (child fault with GMEM fire/owner and GMEM fault with child
fire/response), IDLE command rejection, last-success suppression, terminal
irrevocability, and deadline response priority without reducing the 60-row,
2048-row, or 262144-element coverage.

# fixed-8 first-fault diagnostic completion interface

`ordered-sum-rows-fixed-8` binds the immutable fixed-7 build-success/
warning-audit-failure identity to contract JSON SHA-256
`6caf0d2f6c4502ee821e18cd3ef156706b0ae578dc4f18b784e7e6d5a66e3a3d`.
It repairs only the fixed-7 `UNUSEDSIGNAL` root cause: the post-fire
first-fault record is now a real transaction diagnostic interface rather than
verification-only resident state.

## fixed-8 phase 1: observable requirement

The first fault of a transaction publishes `fault_valid_o` plus cycle,
`{row,read_beat,element,publish}` coordinate, held GMEM address, sticky flags,
and total accepted request/response events after all real fires on that edge.
The record is immutable throughout registered child quarantine, accepted GMEM
drain, error/poison completion and the following IDLE hold.  Reset or the next
clean `start_i && ready_o` is the only invalidation event.  A successful
transaction exposes `fault_valid_o=0` and an all-zero payload.

## fixed-8 phase 2a--2e freeze

- **2a protocol:** diagnostic outputs have no ready input and therefore behave
  as held status.  They are sampled from the same single-writer registers as
  the fixed-7 first-fault ledger; no log-only or reduction consumer is used.
- **2b FSM:** arithmetic, GMEM and cleanup states are unchanged.  `ST_ERROR`,
  `ST_GMEM_DRAIN` post-terminal cleanup and `ST_CHILD_QUARANTINE`
  post-terminal cleanup may return to IDLE without clearing the diagnostic.
  A clean command capture clears it before `ST_PREFLIGHT`.
- **2c invariants:** `fault_valid_o=0` implies every diagnostic payload bit is
  zero; while valid, every payload bit is stable until reset/start-fire;
  subsequent cross-resource faults and drain responses cannot overwrite the
  first cause; success DONE never carries a valid record.
- **2d datapath:** each output is a direct validity-gated view of its resident
  snapshot register.  The snapshot values remain the fixed-7 post-fire
  `active_cycles_after_w`, coordinate, GMEM payload address,
  `flags_after_events_w`, `request_events_after_w` and
  `response_events_after_w` networks.
- **2e topology:** the module adds seven output-only ports; no input,
  backpressure, child instance, owner, buffer or arithmetic path changes.  The
  only new combinational paths are validity muxes from resident registers to
  output pins, and the only sequential change removes terminal/cleanup clears
  that previously invalidated the record before the next command.

The independent TB scoreboard computes the expected record from public
counters, production fire signals and matching child response flags before the
sampling edge.  It checks the output after NBA and on every following negedge,
including quarantine/drain, terminal, IDLE hold and next-command clear.  The
named closure marker is
`[NPU-ORDERED-SUM-ROWS][FAULT-OUTPUT] captures=44 success_zero=16 stable=1`.
All fixed-7 numeric, preflight, overlap, cleanup, reset, retry and full-profile
fixture cardinalities remain unchanged.

# fixed-9 fault-edge oracle dimension repair

`ordered-sum-rows-fixed-9` binds the immutable fixed-8 production RTL and its
unique build-success/native-run-failure evidence to contract JSON SHA-256
`619026547b2f4e60cd64adab9089627aec6612a25bbee281c199c350b35e4bf4`.
The fixed-8 first failure was
`[NPU-ORDERED-SUM-ROWS][FAIL] gmem-ghost+widen-request post-NBA snapshot`
with native rc 134.  The production fault predicate, registered quarantine,
post-fire total request counter and child owner were correct.  The TB helper
incorrectly reused its all-resource request-event delta as the expected delta
of the GMEM model's `small_accept_count`.

## fixed-9 phase 1 and phase 2a--2e freeze

- **Observable requirement:** every fault-edge witness checks two independent
  dimensions: `expected_total_request_event_delta` covers GMEM plus all three
  IEEE-child request fires, while `expected_gmem_accept_delta` covers only a
  GMEM-model request acceptance.  The `small_accept_count` equality remains a
  strict equality and is not derived from a DUT aggregate counter.
- **Protocol/FSM:** production request, response, owner, first-fault, drain,
  quarantine and terminal behavior is byte-for-byte fixed-8.  Only the
  testbench oracle signature, its nine explicit call-site expectations and
  the witness text change.
- **Invariant:** `widen-ghost+gmem-fire` must report total-request delta 1 and
  GMEM-accept delta 1; `gmem-ghost+widen-request` must report total-request
  delta 1 and GMEM-accept delta 0; every remaining named fault-edge fixture
  explicitly supplies GMEM-accept delta 0.  Response-event expectations stay
  independent and unchanged.
- **Datapath/topology:** no production RTL port, register, combinational path,
  buffer, arithmetic child or GMEM path changes.  The TB marker prints both
  `total_request_delta` and `gmem_accept_delta`, permitting the evidence
  runner to bind both discriminating combinations exactly once.

The fixed-9 run retains the 60-row integer oracle, 2048-row/262144-element
full profile, nine fault-edge witnesses, 44 first-fault captures, 16
success-zero checks, all cleanup/reset/busy/retry fixtures, and the exact
source-scoped warning and raw S-row membership gates from fixed-8.

# fixed-10 GMEM ghost single-writer repair

`ordered-sum-rows-fixed-10` binds the immutable fixed-9 preflight/build and
native-run rc134 evidence to contract JSON SHA-256
`adb1295257129491fee6b76157fbb9d7c1e0c3b7db41a70e999c2d5e276b6b36`.
Fixed-9 dynamically cleared both request-accounting dimensions, then failed
with `[NPU-ORDERED-SUM-ROWS][FAIL] small instance did not return ready` after
the GMEM ghost fixture released a forced procedural response-valid variable.

## fixed-10 phase 1 and phase 2a--2e freeze

- **Observable requirement:** the normal GMEM model valid source and the
  synthetic ghost source are independent single-writer variables.  The DUT
  sees their explicit OR.  A named witness proves ghost pre=1, post=0,
  normal-model valid=0, owner-fault predicate=1, GMEM response ready=0, real
  child-request fire=1, zero model-response-count delta, and a clean retry.
- **Protocol:** only `small_rsp_valid_model_q` participates in model pending,
  response completion and `small_response_count`; the ghost overlay cannot
  clear pending or manufacture response credit.  The fixed-10 aggregate-valid
  request interlock is archival only and is removed by fixed-19 so the two
  intentional same-channel collision fixtures can expose a real request fire.
- **FSM:** production quarantine, owner cleanup and terminal transitions are
  unchanged.  The TB lowers its overlay explicitly after the fault sampling
  edge and verifies the combined DUT input is zero before waiting for the
  registered quarantine cycle and ready recovery.
- **Invariants:** production `TensorNpuOrderedSumRows.v` remains byte-identical
  to fixed-8/9.  Ghost injection preserves model pending and response count;
  no global reset, internal-state deposit, timeout relaxation or removed
  fixture is used for recovery.
- **Datapath/topology:** `small_rsp_valid_model_q` is written only by the GMEM
  model posedge process; `small_rsp_valid_ghost_q` is written only by the main
  fixture process; `small_rsp_valid_i` is a wire equal to their OR.  All DUT,
  IEEE-child, memory payload and arithmetic paths remain unchanged.

The named closure marker is
`[NPU-ORDERED-SUM-ROWS][GMEM-GHOST-DRIVER] pre=1 post=0 model=0 predicate=1 ready=0 child_req_fire=1 response_delta=0 retry_clean=1`.
All fixed-9 request-dimension, first-fault diagnostic, full-profile and
fault/recovery cardinalities remain required.

# fixed-11 final shadow ack event-wait repair

`ordered-sum-rows-fixed-11` binds the immutable fixed-10 preflight/build and
native-run rc134 evidence to contract JSON SHA-256
`e63d4419c155c9e671d5b8f5abcb8d5dda09748aab65adbb3cd5d9525fe3a4fc`.
Fixed-10 dynamically closed the GMEM ghost driver witness and seven
fault-edge overlaps, then failed because the final-shadow fixture treated the
first `ST_PUBLISH_WAIT` negedge as if a model response were already valid.

## fixed-11 phase 1 and phase 2a--2e freeze

- **Observable requirement:** the fixture first establishes final publish
  WAIT, index 1, matching write-owner identity, expected aligned destination
  address and GMEM-model pending.  It then separately waits for normal model
  valid and the real matching `gmem_rsp_fire_w` before introducing the child
  ghost.
- **Protocol:** the matching GMEM ack and child owner fault coexist during the
  same pre-edge phase.  The response must receive one transport credit while
  the child fault wins semantic/terminal priority.  No synthetic GMEM
  response, timeout relaxation or direct DUT-state deposit is permitted.
- **FSM:** after the sampling edge the registered state is
  `ST_CHILD_QUARANTINE`, never `ST_DONE`; the GMEM owner and normal model
  pending/valid are cleared by the matching response, child ownership is
  quarantined, and cleanup must return to a clean retry without reset.
- **Invariants:** `small_gmem_write_responses_o` and the independent model
  response count each advance exactly once; `small_done_count` has delta zero;
  the first-fault post-fire snapshot includes response delta one and cannot be
  overwritten.  Transaction-private shadow writes do not gain visible commit
  eligibility.
- **Datapath/topology:** production RTL and the fixed-10 GMEM model/ghost OR
  structure remain unchanged.  Only the final-shadow fixture's event wait,
  pre/post snapshots and named evidence marker change.

The fixed-11 closure marker is
`[NPU-ORDERED-SUM-ROWS][FINAL-SHADOW-ACK-EVENT] wait_seen=1 pending_seen=1 model_valid=1 owner_match=1 ack_fire=1 child_fault=1 post_quarantine=1 commit_delta=0 response_delta=1 retry_clean=1`.
All nine fault-edge, first-fault diagnostic, numeric, cleanup/reset/busy/retry
and full-profile cardinalities remain required.

# fixed-12 one-shot fault / held-request / retired-cleanup repair

`ordered-sum-rows-fixed-12` binds fixed-11's genuine full-engine dynamic PASS
and the independent static-review-v2 counterexamples to contract JSON SHA-256
`7a1afe8929fb5aeda207c8f747247ac1d8b62e64860ed0cc7b00f5e0c230cbc0`.
The repair changes the transport-fault lifecycle and diagnostic ABI; it does
not change the strict ordered F32-to-F64/add/narrow DAG, descriptor preflight,
row/result buffers or private-shadow commit boundary.

## fixed-12 phase 1: verifiable requirements

1. A level fault is detected every cycle but captured at most once per accepted
   descriptor.  Persistent ledger corruption cannot preempt the registered
   quarantine/drain state after the first capture.
2. Every externally exposed GMEM, widen, add or narrow request obeys an
   uncancellable valid-ready contract.  Once observed as `valid && !ready`,
   valid and the entire payload remain bit-stable until the real fire.  A fault
   records abort intent but cannot withdraw that request or invent a fire.
3. An accepted descriptor has exactly one completion eligibility.  After its
   DONE/ERROR pulse retires, an unowned child/GMEM late response enters bounded
   terminal-suppressed cleanup and cannot create another `ERR_NONE` or other
   terminal pulse.
4. The resident command gains `txn_tag_i[31:0]`.  First-fault status exposes the
   command tag, generation, cause resource and post-fire owner
   type/valid/generation/row/index in addition to the fixed-8 cycle,
   coordinate, GMEM address, flags and event totals.  Reset or the next clean
   start fire is the only invalidation event; success remains invalid/all-zero.
5. Matching GMEM and all three child request/response fires win over a watchdog
   deadline on the same edge.  Real event accounting and matching flags are
   retained exactly once.

Out of scope remains synthesis, STA, PPA, backend/36-node atomic commit, Qwen
execution and any modification to the three IEEE children or third-party
HardFloat sources.

## fixed-12 phase 2a: protocol rules

- `txn_active_q` is set only by `start_i && ready_o`; it remains set through the
  single visible terminal state and clears when that pulse retires.
- `fault_detect_w` is the current level predicate.  Only
  `fault_capture_event_w = fault_detect_w && txn_active_q &&
  !fault_latched_q && !terminal_state_w` may latch the first cause.
- If capture occurs while the current request is `valid && !ready`,
  `abort_hold_q` is set and the request state is retained.  All younger
  semantic work is frozen.  The later real request fire establishes its owner
  and increments its request counter before registered child quarantine.
- A first fault without a held request enters one complete
  `ST_CHILD_QUARANTINE` cycle immediately.  Persistent cause levels cannot
  re-enter the capture branch.
- Active-fault cleanup quarantines every child, then drains every accepted GMEM
  owner.  A drain timeout enters the reset-only poison boundary.  No semantic
  buffer/index/counter gains commit eligibility during cleanup.
- A ghost in DONE/ERROR or IDLE is a `retired_cleanup_event_w`, not a new
  transaction fault.  It preserves the existing first-fault record, suppresses
  terminal generation, executes child quarantine, consumes an unowned GMEM
  response in `ST_STRAY_GMEM_DROP`, and returns to IDLE.
- A clean start fire atomically clears previous diagnostics/counters and
  captures the new tag/descriptor.  An ingress ghost combinationally revokes
  `ready_o`, so descriptor capture and retired cleanup cannot both win.

## fixed-12 phase 2b: FSM extension

The arithmetic/preflight states remain those in section 3.  Their fault-side
transitions are refined as follows:

| current condition | next state / action |
|---|---|
| first fault, no held request | latch post-fire record; `ST_CHILD_QUARANTINE` |
| first fault, request `valid&&!ready` | latch record + `abort_hold_q`; retain exact request state/payload |
| `abort_hold_q` and request not fired | retain state/valid/payload; ignore watchdog cancellation |
| `abort_hold_q` and exact request fires | account owner/request once; clear abort; `ST_CHILD_QUARANTINE` |
| active quarantine with GMEM owner | `ST_GMEM_DRAIN` |
| active quarantine clean | `ST_ERROR` |
| suppressed quarantine with unowned GMEM valid | `ST_STRAY_GMEM_DROP` |
| suppressed quarantine otherwise | `ST_IDLE`, no completion |
| stray-drop valid | assert ready; fire/drop once; `ST_IDLE` |
| stray-drop disappearance/timeout | bounded return/poison without terminal duplication |
| DONE/ERROR + ingress ghost | preserve visible pulse; arm suppression; quarantine next |

The following fixed-12 ordering is archival rationale, not a second normative
priority table.  Current arbitration is defined only by the fixed-19 marked
table in section 2a.  Its enduring property is that every real transport fire
is accounted exactly once and a timeout is eligible only when the relevant
true fire is absent.

## fixed-12 phase 2c: invariants

| ID | invariant | failure meaning |
|---|---|---|
| F12-I1 | each start fire sets one active transaction; each active transaction emits at most one DONE/ERROR pulse | duplicate/missing completion |
| F12-I2 | `fault_latched_q` writes once per active transaction and cannot redirect cleanup after capture | persistent-fault livelock |
| F12-I3 | prior-cycle request `valid&&!ready` implies current valid and identical payload unless current fire occurs | uncancellable request withdrawal |
| F12-I4 | abort-held request fire increments exactly one request count and creates exactly one matching owner before quarantine | lost/invented transport event |
| F12-I5 | archival recoverable-error rule; fixed-19 reset-only poison may coexist with held valid or retain a collision owner solely for diagnosis, while response ready and every terminal remain zero | premature terminal/ghost credit |
| F12-I6 | no-active/retired ingress ghost cannot set first-fault valid, overwrite diagnostics or generate DONE/ERROR | duplicate `ERR_NONE` terminal |
| F12-I7 | first-fault tag/generation/resource/owner fields are the post-fire view and remain stable until reset/new start | stale epoch misdiagnosis |
| F12-I8 | matching request/response fire on a deadline edge is counted and beats timeout | lost real event/flags |
| F12-I9 | success exposes fault-valid zero and every diagnostic payload bit zero | false fault attribution |
| F12-I10 | semantic row/result/publish progress is disabled on capture, abort-hold and every cleanup state | failed transaction commit |

## fixed-12 phase 2d: datapath constraints

- The resident descriptor adds only `txn_tag_q[31:0]`; `generation_q` remains
  the one-bit transaction epoch used by all owner comparators.
- `abort_hold_q` and `txn_active_q` are single-bit lifecycle registers.  No
  request payload is recomputed after entering a request state.
- Cause resource uses a compact control/GMEM/widen/add/narrow encoding.  Owner
  type independently encodes none, GMEM-read, GMEM-write, widen, add or narrow.
  Owner identity is selected from the same-edge fire first, then the surviving
  resident owner, so the captured fields are post-fire without reading a
  future cleanup state.
- `ST_STRAY_GMEM_DROP` is the only ownerless GMEM response-credit source.  Its
  response is never included in the retired transaction's semantic or
  diagnostic event totals.
- Arithmetic flags still OR only matching child response fires.  A deadline
  fire contributes its real flags before any subsequent fault cleanup.

## fixed-12 phase 2e: nine-item RTL topology freeze

1. **Boundary:** add `txn_tag_i` and eight validity-gated first-fault identity
   outputs; existing start/GMEM/terminal/counter ports and all child ports keep
   their clock/reset/valid-ready rules.
2. **Registers:** the sole parent `always @(posedge clk_i)` additionally owns
   `txn_tag_q`, `txn_active_q`, `abort_hold_q`, quarantine-complete/suppression
   state and first-fault resource/owner snapshots; reset clears all.
3. **Combinational blocks:** retain preflight and owner matching; split the old
   monolithic fault signal into level detect, first-active capture,
   retired-ingress cleanup, held-request/fire classification and post-fire
   owner snapshot muxes.
4. **FSM:** retain all numeric states, add only explicit ownerless GMEM drop;
   abort hold deliberately remains in the original request state.
5. **Pipeline/flow:** GMEM and child request valid flow stays registered-state
   driven; abort blocks younger state advance but not ready/fire.  Child reset
   is asserted for a complete quarantine/drain cycle.
6. **Priority:** this fixed-12 list is superseded and non-normative; use only
   the marked fixed-19 table in section 2a.
7. **Resources:** GMEM, buffers and three IEEE children are unchanged.  Added
   control muxes select diagnostic resource/owner identity; no arithmetic
   resource is shared or replicated differently.
8. **Critical path:** the new path is bounded owner/fire/fault priority and a
   small identity mux into snapshot registers.  The HardFloat and 128-bit
   preflight critical paths are unchanged.
9. **Function split:** lifecycle/FSM/owner/diagnostic logic remains explicit
   combinational and sequential RTL; no function/task hides arbitration.
   Existing array indexing stays explicit bounded hardware.

Topology self-review: a fault cannot erase an already presented request; a
persistent cause cannot preempt cleanup after its one-shot capture; an
ownerless late response can be consumed only in a terminal-suppressed state;
and every first-fault identity field has one real output consumer.  The frozen
topology is therefore eligible for fixed-12 production RTL implementation.

## fixed-12 production realization and directed closure map

The implemented fault lifecycle uses three different predicates rather than
reusing one level signal as an FSM override.  `fault_detect_w` is the ordered
cause level, `fault_capture_event_w` is a one-shot qualified by
`txn_active_q && !fault_latched_q && !terminal_state_w`, and
`retired_cleanup_event_w` handles only owner faults after the descriptor has
retired.  A persistent `ledger_corrupt_w` can therefore capture once but cannot
preempt the following registered `ST_CHILD_QUARANTINE` or `ST_GMEM_DRAIN`.

`abort_hold_q` is set only when the first fault is sampled while one of
`ST_ROW_READ_REQ`, `ST_PUBLISH_REQ`, `ST_WIDEN_REQ`, `ST_ADD_REQ`, or
`ST_NARROW_REQ` exposes valid without a matching fire.  The FSM remains in that
request state, so valid and its complete payload remain unchanged.  The later
real `held_request_fire_w` is written by the common transport ledger exactly
once, establishes the corresponding owner, and only then transfers control to
registered child quarantine.  Timeout comparison already includes
`!phase_fire_w`; a matching deadline fire consequently keeps its real counter,
owner and response flags.

No-active child ghosts enter terminal-suppressed quarantine.  No-active GMEM
ghosts additionally use `ST_STRAY_GMEM_DROP`, whose ready/fire is excluded from
the retired transaction's request/response totals.  Neither path creates a new
DONE/ERROR, changes `error_code_q` to a fabricated `ERR_NONE` completion, or
overwrites the retained first-fault record.  Clean `start_fire_w` clears that
record and assigns the next `txn_tag_i`/generation.

The full TB owns the expected capture edge independently: fixtures explicitly
arm an expected resource/owner/coordinate record, while event totals are
computed only from real request/response fires and public counters.  It never
uses `fault_detect_w`, `fault_capture_event_w`, or `fault_latched_q` as the
oracle capture enable.  Named fixed-12 killers are:

- `PERSISTENT-LEDGER-CORRUPT`: level corruption stays asserted across
  quarantine and the GMEM-drain decision, then produces one bounded error and
  a reset-free retry;
- `HELD-GMEM-REQ-FAULT`: both read and private-shadow publish requests are held
  for multiple cycles, faulted, kept stable through abort, accepted once, and
  drained before one error;
- `HELD-CHILD-REQ-FAULT`: widen, add and narrow requests receive the same
  valid/payload/one-fire/one-owner proof;
- `POST-ERROR-LATE-GHOST`: separate child and GMEM late responses are
  suppressed/dropped with zero completion and diagnostic deltas;
- `DEADLINE-FIRE-WINS`: two GMEM request, two GMEM response, and all six child
  request/response stall-deadline edges plus the final GMEM response command
  deadline are credited without timeout;
- `FIRST-FAULT-IDENTITY`: tag, generation, resource, owner type/valid/
  generation/row/index are compared on every active fault and held stable
  through cleanup, terminal and IDLE; success requires all fields zero.

The arithmetic DAG, 128-bit descriptor preflight, row/result buffers, sticky
flag sources, private-shadow publish qualification and all three IEEE children
are unchanged by this lifecycle repair.  Fixed-12 evidence remains module
local; it does not claim 36-node backend atomicity, synthesis, STA, PPA or
tokens/s.
## fixed-13 width and warning-evidence separation

`ordered-sum-rows-fixed-13` keeps `TensorNpuOrderedSumRows.v` byte-identical
to the fixed-12 production identity.  The four bounded TB loops that stop one
cycle before the eight-cycle phase watchdog now compare the 64-bit production
`stall_cycles_q` against one typed `SMALL_STALL_TIMEOUT_LAST[63:0]`.  This is a
width-only repair: the threshold remains seven and a matching request/response
fire at that edge continues to outrank timeout.

The fixed-13 evidence topology separates two different propositions that the
fixed-12 runner conflated.  During preflight, a fixed-13-local parser consumes
the immutable fixed-2 unwaived build log and must reproduce the frozen 13-row
HardFloat census exactly.  During the fresh fixed-13 build, the fixed-13-local
exact third-party waiver is applied and the live log must contain zero warning
and zero error rows; the 13-row parser is deliberately not applied to that
clean log.  The local parser, expected census, census-to-waiver map and waiver
are source-identity members and no predecessor runner or parser is sourced,
executed, transformed or evaluated.

The fixed-12 preflight PASS and its build-rc0/warning-audit-rc76/unrun-binary
identity are immutable predecessor evidence.  Dynamic acceptance remains
conditional on the one fixed-13 binary reaching the complete numeric,
cardinality, P0-killer, 11-edge deadline, first-fault identity and cleanup
markers; no fixed-12 runtime result is inferred from its unrun binary.

## fixed-14 post-error late-GMEM-ghost settle repair

`ordered-sum-rows-fixed-14` keeps `TensorNpuOrderedSumRows.v` byte-identical
to SHA-256
`e861a3d56cea794461db3a396ba081b85e7d7050d1a5f1f4a4dee83a292a91fd`.
The immutable fixed-13 build was clean and its full numeric/cardinality path
ran, but its unique native run stopped at rc134 because the late-GMEM-ghost
fixture cleared `small_rsp_valid_ghost_q` and read combinational `ready_o` in
the same active region.  That merged assertion did not identify which of its
eight predicates failed and cannot be reinterpreted as a production PASS.

The fixed-14 TB freezes three explicit sampling phases.  First, the ghost
overlay remains asserted through the posedge that consumes a true
`ST_STRAY_GMEM_DROP` response fire.  In that edge's active region, before any
NBA, local blocking snapshots independently prove the registered state is
`ST_STRAY_GMEM_DROP`, `gmem_stray_rsp_fire_w=1`, ghost overlay is one and the
normal single-writer model's `small_rsp_valid_model_q=0`.  After the production
NBA, the TB proves the model remains isolated, then checks `ST_IDLE`, zero
terminal pulses and zero done/error/fault-capture/model-response counter deltas
individually.  Second, the TB clears only the overlay and yields exactly 1 ns,
strictly below the 5 ns half-cycle and therefore not coincident with a clock
edge, before checking overlay/model input low, `gmem_owner_fault_w=0`,
`ready_o=1` and the same eight independently named witnesses.  Third, it
crosses exactly one additional posedge with the overlay low and proves the
state remains `ST_IDLE`, registered child quarantine does not re-enter,
cleanup suppression stays clear and no completion or response credit appears.
A normal clean transaction must then succeed before the detailed exact-one
`POST-ERROR-LATE-GHOST` marker is emitted.

This is a verification-phase repair only: the real late-child and late-GMEM
ghost injections, one-shot fault ledger, owner cleanup, shadow eligibility,
numeric DAG, descriptor preflight, watchdog priority and all existing counter
oracles remain unchanged.  Fixed-14 acceptance still requires one fresh O3
build/run to reach all three P0 killers, the 11 matching-fire deadline edges,
60-row oracle, full 2048-row/262144-element cardinality, first-fault identity
and the complete fault/reset/cleanup matrix.  It does not claim synthesis,
STA, PPA, backend integration, Qwen graph completion or tokens/s.

## fixed-15 first-fault address provenance and independent oracle

The fixed-14 dynamic evidence passed, but the subsequent static review found
that `first_fault_gmem_addr_q` always sampled `gmem_req_addr_q`.  That payload
is intentionally retained while a request is exposed, yet it is not an owner:
after a successful transaction its last publish address could therefore leak
into a later descriptor's preflight/control fault.  Fixed-15 adds the separate
`gmem_owner_addr_q` ledger.  It is established only by a real GMEM request
fire, cleared by its matching response retirement, reset and a clean accepted
descriptor, and otherwise changes neither the request payload nor GMEM owner
matching.

The diagnostic address mux has one frozen priority:

1. an exposed or same-edge-firing GMEM request contributes its held
   `gmem_req_addr_q`;
2. otherwise an accepted GMEM owner contributes `gmem_owner_addr_q`;
3. otherwise the address is exactly zero.

Consequently a fault never attributes an inactive transaction's stale request
payload.  A request that was already presented still remains valid with stable
payload through a later fault until its true fire; matching deadline fire still
wins timeout; and a late GMEM error drained after first-cause capture remains a
cleanup event rather than a replacement cause.

The full TB's expected first-fault record is also made structurally
independent.  Each fixture supplies the expected coordinate, GMEM address,
resource/owner identity, request/response event deltas and arithmetic flag
delta before the sampling edge.  Cycle, transaction tag and generation come
from the TB-owned accepted-command model, while event bases and flags come only
from public outputs.  The delimited expected-oracle source contains no
`u_small_dut` reference, no DUT fault selector/latch/fire signal and no
`small_req_addr_o` dependency.  Compile-clean coordinate, address and event
mutations must each be rejected by this same comparator before the production
run is accepted.

Five named address-provenance killers cover the complete mux:

- `STALE` follows a successful private-shadow publish with a new bad-header
  descriptor and requires CONTROL/NONE/address zero;
- `HELD` faults a ready-low private-shadow write request and requires its exact
  nonzero descriptor-derived address;
- `OWNED` faults while a nonzero-address read owner awaits its response;
- `CROSS-FIRE` overlaps a child fault with a real nonzero GMEM request fire;
- `OWNERLESS` overlaps an ownerless GMEM ghost with a child request and requires
  address zero despite the real child event.

These changes do not alter arithmetic, descriptor preflight, row/result
buffers, sticky flags, timeout priority, quarantine/drain or shadow commit
eligibility.  Evidence fields named assert/trace/coverage/wave/core only audit
forbidden artifact absence; they are not a claim of formal assertion or
coverage closure.  Fixed-15 remains module-local and makes no synthesis, STA,
PPA, backend, Qwen or tokens/s claim.
## Fixed-16：同一 O3 binary 的运行时 first-fault oracle 变异

### 阶段 1 / 2a--2e 冻结

- 需求：`TensorNpuOrderedSumRows` production RTL 保持 fixed-15 SHA-256
  `5ce80477369ef4ec637341a2489bd67757fc2dadc1632119f2cfebf4cdcce06b`；
  只修复 TB 负向 oracle 的 identity，使 coordinate、GMEM address、request-event
  三类错误都由同一个 warning-clean binary 动态拒绝。
- 协议：TB 在 t=0 只读取一次 `+ORACLE_MODE=`；缺省值为 `production`，其余合法值
  仅为 `wrong-coordinate`、`wrong-gmem-address`、`wrong-event-delta`。运行期间 selector
  不更新，DUT 输入、输出和 fixture 时序不因 selector 改变。
- 控制：DUT FSM 不变。TB 的四态 mode register 选择 expected-record capture mux；负向模式
  在第一个 fixture-owned first-fault record 上，只允许目标字段不匹配且所有非目标字段匹配，
  随即输出 exact-one `[NPU-ORDERED-SUM-ROWS][ORACLE-MUTATION][REJECT]` 并非零退出。
  `production` 模式不得出现 REJECT，并执行完整 full/small regression 后才有 PASS 资格。
- 不变量：四个 mode 使用同一 elaborated source graph 与同一 binary；无编译期 mutation macro；
  三类负向各只扰动一个 expected 字段且绝不修改 DUT record；负向不得到达 production PASS；
  production expected record 与 fixed-15 fixture-owned oracle 逐位相同；所有 state localparam 在四种
  配置中均有真实消费者，禁止用新 source waiver 掩盖 warning。
- 数据通路：`oracle_runtime_mode_q` 驱动三个窄 mux，分别位于 expected coordinate、GMEM
  address、request-events 的 capture 输入；公共 comparator 先比较 cycle/flags/response/identity，
  再比较三个可变字段。不存在新 pipeline、共享算术或 production critical path。
- 九项 topology：module 边界、clock/reset、DUT valid/ready、全部 production state/owner
  register、GMEM/IEEE child pipeline、reset/fault/timeout 优先级、共享 GMEM 与 child 资源、
  production critical path 以及 function/显式时序划分均保持 fixed-15；唯一新增验证拓扑是
  `plusarg -> immutable mode -> 3-way expected-field mux -> independent comparator -> REJECT/PASS`
  控制链，位于 `.sv` TB，不进入可综合 RTL。

### Evidence identity

fixed-16 的自包含 runner 必须先绑定 fixed-15 preflight PASS、coordinate mutation build rc0、
warning 门 rc104、canonical FAIL status 以及零 dynamic run；随后只构建一次
`--binary --timing --sv -O3 -Wall -Wno-fatal` binary。实际 `__verFiles.dat` 的
design/transitive/control/tool membership 与四项 mutation 在任何 binary 调用前闭合。
同一 binary 按三个负向 argv 和一个 production argv 各执行一次：负向要求非零、对应 REJECT
exact-one、production PASS 为零；production 要求 rc0、PASS exact-one、FAIL/REJECT 为零，并保持
five address provenance killers、60-row raw oracle、2048-row/262144-element cardinality、P0、
held-valid、post-retirement cleanup、11 deadline-fire、reset/retry 全矩阵。

## Fixed-18：真实 terminal state witness 与 WSL launcher 身份

fixed-17 的第一条只读工程调用被 Windows PowerShell 直接解释，因 `sed` 不存在而
fail-closed；它未进入 WSL、未修改工作区且 preflight/build/run 均为 0。fixed-18 从
第一条命令开始统一使用
`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<declared command>'`
启动 Ubuntu 工程命令，并把该 launcher GAP 作为不可变前代事实绑定，而不重试
fixed-17 身份。

### 阶段 1 / 2a--2e 冻结

- 需求：production `TensorNpuOrderedSumRows` 保持 SHA-256
  `5ce80477369ef4ec637341a2489bd67757fc2dadc1632119f2cfebf4cdcce06b`；
  只在完整 TB 的真实终止采样点消费 `ST_ERROR`、`ST_POISON_ERROR`、`ST_POISON`。
- 协议：`wait_small_terminal` 已在 negedge/post-NBA 观察到 terminal 后，recoverable
  error 必须处于 `ST_ERROR`；`ERR_POISONED` 同拍必须处于 `ST_POISON_ERROR` 且
  `error=1, poisoned=1, done=0, ready=0`；下一 registered edge 的 post-NBA 采样必须
  处于 `ST_POISON` 且 `poisoned=1, error=0, done=0, ready=0`。
- FSM：production 状态机和转移均不改；TB 仅比较三个真实可达 Moore 状态。全局 reset
  仍是 persistent poison 的唯一恢复手段。
- 不变量：recoverable state witness 的 fixture-derived exact cardinality 为
  `27 preflight + 1 GMEM REQ timeout + 2 GMEM response + 2 accepted drain
  + 1 persistent-ledger + 1 post-error predecessor = 34`；poison-error 与 persistent
  poison 各恰好 1。任何状态/输出/基数不符立即 FAIL，禁止 waiver、dummy reduction
  或不可达分支充当消费者。
- 数据通路与九项 topology：descriptor、GMEM/child owner、row/result buffer、F64
  ordered feedback、sticky flags、shadow publish、drain/quarantine、critical path 和
  production function/时序边界全部保持 fixed-16；新增验证链仅为
  `terminal outputs -> post-NBA state compare -> three counters -> exact marker`。

production 模式必须恰好一次输出
`[NPU-ORDERED-SUM-ROWS][TERMINAL-STATE-WITNESS] error=34 poison_error=1 poison=1`。
同一 warning-clean O3 binary 仍以三个 runtime oracle mutation 配置受控非零退出，随后
以 production 配置完成 60-row raw oracle、2048-row/262144-element cardinality、地址
killer、P0、held-valid、11 类 deadline-fire、fault/reset/retry 全矩阵。该证据不外推
综合、STA、PPA、backend、Qwen 或 tokens/s。

## Fixed-19: ownerless request collision and bounded abort poison

Fixed-19 supersedes every incompatible historical sentence above.  Earlier
hashes, counters, and markers remain immutable predecessor evidence, but they
are not current expected values.  The only normative active-transaction
priority is the table bracketed by `FIXED19_NORMATIVE_PRIORITY_BEGIN` and
`FIXED19_NORMATIVE_PRIORITY_END` in section 2a.

### Phase 1 verifiable requirements

1. In `ST_ROW_READ_REQ` or `ST_PUBLISH_REQ`, an ownerless GMEM response and a
   true `gmem_req_fire_w` on the same edge must retain the request counter,
   owner, and post-fire first-fault identity.  Independent
   `collision_poison_q` must prevent the old ghost and the later real response
   from acquiring DRAIN, row/result-buffer, shadow, response-counter, or
   terminal credit for the new owner.
2. After a normal REQ timeout, `abort_hold_q` must keep the original request
   valid and its complete payload stable.  Independent 64-bit
   `abort_hold_cycles_q` must set `abort_hold_poison_q` within
   `ABORT_HOLD_TIMEOUT_CYCLES` complete held cycles.  Values zero and one both
   mean the first complete held cycle.  Late ready may create exactly one
   request fire, but poison, zero DONE/ERROR, and the immutable first cause
   remain until reset.
3. The arithmetic DAG, descriptor preflight, row/result buffers, private-shadow
   commit boundary, and full-profile cardinality do not change.  The
   `127_add` mutation means +0 seed followed by indices 0 through 126.  The
   `x0_seed` mutation means index 0 is the seed followed by indices 1 through
   127.  These are distinct behaviors.

### Phase 2a protocol and arbitration

- `gmem_ownerless_request_collision_w` is exactly `txn_active_q &&
  gmem_request_state_w && !gmem_owner_valid_q && gmem_req_fire_w &&
  gmem_owner_fault_w`.
- The collision sticky writer is outside the first-fault branch.  This covers
  both the initial ghost plus fire and an abort-held late ghost plus fire after
  an earlier cause has already been captured.
- A fault-side state decision cannot overwrite the transport last writer.
  Every true same-edge request establishes its owner and increments its request
  counter exactly once; first-fault request-event total and owner identity are
  the post-fire view.
- Collision must spend one complete registered `ST_CHILD_QUARANTINE` cycle and
  then bypass `ST_GMEM_DRAIN` for reset-only `ST_POISON`.  Response ready stays
  zero.  The new owner ledger may remain for diagnosis, but cannot recover
  before reset.
- An abort-watchdog hit only sets `abort_hold_poison_q`; it does not change the
  request state, `abort_hold_q`, or payload.  A later fire clears abort and
  enters quarantine once.  Without a collision, an accepted GMEM owner may
  retire only as isolated transport before reset-only poison.
- All first-fault cycle, coordinate, address, flags, event totals, tag,
  generation, resource, and owner fields are write-once.  Collision, abort
  watchdog, late fire, drain late error, and poison cannot overwrite them.

### Phase 2b exact FSM and terminal topology

| fixture-derived class | exact state/output topology |
|---|---|
| recoverable first cause | `ST_ERROR`, `error=1`, `poisoned=0`, exactly 47 |
| legacy drain exhaustion | `ST_POISON_ERROR` for one cycle, exactly 1, then `ST_POISON` |
| collision reset-only poison | quarantine then direct `ST_POISON`; read, publish, and abort-late exactly 3 |
| abort ready permanently low | original REQ state, held valid, `poisoned=1`, no terminal until reset; exactly 2 watchdog causes |
| persistent poison entry | legacy drain 1 plus direct collision 2 plus abort-read collision 1, exactly 4 |
| successful small terminal | `ST_DONE`, exactly 27 pulses |

The counters must be driven by a post-NBA/negedge observation of real Moore
state and outputs, never by helper-call counts.  The exact current marker is:

```text
[NPU-ORDERED-SUM-ROWS][TERMINAL-TOPOLOGY] recoverable_error=47 poison_error=1 poison_state=4 collision_poison=3 abort_hold_poison=2 drain_poison=1 done=27 fault_captures=52
```

### Phase 2c invariants

| ID | fixed-19 invariant | violation |
|---|---|---|
| F19-I1 | a collision edge has request delta exactly 1, response delta 0, and a post-fire GMEM owner | lost or invented transport |
| F19-I2 | collision sticky is independent of `fault_capture_event_w` | prior cause hides poison |
| F19-I3 | collision quarantine/poison never asserts response ready or changes semantic buffers after the real request fire | cross-transaction contamination |
| F19-I4 | abort-held prior-cycle valid and payload remain identical until fire or reset, including after watchdog poison | request cancellation |
| F19-I5 | watchdog poison is visible by the configured bound with zero DONE, ERROR, and start fire | permanent-ready-low livelock |
| F19-I6 | late ready creates exactly one request fire, owner, and count, and cannot clear poison or first cause | duplicate or recovered failed transaction |
| F19-I7 | every collision/watchdog reset is followed by a clean full small-profile retry | stale owner or poison |
| F19-I8 | `mutation_behavior_signatures()` returns ten labels and ten unique full-vector signatures | aliased numeric debt |
| F19-I9 | full profile remains 2048 rows, 262144 elements, and 262144 ordered F64 ADD responses | DAG/cardinality regression |

### Phase 2d datapath and mutation separation

Production semantic writers remain limited to matching WAIT response fires for
row buffer, accumulator, result buffer, flags, and progress.  Collision and
abort watchdog add only lifecycle sticky state/counter state; they add no
semantic-data mux.  The oracle must produce ten distinct 60-row
`(result,flags)` signatures for these ten labels: `x0_seed`,
`f32_accumulator`, `pairwise_tree`, `reorder`, `intermediate_narrow`,
`127_add`, `early_nan`, `payload_propagation`, `ftz`, and `wrong_tininess`.
Z1 kills `x0_seed`; C1 kills `127_add`; every other label also has at least one
real canonical-row witness.

### Phase 2e nine-item topology freeze

1. **Boundary:** no module port is added.  The new watchdog is a parameter and
   the two causes are parent-internal sticky bits.  Existing `poisoned_o`,
   `error_code_o`, and `first_fault_*` ports are the only observability path.
2. **Registers:** the sole parent sequential block additionally owns
   `abort_hold_cycles_q`, `collision_poison_q`, and `abort_hold_poison_q`.
   Synchronous reset clears all three.
3. **Combinational:** add one ownerless-request collision predicate, one abort
   bound comparison, and `reset_only_poison_w`.  First-fault selection, owner
   matching, and fire definitions are not duplicated.
4. **FSM:** no numeric state is added.  Collision only changes the quarantine
   destination; watchdog hit deliberately remains in the original REQ state.
5. **Flow:** GMEM request valid remains Moore-driven by the REQ states.  The
   transport counter/owner last writer preserves a fault-edge fire once.
6. **Priority:** use only the single marked normative table in section 2a.
7. **Resources:** GMEM, both buffers, and the three IEEE child instances are
   unchanged.  Added hardware is one 64-bit watchdog counter and two sticky
   bits.
8. **Critical path:** added logic is a request/owner/fault AND tree, a counter
   comparison, and a poison-output OR.  HardFloat and 128-bit preflight paths
   are unchanged.  This task runs no synthesis or STA, so it makes no
   frequency or area claim.
9. **Function split:** lifecycle, owner, fault, and FSM arbitration remain
   explicit RTL.  TB post-NBA monitoring and Python oracle helpers are not
   production hardware.

### Fixed-19 evidence gates

The self-contained runner must bind the successful fixed-18 identity,
static-review-v5, and the v4 invalid-ownership evidence before any binary
invocation.  One unique preflight must complete oracle validate, self-test,
mutation-audit, verify, and the directed unit test at rc0.  Mutation audit must
report `mutations=10 distinct=10`.

Only after preflight may one fresh warning-clean Verilator
`--binary --timing --sv -O3` build create the binary.  Actual membership must
be design 13, transitive 4, control 1, and tool 2, with all four membership
mutations rejected.  The same binary then runs three controlled independent-
oracle negative modes, each nonzero with exactly one REJECT, followed by one
production run at rc0 with exactly one PASS and zero FAIL/REJECT.  A
signal-safe receipt may set `evidence_complete=1` only after every marker,
hash, and cleanup gate passes.  Synthesis, STA, PPA, backend, Qwen, and
tokens-per-second measurements remain out of scope.

## Fixed-24 terminal-topology diagnostic identity

Fixed-23 proved the two ownerless-request collision killers, the two bounded
abort-hold watchdog killers, all 11 deadline-fire classes, and full-profile
cardinality, but stopped at the final aggregate terminal-state assertion.  Its
log did not expose the three observed state-counter values, so the failure
cannot be classified as an RTL terminal defect, a testbench entry-monitor
defect, or a stale expected total from that artifact alone.

Fixed-24 is a diagnostic-only new elaboration identity.  Production RTL,
integer oracle, canonical 60-row JSONL, and all numeric semantics remain byte
identical.  The full testbench adds two non-driving witnesses only:

1. every real post-NBA transition into `ST_POISON` prints an ordinal and the
   live collision/abort and immutable first-fault classification; and
2. immediately before the aggregate assertion it prints the actual
   `ERROR/POISON_ERROR/POISON` counters together with the independent model
   error count, fault captures, and fixture-derived poison counts.

The marker is evidence, not a relaxed oracle: expected topology remains
`47/1/4`, the original assertion remains active, and no warning waiver is
permitted.  A self-contained fixed-24 runner binds the immutable fixed-23
build/run failure, performs one new warning-clean O3 build and one production
run, and accepts only an exact diagnostic marker plus either the original
controlled topology failure or an exact full PASS.  It must not promote a
diagnostic failure to production PASS.  Any repair inferred from the observed
triple requires a later versioned identity.

## Fixed-25 legacy-drain monitor root fix

Fixed-24 observed the exact aggregate triple `47/1/3`.  Its three
`TERMINAL-POISON-ENTRY` markers were the read collision, publish collision,
and abort-read collision.  The missing fourth entry was the legacy drain path,
even though the same fixture had already proved its registered
`ST_POISON_ERROR -> ST_POISON` transition and terminal output.

The root cause is testbench event ordering.  `run_drain_poison` resumed on the
first negedge that exposed `ST_POISON` and asserted synchronous reset in that
same active region.  The independent negedge topology monitor could therefore
observe reset high first and deliberately skip the state-entry count.  This is
not a production state-machine defect and does not justify changing the
normative `47/1/4` topology.

Fixed-25 keeps the complete poison stimulus and registered-state checks, then
waits `#1` before asserting reset.  Before reset it requires the independent
post-NBA counter to have advanced by exactly one and emits
`DRAIN-POISON-ENTRY post_nba=1 reset_low=1 witness_delta=1`.  The delay is less
than the remaining half clock period, so reset is still asserted before the
next rising edge; it changes only TB observation ordering.  Production RTL,
numeric oracle, canonical JSONL, and all descriptor/GMEM/child semantics stay
unchanged.
