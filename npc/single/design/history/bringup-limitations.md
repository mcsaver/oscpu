# 早期 bring-up 限制记录

以下内容从原顶层 README 保留，仅记录早期阶段判断；其中 CSR/CLINT/UART 与总线描述已不能代表当前实现。
当前能力应以生产 RTL、仿真宿主和直接相关测试为准。

## 当前限制

这套环境已经适合 RV32I bring-up 和 AM 最小程序回归，但还不是完整平台：

- 普通 trap 目前仍是 halt-only 语义，还没有最小 CSR/trap handler 闭环
- 设备当前已覆盖 `serial/rtc/keyboard/vgactl/framebuffer`，并支持 `GPU_CONFIG/GPU_STATUS/GPU_FBDRAW/GPU_MEMCPY/GPU_RENDER`
- 如果构建时未检测到 SDL2，VGA 仍能走 headless framebuffer 语义，但不会弹出窗口，也不会有窗口键盘事件
- NEMU 上的 `am-tests mainargs=d` 现在已经能穿过 VGA 阶段并跑到 `Test End!`
- NPC 上的 `am-tests mainargs=d` 当前主要瓶颈已经不是 VGA，而是前面的 `timer_test` 忙等循环对多周期核太重，后面还叠加了磁盘设备尚未实现；因此若它还没完整跑完，先不要再把问题归因到 VGA 缺口
- 还没有 `mtime/mtimecmp`、完整 UART 状态机和更真实的总线协议
- DPI 总线目前是“一拍请求、一拍返回”的简单模型，目标是 bring-up，而不是最终 SoC 互连

