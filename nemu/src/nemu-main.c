/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
//NEMU主程序入口，主要负责初始化监控器和启动引擎

#include <common.h>

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();
#ifdef CONFIG_HAS_DISK
bool virtio_blk_shutdown(void);
#endif

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
  //初始化监视器/环境
#ifdef CONFIG_TARGET_AM
//如果编译的是AM目标，则调用am_init_monitor初始化
  am_init_monitor();
#else
//否则，普通NEMU仿真，初始化NEMU的监视器（SDB调试器、命令行参数）
  init_monitor(argc, argv);//构建整台虚拟机器
#endif

  /* Start engine. */
  engine_start();//把执行权交给解释器

  //检查仿真是否以良好状态退出
  int exit_status = is_exit_status_bad();
#ifdef CONFIG_HAS_DISK
  /*
   * A reboot exit code is permission for the host supervisor to start a new
   * process.  Publish it only after all pending block I/O and overlay metadata
   * are durable; otherwise turn the lifecycle transition into a hard failure
   * so the next boot cannot silently observe stale overlay ownership bits.
   */
  if (!virtio_blk_shutdown()) {
    fprintf(stderr,
        "nemu: block storage shutdown failed; suppressing guest reboot/poweroff success\n");
    exit_status = EXIT_FAILURE;
  }
#endif
  return exit_status;
}
