# v8b full identity reuse 反例审查

## 结论

8-bit allocation sequence 或 4-bit generation + 4-bit ROB index 都不能单独满足
“allocation cannot reuse a still-live identity”。因此本轮拒绝把只进入 ROB/SQ 的半套 tag 接到 active
permit；这不是实现延期的便利选择，而是由可构造反例决定。

## ROB-only 也可超过 256 次 allocation

令一个旧项 `T` 因未完成/held owner 留在 ROB，后面最多有 `k` 个年轻槽。即使每个具体分支 allocation
至多 resolve/recover 一次，嵌套 wrong-path/correct-path 子树仍能产生递归：

```text
F(0) = 0
F(k) = 1 + 2 * F(k - 1)
     = 2^k - 1
```

先分配当前最老的年轻分支 `B`；`B` resolve 前，它后面的 `k-1` 个槽可完成一棵 recovery/refill
子树；`B` mispredict 后清掉后代，correct path 又可完成另一棵独立子树。`k=9` 时已有 `511`
次 accepted allocation，足以让 8-bit sequence 回绕；16-entry ROB 可有 `k=15`。双发射只改变周期数，
不改变 accepted allocation 计数。

因此不能用“ROB 只有 16 项、顺序退休、每条分支只恢复一次”推导 `<256` 生命周期界。

## ROB 外 holder 使反例更直接

旧 WB、IQ/EX 长操作、SQ/MIQ、AXI response、Q1/Csr reservation、FENCE tombstone 或 registered-abort
窗口都可能在原 ROB slot 已失效后继续持有身份。若 allocator 回绕，而 consumer 只比 4-bit index 或
8-bit ticket，旧 response 会命中新 allocation。仅在 ROB 端 gate done 也不够：旧 WB 仍可能先写 PRF
并广播 wakeup，污染复用后的 physical destination。

## active 前不可缺的机制

候选 identity 必须在 allocation fire 前与全局 still-live reference 集做冲突仲裁；busy 只能在最后一个
引用消失后释放。集合至少覆盖：

- ROB、IQ、EX、mul/div/clmul/FP、WB 与 PRF/wakeup side effect；
- SQ、MIQ、reservation/buffer、bridge/PTW/RMW、terminal collector 与 late response；
- Q1 owner、Csr reservation、pending-system/FENCE owner、registered-abort 窗口与 tombstone。

所有 completion/response 必须携带 full identity；接受条件至少是
`target_live && target_identity == response_identity`，并在任何 side effect（ROB done、PRF write、wakeup、
dequeue、redirect、CSR apply）之前统一 gate。若采用 4+4 编码，per-slot generation 回绕时仍必须 collision
stall；编码方便本地寻址，不代替 last-reference 协议。

## 本轮工程裁决

本轮不修改 ROB/SQ/owner identity 数据面，避免制造“看起来已 generation-safe、实际 stale WB 仍污染”
的假基础。下一 identity 原子切片必须同时给出：全 holder census、last-reference/reuse 仲裁、WB/PRF/wakeup
反例、嵌套 recovery wrap 反例、reset/flush/abort 顺序以及 active 图 SCC 检查。在这些证据前，v8a permit
继续 tie-high，Q1A leaf 继续不实例化。

