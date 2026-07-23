# V9N RTL/验证推导

## 阶段 1：需求

- 观察 plain STORE 的 SQ entry 与 AMO singleton 两类 stateful holder。
- 捕获 request fire 后的 edge-old owner identity；若本拍无 exact terminal，下一拍
  必须仍驻留。
- checker 必须独立于 DUT 清除条件，不能重述 `survive_r`、`release_ready_o` 或
  `mem_rsp_final_fire_w` 的实现结果作为唯一真理。
- 当前优先使用验证 wrapper，不修改生产 datapath/FSM；若只读审查发现真实功能路径
  允许 holder 提前清除，再升级为生产 RTL 架构修正。

## 阶段 2a：协议

- SQ request fire：`req_fire_i && req_valid_o`；terminal acceptance：目标 entry 的
  `terminal_hit_w || terminal1_hit_w`。
- AMO write fire：`push_amo_write_w`；terminal acceptance：
  `mem_rsp_final_fire_w && mem_owner_open_w` 且对应 AMO owner exact。
- checker 在时钟沿保存“下一拍必须驻留”的期待与 full identity，下一沿先比较当前
  Q，再更新新期待。

## 阶段 2b：状态机

```text
IDLE -- physical request fire --> EXPECT_RESIDENT
EXPECT_RESIDENT -- no exact terminal --> EXPECT_RESIDENT
EXPECT_RESIDENT -- exact terminal --> IDLE
EXPECT_RESIDENT -- holder missing/identity drift --> CHECK_FAIL
```

hard reset 回到 IDLE。flush 不单独产生状态转移。

## 阶段 2c：不变量

- V9N-I1：STORE `request_sent && !terminal && !terminal_accept` 蕴含下一拍相同 SQ
  entry 仍 `valid && request_sent`。
- V9N-I2：V9N-I1 驻留期间 `ProducerId/token/epoch/ROB index` 逐位不变。
- V9N-I3：AMO `write_sent && pending && !final_response_fire` 蕴含下一拍 singleton
  仍 `pending && amo && write_sent`。
- V9N-I4：V9N-I3 驻留期间 `ProducerId/token/epoch/ROB index` 逐位不变。
- V9N-I5：每条 checker 有唯一 compile-success RTL variant 使其失败；baseline 必须
  实际达到前件并输出非真空 marker。

## 阶段 2d/2e：观测拓扑

- verification wrapper 作为顶层，实例化现有 module TB；通过只读 XMR 观察其 `dut`
  的 Q、terminal fire 与 identity，不驱动 DUT。
- 每类 holder 使用一组 shadow valid + identity register；无新组合反馈、无生产关键路径、
  无综合面积变化。
- 资源：两个独立 checker，不共享状态；均为 testbench-only `.sv`。
- 优先级：checker shadow `reset > compare/update`；DUT 自身优先级不由 wrapper 改写。

## 阶段 3：独立复核结论与实施

独立 reviewer 判定为 `GAP`：现有 V9L STORE/AMO 断言都以前一沿仍存在的 holder
作为前件，NBA 同沿清除后下一拍 guard 会一起消失。当前实现因此新增两个只读 XMR
wrapper；负向源码变体分别在 STORE request fire 同沿清 `owner_valid_q`、AMO write fire
同沿清 `mem_amo_q`。两者保留旧断言前件所需的其它状态，使旧同沿断言保持安静，
而新增 checker 在下一沿首先报告 exact owner tuple 丢失。

reviewer 另指出 `OooIntBackend.flush_i` 可无条件清 singleton。生产装配回查确认 canonical
`NpcCoreTop` 唯一 RTL 实例把 `OooCoreTopGlue.flush_i` 静态接 `1'b0`；V9N evidence builder
对该具体顶层连接 fail-closed 绑定。模块级测试仍可驱动 leaf flush，但不能外推为生产
顶层已发 AMO 的可达清除路径。
