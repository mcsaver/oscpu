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

//定义虚拟地址层（vaddr）对外接口，供cpu/取值与数据访问调用

#ifndef __MEMORY_VADDR_H__
#define __MEMORY_VADDR_H__

#include <common.h>
//指令抓取
word_t vaddr_ifetch(vaddr_t addr, int len);
// performance 模式下的 RVC 宽取指快路径；不能命中时返回 false 让 ISA 层走旧精确路径。
bool vaddr_ifetch_wide(vaddr_t addr, uint32_t *inst, int *len);
//从虚拟地址读数据
word_t vaddr_read(vaddr_t addr, int len);
//写数据
void vaddr_write(vaddr_t addr, int len, word_t data);
bool vaddr_has_fault(void);
void vaddr_set_fault(word_t cause, vaddr_t tval);
bool vaddr_take_fault(word_t *cause, vaddr_t *tval);

//定义分页常量，方便后续实现页表/分页时使用
#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)

#endif
