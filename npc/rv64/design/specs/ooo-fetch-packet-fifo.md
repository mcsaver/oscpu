# OooFetchPacketFifo Boundary Spec

> **T3W 状态**：生产配置恒死的 seed 通道已物理删除；FIFO 只接受
> reset、clear、normal enqueue/pop。完整 head packet 由 registered shadow
> 呈现，ring head pointer/read mux 不再进入 head-time 控制锥。
>
> **T4B 契约冻结**：`count_q` 继续作为 occupancy 单一真源；
> `head_valid_o` 改由与 occupancy 事件同沿更新的 `head_valid_q` registered
> projection 驱动。该投影不得改变 empty-enqueue、last-pop 或 pop+enqueue
> 的可见拍数，并由独立的 `head_valid_q == (count_q != 0)` 立即断言守住。

## 1. Requirement

`OooFrontend`（原 `OooAluFetchCore`，已重构删除）previously owned fetch packet FIFO pointers, count and packet
storage directly.  The inline FIFO mixed packet storage with redirect, branch
prefetch, JALR prefetch, CSR trap and precise drain control.  This made the
front-end boundary difficult to audit.

`OooFetchPacketFifo` extracts only the packet storage primitive:

- store one fetch packet containing two decoded instruction slots;
- expose the current head packet to the parent;
- accept normal enqueue/pop actions from the parent;
- accept a clear-to-empty action from the parent;

The parent keeps ownership of fetch request/outstanding tracking,
redirect priority, branch/JALR prefetch hit selection and precise
exception policy.

## 2. Interface Contract

Inputs:

- `enqueue_i`: writes the enqueue packet at the current tail.
- `pop_i`: advances the head when the parent consumed a stored packet.
- `clear_i`: clears pointers/count and makes the FIFO empty.
- `*_i` packet fields: PC, next PC, instruction, response code、预测元数据及
  T3V 静态预译码 bundle（`ctrl/rs1/rs2/rd/imm`），两 lane 加 packet next PC；
  T4G `fault_tval` 是 response 边界预计算的首个失败 fetch portion 地址。

Outputs:

- `count_o`: number of valid stored packets, range `0..2^FETCH_PACKET_COUNT_W`.
- `head_valid_o`: registered projection `head_valid_q`，并且任意有效周期都必须
  严格等价于 `count_o != 0`；它不能再由 `count_q` 的零比较组合驱动。
- `head_*_o`: 完整 packet 只由同一个 `head_packet_q` registered shadow 原子驱动；
  有效时与 `ring[head_q]` 等价，但生产输出不得直接读取动态 ring mux。

`head1_pc0_o` 已在 B2 S2 删除；预测后继由包内 `packet_next_pc` 原子保存，不再读取
下一 entry 形成哨兵式组合依赖。

The parent must not use `head_*_o` unless `head_valid_o` is true. T3V 已物理删除
same-cycle fetch-response bypass；所有 dispatch-visible packet 都有 FIFO 寄存 owner。
reset 释放后 `clear_i/enqueue_i/pop_i` 必须都是已知二值；四态仿真中 X/Z
会使 pointer 的 `if` 与 occupancy 的 `case` 产生不同解释，因此立即断言 fail closed。

## 3. State Machine And Priority

Per clock edge:

1. `rst`: reset pointers/count and clear packet storage for deterministic sim.
2. `clear_i`: reset pointers/count to empty；即使同拍 enqueue/pop 也必须把
   `head_valid_q` 清零。
3. Normal enqueue/pop:
   - enqueue only: write tail, increment tail/count，并把 `head_valid_q` 置一；
   - pop only: increment head, decrement count；旧 `count_q==1` 时清
     `head_valid_q`，旧 `count_q>1` 时保持为一；
   - enqueue and pop: write tail, increment both pointers, keep count and
     `head_valid_q` unchanged；合法 pop 保证旧 occupancy 非零，所以 valid 保持一；
   - idle: count、pointer、packet shadow 与 `head_valid_q` 全部保持。

同拍控制优先级严格为 `rst > clear_i > {enqueue_i,pop_i} > idle`。
FIFO 没有内部 ready；parent 负责保证 empty 不 pop、full 不单独 enqueue。
underflow/overflow-request 断言只检查会进入 normal-event 分支的动作；`clear_i`
同拍时这些输入被优先级树吞掉，不得误报 normal-event 违约。

T3W shadow 的同沿更新：empty enqueue 与 `count=1` 的 pop+enqueue 直接装
enqueue bundle；`count>1` 的 pop 装旧 `ring[head+1]`；仅 pop 最后一项只使
count 归零。full pop+enqueue 时 tail=head，新包覆盖旧 head，而 shadow 读取
旧 head+1，两地址不同且顺序保持。上述路径均不增加首包延迟或稳态气泡。

## 4. Data-Path Invariants

- `count_o == 0` implies `head_valid_o == 0`.
- `count_o != 0` implies `head_valid_o == 1`.
- `head_valid_q` 与 `count_q` 必须在同一时序块、同一优先级树更新；禁止
  从 ring payload、head pointer 或 downstream ready 反推 valid。
- reset/clear 后 valid 当沿归零；empty enqueue 后 valid 当沿置一；last-pop
  后 valid 当沿归零；multi-entry pop 和任意合法 pop+enqueue 后 valid 保持一。
- `count_o` never exceeds FIFO depth when the parent respects its reserve
  contract.
- 每个 slot 的 `inst` 与 `ctrl/rs1/rs2/rd/imm` 在 enqueue 与 head 读取时
  始终作为同一个 packet bundle 原子移动；有效 head 的 bundle 必须等价于
  `DecodeStage(head_inst)`。
- `fault_tval` 与产生 per-slot fault response 的同一 packet 原子移动；empty-enqueue
  直装、ring pop、full pop+enqueue 与物理 wrap 均不得用任一 slot PC 替代。
- Clear overrides normal enqueue/pop, matching redirect/trap invalidation priority.
- 在采样沿前，未被 `clear_i` 吞掉的 `pop_i` 要求旧 `head_valid_o=1`
  （等价于旧 count 非零）；full enqueue 必须与 pop 同拍。断言对真正进入
  normal-event 分支的 empty-pop 与 full-push-without-pop fail closed。
- 有效 `head_packet_q` 必须逐位等于当前 ring owner，所有 head 输出必须只来自
  shadow Q；两条要求分别关闭功能复制分叉与 timing-cut 假绿。

## 5. Parent Boundary

`OooFrontend` remains responsible for:

- computing `fetch_rsp_enqueue_w`, `fifo_storage_pop_w` and reservation;
- encoding redirect/trap/drain clear actions；旧 seed 三源已由 T3V 物理删除，
  legacy control combination 统一 clear+refetch。

T3V 的译码所有权与验证见 `ooo-fetch-predecode-bundle.md`。
