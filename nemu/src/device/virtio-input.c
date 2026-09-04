/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <device/virtio.h>
#include <isa.h>
#include <memory/host.h>
#include <memory/paddr.h>
#include <utils.h>

#include <SDL2/SDL.h>
#include <inttypes.h>
#include <linux/input-event-codes.h>
#include <stdio.h>
#include <string.h>

/*
 * 这里实现 Virtio 1.x input device 的键盘子集。Linux 通过配置区发现
 * EV_KEY/EV_REP 能力，通过 eventq 接收按键，通过 statusq 回送 LED/重复
 * 参数等状态。宿主输入只来自 SDL；不把 legacy AM 键码泄漏到该标准 ABI。
 */
#define VIRTIO_INPUT_QUEUE_EVENT 0u
#define VIRTIO_INPUT_QUEUE_STATUS 1u
#define VIRTIO_INPUT_QUEUE_COUNT 2u
#define VIRTIO_INPUT_QUEUE_SIZE 64u
#define VIRTIO_INPUT_MAX_CHAIN VIRTIO_INPUT_QUEUE_SIZE
#define VIRTIO_INPUT_IRQ 7u
#define VIRTIO_INPUT_EVENT_BYTES 8u
#define VIRTIO_INPUT_CONFIG_PAYLOAD_BYTES 128u
#define VIRTIO_INPUT_EVENT_FIFO_CAPACITY 1024u
#define VIRTIO_INPUT_NAME "NEMU SDL virtio keyboard"
#define VIRTIO_INPUT_SERIAL "nemu-virtio-input0"
#define VIRTIO_INPUT_BUS_VIRTUAL 0x06u
#define VIRTIO_INPUT_VENDOR 0x5958u
#define VIRTIO_INPUT_PRODUCT 0x0001u
#define VIRTIO_INPUT_VERSION 0x0001u

enum {
  VIRTIO_INPUT_CFG_UNSET = 0x00,
  VIRTIO_INPUT_CFG_ID_NAME = 0x01,
  VIRTIO_INPUT_CFG_ID_SERIAL = 0x02,
  VIRTIO_INPUT_CFG_ID_DEVIDS = 0x03,
  VIRTIO_INPUT_CFG_PROP_BITS = 0x10,
  VIRTIO_INPUT_CFG_EV_BITS = 0x11,
  VIRTIO_INPUT_CFG_ABS_INFO = 0x12,
};

enum {
  VIRTIO_INPUT_CONFIG_SELECT = 0,
  VIRTIO_INPUT_CONFIG_SUBSEL = 1,
  VIRTIO_INPUT_CONFIG_SIZE = 2,
  VIRTIO_INPUT_CONFIG_PAYLOAD = 8,
  VIRTIO_INPUT_CONFIG_BYTES =
      VIRTIO_INPUT_CONFIG_PAYLOAD + VIRTIO_INPUT_CONFIG_PAYLOAD_BYTES,
};

enum {
  VIRTIO_INPUT_EV_SYN = 0x00,
  VIRTIO_INPUT_EV_KEY = 0x01,
  VIRTIO_INPUT_EV_REP = 0x14,
  VIRTIO_INPUT_SYN_REPORT = 0,
};

typedef struct {
  uint16_t type;
  uint16_t code;
  uint32_t value;
} VirtioInputEvent;

typedef struct {
  uint64_t key_transitions;
  uint64_t events_delivered;
  uint64_t status_events;
  uint64_t dropped_not_ready;
  uint64_t dropped_fifo_full;
  uint64_t invalid_event_buffers;
  uint64_t invalid_status_buffers;
} VirtioInputStats;

_Static_assert(sizeof(VirtioInputEvent) == VIRTIO_INPUT_EVENT_BYTES,
    "virtio_input_event 必须保持 8 字节 wire layout");
_Static_assert(VIRTIO_INPUT_CONFIG_BYTES == 136,
    "virtio_input_config 必须保持 Linux UAPI 的 136 字节布局");

static uint8_t *input_base;
static VirtioMmioTransportState transport;
static VirtqueueState queues[VIRTIO_INPUT_QUEUE_COUNT];
static VirtioInputEvent pending_events[VIRTIO_INPUT_EVENT_FIFO_CAPACITY];
static uint32_t pending_head;
static uint32_t pending_tail;
static uint32_t pending_count;
static uint8_t key_bitmap[VIRTIO_INPUT_CONFIG_PAYLOAD_BYTES];
static uint8_t key_bitmap_size;
static uint32_t advertised_key_count;
static VirtioInputStats input_stats;
static int invalid_log_budget = 32;

/*
 * SDL scancode 0..255 沿用 USB HID keyboard usage；以下映射与 Linux
 * input-event-codes ABI 对齐。高位 consumer scancode 单独映射到等价 KEY_*。
 * 数组中 0 表示该宿主按键不作为 virtio-input 能力暴露。
 */
static const uint16_t sdl_to_linux_key[SDL_NUM_SCANCODES] = {
  [SDL_SCANCODE_A] = KEY_A,
  [SDL_SCANCODE_B] = KEY_B,
  [SDL_SCANCODE_C] = KEY_C,
  [SDL_SCANCODE_D] = KEY_D,
  [SDL_SCANCODE_E] = KEY_E,
  [SDL_SCANCODE_F] = KEY_F,
  [SDL_SCANCODE_G] = KEY_G,
  [SDL_SCANCODE_H] = KEY_H,
  [SDL_SCANCODE_I] = KEY_I,
  [SDL_SCANCODE_J] = KEY_J,
  [SDL_SCANCODE_K] = KEY_K,
  [SDL_SCANCODE_L] = KEY_L,
  [SDL_SCANCODE_M] = KEY_M,
  [SDL_SCANCODE_N] = KEY_N,
  [SDL_SCANCODE_O] = KEY_O,
  [SDL_SCANCODE_P] = KEY_P,
  [SDL_SCANCODE_Q] = KEY_Q,
  [SDL_SCANCODE_R] = KEY_R,
  [SDL_SCANCODE_S] = KEY_S,
  [SDL_SCANCODE_T] = KEY_T,
  [SDL_SCANCODE_U] = KEY_U,
  [SDL_SCANCODE_V] = KEY_V,
  [SDL_SCANCODE_W] = KEY_W,
  [SDL_SCANCODE_X] = KEY_X,
  [SDL_SCANCODE_Y] = KEY_Y,
  [SDL_SCANCODE_Z] = KEY_Z,
  [SDL_SCANCODE_1] = KEY_1,
  [SDL_SCANCODE_2] = KEY_2,
  [SDL_SCANCODE_3] = KEY_3,
  [SDL_SCANCODE_4] = KEY_4,
  [SDL_SCANCODE_5] = KEY_5,
  [SDL_SCANCODE_6] = KEY_6,
  [SDL_SCANCODE_7] = KEY_7,
  [SDL_SCANCODE_8] = KEY_8,
  [SDL_SCANCODE_9] = KEY_9,
  [SDL_SCANCODE_0] = KEY_0,
  [SDL_SCANCODE_RETURN] = KEY_ENTER,
  [SDL_SCANCODE_ESCAPE] = KEY_ESC,
  [SDL_SCANCODE_BACKSPACE] = KEY_BACKSPACE,
  [SDL_SCANCODE_TAB] = KEY_TAB,
  [SDL_SCANCODE_SPACE] = KEY_SPACE,
  [SDL_SCANCODE_MINUS] = KEY_MINUS,
  [SDL_SCANCODE_EQUALS] = KEY_EQUAL,
  [SDL_SCANCODE_LEFTBRACKET] = KEY_LEFTBRACE,
  [SDL_SCANCODE_RIGHTBRACKET] = KEY_RIGHTBRACE,
  [SDL_SCANCODE_BACKSLASH] = KEY_BACKSLASH,
  [SDL_SCANCODE_NONUSHASH] = KEY_BACKSLASH,
  [SDL_SCANCODE_SEMICOLON] = KEY_SEMICOLON,
  [SDL_SCANCODE_APOSTROPHE] = KEY_APOSTROPHE,
  [SDL_SCANCODE_GRAVE] = KEY_GRAVE,
  [SDL_SCANCODE_COMMA] = KEY_COMMA,
  [SDL_SCANCODE_PERIOD] = KEY_DOT,
  [SDL_SCANCODE_SLASH] = KEY_SLASH,
  [SDL_SCANCODE_CAPSLOCK] = KEY_CAPSLOCK,
  [SDL_SCANCODE_F1] = KEY_F1,
  [SDL_SCANCODE_F2] = KEY_F2,
  [SDL_SCANCODE_F3] = KEY_F3,
  [SDL_SCANCODE_F4] = KEY_F4,
  [SDL_SCANCODE_F5] = KEY_F5,
  [SDL_SCANCODE_F6] = KEY_F6,
  [SDL_SCANCODE_F7] = KEY_F7,
  [SDL_SCANCODE_F8] = KEY_F8,
  [SDL_SCANCODE_F9] = KEY_F9,
  [SDL_SCANCODE_F10] = KEY_F10,
  [SDL_SCANCODE_F11] = KEY_F11,
  [SDL_SCANCODE_F12] = KEY_F12,
  [SDL_SCANCODE_PRINTSCREEN] = KEY_SYSRQ,
  [SDL_SCANCODE_SCROLLLOCK] = KEY_SCROLLLOCK,
  [SDL_SCANCODE_PAUSE] = KEY_PAUSE,
  [SDL_SCANCODE_INSERT] = KEY_INSERT,
  [SDL_SCANCODE_HOME] = KEY_HOME,
  [SDL_SCANCODE_PAGEUP] = KEY_PAGEUP,
  [SDL_SCANCODE_DELETE] = KEY_DELETE,
  [SDL_SCANCODE_END] = KEY_END,
  [SDL_SCANCODE_PAGEDOWN] = KEY_PAGEDOWN,
  [SDL_SCANCODE_RIGHT] = KEY_RIGHT,
  [SDL_SCANCODE_LEFT] = KEY_LEFT,
  [SDL_SCANCODE_DOWN] = KEY_DOWN,
  [SDL_SCANCODE_UP] = KEY_UP,
  [SDL_SCANCODE_NUMLOCKCLEAR] = KEY_NUMLOCK,
  [SDL_SCANCODE_KP_DIVIDE] = KEY_KPSLASH,
  [SDL_SCANCODE_KP_MULTIPLY] = KEY_KPASTERISK,
  [SDL_SCANCODE_KP_MINUS] = KEY_KPMINUS,
  [SDL_SCANCODE_KP_PLUS] = KEY_KPPLUS,
  [SDL_SCANCODE_KP_ENTER] = KEY_KPENTER,
  [SDL_SCANCODE_KP_1] = KEY_KP1,
  [SDL_SCANCODE_KP_2] = KEY_KP2,
  [SDL_SCANCODE_KP_3] = KEY_KP3,
  [SDL_SCANCODE_KP_4] = KEY_KP4,
  [SDL_SCANCODE_KP_5] = KEY_KP5,
  [SDL_SCANCODE_KP_6] = KEY_KP6,
  [SDL_SCANCODE_KP_7] = KEY_KP7,
  [SDL_SCANCODE_KP_8] = KEY_KP8,
  [SDL_SCANCODE_KP_9] = KEY_KP9,
  [SDL_SCANCODE_KP_0] = KEY_KP0,
  [SDL_SCANCODE_KP_PERIOD] = KEY_KPDOT,
  [SDL_SCANCODE_NONUSBACKSLASH] = KEY_102ND,
  [SDL_SCANCODE_APPLICATION] = KEY_COMPOSE,
  [SDL_SCANCODE_POWER] = KEY_POWER,
  [SDL_SCANCODE_KP_EQUALS] = KEY_KPEQUAL,
  [SDL_SCANCODE_F13] = KEY_F13,
  [SDL_SCANCODE_F14] = KEY_F14,
  [SDL_SCANCODE_F15] = KEY_F15,
  [SDL_SCANCODE_F16] = KEY_F16,
  [SDL_SCANCODE_F17] = KEY_F17,
  [SDL_SCANCODE_F18] = KEY_F18,
  [SDL_SCANCODE_F19] = KEY_F19,
  [SDL_SCANCODE_F20] = KEY_F20,
  [SDL_SCANCODE_F21] = KEY_F21,
  [SDL_SCANCODE_F22] = KEY_F22,
  [SDL_SCANCODE_F23] = KEY_F23,
  [SDL_SCANCODE_F24] = KEY_F24,
  [SDL_SCANCODE_EXECUTE] = KEY_OPEN,
  [SDL_SCANCODE_HELP] = KEY_HELP,
  [SDL_SCANCODE_MENU] = KEY_PROPS,
  [SDL_SCANCODE_SELECT] = KEY_FRONT,
  [SDL_SCANCODE_STOP] = KEY_STOP,
  [SDL_SCANCODE_AGAIN] = KEY_AGAIN,
  [SDL_SCANCODE_UNDO] = KEY_UNDO,
  [SDL_SCANCODE_CUT] = KEY_CUT,
  [SDL_SCANCODE_COPY] = KEY_COPY,
  [SDL_SCANCODE_PASTE] = KEY_PASTE,
  [SDL_SCANCODE_FIND] = KEY_FIND,
  [SDL_SCANCODE_MUTE] = KEY_MUTE,
  [SDL_SCANCODE_VOLUMEUP] = KEY_VOLUMEUP,
  [SDL_SCANCODE_VOLUMEDOWN] = KEY_VOLUMEDOWN,
  [SDL_SCANCODE_KP_COMMA] = KEY_KPCOMMA,
  [SDL_SCANCODE_KP_EQUALSAS400] = KEY_KPEQUAL,
  [SDL_SCANCODE_INTERNATIONAL1] = KEY_RO,
  [SDL_SCANCODE_INTERNATIONAL2] = KEY_KATAKANAHIRAGANA,
  [SDL_SCANCODE_INTERNATIONAL3] = KEY_YEN,
  [SDL_SCANCODE_INTERNATIONAL4] = KEY_HENKAN,
  [SDL_SCANCODE_INTERNATIONAL5] = KEY_MUHENKAN,
  [SDL_SCANCODE_INTERNATIONAL6] = KEY_KPJPCOMMA,
  [SDL_SCANCODE_LANG1] = KEY_HANGEUL,
  [SDL_SCANCODE_LANG2] = KEY_HANJA,
  [SDL_SCANCODE_LANG3] = KEY_KATAKANA,
  [SDL_SCANCODE_LANG4] = KEY_HIRAGANA,
  [SDL_SCANCODE_LANG5] = KEY_ZENKAKUHANKAKU,
  [SDL_SCANCODE_ALTERASE] = KEY_ALTERASE,
  [SDL_SCANCODE_SYSREQ] = KEY_SYSRQ,
  [SDL_SCANCODE_CANCEL] = KEY_CANCEL,
  [SDL_SCANCODE_CLEAR] = KEY_CLEAR,
  [SDL_SCANCODE_PRIOR] = KEY_PROPS,
  [SDL_SCANCODE_RETURN2] = KEY_ENTER,
  [SDL_SCANCODE_SEPARATOR] = KEY_KPCOMMA,
  [SDL_SCANCODE_OUT] = KEY_EXIT,
  [SDL_SCANCODE_OPER] = KEY_OPEN,
  [SDL_SCANCODE_CLEARAGAIN] = KEY_AGAIN,
  [SDL_SCANCODE_CRSEL] = KEY_SELECT,
  [SDL_SCANCODE_EXSEL] = KEY_SELECT,
  [SDL_SCANCODE_KP_00] = KEY_KP0,
  [SDL_SCANCODE_KP_000] = KEY_KP0,
  [SDL_SCANCODE_THOUSANDSSEPARATOR] = KEY_KPCOMMA,
  [SDL_SCANCODE_DECIMALSEPARATOR] = KEY_KPDOT,
  [SDL_SCANCODE_CURRENCYUNIT] = KEY_DOLLAR,
  [SDL_SCANCODE_CURRENCYSUBUNIT] = KEY_EURO,
  [SDL_SCANCODE_KP_LEFTPAREN] = KEY_KPLEFTPAREN,
  [SDL_SCANCODE_KP_RIGHTPAREN] = KEY_KPRIGHTPAREN,
  [SDL_SCANCODE_KP_TAB] = KEY_TAB,
  [SDL_SCANCODE_KP_BACKSPACE] = KEY_BACKSPACE,
  [SDL_SCANCODE_KP_A] = KEY_A,
  [SDL_SCANCODE_KP_B] = KEY_B,
  [SDL_SCANCODE_KP_C] = KEY_C,
  [SDL_SCANCODE_KP_D] = KEY_D,
  [SDL_SCANCODE_KP_E] = KEY_E,
  [SDL_SCANCODE_KP_F] = KEY_F,
  [SDL_SCANCODE_KP_POWER] = KEY_POWER,
  [SDL_SCANCODE_KP_PLUSMINUS] = KEY_KPPLUSMINUS,
  [SDL_SCANCODE_KP_CLEAR] = KEY_CLEAR,
  [SDL_SCANCODE_KP_CLEARENTRY] = KEY_DELETE,
  [SDL_SCANCODE_LCTRL] = KEY_LEFTCTRL,
  [SDL_SCANCODE_LSHIFT] = KEY_LEFTSHIFT,
  [SDL_SCANCODE_LALT] = KEY_LEFTALT,
  [SDL_SCANCODE_LGUI] = KEY_LEFTMETA,
  [SDL_SCANCODE_RCTRL] = KEY_RIGHTCTRL,
  [SDL_SCANCODE_RSHIFT] = KEY_RIGHTSHIFT,
  [SDL_SCANCODE_RALT] = KEY_RIGHTALT,
  [SDL_SCANCODE_RGUI] = KEY_RIGHTMETA,
  [SDL_SCANCODE_MODE] = KEY_MODE,
  [SDL_SCANCODE_AUDIONEXT] = KEY_NEXTSONG,
  [SDL_SCANCODE_AUDIOPREV] = KEY_PREVIOUSSONG,
  [SDL_SCANCODE_AUDIOSTOP] = KEY_STOPCD,
  [SDL_SCANCODE_AUDIOPLAY] = KEY_PLAYPAUSE,
  [SDL_SCANCODE_AUDIOMUTE] = KEY_MUTE,
  [SDL_SCANCODE_MEDIASELECT] = KEY_MEDIA,
  [SDL_SCANCODE_WWW] = KEY_WWW,
  [SDL_SCANCODE_MAIL] = KEY_MAIL,
  [SDL_SCANCODE_CALCULATOR] = KEY_CALC,
  [SDL_SCANCODE_COMPUTER] = KEY_COMPUTER,
  [SDL_SCANCODE_AC_SEARCH] = KEY_SEARCH,
  [SDL_SCANCODE_AC_HOME] = KEY_HOMEPAGE,
  [SDL_SCANCODE_AC_BACK] = KEY_BACK,
  [SDL_SCANCODE_AC_FORWARD] = KEY_FORWARD,
  [SDL_SCANCODE_AC_STOP] = KEY_STOP,
  [SDL_SCANCODE_AC_REFRESH] = KEY_REFRESH,
  [SDL_SCANCODE_AC_BOOKMARKS] = KEY_BOOKMARKS,
  [SDL_SCANCODE_BRIGHTNESSDOWN] = KEY_BRIGHTNESSDOWN,
  [SDL_SCANCODE_BRIGHTNESSUP] = KEY_BRIGHTNESSUP,
  [SDL_SCANCODE_DISPLAYSWITCH] = KEY_SWITCHVIDEOMODE,
  [SDL_SCANCODE_KBDILLUMTOGGLE] = KEY_KBDILLUMTOGGLE,
  [SDL_SCANCODE_KBDILLUMDOWN] = KEY_KBDILLUMDOWN,
  [SDL_SCANCODE_KBDILLUMUP] = KEY_KBDILLUMUP,
  [SDL_SCANCODE_EJECT] = KEY_EJECTCD,
  [SDL_SCANCODE_SLEEP] = KEY_SLEEP,
  [SDL_SCANCODE_APP1] = KEY_PROG1,
  [SDL_SCANCODE_APP2] = KEY_PROG2,
  [SDL_SCANCODE_AUDIOREWIND] = KEY_REWIND,
  [SDL_SCANCODE_AUDIOFASTFORWARD] = KEY_FASTFORWARD,
  [SDL_SCANCODE_CALL] = KEY_PHONE,
  [SDL_SCANCODE_ENDCALL] = KEY_EXIT,
};

static const IoRegisterDescriptor virtio_input_config_registers[]
    __attribute__((unused)) = {
  VIRTIO_CONFIG_FIELD_RW_U8("select", VIRTIO_INPUT_CONFIG_SELECT),
  VIRTIO_CONFIG_FIELD_RW_U8("subsel", VIRTIO_INPUT_CONFIG_SUBSEL),
  VIRTIO_CONFIG_FIELD_RO_U8("size", VIRTIO_INPUT_CONFIG_SIZE),
  {
    .name = "payload",
    .first_offset = VIRTIO_MMIO_CONFIG + VIRTIO_INPUT_CONFIG_PAYLOAD,
    .last_offset = VIRTIO_MMIO_CONFIG + VIRTIO_INPUT_CONFIG_BYTES - 1u,
    .stride = 1u,
    .width_mask = IO_WIDTH_1 | IO_WIDTH_2 | IO_WIDTH_4,
    .direction_mask = IO_TRANSACTION_READ,
    .naturally_aligned = true,
  },
};

static const IoAccessPolicy virtio_input_mmio_policy
    __attribute__((unused)) = {
  .registers = virtio_input_config_registers,
  .register_count = ARRLEN(virtio_input_config_registers),
  .parent = &virtio_mmio_transport_policy,
};

static uint32_t virtio_input_device_features(uint32_t select) {
  return select == 1 ? 1u << (VIRTIO_F_VERSION_1 - 32) : 0;
}

static bool virtio_input_driver_features_supported(void) {
  if (!virtio_driver_feature_enabled(&transport, VIRTIO_F_VERSION_1)) {
    return false;
  }
  for (uint32_t select = 0; select < 2; select++) {
    if ((transport.driver_features[select] &
        ~virtio_input_device_features(select)) != 0) {
      return false;
    }
  }
  return true;
}

static VirtqueueState *selected_queue(void) {
  return transport.queue_select < VIRTIO_INPUT_QUEUE_COUNT ?
      &queues[transport.queue_select] : NULL;
}

static void virtio_input_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv_plic_set_irq(VIRTIO_INPUT_IRQ, transport.interrupt_status != 0));
}

static uint16_t guest_read16(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 2, &resolved) ?
      (uint16_t)paddr_dma_read_value(resolved, 2) : 0;
}

static uint32_t guest_read32(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 4, &resolved) ?
      (uint32_t)paddr_dma_read_value(resolved, 4) : 0;
}

static uint64_t guest_read64(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 8, &resolved) ?
      paddr_dma_read_value(resolved, 8) : 0;
}

static void guest_write16(GuestDmaAddr addr, uint16_t value) {
  paddr_t resolved;
  if (virtio_dma_resolve_span(addr, 2, &resolved)) {
    paddr_dma_write_value(resolved, 2, value);
  }
}

static void guest_write32(GuestDmaAddr addr, uint32_t value) {
  paddr_t resolved;
  if (virtio_dma_resolve_span(addr, 4, &resolved)) {
    paddr_dma_write_value(resolved, 4, value);
  }
}

static bool guest_range_ok(GuestDmaAddr addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, len, &resolved);
}

static bool guest_copy_to(GuestDmaAddr addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, len, &resolved) &&
      paddr_dma_write(resolved, buf, len);
}

static bool guest_copy_from(GuestDmaAddr addr, void *buf, uint32_t len) {
  if (len == 0) return true;
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, len, &resolved) &&
      paddr_dma_read(resolved, buf, len);
}

static bool virtq_aligned(GuestDmaAddr addr, uint32_t align) {
  return (addr & (GuestDmaAddr)(align - 1u)) == 0;
}

static bool virtq_dma_range_valid(const char *name, const VirtqueueState *queue,
    GuestDmaAddr addr, uint32_t len, uint32_t align) {
  if (addr != 0 && virtq_aligned(addr, align) && guest_range_ok(addr, len)) {
    return true;
  }
  Log("virtio-input: invalid %s ring q=%u addr=0x%" PRIx64
      " len=%u align=%u", name, (unsigned)(queue - queues),
      (uint64_t)addr, len, align);
  return false;
}

static bool virtq_validate_queue_layout(VirtqueueState *queue) {
  VirtioSplitRingSpan span;
  if (!virtio_split_ring_span(queue->num, VIRTIO_INPUT_QUEUE_SIZE,
      false, &span)) {
    Log("virtio-input: invalid QueueNum q=%u num=%u max=%u",
        (unsigned)(queue - queues), queue->num, VIRTIO_INPUT_QUEUE_SIZE);
    return false;
  }
  return virtq_dma_range_valid("desc", queue, queue->desc,
             span.descriptor_bytes, 16) &&
         virtq_dma_range_valid("driver", queue, queue->driver,
             span.driver_bytes, 2) &&
         virtq_dma_range_valid("device", queue, queue->device,
             span.device_bytes, 4);
}

static bool virtq_read_desc(VirtqueueState *queue, uint16_t idx,
    VirtqueueDescriptor *desc) {
  if (idx >= queue->num) return false;
  GuestDmaAddr base;
  if (!virtio_guest_dma_add(queue->desc, (uint64_t)idx * 16u, &base) ||
      !guest_range_ok(base, 16)) {
    return false;
  }
  desc->addr = guest_read64(base);
  desc->len = guest_read32(base + 8);
  desc->flags = guest_read16(base + 12);
  desc->next = guest_read16(base + 14);
  return true;
}

static bool virtq_collect_chain(VirtqueueState *queue, uint16_t head,
    VirtqueueDescriptor *out, int *out_count) {
  bool seen[VIRTIO_INPUT_QUEUE_SIZE] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= queue->num || seen[idx] ||
        count >= (int)VIRTIO_INPUT_MAX_CHAIN ||
        !virtq_read_desc(queue, idx, &out[count])) {
      return false;
    }
    seen[idx] = true;
    /* 本设备未提供 INDIRECT_DESC；出现间接表就是坏 descriptor chain。 */
    if ((out[count].flags & VIRTQUEUE_DESCRIPTOR_F_INDIRECT) != 0) {
      return false;
    }
    count++;
    if ((out[count - 1].flags & VIRTQUEUE_DESCRIPTOR_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }
  *out_count = count;
  return true;
}

static bool virtq_copy_to_writable_chain(const VirtqueueDescriptor *descs,
    int count, const uint8_t *src, uint32_t len) {
  uint32_t capacity = 0;
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQUEUE_DESCRIPTOR_F_WRITE) == 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len) ||
        UINT32_MAX - capacity < descs[i].len) {
      return false;
    }
    capacity += descs[i].len;
  }
  if (capacity < len) return false;

  uint32_t copied = 0;
  for (int i = 0; i < count && copied < len; i++) {
    uint32_t take = descs[i].len < len - copied ?
        descs[i].len : len - copied;
    if (!guest_copy_to(descs[i].addr, src + copied, take)) return false;
    copied += take;
  }
  return copied == len;
}

static bool virtq_copy_from_readable_chain(const VirtqueueDescriptor *descs,
    int count, uint8_t *dst, uint32_t len) {
  uint32_t capacity = 0;
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQUEUE_DESCRIPTOR_F_WRITE) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len) ||
        UINT32_MAX - capacity < descs[i].len) {
      return false;
    }
    capacity += descs[i].len;
  }
  if (capacity < len) return false;

  uint32_t copied = 0;
  for (int i = 0; i < count && copied < len; i++) {
    uint32_t take = descs[i].len < len - copied ?
        descs[i].len : len - copied;
    if (!guest_copy_from(descs[i].addr, dst + copied, take)) return false;
    copied += take;
  }
  return copied == len;
}

static void virtq_push_used(VirtqueueState *queue, uint16_t head,
    uint32_t used_len, uint16_t *used_idx) {
  uint16_t used_offset = *used_idx % queue->num;
  guest_write32(queue->device + 4 + (GuestDmaAddr)used_offset * 8, head);
  guest_write32(queue->device + 8 + (GuestDmaAddr)used_offset * 8, used_len);
  (*used_idx)++;
  guest_write16(queue->device + 2, *used_idx);
}

static void virtq_maybe_interrupt(VirtqueueState *queue, bool used_any) {
  if (!used_any) return;
  uint16_t avail_flags = guest_read16(queue->driver);
  if ((avail_flags & VIRTQUEUE_AVAILABLE_F_NO_INTERRUPT) == 0) {
    virtio_transport_raise_interrupt(
        &transport, VIRTIO_INTERRUPT_USED_BUFFER);
    virtio_input_raise_irq();
  }
}

static bool virtio_input_pending_count(VirtqueueState *queue,
    uint16_t avail_idx, uint16_t *count) {
  if (virtqueue_pending_count(
      queue->last_avail_idx, avail_idx, queue->num, count)) {
    return true;
  }
  Log("virtio-input: invalid avail delta q=%u last=%u avail=%u num=%u",
      (unsigned)(queue - queues), queue->last_avail_idx, avail_idx,
      queue->num);
  if (virtio_transport_set_needs_reset(&transport)) virtio_input_raise_irq();
  return false;
}

static void virtio_input_log_invalid(const char *queue_name, uint16_t head) {
  if (invalid_log_budget > 0) {
    invalid_log_budget--;
    Log("virtio-input: complete invalid %s descriptor head=%u with len=0",
        queue_name, head);
  }
}

static bool virtio_input_write_event(VirtqueueState *queue, uint16_t head,
    const VirtioInputEvent *event) {
  VirtqueueDescriptor descs[VIRTIO_INPUT_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(queue, head, descs, &count) || count == 0) {
    return false;
  }
  uint8_t wire[VIRTIO_INPUT_EVENT_BYTES] = {
    event->type & 0xffu,
    event->type >> 8,
    event->code & 0xffu,
    event->code >> 8,
    event->value & 0xffu,
    (event->value >> 8) & 0xffu,
    (event->value >> 16) & 0xffu,
    (event->value >> 24) & 0xffu,
  };
  return virtq_copy_to_writable_chain(descs, count, wire, sizeof(wire));
}

static void virtio_input_try_deliver_events(void) {
  VirtqueueState *queue = &queues[VIRTIO_INPUT_QUEUE_EVENT];
  if (pending_count == 0 ||
      !virtio_queue_notify_allowed(&transport, queue) ||
      queue->num == 0 || queue->desc == 0 ||
      queue->driver == 0 || queue->device == 0) {
    return;
  }

  uint16_t avail_idx = guest_read16(queue->driver + 2);
  uint16_t buffers = 0;
  if (!virtio_input_pending_count(queue, avail_idx, &buffers)) return;
  uint16_t used_idx = guest_read16(queue->device + 2);
  bool used_any = false;
  while (pending_count != 0 && buffers != 0) {
    uint16_t ring_offset = queue->last_avail_idx % queue->num;
    uint16_t head = guest_read16(
        queue->driver + 4 + (GuestDmaAddr)ring_offset * 2);
    bool valid = virtio_input_write_event(
        queue, head, &pending_events[pending_head]);
    virtq_push_used(queue, head, valid ? VIRTIO_INPUT_EVENT_BYTES : 0,
        &used_idx);
    queue->last_avail_idx++;
    buffers--;
    used_any = true;
    if (valid) {
      pending_head = (pending_head + 1) % VIRTIO_INPUT_EVENT_FIFO_CAPACITY;
      pending_count--;
      input_stats.events_delivered++;
    } else {
      input_stats.invalid_event_buffers++;
      virtio_input_log_invalid("eventq", head);
    }
  }
  virtq_maybe_interrupt(queue, used_any);
}

static void virtio_input_process_status(void) {
  VirtqueueState *queue = &queues[VIRTIO_INPUT_QUEUE_STATUS];
  if (!virtio_queue_notify_allowed(&transport, queue) ||
      queue->num == 0 || queue->desc == 0 ||
      queue->driver == 0 || queue->device == 0) {
    return;
  }

  uint16_t avail_idx = guest_read16(queue->driver + 2);
  uint16_t buffers = 0;
  if (!virtio_input_pending_count(queue, avail_idx, &buffers)) return;
  uint16_t used_idx = guest_read16(queue->device + 2);
  bool used_any = false;
  while (buffers != 0) {
    uint16_t ring_offset = queue->last_avail_idx % queue->num;
    uint16_t head = guest_read16(
        queue->driver + 4 + (GuestDmaAddr)ring_offset * 2);
    VirtqueueDescriptor descs[VIRTIO_INPUT_MAX_CHAIN];
    int count = 0;
    uint8_t wire[VIRTIO_INPUT_EVENT_BYTES];
    bool valid = virtq_collect_chain(queue, head, descs, &count) &&
        count != 0 &&
        virtq_copy_from_readable_chain(descs, count, wire, sizeof(wire));
    if (valid) {
      /* 当前后端没有 LED 输出；完整消费状态事件，避免 Linux 泄漏 stsbuf。 */
      input_stats.status_events++;
    } else {
      input_stats.invalid_status_buffers++;
      virtio_input_log_invalid("statusq", head);
    }
    virtq_push_used(queue, head, 0, &used_idx);
    queue->last_avail_idx++;
    buffers--;
    used_any = true;
  }
  virtq_maybe_interrupt(queue, used_any);
}

static bool virtio_input_enqueue_pair(uint16_t key, bool is_keydown) {
  if (VIRTIO_INPUT_EVENT_FIFO_CAPACITY - pending_count < 2) {
    input_stats.dropped_fifo_full++;
    return false;
  }
  pending_events[pending_tail] = (VirtioInputEvent) {
    .type = VIRTIO_INPUT_EV_KEY,
    .code = key,
    .value = is_keydown ? 1u : 0u,
  };
  pending_tail = (pending_tail + 1) % VIRTIO_INPUT_EVENT_FIFO_CAPACITY;
  pending_events[pending_tail] = (VirtioInputEvent) {
    .type = VIRTIO_INPUT_EV_SYN,
    .code = VIRTIO_INPUT_SYN_REPORT,
    .value = 0,
  };
  pending_tail = (pending_tail + 1) % VIRTIO_INPUT_EVENT_FIFO_CAPACITY;
  pending_count += 2;
  return true;
}

void virtio_input_send_sdl_key(uint32_t scancode, bool is_keydown) {
  VirtqueueState *eventq = &queues[VIRTIO_INPUT_QUEUE_EVENT];
  if (nemu_state.state != NEMU_RUNNING || scancode >= SDL_NUM_SCANCODES ||
      sdl_to_linux_key[scancode] == KEY_RESERVED) {
    return;
  }
  /* 启动早期的宿主按键不应延迟到登录提示符后突然重放。 */
  if (!virtio_queue_notify_allowed(&transport, eventq)) {
    input_stats.dropped_not_ready++;
    return;
  }
  if (!virtio_input_enqueue_pair(sdl_to_linux_key[scancode], is_keydown)) {
    return;
  }
  input_stats.key_transitions++;
  virtio_input_try_deliver_events();
}

void virtio_input_update(void) {
  virtio_input_try_deliver_events();
  virtio_input_process_status();
}

static void virtio_input_build_key_bitmap(void) {
  memset(key_bitmap, 0, sizeof(key_bitmap));
  key_bitmap_size = 0;
  advertised_key_count = 0;
  for (uint32_t scancode = 0; scancode < SDL_NUM_SCANCODES; scancode++) {
    uint16_t key = sdl_to_linux_key[scancode];
    if (key == KEY_RESERVED || key >= sizeof(key_bitmap) * 8u) continue;
    uint8_t mask = 1u << (key % 8u);
    if ((key_bitmap[key / 8u] & mask) == 0) {
      key_bitmap[key / 8u] |= mask;
      advertised_key_count++;
    }
    uint32_t bytes = key / 8u + 1u;
    if (bytes > key_bitmap_size) key_bitmap_size = bytes;
  }
}

static uint8_t virtio_input_config_snapshot(uint8_t *payload) {
  uint8_t select = host_read(
      input_base + VIRTIO_MMIO_CONFIG + VIRTIO_INPUT_CONFIG_SELECT, 1);
  uint8_t subsel = host_read(
      input_base + VIRTIO_MMIO_CONFIG + VIRTIO_INPUT_CONFIG_SUBSEL, 1);
  memset(payload, 0, VIRTIO_INPUT_CONFIG_PAYLOAD_BYTES);

  switch (select) {
    case VIRTIO_INPUT_CFG_ID_NAME:
      if (subsel != 0) return 0;
      memcpy(payload, VIRTIO_INPUT_NAME, sizeof(VIRTIO_INPUT_NAME) - 1u);
      return sizeof(VIRTIO_INPUT_NAME) - 1u;
    case VIRTIO_INPUT_CFG_ID_SERIAL:
      if (subsel != 0) return 0;
      memcpy(payload, VIRTIO_INPUT_SERIAL, sizeof(VIRTIO_INPUT_SERIAL) - 1u);
      return sizeof(VIRTIO_INPUT_SERIAL) - 1u;
    case VIRTIO_INPUT_CFG_ID_DEVIDS:
      if (subsel != 0) return 0;
      payload[0] = VIRTIO_INPUT_BUS_VIRTUAL & 0xffu;
      payload[1] = VIRTIO_INPUT_BUS_VIRTUAL >> 8;
      payload[2] = VIRTIO_INPUT_VENDOR & 0xffu;
      payload[3] = VIRTIO_INPUT_VENDOR >> 8;
      payload[4] = VIRTIO_INPUT_PRODUCT & 0xffu;
      payload[5] = VIRTIO_INPUT_PRODUCT >> 8;
      payload[6] = VIRTIO_INPUT_VERSION & 0xffu;
      payload[7] = VIRTIO_INPUT_VERSION >> 8;
      return 8;
    case VIRTIO_INPUT_CFG_PROP_BITS:
      return 0;
    case VIRTIO_INPUT_CFG_EV_BITS:
      if (subsel == VIRTIO_INPUT_EV_KEY) {
        memcpy(payload, key_bitmap, key_bitmap_size);
        return key_bitmap_size;
      }
      if (subsel == VIRTIO_INPUT_EV_REP) {
        /* 与 QEMU 键盘契约一致：size 启用 Linux input core repeat。 */
        return 1;
      }
      return 0;
    case VIRTIO_INPUT_CFG_ABS_INFO:
    case VIRTIO_INPUT_CFG_UNSET:
    default:
      return 0;
  }
}

static void virtio_input_read_config(uint32_t offset, int len) {
  uint8_t payload[VIRTIO_INPUT_CONFIG_PAYLOAD_BYTES];
  uint8_t size = virtio_input_config_snapshot(payload);
  uint32_t config_offset = offset - VIRTIO_MMIO_CONFIG;
  for (int i = 0; i < len; i++) {
    uint32_t byte_offset = config_offset + (uint32_t)i;
    uint8_t value = 0;
    if (byte_offset == VIRTIO_INPUT_CONFIG_SELECT ||
        byte_offset == VIRTIO_INPUT_CONFIG_SUBSEL) {
      value = host_read(input_base + VIRTIO_MMIO_CONFIG + byte_offset, 1);
    } else if (byte_offset == VIRTIO_INPUT_CONFIG_SIZE) {
      value = size;
    } else if (byte_offset >= VIRTIO_INPUT_CONFIG_PAYLOAD &&
        byte_offset < VIRTIO_INPUT_CONFIG_BYTES) {
      value = payload[byte_offset - VIRTIO_INPUT_CONFIG_PAYLOAD];
    }
    host_write(input_base + offset + i, 1, value);
  }
}

static void virtio_input_reset(void) {
  virtio_transport_reset(&transport);
  memset(queues, 0, sizeof(queues));
  pending_head = 0;
  pending_tail = 0;
  pending_count = 0;
  if (input_base != NULL) memset(input_base, 0, 0x1000);
  virtio_input_raise_irq();
}

static uint32_t virtio_input_read_reg(uint32_t offset) {
  VirtqueueState *queue = selected_queue();
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return VIRTIO_MMIO_MAGIC_VALUE;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_MODERN;
    case VIRTIO_MMIO_DEVICE_ID: return VIRTIO_DEVICE_ID_INPUT;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES:
      return virtio_input_device_features(transport.device_features_select);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
      return transport.device_features_select;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
      return transport.driver_features_select;
    case VIRTIO_MMIO_QUEUE_SEL: return transport.queue_select;
    case VIRTIO_MMIO_QUEUE_NUM_MAX:
      return transport.queue_select < VIRTIO_INPUT_QUEUE_COUNT ?
          VIRTIO_INPUT_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return queue != NULL ? queue->num : 0;
    case VIRTIO_MMIO_QUEUE_READY:
      return queue != NULL && queue->ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS: return transport.interrupt_status;
    case VIRTIO_MMIO_STATUS: return transport.device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      return queue != NULL ? (uint32_t)queue->desc : 0;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      return queue != NULL ? (uint32_t)(queue->desc >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      return queue != NULL ? (uint32_t)queue->driver : 0;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      return queue != NULL ? (uint32_t)(queue->driver >> 32) : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      return queue != NULL ? (uint32_t)queue->device : 0;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      return queue != NULL ? (uint32_t)(queue->device >> 32) : 0;
    case VIRTIO_MMIO_CONFIG_GENERATION: return transport.config_generation;
    default: return 0;
  }
}

static void virtio_input_write_reg(uint32_t offset, uint32_t value) {
  VirtqueueState *queue = selected_queue();
  switch (offset) {
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
      transport.device_features_select = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES:
      if (transport.driver_features_select < 2 &&
          virtio_transport_driver_features_write_allowed(&transport)) {
        transport.driver_features[transport.driver_features_select] = value;
      }
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
      transport.driver_features_select = value;
      break;
    case VIRTIO_MMIO_QUEUE_SEL:
      transport.queue_select = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (queue != NULL) {
        if (!virtio_queue_config_write_allowed(queue)) {
          Log("virtio-input: reject QueueNum write while QueueReady=1 q=%u",
              transport.queue_select);
        } else if (virtio_split_queue_size_valid(
            value, VIRTIO_INPUT_QUEUE_SIZE)) {
          queue->num = value;
        } else {
          Log("virtio-input: reject unsupported QueueNum q=%u num=%u max=%u",
              transport.queue_select, value, VIRTIO_INPUT_QUEUE_SIZE);
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (queue != NULL) {
        bool validate_layout = value == 1 && !queue->ready;
        VirtioQueueReadyWriteResult result = virtio_queue_ready_decode(
            queue, value, !validate_layout ||
                virtq_validate_queue_layout(queue));
        if (result == VIRTIO_QUEUE_READY_DISABLED) {
          queue->ready = false;
          queue->last_avail_idx = 0;
        } else if (result == VIRTIO_QUEUE_READY_ENABLED) {
          queue->ready = true;
          queue->last_avail_idx = guest_read16(queue->driver + 2);
        } else if (result == VIRTIO_QUEUE_READY_INVALID_LAYOUT) {
          queue->ready = false;
          queue->last_avail_idx = 0;
        } else if (result == VIRTIO_QUEUE_READY_INVALID_VALUE) {
          Log("virtio-input: reject invalid QueueReady value=%u q=%u",
              value, transport.queue_select);
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      if (value >= VIRTIO_INPUT_QUEUE_COUNT) break;
      queue = &queues[value];
      if (!virtio_queue_notify_allowed(&transport, queue)) {
        Log("virtio-input: reject QueueNotify q=%u before DRIVER_OK or QueueReady",
            value);
      } else if (value == VIRTIO_INPUT_QUEUE_EVENT) {
        virtio_input_try_deliver_events();
      } else {
        virtio_input_process_status();
      }
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      virtio_transport_acknowledge_interrupt(&transport, value);
      virtio_input_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_input_reset();
      } else {
        VirtioStatusWriteResult result = virtio_transport_accept_status(
            &transport, value, virtio_input_driver_features_supported());
        if (result == VIRTIO_STATUS_FEATURES_REJECTED) {
          Log("virtio-input: reject unsupported negotiated features");
        } else if (result == VIRTIO_STATUS_INVALID_TRANSITION) {
          Log("virtio-input: reject invalid Status progression value=0x%08x",
              value);
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_low(&queue->desc, value);
      break;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_high(&queue->desc, value);
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_low(&queue->driver, value);
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_high(&queue->driver, value);
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_low(&queue->device, value);
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      if (virtio_queue_config_write_allowed(queue))
        virtqueue_write_address_high(&queue->device, value);
      break;
    default:
      break;
  }
}

static void virtio_input_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4 || len == 8);
  if (is_write) {
    /* config select/subsel 已由 map_write 写入 backing store。 */
    if (offset >= VIRTIO_MMIO_CONFIG) return;
    if (len == 4) {
      virtio_input_write_reg(offset, host_read(input_base + offset, 4));
    } else if (len == 8) {
      virtio_input_write_reg(offset, host_read(input_base + offset, 4));
      virtio_input_write_reg(
          offset + 4, host_read(input_base + offset + 4, 4));
    }
    return;
  }

  if (offset >= VIRTIO_MMIO_CONFIG) {
    virtio_input_read_config(offset, len);
  } else if (len == 8) {
    host_write(input_base + offset, 4, virtio_input_read_reg(offset));
    host_write(input_base + offset + 4, 4,
        virtio_input_read_reg(offset + 4));
  } else {
    host_write(input_base + offset, len, virtio_input_read_reg(offset));
  }
}

void init_virtio_input(void) {
  input_base = new_space(0x1000);
  virtio_input_build_key_bitmap();
  virtio_input_reset();
#ifdef NEMU_HAS_PORT_IO
  add_pio_map("virtio-input", DEV_VIRTIO_INPUT_MMIO, input_base, 0x1000,
      virtio_input_io_handler);
#else
  add_mmio_map_with_policy("virtio-input", DEV_VIRTIO_INPUT_MMIO, input_base,
      0x1000, virtio_input_io_handler, &virtio_input_mmio_policy);
#endif
}

void virtio_input_dump_machine_info(FILE *out) {
  fprintf(out, "device.virtio_input.model=virtio-input-keyboard-mmio\n");
  fprintf(out, "device.virtio_input.backend=sdl2\n");
  fprintf(out, "device.virtio_input.mmio_version=%u\n",
      VIRTIO_MMIO_VERSION_MODERN);
  fprintf(out, "device.virtio_input.device_id=%u\n", VIRTIO_DEVICE_ID_INPUT);
  fprintf(out, "device.virtio_input.vendor_id=0x%08x\n", VIRTIO_VENDOR_YSYX);
  fprintf(out, "device.virtio_input.name=%s\n", VIRTIO_INPUT_NAME);
  fprintf(out, "device.virtio_input.serial=%s\n", VIRTIO_INPUT_SERIAL);
  fprintf(out, "device.virtio_input.queue_count=%u\n", VIRTIO_INPUT_QUEUE_COUNT);
  fprintf(out, "device.virtio_input.queue_num_max=%u\n", VIRTIO_INPUT_QUEUE_SIZE);
  fprintf(out, "device.virtio_input.eventq_ready=%d\n",
      queues[VIRTIO_INPUT_QUEUE_EVENT].ready ? 1 : 0);
  fprintf(out, "device.virtio_input.statusq_ready=%d\n",
      queues[VIRTIO_INPUT_QUEUE_STATUS].ready ? 1 : 0);
  fprintf(out, "device.virtio_input.features.version_1=1\n");
  fprintf(out, "device.virtio_input.features.indirect_desc=0\n");
  fprintf(out, "device.virtio_input.features.event_idx=0\n");
  fprintf(out, "device.virtio_input.ev_key.count=%u\n", advertised_key_count);
  fprintf(out, "device.virtio_input.ev_key.bitmap_bytes=%u\n", key_bitmap_size);
  fprintf(out, "device.virtio_input.ev_rep=linux-input-core\n");
  fprintf(out, "device.virtio_input.pending_events=%u\n", pending_count);
  fprintf(out, "device.virtio_input.stats.key_transitions=%" PRIu64 "\n",
      input_stats.key_transitions);
  fprintf(out, "device.virtio_input.stats.events_delivered=%" PRIu64 "\n",
      input_stats.events_delivered);
  fprintf(out, "device.virtio_input.stats.status_events=%" PRIu64 "\n",
      input_stats.status_events);
  fprintf(out, "device.virtio_input.stats.dropped_not_ready=%" PRIu64 "\n",
      input_stats.dropped_not_ready);
  fprintf(out, "device.virtio_input.stats.dropped_fifo_full=%" PRIu64 "\n",
      input_stats.dropped_fifo_full);
  fprintf(out, "device.virtio_input.stats.invalid_event_buffers=%" PRIu64 "\n",
      input_stats.invalid_event_buffers);
  fprintf(out, "device.virtio_input.stats.invalid_status_buffers=%" PRIu64 "\n",
      input_stats.invalid_status_buffers);
}
