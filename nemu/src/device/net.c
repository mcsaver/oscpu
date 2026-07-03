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
#include <errno.h>
#include <fcntl.h>
#include <linux/if_tun.h>
#include <net/if.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

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

#ifndef ETH_P_IP
#define ETH_P_IP 0x0800u
#endif
#ifndef ETH_P_ARP
#define ETH_P_ARP 0x0806u
#endif
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
#define DHCP_OPT_NTP 42u
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
#define NTP_SERVER_PORT 123u
#define NTP_PACKET_LEN 48u
#define NTP_UNIX_EPOCH_DELTA 2208988800ull
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
  uint64_t ntp_requests;
  uint64_t ntp_replies;
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
  uint64_t tap_tx_packets;
  uint64_t tap_tx_bytes;
  uint64_t tap_tx_errors;
  uint64_t tap_rx_packets;
  uint64_t tap_rx_bytes;
  uint64_t tap_rx_errors;
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
static bool tap_requested;
static bool tap_active;
static int tap_fd = -1;
static char tap_ifname[IFNAMSIZ];
static VirtioNetStats net_stats;

static void virtio_net_format_mac(const uint8_t *mac, char *out, size_t out_size) {
  snprintf(out, out_size, "%02x:%02x:%02x:%02x:%02x:%02x",
      mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

static void virtio_net_format_ip(const uint8_t *ip, char *out, size_t out_size) {
  snprintf(out, out_size, "%u.%u.%u.%u", ip[0], ip[1], ip[2], ip[3]);
}

static bool virtio_net_tap_enabled(void) {
  return tap_active && tap_fd >= 0;
}

static const char *virtio_net_backend_name(void) {
  return virtio_net_tap_enabled() ? "tap" : "hostless-responder";
}

void virtio_net_set_tap(const char *ifname) {
  Assert(ifname != NULL && ifname[0] != '\0',
      "--net-tap requires a TAP interface name");
  size_t ifname_len = strlen(ifname);
  Assert(ifname_len < sizeof(tap_ifname),
      "--net-tap interface name is too long: %s", ifname);
  for (const char *p = ifname; *p != '\0'; p++) {
    bool ok = (*p >= 'a' && *p <= 'z') ||
              (*p >= 'A' && *p <= 'Z') ||
              (*p >= '0' && *p <= '9') ||
              *p == '_' || *p == '-' || *p == '.';
    Assert(ok, "--net-tap interface name contains unsupported char: %s", ifname);
  }
  memcpy(tap_ifname, ifname, ifname_len + 1);
  tap_requested = true;
}

static void virtio_net_tap_open_if_requested(void) {
  if (!tap_requested || virtio_net_tap_enabled()) return;

  int fd = open("/dev/net/tun", O_RDWR | O_NONBLOCK);
  Assert(fd >= 0, "virtio-net: can not open /dev/net/tun for --net-tap=%s: %s",
      tap_ifname, strerror(errno));

  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
  size_t ifname_len = strlen(tap_ifname);
  Assert(ifname_len < IFNAMSIZ, "virtio-net: TAP interface name is too long: %s",
      tap_ifname);
  memcpy(ifr.ifr_name, tap_ifname, ifname_len + 1);
  Assert(ioctl(fd, TUNSETIFF, (void *)&ifr) >= 0,
      "virtio-net: TUNSETIFF failed for --net-tap=%s: %s",
      tap_ifname, strerror(errno));

  int flags = fcntl(fd, F_GETFL, 0);
  Assert(flags >= 0 && fcntl(fd, F_SETFL, flags | O_NONBLOCK) >= 0,
      "virtio-net: can not set TAP fd non-blocking: %s", strerror(errno));
  tap_fd = fd;
  tap_active = true;
  memset(tap_ifname, 0, sizeof(tap_ifname));
  memcpy(tap_ifname, ifr.ifr_name, strnlen(ifr.ifr_name, sizeof(tap_ifname) - 1));
  Log("virtio-net: TAP backend attached ifname=%s", tap_ifname);
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
      if (!paddr_dma_write(descs[i].addr + desc_off, src, take)) return false;
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

static void virtio_net_tap_tx(const uint8_t *frame, uint32_t len) {
  if (!virtio_net_tap_enabled()) return;

  ssize_t written = write(tap_fd, frame, len);
  if (written == (ssize_t)len) {
    net_stats.tap_tx_packets++;
    net_stats.tap_tx_bytes += len;
    return;
  }
  net_stats.tap_tx_errors++;
  if (written < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
    Log("virtio-net: TAP TX failed ifname=%s errno=%d (%s)",
        tap_ifname, errno, strerror(errno));
  }
}

void virtio_net_update(void) {
  if (!virtio_net_tap_enabled()) return;

  for (int i = 0; i < VIRTIO_NET_RX_PENDING_CAP; i++) {
    if (rx_pending_count >= VIRTIO_NET_RX_PENDING_CAP) return;

    uint8_t frame[VIRTIO_NET_FRAME_MAX];
    ssize_t nread = read(tap_fd, frame, sizeof(frame));
    if (nread < 0) {
      if (errno != EAGAIN && errno != EWOULDBLOCK) {
        net_stats.tap_rx_errors++;
        Log("virtio-net: TAP RX failed ifname=%s errno=%d (%s)",
            tap_ifname, errno, strerror(errno));
      }
      return;
    }
    if (nread == 0) return;
    if (nread < 14 || nread > VIRTIO_NET_FRAME_MAX) {
      net_stats.tap_rx_errors++;
      continue;
    }
    net_stats.tap_rx_packets++;
    net_stats.tap_rx_bytes += (uint32_t)nread;
    virtio_net_enqueue_rx_frame(frame, (uint32_t)nread);
  }
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
  opt_off = dhcp_put_opt(opts, opt_off, DHCP_OPT_NTP,
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

static void ntp_put_timestamp(uint8_t *p, const struct timespec *ts) {
  uint64_t seconds = (uint64_t)ts->tv_sec + NTP_UNIX_EPOCH_DELTA;
  uint64_t fraction = ((uint64_t)ts->tv_nsec << 32) / 1000000000ull;
  net_put_be32(p, (uint32_t)seconds);
  net_put_be32(p + 4, (uint32_t)fraction);
}

static bool virtio_net_handle_ntp(const uint8_t *frame, uint32_t len) {
  if (len < 14 + 20 + 8 + NTP_PACKET_LEN || net_get_be16(frame + 12) != ETH_P_IP) {
    return false;
  }
  const uint8_t *ip = frame + 14;
  uint32_t ihl = (ip[0] & 0x0fu) * 4u;
  if ((ip[0] >> 4) != 4 || ihl < 20 || ip[9] != IPPROTO_UDP ||
      memcmp(ip + 16, virtio_net_host_ip, sizeof(virtio_net_host_ip)) != 0) {
    return false;
  }

  uint32_t total_len = net_get_be16(ip + 2);
  if (total_len < ihl + 8 + NTP_PACKET_LEN || total_len > VIRTIO_NET_FRAME_MAX - 14 ||
      len < 14 + total_len) {
    return false;
  }
  const uint8_t *udp = ip + ihl;
  uint32_t udp_len = net_get_be16(udp + 4);
  if (udp_len < 8 + NTP_PACKET_LEN || ihl + udp_len > total_len ||
      net_get_be16(udp + 2) != NTP_SERVER_PORT) {
    return false;
  }

  const uint8_t *ntp = udp + 8;
  uint8_t mode = ntp[0] & 0x07u;
  uint8_t version = (ntp[0] >> 3) & 0x07u;
  if (mode != 3) {
    return false;
  }
  if (version == 0) version = 4;

  struct timespec now;
  if (clock_gettime(CLOCK_REALTIME, &now) != 0) {
    return false;
  }

  uint8_t reply[VIRTIO_NET_FRAME_MAX] = {};
  uint32_t reply_udp_len = 8 + NTP_PACKET_LEN;
  uint32_t reply_total_len = 20 + reply_udp_len;

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
  net_put_be16(reply_udp, NTP_SERVER_PORT);
  net_put_be16(reply_udp + 2, net_get_be16(udp));
  net_put_be16(reply_udp + 4, reply_udp_len);
  net_put_be16(reply_udp + 6, 0);

  uint8_t *reply_ntp = reply_udp + 8;
  reply_ntp[0] = (uint8_t)((version << 3) | 4u);
  reply_ntp[1] = 2;
  reply_ntp[2] = ntp[2];
  reply_ntp[3] = 0xec;
  net_put_be32(reply_ntp + 4, 1u << 16);
  net_put_be32(reply_ntp + 8, 1u << 16);
  memcpy(reply_ntp + 12, "NEMU", 4);
  ntp_put_timestamp(reply_ntp + 16, &now);
  memcpy(reply_ntp + 24, ntp + 40, 8);
  ntp_put_timestamp(reply_ntp + 32, &now);
  ntp_put_timestamp(reply_ntp + 40, &now);

  uint32_t reply_len = 14 + reply_total_len;
  if (reply_len < VIRTIO_NET_ETH_MIN_FRAME) {
    reply_len = VIRTIO_NET_ETH_MIN_FRAME;
  }
  net_stats.ntp_requests++;
  bool queued = virtio_net_enqueue_rx_frame(reply, reply_len);
  if (queued) net_stats.ntp_replies++;
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
    " 79ee9e9b166628d367891b673435b6f0 2076 main/binary-riscv64/Packages\n"
    " 0f32069f228042699b0ba3e20354ee6d 680 main/binary-riscv64/Packages.gz\n"
    "SHA256:\n"
    " e61f828aff2a20161aa5ffe35b40274ba5c358c44b961d8daaf86b6881e8a97b 2076 main/binary-riscv64/Packages\n"
    " bc41c871dad81f37fd7662a656340ea4468dfab83b1cad21dc580dfb243558bc 680 main/binary-riscv64/Packages.gz\n";
  static const uint8_t nemu_apt_inrelease[] =
    "-----BEGIN PGP SIGNED MESSAGE-----\n"
    "Hash: SHA256\n"
    "\n"
    "Suite: jammy\n"
    "Codename: jammy\n"
    "Components: main\n"
    "Architectures: riscv64\n"
    "Date: Fri, 12 Jun 2026 00:00:00 UTC\n"
    "MD5Sum:\n"
    " 79ee9e9b166628d367891b673435b6f0 2076 main/binary-riscv64/Packages\n"
    " 0f32069f228042699b0ba3e20354ee6d 680 main/binary-riscv64/Packages.gz\n"
    "SHA256:\n"
    " e61f828aff2a20161aa5ffe35b40274ba5c358c44b961d8daaf86b6881e8a97b 2076 main/binary-riscv64/Packages\n"
    " bc41c871dad81f37fd7662a656340ea4468dfab83b1cad21dc580dfb243558bc 680 main/binary-riscv64/Packages.gz\n"
    "-----BEGIN PGP SIGNATURE-----\n"
    "\n"
    "iQEyBAEBCAAdFiEE5nQniebzqurXSFiSCRCMnq+qbBQFAmotvQAACgkQCRCMnq+q\n"
    "bBSEHwf4rlrzjeQp4XpOES0N0nc52xTSdsCSA/c2KmYSpBZdnLUIlDpJ2jx0ayNa\n"
    "rYopEZ6bJ5Be+8U8dQsW+RorZAFyAcd155HBTE2Dd2sNKpt3TUBQQi8NekiIQhs/\n"
    "U0UybvtDlkR+CxOP2hSUEkiGonkRyEY6rjGxLCsDLhtBwZEHrr4NGTUkVZbINCYY\n"
    "48Weaw0AwVhIwLzv05IYQXEzWDnI4y7WWiQfIRvhP3EkxT4w7eTeiWylvfi0Asxi\n"
    "831wsueV+w5Z9rA2gj3LblqWZbRi1el7P8k8l5P1nKPz3KhvLMAvQFvFiDkqtwA3\n"
    "95RjrOBJW17p6iGhGS6Jh/jJnPjo\n"
    "=EAIg\n"
    "-----END PGP SIGNATURE-----\n";
  static const uint8_t nemu_apt_keyring[] =
    "\231\001\015\004\152\055\270\152\001\010\000\240\333\053\246\161\024\365\176"
    "\011\150\223\115\323\167\304\343\107\007\036\264\016\142\103\320\275\024\050"
    "\105\256\003\244\205\373\004\273\177\367\361\272\205\331\061\221\260\126\355"
    "\144\264\277\154\315\047\311\011\265\165\175\211\006\232\111\074\336\247\363"
    "\103\014\243\135\021\345\142\212\134\065\200\072\337\276\243\346\163\175\251"
    "\023\331\314\212\216\026\020\322\075\370\036\212\046\223\324\047\023\042\316"
    "\337\106\336\163\340\341\300\164\006\240\076\267\040\364\253\061\301\134\217"
    "\305\157\146\203\372\227\066\076\241\275\156\034\215\002\007\151\037\140\100"
    "\123\313\004\004\243\150\372\332\131\243\255\012\350\310\221\061\257\246\124"
    "\225\365\166\345\235\154\017\157\364\062\342\105\063\143\165\036\316\227\147"
    "\051\235\033\166\171\167\271\024\201\261\376\336\177\252\223\127\111\104\146"
    "\166\303\145\007\370\063\122\125\311\342\035\351\306\237\350\372\367\163\342"
    "\230\327\132\277\010\356\313\042\055\242\066\367\154\222\204\351\032\047\165"
    "\225\320\131\305\242\020\372\272\231\161\246\156\252\351\337\120\363\260\033"
    "\305\000\021\001\000\001\264\055\116\105\115\125\040\110\157\163\164\154\145"
    "\163\163\040\101\160\164\040\124\145\163\164\040\074\156\145\155\165\100\145"
    "\170\141\155\160\154\145\056\151\156\166\141\154\151\144\076\211\001\121\004"
    "\023\001\012\000\073\026\041\004\346\164\047\211\346\363\252\352\327\110\130"
    "\222\011\020\214\236\257\252\154\024\005\002\152\055\270\152\002\033\003\005"
    "\013\011\010\007\002\002\042\002\006\025\012\011\010\013\002\004\026\002\003"
    "\001\002\036\007\002\027\200\000\012\011\020\011\020\214\236\257\252\154\024"
    "\030\352\010\000\202\246\024\045\345\115\237\271\203\374\025\251\320\304\257"
    "\113\247\074\130\376\244\014\124\340\330\156\024\206\032\244\250\247\203\107"
    "\054\052\345\366\153\307\043\053\127\372\011\121\167\215\003\254\010\236\374"
    "\366\206\224\256\321\156\227\136\035\240\101\013\332\305\204\016\246\142\171"
    "\231\020\370\060\165\111\266\223\364\036\052\246\140\232\172\245\147\164\030"
    "\366\206\012\050\046\316\060\014\366\147\031\351\311\221\143\231\213\101\113"
    "\022\005\050\072\273\213\047\154\371\210\271\323\127\367\370\170\113\074\035"
    "\001\122\230\301\352\002\245\173\231\327\345\057\256\112\052\340\213\023\145"
    "\353\230\014\165\001\113\164\375\321\251\041\250\246\104\325\212\237\076\303"
    "\200\130\336\317\244\277\172\166\074\277\113\231\345\064\317\273\365\075\246"
    "\151\230\017\235\170\114\172\342\321\103\165\161\175\323\043\063\004\374\162"
    "\200\206\172\267\365\027\315\205\072\036\061\171\137\000\361\307\300\020\020"
    "\375\230\135\350\342\020\006\144\134\101\352\077\233\227\244\306\210\116\156"
    "\243\246\105\070\241\172\256\337\114\055\047\052\275";
  static const uint8_t nemu_apt_packages[] =
    "Package: nemu-hostless-hello\n"
    "Version: 1.1\n"
    "Architecture: riscv64\n"
    "Maintainer: NEMU Hostless Apt <nemu@example.invalid>\n"
    "Installed-Size: 1\n"
    "Filename: pool/main/n/nemu-hostless-hello/nemu-hostless-hello_1.1_riscv64.deb\n"
    "Size: 674\n"
    "MD5sum: 355ee2cd5506863f96e9d3342fa44e12\n"
    "SHA256: 9b9eb02a081a1a9c84d8488252d64c119ad8d8360eeb01e9cd3fcf878b095101\n"
    "Section: base\n"
    "Priority: optional\n"
    "Description: NEMU hostless apt upgrade smoke package\n"
    " This package proves that NEMU hostless APT can upgrade a real deb.\n"
    "\n"
    "Package: nemu-hostless-meta\n"
    "Version: 1.1\n"
    "Architecture: riscv64\n"
    "Maintainer: NEMU Hostless Apt <nemu@example.invalid>\n"
    "Depends: nemu-hostless-hello (= 1.1)\n"
    "Installed-Size: 1\n"
    "Filename: pool/main/n/nemu-hostless-meta/nemu-hostless-meta_1.1_riscv64.deb\n"
    "Size: 886\n"
    "MD5sum: d8f8c0cfe92ea631a114e7a85cceb82a\n"
    "SHA256: 56118bead4403509a5643882a3645454c9c4b765fcc3a25ff9581cc8912ce108\n"
    "Section: base\n"
    "Priority: optional\n"
    "Description: NEMU hostless apt upgrade dependency smoke package\n"
    " This package depends on the upgraded hello package to prove apt upgrade.\n"
    "\n"
    "Package: nemu-hostless-hello\n"
    "Version: 1.0\n"
    "Architecture: riscv64\n"
    "Maintainer: NEMU Hostless Apt <nemu@example.invalid>\n"
    "Installed-Size: 1\n"
    "Filename: pool/main/n/nemu-hostless-hello/nemu-hostless-hello_1.0_riscv64.deb\n"
    "Size: 676\n"
    "MD5sum: 2788a81d64a440d8340e57cb951c7f52\n"
    "SHA256: 49f963a8d5e812279f07b29e9e6df366ccabd08c4c3402f6a89724f20811cbe7\n"
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
    "Size: 868\n"
    "MD5sum: 3a24171e2bf4159a813d33eb2b4e64f0\n"
    "SHA256: 045eea5e02492c3ea2b05729b8feef54f51044d24f5b752012335b4d82de2d67\n"
    "Section: base\n"
    "Priority: optional\n"
    "Description: NEMU hostless apt dependency smoke package\n"
    " This package depends on nemu-hostless-hello to prove apt dependency install.\n"
    "\n";
  static const uint8_t nemu_apt_packages_gz[] =
    "\037\213\010\000\000\000\000\000\002\377\315\225\115\157\323\100\020\206\357"
    "\376\025\173\204\103\323\375\366\156\004\210\110\005\225\103\121\244\026\256"
    "\325\354\354\154\143\325\261\055\333\251\050\277\236\115\323\244\205\246\110"
    "\264\005\041\313\222\275\032\277\073\236\171\366\235\071\340\045\134\320\224"
    "\065\264\134\035\054\332\141\254\151\030\016\026\124\327\155\361\225\372\241"
    "\152\233\051\023\023\121\314\172\134\124\043\341\270\352\163\170\137\015\170"
    "\145\165\161\002\125\063\346\233\372\051\373\374\341\344\013\073\276\225\140"
    "\263\156\144\157\326\252\357\351\033\054\273\232\046\125\163\005\165\025\337"
    "\025\237\232\141\204\272\246\170\160\132\175\317\142\242\370\130\325\324\300"
    "\062\077\167\155\133\037\056\263\342\141\276\036\346\264\157\355\074\247\167"
    "\176\233\320\044\122\050\066\252\266\314\351\035\231\141\265\234\062\145\014"
    "\221\304\150\014\267\316\252\344\055\371\250\224\226\011\264\046\041\213\323"
    "\343\231\064\166\312\174\360\024\270\004\356\004\010\360\350\164\164\332\071"
    "\151\144\264\032\205\360\020\135\164\312\162\312\141\202\074\106\225\060\271"
    "\322\005\356\215\340\242\070\315\025\272\251\131\200\201\212\171\137\265\175"
    "\065\136\117\131\333\255\227\241\056\216\150\300\276\352\066\101\067\045\333"
    "\376\015\203\134\262\125\167\321\103\044\066\054\333\113\142\335\246\075\005"
    "\073\133\124\303\366\215\165\175\173\105\003\033\027\060\376\242\060\233\237"
    "\061\204\146\247\002\254\047\250\131\056\312\244\050\346\373\173\275\244\021"
    "\376\132\253\217\250\243\046\016\173\371\142\257\336\256\267\173\375\104\036"
    "\326\171\357\131\172\204\006\347\354\216\206\350\222\103\216\211\274\044\260"
    "\052\167\132\150\052\301\031\104\012\116\302\216\006\143\205\160\201\040\152"
    "\315\225\341\036\214\325\052\323\000\312\152\223\057\364\250\103\151\115\102"
    "\124\040\115\112\336\070\201\350\274\220\110\202\273\027\243\041\336\224\221"
    "\032\274\376\055\030\233\260\201\265\115\206\203\266\137\107\266\051\367\066"
    "\152\154\067\004\335\337\341\161\074\036\130\001\377\277\255\200\357\265\202"
    "\273\346\313\322\071\160\042\037\347\174\364\171\076\313\232\223\051\061\344"
    "\343\213\145\062\167\126\240\175\266\011\005\056\032\162\102\312\322\047\136"
    "\006\351\311\223\215\111\131\213\010\041\162\207\032\263\204\114\026\234\057"
    "\245\116\062\133\207\300\100\345\263\233\137\155\152\363\114\053\110\064\342"
    "\202\101\023\167\172\117\061\005\376\157\115\201\277\274\051\354\343\302\131"
    "\167\067\042\100\152\121\012\222\041\151\141\174\106\104\345\011\101\101\006"
    "\115\126\047\276\343\202\353\074\113\300\020\227\332\113\124\004\062\160\123"
    "\112\037\134\042\112\106\247\074\007\264\216\031\005\023\112\043\271\220\112"
    "\231\220\347\210\214\224\247\310\363\271\370\163\063\330\127\347\237\134\340"
    "\236\344\055\045\031\215\037\127\126\367\072\034\010\000\000";
  static const uint8_t nemu_apt_hello_v1_0_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142\151\156\141"
    "\162\171\040\040\040\061\067\070\061\062\062\062\064\060\060\040\040\060\040"
    "\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040\040\040\064"
    "\040\040\040\040\040\040\040\040\040\140\012\062\056\060\012\143\157\156\164"
    "\162\157\154\056\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062"
    "\064\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063"
    "\061\070\070\040\040\040\062\071\071\040\040\040\040\040\040\040\140\012\037"
    "\213\010\000\000\000\000\000\002\377\355\320\301\112\003\061\020\006\340\075"
    "\347\051\346\005\272\156\161\333\102\021\261\240\240\207\112\241\325\373\230"
    "\035\335\320\064\131\222\264\250\117\157\332\265\075\364\256\010\376\037\204"
    "\044\103\370\047\111\171\241\275\113\301\333\342\347\124\331\270\256\017\163"
    "\166\076\127\365\350\362\264\356\353\223\121\065\051\250\052\176\301\066\046"
    "\016\271\145\361\077\055\130\257\371\115\246\344\144\263\035\264\076\046\053"
    "\061\016\132\261\326\253\147\011\321\170\067\245\141\131\251\131\320\255\111"
    "\242\323\066\344\343\301\104\275\033\327\152\316\306\245\074\044\114\351\361"
    "\156\376\104\367\337\021\064\353\022\135\355\123\157\344\235\067\235\225\322"
    "\270\035\133\323\134\253\007\227\077\335\132\151\006\113\363\231\303\206\152"
    "\231\163\017\235\136\070\212\132\004\343\203\111\037\123\362\335\276\314\126"
    "\335\112\324\301\164\375\241\103\243\343\135\211\163\043\323\047\122\334\370"
    "\265\120\327\077\112\321\252\065\361\270\243\056\370\235\104\112\055\247\263"
    "\204\331\142\105\232\035\275\112\322\055\261\153\116\171\114\101\330\122\043"
    "\057\245\052\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
    "\000\000\376\222\057\326\102\273\100\000\050\000\000\012\144\141\164\141\056"
    "\164\141\162\056\147\172\040\040\040\040\040\061\067\070\061\062\062\062\064"
    "\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063\061"
    "\070\070\040\040\040\061\070\063\040\040\040\040\040\040\040\140\012\037\213"
    "\010\000\000\000\000\000\002\377\355\321\073\022\202\060\024\106\341\324\256"
    "\042\033\200\204\107\314\012\054\265\163\001\051\242\024\040\116\002\373\067"
    "\303\214\015\243\225\003\342\170\276\346\277\335\055\116\256\306\030\224\130"
    "\224\116\254\061\323\046\363\175\161\357\155\121\011\151\304\012\306\070\270"
    "\220\136\212\377\224\117\375\143\343\202\127\233\351\137\150\135\030\372\257"
    "\335\377\346\273\061\153\372\070\264\076\306\254\361\155\333\253\357\364\257"
    "\154\131\323\177\013\375\273\164\272\253\377\270\377\276\256\337\367\257\314"
    "\254\277\051\155\041\244\246\377\342\246\312\362\022\372\116\236\016\307\263"
    "\174\346\227\356\076\354\004\000\000\000\000\000\000\000\000\000\000\000\370"
    "\005\017\166\356\224\046\000\050\000\000\012";
  static const uint8_t nemu_apt_meta_v1_0_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142\151\156\141"
    "\162\171\040\040\040\061\067\070\061\062\062\062\064\060\060\040\040\060\040"
    "\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040\040\040\064"
    "\040\040\040\040\040\040\040\040\040\140\012\062\056\060\012\143\157\156\164"
    "\162\157\154\056\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062"
    "\064\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063"
    "\061\070\070\040\040\040\064\071\062\040\040\040\040\040\040\040\140\012\037"
    "\213\010\000\000\000\000\000\002\377\355\225\335\213\023\061\020\300\373\234"
    "\277\142\104\244\372\260\237\267\155\241\350\341\201\202\076\234\034\234\372"
    "\344\113\272\073\347\206\146\223\220\244\345\316\277\336\354\166\353\303\172"
    "\132\050\156\217\342\374\240\354\007\331\231\051\311\157\046\116\112\255\274"
    "\325\162\062\036\151\140\136\024\335\065\060\274\246\263\074\377\165\277\173"
    "\277\230\245\305\004\322\311\011\330\070\317\155\110\071\371\077\271\341\345"
    "\232\177\307\045\050\154\066\121\255\235\227\350\134\324\240\347\354\053\132"
    "\047\264\132\102\026\247\354\312\226\265\360\130\372\215\015\253\255\160\345"
    "\166\136\260\153\056\224\017\077\264\113\370\364\376\372\013\174\350\043\300"
    "\225\361\360\272\015\372\026\357\171\143\044\306\102\155\271\024\325\045\173"
    "\207\006\125\345\206\071\153\224\122\303\313\067\155\272\127\354\243\012\033"
    "\043\045\126\321\255\370\021\062\146\354\066\044\357\312\131\161\207\354\306"
    "\012\155\205\177\130\202\066\355\153\056\103\134\127\132\141\166\213\272\152"
    "\366\261\201\207\152\252\056\055\252\362\001\134\243\327\010\146\367\337\031"
    "\174\256\205\333\077\365\313\034\150\365\150\175\136\203\261\172\213\303\220"
    "\142\127\157\314\316\153\377\343\304\130\154\153\037\331\377\305\154\366\107"
    "\377\363\213\337\375\317\062\362\377\024\074\177\226\254\204\112\134\315\034"
    "\172\210\220\065\353\112\130\210\014\044\133\156\023\051\126\311\043\235\301"
    "\330\240\375\035\114\137\270\157\152\012\323\376\010\301\235\325\315\100\274"
    "\166\371\024\056\377\022\154\177\000\303\203\163\255\216\170\057\074\244\154"
    "\102\234\306\377\260\031\343\066\200\303\376\027\103\377\027\131\116\376\237"
    "\217\377\375\021\072\266\001\364\237\123\007\170\242\371\157\233\121\163\034"
    "\364\077\237\017\375\317\302\162\362\377\214\346\277\155\216\237\376\266\041"
    "\363\237\166\376\217\333\000\016\317\377\164\350\377\105\261\040\377\317\152"
    "\376\037\337\000\272\217\251\003\020\004\101\020\004\101\020\004\101\020\004"
    "\101\020\004\101\374\133\176\002\051\352\321\271\000\050\000\000\144\141\164"
    "\141\056\164\141\162\056\147\172\040\040\040\040\040\061\067\070\061\062\062"
    "\062\064\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063"
    "\063\061\070\070\040\040\040\061\070\064\040\040\040\040\040\040\040\140\012"
    "\037\213\010\000\000\000\000\000\002\377\355\323\061\016\202\060\024\200\341"
    "\316\236\242\027\200\322\100\341\004\216\272\171\200\016\125\006\052\111\013"
    "\367\267\220\270\020\235\014\210\361\377\226\367\266\067\374\171\271\032\143"
    "\120\142\125\105\322\030\063\317\144\071\137\354\165\243\113\041\215\330\300"
    "\030\007\033\322\111\361\237\362\271\177\154\155\160\152\067\375\165\121\150"
    "\103\377\255\373\337\235\037\263\266\217\103\347\142\314\274\033\254\372\122"
    "\377\322\124\015\375\167\320\337\247\315\336\334\347\375\353\252\172\337\277"
    "\254\027\375\215\236\376\277\240\377\352\132\327\165\275\274\206\336\313\363"
    "\361\164\221\317\374\162\312\177\020\000\000\000\000\000\000\000\000\000\000"
    "\000\340\007\074\000\361\046\313\375\000\050\000\000";
  static const uint8_t nemu_apt_hello_v1_1_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142\151\156\141"
    "\162\171\040\040\040\061\067\070\061\062\062\062\064\060\060\040\040\060\040"
    "\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040\040\040\064"
    "\040\040\040\040\040\040\040\040\040\140\012\062\056\060\012\143\157\156\164"
    "\162\157\154\056\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062"
    "\064\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063"
    "\061\070\070\040\040\040\062\071\064\040\040\040\040\040\040\040\140\012\037"
    "\213\010\000\000\000\000\000\002\377\355\320\321\112\303\060\024\006\340\136"
    "\347\051\316\013\254\266\120\047\024\021\013\012\172\061\031\154\172\237\245"
    "\207\065\054\113\102\222\016\365\351\315\066\267\213\335\053\202\377\007\041"
    "\311\041\374\047\111\171\245\234\115\301\231\342\347\124\331\264\151\016\163"
    "\166\071\127\115\123\237\327\307\372\315\165\325\024\124\025\277\140\214\111"
    "\206\334\262\370\237\346\122\155\344\232\133\262\274\035\047\203\213\311\160"
    "\214\223\201\215\161\342\215\103\324\316\266\124\227\265\350\202\032\164\142"
    "\225\306\220\217\007\035\325\156\332\210\231\324\066\345\301\241\245\227\307"
    "\331\053\075\175\107\120\347\023\335\356\123\357\371\135\156\275\341\122\333"
    "\235\064\272\277\023\317\066\177\272\061\334\117\026\372\063\207\325\142\221"
    "\163\017\235\126\062\262\230\007\355\202\116\037\055\071\277\057\113\043\036"
    "\070\252\240\375\361\320\241\321\351\256\044\163\243\321\257\203\354\231\342"
    "\326\155\230\374\361\121\202\226\203\216\247\035\371\340\166\034\051\015\062"
    "\135\044\164\363\045\051\151\317\051\222\002\113\103\075\257\112\121\000\000"
    "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\374\115\137"
    "\213\375\232\270\000\050\000\000\144\141\164\141\056\164\141\162\056\147\172"
    "\040\040\040\040\040\061\067\070\061\062\062\062\064\060\060\040\040\060\040"
    "\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040\040\040\061"
    "\070\067\040\040\040\040\040\040\040\140\012\037\213\010\000\000\000\000\000"
    "\002\377\355\321\061\016\202\060\030\206\341\316\236\242\027\200\122\154\351"
    "\011\034\165\363\000\035\252\014\040\206\202\347\267\041\161\041\072\031\220"
    "\304\367\131\276\177\373\207\067\127\143\354\225\130\124\221\070\153\247\115"
    "\346\373\346\256\234\336\013\151\305\012\306\070\370\076\275\024\377\051\237"
    "\372\307\332\367\101\155\246\277\056\012\155\351\277\166\377\133\150\307\254"
    "\356\342\320\204\030\263\072\064\115\247\176\323\177\357\112\103\377\055\364"
    "\157\323\351\257\341\353\376\225\061\237\373\233\162\326\337\226\225\023\262"
    "\240\377\342\246\312\362\322\167\255\074\035\216\147\371\312\057\375\175\220"
    "\017\235\353\235\000\000\000\000\000\000\000\000\000\000\000\000\033\367\004"
    "\374\041\063\101\000\050\000\000\012";
  static const uint8_t nemu_apt_meta_v1_1_deb[] =
    "\041\074\141\162\143\150\076\012\144\145\142\151\141\156\055\142\151\156\141"
    "\162\171\040\040\040\061\067\070\061\062\062\062\064\060\060\040\040\060\040"
    "\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040\040\040\064"
    "\040\040\040\040\040\040\040\040\040\140\012\062\056\060\012\143\157\156\164"
    "\162\157\154\056\164\141\162\056\147\172\040\040\061\067\070\061\062\062\062"
    "\064\060\060\040\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063"
    "\061\070\070\040\040\040\065\060\065\040\040\040\040\040\040\040\140\012\037"
    "\213\010\000\000\000\000\000\002\377\355\225\113\213\333\060\020\200\163\326"
    "\257\230\122\112\332\203\137\033\073\201\320\056\135\150\241\075\154\131\330"
    "\266\247\136\024\173\166\055\142\113\102\122\314\156\177\175\145\307\056\305"
    "\175\344\220\072\045\164\076\010\176\060\231\021\226\276\231\060\312\225\164"
    "\106\125\263\351\210\075\313\064\355\256\236\361\065\316\056\226\337\357\367"
    "\357\127\131\022\317\040\236\235\200\235\165\334\370\222\263\377\223\033\236"
    "\157\371\075\256\101\142\275\013\112\145\135\205\326\006\065\072\316\076\243"
    "\261\102\311\065\044\141\302\256\114\136\012\207\271\333\031\037\155\204\315"
    "\233\145\312\256\271\220\316\377\320\254\341\303\333\353\117\360\256\317\000"
    "\127\332\301\313\066\351\153\174\340\265\256\060\024\262\341\225\050\056\331"
    "\033\324\050\013\073\256\131\142\125\051\170\376\252\055\367\202\275\227\176"
    "\143\252\012\213\340\126\174\365\025\023\166\353\213\167\313\331\160\213\354"
    "\306\010\145\204\173\134\203\322\355\153\136\371\274\066\067\102\357\203\272"
    "\325\014\271\201\373\325\354\364\275\341\005\102\321\225\107\231\077\202\255"
    "\325\026\101\357\277\001\203\217\245\260\303\123\037\146\101\111\160\045\016"
    "\377\056\140\277\314\041\312\371\133\243\032\374\261\102\310\316\147\377\303"
    "\110\033\024\376\133\117\354\377\052\313\176\353\377\305\142\365\263\377\113"
    "\362\377\024\074\175\022\155\204\214\154\311\054\072\010\220\325\333\102\030"
    "\010\064\104\015\067\121\045\066\321\057\072\203\066\136\373\073\230\077\263"
    "\137\344\034\346\375\021\202\073\243\352\221\170\155\070\064\336\350\071\134"
    "\376\041\343\160\012\375\203\265\255\213\370\040\034\304\154\106\114\356\277"
    "\337\207\151\033\300\101\377\323\144\354\377\212\346\377\071\371\337\037\241"
    "\243\032\100\237\203\072\300\351\347\277\251\047\255\161\170\376\057\306\376"
    "\047\331\202\374\077\247\371\157\352\043\247\277\251\311\374\177\066\377\247"
    "\155\000\207\375\317\306\376\057\262\224\374\077\253\371\177\144\003\350\062"
    "\120\007\040\010\202\040\010\202\040\010\202\040\010\202\040\010\202\370\153"
    "\174\003\173\264\303\004\000\050\000\000\012\144\141\164\141\056\164\141\162"
    "\056\147\172\040\040\040\040\040\061\067\070\061\062\062\062\064\060\060\040"
    "\040\060\040\040\040\040\040\060\040\040\040\040\040\063\063\061\070\070\040"
    "\040\040\061\070\070\040\040\040\040\040\040\040\140\012\037\213\010\000\000"
    "\000\000\000\002\377\355\324\061\016\202\060\024\200\341\316\236\242\027\200"
    "\322\320\302\011\034\165\363\000\035\252\014\124\022\012\236\337\102\342\102"
    "\164\062\040\211\377\267\274\267\275\341\117\136\256\306\330\053\261\252\042"
    "\251\255\235\147\262\234\157\366\252\326\245\220\126\154\140\214\203\353\323"
    "\111\361\237\362\271\177\154\134\357\325\156\372\353\242\320\226\376\133\367"
    "\277\373\060\146\115\027\207\326\307\230\005\077\070\365\243\376\245\065\065"
    "\375\167\320\077\244\315\335\374\367\375\053\143\076\367\067\345\242\277\325"
    "\323\377\057\350\277\272\306\267\155\047\257\175\027\344\371\170\272\310\127"
    "\176\071\345\227\017\235\353\203\000\000\000\000\000\000\000\000\000\000\000"
    "\000\373\366\004\224\343\074\273\000\050\000\000";
  static const char http_get_prefix[] = "GET ";
  static const char http_head_prefix[] = "HEAD ";
  static const char http_health_path[] = "/nemu-health";
  static const char http_large_path[] = "/nemu-large";
  static const char http_apt_release_path[] = "/ubuntu/dists/jammy/Release";
  static const char http_apt_inrelease_path[] = "/ubuntu/dists/jammy/InRelease";
  static const char http_apt_keyring_path[] =
    "/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg";
  static const char http_apt_packages_path[] =
    "/ubuntu/dists/jammy/main/binary-riscv64/Packages";
  static const char http_apt_packages_gz_path[] =
    "/ubuntu/dists/jammy/main/binary-riscv64/Packages.gz";
  static const char http_apt_hello_v1_0_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-hello/"
    "nemu-hostless-hello_1.0_riscv64.deb";
  static const char http_apt_meta_v1_0_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-meta/"
    "nemu-hostless-meta_1.0_riscv64.deb";
  static const char http_apt_hello_v1_1_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-hello/"
    "nemu-hostless-hello_1.1_riscv64.deb";
  static const char http_apt_meta_v1_1_deb_path[] =
    "/ubuntu/pool/main/n/nemu-hostless-meta/"
    "nemu-hostless-meta_1.1_riscv64.deb";

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
  bool is_apt_inrelease = path_len == sizeof(http_apt_inrelease_path) - 1 &&
    memcmp(payload + path_off, http_apt_inrelease_path, sizeof(http_apt_inrelease_path) - 1) == 0;
  bool is_apt_keyring = path_len == sizeof(http_apt_keyring_path) - 1 &&
    memcmp(payload + path_off, http_apt_keyring_path,
        sizeof(http_apt_keyring_path) - 1) == 0;
  bool is_apt_packages = path_len == sizeof(http_apt_packages_path) - 1 &&
    memcmp(payload + path_off, http_apt_packages_path, sizeof(http_apt_packages_path) - 1) == 0;
  bool is_apt_packages_gz = path_len == sizeof(http_apt_packages_gz_path) - 1 &&
    memcmp(payload + path_off, http_apt_packages_gz_path,
        sizeof(http_apt_packages_gz_path) - 1) == 0;
  bool is_apt_hello_v1_0_deb = path_len == sizeof(http_apt_hello_v1_0_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_hello_v1_0_deb_path,
        sizeof(http_apt_hello_v1_0_deb_path) - 1) == 0;
  bool is_apt_meta_v1_0_deb = path_len == sizeof(http_apt_meta_v1_0_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_meta_v1_0_deb_path,
        sizeof(http_apt_meta_v1_0_deb_path) - 1) == 0;
  bool is_apt_hello_v1_1_deb = path_len == sizeof(http_apt_hello_v1_1_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_hello_v1_1_deb_path,
        sizeof(http_apt_hello_v1_1_deb_path) - 1) == 0;
  bool is_apt_meta_v1_1_deb = path_len == sizeof(http_apt_meta_v1_1_deb_path) - 1 &&
    memcmp(payload + path_off, http_apt_meta_v1_1_deb_path,
        sizeof(http_apt_meta_v1_1_deb_path) - 1) == 0;
  bool is_apt_deb = is_apt_hello_v1_0_deb || is_apt_meta_v1_0_deb ||
    is_apt_hello_v1_1_deb || is_apt_meta_v1_1_deb;
  bool is_known_path = is_health || is_large || is_apt_release || is_apt_inrelease ||
    is_apt_keyring || is_apt_packages || is_apt_packages_gz || is_apt_deb;

  // 这是 hostless TCP 探针，不是通用 HTTP server；只覆盖健康检查、
  // 多段响应、最小 APT 元数据/包下载和 404 错误路径，避免把它误称为
  // TAP/NAT/外网能力。
  net_stats.tcp_http_requests++;
  if (is_head) {
    net_stats.tcp_http_head_requests++;
  }
  if (is_apt_release || is_apt_inrelease || is_apt_keyring ||
      is_apt_packages || is_apt_packages_gz || is_apt_deb) {
    net_stats.tcp_http_apt_requests++;
  }
  if (is_apt_deb) {
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
  } else if (is_apt_inrelease) {
    status = "200 OK";
    content_type = "text/plain";
    body = nemu_apt_inrelease;
    body_len = sizeof(nemu_apt_inrelease) - 1;
  } else if (is_apt_keyring) {
    status = "200 OK";
    content_type = "application/octet-stream";
    body = nemu_apt_keyring;
    body_len = sizeof(nemu_apt_keyring) - 1;
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
  } else if (is_apt_hello_v1_0_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_hello_v1_0_deb;
    body_len = sizeof(nemu_apt_hello_v1_0_deb) - 1;
  } else if (is_apt_meta_v1_0_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_meta_v1_0_deb;
    body_len = sizeof(nemu_apt_meta_v1_0_deb) - 1;
  } else if (is_apt_hello_v1_1_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_hello_v1_1_deb;
    body_len = sizeof(nemu_apt_hello_v1_1_deb) - 1;
  } else if (is_apt_meta_v1_1_deb) {
    status = "200 OK";
    content_type = "application/vnd.debian.binary-package";
    body = nemu_apt_meta_v1_1_deb;
    body_len = sizeof(nemu_apt_meta_v1_1_deb) - 1;
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
        !virtio_net_handle_dns(frame, len) &&
        !virtio_net_handle_ntp(frame, len)) {
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
    if (virtio_net_tap_enabled()) {
      virtio_net_tap_tx(frame, frame_len);
    } else {
      virtio_net_handle_frame(frame, frame_len);
    }
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
      paddr_dma_write_value(descs[i].addr, 1, ack);
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

  bool tap_enabled = virtio_net_tap_enabled();
  fprintf(out, "device.virtio_net.backend=%s\n", virtio_net_backend_name());
  fprintf(out, "device.virtio_net.host_packet_backend=%s\n",
      tap_enabled ? "tap" : "unsupported");
  fprintf(out, "device.virtio_net.tap=%s\n", tap_enabled ? "enabled" : "unsupported");
  fprintf(out, "device.virtio_net.tap.ifname=%s\n",
      tap_enabled ? tap_ifname : "none");
  fprintf(out, "device.virtio_net.slirp_nat=unsupported\n");
  fprintf(out, "device.virtio_net.host_port_forward=unsupported\n");
  fprintf(out, "device.virtio_net.external_network=%s\n",
      tap_enabled ? "tap-config-dependent" : "unsupported");
  fprintf(out, "device.virtio_net.external_mirror=%s\n",
      tap_enabled ? "tap-config-dependent" : "unsupported");
  fprintf(out, "device.virtio_net.mac=%s\n", mac);
  fprintf(out, "device.virtio_net.host_mac=%s\n", host_mac);
  fprintf(out, "device.virtio_net.host_ip=%s\n", host_ip);
  fprintf(out, "device.virtio_net.guest_ip=%s\n", guest_ip);
  fprintf(out, "device.virtio_net.subnet_mask=%s\n", subnet_mask);
  fprintf(out, "device.virtio_net.link_up=1\n");
  fprintf(out, "device.virtio_net.dhcp=hostless\n");
  fprintf(out, "device.virtio_net.dns=nemu.local\n");
  fprintf(out, "device.virtio_net.ntp=hostless 10.0.2.2:123\n");
  fprintf(out, "device.virtio_net.icmp_echo=hostless\n");
  fprintf(out, "device.virtio_net.tcp_http=/nemu-health\n");
  fprintf(out, "device.virtio_net.tcp_http_head=/nemu-health\n");
  fprintf(out, "device.virtio_net.tcp_http_404=enabled\n");
  fprintf(out, "device.virtio_net.tcp_http_large=/nemu-large bytes=4096\n");
  fprintf(out, "device.virtio_net.tcp_http_segment_payload_max=%u\n",
      VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX);
  fprintf(out, "device.virtio_net.tcp_http_apt_repo=/ubuntu jammy main\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_signed_repo=InRelease signed-by=/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg key-fingerprint=E6742789E6F3AAEAD748589209108C9EAFAA6C14\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_package=nemu-hostless-hello 1.0/1.1 riscv64\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_meta_package=nemu-hostless-meta 1.0/1.1 riscv64 depends=nemu-hostless-hello (= matching-version)\n");
  fprintf(out, "device.virtio_net.tcp_http_apt_upgrade=nemu-hostless-meta 1.0->1.1\n");
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
  fprintf(out, "device.virtio_net.stats.ntp_requests=%" PRIu64 "\n",
      net_stats.ntp_requests);
  fprintf(out, "device.virtio_net.stats.ntp_replies=%" PRIu64 "\n",
      net_stats.ntp_replies);
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
  fprintf(out, "device.virtio_net.stats.tap_tx_packets=%" PRIu64 "\n",
      net_stats.tap_tx_packets);
  fprintf(out, "device.virtio_net.stats.tap_tx_bytes=%" PRIu64 "\n",
      net_stats.tap_tx_bytes);
  fprintf(out, "device.virtio_net.stats.tap_tx_errors=%" PRIu64 "\n",
      net_stats.tap_tx_errors);
  fprintf(out, "device.virtio_net.stats.tap_rx_packets=%" PRIu64 "\n",
      net_stats.tap_rx_packets);
  fprintf(out, "device.virtio_net.stats.tap_rx_bytes=%" PRIu64 "\n",
      net_stats.tap_rx_bytes);
  fprintf(out, "device.virtio_net.stats.tap_rx_errors=%" PRIu64 "\n",
      net_stats.tap_rx_errors);
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

  bool tap_enabled = virtio_net_tap_enabled();
  const char *hostless_bool = tap_enabled ? "false" : "true";

  /*
   * 默认 backend 仍是 hostless-responder；只有显式 --net-tap 成功打开后，
   * QMP 才报告 TAP packet backend，避免把未配置的宿主网络写成已完成。
   */
  snprintf(out, out_size,
      "{\"return\":[{\"id\":\"net0\",\"type\":\"%s\","
      "\"peer\":\"virtio-net0\",\"nemu\":{\"backend\":\"%s\","
      "\"host-packet-backend\":%s,\"tap\":%s,\"tap-ifname\":\"%s\","
      "\"slirp-nat\":false,"
      "\"host-port-forward\":false,\"external-network\":false,"
      "\"external-mirror\":false,"
      "\"model\":\"virtio-net-mmio\",\"mac\":\"%s\",\"host-mac\":\"%s\","
      "\"host-ip\":\"%s\",\"guest-ip\":\"%s\",\"subnet-mask\":\"%s\","
      "\"dhcp\":%s,\"dns\":%s,\"ntp\":%s,\"ntp-server\":\"10.0.2.2\","
      "\"icmp\":%s,\"tcp-http\":%s,"
      "\"http-methods\":[\"GET\",\"HEAD\"],\"http-not-found\":true,"
      "\"http-large\":{\"path\":\"/nemu-large\",\"bytes\":4096,"
      "\"segment-payload-max\":%u},"
      "\"apt-repo\":{\"base\":\"/ubuntu\",\"suite\":\"jammy\","
      "\"component\":\"main\",\"arch\":\"riscv64\","
      "\"signed\":true,\"inrelease\":\"/ubuntu/dists/jammy/InRelease\","
      "\"signed-by\":\"/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg\","
      "\"key-fingerprint\":\"E6742789E6F3AAEAD748589209108C9EAFAA6C14\","
      "\"package\":\"nemu-hostless-hello\",\"version\":\"1.0\","
      "\"deb-size\":676,\"upgrade-version\":\"1.1\","
      "\"upgrade-deb-size\":674,\"meta-package\":\"nemu-hostless-meta\","
      "\"meta-version\":\"1.0\","
      "\"meta-depends\":\"nemu-hostless-hello (= 1.0)\","
      "\"meta-deb-size\":868,\"meta-upgrade-version\":\"1.1\","
      "\"meta-upgrade-depends\":\"nemu-hostless-hello (= 1.1)\","
      "\"meta-upgrade-deb-size\":886},"
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
      "\"ntp-requests\":%" PRIu64 ",\"ntp-replies\":%" PRIu64 ","
      "\"tcp-segments\":%" PRIu64 ",\"tcp-replies\":%" PRIu64 ","
      "\"tcp-http-requests\":%" PRIu64 ","
      "\"tcp-http-head-requests\":%" PRIu64 ","
      "\"tcp-http-not-found\":%" PRIu64 ","
      "\"tcp-http-apt-requests\":%" PRIu64 ","
      "\"tcp-http-apt-deb-requests\":%" PRIu64 ","
      "\"tcp-http-large-requests\":%" PRIu64 ","
      "\"tcp-http-segmented-responses\":%" PRIu64 ","
      "\"tcp-http-response-segments\":%" PRIu64 ","
      "\"tap-tx-packets\":%" PRIu64 ",\"tap-tx-bytes\":%" PRIu64 ","
      "\"tap-tx-errors\":%" PRIu64 ",\"tap-rx-packets\":%" PRIu64 ","
      "\"tap-rx-bytes\":%" PRIu64 ",\"tap-rx-errors\":%" PRIu64 ","
      "\"ctrl-commands\":%" PRIu64 ","
      "\"ctrl-rx-commands\":%" PRIu64 ",\"ctrl-rx-extra-commands\":%" PRIu64 ","
      "\"ctrl-mac-table-commands\":%" PRIu64 ","
      "\"ctrl-mac-addr-commands\":%" PRIu64 ","
      "\"ctrl-vlan-commands\":%" PRIu64 ","
      "\"ctrl-announce-commands\":%" PRIu64 ","
      "\"ctrl-errors\":%" PRIu64 "}}}]}",
      tap_enabled ? "tap" : "hostless",
      virtio_net_backend_name(),
      tap_enabled ? "true" : "false",
      tap_enabled ? "true" : "false",
      tap_enabled ? tap_ifname : "none",
      mac, host_mac, host_ip, guest_ip, subnet_mask,
      hostless_bool, hostless_bool, hostless_bool, hostless_bool, hostless_bool,
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
      net_stats.ntp_requests, net_stats.ntp_replies,
      net_stats.tcp_segments, net_stats.tcp_replies,
      net_stats.tcp_http_requests, net_stats.tcp_http_head_requests,
      net_stats.tcp_http_not_found, net_stats.tcp_http_apt_requests,
      net_stats.tcp_http_apt_deb_requests,
      net_stats.tcp_http_large_requests,
      net_stats.tcp_http_segmented_responses,
      net_stats.tcp_http_response_segments,
      net_stats.tap_tx_packets, net_stats.tap_tx_bytes,
      net_stats.tap_tx_errors, net_stats.tap_rx_packets,
      net_stats.tap_rx_bytes, net_stats.tap_rx_errors,
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
      " ntp=%" PRIu64 "/%" PRIu64
      " tcp_segments=%" PRIu64 " tcp_replies=%" PRIu64
      " tcp_http_requests=%" PRIu64
      " tcp_http_head_requests=%" PRIu64
      " tcp_http_not_found=%" PRIu64
      " tcp_http_apt_requests=%" PRIu64
      " tcp_http_apt_deb_requests=%" PRIu64
      " tcp_http_large_requests=%" PRIu64
      " tcp_http_segmented_responses=%" PRIu64
      " tcp_http_response_segments=%" PRIu64
      " tap_tx=%" PRIu64 "/%" PRIu64 "/%" PRIu64
      " tap_rx=%" PRIu64 "/%" PRIu64 "/%" PRIu64
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
      net_stats.ntp_requests, net_stats.ntp_replies,
      net_stats.tcp_segments, net_stats.tcp_replies,
      net_stats.tcp_http_requests,
      net_stats.tcp_http_head_requests,
      net_stats.tcp_http_not_found,
      net_stats.tcp_http_apt_requests,
      net_stats.tcp_http_apt_deb_requests,
      net_stats.tcp_http_large_requests,
      net_stats.tcp_http_segmented_responses,
      net_stats.tcp_http_response_segments,
      net_stats.tap_tx_packets, net_stats.tap_tx_bytes, net_stats.tap_tx_errors,
      net_stats.tap_rx_packets, net_stats.tap_rx_bytes, net_stats.tap_rx_errors,
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
  virtio_net_tap_open_if_requested();
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("virtio-net", DEV_VIRTIO_NET_MMIO, net_base, 0x1000,
      virtio_net_io_handler);
#else
  add_mmio_map("virtio-net", DEV_VIRTIO_NET_MMIO, net_base, 0x1000,
      virtio_net_io_handler);
#endif
}
