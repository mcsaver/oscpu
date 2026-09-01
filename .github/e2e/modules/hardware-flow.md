# hardware-flow E2E Contract

本 profile 只验证 hardware-flow 编排入口本身，不自动运行 discovery、memory、静态图或整个硬件栈。
实际任务应从用户目标和 acceptance criteria 选择直接相关的模块/profile；只有 claim 跨越
AM → reference/target → DiffTest/SoC/STA 时才组合相应节点。

工程结论来自真实 build/test/simulation/DiffTest/EDA 输出。DiffTest 必须保证两侧 ISA、镜像、配置和
观察边界可比；综合、STA、PPA 必须保持设计与工具输入身份一致。profile/manifest/task-run 只在显式
E2E、持久化或发布边界使用，不是开始安全本地工作的授权凭证。
