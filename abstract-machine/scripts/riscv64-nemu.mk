include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/nemu.mk
CFLAGS  += -DISA_H=\"riscv/riscv.h\"
# NEMU 实现了 B 扩展位操作(Zba/Zbb/Zbc/Zbs, 见 nemu/src/isa/riscv64/inst/bitmanip.c),
# 覆盖 riscv.mk 的基础 rv64g 为含 B 的 march, 让 bitmanip 等位操作测试可编译, 同时保留
# rv64g 的 F/D 浮点; 与 riscv64-npc 的 zba_zbb_zbc_zbs 口径对齐(difftest 两侧一致)。
CFLAGS  += -march=rv64g_zba_zbb_zbc_zbs
ASFLAGS += -march=rv64g_zba_zbb_zbc_zbs

AM_SRCS += riscv/nemu/start.S \
           riscv/nemu/cte.c \
           riscv/nemu/trap.S \
           riscv/nemu/vme.c
