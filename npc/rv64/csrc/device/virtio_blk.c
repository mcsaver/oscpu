/* Minimal virtio-mmio block device for RV64 Linux bring-up.
 * The device is part of the Verilator simulation shell: guest-visible MMIO is
 * handled through DPI, while DMA targets NPC PMEM through memory/paddr helpers. */
#include "device/virtio_blk.h"

#include "cpu/difftest.h"
#include "memory/paddr.h"
#include "monitor/log.h"
#include "utils.h"

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif

#define VIRTIO_MMIO_MAGIC                 0x74726976u
#define VIRTIO_MMIO_VERSION               2u
#define VIRTIO_MMIO_DEVICE_ID_BLOCK       2u
#define VIRTIO_MMIO_VENDOR_ID             0x59535958u
#define VIRTIO_MMIO_QUEUE_MAX             128u
#define VIRTIO_BLK_SECTOR_SIZE            512ull

#define REG_MAGIC_VALUE       0x000u
#define REG_VERSION           0x004u
#define REG_DEVICE_ID         0x008u
#define REG_VENDOR_ID         0x00cu
#define REG_DEVICE_FEATURES   0x010u
#define REG_DEVICE_FEATURES_SEL 0x014u
#define REG_DRIVER_FEATURES   0x020u
#define REG_DRIVER_FEATURES_SEL 0x024u
#define REG_QUEUE_SEL         0x030u
#define REG_QUEUE_NUM_MAX     0x034u
#define REG_QUEUE_NUM         0x038u
#define REG_QUEUE_READY       0x044u
#define REG_QUEUE_NOTIFY      0x050u
#define REG_INTERRUPT_STATUS  0x060u
#define REG_INTERRUPT_ACK     0x064u
#define REG_STATUS            0x070u
#define REG_QUEUE_DESC_LOW    0x080u
#define REG_QUEUE_DESC_HIGH   0x084u
#define REG_QUEUE_DRIVER_LOW  0x090u
#define REG_QUEUE_DRIVER_HIGH 0x094u
#define REG_QUEUE_DEVICE_LOW  0x0a0u
#define REG_QUEUE_DEVICE_HIGH 0x0a4u
#define REG_CONFIG_GENERATION 0x0fcu
#define REG_CONFIG_SPACE      0x100u

#define VIRTIO_F_VERSION_1_HIGH_BIT       0x1u
#define VIRTQ_DESC_F_NEXT                 0x1u
#define VIRTQ_DESC_F_WRITE                0x2u
#define VIRTIO_MMIO_INT_USED_BUFFER       0x1u

#define VIRTIO_BLK_T_IN                   0u
#define VIRTIO_BLK_T_OUT                  1u
#define VIRTIO_BLK_T_FLUSH                4u
#define VIRTIO_BLK_S_OK                   0u
#define VIRTIO_BLK_S_IOERR                1u
#define VIRTIO_BLK_S_UNSUPP               2u

typedef struct {
  uint64_t addr;
  uint32_t len;
  uint16_t flags;
  uint16_t next;
} VirtqDesc;

static FILE *g_disk = NULL;
static char g_disk_path[NPC_PATH_MAX];
static uint64_t g_capacity_sectors = 0;

static uint32_t g_device_features_sel = 0;
static uint32_t g_driver_features_sel = 0;
static uint64_t g_driver_features = 0;
static uint32_t g_queue_sel = 0;
static uint32_t g_queue_num = 0;
static uint32_t g_queue_ready = 0;
static uint64_t g_queue_desc = 0;
static uint64_t g_queue_driver = 0;
static uint64_t g_queue_device = 0;
static uint16_t g_last_avail_idx = 0;
static uint32_t g_interrupt_status = 0;
static uint32_t g_status = 0;
static uint8_t g_config_generation = 0;

static uint16_t load_le16(const void *ptr) {
  const uint8_t *p = (const uint8_t *)ptr;
  return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t load_le32(const void *ptr) {
  const uint8_t *p = (const uint8_t *)ptr;
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
         ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static uint64_t load_le64(const void *ptr) {
  const uint8_t *p = (const uint8_t *)ptr;
  uint64_t value = 0;
  for (int i = 7; i >= 0; --i) value = (value << 8) | p[i];
  return value;
}

static void store_le16(void *ptr, uint16_t value) {
  uint8_t *p = (uint8_t *)ptr;
  p[0] = (uint8_t)value;
  p[1] = (uint8_t)(value >> 8);
}

static void store_le32(void *ptr, uint32_t value) {
  uint8_t *p = (uint8_t *)ptr;
  p[0] = (uint8_t)value;
  p[1] = (uint8_t)(value >> 8);
  p[2] = (uint8_t)(value >> 16);
  p[3] = (uint8_t)(value >> 24);
}

static uint32_t apply_wmask32(uint32_t old_value, uint32_t data, uint32_t mask) {
  uint32_t next = old_value;
  for (int lane = 0; lane < 4; ++lane) {
    if ((mask & (1u << lane)) != 0) {
      uint32_t byte_mask = 0xffu << (lane * 8);
      next = (next & ~byte_mask) | (data & byte_mask);
    }
  }
  return next;
}

static bool disk_present(void) {
  return g_disk != NULL;
}

static void reset_regs(void) {
  g_device_features_sel = 0;
  g_driver_features_sel = 0;
  g_driver_features = 0;
  g_queue_sel = 0;
  g_queue_num = 0;
  g_queue_ready = 0;
  g_queue_desc = 0;
  g_queue_driver = 0;
  g_queue_device = 0;
  g_last_avail_idx = 0;
  g_interrupt_status = 0;
  g_status = 0;
  g_config_generation++;
}

static bool guest_ptr(npc_paddr_t addr, size_t len, void **host) {
  if (!npc_pmem_range_valid(addr, len)) {
    fprintf(stderr, "[virtio-blk] DMA out of PMEM addr=0x%016" NPC_PRIxPADDR
                    " len=%zu\n", addr, len);
    return false;
  }
  if (host) *host = npc_guest_to_host(addr);
  return true;
}

static bool guest_read(npc_paddr_t addr, void *dst, size_t len) {
  void *src = NULL;
  if (!guest_ptr(addr, len, &src)) return false;
  memcpy(dst, src, len);
  return true;
}

static bool guest_write(npc_paddr_t addr, const void *src, size_t len) {
  void *dst = NULL;
  if (!guest_ptr(addr, len, &dst)) return false;
  memcpy(dst, src, len);
  return true;
}

static bool read_desc(uint16_t index, VirtqDesc *desc) {
  if (!desc || g_queue_num == 0 || index >= g_queue_num) {
    fprintf(stderr, "[virtio-blk] bad descriptor index=%u queue_num=%u\n",
            (unsigned)index, (unsigned)g_queue_num);
    return false;
  }

  uint8_t raw[16];
  if (!guest_read((npc_paddr_t)(g_queue_desc + (uint64_t)index * 16ull),
                  raw, sizeof(raw))) {
    return false;
  }
  desc->addr = load_le64(raw);
  desc->len = load_le32(raw + 8);
  desc->flags = load_le16(raw + 12);
  desc->next = load_le16(raw + 14);
  return true;
}

static bool disk_read_bytes(uint64_t offset, void *dst, uint32_t len) {
  if (len == 0) return true;
  if (!disk_present()) return false;
  uint64_t disk_size = g_capacity_sectors * VIRTIO_BLK_SECTOR_SIZE;
  if (offset > disk_size || (uint64_t)len > disk_size - offset) {
    fprintf(stderr, "[virtio-blk] read out of disk offset=%llu len=%u size=%llu\n",
            (unsigned long long)offset, len, (unsigned long long)disk_size);
    return false;
  }
  if (fseeko(g_disk, (off_t)offset, SEEK_SET) != 0) {
    perror("[virtio-blk] fseeko read");
    return false;
  }
  size_t nread = fread(dst, 1, len, g_disk);
  if (nread != len) {
    fprintf(stderr, "[virtio-blk] short read offset=%llu expect=%u got=%zu\n",
            (unsigned long long)offset, len, nread);
    return false;
  }
  return true;
}

static bool disk_write_bytes(uint64_t offset, const void *src, uint32_t len) {
  if (len == 0) return true;
  if (!disk_present()) return false;
  uint64_t disk_size = g_capacity_sectors * VIRTIO_BLK_SECTOR_SIZE;
  if (offset > disk_size || (uint64_t)len > disk_size - offset) {
    fprintf(stderr, "[virtio-blk] write out of disk offset=%llu len=%u size=%llu\n",
            (unsigned long long)offset, len, (unsigned long long)disk_size);
    return false;
  }
  if (fseeko(g_disk, (off_t)offset, SEEK_SET) != 0) {
    perror("[virtio-blk] fseeko write");
    return false;
  }
  size_t nwritten = fwrite(src, 1, len, g_disk);
  if (nwritten != len) {
    fprintf(stderr, "[virtio-blk] short write offset=%llu expect=%u got=%zu\n",
            (unsigned long long)offset, len, nwritten);
    return false;
  }
  fflush(g_disk);
  return true;
}

static bool process_data_desc(const VirtqDesc *desc, uint32_t type,
                              uint64_t *disk_offset, uint32_t *data_len,
                              uint8_t *status) {
  void *guest_buf = NULL;
  if (!guest_ptr((npc_paddr_t)desc->addr, desc->len, &guest_buf)) {
    *status = VIRTIO_BLK_S_IOERR;
    return false;
  }

  if (type == VIRTIO_BLK_T_IN) {
    if ((desc->flags & VIRTQ_DESC_F_WRITE) == 0) {
      fprintf(stderr, "[virtio-blk] IN data descriptor is not writable\n");
      *status = VIRTIO_BLK_S_IOERR;
      return false;
    }
    if (!disk_read_bytes(*disk_offset, guest_buf, desc->len)) {
      *status = VIRTIO_BLK_S_IOERR;
      return false;
    }
  } else if (type == VIRTIO_BLK_T_OUT) {
    if ((desc->flags & VIRTQ_DESC_F_WRITE) != 0) {
      fprintf(stderr, "[virtio-blk] OUT data descriptor is writable\n");
      *status = VIRTIO_BLK_S_IOERR;
      return false;
    }
    if (!disk_write_bytes(*disk_offset, guest_buf, desc->len)) {
      *status = VIRTIO_BLK_S_IOERR;
      return false;
    }
  } else if (type == VIRTIO_BLK_T_FLUSH) {
    fflush(g_disk);
  } else {
    *status = VIRTIO_BLK_S_UNSUPP;
  }

  *disk_offset += desc->len;
  *data_len += desc->len;
  return true;
}

static bool process_request(uint16_t head, uint32_t *used_len) {
  *used_len = 0;
  VirtqDesc desc;
  if (!read_desc(head, &desc)) return false;
  if ((desc.flags & VIRTQ_DESC_F_NEXT) == 0 || desc.len < 16) {
    fprintf(stderr, "[virtio-blk] bad request header desc=%u len=%u flags=0x%x\n",
            (unsigned)head, desc.len, desc.flags);
    return false;
  }

  uint8_t header[16];
  if (!guest_read((npc_paddr_t)desc.addr, header, sizeof(header))) return false;
  uint32_t type = load_le32(header);
  uint64_t sector = load_le64(header + 8);
  uint64_t disk_offset = sector * VIRTIO_BLK_SECTOR_SIZE;
  uint32_t data_len = 0;
  uint8_t status = VIRTIO_BLK_S_OK;
  uint16_t next = desc.next;

  for (uint32_t depth = 0; depth < g_queue_num; ++depth) {
    if (!read_desc(next, &desc)) return false;
    bool has_next = (desc.flags & VIRTQ_DESC_F_NEXT) != 0;
    if (!has_next) {
      if ((desc.flags & VIRTQ_DESC_F_WRITE) == 0 || desc.len < 1) {
        fprintf(stderr, "[virtio-blk] bad status descriptor flags=0x%x len=%u\n",
                desc.flags, desc.len);
        return false;
      }
      if (!guest_write((npc_paddr_t)desc.addr, &status, 1)) return false;
      *used_len = (type == VIRTIO_BLK_T_IN) ? data_len + 1u : 1u;
      return true;
    }

    if (status == VIRTIO_BLK_S_OK) {
      process_data_desc(&desc, type, &disk_offset, &data_len, &status);
    }
    next = desc.next;
  }

  fprintf(stderr, "[virtio-blk] descriptor chain loop detected head=%u\n",
          (unsigned)head);
  return false;
}

static bool push_used(uint16_t head, uint32_t used_len) {
  if (g_queue_num == 0) return false;
  uint8_t used_hdr[4];
  if (!guest_read((npc_paddr_t)g_queue_device, used_hdr, sizeof(used_hdr))) return false;
  uint16_t used_idx = load_le16(used_hdr + 2);
  uint64_t elem_addr = g_queue_device + 4ull +
                       (uint64_t)(used_idx % (uint16_t)g_queue_num) * 8ull;
  uint8_t elem[8];
  store_le32(elem, (uint32_t)head);
  store_le32(elem + 4, used_len);
  if (!guest_write((npc_paddr_t)elem_addr, elem, sizeof(elem))) return false;
  used_idx++;
  store_le16(used_hdr + 2, used_idx);
  if (!guest_write((npc_paddr_t)(g_queue_device + 2ull), used_hdr + 2, 2)) {
    return false;
  }
  return true;
}

static bool process_queue(void) {
  if (!disk_present()) {
    fprintf(stderr, "[virtio-blk] queue notify without block image\n");
    return false;
  }
  if (g_queue_sel != 0 || g_queue_ready == 0 ||
      g_queue_num == 0 || g_queue_num > VIRTIO_MMIO_QUEUE_MAX ||
      g_queue_desc == 0 || g_queue_driver == 0 || g_queue_device == 0) {
    fprintf(stderr, "[virtio-blk] queue not ready sel=%u ready=%u num=%u "
                    "desc=0x%llx driver=0x%llx device=0x%llx\n",
            g_queue_sel, g_queue_ready, g_queue_num,
            (unsigned long long)g_queue_desc,
            (unsigned long long)g_queue_driver,
            (unsigned long long)g_queue_device);
    return false;
  }

  uint8_t avail_hdr[4];
  if (!guest_read((npc_paddr_t)g_queue_driver, avail_hdr, sizeof(avail_hdr))) {
    return false;
  }
  uint16_t avail_idx = load_le16(avail_hdr + 2);
  while (g_last_avail_idx != avail_idx) {
    uint64_t ring_addr = g_queue_driver + 4ull +
                         (uint64_t)(g_last_avail_idx % (uint16_t)g_queue_num) * 2ull;
    uint8_t raw_head[2];
    if (!guest_read((npc_paddr_t)ring_addr, raw_head, sizeof(raw_head))) return false;
    uint16_t head = load_le16(raw_head);
    uint32_t used_len = 0;
    if (!process_request(head, &used_len)) return false;
    if (!push_used(head, used_len)) return false;
    g_last_avail_idx++;
  }
  g_interrupt_status |= VIRTIO_MMIO_INT_USED_BUFFER;
  return true;
}

static uint32_t read_config32(uint32_t offset) {
  uint32_t cfg_off = offset - REG_CONFIG_SPACE;
  switch (cfg_off) {
    case 0x00: return (uint32_t)g_capacity_sectors;
    case 0x04: return (uint32_t)(g_capacity_sectors >> 32);
    default:   return 0;
  }
}

static uint32_t read_reg32(uint32_t offset) {
  switch (offset) {
    case REG_MAGIC_VALUE:         return VIRTIO_MMIO_MAGIC;
    case REG_VERSION:             return VIRTIO_MMIO_VERSION;
    case REG_DEVICE_ID:           return disk_present() ? VIRTIO_MMIO_DEVICE_ID_BLOCK : 0u;
    case REG_VENDOR_ID:           return VIRTIO_MMIO_VENDOR_ID;
    case REG_DEVICE_FEATURES:
      return (g_device_features_sel == 1) ? VIRTIO_F_VERSION_1_HIGH_BIT : 0u;
    case REG_DEVICE_FEATURES_SEL: return g_device_features_sel;
    case REG_DRIVER_FEATURES:
      return (g_driver_features_sel == 0) ? (uint32_t)g_driver_features
                                          : (uint32_t)(g_driver_features >> 32);
    case REG_DRIVER_FEATURES_SEL: return g_driver_features_sel;
    case REG_QUEUE_SEL:           return g_queue_sel;
    case REG_QUEUE_NUM_MAX:       return (g_queue_sel == 0 && disk_present()) ? VIRTIO_MMIO_QUEUE_MAX : 0u;
    case REG_QUEUE_NUM:           return g_queue_num;
    case REG_QUEUE_READY:         return g_queue_ready;
    case REG_INTERRUPT_STATUS:    return g_interrupt_status;
    case REG_STATUS:              return g_status;
    case REG_QUEUE_DESC_LOW:      return (uint32_t)g_queue_desc;
    case REG_QUEUE_DESC_HIGH:     return (uint32_t)(g_queue_desc >> 32);
    case REG_QUEUE_DRIVER_LOW:    return (uint32_t)g_queue_driver;
    case REG_QUEUE_DRIVER_HIGH:   return (uint32_t)(g_queue_driver >> 32);
    case REG_QUEUE_DEVICE_LOW:    return (uint32_t)g_queue_device;
    case REG_QUEUE_DEVICE_HIGH:   return (uint32_t)(g_queue_device >> 32);
    case REG_CONFIG_GENERATION:   return g_config_generation;
    default:
      if (offset >= REG_CONFIG_SPACE && offset < REG_CONFIG_SPACE + 0x100u) {
        return read_config32(offset);
      }
      return 0;
  }
}

static bool write_reg32(uint32_t offset, uint32_t data, uint32_t mask) {
  bool ok = true;
  switch (offset) {
    case REG_DEVICE_FEATURES_SEL:
      g_device_features_sel = apply_wmask32(g_device_features_sel, data, mask);
      break;
    case REG_DRIVER_FEATURES:
      if (g_driver_features_sel == 0) {
        g_driver_features = (g_driver_features & UINT64_C(0xffffffff00000000)) |
                            apply_wmask32((uint32_t)g_driver_features, data, mask);
      } else if (g_driver_features_sel == 1) {
        uint32_t high = apply_wmask32((uint32_t)(g_driver_features >> 32), data, mask);
        g_driver_features = (g_driver_features & UINT64_C(0x00000000ffffffff)) |
                            ((uint64_t)high << 32);
      }
      break;
    case REG_DRIVER_FEATURES_SEL:
      g_driver_features_sel = apply_wmask32(g_driver_features_sel, data, mask);
      break;
    case REG_QUEUE_SEL:
      g_queue_sel = apply_wmask32(g_queue_sel, data, mask);
      break;
    case REG_QUEUE_NUM: {
      uint32_t next = apply_wmask32(g_queue_num, data, mask);
      if (next > VIRTIO_MMIO_QUEUE_MAX) {
        fprintf(stderr, "[virtio-blk] QueueNum too large: %u\n", next);
        ok = false;
      } else {
        g_queue_num = next;
      }
      break;
    }
    case REG_QUEUE_READY:
      g_queue_ready = apply_wmask32(g_queue_ready, data, mask) & 1u;
      if (g_queue_ready == 0) g_last_avail_idx = 0;
      break;
    case REG_QUEUE_NOTIFY:
      ok = process_queue();
      break;
    case REG_INTERRUPT_ACK:
      g_interrupt_status &= ~apply_wmask32(0, data, mask);
      break;
    case REG_STATUS: {
      uint32_t next = apply_wmask32(g_status, data, mask);
      if (next == 0) {
        reset_regs();
      } else {
        g_status = next;
      }
      break;
    }
    case REG_QUEUE_DESC_LOW:
      g_queue_desc = (g_queue_desc & UINT64_C(0xffffffff00000000)) |
                     apply_wmask32((uint32_t)g_queue_desc, data, mask);
      break;
    case REG_QUEUE_DESC_HIGH: {
      uint32_t high = apply_wmask32((uint32_t)(g_queue_desc >> 32), data, mask);
      g_queue_desc = (g_queue_desc & UINT64_C(0x00000000ffffffff)) |
                     ((uint64_t)high << 32);
      break;
    }
    case REG_QUEUE_DRIVER_LOW:
      g_queue_driver = (g_queue_driver & UINT64_C(0xffffffff00000000)) |
                       apply_wmask32((uint32_t)g_queue_driver, data, mask);
      break;
    case REG_QUEUE_DRIVER_HIGH: {
      uint32_t high = apply_wmask32((uint32_t)(g_queue_driver >> 32), data, mask);
      g_queue_driver = (g_queue_driver & UINT64_C(0x00000000ffffffff)) |
                       ((uint64_t)high << 32);
      break;
    }
    case REG_QUEUE_DEVICE_LOW:
      g_queue_device = (g_queue_device & UINT64_C(0xffffffff00000000)) |
                       apply_wmask32((uint32_t)g_queue_device, data, mask);
      break;
    case REG_QUEUE_DEVICE_HIGH: {
      uint32_t high = apply_wmask32((uint32_t)(g_queue_device >> 32), data, mask);
      g_queue_device = (g_queue_device & UINT64_C(0x00000000ffffffff)) |
                       ((uint64_t)high << 32);
      break;
    }
    default:
      ok = false;
      break;
  }
  return ok;
}

bool npc_virtio_blk_init(const char *image_path) {
  npc_virtio_blk_fini();
  reset_regs();

  const char *path = image_path;
  if (!path || path[0] == '\0') path = getenv("NPC_VIRTIO_BLK_IMAGE");
  if (!path || path[0] == '\0') {
    LogBothTag("virtio-blk", "disabled: no --block image");
    return true;
  }

  struct stat st;
  if (stat(path, &st) != 0) {
    perror("[virtio-blk] stat image");
    return false;
  }
  if (st.st_size <= 0 || ((uint64_t)st.st_size % VIRTIO_BLK_SECTOR_SIZE) != 0) {
    fprintf(stderr, "[virtio-blk] bad image size: %s size=%lld\n",
            path, (long long)st.st_size);
    return false;
  }

  g_disk = fopen(path, "r+b");
  if (!g_disk) {
    perror("[virtio-blk] fopen image");
    return false;
  }
  strncpy(g_disk_path, path, NPC_PATH_MAX - 1);
  g_disk_path[NPC_PATH_MAX - 1] = '\0';
  g_capacity_sectors = (uint64_t)st.st_size / VIRTIO_BLK_SECTOR_SIZE;
  LogBothTag("virtio-blk",
             "image=%s capacity=%llu sectors (%llu MiB)",
             g_disk_path,
             (unsigned long long)g_capacity_sectors,
             (unsigned long long)(st.st_size / (1024 * 1024)));
  return true;
}

void npc_virtio_blk_fini(void) {
  if (g_disk) {
    fflush(g_disk);
    fclose(g_disk);
    g_disk = NULL;
  }
  g_disk_path[0] = '\0';
  g_capacity_sectors = 0;
  reset_regs();
}

void npc_virtio_blk_read(uint32_t offset, uint64_t *data, svBit *error, svBit *irq) {
  if (!data || !error || !irq) return;
  npc_difftest_skip_ref();
  uint32_t aligned = offset & ~7u;
  uint32_t low = read_reg32(aligned);
  uint32_t high = read_reg32(aligned + 4u);
  *data = (uint64_t)low | ((uint64_t)high << 32);
  *error = 0;
  *irq = (g_interrupt_status != 0) ? 1 : 0;
}

void npc_virtio_blk_write(uint32_t offset, uint64_t data64, uint64_t mask64,
                          svBit *error, svBit *irq) {
  if (!error || !irq) return;
  npc_difftest_skip_ref();
  *error = 0;
  uint32_t aligned = offset & ~7u;
  uint32_t mask = (uint32_t)(mask64 & 0xffu);
  if (mask == 0) {
    *irq = (g_interrupt_status != 0) ? 1 : 0;
    return;
  }

  if ((mask & 0x0fu) != 0 && !write_reg32(aligned, (uint32_t)data64, mask & 0x0fu)) {
    *error = 1;
  }
  if ((mask & 0xf0u) != 0 &&
      !write_reg32(aligned + 4u, (uint32_t)(data64 >> 32), (mask >> 4) & 0x0fu)) {
    *error = 1;
  }

  *irq = (g_interrupt_status != 0) ? 1 : 0;
}

void npc_virtio_blk_irq(svBit *irq) {
  if (!irq) return;
  *irq = (g_interrupt_status != 0) ? 1 : 0;
}

#ifdef __cplusplus
}
#endif
