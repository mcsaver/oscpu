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
#include "watchpoint.h"
#include <utils.h>

// 下面这些头文件主要服务于 `cmd_p` 新增的 `p test`。（更改日期：2025-12-22）
// - <ctype.h>  : isspace() 用于跳过空白
// - <errno.h>  : 解析数字/文件失败时打印原因
// - <stdlib.h> : getenv()/system()/malloc()/strtol()/strtoul()
// - <string.h> : strlen()/strerror()/strcmp()
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
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
  (void)args;
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_info(char *args) {

  if (args ==NULL) {
    printf("Usage: info r/w\n");
    return 0;
  }
  //提取第一个参数
  //已经调用过一次strtok来提取命令，strtok会在内部分配一个静态变量记录扫描为止
  //继续提取参数
  char *tok = strtok(args, " ");
  if (tok && strcmp(tok, "r") == 0) {
    isa_reg_display();//调用打印
    return 0;
  }
  
  else if (tok && strcmp(tok, "w") == 0)
  {
    watchpoint_print();
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


static int cmd_p(char *args) {
  if (args == NULL) {
    printf("Usage: p EXPR | p test\n");
    return 0;
  }

  // `readline` 返回的参数可能有前导空格，这里先跳过，保证对 "test" 的识别稳定
  while (*args != '\0' && isspace((unsigned char)*args)) args++;

  //`p test`
  // 目的：把表达式求值和 gen-expr 自动对拍接起来，做回归测试。
  // 流程：
  // 1) 调用 tools/gen-expr 的 Makefile 生成一批 "<expected> <expr>" 用例到临时文件
  // 2) 逐行读取：解析 expected（十进制无符号）和表达式字符串
  // 3) 调用 NEMU 内部 `expr()` 计算 got，与 expected 做 32-bit 对比
  // 4) 汇总 PASS/FAIL，并打印前若干条失败样例用于定位
  if (strcmp(args, "test") == 0) { //若相等则返回0
    bool old_enable_expr_log = enable_expr_log;
    enable_expr_log = false; // 关闭逐 token 日志，避免海量输出影响性能和阅读

    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    // 优先使用环境变量 NEMU_HOME 来定位 tools/gen-expr，避免从别的目录启动 NEMU 时相对路径失效。
    // 若没设置 NEMU_HOME，则退化为相对路径 ./tools/gen-expr（要求从 nemu/ 目录启动）。
    //使用geten查询环境变量NEMU_HOME
    const char *nemu_home = getenv("NEMU_HOME");
    char gen_dir[512];
    if (nemu_home && nemu_home[0] != '\0') {
      snprintf(gen_dir, sizeof(gen_dir), "%s/tools/gen-expr", nemu_home);
    } else {
      snprintf(gen_dir, sizeof(gen_dir), "./tools/gen-expr");
    } 

    // 用例文件输出位置：写到 tools/gen-expr/input
    const char *out_path = "./tools/gen-expr/input";

    // 生成用例条数（可根据需要调大，例如 1000/10000 做更强的压力测试）。
    const int loop = 100;

    // 通过 make 触发 tools/gen-expr/Makefile 的 input 目标。
    // `make -C <dir> input LOOP=<n> OUT=<file>`
    // 这样 NEMU 侧不需要关心 gen-expr 的参数细节，只要读 out_path 即可。
    char cmd[1024];

    //snprintf生成执行命令字符串：格式化字符串到cmd中
    // -C <dir>：切换到指定目录执行make
    // input：执行Makefile中的input目标
    snprintf(cmd, sizeof(cmd), "make -C %s input LOOP=%d OUT=%s", gen_dir, loop, "input");
    //system在shell中执行cmd命令，返回值是命令的退出状态
    int ret = system(cmd);
    if (ret != 0) {
      printf("p test: failed to run '%s'\n", cmd);
      printf("p test: hint: ensure NEMU_HOME is set to the nemu/ directory and 'make' is available.\n");
      enable_expr_log = old_enable_expr_log;
      return 0;
    }

    // 打开 gen-expr 生成的用例文件
    FILE *fp = fopen(out_path, "r");
    if (fp == NULL) {
      printf("p test: cannot open %s: %s\n", out_path, strerror(errno));
      enable_expr_log = old_enable_expr_log;
      return 0;
    }

    // 给每行分配一个足够大的缓冲：表达式可能很长（尤其是递归生成 + 随机空格）
    char *line = malloc(65536);
    if (line == NULL) {
      fclose(fp);
      printf("p test: out of memory\n");
      enable_expr_log = old_enable_expr_log;
      return 0;
    }

    int total = 0;//总共测试的表达式用例数量
    int pass = 0;//通过的用例数量
    int fail = 0;//失败的用例数量
    while (fgets(line, 65536, fp) != NULL) {
      char *p = line;//指向当前行的指针
      while (*p != '\0' && isspace((unsigned char)*p)) p++;//跳过所有的行首的空白字符
      if (*p == '\0') continue;//若遇到空白行直接跳过这行

      // 解析 expected：gen-expr 输出格式为："<unsigned> <expr>\n"
      // 用 strtoul() 从行首读取 expected 的十进制数。
      errno = 0;
      char *end = NULL;
      unsigned long expected_ul = strtoul(p, &end, 10);
      if (end == p || errno != 0) {
        continue;
      }

      // end 当前指向 expected 后的第一个字符：跳过空白，剩下部分就是表达式字符串。
      while (*end != '\0' && isspace((unsigned char)*end)) end++;
      if (*end == '\0') {
        continue;
      }

      char *expr_str = end;//从起点开始
      size_t n = strlen(expr_str);
      while (n > 0 && (expr_str[n - 1] == '\n' || expr_str[n - 1] == '\r')) {
        expr_str[n - 1] = '\0';
        n--;//长度减一，继续检查新的末尾字符
      }

      // 调用 NEMU 内的表达式求值器。
      // 注意：expr() 的 `success` 会在词法/语法错误、或 eval 过程中“软失败”（比如除 0）时置为 false。
      bool success = false;
      word_t got = expr(expr_str, &success);

      // 为了和 gen-expr 的输出对齐，这里统一截断/对比为 32-bit
      //（当前用例生成用的是 unsigned result，按 32-bit 无符号打印。）
      uint32_t expected = (uint32_t)expected_ul;
      uint32_t got32 = (uint32_t)got;

      total++;
      if (!success || got32 != expected) {
        fail++;
        // 只打印前 10 条失败样例，避免输出过多；用 total 作为用例序号方便回溯。
        if (fail <= 10) {
          printf("FAIL[%d]: expected=%u got=%u expr=%s\n", total, expected, got32, expr_str);
        }
      } else {
        pass++;
      }
    }

    free(line);
    fclose(fp);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double elapsed = (double)(t1.tv_sec - t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) / 1e9;
    if (elapsed < 0) elapsed = 0;
    printf("p test: PASS %d / %d (FAIL %d) time=%.3fs\n", pass, total, fail, elapsed);
    enable_expr_log = old_enable_expr_log;
    return 0;
  }

  //----------------普通模式执行------------//
  bool success = false;
  word_t result = expr(args, &success);
  if (success) {
    printf("Unsigned result : %u\n", (unsigned)result);
    printf("Signed result : %d\n", (int32_t)result);
    printf("HEX result : 0x%08x\n", (unsigned)result);
  } else {
    printf("Invalid expression: %s\n", args);
  }
  
  enable_expr_log = true;
  return 0;
}

static int cmd_help(char *args);

static int cmd_w(char *args){
  if (args == NULL)
  {
    printf("Usage w EXPR\n");
    return 0;
  }

  while (*args != '\0' && isspace((unsigned char)*args)) args++;
  bool success = false;
  word_t val = expr(args, &success);
  if (success) {
    printf("Unsigned expr : %u\n", (unsigned)val);
    printf("Signed expr : %d\n", (int32_t)val);
    printf("HEX expr : 0x%08x\n", (unsigned)val);
  } else {
    printf("Invalid expression: %s\n", args);
  }
  
  //将args传给表达式求值和监视点创建
  WP *wp = new_wp();
  strncpy(wp->expr_str, args, sizeof(wp->expr_str) - 1);
  wp->expr_str[sizeof(wp->expr_str) - 1] = '\0';
  wp->old_data = val;

  printf("Watchpoint %d set on: %s\n", wp->NO, wp->expr_str);
  return 0;
  
}

//watchpoint的删除，根据序号
static int cmd_d(char *args){
  if (args == NULL)
  {
    printf("Usage p NO\n");
    return 0;
  }

  int no_reg = atoi(args);

  bool success = delete_wp(no_reg);
  
  if (success) {
      printf("Watchpoint %d deleted\n", no_reg);
  } else {
      printf("Watchpoint %d not found\n", no_reg);
  }

  return 0;
}

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
  { "p", "Evaluate expression: p EXPR", cmd_p },
  { "w", "Watchpoint EXPR: Pause execution when the value of the expression EXPR changes", cmd_w},
  { "d", "Delete watchpoint", cmd_d}

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
  }
  //如果启动的时候加了-b参数，就直接调用cmd_c直到程序结束，不接受用户输入
  //不断的显示提示符并读取用户输入保存到str中，只要没有读到EOF(即用户没有按Ctrl+D，就进入循环体处理这条命令)
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
