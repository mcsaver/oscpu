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

##COLOR_RED:=...定义一个变量COLOR_RED，内容是ANSI终端的红色高亮控制码
##echo "\033[1;31m" ：输出转义序列\033[1;31m，这是ANSI终端的“高亮红色”前景色，后续可以用$(COLOR_RED)在Makefile的$(warning ...)或者@echo里输出红色警告信息
##echo "\033[0m"：输出转义蓄力\033[0m，用于关闭所有属性（恢复默认颜色）
COLOR_RED := $(shell echo "\033[1;31m")
COLOR_END := $(shell echo "\033[0m")

##如果当前目录下没有有.config配置文件时候，输出警告
ifeq ($(wildcard .config),)
$(warning $(COLOR_RED)Warning: .config does not exist!$(COLOR_END))
$(warning $(COLOR_RED)To build the project, first run 'make menuconfig'.$(COLOR_END))
endif

##定义变量Q，内容为@，用途：在makefile的命令前加入@(Q)，可以让命令执行时不在终端睡出命令本身
Q            := @
##定义变量KCONFIG_PATH，指向NEMU工程下的kconfig目录
KCONFIG_PATH := $(NEMU_HOME)/tools/kconfig
##定义变量FIXDEF_PATH，指向NEMU工程下的fixdep目录，fixdep是一个依赖关系处理工具，用于自动生成和修正依赖文件
FIXDEP_PATH  := $(NEMU_HOME)/tools/fixdep
##定义变量Kconfig，指向主配置文件Kconfig的路径：此文件描述了可配置项和依赖关系，是menuconfig系统的核心入口
Kconfig      := $(NEMU_HOME)/Kconfig
##作用：把这些路径都追加到rm-distclean变量中：rm-distclean用于distclean目标，表示在执行make distance时要删除的文件和目录（如自动生成的配置和缓存文件）
rm-distclean += include/generated include/config .config .config.old
##定义变量silent，内容为-s，-s是GNU Make的静默选项，表示在执行make时不输出命令本身，只输出命令结果，常用于子make调用，减少终端噪音
silent := -s

##定义变量CONF，其值为$(CONFIG_PATH)/build/conf：conf是Kconfig系统的命令行配置工具（用于解析和生成配置文件），KCONFIG_PATH是Kconfig工具目录
##后续在Makefile里用$(CONF)就能调用这个工具
CONF   := $(KCONFIG_PATH)/build/conf
##定义变量MCONF，其值为$(KCONFIG_PATH)/build/mconf：mconf是Kconfig的图形化菜单配置空间，即make menuconfig时弹出的菜单界面
##用途：后续在makefile里用$(MCONF)就能调用这个工具
MCONF  := $(KCONFIG_PATH)/build/mconf
##定义变量FIXDEP，其值为$(FIXDEF_PATH)/build/fixdep
##fixdep是一个依赖关系处理工具，用于自动生成和修正依赖文件（比如头文件依赖）
##用途：makefile里用$(FIXDEP)调用它，保证依赖关系正确
FIXDEP := $(FIXDEP_PATH)/build/fixdep
##以上这三行代码分别为Kconfig系统的命令行配置工具、菜单配置工具和依赖修正工具定义了变量，方便后续在makefile里同一调用
##这样做可以让构建系统更灵活、更容易维护、也方便跨平台和自动化构建

##如果#(CONF)这个文件不存在或者需要更新，就执行后面的命令
##$(Q)是@，让命令执行时不显示命令本身
##$(MAKE)是递归调用make
##(silent)是-s，让子make静默
##-c...表示切换掉KCONFIG_PATH目录下执行make
##NAME=conf传递变量，告诉zimake构建conf这个目标
##效果：在kconfig目录下编译出build/conf这个工具
$(CONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=conf

##如上
$(MCONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=mconf

##如上
$(FIXDEP):
	$(Q)$(MAKE) $(silent) -C $(FIXDEP_PATH)

##menconfig:这是一个makefile目标，表示可以通过make menuconfig命令来触发它
##冒号后是依赖目标，意思是在执行menucong前确保mconf\conf\fixdep这三个工具已经编译好，如果它们不存在，会自动去编译生成
menuconfig: $(MCONF) $(CONF) $(FIXDEP)
	$(Q)$(MCONF) $(Kconfig)
	$(Q)$(CONF) $(silent) --syncconfig $(Kconfig)

savedefconfig: $(CONF)
	$(Q)$< $(silent) --$@=configs/defconfig $(Kconfig)

%defconfig: $(CONF) $(FIXDEP)
	$(Q)$< $(silent) --defconfig=configs/$@ $(Kconfig)
	$(Q)$< $(silent) --syncconfig $(Kconfig)

.PHONY: menuconfig savedefconfig defconfig

# Help text used by make help
help:
	@echo  '  menuconfig	  - Update current config utilising a menu based program'
	@echo  '  savedefconfig   - Save current config as configs/defconfig (minimal config)'

distclean: clean
	-@rm -rf $(rm-distclean)

.PHONY: help distclean

define call_fixdep
	@$(FIXDEP) $(1) $(2) unused > $(1).tmp
	@mv $(1).tmp $(1)
endef
