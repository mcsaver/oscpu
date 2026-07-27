# 受控实验计划

## 1. 研究目标

后续实验不预设“Loop 必然优于 Prompt”，而检验四个可证伪问题：

- **RQ1**：在模型、任务、源码、工具和预算受控时，可执行工程约束是否降低假完成率？
- **RQ2**：design-id、配置绑定、freshness 和原子发布能否拒绝陈旧、跨设计和不完整证据？
- **RQ3**：经非等价性确认的 mutation 是否提高验证环境对 RTL 故障的区分能力？
- **RQ4**：反馈、分层门禁和回滚是否减少回归逃逸和不安全候选发布？

B0—B3 用于比较逐级工作流包。单个机制的因果贡献必须由随机化消融识别，不能从阶梯差异直接推出。

## 2. 实验条件

| 条件 | Agent 能力 | 反馈 | 证据约束 | 发布规则 |
|---|---|---|---|---|
| **B0：Single Prompt** | 固定任务、源码和静态上下文；一次生成 | 无执行反馈 | 无结构化合同、design-id 或 mutation | 候选提交后由隐藏评审离线判定 |
| **B1：Basic Loop** | 可读取仓库并运行公开工具 | 可依据编译、仿真和测试迭代 | 不强制 bounded recall、合同、身份或 mutation | Agent 自行判断完成 |
| **B2：Contracted Loop** | B1 + bounded recall + task contract | 反馈必须映射到合同输入、输出和成功条件 | 保存命令、返回码、配置和原始日志 | 可见合同门禁通过后才能报告完成 |
| **B3：Evidence-Qualified Loop** | B2 + design-id + freshness + mutation + rollback | 分层验证，坏候选拒绝或恢复 | 绑定源码、配置、命令、原始哈希和 fault set | staging 校验后原子发布；缺一项即保留 GAP |

B0 与其他条件存在固有交互机会差异，因此 B0 vs B3 只解释“完整工作流包总体效果”。RQ1 中可执行合同的独立效应主要由 B1 vs B2 和组件消融回答。

## 3. 固定变量

正式实验前冻结：

1. 精确模型快照、推理参数、上下文上限和基础 system prompt；
2. 每个任务的初始 Git commit、工作树哈希和依赖版本；
3. 操作系统镜像、编译器、仿真器、Yosys/STA 版本和脚本；
4. CPU、内存和并行度限制；
5. 公开规范、公开测试和可读取路径；
6. 每次运行的最大 Token、墙钟时间、工具调用和候选发布次数；
7. 隐藏测试、mutation 集、评价器版本和阈值；
8. 计时、日志、哈希和指标计算方法。

B1—B3 使用同一最大交互预算和工具集合。预算预试验不计入正式统计；正式运行开始后不得按中期结果为某一条件追加资源。

## 4. 任务集

任务覆盖八类历史风险：

| 类别 | 风险 |
|---|---|
| A | 编译或 lint 通过，但功能目标未验证 |
| B | focused test 通过，但 module、official 或系统回归失败 |
| C | 局部 CPI、结构或时序改善，但整体指标或功能退化 |
| D | 证据属于旧源码或旧 design-id |
| E | 证据来自错误配置、另一候选或另一设计实例 |
| F | 结果目录不完整、混合新旧文件或发布中断 |
| G | mutation 没有改变语义，或错误不能传播到观测点 |
| H | FENCE、owner、分支恢复、STORE/AMO 等控制事件错误 |

确认实验至少包含每类两个独立实例，共 16 个任务。两个实例必须位于不同代码或控制路径，不能只是同一 bug 的文本改写。

每个任务包包含：

- 不可变初始源码、公开说明和公开基础测试；
- 独立维护的隐藏正确性 oracle；
- 性能任务的固定 workload、约束和测量脚本；
- 不向 Agent 暴露的失败类型；
- 可恢复的基线 design-id；
- 至少一个正向控制和一个负向控制。

历史修复补丁不能原样成为隐藏任务。若从历史案例派生，应更换信号位置、参数或场景，并由独立评审确认仍代表同一故障家族。

## 5. 重复、随机化与规模

### 5.1 最小可行实验

- 8 个任务，每类 1 个；
- B0—B3 四个条件；
- 每个 task-condition 运行 5 次；
- 总计 160 次运行。

该阶段只验证基础设施、指标和故障注入是否有效，不承担普遍因果结论。

### 5.2 确认实验

- 16 个任务，每类 2 个；
- B0—B3 四个条件；
- 每个 task-condition 运行 8 个预注册 replicate；
- 总计 512 次核心运行。

若模型支持固定种子，同一 task-id / replicate-id 在四个条件中使用配对种子；否则使用隔离的新会话，并记录无法固定种子的限制。任务顺序按 task-id 分块随机化，条件标签仅由调度器掌握，不允许结果驱动的提前停止。

## 6. 隐藏评审

### 6.1 可执行 oracle

主要裁决来自：

1. 私有 testbench、断言、参考模型或差分测试；
2. 指定故障的触发、传播和观测检查；
3. design-id、配置、commit、证据时间和原始哈希一致性；
4. publication 完整性与原子性；
5. 非等价 mutation 杀伤矩阵；
6. 性能任务的功能前置门和 matched-configuration 指标；
7. 回滚后源码身份和回归恢复。

隐藏 oracle 在实验前冻结版本与 SHA，实验结束后公开。

### 6.2 盲化语义评审

完成声明是否越界等不可完全自动判定的问题，由独立评审者检查。评审者只看到匿名 run-id、候选补丁、原始证据和 Agent 声明，不看到 B0—B3 标签或论文预期方向。

人工或第二模型评审不能覆盖可执行 oracle 的失败。二者冲突时，以硬件执行证据为主，并单独记录冲突。

## 7. 指标

设：

- \(C=1\)：Agent 声明完成；
- \(Y=1\)：隐藏评审的全部强制门通过；
- \(P=1\)：工作流发布 complete。

### 7.1 主要质量指标

假完成率：

\[
FCR=\frac{\sum I(C=1,Y=0)}{\sum I(C=1)}
\]

若某条件没有完成声明，报告分母为 0，不把 FCR 记为 0。

验证成功率：

\[
VSR=\frac{\sum I(Y=1)}{N}
\]

不安全发布率：

\[
UPR=\frac{\sum I(P=1,Y=0)}{\sum I(P=1)}
\]

同时报告：

- 回归逃逸率；
- stale/cross-design/config evidence 逃逸率；
- 正确候选被错误失败关闭的比例；
- 完成声明与实际证据范围一致的主张校准率。

### 7.2 mutation 指标

\[
MS=\frac{\text{被杀死的非等价 mutant}}
         {\text{经独立确认的非等价 mutant}}
\]

每个 mutant 还必须记录：

- base SHA 与 mutant SHA；
- 语义锚点与故障类别；
- 触发输入；
- 错误传播点和观测点；
- 正确设计的正向结果；
- mutant 的负向结果；
- 等价性裁决。

编译成功不能使 mutant 进入分母。未改变源码、未触发、未传播、同值连接或疑似等价的变体均不计为杀伤成功。

### 7.3 搜索安全与成本

- 首次发现坏候选所需时间；
- 从失败到拒绝或回滚所需时间；
- 回滚后恢复原 design-id 且重过门禁的比例；
- 每个验证成功所需 Token、墙钟、工具调用和候选数；
- 在同 workload、同工具和同约束下的性能变化。

质量与成本分开报告；高成功率不自动等于高效率。

## 8. 消融

B2 消融：

- `B2 - bounded recall`
- `B2 - task contract`
- `B2 - explicit success criteria`

B3 消融：

- `B3 - design-id`
- `B3 - freshness`
- `B3 - configuration binding`
- `B3 - atomic publication`
- `B3 - mutation gate`
- `B3 - fail-closed`
- `B3 - rollback`
- `B3 - layered verification`

design-id、freshness、配置和原子发布主要在 D/E/F 类任务中检验；mutation 主要在 G/H 中检验；反馈、分层验证与 rollback 主要在 B/C/H 中检验。

## 9. 故障注入矩阵

### 9.1 身份与发布

至少注入：

1. 正确 design-id、配置和完整新证据；
2. 旧 design-id + 新日志；
3. 新 design-id + 旧日志；
4. 正确 design-id + 错误配置；
5. 正确配置 + 另一候选日志；
6. 缺 mandatory raw log；
7. result 更新、manifest 未更新；
8. manifest 更新、result 未更新；
9. staging 过程中终止；
10. 两个发布者并发竞争；
11. 只有 runner-owned 临时路径变化；
12. 语义变化但路径与文件名不变。

成功定义为：全部合法正向控制被接受，全部预注册错误注入被拒绝。结论只限定到该矩阵。

### 9.2 RTL mutation

覆盖：

- 条件反转；
- owner 错接；
- 事件丢失或重复；
- 位宽/符号扩展错误；
- 旧值保持；
- 同值连接；
- FENCE、STORE/AMO 顺序错误；
- selective/full flush 混淆。

每个变体必须同时证明“实际改变”“被触发”“能传播”“被目标 oracle 唯一拒绝”。

## 10. 统计方法

1. 二元结果使用 condition 为固定效应、task-id 和 fault-family 为随机效应的混合 logistic 模型。
2. 同一 task-id / replicate-id 同时报告配对风险差和精确置换检验。
3. Token 与工具调用等计数用负二项模型；墙钟可用对数模型或稳健分位数。
4. time-to-verified-success 使用生存分析，预算耗尽视为右删失。
5. 置信区间按 task-id 聚类 bootstrap，报告 95% CI。
6. 多个主比较用 Holm 方法控制家族错误率。
7. 同时报告绝对风险差和相对风险，不只给 p 值。
8. 性能指标只在配置完全匹配时配对。
9. 未完成、崩溃或证据缺失按预注册 intention-to-treat 规则计入。
10. 不按结果剔除任务、扩大预算或停止实验；所有负结果保留。

## 11. 结论门槛

### RQ1

只有同时满足以下条件，才能在本任务集内写“可执行约束降低假完成风险”：

1. B2 相对 B1 的 FCR 绝对风险差为负且 95% CI 不跨 0；
2. VSR 不低于预注册非劣界；
3. 合同或 bounded-recall 消融使效果减弱；
4. 结果不是单一任务或 fault family 驱动。

B0 vs B3 只能说明工作流包差异。

### RQ2

最低门槛：

1. 正向控制全部接受；
2. 预注册 stale、cross-design、cross-config 和 incomplete evidence 全部拒绝；
3. 发布中断时旧完整版本继续可见，部分新版本不可见为 complete；
4. 移除对应机制后至少一个目标故障发生逃逸。

### RQ3

最低门槛：

1. 每个分母 mutant 有不同 SHA 和独立非等价依据；
2. 正确设计通过，目标 mutant 在预期 oracle 失败；
3. B3 相对 `- mutation gate` 降低隐藏回归逃逸；
4. 结论限定到已测故障类别。

### RQ4

最低门槛：

1. 坏候选不发布为 complete；
2. 失败能落到具体门禁和原始日志；
3. 回滚恢复预期 design-id 并重过门禁；
4. 移除分层验证或 rollback 后回归逃逸增加；
5. 性能改进只在功能门全绿和配置可比时成立。

若置信区间跨 0、预算或模型不一致、隐藏测试泄漏、mutation 等价性不明、身份无法复核或性能配置不一致，结论必须降级为 `PARTIALLY_SUPPORTED`、`OBSERVATIONAL_ONLY` 或 `MISSING`。

## 12. 每次运行必须保存

- study-id、condition、task-id、fault-family、replicate-id；
- 模型精确快照、推理参数和随机种子；
- initial commit、initial/final design-id、配置身份；
- context package 与 task contract 哈希；
- 工具链和容器版本；
- 每条命令、mode、purpose、返回码和起止时间；
- Token、墙钟与工具调用；
- 每个验证层结果；
- base/mutant SHA 和 kill matrix；
- 候选拒绝、回滚和恢复身份；
- publication staging、完整性校验和最终状态；
- 原始日志路径与 SHA；
- Agent 完成声明；
- 隐藏评价器结果与版本。

所有论文数字都必须经 `claim-evidence-map.tsv` 回到这些材料。
