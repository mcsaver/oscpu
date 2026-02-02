#include "hardware/core.h"

#include <stdio.h>

/*
 * RISC-V RV32I 核心执行单元：包含指令译码、执行与寄存器写回。
 * 为保持可读性，将译码和访问抽象为静态辅助函数。
 */

/*
 * DecodeStage:
 *   用于暂存一次取指后的关键信息，避免在执行过程中反复拆分字段。
 */
typedef struct {
    uint32_t raw;     /* 原始指令字 */
    uint32_t pc;      /* 指令对应的 PC */
    uint32_t opcode;  /* 操作码 */
    uint32_t rd;      /* 目的寄存器编号 */
    uint32_t rs1;     /* 源寄存器 1 */
    uint32_t rs2;     /* 源寄存器 2 */
    uint32_t funct3;  /* 三位功能码 */
    uint32_t funct7;  /* 七位功能码 */
} DecodeStage;

/* read_reg:
 *   安全读取寄存器数组，idx 会自动取模 32。
 */
static inline uint32_t read_reg(const CoreState *core, uint32_t idx) {
    return core->regs[idx & 31u];
}

/* write_reg:
 *   写寄存器时自动忽略 x0（硬件规定恒为 0）。
 */
static inline void write_reg(CoreState *core, uint32_t idx, uint32_t value) {
    if ((idx & 31u) == 0) {
        return;
    }
    core->regs[idx & 31u] = value;
}

/* decode:
 *   解析指令的各个字段，供后续执行阶段使用。
 */
static DecodeStage decode(const CoreState *core, uint32_t inst) {
    DecodeStage s;
    s.raw = inst;
    s.pc = core->pc;
    s.opcode = HW_FIELD_OPCODE(inst);
    s.rd = HW_FIELD_RD(inst);
    s.rs1 = HW_FIELD_RS1(inst);
    s.rs2 = HW_FIELD_RS2(inst);
    s.funct3 = HW_FIELD_FUNCT3(inst);
    s.funct7 = HW_FIELD_FUNCT7(inst);
    return s;
}

/* core_reset:
 *   模拟硬件复位，将寄存器和 PC 置零。
 */
void core_reset(CoreState *core) {
    if (!core) {
        return;
    }
    for (int i = 0; i < HW_GPR_COUNT; ++i) {
        core->regs[i] = 0;
    }
    core->pc = 0;
}

/* core_regs/core_pc/core_set_pc:
 *   提供只读访问或写入 PC 的接口，方便调试与平台层调用。
 */
const uint32_t *core_regs(const CoreState *core) {
    return core ? core->regs : NULL;
}

uint32_t core_pc(const CoreState *core) {
    return core ? core->pc : 0;
}

void core_set_pc(CoreState *core, uint32_t pc) {
    if (core) {
        core->pc = pc;
    }
}

/*
 * core_step:
 *   RV32I 指令执行主函数，内部按 opcode 分类完成所有算术、访存和控制流操作。
 *   执行结束后会确保 x0 始终为 0，并返回执行结果。
 */
CoreStepResult core_step(CoreState *core, SystemMemory *mem, uint32_t inst_word) {
    CoreStepResult result = { .state = CORE_STEP_OK, .trap_code = 0 };
    if (!core || !mem) {
        result.state = CORE_STEP_FAULT;
        return result;
    }
    DecodeStage stage = decode(core, inst_word);
    uint32_t next_pc = core->pc + 4;

    switch (stage.opcode) {
        case 0x37: { /* LUI: 取高 20 位立即数写入 rd */
            uint32_t imm = inst_word & 0xfffff000u;
            write_reg(core, stage.rd, imm);
            core->pc = next_pc;
            break;
        }
        case 0x17: { /* AUIPC: 将 PC+立即数 写入 rd */
            uint32_t imm = inst_word & 0xfffff000u;
            write_reg(core, stage.rd, stage.pc + imm);
            core->pc = next_pc;
            break;
        }
        case 0x6f: { /* JAL: 计算跳转目标并保存返回地址 */
            uint32_t imm20 = (inst_word >> 31) & 0x1u;
            uint32_t imm10_1 = (inst_word >> 21) & 0x3ffu;
            uint32_t imm11 = (inst_word >> 20) & 0x1u;
            uint32_t imm19_12 = (inst_word >> 12) & 0xffu;
            uint32_t imm = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1);
            int32_t offset = hw_sign_extend(imm, 21);
            uint32_t target = (uint32_t)((int32_t)stage.pc + offset);
            write_reg(core, stage.rd, next_pc);
            core->pc = target;
            break;
        }
        case 0x67: { /* JALR: 寄存器间接跳转 */
            if (stage.funct3 != 0x0) {
                result.state = CORE_STEP_FAULT;
                return result;
            }
            uint32_t imm = (inst_word >> 20) & 0xfffu;
            int32_t offset = hw_sign_extend(imm, 12);
            uint32_t base = read_reg(core, stage.rs1);
            uint32_t target = ((uint32_t)((int32_t)base + offset)) & ~1u;
            write_reg(core, stage.rd, next_pc);
            core->pc = target;
            break;
        }
        case 0x63: { /* 分支指令族：根据比较结果决定是否跳转 */
            uint32_t imm12 = (inst_word >> 31) & 0x1u;
            uint32_t imm10_5 = (inst_word >> 25) & 0x3fu;
            uint32_t imm4_1 = (inst_word >> 8) & 0xfu;
            uint32_t imm11 = (inst_word >> 7) & 0x1u;
            uint32_t imm = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1);
            int32_t offset = hw_sign_extend(imm, 13);
            uint32_t src1 = read_reg(core, stage.rs1);
            uint32_t src2 = read_reg(core, stage.rs2);
            int take = 0;
            switch (stage.funct3) {
                case 0x0: take = ((int32_t)src1 == (int32_t)src2); break;
                case 0x1: take = ((int32_t)src1 != (int32_t)src2); break;
                case 0x4: take = ((int32_t)src1 < (int32_t)src2); break;
                case 0x5: take = ((int32_t)src1 >= (int32_t)src2); break;
                case 0x6: take = (src1 < src2); break;
                case 0x7: take = (src1 >= src2); break;
                default: take = 0; break;
            }
            core->pc = take ? (uint32_t)((int32_t)stage.pc + offset) : next_pc;
            break;
        }
        case 0x03: { /* LOAD 指令族：从内存读取数据 */
            uint32_t imm = (inst_word >> 20) & 0xfffu;
            int32_t offset = hw_sign_extend(imm, 12);
            uint32_t base = read_reg(core, stage.rs1);
            uint32_t addr = (uint32_t)((int32_t)base + offset);
            uint32_t data = 0;
            switch (stage.funct3) {
                case 0x0: data = (uint32_t)(int32_t)hw_sign_extend(memory_read8(mem, addr), 8); break;
                case 0x1: data = (uint32_t)(int32_t)hw_sign_extend(memory_read16(mem, addr), 16); break;
                case 0x2: data = memory_read32(mem, addr); break;
                case 0x4: data = memory_read8(mem, addr); break;
                case 0x5: data = memory_read16(mem, addr); break;
                default: result.state = CORE_STEP_FAULT; return result;
            }
            write_reg(core, stage.rd, data);
            core->pc = next_pc;
            break;
        }
        case 0x23: { /* STORE 指令族：向内存写入数据 */
            uint32_t imm11_5 = (inst_word >> 25) & 0x7fu;
            uint32_t imm4_0 = (inst_word >> 7) & 0x1fu;
            uint32_t imm = (imm11_5 << 5) | imm4_0;
            int32_t offset = hw_sign_extend(imm, 12);
            uint32_t base = read_reg(core, stage.rs1);
            uint32_t addr = (uint32_t)((int32_t)base + offset);
            uint32_t value = read_reg(core, stage.rs2);
            switch (stage.funct3) {
                case 0x0: memory_write8(mem, addr, (uint8_t)(value & 0xffu)); break;
                case 0x1: memory_write16(mem, addr, (uint16_t)(value & 0xffffu)); break;
                case 0x2: memory_write32(mem, addr, value); break;
                default: result.state = CORE_STEP_FAULT; return result;
            }
            core->pc = next_pc;
            break;
        }
        case 0x13: { /* 算术立即数指令族（ADDI、SLTI、XORI...） */
            uint32_t imm = (inst_word >> 20) & 0xfffu;
            int32_t simm = hw_sign_extend(imm, 12);
            uint32_t src = read_reg(core, stage.rs1);
            uint32_t shamt = imm & 0x1fu;
            uint32_t value = 0;
            switch (stage.funct3) {
                case 0x0: value = (uint32_t)((int32_t)src + simm); break;
                case 0x2: value = ((int32_t)src < simm) ? 1u : 0u; break;
                case 0x3: value = (src < (uint32_t)simm) ? 1u : 0u; break;
                case 0x4: value = src ^ (uint32_t)simm; break;
                case 0x6: value = src | (uint32_t)simm; break;
                case 0x7: value = src & (uint32_t)simm; break;
                case 0x1: value = src << shamt; break;
                case 0x5: {
                    uint32_t funct7 = (imm >> 5) & 0x7fu;
                    if (funct7 == 0x00) {
                        value = src >> shamt;
                    } else if (funct7 == 0x20) {
                        value = (uint32_t)((int32_t)src >> shamt);
                    } else {
                        result.state = CORE_STEP_FAULT;
                        return result;
                    }
                    break;
                }
                default:
                    result.state = CORE_STEP_FAULT;
                    return result;
            }
            write_reg(core, stage.rd, value);
            core->pc = next_pc;
            break;
        }
        case 0x33: { /* 寄存器算术指令族（ADD、SUB、AND...） */
            uint32_t src1 = read_reg(core, stage.rs1);
            uint32_t src2 = read_reg(core, stage.rs2);
            uint32_t value = 0;
            switch ((stage.funct7 << 3) | stage.funct3) {
                case 0x000: value = src1 + src2; break;
                case 0x200: value = src1 - src2; break;
                case 0x001: value = src1 << (src2 & 0x1fu); break;
                case 0x002: value = ((int32_t)src1 < (int32_t)src2) ? 1u : 0u; break;
                case 0x003: value = (src1 < src2) ? 1u : 0u; break;
                case 0x004: value = src1 ^ src2; break;
                case 0x005: value = src1 >> (src2 & 0x1fu); break;
                case 0x205: value = (uint32_t)((int32_t)src1 >> (src2 & 0x1fu)); break;
                case 0x006: value = src1 | src2; break;
                case 0x007: value = src1 & src2; break;
                default:
                    result.state = CORE_STEP_FAULT;
                    return result;
            }
            write_reg(core, stage.rd, value);
            core->pc = next_pc;
            break;
        }
        case 0x73: { /* SYSTEM 指令集合：这里只处理 ECALL/EBREAK */
            if (stage.raw == HW_INST_ECALL || stage.raw == HW_INST_EBREAK) {
                core->pc = next_pc;
                result.state = CORE_STEP_TRAP;
                result.trap_code = (int)core->regs[10];
                break;
            }
            result.state = CORE_STEP_FAULT;
            break;
        }
        default:
            result.state = CORE_STEP_FAULT;
            break;
    }

    core->regs[0] = 0;
    return result;
}
