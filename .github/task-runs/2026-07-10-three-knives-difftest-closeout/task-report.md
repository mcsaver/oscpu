# 任务报告：三刀（X+F+D）全状态 difftest 整体收口

按用户策略"重构整体完成后一次性 difftest"执行。CONFIG_NPC_DIFFTEST=y 重编译
（NEMU ref so 07-07 版），vs NEMU 逐指令全状态比对：

- CoreMark 10 迭代：**零 mismatch，0xfcaf GOOD TRAP，CPI 1.140**（difftest ON 拍数不变）。
- riscv-tests 177/177（含特权套件）+ AM 全套：**0 FAIL**（core-regress difftest 版）。
- 收口对象=刀X(MulDiv radix-4+CLZ+kill 函数修复)+刀F(fetch 融合拍+snoop 降级臂)
  +刀D(dcache 融合拍) 的全部重构面。
- 收口后 .config 已恢复性能配置（difftest off），刀 B2 完成后再收口。
