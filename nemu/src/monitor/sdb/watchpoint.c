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

#include "sdb.h"
#include "watchpoint.h"


//static：这个结构体是在文件作用域用static定义的全局对象
//属于静态存储期，编译后放在.bss/data段
//程序启动即分配，进程结束才释放
//只有函数内的自动变量(无static的局部)才会分配在栈上并随调用结束而销毁

//分配32个连续的sp结构体内存空间
static WP wp_pool[NR_WP] = {};
//head用于组织使用中的监视点结构
//free_用于组织空闲的监视点结构
static WP *head = NULL, *free_ = NULL;

//函数会对两个链表进行初始化
void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
//其中new_wp()从free_链表中返回一个空闲的监视点结构, free_wp()将wp归还到free_链表中
//这两个函数会作为监视点池的接口被其它函数调用
//需要注意的是, 调用new_wp()时可能会出现没有空闲监视点结构的情况
//为了简单起见, 此时可以通过assert(0)马上终止程序
WP * new_wp(){
  //检查此时free_链表是否为空，如果没有空闲节点，直接报错
  assert(free_ != NULL);

  //从free_链表头部领取下一个节点
  WP *wp = free_;
  free_= free_->next;

  //将该节点加入head链表
  wp->next = head;
  head = wp;

  //返回这个节点的指针给外部使用
  return wp;
}


void free_wp(WP *wp){//wp为head中的一个点
  //检查wq是否为空，如果没有节点，直接报错
  assert(wp != NULL);

  //从head链表中删除该节点
  if (head == wp) //wp刚好指向head
  {
    head = head->next;
  }
  else {//删除非头节点
    WP *prev = head;//从链表头开始查找要删除节点的前驱
    while (prev != NULL && prev->next != wp)
    {//走链表直到找到一个节点prev，使prev->next == wp，即前驱
      prev = prev->next;
    }
    assert(prev != NULL);
    
    //prev的next直接指向了wp的mext，B的连接变成孤立
    //修改prev->next不是在改变量prev变量本身，而是在改prev指向的那个节点的next字段
    //所以链表被改变了
    prev->next = wp->next;

  }

  //将该节点加入free_链表
  wp->next = free_;
  free_ = wp;

  //删除旧数据
  wp->expr_str[0] = '\0';
  wp->old_data = 0;
}

//根据序号删除监视点，true成功，false失败
bool delete_wp(int no){
  WP *wp = head;

  while (wp != NULL)
  {
    if (wp->NO == no)
    {
      free_wp(wp);
      return true;
    }
    wp = wp->next;
  }
    
  //找了一圈没有找到
  return false;

}

//info w打印所有监视点
void watchpoint_print(){
  if (head == NULL)
  {
    printf("NO Watchpoint!Please set a watchpoint\n");
    return;
  }
  

  WP *wp = head;
  
  printf("%-4s %-32s %-12s\n", "Num", "Expr", "Old_Value");
  printf("%-4s %-32s %-12s\n", "----", "--------------------------------", "------------");
  while (wp != NULL) {
    printf("%-4d %-32.32s " FMT_WORD "\n", wp->NO, wp->expr_str, wp->old_data);
    wp = wp->next;
  }
}

/*   //将args传给表达式求值和监视点创建
  WP *wp = new_wp();
  strncpy(wp->expr_str, args, sizeof(wp->expr_str) - 1);
  wp->expr_str[sizeof(wp->expr_str) - 1] = '\0';
  wp->old_data = val;
 */
//监视点断点功能
int compare_assert()
{
  WP *wp = head;
  while (wp != NULL) {
    bool success = true;
    word_t new_val = expr(wp->expr_str, &success);  // 传入 &success

    if (!success) {
      printf("Invalid watchpoint expr: %s\n", wp->expr_str);
      // 可选择直接停止或跳过，这里跳过
      wp = wp->next;
      continue;
    }

    if (new_val != wp->old_data) {
      printf("Watchpoint %d triggered: %s\n", wp->NO, wp->expr_str);
      printf("Old = " FMT_WORD ", New = " FMT_WORD "\n", wp->old_data, new_val);
      wp->old_data = new_val;       // 更新旧值
      return 1;                     // 告知外部应暂停
    }

    wp = wp->next;                  // 推进到下一个节点
  }
  return 0;
}