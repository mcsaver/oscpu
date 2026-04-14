#include "memory/paddr.h"

#include "device/map.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "utils.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

namespace npc {

namespace {

std::vector<uint8_t> g_pmem;

uint32_t host_read_u32(const uint8_t *base) {
  return static_cast<uint32_t>(base[0]) |
         (static_cast<uint32_t>(base[1]) << 8) |
         (static_cast<uint32_t>(base[2]) << 16) |
         (static_cast<uint32_t>(base[3]) << 24);
}

void host_write_masked(uint8_t *base, uint32_t data, uint32_t mask) {
  for (int lane = 0; lane < 4; ++lane) {
    if ((mask & (1u << lane)) != 0) {
      base[lane] = static_cast<uint8_t>(data >> (lane * 8));
    }
  }
}

const char *access_kind_name(BusAccessKind kind) {
  switch (kind) {
    case BusAccessKind::kIfetch: return "fetch";
    case BusAccessKind::kLoad: return "load";
    case BusAccessKind::kStore: return "store";
    default: return "access";
  }
}

}  // namespace

void init_mem() {
  g_pmem.assign(kPmemSize, 0);
  Log("physical memory area [0x%08x, 0x%08x]", kPmemBase, kPmemBase + static_cast<uint32_t>(kPmemSize) - 1);
}

bool in_pmem(uint32_t addr) {
  if (addr < kPmemBase || g_pmem.empty()) {
    return false;
  }

  const uint64_t offset = static_cast<uint64_t>(addr - kPmemBase);
  return offset + sizeof(uint32_t) <= g_pmem.size();
}

uint8_t *guest_to_host(uint32_t addr) {
  return g_pmem.data() + (addr - kPmemBase);
}

bool load_img(const std::string &image_path) {
  FILE *image = std::fopen(image_path.c_str(), "rb");
  if (image == nullptr) {
    std::perror("[npc] fopen image");
    return false;
  }

  if (std::fseek(image, 0, SEEK_END) != 0) {
    std::perror("[npc] fseek image");
    std::fclose(image);
    return false;
  }

  const long image_size = std::ftell(image);
  if (image_size < 0) {
    std::perror("[npc] ftell image");
    std::fclose(image);
    return false;
  }

  if (std::fseek(image, 0, SEEK_SET) != 0) {
    std::perror("[npc] rewind image");
    std::fclose(image);
    return false;
  }

  if (static_cast<uint64_t>(image_size) > g_pmem.size()) {
    std::fprintf(stderr,
                 "[npc] image is too large: %ld bytes, pmem capacity is %zu bytes\n",
                 image_size, g_pmem.size());
    std::fclose(image);
    return false;
  }

  // 这里让镜像装载只负责“把程序摆进 PMEM”，而不再顺手管运行循环或设备初始化，避免主程序继续把职责搅在一起。
  std::memset(g_pmem.data(), 0, g_pmem.size());
  const std::size_t read_size = std::fread(guest_to_host(kResetPc), 1, static_cast<std::size_t>(image_size), image);
  std::fclose(image);

  if (read_size != static_cast<std::size_t>(image_size)) {
    std::fprintf(stderr,
                 "[npc] short read when loading image: expect %ld bytes, got %zu bytes\n",
                 image_size, read_size);
    return false;
  }

  Log("image loaded: %s (%ld bytes) -> 0x%08x",
      image_path.c_str(), image_size, kResetPc);
  return true;
}

bool paddr_read(uint32_t addr, uint32_t *data, BusAccessKind kind) {
  if (data == nullptr) {
    return false;
  }

  if (in_pmem(addr)) {
    *data = host_read_u32(guest_to_host(addr));
    if (kind == BusAccessKind::kLoad && mtrace_enabled()) {
      Log("mtrace load addr=0x%08x data=0x%08x", addr, *data);
    }
    return true;
  }

  // 取指不应该偷偷穿过 MMIO；把它显式拦住后，mtrace 也就不会再被 ifetch 噪音淹没。
  if (kind != BusAccessKind::kIfetch && mmio_read(addr, data, kind)) {
    return true;
  }

  std::fprintf(stderr, "[npc] %s out of bound at 0x%08x\n", access_kind_name(kind), addr);
  return false;
}

bool paddr_write(uint32_t addr, uint32_t data, uint32_t mask, BusAccessKind kind) {
  if (in_pmem(addr)) {
    host_write_masked(guest_to_host(addr), data, mask);
    if (kind == BusAccessKind::kStore && mtrace_enabled()) {
      Log("mtrace store addr=0x%08x data=0x%08x mask=0x%x", addr, data, mask);
    }
    return true;
  }

  if (mmio_write(addr, data, mask, kind)) {
    return true;
  }

  std::fprintf(stderr, "[npc] %s out of bound at 0x%08x\n", access_kind_name(kind), addr);
  return false;
}

}  // namespace npc