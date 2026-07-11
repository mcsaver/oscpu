# Timing summary

## 当前首要路径

```text
OooStoreQueue state FF
  -> SQ snoop/order/issue-ready control
  -> integer backend glue / PRF / ALU0 / ALU1
  -> MulDiv control / issue selection
  -> OooIntIssueQueue / PRF / ALU0 / ALU1
  -> memory request / MIQ push control
  -> OooMemInflightQueue D (20.709 ns cumulative)
```

目标周期为 `5.000 ns`，setup 后 required 为 `4.971 ns`，故最差 slack 为 `-15.739 ns`；全报告 `wns max -15.74`、`tns max -196567.73`。

## RTL 锚点

- `OooIntBackend.v`：Store Queue snoop/order/forward 派生的 `issue*_sq_block`、`issue*_sq_fwd` 与 execute readiness；
- `OooIntBackend.v`：`issue*_fire`、long-op/memory can-fire、branch resolve/kill 和 MIQ push 形成同拍控制依赖；
- `OooIntIssueQueue.v`：组合 select 会把当拍 `wakeup_match(...)` OR 到 registered source-ready；
- `OooPhysRegFile.v`：组合 read 函数包含当拍 write-through；
- `OooIntBackend.v`：dispatch backend 的 IQ 输出直接进入 PRF/execute，没有 issue-to-execute 寄存边界；
- `OooIntBackend.v`：issue0 当前结果到 issue1 的 cross-lane forward 仍存在，但 IQ 注释表明其原始 dispatch-to-issue bypass 场景已删除，需用测试证明其不可达后再移除。

## 修复前结论为何过时

旧报告的 DCache 起点不是“被后续 RTL 优化自然消失”，而是映射流程语义改变后的路径重排。修复前自定义 ABC 脚本未把 `{D}` 放进优化命令；修复后 105 个 cone 才真正收到 5 ns target。因此：

- 旧 `-12.63 ns` 不能作为 200 MHz 目标驱动基线；
- “先切 memory completion -> same-cycle reissue”不是当前报告单独支持的唯一结论；
- 当前更强的证据指向后端 issue/execute/ready/kill 的整体组合闭环；
- 前端和 DCache 仍可能在切断闭环后重新成为热点，当前报告不能永久降级它们。

## T1 候选切分

推荐设计候选是在 IQ 两条 issue 输出后各放一个独立 elastic stage：IQ 的 `issue*_ready` 连接 stage 上游 ready，现有 execute readiness 连接 stage 下游 ready；stage 捕获执行所需的全部 payload，并由 flush/checkpoint restore/common kill 清除。这样 IQ 的当拍 wakeup/select 可以继续存在，但组合弧终止在 stage D，SQ/execute/branch/MIQ 的反馈不能再穿回 IQ。

与该切分配套的两个简化候选是：

1. 删除不可达的 issue0 -> issue1 当拍结果前递，消除 ALU0 -> ALU1 静态串接；
2. 若依赖测试证明 stage Q 在下一拍读取已写入 PRF 的值，则删除 PRF 当拍 write-through。

这仍是待批准、待 TDD 的设计候选，不是已实现结论。必须先验证独立 lane 反压、hold/consume/refill、flush、branch kill、WB 相邻拍依赖和双发射顺序，再修改生产 RTL。

## 下一次判定

T1 后沿用完全相同的黑盒、keep-hierarchy、ABC target 合约和 OpenSTA 5 ns 设置重映射。只有新网表与新报告能判定切分收益；若该闭环消失但新的 WNS 仍小于 0，应按新路径继续迭代，不能把“旧最差路径消失”等同于 200 MHz closure。
