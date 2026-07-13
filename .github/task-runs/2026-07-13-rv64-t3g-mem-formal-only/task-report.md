# T3G MEM formal-only 任务报告

- task_id: `2026-07-13-rv64-t3g-mem-formal-only`
- status: `accepted architecture cut; parent timing goal active`
- baseline: `c4a97fbda`
- goal: 将整数 MEM completion 从 same-cycle fast consumer 域移到 formal WB + N+1 sticky 域。
- parent-goal status: active；fresh WNS `-12.979 ns`，尚未达到 200 MHz。

## 实现者交付

- `OooIntBackend` 的 fast-WB 两 lane 收紧为 raw EX 的精确投影；full WB 的
  `EX > MEM > MulDiv > CLMUL > FPWB` owner、ROB/BusyTable/IQ sticky/PRF write 与
  response ready 均未改。
- 普通/MMIO load、LR/AMO 与成功 SC 的总线响应只 formal WB；failed SC 与
  SQ-forwarded integer load 仍是本地 EX fast；FP load 仍走 `fpld_wb`。
- `[INT-FAST-WB-EX-ONLY]` 对 valid/tag/data 逐 lane 等价比较，避免 subset 断言允许
  MEM 冒充 fast 或漏播合法 EX。

## RED / GREEN / 负变异

- RED：旧 RTL 在首个整数 load response 的 N 拍观察到 formal0 与 MEM fast0，同时
  dependent issue；精确失败位于
  `evidence/red/focused/logs/tb_ooo_int_backend.log`。
- GREEN：同一场景 N 拍 `formal0=1, fast={0,0}, issue={0,0}`，N+1 dependent issue
  读取 `0x12345678`；mixed EX+MEM 场景保持 EX fast0、MEM formal1、fast1=0。
  证据为 `evidence/green/focused/logs/tb_ooo_int_backend.log`。
- negative：在自然 no-EX + MEM formal-WB0 下只强制 fast payload 冒充 MEM，日志恰有
  一个 `ERROR:` 且只命中 `[INT-FAST-WB-EX-ONLY] lane0`；见
  `evidence/negative/logs/tb_ooo_int_backend.log`。

## 功能与性能门禁

- focused PASS；module testbench `94/94` PASS；lint、style、contract `83 >= 59` PASS。
- 全量 Verilator 首次被系统 `5.020` 对既有 `PROCASSINIT` pragma 拒绝；使用项目
  OSS-CAD `5.051` 原命令重跑 PASS。首次环境失败和成功重试均留证，未把环境失败当绿。
- unified core regression：module/lint/build/AM PASS，官方 ISA + privileged `177/177`
  PASS，`overall_rc=0`；证据目录
  `evidence/core-regress/20260713-122959-2093816/`。
- CoreMark 10 iter：GOOD TRAP、CRC `0xfcaf`，`3,020,147 cycles`、`3,218,532 commits`、
  CPI `0.938`、`3.379/MHz`。相对 T3F `+82,238 cycles`（`+2.80%`）与 `+0.025 CPI`；
  这是整数 load-use N+1 合同的预期代价。运行后用户 runtime log 已恢复并复核 SHA-256
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`。

## Fresh 200 MHz 综合 / STA

- Yosys：两次 ABC pass 均 `110 candidates - 5 empty = 105 effective`，故按统一口径
  `105/105`；三次 check 与 `synth_check.txt` 均为 0，唯一正常 `End of script`。
- runtime `1403.92 s`，peak `3643.16 MB`；网表 `68,328,773 bytes`，SHA-256
  `95bac1a0e1ecc0fe3154d1461997098caf0f8182760fb9b111aacd95f79ef7b4`，
  `110 module / 110 endmodule`。
- stdcell diagnostic area `1,573,356.12`，sequential `428,920.80 (27.26%)`；相对
  T3F 面积 `+570.08`（`+0.03625%`），增量全为 combinational。
- 独立 OpenSTA 5 ns：`loops=0`、WNS `-12.979 ns`、TNS `-287092.31 ns`、估算功耗
  `0.120 W`。相对 T3F WNS 退化 `0.141 ns`、TNS 退化 `2540.34 ns`，因此没有达到
  200 MHz。
- top40 全由 DCache SRAM 启动。top1 arrival `16.137 ns` 到 FetchPacketCache payload
  SRAM `en_i`，但逻辑链已换成
  `DCache -> fpld_wb_valid/fp_wake1 -> IntIQ resident FP-store same-cycle ready
  -> integer PRF/ALU -> ROB/control -> fetch en_i`。
- 定向非空集合：DCache 113 startpoints；int ex0/ex1 各 145 endpoints、FP exec1 82、
  FpIQ Q 628、payload en 1。DCache→ex0/ex1 为 `-4.900/-7.150 ns`，DCache→FP exec1
  `-8.149 ns`，FpIQ Q→FP exec1 `-3.484 ns`，DCache→payload en `-12.979 ns`。

## 审查者裁决

- 功能合同、负变异和 full/fast ownership 均成立，T3G 可保留；没有用 false-path、
  multicycle 或宏 setup 豁免伪造收敛。
- 关键反例是“DCache→整数 stage 仍非空”：它不是整数 MEM fast 回归，而是未在 T3G
  范围内切断的 FP-load→FP-store 快唤醒。若只把 FpIQ 改 sticky，top1 仍会存在。
- 下一轮 T3H 必须把 FpIQ resident FPR consumer 和 IntIQ resident FP-store consumer
  同时改为 sticky-only，并据此重审 FpPhysRegFile store 读口旁路；之后仍需 fresh STA
  判断纯 FpIQ→FpConvert（当前 `-3.484 ns`）是否要求 elastic issue stage。

## 留档

- fresh synthesis 的 7 个承重文件已归档为
  `tmp/2026-07-13-rv64-t3g-mem-formal-only/NpcTop-200MHz-t3g-mem-formal-only.tar.zst`，
  `22,266,841 bytes`，SHA-256
  `904510750be957cb9641c77f9aec13e362baf63370699bae68f4e61f86f294ab`；
  zstd、tar 与 SHA 校验 PASS。
- `/tmp` 中 7 个 T3G 顶层相关路径、225 个 tar inventory 条目已归档为
  `tmp-archive/t3g-related-tmp.tar.zst`，`27,019,588 bytes`，SHA-256
  `bf93d515a8293378b1e20fddcfd913c1ca3ea5518dda5ff623bde3f9b66a112f`；
  zstd、tar 与 SHA 校验 PASS。
