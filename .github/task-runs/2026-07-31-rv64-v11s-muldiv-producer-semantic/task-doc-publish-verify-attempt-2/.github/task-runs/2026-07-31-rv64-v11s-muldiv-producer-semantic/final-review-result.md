# V11S independent final review

RV64 RTL 结论｜对象=`OooMulDivUnit.producer_id_q`、product instance 与
focused-attempt-4｜周期/配置=request→REQ_BUF→MUL_RUN/DIV_RUN→RESP→
death edge/次周期释放，`PRODUCER_GEN_W=1/4`、assert/release｜
TB/EDA 观测=22/22 profile、18/18 compile-success mutation、
4/4 regression PASS；未运行综合/STA｜范围=PASS（仅
`muldiv-producer`）

## Reviewer 核验

- request fire 捕获完整 `{generation, rob_idx}` 至 `producer_id_q`；
  REQ_BUF、iterative state 与 RESP 均由该 Q 驱动 owner、response PID 和
  live mask。
- raw response transport/ready 与 exact-open 分离；WB/PRF/Busy/IQ/ROB
  公共副作用经 exact-open 与固定 same-cycle claim 链授权。
- 正常 terminal、matching kill 或 flush 的 death edge 保留 edge-old lease；
  RESP 消费或 flush 后下一周期 owner/PID/live mask 清空。
- wrong generation 的 completion query、authorization 与 claim 均为零；
  正确 terminal 只产生一次完整 ProducerId writeback 与有序 retirement。
- 9 类 mutation 均先编译成功，再在唯一声明 stage 被 oracle 拒绝。
- production SHA、design-id、source pre/post、base TB 与 generated overlay
  绑定一致；production RTL 无本轮 diff。
- ledger 只从 34/10 变为 35/9，且只提升 `muldiv-producer`。

## 保留范围

- product-path 未单独枚举 vacant/done-closed，也未让强制错误 generation
  response 完成真实 handshake；当前依赖 exact-open 结构检查、mutation
  oracle 与既有 leaf 证据。
- product-path 只用 MUL、DIVU 代表共享身份控制；不是逐 opcode 生命周期穷举。
- selective kill 细粒度主要由 leaf TB 覆盖，product instance 聚焦 full
  flush。
- 未运行 formal、综合或 STA；不得提升 global no-live-reuse、
  whole architecture 或 PPA。
- 若要求 vacant/done/killed 全假矩阵或全架构 no-live-reuse，必须增加
  OooRob/product-path 定向 replay 与相应系统重新认证，不能复用本 PASS
  越级。

## 合同与 ownership

- reviewer contract：
  `subagent-contracts/v11s-muldiv-producer-final-review.json`
- contract SHA-256：
  `11c12f24688d9570081c3940ac04e9dbde7d21cb7860aa900986219816eba378`
- reviewer blocker：0；结论为 bounded PASS。
- reviewer 未修改 RTL/TB/evidence，全部只读命令已退出并归还
  Windows→WSL single-flight ownership。

