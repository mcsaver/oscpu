#默认目标 直接运行make会构建app
.DEFAULT_GOAL = app

# Add necessary options if the target is a shared library
#支持构建可选的共享库：若传入SHARE=1，会设置SO=-so、增加-fPIC/-shared等编译/链接选项
ifeq ($(SHARE),1)
SO = -so
CFLAGS  += -fPIC -fvisibility=hidden
LDFLAGS += -shared -fPIC
endif

#工作和输出目录，shell pwd即当前运行make时的目录
WORK_DIR  = $(shell pwd)
#所有构建都放在build子目录下
BUILD_DIR = $(WORK_DIR)/build

#头文件搜索路径
#把项目的include目录放在搜索路径前面（保留外部传入的INC_PATH)
INC_PATH := $(WORK_DIR)/include $(INC_PATH)
#把中间目标（.o/.d）放在以NAME命名的obj子目录下，若SHARE则后缀有SO
OBJ_DIR  = $(BUILD_DIR)/obj-$(NAME)$(SO)
#最终生成的可执行/库文件路径
BINARY   = $(BUILD_DIR)/$(NAME)$(SO)

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

#把源文件列表SRCS/CXXSRC映射到OBJ_DIR下对应.o路径（相对目录结构保留）
#把SRCS中每个以.c结尾的项，移除.c，取出中间的stem（%），再前面加上$(OBJ_DIR)/，并在末尾加上.o
OBJS = $(SRCS:%.c=$(OBJ_DIR)/%.o) $(CXXSRC:%.cc=$(OBJ_DIR)/%.o)

# Compilation patterns
#打印编译日志
#确保输出目录存在（对并行构建安全）
#调用编译器生成.o
#调用项目的make函数修正/生成依赖（.d），配合-MMD使用
$(OBJ_DIR)/%.o: %.c
	@echo + CC $<
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -c -o $@ $<
	$(call call_fixdep, $(@:.o=.d), $@)

$(OBJ_DIR)/%.o: %.cc
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -c -o $@ $<
	$(call call_fixdep, $(@:.o=.d), $@)

# Depencies
#把所有.d依赖文件包含进来（使用-include可容忍某些.d缺失，便于首次构建）
-include $(OBJS:.o=.d)

# Some convenient rules
#伪目标，声明避免冲突
.PHONY: app clean
#直接依赖最终可执行库
app: $(BINARY)

#链接规则：双冒号规则允许存在多条独立规则，链接命令ld把所有对象文件、归档库与额外LIBS链接成最终目标
$(BINARY):: $(OBJS) $(ARCHIVES)
	@echo + LD $@
	@$(LD) -o $@ $(OBJS) $(LDFLAGS) $(ARCHIVES) $(LIBS)

clean:
	-rm -rf $(BUILD_DIR)
