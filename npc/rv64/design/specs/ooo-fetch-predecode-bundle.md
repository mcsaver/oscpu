# OoO Fetch Predecode / Static Facts Bundle Boundary

## 1. 需求

T3V 将 `DecodeStage` 的纯指令函数从 dispatch 头部移动到 fetch packet 取得所有权的边界。
`OooFetchPacketFifo` 必须把每条指令及其静态译码结果作为一个原子包保存，
`OooFetchPacketHeadMux` 必须从同一个来源同时选择两者。目标是切断
`FIFO head -> Decode/ImmGen -> backend ready/action -> frontend request` 的跨前后端组合长链，
不改变指令、异常、分支或提交语义。

## 2. Bundle 合同

每个 slot 的静态 bundle 为：

- `inst`；
- `ctrl`；
- `rs1`、`rs2`、`rd`；
- sign-extended `imm`；
- T3W 18-bit `static_facts`：15 个 `OooFpDecode` 类、raw `fp_double`、
  `DYN_RM_BEARING` 与按 lane 方向编码的 semihost peer signature；
- 原有的 PC/next-PC、response、预测元数据仍属于同一个 fetch packet。

`ctrl/rs*/rd/imm` 必须与同 slot 的 `inst` 在同一拍、由同一个来源产生；禁止只更新
其中一部分。response 正常入队时 bundle 来自 `fetch_dec*`。T3V 同时删除恒死的 seed
数据面，故不存在第二个 packet bundle 写入 owner。

## 3. 时序与所有权

- `DecodeStage` 无状态且只依赖 `inst_i`，允许在 packet 入队的寄存器 D 端计算。
- FIFO 头部只做已寄存 bundle 的读选择；dispatch 侧不得再次实例化 live `DecodeStage`。
- T3V 物理删除 response-to-dispatch bypass 的 RunGate/FlowControl/HeadMux 接口与选择臂；
  所有 response 必须先写入 FIFO，response 译码只进入 FIFO 写入边界。不能只依赖跨层级
  常量 0，因为保层级综合会保留 mux 单元及其延迟。
- 预译码不新增 ready/valid 状态，也不改变 FIFO 的 enqueue/pop/clear 优先级。
- `static_facts` 由 `OooFetchPacketDecode` 已 fault-sanitize 的 `fetch_dec0/1_inst` 计算，
  与 packet enqueue 原子寄存；禁止从 raw response byte 或 FIFO head 指令重新译码。
- privilege、`mstatus.FS/TVM/TW/TSR`、committed `frm`、slot visibility、valid 与 fetch fault
  不进入 FIFO，仍由 `OooFetchHeadClassifyGate` 在 head-time 动态重组。

## 4. 不变量

- 任意有效 head packet：`stored_decode(head_inst) == DecodeStage(head_inst)`，两 lane 均成立。
- FIFO 的 enqueue、head 读取均对完整 packet bundle 原子操作；clear 只清空有效状态。
- HeadMux 是 FIFO registered bundle 的 identity view，不得重新引入 response 组合臂。
- fault slot 已在 `OooFetchPacketDecode` 净化为 NOP；其预译码必须对应净化后的指令，
  不得重新读取 fault raw bytes。
- 新旧 42-bit facts 必须逐位一致。特别地，历史 `fp_double` ABI 是不受
  `decode_valid/fetch_fault` gate 的 raw format 位；T3W 必须从静态 pack 原样输出，不能随
  其它 15 个 FP class 一起清零。
- DYN rounding 非法性必须由已存 `DYN_RM_BEARING` 与 head-time committed `frm` 合成；
  semihost 必须由 head-time `ebreak_raw` 与已存 peer signature 合成。
- 本边界不复制 RVC length、response provenance、illegal/trap 或 dynamic branch 判定。

## 5. 验证

- `tb_ooo_fetch_packet_fifo` 对 enqueue、pop、wrap、clear 检查 bundle 随包保存。
- `tb_ooo_fetch_packet_head_mux` 使用与指令可区分的 metadata 检查 FIFO identity view。
- `tb_ooo_fetch_static_classify` 对 15 类 FP、double、DYN-rm 与两种 semihost peer 方向做
  directed + randomized 静态等价检查。
- `tb_ooo_fetch_head_classify_gate` 以 frozen legacy head-time decoder 为参考，对随机
  `inst/ctrl/priv/mstatus/frm/valid/fault/peer` 做完整 42-bit differential。
- `tb_ooo_fetch_head_pair_gate` 保持 static pack 不变并改变 `frm/FS`，验证动态状态只在
  head-time 重组；FIFO 测试同时覆盖 hold、wrap 与双槽 static-facts 原子性。
- `OOO_ASSERT` 下，`OooFrontend` 用 shadow `DecodeStage` 对每个有效 head 做逐位一致性检查。
- `tb_ooo_core_top_glue` 用非零 `fault_addr` 注入 lane1 instruction access fault，白盒确认
  fault raw 指令先净化成 NOP、随预译码 bundle 入队并到达 registered FIFO head；真实 CSR
  handler 再以 `mcause/mepc/mtval` 和 GPR 副作用检查精确异常边界。
- mutation-negative 只修改 workspace 临时 `OooFrontend` 副本：lane1 fault 包入队时翻转一个
  stored lane0 `rd` 位，要求 `T3V-PREDECODE-COHERENCE` 精确命中且测试 harness 判红，防止
  shadow assertion 从未执行或错误接线造成假绿。
- 完整回归负责覆盖其它真实指令流、flush 与后端消费；fresh synthesis 必须确认 dispatch
  侧旧 `u_head*_decode` 不再存在，精确 5 ns 全局 STA 才能判定时序收益。
