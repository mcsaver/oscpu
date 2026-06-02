# RV64 Linux bring-up focused tool tests.
#
# 这些小型裸机 smoke 用于支撑 Linux/Ubuntu bring-up 的 ISA、
# privilege、control-flow 和 rv64gc 用户态边界定位。

ENV_ROOT ?= ../env
LOCAL_ELF_TOOLCHAIN := $(abspath $(ENV_ROOT)/toolchains/riscv)
CROSS_COMPILE ?= $(if $(wildcard $(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-gcc),$(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-,riscv64-linux-gnu-)

CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
DTC ?= dtc
FDTGET ?= fdtget
BUILD_DIR ?= build
NPC_SIM ?= ../../npc/rv64/build/NpcSimTop
PYTHON ?= $(if $(wildcard $(ENV_ROOT)/tools/python/bin/python3),$(ENV_ROOT)/tools/python/bin/python3,python3)
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
VIRTIO_BLK_TEXT ?= 0x80000000
VIRTIO_BLK_STACK ?= 0x87ef2000
VIRTIO_BLK_IMAGE ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64.ext4
VIRTIO_BLK_MAX_CYCLES ?= 2000000
FP_SMOKE_TEXT ?= 0x80200000
FP_SMOKE_STACK ?= 0x87efc000
JAL_LINK_TEXT ?= 0x80000000
JAL_LINK_STACK ?= 0x87ef9000
BRANCH_RAW_TEXT ?= 0x80000000
BRANCH_RAW_STACK ?= 0x87ef8000
SRET_USER_TEXT ?= 0x80000000
SRET_USER_STACK ?= 0x87ef7000
SRET_USER_PF_TEXT ?= 0x80000000
SRET_USER_PF_STACK ?= 0x87ef6000
SRET_USER_PF_ROOT ?= 0x80004000
SRET_USER_PF_VA ?= 0x0000000040000000
SRET_USER_SV39_TEXT ?= 0x80000000
SRET_USER_SV39_STACK ?= 0x87ef4000
SRET_USER_SV39_ROOT ?= 0x80004000
SRET_USER_SV39_L1 ?= 0x80005000
SRET_USER_SV39_L0 ?= 0x80006000
SRET_USER_SV39_UVA ?= 0x0000003fb6410002
SRET_USER_SV39_HALF_TEXT ?= 0x80000000
SRET_USER_SV39_HALF_STACK ?= 0x87ef1000
SRET_USER_SV39_HALF_ROOT ?= 0x80004000
SRET_USER_SV39_HALF_L1 ?= 0x80005000
SRET_USER_SV39_HALF_L0 ?= 0x80006000
SRET_USER_SV39_HALF_UVA ?= 0x0000003fa2184ffe
SRET_RESTORE_TEXT ?= 0x80000000
SRET_RESTORE_STACK ?= 0x87ef3000
SRET_RESTORE_ROOT ?= 0x80004000
SRET_RESTORE_L1 ?= 0x80005000
SRET_RESTORE_L0 ?= 0x80006000
SRET_RESTORE_FRAME ?= 0x80000800
SRET_RESTORE_THREAD ?= 0x80000c00
SRET_RESTORE_UVA ?= 0x0000003fb6410002
RAS_TRAP_TEXT ?= 0x80000000
RAS_TRAP_STACK ?= 0x87ef5000
FP_FMV_FCLASS_TEXT ?= $(FP_SMOKE_TEXT)
FP_FMV_FCLASS_STACK ?= 0x87efb000
FP_CONVERT_TEXT ?= $(FP_SMOKE_TEXT)
FP_CONVERT_STACK ?= 0x87efa000
OPENSBI_FW_JUMP_BIN ?= $(ENV_ROOT)/build/opensbi-npc/platform/generic/firmware/fw_jump.bin
OPENSBI_NEXT_DTB_ADDR ?= 0x82200000
OPENSBI_MAX_CYCLES ?= 5000000
OPENSBI_SBI_MAX_CYCLES ?= 8000000

TRAMPOLINE_ELF := $(BUILD_DIR)/linux-boot-trampoline.elf
TRAMPOLINE_BIN := $(BUILD_DIR)/linux-boot-trampoline.bin
DTB := $(BUILD_DIR)/npc-rv64.dtb
DTB_DTS := $(BUILD_DIR)/generated/npc-rv64.dts
DTB_SMOKE_ELF := $(BUILD_DIR)/linux-dtb-smoke.elf
DTB_SMOKE_BIN := $(BUILD_DIR)/linux-dtb-smoke.bin
MINI_LINUX_ELF := $(BUILD_DIR)/mini-linux-payload.elf
MINI_LINUX_BIN := $(BUILD_DIR)/mini-linux-payload.bin
OPENSBI_SBI_ELF := $(BUILD_DIR)/opensbi-sbi-payload.elf
OPENSBI_SBI_BIN := $(BUILD_DIR)/opensbi-sbi-payload.bin
VIRTIO_BLK_ELF := $(BUILD_DIR)/virtio-blk-smoke.elf
VIRTIO_BLK_BIN := $(BUILD_DIR)/virtio-blk-smoke.bin
FP_SMOKE_ELF := $(BUILD_DIR)/fp-loadstore-smoke.elf
FP_SMOKE_BIN := $(BUILD_DIR)/fp-loadstore-smoke.bin
JAL_LINK_ELF := $(BUILD_DIR)/jal-link-smoke.elf
JAL_LINK_BIN := $(BUILD_DIR)/jal-link-smoke.bin
BRANCH_RAW_ELF := $(BUILD_DIR)/branch-raw-smoke.elf
BRANCH_RAW_BIN := $(BUILD_DIR)/branch-raw-smoke.bin
SRET_USER_ELF := $(BUILD_DIR)/sret-user-smoke.elf
SRET_USER_BIN := $(BUILD_DIR)/sret-user-smoke.bin
SRET_USER_PF_ELF := $(BUILD_DIR)/sret-user-pagefault-smoke.elf
SRET_USER_PF_BIN := $(BUILD_DIR)/sret-user-pagefault-smoke.bin
SRET_USER_SV39_ELF := $(BUILD_DIR)/sret-user-sv39-smoke.elf
SRET_USER_SV39_BIN := $(BUILD_DIR)/sret-user-sv39-smoke.bin
SRET_USER_SV39_HALF_ELF := $(BUILD_DIR)/sret-user-sv39-halfword-smoke.elf
SRET_USER_SV39_HALF_BIN := $(BUILD_DIR)/sret-user-sv39-halfword-smoke.bin
SRET_RESTORE_ELF := $(BUILD_DIR)/sret-restore-smoke.elf
SRET_RESTORE_BIN := $(BUILD_DIR)/sret-restore-smoke.bin
RAS_TRAP_ELF := $(BUILD_DIR)/ras-trap-boundary-smoke.elf
RAS_TRAP_BIN := $(BUILD_DIR)/ras-trap-boundary-smoke.bin
FP_FCSR_ELF := $(BUILD_DIR)/fp-fcsr-smoke.elf
FP_FCSR_BIN := $(BUILD_DIR)/fp-fcsr-smoke.bin
FP_FMV_FCLASS_ELF := $(BUILD_DIR)/fp-fmv-fclass-smoke.elf
FP_FMV_FCLASS_BIN := $(BUILD_DIR)/fp-fmv-fclass-smoke.bin
FP_CONVERT_ELF := $(BUILD_DIR)/fp-convert-smoke.elf
FP_CONVERT_BIN := $(BUILD_DIR)/fp-convert-smoke.bin
FP_COMPARE_SGNJ_ELF := $(BUILD_DIR)/fp-compare-sgnj-smoke.elf
FP_COMPARE_SGNJ_BIN := $(BUILD_DIR)/fp-compare-sgnj-smoke.bin
FP_MINMAX_ELF := $(BUILD_DIR)/fp-minmax-smoke.elf
FP_MINMAX_BIN := $(BUILD_DIR)/fp-minmax-smoke.bin
FP_ADDSUB_ELF := $(BUILD_DIR)/fp-addsub-smoke.elf
FP_ADDSUB_BIN := $(BUILD_DIR)/fp-addsub-smoke.bin
FP_MUL_ELF := $(BUILD_DIR)/fp-mul-smoke.elf
FP_MUL_BIN := $(BUILD_DIR)/fp-mul-smoke.bin
FP_DIV_ELF := $(BUILD_DIR)/fp-div-smoke.elf
FP_DIV_BIN := $(BUILD_DIR)/fp-div-smoke.bin
FP_SQRT_ELF := $(BUILD_DIR)/fp-sqrt-smoke.elf
FP_SQRT_BIN := $(BUILD_DIR)/fp-sqrt-smoke.bin

SMOKE_BINS := \
  $(JAL_LINK_BIN) $(BRANCH_RAW_BIN) \
  $(SRET_USER_BIN) $(SRET_USER_PF_BIN) $(SRET_USER_SV39_BIN) $(SRET_USER_SV39_HALF_BIN) \
  $(SRET_RESTORE_BIN) $(RAS_TRAP_BIN) \
  $(FP_SMOKE_BIN) $(FP_FCSR_BIN) $(FP_FMV_FCLASS_BIN) $(FP_CONVERT_BIN) $(FP_COMPARE_SGNJ_BIN) \
  $(FP_MINMAX_BIN) $(FP_ADDSUB_BIN) $(FP_MUL_BIN) $(FP_DIV_BIN) $(FP_SQRT_BIN)

BOOT_TOOL_BINS := $(TRAMPOLINE_BIN) $(DTB_SMOKE_BIN) $(MINI_LINUX_BIN) $(OPENSBI_SBI_BIN) $(VIRTIO_BLK_BIN)

.PHONY: all boot-tools dtb check-dtb clean \
	smoke-dtb smoke-opensbi smoke-opensbi-sbi smoke-virtio-blk \
	smoke-jal-link smoke-branch-raw smoke-sret-user smoke-sret-user-pagefault \
	smoke-sret-user-sv39 smoke-sret-user-sv39-halfword smoke-sret-restore smoke-ras-trap-boundary \
	smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass smoke-fp-convert \
	smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub smoke-fp-mul \
	smoke-fp-div smoke-fp-sqrt

all: $(SMOKE_BINS)
boot-tools: $(BOOT_TOOL_BINS) $(DTB)
dtb: $(DTB)

$(DTB_DTS): $(GEN_DTS) $(PLATFORM_CONFIG)
	mkdir -p $(dir $@)
	$(PYTHON) $(GEN_DTS) --config $(PLATFORM_CONFIG) --mode kernel --output $@

$(DTB): $(DTB_DTS)
	mkdir -p $(BUILD_DIR)
	$(DTC) -I dts -O dtb -o $@ $<

$(TRAMPOLINE_ELF): linux-boot-trampoline.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imac_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(TRAMPOLINE_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DBOOT_HARTID=$(BOOT_HARTID) -DNEXT_ADDR=$(NEXT_ADDR) -DDTB_ADDR=$(DTB_ADDR) \
	  $< -o $@

$(DTB_SMOKE_ELF): linux-dtb-smoke.c Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -O2 -ffreestanding -fno-builtin -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DDTB_SMOKE_STACK=$(DTB_SMOKE_STACK) \
	  -Wl,-Ttext=$(DTB_SMOKE_TEXT) -Wl,-e,_start \
	  $< -o $@

$(MINI_LINUX_ELF): mini-linux-payload.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(MINI_LINUX_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DMINI_LINUX_STACK=$(MINI_LINUX_STACK) -DMINI_LINUX_UART=$(MINI_LINUX_UART) \
	  $< -o $@

$(OPENSBI_SBI_ELF): opensbi-sbi-payload.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(OPENSBI_SBI_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DOPENSBI_SBI_STACK=$(OPENSBI_SBI_STACK) \
	  $< -o $@

$(VIRTIO_BLK_ELF): virtio-blk-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(VIRTIO_BLK_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DVIRTIO_BLK_STACK=$(VIRTIO_BLK_STACK) \
	  $< -o $@

check-dtb: $(DTB)
	$(FDTGET) $(DTB) / model
	$(FDTGET) $(DTB) /chosen stdout-path
	$(FDTGET) $(DTB) /cpus/cpu@0 mmu-type
	$(FDTGET) $(DTB) /soc/serial@10000000 compatible

smoke-dtb: $(TRAMPOLINE_BIN) $(DTB) $(DTB_SMOKE_BIN)
	$(NPC_SIM) -b --no-diff --no-progress --max=2000000 \
	  --load=$(TRAMPOLINE_TEXT):$(TRAMPOLINE_BIN) \
	  --load=$(NEXT_ADDR):$(DTB_SMOKE_BIN) \
	  --load=$(DTB_ADDR):$(DTB)

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

smoke-virtio-blk: $(VIRTIO_BLK_BIN)
	test -f $(VIRTIO_BLK_IMAGE)
	$(NPC_SIM) -b --no-progress --no-diff --max=$(VIRTIO_BLK_MAX_CYCLES) \
	  --block=$(VIRTIO_BLK_IMAGE) \
	  -i $(VIRTIO_BLK_BIN)

$(FP_SMOKE_ELF): fp-loadstore-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_SMOKE_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_SMOKE_STACK) \
	  $< -o $@

$(JAL_LINK_ELF): jal-link-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(JAL_LINK_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DJAL_LINK_STACK=$(JAL_LINK_STACK) \
	  $< -o $@

$(BRANCH_RAW_ELF): branch-raw-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(BRANCH_RAW_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DBRANCH_RAW_STACK=$(BRANCH_RAW_STACK) \
	  $< -o $@

$(SRET_USER_ELF): sret-user-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SRET_USER_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSRET_USER_STACK=$(SRET_USER_STACK) \
	  $< -o $@

$(SRET_USER_PF_ELF): sret-user-pagefault-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SRET_USER_PF_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSRET_USER_PF_STACK=$(SRET_USER_PF_STACK) \
	  -DSRET_USER_PF_ROOT=$(SRET_USER_PF_ROOT) \
	  -DSRET_USER_PF_VA=$(SRET_USER_PF_VA) \
	  $< -o $@

$(SRET_USER_SV39_ELF): sret-user-sv39-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SRET_USER_SV39_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSRET_USER_SV39_STACK=$(SRET_USER_SV39_STACK) \
	  -DSRET_USER_SV39_ROOT=$(SRET_USER_SV39_ROOT) \
	  -DSRET_USER_SV39_L1=$(SRET_USER_SV39_L1) \
	  -DSRET_USER_SV39_L0=$(SRET_USER_SV39_L0) \
	  -DSRET_USER_SV39_UVA=$(SRET_USER_SV39_UVA) \
	  $< -o $@

$(SRET_USER_SV39_HALF_ELF): sret-user-sv39-halfword-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imac_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SRET_USER_SV39_HALF_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSRET_USER_SV39_HALF_STACK=$(SRET_USER_SV39_HALF_STACK) \
	  -DSRET_USER_SV39_HALF_ROOT=$(SRET_USER_SV39_HALF_ROOT) \
	  -DSRET_USER_SV39_HALF_L1=$(SRET_USER_SV39_HALF_L1) \
	  -DSRET_USER_SV39_HALF_L0=$(SRET_USER_SV39_HALF_L0) \
	  -DSRET_USER_SV39_HALF_UVA=$(SRET_USER_SV39_HALF_UVA) \
	  $< -o $@

$(SRET_RESTORE_ELF): sret-restore-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imac_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SRET_RESTORE_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSRET_RESTORE_STACK=$(SRET_RESTORE_STACK) \
	  -DSRET_RESTORE_ROOT=$(SRET_RESTORE_ROOT) \
	  -DSRET_RESTORE_L1=$(SRET_RESTORE_L1) \
	  -DSRET_RESTORE_L0=$(SRET_RESTORE_L0) \
	  -DSRET_RESTORE_FRAME=$(SRET_RESTORE_FRAME) \
	  -DSRET_RESTORE_THREAD=$(SRET_RESTORE_THREAD) \
	  -DSRET_RESTORE_UVA=$(SRET_RESTORE_UVA) \
	  $< -o $@

$(RAS_TRAP_ELF): ras-trap-boundary-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(RAS_TRAP_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DRAS_TRAP_STACK=$(RAS_TRAP_STACK) \
	  $< -o $@

$(FP_FCSR_ELF): fp-fcsr-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_FMV_FCLASS_ELF): fp-fmv-fclass-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_FMV_FCLASS_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_FMV_FCLASS_STACK) \
	  $< -o $@

$(FP_CONVERT_ELF): fp-convert-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_COMPARE_SGNJ_ELF): fp-compare-sgnj-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_MINMAX_ELF): fp-minmax-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_ADDSUB_ELF): fp-addsub-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_MUL_ELF): fp-mul-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_DIV_ELF): fp-div-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_SQRT_ELF): fp-sqrt-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

smoke-jal-link: $(JAL_LINK_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(JAL_LINK_BIN)

smoke-branch-raw: $(BRANCH_RAW_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(BRANCH_RAW_BIN)

smoke-sret-user: $(SRET_USER_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(SRET_USER_BIN)

smoke-sret-user-pagefault: $(SRET_USER_PF_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(SRET_USER_PF_BIN)

smoke-sret-user-sv39: $(SRET_USER_SV39_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(SRET_USER_SV39_BIN)

smoke-sret-user-sv39-halfword: $(SRET_USER_SV39_HALF_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(SRET_USER_SV39_HALF_BIN)

smoke-sret-restore: $(SRET_RESTORE_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(SRET_RESTORE_BIN)

smoke-ras-trap-boundary: $(RAS_TRAP_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(RAS_TRAP_BIN)

smoke-fp-loadstore: $(FP_SMOKE_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_SMOKE_BIN)

smoke-fp-fcsr: $(FP_FCSR_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_FCSR_BIN)

smoke-fp-fmv-fclass: $(FP_FMV_FCLASS_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_FMV_FCLASS_BIN)

smoke-fp-convert: $(FP_CONVERT_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_CONVERT_BIN)

smoke-fp-compare-sgnj: $(FP_COMPARE_SGNJ_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_COMPARE_SGNJ_BIN)

smoke-fp-minmax: $(FP_MINMAX_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_MINMAX_BIN)

smoke-fp-addsub: $(FP_ADDSUB_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_ADDSUB_BIN)

smoke-fp-mul: $(FP_MUL_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_MUL_BIN)

smoke-fp-div: $(FP_DIV_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_DIV_BIN)

smoke-fp-sqrt: $(FP_SQRT_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(FP_SQRT_BIN)

clean:
	rm -rf $(BUILD_DIR)
