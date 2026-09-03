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

#include "local-include/reg.h"
#include "local-include/privileged.h"
#include "local-include/instruction.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>
#include <memory/cache.h>
#include <memory/vaddr.h>
#include <ftrace.h>
#include <etrace.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

/*
 * RV64 指令实现按功能拆到 inst/ 目录。这里保留 unity translation unit，
 * 让原有 static inline 热路径和文件级局部状态不跨编译单元泄漏，同时让调试行号
 * 落到更小的功能文件中，后续排查指令问题时可以直接按扩展定位。
 */
#include "inst/common.c"
#include "inst/csr.c"
#include "inst/fp.c"
#include "inst/muldiv.c"
#include "inst/amo.c"
#include "inst/bitmanip.c"
#include "inst/compressed.c"
#include "inst/execute.c"
#include "inst/decode_cache.c"
#include "inst/decode.c"
