# S2-Q2 v8a 最终双人格审查

> 日期：2026-07-19
>
> 审查对象：tie-high、无 active consumer 的 v8a neutral shadow foundation。

## 实现者交付证据

- 26 个 ABI 宏、2 个 permit 输入与 3 个 observation 输出沿
  `NpcCoreTop -> OooCoreTopGlue -> OooExecuteBackend -> OooAluCoreSlice ->
  OooAluDecodeBackend -> OooIntBackend -> OooDispatchBackend -> OooRob` 闭合；顶层两 permit
  exact tie-high。
- ROB retire candidate 独立于 `commit_ready_i`/permit，identity-valid 独立于 done/recovery，
  identity exact 零扩展 ROB index；lane1 四类 raw classifier 仅形成 observation。
- `commit0_fire_w` 只在冻结 old base-ready 末端 AND 两 permit；`commit1_fire_w` 保持旧 RHS，
  且断言/测试锁定 `commit1 -> commit0`。
- 统一入口 `make -C npc/rv64 check-q2-v8a-shadow` 通过；104/104 module aggregate、style、
  contract 通过；release/`OOO_ASSERT` 各 1036 行 legacy trace 与 pre-edit bundle 字节相同。

## 审查者反例与处置

| 反例 | 处置 | 状态 |
| --- | --- | --- |
| permit 拉低但 lane1 越过 head0 退休 | exact 锁旧 commit1 RHS；新增 `commit1 -> commit0` assertion；两-entry、两 permit-low 动态测试 | scoped resolved |
| alternate instance 漏接/positional 造成 Z/X | 全 `npc/rv64` `.v/.sv` census：7 RTL + 8 TB；五端口齐、permit 非空、无 positional | scoped resolved |
| raw CSR/SFENCE/xRET/FENCE.I 绕过 aggregate shadow 直接门控 commit1 | checker 禁止六个 raw/potential/shadow source，并 exact 锁 commit1 RHS；四类边界动态触发 | scoped resolved |
| 8-bit identity 任意重编码或被误称 full identity | checker exact 锁零扩展；文档限定为非 generation/reuse-safe observation | scoped resolved，activation blocked |
| 标量端口被扩宽 | 双 active variant 逐 module 锁 scalar direction/range | scoped resolved |
| 只比 warning 数量导致一增一减假绿 | 最新 warning 行归一化后与 pre-edit 快照 byte-match；非致命 lint 完整解析/展开 | evidence resolved，global gate remains RED |
| bounded trace 被误称形式等价 | 结论明确限定为两个配置下 1036-cycle legacy ABI trace | wording resolved |

最终封存前还发现并关闭了一个 runner 自身的假绿：补充 checker 曾被误包在“发现 structural
RED”分支内，正常结构 PASS 时反而跳过。runner 现于开工先删除相关旧日志和 completion marker，
无条件执行 supplement self-test/readiness，并 exact 要求 census=15；104/104、style、contract、
strict lint、forced default build 与 nonfatal parse 也由同一次 runner 亲自重跑。pre-lint log 与
normalized signature 各有固定 SHA，最新 strict/full-build/nonfatal warning 行现场归一化后必须
逐字节匹配，才会重新生成 marker。

## 剩余硬阻塞与裁决

独立审查者最终复核确认：v8a 固定 tie-high、输出无 consumer 时，没有未解决的架构 P0/P1
冲突阻止 scoped 交付。以下事项在任何
permit/observation 激活前仍是 P0：generation/reuse-safe full identity；同 owner 的 CSR/SFENCE/
trap/xRET payload；Q1 实例与 abort；selective younger squash；full quiet；FENCE.I 独立 owner/
generation transaction；grant-edge ingress/apply 原子性；dynamic epoch 全链和 terminal exactly-once。

严格 lint 与 full default build 因同一组 115 条历史告警保持 RED，未被豁免；没有综合、STA、
Linux、面积或功耗证据。因此审查裁决只允许：

> **v8a tie-high scoped neutral shadow foundation GREEN；global lint/build RED。**

不得推出 active permit 正确、Q2 完整、full identity 安全、形式等价、Linux 可启动、200 MHz
达标或 PPA 改善。
