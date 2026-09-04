/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <cpu/bpu.h>
#include <cpu/difftest.h>
#include <memory/paddr.h>
#include <memory/soc.h>
#include <memory/vaddr.h>
#include <platform/platform-map.h>
#include <device/map.h>
#include <ftrace.h>
#include <utils.h>

void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_device();
#ifdef CONFIG_HAS_DISK
void disk_set_image(const char *path);
void disk_set_overlay(const char *path);
void virtio_blk_dump_machine_info(FILE *out);
bool virtio_blk_shutdown(void);
#endif
#ifdef CONFIG_HAS_SERIAL
void serial_dump_machine_info(FILE *out);
#endif
#ifdef CONFIG_HAS_VIRTIO_NET
void virtio_net_dump_machine_info(FILE *out);
void virtio_net_set_tap(const char *ifname);
#endif
#ifdef CONFIG_HAS_VIRTIO_RNG
void virtio_rng_dump_machine_info(FILE *out);
#endif
#ifdef CONFIG_HAS_VIRTIO_INPUT
void virtio_input_dump_machine_info(FILE *out);
#endif
#ifdef CONFIG_HAS_GOLDFISH_RTC
void goldfish_rtc_dump_machine_info(FILE *out);
#endif
void init_sdb();
void init_disasm();

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NEMU!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
  //Log("Exercise: Please remove me in the source code and compile NEMU again.");
  //assert(0);
}

#ifndef CONFIG_TARGET_AM
#include <errno.h>
#include <getopt.h>
#include "monitor.h"
#include "sdb/sdb.h"
#include "qmp.h"
#include "gdbstub.h"

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
#ifdef CONFIG_HAS_DISK
static char *block_file = NULL;
static char *block_overlay_file = NULL;
#endif
static char *machine_info_file = NULL;
static char *elf_file = NULL; //添加ELF文件参数和ftrace初始化
static int difftest_port = 1234;
static bool boot_hartid_valid = false;
static bool boot_dtb_valid = false;
static word_t boot_hartid = 0;
static word_t boot_dtb = 0;

void monitor_apply_boot_arguments(void) {
#if defined(CONFIG_ISA_riscv)
  if (boot_hartid_valid) {
    cpu.gpr[10] = boot_hartid;
    Log("Boot argument a0/hartid = " FMT_WORD, boot_hartid);
  }
  if (boot_dtb_valid) {
    cpu.gpr[11] = boot_dtb;
    Log("Boot argument a1/dtb = " FMT_WORD, boot_dtb);
  }
#endif
}

#define NEMU_MAX_LOAD_IMAGES 16

typedef struct {
  paddr_t addr;
  const char *path;
  size_t size;
} LoadImageSpec;

static LoadImageSpec load_images[NEMU_MAX_LOAD_IMAGES];
static int load_image_count = 0;

#define NEMU_MAX_MONITOR_CMDS 16

static const char *monitor_cmds[NEMU_MAX_MONITOR_CMDS];
static int monitor_cmd_count = 0;

static void add_monitor_cmd(const char *cmd) {
  Assert(monitor_cmd_count < NEMU_MAX_MONITOR_CMDS,
      "too many --monitor-cmd entries, max=%d", NEMU_MAX_MONITOR_CMDS);
  Assert(cmd != NULL && cmd[0] != '\0', "--monitor-cmd expects a non-empty command");
  monitor_cmds[monitor_cmd_count++] = cmd;
}

static void parse_load_image(const char *arg) {
  Assert(load_image_count < NEMU_MAX_LOAD_IMAGES, "too many --load entries, max=%d", NEMU_MAX_LOAD_IMAGES);
  const char *sep = strchr(arg, ':');
  Assert(sep != NULL && sep != arg && sep[1] != '\0',
      "invalid --load=%s, expect ADDR:FILE", arg);

  char addr_buf[64];
  size_t addr_len = sep - arg;
  Assert(addr_len < sizeof(addr_buf), "--load address is too long: %s", arg);
  memcpy(addr_buf, arg, addr_len);
  addr_buf[addr_len] = '\0';

  char *end = NULL;
  errno = 0;
  uint64_t addr = strtoull(addr_buf, &end, 0);
  Assert(addr_buf[0] >= '0' && addr_buf[0] <= '9' &&
         errno == 0 && end != addr_buf && *end == '\0',
      "invalid --load address: %s", addr_buf);
  Assert((uint64_t)(paddr_t)addr == addr,
      "--load address does not fit the guest physical address width: %s",
      addr_buf);

  load_images[load_image_count++] = (LoadImageSpec){
    .addr = (paddr_t)addr,
    .path = sep + 1,
    .size = 0,
  };
}

static long load_file_to_guest(const char *path, paddr_t addr) {
  FILE *fp = fopen(path, "rb");
  Assert(fp, "Can not open '%s'", path);

  Assert(fseek(fp, 0, SEEK_END) == 0,
      "Can not seek to the end of image '%s'", path);
  long size = ftell(fp);
  Assert(size > 0, "Image '%s' is empty or has no measurable size", path);
  Assert((uintmax_t)size <= (uintmax_t)SIZE_MAX,
      "Image '%s' is too large for this host", path);
  Assert(fseek(fp, 0, SEEK_SET) == 0,
      "Can not rewind image '%s'", path);
  const size_t image_size = (size_t)size;

#ifdef CONFIG_SOC_SIM
  const SocSimRegionInfo *region =
      soc_sim_region_containing(addr, image_size);
  Assert(region != NULL && region->kind == SOC_SIM_REGION_MEMORY,
      "image '%s' does not fit a loadable ysyxSoC memory region at " FMT_PADDR,
      path, addr);
  if (paddr_span_in_pmem(addr, (uint64_t)image_size)) {
    size_t nread = fread(guest_to_host(addr), 1, image_size, fp);
    Assert(nread == image_size, "Can not read complete image '%s'", path);
  } else {
    uint8_t *image = (uint8_t *)malloc(image_size);
    Assert(image != NULL, "Can not allocate image buffer for '%s'", path);
    size_t nread = fread(image, 1, image_size, fp);
    Assert(nread == image_size, "Can not read complete image '%s'", path);
    Assert(soc_sim_copy_to_guest(addr, image, image_size),
        "image '%s' does not fit a loadable ysyxSoC memory region at " FMT_PADDR,
        path, addr);
    free(image);
  }
#else
  Assert(paddr_span_in_pmem(addr, (uint64_t)image_size),
      "image '%s' range [" FMT_PADDR ", " FMT_PADDR "] is out of pmem ["
      FMT_PADDR ", " FMT_PADDR "]",
      path, addr, addr + (paddr_t)image_size - 1,
      PMEM_LEFT, PMEM_RIGHT);

  size_t nread = fread(guest_to_host(addr), 1, image_size, fp);
  Assert(nread == image_size, "Can not read complete image '%s'", path);
#endif
  fclose(fp);

  Log("Load image %s at " FMT_PADDR ", size = %ld", path, addr, size);
  return size;
}

//-i IMAGE装到RESET_VECTOR，覆盖内建镜像
//--load=ADDR:FILE装到指定物理地址
//镜像加载只改变内存，不改变pc
//没有主镜像的时候，继续执行内建测试镜像
static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    for (int i = 0; i < load_image_count; i++) {
      load_images[i].size = (size_t)load_file_to_guest(
          load_images[i].path, load_images[i].addr);
    }
    return 4096; // built-in image size
  }

  // 主镜像保持旧语义装载到 RESET_VECTOR；额外 Linux/OpenSBI 产物用 --load 指定地址。
  long size = load_file_to_guest(img_file, RESET_VECTOR);
  for (int i = 0; i < load_image_count; i++) {
    load_images[i].size = (size_t)load_file_to_guest(
        load_images[i].path, load_images[i].addr);
  }
  return size;
}

static void machine_info_write_bool(FILE *out, const char *key, bool value) {
  fprintf(out, "%s=%d\n", key, value ? 1 : 0);
}

static void machine_info_write_hex(FILE *out, const char *key, uint64_t value) {
  fprintf(out, "%s=0x%08" PRIx64 "\n", key, value);
}

static const char *soc_region_kind_name(SocSimRegionKind kind) {
  switch (kind) {
    case SOC_SIM_REGION_MEMORY: return "memory";
    case SOC_SIM_REGION_MMIO: return "mmio";
    case SOC_SIM_REGION_XIP_FLASH: return "xip-flash";
    default: return "unknown";
  }
}

#ifdef CONFIG_SOC_SIM
static const SocSimRegionInfo *machine_info_find_soc_region(const char *name) {
  for (size_t i = 0; i < soc_sim_region_count(); i++) {
    const SocSimRegionInfo *region = soc_sim_region_at(i);
    Assert(region != NULL, "missing ysyxSoC region descriptor %zu", i);
    if (strcmp(region->name, name) == 0) return region;
  }
  return NULL;
}
#endif

static void dump_soc_platform_info(FILE *out) {
  const size_t region_count = soc_sim_region_count();
  fprintf(out, "platform.soc.region_count=%zu\n", region_count);
  for (size_t i = 0; i < region_count; i++) {
    const SocSimRegionInfo *region = soc_sim_region_at(i);
    Assert(region != NULL && region->name != NULL && region->size != 0,
        "invalid ysyxSoC region descriptor %zu", i);
    const paddr_t end = region->base + (paddr_t)region->size - 1;
    fprintf(out, "platform.soc.region.%s=" FMT_PADDR ".." FMT_PADDR "\n",
        region->name, region->base, end);
    fprintf(out, "platform.soc.region.%s.kind=%s\n",
        region->name, soc_region_kind_name(region->kind));
    fprintf(out, "platform.soc.region.%s.readonly=%d\n",
        region->name, region->readonly ? 1 : 0);
    fprintf(out, "platform.soc.region.%s.difftest_skip=%d\n",
        region->name, region->skip_ref ? 1 : 0);
  }
  const SocSimRegionInfo *pmem_region = soc_sim_pmem_backed_region();
  if (pmem_region != NULL) {
    fprintf(out, "platform.soc.pmem_region=%s\n", pmem_region->name);
  }
}

static void dump_machine_info(FILE *out) {
  fprintf(out, "nemu.machine_info.version=1\n");
  fprintf(out, "config.isa=%s\n", CONFIG_ISA);
  fprintf(out, "config.engine=%s\n", NEMU_ENGINE_NAME);
  machine_info_write_bool(out, "config.mode_system", NEMU_SYSTEM_MODE != 0);
  machine_info_write_bool(out, "config.performance", ISDEF(CONFIG_PERFORMANCE));
  machine_info_write_bool(out, "config.trace", ISDEF(CONFIG_TRACE));

  machine_info_write_bool(out, "config.riscv_ext_m", ISDEF(CONFIG_RISCV_EXT_M));
  machine_info_write_bool(out, "config.riscv_ext_a", ISDEF(CONFIG_RISCV_EXT_A));
  machine_info_write_bool(out, "config.riscv_ext_f", ISDEF(CONFIG_RISCV_EXT_F));
  machine_info_write_bool(out, "config.riscv_ext_d", ISDEF(CONFIG_RISCV_EXT_D));
  machine_info_write_bool(out, "config.riscv_ext_c", ISDEF(CONFIG_RISCV_EXT_C));
  machine_info_write_bool(out, "config.riscv_ext_b", ISDEF(CONFIG_RISCV_EXT_B));
  machine_info_write_bool(out, "config.riscv_ext_e", ISDEF(CONFIG_RVE));
  machine_info_write_bool(out, "config.cache", ISDEF(CONFIG_CACHE));
  machine_info_write_bool(out, "config.interpreter_basic_block", ISDEF(CONFIG_INTERPRETER_BASIC_BLOCK));
  machine_info_write_bool(out, "runtime.interpreter_basic_block.enabled",
      ISDEF(CONFIG_INTERPRETER_BASIC_BLOCK) && cpu_interpreter_basic_block_runtime_enabled());
  fprintf(out, "runtime.interpreter_basic_block.disable_env=NEMU_INTERPRETER_BASIC_BLOCK=0\n");
#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
  fprintf(out, "config.interpreter_tb_max_inst=%d\n", CONFIG_INTERPRETER_TB_MAX_INST);
  fprintf(out, "runtime.interpreter_tb_max_inst=%" PRIu64 "\n",
      cpu_interpreter_tb_max_inst_runtime());
  fprintf(out, "runtime.interpreter_tb_max_inst.env=NEMU_INTERPRETER_TB_MAX_INST\n");
#else
  fprintf(out, "config.interpreter_tb_max_inst=0\n");
  fprintf(out, "runtime.interpreter_tb_max_inst=0\n");
#endif
  machine_info_write_bool(out, "runtime.interpreter_tb_amo_continue.enabled",
      ISDEF(CONFIG_INTERPRETER_BASIC_BLOCK) && cpu_interpreter_basic_block_runtime_enabled() &&
      cpu_interpreter_tb_amo_continue_runtime_enabled());
  fprintf(out, "runtime.interpreter_tb_amo_continue.disable_env=NEMU_INTERPRETER_TB_AMO_CONTINUE=0\n");
  machine_info_write_bool(out, "config.interpreter_wide_ifetch", ISDEF(CONFIG_INTERPRETER_WIDE_IFETCH));
  machine_info_write_bool(out, "config.interpreter_ifetch_page_cache",
      ISDEF(CONFIG_INTERPRETER_IFETCH_PAGE_CACHE));
  machine_info_write_bool(out, "policy.interpreter_decode_cache",
      NEMU_RV64_DECODE_CACHE != 0);
  machine_info_write_bool(out, "runtime.interpreter_wide_ifetch.enabled",
      ISDEF(CONFIG_INTERPRETER_WIDE_IFETCH) && vaddr_ifetch_wide_runtime_enabled());
  fprintf(out, "runtime.interpreter_wide_ifetch.disable_env=NEMU_INTERPRETER_WIDE_IFETCH=0\n");
  machine_info_write_bool(out, "runtime.interpreter_ifetch_page_cache.enabled",
      ISDEF(CONFIG_INTERPRETER_IFETCH_PAGE_CACHE) &&
      vaddr_ifetch_wide_runtime_enabled() && vaddr_host_fast_runtime_enabled());
#if NEMU_RV64_DECODE_CACHE
  bool decode_cache_runtime_enabled = isa_riscv_decode_cache_runtime_enabled();
#else
  bool decode_cache_runtime_enabled = false;
#endif
  machine_info_write_bool(out, "runtime.interpreter_decode_cache.enabled",
      decode_cache_runtime_enabled);
  fprintf(out, "runtime.interpreter_decode_cache.disable_env=NEMU_INTERPRETER_DECODE_CACHE=0\n");
  machine_info_write_bool(out, "runtime.vaddr_host_fast.enabled", vaddr_host_fast_runtime_enabled());
  fprintf(out, "runtime.vaddr_host_fast.disable_env=NEMU_VADDR_HOST_FAST=0\n");
  vaddr_write_trace_dump_machine_info(out);
  paddr_write_trace_dump_machine_info(out);
#if NEMU_RV64_DECODE_CACHE
  fprintf(out, "policy.interpreter_decode_cache_entries=%d\n",
      NEMU_RV64_DECODE_CACHE_ENTRIES);
#else
  fprintf(out, "policy.interpreter_decode_cache_entries=0\n");
#endif
  machine_info_write_bool(out, "config.interpreter_intr_fast_flag", ISDEF(CONFIG_INTERPRETER_INTR_FAST_FLAG));
  fprintf(out, "policy.device_update_check_interval=%u\n",
      NEMU_DEVICE_UPDATE_CHECK_INTERVAL);

  // 能力边界清单把 QEMU-like 缺口变成可执行 gate，避免以后把单个切片误判为完整 VM。
  fprintf(out, "platform.profile=%s\n", NEMU_PLATFORM_NAME);
  machine_info_write_hex(out, "platform.reset_vector", RESET_VECTOR);
  fprintf(out, "platform.hart_count=1\n");
  fprintf(out, "platform.smp=unsupported\n");
  fprintf(out, "platform.pci=unsupported\n");
#ifdef CONFIG_SOC_SIM
  fprintf(out, "platform.virtio_transport=none\n");
  fprintf(out, "platform.virtio_mmio_slots=0\n");
#else
  const unsigned virtio_mmio_slots =
      (ISDEF(CONFIG_HAS_DISK) ? 1u : 0u) +
      (ISDEF(CONFIG_HAS_VIRTIO_RNG) ? 1u : 0u) +
      (ISDEF(CONFIG_HAS_VIRTIO_NET) ? 1u : 0u) +
      (ISDEF(CONFIG_HAS_VIRTIO_INPUT) ? 1u : 0u);
  fprintf(out, "platform.virtio_transport=%s\n",
      virtio_mmio_slots != 0 ? "mmio" : "none");
  fprintf(out, "platform.virtio_mmio_slots=%u\n", virtio_mmio_slots);
#endif
  dump_soc_platform_info(out);
  fprintf(out, "monitor.machine_info=enabled\n");
  fprintf(out, "monitor.oneshot_cmd=enabled\n");
  fprintf(out, "monitor.qmp=%s\n", qmp_capability());
  fprintf(out, "monitor.qmp.mode=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown-quit\n");
  fprintf(out, "debug.gdbstub=%s\n", gdbstub_capability());
  fprintf(out, "debug.gdbstub.mode=startup-rw-regmem-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack\n");
  fprintf(out, "snapshot.vm_state=unsupported\n");
#ifdef CONFIG_SOC_SIM
  fprintf(out, "snapshot.block=unsupported\n");
  fprintf(out, "block.format=none\n");
#else
  fprintf(out, "snapshot.block=raw-sparse-overlay\n");
  fprintf(out, "block.format=raw\n");
#endif

#ifdef CONFIG_ISA_riscv
  /*
   * A time CSR source and a memory-mapped interrupt controller are distinct
   * platform facts.  ysyxSoC keeps NEMU's instruction-time CSR counter but
   * must not advertise the generic CLINT/PLIC apertures or interrupt wires.
   */
  machine_info_write_bool(out, "platform.riscv.clint_mmio",
      NEMU_PLATFORM_HAS_RISCV_CLINT != 0);
  machine_info_write_bool(out, "platform.riscv.plic_mmio",
      NEMU_PLATFORM_HAS_RISCV_PLIC != 0);
  machine_info_write_bool(out, "interrupt.cpu_external_connected",
      NEMU_PLATFORM_CPU_EXTERNAL_IRQ_CONNECTED != 0);
  machine_info_write_bool(out, "time.counter.enabled",
      NEMU_PLATFORM_HAS_RISCV_TIME_COUNTER != 0);
  fprintf(out, "time.counter.timebase_hz=%" PRIu64 "\n",
      isa_riscv_clint_timebase_hz());
  fprintf(out, "time.counter.source=%s\n", isa_riscv_clint_time_source());
#ifdef CONFIG_SOC_SIM
  fprintf(out, "time.clint.enabled=0\n");
  fprintf(out, "time.csr_time_source=platform-counter\n");
  fprintf(out, "interrupt.controller=none\n");
  fprintf(out, "interrupt.clint.enabled=0\n");
  fprintf(out, "interrupt.plic.enabled=0\n");
  fprintf(out, "interrupt.cpu_external_line=tied-low\n");
#else
  // generic profile 的 time CSR 直接读取同一 CLINT mtime 状态。
  fprintf(out, "time.clint.enabled=1\n");
  fprintf(out, "time.clint.timebase_hz=%" PRIu64 "\n",
      isa_riscv_clint_timebase_hz());
  fprintf(out, "time.clint.source=%s\n", isa_riscv_clint_time_source());
  fprintf(out, "time.csr_time_source=clint_mtime\n");
  fprintf(out, "interrupt.controller=riscv-clint+plic\n");
  fprintf(out, "interrupt.cpu_external_line=connected\n");
#ifndef CONFIG_ISA64
  fprintf(out, "interrupt.clint.enabled=1\n");
  fprintf(out, "interrupt.plic.enabled=1\n");
#endif
#ifdef CONFIG_ISA64
  isa_riscv_clint_dump_machine_info(out);
  isa_riscv_plic_dump_machine_info(out);
  isa_riscv_pmp_dump_machine_info(out);
#endif
#endif
#endif

  machine_info_write_hex(out, "memory.base", CONFIG_MBASE);
  machine_info_write_hex(out, "memory.size", CONFIG_MSIZE);
  machine_info_write_hex(out, "memory.end", (uint64_t)CONFIG_MBASE + CONFIG_MSIZE - 1);
  machine_info_write_bool(out, "boot.hartid.valid", boot_hartid_valid);
  machine_info_write_hex(out, "boot.hartid", boot_hartid);
  machine_info_write_bool(out, "boot.dtb.valid", boot_dtb_valid);
  machine_info_write_hex(out, "boot.dtb", boot_dtb);

/* A selected platform owns the provider as well as the address. */
#ifdef CONFIG_SOC_SIM
  const SocSimRegionInfo *soc_uart = machine_info_find_soc_region("uart0");
  Assert(soc_uart != NULL && soc_uart->kind == SOC_SIM_REGION_MMIO,
      "SOC_SIM platform manifest has no MMIO uart0 region");
  machine_info_write_bool(out, "device.serial.enabled", true);
  machine_info_write_hex(out, "device.serial.mmio", soc_uart->base);
  fprintf(out, "device.serial.irq=none\n");
  machine_info_write_bool(out, "device.serial.irq_connected", false);
  fprintf(out, "device.serial.provider=soc-direct\n");
#else
  machine_info_write_bool(out, "device.serial.enabled", ISDEF(CONFIG_HAS_SERIAL));
#ifdef CONFIG_HAS_SERIAL
  machine_info_write_hex(out, "device.serial.mmio", DEV_SERIAL_MMIO);
  fprintf(out, "device.serial.irq=1\n");
  machine_info_write_bool(out, "device.serial.irq_connected", true);
  fprintf(out, "device.serial.provider=iomap\n");
  serial_dump_machine_info(out);
#else
  fprintf(out, "device.serial.provider=none\n");
#endif
#endif

#ifdef CONFIG_SOC_SIM
  machine_info_write_bool(out, "device.virtio_blk.enabled", false);
  fprintf(out, "device.virtio_blk.provider=none\n");
#else
  machine_info_write_bool(out, "device.virtio_blk.enabled", ISDEF(CONFIG_HAS_DISK));
#ifdef CONFIG_HAS_DISK
  machine_info_write_hex(out, "device.virtio_blk.mmio", DEV_DISK_MMIO);
  fprintf(out, "device.virtio_blk.irq=2\n");
  fprintf(out, "device.virtio_blk.provider=iomap\n");
  virtio_blk_dump_machine_info(out);
#else
  fprintf(out, "device.virtio_blk.provider=none\n");
#endif
#endif

#ifdef CONFIG_SOC_SIM
  machine_info_write_bool(out, "device.virtio_rng.enabled", false);
  fprintf(out, "device.virtio_rng.provider=none\n");
#else
  machine_info_write_bool(out, "device.virtio_rng.enabled", ISDEF(CONFIG_HAS_VIRTIO_RNG));
#ifdef CONFIG_HAS_VIRTIO_RNG
  machine_info_write_hex(out, "device.virtio_rng.mmio", DEV_VIRTIO_RNG_MMIO);
  fprintf(out, "device.virtio_rng.irq=3\n");
  fprintf(out, "device.virtio_rng.provider=iomap\n");
  virtio_rng_dump_machine_info(out);
#else
  fprintf(out, "device.virtio_rng.provider=none\n");
#endif
#endif

  machine_info_write_bool(out, "device.goldfish_rtc.enabled", ISDEF(CONFIG_HAS_GOLDFISH_RTC));
#ifdef CONFIG_HAS_GOLDFISH_RTC
  machine_info_write_hex(out, "device.goldfish_rtc.mmio", DEV_GOLDFISH_RTC_MMIO);
  fprintf(out, "device.goldfish_rtc.irq=4\n");
  goldfish_rtc_dump_machine_info(out);
#endif

#ifdef CONFIG_SOC_SIM
  machine_info_write_bool(out, "device.virtio_net.enabled", false);
  fprintf(out, "device.virtio_net.provider=none\n");
#else
  machine_info_write_bool(out, "device.virtio_net.enabled", ISDEF(CONFIG_HAS_VIRTIO_NET));
#ifdef CONFIG_HAS_VIRTIO_NET
  machine_info_write_hex(out, "device.virtio_net.mmio", DEV_VIRTIO_NET_MMIO);
  fprintf(out, "device.virtio_net.irq=5\n");
  fprintf(out, "device.virtio_net.provider=iomap\n");
  virtio_net_dump_machine_info(out);
#else
  fprintf(out, "device.virtio_net.provider=none\n");
#endif
#endif

#ifdef CONFIG_SOC_SIM
  machine_info_write_bool(out, "device.virtio_input.enabled", false);
  fprintf(out, "device.virtio_input.provider=none\n");
#else
  machine_info_write_bool(out, "device.virtio_input.enabled",
      ISDEF(CONFIG_HAS_VIRTIO_INPUT));
#ifdef CONFIG_HAS_VIRTIO_INPUT
  machine_info_write_hex(out, "device.virtio_input.mmio",
      DEV_VIRTIO_INPUT_MMIO);
  fprintf(out, "device.virtio_input.irq=7\n");
  fprintf(out, "device.virtio_input.provider=iomap\n");
  virtio_input_dump_machine_info(out);
#else
  fprintf(out, "device.virtio_input.provider=none\n");
#endif
#endif

  machine_info_write_bool(out, "device.syscon_reset.enabled", ISDEF(CONFIG_HAS_SYSCON_RESET));
#ifdef CONFIG_HAS_SYSCON_RESET
  machine_info_write_hex(out, "device.syscon_reset.mmio", DEV_SYSCON_RESET_MMIO);
  machine_info_write_hex(out, "device.syscon_reset.poweroff_value", CONFIG_SYSCON_POWEROFF_VALUE);
  machine_info_write_hex(out, "device.syscon_reset.reboot_value", CONFIG_SYSCON_REBOOT_VALUE);
#endif

  dump_mmio_maps(out);
  dump_pio_maps(out);
}

static void dump_machine_info_and_exit() {
  if (machine_info_file == NULL) {
    return;
  }

  FILE *out = stdout;
  if (strcmp(machine_info_file, "-") != 0) {
    out = fopen(machine_info_file, "w");
    Assert(out != NULL, "Can not open machine info file '%s'", machine_info_file);
  }
  // 这里导出的是已初始化后的机器契约，用于 e2e 在不开 guest 的情况下验证 VM 形态。
  dump_machine_info(out);
  int output_errno = 0;
  if (fflush(out) != 0) {
    output_errno = errno != 0 ? errno : EIO;
  } else if (ferror(out)) {
    output_errno = EIO;
  }
  if (out != stdout) {
    if (fclose(out) != 0 && output_errno == 0) {
      output_errno = errno != 0 ? errno : EIO;
    }
  }
  int exit_status = EXIT_SUCCESS;
  if (output_errno != 0) {
    fprintf(stderr, "nemu: can not finish machine-info output '%s': %s\n",
        machine_info_file, strerror(output_errno));
    exit_status = EXIT_FAILURE;
  }
#ifdef CONFIG_HAS_DISK
  if (!virtio_blk_shutdown()) {
    fprintf(stderr,
        "nemu: block storage shutdown failed during machine-info; forcing failure\n");
    exit_status = EXIT_FAILURE;
  }
#endif
  exit(exit_status);
}

static void run_monitor_cmds_and_exit() {
  if (monitor_cmd_count == 0) {
    return;
  }

  for (int i = 0; i < monitor_cmd_count; i++) {
    char *line = strdup(monitor_cmds[i]);
    Assert(line != NULL, "Can not duplicate monitor command");
    printf("[monitor-cmd] %s\n", line);
    int rc = sdb_exec_line(line);
    free(line);
    if (rc < 0) {
      break;
    }
  }

  if (nemu_state.state == NEMU_STOP) {
    nemu_state.state = NEMU_QUIT;
  }
  int exit_status = is_exit_status_bad();
#ifdef CONFIG_HAS_DISK
  if (!virtio_blk_shutdown()) {
    fprintf(stderr,
        "nemu: block storage shutdown failed during monitor-command; forcing failure\n");
    exit_status = EXIT_FAILURE;
  }
#endif
  exit(exit_status);
}

/* 用于解析命令行参数 */
static int parse_args(int argc, char *argv[]) {
  enum {
    OPT_LOAD = 256,
    OPT_MAX,
    OPT_BLOCK,
    OPT_DISK,
    OPT_BLOCK_OVERLAY,
    OPT_BOOT_HARTID,
    OPT_BOOT_DTB,
    OPT_MACHINE_INFO,
    OPT_MONITOR_CMD,
    OPT_QMP,
    OPT_GDBSTUB,
    OPT_NET_TAP,
    OPT_TOHOST,
  };
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"image"    , required_argument, NULL, 'i'},
    {"load"     , required_argument, NULL, OPT_LOAD},
    {"max"      , required_argument, NULL, OPT_MAX},
    {"max-insts", required_argument, NULL, OPT_MAX},
    {"block"    , required_argument, NULL, OPT_BLOCK},
    {"disk"     , required_argument, NULL, OPT_DISK},
    {"block-overlay", required_argument, NULL, OPT_BLOCK_OVERLAY},
    {"boot-hartid", required_argument, NULL, OPT_BOOT_HARTID},
    {"boot-dtb" , required_argument, NULL, OPT_BOOT_DTB},
    {"machine-info", required_argument, NULL, OPT_MACHINE_INFO},
    {"monitor-cmd", required_argument, NULL, OPT_MONITOR_CMD},
    {"qmp"      , required_argument, NULL, OPT_QMP},
    {"gdbstub"  , required_argument, NULL, OPT_GDBSTUB},
    {"net-tap"  , required_argument, NULL, OPT_NET_TAP},
    {"tohost"   , required_argument, NULL, OPT_TOHOST},
    {"help"     , no_argument      , NULL, 'h'},
    {"elf"      , required_argument, NULL, 'e'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhi:l:d:p:e:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;                                //批处理模式
      case 'i': img_file = optarg; break;                                    //显式主镜像
      case 'p': sscanf(optarg, "%d", &difftest_port); break;                
      case 'l': log_file = optarg; break;                                   //日志文件
      case 'd': diff_so_file = optarg; break;                               //difftest
      case 'e': elf_file = optarg; break;                                   //elf_log用
      case OPT_LOAD: parse_load_image(optarg); break;
      case OPT_MAX: sdb_set_batch_limit(strtoull(optarg, NULL, 0)); break;
      case OPT_BLOCK:
      case OPT_DISK:
#ifdef CONFIG_HAS_DISK
        block_file = optarg;
#else
        printf("--block/--disk requires CONFIG_HAS_DISK\n");
        exit(1);
#endif
        break;
      case OPT_BLOCK_OVERLAY:
#ifdef CONFIG_HAS_DISK
        block_overlay_file = optarg;
#else
        printf("--block-overlay requires CONFIG_HAS_DISK\n");
        exit(1);
#endif
        break;
      case OPT_BOOT_HARTID:
        boot_hartid = strtoull(optarg, NULL, 0);
        boot_hartid_valid = true;
        break;
      case OPT_BOOT_DTB:
        boot_dtb = strtoull(optarg, NULL, 0);
        boot_dtb_valid = true;
        break;
      case OPT_MACHINE_INFO: machine_info_file = optarg; break;
      case OPT_MONITOR_CMD: add_monitor_cmd(optarg); break;
      case OPT_QMP: qmp_set_port(atoi(optarg)); break;
      case OPT_GDBSTUB: gdbstub_set_port(atoi(optarg)); break;
      case OPT_TOHOST: {
        // This only enables external arch-test exits; normal AM/batch exits stay unchanged.
        char *end = NULL;
        uint64_t addr = strtoull(optarg, &end, 0);
        Assert(end != optarg && end != NULL && *end == '\0',
            "invalid --tohost address: %s", optarg);
        paddr_tohost_set_addr((paddr_t)addr);
        break;
      }
      case OPT_NET_TAP:
#ifdef CONFIG_HAS_VIRTIO_NET
        virtio_net_set_tap(optarg);
#else
        printf("--net-tap requires CONFIG_HAS_VIRTIO_NET\n");
        exit(1);
#endif
        break;
      case 1: img_file = optarg; return 0;                                  //镜像文件
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-i,--image=FILE         load main image at reset vector\n");
        printf("\t   --load=ADDR:FILE     load extra image at physical address\n");
        printf("\t   --max-insts=N        stop batch run after N dispatched instruction attempts\n");
        printf("\t   --boot-hartid=N      set boot argument a0 before guest start\n");
        printf("\t   --boot-dtb=ADDR      set boot argument a1 before guest start\n");
        printf("\t   --machine-info=FILE  dump initialized machine/device contract and exit\n");
        printf("\t   --monitor-cmd=CMD    run one SDB command after init and exit (repeatable)\n");
        printf("\t   --qmp=PORT           wait for startup QMP, then same-socket runtime query/stop/cont/events/device introspection/quit (exclusive with --gdbstub)\n");
        printf("\t   --gdbstub=PORT       wait for a startup GDB remote client on localhost (exclusive with --qmp)\n");
        printf("\t   --net-tap=IFNAME     attach virtio-net to an existing host TAP interface\n");
        printf("\t   --tohost=ADDR        stop when a riscv-tests/ACT4 tohost word becomes non-zero\n");
        printf("\t   --block=FILE         attach block image (Linux path placeholder)\n");
        printf("\t   --block-overlay=FILE write block changes to sparse overlay\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);//解析主镜像、磁盘、DTB、hartid、日志、difftest、QMP、GDB等参数
  if (qmp_is_enabled() && gdbstub_is_enabled()) {
    fprintf(stderr,
        "nemu: --qmp and --gdbstub cannot be enabled together; "
        "both own CPU run-control\n");
    exit(EXIT_FAILURE);
  }

  /* Set random seed. */
  //初始化随机数种子
  init_rand();

  //打开日志文件
  /* Open the log file. */
  init_log(log_file);

  //设置磁盘backing/overlay路径，必须发生在init_device()前，否则磁盘设备不知道应该打开哪个文件
#ifdef CONFIG_HAS_DISK
  if (block_file != NULL) {
    disk_set_image(block_file);
    Log("Block image requested: %s", block_file);
  }
  if (block_overlay_file != NULL) {
    disk_set_overlay(block_overlay_file);
    Log("Block overlay requested: %s", block_overlay_file);
  }
#endif

  //初始化物理内存
  /* Initialize memory. */
  init_mem();

  IFDEF(CONFIG_BPU, init_bpu());

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Perform ISA dependent initialization. */
  init_isa();//先在RESET_VECTOR放一个内建测试镜像，再清空cpu/csr
  //将cpu.pc = RESET_VECTOR,cpu.priv=m-mode,x0=0
  //然后设置启动ABI
  //a0/x10=boot hart id
  //a1/x11 = dtb地址
  monitor_apply_boot_arguments();

  dump_machine_info_and_exit();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);
  /* --load segments are part of the initial machine state, not DUT-only data. */
  for (int i = 0; i < load_image_count; i++) {
    difftest_sync_memory(load_images[i].addr, load_images[i].size);
  }

  //调试器初始化
  /* Initialize the simple debugger. */
  init_sdb();

  IFDEF(CONFIG_ITRACE, init_disasm());

  //ELF_log调用
  IFDEF(CONFIG_FTRACE, init_ftrace(elf_file));

  //初始化qmp
  QMPStartupResult qmp_startup_result = qmp_wait_for_client_if_enabled();
  if (qmp_startup_result != QMP_STARTUP_RUN_GUEST) {
    int exit_status = qmp_startup_result == QMP_STARTUP_EXIT_SUCCESS ?
      EXIT_SUCCESS : EXIT_FAILURE;
#ifdef CONFIG_HAS_DISK
    if (!virtio_blk_shutdown()) {
      fprintf(stderr,
          "nemu: block storage shutdown failed during startup QMP exit; forcing failure\n");
      exit_status = EXIT_FAILURE;
    }
#endif
    exit(exit_status);
  }
  //初始化gdb
  gdbstub_wait_for_client_if_enabled();
  run_monitor_cmds_and_exit();

  /* Display welcome message. */
  welcome();//初始化完成
}
#else // CONFIG_TARGET_AM
static long load_img() {
  extern char bin_start, bin_end;
  size_t size = &bin_end - &bin_start;
  Log("img size = %ld", size);
  memcpy(guest_to_host(RESET_VECTOR), &bin_start, size);
  return size;
}//将用户指定的镜像文件（二进制程序）读入到模拟器的内存中（通常从0x80000000开始）

void am_init_monitor() {
  init_rand();
  init_mem();
  IFDEF(CONFIG_BPU, init_bpu());
  init_isa();
  load_img();
  IFDEF(CONFIG_DEVICE, init_device());
  welcome();
}
#endif
