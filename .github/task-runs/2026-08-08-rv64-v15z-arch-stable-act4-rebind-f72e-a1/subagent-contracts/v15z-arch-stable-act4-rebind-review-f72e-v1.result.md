RV64 RTL 结论｜对象=NpcTop f72e ARCH_STABLE 候选｜周期/配置=146 RTL、5.0 ns、seed=0、thread=1、9 项硬门禁｜TB/EDA 观测=ACT4 100/100、holder 46/46、历史缺陷 6/6、断言 0 失败｜范围=PASS

- 候选 SHA 精确匹配 `697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade`；design-id 为 `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`。146 项 RTL 无漂移，9/9 architecture gates GREEN。
- L0 为 113/113；默认 L1 包含强制 ACT4 子队列 100/100，另有 official 177/177、AM 61/61、DiffTest mismatch=0；L2/L3 同设计 PASS、RTL assertion failure=0。
- producer-holder closure 为 17 个 holder、46/46 semantic units、52 个 elaborated bindings；V14G baseline 4/4、compile-success mutation 22/22。历史缺陷 6/6 回填当前设计，其中 VD4=3、VD3=3、VD0/VD1=0。
- V9P 精确重绑定确认 terminal collector 仍为 fail-loud、exactly-once、无 dedup；bank0、bank1、retry-fire-open 与 final-B fallthrough 反例均被相应 oracle/marker 捕获。
- 决策为 `APPROVE_ARCH_STABLE`：`architecture_prerequisites=PASS`、`producer_holder_static_semantic_dynamic=PASS`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。预审唯一 GAP 是待本报告生成精确绑定 receipt，非额外 RTL 技术缺口。
- `unknowns=[]`，`open_blockers=[]`，`scope_extension_request=none`。边界保持：Ubuntu 为可选 `NOT_RUN`；5 ns STA 仍为 `FAIL_NOT_PROMOTABLE`，未运行新的综合/STA，且不得据此提升 PPA 或 canonical 状态。
- 假设：四项 cohort exclusions 保持既定产品边界；L2/L3 使用已封存 receipt 的确定性重放。替代方案中的对称 bank 选择或不同 final-B 延迟契约均不改变当前合同。置信度：高。

[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42 candidate_sha256=697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade

全部只读命令已退出，未写入仓库；WSL shell ownership 已归还主 agent。
