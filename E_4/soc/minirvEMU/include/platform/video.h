#pragma once

#include "hardware/memory.h"

#include <stdbool.h>

/*
 * 视频接口：负责将 SystemMemory 中的帧缓冲推送到 AM 平台提供的显示设备，
 * 并在必要时保持窗口等待用户退出。可以把它理解为“模拟器与图形外设的适配层”。
 */

/* video_flush:
 *   遍历显存，将像素逐行写入 AM_GPU_FBDRAW。
 *   wait_after 为 true 时，会在刷新后等待一段时间（用于最终画面展示）。
 */
void video_flush(SystemMemory *mem, bool wait_after);

/* video_hold_until_exit:
 *   进入阻塞循环，等待用户按下 ESC/Q 或输入 exit 命令后退出。
 */
void video_hold_until_exit(void);
