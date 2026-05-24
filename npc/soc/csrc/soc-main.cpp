#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <verilated.h>
#include "VysyxSoCFull.h"

namespace {

constexpr uint32_t kMromBase = 0x20000000u;
constexpr size_t kMromSize = 0x1000u;
constexpr size_t kFlashSize = 16u * 1024u * 1024u;
constexpr uint64_t kDefaultMaxCycles = 5000000ull;

uint8_t g_mrom[kMromSize];
uint8_t *g_flash = nullptr;
size_t g_mrom_image_size = 0;
size_t g_flash_image_size = 0;
bool g_exit_seen = false;
uint32_t g_exit_is_ebreak = 0;
uint32_t g_exit_is_ecall = 0;
uint32_t g_exit_code = 0;
uint32_t g_exit_pc = 0;
bool g_commit_seen = false;
uint32_t g_last_commit_pc = 0;
uint32_t g_last_commit_inst = 0;
uint32_t g_last_commit_state = 0;

uint32_t load_le32(const uint8_t *mem, size_t size, uint32_t addr) {
  uint32_t data = 0;
  for (size_t lane = 0; lane < 4; ++lane) {
    if ((size_t)addr + lane < size) {
      data |= (uint32_t)mem[(size_t)addr + lane] << (lane * 8);
    }
  }
  return data;
}

void store_builtin_program() {
  std::memset(g_mrom, 0, sizeof(g_mrom));
  // 无镜像时保留一个最小 GOOD TRAP 程序，便于 make soc 后直接 smoke。
  const uint32_t program[] = {
    0x00000513u, // li a0, 0
    0x00100073u, // ebreak
  };
  for (size_t i = 0; i < sizeof(program) / sizeof(program[0]); ++i) {
    g_mrom[i * 4 + 0] = (uint8_t)(program[i] >> 0);
    g_mrom[i * 4 + 1] = (uint8_t)(program[i] >> 8);
    g_mrom[i * 4 + 2] = (uint8_t)(program[i] >> 16);
    g_mrom[i * 4 + 3] = (uint8_t)(program[i] >> 24);
  }
  g_mrom_image_size = sizeof(program);
}

bool load_file_to_mrom(const char *path) {
  FILE *fp = std::fopen(path, "rb");
  if (!fp) {
    std::perror("[ysyxSoCFull] fopen image");
    return false;
  }
  if (std::fseek(fp, 0, SEEK_END) != 0) {
    std::perror("[ysyxSoCFull] fseek");
    std::fclose(fp);
    return false;
  }
  long image_size = std::ftell(fp);
  if (image_size < 0) {
    std::perror("[ysyxSoCFull] ftell");
    std::fclose(fp);
    return false;
  }
  if ((uint64_t)image_size > kMromSize) {
    std::fprintf(stderr,
                 "[ysyxSoCFull] image too large for 4KB MROM: %ld bytes\n",
                 image_size);
    std::fclose(fp);
    return false;
  }
  if (std::fseek(fp, 0, SEEK_SET) != 0) {
    std::perror("[ysyxSoCFull] rewind");
    std::fclose(fp);
    return false;
  }

  std::memset(g_mrom, 0, sizeof(g_mrom));
  size_t nread = std::fread(g_mrom, 1, (size_t)image_size, fp);
  std::fclose(fp);
  if (nread != (size_t)image_size) {
    std::fprintf(stderr, "[ysyxSoCFull] short read: expect %ld, got %zu\n",
                 image_size, nread);
    return false;
  }
  g_mrom_image_size = (size_t)image_size;

  // flash_read() 复用同一份镜像内容，后续 B2 XIP/flash 测试可在不改 harness 的情况下先读到确定数据。
  if (!g_flash) {
    g_flash = (uint8_t *)std::calloc(1, kFlashSize);
    if (!g_flash) {
      std::perror("[ysyxSoCFull] calloc flash");
      return false;
    }
  } else {
    std::memset(g_flash, 0, kFlashSize);
  }
  g_flash_image_size = std::min((size_t)image_size, kFlashSize);
  std::memcpy(g_flash, g_mrom, g_flash_image_size);

  std::fprintf(stderr, "[ysyxSoCFull] loaded image %s, size = %zu bytes\n",
               path, g_mrom_image_size);
  return true;
}

struct Args {
  const char *image = nullptr;
  uint64_t max_cycles = kDefaultMaxCycles;
};

bool parse_uint64(const char *text, uint64_t *value) {
  char *end = nullptr;
  unsigned long long parsed = std::strtoull(text, &end, 0);
  if (!text[0] || (end && *end)) return false;
  *value = (uint64_t)parsed;
  return true;
}

bool parse_args(int argc, char **argv, Args *args) {
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "--help") == 0) {
      std::printf("Usage: %s [image.bin] [--max-cycles N|-m N]\n", argv[0]);
      return false;
    }
    if (std::strcmp(argv[i], "--max-cycles") == 0 || std::strcmp(argv[i], "-m") == 0) {
      if (++i >= argc || !parse_uint64(argv[i], &args->max_cycles)) {
        std::fprintf(stderr, "[ysyxSoCFull] bad max cycle argument\n");
        return false;
      }
      continue;
    }
    if (std::strncmp(argv[i], "--max-cycles=", 13) == 0) {
      if (!parse_uint64(argv[i] + 13, &args->max_cycles)) {
        std::fprintf(stderr, "[ysyxSoCFull] bad max cycle argument\n");
        return false;
      }
      continue;
    }
    if (argv[i][0] == '-') {
      std::fprintf(stderr, "[ysyxSoCFull] unknown option: %s\n", argv[i]);
      return false;
    }
    args->image = argv[i];
  }
  return true;
}

void init_inputs(VysyxSoCFull &top) {
  top.externalPins_gpio_in = 0;
  top.externalPins_ps2_clk = 1;
  top.externalPins_ps2_data = 1;
  top.externalPins_uart_rx = 1;
}

void tick(VysyxSoCFull &top) {
  top.clock = 0;
  top.eval();
  top.clock = 1;
  top.eval();
}

} // namespace

extern "C" void flash_read(int32_t addr, int32_t *data) {
  if (!data) return;
  uint32_t offset = (uint32_t)addr;
  *data = (g_flash && offset < kFlashSize)
            ? (int32_t)load_le32(g_flash, kFlashSize, offset)
            : 0;
}

extern "C" void mrom_read(int32_t raddr, int32_t *rdata) {
  if (!rdata) return;
  uint32_t addr = (uint32_t)raddr;
  *rdata = (addr >= kMromBase && addr < kMromBase + kMromSize)
             ? (int32_t)load_le32(g_mrom, kMromSize, addr - kMromBase)
             : 0;
}

extern "C" void npc_soc_exit_event(uint32_t is_ebreak, uint32_t is_ecall,
                                   uint32_t code, uint32_t pc) {
  g_exit_seen = true;
  g_exit_is_ebreak = is_ebreak;
  g_exit_is_ecall = is_ecall;
  g_exit_code = code;
  g_exit_pc = pc;
}

extern "C" void npc_soc_commit_event(uint32_t pc, uint32_t inst, uint32_t state) {
  g_commit_seen = true;
  g_last_commit_pc = pc;
  g_last_commit_inst = inst;
  g_last_commit_state = state;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Args args;
  if (!parse_args(argc, argv, &args)) return 1;
  store_builtin_program();
  if (args.image && !load_file_to_mrom(args.image)) return 1;

  VysyxSoCFull top;
  init_inputs(top);
  top.reset = 1;
  for (int i = 0; i < 20; ++i) tick(top);

  top.reset = 0;
  uint64_t cycles = 0;
  for (; (args.max_cycles == 0 || cycles < args.max_cycles) &&
         !Verilated::gotFinish() && !g_exit_seen; ++cycles) {
    tick(top);
  }

  top.final();
  if (g_exit_seen) {
    bool good = (g_exit_is_ebreak != 0) && (g_exit_code == 0);
    std::fprintf(stderr,
                 "\n[ysyxSoCFull] HIT %s TRAP via %s at pc=0x%08x, code=%u, cycles=%llu\n",
                 good ? "GOOD" : "BAD",
                 g_exit_is_ebreak ? "ebreak" : (g_exit_is_ecall ? "ecall" : "unknown"),
                 g_exit_pc, g_exit_code, (unsigned long long)cycles);
    return good ? 0 : 1;
  }

  std::fprintf(stderr,
               "\n[ysyxSoCFull] timeout or finish before AM ebreak, cycles=%llu",
               (unsigned long long)cycles);
  if (g_commit_seen) {
    std::fprintf(stderr, ", last_commit_pc=0x%08x, inst=0x%08x, state=%u",
                 g_last_commit_pc, g_last_commit_inst, g_last_commit_state);
  }
  std::fprintf(stderr, "\n");
  return 1;
}
