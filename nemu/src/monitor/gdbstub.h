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

#ifndef __GDBSTUB_H__
#define __GDBSTUB_H__

#include <common.h>

void gdbstub_set_port(int port);
bool gdbstub_is_enabled(void);
extern bool gdbstub_runtime_enabled;

static inline bool gdbstub_fast_enabled(void) {
#ifndef CONFIG_TARGET_AM
  return unlikely(gdbstub_runtime_enabled);
#else
  return false;
#endif
}

const char *gdbstub_capability(void);
void gdbstub_wait_for_client_if_enabled(void);
bool gdbstub_breakpoint_hit(vaddr_t pc);
void gdbstub_watchpoint_after_access(vaddr_t addr, int len, bool is_write);
bool gdbstub_async_stop_requested(void);

#endif
