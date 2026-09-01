# 文档生命周期原则

本文件适用于工程规范、README、设计笔记、计划、报告与 memory。目标是让用户能找到当前真源并看懂
适用范围，不建立一套独立于工程目标的文档状态机或归档审计。

## Work from the document's purpose

常见文档类型只是维护提示：

| 类型 | 维护重点 |
| --- | --- |
| normative/spec | 与当前接口、架构和实现语义一致，明确版本/适用配置 |
| README/index | 给出可靠入口、所有权与当前链接 |
| plan | 区分已完成、仍有效和已放弃步骤 |
| snapshot/report | 写明采样时间、design/config/tool/corner/workload，不冒充 current 真源 |
| memory | 只保存稳定、跨会话复用的事实，遵循 memory-protocol |
| task-run | 仅在显式持久化场景保存单次结果与 evidence 指针 |

新文档只在它能减少真实使用者的不确定性时创建。已有合适真源时优先就地更新或增加短链接，不为了类型
齐全复制同一事实到多份文件。

## Source of truth and references

- 代码、生成配置、schema、filelist 和可执行测试是行为真源；文档不得与它们制造另一个 current 状态。
- 全局入口负责导航和稳定原则，模块 spec 负责详细接口/状态；允许使用清楚、稳定的链接，不要求把所有
  细节内联复制到常驻文档。
- 引用短期 report/task-run 时写明它是历史 evidence，不把它当作永远 current 的唯一依据。
- 生成物应指向 generator/source；除非任务明确修复生成链或做受控临时诊断，不长期手改可再生输出。
- 一个事实有 canonical owner 后，其它文档只给范围说明和链接，避免多份状态同步仪式。

## Update only what the engineering change invalidates

修改代码、接口、配置或入口时，检查直接受影响的 spec/README/示例。只有读者会因旧描述作出错误操作或
结论时才同步文档；不要因为修改文件数量或路径自动扫描全部 Markdown、刷新所有索引或创建 audit run。

跨模块变更先确认调用链和数据流，再更新 canonical contract 与必要 consumer 文档。纯措辞、格式或链接
修复不要求重新运行不相关的 RTL、系统或 PPA profile。

## Stale, superseded, and historical material

- 当前文档描述错误：就地修正并保留有价值的设计理由。
- 计划已完成/放弃：在仍会被发现的位置明确状态；只有归档能显著减少混淆时才移动到 `history/`。
- 模块删除或入口重命名：更新直接索引和 inbound links，必要时保留短迁移说明。
- snapshot 被替代：标注历史采样点并让 current 导航指向新结果；不要求删除全部旧 evidence。
- 内容重复：选择一个 canonical owner，逐步收敛重复文本；不为一次普通编辑发起全库文档普查。

移动、删除或批量归档前核对准确目标、引用方和用户未提交修改。大范围、难恢复清理需要明确授权；优先
使用可恢复操作。

## Validation

根据改动选择最小检查：

- Markdown/链接/索引修改：查看相关链接与目标文件是否存在；
- 命令示例：只在命令行为是 acceptance criterion 时运行对应 dry-run/target；
- schema/generated docs：修改 generator 时运行直接生成/解析测试；
- 架构或系统结论：由实际 RTL/TB/DiffTest/仿真/综合/STA/PPA evidence 判断，文档 lint 不替代它们。

版本控制内未修改且有自身测试的 link checker、generator 或 doc verifier 默认可信。没有真实异常时不先
运行其自测、全量文档覆盖审计或 snapshot/manifest rebuild。

## Persistence and reporting

普通文档修改不创建 task-run，也不强制更新 memory。正式 release/migration/publication、跨会话文档
重组或用户明确要求时，可保存受影响路径、迁移映射和验证结果；hash 只在 byte identity 是验收条件时用。

最终报告说明 canonical 文档发生了什么语义变化、哪些链接/示例被更新、做了什么直接验证及剩余历史
例外。不要用归档数量、扫描覆盖率、marker/hash 或 verifier 层数代替文档是否准确可用。
