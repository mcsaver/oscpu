/* RV64C decode stores the shared manual descriptor without a second mnemonic map. */

#ifdef CONFIG_RISCV_EXT_C
static inline bool rv_decode_compressed_instruction(
    uint16_t encoding, RvDecodedInstruction *instruction) {
  RiscvCompressedInstruction compressed;
  if (!riscv_decode_compressed_instruction(
          encoding, 64, 32,
          ISDEF(CONFIG_RISCV_EXT_F), ISDEF(CONFIG_RISCV_EXT_D),
          &compressed)) {
    return false;
  }

  instruction->encoding = encoding;
  instruction->instruction_class = RV_INSTRUCTION_CLASS_COMPRESSED;
  instruction->operation = RV_OPERATION_COMPRESSED;
  instruction->compressed = compressed;
  instruction->length = compressed.length;
  instruction->rd = compressed.rd;
  instruction->rs1 = compressed.rs1;
  instruction->rs2 = compressed.rs2;
  instruction->rs3 = 0;
  instruction->immediate = (word_t)compressed.immediate;
  return true;
}
#endif
