#ifndef __WATCHPOINT_H__
#define __WATCHPOINT_H__

#include "sdb.h"

#define NR_WP 32


typedef struct watchpoint {
  int NO;//表示监视点的序号
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char expr_str[128];//保存监视用字符串
  word_t old_data;//旧数据

} WP;

// expr.c 中的 expr() 函数声明
word_t expr(char *e, bool *success);


WP * new_wp();
void free_wp(WP *wp);
bool delete_wp(int no);
void watchpoint_print();


#endif