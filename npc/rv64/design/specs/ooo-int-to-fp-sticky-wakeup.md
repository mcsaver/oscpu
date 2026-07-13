# 规范：Integer→FP GPR 依赖的 sticky 时序边界

> 模块：`OooIntBackend`、`OooFpBackend`、`OooFpIssueQueue`、`OooPhysRegFile`。
> 状态：**T3F 已实现并完成 fresh 5 ns 结构验证（2026-07-13）**。
> 目标：物理切断 integer full-WB/fast-WB 到 FP IQ select、GPR read8 和 FP convert
> 的同拍跨域组合路径，不丢单拍 wakeup，不改正式 WB/精确异常 owner。

## 1. Fresh STA 根因

T3E 已使 `check_setup` 组合环从 16 降为 0，但 fresh 5 ns top40 全部落在
同一无环长路径族：

```text
DCache SRAM/tag/hit
 -> MemBridge response
 -> integer fast wake/select/PRF/ALU/branch resolve
 -> MulDiv kill mask -> formal WB winner/tag
 -> FpIssueQueue integer resident same-cycle wake/select
 -> FP PRF / read8 -> FpConvert
 -> exec1 stage D
```

top1 arrival 约 22.23 ns，其中 formal `wb1` 约在 12.95 ns 进入 FP IQ，FP IQ
oldest-select 约在 16.73 ns 送出，再经 FP PRF/convert 到 21.33 ns。这条路传播的
不是 MulDiv data，而是 branch kill 改变 `resp_valid` 后进一步改变 WB winner/tag。

T3B 把 full-WB 与 EX/MEM fast broadcast 分开后，FP IQ 仍把 integer full wake 同时用作：

- resident entry 组合 ready/select；
- dispatch 同拍唯一 pulse 捕获；
- `gpr_ready_q` 时序 sticky 落账。

且 integer PRF `read8` 仍使用 full write-through。因此 tag 前视与 data 旁路同时
将正式 WB 组合路径接入 FP 执行域。

## 2. 冻结架构

### 2.1 Integer wake 只做 sticky

- `int_wake0/1` 仍是 integer 正式 GPR write event，每 lane 的 valid 必须为
  `wb_valid && wb_pdest != 0`，tag 与正式 WB 相同。
- FP IQ resident entry 的 GPR source 组合 ready 只读 `gpr_ready_q`，禁止直接比较
  当拍 `int_wake0/1`。
- `int_wake0/1` 仍在上升沿更新 resident `gpr_ready_q`；仍用于 dispatch0/1
  同拍 insertion lookahead，防止唯一 pulse 被后写的 not-ready 覆盖。
- FP source 的 arithmetic/load wake 不属于本刀，继续保留现有同拍 select。

### 2.2 Integer PRF read8 只读已落账状态

- `read8_data_o` 只读 `regs_q[read8_addr_i]`，preg0 仍恒 0。
- `read8` 既不消费 full write-through，也不消费 fast bypass。
- read0–3 继续消费 EX-only fast bypass（T3G 起 MEM formal-only）；正式 `write0/1` 仍是 `regs_q` 唯一
  更新真源。

IQ tag 边界和 PRF data 边界必须原子修改。只切 IQ 会留下无用的 full/fast
payload 长弧；只切 read8 会使旧 IQ 在 N 拍发射时读到尚未落账的旧值。

## 3. 六类接口合同

### 3.1 握手

- 不新增 ready/valid 通道，不改 integer WB 仲裁、response ready 或 FP issue ready。
- wake 是单拍事件，sticky ready 是唯一可发射状态；禁止引入第二份 FIFO/重放状态。

### 3.2 stall / backpressure

- producer 在 N 拍正式 WB 时，resident GPR-dependent FP uop 不因该 pulse 在 N 拍
  select；N 沿同时写 PRF 并置 sticky，N+1 发射并读到新 `regs_q`。
- EX/MEM、MulDiv/CLMUL、FPWB→GPR 统一遵循该边界；这类跨域依赖比旧 RTL
  增加 1 拍。
- dispatch 本来不能同拍 issue；dispatch 与 WB 相撞时 N 沿捕获 sticky，N+1
  正常发射，不丢唯一 pulse。

### 3.3 flush / kill / redirect

- kill/recover 拍继续压低 issue；存活前缀在 N 沿仍必须吸收 full wake，N+1
  可发射；年轻后缀照旧 squash，不得复活。
- 不注册 branch kill，不缓存 wrong-path completion，不改 ROB age 规则。

### 3.4 异常序

- full WB 仍是 ROB done/exception/fflags/data 的唯一正式 owner。
- consumer 晚一拍 select 不改 producer/consumer ROB 年龄和提交全序；异常 producer
  的年轻 consumer 仍由既有精确 flush 清除。

### 3.5 访存序

- 本刀只作用于进入 FP issue 的 GPR source，不改 integer load/store 的 MIQ/SQ/order。
- integer load→FP convert/move 变为 WB 后 N+1 发射；T3G 起整数域内 load-use 也在
  MEM formal WB 后 N+1 发射，见 `ooo-mem-formal-only.md`。

### 3.6 恢复 / 单一真源

- integer PRF `regs_q` 是 GPR payload 真源；FP IQ `gpr_ready_q` 是跨域可发射真源。
- wake 只是对这两个时序状态的同沿 event，不得直接驱动 resident select/data。

## 4. 周期模型

| 周期 | integer formal WB | resident FP IQ GPR ready | PRF read8 | 结果 |
| --- | --- | --- | --- | --- |
| N 沿前 | valid/tag/data | 仍为 sticky 旧值 | 旧 `regs_q` | 不因该 WB 发射 |
| N 上升沿 | 写 `regs_q` | full wake 置 ready | — | 同沿落账 |
| N+1 | pulse 可撤回 | ready=1 | 新 `regs_q` | 可发射，数据正确 |

## 5. RED、断言与接受门禁

- FpIQ RED：resident entry 只等 GPR preg33，N 拍只给 full wake；旧 RTL 错误
  `issue_valid=1`，新 RTL 必须 N=0、N+1=1。
- PRF RED：full-only write 的 N 拍 read8 必须保留旧值，N+1 读新值；旧 RTL
  在 write0、双写冲突、mixed lane1 三个场景稳定失败。
- `[FP-IQ-INT-STICKY-ONLY]`：任何实际 issue 的 GPR source 必须已有
  `gpr_ready_q=1`；强制 ready/select 越过 sticky 必须精准触发 marker。
- focused/module/full Verilator、ISA/privileged/FP/CoreMark 全通过；CoreMark 不含 FP，
  周期应与 T3E 一致。
- fresh OpenSTA 必须继续 `loops=0`，top40 的同一路径上游不得再出现
  `wb*`/`fast_wb*`/`int_wake*`→FP IQ/convert 跨域弧。合法的
  `gpr_ready_q/regs_q Q`→oldest-select/read8→FpConvert 本域路径可以存在，需单独
  评估是否超过 5 ns，不能只按 `read8`/`convert` 名字误判。

## 6. 已拒绝方案与非声明

- **拒绝把 EX/MEM fast-select 接入 FP 域**：它能切掉 MulDiv/full-WB 回穿，但仍留下
  DCache→fast-WB→FpIQ→FpConvert 约 12–15 ns 跨域路径，不适合 5 ns 目标。
- **拒绝 false-path/UNOPTFLAT**：该路径是功能上真实可激活的组合路，不能被约束掩盖。
- 本刀不保证 FP IQ 本域 oldest-select/FP PRF/FpConvert 自身已小于 5 ns，也不声称
  physical 200 MHz。只有 fresh WNS≥0 且全功能门禁闭合后才能完成父目标。

## 7. Fresh 验证结果

- Yosys check `0 problems`，有效 ABC mapping `105/105`；综合网表 SHA256 为
  `ed05a3609ff3c23109d3417506768511438bac00eb79f95d20e4fccc24f87654`。
- OpenSTA 保持 `loops=0`，WNS `-12.838 ns`、TNS `-284551.97 ns`；相对 T3E
  WNS 改善 `4.392 ns`。top40 不再出现 integer WB/fast-wake→FP execute 家族。
- `int_wake0/1` 的 flat fanout 各自仅终止于 FP IQ 的 11 个状态触发器 D/E，
  没有 exec-stage 端点，证明 wake 已成为 sticky state event。
- 独立审查同时发现后续真实瓶颈：FpIQ state→FpPRF→FpConvert→exec 最差
  `-3.484 ns`；DCache→FP exec 最差 `-8.058 ns`。这些属于下一阶段，不回退
  T3F 结构裁决，也证明父目标仍不能完成。
