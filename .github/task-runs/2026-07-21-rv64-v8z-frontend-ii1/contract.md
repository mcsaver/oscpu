# RV64 V8Z DI-1 Frontend II=1 合同

## 本地工程范围

工作对象是授权工作区中的 RV64 双发射 OoO Verilog/SystemVerilog 处理器前端、testbench、仿真与架构证据。操作仅覆盖本地源码、EDA 工具和生成产物；不使用工作区外来源。

## 架构目标

在 cache hit、无 redirect、下游持续 ready 的条件下，预热后连续 64 个周期：

- `OooFetchAxiBridge` 每周期接收一个 fetch packet request，并每周期交付一个命中 packet response；
- `OooFrontend` 的 request/response/outstanding/FIFO credit 闭环每周期完成一次 response enqueue 与 successor request turnover；
- 连续窗口内 accepted packets=64、produced packets=64、最大 initiation interval=1；
- 请求 PC 由当前 response owner 的 packet successor 精确推进，不产生重复、跳号、redirect 或控制流 stop；
- response backpressure 时保持 ready/valid 稳定，恢复 ready 后继续，无假 request token 或重复 response。

## 初始证据计划

1. 复用 `tb_ooo_fetch_axi_bridge` 已有 bare-mode 与 paged-context 各 64-cycle FPC/ITLB hit turnover，并把 marker、计数和失败条件纳入专用 parser。
2. 在 `tb_ooo_core_top_glue` 增加独立整数 NOP packet 的 focused 配置，穿过真实 `OooFrontend`、`OooFetchFlowControl`、`OooFetchPcOutstandingSequencer`、packet decode/FIFO、rename/dispatch/backend，要求 64 个连续 response-enqueue + successor-request fire。
3. 用 compile-success RTL source mutation 分别切断 FPC H1 turnover、semantic lookup、frontend outstanding turnover、response enqueue ready 与 replacement owner 更新；每项必须编译成功并由对应动态 oracle 拒绝。
4. evidence record 必须绑定完整 RTL design_id、assert/release 日志、source pre/post、变异清单、相关回归、精确命令与 proof provenance；只授权 DI-1，不外推 DI-2、overall architecture 或 PPA。

## 预期永久入口

`make -C npc/rv64 check-frontend-ii1`

## 当前声明边界

本文件只冻结待审查的验证合同，不声明 DI-1 已通过。当前 DI-1、DI-2 与 overall architecture 保持 RED，PPA 为 UNQUALIFIED，`promotion_eligible=false`。
