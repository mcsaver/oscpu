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
//提供对host内存指针的按宽度读写内联函数（直接访问NEMU进程的内存表示），被paddr层用于对pmem的访问

#ifndef __MEMORY_HOST_H__
#define __MEMORY_HOST_H__

#include <common.h>
#include <string.h>

// 根据 len(1/2/4/8) 做小端读写；使用 memcpy 避免 uint8_t pmem 上的未对齐/strict-aliasing UB。
static inline word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: {
      uint8_t ret = 0;
      memcpy(&ret, addr, sizeof(ret));
      return ret;
    }
    case 2: {
      uint16_t ret = 0;
      memcpy(&ret, addr, sizeof(ret));
      return ret;
    }
    case 4: {
      uint32_t ret = 0;
      memcpy(&ret, addr, sizeof(ret));
      return ret;
    }
    IFDEF(CONFIG_ISA64, case 8: {
      uint64_t ret = 0;
      memcpy(&ret, addr, sizeof(ret));
      return ret;
    });
    default: MUXDEF(CONFIG_RT_CHECK, assert(0), return 0);
  }
}

// 对应的写入。
static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: {
      uint8_t value = data;
      memcpy(addr, &value, sizeof(value));
      return;
    }
    case 2: {
      uint16_t value = data;
      memcpy(addr, &value, sizeof(value));
      return;
    }
    case 4: {
      uint32_t value = data;
      memcpy(addr, &value, sizeof(value));
      return;
    }
    IFDEF(CONFIG_ISA64, case 8: {
      uint64_t value = data;
      memcpy(addr, &value, sizeof(value));
      return;
    });
    IFDEF(CONFIG_RT_CHECK, default: assert(0));
  }
}

#endif
