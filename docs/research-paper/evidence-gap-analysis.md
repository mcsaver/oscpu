# 证据缺口分析

## 1. 目的

本文拟研究：仓库级 RTL Agent 能否通过反馈循环、任务合同、设计身份绑定、负向验证和失败关闭机制，降低“报告完成、实际未满足工程目标”的风险。

现有材料能够证明若干错误候选被发现、拒绝或回滚，也能证明部分结果已绑定到 design-id、配置、原始日志和哈希。但这些材料来自不同月份、不同任务、不同设计状态和不同工具条件，只能形成纵向案例证据，不能直接承担严格因果比较。

## 2. 当前可支持与不可支持的结论

当前证据可支持：

1. 仓库中确实出现过 lint 或局部测试通过、整体目标却未满足的情形。
2. 双 memory、branch+ret 和分支推测等候选确实因性能、结构或聚合回归失败而被拒绝或回滚。
3. 七月的部分证据确实携带 design-id、原始结果哈希和指定错误变体的动态拒绝结果。
4. full-core `GAP` 和 PPA `UNQUALIFIED` 在局部测试全绿后仍被保留。
5. Yosys 结构统计和代理 STA 可用于风险定位或候选筛选，不能替代物理签核。

当前证据不可支持：

1. 不能证明反馈闭环相对于单次 Prompt 具有普遍因果优势。
2. 不能证明 design-id 和 publication 机制消除了全部 stale、cross-design 或 partial-write 风险。
3. 不能证明现有 mutation 集覆盖了全部重要 RTL 故障。
4. 不能把不同快照、workload 和测量边界中的 CPI、面积或时序拼成连续改进曲线。
5. 不能把 focused、module、代理综合或理想时钟 STA 通过写成全核完成或物理 PPA 签核。

## 3. 缺口台账

| ID | 研究轴 | 状态 | 缺失证据 | 不补齐的风险 | 最小关闭方式 |
|---|---|---|---|---|---|
| G01 | Prompt 与可执行约束 | `MISSING` | 同模型、同源码快照、同任务、同工具和同预算的配对对照 | 把时间演进误写成机制因果 | 预注册 B0—B3 受控实验 |
| G02 | task-run 计数 | `PARTIALLY_SUPPORTED` | workflow event、独立任务和有效实验单元的分母 | 把目录密度写成任务成功率或生产率 | 保留只读月度盘点并明确口径 |
| G03 | 运行环境 | `MISSING` | 早期模型精确快照、推理参数、随机种子、工具版本和初始树哈希 | 无法排除模型与环境混杂 | 未来 run manifest 将这些字段设为必填 |
| G04 | design-id / freshness | `PARTIALLY_SUPPORTED` | 陈旧证据、错误 design-id、错误配置、路径漂移的系统化注入矩阵 | 个别正确运行不能证明错误输入可被稳定拒绝 | 正负控制并行的身份故障注入 |
| G05 | 原子发布 | `MISSING` | 中断、并发写、缺文件、混合新旧文件和崩溃恢复测试 | 中间态可能被误读为 complete | staging + transaction + crash injection |
| G06 | mutation 非等价性 | `PARTIALLY_SUPPORTED` | base/mutant SHA、语义锚点和独立非等价裁决并非所有历史任务都齐全 | 编译成功却没有实际语义变化 | 只把经确认的非等价 mutant 计入分母 |
| G07 | oracle 可观察性 | `PARTIALLY_SUPPORTED` | 触发、传播和观测点的逐变体证明 | 同值连接或旧值 force/release 可产生假绿 | 每个 mutant 保存错误传播轨迹 |
| G08 | 回滚 | `OBSERVATIONAL_ONLY` | 有/无回滚门禁的配对结果，以及回滚后 design-id 恢复率 | 只能说明曾经回滚，不能量化收益 | 随机化移除 rollback 的消融 |
| G09 | 分层验证 | `OBSERVATIONAL_ONLY` | 每层新增发现的故障及移除某层后的逃逸率 | 不能量化 focused、module、official 等层的边际价值 | 逐层消融并记录首次检出层 |
| G10 | PPA 外部有效性 | `PARTIALLY_SUPPORTED` | 完整 I/O 约束、真实宏、SPEF、CTS、OCV 和物理后端 | 代理结果被误写成签核 | 未闭合前统一标记 `PPA UNQUALIFIED` |
| G11 | 隐藏评审 | `MISSING` | Agent 是否提前看到隐藏测试、mutation 标签或判定规则 | 对已知样例过拟合 | 独立维护者冻结私有 oracle |
| G12 | 评审独立性 | `MISSING` | reviewer 是否不知道条件标签和预期结论 | 审查者可能重复实现者假设 | 匿名 run-id 与盲化语义评审 |
| G13 | 论文可复现性 | `PARTIALLY_SUPPORTED` | 所有正文数字到原始文件和工具版本的机器追踪 | 数字随文档复制而失去来源 | claim-evidence map + 只读抽取脚本 |
| G14 | 外部有效性 | `MISSING` | 其他 RTL 仓库、HDL、EDA 流程和团队中的重复 | 单仓库经验被外推为普遍规律 | 将当前结论限制在本仓库，未来跨项目复现 |
| G15 | 模块纵向快照归因 | `OBSERVATIONAL_ONLY` | 同一 base design 上只开关 drain 条件的 paired variant、相同 workload/EDA 配置与重复测量 | 把 `OooPendingDrainResolveGate` 的三快照源码演化误写成单一机制导致性能或正确率提升 | 保留精确 Git/file SHA 历史用于机制追踪；因果问题另做配对消融 |

## 4. 论文提交前的 P0 边界

以下内容不要求现在补做实验，但正文必须明确降级：

1. G01：没有受控对照，因此不作“Loop 优于 Prompt”的因果结论。
2. G02：task-run 顶层目录只称 workflow-event directory。
3. G04：design-id 只证明证据归属与已注入错配的可检测性。
4. G06/G07：mutation 只对实际改变且可观察的指定故障集成立。
5. G10：结构综合和代理 STA 不写成物理签核。
6. G13：正文关键数字必须落到 `claim-evidence-map.tsv` 的真实路径。
7. G15：三个模块快照只证明合同演化；不把跨快照指标差异归因于某一新增或删除条件。

## 5. 推荐措辞

推荐：

- “现有任务记录观察到……”
- “该机制在所列 design-id 和故障集合内拒绝了……”
- “这个案例说明局部通过不足以推出整体完成……”
- “结果支持将该机制作为降低风险的候选方法……”
- “尚不能从纵向记录中识别独立因果效应……”

避免：

- “证明了 Loop 一定优于 Prompt。”
- “彻底消除了陈旧证据或假完成。”
- “mutation 已覆盖全部关键错误。”
- “RV64CORE 已完成物理 PPA 签核。”
- “task-run 数量就是独立实验数量。”
