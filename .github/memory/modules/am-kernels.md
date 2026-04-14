# AM-Kernels 模块笔记

## 测试通过情况
<!-- 各测试集的通过状态 -->
- [2026-04-13] 本地统一回归入口已落到 `scripts/am-regression.sh`：默认跑 `alu/cpu/klib/am(h/a)/devscan smoke + benchmark`，日志目录固定为 `am-kernels/build/regression/<时间戳>/`，`latest` 总是指向最新一轮结果。
- [2026-04-13] `scripts/am-regression.sh --watch` 已验证可用；监控目录发生源码修改后，会自动启动新一轮回归，适合做 `abstract-machine` / `nemu` / `am-kernels` 小步修改后的本地守护回归。
- [2026-04-13] `ARCH=riscv32-nemu` 回归通过：`alu-tests`、`cpu-tests` 35 项、`klib-tests` 4 项、`am-tests mainargs=h`、`am-tests mainargs=a` 均在 NEMU batch 模式下跑到 `HIT GOOD TRAP`。
- [2026-04-13] `am-tests mainargs=d` 未通过，但已确认不是 `stdlib` 回归：日志在 `Screen size: 400 x 300` 后报 `AM Panic: access nonexist register`，根因是 `platform/nemu` 没有实现 `AM_GPU_MEMCPY/AM_GPU_RENDER`。

## 基准测试结果
<!-- CoreMark/Dhrystone/MicroBench 性能数据 -->
- [2026-04-13] `Dhrystone PASS 537 Marks`，`500000` 次运行完成于 `1639 ms`。
- [2026-04-13] `MicroBench PASS 1563 Marks`，`Scored time: 12086.902 ms`，`Total time: 13983.183 ms`。
- [2026-04-13] `CoreMark PASS 1203 Marks`，`1000` 次迭代总耗时 `2428 ms`。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- hello/mainargs 调试时要区分平台：native 依赖宿主环境变量 mainargs；riscv32-nemu 与 npc 依赖镜像里的静态 mainargs 区域，改的是生成后的 bin，不是运行时环境。
- `am-tests` 不能机械地“全量 batch 跑到底”：`devscan()` 末尾有 `while (1)`，`intr/rtc/video/keyboard/mp/vm` 也多为常驻或交互型测试，回归时应优先筛选可自动结束子项。
- `devscan()` 在 NEMU 上访问 `AM_GPU_MEMCPY/AM_GPU_RENDER` 会直接落到 `access nonexist register`；做回归归因时要先区分“最近代码改坏”与“平台本来就没实现该设备接口”。
