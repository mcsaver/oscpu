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
//工作流程：
// 1. 生成随机表达式字符串
// 2. 用code_format格式化生成临时C代码文件，赋值给code_buf
// 3. 把code_buf写道/tmp/.code.c，然后用gcc编译成可执行文件/tmp/.expr
// 4. 允许/tmp/.expr运行，用fscanf读取其输出结果
// 5. 打印结果和表达式字符串

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
// [新增] 用于解析 pclose() 返回的子进程状态。（更改日期：2025-12-22）
// - WIFEXITED/WEXITSTATUS：判断子进程是否正常退出
// - 如果表达式运行时触发 SIGFPE（比如除 0），子进程会异常退出；我们需要丢弃这条用例并重试
#include <sys/wait.h>

//static  int flat_nospace;

//buffer size
#define BUF_SIZE 65536
//递归深度
#define MAX_DEPTH 7

// this should be enough

//buf存放生成的表达式
static char buf[BUF_SIZE] = {};
//code_buf存放完整的c程序代码
// code_buf 需要比 buf 稍大：除了表达式本身，还要拼上 code_format 的 C 模板（include/main/printf 等）。（更改日期：2025-12-22）
// 这里 +128 是一个经验值，足够容纳模板的固定部分。
static char code_buf[BUF_SIZE + 128] = {};
//code_format是生成临时c程序的模板，用于把表达式嵌入到main函数中
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

//从0到n-1中随机选择一个整数
static int choose(int n) {
  return rand() % n ;
}

//在buf末尾添加字符c
static void gen(char c) {
  //flat_nospace = 1;
  int len = strlen(buf);
  if (len + 2 >= BUF_SIZE) return;
  buf[len] = c;
  buf[len + 1] = '\0';
}

//生成一个随机十进制数字并追加到buf末尾
static void gen_num() {
  //flat_nospace = 0;
  int len = strlen(buf);
  if (len + 16 >= BUF_SIZE) return;
  //生成一个随机数，范围是0~999
  int num = choose(1000); 
  //把数字转换成字符串，追加到buf后面
  len += sprintf(buf + len, "%d", num);
}

// 生成一个随机运算符并追加到buf末尾
static void gen_rand_op() {
  //flat_nospace = 0;//允许运算符前后有空格;
  switch (choose(4)) {
    case 0: gen('+'); break;
    case 1: gen('-'); break;
    case 2: gen('*'); break;
    default: gen('/'); break;
  }
}

//生成一个随机空格
static void gen_rand_space() {
  // if(flat_nospace==1) return ;
  int n = choose(4); // 0~3 个空格
  for (int i = 0; i < n; i++) {
    gen(' ');
  }
}

//递归生成随机表达式
static void gen_rand_expr(int depth) {
  //buf[0] = '\0';
  if (depth > MAX_DEPTH) {
    gen_num();
    return;
  }
  switch (choose(6)) {
    case 0: gen_num(); break;
    case 1: gen('('); gen_rand_expr(depth + 1); gen(')'); break;
    //case 2: gen('('); gen_rand_expr(depth + 1); gen(')'); break;
    //case 2: gen_rand_space(); break;
    case 2: gen_rand_expr(depth + 1); gen_rand_space(); gen_rand_op(); gen_rand_expr(depth + 1); break;
    case 3: gen_rand_expr(depth + 1);  gen_rand_op(); gen_rand_space(); gen_rand_expr(depth + 1); break;
    case 4: gen_rand_expr(depth + 1); gen_rand_space();gen_rand_op(); gen_rand_space(); gen_rand_expr(depth + 1); break;
    default: gen_rand_expr(depth + 1); gen_rand_op(); gen_rand_expr(depth + 1); break;
  }
}


int main(int argc, char *argv[]) {
  int seed = time(0);
  //srand(seed)，设置随机数种子
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);//sscanf从字符串读取格式化输入
  }
  int i;
  for (i = 0; i < loop; i ++) {
    // 每次生成一条新用例前都要清空 buf，否则会把上一条表达式拼接到下一条上，（更改日期：2025-12-22）
    // 造成类似 "(((104)))962" 或 "817(((..." 这种非法 C 表达式。
    buf[0] = '\0';
    gen_rand_expr(0);//生成随机表达式，存入buf

    //把buf填进code_format，生成完整的c程序代码到code_buf
    sprintf(code_buf, code_format, buf);

    //把生成的完整C程序源码写入临时文件/tmp/.code.c
    //fopen以写模式打开文件，assert确保文件成功打开
    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    //fputs把code_buf(完整C程序代码字符串)写入文件
    fputs(code_buf, fp);
    fclose(fp);

    //调用系统gcc编译/tmp/.code.c生成可执行文件/tmp/.expr
    // 这里只需要拿到“可运行并打印结果”的可执行文件作为标准答案来源。
    // 随机表达式可能触发编译器溢出等告警，屏蔽告警输出避免干扰用例生成。
    //int ret = system("gcc -w /tmp/.code.c -o /tmp/.expr");
    //int ret = system("gcc  /tmp/.code.c -o /tmp/.expr");
    // [关键改动] 生成“标准答案”的 C 程序编译参数：（更改日期：2025-12-22）
    // - -fwrapv：把有符号溢出定义为按二进制补码回绕（避免 C 的 UB 导致结果不稳定）
    // - -O0：降低优化带来的常量折叠/重排差异，让“标准答案”更接近我们在 NEMU 里按 int32_t/uint32_t 的求值语义
    // - 2> /tmp/.gcc_warn.log：收集告警，后面可以筛掉 overflow 等可疑用例
    int ret = system("gcc -O0 -fwrapv /tmp/.code.c -o /tmp/.expr 2> /tmp/.gcc_warn.log");
    if (ret != 0) {          // 编译失败：重试，保证输出条数够
      i = i - 1;
      continue;
    }

    // 检查是否有溢出警告
    FILE *warn_fp = fopen("/tmp/.gcc_warn.log", "r");
    int has_overflow = 0;
    if (warn_fp) {
      char line[256];
      while (fgets(line, sizeof(line), warn_fp)) {
        if (strstr(line, "overflow")) {
          has_overflow = 1;
          break;
        }
      }
      fclose(warn_fp);
    }
    if (has_overflow) {
      i = i - 1;
      continue;
    }

    // 运行子进程：把 stderr 丢到 /dev/null，避免除 0 等运行时错误信息污染 stdout。（更改日期：2025-12-22）
    // 注意：stderr 被丢弃不代表我们忽略异常；异常会在 pclose() 的退出状态里体现。
    fp = popen("/tmp/.expr 2>/dev/null", "r");
    assert(fp != NULL);

    unsigned result = 0;
    ret = fscanf(fp, "%u", &result);

    // 关闭管道并拿到子进程退出状态：用于判断是否发生 SIGFPE 等异常。（更改日期：2025-12-22）
    int status = pclose(fp);

    // 读取失败 或 子进程异常退出（比如 SIGFPE/除 0）=> 丢弃用例并重试。（更改日期：2025-12-22）
    if (ret != 1 || status == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
      i = i - 1;
      continue;
    }

    printf("%u %s\n", result, buf);
  }
  return 0;
}
