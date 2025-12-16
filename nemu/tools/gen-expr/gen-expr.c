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

// this should be enough
//buf存放生成的表达式
static char buf[65536] = {};
//code_buf存放完整的c程序代码
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
//code_format是生成临时c程序的模板，用于把表达式嵌入到main函数中
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

static void gen_rand_expr() {
  buf[0] = '\0';
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
    gen_rand_expr();

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
    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    //如果编译失败（比如表达式有语法错误），则跳过本次循环
    if (ret != 0) continue;

    //运行刚刚编译出来的可执行文件/tmp/.expr，并用管道读取其输出结果
    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    //用fscanf从管道中读取输出的结果
    ret = fscanf(fp, "%d", &result);
    //关闭管道
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
