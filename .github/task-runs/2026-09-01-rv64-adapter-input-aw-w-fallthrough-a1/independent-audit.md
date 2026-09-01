# Adapter input AW/W fall-through：独立只读审计

## 结论

`RETAIN`，`must-fix=0`，且严格限定为 retained local exploratory slice。

审计重新计算并确认 exact predecessor adapter SHA256 为
`6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22`，candidate 为
`0199aa2fd75a6ce6b2a087ea6ca2a509cdba11db287224fc4e2be0cdda79b421`。

未发现会导致下列问题的 production RTL 缺陷：

- AW/W 已接收通道重发或未接收通道 payload 丢失；
- invalid、sparse、misaligned 或 split request 误入 direct path；
- B error、sticky split response 或 final-B owner 归属变化；
- flush 撤销已逃逸 write；
- downstream READY 进入 upstream READY 的组合环。

## 审计覆盖

- E0 `11/10/01/00` 分别落到 `S_W_RESP`、仅 W 重发、仅 AW 重发、AW/W 都从 q 重发；
  `d_aw_sent_q/d_w_sent_q` 取同拍真实 fire，`S_W_SEND` 只拉高尚未接受的通道。
- direct qualification 同时要求 reset 解除、idle、完整 AW+W、size 合法、精确 low-contiguous
  mask 与自然对齐；允许 split 的 misaligned 请求继续走原 byte-split 慢路。
- direct E0 payload 与同边沿写入 q 的表达式相同；离开 idle 后输出只取 q。跨拍 AW/W stall
  assertions 对 VALID 与 payload 做逐位稳定检查。
- 上游 READY 仍只依赖 adapter state/holder；BREADY 仍只依赖 write-response state。
- adapter 没有 flush 输入；bridge 对已经呈现或 fire 的 AW/W 建立 escaped maintenance authority，
  并以 `old_done || same-edge fire` 补齐另一半通道后等待唯一真实 B。
- focused TB、causal exact-predecessor 对照、input/final-B compile-success mutations 与 canonical
  CoreMark/Dhrystone A/B 均与 task contract 一致。

## 非阻断的 promotion 前硬化建议

1. 在 E0 `00` 与一个单通道接受 case 后立即 poison 上游 live AW/W payload，强化 direct-to-q
   authority 的动态反例。
2. final-B mutation runner 像 input runner 一样逐项匹配绝对 latency vector，而不只匹配通用
   failure marker。
3. focused TB 增加独立 write `AWSIZE>3` fail-closed stimulus。
4. system signoff 增加 flush 与 E0 direct handshake 同边沿的 bridge+arbiter+adapter witness。

这些建议不改变本轮 `must-fix=0`，但在 promotion 前应重新评估。

## 声明边界

`PPA=UNQUALIFIED`，`promotion_eligible=false`。审计没有运行 synthesis、STA、area、power，
也没有资格化 5 ns timing。

最终 marker：

```text
[ADAPTER-INPUT-AW-W-FALLTHROUGH-INDEPENDENT-AUDIT][RETAIN] must_fix=0 predecessor_sha256=6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22 candidate_sha256=0199aa2fd75a6ce6b2a087ea6ca2a509cdba11db287224fc4e2be0cdda79b421 PPA=UNQUALIFIED promotion_eligible=false
```
