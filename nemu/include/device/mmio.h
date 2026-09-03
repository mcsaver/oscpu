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

#ifndef __DEVICE_MMIO_H__
#define __DEVICE_MMIO_H__

#include <device/map.h>

word_t mmio_read(paddr_t addr, int len);
void mmio_write(paddr_t addr, int len, word_t data);

// 纯查询: 地址区间是否命中某个已注册 MMIO 设备窗口 (无 difftest 副作用)。
// 供 paddr 层的物理地址可访问性预检使用, 以便越界访问抬 guest access-fault 而非 host assert。
bool mmio_is_mapped(paddr_t addr, int len);
IoTransactionStatus mmio_decode_transaction(
    paddr_t addr, int len, bool is_write);

#endif
