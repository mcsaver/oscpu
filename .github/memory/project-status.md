# YSYX 项目状态总览

> 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

## 当前阶段
<!-- agent 在此更新当前所处的开发阶段 -->
- [ ] 数字逻辑实验
- [ ] 单周期 CPU 设计
- [ ] 多周期 CPU 设计
- [ ] 流水线 CPU 设计
- [ ] 差分测试通过
- [ ] 综合分析通过

## 已完成的工作
<!-- 按时间倒序记录，格式: - [日期] 简要描述 -->
- [2026-04-01] 解析 nemu/src/device/keyboard.c，确认键盘设备在非 AM 目标下走 SDL 事件采集与本地环形队列，在 CONFIG_TARGET_AM 下改为直接读取 AM_INPUT_KEYBRD；i8042 数据寄存器通过读回调在 CPU 访问时出队 1 个键盘事件。
- [2026-03-31] 定位 fceux-am 通过 NEMU 运行时的 LeakSanitizer 报告：确认根因是 nemu/.config 开启 CONFIG_CC_ASAN 且 VGA 显示路径会在宿主侧调用 SDL/GLX/Mesa；退出时主机图形资源未显式销毁，LSan 因此把主机库分配记为泄漏，并非 guest 侧 NES 程序逻辑错误。
- [2026-03-31] 清理 fceux-am/nes/rom 目录下从 Windows 复制带来的 `*:Zone.Identifier` 文件，确认未影响真实 `.nes` ROM 文件。
- [2026-03-31] 修复 fceux-am 在无 ROM 时编译失败的问题：调整 fceux-am/Makefile 让 roms.h 总能生成，build-roms.py 支持零 ROM 生成占位表，emufile.cpp 在无内嵌 ROM 时给出明确提示；验证 `make ARCH=riscv32-nemu` 可构建通过，`make ARCH=riscv32-nemu run mainargs=mario` 能进入 NEMU 并明确提示缺少 `nes/rom/*.nes`。
- [2026-03-31] 补全 NEMU 的 DTRACE 配置链路：在 nemu/Kconfig 增加 DTRACE/DTRACE_COND，在 nemu/Makefile 传递 -DDTRACE_COND 宏，并整理 mmio.c 的 MMIO 读写日志代码；随后执行 `make -C nemu -j4` 构建通过。
- [2026-03-30] 排查 klib printf 输出 `%02d` 被原样打印的问题，确认根因是 kvsnprintf 仅支持 `%d/%s/%c/%%`，尚未解析宽度与补零标志。
- [2026-03-30] 在 .github/copilot-instructions.md 增加 agent 代码建议约束：默认只在对话框提供代码建议，不直接修改文件，除非用户明确要求落盘实现。
- [2026-03-30] 解析 nemu/src/device/timer.c，确认 RTC 设备仅在读 offset 4 时用 get_time() 刷新 64 位时间寄存器；非 AM 目标下还会通过 alarm.c 周期触发 dev_raise_intr() 注入时钟中断。
- [2026-03-30] 梳理 hello 的 mainargs 传参链路，确认 riscv32-nemu 通过占位符加镜像回写传参，native 通过 make 命令行变量导出为环境变量并由 native/platform.c 中 getenv("mainargs") 读取。
- [2026-03-30] 在 .github/copilot-instructions.md 增加 agent 终端约束，明确 NEMU/NVBoard/menuconfig 等交互程序禁止用 tail/head/管道截断输出，避免界面无法显示。
- [2026-03-30] 排查 am-kernels hello 在 riscv32-nemu 上访问 0xa00003f8 越界，确认根因是 nemu/.config 关闭了 CONFIG_DEVICE 且未启用 CONFIG_TARGET_AM，串口 MMIO 未注册而落入 pmem 越界检查。
- [2026-03-29] 梳理 abstract-machine/klib/include/klib-macros.h，确认 io_read/io_write 依赖 AM_DEVREG 生成的寄存器类型，panic_on 通过 putch/putstr 输出并最终 halt。
- [2026-03-27] 梳理 NEMU 设备映射层 map.h/map.c，确认 PIO/MMIO 共用 IOMap 抽象，命中设备映射时会触发 difftest_skip_ref。
- [2026-03-22] 在 npc/single/vsrc/alu.v 中补全 SLT 与 SLTU，两种比较运算已接入基础 ALU。
- [2026-03-22] 补全 npc/single/vsrc/alu.v，完成 NPC 模块基础 ALU 的 8 类运算实现。

## 正在进行的工作
<!-- 当前正在处理的任务 -->

## 待办事项
<!-- 已知但尚未开始的任务 -->

## 里程碑
<!-- 重要节点记录 -->
