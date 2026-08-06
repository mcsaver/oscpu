# V14P owner timing closing review input

- production RTL、`NpcSimTop.sv` 与 production filelist 未修改；诊断扩展通过第二 Makefile
  append bind probe 与独立 C++ DPI collector；`CONFIG_NPC_OOO_STATS=y` 是显式 fail-fast 前置条件。
- 快速证据：合同 JSON PASS；C++17 `-Wall -Wextra -Werror` PASS；9 个用例覆盖完整 store、
  左右删失、owner ABA、station flush cancel、active drop cancel、非法 S13、双桥 overlap、同拍零周期
  ROI、A/D update；SystemVerilog lint PASS；production observation input pre/post SHA 一致。
- 早期 40-bit ABI 曾完整链接 PASS，但终审前发现它混合 normal response 与 drop；当前 ABI 已拆成
  bit38 `station_cancel`、bit39 `active_drop`、bit40 `response_fire`，并把 `S_SQ_QUERY` 从
  translation 独立。当前 ABI 的最终完整链接尚待本次审查后的 link tier。
- C gate pointers：instrumentation 变化默认 fast；层次/sample/DPI/config 变化显式 link；link
  替代 fast；review/analysis 零 gate；40% 仅为非阻断复盘目标。
- 当前授权边界固定为 `optimization_candidate_authorized=false`、`ppa=UNQUALIFIED`、
  `promotion_eligible=false`；本轮不运行 workload、不修改 B response 唯一 write terminal、不削弱
  任何 RTL assertion。
