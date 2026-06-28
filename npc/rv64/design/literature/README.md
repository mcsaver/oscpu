# 文献与参考（design/literature/）

本目录管理 RV64 OoO 核设计所参考的体系结构资料与读书笔记，供 spec/实现引用。

约定：
- 每篇资料一个 `NN-<主题>.md` 笔记：要点摘要 + 对本核的可借鉴结论 + 出处链接。
- 不在仓库存放受版权保护的 PDF 全文；只存自写摘要与链接。大文件如需本地存放则 gitignore 并在此说明。
- 实现/规范中引用文献时用 `[[NN-主题]]` 或相对链接，保持可追溯。

计划纳入主题（按 backlog 需要逐步补）：
- LSQ / store buffer / store-to-load forwarding（B1 访存解耦）
- 精确异常下的乱序访存排序（memory disambiguation）
- 分支预测恢复与 checkpoint/rename 回滚（B6）
- SRT 高基数除法（DIV radix-4/8 已部分实现）
