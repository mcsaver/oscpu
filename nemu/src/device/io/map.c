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
#include <memory/host.h>
#include <memory/vaddr.h>
#include <device/map.h>

//为什么读回调在前面，写回调在后
//读操作时，先回调，再读内存
//1.因为很多设备寄存器的值不是一直提前写好了
//2.例如定时器寄存器，读之前可能要先“现算”当前时间并写进寄存器缓存，所以回调负责“准备好将要被读出的值”
//写操作时，先写内存，再回调
//1.因为很多设备逻辑希望先看到寄存器已经被更新，再根据新值触发副作用
//2.例如串口控制器被写后，回调再决定是否发送字符或更新状态，这也是注释里那句prepare data to read的真实含义

#define IO_SPACE_MAX (32 * 1024 * 1024)

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;

uint8_t* new_space(int size) {
  uint8_t *p = p_space;
  // page aligned;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p;
}

static void invoke_callback(io_callback_t c, paddr_t offset, int len, bool is_write) {
  if (c != NULL) { c(offset, len, is_write); }
}

static uint8_t io_width_mask(int len) {
  switch (len) {
    case 1: return IO_WIDTH_1;
    case 2: return IO_WIDTH_2;
    case 4: return IO_WIDTH_4;
    case 8: return IO_WIDTH_8;
    default: return 0;
  }
}

IoTransactionStatus map_decode_transaction(
    const IOMap *map, paddr_t addr, int len, bool is_write,
    IoTransaction *transaction) {
  uint8_t width_mask = io_width_mask(len);
  if (width_mask == 0) return IO_TRANSACTION_INVALID_WIDTH;
  if (!map_span_inside(map, addr, (uint64_t)len)) {
    return IO_TRANSACTION_OUTSIDE_REGION;
  }

  IoTransaction decoded = {
    .addr = addr,
    .offset = (uint32_t)(addr - map->low),
    .width = (uint8_t)len,
    .direction = is_write ? IO_TRANSACTION_WRITE : IO_TRANSACTION_READ,
  };
  if (transaction != NULL) *transaction = decoded;
  if (map->policy == NULL) return IO_TRANSACTION_ACCEPTED;

  IoTransactionStatus rejected = IO_TRANSACTION_UNKNOWN_REGISTER;
  for (const IoAccessPolicy *policy = map->policy;
       policy != NULL; policy = policy->parent) {
    for (uint32_t i = 0; i < policy->register_count; i++) {
      const IoRegisterDescriptor *reg = &policy->registers[i];
      if (decoded.offset < reg->first_offset ||
          decoded.offset > reg->last_offset) {
        continue;
      }
      if (reg->stride == 0 ||
          (decoded.offset - reg->first_offset) % reg->stride != 0) {
        rejected = reg->naturally_aligned &&
            (((uint64_t)addr & ((uint64_t)len - 1u)) != 0)
            ? IO_TRANSACTION_MISALIGNED
            : IO_TRANSACTION_OUTSIDE_REGISTER;
        continue;
      }
      uint64_t register_room =
          (uint64_t)reg->last_offset - decoded.offset + 1u;
      if ((uint64_t)len > register_room) {
        rejected = IO_TRANSACTION_OUTSIDE_REGISTER;
        continue;
      }
      if ((reg->width_mask & width_mask) == 0) {
        rejected = IO_TRANSACTION_INVALID_WIDTH;
        continue;
      }
      if (reg->naturally_aligned &&
          ((uint64_t)addr & ((uint64_t)len - 1u)) != 0) {
        rejected = IO_TRANSACTION_MISALIGNED;
        continue;
      }
      if ((reg->direction_mask & decoded.direction) == 0) {
        rejected = IO_TRANSACTION_DIRECTION_DENIED;
        continue;
      }
      return IO_TRANSACTION_ACCEPTED;
    }
  }
  return rejected;
}

void init_map() {
  io_space = malloc(IO_SPACE_MAX);
  assert(io_space);
  p_space = io_space;
}

word_t map_read(paddr_t addr, int len, IOMap *map) {
  /* Guest-controlled invalid spans must not reach callback/backing storage. */
  IoTransaction transaction;
  if (map_decode_transaction(
          map, addr, len, false, &transaction) != IO_TRANSACTION_ACCEPTED) {
    return 0;
  }
  paddr_t offset = transaction.offset;
  invoke_callback(map->callback, offset, len, false); // prepare data to read
  word_t ret = host_read((uint8_t *)map->space + offset, len);
  return ret;
}

void map_write(paddr_t addr, int len, word_t data, IOMap *map) {
  /* Reject cross-region/overflowing spans before touching device storage. */
  IoTransaction transaction;
  if (map_decode_transaction(
          map, addr, len, true, &transaction) != IO_TRANSACTION_ACCEPTED) {
    return;
  }
  paddr_t offset = transaction.offset;
  host_write((uint8_t *)map->space + offset, len, data);
  invoke_callback(map->callback, offset, len, true);
}
