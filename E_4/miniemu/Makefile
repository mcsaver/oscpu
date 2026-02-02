
NAME = miniemu
SRCS = miniemu.c

ARCH ?= native
export ARCH

include $(AM_HOME)/Makefile

# 指定 C 编译器变量（默认使用 gcc）
CC = gcc
# 指定编译器选项（警告开启）
CFLAGS += -Wall -Wextra -g

HEX ?= hex/sum

%.bin: %.hex
    # 注意这里用 $< 和 $@
	tail -n +2 $< | sed -e 's/.*: //' -e 's/ /\n/g' | sed -e 's/\(..\)\(..\)\(..\)\(..\)/\4 \3 \2 \1/' | xxd -r -p > $@

BIN := $(HEX).bin

.PHONY: all clean miniemu

all: miniemu

miniemu: miniemu.c
	tail -n +2 $(HEX).hex | sed -e 's/.*: //' -e 's/ /\n/g' | sed -e 's/\(..\)\(..\)\(..\)\(..\)/\4 \3 \2 \1/' | xxd -r -p > $(HEX).bin
	$(CC) $(CFLAGS) -o miniemu miniemu.c
	./miniemu $(HEX).bin

runhex: image $(BIN) 
	env mainargs=$(BIN) $(IMAGE).elf

