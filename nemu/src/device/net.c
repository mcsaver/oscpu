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
#include <stdio.h>
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
#define VIRTIO_MMIO_INT_CONFIG_CHANGE 0x2u
#define VIRTIO_NET_F_MTU 3
#define VIRTIO_NET_F_MAC 5
#define VIRTIO_NET_F_MRG_RXBUF 15
#define VIRTIO_NET_F_STATUS 16
#define VIRTIO_NET_F_CTRL_VQ 17
#define VIRTIO_NET_F_CTRL_RX 18
#define VIRTIO_NET_F_CTRL_VLAN 19
#define VIRTIO_NET_F_CTRL_RX_EXTRA 20
#define VIRTIO_NET_F_GUEST_ANNOUNCE 21
#define VIRTIO_NET_F_CTRL_MAC_ADDR 23
#define VIRTIO_NET_F_SPEED_DUPLEX 63
#define VIRTIO_NET_S_LINK_UP 1u
#define VIRTIO_NET_S_ANNOUNCE 2u
#define VIRTIO_NET_MTU 1500u
#define VIRTIO_NET_LINK_SPEED_MBIT 1000u
#define VIRTIO_NET_LINK_DUPLEX_FULL 1u
#define VIRTIO_NET_CTRL_ACK_OK 0u
#define VIRTIO_NET_CTRL_ACK_ERR 1u
#define VIRTIO_NET_CTRL_RX 0u
#define VIRTIO_NET_CTRL_RX_PROMISC 0u
#define VIRTIO_NET_CTRL_RX_ALLMULTI 1u
#define VIRTIO_NET_CTRL_RX_ALLUNI 2u
#define VIRTIO_NET_CTRL_RX_NOMULTI 3u
#define VIRTIO_NET_CTRL_RX_NOUNI 4u
#define VIRTIO_NET_CTRL_RX_NOBCAST 5u
#define VIRTIO_NET_CTRL_MAC 1u
#define VIRTIO_NET_CTRL_MAC_TABLE_SET 0u
#define VIRTIO_NET_CTRL_MAC_ADDR_SET 1u
#define VIRTIO_NET_CTRL_VLAN 2u
#define VIRTIO_NET_CTRL_VLAN_ADD 0u
#define VIRTIO_NET_CTRL_VLAN_DEL 1u
#define VIRTIO_NET_CTRL_ANNOUNCE 3u
#define VIRTIO_NET_CTRL_ANNOUNCE_ACK 0u
#define VRING_AVAIL_F_NO_INTERRUPT 0x1u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VIRTIO_STATUS_DRIVER_OK 0x04u
#define VIRTQ_DESC_F_NEXT  0x1u
#define VIRTQ_DESC_F_WRITE 0x2u
#define VIRTQ_DESC_F_INDIRECT 0x4u

#define VIRTIO_NET_QUEUE_RX 0u
#define VIRTIO_NET_QUEUE_TX 1u
#define VIRTIO_NET_QUEUE_CTRL 2u
#define VIRTIO_NET_QUEUE_COUNT 3u
#define VIRTIO_NET_QUEUE_SIZE 64u
#define VIRTIO_NET_MAX_CHAIN 128u
#define VIRTIO_NET_IRQ 5u
#define VIRTIO_NET_CONFIG_BYTES 17u
#define VIRTIO_NET_CONFIG_MTU_OFFSET 10u
#define VIRTIO_NET_CONFIG_SPEED_OFFSET 12u
#define VIRTIO_NET_CONFIG_DUPLEX_OFFSET 16u
#define VIRTIO_NET_HDR_MIN_LEN 10u
#define VIRTIO_NET_HDR_MRG_LEN 12u
#define VIRTIO_NET_RX_HDR_LEN VIRTIO_NET_HDR_MRG_LEN
#define VIRTIO_NET_ETH_MIN_FRAME 60u
#define VIRTIO_NET_FRAME_MAX 1514u
#define VIRTIO_NET_RX_PENDING_CAP 8u
#define VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX 1200u
#define VIRTIO_NET_VLAN_COUNT 4096u

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

typedef struct {
  uint64_t tx_packets;
  uint64_t tx_bytes;
  uint64_t tx_errors;
  uint64_t rx_packets;
  uint64_t rx_bytes;
  uint64_t rx_drops;
  uint64_t arp_requests;
  uint64_t arp_replies;
  uint64_t icmp_echo_requests;
  uint64_t icmp_echo_replies;
  uint64_t dhcp_requests;
  uint64_t dhcp_replies;
  uint64_t dns_queries;
  uint64_t dns_replies;
  uint64_t tcp_segments;
  uint64_t tcp_replies;
  uint64_t tcp_http_requests;
  uint64_t tcp_http_head_requests;
  uint64_t tcp_http_not_found;
  uint64_t tcp_http_apt_requests;
  uint64_t tcp_http_apt_deb_requests;
  uint64_t tcp_http_large_requests;
  uint64_t tcp_http_segmented_responses;
  uint64_t tcp_http_response_segments;
  uint64_t ctrl_commands;
  uint64_t ctrl_rx_commands;
  uint64_t ctrl_rx_extra_commands;
  uint64_t ctrl_mac_table_commands;
  uint64_t ctrl_mac_addr_commands;
  uint64_t ctrl_vlan_commands;
  uint64_t ctrl_announce_commands;
  uint64_t ctrl_errors;
} VirtioNetStats;

static uint8_t *net_base;
static uint32_t device_features_sel;
static uint32_t driver_features_sel;
static uint32_t driver_features[2];
static uint32_t interrupt_status;
static uint32_t device_status;
static uint32_t queue_sel;
static VirtqState queues[VIRTIO_NET_QUEUE_COUNT];
static const uint8_t virtio_net_default_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};
static uint8_t virtio_net_mac[6];
static const uint8_t virtio_net_host_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x57};
static const uint8_t virtio_net_host_ip[4] = {10, 0, 2, 2};
static const uint8_t virtio_net_guest_ip[4] = {10, 0, 2, 15};
static const uint8_t virtio_net_subnet_mask[4] = {255, 255, 255, 0};
static VirtioNetPacket rx_pending[VIRTIO_NET_RX_PENDING_CAP];
static uint32_t rx_pending_head;
static uint32_t rx_pending_tail;
static uint32_t rx_pending_count;
static bool ctrl_rx_promisc;
static bool ctrl_rx_allmulti;
static bool ctrl_rx_alluni;
static bool ctrl_rx_nomulti;
static bool ctrl_rx_nouni;
static bool ctrl_rx_nobcast;
static bool ctrl_mac_table_set;
static bool ctrl_mac_addr_set;
static uint32_t ctrl_mac_unicast_count;
static uint32_t ctrl_mac_multicast_count;
static bool ctrl_vlan_filter[VIRTIO_NET_VLAN_COUNT];
static uint32_t ctrl_vlan_filter_count;
static bool ctrl_vlan_last_valid;
static uint16_t ctrl_vlan_last_vid;
static uint8_t ctrl_vlan_last_cmd;
static bool ctrl_announce_pending;
static bool ctrl_announce_requested;
static VirtioNetStats net_stats;

static void virtio_net_format_mac(const uint8_t *mac, char *out, size_t out_size) {
  snprintf(out, out_size, "%02x:%02x:%02x:%02x:%02x:%02x",
      mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

static void virtio_net_format_ip(const uint8_t *ip, char *out, size_t out_size) {
  snprintf(out, out_size, "%u.%u.%u.%u", ip[0], ip[1], ip[2], ip[3]);
}

static uint32_t virtio_net_device_features(uint32_t sel) {
  if (sel == 0) {
    return (1u << VIRTIO_NET_F_MTU) |
           (1u << VIRTIO_NET_F_MAC) |
           (1u << VIRTIO_NET_F_MRG_RXBUF) |
           (1u << VIRTIO_NET_F_STATUS) |
           (1u << VIRTIO_NET_F_CTRL_VQ) |
           (1u << VIRTIO_NET_F_CTRL_RX) |
           (1u << VIRTIO_NET_F_CTRL_VLAN) |
           (1u << VIRTIO_NET_F_CTRL_RX_EXTRA) |
           (1u << VIRTIO_NET_F_GUEST_ANNOUNCE) |
           (1u << VIRTIO_NET_F_CTRL_MAC_ADDR) |
           (1u << VIRTIO_RING_F_INDIRECT_DESC) |
           (1u << VIRTIO_RING_F_EVENT_IDX);
  }
  if (sel == 1) {
    return (1u << (VIRTIO_F_VERSION_1 - 32)) |
           (1u << (VIRTIO_NET_F_SPEED_DUPLEX - 32));
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

static bool virtio_net_indirect_desc_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_RING_F_INDIRECT_DESC);
}

static bool virtio_net_ctrl_vq_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_CTRL_VQ);
}

static bool virtio_net_ctrl_rx_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_CTRL_RX);
}

static bool virtio_net_ctrl_rx_extra_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_CTRL_RX_EXTRA);
}

static bool virtio_net_ctrl_vlan_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_CTRL_VLAN);
}

static bool virtio_net_guest_announce_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_GUEST_ANNOUNCE);
}

static bool virtio_net_ctrl_mac_addr_enabled(void) {
  return virtio_net_driver_feature_enabled(VIRTIO_NET_F_CTRL_MAC_ADDR);
}

static const char *virtio_net_json_bool(bool value) {
  return value ? "true" : "false";
}

static void virtio_net_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv, isa_riscv_plic_set_irq(VIRTIO_NET_IRQ, interrupt_status != 0));
}

static uint16_t virtio_net_config_status(void) {
  return VIRTIO_NET_S_LINK_UP | (ctrl_announce_pending ? VIRTIO_NET_S_ANNOUNCE : 0);
}

static void virtio_net_request_guest_announce(void) {
  if (!virtio_net_guest_announce_enabled() || ctrl_announce_requested) return;
  /*
   * GUEST_ANNOUNCE 是 link announce 账本：device 设置 config status 的
   * ANNOUNCE 位并发 config-change IRQ，driver ACK 后清位；不表示 MQ/offload。
   */
  ctrl_announce_pending = true;
  ctrl_announce_requested = true;
  interrupt_status |= VIRTIO_MMIO_INT_CONFIG_CHANGE;
  virtio_net_raise_irq();
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

static bool virtq_readable_chain_len(const VirtqDesc *descs, int count, uint32_t *len) {
  uint32_t total = 0;
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0) continue;
    if (!guest_range_ok(descs[i].addr, descs[i].len) ||
        UINT32_MAX - total < descs[i].len) {
      return false;
    }
    total += descs[i].len;
  }
  *len = total;
  return true;
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
  if (len > VIRTIO_NET_FRAME_MAX) {
    net_stats.rx_drops++;
    return false;
  }
  if (rx_pending_count >= VIRTIO_NET_RX_PENDING_CAP) {
    Log("virtio-net: drop responder frame, pending rx queue full");
    net_stats.rx_drops++;
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
  net_stats.arp_requests++;
  bool queued = virtio_net_enqueue_rx_frame(reply, sizeof(reply));
  if (queued) net_stats.arp_replies++;
  return queued;
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
  net_stats.icmp_echo_requests++;
  bool queued = virtio_net_enqueue_rx_frame(reply, reply_len);
  if (queued) net_stats.icmp_echo_replies++;
  return queued;
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
  net_stats.dhcp_requests++;
  bool queued = virtio_net_enqueue_rx_frame(reply, reply_len);
  if (queued) net_stats.dhcp_replies++;
  return queued;
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
  net_stats.dns_queries++;
  bool queued = virtio_net_enqueue_rx_frame(reply, reply_len);
  if (queued) net_stats.dns_replies++;
  return queued;
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
  bool queued = virtio_net_enqueue_rx_frame(reply, reply_len);
  if (queued) net_stats.tcp_replies++;
  return queued;
}

static bool virtio_net_send_tcp_payload(const uint8_t *frame, const uint8_t *ip,
    const uint8_t *tcp, uint32_t seq, uint32_t ack,
    const uint8_t *payload, uint32_t payload_len) {
  if (payload_len == 0) {
    return virtio_net_send_tcp_reply(frame, ip, tcp,
        TCP_FLAG_PSH | TCP_FLAG_ACK | TCP_FLAG_FIN,
        seq, ack, NULL, 0);
  }

  uint32_t offset = 0;
  uint32_t segments = 0;
  while (offset < payload_len) {
    uint32_t chunk_len = payload_len - offset;
    if (chunk_len > VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX) {
      chunk_len = VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX;
    }
    uint8_t flags = TCP_FLAG_PSH | TCP_FLAG_ACK;
    if (offset + chunk_len == payload_len) {
      flags |= TCP_FLAG_FIN;
    }
    if (!virtio_net_send_tcp_reply(frame, ip, tcp, flags,
          seq + offset, ack, payload + offset, chunk_len)) {
      return false;
    }
    offset += chunk_len;
    segments++;
  }
  if (segments > 1) {
    net_stats.tcp_http_segmented_responses++;
  }
  net_stats.tcp_http_response_segments += segments;
  return true;
}

static bool virtio_net_send_http_response(const uint8_t *frame, const uint8_t *ip,
    const uint8_t *tcp, uint32_t seq, uint32_t ack, const char *status,
    const char *content_type, const uint8_t *body, uint32_t body_len,
    bool include_body) {
  static uint8_t response[8192];
  int header_len;
  if (content_type != NULL) {
    header_len = snprintf((char *)response, sizeof(response),
        "HTTP/1.0 %s\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %u\r\n"
        "Connection: close\r\n"
        "\r\n",
        status, content_type, body_len);
  } else {
    header_len = snprintf((char *)response, sizeof(response),
        "HTTP/1.0 %s\r\n"
        "Content-Length: %u\r\n"
        "Connection: close\r\n"
        "\r\n",
        status, body_len);
  }
  if (header_len < 0 || (uint32_t)header_len >= sizeof(response)) {
    return false;
  }

  uint32_t response_len = (uint32_t)header_len;
  if (include_body && body_len != 0) {
    if (body == NULL || response_len + body_len > sizeof(response)) {
      return false;
    }
    memcpy(response + response_len, body, body_len);
    response_len += body_len;
  }
  return virtio_net_send_tcp_payload(frame, ip, tcp, seq, ack,
      response, response_len);
}

static bool virtio_net_handle_tcp_http(const uint8_t *frame, uint32_t len) {
#define NEMU_HTTP_LARGE_64 \
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ._"
#define NEMU_HTTP_LARGE_256 \
    NEMU_HTTP_LARGE_64 NEMU_HTTP_LARGE_64 NEMU_HTTP_LARGE_64 NEMU_HTTP_LARGE_64
#define NEMU_HTTP_LARGE_1024 \
    NEMU_HTTP_LARGE_256 NEMU_HTTP_LARGE_256 NEMU_HTTP_LARGE_256 NEMU_HTTP_LARGE_256
#define NEMU_HTTP_LARGE_4096 \
    NEMU_HTTP_LARGE_1024 NEMU_HTTP_LARGE_1024 NEMU_HTTP_LARGE_1024 NEMU_HTTP_LARGE_1024
  static const uint8_t http_empty_body[] = "";
  static const uint8_t http_not_found_body[] = "not found\n";
  static const uint8_t http_large_body[] = NEMU_HTTP_LARGE_4096;
  static const uint8_t nemu_apt_release[] =
    "Suite: jammy\n"
    "Codename: jammy\n"
    "Components: main\n"
    "Architectures: riscv64\n"
    "Date: Fri, 12 Jun 2026 00:00:00 UTC\n"
    "MD5Sum:\n"
    " 438d0b474f7d0dd6a4eb1258a9803309 1041 main/binary-riscv64/Packages\n"
    " d50ff3b8de523a6d8af6e204dedac9e3 484 main/binary-riscv64/Packages.gz\n"
    "SHA256:\n"
    " 5ab350d54205a6164abb316eca97414ba3596d47e48fb926ced0ad73958bb3e1 1041 main/binary-riscv64/Packages\n"
    " 707ca8cf2ad64e7e26708f3e92ea67c205b3a6f97f3caabbe4aeab56906b9b8c 484 main/binary-riscv64/Packages.gz\n";
  static const uint8_t nemu_apt_packages[] =
    "Package: nemu-hostless-hello\n"
    "Version: 1.0\n"
    "Architecture: riscv64\n"
    "Maintainer: NEMU Hostless Apt <nemu@example.invalid>\n"
    "Installed-Size: 1\n"
    "Filename: pool/main/n/nemu-hostless-hello/nemu-hostless-hello_1.0_riscv64.deb\n"
    "Size: 722\n"
    "MD5sum: 1c2cb7034d8dc6f5d1ef3b5edfa38bd9\n"
    "SHA256: 073216e022c5d7f98d7d07279921a2576920784a0895d870c5f962cb07647187\n"
    "Section: base\n"
    "Priority: optional\n"
    "Description: NEMU hostless apt install smoke package\n"
    " This package proves that NEMU hostless APT can fetch and install a real deb.\n"
    "\n"
    "Package: nemu-hostless-meta\n"
    "Version: 1.0\n"
    "Architecture: riscv64\n"
    "Maintainer: NEMU Hostless Apt <nemu@example.invalid>\n"
    "Depends: nemu-hostless-hello (= 1.0)\n"
    "Installed-Size: 1\n"
    "Filename: pool/main/n/nemu-hostless-meta/nemu-hostless-meta_1.0_riscv64.deb\n"
    "Size: 896\n"
    "MD5sum: 887bf63847b0ea00d1eb86287b3999d9\n"
    "SHA256: b40a91a80a056423051d440ef614d76d36666f88b29ed8a2a86aa76716e3d0e5\n"
    "Section: base\n"
    "Priority: optional\n"
    "Description: NEMU hostless apt dependency smoke package\n"
    " This package depends on nemu-hostless-hello to prove apt dependency install.\n"
    "\n";
  static const uint8_t nemu_apt_packages_gz[] =
    "\037\213\010\000\000\000\000\000\002\003\265\222\115\217\323\060"
    "\020\206\357\376\025\076\302\241\135\307\111\374\121\001\242\122"
    "\101\313\241\250\122\167\271\256\046\366\204\130\353\070\121\354"
    "\126\054\277\036\167\323\135\241\245\160\000\221\050\122\062\032"
    "\075\236\274\363\354\300\334\303\127\134\321\200\375\141\321\015"
    "\061\171\214\161\321\241\367\003\371\202\123\164\103\130\321\142"
    "\311\310\172\062\235\113\150\322\141\312\355\223\213\346\050\052"
    "\262\005\027\122\176\160\132\321\317\037\266\267\364\372\214\240"
    "\353\061\321\067\047\352\173\374\006\375\350\161\351\302\021\274"
    "\263\357\310\247\020\023\170\217\166\261\167\337\063\254\040\037"
    "\235\307\000\175\176\037\207\301\137\365\231\170\225\357\137\147"
    "\272\124\273\313\343\335\235\007\132\132\154\310\114\225\234\223"
    "\355\246\216\207\076\237\140\270\151\044\053\053\253\254\021\155"
    "\155\013\154\313\246\106\333\102\251\032\253\311\376\172\315\153"
    "\261\242\114\226\274\020\310\070\067\265\225\255\126\126\132\046"
    "\271\324\232\027\300\153\051\064\147\122\125\300\224\256\255\222"
    "\314\324\255\026\231\315\244\250\144\241\044\331\347\204\036\063"
    "\153\040\042\331\115\156\230\134\172\130\321\141\074\225\301\223"
    "\015\106\063\271\161\156\172\214\354\351\157\050\344\310\334\234"
    "\015\215\375\160\217\164\234\327\103\350\115\347\342\323\027\035"
    "\247\341\210\221\246\016\322\013\302\172\167\103\015\004\332\142"
    "\062\035\205\140\237\171\100\047\004\117\163\074\113\102\166\227"
    "\267\336\143\202\377\266\364\015\216\030\154\274\150\032\175\365"
    "\366\164\334\353\277\064\343\064\367\205\322\157\274\120\132\074"
    "\173\241\224\154\132\121\252\112\066\014\201\261\354\105\243\004"
    "\317\325\122\153\375\223\027\115\305\100\027\240\030\260\132\124"
    "\274\144\165\141\253\212\141\053\212\312\112\141\113\221\257\126"
    "\251\206\153\264\012\070\050\001\040\205\314\056\225\226\141\375"
    "\317\136\330\307\370\060\230\207\077\252\061\267\105\072\204\213"
    "\071\247\141\226\347\045\362\154\111\126\343\007\376\373\060\051"
    "\021\004\000\000";
  static const uint8_t nemu_apt_hello_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142"
    "\151\156\141\162\171\040\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040"
    "\061\060\060\066\064\064\040\040\064\040\040\040\040\040\040\040"
    "\040\040\140\012\062\056\060\012\143\157\156\164\162\157\154\056"
    "\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040"
    "\061\060\060\066\064\064\040\040\063\062\064\040\040\040\040\040"
    "\040\040\140\012\037\213\010\000\000\000\000\000\002\003\355\321"
    "\337\112\303\060\024\006\360\136\347\051\316\013\254\153\267\266"
    "\203\042\342\100\301\233\311\300\351\175\226\035\155\130\226\224"
    "\044\033\372\366\166\235\023\034\250\127\023\205\357\007\045\177"
    "\232\234\323\362\245\303\344\354\262\316\244\054\373\261\163\072"
    "\366\363\274\034\345\243\252\250\016\373\223\111\126\046\124\046"
    "\277\140\033\242\364\104\211\167\056\176\167\356\247\367\377\124"
    "\072\124\316\106\357\314\231\363\257\212\342\313\374\213\161\376"
    "\071\377\074\037\147\125\102\031\362\077\273\271\124\153\371\314"
    "\065\131\336\154\007\215\013\321\160\010\203\206\215\161\342\221"
    "\175\320\316\326\224\247\231\270\147\025\373\305\122\006\026\163"
    "\257\235\327\361\265\046\327\356\267\245\021\123\257\032\035\273"
    "\123\133\337\325\363\072\250\135\125\210\231\324\066\166\017\373"
    "\232\356\156\146\017\164\373\336\203\246\155\244\213\175\333\053"
    "\176\221\233\326\160\252\355\116\032\275\272\024\327\034\224\327"
    "\355\241\137\177\353\370\145\044\273\133\332\166\241\031\103\141"
    "\343\326\114\355\341\027\004\055\032\035\216\053\152\275\333\161"
    "\240\330\310\170\122\141\072\137\220\222\226\236\070\252\206\244"
    "\135\175\324\223\344\131\032\132\361\062\025\011\000\000\000\000"
    "\000\000\000\000\000\000\000\000\000\000\000\000\300\337\367\006"
    "\077\031\213\103\000\050\000\000\144\141\164\141\056\164\141\162"
    "\056\147\172\040\040\040\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040"
    "\061\060\060\066\064\064\040\040\062\060\066\040\040\040\040\040"
    "\040\040\140\012\037\213\010\000\000\000\000\000\002\003\355\321"
    "\061\216\302\060\020\100\121\327\234\302\027\000\333\331\214\175"
    "\202\055\227\216\003\244\360\222\042\301\053\073\271\377\106\101"
    "\064\110\100\201\010\101\372\257\231\321\330\335\337\031\365\162"
    "\166\022\104\346\071\271\236\363\356\244\162\225\257\375\371\036"
    "\202\025\245\105\055\140\054\103\223\265\126\071\245\341\336\277"
    "\107\357\037\152\147\306\222\315\312\372\073\053\316\323\177\271"
    "\376\245\155\162\064\353\351\357\174\145\351\277\164\377\123\354"
    "\307\155\233\312\320\305\122\266\155\354\272\144\336\323\137\244"
    "\012\364\137\103\377\176\132\233\143\174\272\277\257\353\333\375"
    "\277\344\252\177\260\241\126\332\322\377\345\346\312\372\067\247"
    "\136\357\277\177\016\372\222\137\067\177\303\106\001\000\000\000"
    "\000\000\000\000\000\000\000\076\305\077\361\310\071\170\000\050"
    "\000\000";
  static const uint8_t nemu_apt_meta_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142"
    "\151\156\141\162\171\040\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040"
    "\061\060\060\066\064\064\040\040\064\040\040\040\040\040\040\040"
    "\040\040\140\012\062\056\060\012\143\157\156\164\162\157\154\056"
    "\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040"
    "\061\060\060\066\064\064\040\040\064\071\067\040\040\040\040\040"
    "\040\040\140\012\037\213\010\000\000\000\000\000\002\003\355\227"
    "\317\153\333\060\024\200\175\326\137\361\226\061\350\016\361\257"
    "\332\016\204\255\254\260\301\056\035\205\255\073\355\242\070\352"
    "\054\042\113\342\111\011\353\177\077\071\156\172\360\272\256\254"
    "\070\301\360\076\060\266\354\347\047\011\351\223\354\070\211\106"
    "\047\015\054\312\162\177\016\014\317\373\353\254\314\263\274\052"
    "\252\376\376\142\221\226\021\224\321\021\330\072\317\021\040\102"
    "\143\374\123\161\377\172\076\121\342\244\066\332\243\121\043\217"
    "\177\125\024\177\035\377\162\070\376\131\166\236\236\107\220\322"
    "\370\217\316\065\257\067\374\247\130\202\026\355\166\336\030\347"
    "\225\160\156\336\012\317\331\167\201\116\032\275\204\054\116\331"
    "\127\121\373\175\141\305\235\140\327\050\015\112\177\267\004\143"
    "\273\333\134\261\113\254\033\351\103\324\026\103\072\224\256\336"
    "\125\005\273\342\122\373\160\010\134\302\227\117\127\067\360\371"
    "\276\012\270\264\036\336\165\265\176\020\277\170\153\225\210\245"
    "\336\161\045\327\027\354\243\260\102\257\335\260\121\215\120\312"
    "\300\331\373\256\075\157\103\220\253\121\332\276\121\373\324\207"
    "\100\340\041\365\172\237\103\350\372\016\134\153\066\002\154\337"
    "\123\006\337\032\351\016\245\373\060\007\106\077\132\231\067\140"
    "\321\354\304\060\245\324\141\332\050\025\263\351\373\157\103\217"
    "\273\356\234\156\375\317\363\152\350\177\231\125\344\377\061\170"
    "\375\052\131\111\235\270\206\071\341\141\056\130\273\131\113\204"
    "\271\205\144\307\061\121\162\225\074\262\062\130\014\126\337\302"
    "\354\215\373\241\147\060\073\114\041\270\105\323\016\134\354\342"
    "\147\160\361\124\272\207\051\030\112\316\165\216\106\304\121\375"
    "\307\366\224\337\177\171\236\017\375\317\112\332\377\247\345\077"
    "\266\057\261\037\133\162\377\124\376\243\030\167\373\177\206\377"
    "\305\037\337\377\131\111\376\117\307\377\176\012\375\367\002\320"
    "\277\116\053\300\251\374\037\167\373\177\206\377\303\377\377\020"
    "\236\223\377\123\362\377\005\333\177\367\062\271\117\020\004\101"
    "\020\004\101\020\004\101\020\004\101\020\043\360\033\016\262\071"
    "\070\000\050\000\000\012\144\141\164\141\056\164\141\162\056\147"
    "\172\040\040\040\040\040\061\067\070\061\062\062\062\064\060\060"
    "\040\040\060\040\040\040\040\040\060\040\040\040\040\040\061\060"
    "\060\066\064\064\040\040\062\060\065\040\040\040\040\040\040\040"
    "\140\012\037\213\010\000\000\000\000\000\002\003\355\323\061\016"
    "\202\060\024\200\341\316\236\242\027\200\266\110\313\011\034\165"
    "\363\000\014\125\006\260\111\013\367\027\065\056\044\352\140\104"
    "\110\376\157\171\057\155\267\077\315\225\370\071\075\252\254\275"
    "\317\321\164\336\167\143\013\123\270\322\075\316\253\112\133\041"
    "\255\230\301\220\372\072\112\051\142\010\375\273\167\237\356\127"
    "\052\127\103\212\152\141\375\215\266\306\321\177\276\376\251\251"
    "\243\127\313\351\157\134\241\351\077\167\377\213\357\206\254\011"
    "\251\157\175\112\131\347\373\132\375\251\277\335\332\202\376\013"
    "\350\337\215\133\175\366\337\367\167\145\371\272\377\326\115\372"
    "\273\352\366\377\065\375\177\256\361\155\033\344\051\206\116\036"
    "\166\373\243\174\346\227\267\374\033\001\000\000\000\000\000\000"
    "\000\000\000\000\130\211\053\152\376\201\261\000\050\000\000\012";
  static const char http_get_prefix[] = "GET ";
  static const char http_head_prefix[] = "HEAD ";
  static const char http_health_path[] = "/nemu-health";
  static const char http_large_path[] = "/nemu-large";
  static const char http_apt_release_path[] = "/ubuntu/dists/jammy/Release";
  static const char http_apt_packages_path[] =
    "/ubuntu/dists/jammy/main/binary-riscv64/Packages";
  static const char http_apt_packages_gz_path[] =
    "/ubuntu/dists/jammy/main/binary-riscv64/Packages.gz";
  static const char http_apt_hello_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-hello/"
    "nemu-hostless-hello_1.0_riscv64.deb";
  static const char http_apt_meta_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-meta/"
    "nemu-hostless-meta_1.0_riscv64.deb";

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
  net_stats.tcp_segments++;

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

  bool is_head = false;
  uint32_t path_off = 0;
  if (payload_len >= sizeof(http_get_prefix) - 1 &&
      memcmp(payload, http_get_prefix, sizeof(http_get_prefix) - 1) == 0) {
    path_off = sizeof(http_get_prefix) - 1;
  } else if (payload_len >= sizeof(http_head_prefix) - 1 &&
      memcmp(payload, http_head_prefix, sizeof(http_head_prefix) - 1) == 0) {
    path_off = sizeof(http_head_prefix) - 1;
    is_head = true;
  } else {
    return false;
  }

  uint32_t path_len = 0;
  while (path_off + path_len < payload_len && payload[path_off + path_len] != ' ') {
    path_len++;
  }
  if (path_off + path_len >= payload_len) {
    return false;
  }

  bool is_health = path_len == sizeof(http_health_path) - 1 &&
    memcmp(payload + path_off, http_health_path, sizeof(http_health_path) - 1) == 0;
  bool is_large = path_len == sizeof(http_large_path) - 1 &&
    memcmp(payload + path_off, http_large_path, sizeof(http_large_path) - 1) == 0;
  bool is_apt_release = path_len == sizeof(http_apt_release_path) - 1 &&
    memcmp(payload + path_off, http_apt_release_path, sizeof(http_apt_release_path) - 1) == 0;
  bool is_apt_packages = path_len == sizeof(http_apt_packages_path) - 1 &&
    memcmp(payload + path_off, http_apt_packages_path, sizeof(http_apt_packages_path) - 1) == 0;
  bool is_apt_packages_gz = path_len == sizeof(http_apt_packages_gz_path) - 1 &&
    memcmp(payload + path_off, http_apt_packages_gz_path,
        sizeof(http_apt_packages_gz_path) - 1) == 0;
  bool is_apt_hello_deb = path_len == sizeof(http_apt_hello_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_hello_deb_path,
        sizeof(http_apt_hello_deb_path) - 1) == 0;
  bool is_apt_meta_deb = path_len == sizeof(http_apt_meta_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_meta_deb_path,
        sizeof(http_apt_meta_deb_path) - 1) == 0;
  bool is_known_path = is_health || is_large || is_apt_release || is_apt_packages ||
    is_apt_packages_gz || is_apt_hello_deb || is_apt_meta_deb;

  // 这是 hostless TCP 探针，不是通用 HTTP server；只覆盖健康检查、
  // 多段响应、最小 APT 元数据/包下载和 404 错误路径，避免把它误称为
  // TAP/NAT/外网能力。
  net_stats.tcp_http_requests++;
  if (is_head) {
    net_stats.tcp_http_head_requests++;
  }
  if (is_apt_release || is_apt_packages || is_apt_packages_gz ||
      is_apt_hello_deb || is_apt_meta_deb) {
    net_stats.tcp_http_apt_requests++;
  }
  if (is_apt_hello_deb || is_apt_meta_deb) {
    net_stats.tcp_http_apt_deb_requests++;
  }
  if (is_large) {
    net_stats.tcp_http_large_requests++;
  }
  if (!is_known_path) {
    net_stats.tcp_http_not_found++;
  }
  uint32_t seq = (flags & TCP_FLAG_ACK) != 0 ? client_ack : server_base_seq + 1;
  const char *status = "404 Not Found";
  const char *content_type = NULL;
  const uint8_t *body = http_not_found_body;
  uint32_t body_len = sizeof(http_not_found_body) - 1;
  if (is_health) {
    status = "204 No Content";
    body = http_empty_body;
    body_len = 0;
  } else if (is_large) {
    status = "200 OK";
    content_type = "application/octet-stream";
    body = http_large_body;
    body_len = sizeof(http_large_body) - 1;
  } else if (is_apt_release) {
    status = "200 OK";
    content_type = "text/plain";
    body = nemu_apt_release;
    body_len = sizeof(nemu_apt_release) - 1;
  } else if (is_apt_packages) {
    status = "200 OK";
    content_type = "text/plain";
    body = nemu_apt_packages;
    body_len = sizeof(nemu_apt_packages) - 1;
  } else if (is_apt_packages_gz) {
    status = "200 OK";
    content_type = "application/gzip";
    body = nemu_apt_packages_gz;
    body_len = sizeof(nemu_apt_packages_gz) - 1;
  } else if (is_apt_hello_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_hello_deb;
    body_len = sizeof(nemu_apt_hello_deb) - 1;
  } else if (is_apt_meta_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_meta_deb;
    body_len = sizeof(nemu_apt_meta_deb) - 1;
  }
  return virtio_net_send_http_response(frame, ip, tcp, seq,
      client_seq + payload_len, status, content_type, body, body_len, !is_head);
#undef NEMU_HTTP_LARGE_4096
#undef NEMU_HTTP_LARGE_1024
#undef NEMU_HTTP_LARGE_256
#undef NEMU_HTTP_LARGE_64
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
    net_stats.tx_errors++;
    return 0;
  }
  uint32_t total = 0;
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      net_stats.tx_errors++;
      return 0;
    }
    total += descs[i].len;
  }
  if (total < VIRTIO_NET_HDR_MIN_LEN) {
    net_stats.tx_errors++;
    return 0;
  }
  uint32_t hdr_len = VIRTIO_NET_HDR_MIN_LEN;
  uint32_t frame_len = total - hdr_len;
  if (frame_len > VIRTIO_NET_FRAME_MAX) {
    net_stats.tx_errors++;
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
    net_stats.tx_packets++;
    net_stats.tx_bytes += frame_len;
    virtio_net_handle_frame(frame, frame_len);
  } else {
    net_stats.tx_errors++;
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

static bool virtio_net_write_ctrl_ack(const VirtqDesc *descs, int count, uint8_t ack) {
  for (int i = count - 1; i >= 0; i--) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 &&
        descs[i].len >= 1 && guest_range_ok(descs[i].addr, 1)) {
      paddr_write(descs[i].addr, 1, ack);
      return true;
    }
  }
  return false;
}

static bool virtio_net_read_ctrl_u32(const VirtqDesc *descs, int count,
    uint32_t *offset, uint32_t *value) {
  uint8_t data[4];
  if (!virtq_copy_from_readable_chain(descs, count, *offset, data, sizeof(data))) {
    return false;
  }
  *value = (uint32_t)data[0] |
           ((uint32_t)data[1] << 8) |
           ((uint32_t)data[2] << 16) |
           ((uint32_t)data[3] << 24);
  *offset += sizeof(data);
  return true;
}

static bool virtio_net_parse_ctrl_mac_table(const VirtqDesc *descs, int count,
    uint32_t *unicast_count, uint32_t *multicast_count) {
  uint32_t readable_len = 0;
  uint32_t offset = 2;
  uint32_t uni = 0;
  uint32_t multi = 0;
  if (!virtq_readable_chain_len(descs, count, &readable_len) ||
      !virtio_net_read_ctrl_u32(descs, count, &offset, &uni)) {
    return false;
  }
  if (uni > (UINT32_MAX - offset) / 6u) return false;
  offset += uni * 6u;
  if (!virtio_net_read_ctrl_u32(descs, count, &offset, &multi)) {
    return false;
  }
  if (multi > (UINT32_MAX - offset) / 6u) return false;
  offset += multi * 6u;
  if (offset != readable_len) return false;

  *unicast_count = uni;
  *multicast_count = multi;
  return true;
}

static bool virtio_net_parse_ctrl_mac_addr(const VirtqDesc *descs, int count,
    uint8_t mac[6]) {
  uint32_t readable_len = 0;
  if (!virtq_readable_chain_len(descs, count, &readable_len) ||
      readable_len != sizeof(uint16_t) + 6u) {
    return false;
  }
  return virtq_copy_from_readable_chain(descs, count, sizeof(uint16_t), mac, 6);
}

static bool virtio_net_parse_ctrl_vlan(const VirtqDesc *descs, int count,
    uint16_t *vid) {
  uint8_t data[2];
  uint32_t readable_len = 0;
  if (!virtq_readable_chain_len(descs, count, &readable_len) ||
      readable_len != sizeof(uint16_t) + sizeof(data) ||
      !virtq_copy_from_readable_chain(descs, count, sizeof(uint16_t), data, sizeof(data))) {
    return false;
  }
  uint16_t value = (uint16_t)data[0] | ((uint16_t)data[1] << 8);
  if (value >= VIRTIO_NET_VLAN_COUNT) return false;
  *vid = value;
  return true;
}

static bool virtio_net_parse_ctrl_no_payload(const VirtqDesc *descs, int count) {
  uint32_t readable_len = 0;
  return virtq_readable_chain_len(descs, count, &readable_len) &&
         readable_len == sizeof(uint16_t);
}

static bool virtio_net_ctrl_rx_basic_cmd(uint8_t cmd) {
  return cmd == VIRTIO_NET_CTRL_RX_PROMISC ||
         cmd == VIRTIO_NET_CTRL_RX_ALLMULTI;
}

static bool virtio_net_ctrl_rx_extra_cmd(uint8_t cmd) {
  return cmd == VIRTIO_NET_CTRL_RX_ALLUNI ||
         cmd == VIRTIO_NET_CTRL_RX_NOMULTI ||
         cmd == VIRTIO_NET_CTRL_RX_NOUNI ||
         cmd == VIRTIO_NET_CTRL_RX_NOBCAST;
}

static bool virtio_net_ctrl_vlan_cmd(uint8_t cmd) {
  return cmd == VIRTIO_NET_CTRL_VLAN_ADD ||
         cmd == VIRTIO_NET_CTRL_VLAN_DEL;
}

static uint32_t virtio_net_handle_ctrl_chain(VirtqState *q, uint16_t head) {
  VirtqDesc descs[VIRTIO_NET_MAX_CHAIN];
  int count = 0;
  uint8_t hdr[2] = {};
  if (!virtq_collect_chain(q, head, descs, &count) ||
      !virtq_copy_from_readable_chain(descs, count, 0, hdr, sizeof(hdr))) {
    net_stats.ctrl_errors++;
    return 0;
  }

  net_stats.ctrl_commands++;
  /*
   * CTRL_RX/CTRL_RX_EXTRA 是 Linux 常见控制面命令。hostless responder
   * 当前只记录 RX mode 状态，不把它解释成 TAP/NAT 或完整 filtering；
   * 未声明的 control class/cmd 仍返回 ERR。
   */
  uint8_t ack = VIRTIO_NET_CTRL_ACK_ERR;
  bool supported = false;
  bool next_promisc = ctrl_rx_promisc;
  bool next_allmulti = ctrl_rx_allmulti;
  bool next_alluni = ctrl_rx_alluni;
  bool next_nomulti = ctrl_rx_nomulti;
  bool next_nouni = ctrl_rx_nouni;
  bool next_nobcast = ctrl_rx_nobcast;
  uint8_t next_mac[6];
  uint32_t next_mac_unicast_count = ctrl_mac_unicast_count;
  uint32_t next_mac_multicast_count = ctrl_mac_multicast_count;
  uint16_t next_vlan_vid = 0;
  uint8_t next_vlan_cmd = 0;
  bool update_rx_mode = false;
  bool update_rx_extra_mode = false;
  bool update_mac_table = false;
  bool update_mac_addr = false;
  bool update_vlan = false;
  bool update_announce_ack = false;
  memcpy(next_mac, virtio_net_mac, sizeof(next_mac));

  if (hdr[0] == VIRTIO_NET_CTRL_RX &&
      ((virtio_net_ctrl_rx_enabled() && virtio_net_ctrl_rx_basic_cmd(hdr[1])) ||
       (virtio_net_ctrl_rx_extra_enabled() && virtio_net_ctrl_rx_extra_cmd(hdr[1])))) {
    uint8_t value = 0;
    if (virtq_copy_from_readable_chain(descs, count, sizeof(hdr), &value, sizeof(value))) {
      bool enabled = value != 0;
      switch (hdr[1]) {
        case VIRTIO_NET_CTRL_RX_PROMISC: next_promisc = enabled; break;
        case VIRTIO_NET_CTRL_RX_ALLMULTI: next_allmulti = enabled; break;
        case VIRTIO_NET_CTRL_RX_ALLUNI: next_alluni = enabled; update_rx_extra_mode = true; break;
        case VIRTIO_NET_CTRL_RX_NOMULTI: next_nomulti = enabled; update_rx_extra_mode = true; break;
        case VIRTIO_NET_CTRL_RX_NOUNI: next_nouni = enabled; update_rx_extra_mode = true; break;
        case VIRTIO_NET_CTRL_RX_NOBCAST: next_nobcast = enabled; update_rx_extra_mode = true; break;
        default: break;
      }
      update_rx_mode = true;
      supported = true;
      ack = VIRTIO_NET_CTRL_ACK_OK;
    }
  } else if (hdr[0] == VIRTIO_NET_CTRL_MAC && hdr[1] == VIRTIO_NET_CTRL_MAC_TABLE_SET &&
      virtio_net_ctrl_rx_enabled()) {
    if (virtio_net_parse_ctrl_mac_table(descs, count,
          &next_mac_unicast_count, &next_mac_multicast_count)) {
      /*
       * MAC_TABLE_SET 随 CTRL_RX feature 可用。当前 hostless responder 只把
       * Linux 下发的过滤表记录到账本，不按表丢包，避免伪装成完整过滤后端。
       */
      update_mac_table = true;
      supported = true;
      ack = VIRTIO_NET_CTRL_ACK_OK;
    }
  } else if (hdr[0] == VIRTIO_NET_CTRL_MAC && hdr[1] == VIRTIO_NET_CTRL_MAC_ADDR_SET &&
      virtio_net_ctrl_mac_addr_enabled()) {
    if (virtio_net_parse_ctrl_mac_addr(descs, count, next_mac)) {
      /*
       * CTRL_MAC_ADDR_SET 只改变设备配置区和管理面可见的 MAC 地址；
       * 当前 hostless 后端仍不承诺真实 MAC filter 或 TAP/NAT 语义。
       */
      update_mac_addr = true;
      supported = true;
      ack = VIRTIO_NET_CTRL_ACK_OK;
    }
  } else if (hdr[0] == VIRTIO_NET_CTRL_VLAN && virtio_net_ctrl_vlan_cmd(hdr[1]) &&
      virtio_net_ctrl_vlan_enabled()) {
    if (virtio_net_parse_ctrl_vlan(descs, count, &next_vlan_vid)) {
      /*
       * CTRL_VLAN ADD/DEL 记录 Linux 期望的 VLAN filter 表状态；hostless
       * responder 暂不据此过滤以太帧，避免把账本误说成完整 VLAN 后端。
       */
      next_vlan_cmd = hdr[1];
      update_vlan = true;
      supported = true;
      ack = VIRTIO_NET_CTRL_ACK_OK;
    }
  } else if (hdr[0] == VIRTIO_NET_CTRL_ANNOUNCE && hdr[1] == VIRTIO_NET_CTRL_ANNOUNCE_ACK &&
      virtio_net_guest_announce_enabled()) {
    if (virtio_net_parse_ctrl_no_payload(descs, count)) {
      /*
       * ACK 只确认 guest 已看见 link announce；不在这里伪造真实
       * gratuitous ARP/ND 传播语义，后续 packet backend 再处理。
       */
      update_announce_ack = true;
      supported = true;
      ack = VIRTIO_NET_CTRL_ACK_OK;
    }
  }

  bool is_error = !supported;
  if (!virtio_net_write_ctrl_ack(descs, count, ack)) {
    if (!is_error) net_stats.ctrl_errors++;
    return 0;
  }
  if (is_error) {
    net_stats.ctrl_errors++;
  } else if (update_rx_mode) {
    ctrl_rx_promisc = next_promisc;
    ctrl_rx_allmulti = next_allmulti;
    ctrl_rx_alluni = next_alluni;
    ctrl_rx_nomulti = next_nomulti;
    ctrl_rx_nouni = next_nouni;
    ctrl_rx_nobcast = next_nobcast;
    net_stats.ctrl_rx_commands++;
    if (update_rx_extra_mode) net_stats.ctrl_rx_extra_commands++;
  } else if (update_mac_table) {
    ctrl_mac_table_set = true;
    ctrl_mac_unicast_count = next_mac_unicast_count;
    ctrl_mac_multicast_count = next_mac_multicast_count;
    net_stats.ctrl_mac_table_commands++;
  } else if (update_mac_addr) {
    memcpy(virtio_net_mac, next_mac, sizeof(virtio_net_mac));
    ctrl_mac_addr_set = true;
    net_stats.ctrl_mac_addr_commands++;
  } else if (update_vlan) {
    if (next_vlan_cmd == VIRTIO_NET_CTRL_VLAN_ADD) {
      if (!ctrl_vlan_filter[next_vlan_vid]) {
        ctrl_vlan_filter[next_vlan_vid] = true;
        ctrl_vlan_filter_count++;
      }
    } else {
      if (ctrl_vlan_filter[next_vlan_vid]) {
        ctrl_vlan_filter[next_vlan_vid] = false;
        ctrl_vlan_filter_count--;
      }
    }
    ctrl_vlan_last_valid = true;
    ctrl_vlan_last_vid = next_vlan_vid;
    ctrl_vlan_last_cmd = next_vlan_cmd;
    net_stats.ctrl_vlan_commands++;
  } else if (update_announce_ack) {
    ctrl_announce_pending = false;
    net_stats.ctrl_announce_commands++;
  }
  return 1;
}

static void virtio_net_process_ctrl_queue(void) {
  VirtqState *q = &queues[VIRTIO_NET_QUEUE_CTRL];
  if (!virtio_net_ctrl_vq_enabled() ||
      !q->ready || q->num == 0 || q->desc == 0 || q->driver == 0 || q->device == 0) {
    return;
  }
  uint16_t avail_idx = guest_read16(q->driver + 2);
  uint16_t old_used_idx = guest_read16(q->device + 2);
  uint16_t used_idx = old_used_idx;
  bool used_any = false;
  while (q->last_avail_idx != avail_idx) {
    uint16_t ring_off = q->last_avail_idx % q->num;
    uint16_t head = guest_read16(q->driver + 4 + ring_off * 2);
    uint32_t used_len = virtio_net_handle_ctrl_chain(q, head);
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
      net_stats.rx_packets++;
      net_stats.rx_bytes += rx_pending[rx_pending_head].len;
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
  memcpy(virtio_net_mac, virtio_net_default_mac, sizeof(virtio_net_mac));
  ctrl_rx_promisc = false;
  ctrl_rx_allmulti = false;
  ctrl_rx_alluni = false;
  ctrl_rx_nomulti = false;
  ctrl_rx_nouni = false;
  ctrl_rx_nobcast = false;
  ctrl_mac_table_set = false;
  ctrl_mac_addr_set = false;
  ctrl_mac_unicast_count = 0;
  ctrl_mac_multicast_count = 0;
  memset(ctrl_vlan_filter, 0, sizeof(ctrl_vlan_filter));
  ctrl_vlan_filter_count = 0;
  ctrl_vlan_last_valid = false;
  ctrl_vlan_last_vid = 0;
  ctrl_vlan_last_cmd = 0;
  ctrl_announce_pending = false;
  ctrl_announce_requested = false;
  device_features_sel = 0;
  driver_features_sel = 0;
  interrupt_status = 0;
  device_status = 0;
  queue_sel = 0;
  virtio_net_raise_irq();
}

void virtio_net_dump_machine_info(FILE *out) {
  char mac[18];
  char host_mac[18];
  char host_ip[16];
  char guest_ip[16];
  char subnet_mask[16];
  virtio_net_format_mac(virtio_net_mac, mac, sizeof(mac));
  virtio_net_format_mac(virtio_net_host_mac, host_mac, sizeof(host_mac));
  virtio_net_format_ip(virtio_net_host_ip, host_ip, sizeof(host_ip));
  virtio_net_format_ip(virtio_net_guest_ip, guest_ip, sizeof(guest_ip));
  virtio_net_format_ip(virtio_net_subnet_mask, subnet_mask, sizeof(subnet_mask));

  fprintf(out, "device.virtio_net.backend=hostless-responder\n");
  fprintf(out, "device.virtio_net.mac=%s\n", mac);
  fprintf(out, "device.virtio_net.host_mac=%s\n", host_mac);
  fprintf(out, "device.virtio_net.host_ip=%s\n", host_ip);
  fprintf(out, "device.virtio_net.guest_ip=%s\n", guest_ip);
  fprintf(out, "device.virtio_net.subnet_mask=%s\n", subnet_mask);
  fprintf(out, "device.virtio_net.link_up=1\n");
  fprintf(out, "device.virtio_net.dhcp=hostless\n");
  fprintf(out, "device.virtio_net.dns=nemu.local\n");
  fprintf(out, "device.virtio_net.icmp_echo=hostless\n");
  fprintf(out, "device.virtio_net.tcp_http=/nemu-health\n");
  fprintf(out, "device.virtio_net.tcp_http_head=/nemu-health\n");
  fprintf(out, "device.virtio_net.tcp_http_404=enabled\n");
  fprintf(out, "device.virtio_net.tcp_http_large=/nemu-large bytes=4096\n");
  fprintf(out, "device.virtio_net.tcp_http_segment_payload_max=%u\n",
      VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX);
  fprintf(out, "device.virtio_net.tcp_http_apt_repo=/ubuntu jammy main\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_package=nemu-hostless-hello 1.0 riscv64\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_meta_package=nemu-hostless-meta 1.0 riscv64 depends=nemu-hostless-hello (= 1.0)\n");
  fprintf(out, "device.virtio_net.mtu=%u\n", VIRTIO_NET_MTU);
  fprintf(out, "device.virtio_net.config_bytes=%u\n", VIRTIO_NET_CONFIG_BYTES);
  fprintf(out, "device.virtio_net.speed_mbps=%u\n", VIRTIO_NET_LINK_SPEED_MBIT);
  fprintf(out, "device.virtio_net.duplex=full\n");
  fprintf(out, "device.virtio_net.queue_count=%u\n", VIRTIO_NET_QUEUE_COUNT);
  fprintf(out, "device.virtio_net.queue_num_max=%u\n", VIRTIO_NET_QUEUE_SIZE);
  fprintf(out, "device.virtio_net.features.version_1=1\n");
  fprintf(out, "device.virtio_net.features.mtu=1\n");
  fprintf(out, "device.virtio_net.features.mac=1\n");
  fprintf(out, "device.virtio_net.features.mrg_rxbuf=1\n");
  fprintf(out, "device.virtio_net.features.status=1\n");
  fprintf(out, "device.virtio_net.features.ctrl_vq=1\n");
  fprintf(out, "device.virtio_net.features.ctrl_rx=1\n");
  fprintf(out, "device.virtio_net.features.ctrl_vlan=1\n");
  fprintf(out, "device.virtio_net.features.ctrl_rx_extra=1\n");
  fprintf(out, "device.virtio_net.features.guest_announce=1\n");
  fprintf(out, "device.virtio_net.features.ctrl_mac_addr=1\n");
  fprintf(out, "device.virtio_net.features.speed_duplex=1\n");
  fprintf(out, "device.virtio_net.features.indirect_desc=1\n");
  fprintf(out, "device.virtio_net.features.event_idx=1\n");
  fprintf(out, "device.virtio_net.driver_features.version_1=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_F_VERSION_1) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.mtu=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_NET_F_MTU) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.mac=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_NET_F_MAC) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.mrg_rxbuf=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_NET_F_MRG_RXBUF) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.status=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_NET_F_STATUS) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.ctrl_vq=%d\n",
      virtio_net_ctrl_vq_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.ctrl_rx=%d\n",
      virtio_net_ctrl_rx_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.ctrl_vlan=%d\n",
      virtio_net_ctrl_vlan_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.ctrl_rx_extra=%d\n",
      virtio_net_ctrl_rx_extra_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.guest_announce=%d\n",
      virtio_net_guest_announce_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.ctrl_mac_addr=%d\n",
      virtio_net_ctrl_mac_addr_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.speed_duplex=%d\n",
      virtio_net_driver_feature_enabled(VIRTIO_NET_F_SPEED_DUPLEX) ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.indirect_desc=%d\n",
      virtio_net_indirect_desc_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.driver_features.event_idx=%d\n",
      virtio_net_event_idx_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.promisc=%d\n", ctrl_rx_promisc ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.allmulti=%d\n", ctrl_rx_allmulti ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.alluni=%d\n", ctrl_rx_alluni ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.nomulti=%d\n", ctrl_rx_nomulti ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.nouni=%d\n", ctrl_rx_nouni ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_rx.nobcast=%d\n", ctrl_rx_nobcast ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_mac.current=%s\n", mac);
  fprintf(out, "device.virtio_net.ctrl_mac.table_set=%d\n", ctrl_mac_table_set ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_mac.addr_set=%d\n", ctrl_mac_addr_set ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_mac.unicast=%u\n", ctrl_mac_unicast_count);
  fprintf(out, "device.virtio_net.ctrl_mac.multicast=%u\n", ctrl_mac_multicast_count);
  fprintf(out, "device.virtio_net.ctrl_vlan.filter_count=%u\n", ctrl_vlan_filter_count);
  fprintf(out, "device.virtio_net.ctrl_vlan.last_vid_valid=%d\n",
      ctrl_vlan_last_valid ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_vlan.last_vid=%u\n", ctrl_vlan_last_vid);
  fprintf(out, "device.virtio_net.ctrl_vlan.last_cmd=%u\n", ctrl_vlan_last_cmd);
  fprintf(out, "device.virtio_net.ctrl_announce.pending=%d\n",
      ctrl_announce_pending ? 1 : 0);
  fprintf(out, "device.virtio_net.ctrl_announce.requested=%d\n",
      ctrl_announce_requested ? 1 : 0);
  fprintf(out, "device.virtio_net.stats.tx_packets=%" PRIu64 "\n", net_stats.tx_packets);
  fprintf(out, "device.virtio_net.stats.rx_packets=%" PRIu64 "\n", net_stats.rx_packets);
  fprintf(out, "device.virtio_net.stats.tx_errors=%" PRIu64 "\n", net_stats.tx_errors);
  fprintf(out, "device.virtio_net.stats.rx_drops=%" PRIu64 "\n", net_stats.rx_drops);
  fprintf(out, "device.virtio_net.stats.ctrl_commands=%" PRIu64 "\n", net_stats.ctrl_commands);
  fprintf(out, "device.virtio_net.stats.tcp_http_head_requests=%" PRIu64 "\n",
      net_stats.tcp_http_head_requests);
  fprintf(out, "device.virtio_net.stats.tcp_http_not_found=%" PRIu64 "\n",
      net_stats.tcp_http_not_found);
  fprintf(out, "device.virtio_net.stats.tcp_http_apt_requests=%" PRIu64 "\n",
      net_stats.tcp_http_apt_requests);
  fprintf(out, "device.virtio_net.stats.tcp_http_apt_deb_requests=%" PRIu64 "\n",
      net_stats.tcp_http_apt_deb_requests);
  fprintf(out, "device.virtio_net.stats.tcp_http_large_requests=%" PRIu64 "\n",
      net_stats.tcp_http_large_requests);
  fprintf(out, "device.virtio_net.stats.tcp_http_segmented_responses=%" PRIu64 "\n",
      net_stats.tcp_http_segmented_responses);
  fprintf(out, "device.virtio_net.stats.tcp_http_response_segments=%" PRIu64 "\n",
      net_stats.tcp_http_response_segments);
  fprintf(out, "device.virtio_net.stats.ctrl_rx_commands=%" PRIu64 "\n",
      net_stats.ctrl_rx_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_rx_extra_commands=%" PRIu64 "\n",
      net_stats.ctrl_rx_extra_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_mac_table_commands=%" PRIu64 "\n",
      net_stats.ctrl_mac_table_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_mac_addr_commands=%" PRIu64 "\n",
      net_stats.ctrl_mac_addr_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_vlan_commands=%" PRIu64 "\n",
      net_stats.ctrl_vlan_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_announce_commands=%" PRIu64 "\n",
      net_stats.ctrl_announce_commands);
  fprintf(out, "device.virtio_net.stats.ctrl_errors=%" PRIu64 "\n", net_stats.ctrl_errors);
}

void virtio_net_qmp_query_netdev(char *out, size_t out_size) {
  Assert(out != NULL && out_size > 0, "invalid query-netdev output buffer");

  char mac[18];
  char host_mac[18];
  char host_ip[16];
  char guest_ip[16];
  char subnet_mask[16];
  virtio_net_format_mac(virtio_net_mac, mac, sizeof(mac));
  virtio_net_format_mac(virtio_net_host_mac, host_mac, sizeof(host_mac));
  virtio_net_format_ip(virtio_net_host_ip, host_ip, sizeof(host_ip));
  virtio_net_format_ip(virtio_net_guest_ip, guest_ip, sizeof(guest_ip));
  virtio_net_format_ip(virtio_net_subnet_mask, subnet_mask, sizeof(subnet_mask));

  /*
   * 这里故意把 backend 写成 hostless-responder：当前网卡只闭合 guest
   * 可见的 DHCP/DNS/ICMP/固定 HTTP 健康检查，不冒充 TAP/NAT 或外网能力。
   */
  snprintf(out, out_size,
      "{\"return\":[{\"id\":\"net0\",\"type\":\"hostless\","
      "\"peer\":\"virtio-net0\",\"nemu\":{\"backend\":\"hostless-responder\","
      "\"model\":\"virtio-net-mmio\",\"mac\":\"%s\",\"host-mac\":\"%s\","
      "\"host-ip\":\"%s\",\"guest-ip\":\"%s\",\"subnet-mask\":\"%s\","
      "\"dhcp\":true,\"dns\":true,\"icmp\":true,\"tcp-http\":true,"
      "\"http-methods\":[\"GET\",\"HEAD\"],\"http-not-found\":true,"
      "\"http-large\":{\"path\":\"/nemu-large\",\"bytes\":4096,"
      "\"segment-payload-max\":%u},"
      "\"apt-repo\":{\"base\":\"/ubuntu\",\"suite\":\"jammy\","
      "\"component\":\"main\",\"arch\":\"riscv64\","
      "\"package\":\"nemu-hostless-hello\",\"version\":\"1.0\","
      "\"deb-size\":722,\"meta-package\":\"nemu-hostless-meta\","
      "\"meta-version\":\"1.0\","
      "\"meta-depends\":\"nemu-hostless-hello (= 1.0)\","
      "\"meta-deb-size\":896},"
      "\"link-up\":true,\"mtu\":%u,\"speed-mbps\":%u,\"duplex\":\"full\","
      "\"config-bytes\":%u,\"device-status\":%u,"
      "\"rx-queue-ready\":%s,\"tx-queue-ready\":%s,\"ctrl-queue-ready\":%s,"
      "\"rx-pending\":%u,\"event-idx\":%s,"
      "\"features\":{\"version-1\":true,\"mtu\":true,\"mac\":true,\"mrg-rxbuf\":true,"
      "\"status\":true,\"ctrl-vq\":true,\"ctrl-rx\":true,"
      "\"ctrl-vlan\":true,\"ctrl-rx-extra\":true,\"guest-announce\":true,"
      "\"ctrl-mac-addr\":true,\"speed-duplex\":true,"
      "\"indirect-desc\":true,\"event-idx\":true},"
      "\"driver-features\":{\"version-1\":%s,\"mtu\":%s,\"mac\":%s,\"mrg-rxbuf\":%s,"
      "\"status\":%s,\"ctrl-vq\":%s,\"ctrl-rx\":%s,"
      "\"ctrl-vlan\":%s,\"ctrl-rx-extra\":%s,\"guest-announce\":%s,"
      "\"ctrl-mac-addr\":%s,\"speed-duplex\":%s,"
      "\"indirect-desc\":%s,\"event-idx\":%s},"
      "\"ctrl-rx\":{\"promisc\":%s,\"allmulti\":%s,\"alluni\":%s,"
      "\"nomulti\":%s,\"nouni\":%s,\"nobcast\":%s},"
      "\"ctrl-mac\":{\"current\":\"%s\",\"table-set\":%s,\"addr-set\":%s,"
      "\"unicast\":%u,\"multicast\":%u},"
      "\"ctrl-vlan\":{\"filter-count\":%u,\"last-vid-valid\":%s,"
      "\"last-vid\":%u,\"last-cmd\":%u},"
      "\"ctrl-announce\":{\"pending\":%s,\"requested\":%s},"
      "\"stats\":{\"tx-packets\":%" PRIu64 ",\"tx-bytes\":%" PRIu64 ","
      "\"tx-errors\":%" PRIu64 ",\"rx-packets\":%" PRIu64 ","
      "\"rx-bytes\":%" PRIu64 ",\"rx-drops\":%" PRIu64 ","
      "\"arp-requests\":%" PRIu64 ",\"arp-replies\":%" PRIu64 ","
      "\"icmp-echo-requests\":%" PRIu64 ",\"icmp-echo-replies\":%" PRIu64 ","
      "\"dhcp-requests\":%" PRIu64 ",\"dhcp-replies\":%" PRIu64 ","
      "\"dns-queries\":%" PRIu64 ",\"dns-replies\":%" PRIu64 ","
      "\"tcp-segments\":%" PRIu64 ",\"tcp-replies\":%" PRIu64 ","
      "\"tcp-http-requests\":%" PRIu64 ","
      "\"tcp-http-head-requests\":%" PRIu64 ","
      "\"tcp-http-not-found\":%" PRIu64 ","
      "\"tcp-http-apt-requests\":%" PRIu64 ","
      "\"tcp-http-apt-deb-requests\":%" PRIu64 ","
      "\"tcp-http-large-requests\":%" PRIu64 ","
      "\"tcp-http-segmented-responses\":%" PRIu64 ","
      "\"tcp-http-response-segments\":%" PRIu64 ","
      "\"ctrl-commands\":%" PRIu64 ","
      "\"ctrl-rx-commands\":%" PRIu64 ",\"ctrl-rx-extra-commands\":%" PRIu64 ","
      "\"ctrl-mac-table-commands\":%" PRIu64 ","
      "\"ctrl-mac-addr-commands\":%" PRIu64 ","
      "\"ctrl-vlan-commands\":%" PRIu64 ","
      "\"ctrl-announce-commands\":%" PRIu64 ","
      "\"ctrl-errors\":%" PRIu64 "}}}]}",
      mac, host_mac, host_ip, guest_ip, subnet_mask,
      VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX,
      VIRTIO_NET_MTU, VIRTIO_NET_LINK_SPEED_MBIT, VIRTIO_NET_CONFIG_BYTES,
      device_status,
      queues[VIRTIO_NET_QUEUE_RX].ready ? "true" : "false",
      queues[VIRTIO_NET_QUEUE_TX].ready ? "true" : "false",
      queues[VIRTIO_NET_QUEUE_CTRL].ready ? "true" : "false",
      rx_pending_count,
      virtio_net_event_idx_enabled() ? "true" : "false",
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_F_VERSION_1)),
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_NET_F_MTU)),
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_NET_F_MAC)),
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_NET_F_MRG_RXBUF)),
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_NET_F_STATUS)),
      virtio_net_json_bool(virtio_net_ctrl_vq_enabled()),
      virtio_net_json_bool(virtio_net_ctrl_rx_enabled()),
      virtio_net_json_bool(virtio_net_ctrl_vlan_enabled()),
      virtio_net_json_bool(virtio_net_ctrl_rx_extra_enabled()),
      virtio_net_json_bool(virtio_net_guest_announce_enabled()),
      virtio_net_json_bool(virtio_net_ctrl_mac_addr_enabled()),
      virtio_net_json_bool(virtio_net_driver_feature_enabled(VIRTIO_NET_F_SPEED_DUPLEX)),
      virtio_net_json_bool(virtio_net_indirect_desc_enabled()),
      virtio_net_json_bool(virtio_net_event_idx_enabled()),
      virtio_net_json_bool(ctrl_rx_promisc),
      virtio_net_json_bool(ctrl_rx_allmulti),
      virtio_net_json_bool(ctrl_rx_alluni),
      virtio_net_json_bool(ctrl_rx_nomulti),
      virtio_net_json_bool(ctrl_rx_nouni),
      virtio_net_json_bool(ctrl_rx_nobcast),
      mac,
      virtio_net_json_bool(ctrl_mac_table_set),
      virtio_net_json_bool(ctrl_mac_addr_set),
      ctrl_mac_unicast_count, ctrl_mac_multicast_count,
      ctrl_vlan_filter_count,
      virtio_net_json_bool(ctrl_vlan_last_valid),
      ctrl_vlan_last_vid, ctrl_vlan_last_cmd,
      virtio_net_json_bool(ctrl_announce_pending),
      virtio_net_json_bool(ctrl_announce_requested),
      net_stats.tx_packets, net_stats.tx_bytes, net_stats.tx_errors,
      net_stats.rx_packets, net_stats.rx_bytes, net_stats.rx_drops,
      net_stats.arp_requests, net_stats.arp_replies,
      net_stats.icmp_echo_requests, net_stats.icmp_echo_replies,
      net_stats.dhcp_requests, net_stats.dhcp_replies,
      net_stats.dns_queries, net_stats.dns_replies,
      net_stats.tcp_segments, net_stats.tcp_replies,
      net_stats.tcp_http_requests, net_stats.tcp_http_head_requests,
      net_stats.tcp_http_not_found, net_stats.tcp_http_apt_requests,
      net_stats.tcp_http_apt_deb_requests,
      net_stats.tcp_http_large_requests,
      net_stats.tcp_http_segmented_responses,
      net_stats.tcp_http_response_segments,
      net_stats.ctrl_commands,
      net_stats.ctrl_rx_commands, net_stats.ctrl_rx_extra_commands,
      net_stats.ctrl_mac_table_commands,
      net_stats.ctrl_mac_addr_commands,
      net_stats.ctrl_vlan_commands,
      net_stats.ctrl_announce_commands,
      net_stats.ctrl_errors);
}

void virtio_net_statistic(void) {
  char mac[18];
  virtio_net_format_mac(virtio_net_mac, mac, sizeof(mac));
  Log("virtio-net runtime tx_packets=%" PRIu64 " tx_bytes=%" PRIu64
      " rx_packets=%" PRIu64 " rx_bytes=%" PRIu64
      " tx_errors=%" PRIu64 " rx_drops=%" PRIu64
      " arp=%" PRIu64 "/%" PRIu64
      " icmp=%" PRIu64 "/%" PRIu64
      " dhcp=%" PRIu64 "/%" PRIu64
      " dns=%" PRIu64 "/%" PRIu64
      " tcp_segments=%" PRIu64 " tcp_replies=%" PRIu64
      " tcp_http_requests=%" PRIu64
      " tcp_http_head_requests=%" PRIu64
      " tcp_http_not_found=%" PRIu64
      " tcp_http_apt_requests=%" PRIu64
      " tcp_http_apt_deb_requests=%" PRIu64
      " tcp_http_large_requests=%" PRIu64
      " tcp_http_segmented_responses=%" PRIu64
      " tcp_http_response_segments=%" PRIu64
      " ctrl=%" PRIu64 "/%" PRIu64
      " ctrl_rx=%" PRIu64 " ctrl_rx_extra=%" PRIu64
      " promisc=%d allmulti=%d alluni=%d nomulti=%d nouni=%d nobcast=%d"
      " ctrl_mac_table=%" PRIu64 " ctrl_mac_addr=%" PRIu64
      " ctrl_vlan=%" PRIu64 " vlan_active=%u vlan_last=%u vlan_last_cmd=%u"
      " ctrl_announce=%" PRIu64 " announce_pending=%d announce_requested=%d"
      " mac_uni=%u mac_multi=%u mac=%s rx_pending=%u",
      net_stats.tx_packets, net_stats.tx_bytes,
      net_stats.rx_packets, net_stats.rx_bytes,
      net_stats.tx_errors, net_stats.rx_drops,
      net_stats.arp_requests, net_stats.arp_replies,
      net_stats.icmp_echo_requests, net_stats.icmp_echo_replies,
      net_stats.dhcp_requests, net_stats.dhcp_replies,
      net_stats.dns_queries, net_stats.dns_replies,
      net_stats.tcp_segments, net_stats.tcp_replies,
      net_stats.tcp_http_requests,
      net_stats.tcp_http_head_requests,
      net_stats.tcp_http_not_found,
      net_stats.tcp_http_apt_requests,
      net_stats.tcp_http_apt_deb_requests,
      net_stats.tcp_http_large_requests,
      net_stats.tcp_http_segmented_responses,
      net_stats.tcp_http_response_segments,
      net_stats.ctrl_commands, net_stats.ctrl_errors,
      net_stats.ctrl_rx_commands, net_stats.ctrl_rx_extra_commands,
      ctrl_rx_promisc ? 1 : 0, ctrl_rx_allmulti ? 1 : 0,
      ctrl_rx_alluni ? 1 : 0, ctrl_rx_nomulti ? 1 : 0,
      ctrl_rx_nouni ? 1 : 0, ctrl_rx_nobcast ? 1 : 0,
      net_stats.ctrl_mac_table_commands,
      net_stats.ctrl_mac_addr_commands,
      net_stats.ctrl_vlan_commands,
      ctrl_vlan_filter_count,
      ctrl_vlan_last_valid ? ctrl_vlan_last_vid : 0,
      ctrl_vlan_last_valid ? ctrl_vlan_last_cmd : 0,
      net_stats.ctrl_announce_commands,
      ctrl_announce_pending ? 1 : 0,
      ctrl_announce_requested ? 1 : 0,
      ctrl_mac_unicast_count, ctrl_mac_multicast_count, mac, rx_pending_count);
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
  uint16_t status = virtio_net_config_status();
  if (config_off < 6) return virtio_net_mac[config_off];
  if (config_off == 6) return status & 0xffu;
  if (config_off == 7) return (status >> 8) & 0xffu;
  if (config_off == VIRTIO_NET_CONFIG_MTU_OFFSET) return VIRTIO_NET_MTU & 0xffu;
  if (config_off == VIRTIO_NET_CONFIG_MTU_OFFSET + 1) return (VIRTIO_NET_MTU >> 8) & 0xffu;
  if (config_off >= VIRTIO_NET_CONFIG_SPEED_OFFSET &&
      config_off < VIRTIO_NET_CONFIG_SPEED_OFFSET + 4u) {
    uint32_t byte = config_off - VIRTIO_NET_CONFIG_SPEED_OFFSET;
    return (VIRTIO_NET_LINK_SPEED_MBIT >> (byte * 8u)) & 0xffu;
  }
  if (config_off == VIRTIO_NET_CONFIG_DUPLEX_OFFSET) return VIRTIO_NET_LINK_DUPLEX_FULL;
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
      } else if (value == VIRTIO_NET_QUEUE_CTRL) {
        virtio_net_process_ctrl_queue();
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
        if ((device_status & VIRTIO_STATUS_DRIVER_OK) != 0) {
          virtio_net_request_guest_announce();
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
