# v8h RTL 四段式推导

## 阶段 1：需求

- 把 integer IQ 已有 full ProducerId 贯通 MulDiv/CLMUL request、unit holder、response 与 ROB query。
- 防止两个 long-op holder 存活时同一 full PID 被 dispatch 重用。
- stale/done/killed response 必须可运输核销，但不得进入任何完成副作用。
- 保持算法、延迟、WB source priority、commit 与 memory 语义不变。

## 阶段 2a：协议

- request 为 valid/ready capture；valid 不依赖 ready，ready 仅由 IDLE 与 reset/flush/kill guard决定。
- response valid 在 RESP/backpressure 保持；raw shared-WB route生成 ready。
- ROB exact-open 是 Q-only observation，只进入 actual side-effect valid。
- owner lease 是 Moore Q 输出，dispatch 只读 onehot union 的 indexed bit。

## 阶段 2b：FSM

- MulDiv 保持五态，CLMUL 保持三态；不新增状态。
- 每个 unit 新的唯一 identity state 为 `producer_id_q`；替代 raw request/response owner index。
- 全序：reset/flush > matching kill > state case；RESP 内 transport fire > hold。

## 阶段 2c：不变量

1. full PID capture 后到 terminal 逐位稳定，raw idx=PID low projection。
2. non-IDLE 全部持有 lease；IDLE 不持有。
3. death edge 仍保持 old lease，禁止同沿 birth。
4. route/ready 不读 exact-open；所有实际副作用读 exact-open。
5. dispatch mask 为 memory/MulDiv/CLMUL 精确并集。
6. ROB query 3/4 与 query 0..2 同义，拒 vacant/done/wrong-generation/killed。
7. edge-old exact-open 后再按 full PID 建立 `EX0 > EX1 > memory > MulDiv > CLMUL` actual claim 链；
   每 PID 每拍至多一个 side effect，raw transport不读取该链。
8. dual-dispatch pair candidate 的 index 低位不同，故完整 PID 结构性不同；不能把 registered
   live mask 当成同拍 pair collision arbiter。

## 阶段 2d：数据通路

```text
IntIQ full PID
  -> unit producer_id_q -------------------+-> resp full PID -> ROB exact-open
           |                               |                    |
           +-> owner_valid + PID -> onehot |                    +-> actual WB valid
                                   \       |                         |
memory registered mask ------------- OR --+-> dispatch indexed gate +-> PRF/Busy/IQ/ROB/public

raw response valid -> unchanged WB route -> resp_ready / transport terminal
```

## 阶段 2e：RTL 级拓扑自审

1. **边界**：五个 production module；所有信号同 `clk` 域，active-high synchronous reset。
2. **状态寄存器**：仅两份 `producer_id_q` 新/替换身份状态；其余 FSM/algorithm state 不变。
3. **组合块**：PID low projection、Q-only owner outputs、两个 onehot decoder、mask OR、两个 ROB
   exact queries、transport route、exact-open AND 与逐源 full-PID claim fence。
4. **FSM**：保持现有五态/三态，不增加非法转移。
5. **valid/ready**：request capture；response backpressure；query禁止反向进入 ready。
6. **优先级**：reset/flush > kill > normal；death-edge lease来自旧 Q。
7. **共享资源**：两个 unit不复制；WB mux/priority原样，新增的只是每源 authorization AND。
8. **关键路径**：Q PID/state→mask→dispatch ready；ROB Q array/equality→actual WB valid。两者不连接
   response ready，预期不形成 SCC。
9. **function 划分**：不新增 function；FSM/handshake/lease/arbiter均用显式 assign/时序块。

自审裁决 v8h.1：评审发现的同拍多源 claim 与 dual-birth candidate 缺口已转为上述显式不变量；
只有 claim 链、pair-distinct 断言及相应 mutation/TB 全部落地后，才可以把本地切片判为 GREEN。
