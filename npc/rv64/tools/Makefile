ENV_ROOT ?= ../env
LOCAL_ELF_TOOLCHAIN := $(abspath $(ENV_ROOT)/toolchains/riscv)
CROSS_COMPILE ?= $(if $(wildcard $(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-gcc),$(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-,riscv64-linux-gnu-)
PYTHON ?= $(if $(wildcard $(ENV_ROOT)/tools/python/bin/python3),$(ENV_ROOT)/tools/python/bin/python3,python3)

CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
DTC ?= dtc
FDTGET ?= fdtget

BUILD_DIR ?= build
PLATFORM_CONFIG ?= ../platform/npc-rv64.yml
GEN_DTS ?= ../platform/gen_dts.py
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
FP_SMOKE_TEXT ?= $(NEXT_ADDR)
FP_SMOKE_STACK ?= 0x87efc000
OPENSBI_FW_JUMP_BIN ?= $(ENV_ROOT)/build/opensbi-npc/platform/generic/firmware/fw_jump.bin
OPENSBI_INITRAMFS_FW_JUMP_BIN ?= $(ENV_ROOT)/build/opensbi-npc-initramfs/platform/generic/firmware/fw_jump.bin
OPENSBI_UBUNTU_INITRAMFS_FW_JUMP_BIN ?= $(ENV_ROOT)/build/opensbi-npc-ubuntu-initramfs/platform/generic/firmware/fw_jump.bin
OPENSBI_ROOTFS_FW_JUMP_BIN ?= $(ENV_ROOT)/build/opensbi-npc-rootfs/platform/generic/firmware/fw_jump.bin
OPENSBI_NEXT_DTB_ADDR ?= 0x82200000
OPENSBI_MAX_CYCLES ?= 5000000
OPENSBI_SBI_MAX_CYCLES ?= 8000000
LINUX_IMAGE ?= $(ENV_ROOT)/src/linux/arch/riscv/boot/Image
LINUX_MAX_CYCLES ?= 20000000
INITRD_IMAGE ?= $(ENV_ROOT)/images/initramfs/rootfs.cpio
INITRD_ADDR ?= 0x84000000
UBUNTU_INITRD_IMAGE ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-probe.cpio
UBUNTU_INITRAMFS_MEMORY_SIZE ?= $(if $(findstring probe,$(notdir $(UBUNTU_INITRD_IMAGE))),0x08000000,0x10000000)
LINUX_INITRAMFS_MAX_CYCLES ?= 100000000
UBUNTU_INITRAMFS_MAX_CYCLES ?= 1200000000
LOG_DIR ?= $(ENV_ROOT)/logs/linux-smoke
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
FP_SMOKE_ELF := $(BUILD_DIR)/fp-loadstore-smoke.elf
FP_SMOKE_BIN := $(BUILD_DIR)/fp-loadstore-smoke.bin
DTB_DTS := $(BUILD_DIR)/generated/npc-rv64.dts
INITRAMFS_DTS := $(BUILD_DIR)/generated/npc-rv64-initramfs.dts
INITRAMFS_DTB := $(BUILD_DIR)/npc-rv64-initramfs.dtb
UBUNTU_INITRAMFS_DTS := $(BUILD_DIR)/generated/npc-rv64-ubuntu-initramfs.dts
UBUNTU_INITRAMFS_DTB := $(BUILD_DIR)/npc-rv64-ubuntu-initramfs.dtb
ROOTFS_DTS := $(BUILD_DIR)/generated/npc-rv64-rootfs.dts
ROOTFS_DTB := $(BUILD_DIR)/npc-rv64-rootfs.dtb

.PHONY: all clean dtb check-dtb initramfs-dtb ubuntu-initramfs-dtb rootfs-dtb \
	smoke-dtb smoke-opensbi smoke-opensbi-sbi smoke-linux-kernel smoke-linux-initramfs \
	smoke-ubuntu-initramfs smoke-fp-loadstore

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

$(DTB_DTS): $(GEN_DTS) $(PLATFORM_CONFIG)
	mkdir -p $(dir $@)
	$(PYTHON) $(GEN_DTS) --config $(PLATFORM_CONFIG) --mode kernel --output $@

$(DTB): $(DTB_DTS)
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

$(INITRAMFS_DTS): $(GEN_DTS) $(PLATFORM_CONFIG) $(INITRD_IMAGE)
	mkdir -p $(dir $@)
	$(PYTHON) $(GEN_DTS) --config $(PLATFORM_CONFIG) --mode initramfs \
	  --initrd-image $(INITRD_IMAGE) --output $@

$(INITRAMFS_DTB): $(INITRAMFS_DTS)
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

$(UBUNTU_INITRAMFS_DTS): $(GEN_DTS) $(PLATFORM_CONFIG) $(UBUNTU_INITRD_IMAGE)
	mkdir -p $(dir $@)
	$(PYTHON) $(GEN_DTS) --config $(PLATFORM_CONFIG) --mode initramfs \
	  --bootargs-key ubuntu_initramfs \
	  --initrd-image $(UBUNTU_INITRD_IMAGE) \
	  --memory-size $(UBUNTU_INITRAMFS_MEMORY_SIZE) --output $@

$(UBUNTU_INITRD_IMAGE): ysyx-ubuntu-init.c ../scripts/build-ubuntu-base-initramfs.sh Makefile
	UBUNTU_INIT_MODE=syscall UBUNTU_INITRAMFS_PROFILE=probe \
	  UBUNTU_INITRD_IMAGE=$(abspath $(UBUNTU_INITRD_IMAGE)) \
	  NPC_RV64_ENV_ROOT=$(abspath $(ENV_ROOT)) \
	  bash ../scripts/build-ubuntu-base-initramfs.sh

$(UBUNTU_INITRAMFS_DTB): $(UBUNTU_INITRAMFS_DTS)
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

$(ROOTFS_DTS): $(GEN_DTS) $(PLATFORM_CONFIG)
	mkdir -p $(dir $@)
	$(PYTHON) $(GEN_DTS) --config $(PLATFORM_CONFIG) --mode rootfs --output $@

$(ROOTFS_DTB): $(ROOTFS_DTS)
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

initramfs-dtb: $(INITRAMFS_DTB)
ubuntu-initramfs-dtb: $(UBUNTU_INITRAMFS_DTB)
rootfs-dtb: $(ROOTFS_DTB)

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

$(FP_SMOKE_ELF): fp-loadstore-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_SMOKE_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_SMOKE_STACK) \
	  $< -o $@

$(FP_SMOKE_BIN): $(FP_SMOKE_ELF)
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

smoke-fp-loadstore: $(FP_SMOKE_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 \
	  -i $(FP_SMOKE_BIN)

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

smoke-linux-initramfs: $(INITRAMFS_DTB)
	test -f $(OPENSBI_INITRAMFS_FW_JUMP_BIN)
	test -f $(LINUX_IMAGE)
	test -f $(INITRD_IMAGE)
	mkdir -p $(LOG_DIR)
	$(NPC_SIM) -b --no-progress --no-diff --max=$(LINUX_INITRAMFS_MAX_CYCLES) \
	  --log=$(LOG_DIR)/npc-linux-initramfs.log \
	  -i $(OPENSBI_INITRAMFS_FW_JUMP_BIN) \
	  --load=$(NEXT_ADDR):$(LINUX_IMAGE) \
	  --load=$(OPENSBI_NEXT_DTB_ADDR):$(INITRAMFS_DTB) \
	  --load=$(INITRD_ADDR):$(INITRD_IMAGE)

smoke-ubuntu-initramfs: $(UBUNTU_INITRAMFS_DTB)
	test -f $(OPENSBI_UBUNTU_INITRAMFS_FW_JUMP_BIN)
	test -f $(LINUX_IMAGE)
	test -f $(UBUNTU_INITRD_IMAGE)
	mkdir -p $(LOG_DIR)
	$(NPC_SIM) -b --no-progress --no-diff --max=$(UBUNTU_INITRAMFS_MAX_CYCLES) \
	  --log=$(LOG_DIR)/npc-ubuntu-initramfs.log \
	  -i $(OPENSBI_UBUNTU_INITRAMFS_FW_JUMP_BIN) \
	  --load=$(NEXT_ADDR):$(LINUX_IMAGE) \
	  --load=$(OPENSBI_NEXT_DTB_ADDR):$(UBUNTU_INITRAMFS_DTB) \
	  --load=$(INITRD_ADDR):$(UBUNTU_INITRD_IMAGE)

clean:
	rm -rf $(BUILD_DIR)
