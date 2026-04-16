# NPC 仿真性能分析与优化

## 目录结构

```
perf/
├── README.md           — 本文件：优化说明和分析记录
├── configs/            — 分析专用 defconfig
│   └── perf_defconfig  — 关闭所有 trace 的极速配置
├── results/            — 跑分和 profiling 产物
│   └── <日期>/         — 按日期归档
└── scripts/
    ├── bench.sh        — 一键 CoreMark 基准跑分
    └── profile.sh      — callgrind 热点分析
```

## 可用工具

| 工具 | 用途 | 备注 |
|------|------|------|
| Verilator --prof-cfuncs | 给 C++ 函数加可读名称便于采样 | 零额外开销 |
| gprof (-pg) | 编译插桩，函数级耗时 | 约 5% 开销 |
| callgrind | 指令级精确计数 | 20-40x 慢，短程序 |
| Verilator -O3 | RTL 转 C++ 优化等级 | 构建时间增加 |

## 优化记录

> 以下按日期追加，保留历史基线用于对比。

### 2026-04-16 首轮优化

#### 基线（优化前）
- **配置**: default_defconfig（含 VGA/SDB/trace/log/watchpoint/itrace/mtrace/dtrace）
- **短程序 (add test)**: ~820,939 inst/s
- **CoreMark**: 无法在 10 分钟内完成（太慢）

#### 优化项

| # | 优化内容 | 影响文件 | 原理 |
|---|---------|----------|------|
| 1 | Verilator `--trace` 条件化 | Makefile | 不开 trace 时消除 VCD 生成开销 |
| 2 | Verilator `-O3 --prof-cfuncs` | Makefile | RTL→C++ 更高编译优化等级 |
| 3 | `#if VM_TRACE` 条件编译 | cpu-exec.cpp | 未开 trace 时跳过所有 VCD 相关代码 |
| 4 | 设备轮询节流 (DEVICE_POLL_INTERVAL=65536) | device.c | 避免每周期调用 `poll()` 系统调用 |
| 5 | `calloc` 替代 `malloc+memset`，移除冗余 memset | paddr.c | 减少 128MB×2 的内存初始化开销 |
| 6 | `npc_state()`/`npc_stats()` extern + static inline | utils.h, utils.c | 热循环中消除跨编译单元函数调用 |

#### 结果（perf_defconfig）
- **CoreMark 1000 iterations**: **863,362 inst/s**
- **总指令数**: 746,654,077
- **总耗时**: 865 秒
- **cpu-tests**: 35/35 PASS

#### callgrind 热点分析（优化前，短程序）
```
npc_load_img    71.85%  — 128MB memset (已优化)
npc_init_mem    17.96%  — malloc+memset (已优化)
eval_nba         0.67%  — RTL 仿真核心（无法优化）
check_watchpoints 0.10% — 跨 TU 函数调用
npc_stats        0.06%  — 跨 TU 函数调用
```
