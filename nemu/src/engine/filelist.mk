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

##INC_PATH通常用于收集所有需要加入编译器-I选项的头文件搜索路径
##ENGINE是当前配置执行的引擎名，确保编译时能找到对应引擎目录下的头文件
##DIRS-y把src/engine/$(ENGINE)是当前配置的执行引擎名(如interpreter、difftest等)，由Kconfig系统自动设置
##效果：确保编译的时候能找到对应引擎目录下的头文件
INC_PATH += $(NEMU_HOME)/src/engine/$(ENGINE)
DIRS-y += src/engine/$(ENGINE)
