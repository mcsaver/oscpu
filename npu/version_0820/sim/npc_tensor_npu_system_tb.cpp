#include <verilated.h>
#include "VNpcTensorNpuSystemTop.h"
#include "svdpi.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <vector>

#ifndef NPC_DIRECT_NPU_SYSTEM_OOO_STATS
#define NPC_DIRECT_NPU_SYSTEM_OOO_STATS 0
#endif

namespace {
constexpr uint64_t kCpuBase=0x80000000ull, kGmemBase=0x10000000ull;
constexpr size_t kCpuBytes=8192, kGmemBytes=4096;
constexpr uint32_t kAddiBase=0x00100093u; // addi x1,x0,1
constexpr uint32_t kSlliBase=0x01f09093u; // slli x1,x1,31
constexpr uint32_t kLuiTable=0x000011b7u; // lui x3,0x1
constexpr uint32_t kAddTable=0x003081b3u; // add x3,x1,x3
constexpr uint32_t kNop=0x00000013u, kLo=0x0220305bu;
constexpr uint32_t kHi=0x0bf0305bu, kJal0=0x0000006fu;
constexpr uint64_t kLaunchBits=(uint64_t{kHi}<<32)|kLo;
constexpr uint32_t kContext=0x43414e01u;
constexpr uint64_t kSequence=0xa7a6a5a4a3a2a1a0ull;
constexpr uint64_t kMacroProducer=0xafaeadacabaaa9d3ull;
constexpr uint64_t kUserTag=0xb7b6b5b4b3b2b1b0ull;
constexpr uint64_t kHashLo=0x8786858483828180ull;
constexpr uint64_t kHashHi=0x9796959493929190ull;

constexpr std::array<uint32_t,16> kA={
  0x3f800000,0xbf800000,0x40600000,0x41200000,
  0x3f800000,0x3f800000,0x3f800000,0x3f800000,
  0x3f800000,0x3f800000,0x3f800000,0x3f800000,
  0x3f800000,0x3f800000,0x3f800000,0x3f800000};
constexpr std::array<uint32_t,16> kB={
  0x40000000,0x3f000000,0xbfa00000,0xc0a00000,
  0x40000000,0x40000000,0x40000000,0x40000000,
  0x40000000,0x40000000,0x40000000,0x40000000,
  0x40000000,0x40000000,0x40000000,0x40000000};
constexpr std::array<uint32_t,16> kGold={
  0x40400000,0xbf000000,0x40100000,0x40a00000,
  0x40400000,0x40400000,0x40400000,0x40400000,
  0x40400000,0x40400000,0x40400000,0x40400000,
  0x40400000,0x40400000,0x40400000,0x40400000};

std::array<uint8_t,kCpuBytes> cpu_mem{};
std::array<uint8_t,kGmemBytes> gmem{};
uint64_t cycles=0,commit_callbacks=0;
std::vector<uint64_t> commit_pcs,trap_pcs,handled_pcs;
std::vector<uint32_t> commit_insts,trap_causes,handled_causes;

struct TensorObserverSnapshot {
  uint64_t issued=0;
  uint64_t terminal=0;
  uint64_t completion=0;
  uint64_t wait_head=0;
  uint64_t wait_drain=0;
  uint64_t npu_backpressure=0;
  uint64_t serialize=0;
  uint64_t alloc_direct_issue=0;
  uint64_t attr_prelaunch_cancel=0;
  uint64_t attr_wait_not_exact_head=0;
  uint64_t attr_wait_launch_gate=0;
  uint64_t attr_wait_src_dependency=0;
  uint64_t attr_wait_src_value=0;
  uint64_t attr_wait_mem_active=0;
  uint64_t attr_wait_mem_retire=0;
  uint64_t attr_launch_to_offer=0;
  uint64_t attr_offer_backpressure=0;
  uint64_t attr_offer_accept=0;
  uint64_t attr_sent_terminal_absent=0;
  uint64_t attr_sent_terminal_stale=0;
  uint64_t attr_sent_terminal_accept=0;
  uint64_t attr_complete_wb_backpressure=0;
  uint64_t attr_complete_stale_drop=0;
  uint64_t attr_complete_wb_accept=0;
  uint64_t attr_invalid_state=0;
  uint64_t attr_sent_terminal_completion_stale=0;
  uint64_t attr_sent_terminal_wb_accept=0;
};
struct RtlCounter32Epoch {
  uint32_t last_raw=0;
  uint64_t extended=0;
  bool initialized=false;
};
struct TensorObserverEpochs {
  RtlCounter32Epoch issued;
  RtlCounter32Epoch terminal;
  RtlCounter32Epoch completion;
  RtlCounter32Epoch wait_head;
  RtlCounter32Epoch wait_drain;
  RtlCounter32Epoch npu_backpressure;
  RtlCounter32Epoch serialize;
  RtlCounter32Epoch alloc_direct_issue;
  RtlCounter32Epoch attr_prelaunch_cancel;
  RtlCounter32Epoch attr_wait_not_exact_head;
  RtlCounter32Epoch attr_wait_launch_gate;
  RtlCounter32Epoch attr_wait_src_dependency;
  RtlCounter32Epoch attr_wait_src_value;
  RtlCounter32Epoch attr_wait_mem_active;
  RtlCounter32Epoch attr_wait_mem_retire;
  RtlCounter32Epoch attr_launch_to_offer;
  RtlCounter32Epoch attr_offer_backpressure;
  RtlCounter32Epoch attr_offer_accept;
  RtlCounter32Epoch attr_sent_terminal_absent;
  RtlCounter32Epoch attr_sent_terminal_stale;
  RtlCounter32Epoch attr_sent_terminal_accept;
  RtlCounter32Epoch attr_complete_wb_backpressure;
  RtlCounter32Epoch attr_complete_stale_drop;
  RtlCounter32Epoch attr_complete_wb_accept;
  RtlCounter32Epoch attr_invalid_state;
  RtlCounter32Epoch attr_sent_terminal_completion_stale;
  RtlCounter32Epoch attr_sent_terminal_wb_accept;
};
uint64_t extend_rtl_counter32(RtlCounter32Epoch*epoch,uint32_t raw){
  if(!epoch->initialized){epoch->last_raw=raw;epoch->extended=raw;epoch->initialized=true;return epoch->extended;}
  const uint32_t delta=raw-epoch->last_raw;
  epoch->last_raw=raw;epoch->extended+=uint64_t{delta};return epoch->extended;
}
bool sum_u64(const uint64_t*values,size_t count,uint64_t*sum){
  if(!sum)return false;*sum=0;
  for(size_t i=0;i<count;++i){
    if((~uint64_t{0})-*sum<values[i])return false;
    *sum+=values[i];
  }
  return true;
}
TensorObserverSnapshot tensor_observer{};
TensorObserverEpochs tensor_observer_epochs{};
uint64_t cpu_active_serialize_edges=0;
bool system_posedge_serialize_sample=false;

bool inside(uint64_t a,uint64_t n,uint64_t base,size_t bytes){
  if(a<base)return false; uint64_t o=a-base;
  return o<=bytes&&n<=bytes-o;
}
bool cpu_read(uint64_t a,uint32_t n,uint64_t*v){
  if(!n||n>8||!inside(a,n,kCpuBase,kCpuBytes))return false;
  *v=0; size_t o=size_t(a-kCpuBase);
  for(uint32_t i=0;i<n;++i)*v|=uint64_t(cpu_mem[o+i])<<(8*i); return true;
}
bool cpu_write(uint64_t a,uint64_t v,uint64_t m){
  if(!inside(a,1,kCpuBase,kCpuBytes))return false; size_t o=size_t(a-kCpuBase);
  for(unsigned i=0;i<8;++i)if((m>>i)&1u){if(!inside(a+i,1,kCpuBase,kCpuBytes))return false;cpu_mem[o+i]=uint8_t(v>>(8*i));} return true;
}
bool gmem_read(uint64_t a,uint32_t n,uint64_t*v){
  if(!n||n>8||!inside(a,n,kGmemBase,kGmemBytes))return false;
  *v=0;size_t o=size_t(a-kGmemBase);
  for(uint32_t i=0;i<n;++i)*v|=uint64_t(gmem[o+i])<<(8*i);return true;
}
bool gmem_write(uint64_t a,uint64_t v,uint64_t m){
  if(!inside(a,1,kGmemBase,kGmemBytes))return false;size_t o=size_t(a-kGmemBase);
  for(unsigned i=0;i<8;++i)if((m>>i)&1u){if(!inside(a+i,1,kGmemBase,kGmemBytes))return false;gmem[o+i]=uint8_t(v>>(8*i));}return true;
}
void put_cpu32(uint64_t a,uint32_t v){size_t o=size_t(a-kCpuBase);for(unsigned i=0;i<4;++i)cpu_mem[o+i]=uint8_t(v>>(8*i));}
void put_cpu64(uint64_t a,uint64_t v){size_t o=size_t(a-kCpuBase);for(unsigned i=0;i<8;++i)cpu_mem[o+i]=uint8_t(v>>(8*i));}
void put_gmem32(uint64_t a,uint32_t v){size_t o=size_t(a-kGmemBase);for(unsigned i=0;i<4;++i)gmem[o+i]=uint8_t(v>>(8*i));}
uint32_t get_gmem32(uint64_t a){size_t o=size_t(a-kGmemBase);uint32_t v=0;for(unsigned i=0;i<4;++i)v|=uint32_t(gmem[o+i])<<(8*i);return v;}
uint32_t enc_ld(unsigned rd,unsigned rs1,unsigned imm){return ((imm&0xfff)<<20)|(rs1<<15)|(3u<<12)|(rd<<7)|3u;}
uint32_t enc_cfg(unsigned index,unsigned rs1){return (5u<<25)|(index<<20)|(rs1<<15)|(4u<<12)|(31u<<7)|0x5bu;}
using Descriptor=std::array<uint64_t,30>;
struct Layout{
  std::vector<uint64_t> cfg_pcs;
  std::vector<uint64_t> launch_pcs;
  std::vector<uint64_t> tensor_pcs;
  uint64_t partial_cfg_pc=0,bad_launch_pc=0;
};
Descriptor make_descriptor(unsigned id,uint64_t src0,uint64_t src1,uint64_t dst){
  return Descriptor{
    (uint64_t{0x11}<<32)|0x514e0010u,
    (uint64_t{1}<<32)|kContext,
    kSequence+id,kMacroProducer+id,kUserTag+id,
    (uint64_t{1}<<32)|1u,kHashLo+id,kHashHi+id,
    0,(uint64_t{1}<<32),src0,src1,0,dst,0,16,
    1,0,0,64,64,0,64,src0,64,0x97,src1,64,dst,64};
}
Layout install_program(const std::vector<Descriptor>& descriptors,bool add_bad_launch){
  cpu_mem.fill(0);Layout layout;
  put_cpu32(kCpuBase,kAddiBase);put_cpu32(kCpuBase+4,kSlliBase);
  put_cpu32(kCpuBase+8,kLuiTable);put_cpu32(kCpuBase+12,kAddTable);
  uint64_t pc=kCpuBase+16;
  for(size_t tx=0;tx<descriptors.size();++tx){
    const unsigned table_off=unsigned(tx)*0x100u;
    for(unsigned i=0;i<30;++i){
      put_cpu64(kCpuBase+0x1000+table_off+8*i,descriptors[tx][i]);
      put_cpu32(pc,enc_ld(2,3,table_off+8*i));put_cpu32(pc+4,kNop);
      put_cpu32(pc+8,enc_cfg(i,2));put_cpu32(pc+12,kNop);
      layout.cfg_pcs.push_back(pc+8);layout.tensor_pcs.push_back(pc+8);pc+=16;
    }
    layout.launch_pcs.push_back(pc);layout.tensor_pcs.push_back(pc);
    put_cpu32(pc,kLo);put_cpu32(pc+4,kHi);pc+=8;
  }
  if(add_bad_launch){
    put_cpu32(pc,enc_ld(2,3,0));put_cpu32(pc+4,kNop);
    layout.partial_cfg_pc=pc+8;layout.tensor_pcs.push_back(pc+8);
    put_cpu32(pc+8,enc_cfg(0,2));put_cpu32(pc+12,kNop);pc+=16;
    layout.bad_launch_pc=pc;layout.tensor_pcs.push_back(pc);
    put_cpu32(pc,kLo);put_cpu32(pc+4,kHi);put_cpu32(pc+8,kJal0);
  }else put_cpu32(pc,kJal0);
  return layout;
}
void init_vectors(const std::vector<Descriptor>& descriptors){
  gmem.fill(0);
  for(const auto& d:descriptors){
    const uint64_t src0=d[10],src1=d[11],dst=d[13];
    for(unsigned i=0;i<16;++i){put_gmem32(src0+4*i,kA[i]);put_gmem32(src1+4*i,kB[i]);put_gmem32(dst+4*i,0xa5a5a5a5);}
  }
}
struct Txn{uint64_t bits;uint8_t pid;uint8_t error;uint8_t code;};
} // namespace

extern "C" void npc_ifetch_sized(uint64_t a,uint32_t n,uint64_t*d,svBit*e){*d=0;*e=cpu_read(a,n,d)?0:1;}
extern "C" void npc_mem_read_sized(uint64_t a,uint32_t n,uint64_t*d,svBit*e){*d=0;*e=cpu_read(a,n,d)?0:1;}
extern "C" void npc_mem_write(uint64_t a,uint64_t d,uint64_t m,svBit*e){*e=cpu_write(a,d,m)?0:1;}
extern "C" void npc_commit_event(uint64_t pc,uint32_t inst,uint64_t,uint32_t,uint32_t,uint64_t,uint32_t){++commit_callbacks;commit_pcs.push_back(pc);commit_insts.push_back(inst);}
extern "C" void npc_exit_event(uint32_t,uint32_t,uint32_t,uint64_t,uint64_t){}
extern "C" uint64_t npc_current_cycles(){return cycles;}
extern "C" uint64_t npc_current_commits(){return commit_callbacks;}
extern "C" void npc_mmio_load_event(){}
extern "C" void npc_trap_event(uint32_t c,uint64_t pc,uint64_t){trap_causes.push_back(c);trap_pcs.push_back(pc);}
extern "C" void npc_handled_trap_event(uint32_t,uint32_t c,uint64_t pc,uint64_t){handled_causes.push_back(c);handled_pcs.push_back(pc);}
extern "C" void npc_arch_csr_event(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t){}
extern "C" void npc_arch_fpr_event(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t){}
extern "C" void npc_uart_event(uint32_t,uint32_t,uint32_t,uint32_t,uint64_t,uint32_t,uint64_t){}
extern "C" int npc_uart_rx_pop(uint32_t*d){*d=0;return 0;}
extern "C" void npc_irq_event(uint32_t,uint32_t){}
extern "C" void npc_virtio_blk_read(uint32_t,uint64_t*d,svBit*e,svBit*i){*d=0;*e=1;*i=0;}
extern "C" void npc_virtio_blk_write(uint32_t,uint64_t,uint64_t,svBit*e,svBit*i){*e=1;*i=0;}
extern "C" void npc_virtio_blk_irq(svBit*i){*i=0;}
extern "C" void npc_ooo_cycle_event(
    uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,
    uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,
    uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,
    uint32_t,uint32_t,uint64_t,uint64_t,uint32_t,uint32_t,uint32_t,uint32_t,
    uint32_t tensor_issued,uint32_t tensor_terminal,
    uint32_t tensor_completion,uint32_t tensor_wait_head,
    uint32_t tensor_wait_drain,uint32_t tensor_npu_backpressure,
    uint32_t tensor_serialize,
    uint32_t tensor_alloc_direct_issue,
    uint32_t tensor_attr_prelaunch_cancel,
    uint32_t tensor_attr_wait_not_exact_head,
    uint32_t tensor_attr_wait_launch_gate,
    uint32_t tensor_attr_wait_src_dependency,
    uint32_t tensor_attr_wait_src_value,
    uint32_t tensor_attr_wait_mem_active,
    uint32_t tensor_attr_wait_mem_retire,
    uint32_t tensor_attr_launch_to_offer,
    uint32_t tensor_attr_offer_backpressure,
    uint32_t tensor_attr_offer_accept,
    uint32_t tensor_attr_sent_terminal_absent,
    uint32_t tensor_attr_sent_terminal_stale,
    uint32_t tensor_attr_sent_terminal_accept,
    uint32_t tensor_attr_complete_wb_backpressure,
    uint32_t tensor_attr_complete_stale_drop,
    uint32_t tensor_attr_complete_wb_accept,
    uint32_t tensor_attr_invalid_state,
    uint32_t tensor_attr_sent_terminal_completion_stale,
    uint32_t tensor_attr_sent_terminal_wb_accept){
#if NPC_DIRECT_NPU_SYSTEM_OOO_STATS
  tensor_observer.issued=extend_rtl_counter32(&tensor_observer_epochs.issued,tensor_issued);
  tensor_observer.terminal=extend_rtl_counter32(&tensor_observer_epochs.terminal,tensor_terminal);
  tensor_observer.completion=extend_rtl_counter32(&tensor_observer_epochs.completion,tensor_completion);
  tensor_observer.wait_head=extend_rtl_counter32(&tensor_observer_epochs.wait_head,tensor_wait_head);
  tensor_observer.wait_drain=extend_rtl_counter32(&tensor_observer_epochs.wait_drain,tensor_wait_drain);
  tensor_observer.npu_backpressure=extend_rtl_counter32(&tensor_observer_epochs.npu_backpressure,tensor_npu_backpressure);
  tensor_observer.serialize=extend_rtl_counter32(&tensor_observer_epochs.serialize,tensor_serialize);
  tensor_observer.alloc_direct_issue=extend_rtl_counter32(&tensor_observer_epochs.alloc_direct_issue,tensor_alloc_direct_issue);
  tensor_observer.attr_prelaunch_cancel=extend_rtl_counter32(&tensor_observer_epochs.attr_prelaunch_cancel,tensor_attr_prelaunch_cancel);
  tensor_observer.attr_wait_not_exact_head=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_not_exact_head,tensor_attr_wait_not_exact_head);
  tensor_observer.attr_wait_launch_gate=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_launch_gate,tensor_attr_wait_launch_gate);
  tensor_observer.attr_wait_src_dependency=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_src_dependency,tensor_attr_wait_src_dependency);
  tensor_observer.attr_wait_src_value=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_src_value,tensor_attr_wait_src_value);
  tensor_observer.attr_wait_mem_active=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_mem_active,tensor_attr_wait_mem_active);
  tensor_observer.attr_wait_mem_retire=extend_rtl_counter32(&tensor_observer_epochs.attr_wait_mem_retire,tensor_attr_wait_mem_retire);
  tensor_observer.attr_launch_to_offer=extend_rtl_counter32(&tensor_observer_epochs.attr_launch_to_offer,tensor_attr_launch_to_offer);
  tensor_observer.attr_offer_backpressure=extend_rtl_counter32(&tensor_observer_epochs.attr_offer_backpressure,tensor_attr_offer_backpressure);
  tensor_observer.attr_offer_accept=extend_rtl_counter32(&tensor_observer_epochs.attr_offer_accept,tensor_attr_offer_accept);
  tensor_observer.attr_sent_terminal_absent=extend_rtl_counter32(&tensor_observer_epochs.attr_sent_terminal_absent,tensor_attr_sent_terminal_absent);
  tensor_observer.attr_sent_terminal_stale=extend_rtl_counter32(&tensor_observer_epochs.attr_sent_terminal_stale,tensor_attr_sent_terminal_stale);
  tensor_observer.attr_sent_terminal_accept=extend_rtl_counter32(&tensor_observer_epochs.attr_sent_terminal_accept,tensor_attr_sent_terminal_accept);
  tensor_observer.attr_complete_wb_backpressure=extend_rtl_counter32(&tensor_observer_epochs.attr_complete_wb_backpressure,tensor_attr_complete_wb_backpressure);
  tensor_observer.attr_complete_stale_drop=extend_rtl_counter32(&tensor_observer_epochs.attr_complete_stale_drop,tensor_attr_complete_stale_drop);
  tensor_observer.attr_complete_wb_accept=extend_rtl_counter32(&tensor_observer_epochs.attr_complete_wb_accept,tensor_attr_complete_wb_accept);
  tensor_observer.attr_invalid_state=extend_rtl_counter32(&tensor_observer_epochs.attr_invalid_state,tensor_attr_invalid_state);
  tensor_observer.attr_sent_terminal_completion_stale=extend_rtl_counter32(&tensor_observer_epochs.attr_sent_terminal_completion_stale,tensor_attr_sent_terminal_completion_stale);
  tensor_observer.attr_sent_terminal_wb_accept=extend_rtl_counter32(&tensor_observer_epochs.attr_sent_terminal_wb_accept,tensor_attr_sent_terminal_wb_accept);
  if(system_posedge_serialize_sample)++cpu_active_serialize_edges;
#else
  (void)tensor_issued;(void)tensor_terminal;(void)tensor_completion;
  (void)tensor_wait_head;(void)tensor_wait_drain;
  (void)tensor_npu_backpressure;(void)tensor_serialize;
  (void)tensor_alloc_direct_issue;
  (void)tensor_attr_prelaunch_cancel;
  (void)tensor_attr_wait_not_exact_head;
  (void)tensor_attr_wait_launch_gate;
  (void)tensor_attr_wait_src_dependency;
  (void)tensor_attr_wait_src_value;
  (void)tensor_attr_wait_mem_active;
  (void)tensor_attr_wait_mem_retire;
  (void)tensor_attr_launch_to_offer;
  (void)tensor_attr_offer_backpressure;
  (void)tensor_attr_offer_accept;
  (void)tensor_attr_sent_terminal_absent;
  (void)tensor_attr_sent_terminal_stale;
  (void)tensor_attr_sent_terminal_accept;
  (void)tensor_attr_complete_wb_backpressure;
  (void)tensor_attr_complete_stale_drop;
  (void)tensor_attr_complete_wb_accept;
  (void)tensor_attr_invalid_state;
  (void)tensor_attr_sent_terminal_completion_stale;
  (void)tensor_attr_sent_terminal_wb_accept;
#endif
}

int main(int argc,char**argv){
  Verilated::commandArgs(argc,argv);VNpcTensorNpuSystemTop dut;
  const Descriptor abort_desc=make_descriptor(0x40,kGmemBase+0xa00,kGmemBase+0xa80,kGmemBase+0xb00);
  const std::vector<Descriptor> recovery_descs={
    make_descriptor(0,kGmemBase+0x100,kGmemBase+0x180,kGmemBase+0x200),
    make_descriptor(1,kGmemBase+0x400,kGmemBase+0x480,kGmemBase+0x500),
    make_descriptor(2,kGmemBase+0x700,kGmemBase+0x780,kGmemBase+0x800)};
  std::vector<Descriptor> active_descs{abort_desc};Layout layout=install_program(active_descs,false);init_vectors(active_descs);
  dut.clk=0;dut.rst=1;dut.terminal_allow_i=1;dut.gmem_req_ready_i=0;
  dut.gmem_rsp_valid_i=0;dut.gmem_rsp_rdata_i=0;dut.gmem_rsp_error_i=0;
  // This directed CPU-boundary test intentionally elaborates the public
  // default (portal disabled).  Drive every new input inactive and prove that
  // the disabled branch cannot publish transport activity or ledger state.
  dut.q8_portal_req_ready_i=0;dut.q8_portal_rsp_valid_i=0;
  dut.q8_portal_rsp_mask_i=0;dut.q8_portal_rsp_error_i=0;
  for(unsigned i=0;i<34;++i)dut.q8_portal_rsp_blocks_i[i]=0;
  dut.f32_alu_portal_req_ready_i=0;
  dut.f32_alu_portal_rsp_valid_i=0;
  dut.f32_alu_portal_rsp_mask_i=0;
  dut.f32_alu_portal_rsp_error_i=0;
  for(unsigned i=0;i<8;++i){
    dut.f32_alu_portal_rsp_src0_data_i[i]=0;
    dut.f32_alu_portal_rsp_src1_data_i[i]=0;
  }
  dut.f32_mover_portal_req_ready_i=0;
  dut.f32_mover_portal_rsp_valid_i=0;
  dut.f32_mover_portal_rsp_mask_i=0;
  dut.f32_mover_portal_rsp_error_i=0;
  for(unsigned i=0;i<16;++i)
    dut.f32_mover_portal_rsp_rdata_i[i]=0;

  unsigned failures=0,cfg_commits=0,legal_launches=0,macro_terminals=0;
  unsigned stall_left=4,term_cycles=0;uint64_t req=0,rsp=0,reads=0,writes=0,req_at_bad=~uint64_t{0};
  uint64_t system_serialize_edges=0;
  bool recovery_phase=false,abort_launch_seen=false,bad_cmd_seen=false,bad_commit=false,bad_no_rd=false;
  bool resident_before29=false,resident_after29=false,held_req=false,saw_gmem_stall=false,term_hold=false,term_seen=false;
  uint64_t held_addr=0,held_data=0,held_npu_cycles=0;uint8_t held_write=0,held_strb=0,held_pid=0,held_err=0,held_code=0;
  std::vector<Txn> cmds,terms;std::vector<uint8_t> launch_pids;
  std::vector<uint64_t> tensor_issue_edges,tensor_terminal_edges;
  std::vector<uint64_t> tensor_commit_edges(layout.tensor_pcs.size(),0);
  std::array<bool,3> allow_low_seen{},macro_commit_seen{},completion_seen{};
  auto fail=[&](const char*m){std::fprintf(stderr,"[CHECK-FAIL] %s\n",m);++failures;};
  auto check=[&](bool x,const char*m){if(!x)fail(m);};
  auto portal_outputs_zero=[&](){
    if(dut.q8_portal_req_valid_o||dut.q8_portal_rsp_ready_o||
       dut.q8_portal_req_mask_o||dut.q8_portal_request_count_o||
       dut.q8_portal_response_count_o||dut.q8_portal_block_count_o||
       dut.q8_portal_byte_count_o||dut.q8_portal_outstanding_o)return false;
    for(unsigned i=0;i<8;++i)if(dut.q8_portal_req_addr_o[i])return false;
    if(dut.f32_alu_portal_req_valid_o||
       dut.f32_alu_portal_req_write_o||
       dut.f32_alu_portal_rsp_ready_o||
       dut.f32_alu_portal_req_mask_o||
       dut.f32_alu_portal_request_groups_o||
       dut.f32_alu_portal_response_groups_o||
       dut.f32_alu_portal_read_groups_o||
       dut.f32_alu_portal_write_groups_o||
       dut.f32_alu_portal_input_words_o||
       dut.f32_alu_portal_output_words_o||
       dut.f32_alu_portal_read_bytes_o||
       dut.f32_alu_portal_write_bytes_o||
       dut.f32_alu_portal_outstanding_o)return false;
    for(unsigned i=0;i<16;++i){
      if(dut.f32_alu_portal_req_src0_addr_o[i]||
         dut.f32_alu_portal_req_src1_addr_o[i]||
         dut.f32_alu_portal_req_dst_addr_o[i])return false;
    }
    for(unsigned i=0;i<8;++i)
      if(dut.f32_alu_portal_req_wdata_o[i])return false;
    if(dut.f32_mover_portal_req_valid_o||
       dut.f32_mover_portal_req_write_o||
       dut.f32_mover_portal_rsp_ready_o||
       dut.f32_mover_portal_req_mask_o||
       dut.f32_mover_portal_request_groups_o||
       dut.f32_mover_portal_response_groups_o||
       dut.f32_mover_portal_read_groups_o||
       dut.f32_mover_portal_write_groups_o||
       dut.f32_mover_portal_read_words_o||
       dut.f32_mover_portal_write_words_o||
       dut.f32_mover_portal_read_bytes_o||
       dut.f32_mover_portal_write_bytes_o||
       dut.f32_mover_portal_outstanding_o)return false;
    for(unsigned i=0;i<32;++i)
      if(dut.f32_mover_portal_req_addr_o[i])return false;
    for(unsigned i=0;i<16;++i)
      if(dut.f32_mover_portal_req_wdata_o[i])return false;
    return true;
  };
  auto verify_completion=[&](size_t idx){
    if(idx>=active_descs.size()){fail("unexpected raw macro completion");return;}
    const auto&d=active_descs[idx];
    check(dut.macro_completion_valid_o,"identity match lacked raw macro completion valid");
    check(dut.npu_identity_match_o,"wrapper rejected exact completion identity");
    check(!dut.macro_completion_status_o&&!dut.macro_completion_error_class_o,"success macro status/error_class mismatch");
    check(dut.macro_completion_kernel_id_o==uint32_t(d[0])&&dut.macro_completion_command_flags_o==uint32_t(d[0]>>32)&&dut.macro_completion_vector_flags_o==uint32_t(d[9]),"macro kernel/flags echo mismatch");
    check(dut.macro_completion_context_id_o==uint32_t(d[1])&&dut.macro_completion_sequence_id_o==d[2]&&dut.completion_macro_producer_id_o==d[3]&&dut.macro_completion_user_tag_o==d[4],"full macro identity echo mismatch");
    check(dut.macro_completion_covered_node_count_o==uint32_t(d[5])&&dut.macro_completion_node_hash_lo_o==d[6]&&dut.macro_completion_node_hash_hi_o==d[7],"macro node identity echo mismatch");
    check(dut.macro_completion_npu_cycles_o&&dut.macro_completion_gmem_read_bytes_o==128&&dut.macro_completion_gmem_write_bytes_o==64&&dut.macro_completion_q8_mac_count_o==0&&dut.macro_completion_vector_element_count_o==16&&dut.macro_completion_state_update_count_o==0,"macro completion counters mismatch");
  };
  auto tick=[&](){
    const uint64_t edge=cycles+1;
    dut.clk=0;dut.gmem_req_ready_i=(stall_left==0&&!dut.gmem_rsp_valid_i)?1:0;dut.eval();
    const bool cf=dut.cpu_tensor_cmd_valid_o&&dut.cpu_tensor_cmd_ready_o;
    const bool tf=dut.npu_terminal_valid_o&&dut.npu_terminal_ready_o;
    const bool qf=dut.gmem_req_valid_o&&dut.gmem_req_ready_i;
    const bool rf=dut.gmem_rsp_valid_i&&dut.gmem_rsp_ready_o;
    const bool raw_completion=dut.macro_completion_valid_o;
    const Txn c{dut.cpu_tensor_cmd_bits_o,uint8_t(dut.cpu_tensor_cmd_producer_id_o),0,0};
    const Txn t{0,uint8_t(dut.npu_terminal_producer_id_o),uint8_t(dut.npu_terminal_error_o),uint8_t(dut.npu_terminal_error_code_o)};
    const uint64_t qa=dut.gmem_req_addr_o,qd=dut.gmem_req_wdata_o;const uint8_t qw=dut.gmem_req_write_o,qs=dut.gmem_req_wstrb_o;
    if(!dut.rst&&dut.descriptor_inflight_o&&legal_launches>macro_terminals&&macro_terminals<allow_low_seen.size()&&!dut.terminal_allow_i)allow_low_seen[macro_terminals]=true;
    if(raw_completion)verify_completion(macro_terminals);
    if(dut.gmem_req_valid_o&&!dut.gmem_req_ready_i){
      saw_gmem_stall=true;
      if(!held_req){held_req=true;held_addr=qa;held_data=qd;held_write=qw;held_strb=qs;}
      else check(held_addr==qa&&held_data==qd&&held_write==qw&&held_strb==qs,"GMEM payload changed under backpressure");
      if(stall_left)--stall_left;
    }
    if(term_hold&&dut.npu_terminal_valid_o){
      if(!term_seen){term_seen=true;held_pid=t.pid;held_err=t.error;held_code=t.code;held_npu_cycles=dut.macro_completion_npu_cycles_o;}
      else check(held_pid==t.pid&&held_err==t.error&&held_code==t.code&&held_npu_cycles==dut.macro_completion_npu_cycles_o,"terminal/completion payload changed under backpressure");
      check(!dut.npu_terminal_ready_o,"terminal ready escaped throttle");++term_cycles;
    }
    system_posedge_serialize_sample=!dut.rst&&dut.cpu_tensor_serialize_o;
    if(system_posedge_serialize_sample)++system_serialize_edges;
    dut.clk=1;dut.eval();++cycles;
    if(!dut.rst&&cf){
      cmds.push_back(c);
      if(recovery_phase)tensor_issue_edges.push_back(edge);
      if(c.bits==kLaunchBits){
        if(legal_launches<active_descs.size()){
          launch_pids.push_back(c.pid);++legal_launches;
          if(!recovery_phase)abort_launch_seen=true;
          else if(legal_launches==2){term_hold=true;term_seen=false;term_cycles=0;dut.terminal_allow_i=0;}
        }else{bad_cmd_seen=true;req_at_bad=req;}
      }else{
        const unsigned idx=(uint32_t(c.bits)>>20)&31u;
        if(idx<29&&dut.direct_f32_desc_resident_o)resident_before29=true;
        if(idx==29&&dut.direct_f32_desc_resident_o)resident_after29=true;
      }
    }
    if(!dut.rst&&tf){
      terms.push_back(t);
      if(recovery_phase)tensor_terminal_edges.push_back(edge);
      if(raw_completion){
        if(macro_terminals<completion_seen.size())completion_seen[macro_terminals]=true;
        ++macro_terminals;
        check(dut.launch_cpu_pid_o==0&&!dut.descriptor_inflight_o&&!dut.direct_f32_desc_resident_o,"consumed macro left stale descriptor/PID state");
      }
    }
    if(!dut.rst&&dut.cpu_commit0_valid_o){
      const uint64_t cp=dut.cpu_commit0_pc_o;
      if(recovery_phase){
        const auto tensor_it=std::find(layout.tensor_pcs.begin(),
                                       layout.tensor_pcs.end(),cp);
        if(tensor_it!=layout.tensor_pcs.end()){
          const size_t idx=size_t(tensor_it-layout.tensor_pcs.begin());
          check(idx<tensor_commit_edges.size(),
                "Tensor commit timeline index escaped layout");
          if(idx<tensor_commit_edges.size()){
            check(tensor_commit_edges[idx]==0,
                  "Tensor instruction committed more than once");
            tensor_commit_edges[idx]=edge;
          }
        }
      }
      if(std::find(layout.cfg_pcs.begin(),layout.cfg_pcs.end(),cp)!=layout.cfg_pcs.end()){
        check(!dut.cpu_commit0_exception_o&&!dut.cpu_commit0_rd_en_o,"CONFIG did not commit success/no-rd");++cfg_commits;
      }
      if(recovery_phase&&cp==layout.partial_cfg_pc){check(!dut.cpu_commit0_exception_o&&!dut.cpu_commit0_rd_en_o,"partial CONFIG word0 commit bad");++cfg_commits;}
      const auto launch_it=std::find(layout.launch_pcs.begin(),layout.launch_pcs.end(),cp);
      if(launch_it!=layout.launch_pcs.end()){
        const size_t idx=size_t(launch_it-layout.launch_pcs.begin());
        check(macro_terminals>idx,"macro retired before real terminal");
        check(!dut.cpu_commit0_exception_o&&!dut.cpu_commit0_rd_en_o,"legal macro commit failed");
        if(idx<macro_commit_seen.size())macro_commit_seen[idx]=true;
      }
      if(recovery_phase&&cp==layout.bad_launch_pc){bad_commit=dut.cpu_commit0_exception_o;bad_no_rd=!dut.cpu_commit0_rd_en_o;}
    }
    if(rf){dut.gmem_rsp_valid_i=0;dut.gmem_rsp_rdata_i=0;dut.gmem_rsp_error_i=0;++rsp;}
    if(qf){
      ++req;held_req=false;uint64_t x=0;
      check(!(qa&7)&&inside(qa,8,kGmemBase,kGmemBytes),"NPU GMEM escaped separate aperture");
      if(qw){++writes;check(qs==0x0f||qs==0xf0,"bad F32 write strobe");check(gmem_write(qa,qd,qs),"GMEM write bounds");}
      else{++reads;check(!qd&&!qs,"GMEM read carried write payload");check(gmem_read(qa,8,&x),"GMEM read bounds");}
      dut.gmem_rsp_valid_i=1;dut.gmem_rsp_rdata_i=x;dut.gmem_rsp_error_i=0;
    }
    if(term_hold&&term_seen&&term_cycles>=4){term_hold=false;dut.terminal_allow_i=1;}
  };

  for(unsigned i=0;i<10;++i)tick();
  check(!dut.direct_f32_desc_resident_o&&!dut.descriptor_inflight_o&&dut.descriptor_expected_index_o==0&&dut.launch_cpu_pid_o==0,"initial reset did not clear descriptor state");
  check(portal_outputs_zero(),"default-disabled portal exposed state/activity during reset");
  dut.rst=0;
  for(unsigned i=0;i<20000&&!abort_launch_seen;++i)tick();
  check(abort_launch_seen&&dut.descriptor_inflight_o,"reset-abort macro did not reach inflight");
  tick();
  check(dut.descriptor_inflight_o&&macro_terminals==0,"reset-abort transaction completed before gated reset");
  dut.clk=0;dut.eval(); // Capture the closed CPU gate before reset is asserted.
  dut.rst=1;dut.terminal_allow_i=1;dut.gmem_rsp_valid_i=0;dut.gmem_rsp_rdata_i=0;dut.gmem_rsp_error_i=0;
  for(unsigned i=0;i<10;++i)tick();
  check(!dut.direct_f32_desc_resident_o&&!dut.descriptor_inflight_o&&dut.descriptor_expected_index_o==0&&dut.launch_cpu_pid_o==0,"inflight reset left stale descriptor/PID state");
  check(!dut.macro_completion_valid_o&&!dut.npu_terminal_valid_o,"inflight reset left stale completion/terminal");
  check(dut.npu_command_count_o==0&&dut.npu_completion_count_o==0&&dut.npu_required_issued_o==0&&dut.npu_required_completed_o==0,"inflight reset left stale public counters");

  const uint64_t pre_recovery_cycles=cycles;
  active_descs=recovery_descs;layout=install_program(active_descs,true);init_vectors(active_descs);
  recovery_phase=true;cmds.clear();terms.clear();launch_pids.clear();commit_pcs.clear();commit_insts.clear();trap_pcs.clear();trap_causes.clear();handled_pcs.clear();handled_causes.clear();commit_callbacks=0;
  tensor_issue_edges.clear();tensor_terminal_edges.clear();
  tensor_commit_edges.assign(layout.tensor_pcs.size(),0);
  cfg_commits=legal_launches=macro_terminals=0;stall_left=4;term_cycles=0;req=rsp=reads=writes=0;req_at_bad=~uint64_t{0};
  resident_before29=resident_after29=held_req=saw_gmem_stall=term_hold=term_seen=bad_cmd_seen=bad_commit=bad_no_rd=false;
  allow_low_seen.fill(false);macro_commit_seen.fill(false);completion_seen.fill(false);
  tensor_observer=TensorObserverSnapshot{};
  tensor_observer_epochs=TensorObserverEpochs{};
  cpu_active_serialize_edges=0;
  system_serialize_edges=0;
  system_posedge_serialize_sample=false;
  dut.rst=0;
  for(unsigned i=0;i<80000&&!bad_commit;++i)tick();
  // This direct-system wrapper consumes NpcSimTop's cycle-DPI ABI, whose
  // snapshot is sampled in the active region before the same edge's Sidecar
  // NBA updates.  Advance one common stats-on/stats-off observation edge for
  // this directed oracle.  The production VNpcSimTop host instead reads its
  // post-eval debug outputs and must not add a final guest cycle.
  tick();
  const uint64_t recovery_cycles=cycles-pre_recovery_cycles;

  check(cmds.size()==95&&terms.size()==95,"expected 90 CONFIG + 3 macro + partial CONFIG + bad macro terminals");
  check(tensor_issue_edges.size()==cmds.size()&&
        tensor_terminal_edges.size()==terms.size()&&
        tensor_commit_edges.size()==layout.tensor_pcs.size(),
        "Tensor critical timeline cardinality mismatch");
  uint64_t cfg_count=0,cfg_i2t=0,cfg_t2c=0,cfg_i2c=0;
  uint64_t macro_count=0,macro_i2t=0,macro_t2c=0,macro_i2c=0;
  uint64_t error_count=0,error_i2t=0,error_t2c=0,error_i2c=0;
  uint64_t terminal_commit_same=0,commit_next_issue_same=0;
  if(tensor_issue_edges.size()==cmds.size()&&
     tensor_terminal_edges.size()==terms.size()&&
     tensor_commit_edges.size()==cmds.size()){
    for(size_t i=0;i<cmds.size();++i){
      check(tensor_commit_edges[i]!=0,
            "Tensor instruction missing commit timeline edge");
      check(tensor_terminal_edges[i]>=tensor_issue_edges[i]&&
            tensor_commit_edges[i]>=tensor_terminal_edges[i],
            "Tensor issue/terminal/commit timeline order mismatch");
      const uint64_t i2t=tensor_terminal_edges[i]-tensor_issue_edges[i];
      const uint64_t t2c=tensor_commit_edges[i]-tensor_terminal_edges[i];
      const uint64_t i2c=tensor_commit_edges[i]-tensor_issue_edges[i];
      if(t2c==0)++terminal_commit_same;
      if(i+1<cmds.size()&&tensor_issue_edges[i+1]==tensor_commit_edges[i])
        ++commit_next_issue_same;
      if(cmds[i].bits!=kLaunchBits){
        ++cfg_count;cfg_i2t+=i2t;cfg_t2c+=t2c;cfg_i2c+=i2c;
      }else if(!terms[i].error){
        ++macro_count;macro_i2t+=i2t;macro_t2c+=t2c;macro_i2c+=i2c;
      }else{
        ++error_count;error_i2t+=i2t;error_t2c+=t2c;error_i2c+=i2c;
      }
    }
  }
  std::printf("[RV64-DIRECT-NPU-CRITICAL] cfg_count=%llu cfg_i2t=%llu cfg_t2c=%llu cfg_i2c=%llu macro_count=%llu macro_i2t=%llu macro_t2c=%llu macro_i2c=%llu error_count=%llu error_i2t=%llu error_t2c=%llu error_i2c=%llu terminal_commit_same=%llu commit_next_issue_same=%llu\n",
      (unsigned long long)cfg_count,(unsigned long long)cfg_i2t,
      (unsigned long long)cfg_t2c,(unsigned long long)cfg_i2c,
      (unsigned long long)macro_count,(unsigned long long)macro_i2t,
      (unsigned long long)macro_t2c,(unsigned long long)macro_i2c,
      (unsigned long long)error_count,(unsigned long long)error_i2t,
      (unsigned long long)error_t2c,(unsigned long long)error_i2c,
      (unsigned long long)terminal_commit_same,
      (unsigned long long)commit_next_issue_same);
  check(cfg_count==91&&cfg_i2t==91&&cfg_t2c==0&&cfg_i2c==91,
        "CONFIG Tensor critical timing signature mismatch");
  // Each successful 16-element F32 macro prepares element N+1 during element
  // N's WRITE_WAIT, so turnover saves 3 * (16 - 1) = 45 cycles in this fixed
  // workload.  The zero-coordinate first-element addresses are now captured
  // on command admission; successful preflight enters SRC0_REQ directly and
  // removes one ELEMENT_PREP cycle per macro.  A successful
  // held child response now also hands its shadow write directly to GMEM when
  // ready, removing one WRITE_REQ cycle for all 3 * 16 elements.  A clean
  // successful SRC1 response now also hands its FP request directly to the
  // child when ready, removing one CHILD_REQ cycle for those same 3 * 16
  // elements.  Registered dual-source 64-bit beat reuse skips both source
  // reads for 8 odd elements per command; each such element replaces four
  // request/wait/direct-child cycles with one registered CHILD_REQ cycle.
  // The preceding clean child response now prepares that reused element in
  // the resident operand registers, so its successful write response can
  // hand the request directly to the ready child and remove the remaining
  // CHILD_REQ cycle.  Keep all independently derived terms visible so the
  // executable oracle documents the cumulative
  // 45 + 48 + 48 + 72 + 24 + 3 = 240-cycle reduction from the 5337 baseline.
  constexpr uint64_t kF32TurnoverSavedCycles=3ull*(16ull-1ull);
  constexpr uint64_t kF32ChildWriteDirectSavedCycles=3ull*16ull;
  constexpr uint64_t kF32Src1ChildDirectSavedCycles=3ull*16ull;
  constexpr uint64_t kF32BeatPairReuseSavedCycles=3ull*(16ull/2ull)*3ull;
  constexpr uint64_t kF32BeatPairChildDirectSavedCycles=
      3ull*(16ull/2ull);
  constexpr uint64_t kF32FirstElementPrepFoldSavedCycles=3ull;
  constexpr uint64_t kF32SavedCycles=kF32TurnoverSavedCycles+
      kF32ChildWriteDirectSavedCycles+kF32Src1ChildDirectSavedCycles+
      kF32BeatPairReuseSavedCycles+kF32BeatPairChildDirectSavedCycles+
      kF32FirstElementPrepFoldSavedCycles;
  check(macro_count==3&&
        macro_i2t==(557-kF32SavedCycles)&&macro_t2c==0&&
        macro_i2c==(557-kF32SavedCycles),
        "F32 turnover/direct-write/direct-child/beat-reuse/pair-child-direct/first-prep-fold macro Tensor critical timing signature mismatch");
  check(error_count==1&&error_i2t==1&&error_t2c==0&&error_i2c==1,
        "error Tensor critical timing signature mismatch");
  check(terminal_commit_same==95&&commit_next_issue_same==0,
        "Tensor terminal/commit edge relation mismatch");
  if(cmds.size()==95&&terms.size()==95){
    for(unsigned i=0;i<95;++i)check(cmds[i].pid==terms[i].pid,"terminal CPU PID mismatch");
    for(unsigned i=0;i<94;++i)check(!terms[i].error&&terms[i].code==0,"success command reported terminal error");
    check(terms[94].error&&terms[94].code==18,"incomplete launch did not return protocol error");
  }
  check(cfg_commits==91&&!resident_before29&&resident_after29,"CONFIG count/residency invariant failed");
  check(legal_launches==3&&macro_terminals==3,"legal macro exact-once completion count failed");
  for(unsigned i=0;i<3;++i){check(completion_seen[i]&&macro_commit_seen[i],"legal macro completion/commit missing");check(launch_pids.size()>i&&launch_pids[i]!=uint8_t(active_descs[i][3]),"macro producer low8 accidentally equals CPU PID");}
  check(!allow_low_seen[0]&&!allow_low_seen[2],"no-prepressure macro observed terminal_allow low");
  check(allow_low_seen[1]&&term_cycles>=4,"held terminal backpressure not exercised");
  check(saw_gmem_stall&&stall_left==0,"GMEM backpressure not exercised");
  check(bad_cmd_seen&&bad_commit&&bad_no_rd&&req_at_bad==req,"incomplete launch precise error/no-GMEM failed");
  check(req==96&&rsp==96&&reads==48&&writes==48,"three-macro F32 GMEM cardinality mismatch");
  for(const auto&d:active_descs)for(unsigned i=0;i<16;++i)if(get_gmem32(d[13]+4*i)!=kGold[i]){fail("RTL F32 result or per-transaction destination mismatch");break;}
  check(dut.npu_command_count_o==3&&dut.npu_completion_count_o==3&&dut.npu_error_count_o==0,"public NPU counters mismatch");
  check(dut.npu_required_issued_o==3&&dut.npu_required_completed_o==3,"REQUIRED issued/completed counters mismatch");
  check(dut.npu_macro_command_count_o==3&&dut.npu_macro_f32_start_count_o==3&&dut.npu_macro_completion_count_o==3,"macro counters mismatch");
#if NPC_DIRECT_NPU_SYSTEM_OOO_STATS
  const uint64_t legacy_attribution_values[]={
      tensor_observer.wait_head,tensor_observer.wait_drain,
      tensor_observer.npu_backpressure};
  uint64_t legacy_attribution_sum=0;
  const bool legacy_attribution_sum_ok=sum_u64(
      legacy_attribution_values,
      sizeof(legacy_attribution_values)/sizeof(legacy_attribution_values[0]),
      &legacy_attribution_sum);
  const uint64_t tensor_attribution_values[]={
      tensor_observer.attr_prelaunch_cancel,
      tensor_observer.attr_wait_not_exact_head,
      tensor_observer.attr_wait_launch_gate,
      tensor_observer.attr_wait_src_dependency,
      tensor_observer.attr_wait_src_value,
      tensor_observer.attr_wait_mem_active,
      tensor_observer.attr_wait_mem_retire,
      tensor_observer.attr_launch_to_offer,
      tensor_observer.attr_offer_backpressure,
      tensor_observer.attr_offer_accept,
      tensor_observer.attr_sent_terminal_absent,
      tensor_observer.attr_sent_terminal_stale,
      tensor_observer.attr_sent_terminal_accept,
      tensor_observer.attr_complete_wb_backpressure,
      tensor_observer.attr_complete_stale_drop,
      tensor_observer.attr_complete_wb_accept,
      tensor_observer.attr_invalid_state,
      tensor_observer.attr_sent_terminal_completion_stale,
      tensor_observer.attr_sent_terminal_wb_accept};
  uint64_t tensor_attribution_sum=0;
  const bool tensor_attribution_sum_ok=sum_u64(
      tensor_attribution_values,
      sizeof(tensor_attribution_values)/sizeof(tensor_attribution_values[0]),
      &tensor_attribution_sum);
  const bool tensor_attribution_partition_ok=tensor_attribution_sum_ok&&
      tensor_attribution_sum==tensor_observer.serialize;
  std::printf("[RV64-DIRECT-NPU-STATS-RAW] issued=%llu terminal=%llu completion=%llu alloc_direct_issue=%llu serialize_active=%llu independent_active=%llu system_serialize=%llu wait_head=%llu wait_drain=%llu cmd_backpressure=%llu\n",
      (unsigned long long)tensor_observer.issued,
      (unsigned long long)tensor_observer.terminal,
      (unsigned long long)tensor_observer.completion,
      (unsigned long long)tensor_observer.alloc_direct_issue,
      (unsigned long long)tensor_observer.serialize,
      (unsigned long long)cpu_active_serialize_edges,
      (unsigned long long)system_serialize_edges,
      (unsigned long long)tensor_observer.wait_head,
      (unsigned long long)tensor_observer.wait_drain,
      (unsigned long long)tensor_observer.npu_backpressure);
  std::printf("[RV64-DIRECT-NPU-ATTRIBUTION] prelaunch_cancel=%llu wait_not_exact_head=%llu wait_launch_gate=%llu wait_src_dependency=%llu wait_src_value=%llu wait_mem_active=%llu wait_mem_retire=%llu launch_to_offer=%llu offer_backpressure=%llu offer_accept=%llu sent_terminal_absent=%llu sent_terminal_stale=%llu sent_terminal_accept=%llu complete_wb_backpressure=%llu complete_stale_drop=%llu complete_wb_accept=%llu invalid_state=%llu sent_terminal_completion_stale=%llu sent_terminal_wb_accept=%llu sum=%llu serialize_active=%llu overflow=%u partition_ok=%u\n",
      (unsigned long long)tensor_observer.attr_prelaunch_cancel,
      (unsigned long long)tensor_observer.attr_wait_not_exact_head,
      (unsigned long long)tensor_observer.attr_wait_launch_gate,
      (unsigned long long)tensor_observer.attr_wait_src_dependency,
      (unsigned long long)tensor_observer.attr_wait_src_value,
      (unsigned long long)tensor_observer.attr_wait_mem_active,
      (unsigned long long)tensor_observer.attr_wait_mem_retire,
      (unsigned long long)tensor_observer.attr_launch_to_offer,
      (unsigned long long)tensor_observer.attr_offer_backpressure,
      (unsigned long long)tensor_observer.attr_offer_accept,
      (unsigned long long)tensor_observer.attr_sent_terminal_absent,
      (unsigned long long)tensor_observer.attr_sent_terminal_stale,
      (unsigned long long)tensor_observer.attr_sent_terminal_accept,
      (unsigned long long)tensor_observer.attr_complete_wb_backpressure,
      (unsigned long long)tensor_observer.attr_complete_stale_drop,
      (unsigned long long)tensor_observer.attr_complete_wb_accept,
      (unsigned long long)tensor_observer.attr_invalid_state,
      (unsigned long long)tensor_observer.attr_sent_terminal_completion_stale,
      (unsigned long long)tensor_observer.attr_sent_terminal_wb_accept,
      (unsigned long long)tensor_attribution_sum,
      (unsigned long long)tensor_observer.serialize,
      tensor_attribution_sum_ok?0u:1u,
      tensor_attribution_partition_ok?1u:0u);
  check(tensor_observer.issued==95&&tensor_observer.terminal==95&&tensor_observer.completion==95,"Tensor observer issued/terminal/completion mismatch");
  check(tensor_observer.alloc_direct_issue==4,
        "Tensor observer allocation-edge direct issue signature mismatch");
  check(legacy_attribution_sum_ok&&
        tensor_observer.serialize>=legacy_attribution_sum,
        "Tensor observer legacy bucket sum exceeds serialize or overflowed");
  check(tensor_observer.wait_head==0&&tensor_observer.wait_drain==0&&
        tensor_observer.npu_backpressure==0,
        "Tensor observer fixed legacy coarse-bucket signature mismatch");
  check(tensor_attribution_partition_ok,
        "Tensor observer one-hot attribution sum does not equal serialize");
  check(tensor_observer.serialize==194,
        "Tensor observer terminal-fallthrough active serialize prediction mismatch");
  check(tensor_observer.attr_prelaunch_cancel==0&&
        tensor_observer.attr_wait_not_exact_head==0&&
        tensor_observer.attr_wait_launch_gate==0&&
        tensor_observer.attr_wait_src_dependency==0&&
        tensor_observer.attr_wait_src_value==0&&
        tensor_observer.attr_wait_mem_active==0&&
        tensor_observer.attr_wait_mem_retire==0&&
        tensor_observer.attr_launch_to_offer==0&&
        tensor_observer.attr_offer_backpressure==0&&
        tensor_observer.attr_offer_accept==95&&
        tensor_observer.attr_sent_terminal_absent==4&&
        tensor_observer.attr_sent_terminal_stale==0&&
        tensor_observer.attr_sent_terminal_accept==0&&
        tensor_observer.attr_complete_wb_backpressure==0&&
        tensor_observer.attr_complete_stale_drop==0&&
        tensor_observer.attr_complete_wb_accept==0&&
        tensor_observer.attr_invalid_state==0&&
        tensor_observer.attr_sent_terminal_completion_stale==0&&
        tensor_observer.attr_sent_terminal_wb_accept==95,
        "Tensor observer fixed one-hot attribution distribution mismatch");
  check(cpu_active_serialize_edges==tensor_observer.serialize,"independent active CPU-clock serialize count mismatch");
  check(system_serialize_edges>=cpu_active_serialize_edges,"system serialize count smaller than active CPU-clock count");
  check(system_serialize_edges==(744-kF32SavedCycles),
        "F32 turnover/direct-write/direct-child/beat-reuse/pair-child-direct/first-prep-fold fixed system serialize prediction mismatch");
  check(system_serialize_edges>=cpu_active_serialize_edges&&
        system_serialize_edges-cpu_active_serialize_edges==
            (550-kF32SavedCycles),
        "F32 turnover/direct-write/direct-child/beat-reuse/pair-child-direct/first-prep-fold fixed clock-gated serialize gap mismatch");
#endif
  std::printf("[RV64-DIRECT-NPU-PHASE-CYCLES] pre_recovery=%llu recovery=%llu total=%llu\n",
      (unsigned long long)pre_recovery_cycles,
      (unsigned long long)recovery_cycles,
      (unsigned long long)cycles);
  check(pre_recovery_cycles==1218&&
        recovery_cycles==(4119-kF32SavedCycles),
        "F32 turnover/direct-write/direct-child/beat-reuse/pair-child-direct/first-prep-fold fixed phase-cycle signature mismatch");
  check(cycles==(5337-kF32SavedCycles),
        "F32 turnover/direct-write/direct-child/beat-reuse/pair-child-direct/first-prep-fold fixed system cycle signature mismatch");
  check(portal_outputs_zero(),"default-disabled portal exposed state/activity");
  dut.final();
  if(failures){std::fprintf(stderr,"[RV64-DIRECT-NPU-SYSTEM][FAIL] cycles=%llu cmd=%zu term=%zu req=%llu failures=%u\n",(unsigned long long)cycles,cmds.size(),terms.size(),(unsigned long long)req,failures);return 1;}
#if NPC_DIRECT_NPU_SYSTEM_OOO_STATS
  std::printf("[RV64-DIRECT-NPU-STATS] issued=%llu terminal=%llu completion=%llu alloc_direct_issue=%llu serialize_active=%llu wait_head=%llu wait_drain=%llu cmd_backpressure=%llu unattributed=%llu system_serialize=%llu clock_gated_gap=%llu\n",
      (unsigned long long)tensor_observer.issued,
      (unsigned long long)tensor_observer.terminal,
      (unsigned long long)tensor_observer.completion,
      (unsigned long long)tensor_observer.alloc_direct_issue,
      (unsigned long long)tensor_observer.serialize,
      (unsigned long long)tensor_observer.wait_head,
      (unsigned long long)tensor_observer.wait_drain,
      (unsigned long long)tensor_observer.npu_backpressure,
      (unsigned long long)(tensor_observer.serialize-legacy_attribution_sum),
      (unsigned long long)system_serialize_edges,
      (unsigned long long)(system_serialize_edges-cpu_active_serialize_edges));
#endif
  std::printf("[RV64-DIRECT-NPU-SYSTEM][PASS] cycles=%llu reset_inflight=1 recovery=1 config=91 macro=3 exact_once=1 no_prepressure=2 held_terminal=%u bad_launch=1 terminals=95 identity_isolation=1 gmem_req=96 read=48 write=48 cpu_mem_separate=1\n",(unsigned long long)cycles,term_cycles);
  return 0;
}
