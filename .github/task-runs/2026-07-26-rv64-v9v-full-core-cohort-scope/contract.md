# RV64 V9V full-core capability cohort contract

## RTL 对象

- 当前本地 RV64 双发射 OoO RTL：
  `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。
- 规范 cohort：
  `full-core-single-hart-rv64-dual-issue-ooo-v1`。
- terminal 数据流：
  `OooIntBackend` 12 路 terminal ingress →
  `OooMemOwnerTerminalCollector` →
  `OooMemOwnerTracker` 双路 exact free。

## 本轮目标

1. 核验历史 rootfs 终态证据的 RTL/仿真器/配置/terminal marker 绑定，不把
   host timeout 或空 marker 外推为 RTL PASS。
2. 在当前设计重放 12-lane collector exact capture/drain，以及 bank0/bank1
   SQ-query retry-holder 的 C0 屏障交接。
3. 为单 hart A-extension、WFI immediate-resume、global
   SFENCE/Svinval 和无 architectural Debug/trigger 建立
   design/cohort-bound 规范合同。
4. 保持 `SERIALIZE-G1=OPEN`、完整 producer-holder census 与 freeze-input
   inventory 为 GAP；不得由局部闭合生成 PPA 或 promotion 结论。

## 不变量

- 不以 terminal event 去重掩盖同 token 双 ingress。
- 不关闭、降级或放宽 `OOO_ASSERT` / `OOO_TERMINAL_HOLDER_ASSERT`。
- 不把 simulation observability、semihost EBREAK 或 rootfs 有界未复现解释为
  architectural Debug 或系统完成。
- 本轮仅在发现当前生产 RTL 根因时修改 `.v`；若定向重放通过，则保持现有
  producer-side C0 修复，不改 collector 功能方程。

## 成功条件

- 当前 design-id 在验证前后相同。
- 8 个定向 module testbench 全部 PASS，包含 collector 12/12 exact drain 和
  两个 bank 的 retry-holder C0 交接。
- 四份 exclusion JSON 的 cohort/design/rationale/hash 由
  `arch_stable_freeze.py` fail-closed 校验为 PASS，candidate 与 ledger 排除集
  完全对称。
- 15 个 CLOSED debt 的 current-design binding 保持 PASS；
  `SERIALIZE-G1.resolved=GAP`。
- 最终边界仍为 `architecture_freeze=GAP`、`PPA=UNQUALIFIED`、
  `promotion_eligible=false`。
