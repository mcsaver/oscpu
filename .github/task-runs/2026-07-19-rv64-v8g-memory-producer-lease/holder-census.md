# v8g memory holder / terminal census

## Source-to-sink map

```text
ROB/IQ full ProducerId
  -> memory issue reservation (full PID + raw idx view)
  -> OooMemOwnerTracker alloc {token, kind, epoch, immutable PID}
       -> reservation / buffer / legacy singleton / MIQ / SQ / bridge carry token tuple
       -> tracker registered producer_live_mask -> parent dispatch collision gate
       -> tracker producer table[token] -> memory completion exact-open query
  -> response owner-tuple match -> transport pop/terminal
  -> PID exact-open -> formal WB/PRF/Busy/IQ/public completion
```

## Stateful holders

| holder | 当前 identity | v8g identity role | 创建 | 终止 |
| --- | --- | --- | --- | --- |
| ROB slot / IQ entry | full PID 已存在 | source/current truth | dispatch fire | commit/walk/flush |
| `mem_issue_res_*_q` | full PID + tuple | direct carrier；alloc source | current-authorized issue capture | local completion/request handoff/kill/global cancel |
| `mem_buffer_*_q` | raw idx + tuple | token-indirected PID | reservation handoff | request fire或未发 cancel |
| `mem_pending_q` legacy | raw idx + tuple | token-indirected PID | AMO/LR/SC request/phase | final response或interphase cancel |
| `OooMemInflightQueue` | raw idx + exact tuple | token-indirected PID；response head source | bridge request fire | exact response pop/flush-compress drain rule |
| `OooStoreQueue` | raw idx；bind 后 exact tuple | **dispatch时直接保存 full PID**，bind/request/release full exact；store authority remains through B/release | dispatch alloc + current-exact issue bind | exact ROB/SQ release or eligible squash；已发写必须等 B |
| bridge station/active/response | exact tuple | token-indirected PID；不扩 AXI ABI | request fire/advance | exact response/drop drain |
| terminal collector | exact tuple pending | token-indirected PID until dequeue | six lossless ingress sources | tracker exact free |
| owner tracker | token live + kind/epoch | **新增 PID metadata + PID lease true owner** | reservation alloc fire | tagged free / STORE-only effective release |

任一 token-indirected holder 的资格前提是 tracker token 仍 live。holder raw index 只允许用于环形
年龄、SQ/MIQ地址或既有顺序；不得单独授权完成或复用。

## Terminal census

| terminal source | owner kinds | 是否可直接 free | ProducerId lease 规则 |
| --- | --- | --- | --- |
| exact normal response (`mem_rsp_final` / plain load) | LOAD/ATOMIC | collector tagged free | response side effect先 exact-open；free 沿后下一拍才可复用 |
| killed PROBE response | STORE provenance | 不能绕过 SQ authority | 只有 SQ/bridge/reservation authority全部结束的 effective release 才清 |
| bridge `drop0/drop1` | speculative LOAD/STORE/ATOMIC | collector/STORE release discipline | tuple exact，迟到 response不得 WB |
| reservation local complete/kill/global cancel | LOAD/ATOMIC tagged；STORE走SQ override | 按现有 collector/release algebra | local complete 的 EX full PID 已由 v8f gate；其余无副作用 |
| buffer pre-fire cancel | LOAD tagged；STORE走SQ override | 同上 | token 仍提供 PID，直到最终 release |
| AMO read→write interphase cancel | ATOMIC | collector tagged free | 未发 write，禁止残留 PID lease |
| SQ release/squash mask | STORE only | 仅 effective mask | 已发写等B时 MIQ/bridge residency 阻止清除；只有未发且无其它 authority，或 B exact terminal 的同沿最后 handoff 可清 |

## 初始缺口与本切片关闭点

- 缺口 A：tracker 没有 PID metadata，token 无法证明 ROB incarnation。
- 缺口 B：dispatch 不知道仍存活的异步 memory PID，generation 回绕可同名。
- 缺口 C：async memory WB 只带 raw ROB index，未在副作用前 exact-open。
- 缺口 D：memory reservation capture 未消费已有 current query。
- 关闭方式：A→immutable table；B→registered PID mask + parent gate；C→third ROB query +
  sink-credit `completion_fire`；D→current-authorized capture/consume-without-owner；SQ/AMO 的
  不可逆 request/release 另用 full PID==ROB head PID 收口。

## 明确保留 RED

- long-op、FP、branch/public completion 的 live PID 未并入同一 global scoreboard；
- token-indirected memory scoped closure 不证明所有 holder census 的全核 lease；
- 4-bit generation 仍会回绕，只是不能与 live memory owner 同名。
