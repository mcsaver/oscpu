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
#include <cpu/bpu.h>
#include <memory/paddr.h>
#include <device/map.h>
#include <ftrace.h>
#include <utils.h>

void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void disk_set_image(const char *path);
void disk_set_overlay(const char *path);
#ifdef CONFIG_HAS_DISK
void virtio_blk_dump_machine_info(FILE *out);
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
#include <getopt.h>
#include "sdb/sdb.h"
#include "qmp.h"
#include "gdbstub.h"

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *block_file = NULL;
static char *block_overlay_file = NULL;
static char *machine_info_file = NULL;
static char *elf_file = NULL; //添加ELF文件参数和ftrace初始化
static int difftest_port = 1234;
static bool boot_hartid_valid = false;
static bool boot_dtb_valid = false;
static word_t boot_hartid = 0;
static word_t boot_dtb = 0;

#define NEMU_MAX_LOAD_IMAGES 16

typedef struct {
  paddr_t addr;
  const char *path;
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
  uint64_t addr = strtoull(addr_buf, &end, 0);
  Assert(end != addr_buf && *end == '\0', "invalid --load address: %s", addr_buf);

  load_images[load_image_count++] = (LoadImageSpec){
    .addr = (paddr_t)addr,
    .path = sep + 1,
  };
}

static long load_file_to_pmem(const char *path, paddr_t addr) {
  FILE *fp = fopen(path, "rb");
  Assert(fp, "Can not open '%s'", path);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  rewind(fp);

  Assert(addr >= PMEM_LEFT && (uint64_t)addr + (uint64_t)size - 1 <= PMEM_RIGHT,
      "image '%s' range [" FMT_PADDR ", " FMT_PADDR "] is out of pmem ["
      FMT_PADDR ", " FMT_PADDR "]",
      path, addr, (paddr_t)((uint64_t)addr + (uint64_t)size - 1),
      PMEM_LEFT, PMEM_RIGHT);

  int ret = fread(guest_to_host(addr), size, 1, fp);
  assert(ret == 1);
  fclose(fp);

  Log("Load image %s at " FMT_PADDR ", size = %ld", path, addr, size);
  return size;
}

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    for (int i = 0; i < load_image_count; i++) {
      load_file_to_pmem(load_images[i].path, load_images[i].addr);
    }
    return 4096; // built-in image size
  }

  // 主镜像保持旧语义装载到 RESET_VECTOR；额外 Linux/OpenSBI 产物用 --load 指定地址。
  long size = load_file_to_pmem(img_file, RESET_VECTOR);
  for (int i = 0; i < load_image_count; i++) {
    load_file_to_pmem(load_images[i].path, load_images[i].addr);
  }
  return size;
}

static void machine_info_write_bool(FILE *out, const char *key, bool value) {
  fprintf(out, "%s=%d\n", key, value ? 1 : 0);
}

static void machine_info_write_hex(FILE *out, const char *key, uint64_t value) {
  fprintf(out, "%s=0x%08" PRIx64 "\n", key, value);
}

static void dump_machine_info(FILE *out) {
  fprintf(out, "nemu.machine_info.version=1\n");
  fprintf(out, "config.isa=%s\n", CONFIG_ISA);
  fprintf(out, "config.engine=%s\n", CONFIG_ENGINE);
  machine_info_write_bool(out, "config.mode_system", ISDEF(CONFIG_MODE_SYSTEM));
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
  machine_info_write_bool(out, "config.interpreter_wide_ifetch", ISDEF(CONFIG_INTERPRETER_WIDE_IFETCH));
  machine_info_write_bool(out, "config.interpreter_decode_cache", ISDEF(CONFIG_INTERPRETER_DECODE_CACHE));
  machine_info_write_bool(out, "config.interpreter_intr_fast_flag", ISDEF(CONFIG_INTERPRETER_INTR_FAST_FLAG));

  // 能力边界清单把 QEMU-like 缺口变成可执行 gate，避免以后把单个切片误判为完整 VM。
  fprintf(out, "platform.hart_count=1\n");
  fprintf(out, "platform.smp=unsupported\n");
  fprintf(out, "platform.pci=unsupported\n");
  fprintf(out, "platform.virtio_transport=mmio\n");
  fprintf(out, "platform.virtio_mmio_slots=3\n");
  fprintf(out, "monitor.machine_info=enabled\n");
  fprintf(out, "monitor.oneshot_cmd=enabled\n");
  fprintf(out, "monitor.qmp=%s\n", qmp_capability());
  fprintf(out, "monitor.qmp.mode=startup-query-cont-stop-runtime-query-quit\n");
  fprintf(out, "debug.gdbstub=%s\n", gdbstub_capability());
  fprintf(out, "debug.gdbstub.mode=startup-readonly\n");
  fprintf(out, "snapshot.vm_state=unsupported\n");
  fprintf(out, "snapshot.block=raw-sparse-overlay\n");
  fprintf(out, "block.format=raw\n");

#ifdef CONFIG_ISA_riscv
  // 开机前暴露 guest time CSR 的真实来源，便于 e2e 发现 timebase 漂移。
  fprintf(out, "time.clint.enabled=1\n");
  fprintf(out, "time.clint.timebase_hz=%" PRIu64 "\n", isa_riscv_clint_timebase_hz());
  fprintf(out, "time.clint.source=%s\n", isa_riscv_clint_time_source());
  fprintf(out, "time.csr_time_source=clint_mtime\n");
#endif

  machine_info_write_hex(out, "memory.base", CONFIG_MBASE);
  machine_info_write_hex(out, "memory.size", CONFIG_MSIZE);
  machine_info_write_hex(out, "memory.end", (uint64_t)CONFIG_MBASE + CONFIG_MSIZE - 1);
  machine_info_write_bool(out, "boot.hartid.valid", boot_hartid_valid);
  machine_info_write_hex(out, "boot.hartid", boot_hartid);
  machine_info_write_bool(out, "boot.dtb.valid", boot_dtb_valid);
  machine_info_write_hex(out, "boot.dtb", boot_dtb);

  machine_info_write_bool(out, "device.serial.enabled", ISDEF(CONFIG_HAS_SERIAL));
#ifdef CONFIG_HAS_SERIAL
  machine_info_write_hex(out, "device.serial.mmio", CONFIG_SERIAL_MMIO);
  fprintf(out, "device.serial.irq=1\n");
#endif
  machine_info_write_bool(out, "device.virtio_blk.enabled", ISDEF(CONFIG_HAS_DISK));
#ifdef CONFIG_HAS_DISK
  machine_info_write_hex(out, "device.virtio_blk.mmio", CONFIG_DISK_CTL_MMIO);
  fprintf(out, "device.virtio_blk.irq=2\n");
  virtio_blk_dump_machine_info(out);
#endif
  machine_info_write_bool(out, "device.virtio_rng.enabled", ISDEF(CONFIG_HAS_VIRTIO_RNG));
#ifdef CONFIG_HAS_VIRTIO_RNG
  machine_info_write_hex(out, "device.virtio_rng.mmio", CONFIG_VIRTIO_RNG_MMIO);
  fprintf(out, "device.virtio_rng.irq=3\n");
#endif
  machine_info_write_bool(out, "device.goldfish_rtc.enabled", ISDEF(CONFIG_HAS_GOLDFISH_RTC));
#ifdef CONFIG_HAS_GOLDFISH_RTC
  machine_info_write_hex(out, "device.goldfish_rtc.mmio", CONFIG_GOLDFISH_RTC_MMIO);
  fprintf(out, "device.goldfish_rtc.irq=4\n");
#endif
  machine_info_write_bool(out, "device.virtio_net.enabled", ISDEF(CONFIG_HAS_VIRTIO_NET));
#ifdef CONFIG_HAS_VIRTIO_NET
  machine_info_write_hex(out, "device.virtio_net.mmio", CONFIG_VIRTIO_NET_MMIO);
  fprintf(out, "device.virtio_net.irq=5\n");
#endif
  machine_info_write_bool(out, "device.syscon_reset.enabled", ISDEF(CONFIG_HAS_SYSCON_RESET));
#ifdef CONFIG_HAS_SYSCON_RESET
  machine_info_write_hex(out, "device.syscon_reset.mmio", CONFIG_SYSCON_RESET_MMIO);
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
  if (out != stdout) {
    fclose(out);
  }
  exit(0);
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
  exit(is_exit_status_bad());
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
      case OPT_DISK: block_file = optarg; break;
      case OPT_BLOCK_OVERLAY: block_overlay_file = optarg; break;
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
      case 1: img_file = optarg; return 0;                                  //镜像文件
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-i,--image=FILE         load main image at reset vector\n");
        printf("\t   --load=ADDR:FILE     load extra image at physical address\n");
        printf("\t   --max-insts=N        stop batch run after N retired instructions\n");
        printf("\t   --boot-hartid=N      set boot argument a0 before guest start\n");
        printf("\t   --boot-dtb=ADDR      set boot argument a1 before guest start\n");
        printf("\t   --machine-info=FILE  dump initialized machine/device contract and exit\n");
        printf("\t   --monitor-cmd=CMD    run one SDB command after init and exit (repeatable)\n");
        printf("\t   --qmp=PORT           wait for startup QMP, then same-socket runtime query/quit\n");
        printf("\t   --gdbstub=PORT       wait for a startup GDB remote client on localhost\n");
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
  parse_args(argc, argv);

  /* Set random seed. */
  //初始化随机数种子
  init_rand();

  //打开日志文件
  /* Open the log file. */
  init_log(log_file);
  if (block_file != NULL) {
    disk_set_image(block_file);
    Log("Block image requested: %s", block_file);
  }
  if (block_overlay_file != NULL) {
    disk_set_overlay(block_overlay_file);
    Log("Block overlay requested: %s", block_overlay_file);
  }

  //初始化物理内存
  /* Initialize memory. */
  init_mem();

  IFDEF(CONFIG_BPU, init_bpu());

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Perform ISA dependent initialization. */
  init_isa();
  if (boot_hartid_valid) {
    cpu.gpr[10] = boot_hartid;
    Log("Boot argument a0/hartid = " FMT_WORD, boot_hartid);
  }
  if (boot_dtb_valid) {
    cpu.gpr[11] = boot_dtb;
    Log("Boot argument a1/dtb = " FMT_WORD, boot_dtb);
  }
  dump_machine_info_and_exit();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  //调试器初始化
  /* Initialize the simple debugger. */
  init_sdb();

  IFDEF(CONFIG_ITRACE, init_disasm());

  //ELF_log调用
  IFDEF(CONFIG_FTRACE, init_ftrace(elf_file));

  if (qmp_wait_for_client_if_enabled()) {
    exit(0);
  }
  gdbstub_wait_for_client_if_enabled();
  run_monitor_cmds_and_exit();

  /* Display welcome message. */
  welcome();
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
