# V11S completion definition

本地 RV64 MulDiv producer lifecycle 只有在当前源码、双 generation width、
assert/release、compile-success 负向 RTL 版本、普通回归、current graph 与
独立终审同时闭合后，才可关闭限定的 `muldiv-producer` 语义单元。

## 已满足

- [x] production `OooIntBackend.v` SHA-256 为
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`。
- [x] production `OooMulDivUnit.v` SHA-256 为
  `c28ad0cf4a00644d906261cc05a6194cc78474afa9f70f8183a6bf996ba38eed`。
- [x] design-id 为
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- [x] 4/4 baseline 在 generation width 1/4、assert/release 下通过。
- [x] 9 类 compile-success RTL 版本在两个 generation width 下由声明
  exact-stage oracle 拒绝，18/18。
- [x] 4/4 ordinary regression 与 source pre/post binding 通过。
- [x] V11S runner unit 10/10。
- [x] graph unit 19/19、census unit 15/15、V11H replay unit 6/6、
  semantic unit 85/85。
- [x] current graph 为 15 holder modules、17 holder instances、
  2 duplicate modules，拓扑与 V11R 完全一致。
- [x] combined semantic gate `rc=0`。
- [x] ledger 只将 `muldiv-producer` 晋为 PASS，汇总为 35 PASS / 9 GAP。
- [x] 独立反例优先 reviewer 完成 bounded PASS 终审。

## 收尾门禁

- [x] project/module memory 更新与 bounded DB recall。
- [x] `npc-dev` e2e、scoped strict guard 与 full-worktree strict guard；
  full-worktree 唯一 FAIL 已绑定范围外 `amo.c → nemu-dev`。
- [x] final static gates、task-run publication 与最终 verification receipt。

## 不构成完成

- CLMUL、pending-system 与七个 FP producer 语义仍为 GAP。
- whole architecture 仍为 `RED`，PPA 仍为 `UNPROMOTED`。
- 本轮未运行完整系统、formal、综合、STA 或功耗。
- A3 checker replay 不改写 A3 原始 `FAIL rc=1`。
