# T4T D-cache tag-mask timing boundary

## Red evidence

T4S 的冻结网表和 exact 5.000ns 证据均有效，但目标未闭合：

- WNS `-1.731339097ns`
- TNS `-1813.349243164ns`
- top40 `40/40` violated
- 全部最差路径经过 `serial_flush -> cpu_kill -> dcache_read_fill_valid -> fill_we -> valid_q[*]`

OpenSTA 的 net audit 进一步证明 `fill_we_w` 的 0.502324879pF 负载中，
0.500pF 来自 49 个 SRAM tag `wmask` pin 与 1 个 tag `wdata` pin。
最小驱动反相器因此产生 8.170ns slew 和 4.327ns 单级延迟。

## Root fix

RMW hit 的定义已经证明 SRAM 旧 tag 等于 commit 拍锁存的
`rmw_tag_q`。所以 RMW 对 tag 从“mask=0 保持”改为“mask=1 幂等写回
`rmw_tag_q`”，功能完全等价：

- fill 仍写完整 tag/data；
- RMW hit 写回相同 tag，只按 byte mask 更新 data；
- RMW miss 时 SRAM `we=0`，tag payload/mask 无效；
- DMA 与 fill/RMW 合法重叠仍由 valid 最高优先级隐藏；
- fill/lookup/RMW 的非法 1RW 重叠合同不变。

该变换把 tag `wmask[112:64]` 变成常量 1，并避免 PMEM 固定位把
`wdata[80]` 化简成 `fill_we` 直连；不增加拍数、不改变接口。

## Acceptance

1. direct D-cache 与 memory bridge 测试通过，包括 inactive live
   `fill_addr=ALIAS0` 的 RMW tag-owner 反例和同-index tag replacement。
2. fresh synthesis 的 netlist audit 必须证明 tag mask 全为 tie-high，且
   不再存在 `fill_we_w` 对 SRAM wmask/wdata 的旧式直连。该变换允许综合器
   消除内部 `fill_we_w` 网名；物理负载审计因此从稳定的 bridge→D-cache
   `fill_valid_i` 接口反向解析真实 producer pin，而不依赖内部临时网名。
3. fill-control producer 的 original-Liberty rise/fall 报告必须同时满足
   总负载 `<0.05pF`、最坏 slew `<=0.795659ns`，并校验 report-net 与路径
   fanout/cap 一致；报告及 checker 输出进入 pre/post 输入冻结。
4. exact 5.000ns 全局 STA 必须 WNS >= 0、TNS = 0，并通过冻结、绑定、
   setup-member、hardening 与最终 attestation 检查。
