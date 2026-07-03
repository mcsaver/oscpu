/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <isa.h>
#include <memory/host.h>
#include <memory/paddr.h>

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#ifndef CONFIG_TARGET_AM
#include <pthread.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

// Linux rootfs gate 使用 modern virtio-mmio block 设备。native NEMU 下 host block I/O
// 由后台 worker 串行执行，guest 内存与 used ring 仍只在主线程完成，避免并发写 guest PMEM。
#define VIRTIO_MMIO_MAGIC          0x000
#define VIRTIO_MMIO_VERSION        0x004
#define VIRTIO_MMIO_DEVICE_ID      0x008
#define VIRTIO_MMIO_VENDOR_ID      0x00c
#define VIRTIO_MMIO_DEVICE_FEATURES     0x010
#define VIRTIO_MMIO_DEVICE_FEATURES_SEL 0x014
#define VIRTIO_MMIO_DRIVER_FEATURES     0x020
#define VIRTIO_MMIO_DRIVER_FEATURES_SEL 0x024
#define VIRTIO_MMIO_QUEUE_SEL      0x030
#define VIRTIO_MMIO_QUEUE_NUM_MAX  0x034
#define VIRTIO_MMIO_QUEUE_NUM      0x038
#define VIRTIO_MMIO_QUEUE_READY    0x044
#define VIRTIO_MMIO_QUEUE_NOTIFY   0x050
#define VIRTIO_MMIO_INTERRUPT_STATUS 0x060
#define VIRTIO_MMIO_INTERRUPT_ACK  0x064
#define VIRTIO_MMIO_STATUS         0x070
#define VIRTIO_MMIO_QUEUE_DESC_LOW 0x080
#define VIRTIO_MMIO_QUEUE_DESC_HIGH 0x084
#define VIRTIO_MMIO_QUEUE_DRIVER_LOW 0x090
#define VIRTIO_MMIO_QUEUE_DRIVER_HIGH 0x094
#define VIRTIO_MMIO_QUEUE_DEVICE_LOW 0x0a0
#define VIRTIO_MMIO_QUEUE_DEVICE_HIGH 0x0a4
#define VIRTIO_MMIO_CONFIG_GENERATION 0x0fc
#define VIRTIO_MMIO_CONFIG         0x100

#define VIRTIO_BLK_DEVICE_ID 2u
#define VIRTIO_MMIO_VERSION_2 2u
#define VIRTIO_VENDOR_YSYX 0x58535959u
#define VIRTIO_F_VERSION_1 32
#define VIRTIO_MMIO_INT_USED_BUFFER 0x1u
#define VIRTIO_BLK_F_BLK_SIZE 6
#define VIRTIO_BLK_F_FLUSH 9
#define VIRTIO_BLK_F_TOPOLOGY 10
#define VIRTIO_BLK_F_CONFIG_WCE 11
#define VIRTIO_BLK_F_MQ 12
#define VIRTIO_BLK_F_DISCARD 13
#define VIRTIO_BLK_F_WRITE_ZEROES 14
#define VIRTIO_RING_F_INDIRECT_DESC 28
#define VIRTIO_RING_F_EVENT_IDX 29
#define VRING_AVAIL_F_NO_INTERRUPT 0x1u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VIRTQ_DESC_F_NEXT  0x1u
#define VIRTQ_DESC_F_WRITE 0x2u
#define VIRTQ_DESC_F_INDIRECT 0x4u

#define VIRTIO_BLK_T_IN     0u
#define VIRTIO_BLK_T_OUT    1u
#define VIRTIO_BLK_T_FLUSH  4u
#define VIRTIO_BLK_T_GET_ID 8u
#define VIRTIO_BLK_T_DISCARD 11u
#define VIRTIO_BLK_T_WRITE_ZEROES 13u
#define VIRTIO_BLK_S_OK     0u
#define VIRTIO_BLK_S_IOERR  1u
#define VIRTIO_BLK_S_UNSUPP 2u

#define VIRTIO_BLK_SECTOR_SIZE 512u
#define VIRTIO_BLK_CONFIG_BLK_SIZE 20u
#define VIRTIO_BLK_CONFIG_PHYSICAL_BLOCK_EXP 24u
#define VIRTIO_BLK_CONFIG_ALIGNMENT_OFFSET 25u
#define VIRTIO_BLK_CONFIG_MIN_IO_SIZE 26u
#define VIRTIO_BLK_CONFIG_OPT_IO_SIZE 28u
#define VIRTIO_BLK_CONFIG_WCE 32u
#define VIRTIO_BLK_CONFIG_NUM_QUEUES 34u
#define VIRTIO_BLK_CONFIG_MAX_DISCARD_SECTORS 36u
#define VIRTIO_BLK_CONFIG_MAX_DISCARD_SEG 40u
#define VIRTIO_BLK_CONFIG_DISCARD_SECTOR_ALIGNMENT 44u
#define VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SECTORS 48u
#define VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SEG 52u
#define VIRTIO_BLK_CONFIG_WRITE_ZEROES_MAY_UNMAP 56u
#define VIRTIO_BLK_ID_BYTES 20u
#define VIRTIO_BLK_ID_STRING "ysyx-nemu-virtio-blk"
#define VIRTIO_BLK_QUEUE_COUNT 4u
#define VIRTIO_BLK_QUEUE_SIZE 64u
#define VIRTIO_BLK_MAX_CHAIN 128u
#define VIRTIO_BLK_IRQ 2u
#define VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES 16u
#define VIRTIO_BLK_WRITE_ZEROES_FLAG_UNMAP 0x00000001u
#define VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS 4096u
#define VIRTIO_BLK_MAX_ZERO_RANGE_SEG 1u

#if !defined(CONFIG_TARGET_AM)
#define VIRTIO_BLK_ASYNC_BACKEND 1
#else
#define VIRTIO_BLK_ASYNC_BACKEND 0
#endif

typedef struct {
  paddr_t addr;
  uint32_t len;
  uint16_t flags;
  uint16_t next;
} VirtqDesc;

typedef struct {
  uint16_t num;
  bool ready;
  paddr_t desc;
  paddr_t driver;
  paddr_t device;
  uint16_t last_avail_idx;
} VirtqState;

typedef struct {
  paddr_t addr;
  uint32_t len;
  uint32_t data_off;
} VirtioBlkDataSeg;

typedef struct {
  uint64_t sector;
  uint32_t num_sectors;
} VirtioBlkZeroRange;

typedef enum {
  VIRTIO_BLK_REQ_INVALID,
  VIRTIO_BLK_REQ_IN,
  VIRTIO_BLK_REQ_OUT,
  VIRTIO_BLK_REQ_FLUSH,
  VIRTIO_BLK_REQ_GET_ID,
  VIRTIO_BLK_REQ_ZERO_RANGE,
} VirtioBlkReqKind;

typedef struct VirtioBlkAsyncReq {
  struct VirtioBlkAsyncReq *next;
  uint32_t generation;
  uint32_t queue_idx;
  uint16_t head;
  paddr_t status_addr;
  bool write_status;
  uint8_t status;
  uint32_t used_len;
  VirtioBlkReqKind kind;
  uint64_t offset;
  uint32_t data_len;
  uint8_t *data;
  uint32_t data_seg_count;
  VirtioBlkDataSeg data_segs[VIRTIO_BLK_MAX_CHAIN];
  uint32_t zero_range_count;
  VirtioBlkZeroRange zero_ranges[VIRTIO_BLK_MAX_ZERO_RANGE_SEG];
  bool zero_range_write_zeroes;
} VirtioBlkAsyncReq;

typedef struct {
  uint64_t rd_bytes;
  uint64_t wr_bytes;
  uint64_t wr_highest_offset;
  uint64_t rd_operations;
  uint64_t wr_operations;
  uint64_t flush_operations;
  uint64_t get_id_operations;
  uint64_t discard_bytes;
  uint64_t discard_operations;
  uint64_t write_zeroes_bytes;
  uint64_t write_zeroes_operations;
  uint64_t failed_operations;
} VirtioBlkStats;

static uint8_t *virtio_base;
static const char *disk_image_path;
static const char *disk_overlay_path;
static FILE *disk_fp;
static FILE *disk_overlay_fp;
static bool disk_readonly;
static bool disk_backing_readonly;
static bool disk_writeback = true;
static uint64_t disk_size;
static uint8_t *disk_mmap;
static uint64_t disk_mmap_size;
static uint8_t *disk_overlay_dirty;
static uint64_t disk_overlay_sector_count;
static uint64_t disk_overlay_dirty_sector_count;
static uint32_t device_features_sel;
static uint32_t driver_features_sel;
static uint32_t driver_features[2];
static uint32_t interrupt_status;
static uint32_t device_status;
static uint32_t queue_sel;
static VirtqState queues[VIRTIO_BLK_QUEUE_COUNT];
static uint32_t virtio_blk_generation;
static int disk_log_budget = 16;
static VirtioBlkStats disk_stats;
static bool disk_force_sync_backend;

#if VIRTIO_BLK_ASYNC_BACKEND
static pthread_t disk_worker_thread;
static pthread_mutex_t disk_async_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t disk_backend_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t disk_async_cond = PTHREAD_COND_INITIALIZER;
static VirtioBlkAsyncReq *disk_pending_head;
static VirtioBlkAsyncReq *disk_pending_tail;
static VirtioBlkAsyncReq *disk_done_head;
static VirtioBlkAsyncReq *disk_done_tail;
static bool disk_worker_started;
static uint64_t disk_async_submitted;
static uint64_t disk_async_completed;
#ifdef CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
static bool disk_async_done_pending;
#endif
#endif

static void virtio_blk_execute_request(VirtioBlkAsyncReq *req);
static void virtio_blk_complete_request(VirtioBlkAsyncReq *req);
static void virtio_blk_submit_request(VirtioBlkAsyncReq *req);
static void virtio_blk_poll_async(void);

#if VIRTIO_BLK_ASYNC_BACKEND
static inline void virtio_blk_mark_done_pending(void) {
#ifdef CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
  __atomic_store_n(&disk_async_done_pending, true, __ATOMIC_RELEASE);
#endif
}

static inline bool virtio_blk_done_maybe_pending(void) {
#ifdef CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
  return __atomic_load_n(&disk_async_done_pending, __ATOMIC_ACQUIRE);
#else
  return true;
#endif
}

static inline void virtio_blk_clear_done_pending_locked(void) {
#ifdef CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
  __atomic_store_n(&disk_async_done_pending, false, __ATOMIC_RELEASE);
#endif
}
#endif

static void virtio_blk_free_request(VirtioBlkAsyncReq *req) {
  if (req == NULL) return;
  free(req->data);
  free(req);
}

static uint64_t virtio_blk_req_data_bytes(const VirtioBlkAsyncReq *req) {
  uint64_t bytes = 0;
  for (uint32_t i = 0; i < req->data_seg_count; i++) {
    bytes += req->data_segs[i].len;
  }
  return bytes;
}

static uint64_t virtio_blk_req_zero_range_bytes(const VirtioBlkAsyncReq *req) {
  uint64_t bytes = 0;
  for (uint32_t i = 0; i < req->zero_range_count; i++) {
    bytes += (uint64_t)req->zero_ranges[i].num_sectors * VIRTIO_BLK_SECTOR_SIZE;
  }
  return bytes;
}

static void virtio_blk_record_stats(const VirtioBlkAsyncReq *req) {
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_backend_lock);
#endif
  if (req->status != VIRTIO_BLK_S_OK || req->kind == VIRTIO_BLK_REQ_INVALID) {
    disk_stats.failed_operations++;
  } else if (req->kind == VIRTIO_BLK_REQ_IN) {
    disk_stats.rd_operations++;
    disk_stats.rd_bytes += virtio_blk_req_data_bytes(req);
  } else if (req->kind == VIRTIO_BLK_REQ_OUT) {
    uint64_t bytes = virtio_blk_req_data_bytes(req);
    disk_stats.wr_operations++;
    disk_stats.wr_bytes += bytes;
    if (req->offset + bytes > disk_stats.wr_highest_offset) {
      disk_stats.wr_highest_offset = req->offset + bytes;
    }
  } else if (req->kind == VIRTIO_BLK_REQ_FLUSH) {
    disk_stats.flush_operations++;
  } else if (req->kind == VIRTIO_BLK_REQ_GET_ID) {
    disk_stats.get_id_operations++;
  } else if (req->kind == VIRTIO_BLK_REQ_ZERO_RANGE) {
    uint64_t bytes = virtio_blk_req_zero_range_bytes(req);
    if (req->zero_range_write_zeroes) {
      disk_stats.write_zeroes_operations++;
      disk_stats.write_zeroes_bytes += bytes;
      if (req->offset + bytes > disk_stats.wr_highest_offset) {
        disk_stats.wr_highest_offset = req->offset + bytes;
      }
    } else {
      disk_stats.discard_operations++;
      disk_stats.discard_bytes += bytes;
    }
  }
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_unlock(&disk_backend_lock);
#endif
}

static VirtioBlkStats virtio_blk_stats_snapshot(void) {
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_backend_lock);
#endif
  VirtioBlkStats snapshot = disk_stats;
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_unlock(&disk_backend_lock);
#endif
  return snapshot;
}

#if VIRTIO_BLK_ASYNC_BACKEND
static void virtio_blk_push_req(VirtioBlkAsyncReq **head, VirtioBlkAsyncReq **tail,
    VirtioBlkAsyncReq *req) {
  req->next = NULL;
  if (*tail != NULL) {
    (*tail)->next = req;
  } else {
    *head = req;
  }
  *tail = req;
}

static VirtioBlkAsyncReq *virtio_blk_pop_req(VirtioBlkAsyncReq **head,
    VirtioBlkAsyncReq **tail) {
  VirtioBlkAsyncReq *req = *head;
  if (req == NULL) return NULL;
  *head = req->next;
  if (*head == NULL) *tail = NULL;
  req->next = NULL;
  return req;
}

static void *virtio_blk_worker_main(void *opaque) {
  (void)opaque;
  while (true) {
    pthread_mutex_lock(&disk_async_lock);
    while (disk_pending_head == NULL) {
      pthread_cond_wait(&disk_async_cond, &disk_async_lock);
    }
    VirtioBlkAsyncReq *req = virtio_blk_pop_req(&disk_pending_head, &disk_pending_tail);
    pthread_mutex_unlock(&disk_async_lock);

    pthread_mutex_lock(&disk_backend_lock);
    virtio_blk_execute_request(req);
    pthread_mutex_unlock(&disk_backend_lock);

    pthread_mutex_lock(&disk_async_lock);
    disk_async_completed++;
    virtio_blk_push_req(&disk_done_head, &disk_done_tail, req);
    virtio_blk_mark_done_pending();
    pthread_mutex_unlock(&disk_async_lock);
  }
  return NULL;
}

static void virtio_blk_start_worker(void) {
  if (disk_worker_started) return;
  int ret = pthread_create(&disk_worker_thread, NULL, virtio_blk_worker_main, NULL);
  Assert(ret == 0, "Can not start virtio-blk worker: %s", strerror(ret));
  pthread_detach(disk_worker_thread);
  disk_worker_started = true;
}

static void virtio_blk_submit_request(VirtioBlkAsyncReq *req) {
  if (unlikely(disk_force_sync_backend)) {
    virtio_blk_execute_request(req);
    virtio_blk_complete_request(req);
    return;
  }
  virtio_blk_start_worker();
  pthread_mutex_lock(&disk_async_lock);
  disk_async_submitted++;
  virtio_blk_push_req(&disk_pending_head, &disk_pending_tail, req);
  pthread_cond_signal(&disk_async_cond);
  pthread_mutex_unlock(&disk_async_lock);
}

static void virtio_blk_poll_async(void) {
  if (!virtio_blk_done_maybe_pending()) return;

  while (true) {
    pthread_mutex_lock(&disk_async_lock);
    VirtioBlkAsyncReq *req = virtio_blk_pop_req(&disk_done_head, &disk_done_tail);
    if (req == NULL) {
      virtio_blk_clear_done_pending_locked();
      pthread_mutex_unlock(&disk_async_lock);
      break;
    }
    pthread_mutex_unlock(&disk_async_lock);
    virtio_blk_complete_request(req);
  }
}
#else
static void virtio_blk_submit_request(VirtioBlkAsyncReq *req) {
  virtio_blk_execute_request(req);
  virtio_blk_complete_request(req);
}

static void virtio_blk_poll_async(void) {
}
#endif

void virtio_blk_statistic(void) {
#if VIRTIO_BLK_ASYNC_BACKEND
  // 退出统计前先把 worker 已完成的请求写回 used ring，避免只看到队列内部状态。
  virtio_blk_poll_async();

  pthread_mutex_lock(&disk_async_lock);
  uint64_t submitted = disk_async_submitted;
  uint64_t completed = disk_async_completed;
  uint64_t pending = 0;
  uint64_t done = 0;
  for (VirtioBlkAsyncReq *req = disk_pending_head; req != NULL; req = req->next) pending++;
  for (VirtioBlkAsyncReq *req = disk_done_head; req != NULL; req = req->next) done++;
  pthread_mutex_unlock(&disk_async_lock);

  Log("virtio-blk async runtime submitted=%" PRIu64 " completed=%" PRIu64
      " pending=%" PRIu64 " done=%" PRIu64,
      submitted, completed, pending, done);
#else
  Log("virtio-blk async runtime submitted=0 completed=0 pending=0 done=0");
#endif
}

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static int virtio_irq_debug_budget = 256;
#define VIRTIO_IRQ_DEBUG_LOG(...) \
  do { \
    if (virtio_irq_debug_budget > 0) { \
      virtio_irq_debug_budget--; \
      Log(__VA_ARGS__); \
    } \
  } while (0)
#else
#define VIRTIO_IRQ_DEBUG_LOG(...) ((void)0)
#endif

static uint32_t virtio_blk_device_features(uint32_t sel) {
  if (sel == 0) {
    return (1u << VIRTIO_BLK_F_BLK_SIZE) |
           (1u << VIRTIO_BLK_F_FLUSH) |
           (1u << VIRTIO_BLK_F_TOPOLOGY) |
           (1u << VIRTIO_BLK_F_CONFIG_WCE) |
           (1u << VIRTIO_BLK_F_MQ) |
           (1u << VIRTIO_BLK_F_DISCARD) |
           (1u << VIRTIO_BLK_F_WRITE_ZEROES) |
           (1u << VIRTIO_RING_F_INDIRECT_DESC) |
           (1u << VIRTIO_RING_F_EVENT_IDX);
  }
  if (sel == 1) {
    return 1u << (VIRTIO_F_VERSION_1 - 32);
  }
  return 0;
}

static bool virtio_blk_driver_features_supported(void) {
  for (uint32_t sel = 0; sel < 2; sel++) {
    uint32_t unsupported = driver_features[sel] & ~virtio_blk_device_features(sel);
    if (unsupported != 0) {
      Log("virtio-blk: unsupported driver features sel=%u bits=0x%08x", sel, unsupported);
      return false;
    }
  }
  return true;
}

static bool virtio_blk_driver_feature_enabled(uint32_t bit) {
  uint32_t sel = bit / 32;
  uint32_t off = bit % 32;
  return sel < 2 && (driver_features[sel] & (1u << off)) != 0;
}

static bool virtio_blk_event_idx_enabled(void) {
  return virtio_blk_driver_feature_enabled(VIRTIO_RING_F_EVENT_IDX);
}

void disk_set_image(const char *path) {
  disk_image_path = path;
}

void disk_set_overlay(const char *path) {
  disk_overlay_path = path;
}

void virtio_blk_dump_machine_info(FILE *out) {
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_backend_lock);
#endif
  uint64_t sectors = disk_size / VIRTIO_BLK_SECTOR_SIZE;
  fprintf(out, "device.virtio_blk.block_image=%s\n", disk_fp != NULL ? "attached" : "detached");
  fprintf(out, "device.virtio_blk.mmio_device_id=%u\n", disk_fp != NULL ? VIRTIO_BLK_DEVICE_ID : 0u);
  fprintf(out, "device.virtio_blk.capacity_bytes=%" PRIu64 "\n", disk_size);
  fprintf(out, "device.virtio_blk.capacity_sectors=%" PRIu64 "\n", sectors);
  fprintf(out, "device.virtio_blk.readonly=%d\n", disk_readonly ? 1 : 0);
  fprintf(out, "device.virtio_blk.writeback=%d\n", disk_writeback ? 1 : 0);
  fprintf(out, "device.virtio_blk.queue_count=%u\n", VIRTIO_BLK_QUEUE_COUNT);
  fprintf(out, "device.virtio_blk.multiqueue=enabled\n");
  fprintf(out, "device.virtio_blk.async=%s\n",
      disk_force_sync_backend ? "forced-synchronous" :
      (VIRTIO_BLK_ASYNC_BACKEND ? "threaded-poll" : "unsupported"));
  fprintf(out, "device.virtio_blk.force_sync=%d\n", disk_force_sync_backend ? 1 : 0);
  fprintf(out, "device.virtio_blk.async_completion_fast_flag=%d\n",
      ISDEF(CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG));
  fprintf(out, "device.virtio_blk.queue_num_max=%u\n", VIRTIO_BLK_QUEUE_SIZE);
  fprintf(out, "device.virtio_blk.read_mmap=%s\n", disk_mmap != NULL ? "enabled" : "disabled");
  fprintf(out, "device.virtio_blk.read_mmap_bytes=%" PRIu64 "\n", disk_mmap_size);
  fprintf(out, "device.virtio_blk.backing_readonly=%d\n", disk_backing_readonly ? 1 : 0);
  fprintf(out, "device.virtio_blk.overlay=%s\n", disk_overlay_fp != NULL ? "enabled" : "disabled");
  fprintf(out, "device.virtio_blk.write_target=%s\n", disk_overlay_fp != NULL ? "overlay" : "backing");
  fprintf(out, "device.virtio_blk.overlay_dirty_sectors=%" PRIu64 "\n",
      disk_overlay_dirty_sector_count);
  VirtioBlkStats stats = disk_stats;
  fprintf(out, "device.virtio_blk.stats.rd_bytes=%" PRIu64 "\n", stats.rd_bytes);
  fprintf(out, "device.virtio_blk.stats.wr_bytes=%" PRIu64 "\n", stats.wr_bytes);
  fprintf(out, "device.virtio_blk.stats.rd_operations=%" PRIu64 "\n", stats.rd_operations);
  fprintf(out, "device.virtio_blk.stats.wr_operations=%" PRIu64 "\n", stats.wr_operations);
  fprintf(out, "device.virtio_blk.stats.wr_highest_offset=%" PRIu64 "\n",
      stats.wr_highest_offset);
  fprintf(out, "device.virtio_blk.stats.flush_operations=%" PRIu64 "\n", stats.flush_operations);
  fprintf(out, "device.virtio_blk.stats.failed_operations=%" PRIu64 "\n", stats.failed_operations);
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_unlock(&disk_backend_lock);
  pthread_mutex_lock(&disk_async_lock);
  fprintf(out, "device.virtio_blk.async_submitted=%" PRIu64 "\n", disk_async_submitted);
  fprintf(out, "device.virtio_blk.async_completed=%" PRIu64 "\n", disk_async_completed);
  pthread_mutex_unlock(&disk_async_lock);
#else
  fprintf(out, "device.virtio_blk.async_submitted=0\n");
  fprintf(out, "device.virtio_blk.async_completed=0\n");
#endif
}

void virtio_blk_qmp_query_block(char *out, size_t out_size) {
  Assert(out != NULL && out_size > 0, "invalid query-block output buffer");

#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_backend_lock);
#endif
  bool attached = disk_fp != NULL;
  bool readonly = disk_readonly;
  bool writeback = disk_writeback;
  uint64_t capacity_bytes = disk_size;
  uint64_t capacity_sectors = disk_size / VIRTIO_BLK_SECTOR_SIZE;
  bool read_mmap = disk_mmap != NULL;
  uint64_t read_mmap_bytes = disk_mmap_size;
  bool backing_readonly = disk_backing_readonly;
  bool overlay = disk_overlay_fp != NULL;
  uint64_t overlay_dirty_sectors = disk_overlay_dirty_sector_count;
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_unlock(&disk_backend_lock);
#endif

  if (!attached) {
    snprintf(out, out_size, "{\"return\":[]}");
    return;
  }

#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_async_lock);
  uint64_t async_submitted = disk_async_submitted;
  uint64_t async_completed = disk_async_completed;
  pthread_mutex_unlock(&disk_async_lock);
#else
  uint64_t async_submitted = 0;
  uint64_t async_completed = 0;
#endif

  snprintf(out, out_size,
      "{\"return\":[{\"device\":\"virtio0\","
      "\"qdev\":\"/machine/virtio-mmio/virtio-blk0\","
      "\"type\":\"unknown\",\"removable\":false,\"locked\":false,\"tray_open\":false,"
      "\"inserted\":{\"node-name\":\"virtio0\",\"drv\":\"raw\",\"ro\":%s,"
      "\"encrypted\":false,\"detect_zeroes\":\"off\",\"writeback\":%s,"
      "\"image\":{\"virtual-size\":%" PRIu64 ",\"actual-size\":%" PRIu64 "}},"
      "\"nemu\":{\"capacity-bytes\":%" PRIu64 ",\"capacity-sectors\":%" PRIu64 ","
      "\"read-mmap\":\"%s\",\"read-mmap-bytes\":%" PRIu64 ","
      "\"backing-readonly\":%s,\"overlay\":\"%s\",\"write-target\":\"%s\","
      "\"overlay-dirty-sectors\":%" PRIu64 ","
      "\"async-submitted\":%" PRIu64 ",\"async-completed\":%" PRIu64 "}}]}",
      readonly ? "true" : "false",
      writeback ? "true" : "false",
      capacity_bytes, capacity_bytes,
      capacity_bytes, capacity_sectors,
      read_mmap ? "enabled" : "disabled", read_mmap_bytes,
      backing_readonly ? "true" : "false",
      overlay ? "enabled" : "disabled",
      overlay ? "overlay" : "backing",
      overlay_dirty_sectors,
      async_submitted, async_completed);
}

void virtio_blk_qmp_query_blockstats(char *out, size_t out_size) {
  Assert(out != NULL && out_size > 0, "invalid query-blockstats output buffer");

#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_backend_lock);
#endif
  bool attached = disk_fp != NULL;
#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_unlock(&disk_backend_lock);
#endif

  if (!attached) {
    snprintf(out, out_size, "{\"return\":[]}");
    return;
  }

  VirtioBlkStats stats = virtio_blk_stats_snapshot();

#if VIRTIO_BLK_ASYNC_BACKEND
  pthread_mutex_lock(&disk_async_lock);
  uint64_t async_submitted = disk_async_submitted;
  uint64_t async_completed = disk_async_completed;
  pthread_mutex_unlock(&disk_async_lock);
#else
  uint64_t async_submitted = 0;
  uint64_t async_completed = 0;
#endif

  snprintf(out, out_size,
      "{\"return\":[{\"device\":\"virtio0\",\"node-name\":\"virtio0\","
      "\"stats\":{\"rd_bytes\":%" PRIu64 ",\"wr_bytes\":%" PRIu64 ","
      "\"rd_operations\":%" PRIu64 ",\"wr_operations\":%" PRIu64 ","
      "\"flush_operations\":%" PRIu64 ","
      "\"wr_highest_offset\":%" PRIu64 ","
      "\"rd_total_time_ns\":0,\"wr_total_time_ns\":0,\"flush_total_time_ns\":0,"
      "\"failed_rd_operations\":0,\"failed_wr_operations\":0,"
      "\"invalid_rd_operations\":0,\"invalid_wr_operations\":0},"
      "\"nemu\":{\"get-id-operations\":%" PRIu64 ","
      "\"discard-bytes\":%" PRIu64 ",\"discard-operations\":%" PRIu64 ","
      "\"write-zeroes-bytes\":%" PRIu64 ","
      "\"write-zeroes-operations\":%" PRIu64 ","
      "\"failed-operations\":%" PRIu64 ","
      "\"async-submitted\":%" PRIu64 ","
      "\"async-completed\":%" PRIu64 "}}]}",
      stats.rd_bytes, stats.wr_bytes,
      stats.rd_operations, stats.wr_operations,
      stats.flush_operations,
      stats.wr_highest_offset,
      stats.get_id_operations,
      stats.discard_bytes, stats.discard_operations,
      stats.write_zeroes_bytes, stats.write_zeroes_operations,
      stats.failed_operations,
      async_submitted, async_completed);
}

static VirtqState *selected_queue(void) {
  return queue_sel < VIRTIO_BLK_QUEUE_COUNT ? &queues[queue_sel] : NULL;
}

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static uint32_t virtio_blk_ready_queue_count(void) {
  uint32_t count = 0;
  for (uint32_t i = 0; i < VIRTIO_BLK_QUEUE_COUNT; i++) {
    if (queues[i].ready) count++;
  }
  return count;
}
#endif

static void virtio_blk_raise_irq(void) {
  VIRTIO_IRQ_DEBUG_LOG("virtio-blk irq line=%u status=0x%08x ready_queues=%u selected_queue=%u",
      interrupt_status != 0, interrupt_status, virtio_blk_ready_queue_count(), queue_sel);
  IFDEF(CONFIG_ISA_riscv, isa_riscv_plic_set_irq(VIRTIO_BLK_IRQ, interrupt_status != 0));
}

static uint16_t guest_read16(paddr_t addr) {
  return (uint16_t)paddr_dma_read_value(addr, 2);
}

static uint32_t guest_read32(paddr_t addr) {
  return (uint32_t)paddr_dma_read_value(addr, 4);
}

static uint64_t guest_read64(paddr_t addr) {
  return (uint64_t)paddr_dma_read_value(addr, 8);
}

static void guest_write16(paddr_t addr, uint16_t value) {
  paddr_dma_write_value(addr, 2, value);
}

static void guest_write32(paddr_t addr, uint32_t value) {
  paddr_dma_write_value(addr, 4, value);
}

static bool guest_range_ok(paddr_t addr, uint32_t len);

static paddr_t virtq_used_event_addr(const VirtqState *queue) {
  return queue->driver + 4 + (paddr_t)queue->num * 2;
}

static paddr_t virtq_avail_event_addr(const VirtqState *queue) {
  return queue->device + 4 + (paddr_t)queue->num * 8;
}

static bool virtq_need_event(uint16_t event_idx, uint16_t new_idx, uint16_t old_idx) {
  return (uint16_t)(new_idx - event_idx - 1) < (uint16_t)(new_idx - old_idx);
}

static void virtq_set_avail_event(VirtqState *queue, uint16_t avail_idx) {
  if (virtio_blk_event_idx_enabled() && queue->num != 0 &&
      guest_range_ok(virtq_avail_event_addr(queue), 2)) {
    // EVENT_IDX 协商后 used->flags 必须保持 0；avail_event 先设为下一次 avail idx，
    // 等价于不主动抑制 driver kick，保证同步解释器设备不会因缺通知饿死。
    guest_write16(queue->device, 0);
    guest_write16(virtq_avail_event_addr(queue), avail_idx);
  }
}

static bool virtq_aligned(paddr_t addr, uint32_t align) {
  return (addr & (paddr_t)(align - 1)) == 0;
}

static bool virtq_dma_range_valid(const char *name, paddr_t addr,
    uint32_t len, uint32_t align) {
  if (addr != 0 && virtq_aligned(addr, align) && guest_range_ok(addr, len)) {
    return true;
  }
  Log("virtio-blk: invalid %s ring addr=0x%" PRIx64 " len=%u align=%u",
      name, (uint64_t)addr, len, align);
  return false;
}

static bool virtq_validate_queue_layout(VirtqState *queue, uint32_t queue_idx) {
  if (queue->num == 0 || queue->num > VIRTIO_BLK_QUEUE_SIZE) {
    Log("virtio-blk: invalid queue=%u QueueNum=%u max=%u",
        queue_idx, queue->num, VIRTIO_BLK_QUEUE_SIZE);
    return false;
  }

  uint32_t desc_bytes = (uint32_t)queue->num * 16u;
  uint32_t event_tail = virtio_blk_event_idx_enabled() ? 2u : 0u;
  uint32_t driver_bytes = 4u + (uint32_t)queue->num * 2u + event_tail;
  uint32_t device_bytes = 4u + (uint32_t)queue->num * 8u + event_tail;

  // QueueReady 是进入真实 I/O 前的设备边界；在这里拒绝非法 DMA 布局，
  // 避免后续 QueueNotify 时把坏地址当成空队列或半有效请求继续消费。
  return virtq_dma_range_valid("desc", queue->desc, desc_bytes, 16) &&
         virtq_dma_range_valid("driver", queue->driver, driver_bytes, 2) &&
         virtq_dma_range_valid("device", queue->device, device_bytes, 4);
}

static bool guest_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static bool guest_copy_from(paddr_t addr, void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!guest_range_ok(addr, len)) return false;
  // 必须经 dcache 一致视图读: guest 刚写的数据段可能 dirty 停在 write-back dcache,
  // 裸 memcpy(guest_to_host) 会读到 pmem stale(与 #108 tohost 漏判同源)。
  return paddr_dma_read(addr, buf, len);
}

static bool guest_copy_to(paddr_t addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!guest_range_ok(addr, len)) return false;
  return paddr_dma_write(addr, buf, len);
}

static bool virtq_read_desc_from(paddr_t table, uint16_t table_num, uint16_t idx, VirtqDesc *desc) {
  if (idx >= table_num) return false;
  paddr_t base = table + (paddr_t)idx * 16;
  if (!guest_range_ok(base, 16)) return false;
  desc->addr = guest_read64(base);
  desc->len = guest_read32(base + 8);
  desc->flags = guest_read16(base + 12);
  desc->next = guest_read16(base + 14);
  return true;
}

static bool virtq_collect_table(paddr_t table, uint16_t table_num, uint16_t head,
    VirtqDesc *out, int *out_count) {
  if (table_num == 0 || table_num > VIRTIO_BLK_MAX_CHAIN) return false;

  bool seen[VIRTIO_BLK_MAX_CHAIN] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= table_num || seen[idx] || count >= (int)VIRTIO_BLK_MAX_CHAIN) return false;
    seen[idx] = true;
    if (!virtq_read_desc_from(table, table_num, idx, &out[count])) return false;
    // indirect 描述符只允许出现在主队列 head，不能在 indirect table 里再次嵌套。
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static bool virtq_collect_chain(const VirtqState *queue, uint16_t head,
    VirtqDesc *out, int *out_count) {
  VirtqDesc first;
  if (!virtq_read_desc_from(queue->desc, queue->num, head, &first)) return false;

  if (first.flags & VIRTQ_DESC_F_INDIRECT) {
    if ((first.flags & (VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE)) ||
        first.len == 0 || (first.len % 16) != 0) {
      return false;
    }
    uint32_t indirect_num = first.len / 16;
    if (indirect_num == 0 || indirect_num > VIRTIO_BLK_MAX_CHAIN) return false;
    // Linux 可能在压力下启用 indirect descriptor；这里按规范解析而不是强行依赖直接三段链。
    return virtq_collect_table(first.addr, indirect_num, 0, out, out_count);
  }

  bool seen[VIRTIO_BLK_QUEUE_SIZE] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= queue->num || idx >= VIRTIO_BLK_QUEUE_SIZE || seen[idx] ||
        count >= (int)VIRTIO_BLK_MAX_CHAIN) {
      return false;
    }
    seen[idx] = true;
    if (!virtq_read_desc_from(queue->desc, queue->num, idx, &out[count])) return false;
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static bool disk_range64_ok(uint64_t offset, uint64_t len) {
  return offset <= disk_size && len <= disk_size - offset;
}

static bool disk_range_ok(uint64_t offset, uint32_t len) {
  return disk_range64_ok(offset, len);
}

static bool disk_mmap_read(void *buf, uint32_t len, uint64_t offset) {
  if (disk_mmap == NULL || len > disk_mmap_size || offset > disk_mmap_size - len) {
    return false;
  }
  memcpy(buf, disk_mmap + offset, len);
  return true;
}

static bool disk_backing_pread_all(void *buf, uint32_t len, uint64_t offset) {
  if (disk_mmap_read(buf, len, offset)) {
    return true;
  }
  uint8_t *out = buf;
  while (len > 0) {
    ssize_t got = pread(fileno(disk_fp), out, len, (off_t)offset);
    if (got < 0 && errno == EINTR) continue;
    if (got <= 0) return false;
    out += got;
    offset += got;
    len -= got;
  }
  return true;
}

static bool disk_overlay_pread_all(void *buf, uint32_t len, uint64_t offset) {
  uint8_t *out = buf;
  while (len > 0) {
    ssize_t got = pread(fileno(disk_overlay_fp), out, len, (off_t)offset);
    if (got < 0 && errno == EINTR) continue;
    if (got <= 0) return false;
    out += got;
    offset += got;
    len -= got;
  }
  return true;
}

static bool disk_overlay_pwrite_all(const void *buf, uint32_t len, uint64_t offset) {
  const uint8_t *in = buf;
  while (len > 0) {
    ssize_t done = pwrite(fileno(disk_overlay_fp), in, len, (off_t)offset);
    if (done < 0 && errno == EINTR) continue;
    if (done <= 0) return false;
    in += done;
    offset += done;
    len -= done;
  }
  return true;
}

static bool disk_overlay_dirty_get(uint64_t sector) {
  Assert(sector < disk_overlay_sector_count, "overlay dirty sector out of range");
  return (disk_overlay_dirty[sector / 8] & (1u << (sector % 8))) != 0;
}

static void disk_overlay_dirty_set(uint64_t sector) {
  Assert(sector < disk_overlay_sector_count, "overlay dirty sector out of range");
  uint8_t mask = 1u << (sector % 8);
  uint8_t *byte = &disk_overlay_dirty[sector / 8];
  if ((*byte & mask) == 0) {
    *byte |= mask;
    disk_overlay_dirty_sector_count++;
  }
}

typedef enum {
  DISK_OVERLAY_RANGE_CLEAN,
  DISK_OVERLAY_RANGE_DIRTY,
  DISK_OVERLAY_RANGE_MIXED,
} DiskOverlayRangeState;

static DiskOverlayRangeState disk_overlay_range_state(uint64_t offset, uint32_t len) {
  uint64_t first = offset / VIRTIO_BLK_SECTOR_SIZE;
  uint64_t last = (offset + len - 1) / VIRTIO_BLK_SECTOR_SIZE;
  bool any_clean = false;
  bool any_dirty = false;
  for (uint64_t sector = first; sector <= last; sector++) {
    if (disk_overlay_dirty_get(sector)) any_dirty = true;
    else any_clean = true;
    if (any_clean && any_dirty) return DISK_OVERLAY_RANGE_MIXED;
  }
  return any_dirty ? DISK_OVERLAY_RANGE_DIRTY : DISK_OVERLAY_RANGE_CLEAN;
}

static bool disk_overlay_prepare_write(uint64_t offset, uint32_t len) {
  uint64_t write_end = offset + len;
  uint64_t first = offset / VIRTIO_BLK_SECTOR_SIZE;
  uint64_t last = (write_end - 1) / VIRTIO_BLK_SECTOR_SIZE;
  uint8_t sector_buf[VIRTIO_BLK_SECTOR_SIZE];

  for (uint64_t sector = first; sector <= last; sector++) {
    if (disk_overlay_dirty_get(sector)) continue;

    uint64_t sector_start = sector * VIRTIO_BLK_SECTOR_SIZE;
    uint64_t sector_end = sector_start + VIRTIO_BLK_SECTOR_SIZE;
    if (sector_end > disk_size) sector_end = disk_size;
    bool full_sector_write = offset <= sector_start && write_end >= sector_end;

    if (!full_sector_write) {
      uint32_t backing_len = (uint32_t)(sector_end - sector_start);
      memset(sector_buf, 0, sizeof(sector_buf));
      if (backing_len != 0 &&
          !disk_backing_pread_all(sector_buf, backing_len, sector_start)) {
        return false;
      }
      if (backing_len != 0 &&
          !disk_overlay_pwrite_all(sector_buf, backing_len, sector_start)) {
        return false;
      }
    }
    disk_overlay_dirty_set(sector);
  }
  return true;
}

static bool disk_pread_all(void *buf, uint32_t len, uint64_t offset) {
  if (disk_overlay_fp == NULL) {
    return disk_backing_pread_all(buf, len, offset);
  }

  DiskOverlayRangeState state = disk_overlay_range_state(offset, len);
  if (state == DISK_OVERLAY_RANGE_CLEAN) {
    return disk_backing_pread_all(buf, len, offset);
  }
  if (state == DISK_OVERLAY_RANGE_DIRTY) {
    return disk_overlay_pread_all(buf, len, offset);
  }

  uint8_t *out = buf;
  uint32_t left = len;
  uint64_t cur = offset;
  while (left > 0) {
    uint64_t sector = cur / VIRTIO_BLK_SECTOR_SIZE;
    uint32_t sector_off = cur % VIRTIO_BLK_SECTOR_SIZE;
    uint32_t chunk = VIRTIO_BLK_SECTOR_SIZE - sector_off;
    if (chunk > left) chunk = left;
    bool ok = disk_overlay_dirty_get(sector) ?
      disk_overlay_pread_all(out, chunk, cur) :
      disk_backing_pread_all(out, chunk, cur);
    if (!ok) return false;
    out += chunk;
    cur += chunk;
    left -= chunk;
  }
  return true;
}

static bool disk_pwrite_all(const void *buf, uint32_t len, uint64_t offset) {
  if (disk_overlay_fp != NULL) {
    if (!disk_overlay_prepare_write(offset, len)) return false;
    return disk_overlay_pwrite_all(buf, len, offset);
  }

  const uint8_t *in = buf;
  while (len > 0) {
    ssize_t done = pwrite(fileno(disk_fp), in, len, (off_t)offset);
    if (done < 0 && errno == EINTR) continue;
    if (done <= 0) return false;
    in += done;
    offset += done;
    len -= done;
  }
  return true;
}

static bool disk_sync_if_writethrough(void) {
  FILE *sync_fp = disk_overlay_fp != NULL ? disk_overlay_fp : disk_fp;
  return disk_writeback || (fflush(sync_fp) == 0 && fsync(fileno(sync_fp)) == 0);
}

static bool disk_zero_range(uint64_t offset, uint64_t len) {
  if (disk_readonly) return false;
  if (!disk_range64_ok(offset, len)) return false;
  uint8_t zeros[4096] = {};
  while (len > 0) {
    uint32_t chunk = len < sizeof(zeros) ? (uint32_t)len : (uint32_t)sizeof(zeros);
    if (!disk_pwrite_all(zeros, chunk, offset)) return false;
    offset += chunk;
    len -= chunk;
  }
  if (!disk_sync_if_writethrough()) return false;
  return true;
}

static bool virtio_blk_zero_range_from_sector(uint64_t sector, uint32_t num_sectors) {
  if (num_sectors == 0) return true;
  if (sector > UINT64_MAX / VIRTIO_BLK_SECTOR_SIZE) return false;
  uint64_t offset = sector * VIRTIO_BLK_SECTOR_SIZE;
  uint64_t len = (uint64_t)num_sectors * VIRTIO_BLK_SECTOR_SIZE;
  return disk_zero_range(offset, len);
}

static bool virtio_blk_req_add_data_seg(VirtioBlkAsyncReq *req, paddr_t addr,
    uint32_t len) {
  if (req->data_seg_count >= VIRTIO_BLK_MAX_CHAIN ||
      UINT32_MAX - req->data_len < len) {
    return false;
  }
  VirtioBlkDataSeg *seg = &req->data_segs[req->data_seg_count++];
  seg->addr = addr;
  seg->len = len;
  seg->data_off = req->data_len;
  req->data_len += len;
  return true;
}

static bool virtio_blk_req_alloc_data(VirtioBlkAsyncReq *req) {
  if (req->data_len == 0) return true;
  req->data = malloc(req->data_len);
  return req->data != NULL;
}

static bool virtio_blk_req_copy_from_guest(VirtioBlkAsyncReq *req) {
  for (uint32_t i = 0; i < req->data_seg_count; i++) {
    VirtioBlkDataSeg *seg = &req->data_segs[i];
    if (seg->len != 0 &&
        !guest_copy_from(seg->addr, req->data + seg->data_off, seg->len)) {
      return false;
    }
  }
  return true;
}

static bool virtio_blk_req_copy_to_guest(VirtioBlkAsyncReq *req) {
  for (uint32_t i = 0; i < req->data_seg_count; i++) {
    VirtioBlkDataSeg *seg = &req->data_segs[i];
    if (seg->len != 0 &&
        !guest_copy_to(seg->addr, req->data + seg->data_off, seg->len)) {
      return false;
    }
  }
  return true;
}

static void virtio_blk_req_fill_id(VirtioBlkAsyncReq *req) {
  if (req->data == NULL || req->data_len < VIRTIO_BLK_ID_BYTES) return;
  memset(req->data, 0, req->data_len);
  const char id_string[] = VIRTIO_BLK_ID_STRING;
  uint32_t id_len = sizeof(id_string) - 1u;
  if (id_len > VIRTIO_BLK_ID_BYTES) id_len = VIRTIO_BLK_ID_BYTES;
  memcpy(req->data, id_string, id_len);
}

static bool virtio_blk_req_add_zero_ranges(VirtioBlkAsyncReq *req,
    const VirtqDesc *descs, int status_desc, bool is_write_zeroes) {
  for (int i = 1; i < status_desc; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
        (descs[i].len % VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      return false;
    }

    for (uint32_t off = 0; off < descs[i].len; off += VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES) {
      paddr_t range = descs[i].addr + off;
      uint64_t sector = guest_read64(range);
      uint32_t num_sectors = guest_read32(range + 8);
      uint32_t flags = guest_read32(range + 12);
      if (req->zero_range_count >= VIRTIO_BLK_MAX_ZERO_RANGE_SEG ||
          num_sectors > VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS) {
        return false;
      }
      if (is_write_zeroes) {
        if ((flags & ~VIRTIO_BLK_WRITE_ZEROES_FLAG_UNMAP) != 0) return false;
      } else if (flags != 0) {
        return false;
      }
      VirtioBlkZeroRange *out = &req->zero_ranges[req->zero_range_count++];
      out->sector = sector;
      out->num_sectors = num_sectors;
    }
  }
  return true;
}

static VirtioBlkAsyncReq *virtio_blk_build_request(VirtqState *queue,
    uint32_t queue_idx, uint16_t head) {
  VirtioBlkAsyncReq *req = calloc(1, sizeof(*req));
  Assert(req != NULL, "Can not allocate virtio-blk request");
  req->generation = virtio_blk_generation;
  req->queue_idx = queue_idx;
  req->head = head;
  req->status = VIRTIO_BLK_S_OK;
  req->kind = VIRTIO_BLK_REQ_INVALID;

  VirtqDesc descs[VIRTIO_BLK_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(queue, head, descs, &count)) return req;
  if (count < 2 || descs[0].len < 16) return req;
  if (descs[0].flags & VIRTQ_DESC_F_WRITE) return req;
  if (!guest_range_ok(descs[0].addr, 16)) return req;

  uint32_t type = guest_read32(descs[0].addr);
  uint64_t sector = guest_read64(descs[0].addr + 8);
  int status_desc = count - 1;

  if ((descs[status_desc].flags & VIRTQ_DESC_F_WRITE) == 0 || descs[status_desc].len < 1) {
    return req;
  }
  req->status_addr = descs[status_desc].addr;
  req->write_status = true;
  if (sector > UINT64_MAX / VIRTIO_BLK_SECTOR_SIZE) {
    req->status = VIRTIO_BLK_S_IOERR;
    return req;
  }
  req->offset = sector * VIRTIO_BLK_SECTOR_SIZE;

  if (type == VIRTIO_BLK_T_IN) {
    req->kind = VIRTIO_BLK_REQ_IN;
    for (int i = 1; i < status_desc; i++) {
      if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0 ||
          !guest_range_ok(descs[i].addr, descs[i].len) ||
          !virtio_blk_req_add_data_seg(req, descs[i].addr, descs[i].len)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
    }
    if (req->status == VIRTIO_BLK_S_OK && !virtio_blk_req_alloc_data(req)) {
      req->status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_OUT) {
    req->kind = VIRTIO_BLK_REQ_OUT;
    for (int i = 1; i < status_desc; i++) {
      if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
          !guest_range_ok(descs[i].addr, descs[i].len) ||
          !virtio_blk_req_add_data_seg(req, descs[i].addr, descs[i].len)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
    }
    if (req->status == VIRTIO_BLK_S_OK &&
        (!virtio_blk_req_alloc_data(req) || !virtio_blk_req_copy_from_guest(req))) {
      req->status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_FLUSH) {
    req->kind = VIRTIO_BLK_REQ_FLUSH;
  } else if (type == VIRTIO_BLK_T_GET_ID) {
    // Linux 的 /sys/block/vda/serial 会触发 GET_ID；按规范写满固定 20B，
    // 即使未来请求被拆成多个 writable descriptor 也能返回稳定设备身份。
    req->kind = VIRTIO_BLK_REQ_GET_ID;
    uint32_t done = 0;
    for (int i = 1; i < status_desc && done < VIRTIO_BLK_ID_BYTES; i++) {
      if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0 ||
          !guest_range_ok(descs[i].addr, descs[i].len)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
      uint32_t left = VIRTIO_BLK_ID_BYTES - done;
      uint32_t chunk = descs[i].len < left ? descs[i].len : left;
      if (!virtio_blk_req_add_data_seg(req, descs[i].addr, chunk)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
      done += chunk;
    }
    if (done != VIRTIO_BLK_ID_BYTES) {
      req->status = VIRTIO_BLK_S_IOERR;
    } else if (!virtio_blk_req_alloc_data(req)) {
      req->status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_DISCARD) {
    if (!virtio_blk_driver_feature_enabled(VIRTIO_BLK_F_DISCARD)) {
      req->status = VIRTIO_BLK_S_UNSUPP;
    } else {
      req->kind = VIRTIO_BLK_REQ_ZERO_RANGE;
      req->zero_range_write_zeroes = false;
      if (!virtio_blk_req_add_zero_ranges(req, descs, status_desc, false)) {
        req->status = VIRTIO_BLK_S_IOERR;
      }
    }
  } else if (type == VIRTIO_BLK_T_WRITE_ZEROES) {
    if (!virtio_blk_driver_feature_enabled(VIRTIO_BLK_F_WRITE_ZEROES)) {
      req->status = VIRTIO_BLK_S_UNSUPP;
    } else {
      req->kind = VIRTIO_BLK_REQ_ZERO_RANGE;
      req->zero_range_write_zeroes = true;
      if (!virtio_blk_req_add_zero_ranges(req, descs, status_desc, true)) {
        req->status = VIRTIO_BLK_S_IOERR;
      }
    }
  } else {
    req->status = VIRTIO_BLK_S_UNSUPP;
  }

  return req;
}

static void virtio_blk_execute_request(VirtioBlkAsyncReq *req) {
  if (req->status != VIRTIO_BLK_S_OK) return;

  if (req->kind == VIRTIO_BLK_REQ_IN) {
    uint64_t offset = req->offset;
    req->used_len = 0;
    for (uint32_t i = 0; i < req->data_seg_count; i++) {
      VirtioBlkDataSeg *seg = &req->data_segs[i];
      if (!disk_range_ok(offset, seg->len) ||
          !disk_pread_all(req->data + seg->data_off, seg->len, offset)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
      offset += seg->len;
      req->used_len += seg->len;
    }
  } else if (req->kind == VIRTIO_BLK_REQ_OUT) {
    if (disk_readonly) {
      req->status = VIRTIO_BLK_S_IOERR;
      return;
    }
    uint64_t offset = req->offset;
    for (uint32_t i = 0; i < req->data_seg_count; i++) {
      VirtioBlkDataSeg *seg = &req->data_segs[i];
      if (!disk_range_ok(offset, seg->len) ||
          !disk_pwrite_all(req->data + seg->data_off, seg->len, offset)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
      offset += seg->len;
    }
    if (req->status == VIRTIO_BLK_S_OK && !disk_sync_if_writethrough()) {
      req->status = VIRTIO_BLK_S_IOERR;
    }
  } else if (req->kind == VIRTIO_BLK_REQ_FLUSH) {
    FILE *sync_fp = disk_overlay_fp != NULL ? disk_overlay_fp : disk_fp;
    if (sync_fp != NULL &&
        (fflush(sync_fp) != 0 || fsync(fileno(sync_fp)) != 0)) {
      req->status = VIRTIO_BLK_S_IOERR;
    }
  } else if (req->kind == VIRTIO_BLK_REQ_GET_ID) {
    virtio_blk_req_fill_id(req);
    req->used_len = VIRTIO_BLK_ID_BYTES;
  } else if (req->kind == VIRTIO_BLK_REQ_ZERO_RANGE) {
    if (disk_readonly) {
      req->status = VIRTIO_BLK_S_IOERR;
      return;
    }
    for (uint32_t i = 0; i < req->zero_range_count; i++) {
      VirtioBlkZeroRange *range = &req->zero_ranges[i];
      // raw image 后端没有 hole-punch 接口；DISCARD 与 WRITE_ZEROES 都采用确定性写零，
      // worker 线程串行执行这些 offset I/O，避免 overlay dirty bitmap 被并发改写。
      if (!virtio_blk_zero_range_from_sector(range->sector, range->num_sectors)) {
        req->status = VIRTIO_BLK_S_IOERR;
        break;
      }
    }
  }
}

static void virtio_blk_complete_request(VirtioBlkAsyncReq *req) {
  if (req->generation != virtio_blk_generation ||
      req->queue_idx >= VIRTIO_BLK_QUEUE_COUNT) {
    virtio_blk_free_request(req);
    return;
  }

  VirtqState *queue = &queues[req->queue_idx];
  if (!queue->ready || queue->num == 0 || queue->device == 0 || queue->driver == 0) {
    virtio_blk_free_request(req);
    return;
  }

  if (req->status == VIRTIO_BLK_S_OK &&
      (req->kind == VIRTIO_BLK_REQ_IN || req->kind == VIRTIO_BLK_REQ_GET_ID) &&
      !virtio_blk_req_copy_to_guest(req)) {
    req->status = VIRTIO_BLK_S_IOERR;
    req->used_len = 0;
  }

  virtio_blk_record_stats(req);

  uint32_t used_len = req->used_len;
  if (req->write_status) {
    if (guest_copy_to(req->status_addr, &req->status, 1)) {
      used_len++;
    } else {
      used_len = 0;
    }
  }

  uint16_t avail_flags = guest_read16(queue->driver);
  uint16_t old_used_idx = guest_read16(queue->device + 2);
  uint16_t used_idx = old_used_idx + 1;
  uint16_t used_off = old_used_idx % queue->num;
  guest_write32(queue->device + 4 + used_off * 8, req->head);
  guest_write32(queue->device + 4 + used_off * 8 + 4, used_len);
  guest_write16(queue->device + 2, used_idx);
  virtq_set_avail_event(queue, queue->last_avail_idx);

  bool notify = true;
  if (virtio_blk_event_idx_enabled()) {
    uint16_t used_event = guest_range_ok(virtq_used_event_addr(queue), 2) ?
      guest_read16(virtq_used_event_addr(queue)) : old_used_idx;
    notify = virtq_need_event(used_event, used_idx, old_used_idx);
  } else {
    notify = (avail_flags & VRING_AVAIL_F_NO_INTERRUPT) == 0;
  }

  if (notify) {
    // 异步后端完成时才置 used-buffer interrupt；PLIC IRQ2 仍由主线程触发。
    interrupt_status |= VIRTIO_MMIO_INT_USED_BUFFER;
    VIRTIO_IRQ_DEBUG_LOG("virtio-blk async used interrupt queue=%u head=%u old_used=%u new_used=%u status=%u len=%u event_idx=%u",
        req->queue_idx, req->head, old_used_idx, used_idx, req->status, used_len,
        virtio_blk_event_idx_enabled());
    virtio_blk_raise_irq();
  } else {
    VIRTIO_IRQ_DEBUG_LOG("virtio-blk async used interrupt suppressed queue=%u head=%u old_used=%u new_used=%u status=%u len=%u event_idx=%u",
        req->queue_idx, req->head, old_used_idx, used_idx, req->status, used_len,
        virtio_blk_event_idx_enabled());
  }

  virtio_blk_free_request(req);
}

static void virtio_blk_process_queue(uint32_t queue_idx) {
  if (queue_idx >= VIRTIO_BLK_QUEUE_COUNT) return;
  VirtqState *queue = &queues[queue_idx];
  if (disk_fp == NULL || !queue->ready || queue->num == 0 ||
      queue->desc == 0 || queue->driver == 0 || queue->device == 0) {
    return;
  }

  uint16_t avail_idx = guest_read16(queue->driver + 2);
  while (queue->last_avail_idx != avail_idx) {
    uint16_t ring_off = queue->last_avail_idx % queue->num;
    uint16_t head = guest_read16(queue->driver + 4 + ring_off * 2);
    VirtioBlkAsyncReq *req = virtio_blk_build_request(queue, queue_idx, head);
    queue->last_avail_idx++;
    virtio_blk_submit_request(req);
  }
  virtq_set_avail_event(queue, queue->last_avail_idx);
  virtio_blk_poll_async();
}

void virtio_blk_update(void) {
  virtio_blk_poll_async();
}

static void virtio_blk_reset(void) {
  virtio_blk_generation++;
  memset(driver_features, 0, sizeof(driver_features));
  memset(queues, 0, sizeof(queues));
  device_features_sel = 0;
  driver_features_sel = 0;
  interrupt_status = 0;
  device_status = 0;
  queue_sel = 0;
  virtio_blk_raise_irq();
}

static uint32_t virtio_read_reg(uint32_t offset) {
  VirtqState *queue = selected_queue();
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return 0x74726976u;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_2;
    case VIRTIO_MMIO_DEVICE_ID: return disk_fp != NULL ? VIRTIO_BLK_DEVICE_ID : 0;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES:
      return virtio_blk_device_features(device_features_sel);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL: return device_features_sel;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL: return driver_features_sel;
    case VIRTIO_MMIO_QUEUE_SEL: return queue_sel;
    case VIRTIO_MMIO_QUEUE_NUM_MAX: return queue != NULL ? VIRTIO_BLK_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return queue != NULL ? queue->num : 0;
    case VIRTIO_MMIO_QUEUE_READY: return queue != NULL && queue->ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS:
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk read interrupt status=0x%08x", interrupt_status);
      return interrupt_status;
    case VIRTIO_MMIO_STATUS: return device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW: return queue != NULL ? (uint32_t)queue->desc : 0;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH: return queue != NULL ? (uint32_t)((uint64_t)queue->desc >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW: return queue != NULL ? (uint32_t)queue->driver : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH: return queue != NULL ? (uint32_t)((uint64_t)queue->driver >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW: return queue != NULL ? (uint32_t)queue->device : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH: return queue != NULL ? (uint32_t)((uint64_t)queue->device >> 32) : 0;
    case VIRTIO_MMIO_CONFIG_GENERATION: return 0;
    case VIRTIO_MMIO_CONFIG: return (uint32_t)(disk_size / VIRTIO_BLK_SECTOR_SIZE);
    case VIRTIO_MMIO_CONFIG + 4: return (uint32_t)((disk_size / VIRTIO_BLK_SECTOR_SIZE) >> 32);
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_BLK_SIZE:
      // Linux virtio-blk 只有在协商 BLK_SIZE 后才读取这里；显式返回 512B，
      // 避免 guest 队列限制只是依赖内核默认值。
      return VIRTIO_BLK_SECTOR_SIZE;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_PHYSICAL_BLOCK_EXP:
      // TOPOLOGY 用最保守的 512B 物理块、0 对齐偏移和 512B minimum I/O，
      // 让 Linux 的 queue topology 走标准 virtio config 路径而不是默认猜测。
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_ALIGNMENT_OFFSET:
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MIN_IO_SIZE:
      return 1;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_OPT_IO_SIZE:
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WCE:
      // CONFIG_WCE 让 Linux /sys/block/vda/cache_type 能读写缓存模式；
      // write-through 模式下写请求会在完成前同步落盘，避免该 sysfs 控制只是空壳。
      return disk_writeback ? 1 : 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_NUM_QUEUES:
      return VIRTIO_BLK_QUEUE_COUNT;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_DISCARD_SECTORS:
      // 暴露保守的 2MiB 单段上限；后端按 offset 分块 pwrite 零化，不依赖 FILE seek 状态。
      return VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_DISCARD_SEG:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SEG;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_DISCARD_SECTOR_ALIGNMENT:
      return 1;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SECTORS:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SEG:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SEG;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITE_ZEROES_MAY_UNMAP:
      return 0;
    default: return 0;
  }
}

static void virtio_write_reg(uint32_t offset, uint32_t value) {
  switch (offset) {
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
      device_features_sel = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES:
      if (driver_features_sel < 2) driver_features[driver_features_sel] = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
      driver_features_sel = value;
      break;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WCE:
#if VIRTIO_BLK_ASYNC_BACKEND
      pthread_mutex_lock(&disk_backend_lock);
#endif
      disk_writeback = (value & 1u) != 0;
#if VIRTIO_BLK_ASYNC_BACKEND
      pthread_mutex_unlock(&disk_backend_lock);
#endif
      break;
    case VIRTIO_MMIO_QUEUE_SEL:
      queue_sel = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        if (value <= VIRTIO_BLK_QUEUE_SIZE) {
          queue->num = value;
        } else {
          // QueueNum 不能静默 clamp，否则坏 guest/坏驱动会以为更大的队列已经被设备接受。
          Log("virtio-blk: reject unsupported QueueNum queue=%u value=%u max=%u",
              queue_sel, value, VIRTIO_BLK_QUEUE_SIZE);
          queue->num = 0;
          queue->ready = false;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        if ((value & 1u) == 0) {
          queue->ready = false;
          queue->last_avail_idx = 0;
        } else if (virtq_validate_queue_layout(queue, queue_sel)) {
          queue->ready = true;
          queue->last_avail_idx = guest_read16(queue->driver + 2);
          virtq_set_avail_event(queue, queue->last_avail_idx);
        } else {
          queue->ready = false;
          queue->last_avail_idx = 0;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      // Linux 写 QueueNotify 后只提交 avail ring；host I/O 由 worker 执行，主线程稍后写回 used ring。
      if (value < VIRTIO_BLK_QUEUE_COUNT) {
        VIRTIO_IRQ_DEBUG_LOG("virtio-blk queue notify value=%u ready=%u num=%u last_avail=%u avail_idx=%u",
            value, queues[value].ready, queues[value].num, queues[value].last_avail_idx,
            queues[value].driver != 0 ? guest_read16(queues[value].driver + 2) : 0);
        virtio_blk_process_queue(value);
      } else {
        VIRTIO_IRQ_DEBUG_LOG("virtio-blk ignore invalid queue notify value=%u", value);
      }
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk interrupt ack value=0x%08x old_status=0x%08x",
          value, interrupt_status);
      interrupt_status &= ~value;
      virtio_blk_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_blk_reset();
      } else {
        // virtio 要求设备只在 driver 选择的 feature 全部受支持时保留 FEATURES_OK；
        // 否则后续 queue/IO 不能进入 DRIVER_OK，避免错误协商被 Linux 或 smoke 误当成功。
        device_status = value;
        if ((value & VIRTIO_STATUS_FEATURES_OK) &&
            !virtio_blk_driver_features_supported()) {
          device_status &= ~VIRTIO_STATUS_FEATURES_OK;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->desc = (queue->desc & 0xffffffff00000000ull) | value;
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->desc = ((uint64_t)value << 32) | (uint32_t)queue->desc;
      }
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->driver = (queue->driver & 0xffffffff00000000ull) | value;
      }
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->driver = ((uint64_t)value << 32) | (uint32_t)queue->driver;
      }
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->device = (queue->device & 0xffffffff00000000ull) | value;
      }
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      if (queue_sel < VIRTIO_BLK_QUEUE_COUNT) {
        VirtqState *queue = &queues[queue_sel];
        queue->device = ((uint64_t)value << 32) | (uint32_t)queue->device;
      }
      break;
    default:
      break;
  }
}

static void virtio_blk_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4 || len == 8);
  if (is_write) {
    if (len == 1 || len == 2 || len == 4) {
      virtio_write_reg(offset, host_read(virtio_base + offset, len));
    } else if (len == 8) {
      virtio_write_reg(offset, host_read(virtio_base + offset, 4));
      virtio_write_reg(offset + 4, host_read(virtio_base + offset + 4, 4));
    }
    return;
  }

  if (len == 8) {
    host_write(virtio_base + offset, 4, virtio_read_reg(offset));
    host_write(virtio_base + offset + 4, 4, virtio_read_reg(offset + 4));
  } else {
    host_write(virtio_base + offset, len, virtio_read_reg(offset));
  }
}

static void open_disk_overlay(void) {
  const char *path = disk_overlay_path;
  if (path == NULL || path[0] == '\0') {
    return;
  }

  int fd = open(path, O_RDWR | O_CREAT | O_TRUNC, 0600);
  Assert(fd >= 0, "Can not open block overlay '%s': %s", path, strerror(errno));
  Assert(ftruncate(fd, (off_t)disk_size) == 0,
      "Can not resize block overlay '%s' to %" PRIu64 " bytes: %s",
      path, disk_size, strerror(errno));
  disk_overlay_fp = fdopen(fd, "r+b");
  Assert(disk_overlay_fp != NULL, "Can not fdopen block overlay '%s': %s",
      path, strerror(errno));

  disk_overlay_sector_count =
    (disk_size + VIRTIO_BLK_SECTOR_SIZE - 1) / VIRTIO_BLK_SECTOR_SIZE;
  uint64_t dirty_bytes = (disk_overlay_sector_count + 7) / 8;
  disk_overlay_dirty = calloc((size_t)dirty_bytes, 1);
  Assert(disk_overlay_dirty != NULL, "Can not allocate overlay dirty bitmap");
  disk_overlay_dirty_sector_count = 0;
  disk_readonly = false;

  Log("virtio-blk: overlay=%s sectors=%" PRIu64 " backing_readonly=%u",
      path, disk_overlay_sector_count, disk_backing_readonly);
}

static void open_disk_image(void) {
  const char *path = disk_image_path;
  if ((path == NULL || path[0] == '\0') && strlen(CONFIG_DISK_IMG_PATH) > 0) {
    path = CONFIG_DISK_IMG_PATH;
  }
  if (path == NULL || path[0] == '\0') {
    Log("virtio-blk: no --block image, device id stays 0");
    return;
  }

  disk_fp = fopen(path, "r+b");
  if (disk_fp == NULL) {
    disk_fp = fopen(path, "rb");
    disk_backing_readonly = true;
    disk_readonly = true;
  }
  Assert(disk_fp != NULL, "Can not open block image '%s': %s", path, strerror(errno));
  Assert(fseeko(disk_fp, 0, SEEK_END) == 0, "Can not seek block image '%s'", path);
  off_t size = ftello(disk_fp);
  Assert(size > 0, "Invalid block image size for '%s'", path);
  disk_size = size;
  rewind(disk_fp);
  if ((uint64_t)(size_t)disk_size == disk_size) {
    void *map = mmap(NULL, (size_t)disk_size, PROT_READ, MAP_SHARED, fileno(disk_fp), 0);
    if (map != MAP_FAILED) {
      // raw rootfs 的读路径远多于写路径；共享只读 mmap 命中时可直接 memcpy，
      // 失败或宿主不支持时仍回退 pread，保持 bring-up 的可移植性。
      disk_mmap = map;
      disk_mmap_size = disk_size;
    } else if (disk_log_budget > 0) {
      Log("virtio-blk: mmap read cache disabled for '%s': %s", path, strerror(errno));
    }
  }
  open_disk_overlay();
  if (disk_log_budget > 0) {
    disk_log_budget--;
    Log("virtio-blk: image=%s size=%" PRIu64 " bytes%s read_mmap=%s write_target=%s",
        path, disk_size, disk_readonly ? " readonly" : "",
        disk_mmap != NULL ? "enabled" : "disabled",
        disk_overlay_fp != NULL ? "overlay" : "backing");
  }
}

void init_disk() {
  virtio_base = new_space(0x1000);
  const char *force_sync = getenv("NEMU_VIRTIO_BLK_SYNC");
  disk_force_sync_backend = force_sync != NULL && force_sync[0] != '\0' &&
    strcmp(force_sync, "0") != 0;
  virtio_blk_reset();
  open_disk_image();
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("virtio-blk", CONFIG_DISK_CTL_PORT, virtio_base, 0x1000, virtio_blk_io_handler);
#else
  add_mmio_map("virtio-blk", DEV_DISK_MMIO, virtio_base, 0x1000, virtio_blk_io_handler);
#endif
}
