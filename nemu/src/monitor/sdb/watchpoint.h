#ifndef __WATCHPOINT_H__
#define __WATCHPOINT_H__

#include "sdb.h"

#define NR_WP 32
#define max_str 1024

typedef struct watchpoint {
  int NO;//表示监视点的序号
  //指针大小是已知的，如果写成struct watchpoint next会导致无限递归
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char expr_str[1024];//保存监视用字符串
  word_t old_data;//旧数据

} WP;

// 把“当前是否存在监视点”暴露给执行热路径，便于零监视点时直接走快路径。
extern bool watchpoint_enabled;

// expr.c 中的 expr() 函数声明
word_t expr(char *e, bool *success);


WP * new_wp();
void free_wp(WP *wp);
bool delete_wp(int no);
void watchpoint_print();
int compare_assert();

#endif