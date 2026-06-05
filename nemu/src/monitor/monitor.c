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
#include <ftrace.h>

void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void disk_set_image(const char *path);
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

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *block_file = NULL;
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

/* 用于解析命令行参数 */
static int parse_args(int argc, char *argv[]) {
  enum {
    OPT_LOAD = 256,
    OPT_MAX,
    OPT_BLOCK,
    OPT_DISK,
    OPT_BOOT_HARTID,
    OPT_BOOT_DTB,
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
    {"boot-hartid", required_argument, NULL, OPT_BOOT_HARTID},
    {"boot-dtb" , required_argument, NULL, OPT_BOOT_DTB},
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
      case OPT_BOOT_HARTID:
        boot_hartid = strtoull(optarg, NULL, 0);
        boot_hartid_valid = true;
        break;
      case OPT_BOOT_DTB:
        boot_dtb = strtoull(optarg, NULL, 0);
        boot_dtb_valid = true;
        break;
      case 1: img_file = optarg; return 0;                                  //镜像文件
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-i,--image=FILE         load main image at reset vector\n");
        printf("\t   --load=ADDR:FILE     load extra image at physical address\n");
        printf("\t   --max-insts=N        stop batch run after N retired instructions\n");
        printf("\t   --boot-hartid=N      set boot argument a0 before guest start\n");
        printf("\t   --boot-dtb=ADDR      set boot argument a1 before guest start\n");
        printf("\t   --block=FILE         attach block image (Linux path placeholder)\n");
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
