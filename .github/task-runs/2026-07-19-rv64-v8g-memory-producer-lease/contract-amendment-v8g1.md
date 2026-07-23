# v8g.1 reviewer-blocker amendment

## 独立复核结果

只读 reviewer 在不调用工具/文件/网络的前提下给出 3 个 blocker：

1. reservation capture 的 current-exact 不能替代若干拍后 AMO/STORE 不可逆 request fire 授权；
2. STORE bulk release 若只按 kind，无法证明 aggregate B 前 lease 不被提前清；
3. ROB query match 不等于 completion sink 已有 credit，transport pop/free 必须与真实 acceptance
   分开。

初次 verdict 为“不可进入 RTL”。父目标保持 `active`，未通过弱化语义或重复派发绕过结论。

## 冻结修订

| blocker | 修订 | RTL 判据 |
| --- | --- | --- |
| AMO/STORE launch | SQ 保存 dispatch full PID；AMO token PID 与 SQ head PID 都必须在 request fire 当拍等于 current ROB head PID，且非 flush/restore | request-fire assertions + wrong-generation directed cases |
| STORE B terminal | `qualified_store_release` 仅限未发且无其它 authority，或 aggregate B status 已被 exact completion 接收后的最后同沿 handoff；现有 resident/pending/override 代数必须机器审计 | AW/W-before-B、flush-before-B、B-error、same-edge B/release tests |
| completion acceptance | `completion_fire = exact tuple && tracker live && ROB exact-open && !done_now && all sink credit`；open-no-credit hold；closed speculative drain-only；DRAIN closed fatal | WB-credit stall、duplicate EX/mem PID、stale LOAD/AMO/PROBE tests |

## 额外 reviewer 要求

- mandatory 双发射必须原子接受；optional lane1 collision 只丢 lane1；lane1 candidate 禁止依赖
  ready/fire；双候选 PID 不同。
- tracker 使用显式 birth/death、pid_clear/pid_set 集合代数；exact free 与 release 同 token
  只能产生一个 death；dual alloc token/PID pairwise unique。
- 一一映射不能只靠 popcount：每个 live token 必须命中 live PID，每个 PID 的 token match
  vector onehot0，且 PID live 等价于至少一个 live token。
- token free 前必须证明所有仍可能消费 tuple 的 holder 已终止，或消费必先复核 tracker live/tuple。

本修订已同步 active spec、contract、census 与 derivation；需通过 reviewer 二次复核后才进入 RTL。
