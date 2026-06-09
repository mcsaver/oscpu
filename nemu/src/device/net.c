/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <isa.h>
#include <memory/host.h>
#include <memory/paddr.h>

#include <inttypes.h>
#include <string.h>

// 当前 virtio-net 先闭合 hostless 最小数据路径：Linux 可枚举的 modern
// virtio-mmio 网卡、稳定 MAC/link-up、TX/RX vring，以及固定 10.0.2.2
// 的 ARP/ICMP/DHCP/DNS/TCP responder；真实 TAP/NAT/packet backend 留给后续切片，
// 避免现在假装已经具备外网能力。
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

#define VIRTIO_NET_DEVICE_ID 1u
#define VIRTIO_MMIO_VERSION_2 2u
#define VIRTIO_VENDOR_YSYX 0x58535959u
#define VIRTIO_RING_F_INDIRECT_DESC 28
#define VIRTIO_RING_F_EVENT_IDX 29
#define VIRTIO_F_VERSION_1 32
#define VIRTIO_MMIO_INT_USED_BUFFER 0x1u
#define VIRTIO_NET_F_MAC 5
#define VIRTIO_NET_F_MRG_RXBUF 15
#define VIRTIO_NET_F_STATUS 16
#define VIRTIO_NET_S_LINK_UP 1u
#define VRING_AVAIL_F_NO_INTERRUPT 0x1u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VIRTQ_DESC_F_NEXT  0x1u
#define VIRTQ_DESC_F_WRITE 0x2u
#define VIRTQ_DESC_F_INDIRECT 0x4u

#define VIRTIO_NET_QUEUE_RX 0u
#define VIRTIO_NET_QUEUE_TX 1u
#define VIRTIO_NET_QUEUE_COUNT 2u
#define VIRTIO_NET_QUEUE_SIZE 64u
#define VIRTIO_NET_MAX_CHAIN 128u
#define VIRTIO_NET_IRQ 5u
#define VIRTIO_NET_CONFIG_BYTES 8u
#define VIRTIO_NET_HDR_MIN_LEN 10u
#define VIRTIO_NET_HDR_MRG_LEN 12u
#define VIRTIO_NET_RX_HDR_LEN VIRTIO_NET_HDR_MRG_LEN
#define VIRTIO_NET_ETH_MIN_FRAME 60u
#define VIRTIO_NET_FRAME_MAX 1514u
#define VIRTIO_NET_RX_PENDING_CAP 8u

#define ETH_P_IP 0x0800u
#define ETH_P_ARP 0x0806u
#define ARP_HTYPE_ETHERNET 1u
#define ARP_OPER_REQUEST 1u
#define ARP_OPER_REPLY 2u
#define IPPROTO_ICMP 1u
#define IPPROTO_TCP 6u
#define IPPROTO_UDP 17u
#define ICMP_ECHO_REPLY 0u
#define ICMP_ECHO_REQUEST 8u
#define DHCP_SERVER_PORT 67u
#define DHCP_CLIENT_PORT 68u
#define DHCP_BOOTREQUEST 1u
#define DHCP_BOOTREPLY 2u
#define DHCP_HTYPE_ETHERNET 1u
#define DHCP_MAGIC_COOKIE 0x63825363u
#define DHCP_OPT_PAD 0u
#define DHCP_OPT_SUBNET_MASK 1u
#define DHCP_OPT_ROUTER 3u
#define DHCP_OPT_DNS 6u
#define DHCP_OPT_REQUESTED_IP 50u
#define DHCP_OPT_LEASE_TIME 51u
#define DHCP_OPT_MSG_TYPE 53u
#define DHCP_OPT_SERVER_ID 54u
#define DHCP_OPT_END 255u
#define DHCPDISCOVER 1u
#define DHCPOFFER 2u
#define DHCPREQUEST 3u
#define DHCPACK 5u
#define DHCP_FIXED_LEN 240u
#define DHCP_LEASE_SECONDS 86400u
#define DNS_SERVER_PORT 53u
#define DNS_HEADER_LEN 12u
#define DNS_QTYPE_A 1u
#define DNS_QCLASS_IN 1u
#define DNS_TTL_SECONDS 60u
#define TCP_HTTP_PORT 80u
#define TCP_WINDOW_SIZE 4096u
#define TCP_FLAG_FIN 0x01u
#define TCP_FLAG_SYN 0x02u
#define TCP_FLAG_RST 0x04u
#define TCP_FLAG_PSH 0x08u
#define TCP_FLAG_ACK 0x10u

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
  uint8_t data[VIRTIO_NET_FRAME_MAX];
  uint32_t len;
} VirtioNetPacket;

static uint8_t *net_base;
static uint32_t device_features_sel;
static uint32_t driver_features_sel;
static uint32_t driver_features[2];
static uint32_t interrupt_status;
static uint32_t device_status;
static uint32_t queue_sel;
static VirtqState queues[VIRTIO_NET_QUEUE_COUNT];
static const uint8_t virtio_net_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};
static const uint8_t virtio_net_host_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x57};
static const uint8_t virtio_net_host_ip[4] = {10, 0, 2, 2};
static const uint8_t virtio_net_guest_ip[4] = {10, 0, 2, 15};
static const uint8_t virtio_net_subnet_mask[4] = {255, 255, 255, 0};
static VirtioNetPacket rx_pending[VIRTIO_NET_RX_PENDING_CAP];
static uint32_t rx_pending_head;
static uint32_t rx_pending_tail;
static uint32_t rx_pending_count;

static uint32_t virtio_net_device_features(uint32_t sel) {
  if (sel == 0) {
    return (1u << VIRTIO_NET_F_MAC) |
           (1u << VIRTIO_NET_F_MRG_RXBUF) |
           (1u << VIRTIO_NET_F_STATUS) |
           (1u << VIRTIO_RING_F_INDIRECT_DESC) |
           (1u << VIRTIO_RING_F_EVENT_IDX);
  }
  if (sel == 1) {
    return 1u << (VIRTIO_F_VERSION_1 - 32);
  }
  return 0;
}

static bool virtio_net_driver_features_supported(void) {
  for (uint32_t sel = 0; sel < 2; sel++) {
    uint32_t unsupported = driver_features[sel] & ~virtio_net_device_features(sel);
    if (unsupported != 0) {
      Log("virtio-net: unsupported driver features sel=%u bits=0x%08x", sel, unsupported);
      return false;
    }
  }
  return true;
}

static bool virtio_net_driver_feature_enabled(uint32_t bit) {
  uint32_t sel = bit / 32;
  uint32_t off = bit % 32;
  return sel < 2 && (driver_features[sel] & (1u << off)) != 0;
}

static bool virtio_net_event_idx_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_RING_F_EVENT_IDX);
}

static void virtio_net_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv, isa_riscv_plic_set_irq(VIRTIO_NET_IRQ, interrupt_status != 0));
}

static uint16_t guest_read16(paddr_t addr) {
  return paddr_read(addr, 2);
}

static uint32_t guest_read32(paddr_t addr) {
  return paddr_read(addr, 4);
}

static uint64_t guest_read64(paddr_t addr) {
  return paddr_read(addr, 8);
}

static void guest_write16(paddr_t addr, uint16_t value) {
  paddr_write(addr, 2, value);
}

static void guest_write32(paddr_t addr, uint32_t value) {
  paddr_write(addr, 4, value);
}

static bool guest_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static uint16_t net_get_be16(const uint8_t *p) {
  return ((uint16_t)p[0] << 8) | p[1];
}

static uint32_t net_get_be32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | p[3];
}

static void net_put_be16(uint8_t *p, uint16_t value) {
  p[0] = value >> 8;
  p[1] = value & 0xffu;
}

static void net_put_be32(uint8_t *p, uint32_t value) {
  p[0] = value >> 24;
  p[1] = (value >> 16) & 0xffu;
  p[2] = (value >> 8) & 0xffu;
  p[3] = value & 0xffu;
}

static uint16_t net_checksum(const uint8_t *data, uint32_t len) {
  uint32_t sum = 0;
  while (len >= 2) {
    sum += net_get_be16(data);
    data += 2;
    len -= 2;
  }
  if (len != 0) {
    sum += (uint16_t)data[0] << 8;
  }
  while ((sum >> 16) != 0) {
    sum = (sum & 0xffffu) + (sum >> 16);
  }
  return (uint16_t)~sum;
}

static uint32_t net_checksum_accumulate(uint32_t sum, const uint8_t *data,
    uint32_t len) {
  while (len >= 2) {
    sum += net_get_be16(data);
    data += 2;
    len -= 2;
  }
  if (len != 0) {
    sum += (uint16_t)data[0] << 8;
  }
  return sum;
}

static uint16_t net_checksum_finish(uint32_t sum) {
  while ((sum >> 16) != 0) {
    sum = (sum & 0xffffu) + (sum >> 16);
  }
  return (uint16_t)~sum;
}

static uint16_t tcp_checksum_ipv4(const uint8_t *src_ip, const uint8_t *dst_ip,
    const uint8_t *tcp, uint32_t tcp_len) {
  uint32_t sum = 0;
  sum = net_checksum_accumulate(sum, src_ip, 4);
  sum = net_checksum_accumulate(sum, dst_ip, 4);
  sum += IPPROTO_TCP;
  sum += tcp_len;
  sum = net_checksum_accumulate(sum, tcp, tcp_len);
  return net_checksum_finish(sum);
}

static bool virtq_aligned(paddr_t addr, uint32_t align) {
  return (addr & (paddr_t)(align - 1)) == 0;
}

static paddr_t virtq_used_event_addr(const VirtqState *q) {
  return q->driver + 4 + (paddr_t)q->num * 2;
}

static paddr_t virtq_avail_event_addr(const VirtqState *q) {
  return q->device + 4 + (paddr_t)q->num * 8;
}

static bool virtq_need_event(uint16_t event_idx, uint16_t new_idx, uint16_t old_idx) {
  return (uint16_t)(new_idx - event_idx - 1) < (uint16_t)(new_idx - old_idx);
}

static void virtq_set_avail_event(VirtqState *q, uint16_t avail_idx) {
  if (virtio_net_event_idx_enabled() && q->num != 0 &&
      guest_range_ok(virtq_avail_event_addr(q), 2)) {
    // 和 virtio-blk 保持一致：先不抑制 driver kick，只把设备已消费到的位置回写给 Linux。
    guest_write16(q->device, 0);
    guest_write16(virtq_avail_event_addr(q), avail_idx);
  }
}

static bool virtq_dma_range_valid(const char *name, const VirtqState *q,
    paddr_t addr, uint32_t len, uint32_t align) {
  if (addr != 0 && virtq_aligned(addr, align) && guest_range_ok(addr, len)) {
    return true;
  }
  Log("virtio-net: invalid %s ring q=%u addr=0x%" PRIx64 " len=%u align=%u",
      name, (unsigned)(q - queues), (uint64_t)addr, len, align);
  return false;
}

static bool virtq_validate_queue_layout(VirtqState *q) {
  if (q->num == 0 || q->num > VIRTIO_NET_QUEUE_SIZE) {
    Log("virtio-net: invalid QueueNum q=%u num=%u max=%u",
        (unsigned)(q - queues), q->num, VIRTIO_NET_QUEUE_SIZE);
    return false;
  }
  uint32_t desc_bytes = (uint32_t)q->num * 16u;
  uint32_t event_tail = virtio_net_event_idx_enabled() ? 2u : 0u;
  uint32_t driver_bytes = 4u + (uint32_t)q->num * 2u + event_tail;
  uint32_t device_bytes = 4u + (uint32_t)q->num * 8u + event_tail;
  return virtq_dma_range_valid("desc", q, q->desc, desc_bytes, 16) &&
         virtq_dma_range_valid("driver", q, q->driver, driver_bytes, 2) &&
         virtq_dma_range_valid("device", q, q->device, device_bytes, 4);
}

static bool virtq_read_desc_from(paddr_t table, uint16_t table_num,
    uint16_t idx, VirtqDesc *desc) {
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
  if (table_num == 0 || table_num > VIRTIO_NET_MAX_CHAIN) return false;
  bool seen[VIRTIO_NET_MAX_CHAIN] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= table_num || idx >= VIRTIO_NET_MAX_CHAIN || seen[idx] ||
        count >= (int)VIRTIO_NET_MAX_CHAIN) {
      return false;
    }
    seen[idx] = true;
    if (!virtq_read_desc_from(table, table_num, idx, &out[count])) return false;
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }
  *out_count = count;
  return true;
}

static bool virtq_collect_chain(VirtqState *q, uint16_t head,
    VirtqDesc *out, int *out_count) {
  VirtqDesc first;
  if (!virtq_read_desc_from(q->desc, q->num, head, &first)) return false;

  if (first.flags & VIRTQ_DESC_F_INDIRECT) {
    if ((first.flags & (VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE)) ||
        first.len == 0 || (first.len % 16) != 0) {
      return false;
    }
    uint32_t indirect_num = first.len / 16;
    if (indirect_num == 0 || indirect_num > VIRTIO_NET_MAX_CHAIN) return false;
    return virtq_collect_table(first.addr, indirect_num, 0, out, out_count);
  }

  return virtq_collect_table(q->desc, q->num, head, out, out_count);
}

static bool virtq_copy_from_readable_chain(const VirtqDesc *descs, int count,
    uint32_t skip, uint8_t *dst, uint32_t len) {
  uint32_t copied = 0;
  for (int i = 0; i < count && copied < len; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      return false;
    }
    if (skip >= descs[i].len) {
      skip -= descs[i].len;
      continue;
    }
    uint32_t off = skip;
    skip = 0;
    uint32_t avail = descs[i].len - off;
    uint32_t take = len - copied < avail ? len - copied : avail;
    memcpy(dst + copied, guest_to_host(descs[i].addr + off), take);
    copied += take;
  }
  return copied == len;
}

static bool virtq_write_to_writable_chain(const VirtqDesc *descs, int count,
    const uint8_t *frame, uint32_t frame_len, uint32_t *used_len) {
  uint8_t net_hdr[VIRTIO_NET_RX_HDR_LEN] = {};
  net_hdr[10] = 1;
  uint32_t total = VIRTIO_NET_RX_HDR_LEN + frame_len;
  uint32_t written = 0;
  for (int i = 0; i < count && written < total; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      return false;
    }
    uint32_t desc_off = 0;
    while (desc_off < descs[i].len && written < total) {
      const uint8_t *src;
      uint32_t left;
      if (written < VIRTIO_NET_RX_HDR_LEN) {
        src = net_hdr + written;
        left = VIRTIO_NET_RX_HDR_LEN - written;
      } else {
        uint32_t frame_off = written - VIRTIO_NET_RX_HDR_LEN;
        src = frame + frame_off;
        left = frame_len - frame_off;
      }
      uint32_t avail = descs[i].len - desc_off;
      uint32_t take = left < avail ? left : avail;
      memcpy(guest_to_host(descs[i].addr + desc_off), src, take);
      desc_off += take;
      written += take;
    }
  }
  if (written != total) return false;
  *used_len = total;
  return true;
}

static void virtq_push_used(VirtqState *q, uint16_t head, uint32_t used_len,
    uint16_t *used_idx) {
  uint16_t used_off = *used_idx % q->num;
  guest_write32(q->device + 4 + used_off * 8, head);
  guest_write32(q->device + 4 + used_off * 8 + 4, used_len);
  (*used_idx)++;
  guest_write16(q->device + 2, *used_idx);
}

static void virtq_maybe_interrupt(VirtqState *q,
    uint16_t old_used_idx, uint16_t new_used_idx) {
  bool notify;
  if (virtio_net_event_idx_enabled()) {
    uint16_t used_event = guest_range_ok(virtq_used_event_addr(q), 2) ?
      guest_read16(virtq_used_event_addr(q)) : old_used_idx;
    notify = virtq_need_event(used_event, new_used_idx, old_used_idx);
  } else {
    uint16_t avail_flags = guest_read16(q->driver);
    notify = (avail_flags & VRING_AVAIL_F_NO_INTERRUPT) == 0;
  }
  if (notify) {
    interrupt_status |= VIRTIO_MMIO_INT_USED_BUFFER;
    virtio_net_raise_irq();
  }
}

static void virtio_net_try_deliver_rx_queue(void);

static bool virtio_net_enqueue_rx_frame(const uint8_t *frame, uint32_t len) {
  if (len > VIRTIO_NET_FRAME_MAX) return false;
  if (rx_pending_count >= VIRTIO_NET_RX_PENDING_CAP) {
    Log("virtio-net: drop responder frame, pending rx queue full");
    return false;
  }
  memcpy(rx_pending[rx_pending_tail].data, frame, len);
  rx_pending[rx_pending_tail].len = len;
  rx_pending_tail = (rx_pending_tail + 1) % VIRTIO_NET_RX_PENDING_CAP;
  rx_pending_count++;
  virtio_net_try_deliver_rx_queue();
  return true;
}

static bool virtio_net_handle_arp(const uint8_t *frame, uint32_t len) {
  if (len < 42) return false;
  const uint8_t *arp = frame + 14;
  if (net_get_be16(arp) != ARP_HTYPE_ETHERNET ||
      net_get_be16(arp + 2) != ETH_P_IP ||
      arp[4] != 6 || arp[5] != 4 ||
      net_get_be16(arp + 6) != ARP_OPER_REQUEST ||
      memcmp(arp + 24, virtio_net_host_ip, sizeof(virtio_net_host_ip)) != 0) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_ETH_MIN_FRAME] = {};
  memcpy(reply, frame + 6, 6);
  memcpy(reply + 6, virtio_net_host_mac, 6);
  net_put_be16(reply + 12, ETH_P_ARP);
  net_put_be16(reply + 14, ARP_HTYPE_ETHERNET);
  net_put_be16(reply + 16, ETH_P_IP);
  reply[18] = 6;
  reply[19] = 4;
  net_put_be16(reply + 20, ARP_OPER_REPLY);
  memcpy(reply + 22, virtio_net_host_mac, 6);
  memcpy(reply + 28, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memcpy(reply + 32, arp + 8, 6);
  memcpy(reply + 38, arp + 14, 4);
  return virtio_net_enqueue_rx_frame(reply, sizeof(reply));
}

static bool virtio_net_handle_icmp(const uint8_t *frame, uint32_t len) {
  if (len < 14 + 20 + 8 || net_get_be16(frame + 12) != ETH_P_IP) {
    return false;
  }
  const uint8_t *ip = frame + 14;
  uint32_t ihl = (ip[0] & 0x0fu) * 4u;
  if ((ip[0] >> 4) != 4 || ihl < 20 || len < 14 + ihl + 8 ||
      ip[9] != IPPROTO_ICMP ||
      memcmp(ip + 16, virtio_net_host_ip, sizeof(virtio_net_host_ip)) != 0) {
    return false;
  }

  uint32_t total_len = net_get_be16(ip + 2);
  if (total_len < ihl + 8 || total_len > VIRTIO_NET_FRAME_MAX - 14 ||
      len < 14 + total_len) {
    return false;
  }
  const uint8_t *icmp = ip + ihl;
  if (icmp[0] != ICMP_ECHO_REQUEST || icmp[1] != 0) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_FRAME_MAX] = {};
  uint32_t reply_len = 14 + total_len;
  memcpy(reply, frame, reply_len);
  memcpy(reply, frame + 6, 6);
  memcpy(reply + 6, virtio_net_host_mac, 6);

  uint8_t *reply_ip = reply + 14;
  reply_ip[8] = 64;
  memcpy(reply_ip + 12, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memcpy(reply_ip + 16, ip + 12, 4);
  reply_ip[10] = 0;
  reply_ip[11] = 0;
  net_put_be16(reply_ip + 10, net_checksum(reply_ip, ihl));

  uint8_t *reply_icmp = reply_ip + ihl;
  uint32_t icmp_len = total_len - ihl;
  reply_icmp[0] = ICMP_ECHO_REPLY;
  reply_icmp[1] = 0;
  reply_icmp[2] = 0;
  reply_icmp[3] = 0;
  net_put_be16(reply_icmp + 2, net_checksum(reply_icmp, icmp_len));
  if (reply_len < VIRTIO_NET_ETH_MIN_FRAME) {
    reply_len = VIRTIO_NET_ETH_MIN_FRAME;
  }
  return virtio_net_enqueue_rx_frame(reply, reply_len);
}

static uint32_t dhcp_put_opt(uint8_t *opts, uint32_t off, uint8_t code,
    const uint8_t *value, uint8_t len) {
  opts[off++] = code;
  opts[off++] = len;
  memcpy(opts + off, value, len);
  return off + len;
}

static uint32_t dhcp_put_u32_opt(uint8_t *opts, uint32_t off, uint8_t code,
    uint32_t value) {
  uint8_t buf[4];
  net_put_be32(buf, value);
  return dhcp_put_opt(opts, off, code, buf, sizeof(buf));
}

static bool dhcp_find_msg_type(const uint8_t *opts, uint32_t len,
    uint8_t *msg_type) {
  uint32_t off = 0;
  while (off < len) {
    uint8_t code = opts[off++];
    if (code == DHCP_OPT_END) break;
    if (code == DHCP_OPT_PAD) continue;
    if (off >= len) return false;
    uint8_t opt_len = opts[off++];
    if (off + opt_len > len) return false;
    if (code == DHCP_OPT_MSG_TYPE && opt_len == 1) {
      *msg_type = opts[off];
      return true;
    }
    off += opt_len;
  }
  return false;
}

static bool virtio_net_handle_dhcp(const uint8_t *frame, uint32_t len) {
  if (len < 14 + 20 + 8 + DHCP_FIXED_LEN || net_get_be16(frame + 12) != ETH_P_IP) {
    return false;
  }
  const uint8_t *ip = frame + 14;
  uint32_t ihl = (ip[0] & 0x0fu) * 4u;
  if ((ip[0] >> 4) != 4 || ihl < 20 || ip[9] != IPPROTO_UDP) return false;

  uint32_t total_len = net_get_be16(ip + 2);
  if (total_len < ihl + 8 + DHCP_FIXED_LEN || total_len > VIRTIO_NET_FRAME_MAX - 14 ||
      len < 14 + total_len) {
    return false;
  }
  const uint8_t *udp = ip + ihl;
  uint32_t udp_len = net_get_be16(udp + 4);
  if (udp_len < 8 + DHCP_FIXED_LEN || ihl + udp_len > total_len ||
      net_get_be16(udp + 2) != DHCP_SERVER_PORT) {
    return false;
  }
  const uint8_t *dhcp = udp + 8;
  uint32_t dhcp_len = udp_len - 8;
  if (dhcp[0] != DHCP_BOOTREQUEST ||
      dhcp[1] != DHCP_HTYPE_ETHERNET ||
      dhcp[2] != 6 ||
      net_get_be32(dhcp + 236) != DHCP_MAGIC_COOKIE) {
    return false;
  }

  uint8_t msg_type = 0;
  if (!dhcp_find_msg_type(dhcp + DHCP_FIXED_LEN, dhcp_len - DHCP_FIXED_LEN, &msg_type) ||
      (msg_type != DHCPDISCOVER && msg_type != DHCPREQUEST)) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_FRAME_MAX] = {};
  memset(reply, 0xff, 6);
  memcpy(reply + 6, virtio_net_host_mac, 6);
  net_put_be16(reply + 12, ETH_P_IP);

  uint8_t *reply_ip = reply + 14;
  reply_ip[0] = 0x45;
  reply_ip[8] = 64;
  reply_ip[9] = IPPROTO_UDP;
  memcpy(reply_ip + 12, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memset(reply_ip + 16, 0xff, 4);

  uint8_t *reply_udp = reply_ip + 20;
  net_put_be16(reply_udp, DHCP_SERVER_PORT);
  net_put_be16(reply_udp + 2, DHCP_CLIENT_PORT);

  uint8_t *reply_dhcp = reply_udp + 8;
  reply_dhcp[0] = DHCP_BOOTREPLY;
  reply_dhcp[1] = DHCP_HTYPE_ETHERNET;
  reply_dhcp[2] = 6;
  reply_dhcp[3] = 0;
  memcpy(reply_dhcp + 4, dhcp + 4, 4);
  memcpy(reply_dhcp + 8, dhcp + 8, 2);
  memcpy(reply_dhcp + 10, dhcp + 10, 2);
  memcpy(reply_dhcp + 16, virtio_net_guest_ip, sizeof(virtio_net_guest_ip));
  memcpy(reply_dhcp + 20, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memcpy(reply_dhcp + 28, dhcp + 28, 16);
  net_put_be32(reply_dhcp + 236, DHCP_MAGIC_COOKIE);

  uint8_t *opts = reply_dhcp + DHCP_FIXED_LEN;
  uint32_t opt_off = 0;
  uint8_t reply_type = msg_type == DHCPDISCOVER ? DHCPOFFER : DHCPACK;
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_MSG_TYPE, &reply_type, 1);
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_SERVER_ID,
      virtio_net_host_ip, sizeof(virtio_net_host_ip));
  opt_off = dhcp_put_u32_opt(opts, opt_off, DHCP_OPT_LEASE_TIME, DHCP_LEASE_SECONDS);
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_SUBNET_MASK,
      virtio_net_subnet_mask, sizeof(virtio_net_subnet_mask));
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_ROUTER,
      virtio_net_host_ip, sizeof(virtio_net_host_ip));
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_DNS,
      virtio_net_host_ip, sizeof(virtio_net_host_ip));
  opts[opt_off++] = DHCP_OPT_END;

  uint32_t reply_dhcp_len = DHCP_FIXED_LEN + opt_off;
  uint32_t reply_udp_len = 8 + reply_dhcp_len;
  uint32_t reply_total_len = 20 + reply_udp_len;
  net_put_be16(reply_ip + 2, reply_total_len);
  net_put_be16(reply_ip + 10, 0);
  net_put_be16(reply_ip + 10, net_checksum(reply_ip, 20));
  net_put_be16(reply_udp + 4, reply_udp_len);
  net_put_be16(reply_udp + 6, 0);

  uint32_t reply_len = 14 + reply_total_len;
  if (reply_len < VIRTIO_NET_ETH_MIN_FRAME) {
    reply_len = VIRTIO_NET_ETH_MIN_FRAME;
  }
  return virtio_net_enqueue_rx_frame(reply, reply_len);
}

static bool dns_query_is_nemu_local_a(const uint8_t *dns, uint32_t dns_len,
    uint32_t *question_end) {
  static const uint8_t nemu_local_qname[] = {
    4, 'n', 'e', 'm', 'u',
    5, 'l', 'o', 'c', 'a', 'l',
    0,
  };
  if (dns_len < DNS_HEADER_LEN + sizeof(nemu_local_qname) + 4 ||
      net_get_be16(dns + 4) != 1) {
    return false;
  }
  uint32_t off = DNS_HEADER_LEN;
  if (memcmp(dns + off, nemu_local_qname, sizeof(nemu_local_qname)) != 0) {
    return false;
  }
  off += sizeof(nemu_local_qname);
  if (net_get_be16(dns + off) != DNS_QTYPE_A ||
      net_get_be16(dns + off + 2) != DNS_QCLASS_IN) {
    return false;
  }
  *question_end = off + 4;
  return true;
}

static bool virtio_net_handle_dns(const uint8_t *frame, uint32_t len) {
  if (len < 14 + 20 + 8 + DNS_HEADER_LEN || net_get_be16(frame + 12) != ETH_P_IP) {
    return false;
  }
  const uint8_t *ip = frame + 14;
  uint32_t ihl = (ip[0] & 0x0fu) * 4u;
  if ((ip[0] >> 4) != 4 || ihl < 20 || ip[9] != IPPROTO_UDP ||
      memcmp(ip + 16, virtio_net_host_ip, sizeof(virtio_net_host_ip)) != 0) {
    return false;
  }

  uint32_t total_len = net_get_be16(ip + 2);
  if (total_len < ihl + 8 + DNS_HEADER_LEN || total_len > VIRTIO_NET_FRAME_MAX - 14 ||
      len < 14 + total_len) {
    return false;
  }
  const uint8_t *udp = ip + ihl;
  uint32_t udp_len = net_get_be16(udp + 4);
  if (udp_len < 8 + DNS_HEADER_LEN || ihl + udp_len > total_len ||
      net_get_be16(udp + 2) != DNS_SERVER_PORT) {
    return false;
  }

  const uint8_t *dns = udp + 8;
  uint32_t dns_len = udp_len - 8;
  uint32_t question_end = 0;
  if ((net_get_be16(dns + 2) & 0x8000u) != 0 ||
      !dns_query_is_nemu_local_a(dns, dns_len, &question_end)) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_FRAME_MAX] = {};
  uint32_t answer_len = 2 + 2 + 2 + 4 + 2 + sizeof(virtio_net_host_ip);
  uint32_t reply_dns_len = question_end + answer_len;
  uint32_t reply_udp_len = 8 + reply_dns_len;
  uint32_t reply_total_len = 20 + reply_udp_len;
  if (14 + reply_total_len > VIRTIO_NET_FRAME_MAX) {
    return false;
  }

  memcpy(reply, frame + 6, 6);
  memcpy(reply + 6, virtio_net_host_mac, 6);
  net_put_be16(reply + 12, ETH_P_IP);

  uint8_t *reply_ip = reply + 14;
  reply_ip[0] = 0x45;
  reply_ip[8] = 64;
  reply_ip[9] = IPPROTO_UDP;
  net_put_be16(reply_ip + 2, reply_total_len);
  memcpy(reply_ip + 12, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memcpy(reply_ip + 16, ip + 12, 4);
  net_put_be16(reply_ip + 10, net_checksum(reply_ip, 20));

  uint8_t *reply_udp = reply_ip + 20;
  net_put_be16(reply_udp, DNS_SERVER_PORT);
  net_put_be16(reply_udp + 2, net_get_be16(udp));
  net_put_be16(reply_udp + 4, reply_udp_len);
  net_put_be16(reply_udp + 6, 0);

  uint8_t *reply_dns = reply_udp + 8;
  memcpy(reply_dns, dns, question_end);
  net_put_be16(reply_dns + 2, 0x8180u);
  net_put_be16(reply_dns + 6, 1);
  net_put_be16(reply_dns + 8, 0);
  net_put_be16(reply_dns + 10, 0);

  uint8_t *answer = reply_dns + question_end;
  net_put_be16(answer, 0xc00cu);
  net_put_be16(answer + 2, DNS_QTYPE_A);
  net_put_be16(answer + 4, DNS_QCLASS_IN);
  net_put_be32(answer + 6, DNS_TTL_SECONDS);
  net_put_be16(answer + 10, sizeof(virtio_net_host_ip));
  memcpy(answer + 12, virtio_net_host_ip, sizeof(virtio_net_host_ip));

  uint32_t reply_len = 14 + reply_total_len;
  if (reply_len < VIRTIO_NET_ETH_MIN_FRAME) {
    reply_len = VIRTIO_NET_ETH_MIN_FRAME;
  }
  return virtio_net_enqueue_rx_frame(reply, reply_len);
}

static uint32_t virtio_net_tcp_server_seq(const uint8_t *client_ip,
    uint16_t client_port) {
  return 0x4e455455u ^ net_get_be32(client_ip) ^
    ((uint32_t)client_port << 16) ^ client_port;
}

static bool virtio_net_send_tcp_reply(const uint8_t *frame, const uint8_t *ip,
    const uint8_t *tcp, uint8_t flags, uint32_t seq, uint32_t ack,
    const uint8_t *payload, uint32_t payload_len) {
  uint32_t reply_tcp_len = 20 + payload_len;
  uint32_t reply_total_len = 20 + reply_tcp_len;
  if (14 + reply_total_len > VIRTIO_NET_FRAME_MAX) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_FRAME_MAX] = {};
  memcpy(reply, frame + 6, 6);
  memcpy(reply + 6, virtio_net_host_mac, 6);
  net_put_be16(reply + 12, ETH_P_IP);

  uint8_t *reply_ip = reply + 14;
  reply_ip[0] = 0x45;
  reply_ip[8] = 64;
  reply_ip[9] = IPPROTO_TCP;
  net_put_be16(reply_ip + 2, reply_total_len);
  memcpy(reply_ip + 12, virtio_net_host_ip, sizeof(virtio_net_host_ip));
  memcpy(reply_ip + 16, ip + 12, 4);
  net_put_be16(reply_ip + 10, net_checksum(reply_ip, 20));

  uint8_t *reply_tcp = reply_ip + 20;
  net_put_be16(reply_tcp, TCP_HTTP_PORT);
  net_put_be16(reply_tcp + 2, net_get_be16(tcp));
  net_put_be32(reply_tcp + 4, seq);
  net_put_be32(reply_tcp + 8, ack);
  reply_tcp[12] = 5u << 4;
  reply_tcp[13] = flags;
  net_put_be16(reply_tcp + 14, TCP_WINDOW_SIZE);
  if (payload_len != 0) {
    memcpy(reply_tcp + 20, payload, payload_len);
  }
  net_put_be16(reply_tcp + 16,
      tcp_checksum_ipv4(reply_ip + 12, reply_ip + 16, reply_tcp, reply_tcp_len));

  uint32_t reply_len = 14 + reply_total_len;
  if (reply_len < VIRTIO_NET_ETH_MIN_FRAME) {
    reply_len = VIRTIO_NET_ETH_MIN_FRAME;
  }
  return virtio_net_enqueue_rx_frame(reply, reply_len);
}

static bool virtio_net_handle_tcp_http(const uint8_t *frame, uint32_t len) {
  static const uint8_t http_response[] =
    "HTTP/1.0 204 No Content\r\n"
    "Content-Length: 0\r\n"
    "Connection: close\r\n"
    "\r\n";
  static const char http_get_prefix[] = "GET /nemu-health ";

  if (len < 14 + 20 + 20 || net_get_be16(frame + 12) != ETH_P_IP) {
    return false;
  }
  const uint8_t *ip = frame + 14;
  uint32_t ihl = (ip[0] & 0x0fu) * 4u;
  if ((ip[0] >> 4) != 4 || ihl < 20 || ip[9] != IPPROTO_TCP ||
      memcmp(ip + 16, virtio_net_host_ip, sizeof(virtio_net_host_ip)) != 0) {
    return false;
  }

  uint32_t total_len = net_get_be16(ip + 2);
  if (total_len < ihl + 20 || total_len > VIRTIO_NET_FRAME_MAX - 14 ||
      len < 14 + total_len) {
    return false;
  }
  const uint8_t *tcp = ip + ihl;
  uint32_t tcp_len = total_len - ihl;
  uint32_t tcp_hdr_len = (tcp[12] >> 4) * 4u;
  if (tcp_hdr_len < 20 || tcp_hdr_len > tcp_len ||
      net_get_be16(tcp + 2) != TCP_HTTP_PORT) {
    return false;
  }

  uint16_t client_port = net_get_be16(tcp);
  uint32_t client_seq = net_get_be32(tcp + 4);
  uint32_t client_ack = net_get_be32(tcp + 8);
  uint8_t flags = tcp[13];
  const uint8_t *payload = tcp + tcp_hdr_len;
  uint32_t payload_len = tcp_len - tcp_hdr_len;
  uint32_t server_base_seq = virtio_net_tcp_server_seq(ip + 12, client_port);

  if ((flags & TCP_FLAG_RST) != 0) {
    return true;
  }
  if ((flags & TCP_FLAG_SYN) != 0) {
    return virtio_net_send_tcp_reply(frame, ip, tcp,
        TCP_FLAG_SYN | TCP_FLAG_ACK, server_base_seq, client_seq + 1, NULL, 0);
  }
  if ((flags & TCP_FLAG_FIN) != 0) {
    uint32_t seq = (flags & TCP_FLAG_ACK) != 0 ? client_ack : server_base_seq + 1;
    return virtio_net_send_tcp_reply(frame, ip, tcp, TCP_FLAG_ACK,
        seq, client_seq + payload_len + 1, NULL, 0);
  }
  if (payload_len == 0) {
    return (flags & TCP_FLAG_ACK) != 0;
  }
  if (payload_len < sizeof(http_get_prefix) - 1 ||
      memcmp(payload, http_get_prefix, sizeof(http_get_prefix) - 1) != 0) {
    return false;
  }

  // 这是 hostless TCP 可用性探针，不是通用 HTTP server；只回复固定健康检查。
  uint32_t seq = (flags & TCP_FLAG_ACK) != 0 ? client_ack : server_base_seq + 1;
  return virtio_net_send_tcp_reply(frame, ip, tcp,
      TCP_FLAG_PSH | TCP_FLAG_ACK | TCP_FLAG_FIN,
      seq, client_seq + payload_len, http_response, sizeof(http_response) - 1);
}

static void virtio_net_handle_frame(const uint8_t *frame, uint32_t len) {
  if (len < 14) return;
  uint16_t eth_type = net_get_be16(frame + 12);
  if (eth_type == ETH_P_ARP) {
    virtio_net_handle_arp(frame, len);
  } else if (eth_type == ETH_P_IP) {
    if (!virtio_net_handle_icmp(frame, len) &&
        !virtio_net_handle_dhcp(frame, len) &&
        !virtio_net_handle_dns(frame, len)) {
      virtio_net_handle_tcp_http(frame, len);
    }
  }
}

static bool virtio_net_frame_type_known(const uint8_t *frame, uint32_t len) {
  if (len < 14) return false;
  uint16_t eth_type = net_get_be16(frame + 12);
  return eth_type == ETH_P_ARP || eth_type == ETH_P_IP;
}

static uint32_t virtio_net_handle_tx_chain(VirtqState *q, uint16_t head) {
  VirtqDesc descs[VIRTIO_NET_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(q, head, descs, &count) || count == 0) {
    return 0;
  }
  uint32_t total = 0;
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      return 0;
    }
    total += descs[i].len;
  }
  if (total < VIRTIO_NET_HDR_MIN_LEN) {
    return 0;
  }
  uint32_t hdr_len = VIRTIO_NET_HDR_MIN_LEN;
  uint32_t frame_len = total - hdr_len;
  if (frame_len > VIRTIO_NET_FRAME_MAX) {
    return 0;
  }

  uint8_t frame[VIRTIO_NET_FRAME_MAX];
  bool copied = virtq_copy_from_readable_chain(descs, count, hdr_len, frame, frame_len);
  if (copied && !virtio_net_frame_type_known(frame, frame_len) &&
      total >= VIRTIO_NET_HDR_MRG_LEN + 14) {
    hdr_len = VIRTIO_NET_HDR_MRG_LEN;
    frame_len = total - hdr_len;
    if (frame_len <= VIRTIO_NET_FRAME_MAX) {
      copied = virtq_copy_from_readable_chain(descs, count, hdr_len, frame, frame_len);
    }
  }
  if (copied) {
    virtio_net_handle_frame(frame, frame_len);
  }
  // TX 描述符仍按 virtio-net 语义完成；只有 responder 识别的包会生成 RX reply。
  return 0;
}

static void virtio_net_process_tx_queue(void) {
  VirtqState *q = &queues[VIRTIO_NET_QUEUE_TX];
  if (!q->ready || q->num == 0 || q->desc == 0 || q->driver == 0 || q->device == 0) {
    return;
  }
  uint16_t avail_idx = guest_read16(q->driver + 2);
  uint16_t old_used_idx = guest_read16(q->device + 2);
  uint16_t used_idx = old_used_idx;
  bool used_any = false;
  while (q->last_avail_idx != avail_idx) {
    uint16_t ring_off = q->last_avail_idx % q->num;
    uint16_t head = guest_read16(q->driver + 4 + ring_off * 2);
    uint32_t used_len = virtio_net_handle_tx_chain(q, head);
    virtq_push_used(q, head, used_len, &used_idx);
    q->last_avail_idx++;
    used_any = true;
  }
  virtq_set_avail_event(q, q->last_avail_idx);
  if (used_any) virtq_maybe_interrupt(q, old_used_idx, used_idx);
}

static void virtio_net_try_deliver_rx_queue(void) {
  VirtqState *q = &queues[VIRTIO_NET_QUEUE_RX];
  if (rx_pending_count == 0 ||
      !q->ready || q->num == 0 || q->desc == 0 || q->driver == 0 || q->device == 0) {
    return;
  }

  uint16_t avail_idx = guest_read16(q->driver + 2);
  uint16_t old_used_idx = guest_read16(q->device + 2);
  uint16_t used_idx = old_used_idx;
  bool used_any = false;
  while (rx_pending_count != 0 && q->last_avail_idx != avail_idx) {
    uint16_t ring_off = q->last_avail_idx % q->num;
    uint16_t head = guest_read16(q->driver + 4 + ring_off * 2);
    VirtqDesc descs[VIRTIO_NET_MAX_CHAIN];
    int count = 0;
    uint32_t used_len = 0;
    bool ok = virtq_collect_chain(q, head, descs, &count) &&
      virtq_write_to_writable_chain(descs, count, rx_pending[rx_pending_head].data,
          rx_pending[rx_pending_head].len, &used_len);
    if (ok) {
      rx_pending_head = (rx_pending_head + 1) % VIRTIO_NET_RX_PENDING_CAP;
      rx_pending_count--;
    } else {
      Log("virtio-net: drop responder frame, invalid rx buffer head=%u", head);
    }
    virtq_push_used(q, head, used_len, &used_idx);
    q->last_avail_idx++;
    used_any = true;
  }
  virtq_set_avail_event(q, q->last_avail_idx);
  if (used_any) {
    virtq_maybe_interrupt(q, old_used_idx, used_idx);
  }
}

static void virtio_net_reset(void) {
  memset(driver_features, 0, sizeof(driver_features));
  memset(queues, 0, sizeof(queues));
  memset(rx_pending, 0, sizeof(rx_pending));
  rx_pending_head = 0;
  rx_pending_tail = 0;
  rx_pending_count = 0;
  device_features_sel = 0;
  driver_features_sel = 0;
  interrupt_status = 0;
  device_status = 0;
  queue_sel = 0;
  virtio_net_raise_irq();
}

static VirtqState *selected_queue(void) {
  return queue_sel < VIRTIO_NET_QUEUE_COUNT ? &queues[queue_sel] : NULL;
}

static uint32_t virtio_net_read_reg(uint32_t offset) {
  VirtqState *q = selected_queue();
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return 0x74726976u;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_2;
    case VIRTIO_MMIO_DEVICE_ID: return VIRTIO_NET_DEVICE_ID;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES: return virtio_net_device_features(device_features_sel);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL: return device_features_sel;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL: return driver_features_sel;
    case VIRTIO_MMIO_QUEUE_SEL: return queue_sel;
    case VIRTIO_MMIO_QUEUE_NUM_MAX:
      return queue_sel < VIRTIO_NET_QUEUE_COUNT ? VIRTIO_NET_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return q != NULL ? q->num : 0;
    case VIRTIO_MMIO_QUEUE_READY: return q != NULL && q->ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS: return interrupt_status;
    case VIRTIO_MMIO_STATUS: return device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW: return q != NULL ? (uint32_t)q->desc : 0;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH: return q != NULL ? (uint32_t)((uint64_t)q->desc >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW: return q != NULL ? (uint32_t)q->driver : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH: return q != NULL ? (uint32_t)((uint64_t)q->driver >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW: return q != NULL ? (uint32_t)q->device : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH: return q != NULL ? (uint32_t)((uint64_t)q->device >> 32) : 0;
    case VIRTIO_MMIO_CONFIG_GENERATION: return 0;
    default: return 0;
  }
}

static uint8_t virtio_net_config_byte(uint32_t config_off) {
  if (config_off < 6) return virtio_net_mac[config_off];
  if (config_off == 6) return VIRTIO_NET_S_LINK_UP & 0xffu;
  if (config_off == 7) return (VIRTIO_NET_S_LINK_UP >> 8) & 0xffu;
  return 0;
}

static void virtio_net_read_config(uint32_t offset, int len) {
  uint32_t config_off = offset - VIRTIO_MMIO_CONFIG;
  for (int i = 0; i < len; i++) {
    host_write(net_base + offset + i, 1, virtio_net_config_byte(config_off + i));
  }
}

static void virtio_net_write_reg(uint32_t offset, uint32_t value) {
  VirtqState *q = selected_queue();
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
    case VIRTIO_MMIO_QUEUE_SEL:
      queue_sel = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (q != NULL) {
        if (value <= VIRTIO_NET_QUEUE_SIZE) {
          q->num = value;
        } else {
          Log("virtio-net: reject unsupported QueueNum q=%u num=%u max=%u",
              queue_sel, value, VIRTIO_NET_QUEUE_SIZE);
          q->num = 0;
          q->ready = false;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (q != NULL) {
        if ((value & 1u) == 0) {
          q->ready = false;
          q->last_avail_idx = 0;
        } else if (virtq_validate_queue_layout(q)) {
          q->ready = true;
          q->last_avail_idx = guest_read16(q->driver + 2);
          virtq_set_avail_event(q, q->last_avail_idx);
          if (queue_sel == VIRTIO_NET_QUEUE_RX) {
            virtio_net_try_deliver_rx_queue();
          }
        } else {
          q->ready = false;
          q->last_avail_idx = 0;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      if (value == VIRTIO_NET_QUEUE_TX) {
        virtio_net_process_tx_queue();
      } else if (value == VIRTIO_NET_QUEUE_RX) {
        virtio_net_try_deliver_rx_queue();
      }
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      interrupt_status &= ~value;
      virtio_net_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_net_reset();
      } else {
        device_status = value;
        if ((value & VIRTIO_STATUS_FEATURES_OK) &&
            !virtio_net_driver_features_supported()) {
          device_status &= ~VIRTIO_STATUS_FEATURES_OK;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      if (q != NULL) q->desc = (q->desc & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      if (q != NULL) q->desc = ((uint64_t)value << 32) | (uint32_t)q->desc;
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      if (q != NULL) q->driver = (q->driver & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      if (q != NULL) q->driver = ((uint64_t)value << 32) | (uint32_t)q->driver;
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      if (q != NULL) q->device = (q->device & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      if (q != NULL) q->device = ((uint64_t)value << 32) | (uint32_t)q->device;
      break;
    default:
      break;
  }
}

static void virtio_net_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4 || len == 8);
  if (is_write) {
    if (offset >= VIRTIO_MMIO_CONFIG) return;
    if (len == 1 || len == 2 || len == 4) {
      virtio_net_write_reg(offset, host_read(net_base + offset, len));
    } else if (len == 8) {
      virtio_net_write_reg(offset, host_read(net_base + offset, 4));
      virtio_net_write_reg(offset + 4, host_read(net_base + offset + 4, 4));
    }
    return;
  }

  if (offset >= VIRTIO_MMIO_CONFIG) {
    virtio_net_read_config(offset, len);
  } else if (len == 8) {
    host_write(net_base + offset, 4, virtio_net_read_reg(offset));
    host_write(net_base + offset + 4, 4, virtio_net_read_reg(offset + 4));
  } else {
    host_write(net_base + offset, len, virtio_net_read_reg(offset));
  }
}

void init_virtio_net() {
  net_base = new_space(0x1000);
  virtio_net_reset();
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("virtio-net", CONFIG_VIRTIO_NET_MMIO, net_base, 0x1000,
      virtio_net_io_handler);
#else
  add_mmio_map("virtio-net", CONFIG_VIRTIO_NET_MMIO, net_base, 0x1000,
      virtio_net_io_handler);
#endif
}
