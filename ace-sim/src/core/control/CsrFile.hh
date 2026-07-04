// ace-sim/core/control: CSR 文件 + trap 序列器(对应 npc CsrFile + Ooo*TrapRequestMux)。
// 持特权 CSR(mtvec/mepc/mcause + 通用);trap 保存 PC/cause 并给出 handler PC,mret 返回。
// 所有 CSR/trap 效应发生在 commit 边界(精确)。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"
#include "isa/inst.hh"

namespace ace {

class CsrFile : public Module {
 public:
  CsrFile() : Module("CsrFile"), csr_(CSR_COUNT, 0) {}

  uint64_t read(int idx) const { return csr_[idx]; }
  void     write(int idx, uint64_t v) { csr_[idx] = v; }

  // 精确 trap:保存返回 PC 与 cause,返回 handler PC(mtvec)。
  uint64_t trap(uint64_t epc, uint64_t cause) {
    csr_[CSR_MEPC] = epc;
    csr_[CSR_MCAUSE] = cause;
    return csr_[CSR_MTVEC];
  }
  uint64_t mret() const { return csr_[CSR_MEPC]; }  // 返回地址

 private:
  std::vector<uint64_t> csr_;
};

}  // namespace ace
