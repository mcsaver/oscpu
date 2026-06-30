# RV64 CoreMark 计时语义 — RTC/uptime 改 guest 时基 + CLINT mtime 诊断 divisor-aware

## 触发
紧接 [coremark-serial-pmem-alias] 修复(串口输出已恢复)后,默认 `make ARCH=riscv64-npc run`
(ITERATIONS=1000)在 `cycles=100000000` abort,且统计行 `CLINT mtime = … match=no`。
用户追问:为什么 RTC 里 mtime 和 cycle「时间不同步」。

## 诊断(先摸清调用链,非症状级)
两个独立事实,只有一个是真问题。先厘清三个不同的「时间」:

| 时钟 | 来源 | 值 | 谁在用 |
| --- | --- | --- | --- |
| `cycles` | 仿真时钟 posedge 计数 | 基准 | 统计 / CPI |
| CLINT `mtime` | `AxiLiteClint.v`,`NpcTop.v:159` 例化 `CLINT_MTIME_DIVISOR=10` | `cycles/10` | M-mode 定时中断;AM 当前**没读** |
| RTC(0xa0000048) | `csrc/device/timer.c rtc_read_cb`→`npc_get_time_us()`=`clock_gettime(MONOTONIC)` | **宿主墙钟 μs** | AM `AM_TIMER_UPTIME`、CoreMark 计时 |

- **`abort` 本身不是 bug**:`core-state=0x3 = NPC_ABORT` = `--max-cycles` 触顶(cap=100M 来自
  Kconfig `CONFIG_NPC_DEFAULT_MAX_CYCLES`)。1000 次迭代需 ~325M cycles(实测 1 次 370320、
  10 次 3291800,边际 ~324.6K/次),100M 只够 ~307 次。撞顶前 CPI 1.02、98M 有效提交、零 trap,核心健康。
- **事实 A `match=no`**:CLINT 故意 `DIVISOR=10` 预分频(`mtime_tick_w` 每 10 拍 +1),`mtime=cycles/10`
  乃设计;`cpu-exec.cpp` 旧诊断 naive 地 `clint_mtime==cycles` 判等 → 永远 no。**陈旧诊断,非硬件失步。**
- **事实 B(真问题)**:CoreMark 走的是 host-time RTC,量的是「宿主跑这次仿真多久」而非「核心要花多少
  guest 时间」。RTL 仿真 ~197k inst/s(比真实 GHz 核慢 ~5000×)→ 分值塌缩。原 `CoreMark PASS 1 Marks`:
  `secs_ret=ee_u32`(HAS_FLOAT=0,**整数**非 double),`2921400 / 16000(host ms) = 182`,`×10/1000 = 1`
  —— 纯整数截断 + 宿主时间过大,**不是 `%d` 打 double 的 UB**(此前误判,已纠正)。

## 修复(2 文件功能 + 1 文件诊断;core_main.c 经核查无 bug,未动)
1. `csrc/device/timer.c`:RTC/uptime 默认改用 `npc_stats()->cycles` 当时基(1 cycle ↦ 1 μs,标称 1 MHz),
   确定性、可复现,让 CoreMark 量到 guest 时间。`NPC_RTC_USE_HOST_TIME` 可回退宿主墙钟。
2. `csrc/cpu/cpu-exec.cpp`:`CLINT mtime` 统计行改成 divisor-aware——`expected=cycles/N`,容忍 ±1 拍
   采样相位,打印 `(= cycles/10, expected …, delta=…, match=…)`,变成有用的 CLINT 跳动自检。
3. `csrc/include/utils.h`:新增 `NPC_CLINT_MTIME_DIVISOR=10`(注释要求与 `NpcTop.v:159` 镜像同步)。
4. `core_main.c`:**未改**。原以为 `%d`/double UB,核查 `core_portme.h HAS_FLOAT=0`→`secs_ret=ee_u32` 整数,
   `%d` 合法;「1 Marks」是宿主时间的症状,#1 改时基后自动变 8 Marks。乱改 vendored 评分公式无益。

## 验证(ITERATIONS=10 重建 + 跑)
- 无回归:`HIT GOOD TRAP` pc=0x80001fe0、code=0、cycles=3291673、CPI 1.023、crcfinal=0xfcaf(同修前)。
- 诊断:`CLINT mtime = 329167 (= cycles/10, expected 329167, delta=+0, match=yes)`。
- 时基:`Finised in 3247 ms`(guest 确定值),`CoreMark PASS 8 Marks`(1→8,确定,反映 guest cycles/迭代)。
- difftest 安全:RTC 读落在 `paddr.c` 设备窗口的 `npc_difftest_skip_ref()` 路径,值被跳过比对;
  修前宿主时间同样与 NEMU 不符而 difftest 41/41 绿,故按构造中性。

## 残留 / 风险
- 全量 AM(57)/difftest(41)/riscv-tests 回归未在本轮重跑;提交前建议补跑(理论中性)。
- `NPC_CLINT_MTIME_DIVISOR` 与 `NpcTop.v` 是手工镜像常量,改 RTL divisor 时需同步(注释已标注)。
- 1000 次迭代要完整跑通仍需抬 cap(`--max-cycles 0`/~400M,~27 分钟);RTL 仿真惯例是用小迭代数。
- 「Marks」绝对值随标称频率/魔数标定;频率无关的真实指标是 CoreMark/MHz(≈3.08)与 CPI(1.02)。

## 追加(用户连续追问驱动,2026-06-29 续)

用户三连问,逐个闭环:

1. **「为什么 CLINT 要 ÷10」**:mtime 是固定频率实时钟非核心时钟。`Linux/tools/npc-rv64.dts:26 timebase-frequency=<10000000>`(10MHz)+ `CLINT_MTIME_DIVISOR=10`(`NpcTop.v:159`)→ 隐含核心 100MHz(F_core/10=10MHz)。消费者=`mtimecmp`→MTIP 定时中断(`NpcTop.v:270`→CsrFile `MIP_MTIP`),Linux 调度 tick 用;裸机 AM 不读。

2. **「uptime 该用核心计数器吧」**:对——我的修复正是把 RTC 从宿主墙钟改成 `npc_stats()->cycles`(核心周期)。核还暴露 `mcycle`/`minstret` CSR(`CsrFile.v:672` 逐拍++,可 `rdcycle`)和 CLINT mtime(=cycles/10)两个真硬件计时源。

3. **「100MHz 你怎么知道?」(关键纠错)**:**仓库无权威核心频率**——综合 `create_clock -period $PERIOD` 是每跑参数(`STA_CLK_FREQ_MHZ?=500` 是压力靶)、DTS `cpu@0` 无 clock-frequency、OOC 实测 Fmax~126MHz。先前"100MHz"是倒推非事实,已收回 `/100` 对齐建议。**潜在隐患**:divisor=10+DTS 10MHz 隐含 100MHz 与 Fmax~126MHz 不自洽(出片按 Fmax 则 Linux 墙钟偏 26%)→ 记入 known-issues [99] 续注。

4. **「RTC 里是真实 cycles 吗,哪来的」**:**是**。`timer.c:21 rtc_read_cb`→`npc_stats()->cycles`,唯一自增点 `cpu-exec.cpp:1994 ++npc_stats()->cycles`,在 `step_cycle()` 里每推进一个完整 RTL 时钟周期(`eval_half_cycle(0)`+`eval_half_cycle(1)`)+1,**与 CPI(`cpu-exec.cpp:1700 cycles/commits`)同一计数器**;`clint_mtime`(`cpu-exec.cpp:1996` 从 RTL `debug_clint_mtime_o` 采样)是另一字段=cycles/10。

**追加修改**:`core_main.c` 加 `CoreMark/MHz` 打印(`= 1e6×iters/timed-cycles = 1000×ITERATIONS/total_time`,定点 milli 因 klib 无 %f),频率无关的可对标真值。验证 ITERATIONS=10 重建跑:`CoreMark/MHz : 3.078`,GOOD TRAP code=0、CPI 1.024、CLINT `match=yes` 全保持。**结论**:核心侧真实周期计数(cycles)→ CPI + CoreMark/MHz 才是该对标的精确频率无关指标,绝对"Marks/秒"需假设频率不可信。
