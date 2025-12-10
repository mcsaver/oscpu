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

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
//使用readline库显示提示符（nemu)并等待用户输入
static char* rl_gets() {
  static char *line_read = NULL;//静态变量保存上次readline返回的指针，跨函数调用保持有效

  if (line_read) {//每次读取去新行前释放上次分配的内存，避免泄露
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");//调用readline显示提示符“(nemu)”，支持行编辑、历史搜索等等
  //返回值：成功，指向malloc分配的字符串（不包括末尾换行）
  //返回值：EOF（Ctrl-D）：返回NULL

  //当且仅当line_read非空且不是空字符串的时候，把该行加入内存的历史（readline）管理
  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}//注：readline使用动态内存，链接时需要-lreadline（项目已依赖）
//如果你像长期保存该字符串，需自己strdup一份
//该函数不是线程安全的（依赖静态变量和readline全局状态

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

//monitor的核心
void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }//如果启动的时候加了-b参数，就直接调用cmd_c知道程序结束，不接受用户输入

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    //使用strtok获得第一个单词作为命令，如c,q,si,info剩余部分作为参数args
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {//遍历cmd_table数组，查找匹配的命令名称
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  //编译正则表达式，为表达式求值做准备
  init_regex();

  //调用init_wq_pool在初始化监视池
  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
