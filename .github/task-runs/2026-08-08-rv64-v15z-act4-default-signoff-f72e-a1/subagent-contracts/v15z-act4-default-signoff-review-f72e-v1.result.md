# V15Z ACT4 默认签核独立审查结果（v1）

- RTL / 本地证据对象：f72e 当前生产 RTL、冻结的 L1 `NpcSimTop`、`sail-RVA22S64` ACT4 清单与现有分层签核入口。
- 周期 / 编译配置：ACT4 选择 `rv64i/I=51`、`rv64i/M=13`、`priv/Sv=33`，合计 97 项；冻结仿真器 SHA-256 为 `8e426a6863652fd42f195d000e56e4626e918a9abac4ae7c30cde9549308fd2e`，构建日志包含 `--assert`、`+define+OOO_ASSERT`、`+define+OOO_TERMINAL_HOLDER_ASSERT` 与 `+define+OOO_CSR_QUEUE_HEAD=1`。
- testbench / EDA 观测：静态清单聚合 SHA-256 分别为 I `4f5701e53874779ac2ac94a5f08458670f667af0fce0c4089aa708bc1f99b085`、M `d4767f51b3fc36c4a18737cb58c459a97e6bbc6e6603e79eb901ff17f1ab24c5`、Sv `ffb6d90e471ead8df568c359d642e873d32c6e7d5f0cd807fc3d2d087bba7e94`、全集 `1c776930e1c329f95208ed32680143796bd826323e710fc8b7cf8bceac4fe900`。
- PASS / GAP 范围：现有默认签核未执行或合取 ACT4，因此结论为 `GAP`。ACT4 应作为 L1 的必选架构认证子队列，而不是新增 L4；它不能替代 L0 合同、L2 mini-system、L3 轻量 Linux 或 PPA 门禁。
- 必需反例：缺失、替换、额外或重复 ELF；过滤、限量或跳过；零次或两次 `TOHOST PASS`；`TOHOST FAIL`、`BAD TRAP`、断言、超时或非零返回码；多个 tohost 符号；断言未启用；错误仿真器；前后输入漂移；以及用旧 receipt 绕过新增 ACT4 合取。
- 未知项：本次审查未运行仿真；v1 合同未列入 `am-kernels/arch-test/scripts/act4-arch-run.sh`，最终 v2 审查应覆盖该入口、新增 runner/checker/schema/policy、实际 task-run 与 canonical receipt。
