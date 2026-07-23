# RV64 V9H IFU-FETCH-G2 当前设计重绑定

状态：scoped_closed；长期 goal 继续 active

本轮仅关闭本地 fetch bridge→packet decoder 的 `IFU-FETCH-G2` second-page page-fault
byte provenance。生产 `.v` RTL 未修改；改动集中在 testbench、current-design 证据生成器、
冻结语义验证器、canonical 入口和架构债务台账。

## Current-design 结论

- `design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `make -C npc/rv64 check-ifu-fetch-provenance`：focused 2/2、module aggregate 109/109、
  current-source 可编译 RTL 验证变体 16/16、fail-closed 单元测试 10/10。
- 13 行 page-end 矩阵包含 9 条 F2/F4/F6 fault（5/3/1）；每条 fault 在两拍 response
  backpressure 期间锁定原事务 owner，并在接受后两拍禁止年轻 instruction AR、cache fill 和
  SRAM write。真实 invalid-PTE F0、decoder F0、fault-tail poison 和无复位 stale-prefill
  反例均 PASS；成功正控制观察到 instruction AR=4、cache fill=1、SRAM write=1。
- current result SHA-256：
  `316c990ca24e3f6a097e0d827158a4b70bc35519ee46011e8ff80d73599fb1b0`；raw log：
  `d451a36815f23c4ef4f6bb582b7902e31f611613e8f5ed7aadb0c1d900b1cdc4`。
- 独立无工具复核结论 PASS；合同哈希只限定复核输入，不冒充 RTL 或动态证据来源绑定。

## 集成与全局边界

- `IFU-FETCH-G2` 已在 `architecture-debt-ledger.json` 中重绑为 `CLOSED`；V9H 测试已纳入
  `run-arch-stable-audit.sh` 的常驻 fail-closed 回归。
- 9 个 directed architecture hard gates 为 9/9 GREEN；来源摘要重绑定审计证明只处理
  `Makefile` 入口哈希漂移，architecture test semantic projection 未改变。
- 公共验证入口变更触发的既有证据过期已经通过 5 组 canonical 本地仿真重放修复：FDG 6/6、
  XRET 8/8、memory lifecycle 11/11、IFU AXI 18/18、INSTRET 3/3，且每组 module
  aggregate 均为 109/109。
- 最终 full-core audit：`architecture_freeze=GAP`、`ppa=UNQUALIFIED`、
  `promotion_eligible=false`、40 blockers。PMP/RRESP、完整物理 footprint、lane1 capture、
  fault-`tval` lifecycle、PTW write PMP 及其余 full-core/PPA 门保持独立，未越级关闭。
- 证据资产索引完成：182 assets；`npc-dev` profile 5/5 completed。首次 `agent-system`
  profile 虽 10 个执行节点均 PASS，但任务词只命中该 profile 自身记忆，bounded recall 因缺少
  独立业务 focus 正确保持 blocked；改用已发布到 NPC module memory 的领域词后，正式
  `agent-system` profile 10/10 completed。最终 strict guard 对 `agent-system`、`npc-dev`、
  `github-index` 三个必需 profile 全部 PASS。
