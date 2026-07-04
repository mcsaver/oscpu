// ace-sim/core/decode: 译码分类(对应 npc OooDecode / 微 op 裂分)。
// 纯组合 *Gate:把一条静态指令分类到 dispatch 各处理类别,并标注是否需裂微 op(store->STA/STD,⑥)。
#pragma once
#include "isa/inst.hh"
#include "hw/module.hh"

namespace ace {

struct Decoded {
  bool is_halt   = false;
  bool is_store  = false;   // 用户态 STORE(dispatch 裂成 STA+STD)
  bool is_branch = false;
  bool is_jump   = false;
  bool is_jal    = false;
  bool is_jalr   = false;
  bool is_sys    = false;
  bool needs_dst = false;   // 需分配物理目的寄存器(触发 free-list backpressure 检查)
  bool needs_iq  = false;   // 需 IQ 条目(等待操作数);store 需 2 个(STA+STD)
};

class Decode : public Module {
 public:
  Decode() : Module("Decode") {}

  static Decoded decode(const Inst& in) {
    Decoded d;
    d.is_halt   = (in.fu == FuType::HALT);
    d.is_store  = (in.fu == FuType::STORE);
    d.is_branch = (in.fu == FuType::BRANCH);
    d.is_jump   = (in.fu == FuType::JUMP);
    d.is_jal    = (in.fu == FuType::JAL);
    d.is_jalr   = (in.fu == FuType::JALR);
    d.is_sys    = is_system(in.fu);
    d.needs_dst = !d.is_halt && !d.is_branch && !d.is_jump && in.dst >= 0;  // JAL/JALR 含 dst
    d.needs_iq  = !d.is_halt && !d.is_jump && !d.is_sys && !d.is_jal;        // JALR/store 需 IQ
    return d;
  }
};

}  // namespace ace
