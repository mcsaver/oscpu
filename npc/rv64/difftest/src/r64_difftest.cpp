#include "r64_difftest.h"
#include <cstdio>
#include <cstring>
#include <dlfcn.h>
#include <stdexcept>
#include <string>

namespace r64 {
namespace {
[[noreturn]] void fail(const std::string& message){throw std::runtime_error(message);}
void check(bool value,const char* message){if(!value)fail(message);}
// Independent integer-memory decode for platform observation/trap policy.
// The architectural execution remains in NEMU, including all compressed ops.
struct MemoryAccess {bool valid=false,store=false;unsigned rd=0,base=0,bytes=0;int64_t offset=0;};
static MemoryAccess memory_access(uint32_t ins){
 MemoryAccess m;
 if((ins&3)==3){
  unsigned op=ins&0x7f,fun=(ins>>12)&7;
  if((op==3&&fun<7)||(op==0x23&&fun<4)){
   m.valid=true;m.store=op==0x23;m.rd=(ins>>7)&31;m.base=(ins>>15)&31;
   m.bytes=1u<<(fun&3);
   uint32_t imm=m.store?((ins>>25)<<5)|((ins>>7)&31):ins>>20;
   m.offset=int64_t(imm&0x7ff)-int64_t(imm&0x800);
  }
 }else{
  unsigned q=ins&3,fun=(ins>>13)&7;
  if(q==0&&(fun==2||fun==3||fun==6||fun==7)){
   m.valid=true;m.store=fun>=6;m.rd=8+((ins>>2)&7);m.base=8+((ins>>7)&7);
   m.bytes=(fun&1)?8:4;
   m.offset=((ins>>10)&7)<<3;
   m.offset|=(fun&1)?((ins>>5)&3)<<6:(((ins>>6)&1)<<2)|(((ins>>5)&1)<<6);
  }else if(q==2&&(fun==2||fun==3)&&((ins>>7)&31)!=0){
   m.valid=true;m.rd=(ins>>7)&31;m.base=2;m.bytes=(fun&1)?8:4;
   m.offset=((ins>>12)&1)<<5;
   m.offset|=(fun&1)?(((ins>>5)&3)<<3)|(((ins>>2)&7)<<6):
                          (((ins>>4)&7)<<2)|(((ins>>2)&3)<<6);
  }else if(q==2&&(fun==6||fun==7)){
   m.valid=true;m.store=true;m.base=2;m.bytes=(fun&1)?8:4;
   m.offset=(fun&1)?(((ins>>10)&7)<<3)|(((ins>>7)&7)<<6):
                    (((ins>>9)&15)<<2)|(((ins>>7)&3)<<6);
  }
 }
 return m;
}
} // namespace

DiffTest::DiffTest(const char* path,const ReferenceConfig& config):config_(config){
  handle=dlopen(path,RTLD_NOW|RTLD_LOCAL);if(!handle)fail(dlerror());
  init=(decltype(init))dlsym(handle,"difftest_init");copy=(decltype(copy))dlsym(handle,"difftest_memcpy");
  regs=(decltype(regs))dlsym(handle,"difftest_regcpy");exec=(decltype(exec))dlsym(handle,"difftest_exec");
  csrs=(decltype(csrs))dlsym(handle,"difftest_csr_snapshot");fprs=(decltype(fprs))dlsym(handle,"difftest_fpr_snapshot");
  raise=(decltype(raise))dlsym(handle,"difftest_raise_intr");
  exception=(decltype(exception))dlsym(handle,"difftest_raise_exception");
  set_gpr=(decltype(set_gpr))dlsym(handle,"difftest_set_gpr");
  peek=(decltype(peek))dlsym(handle,"difftest_pmem_read");
  check(init&&copy&&regs&&exec&&csrs&&fprs&&raise&&exception&&set_gpr&&peek,"reference lacks required full-state API");init(0);
#ifdef R64_SYSTEM
  auto devices=(void(*)())dlsym(handle,"difftest_init_devices");
  auto external_irqs=(void(*)(bool))dlsym(handle,"difftest_set_external_interrupts");
  check(devices&&external_irqs,"reference lacks platform initialization/interrupt boundary API");
  auto serial_sink=(void(*)(void(*)(uint8_t)))dlsym(handle,"difftest_set_serial_sink");
  check(serial_sink,"reference lacks UART byte observation API");
  serial_sink(config_.serial_sink);devices();external_irqs(true);
  auto block=(void(*)(const char*))dlsym(handle,"difftest_init_block");
  check(block,"reference lacks block platform API");block(config_.disk);
  serial_receive=(decltype(serial_receive))dlsym(handle,"difftest_serial_receive");
  read_syscon=(decltype(read_syscon))dlsym(handle,"difftest_syscon_value");
  check(!config_.require_uart_input||serial_receive,"reference lacks UART input API");
  check(!config_.require_syscon||read_syscon,"reference lacks syscon observation API");
#endif
  auto mmu_profile=(void(*)(uint16_t,uint64_t))dlsym(handle,"difftest_configure_mmu");
  check(mmu_profile,"reference lacks hart MMU capability profile");
  // Preserve this CPU's Bare/Sv39-only and no-Svrsw60t59b capability. Wider
  // NEMU standalone capabilities must not change the oracle's WARL result.
  mmu_profile((1u<<0)|(1u<<8),3ull<<59);
  copy(config_.memory_base,config_.memory,config_.memory_size,true);Context c={};c.pc=config_.memory_base;regs(&c,true);
 }
#ifdef R64_TENSOR
void DiffTest::extension(const ArchitecturalState& dut,uint64_t at,uint64_t next,uint64_t raw,const Context& before){
  auto advance=(void(*)(uint64_t,unsigned))dlsym(handle,"difftest_extension_advance");
  auto dma_write=(void(*)(uint32_t,int,uint64_t))dlsym(handle,"difftest_dma_write");
  check(advance&&dma_write,"reference lacks explicit extension/DMA API");
  uint32_t ins=raw;
  if((ins&0xfe007fff)==((5u<<25)|(4u<<12)|(31u<<7)|0x5b)){
   unsigned index=(ins>>20)&31;
   check(raw==ins&&index==descriptor_words&&index<30,"invalid tensor descriptor instruction/order");
   check(next==at+4,"CONFIG instruction length mismatch");
   descriptor[index]=before.x[(ins>>15)&31];descriptor_words++;
   advance(at,4);
  }else{
   check(raw==0x0bf0305b0220305bull&&next==at+8,"unknown custom instruction or macro framing");
   check(descriptor_words==30,"macro lacks complete descriptor");
   // This system case supports the explicitly checked F32 ADD ABI. Other
   // kernels fail here; their numerical engines have separate direct tests.
   check(descriptor[0]==0x11514e0010ull&&descriptor[5]==0x100000001ull&&
    descriptor[9]==0x100000000ull&&descriptor[15]==16&&descriptor[16]==1,
    "unsupported tensor oracle kernel/shape/type");
   check(descriptor[19]==64&&descriptor[20]==64&&descriptor[22]==64&&
    descriptor[24]==64&&descriptor[27]==64&&descriptor[29]==64&&descriptor[25]==0x97,
    "invalid tensor oracle strides/windows/permissions");
   check(descriptor[10]==descriptor[23]&&descriptor[11]==descriptor[26]&&
    descriptor[13]==descriptor[28],"tensor window/address mismatch");
   for(unsigned n=0;n<16;n++){
    uint64_t a=descriptor[10]+4*n,b=descriptor[11]+4*n,o=descriptor[13]+4*n;
    check(mapped(a,4)&&mapped(b,4)&&mapped(o,4),"tensor oracle out of memory");
    uint32_t ia=peek(a,4),ib=peek(b,4),expected;
    float fa,fb,fc;std::memcpy(&fa,&ia,4);std::memcpy(&fb,&ib,4);fc=fa+fb;
    std::memcpy(&expected,&fc,4);
    // Compare every physical output against independent input arithmetic,
    // then update only the reference DMA range, including dirty cache lines.
    check(uint32_t(read64(o))==expected,"tensor physical result mismatch");
    dma_write(o,4,expected);
   }
   descriptor_words=0;advance(at,8);
  }
  compare(dut,at,next);
 }
#endif
void DiffTest::step(const ArchitecturalState& dut,uint64_t at,uint64_t next,uint64_t raw){
  uint32_t instruction=raw;
  Context before;regs(&before,false);
  if(before.pc!=at){char s[160];std::snprintf(s,sizeof s,"event PC mismatch DUT=%016llx REF=%016llx",(long long)at,(long long)before.pc);fail(s);}
#ifdef R64_TENSOR
  if((instruction&0x7f)==0x5b){extension(dut,at,next,raw,before);return;}
#endif
  exec(1);Context c;regs(&c,false);
  unsigned csr=instruction>>20,rd=(instruction>>7)&31;
  bool counter=(instruction&0x7f)==0x73&&((instruction>>12)&7)!=0&&
    (csr==0xc00||csr==0xc01||csr==0xc02||csr==0xb00||csr==0xb02);
  // Time/cycle/retired-counter read values are environment timing observations.
  // Synchronize only the one destination; all other architectural effects
  // from this instruction are still independently executed and compared.
  bool timed_load=false;
#ifdef R64_SYSTEM
  const auto mem=memory_access(instruction);
  if(mem.valid&&!mem.store){
   uint64_t ea=before.x[mem.base]+mem.offset;
   // The address uses pre-instruction registers, including rd == rs1.
   // CLINT and RTC clocks run in DUT cycles, independently of reference steps.
   timed_load=ea==0x0200bff8||ea==0x0200bffc||ea==0x10003000||ea==0x10003004||ea==0x12000048||ea==0x1200004c;
   if(timed_load)rd=mem.rd;
  }
#endif
  if((counter||timed_load)&&rd)set_gpr(rd,dut.x[rd]);
#ifdef R64_SYSTEM
  if(rd&&(instruction&0x7f)==0x73&&((instruction>>12)&7)!=0&&(csr==0x344||csr==0x144)){
   Context observed;regs(&observed,false);
   set_gpr(rd,(observed.x[rd]&~uint64_t(0x80))|(dut.x[rd]&0x80));
  }
#endif
  compare(dut,at,next);
 }
void DiffTest::compare(const ArchitecturalState& dut,uint64_t at,uint64_t next){
  Context c;regs(&c,false);uint64_t rf[32];fprs(rf);
  if(c.pc!=next){char s[160];std::snprintf(s,sizeof s,"next PC mismatch at=%016llx DUT=%016llx REF=%016llx",(long long)at,(long long)next,(long long)c.pc);fail(s);}
  for(int i=0;i<32;i++){
   if(c.x[i]!=dut.x[i]){char s[200];std::snprintf(s,sizeof s,"GPR mismatch at=%016llx x%d DUT=%016llx REF=%016llx",(long long)at,i,(long long)dut.x[i],(long long)c.x[i]);fail(s);}
   if(rf[i]!=dut.f[i]){char s[200];std::snprintf(s,sizeof s,"FPR mismatch at=%016llx f%d DUT=%016llx REF=%016llx",(long long)at,i,(long long)dut.f[i],(long long)rf[i]);fail(s);}
  }
 }
void DiffTest::trap(const ArchitecturalState& dut,uint64_t at,uint64_t next,unsigned cause,bool interrupt,uint64_t tval,uint64_t raw){
  Context before;regs(&before,false);check(before.pc==at,"reference not at trapped instruction");
  if(interrupt){raise((1ull<<63)|cause);compare(dut,at,next);return;}
#ifdef R64_SYSTEM
  if(cause==5||cause==7){
   const auto mem=memory_access(raw);unsigned bytes=mem.bytes;
   uint64_t ea=before.x[mem.base]+mem.offset;
   // The concrete PLIC/RTC register contract reports an access fault for an
   // unsupported transaction before generic alignment. NEMU otherwise chooses
   // the ISA-permitted opposite priority for an ordinary misaligned operation.
   bool strict_device=(ea>=0x02000000&&ea<0x02010000)||(ea>=0x0c000000&&ea<0x10000000)||(ea>=0x10003000&&ea<0x10004000);
   if(mem.valid&&strict_device&&(ea&(bytes-1))&&((cause==5&&!mem.store)||(cause==7&&mem.store))){
    check(ea==tval,"device access trap address mismatch");exception(cause,tval);compare(dut,at,next);return;
   }
  }
#endif
  if(cause==4||cause==6){
   // NEMU deliberately supports ordinary unaligned memory; this EEI permits alignment traps for IO and translated page crossings.
   // Verify that such a trap describes an actual misaligned request. Verify the request independently before injecting
   // that platform policy, instead of skipping or executing a faulting access.
   const auto mem=memory_access(raw);
   uint64_t ea=before.x[mem.base]+mem.offset;
   check(mem.valid&&((cause==4&&!mem.store)||(cause==6&&mem.store)),"alignment trap on wrong instruction class");
   check(mem.bytes>1&&(ea&(mem.bytes-1))&&ea==tval,"alignment trap address/size mismatch");
   exception(cause,tval);compare(dut,at,next);return;
  }
  if(cause==3&&tval==0&&((uint32_t(raw)==0x00100073)||(uint16_t(raw)==0x9002))){
   // Preserve the EEI EBREAK form. Hardware triggers instead execute the
   // independent reference match logic below; no trigger exception injection.
   exception(cause,tval);compare(dut,at,next);return;
  }
  step(dut,at,next);
 }
void DiffTest::check_csrs(uint64_t pc,const CsrSnapshot& dut){
  uint64_t rc[32]={};csrs(rc);
  // NEMU's snapshot exports stored mstatus, while hardware exports the CSR
  // read view. SD is derived from FS/VS/XS, rather than a writable state bit.
  if(((rc[0]>>13)&3)==3||((rc[0]>>9)&3)==3||((rc[0]>>15)&3)==3)rc[0]|=1ull<<63;
  else rc[0]&=~(1ull<<63);
  for(int i=0;i<27;i++)if(i!=18&&i!=19&&i!=20){
   if(dut[i]!=rc[i]){char s[200];std::snprintf(s,sizeof s,"CSR mismatch after=%016llx index=%d DUT=%016llx REF=%016llx",(long long)pc,i,(long long)dut[i],(long long)rc[i]);fail(s);}
  }
 }
#ifdef R64_TENSOR
bool DiffTest::mapped(uint64_t address,size_t bytes) const {
 return bytes<=config_.memory_size&&address>=config_.memory_base&&
        address-config_.memory_base<=config_.memory_size-bytes;
}
uint64_t DiffTest::read64(uint64_t address) const {
 uint64_t value=0;
 if(mapped(address,8))std::memcpy(&value,config_.memory+address-config_.memory_base,8);
 return value;
}
#endif
} // namespace r64
