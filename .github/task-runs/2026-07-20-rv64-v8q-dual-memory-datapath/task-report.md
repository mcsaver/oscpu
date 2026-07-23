# v8q 任务报告：双内存共享 AXI miss fabric F0

## 本轮结果

本轮新增并验证了未接入 canonical core 的可综合叶模块
`OooDualMemAxiArbiter`。它允许未来两份单 outstanding、单 beat memory bridge
安全共享一个 downstream AXI 子集：IDLE 注册选择 transport owner，read 锁到 exact-owner
R terminal，write 独立吸收 AW/W 任意偏斜并锁到 B terminal，非 owner 不可观察
request READY 或 response VALID。

唯一获准的结果是 `dual_axi_miss_fabric_leaf_verified`。F0 尚未提供第二份
bridge/DTLB/cache/MIQ/final-PA SQ query/completion，也没有接入主核，因此 DI-5、OOO-3、
overall 保持 RED，PPA 为 UNQUALIFIED。

## 实现与合同闭环

- 五态 FSM：`IDLE/READ_ADDR/READ_RESP/WRITE_DATA/WRITE_RESP`。IDLE 无组合
  fall-through，只在时钟沿捕获 `owner_q/is_write_q`。
- `aw_seen_q/w_seen_q` 独立记账；已 fire channel 不重复展示，只有两者都完成才进入
  B phase。`rr_q` 只在 R/B terminal 指向另一 lane。
- `rst` 固定为上下游同域的全系统同步 reset：组合握手输出静默，沿上清 state/owner/
  type/rr/seen，并共同放弃 reset 前事务；解除后不消费孤儿 R/B。
- 一个 lane 同拍出现 AR 与 AW/W 时全局 fail-closed：release 不捕获任一 lane、不更新
  状态、不产生 fire；assert profile 以 `ARB-REQ-CLASS-ONEHOT` 拒绝。
- 过程式 assertion 覆盖 owner hold、非 owner 隔离、AW/W exactly-once、R/B phase、
  response onehot、IDLE/reset quiet 和 AR/AW/W/R/B stall payload 稳定。

首轮独立合同审查提出 F0-G01..G05：reset、progress-bounded fairness、非法 dual-type
范围、mutation 接受条件、source closure/freshness。五项均被写回 spec/contract，并转换为
逐 phase reset TB、定向公平/非法输入 oracle、固定 12 族 compile-success mutation 和
去注释 fail-closed checker；文本审查本身未作为 PASS。

## 可执行证据

永久入口：

`make -C npc/rv64 check-dual-memory-fabric-foundation`

最终 fresh run：

- `run_id`: `v8q-f0-20260720T030925Z-849762`
- F0 RTL SHA-256：`f4b810ed5ada6f68e920ab077a596daf18dee7fe485acae59102f0c2d575b3b7`
- source closure SHA-256：`d271ddf5fca6c6c8ef552fb1c1111b691e43e77714aeb51f3720dedbe18a5186`
- release、`OOO_ASSERT`、assert-negative 三个 profile 全部 fresh PASS；负例真实非零退出并
  唯一命中 `ARB-REQ-CLASS-ONEHOT`。
- release/assert 矩阵覆盖 lane0/lane1 read、AR/R stall、transaction-bounded fairness、
  AW-before-W、W-before-AW、同拍 AW/W、B stall、response isolation、IDLE registered
  capture，以及 READ_ADDR、READ_RESP、AW-only、W-only、WRITE_RESP reset 和 orphan R/B。
- 12/12 source mutation 均 `compile_success/elaborated/activated/target_rejected=true`，且
  只有专属失败码；覆盖 read/write 早释、seen tieoff、R/B 广播、READY 交换、固定优先、
  rr 提前更新、IDLE fall-through 与 reset owner 残留。
- fail-closed checker 的 10/10 单测覆盖空文件、comment-only module/marker、缺状态、
  seen tieoff、duplicate module、response broadcast、rr 非 terminal 更新和 canonical 实例检测；
  Verilator release/assert lint 与仓库 RTL style gate 通过。
- runner 在执行前后重算完整 source closure 和 canonical architecture manifest 摘要；两者
  均未在运行中变化，唯一 `[V8Q-F0][PASS]` 只在全部子门通过后生成。

## 同摘要架构发布

F0 文件进入统一 RTL catalog 后，canonical source digest 变化，旧摘要证据没有被复用。
先 fresh 重跑 `make -C npc/rv64 check-pair-matrix`，再重跑 F0。当前 architecture manifest
与 hard checker 共同绑定：

- design id：`sha256:79e445cd976f7a2ace1da6288866b2442846677520052a95eea7c14504ab2cca`
- GREEN：`DI-3`、`DI-4`、`OOO-1`、`OOO-2`
- RED：`DI-1`、`DI-2`、`DI-5`、`OOO-3`、`OOO-4`、overall
- PPA：UNQUALIFIED

因此本轮既没有因“未实例化”跨摘要借用旧 PASS，也没有把 F0 leaf 误作完整双 memory
data path。

## 独立审查与权限边界

最终实现审查使用 skill 生成、校验并渲染的原生 `self-contained-no-tools` 合同：

- 路径：`subagent-contracts/v8q-dual-memory-fabric-final-review.json`
- SHA-256：`191ff2dc5506253ad0c82a3db8eb8f768e72535f8f0de3a44c0d9baaf382e46d`
- 权限：无工具、无 shell、无文件访问、无网络、无账号/凭据、无写入。

reviewer 结论为 `pass`、blockers 为空、`same_digest_publication_ok=true`、
`claim_boundary_ok=true`，逐项挑战了 owner 早释、AW/W skew、response 广播/READY 交换、
公平、非法 dual-type、逐 phase reset/orphan response、fall-through/stall 稳定、inactive
mutation/vacuous checker 与跨摘要越级发布。

该协作方式的目标是准确描述本地 RTL、最小化真实权限并保留可审计 provenance，不是规避或
削弱平台检查。若某个 reviewer 请求暂时不处理，只把该节点记为 `review_pending`；父目标保持
active，已有 RTL 证据不被抹除，也不通过改写 RTL 语义反复重提。

## AI 环境实战纠偏

首次使用 `no-tools-rtl-subagent-contract-v8q` 和 `db-first-stored-memory-audit-v8q` 运行
`agent-system`/`github-index` 时，所有业务节点虽为 PASS，startup recall 仍因 `v8q` 没有独立
primary focus 而正确 blocked。两个失败包原样保留，节点绿没有覆盖召回失败。

根因是 `e2e_context_brief_terms` 把 task slug 中未声明用途的版本词也作为 non-history AND
focus，不是 RTL 内容或 reviewer 权限越界。第一版“至少两个领域词后删除末尾 v-number”的
启发式没有被接受：临时 no-tools 复核给出 `SLUG-G01/G02`，证明它会让短生命周期 slug 假非空，
也会误删 JavaScript V8、v2ray 等真实领域词；该复核又缺少派发前 JSON 合同，因此只保留为
gap discovery，不作为最终 provenance。

canonical runner 现采用受控身份片段：只有显式相邻的
`revtag-v<数字><可选字母>` 会在 stopword/数字/去重/八词截断之前从 focus 删除；裸 `v8`、
`v2ray`、内部 `v8a` 一律保留，畸形或重复 `revtag` 非零，task slug 原文继续绑定 report、
manifest 与 DB。`agent-system` 固定以下正反例：

- `no-tools-rtl-subagent-contract-revtag-v8q` → `no/tools/rtl/subagent/contract`；
- `agent-e2e-run-revtag-v8q` 与 `rtl-contract-revtag-latest` 均非零且无输出；
- `node-javascript-engine-v8`、`network-client-v2ray` 与内部 `v8a` 均保留；
- 八个业务词再加 `revtag-v8q` 时仍完整保留八词。

最终复审由 canonical `self-contained-no-tools` JSON 合同预先绑定：路径
`subagent-contracts/v8q-task-slug-revision-review.json`，SHA-256
`46fe3b4d3cd33b088d4f32292b196f598a7d7a8f24bef139d706dbce8d040c82`；reviewer 未调用
工具/文件/网络/写入，裁决两项 gap 均 closed、blockers=0。完整
`2026-07-20-no-tools-rtl-subagent-contract-revtag-v8q` 为 agent-system 10/10 PASS、
`recall_status=complete`，strict guard 已接受。两次更早的 strict guard 失败也原样保留：其输入
mtime 晚于旧 run；fresh run 前后相关 source SHA/mtime 不变，证明 runner 自身没有改写 live source。

在最终 memory/DB/task-run 同步之后，又以受控 revision 身份完成 freshness 收尾：

- `2026-07-20-no-tools-rtl-subagent-contract-revtag-v8q-final`：agent-system 10/10 PASS；
- `2026-07-20-db-first-stored-memory-audit-revtag-v8q-final`：github-index 1/1 PASS；
- `2026-07-20-dual-memory-axi-fabric-revtag-v8q-final`：npc-dev 5/5 PASS。

三者均为 `status=completed`、`recall_status=complete`，原始 task slug 保留受控 revision 片段，
focus 中只删除 `revtag-v8q`。

因此后续遇到平台 review 或 recall 暂停时，应保留原失败证据、区分权限问题与检索身份噪声、
修 canonical 入口并补正反回归；不得通过含糊措辞、扩大权限、删除失败记录或降低 fail-closed
门槛来追求通过。

## 剩余风险与下一步

- directed/mutation evidence 不是形式化穷尽；RTL、TB、checker、构建参数或 manifest 任一
  摘要变化都必须重新运行固定入口。
- F0 尚未实例化，未证明两路 cache hit admission、独立翻译/MIQ/completion 或物理 SQ
  byte query；也未证明 miss lock 不反压另一条真实 hit path。
- 没有 fresh synthesis/STA/power/Pareto 数字，不得声称 PPA 改善。
- 长期父目标保持 `active`。下一原子阶段应是 F1 双 bridge/cache-hit wrapper 与 peer
  maintenance 叶级验证，仍不得在接入 backend 前提升 DI-5。
