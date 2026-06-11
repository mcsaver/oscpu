# RV64 inst/ 下的文件由 ../inst.c 统一 include，保持原有 static inline 热路径和
# 文件级局部状态；这里排除独立编译，避免同一指令实现被链接两次。
SRCS-BLACKLIST-y += $(shell find -L src/isa/riscv64/inst -name "*.c")
