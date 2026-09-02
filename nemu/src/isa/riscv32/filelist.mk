# RV32 inst/ 由 ../inst.c 统一包含，以便旧 static helper 只在兼容边界内可见。
SRCS-BLACKLIST-y += $(shell find -L src/isa/riscv32/inst -name "*.c")
