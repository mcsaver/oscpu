# V9A DI-2 独立终审（v3）

- 审查方式：只读；未修改工作区或生产 RTL。
- 审查合同：`subagent-contracts/v9a-di2-final-evidence-review-v3.json`
- 合同 SHA-256：`386e81af255c9277db304abaf455327dc3f3743462c8efce7123c7396940de2b`
- 总体裁决：本轮 DI-2 在合同限定范围内 `PASS/GREEN`。

| 类别 | 裁决 | 核心依据 |
| --- | --- | --- |
| boundary | PASS | 七个固定边界全部纳入观测 |
| event | PASS | 64 周期均为 128 次传输、peak=2、dual=64 |
| identity | PASS | 完整 ProducerId 生命周期连续，无残留活动项 |
| window | PASS | 固定窗口扰动在 cycle 17 被正确拒绝 |
| sink | PASS | EX→WB 已建立 N→N+1 完整 payload ledger |
| mutation | PASS | 11/11 变异均编译成功并被动态拒绝 |
| provenance | PASS | 73 项精确来源闭包，已补齐相邻回归 TB |
| drain | PASS | 请求、响应、入队均为 89，holder 清零，free=32 |
| claim | PASS | 同一 design_id 下九项架构门全部 GREEN |

## v2 阻塞项闭合

1. EX→WB 逐项核对 `ProducerId/pdest/result/exception/cause/tval/fwd` 的跨周期传递。
2. 精确 provenance 已包含相邻回归 TB 源文件，并由哈希绑定。

## 非阻塞限制

- 聚焦 ADDI 流中的异常字段多数为常量；其语义覆盖由同 provenance 的 backend fault/forward 和通用 stage payload 回归补强。
- drain 最后一拍对部分内部控制线的直接观测较窄。
- 178 条 uop 覆盖多次 ROB 环绕，但未覆盖完整 8-bit ProducerId 命名空间回卷。

## 声明边界

- PPA 状态仍为 `UNQUALIFIED`。
- `promotion_eligible=false`。
- 本裁决只关闭 V9A DI-2 架构宽度连续性缺口，不宣称形式 PPA 已完成。
- 长期 RV64 OoO 核优化目标继续保持 active。

WSL shell ownership 已释放。
