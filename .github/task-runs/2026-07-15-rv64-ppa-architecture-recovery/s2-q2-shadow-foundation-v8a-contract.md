# S2-Q2 v8a 中性 shadow foundation 合同

> 日期：2026-07-19
>
> 状态：`reviewed scope / implementation RED / behavior-neutral shadow only / mem0-only`。
>
> 机器接口：`s2-q2-shadow-foundation-interface-v8a.json`。

## 1. 裁决

Q2 v7 的历史 RED 证据保持原样，不改写、不覆盖。反例审查证明 v7 不能直接作为完整 RTL
落地合同：它把 ROB head、前端 head 与 registered pending-system owner 混为一个事务，还没有冻结
完整 context payload、full identity provenance、FENCE.I generation 时序及 Q1 abort 优先级。

因此 v8a 只冻结一组可逆、行为中性的地基：

1. context ABI 宏；
2. ROB 的 commit-ready-independent precommit 观察口；
3. 独立于 done/recovery 的 live head-present/identity-valid 观察口；
4. context/FENCE.I permit 的 wrapper spine，但在 `NpcCoreTop` 精确 tie-high；
5. lane1 potential boundary 的 shadow classifier，但不进入 commit1 gate；
6. v8b 前必须关闭的 P0/P1 blocker 清单。

v8a 不实例化 Q1，不激活 permit，不发 selective squash，不推进 epoch，也不宣称 8-bit identity
已经具有跨 owner/wrap 安全性。即使结构 checker 变 GREEN，允许的上界仍只有
`v8a shadow interface/checker readiness`。

## 2. 冻结方程

### 2.1 ROB 观察与中性 gate

```verilog
head0_retire_candidate_valid_o =
    !recovering_w &&
    (count_q != 0) &&
    valid_q[head_q] &&
    head_done_w;

head0_identity_valid_o =
    (count_q != 0) && valid_q[head_q];

head0_base_ready_w =
    !recovering_w &&
    commit_ready_i &&
    (count_q != 0) &&
    valid_q[head_q] &&
    head_done_w &&
    !head0_csr_mem_hold_w;

commit0_fire_w =
    head0_base_ready_w &&
    head0_context_permit_i &&
    fencei_retire_permit_i;
```

`head0_retire_candidate_valid_o` 禁止依赖 `commit_ready_i`、两个 permit 或 commit fire；
`head0_identity_valid_o` 禁止依赖 done、recovery、commit ready 或 commit fire。后者只回答“captured
slot 是否仍是 live head”，不回答“能否退休”。

`head0_identity_o` 在 v8a 只要求宽度为 `OOO_CONTEXT_ID_W` 且依赖 `head_q`。其 generation 编码、
allocation provenance 与 reuse guard 明确留给 v8b；v8a 不允许任何 active consumer 据此 apply。

### 2.2 wrapper spine

真实链为：

```text
NpcCoreTop
  -> OooCoreTopGlue
  -> OooExecuteBackend
  -> OooAluCoreSlice
  -> OooAluDecodeBackend
  -> OooIntBackend
  -> OooDispatchBackend
  -> OooRob
```

中间六层必须逐层传播：

```text
inputs : head0_context_permit_i, fencei_retire_permit_i
outputs: head0_retire_candidate_valid_o,
         head0_identity_valid_o,
         head0_identity_o[OOO_CONTEXT_ID_W-1:0]
```

`NpcCoreTop` 冻结：

```verilog
head0_context_shadow_permit_w = 1'b1;
fencei_shadow_permit_w        = 1'b1;
```

这两个 tie-high 必须 exact-map 到 `u_ooo_core`；所有向上的输出必须来自锁名 canonical child，
宿主不得再加 local writer。tie-high 时退休行为逐位保持旧逻辑。

### 2.3 lane1 shadow classifier

v8a 只形成 shadow/后续 assertion 所需的 potential 分类：

```verilog
head1_is_csr_raw_w =
    (inst_q[head1_w][6:0] == OPCODE_SYSTEM) &&
    (inst_q[head1_w][14:12] != 3'b000);
head1_is_sfence_vma_raw_w =
    (inst_q[head1_w] & 32'hfe007fff) == 32'h12000073;
head1_is_xret_raw_w =
    (inst_q[head1_w] == 32'h30200073) ||
    (inst_q[head1_w] == 32'h10200073);
head1_is_fencei_raw_w = inst_q[head1_w] == 32'h0000100f;
head1_potential_context_boundary_w =
    head1_is_csr_raw_w || head1_is_sfence_vma_raw_w ||
    head1_is_xret_raw_w || head1_is_fencei_raw_w;
head1_context_boundary_shadow_w =
    valid_q[head1_w] && head1_done_w && !head1_exception_w &&
    head1_potential_context_boundary_w;
```

`commit1_fire_w` 在 v8a **禁止**依赖 `head1_context_boundary_shadow_w`。先观察、再用 focused
反例确认真实 system 指令归属，不能在 owner 模型未裁决前改变退休。

## 3. v8b 前置 blocker

| ID | 当前反例 | v8b 退出条件 |
| --- | --- | --- |
| `P0-IFU-ACK-DIRECTION` | done 的 exact RHS 不含 ack-generation output，但 v7 dependency 反向要求依赖该 output | done 只比较 sticky captured/request generation；ack-generation 另有 exact single driver |
| `P0-HEAD-PRESENT-AND-FLUSH` | identity bits 相同不等于 captured head 仍 live | held match 加 identity-valid，global flush 明确 retain 或 registered abort |
| `P0-FULL-IDENTITY-PROVENANCE-AND-REUSE` | SQ/owner 只保存 4-bit ROB index | full identity 从 allocation 进入每个 SQ/owner entry，并阻止 still-live identity reuse |
| `P0-SAME-OWNER-TYPED-CONTEXT-PAYLOAD` | precommit identity 可与 live/pending 另一条 CSR 载荷混配 | identity、operation、CSR operand、SFENCE scope、trap/xRET envelope、redirect 全来自同一 registered owner bundle |
| `P0-FENCEI-OWNER-DOMAIN` | ROB candidate 与 frontend FENCE.I raw 跨域 AND | FENCE.I 全部 ROB-owned 或全部 pending-system-owned |
| `P0-FENCEI-GENERATION-AND-CAPTURE-BLOCK` | request generation 与更新后的 q 比较存在 off-by-one/复用歧义 | alloc/held generation 分离，active/sent exact next，直到最终 commit 都阻止 admission/fill |
| `P0-Q1-ABORT-PRIORITY` | Q1 spec/RTL 无 abort，v7 wrapper 却依赖 abort 退出 sticky grant | spec、RTL、assertion、focused mutation 同时冻结 `abort > grant/apply > normal > hold` |
| `P1-CHECKER-SUPPORT-MODULE-DIRECTIONS` | v7 未加载既有 child direction，canonical clk/rst 出现 6 条假 RED/variant | audited/source-direction-support inventory 分离并锁定，已知 input 不再 fail-closed 为 output |

完整 v8b 还必须冻结 CsrFile raw writer arbitration、Q1 state/held exact next、phase/sent/recovery exact
transition，以及 FENCE.I ack 后到 commit 前的独立 capture block。结构 dependency reachability 不能替代
这些时序规则。

## 4. 必须失败的 v8a checker mutation

checker self-test 必须逐项杀死：错误实例映射、漏任一 permit、precommit 读 commit-ready、
identity-valid 复用 done、active permit 替换 tie-high、lane1 CSR self-inequality、漏 SFENCE 分类、
shadow classifier 偷接 commit1、identity 截成 4 bit、canonical child output 被宿主第二写、v8a 偷实例化
Q1、延期 blocker 漂移、v7 provenance 漂移与 contract-lock 漂移。

runner 对 release 与 `OOO_ASSERT` 两个 active-source 变体分别检查，并绑定 checker self-test、
RED count/digest 及 source pre/post 快照。结构 RED 只表示 shadow 地基尚未落 RTL；不能换算成功能缺陷数。

## 5. 历史证据与交付上界

v7 contract/manifest/checker/runner 及其 28-path evidence source inventory 由 v8a manifest 固定 SHA-256；
v8a 不修改这些文件。历史 v7 仍是 release 931、`OOO_ASSERT` 931、aggregate 1862 的预期 RED，
不是 v8a 的实施目标，也不是完整 Q2 可实现性证明。

当前交付不得声明：Q1 live、context barrier live、FENCE.I 已序列化、full identity/wrap 安全、
selective squash/full quiet 正确、dynamic epoch/stale response 安全、Linux、200 MHz 或 PPA 改善。
