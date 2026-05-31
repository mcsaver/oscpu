CROSS_COMPILE ?= $(if $(wildcard /home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-gcc),/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-,riscv64-linux-gnu-)

CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
DTC ?= dtc
FDTGET ?= fdtget

BUILD_DIR ?= build
TRAMPOLINE_TEXT ?= 0x80000000
BOOT_HARTID ?= 0
NEXT_ADDR ?= 0x80200000
DTB_ADDR ?= 0x87f00000
DTB_SMOKE_TEXT ?= $(NEXT_ADDR)
DTB_SMOKE_STACK ?= 0x87eff000
MINI_LINUX_TEXT ?= $(NEXT_ADDR)
MINI_LINUX_STACK ?= 0x87efe000
MINI_LINUX_UART ?= 0x10000000
OPENSBI_SBI_TEXT ?= $(NEXT_ADDR)
OPENSBI_SBI_STACK ?= 0x87efd000
OPENSBI_FW_JUMP_BIN ?= /tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin
OPENSBI_NEXT_DTB_ADDR ?= 0x82200000
OPENSBI_MAX_CYCLES ?= 5000000
OPENSBI_SBI_MAX_CYCLES ?= 8000000
LINUX_IMAGE ?= /tmp/ysyx-rv64-linux/root/boot/vmlinux-6.12.90+deb13-riscv64
LINUX_MAX_CYCLES ?= 20000000
NPC_SIM ?= ../build/NpcSimTop

TRAMPOLINE_BIN := $(BUILD_DIR)/linux-boot-trampoline.bin
TRAMPOLINE_ELF := $(BUILD_DIR)/linux-boot-trampoline.elf
DTB := $(BUILD_DIR)/npc-rv64.dtb
DTB_SMOKE_ELF := $(BUILD_DIR)/linux-dtb-smoke.elf
DTB_SMOKE_BIN := $(BUILD_DIR)/linux-dtb-smoke.bin
MINI_LINUX_ELF := $(BUILD_DIR)/mini-linux-payload.elf
MINI_LINUX_BIN := $(BUILD_DIR)/mini-linux-payload.bin
OPENSBI_SBI_ELF := $(BUILD_DIR)/opensbi-sbi-payload.elf
OPENSBI_SBI_BIN := $(BUILD_DIR)/opensbi-sbi-payload.bin

.PHONY: all clean dtb check-dtb smoke-dtb smoke-opensbi smoke-opensbi-sbi smoke-linux-kernel

all: $(TRAMPOLINE_BIN) $(DTB)

$(TRAMPOLINE_ELF): linux-boot-trampoline.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imac_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(TRAMPOLINE_TEXT) \
	  -Wl,--no-relax \
	  -DBOOT_HARTID=$(BOOT_HARTID) -DNEXT_ADDR=$(NEXT_ADDR) -DDTB_ADDR=$(DTB_ADDR) \
	  $< -o $@

$(TRAMPOLINE_BIN): $(TRAMPOLINE_ELF)
	$(OBJCOPY) -O binary $< $@

dtb: $(DTB)

$(DTB): npc-rv64.dts Makefile
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

$(DTB_SMOKE_ELF): linux-dtb-smoke.c Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -O2 -ffreestanding -fno-builtin -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
	  -DDTB_SMOKE_STACK=$(DTB_SMOKE_STACK) \
	  -Wl,-Ttext=$(DTB_SMOKE_TEXT) \
	  -Wl,-e,_start -Wl,--no-relax \
	  $< -o $@

$(DTB_SMOKE_BIN): $(DTB_SMOKE_ELF)
	$(OBJCOPY) -O binary $< $@

$(MINI_LINUX_ELF): mini-linux-payload.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(MINI_LINUX_TEXT) \
	  -Wl,--no-relax \
	  -DMINI_LINUX_STACK=$(MINI_LINUX_STACK) -DMINI_LINUX_UART=$(MINI_LINUX_UART) \
	  $< -o $@

$(MINI_LINUX_BIN): $(MINI_LINUX_ELF)
	$(OBJCOPY) -O binary $< $@

$(OPENSBI_SBI_ELF): opensbi-sbi-payload.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(OPENSBI_SBI_TEXT) \
	  -Wl,--no-relax \
	  -DOPENSBI_SBI_STACK=$(OPENSBI_SBI_STACK) \
	  $< -o $@

$(OPENSBI_SBI_BIN): $(OPENSBI_SBI_ELF)
	$(OBJCOPY) -O binary $< $@

check-dtb: $(DTB)
	$(FDTGET) $(DTB) / model
	$(FDTGET) $(DTB) /chosen stdout-path
	$(FDTGET) $(DTB) /cpus/cpu@0 mmu-type
	$(FDTGET) $(DTB) /soc/serial@10000000 compatible

smoke-dtb: $(TRAMPOLINE_BIN) $(DTB) $(DTB_SMOKE_BIN)
	$(NPC_SIM) \
	  --load=$(TRAMPOLINE_TEXT):$(TRAMPOLINE_BIN) \
	  --load=$(NEXT_ADDR):$(DTB_SMOKE_BIN) \
	  --load=$(DTB_ADDR):$(DTB) \
	  --no-diff --no-progress --max=2000000

smoke-opensbi: $(DTB) $(MINI_LINUX_BIN)
	test -f $(OPENSBI_FW_JUMP_BIN)
	$(NPC_SIM) -b --no-progress --max=$(OPENSBI_MAX_CYCLES) \
	  -i $(OPENSBI_FW_JUMP_BIN) \
	  --load=$(NEXT_ADDR):$(MINI_LINUX_BIN) \
	  --load=$(OPENSBI_NEXT_DTB_ADDR):$(DTB)

smoke-opensbi-sbi: $(DTB) $(OPENSBI_SBI_BIN)
	test -f $(OPENSBI_FW_JUMP_BIN)
	$(NPC_SIM) -b --no-progress --max=$(OPENSBI_SBI_MAX_CYCLES) \
	  -i $(OPENSBI_FW_JUMP_BIN) \
	  --load=$(NEXT_ADDR):$(OPENSBI_SBI_BIN) \
	  --load=$(OPENSBI_NEXT_DTB_ADDR):$(DTB)

smoke-linux-kernel: $(DTB)
	test -f $(OPENSBI_FW_JUMP_BIN)
	test -f $(LINUX_IMAGE)
	$(NPC_SIM) -b --no-progress --max=$(LINUX_MAX_CYCLES) \
	  -i $(OPENSBI_FW_JUMP_BIN) \
	  --load=$(NEXT_ADDR):$(LINUX_IMAGE) \
	  --load=$(OPENSBI_NEXT_DTB_ADDR):$(DTB)

clean:
	rm -rf $(BUILD_DIR)
