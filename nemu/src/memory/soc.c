/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
***************************************************************************************/

#include <memory/soc.h>
#include <device/uart16550.h>
#include <difftest-def.h>
#include <platform/platform-map.h>

#ifdef CONFIG_SOC_SIM
#include <isa.h>
#include <utils.h>

typedef enum {
  SOC_REGION_BACKEND_BYTES,
  SOC_REGION_BACKEND_PMEM,
  SOC_REGION_BACKEND_UART16550,
  SOC_REGION_BACKEND_EMPTY_FLASH,
} SocRegionBackend;

typedef struct {
  SocSimRegionInfo info;
  SocRegionBackend backend;
  uint8_t *data;
} SocRegion;

static Uart16550 *soc_uart = NULL;
static const Uart16550BusProfile soc_uart_bus_profile =
    UART16550_BUS_PROFILE_8BIT;

/*
 * ysyxSoC physical address map.  This table is both the decoder's source and
 * the enumerable machine-topology contract exposed through memory/soc.h.
 */
static SocRegion soc_regions[] = {
  {
    .info = { "sram", YSYXSOC_SRAM_BASE, YSYXSOC_SRAM_SIZE,
      SOC_SIM_REGION_MEMORY, false, false },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "uart0", YSYXSOC_UART_BASE, YSYXSOC_UART_SIZE,
      SOC_SIM_REGION_MMIO, false, true },
    .backend = SOC_REGION_BACKEND_UART16550,
  },
  {
    .info = { "spi0", YSYXSOC_SPI_BASE, YSYXSOC_SPI_SIZE,
      SOC_SIM_REGION_MMIO, false, true },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "gpio0", YSYXSOC_GPIO_BASE, YSYXSOC_GPIO_SIZE,
      SOC_SIM_REGION_MMIO, false, true },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "ps2", YSYXSOC_PS2_BASE, YSYXSOC_PS2_SIZE,
      SOC_SIM_REGION_MMIO, false, true },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "mrom", YSYXSOC_MROM_BASE, YSYXSOC_MROM_SIZE,
      SOC_SIM_REGION_MEMORY, true, false },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "vga", YSYXSOC_VGA_BASE, YSYXSOC_VGA_SIZE,
      SOC_SIM_REGION_MMIO, false, true },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
  {
    .info = { "flash", YSYXSOC_FLASH_BASE, YSYXSOC_FLASH_SIZE,
      SOC_SIM_REGION_XIP_FLASH, true, true },
    .backend = SOC_REGION_BACKEND_EMPTY_FLASH,
  },
  {
    /* NEMU 的 primary-memory allocation 就是 SoC 手册中的 PSRAM。 */
    .info = { "psram", YSYXSOC_PSRAM_BASE, YSYXSOC_PSRAM_SIZE,
      SOC_SIM_REGION_MEMORY, false, false },
    .backend = SOC_REGION_BACKEND_PMEM,
  },
  {
    .info = { "sdram", YSYXSOC_SDRAM_BASE, YSYXSOC_SDRAM_SIZE,
      SOC_SIM_REGION_MEMORY, false, false },
    .backend = SOC_REGION_BACKEND_BYTES,
  },
};

static bool soc_region_table_validated = false;

static bool range_end(paddr_t base, size_t size, paddr_t *end) {
  if (size == 0) return false;

  size_t offset = size - 1;
  paddr_t address_offset = (paddr_t)offset;
  if ((size_t)address_offset != offset) return false;
  if (base > ~(paddr_t)0 - address_offset) return false;

  *end = base + address_offset;
  return true;
}

static bool region_contains(const SocSimRegionInfo *region,
    paddr_t base, size_t size) {
  paddr_t region_end = 0;
  paddr_t span_end = 0;
  return range_end(region->base, region->size, &region_end) &&
      range_end(base, size, &span_end) &&
      base >= region->base && span_end <= region_end;
}

static bool region_overlaps(const SocSimRegionInfo *region,
    paddr_t base, size_t size) {
  paddr_t region_end = 0;
  paddr_t span_end = 0;
  return range_end(region->base, region->size, &region_end) &&
      range_end(base, size, &span_end) &&
      base <= region_end && region->base <= span_end;
}

static SocRegion *find_region(paddr_t base, size_t size) {
  for (size_t i = 0; i < ARRLEN(soc_regions); i++) {
    if (region_contains(&soc_regions[i].info, base, size)) {
      return &soc_regions[i];
    }
  }
  return NULL;
}

static uint8_t *region_bytes(SocRegion *region) {
  Assert(region->backend == SOC_REGION_BACKEND_BYTES,
      "ysyxSoC %s has no byte-addressable host backing", region->info.name);
  if (region->data == NULL) {
    region->data = (uint8_t *)calloc(1, region->info.size);
    Assert(region->data != NULL,
        "can not allocate ysyxSoC %s space, size=%zu",
        region->info.name, region->info.size);
  }
  return region->data;
}

/* Loader/DiffTest images may initialize memories, never device registers. */
static bool region_is_byte_backed_memory(const SocRegion *region) {
  return region != NULL &&
      region->info.kind == SOC_SIM_REGION_MEMORY &&
      region->backend == SOC_REGION_BACKEND_BYTES;
}

static word_t read_le(const uint8_t *base, int len) {
  word_t ret = 0;
  for (int i = 0; i < len; i++) {
    ret |= (word_t)base[i] << (i * 8);
  }
  return ret;
}

static void write_le(uint8_t *base, int len, word_t data) {
  for (int i = 0; i < len; i++) {
    base[i] = (uint8_t)(data >> (i * 8));
  }
}

static void soc_uart_tx(void *opaque, uint8_t ch) {
  (void)opaque;
  putc((char)ch, stderr);
  fflush(stderr);
}

static void soc_uart_init_once(void) {
  if (soc_uart != NULL) {
    return;
  }
  Uart16550Ops ops = {
    .tx = soc_uart_tx,
    /*
     * The external ysyxSoC APB wrapper keeps the UART interrupt signal inside
     * the wrapper and does not route it to the CPU.  Preserve UART register/IIR
     * state, but do not invent a UART -> PLIC -> CPU wire in the NEMU profile.
     */
    .irq = NULL,
  };
  Uart16550Config config = {
    .ops = &ops,
  };
  soc_uart = uart16550_create(&config);
  Assert(soc_uart != NULL, "can not create ysyxSoC 16550A device");
}

static word_t uart_read(paddr_t addr, int len) {
  soc_uart_init_once();
  uint32_t offset = (uint32_t)(addr - YSYXSOC_UART_BASE);
  uart16550_service(soc_uart);
  return (word_t)uart16550_bus_read(soc_uart, &soc_uart_bus_profile,
      offset, len);
}

static void uart_write(paddr_t addr, int len, word_t data) {
  soc_uart_init_once();
  uint32_t offset = (uint32_t)(addr - YSYXSOC_UART_BASE);
  uart16550_bus_write(soc_uart, &soc_uart_bus_profile, offset, len, data);
}

size_t soc_sim_region_count(void) {
  return sizeof(soc_regions) / sizeof(soc_regions[0]);
}

const SocSimRegionInfo *soc_sim_region_at(size_t index) {
  return index < soc_sim_region_count() ? &soc_regions[index].info : NULL;
}

const SocSimRegionInfo *soc_sim_region_containing(paddr_t base, size_t size) {
  SocRegion *region = find_region(base, size);
  return region != NULL ? &region->info : NULL;
}

const SocSimRegionInfo *soc_sim_region_overlapping(paddr_t base, size_t size) {
  for (size_t i = 0; i < soc_sim_region_count(); i++) {
    if (region_overlaps(&soc_regions[i].info, base, size)) {
      return &soc_regions[i].info;
    }
  }
  return NULL;
}

const SocSimRegionInfo *soc_sim_pmem_backed_region(void) {
  for (size_t i = 0; i < soc_sim_region_count(); i++) {
    if (soc_regions[i].backend == SOC_REGION_BACKEND_PMEM) {
      return &soc_regions[i].info;
    }
  }
  return NULL;
}

bool soc_sim_transaction_valid(
    paddr_t addr, int len, SocSimTransactionDirection direction) {
  if (len != 1 && len != 2 && len != 4) return false;

  SocRegion *region = find_region(addr, (size_t)len);
  if (region == NULL) return false;

  switch (direction) {
    case SOC_SIM_TRANSACTION_IFETCH:
      return len != 1 && region->info.kind != SOC_SIM_REGION_MMIO;
    case SOC_SIM_TRANSACTION_READ:
      return true;
    case SOC_SIM_TRANSACTION_WRITE:
      /*
       * MROM is architecturally read-only and must raise a guest access fault.
       * The empty XIP-flash model deliberately accepts stores as defined
       * no-ops, matching soc_sim_write() without claiming mutable flash data.
       */
      return !region->info.readonly ||
          region->backend == SOC_REGION_BACKEND_EMPTY_FLASH;
    default:
      return false;
  }
}

__EXPORT bool soc_sim_in_range(paddr_t addr) {
  return soc_sim_span_in_range(addr, 1);
}

bool soc_sim_span_in_range(paddr_t addr, int len) {
  if (len <= 0) return false;
  return soc_sim_region_containing(addr, (size_t)len) != NULL;
}

bool soc_sim_should_skip_ref(paddr_t addr) {
  const SocSimRegionInfo *region = soc_sim_region_containing(addr, 1);
  return region != NULL && region->skip_ref;
}

word_t soc_sim_read(paddr_t addr, int len) {
  Assert(len == 1 || len == 2 || len == 4,
      "unsupported ysyxSoC read length: addr=" FMT_PADDR ", len=%d", addr, len);

  SocRegion *region = find_region(addr, (size_t)len);
  Assert(region != NULL,
      "ysyxSoC read out of modeled range: addr=" FMT_PADDR ", len=%d",
      addr, len);

  switch (region->backend) {
    case SOC_REGION_BACKEND_UART16550:
      return uart_read(addr, len);
    case SOC_REGION_BACKEND_EMPTY_FLASH:
      // 当前 ysyxSoC flash 仍是 SPI/XIP 外设占位；读 0 让空镜像表现为非法指令/空数据。
      return 0;
    case SOC_REGION_BACKEND_BYTES:
      return read_le(region_bytes(region) + (addr - region->info.base), len);
    case SOC_REGION_BACKEND_PMEM:
      panic("ysyxSoC %s must be dispatched through NEMU PMEM", region->info.name);
      return 0;
    default:
      panic("unknown ysyxSoC backend for %s", region->info.name);
  }
}

void soc_sim_write(paddr_t addr, int len, word_t data) {
  Assert(len == 1 || len == 2 || len == 4,
      "unsupported ysyxSoC write length: addr=" FMT_PADDR ", len=%d", addr, len);

  SocRegion *region = find_region(addr, (size_t)len);
  Assert(region != NULL,
      "ysyxSoC write out of modeled range: addr=" FMT_PADDR ", len=%d",
      addr, len);

  switch (region->backend) {
    case SOC_REGION_BACKEND_UART16550:
      uart_write(addr, len, data);
      return;
    case SOC_REGION_BACKEND_EMPTY_FLASH:
      // XIP flash 对普通 CPU store 不产生可见架构状态；控制器寄存器仍由 SPI 窗口建模。
      return;
    case SOC_REGION_BACKEND_BYTES:
      Assert(!region->info.readonly,
          "ysyxSoC %s is read-only: addr=" FMT_PADDR,
          region->info.name, addr);
      write_le(region_bytes(region) + (addr - region->info.base), len, data);
      return;
    case SOC_REGION_BACKEND_PMEM:
      panic("ysyxSoC %s must be dispatched through NEMU PMEM", region->info.name);
      return;
    default:
      panic("unknown ysyxSoC backend for %s", region->info.name);
  }
}

void soc_sim_reset(void) {
  if (!soc_region_table_validated) {
    size_t pmem_backed_regions = 0;
    for (size_t i = 0; i < soc_sim_region_count(); i++) {
      paddr_t ignored_end = 0;
      Assert(soc_regions[i].info.name != NULL &&
             range_end(soc_regions[i].info.base,
                 soc_regions[i].info.size, &ignored_end),
          "invalid ysyxSoC region descriptor at index %zu", i);
      for (size_t j = i + 1; j < soc_sim_region_count(); j++) {
        Assert(!region_overlaps(&soc_regions[i].info,
                soc_regions[j].info.base, soc_regions[j].info.size),
            "ysyxSoC regions %s and %s overlap",
            soc_regions[i].info.name, soc_regions[j].info.name);
      }
      if (soc_regions[i].backend == SOC_REGION_BACKEND_PMEM) {
        pmem_backed_regions++;
        Assert(soc_regions[i].info.kind == SOC_SIM_REGION_MEMORY &&
               !soc_regions[i].info.readonly,
            "ysyxSoC PMEM-backed region %s must be writable memory",
            soc_regions[i].info.name);
      }
    }
    Assert(pmem_backed_regions == 1,
        "ysyxSoC platform must define exactly one PMEM-backed region");
    soc_region_table_validated = true;
  }

  for (size_t i = 0; i < soc_sim_region_count(); i++) {
    SocRegion *region = &soc_regions[i];
    if (region->backend == SOC_REGION_BACKEND_BYTES) {
      memset(region_bytes(region), 0, region->info.size);
    }
  }
  if (soc_uart == NULL) {
    soc_uart_init_once();
  } else {
    uart16550_reset(soc_uart);
  }
}

bool soc_sim_copy_to_guest(paddr_t addr, const void *buf, size_t n) {
  if (n == 0) return false;
  Assert(buf != NULL, "ysyxSoC loader buffer is NULL");
  SocRegion *region = find_region(addr, n);
  /*
   * PMEM-backed PSRAM 交还标准 PMEM memcpy 路径，避免双份 backing；SPI、
   * GPIO、PS/2、VGA 即使模型内部有寄存器 backing，也不是可装载内存。
   */
  if (!region_is_byte_backed_memory(region)) return false;

  uint8_t *host = region_bytes(region) + (addr - region->info.base);
  memcpy(host, buf, n);
  return true;
}

bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (n == 0) return false;
  Assert(buf != NULL, "ysyxSoC difftest memcpy buffer is NULL");
  SocRegion *region = find_region(addr, n);
  /* PMEM-backed PSRAM 交还 ref.c 的标准 PMEM memcpy 路径，避免双份 backing。 */
  if (!region_is_byte_backed_memory(region)) return false;

  uint8_t *host = region_bytes(region) + (addr - region->info.base);
  if (direction == DIFFTEST_TO_REF) {
    // difftest_memcpy 是加载/同步入口；允许 host 初始化 MROM，运行期 CPU store 仍由 soc_sim_write() 拦住。
    return soc_sim_copy_to_guest(addr, buf, n);
  } else {
    memcpy(buf, host, n);
  }
  return true;
}

#else

size_t soc_sim_region_count(void) {
  return 0;
}

const SocSimRegionInfo *soc_sim_region_at(size_t index) {
  (void)index;
  return NULL;
}

const SocSimRegionInfo *soc_sim_region_containing(paddr_t base, size_t size) {
  (void)base;
  (void)size;
  return NULL;
}

const SocSimRegionInfo *soc_sim_region_overlapping(paddr_t base, size_t size) {
  (void)base;
  (void)size;
  return NULL;
}

const SocSimRegionInfo *soc_sim_pmem_backed_region(void) {
  return NULL;
}

bool soc_sim_transaction_valid(
    paddr_t addr, int len, SocSimTransactionDirection direction) {
  (void)addr;
  (void)len;
  (void)direction;
  return false;
}

__EXPORT bool soc_sim_in_range(paddr_t addr) {
  (void)addr;
  return false;
}

bool soc_sim_span_in_range(paddr_t addr, int len) {
  (void)addr;
  (void)len;
  return false;
}

bool soc_sim_should_skip_ref(paddr_t addr) {
  (void)addr;
  return false;
}

word_t soc_sim_read(paddr_t addr, int len) {
  (void)addr;
  (void)len;
  return 0;
}

void soc_sim_write(paddr_t addr, int len, word_t data) {
  (void)addr;
  (void)len;
  (void)data;
}

void soc_sim_reset(void) {}

bool soc_sim_copy_to_guest(paddr_t addr, const void *buf, size_t n) {
  (void)addr;
  (void)buf;
  (void)n;
  return false;
}

bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  (void)addr;
  (void)buf;
  (void)n;
  (void)direction;
  return false;
}

#endif
