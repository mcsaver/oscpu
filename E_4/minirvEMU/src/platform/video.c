#include "platform/video.h"

#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <sys/select.h>

#include <am.h>

/*
 * 模块定位：视频输出适配层。
 *   - video_flush 将 SystemMemory 中的像素推送给 AM 平台的 GPU 接口；
 *   - video_hold_until_exit 在程序结束后阻塞等待用户确认；
 *   - trim 是处理终端输入的辅助函数。
 */

/* trim:
 *   去除字符串两端的空白字符，便于解析终端输入命令。
 */
static void trim(char *line) {
    if (!line) {
        return;
    }
    size_t len = strlen(line);
    while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r' || line[len - 1] == '\t' || line[len - 1] == ' ')) {
        line[--len] = '\0';
    }
    size_t start = 0;
    while (line[start] == ' ' || line[start] == '\t' || line[start] == '\r' || line[start] == '\n') {
        start++;
    }
    if (start != 0) {
        memmove(line, line + start, strlen(line + start) + 1);
    }
}

/* video_flush:
 *   若显存标记为脏，则逐行写入 AM_GPU_FBDRAW，并在需要时延迟 2 秒以方便观察。
 */
void video_flush(SystemMemory *mem, bool wait_after) {
    if (!mem || !memory_video_dirty(mem)) {
        return;
    }
    const uint8_t *fb = memory_video_data(mem);
    int width = memory_video_width();
    int height = memory_video_height();
    for (int y = 0; y < height; ++y) {
        AM_GPU_FBDRAW_T ctl = {
            .x = 0,
            .y = y,
            .pixels = (void *)(fb + (size_t)y * (size_t)width * HW_VIDEO_BPP),
            .w = width,
            .h = 1,
            .sync = false
        };
        ioe_write(AM_GPU_FBDRAW, &ctl);
    }
    AM_GPU_FBDRAW_T sync = { .x = 0, .y = 0, .pixels = NULL, .w = 0, .h = 0, .sync = true };
    ioe_write(AM_GPU_FBDRAW, &sync);
    memory_video_clear(mem);

    if (!wait_after) {
        return;
    }
    AM_TIMER_UPTIME_T t0;
    ioe_read(AM_TIMER_UPTIME, &t0);
    while (1) {
        AM_TIMER_UPTIME_T t1;
        ioe_read(AM_TIMER_UPTIME, &t1);
        if (t1.us - t0.us >= 2000000ull) {
            break;
        }
    }
}

/* video_hold_until_exit:
 *   打开 /dev/tty 监听键盘输入，支持输入 exit/quit 或按下 ESC/Q 退出等待。
 *   该函数在 hold_after_halt 为真时被调用。
 */
void video_hold_until_exit(void) {
    FILE *in = fopen("/dev/tty", "r");
    if (!in) {
        in = stdin;
    }
    int fd = (in ? fileno(in) : -1);

    printf("[hold] framebuffer locked; ESC/Q or typing exit quits.\n");
    fflush(stdout);
    char line[256];

    while (1) {
        int ready = 0;
        if (fd >= 0) {
            fd_set rfds;
            FD_ZERO(&rfds);
            FD_SET(fd, &rfds);
            struct timeval tv = { .tv_sec = 0, .tv_usec = 50000 };
            if (select(fd + 1, &rfds, NULL, NULL, &tv) > 0 && FD_ISSET(fd, &rfds)) {
                if (fgets(line, sizeof(line), in)) {
                    trim(line);
                    if (line[0] != '\0') {
                        ready = 1;
                    }
                } else {
                    ready = 0;
                }
            }
        } else {
            usleep(50000);
        }

        if (ready) {
            if (strcasecmp(line, "exit") == 0 || strcasecmp(line, "quit") == 0 || strcasecmp(line, "q") == 0) {
                break;
            }
            if (line[0] == '\x1b' || line[0] == 'q' || line[0] == 'Q') {
                break;
            }
        }

        AM_INPUT_KEYBRD_T kb;
        ioe_read(AM_INPUT_KEYBRD, &kb);
        if (kb.keydown && (kb.keycode == AM_KEY_ESCAPE || kb.keycode == AM_KEY_Q)) {
            break;
        }
    }

    if (in && in != stdin) {
        fclose(in);
    }
}
