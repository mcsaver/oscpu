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

#ifndef __QMP_H__
#define __QMP_H__

#include <common.h>

void qmp_set_port(int port);
bool qmp_is_enabled(void);
extern bool qmp_runtime_enabled;

static inline bool qmp_fast_enabled(void) {
#ifndef CONFIG_TARGET_AM
  return unlikely(qmp_runtime_enabled);
#else
  return false;
#endif
}

const char *qmp_capability(void);
bool qmp_wait_for_client_if_enabled(void);
void qmp_cpu_pause_point(void);
void qmp_notify_shutdown_event(void);

#endif
