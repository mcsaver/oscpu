/* RV32A：共享手册 descriptor 到 RV32 体系结构状态的薄适配器。 */

void isa_riscv32_lr_sc_invalidate(paddr_t paddr, uint64_t len) {
  riscv_load_reservation_invalidate_if_overlap(
      &cpu.load_reservation, (uint64_t)paddr, len);
}

void isa_riscv32_lr_sc_clear(void) {
  riscv_load_reservation_clear(&cpu.load_reservation);
}

#ifdef CONFIG_RISCV_EXT_A
static inline void rv32_atomic_write_x_register(uint8_t index, word_t value) {
  if (index != 0) R(index) = value;
}

/*
 * 当前 NEMU 是单 hart、程序序解释器，guest 访存已经以程序序完成。
 * adapter 只显式消费 descriptor 的 rl/aq；它不是完整 RVWMO 的宿主替代品。
 */
static inline void rv32_atomic_order_before(
    const RiscvAtomicInstruction *instruction) {
  if (!instruction->rl) return;
}

static inline void rv32_atomic_order_after(
    const RiscvAtomicInstruction *instruction) {
  if (!instruction->aq) return;
}

static inline void rv32_atomic_raise_misaligned(vaddr_t address,
    const RiscvAtomicInstruction *instruction) {
  const word_t cause = riscv_atomic_is_load_reserved(instruction)
      ? CAUSE_LOAD_MISALIGNED : CAUSE_STORE_MISALIGNED;
  vaddr_set_fault(cause, address);
}

static inline bool rv32_execute_load_reserved(
    const Rv32DecodedInstruction *instruction) {
  const RiscvAtomicInstruction *atomic = &instruction->atomic;
  const vaddr_t address = R(instruction->rs1);
  if (!riscv_atomic_address_is_naturally_aligned(address, atomic)) {
    rv32_atomic_raise_misaligned(address, atomic);
    return true;
  }

  word_t old_value = 0;
  paddr_t physical_address = 0;
  rv32_atomic_order_before(atomic);
  if (!vaddr_atomic_load_reserved(
          address, atomic, &old_value, &physical_address)) {
    return true;
  }

  riscv_load_reservation_set(&cpu.load_reservation,
      (uint64_t)physical_address, riscv_atomic_width_bytes(atomic));
  rv32_atomic_write_x_register(instruction->rd,
      (word_t)riscv_atomic_old_value_to_xlen(atomic, old_value, 32));
  rv32_atomic_order_after(atomic);
  return true;
}

static inline bool rv32_execute_store_conditional(
    const Rv32DecodedInstruction *instruction) {
  const RiscvAtomicInstruction *atomic = &instruction->atomic;
  const vaddr_t address = R(instruction->rs1);
  const RiscvLoadReservation reservation = cpu.load_reservation;

  /*
   * 这是 NEMU 的保守实现策略，不是规范对未退休 SC 的强制要求：有效 SC
   * 一旦开始执行，即使随后 misaligned 或 permission fault，也清旧 reservation。
   */
  riscv_load_reservation_clear(&cpu.load_reservation);
  if (!riscv_atomic_address_is_naturally_aligned(address, atomic)) {
    rv32_atomic_raise_misaligned(address, atomic);
    return true;
  }

  bool stored = false;
  rv32_atomic_order_before(atomic);
  if (!vaddr_atomic_store_conditional(address, atomic, R(instruction->rs2),
          &reservation, &stored)) {
    return true;
  }

  rv32_atomic_write_x_register(instruction->rd,
      stored ? RISCV_SC_SUCCESS : RISCV_SC_FAILURE);
  rv32_atomic_order_after(atomic);
  return true;
}

static inline bool rv32_execute_atomic_memory_operation(
    const Rv32DecodedInstruction *instruction) {
  const RiscvAtomicInstruction *atomic = &instruction->atomic;
  const vaddr_t address = R(instruction->rs1);
  if (!riscv_atomic_address_is_naturally_aligned(address, atomic)) {
    rv32_atomic_raise_misaligned(address, atomic);
    return true;
  }

  word_t old_value = 0;
  rv32_atomic_order_before(atomic);
  if (!vaddr_atomic_rmw(
          address, atomic, R(instruction->rs2), &old_value)) {
    return true;
  }

  rv32_atomic_write_x_register(instruction->rd,
      (word_t)riscv_atomic_old_value_to_xlen(atomic, old_value, 32));
  rv32_atomic_order_after(atomic);
  return true;
}

static inline bool rv32_execute_atomic(
    const Rv32DecodedInstruction *instruction) {
  if (riscv_atomic_is_load_reserved(&instruction->atomic)) {
    return rv32_execute_load_reserved(instruction);
  }
  if (riscv_atomic_is_store_conditional(&instruction->atomic)) {
    return rv32_execute_store_conditional(instruction);
  }
  if (riscv_atomic_is_memory_operation(&instruction->atomic)) {
    return rv32_execute_atomic_memory_operation(instruction);
  }
  return false;
}
#else
static inline bool rv32_execute_atomic(
    const Rv32DecodedInstruction *instruction) {
  (void)instruction;
  return false;
}
#endif
