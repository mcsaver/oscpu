RV64 RTL 结论｜对象=NpcTop f72e / `arch-stable-candidate-f72e-v5/candidate.json`｜周期/配置=146 production RTL、clk=5.0 ns、seed=0、threads=1｜TB/EDA 观测=9/9 GREEN、ACT4 100/100、L0–L3 PASS、STA `FAIL_NOT_PROMOTABLE`｜范围=PASS

- 精确绑定：v2 合同 SHA 为 `e9eefb5e…c0a9`，候选 SHA 为 `697ec156…6dade`，design-id 为 `sha256:f72e1fb4…e3659a42`。预审唯一 GAP 是 `independent_review.exact_binding`，无其它 FAIL/GAP；本报告给出该独立复核决定。
- 架构与系统：146 项 RTL 无漂移，DI-1…DI-5、OOO-1…OOO-4 全部 GREEN。L0 113/113；L1 official 177/177、AM 61/61、DiffTest mismatch=0，且 ACT4 是 `required_subcohorts.act4_architectural_certification`，100/100、每例唯一 terminal PASS、断言失败 0；L2 为 6,098,497 commits/9,882,568 cycles，L3 为 24,460,280 commits/57,129,353 cycles，均 PASS 且断言失败 0。
- Holder 与历史闭合：17 个 holder instance、46/46 semantic units、52 个 elaborated bindings，V14G baseline 4/4、compile-success mutation 22/22。静态 census 的 `semantic_complete:false` 是交接状态；候选实际采用的 canonical semantic coverage 为 46/46、gap=0，三个 stale evidence set 未被选作闭合证据。历史缺陷 6/6 为当前 f72e 回填，VD4=3、VD3=3、VD0/VD1=0。
- Exactly-once：`OooMemOwnerTerminalCollector` 保持 fail-loud、no-dedup；`OooIntBackend` bank0/bank1 ready-open 分别被 `[V9R-SQ-RETRY-C0-HANDOFF]` 拒绝，bridge retry-fire-open 被 `[V9R-MEM-SQ-RETRY-C0-HANDOFF]` 拒绝，final-B fallthrough 被绝对 owner-terminal latency oracle 拒绝。changed cone 29/29、历史负向集合 175 项均闭合。
- 边界：Ubuntu 为 `NOT_RUN`、仅显式用户请求运行且不阻塞默认签核；未执行新的 L2/L3 guest、综合或 STA。PPA=`UNQUALIFIED`、promotion_eligible=false，5 ns STA 仍不得晋级，结论不提升 canonical、PPA、功耗、面积或 CPI。
- `unknowns=[]`、`open_blockers=[]`、`scope_extension_request=none`。保留的非声明边界是历史 V9P immutable bank/owner tuple 未留存及 final-B 负向复用既有同哈希证据；当前 f72e 对称双 bank 定向反例与精确源码绑定已使其不构成本候选未知项。替代解释仍包括任一对称 bank 可能是历史来源，以及不同 latency contract 下 registered-only final-B 可能成立。
- `confidence_and_basis=HIGH`：依据候选、预审、ACT4、layered/system、holder、debt、historical 与 V9P receipt 的现场 SHA-256 及字段交叉核对。

[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42 candidate_sha256=697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade

全部只读命令已退出，未写入仓库；WSL shell ownership 已明确归还主节点。
