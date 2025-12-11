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
/* #include <errno.h>
#include <ctype.h>
#include <limits.h> */

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

static int cmd_si(char *args){
  //单步或者N步执行
  int n = 1;
  if (args) {
    char *end = NULL;
    //errno = 0;
    long v = strtol(args, &end, 0);
    
    if (end == args) {
      printf("si: invalid number '%s'\n", args);
      return 0;
    } 
/*     if (errno == ERANGE) {
      printf("si: number out of range '%s'\n/", args);
      return 0;
    }
    //跳过end指向的空白，检查是否有尾随非空字符
    while (isspace((unsigned char)*end)) end++;
    if (*end != '\0')
    {
      printf("Trailing characters after number: '%s'\n", end);
      return 1;
    } */

    n = (int)v;
    if (n <= 0) n = 1;
  }
  cpu_exec(n);
  return 0;
}

static int cmd_q(char *args) {
  return -1;
}

static int cmd_info(char *args) {

  if (args ==NULL) {
    printf("Usage: info r\n");
    return 0;
  }
  //提取第一个参数
  char *tok = strtok(args, " ");
  if (tok && strcmp(tok, "r") == 0) {
    isa_reg_display();//调用打印
    return 0;
  }
  printf("Unknown info command '%s'\n", tok ? tok : "");
  return 0;
}

static int cmd_x(char *args) {
  if (args == NULL) {
    printf("Usage: x N ADDR\n");
    return 0;
  }

  //strtok会修改传入的字符串，把遇到的分隔符字符替换成‘\0'，并返回各个token的起始指针
  char *count_tok = strtok(args, " \t");//计数，读取args中的字符知道遇到空格为止
  char *addr_tok = strtok(NULL, " \t");//地址，传入NULL 参数可以标售继续上一次对同一字符串的分割
  if (count_tok == NULL || addr_tok == NULL) {
    printf("Usage: x N ADDR\n");
  }

  char *end = NULL;
  long n = strtol(count_tok, &end, 0);
  if (end == count_tok || n <= 0) {
    printf("x: invalid count '%s'\n", count_tok);
    return 0;
  }

  //if (n > 1024) n = 1024;

  //从字符串开头（跳过前导空白）解析符合当前进制的数字字符，遇到第一个不属于数学语法的字符就停止，并把end指向该位置，他不会修改原字符串
  paddr_t addr = (paddr_t)strtoul(addr_tok, &end, 0);
  if (end == addr_tok) {
    printf("x: invalid count '%s'\n", count_tok);
    return 0;
  }

  for (long i = 0; i < n; i++)
  {
    paddr_t a = addr + i * 4;
    word_t v = paddr_read(a, 4);
    printf("0x%08x: 0x%08x\n", (unsigned)a, (unsigned)v);
  }
  
  return 0;
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
  { "si", "Single-step N instructions (default 1)", cmd_si },
  { "info", "Show information (e.g. 'info r')", cmd_info },
  { "x", "Examine memory: x N ADDR (print N words of 4 bytes from ADDR)", cmd_x },

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
  }//如果启动的时候加了-b参数，就直接调用cmd_c直到程序结束，不接受用户输入

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    //使用strtok获得第一个单词作为命令，如c,q,si,info，剩余部分作为参数args
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
