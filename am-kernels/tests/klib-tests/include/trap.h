#ifndef __TRAP_H__
#define __TRAP_H__

#include <am.h>
#include <klib.h>
#include <klib-macros.h>


//断言函数，作用是判断测试是否通过
__attribute__((noinline))
void check(bool cond) {
  if (!cond) halt(1);
}

#endif
