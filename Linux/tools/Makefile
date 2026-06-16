# RV64 Linux bring-up focused tool tests.
#
# 这些小型裸机 smoke 用于支撑 Linux/Ubuntu bring-up 的 ISA、
# privilege、control-flow 和 rv64gc 用户态边界定位。

ENV_ROOT ?= ../env
TOOL_PLATFORM ?= npc
PLATFORM_ROOT ?= $(ENV_ROOT)/platforms/$(TOOL_PLATFORM)
LOCAL_ELF_TOOLCHAIN := $(abspath $(ENV_ROOT)/toolchains/riscv)
CROSS_COMPILE ?= $(if $(wildcard $(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-gcc),$(LOCAL_ELF_TOOLCHAIN)/bin/riscv64-unknown-elf-,riscv64-linux-gnu-)

CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
DTC ?= dtc
FDTGET ?= fdtget
BUILD_DIR ?= build
NPC_SIM ?= ../../npc/rv64/build/NpcSimTop
NEMU_HOME ?= ../../nemu
NEMU_BUILD_JOBS ?= $(shell nproc 2>/dev/null || echo 1)
NEMU := $(abspath $(NEMU_HOME)/build/riscv64-nemu-interpreter)
NEMU_PRESERVED_RUN ?= ../../scripts/nemu-preserved-run.sh
# NEMU system-mode smoke 会临时切 defconfig；这些路径必须在运行后恢复到用户原状态。
NEMU_CONFIG_PATHS := .config .config.old include/config include/generated
NEMU_AMO_MISALIGNED_LOG ?= $(BUILD_DIR)/amo-misaligned-nemu.log
NEMU_LRSC_RESERVATION_LOG ?= $(BUILD_DIR)/lrsc-reservation-nemu.log
NEMU_PMP_ACCESS_LOG ?= $(BUILD_DIR)/pmp-access-nemu.log
NEMU_PMP_PAGEWALK_LOG ?= $(BUILD_DIR)/pmp-pagewalk-nemu.log
NEMU_PMP_PAGEWALK_AD_LOG ?= $(BUILD_DIR)/pmp-pagewalk-ad-nemu.log
NEMU_SV39_SFENCE_ASID_LOG ?= $(BUILD_DIR)/sv39-sfence-asid-nemu.log
NEMU_FP_CONVERT_LOG ?= $(BUILD_DIR)/fp-convert-nemu.log
NEMU_FP_COMPARE_SGNJ_LOG ?= $(BUILD_DIR)/fp-compare-sgnj-nemu.log
NEMU_FP_SQRT_LOG ?= $(BUILD_DIR)/fp-sqrt-nemu.log
NEMU_VIRTIO_BLK_ERROR_LOG ?= $(BUILD_DIR)/virtio-blk-error-nemu.log
NEMU_VIRTIO_NET_CTRL_LOG ?= $(BUILD_DIR)/virtio-net-ctrl-nemu.log
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
VIRTIO_NET_CTRL_STACK ?= 0x87ee8000
VIRTIO_BLK_IMAGE ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64.ext4
VIRTIO_BLK_MAX_CYCLES ?= 2000000
VIRTIO_BLK_ERROR_MAX_INSTS ?= 10000000
VIRTIO_NET_CTRL_MAX_INSTS ?= 2000000
FP_SMOKE_TEXT ?= 0x80200000
FP_SMOKE_STACK ?= 0x87efc000
JAL_LINK_TEXT ?= 0x80000000
JAL_LINK_STACK ?= 0x87ef9000
BRANCH_RAW_TEXT ?= 0x80000000
BRANCH_RAW_STACK ?= 0x87ef8000
MULDIV_SMOKE_TEXT ?= 0x80000000
MULDIV_SMOKE_STACK ?= 0x87ef0000
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
AMO_MISALIGNED_TEXT ?= 0x80000000
AMO_MISALIGNED_STACK ?= 0x87eef000
LRSC_RESERVATION_TEXT ?= 0x80000000
LRSC_RESERVATION_STACK ?= 0x87eed000
PMP_ACCESS_TEXT ?= 0x80000000
PMP_ACCESS_STACK ?= 0x87eec000
PMP_PAGEWALK_TEXT ?= 0x80000000
PMP_PAGEWALK_STACK ?= 0x87eeb000
PMP_PAGEWALK_AD_TEXT ?= 0x80000000
PMP_PAGEWALK_AD_STACK ?= 0x87ee9000
SV39_SFENCE_ASID_TEXT ?= 0x80000000
SV39_SFENCE_ASID_STACK ?= 0x87eee000
FP_FMV_FCLASS_TEXT ?= $(FP_SMOKE_TEXT)
FP_FMV_FCLASS_STACK ?= 0x87efb000
FP_CONVERT_TEXT ?= $(FP_SMOKE_TEXT)
FP_CONVERT_STACK ?= 0x87efa000
OPENSBI_FW_JUMP_BIN ?= $(PLATFORM_ROOT)/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin
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
VIRTIO_BLK_ERROR_ELF := $(BUILD_DIR)/virtio-blk-error-smoke.elf
VIRTIO_BLK_ERROR_BIN := $(BUILD_DIR)/virtio-blk-error-smoke.bin
VIRTIO_NET_CTRL_ELF := $(BUILD_DIR)/virtio-net-ctrl-smoke.elf
VIRTIO_NET_CTRL_BIN := $(BUILD_DIR)/virtio-net-ctrl-smoke.bin
FP_SMOKE_ELF := $(BUILD_DIR)/fp-loadstore-smoke.elf
FP_SMOKE_BIN := $(BUILD_DIR)/fp-loadstore-smoke.bin
JAL_LINK_ELF := $(BUILD_DIR)/jal-link-smoke.elf
JAL_LINK_BIN := $(BUILD_DIR)/jal-link-smoke.bin
BRANCH_RAW_ELF := $(BUILD_DIR)/branch-raw-smoke.elf
BRANCH_RAW_BIN := $(BUILD_DIR)/branch-raw-smoke.bin
MULDIV_SMOKE_ELF := $(BUILD_DIR)/muldiv-smoke.elf
MULDIV_SMOKE_BIN := $(BUILD_DIR)/muldiv-smoke.bin
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
AMO_MISALIGNED_ELF := $(BUILD_DIR)/amo-misaligned-smoke.elf
AMO_MISALIGNED_BIN := $(BUILD_DIR)/amo-misaligned-smoke.bin
LRSC_RESERVATION_ELF := $(BUILD_DIR)/lrsc-reservation-smoke.elf
LRSC_RESERVATION_BIN := $(BUILD_DIR)/lrsc-reservation-smoke.bin
PMP_ACCESS_ELF := $(BUILD_DIR)/pmp-access-smoke.elf
PMP_ACCESS_BIN := $(BUILD_DIR)/pmp-access-smoke.bin
PMP_PAGEWALK_ELF := $(BUILD_DIR)/pmp-pagewalk-smoke.elf
PMP_PAGEWALK_BIN := $(BUILD_DIR)/pmp-pagewalk-smoke.bin
PMP_PAGEWALK_AD_ELF := $(BUILD_DIR)/pmp-pagewalk-ad-smoke.elf
PMP_PAGEWALK_AD_BIN := $(BUILD_DIR)/pmp-pagewalk-ad-smoke.bin
SV39_SFENCE_ASID_ELF := $(BUILD_DIR)/sv39-sfence-asid-smoke.elf
SV39_SFENCE_ASID_BIN := $(BUILD_DIR)/sv39-sfence-asid-smoke.bin
FP_FCSR_ELF := $(BUILD_DIR)/fp-fcsr-smoke.elf
FP_FCSR_BIN := $(BUILD_DIR)/fp-fcsr-smoke.bin
FP_FMV_FCLASS_ELF := $(BUILD_DIR)/fp-fmv-fclass-smoke.elf
FP_FMV_FCLASS_BIN := $(BUILD_DIR)/fp-fmv-fclass-smoke.bin
FP_CONVERT_ELF := $(BUILD_DIR)/fp-convert-smoke.elf
FP_CONVERT_BIN := $(BUILD_DIR)/fp-convert-smoke.bin
FP_CONVERT_NEMU_ELF := $(BUILD_DIR)/fp-convert-smoke-nemu.elf
FP_CONVERT_NEMU_BIN := $(BUILD_DIR)/fp-convert-smoke-nemu.bin
FP_COMPARE_SGNJ_ELF := $(BUILD_DIR)/fp-compare-sgnj-smoke.elf
FP_COMPARE_SGNJ_BIN := $(BUILD_DIR)/fp-compare-sgnj-smoke.bin
FP_COMPARE_SGNJ_NEMU_ELF := $(BUILD_DIR)/fp-compare-sgnj-smoke-nemu.elf
FP_COMPARE_SGNJ_NEMU_BIN := $(BUILD_DIR)/fp-compare-sgnj-smoke-nemu.bin
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
FP_SQRT_NEMU_ELF := $(BUILD_DIR)/fp-sqrt-smoke-nemu.elf
FP_SQRT_NEMU_BIN := $(BUILD_DIR)/fp-sqrt-smoke-nemu.bin

SMOKE_BINS := \
  $(JAL_LINK_BIN) $(BRANCH_RAW_BIN) $(MULDIV_SMOKE_BIN) \
  $(SRET_USER_BIN) $(SRET_USER_PF_BIN) $(SRET_USER_SV39_BIN) $(SRET_USER_SV39_HALF_BIN) \
  $(SRET_RESTORE_BIN) $(RAS_TRAP_BIN) $(AMO_MISALIGNED_BIN) $(LRSC_RESERVATION_BIN) $(PMP_ACCESS_BIN) $(PMP_PAGEWALK_BIN) $(PMP_PAGEWALK_AD_BIN) $(SV39_SFENCE_ASID_BIN) \
  $(FP_SMOKE_BIN) $(FP_FCSR_BIN) $(FP_FMV_FCLASS_BIN) $(FP_CONVERT_BIN) $(FP_COMPARE_SGNJ_BIN) \
  $(FP_MINMAX_BIN) $(FP_ADDSUB_BIN) $(FP_MUL_BIN) $(FP_DIV_BIN) $(FP_SQRT_BIN)

BOOT_TOOL_BINS := $(TRAMPOLINE_BIN) $(DTB_SMOKE_BIN) $(MINI_LINUX_BIN) $(OPENSBI_SBI_BIN) $(VIRTIO_BLK_BIN) $(VIRTIO_BLK_ERROR_BIN) $(VIRTIO_NET_CTRL_BIN)

.PHONY: all boot-tools dtb check-dtb clean \
	smoke-dtb smoke-opensbi smoke-opensbi-sbi smoke-virtio-blk smoke-nemu-virtio-blk-error smoke-nemu-virtio-net-ctrl smoke-nemu-config-preserve \
	smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user smoke-sret-user-pagefault \
	smoke-sret-user-sv39 smoke-sret-user-sv39-halfword smoke-sret-restore smoke-ras-trap-boundary \
	smoke-nemu-amo-misaligned smoke-nemu-lrsc-reservation smoke-nemu-pmp-access smoke-nemu-pmp-pagewalk smoke-nemu-pmp-pagewalk-ad smoke-nemu-sv39-sfence-asid \
	smoke-nemu-fp-convert smoke-nemu-fp-compare-sgnj \
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

$(VIRTIO_BLK_ERROR_ELF): virtio-blk-error-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(VIRTIO_BLK_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DVIRTIO_BLK_STACK=$(VIRTIO_BLK_STACK) \
	  $< -o $@

$(VIRTIO_NET_CTRL_ELF): virtio-net-ctrl-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(VIRTIO_BLK_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DVIRTIO_NET_STACK=$(VIRTIO_NET_CTRL_STACK) \
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

smoke-nemu-virtio-blk-error: $(VIRTIO_BLK_ERROR_BIN)
	test -f $(VIRTIO_BLK_IMAGE)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=$(VIRTIO_BLK_ERROR_MAX_INSTS) \
	  --block=$(VIRTIO_BLK_IMAGE) -i $(VIRTIO_BLK_ERROR_BIN) > $(NEMU_VIRTIO_BLK_ERROR_LOG) 2>&1
	cat $(NEMU_VIRTIO_BLK_ERROR_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_VIRTIO_BLK_ERROR_LOG)

smoke-nemu-virtio-net-ctrl: $(VIRTIO_NET_CTRL_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=$(VIRTIO_NET_CTRL_MAX_INSTS) \
	  -i $(VIRTIO_NET_CTRL_BIN) > $(NEMU_VIRTIO_NET_CTRL_LOG) 2>&1
	cat $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl=8/1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_rx=2' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_rx_extra=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_vlan=2' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*vlan_active=0 vlan_last=42' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_announce=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*announce_pending=0 announce_requested=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*alluni=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_mac_table=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*ctrl_mac_addr=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*promisc=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*mac_uni=1 mac_multi=1' $(NEMU_VIRTIO_NET_CTRL_LOG)
	grep -q 'virtio-net runtime .*mac=02:00:5e:00:53:02' $(NEMU_VIRTIO_NET_CTRL_LOG)

smoke-nemu-config-preserve: $(VIRTIO_NET_CTRL_BIN)
	@set -e; \
	hash_nemu_config() { \
	  { \
	    for rel in $(NEMU_CONFIG_PATHS); do \
	      if [ -e "$(abspath $(NEMU_HOME))/$$rel" ]; then \
	        printf 'present %s\n' "$$rel"; \
	      else \
	        printf 'absent %s\n' "$$rel"; \
	      fi; \
	    done; \
	    tar -C "$(abspath $(NEMU_HOME))" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --ignore-failed-read -cf - $(NEMU_CONFIG_PATHS) 2>/dev/null || true; \
	  } | sha256sum | sed 's/ .*//'; \
	}; \
	before=$$(hash_nemu_config); \
	make --no-print-directory smoke-nemu-virtio-net-ctrl; \
	after=$$(hash_nemu_config); \
	printf 'NEMU_CONFIG_HASH_BEFORE=%s\n' "$$before"; \
	printf 'NEMU_CONFIG_HASH_AFTER=%s\n' "$$after"; \
	if [ "$$before" = "$$after" ]; then \
	  printf 'PASS nemu-config-preserve\n'; \
	else \
	  printf 'FAIL nemu-config-preserve\n'; \
	  exit 1; \
	fi

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

$(MULDIV_SMOKE_ELF): muldiv-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(MULDIV_SMOKE_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DMULDIV_SMOKE_STACK=$(MULDIV_SMOKE_STACK) \
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

$(AMO_MISALIGNED_ELF): amo-misaligned-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(AMO_MISALIGNED_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DAMO_MISALIGNED_STACK=$(AMO_MISALIGNED_STACK) \
	  $< -o $@

$(LRSC_RESERVATION_ELF): lrsc-reservation-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(LRSC_RESERVATION_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DLRSC_RESERVATION_STACK=$(LRSC_RESERVATION_STACK) \
	  $< -o $@

$(PMP_ACCESS_ELF): pmp-access-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(PMP_ACCESS_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DPMP_ACCESS_STACK=$(PMP_ACCESS_STACK) \
	  $< -o $@

$(PMP_PAGEWALK_ELF): pmp-pagewalk-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(PMP_PAGEWALK_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DPMP_PAGEWALK_STACK=$(PMP_PAGEWALK_STACK) \
	  $< -o $@

$(PMP_PAGEWALK_AD_ELF): pmp-pagewalk-ad-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(PMP_PAGEWALK_AD_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DPMP_PAGEWALK_AD_STACK=$(PMP_PAGEWALK_AD_STACK) \
	  $< -o $@

$(SV39_SFENCE_ASID_ELF): sv39-sfence-asid-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64ima_zicsr_zifencei -mabi=lp64 -Wl,-Ttext=$(SV39_SFENCE_ASID_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DSV39_SFENCE_ASID_STACK=$(SV39_SFENCE_ASID_STACK) \
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

$(FP_CONVERT_NEMU_ELF): fp-convert-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=0x80000000 \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) -DFP_SMOKE_NEMU_SYSCON_EXIT=1 \
	  $< -o $@

$(FP_COMPARE_SGNJ_ELF): fp-compare-sgnj-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=$(FP_CONVERT_TEXT) \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) \
	  $< -o $@

$(FP_COMPARE_SGNJ_NEMU_ELF): fp-compare-sgnj-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=0x80000000 \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) -DFP_SMOKE_NEMU_SYSCON_EXIT=1 \
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

$(FP_SQRT_NEMU_ELF): fp-sqrt-smoke.S Makefile
	mkdir -p $(BUILD_DIR)
	$(CC) -x assembler-with-cpp -nostdlib -nostartfiles \
	  -march=rv64imafdc_zicsr_zifencei -mabi=lp64d -Wl,-Ttext=0x80000000 \
	  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
	  -DFP_SMOKE_STACK=$(FP_CONVERT_STACK) -DFP_SMOKE_NEMU_SYSCON_EXIT=1 \
	  $< -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

smoke-jal-link: $(JAL_LINK_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(JAL_LINK_BIN)

smoke-branch-raw: $(BRANCH_RAW_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=2000000 -i $(BRANCH_RAW_BIN)

smoke-muldiv: $(MULDIV_SMOKE_BIN)
	$(NPC_SIM) -b --no-progress --no-diff --max=4000000 -i $(MULDIV_SMOKE_BIN)

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

smoke-nemu-amo-misaligned: $(AMO_MISALIGNED_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(AMO_MISALIGNED_BIN) > $(NEMU_AMO_MISALIGNED_LOG) 2>&1
	cat $(NEMU_AMO_MISALIGNED_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_AMO_MISALIGNED_LOG)

smoke-nemu-lrsc-reservation: $(LRSC_RESERVATION_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(LRSC_RESERVATION_BIN) > $(NEMU_LRSC_RESERVATION_LOG) 2>&1
	cat $(NEMU_LRSC_RESERVATION_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_LRSC_RESERVATION_LOG)

smoke-nemu-pmp-access: $(PMP_ACCESS_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(PMP_ACCESS_BIN) > $(NEMU_PMP_ACCESS_LOG) 2>&1
	cat $(NEMU_PMP_ACCESS_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_PMP_ACCESS_LOG)

smoke-nemu-pmp-pagewalk: $(PMP_PAGEWALK_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=300000 -i $(PMP_PAGEWALK_BIN) > $(NEMU_PMP_PAGEWALK_LOG) 2>&1
	cat $(NEMU_PMP_PAGEWALK_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_PMP_PAGEWALK_LOG)

smoke-nemu-pmp-pagewalk-ad: $(PMP_PAGEWALK_AD_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=300000 -i $(PMP_PAGEWALK_AD_BIN) > $(NEMU_PMP_PAGEWALK_AD_LOG) 2>&1
	cat $(NEMU_PMP_PAGEWALK_AD_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_PMP_PAGEWALK_AD_LOG)

smoke-nemu-sv39-sfence-asid: $(SV39_SFENCE_ASID_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=300000 -i $(SV39_SFENCE_ASID_BIN) > $(NEMU_SV39_SFENCE_ASID_LOG) 2>&1
	cat $(NEMU_SV39_SFENCE_ASID_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_SV39_SFENCE_ASID_LOG)

smoke-nemu-fp-convert: $(FP_CONVERT_NEMU_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(FP_CONVERT_NEMU_BIN) > $(NEMU_FP_CONVERT_LOG) 2>&1
	cat $(NEMU_FP_CONVERT_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_FP_CONVERT_LOG)

smoke-nemu-fp-compare-sgnj: $(FP_COMPARE_SGNJ_NEMU_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(FP_COMPARE_SGNJ_NEMU_BIN) > $(NEMU_FP_COMPARE_SGNJ_LOG) 2>&1
	cat $(NEMU_FP_COMPARE_SGNJ_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_FP_COMPARE_SGNJ_LOG)

smoke-nemu-fp-sqrt: $(FP_SQRT_NEMU_BIN)
	$(abspath $(NEMU_PRESERVED_RUN)) $(abspath $(NEMU_HOME)) $(NEMU_BUILD_JOBS) -- \
	  -b --max-insts=200000 -i $(FP_SQRT_NEMU_BIN) > $(NEMU_FP_SQRT_LOG) 2>&1
	cat $(NEMU_FP_SQRT_LOG)
	grep -q 'HIT GOOD TRAP' $(NEMU_FP_SQRT_LOG)

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
