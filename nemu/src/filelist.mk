#***************************************************************************************
# Copyright (c) 2014-2024 Zihao Yu, Nanjing University
#
# NEMU is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
#**************************************************************************************/

#把src/nemu-main.c添加到SRCS-y变量中
SRCS-y += src/nemu-main.c
#把这些子目录加入DIRS-y,表示需要递归进入这些目录构建
DIRS-y += src/cpu src/monitor src/utils
#表示CONFIG_MODE_SYSTEM作为条件化变量拓展，当该值为y的时候（或者其他非空值），会最终影响DIRC-的处理
DIRS-$(CONFIG_MODE_SYSTEM) += src/memory
#黑名单，针对某个目标（CONFIG_TARGET_AM）把src/monitor/sdb从要进入构建的目录中排除
DIRS-BLACKLIST-$(CONFIG_TARGET_AM) += src/monitor/sdb

#如果CONFIG_TARGET_SHARE非空，则SHARE=1，否则=0，等价开关变量初始化
SHARE = $(if $(CONFIG_TARGET_SHARE),1,0)
#如果CONFIG_TARGET_NATIVE_ELF启用，则向LIBS添加链接库 -lreadlin -ldl -pie，否则不添加
LIBS += $(if $(CONFIG_TARGET_NATIVE_ELF),-lreadline -ldl -pie,)

#如果在make环境中传入了mainargs，则在汇编/编译标志ASFLAGS中添加一个预处理定义-DBIN_PATH=\"$(mainars)\"，常用于把运行时二进制的路径写入目标
ifdef mainargs
ASFLAGS += -DBIN_PATH=\"$(mainargs)\"
endif
#条件把汇编文件src/am-bin.s加入到SRCS-<value>，即只在CONFIG_TARGET_AM开启时才会纳入构建
SRCS-$(CONFIG_TARGET_AM) += src/am-bin.S
#把src/am-bin.s标记为伪目标，意味着即使文件存在也要强制执行对应规则，确保某个生成步骤（如把二进制转换成汇编）每次都会运行，而不是被文件时间戳跳过
.PHONY: src/am-bin.S
