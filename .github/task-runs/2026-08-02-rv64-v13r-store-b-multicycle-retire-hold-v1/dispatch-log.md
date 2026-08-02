# V13R RTL 审查派发记录

## 周期模型预审

- 对象：本地 RV64 `OooMemAxiBridge`、`OooIntBackend` 与 store B terminal transaction。
- 输入合同：`subagent-contracts/v13r-cycle-oracle-review.json`（SHA256 `e15a371cfcd852711cd30bb840f218999917618313780b3ffaf9ef854ffa982f`）。
- 结论：原“两轮双 ALU 均填满 WB”假设存在反例；当 memory response 等待 WB 时，backend 的 anti-starvation 条件会关闭 lane1 refill。该结论随后由定向 testbench 周期观测确认，集成响应界限修正为 `C_B+1`。

## 完整证据独立复核

- 输入合同：`subagent-contracts/v13r-final-independent-review.json`（SHA256 `38960a0e49c357f80b58b13e5dab7917ecd5a48e550be562358f4e86ae785b76`）。
- 首轮结论：RTL 行为证据成立，但 source binding 未覆盖完整编译闭包，mutation 清理时序和 regression binding 引用不足；证据状态为 GAP。
- 处理：由 Makefile 目标导出实际 `TB_SRCS/TB_DEPS`，形成 61 项 source closure；focused、mutation、regression receipt 统一绑定同一 SHA256，并把 mutation 全变体旧 receipt/log 的清理移动到首个变体执行之前。

## 缺口闭合复核

- 输入合同：`subagent-contracts/v13r-binding-gap-closure-review.json`（SHA256 `9bf5e238612d80a9029f49f3ebd2a2af93100a0d770458d3d322c7067230be75`）。
- 观测：`critical-source-binding.sha256` 共 61/61 项独立校验通过；focused、mutation、regression receipt 均引用 SHA256 `75691729620e5cf093bd08accf5bd48dc59742f78dd6d75c21cdba640fe74aaa`；mutation 全量预清理顺序符合合同。
- 最终范围：`VERIFICATION_PASS_WITH_DECLARED_GAPS`。不扩展为 system/CPI/synthesis/STA/PPA 结论，也不声称无界时序性质已证明。
