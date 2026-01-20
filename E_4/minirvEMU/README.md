# minirvEMU 工程说明


特点摘要：

- **硬件风格实现**：核心执行单元、内存、追踪等模块保持硬件语义，便于和真机行为对照分析。
- **清晰的分层目录**：`hardware/`、`runtime/`、`platform/` 分别承担不同职责，初学者可以从最感兴趣的层级切入阅读。
- **友好的调试体验**：提供循环保护、指令追踪、寄存器快照、自动清理等实用功能，方便快速定位问题。

## 目录结构

```text
E_4/minirvEMU/
├── app_main.c              # 程序入口，协调配置加载、镜像管理与 SoC 启动
├── include/
│   ├── hardware/           # 硬件层公共头文件（types、core、memory、trace）
│   ├── platform/           # 平台层头文件（soc、video、loopguard）
│   └── runtime/            # 运行时选项与镜像加载头文件
├── src/
│   ├── hardware/           # 硬件层实现：内存、核心执行、追踪
│   ├── platform/           # 平台层实现：SoC 主循环、视频输出、循环保护
│   └── runtime/            # 配置解析、程序加载
├── hex/                    # 示例 HEX 镜像（例如 vga.hex）
├── build/                  # 构建产物目录（由 make 创建）
├── Makefile                # 构建脚本，封装 runhex/clean/help 等目标
└── README.md               # 工程说明（本文档）
```

## 构建与运行
1. **准备环境**：确保已完成 Abstract Machine 环境变量配置（`AM_HOME` 等），并在工程根目录执行。

2. **编译模拟器**：

   ```bash
   make
   ```

   生成的 ELF 会位于 `build/minirvEMU-native.elf`。

3. **运行示例镜像**：

   ```bash
   make runhex HEX=hex/vga.hex
   ```

   - `HEX` 支持任意相对或绝对路径的 `.hex` 文件；
   - 若传入的镜像文件名包含 `vga`，系统会自动在程序结束后保持窗口。

4. **调试模式**：

   ```bash
   make runhex HEX=hex/vga.hex DEBUG=1
   ```

   开启指令追踪，并沿用默认的追踪步数限制（200 条）。

5. **清理产物**：

   ```bash
   make clean
   ```

   将删除 `build/`、顶层 `*.bin` 以及 `hex/*.bin`。

## 运行时配置（环境变量）

所有开关均通过环境变量控制，可在 `make runhex` 时通过 `env VAR=VALUE` 指定：

| 变量名 | 说明 | 默认值 |
| --- | --- | --- |
| `TRACE_INS` | 是否启用指令追踪（1/0） | 0 |
| `TRACE_LIMIT` | 追踪输出的指令条数上限（0 表示无限） | 200 |
| `SHOW_REGS_AFTER` | 程序结束后是否打印寄存器快照 | 0 |
| `PROGRESS_EVERY` | 每执行多少步打印一次进度（0 关闭） | 0 |
| `LOOP_THRESH` | 循环保护：同一 PC 重复的阈值 | 1,000,000 |
| `LOOP_MAX_STEPS` | 循环保护：总步数上限 | 5,000,000 |
| `HOLD_IMAGE_AFTER_HALT` | 程序结束后是否保持视频窗口 | 0 |

| `AUTO_CLEAN_AFTER_HALT` | 程序结束后是否自动清理构建产物 | 1 |


示例：

```bash

env TRACE_INS=1 TRACE_LIMIT=50 make runhex HEX=hex/sum.hex
```

## 代码分层概览

- **hardware/**

  - `types.h`：硬件常量、指令字段宏、执行结果枚举。
  - `memory.[ch]`：主存/显存的读写接口，实现越界检测与显存脏标记。
  - `core.[ch]`：RV32I 指令执行单元，负责译码、执行、寄存器维护。
  - `trace.[ch]`：指令追踪模块。

- **runtime/**
  - `config.[ch]`：读取环境变量生成 `RuntimeOptions`。
  - `loader.[ch]`：加载外部二进制或内置测试程序，填充 `ProgramImage` 并写入内存。
- **platform/**

  - `soc.[ch]`：SoC 总控循环，协调核心执行、循环保护、视频刷新、自动清理。
  - `video.[ch]`：将帧缓冲推送至 AM 图形设备，提供驻留等待功能。
  - `loopguard.[ch]`：检测重复 PC 或步数超限，防止死循环。
- **app_main.c**

  - 中央调度，负责配置加载、SoC 初始化、镜像管理与结果收尾。
- **Makefile**

  - 汇总源文件、编译参数、HEX-to-BIN 转换规则，定义 `runhex`/`clean`/`help` 目标。

## 显示与 IO 逻辑提示


- 指令执行期间只要写入显存地址区间，`memory_write*` 会设置 `video_dirty=1`。
- 主循环在每条指令后检查 `video_dirty`，若为真则调用 `video_flush`：

  - 将 `SystemMemory.video` 中的像素逐行写入 `AM_GPU_FBDRAW`；
  - 发送一次 `.sync=true` 以刷新屏幕；
  - 清除脏标记。
- 如果 `HOLD_IMAGE_AFTER_HALT` 或自动检测到 `vga` 镜像，程序结束时会调用 `video_hold_until_exit`，等待用户按下 ESC/Q 或输入 `exit/quit`。


## 常见工作流

1. **加载自定义程序**：
   - 使用工具将 RISC-V 指令编译为 `.hex` 或 `.bin`；
   - 若是 HEX，直接 `make runhex HEX=/path/to/file.hex`；
   - 若是 BIN，可参照 `runtime/loader.c` 的实现通过 `mainargs` 传入。
2. **调试死循环**：
   - 调大或调小 `LOOP_THRESH`、`LOOP_MAX_STEPS`；
   - 开启 `TRACE_INS` 获取 PC/指令轨迹；

   - 查看自动打印的寄存器快照与摘要。

3. **分析显示行为**：
   - 在 `video_flush` 中加入断点或日志，观察刷新频率；
   - 适当修改刷新策略（例如批量写入后再刷新），以适配复杂图形程序。

## 扩展建议

- **指令支持**：在 `hardware/core.c` 中增补 RV32M/D/A 等扩展的执行路径。
- **显存优化**：实现脏区域记录或双缓冲，减少整帧刷新次数。
- **外设模拟**：新增定时器、中断、串口等模块，扩展 `platform/` 层能力。
- **性能测量**：在 `soc_run` 中增加性能统计（CPI、访存次数等），便于教学分析。

## 致谢

本工程基于南京大学 ICS/PA 框架环境。感谢所有维护 Abstract Machine 与相关工具链的开发者，使得教学与实验能够在统一平台上顺利开展。
