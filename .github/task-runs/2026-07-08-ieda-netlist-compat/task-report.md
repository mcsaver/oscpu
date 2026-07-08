# 2026-07-08-ieda-netlist-compat

## 目标

继续推进四黑盒 `NpcTop` synthesis 到 iEDA STA smoke 的前置链路。范围限定在综合/STA 准备，
不启动 Ubuntu/rootfs，不宣称完整 timing/area closure。

## 根因

旧四黑盒 `NpcTop.netlist.v` 不能进入 iEDA：

- 第一处 RED：Yosys mapped netlist 保留 `$print` cell 和 `defparam`，iEDA Verilog parser 在
  `$print` 后的 `defparam _69549_.ARGS_WIDTH = 32'b...` 处 abort。
- 第二处 RED：去掉 `defparam` 后，iEDA 继续在 `OooFetchPacketCache #(...) u_fetch_packet_cache`
  这种 parameterized blackbox instance 处 abort。

这些都是 Yosys->iEDA 网表方言问题，还没走到真实 macro timing/area 假设。

## 变更

- `yosys-sta/scripts/yosys.tcl` 在写 mapped netlist 前删除 `$print/$assert/$assume/$cover/$check`
  等仿真/形式 side-effect cell，并去掉 `write_verilog -defparam`。
- 新增 `yosys-sta/scripts/check_ieda_netlist_compat.py`，禁止 iEDA 已知不兼容的
  side-effect cell、`defparam` 和 parameterized instance。
- `OooFetchPacketCache` 默认 `INDEX_W` 改为 `OOO_FETCH_PACKET_CACHE_INDEX_W`，实例端不再参数化。
- 新增 `OOO_DATA_WORD_CACHE_INDEX_W`，`OooDataWordCache` 默认 `INDEX_W` 改为该宏，实例端不再参数化。
- 更新 `yosys-macro-boundary-contracts.md`、`.github/e2e/modules/yosys-sta.md` 与相关 spec 容量宏口径。

## 验证

- RED old netlist preflight：`defparam=44`、`$print=7`。
- 四黑盒 `NpcTop` synthesis after side-effect cleanup PASS：`1021.44s`，但仍有 cache `defparam`。
- 四黑盒 `NpcTop` synthesis after no-`defparam` PASS：`1014.06s`，但 iEDA 仍卡 parameterized cache instance。
- Cache focused TB after non-parameterized instances PASS：`tb_ooo_fetch_packet_cache`、`tb_ooo_data_word_cache`。
- 四黑盒 `NpcTop` synthesis after no-parameterized cache instance PASS：`1020.82s`。
- `check_ieda_netlist_compat.py` PASS：forbidden=0。
- `check_macro_contracts.py` PASS：四个 blackbox instance 仍存在。
- Fetch/D-cache/BPU/FP macro placeholder/decision checkers PASS。
- `check-rtl-style` PASS，`check-contract` PASS，`make -C npc/rv64 lint` PASS。

## STA Smoke

- 旧 netlist：iEDA 在 Verilog parser 阶段 abort。
- 新 netlist：iEDA 可越过 parser，进入 timing analysis 与 data backward propagation。
- `600s` 与 `2400s` smoke 均未生成 `NpcTop.rpt`/`NpcTop.pwr`，最后停在
  `StaDataPropagation.cc` 的 data backward propagation。

## 结论

本轮关闭的是 iEDA netlist parser/front-end 兼容缺口。完整 iEDA STA smoke 仍 open；下一步应继续
拆解 iEDA data propagation 长尾，或在真实 macro assumptions/OOC timing report 明确后降低四黑盒
unknown timing/area 对 STA 图的压力。
