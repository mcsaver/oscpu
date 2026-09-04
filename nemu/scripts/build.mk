#默认目标 直接运行make会构建app
.DEFAULT_GOAL = app

# Add necessary options if the target is a shared library
#支持构建可选的共享库：若传入SHARE=1，会设置SO=-so、增加-fPIC/-shared等编译/链接选项
ifeq ($(SHARE),1)
SO = -so
CFLAGS  += -fPIC -fvisibility=hidden -DCONFIG_TARGET_SHARE
LDFLAGS += -shared -fPIC
endif

#工作和输出目录，shell pwd即当前运行make时的目录
WORK_DIR  = $(shell pwd)
#所有构建都放在build子目录下
BUILD_DIR = $(WORK_DIR)/build

#头文件搜索路径
#把项目的include目录放在搜索路径前面（保留外部传入的INC_PATH)
INC_PATH := $(NEMU_CONFIG_DIR)/include $(WORK_DIR)/include $(INC_PATH)
# Compilation flags
#若指定CC=clang，则使用clang++作为C++链接器/编译器，否则用g++
ifeq ($(CC),clang)
CXX := clang++
else
CXX := g++
endif
#链接器使用	C++编译器（确保正确链接C++标准库）
LD := $(CXX)
#把INC_PATH转换为-I/path的形式供编译器使用
INCLUDES = $(addprefix -I, $(INC_PATH))
#CFLAGS/LDFLAGS基础设置
#-O2优化；-MMD在编译时生成依赖文件（.d）；-Wall -Werror打开警告并当作错误；包含INCLUDES；允许外部追加CFLAGS
#
#注意，此处可以自行添加了-G作为gdb调试用
#
CFLAGS  := -O2 -MMD -Wall -Werror  $(INCLUDES) $(CFLAGS)
#链接器标志可被外部追击到
LDFLAGS := -O2 $(LDFLAGS)

# Object files are namespaced by the complete effective build profile.  Merely
# depending on split Kconfig markers is insufficient: switching NEMU_CONFIG_DIR
# in an existing BUILD_DIR used to retain objects compiled with the previous
# profile, and compiler-only options need not appear in fixdep output at all.
# A private manifest is written with GNU make's file function, not a generated
# shell command.  Consequently quotes, dollars and other compiler-flag bytes
# remain plain data.  `export` alone cannot be used here: variables exported by
# this makefile are not visible to a `shell` expansion in the same parse pass.
NEMU_BUILD_PROFILE_MANIFEST := $(shell mktemp /tmp/nemu-build-profile.XXXXXXXX)
ifeq ($(strip $(NEMU_BUILD_PROFILE_MANIFEST)),)
  $(error failed to allocate the NEMU build profile manifest)
endif
$(file >$(NEMU_BUILD_PROFILE_MANIFEST),nemu-build-profile-v2)
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CONFIG_DIR=$(NEMU_CONFIG_DIR_REAL))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),NAME=$(NAME))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),SO=$(SO))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),SHARE=$(SHARE))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CC=$(CC))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CXX=$(CXX))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CFLAGS=$(CFLAGS))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CXXFLAGS=$(CXXFLAGS))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),LDFLAGS=$(LDFLAGS))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),SRCS=$(sort $(SRCS)))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),CXXSRC=$(sort $(CXXSRC)))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),ARCHIVES=$(ARCHIVES))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),LIBS=$(LIBS))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),-- dot-config --)
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),$(if $(wildcard $(NEMU_DOT_CONFIG)),$(file <$(NEMU_DOT_CONFIG)),missing))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),-- auto-config --)
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),$(if $(wildcard $(NEMU_AUTOCONFIG)),$(file <$(NEMU_AUTOCONFIG)),missing))
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),-- auto-header --)
$(file >>$(NEMU_BUILD_PROFILE_MANIFEST),$(if $(wildcard $(NEMU_AUTOHEADER)),$(file <$(NEMU_AUTOHEADER)),missing))
NEMU_BUILD_PROFILE_ID := $(shell bash $(NEMU_HOME)/scripts/build-profile-id.sh $(NEMU_BUILD_PROFILE_MANIFEST))
NEMU_BUILD_PROFILE_MANIFEST_CLEANED := $(shell rm -f -- $(NEMU_BUILD_PROFILE_MANIFEST))
ifeq ($(strip $(NEMU_BUILD_PROFILE_ID)),)
  $(error failed to compute the NEMU build profile identity)
endif
ifneq ($(words $(NEMU_BUILD_PROFILE_ID)),1)
  $(error invalid NEMU build profile identity: $(NEMU_BUILD_PROFILE_ID))
endif

#把中间目标（.o/.d）放在以完整构建配置命名的obj子目录下
OBJ_DIR  = $(BUILD_DIR)/obj-$(NAME)$(SO)-$(NEMU_BUILD_PROFILE_ID)
#最终生成的可执行/库文件路径保持稳定，供上层启动脚本使用
BINARY   = $(BUILD_DIR)/$(NAME)$(SO)

#把源文件列表SRCS/CXXSRC映射到OBJ_DIR下对应.o路径（相对目录结构保留）
#把SRCS中每个以.c结尾的项，移除.c，取出中间的stem（%），再前面加上$(OBJ_DIR)/，并在末尾加上.o
OBJS = $(SRCS:%.c=$(OBJ_DIR)/%.o) $(CXXSRC:%.cc=$(OBJ_DIR)/%.o)
# The outer make owns no mutable build rule.  It takes one stable lock and
# re-enters make for the complete object/link transaction.  This prevents two
# processes using the same BUILD_DIR (including different profiles) from both
# compiling or publishing the stable BINARY path at once.  The sibling lock is
# deliberately outside BUILD_DIR so `clean` cannot replace its inode.
ifeq ($(NEMU_BUILD_LOCK_HELD),1)

# Compilation patterns
#打印编译日志
#确保输出目录存在（对并行构建安全）
#调用编译器生成.o
#调用项目的make函数修正/生成依赖（.d），配合-MMD使用
$(OBJ_DIR)/%.o: %.c $(FIXDEP)
	@echo + CC $<
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -c -o $@ $<
	$(call call_fixdep, $(@:.o=.d), $@)

$(OBJ_DIR)/%.o: %.cc $(FIXDEP)
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -c -o $@ $<
	$(call call_fixdep, $(@:.o=.d), $@)

# Depencies
#把所有.d依赖文件包含进来（使用-include可容忍某些.d缺失，便于首次构建）
-include $(OBJS:.o=.d)

#链接规则：双冒号规则允许存在多条独立规则，链接命令ld把所有对象文件、归档库与额外LIBS链接成最终目标
# The public binary path intentionally stays stable.  Relink on every explicit
# build so switching back to an older, cached object namespace cannot leave the
# binary from the most recently selected *other* profile in place.
$(BINARY):: $(OBJS) $(ARCHIVES) FORCE_LINK
	@echo + LD $@
	@$(LD) -o $@ $(OBJS) $(LDFLAGS) $(ARCHIVES) $(LIBS)

clean:
	-rm -rf $(BUILD_DIR)
else
.PHONY: FORCE_LOCKED_BUILD

$(BINARY):: FORCE_LOCKED_BUILD
	@mkdir -p $(dir $(NEMU_BUILD_LOCK)) $(dir $(KCONFIG_LOCK))
	@python3 "$(NEMU_SAFE_FLOCK)" \
	  "$(NEMU_BUILD_LOCK)" "$(KCONFIG_LOCK)" -- \
	  $(MAKE) --no-print-directory NEMU_BUILD_LOCK_HELD=1 \
	    NEMU_OUTER_CONFIG_PARSE_ID="$(NEMU_CONFIG_PARSE_ID)" app

clean:
	@mkdir -p $(dir $(NEMU_BUILD_LOCK)) $(dir $(KCONFIG_LOCK))
	@python3 "$(NEMU_SAFE_FLOCK)" \
	  "$(NEMU_BUILD_LOCK)" "$(KCONFIG_LOCK)" -- \
	  $(MAKE) --no-print-directory NEMU_BUILD_LOCK_HELD=1 \
	    NEMU_OUTER_CONFIG_PARSE_ID="$(NEMU_CONFIG_PARSE_ID)" clean
endif

# Some convenient rules
#伪目标，声明避免冲突
.PHONY: app clean FORCE_LINK
#直接依赖最终可执行库
app: $(BINARY)
