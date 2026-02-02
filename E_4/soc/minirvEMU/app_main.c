#include "runtime/config.h"
#include "runtime/loader.h"
#include "platform/soc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * 模块定位：应用入口层。
 * 负责三件事：
 *   1. 读取环境变量构建 RuntimeOptions；
 *   2. 加载外部或内置的程序镜像；
 *   3. 驱动 HardwareSystem 完成仿真并输出结果。
 */

/*
 * check_auto_hold:
 *   判断镜像文件名是否包含 "vga"，如果是则默认在程序结束后保持窗口。
 *   这样做的目的是方便观看图形程序的最终输出画面。
 */
static int check_auto_hold(const char *path) {
    if (!path) {
        return 0;
    }
    const char *base = strrchr(path, '/');
    base = base ? base + 1 : path;
    return (strstr(base, "vga") != NULL);
}

/*
 * main:
 *   - 从 mainargs 读取可选的外部程序路径；
 *   - 调用 runtime_config_load 获取配置；
 *   - 初始化 HardwareSystem 并根据输入加载镜像；
 *   - 调用 soc_run 启动仿真，最后回收所有资源。
 *   对初学者来说，可以把这段代码理解为“模拟器的总控脚本”。
 */
int main(const char *args) {
    RuntimeOptions options; /* 运行时选项由环境变量驱动 */
    runtime_config_load(&options);

    HardwareSystem *soc = (HardwareSystem *)malloc(sizeof(HardwareSystem)); /* 单实例 SoC */
    if (!soc) {
        perror("alloc soc");
        return 1;
    }
    soc_bootstrap(soc, &options);

    ProgramImage image;
    memset(&image, 0, sizeof(image));

    int external = (args && args[0]);
    if (external) {
        if (strcmp(args, "-h") == 0 || strcmp(args, "--help") == 0) {
            printf("usage: mainargs=<program.bin> make runhex\n");
            return 0;
        }
        if (loader_from_bin(args, &image, soc_memory(soc)) != 0) {
            free(soc);
            return 1;
        }
        printf("loaded %zu instructions from %s\n", image.word_count, args);
        if (image.halt_pc != 0xffffffffu) {
            printf("detected halt at 0x%08x\n", image.halt_pc);
        }
        if (check_auto_hold(args)) {
            soc_force_hold(soc, 1);
            printf("auto hold after halt enabled.\n");
        }
    } else {
        loader_make_builtin(&image, soc_memory(soc));
        printf("no external program provided; builtin demo active (%zu instructions).\n", image.word_count);
    }

    soc_attach_program(soc, &image);

    int rc = soc_run(soc);

    loader_release(&image);
    free(soc);
    return rc;
}
