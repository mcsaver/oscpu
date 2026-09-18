#include "decode.hpp"
#include "../../sim/include/r64_image.h"
#include <chrono>
#include <cstdio>
#include <dlfcn.h>
#include <iostream>
using namespace r64model;
struct Context{uint64_t x[32],pc;};
template<class T>T sym(void* h,const char* n){auto p=reinterpret_cast<T>(dlsym(h,n));require(p,std::string("missing reference API: ")+n);return p;}
static void silent_serial(uint8_t){}
int main(int argc,char** argv){try{
 require(argc>=4,"usage: trace-nemu IMAGE REF.so TRACE [--max-instructions=N] [--allow-timing-inputs]");
 uint64_t limit=20000000;bool allow_timing=false;
 for(int i=4;i<argc;i++){std::string a=argv[i];if(a=="--allow-timing-inputs")allow_timing=true;
  else if(a.rfind("--max-instructions=",0)==0)limit=std::stoull(a.substr(19));else throw std::runtime_error("unknown trace option: "+a);}
 require(limit>0,"instruction limit must be positive");auto start=std::chrono::steady_clock::now();
 std::vector<uint8_t> memory(64*1024*1024);R64Images images(memory,0x80000000);images.boot(argv[1]);
 void* h=dlopen(argv[2],RTLD_NOW|RTLD_LOCAL);if(!h)throw std::runtime_error(dlerror());
 auto init=sym<void(*)(int)>(h,"difftest_init");
 auto copy=sym<void(*)(uint32_t,void*,size_t,bool)>(h,"difftest_memcpy");
 auto regs=sym<void(*)(void*,bool)>(h,"difftest_regcpy");
 auto exec=sym<void(*)(uint64_t)>(h,"difftest_exec");
 auto peek=sym<uint64_t(*)(uint32_t,int)>(h,"difftest_pmem_read");
 init(0);sym<void(*)()>(h,"difftest_init_devices")();
 sym<void(*)(bool)>(h,"difftest_set_external_interrupts")(true);
 sym<void(*)(void(*)(uint8_t))>(h,"difftest_set_serial_sink")(silent_serial);
 sym<void(*)(uint16_t,uint64_t)>(h,"difftest_configure_mmu")((1u<<0)|(1u<<8),3ull<<59);
 copy(0x80000000,memory.data(),memory.size(),true);Context c{};c.pc=0x80000000;regs(&c,true);
 std::ofstream out(argv[3],std::ios::binary|std::ios::trunc);require(bool(out),"cannot create trace");
 TraceHeader head;out.write(reinterpret_cast<char*>(&head),sizeof head);
 while(head.count<limit){
  require(c.pc>=0x80000000&&c.pc<0x84000000,"execution left supported bare RAM (trap/MMU unsupported)");
  Record r;r.pc=c.pc;r.raw=peek(c.pc,2);if((r.raw&3)==3)r.raw|=uint32_t(peek(c.pc+2,2))<<16;
  if(r.raw==0x00100073||r.raw==0x9002){require(c.x[10]==0,"program terminated with nonzero a0");head.flags|=1;break;}
  Decoded d;try{d=decode(r.raw);}catch(const std::exception&e){
   char buf[100];snprintf(buf,sizeof buf," at pc=0x%llx raw=0x%08x",static_cast<unsigned long long>(c.pc),r.raw);
   throw std::runtime_error(std::string(e.what())+buf);}
  r.a=c.x[d.rs1];r.b=c.x[d.rs2];if(d.kind==LOAD||d.kind==STORE)r.address=c.x[d.base]+d.offset;
  bool timer=d.timing_csr||(d.kind==LOAD&&(r.address==0x0200bff8||r.address==0x0200bffc||
   r.address==0x10003000||r.address==0x10003004||r.address==0x12000048||r.address==0x1200004c));
  if(timer){require(allow_timing,"timing-dependent input: use fixed RTL trace or explicitly --allow-timing-inputs");head.flags|=2;}
  exec(1);regs(&c,false);r.next=c.pc;
  require(r.next>=0x80000000&&r.next<0x84000000,"NEMU exception or unsupported control transfer");
  out.write(reinterpret_cast<char*>(&r),sizeof r);head.count++;
 }
 require(head.count>0,"empty trace");out.seekp(0);out.write(reinterpret_cast<char*>(&head),sizeof head);out.close();require(bool(out),"trace write failed");
 double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
 std::cerr<<"trace instructions="<<head.count<<" natural_end="<<bool(head.flags&1)<<" timing_inputs="<<bool(head.flags&2)<<" seconds="<<seconds<<"\n";
 return (head.flags&1)?0:3;
 }catch(const std::exception&e){std::cerr<<"trace error: "<<e.what()<<"\n";return 1;}}
