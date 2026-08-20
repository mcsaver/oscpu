# BPU local-PHT production child-split architecture v2

RV64 RTL 结论｜对象=`NpcTop.u_core.u_ooo_core.u_frontend.u_branch_direction_predictor` / `local_pht_q` / sealed `opensta-top40.rpt`｜周期/配置=5.000 ns、d3f3、`mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=既有 predictor TB PASS；sealed WNS=-50.241458893 ns、TNS=-719693.1875 ns、Top40=40/40 BPU internal、BPU area=283823.40｜范围=FIX current structure；RETAIN one next candidate

唯一下一候选：`OooBranchLocalPht` production child，内部显式 16×256 banking/write decode。保持双异步组合读和现有两拍 update，不改变 `OooFrontend` prediction 消费周期。

## Architecture IR

```text
fetch response / PacketDecode
  ├─ lane0 PC/static ─┐
  └─ lane1 PC/static ─┼─ dual 0-cycle prediction read
                      │   ├─ PC[10:1] xor ghr_q -> BHT
                      │   ├─ PC[8:1] -> local history
                      │   └─ {PC[4:1], local_history[7:0]} -> local-PHT
                      └─ hybrid select -> fetch_pred0/1_taken
                           -> response/enqueue-edge FIFO metadata

issue-resolve
  -> OooBranchBpuUpdateGate single authorized update
  -> S1 edge: capture old BHT/local-history/local-PHT counter; update GHR
  -> S2 edge: saturating BHT/local-PHT write + local-history shift

mispredict
  -> OooBranchResolveRecoveryGate -> ROB-walk redirect/squash
  -> predictor state is not checkpointed/restored; resolved branch still trains
```

状态与周期不变量：

- `OooBranchDirectionPredictor` 保留 GHR、gshare BHT、local history、hybrid selector、BHT/local-history update pipeline。
- 当前 local-PHT 是 4096×(valid+2-bit counter)，双组合读；lane0/lane1 同 bank/same row 也不能仲裁或降为单路。
- resolve edge 为 S1：读取旧 counter/history、捕获 index/taken；下一 edge S2 饱和写回。
- 背靠背 same-entry update 当前保持 read-before-write 并可能丢一次增量；这是现有 RAW 语义，候选不得偷偷增加 forwarding。
- lookup 与 S2 write 同 edge 时 FIFO 采样写前预测。
- `rst || clear_i` 清 valid/GHR/在飞 update；child 必须清 bank-local update valid。mispredict 不触发 predictor restore。

## Top40-to-RTL mapping

最坏 path：`update_taken_i` DFF/Q → `upd_lpht_ctr_q_0__AOI21X0P5H7L_A1/Y` → `local_pht_q[0][0]` DFF/D；关键 arc=54.784690857 ns、arrival=55.933452606 ns、required=5.691995621 ns、slack=-50.241458893 ns。它映射到 S1 `upd_taken_q/upd_lpht_ctr_q` 经 `counter_train()` 生成公共 write data，再经 variable-index write 驱动 4096-entry local-PHT。

Top40 40/40 都从同一 taken flop 到不同 local-PHT entry，结合 17,706 DFF、5,377 ICG、5,460 MUX4 和 BPU area 283,823.40，支持集中 update-data/load 假设。该机制置信度为中等：缺少已删除 netlist 的 fanout/capacitance、P&R、CTS 与多角证据，ideal-clock stdcell proxy/Liberty overload 外推也可能放大延迟。

## Candidate decisions

| Candidate | Decision | Basis |
|---|---|---|
| Whole predictor inline | BLOCK promotion；RETAIN semantic oracle | 暴露内部路径但 WNS/area 失败 |
| Unbanked local-PHT child only | FIX | 只换层级不改变 4096-entry variable write；blackbox 会隐藏路径 |
| Local-PHT child + 16×256 bank/write decode | RETAIN，唯一推荐 | 自然使用 `{PC[4:1],history[7:0]}` bank/row；将公共 update load 局限到 16-way select 与选中 bank 256 entries |
| Registered/queued update alone | BLOCK | 当前已有 S1/S2；新增 queue 不降低 fanout，且改变 RAW/clear/update visibility |
| Add prediction pipeline stage | BLOCK | 改变 response/enqueue 周期；历史 S1.5 accuracy 88.6%→78.4% 反例，未获 CPI/accuracy 授权 |
| Whole predictor placeholder/OOC | BLOCK PPA claim | 现有 Liberty area=0 且无真实 lookup arcs，只可作历史锚 |

## Recommended child boundary

`OooBranchLocalPht` ports：`clk/rst/clear_i`；两组 `lookup{0,1}_idx_i/valid_o/ctr_o`；一组 `update_valid_i/update_idx_i/update_taken_i`。无 ready、stall、queue、forwarding 或 checkpoint。

- wrapper 内显式实例化 `OooBranchLocalPhtBank[0:15]`，wrapper 不拥有预测状态。
- 每个 bank 拥有 256 valid bits、256×2-bit counters 和 bank-local `upd_valid/row/taken/old_ctr` S1 registers。
- bank=`idx[11:8]=PC[4:1]`；row=`idx[7:0]=local history`。
- lookup latency=0-cycle combinational；selected bank 在 resolve edge 捕获 old counter，下一 edge 与 parent BHT/local-history 同拍写回。
- 必须禁止跨 bank logic sharing 并保留 bank hierarchy；双路 same-bank lookup 使用两个组合 read view，不复制 architected state。

## Registry and OOC

首个 inline config：

- ID=`mapped-5ns-bpu-local-pht-banked-child-inline-v1`
- comparison parent=`mapped-5ns-bpu-inline-v1`
- predictor、local-PHT child/banks 全部 inline；SRAM199/SRAM113/FP 仍为三类 placeholder。

inline 结果闭合内部路径后才允许 OOC config：

- ID=`mapped-5ns-bpu-local-pht-banked-child-ooc-v1`
- real Liberty=`npc/rv64/syn/macro-lib/OooBranchLocalPht.lib`
- plumbing-only placeholder 独立命名，不得进入 PPA 数值。
- Liberty 必须有两路 lookup index→valid/counter 组合 arcs、update/reset/clear setup/hold、非零 area/power。

OOC promotion 是合取：child internal reg/input STA + real lookup arcs + NpcTop child-boundary→hybrid-select→FIFO D STA + child/top outside-child area/power。缺一项都只是隐藏路径。

## Implementation/evidence sequence

1. 冻结 spec 的 0-cycle dual-read、S1/S2 update、RAW、clear 和 no-predictor-recovery 合同。
2. 新增 child/bank RTL，只替换 parent local-PHT，不改 `OooFrontend` 端口或周期。
3. 更新 filelist、registry 与 inline physical config；保留 whole-inline/four-placeholder evidence。
4. Directed TB：dual lookup 的 same-bank/same-row、same-bank/different-row、different-bank；counter 饱和边界；S1/S2 visibility；same-entry RAW；lookup/S2-write collision；reset/clear；BPU update single source；mispredict trains but does not restore。
5. Compile-success mutations：lane1复用lane0地址、bank/row交换、插入lookup一拍、counter wrap/taken反相、update变一拍/三拍、错误 RAW forwarding、clear不清 bank update、same-bank读仲裁、mispredict抑制训练/触发 restore、Liberty删 lookup arc/area置零/缺 internal STA。
6. 同一 parent/5 ns/PDK/SDC/tool/seed/thread 下，单次 deterministic inline PPA，保留 raw Top40/synth-stat/binding/manifests。

## Retain/rollback

候选 RETAIN 必须同时满足：功能/TB/assertion PASS、所有 mutation 被检出；prediction/update 周期不变；Top40 中旧 `update_taken_i→local_pht_q[*]` fanout family 消失且无同等替代；WNS/TNS 严格优于 -50.241458893/-719693.1875 ns；相对四宏 logic-area delta 严格小于 +283,823.40；内部路径保持可见。任一语义/cycle失败立即回滚；WNS不优、area不降或 fanout仍在则终止该候选。

正式 5 ns promotion 仍需 WNS≥+0.10 ns、TNS=0、violations=0、loops=0、macro-inclusive area 与 qualified power；本裁决不宣称满足。

Unknowns：Yosys是否重新合并 bank logic；2R1W async OOC 可实现性；真实 CTS/routing load；bank mux 新 critical path；child power/macro-inclusive area；现有 TB 对 RAW/collision 的覆盖。替代假设包括物理 buffering/fanout constraint 可免 RTL banking、54.78 ns 主要是 Liberty overload，以及修复 write fanout 后 local-history→PHT read 成为主瓶颈。

`scope_extension_request=无`。RTL/state/cycle 与 raw 数值置信度高；banked 改善机制中等；OOC/P&R/power 未知。本轮合同 SHA 匹配，scoped diff 为空，未写文件或运行 EDA/test，shell ownership 已归还。
