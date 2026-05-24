/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
***************************************************************************************/

#include <memory/soc.h>
#include <difftest-def.h>

#ifdef CONFIG_SOC_SIM
#include <utils.h>

#define SOC_SRAM_BASE   ((paddr_t)0x0f000000u)
#define SOC_SRAM_SIZE   ((size_t)0x00002000u)
#define SOC_UART_BASE   ((paddr_t)0x10000000u)
#define SOC_UART_SIZE   ((size_t)0x00001000u)
#define SOC_SPI_BASE    ((paddr_t)0x10001000u)
#define SOC_SPI_SIZE    ((size_t)0x00001000u)
#define SOC_GPIO_BASE   ((paddr_t)0x10002000u)
#define SOC_GPIO_SIZE   ((size_t)0x00000010u)
#define SOC_PS2_BASE    ((paddr_t)0x10011000u)
#define SOC_PS2_SIZE    ((size_t)0x00000008u)
#define SOC_MROM_BASE   ((paddr_t)0x20000000u)
#define SOC_MROM_SIZE   ((size_t)0x00001000u)
#define SOC_VGA_BASE    ((paddr_t)0x21000000u)
#define SOC_VGA_SIZE    ((size_t)0x00200000u)
#define SOC_FLASH_BASE  ((paddr_t)0x30000000u)
#define SOC_FLASH_SIZE  ((size_t)0x10000000u)
#define SOC_SDRAM_BASE  ((paddr_t)0xa0000000u)
#define SOC_SDRAM_SIZE  ((size_t)0x02000000u)

typedef struct {
  const char *name;
  paddr_t base;
  size_t size;
  uint8_t *data;
  bool readonly;
  bool skip_ref;
} SocMemRegion;

static uint8_t *soc_sram = NULL;
static uint8_t *soc_spi = NULL;
static uint8_t *soc_gpio = NULL;
static uint8_t *soc_ps2 = NULL;
static uint8_t *soc_mrom = NULL;
static uint8_t *soc_vga = NULL;
static uint8_t *soc_sdram = NULL;

static uint8_t soc_uart_regs[8];

static SocMemRegion soc_regions[] = {
  { "sram",  SOC_SRAM_BASE,  SOC_SRAM_SIZE,  NULL, false, false },
  { "spi",   SOC_SPI_BASE,   SOC_SPI_SIZE,   NULL, false, true  },
  { "gpio",  SOC_GPIO_BASE,  SOC_GPIO_SIZE,  NULL, false, true  },
  { "ps2",   SOC_PS2_BASE,   SOC_PS2_SIZE,   NULL, false, true  },
  { "mrom",  SOC_MROM_BASE,  SOC_MROM_SIZE,  NULL, true,  false },
  { "vga",   SOC_VGA_BASE,   SOC_VGA_SIZE,   NULL, false, true  },
  { "sdram", SOC_SDRAM_BASE, SOC_SDRAM_SIZE, NULL, false, false },
};

static bool range_hit(paddr_t base, size_t size, paddr_t addr, int len) {
  if (len <= 0) return false;
  paddr_t end = addr + (paddr_t)len - 1;
  if (end < addr) return false;
  return addr >= base && end < base + size;
}

static uint8_t *ensure_space(uint8_t **slot, size_t size, const char *name) {
  if (*slot == NULL) {
    *slot = (uint8_t *)calloc(1, size);
    Assert(*slot != NULL, "can not allocate ysyxSoC %s space, size=%zu", name, size);
  }
  return *slot;
}

static void bind_regions(void) {
  soc_regions[0].data = ensure_space(&soc_sram, SOC_SRAM_SIZE, "sram");
  soc_regions[1].data = ensure_space(&soc_spi, SOC_SPI_SIZE, "spi");
  soc_regions[2].data = ensure_space(&soc_gpio, SOC_GPIO_SIZE, "gpio");
  soc_regions[3].data = ensure_space(&soc_ps2, SOC_PS2_SIZE, "ps2");
  soc_regions[4].data = ensure_space(&soc_mrom, SOC_MROM_SIZE, "mrom");
  soc_regions[5].data = ensure_space(&soc_vga, SOC_VGA_SIZE, "vga");
  soc_regions[6].data = ensure_space(&soc_sdram, SOC_SDRAM_SIZE, "sdram");
}

static SocMemRegion *find_region(paddr_t addr, int len) {
  bind_regions();
  for (size_t i = 0; i < ARRLEN(soc_regions); i++) {
    if (range_hit(soc_regions[i].base, soc_regions[i].size, addr, len)) {
      return &soc_regions[i];
    }
  }
  return NULL;
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

static uint8_t uart_read_byte(uint32_t offset) {
  switch (offset & 0x7u) {
    case 2: return 0x01; // IIR: no interrupt pending.
    case 5: return 0x60; // LSR: THRE/TEMT，和当前 NPC/ysyxSoC 串口轮询语义对齐。
    default: return soc_uart_regs[offset & 0x7u];
  }
}

static word_t uart_read(paddr_t addr, int len) {
  uint32_t offset = addr - SOC_UART_BASE;
  word_t ret = 0;
  for (int i = 0; i < len; i++) {
    ret |= (word_t)uart_read_byte(offset + i) << (i * 8);
  }
  return ret;
}

static void uart_write(paddr_t addr, int len, word_t data) {
  uint32_t offset = addr - SOC_UART_BASE;
  uint8_t selected = (uint8_t)data;
  if ((offset & 0x7u) == 0) {
    // ysyxSoC 的 16550 APB wrapper 按 paddr[1:0] 选一个 8-bit 寄存器写入；
    // 因此 32-bit sw 到 THR 时也只消费低字节，避免误打印高 3 个空字节。
    putc((char)selected, stderr);
    fflush(stderr);
    return;
  }
  for (int i = 0; i < len; i++) {
    uint32_t reg = (offset + i) & 0x7u;
    soc_uart_regs[reg] = (uint8_t)(data >> (i * 8));
  }
}

static bool flash_in_range(paddr_t addr, int len) {
  return range_hit(SOC_FLASH_BASE, SOC_FLASH_SIZE, addr, len);
}

__EXPORT bool soc_sim_in_range(paddr_t addr) {
  if (range_hit(SOC_UART_BASE, SOC_UART_SIZE, addr, 1)) return true;
  if (flash_in_range(addr, 1)) return true;
  return find_region(addr, 1) != NULL;
}

bool soc_sim_should_skip_ref(paddr_t addr) {
  if (range_hit(SOC_UART_BASE, SOC_UART_SIZE, addr, 1)) return true;
  if (flash_in_range(addr, 1)) return true;
  SocMemRegion *region = find_region(addr, 1);
  return region != NULL && region->skip_ref;
}

word_t soc_sim_read(paddr_t addr, int len) {
  Assert(len == 1 || len == 2 || len == 4,
      "unsupported ysyxSoC read length: addr=" FMT_PADDR ", len=%d", addr, len);

  if (range_hit(SOC_UART_BASE, SOC_UART_SIZE, addr, len)) {
    return uart_read(addr, len);
  }
  if (flash_in_range(addr, len)) {
    // 当前 ysyxSoC flash 仍是 SPI/XIP 外设占位；读 0 让空镜像表现为非法指令/空数据。
    return 0;
  }

  SocMemRegion *region = find_region(addr, len);
  Assert(region != NULL, "ysyxSoC read out of modeled range: addr=" FMT_PADDR ", len=%d", addr, len);
  return read_le(region->data + (addr - region->base), len);
}

void soc_sim_write(paddr_t addr, int len, word_t data) {
  Assert(len == 1 || len == 2 || len == 4,
      "unsupported ysyxSoC write length: addr=" FMT_PADDR ", len=%d", addr, len);

  if (range_hit(SOC_UART_BASE, SOC_UART_SIZE, addr, len)) {
    uart_write(addr, len, data);
    return;
  }
  if (flash_in_range(addr, len)) {
    // XIP flash 对普通 CPU store 不产生可见架构状态；控制器寄存器仍由 SPI 窗口建模。
    return;
  }

  SocMemRegion *region = find_region(addr, len);
  Assert(region != NULL, "ysyxSoC write out of modeled range: addr=" FMT_PADDR ", len=%d", addr, len);
  Assert(!region->readonly, "ysyxSoC %s is read-only: addr=" FMT_PADDR, region->name, addr);
  write_le(region->data + (addr - region->base), len, data);
}

void soc_sim_reset(void) {
  bind_regions();
  memset(soc_sram, 0, SOC_SRAM_SIZE);
  memset(soc_spi, 0, SOC_SPI_SIZE);
  memset(soc_gpio, 0, SOC_GPIO_SIZE);
  memset(soc_ps2, 0, SOC_PS2_SIZE);
  memset(soc_mrom, 0, SOC_MROM_SIZE);
  memset(soc_vga, 0, SOC_VGA_SIZE);
  memset(soc_sdram, 0, SOC_SDRAM_SIZE);
  memset(soc_uart_regs, 0, sizeof(soc_uart_regs));
}

bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (n == 0) return false;
  Assert(buf != NULL, "ysyxSoC difftest memcpy buffer is NULL");
  if (n > (size_t)INT32_MAX) return false;

  if (range_hit(SOC_UART_BASE, SOC_UART_SIZE, addr, (int)n) || flash_in_range(addr, (int)n)) {
    return false;
  }
  SocMemRegion *region = find_region(addr, (int)n);
  if (region == NULL) return false;

  uint8_t *host = region->data + (addr - region->base);
  if (direction == DIFFTEST_TO_REF) {
    // difftest_memcpy 是加载/同步入口；允许 host 初始化 MROM，运行期 CPU store 仍由 soc_sim_write() 拦住。
    memcpy(host, buf, n);
  } else {
    memcpy(buf, host, n);
  }
  return true;
}

#else

__EXPORT bool soc_sim_in_range(paddr_t addr) {
  (void)addr;
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

bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  (void)addr;
  (void)buf;
  (void)n;
  (void)direction;
  return false;
}

#endif
