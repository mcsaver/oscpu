RV64 RTL 结论｜对象=OooBranchDirectionPredictor/u_local_pht/OooBranchLocalPhtBank 与 bpu-local-pht-banked-child-implementation-v1 evidence｜周期/配置=0-cycle 双读、update S1/S2；live b279 / mapped-5ns-bpu-local-pht-banked-child-inline-v1｜TB/EDA 观测=既存证据中 directed TB PASS；11/11 mutant 编译并动态 FAIL、仅 9/11 满足当前 runner marker；未重跑仿真/综合/STA，d3f3 PPA 为 stale｜范围=GAP

独立裁决：**FIX**。功能 RTL 可 **RETAIN**，当前 evidence bundle 与 PPA promotion 必须 **BLOCK**；完成下列最小修订后可进入 A2，不需要修改 `OooFrontend` 或增加预测周期。

## RTL/cycle/state 复核

- `OooBranchLocalPht` 独占 16×256 `valid_q/counter_q`；`OooBranchDirectionPredictor` 继续独占 global BHT、local history、GHR 与 hybrid-select 状态，parent/child 未形成重复 state owner。
- 两条 lookup 均为组合 bank/row decode 和组合返回，保持 0-cycle、同周期双取指消费。
- update 在 child 内为 S1 捕获 `valid/row/taken/old_ctr`，S2 饱和写回；与 parent 的 local-history/global/select S1/S2 对齐。
- 同 bank 同 row双读返回同一 entry；同 bank异 row已有 directed覆盖。**已训练的不同-bank双读没有 directed覆盖**，这是最小 A2必补项。
- lookup 与 S2 collision保持 read-before-write；back-to-back同 entry update保留原有无 forwarding语义。
- `clear_i` 同时清 valid和 pending S1，丢弃尚未进入 S2的 update。
- predictor 没有 restore-local-PHT 端口；有效 resolve/update即训练，mispredict不回滚 PHT。现有 parent TB对该局部语义有效，但并非完整 frontend recovery集成证明。
- public `update_taken_i`仍驱动16个 bank端口；每个 bank仅在本 bank one-hot valid时捕获，所以 RTL将原集中 state-array写入缩至16个 bank-local S1，而不是4096-entry级 fanout。

## Mutation oracle

原始 `mutation-evidence.json` 显示 `compile_succeeded=11`，11项均非零退出且各有一个 `[RESULT] FAIL`。前9项满足当前精确 marker；`mispredict-suppresses-train` 与 `mispredict-restores-local-pht` 首个可观察分歧更早被 checker 捕获：

```text
[BPU-L1-STRONG] lookup1 strength mismatch: got=0 exp=1 pc=0000000080001020 @28
```

因 runner错误期待后续 P1 marker，故当前为 `rejected=9`、`all_rejected=false`。

应当**修 runner，不修 TB**：独立 checker的 fail-fast是更强 oracle。两项 mutation应绑定稳定前缀（至少含 marker、got/exp与PC），并把 `expected_marker_count > 0` 收紧为 `== 1`；仍要求 compile artifact、唯一 `[RESULT] FAIL`、无PASS和source hash不变。

建议但非最低准入项：补 `taken-polarity-inversion` 和 lookup bank-decode反例；当前11项未直接证明这两类 mutation sensitivity。

## 工程与 registry

- `OooBranchLocalPht.v`已进入 frontend filelist，且位于 parent predictor之前；owner/lifecycle为 product core。
- registry只有一个新 identity：`mapped-5ns-bpu-local-pht-banked-child-inline-v1`，为 noncanonical/nonchampion engineering archive；child仍 inline，因此当前不应伪造 placeholder/Liberty/OOC宏。
- live design为 `sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e`；旧mapped receipt为d3f3。`ARCHITECTURE.md`的`GAP_STALE_DESIGN`与run contract仍期待d3f3，能阻止旧PPA绑定live RTL，fail-closed正确。
- mutation Makefile默认结果目录硬编码旧task-run；A2应改成新的task-owned空目录或要求显式传入，避免复用旧evidence。
- `flatten=0/share=0`有利于保留bank结构，但`keep_hierarchy_modules`未包含`OooBranchDirectionPredictor`、`OooBranchLocalPht`、`OooBranchLocalPhtBank`。因此当前只能确认RTL结构，不能确认mapped逻辑未重新sharing。PPA前应增加配置级hierarchy保持投影及负向registry/tool检查。

## 最小 A2 修订

1. 新增“已训练、不同bank、不同counter、同周期双lane、无tick”directed case。
2. 将两项mispredict mutation的oracle改绑`[BPU-L1-STRONG]`首分歧，并要求marker恰好一次；保留P1/P2正向marker。
3. mutation输出改为全新、空、task-owned路径，并绑定raw log hash/size。
4. 为predictor/child/bank增加配置级hierarchy/share约束及静态负向检查。
5. 新PPA前把run design identity/versioned contract更新到A2实际digest；旧d3f3 receipt必须继续拒绝绑定。

未来授权验证应依次满足：child/parent directed TB RC=0；11/11 compile-success mutation精确拒绝；registry/schema/tool定向测试通过；mapped结构可见16个bank-local S1且无重新形成的集中write cone；最后执行一次确定性同设计5ns PPA。

Pareto/rollback门：相对旧inline `WNS=-50.241458893 ns`、相对四宏基线`area +283823.40`，必须至少一项严格改善且另一项不退化，并同时闭合child internal timing与`NpcTop` boundary timing。任一cycle/state/mutation失败、bank结构被映射重共享、receipt仍绑定d3f3，或仅靠黑盒隐藏内部违例，均回滚。

Unknowns：没有新mapped netlist、fanout report、child internal timing/area/power或同设计STA；完整recovery-gate→frontend集成交互未在本节点动态证明；未冻结最终scoped diff provenance。中等置信度判断是banking可降低集中update fanout，但不能视为已证明的Top40 root cause，替代解释仍包括decode/mux深度、布局拥塞或综合重共享。

`scope_extension_request`：当前功能FIX不需扩展；若要解除PPA GAP，需另建授权节点运行fresh mapped synthesis/STA，并纳入mapped hierarchy/fanout、child internal timing/area/power、`NpcTop` Top40和新receipt。

合同SHA-256=`1286e9d3a69736ec9ea5108549f6b69d77a59bc22f7b897852f452576123b697`。WSL工程命令已停止，shell ownership已归还。
