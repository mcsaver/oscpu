/* RV64A LR/SC 与 AMO 扩展。 */

/*
 * CONFIG_RISCV_EXT_A 必须由 Kconfig/autoconf 统一提供。inst.c 采用 unity build
 * 包含本文件，不能在这里临时定义配置宏，否则会让后续指令文件看到意外配置。
 */
#ifdef CONFIG_RISCV_EXT_A
static inline word_t amo_sext_word(uint32_t value) {
  return MUXDEF(CONFIG_ISA64, (word_t)SEXT(value, 32), (word_t)value);
}

// AMO 事务：
//old = Memory[addr]
//new = operation(old, rs2)
//Memory[addr] = new
//rd = old
//
//31       27 26  25 24       20 19       15 14    12 11       7 6       0
//+----------+---+---+-----------+-----------+--------+-----------+---------+
//|  funct5  |aq |rl |    rs2    |    rs1    | funct3 |    rd     | 0101111 |
//+----------+---+---+-----------+-----------+--------+-----------+---------+
//funct5：具体原子操作
//aq：acquire
//rl：release
//rs1：内存地址，没有立即数
//rs2：参与计算或准备写入的源操作数
//funct3=010：.W，32bit
//funct3=011：.D，64bit，仅RV64
//rd：返回内存旧值，SC除外
//LR的rs2字段必须为0

static inline bool amo_aq(uint32_t inst) {
  return BITS(inst, 26, 26) != 0;
}

static inline bool amo_rl(uint32_t inst) {
  return BITS(inst, 25, 25) != 0;
}

/*
 * 当前 NEMU 是单 hart、单执行线程模型，guest 访存本身已经按程序序串行，
 * 强于 RVWMO 的 aq/rl 要求。这里仍显式建立宿主内存序边界，避免编译器重排，
 * 也为未来并发设备或多 hart 扩展保留准确的 acquire/release 语义。
 */
static inline void amo_order_before(uint32_t inst) {
  if (!amo_rl(inst)) return;
  __atomic_thread_fence(amo_aq(inst) ? __ATOMIC_SEQ_CST : __ATOMIC_RELEASE);
}

static inline void amo_order_after(uint32_t inst) {
  if (!amo_aq(inst)) return;
  __atomic_thread_fence(amo_rl(inst) ? __ATOMIC_SEQ_CST : __ATOMIC_ACQUIRE);
}

// 只判断普通 AMO 运算是否合法，不包含 LR 和 SC。
static inline bool amo_funct5_valid(uint32_t funct5) {
  switch (funct5) {
    case 0x00: case 0x01: case 0x04: case 0x08: case 0x0c:
    case 0x10: case 0x14: case 0x18: case 0x1c:
      return true;
    default:
      return false;
  }
}

// 计算 32 bit AMO；RV64 的 rs2 高 32 bit 在此自然忽略。
static inline uint32_t amo_compute_w(uint32_t old, uint32_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.w
    case 0x00: return old + src;                                // amoadd.w
    case 0x04: return old ^ src;                                // amoxor.w
    case 0x0c: return old & src;                                // amoand.w
    case 0x08: return old | src;                                // amoor.w
    case 0x10: return (int32_t)old < (int32_t)src ? old : src;  // amomin.w
    case 0x14: return (int32_t)old > (int32_t)src ? old : src;  // amomax.w
    case 0x18: return old < src ? old : src;                    // amominu.w
    case 0x1c: return old > src ? old : src;                    // amomaxu.w
    default: return old;
  }
}

static inline bool amo_raise_misaligned(word_t addr, uint32_t funct5) {
  // AMO/LR/SC 编码有效但地址不对齐时应投递地址异常，不能退化成 illegal instruction。
  vaddr_set_fault(funct5 == 0x02 ? CAUSE_LOAD_MISALIGNED : CAUSE_STORE_MISALIGNED, addr);
  return true;
}

// LR 对物理内存范围建立 reservation；状态定义在 common.c 中。
static inline void lr_sc_set_reservation(int len, paddr_t paddr) {
  lr_reservation_valid = true;
  lr_reservation_paddr = paddr;
  lr_reservation_len = len;
}

// 计算 XLEN bit AMO。
static inline word_t amo_compute_xlen(word_t old, word_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.d
    case 0x00: return old + src;                                // amoadd.d
    case 0x04: return old ^ src;                                // amoxor.d
    case 0x0c: return old & src;                                // amoand.d
    case 0x08: return old | src;                                // amoor.d
    case 0x10: return (sword_t)old < (sword_t)src ? old : src;  // amomin.d
    case 0x14: return (sword_t)old > (sword_t)src ? old : src;  // amomax.d
    case 0x18: return old < src ? old : src;                    // amominu.d
    case 0x1c: return old > src ? old : src;                    // amomaxu.d
    default: return old;
  }
}

typedef struct {
  word_t src;
  uint32_t funct5;
  int len;
} AmoComputeContext;

static word_t amo_compute_callback(word_t old, const void *opaque) {
  const AmoComputeContext *ctx = opaque;
  if (ctx->len == 4) {
    return amo_compute_w((uint32_t)old, (uint32_t)ctx->src, ctx->funct5);
  }
  return amo_compute_xlen(old, ctx->src, ctx->funct5);
}

static inline word_t amo_old_to_rd(word_t old, int len) {
  return len == 4 ? amo_sext_word((uint32_t)old) : old;
}

static inline bool exec_rva_amo_width(
    uint32_t inst, int rd, int rs1, int rs2, int len) {
  uint32_t funct5 = BITS(inst, 31, 27);
  word_t addr = R(rs1);
  word_t align_mask = (word_t)len - 1;

  if (funct5 == 0x02) {                                        // lr.w / lr.d
    // LR 的 rs2!=0 是非法编码，必须先于地址访问被拒绝。
    if (rs2 != 0) return false;
    if ((addr & align_mask) != 0) return amo_raise_misaligned(addr, funct5);

    word_t old = 0;
    paddr_t paddr = 0;
    amo_order_before(inst);
    if (!vaddr_atomic_load_reserved(addr, len, &old, &paddr)) return true;
    lr_sc_set_reservation(len, paddr);
    R(rd) = amo_old_to_rd(old, len);
    amo_order_after(inst);
    return true;
  }

  if (funct5 == 0x03) {                                        // sc.w / sc.d
    if ((addr & align_mask) != 0) {
      // 地址异常也属于执行过一次有效 SC；不得把旧 reservation 带到 trap 之后。
      lr_reservation_valid = false;
      return amo_raise_misaligned(addr, funct5);
    }

    bool reservation_matches =
        lr_reservation_valid && lr_reservation_len == len;
    bool stored = false;
    amo_order_before(inst);
    bool access_ok = vaddr_atomic_store_conditional(addr, len, R(rs2),
        reservation_matches, lr_reservation_paddr, &stored);

    // SC 无论成功、失败还是触发异常，都必须使本 hart 的 reservation 失效。
    lr_reservation_valid = false;
    if (!access_ok) return true;
    R(rd) = stored ? 0 : 1;
    amo_order_after(inst);
    return true;
  }

  if (!amo_funct5_valid(funct5)) return false;
  if ((addr & align_mask) != 0) return amo_raise_misaligned(addr, funct5);

  AmoComputeContext ctx = {
    .src = R(rs2),
    .funct5 = funct5,
    .len = len,
  };
  word_t old = 0;
  amo_order_before(inst);
  if (!vaddr_atomic_rmw(addr, len, amo_compute_callback, &ctx, &old)) return true;
  R(rd) = amo_old_to_rd(old, len);
  amo_order_after(inst);
  return true;
}

static inline bool exec_rva_amo(uint32_t inst, int rd, int rs1, int rs2) {
  uint32_t funct3 = FUNCT3(inst);
  if (funct3 == 0x2) {
    return exec_rva_amo_width(inst, rd, rs1, rs2, 4);
  }
  if (funct3 == 0x3 && ISDEF(CONFIG_ISA64)) {
    return exec_rva_amo_width(inst, rd, rs1, rs2, 8);
  }
  return false;
}
#endif
