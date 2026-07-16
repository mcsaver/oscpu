# T4R fresh synthesis / exact 5 ns diagnostic result

- frozen-input fresh synthesis：PASS，115 RTL、117 modules、222 ABC runs。
- netlist SHA256：`67f01b021efed7d12d515fbe3aacd03da7217db62e0652ada44e2c47e4a0ae08`。
- area：`1622397.56`；sequential：`448700.56` (`27.66%`)。
- exact 5.0 ns global diagnostic：WNS `-0.050334848 ns`、TNS
  `-0.197783574 ns`、top40 中 13 条 violation。
- T4Q 的 xbar fall-through/IFU PMP 族已全部退出 top40；T4R 不宣称 200 MHz
  达标，保留为下一轮的真实红线。

剩余族：

1. fetch packet valid 经 FP resource-credit ready 回灌，再落到 integer/FP IQ 与
   fetch-PC owner：11 条，最差 `-0.050334848 ns`。
2. serial flush 经 mem bridge fill-valid/cacheability 落到 Dcache SRAM addr：2 条，
   最差 `-0.027487790 ns`。

