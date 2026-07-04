// ace-sim: V1 指令模型(合成 trace)。
#pragma once
#include <bit>
#include <cstdint>
#include <vector>

namespace ace {

// FADD/FMUL/FDIV/FCVTIF(int→fp)/FCVTFI(fp→int)/FCMP(fp <):FP 算术(V-扩展 ② FP 数据通路)。
// CSRRW/ECALL/MRET:系统/异常(③ CSR + trap/中断),commit 边界串行 + 精确 trap。
// JAL(直接调用,目标=imm 取指即知)/ JALR(间接跳转/返回,目标=reg+off execute 才知):⑤ 调用/返回控制流。
enum class FuType : uint8_t {
  ALU, MUL, DIV, LOAD, STORE, BRANCH, JUMP,
  FADD, FMUL, FDIV, FCVTIF, FCVTFI, FCMP,
  CSRW, CSRR, ECALL, MRET,
  JAL, JALR,
  STA, STD,   // store 地址/数据分离微 op(⑥):由 STORE 在 dispatch 裂出,功能模型不可见
  HALT
};

inline constexpr int RA_REG = 1;  // 链接寄存器约定(RAS 启发式:JAL rd==RA=call,JALR rs==RA&&无 rd=ret)

// CSR 索引(小集合;ace-sim 非严格 RISC-V)
inline constexpr int CSR_MTVEC = 0;   // trap 向量 PC
inline constexpr int CSR_MEPC  = 1;   // 保存的 PC
inline constexpr int CSR_MCAUSE = 2;  // trap 原因
inline constexpr int CSR_COUNT = 8;
inline constexpr uint64_t CAUSE_ECALL = 8, CAUSE_TIMER_IRQ = 0x8000000000000007ull;

inline bool is_system(FuType t) {
  return t == FuType::CSRW || t == FuType::CSRR ||
         t == FuType::ECALL || t == FuType::MRET;
}

inline const char* fu_name(FuType t) {
  switch (t) {
    case FuType::ALU:    return "ALU";
    case FuType::MUL:    return "MUL";
    case FuType::DIV:    return "DIV";
    case FuType::LOAD:   return "LOAD";
    case FuType::STORE:  return "STORE";
    case FuType::BRANCH: return "BRANCH";
    case FuType::JUMP:   return "JUMP";
    case FuType::FADD:   return "FADD";
    case FuType::FMUL:   return "FMUL";
    case FuType::FDIV:   return "FDIV";
    case FuType::FCVTIF: return "FCVTIF";
    case FuType::FCVTFI: return "FCVTFI";
    case FuType::FCMP:   return "FCMP";
    case FuType::CSRW:   return "CSRW";
    case FuType::CSRR:   return "CSRR";
    case FuType::ECALL:  return "ECALL";
    case FuType::MRET:   return "MRET";
    case FuType::JAL:    return "JAL";
    case FuType::JALR:   return "JALR";
    case FuType::STA:    return "STA";
    case FuType::STD:    return "STD";
    case FuType::HALT:   return "HALT";
    default:             return "?";
  }
}

inline bool is_fp_arith(FuType t) {
  return t == FuType::FADD || t == FuType::FMUL || t == FuType::FDIV ||
         t == FuType::FCVTIF || t == FuType::FCVTFI || t == FuType::FCMP;
}

// 静态指令。dst/src 为寄存器号,-1 表示无。imm 兼作 ALU 立即数 / load 偏移 / 分支目标(绝对 PC 下标)。
// cond:分支条件(0=EQ,1=NE)。
struct Inst {
  FuType   fu   = FuType::ALU;
  int      dst  = -1;
  int      src0 = -1;
  int      src1 = -1;
  uint64_t imm  = 0;
  int      cond = 0;
};

using Program = std::vector<Inst>;

// 构造辅助
inline Inst alu (int dst, int s0, int s1, uint64_t imm = 0) { return {FuType::ALU,  dst, s0, s1, imm}; }
inline Inst mul (int dst, int s0, int s1)                   { return {FuType::MUL,  dst, s0, s1, 0}; }
inline Inst divi(int dst, int s0, int s1)                   { return {FuType::DIV,  dst, s0, s1, 0}; }
inline Inst load(int dst, int base, uint64_t off)          { return {FuType::LOAD, dst, base, -1, off}; }
// store:src0=base 地址寄存器,src1=data 数据寄存器,imm=偏移。无目的寄存器。
inline Inst store(int base, int data, uint64_t off)        { return {FuType::STORE, -1, base, data, off}; }
// 分支/跳转:imm=目标绝对 PC 下标。beq/bne 比较 src0/src1。
inline Inst beq(int s0, int s1, uint64_t target)           { return {FuType::BRANCH, -1, s0, s1, target, 0}; }
inline Inst bne(int s0, int s1, uint64_t target)           { return {FuType::BRANCH, -1, s0, s1, target, 1}; }
inline Inst jmp(uint64_t target)                           { return {FuType::JUMP, -1, -1, -1, target, 0}; }
inline Inst halt()                                         { return {FuType::HALT, -1, -1, -1, 0}; }

// ---- FP(② FP 数据通路)----
// 物理寄存器统一 64-bit,承载 int 或 double 的位型;f0..f31 = 架构寄存器 32..63(需 num_arch_regs>=64)。
inline int freg(int f) { return 32 + f; }                  // FP 架构寄存器号
inline double   f64(uint64_t u) { return std::bit_cast<double>(u); }
inline uint64_t fbits(double d) { return std::bit_cast<uint64_t>(d); }

inline Inst fadd(int d, int s0, int s1)   { return {FuType::FADD,   d, s0, s1, 0, 0}; }
inline Inst fmul(int d, int s0, int s1)   { return {FuType::FMUL,   d, s0, s1, 0, 0}; }
inline Inst fdivi(int d, int s0, int s1)  { return {FuType::FDIV,   d, s0, s1, 0, 0}; }
inline Inst fcvt_i2f(int d, int s0)       { return {FuType::FCVTIF, d, s0, -1, 0, 0}; }  // int -> double
inline Inst fcvt_f2i(int d, int s0)       { return {FuType::FCVTFI, d, s0, -1, 0, 0}; }  // double -> int(截断)
inline Inst fcmp_lt(int d, int s0, int s1){ return {FuType::FCMP,   d, s0, s1, 0, 0}; }  // (s0<s1)?1:0 -> int

// ---- 系统/CSR(③),commit 边界串行 + 精确 trap ----
// csrw:csr[idx] = value(imm);csrr:rd = csr[idx]。cond 兼作 csr 索引。
inline Inst csrw(int csr_idx, uint64_t value) { return {FuType::CSRW, -1, -1, -1, value, csr_idx}; }
inline Inst csrr(int rd, int csr_idx)         { return {FuType::CSRR, rd, -1, -1, 0, csr_idx}; }
inline Inst ecall() { return {FuType::ECALL, -1, -1, -1, 0, 0}; }  // 精确 trap -> mtvec
inline Inst mret()  { return {FuType::MRET,  -1, -1, -1, 0, 0}; }  // 返回 -> mepc

// ---- 调用/返回(⑤)----
// jal:直接调用,rd = pc+1(链接),pc = target(imm,取指即知)。rd=RA_REG 视为 call(RAS push)。
inline Inst jal(int rd, uint64_t target)          { return {FuType::JAL,  rd, -1, -1, target, 0}; }
// jalr:间接跳转,rd = pc+1,pc = reg[rs] + off(execute 才知 -> 需预测)。rs=RA_REG&&无 rd 视为 ret(RAS pop)。
inline Inst jalr(int rd, int rs, uint64_t off)    { return {FuType::JALR, rd, rs, -1, off, 0}; }
inline Inst call(uint64_t target)                 { return {FuType::JAL,  RA_REG, -1, -1, target, 0}; }
inline Inst ret()                                 { return {FuType::JALR, -1, RA_REG, -1, 0, 0}; }

inline bool is_call(const Inst& in) { return in.fu == FuType::JAL  && in.dst == RA_REG; }
inline bool is_ret (const Inst& in) { return in.fu == FuType::JALR && in.src0 == RA_REG && in.dst < 0; }

// basic-block 终结指令(控制流可能不落到 pc+1):⑦ DBT 块边界。
inline bool is_terminator(FuType t) {
  return t == FuType::BRANCH || t == FuType::JUMP || t == FuType::JAL || t == FuType::JALR ||
         t == FuType::ECALL || t == FuType::MRET || t == FuType::HALT;
}

}  // namespace ace
