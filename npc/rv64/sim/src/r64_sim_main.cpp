#ifndef R64_DUT_HEADER
#define R64_DUT_HEADER "r64_verilator_dut.h"
#endif
#include R64_DUT_HEADER
#include "r64_difftest.h"
#include "r64_image.h"
#ifdef R64_SYSTEM
#include "r64_block.h"
#endif
#include <array>
#include <cstdint>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <elf.h>
#include <fstream>
#include <iterator>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

// Integration oracle: execute each architectural event in independently built
// NEMU, compare all GPR/FPR each instruction and deterministic CSR after the
// cycle's complete retirement prefix. No delayed CSR skips or xRET exceptions.
static constexpr uint64_t BASE=0x80000000;
static std::vector<uint8_t> memory;
#ifdef R64_SYSTEM
static std::array<uint8_t,400*300*4> framebuffer{};
static std::deque<uint8_t> reference_uart,dut_uart;
static void reference_serial(uint8_t ch){reference_uart.push_back(ch);}

#endif
static r64::ArchitecturalState architecture;
static auto& x=architecture.x;
static auto& f=architecture.f;
static auto& pc=architecture.pc;
static uint64_t commits=0,cycles=0,reads=0,writes=0,traps=0,dual=0;
static bool verbose=false;
static uint32_t random_state=0x9813542;
static uint32_t random_word(){random_state^=random_state<<13;random_state^=random_state>>17;random_state^=random_state<<5;return random_state;}
template<class T> static uint64_t word(const T& v,int i){return uint64_t(v[i*2])|(uint64_t(v[i*2+1])<<32);}
[[noreturn]] static void fail(const std::string& s){throw std::runtime_error(s);}
static void check(bool v,const char* s){if(!v)fail(s);}
static bool mapped(uint64_t a,size_t n=8){return n<=memory.size()&&a>=BASE&&a-BASE<=memory.size()-n;}
static uint64_t read64(uint64_t a){uint64_t v=0;if(mapped(a))std::memcpy(&v,&memory[a-BASE],8);return v;}
static void write64(uint64_t a,uint64_t d,unsigned m){check(mapped(a),"write outside test memory");for(int i=0;i<8;i++)if(m>>i&1)memory[a-BASE+i]=d>>(i*8);}
#ifdef R64_SYSTEM
static bool block_dma_written=false;
static bool block_dma(uint32_t address,void* data,uint32_t length,bool write){
 if(!mapped(address,length))return false;
 if(write){std::memcpy(memory.data()+address-BASE,data,length);block_dma_written|=length!=0;}
 else std::memcpy(data,memory.data()+address-BASE,length);
 return true;
}
#endif
struct Read {uint64_t addr;unsigned id,left,size;};
struct Write {uint64_t addr;unsigned id,left,size;};
struct Beat {uint64_t data;unsigned strb;bool last;};
int main(int argc,char**argv){
 try{
  check(argc>=3,"usage: core-test image reference.so [--verbose] [--stalls] [--maxcycles=N] [--tohost=ADDR] [--progress[=N]] [--system] [--memory=BYTES] [--load=ADDR:PATH] [--uart-input=MARKER:BYTES] [--uart-stdin] [--expect=TEXT] [--block=WRITABLE_RUN_IMAGE]");
  bool stalls=false,progress=false,system_mode=false,uart_stdin=false;
  std::string expect;bool expect_seen=false;
  uint64_t tohost=0,maxcycles=200000,memory_size=64*1024*1024,progress_interval=1000000;
  struct ExtraImage {uint64_t address;std::string path;};
  struct UartInput {std::string marker,bytes;size_t offset=0;uint64_t release=0;bool armed=false;};
  std::string block_path;
  std::vector<ExtraImage> extra_images;
  std::vector<UartInput> uart_inputs;
  std::deque<uint8_t> stdin_bytes;
  size_t uart_input=0;std::string uart_tail;
  unsigned syscon_events=0;uint32_t syscon_value=0;
  auto number=[](const char* text){
   char* end=nullptr;errno=0;
   uint64_t value=std::strtoull(text,&end,0);
   check(*text&&*text!='-'&&!errno&&end&&!*end,"invalid unsigned command-line value");
   return value;
  };
  for(int i=3;i<argc;i++){
   const std::string arg=argv[i];
   if(arg=="--verbose")verbose=true;
   else if(arg=="--stalls")stalls=true;
   else if(arg=="--system")system_mode=true;
   else if(arg=="--uart-stdin")uart_stdin=true;
   else if(arg.rfind("--expect=",0)==0){expect=arg.substr(9);check(!expect.empty()&&expect.size()<=512,"expect must contain 1..512 bytes");}
   else if(arg.rfind("--block=",0)==0){block_path=arg.substr(8);check(!block_path.empty(),"empty block image");}
   else if(arg.rfind("--memory=",0)==0)memory_size=number(argv[i]+9);
   else if(arg.rfind("--load=",0)==0){
    auto sep=arg.find(':',7);check(sep!=std::string::npos&&sep+1<arg.size(),"--load expects ADDRESS:PATH");
    extra_images.push_back({number(arg.substr(7,sep-7).c_str()),arg.substr(sep+1)});
   }else if(arg.rfind("--uart-input=",0)==0){
    auto sep=arg.find(':',13);check(sep!=std::string::npos&&sep>13&&sep+1<arg.size(),"--uart-input expects MARKER:BYTES");
    uart_inputs.push_back({arg.substr(13,sep-13),arg.substr(sep+1)});
   }
   else if(arg=="--progress")progress=true;
   else if(arg.rfind("--progress=",0)==0){progress_interval=number(argv[i]+11);check(progress_interval>0,"progress interval must be positive");progress=true;}
   else if(arg=="--no-progress")progress=false;
   else if(arg=="-b"||arg=="--batch"){} // This runner always executes in batch.
   else if(arg.rfind("--maxcycles=",0)==0)maxcycles=number(argv[i]+12);
   else if(arg.rfind("--max-cycles=",0)==0)maxcycles=number(argv[i]+13);
   else if(arg=="--max-cycles"||arg=="--maxcycles"){
    check(i+1<argc,"missing maximum cycle count");maxcycles=number(argv[++i]);
   }else if(arg.rfind("--tohost=",0)==0)tohost=number(argv[i]+9);
   else if(arg.rfind("--diff=",0)==0){
    check(arg.substr(7)==argv[2],"--diff differs from CORE_REF; select the reference with CORE_REF");
   }else fail("unknown simulation argument: "+arg);
  }
  check(maxcycles>0,"maximum cycle count must be positive");
  check(memory_size>=4096&&memory_size<=0x40000000ull&&!(memory_size&4095),"memory size must be page aligned, 4 KiB to 1 GiB");
#ifndef R64_SYSTEM
  check(!system_mode&&uart_inputs.empty()&&block_path.empty()&&!uart_stdin,"system mode, UART and block require R64SystemTestTop");
#endif
  check(!system_mode||!tohost,"system mode uses syscon termination, not tohost");
  memory.resize(memory_size);
  check(!tohost||(mapped(tohost,8)&&!(tohost&7)),"tohost must be an aligned word in guest RAM");
  // read(2) does not flush stdio prompts. Interactive output must be visible
  // even without a newline and when Linux/Makefile pipes stdout through tee.
  if(uart_stdin)std::setvbuf(stdout,nullptr,_IONBF,0);
  else if(progress)std::setvbuf(stdout,nullptr,_IOLBF,0);
  R64Images images(memory,BASE);images.boot(argv[1]);
  for(const auto& extra:extra_images)images.raw(extra.path,extra.address);
  #ifdef R64_SYSTEM
  R64BlockImages block_images(block_path);
  r64::DiffTest ref(argv[2],{BASE,memory.data(),memory.size(),block_images.reference(),
                           reference_serial,!uart_inputs.empty()||uart_stdin,system_mode});
  R64BlockDevice block(argv[2],block_path.empty()?nullptr:block_path.c_str(),block_dma);
#else
  r64::DiffTest ref(argv[2],{BASE,memory.data(),memory.size()});
#endif
  r64::initialize_dut(argc,argv);Dut d;
#ifdef R64_SYSTEM
  struct StdinMode {
   int original=-1;
   explicit StdinMode(bool enabled){
    if(enabled){original=fcntl(STDIN_FILENO,F_GETFL);
     check(original>=0&&fcntl(STDIN_FILENO,F_SETFL,original|O_NONBLOCK)==0,"cannot set nonblocking UART stdin");}
   }
   ~StdinMode(){if(original>=0)fcntl(STDIN_FILENO,F_SETFL,original);}
  } stdin_mode(uart_stdin);
#endif
  d.run_i=1;d.rst_i=1;d.trace_ready_i=3;
#ifndef R64_TENSOR
  d.dma_invalidate_i=0;
#endif
#ifndef R64_SYSTEM
  d.time_i=0;d.wfi_wait_i=0;d.irq_software_i=0;d.irq_timer_i=0;d.irq_external_i=0;d.irq_supervisor_external_i=0;
#else
  d.uart_rx_valid_i=0;d.uart_rx_data_i=0;d.external_irq_sources_i=0;
#endif
#ifndef R64_TENSOR
  d.tensor_cmd_ready_i=0;d.tensor_terminal_valid_i=0;d.tensor_terminal_tag_i=0;d.tensor_error_i=0;d.tensor_error_code_i=0;
#else
  d.gmem_req_ready_i=0;d.gmem_rsp_valid_i=0;d.gmem_rsp_rdata_i=0;d.gmem_rsp_error_i=0;d.gmem_rsp_tag_i=0;
#endif
#ifndef R64_SYSTEM
  d.arready_i=0;d.rvalid_i=0;d.awready_i=0;d.wready_i=0;d.bvalid_i=0;
#else
  d.ext_arready_i=0;d.ext_rvalid_i=0;d.ext_awready_i=0;d.ext_wready_i=0;d.ext_bvalid_i=0;
  d.ext_rresp_i=0;d.ext_bresp_i=0;for(int i=0;i<8;i++)d.ext_rdata_i[i]=0;
#endif
  for(int i=0;i<5;i++){d.clk_i=0;d.eval();d.clk_i=1;d.eval();}
  d.rst_i=0;
#ifndef R64_SYSTEM
  std::deque<Read> rq;std::deque<Write> wq;std::deque<Beat> wd;std::deque<unsigned> bq;
  bool rh=false,bh=false;Read selected{};unsigned bsel=0;uint64_t held_rdata=0;
#else
  struct Endpoint { bool rv=false,av=false,wv=false,bv=false;uint64_t rd=0,wa=0,wd=0;unsigned strb=0,size=0,rerr=0,berr=0; };
  std::array<Endpoint,4> ep{};
#endif
#ifdef R64_TENSOR
  bool dma_pending=false;uint64_t dma_data=0;unsigned dma_tag=0;bool dma_error=false;
  uint64_t dma_reads=0,dma_writes=0;
#endif
  for(cycles=0;cycles<maxcycles;cycles++){
   if(progress&&cycles&&cycles%progress_interval==0)std::fprintf(stderr,"PROGRESS cycles=%llu commits=%llu pc=%016llx rob=%u\n",(long long)cycles,(long long)commits,(long long)pc,d.rob_count_o);
   d.clk_i=0;d.eval();uint32_t rnd=random_word();
   d.trace_ready_i=!stalls?3:((rnd&7)==0?0:((rnd&7)==1?1:3));
 #ifndef R64_SYSTEM
   d.time_i=cycles;
   d.arready_i=rq.size()<4&&(!stalls||(rnd&8));
   d.awready_i=wq.size()<2&&(!stalls||(rnd&16));
   d.wready_i=wd.size()<2&&(!stalls||(rnd&32));
   if(!rh&&!rq.empty()&&(!stalls||(rnd&64))){selected=rq.front();held_rdata=read64(selected.addr&~7ull);rh=true;}
   d.rvalid_i=rh;d.rid_i=selected.id;d.rdata_i=held_rdata;
   d.rresp_i=mapped(selected.addr&~7ull)?0:2;d.rlast_i=selected.left==1;
   if(!bh&&!bq.empty()&&(!stalls||(rnd&128))){bh=true;bsel=bq.front();}
   d.bvalid_i=bh;d.bid_i=bsel;d.bresp_i=0;
   d.eval();
   bool ar=d.arvalid_o&&d.arready_i,rr=d.rvalid_i&&d.rready_o,aw=d.awvalid_o&&d.awready_i;
   bool wt=d.wvalid_o&&d.wready_i,bt=d.bvalid_i&&d.bready_o;
   if(ar){check(d.arburst_o==1,"non-INCR AR");rq.push_back({d.araddr_o,d.arid_o,unsigned(d.arlen_o)+1,d.arsize_o});reads++;}
   if(aw){check(d.awburst_o==1,"non-INCR AW");wq.push_back({d.awaddr_o,d.awid_o,unsigned(d.awlen_o)+1,d.awsize_o});writes++;}
   if(wt)wd.push_back({d.wdata_o,d.wstrb_o,bool(d.wlast_o)});
   d.clk_i=1;d.eval();
   if(rr){check(!rq.empty(),"unowned R");auto q=rq.front();rq.pop_front();q.addr+=1ull<<q.size;if(--q.left)rq.push_front(q);rh=false;}
   if(bt){check(!bq.empty(),"unowned B");bq.pop_front();bh=false;}
   if(!wq.empty()&&!wd.empty()){
    auto &q=wq.front();auto b=wd.front();wd.pop_front();check(b.last==(q.left==1),"bad WLAST");
    write64(q.addr&~7ull,b.data,b.strb);q.addr+=1ull<<q.size;
    if(--q.left==0){bq.push_back(q.id);wq.pop_front();}
   }
#else
#ifndef R64_TENSOR
   d.dma_invalidate_i=0;
#endif
   block_dma_written=false;
   d.external_irq_sources_i=block.irq()?4:0;
   if(uart_stdin&&stdin_bytes.size()<1024){
    uint8_t bytes[128];ssize_t count=read(STDIN_FILENO,bytes,sizeof bytes);
    if(count>0)stdin_bytes.insert(stdin_bytes.end(),bytes,bytes+count);
    else check(count==0||errno==EAGAIN||errno==EWOULDBLOCK||errno==EINTR,"UART stdin read failed");
   }
   d.uart_rx_valid_i=0;
   if(uart_input<uart_inputs.size()){
    auto& input=uart_inputs[uart_input];
    if(!input.armed&&uart_tail.find(input.marker)!=std::string::npos){input.armed=true;input.release=cycles+1000;}
    if(input.armed&&cycles>=input.release){d.uart_rx_valid_i=1;d.uart_rx_data_i=uint8_t(input.bytes[input.offset]);}
   }
   if(uart_input==uart_inputs.size()&&!stdin_bytes.empty()){
    d.uart_rx_valid_i=1;d.uart_rx_data_i=stdin_bytes.front();
   }
   d.ext_arready_i=0;d.ext_awready_i=0;d.ext_wready_i=0;d.ext_rvalid_i=0;d.ext_bvalid_i=0;
   d.ext_rresp_i=0;d.ext_bresp_i=0;
   for(unsigned n=0;n<4;n++){
    auto &e=ep[n];unsigned bit=1u<<n;
    if(!e.rv&&(!stalls||(rnd&8)))d.ext_arready_i|=bit;
    if(!e.av&&!e.bv&&(!stalls||(rnd&16)))d.ext_awready_i|=bit;
    if(!e.wv&&!e.bv&&(!stalls||(rnd&32)))d.ext_wready_i|=bit;
    if(e.rv)d.ext_rvalid_i|=bit;if(e.bv)d.ext_bvalid_i|=bit;
    d.ext_rdata_i[n*2]=e.rd;d.ext_rdata_i[n*2+1]=e.rd>>32;
    d.ext_rresp_i|=e.rerr<<(n*2);d.ext_bresp_i|=e.berr<<(n*2);
   }
#ifdef R64_TENSOR
   d.gmem_req_ready_i=!dma_pending&&(!stalls||(rnd&256));
   d.gmem_rsp_valid_i=dma_pending;d.gmem_rsp_rdata_i=dma_data;
   d.gmem_rsp_error_i=dma_error;d.gmem_rsp_tag_i=dma_tag;
#endif
   d.eval();
#ifdef R64_TENSOR
   bool dma_req=d.gmem_req_valid_o&&d.gmem_req_ready_i;
   bool dma_rsp=d.gmem_rsp_valid_i&&d.gmem_rsp_ready_o;
   if(dma_rsp)dma_pending=false;
   if(dma_req){
    dma_error=!mapped(d.gmem_req_addr_o);dma_data=read64(d.gmem_req_addr_o);
    dma_tag=d.gmem_req_tag_o;dma_pending=true;
    if(d.gmem_req_write_o){
     if(!dma_error)write64(d.gmem_req_addr_o,d.gmem_req_wdata_o,d.gmem_req_wstrb_o);
     dma_writes++;
    }else dma_reads++;
   }
#endif
   if(d.uart_rx_valid_i&&d.uart_rx_ready_o){
    check(ref.receive_serial(d.uart_rx_data_i),"reference UART rejected accepted input");
    // Preserve causal order when the guest marker has no trailing newline yet.
    std::fflush(stdout);
    std::fprintf(stderr,"UART_RX cycle=%llu byte=0x%02x\n",(long long)cycles,d.uart_rx_data_i);
    if(uart_input<uart_inputs.size()){
     auto& input=uart_inputs[uart_input];if(++input.offset==input.bytes.size()){uart_input++;uart_tail.clear();}
    }else stdin_bytes.pop_front();
   }
   if(system_mode&&d.syscon_valid_o){check(++syscon_events==1,"duplicate syscon event");syscon_value=d.syscon_value_o;}
   unsigned ar=d.ext_arvalid_o&d.ext_arready_i,rr=d.ext_rvalid_i&d.ext_rready_o;
   unsigned aw=d.ext_awvalid_o&d.ext_awready_i,wt=d.ext_wvalid_o&d.ext_wready_i;
   unsigned bt=d.ext_bvalid_i&d.ext_bready_o;
   for(unsigned n=0;n<4;n++){
    auto &e=ep[n];unsigned bit=1u<<n;
    if(rr&bit)e.rv=false;if(bt&bit)e.bv=false;
    if(ar&bit){
     uint64_t a=word(d.ext_araddr_o,n);unsigned size=(d.ext_arsize_o>>(n*3))&7;
     e.rd=read64(a&~7ull);e.rerr=mapped(a&~7ull)?0:2;
     // Existing external legacy device aperture: its benchmark clock is
     // deterministic at one microsecond per DUT cycle, matching the old host.
     if(n==2&&size==2&&(a==0x12000048||a==0x1200004c)){e.rd=cycles;e.rerr=0;}
     if(n==2&&size==2&&a==0x12000100){e.rd=(400u<<16)|300u;e.rerr=0;}
     if(n==2&&a>=0x13000000&&a+(1ull<<size)<=0x13000000+framebuffer.size()){
      std::memcpy(&e.rd,framebuffer.data()+((a-0x13000000)&~7ull),8);e.rerr=0;
     }
     if(n==3){uint64_t value=0;e.rerr=block.access(a,size,value,false)?0:2;e.rd=value<<((a&7)*8);}
     e.rv=true;reads++;
    }
    if(aw&bit){e.wa=word(d.ext_awaddr_o,n);e.size=(d.ext_awsize_o>>(n*3))&7;e.av=true;}
    if(wt&bit){e.wd=word(d.ext_wdata_o,n);e.strb=(d.ext_wstrb_o>>(n*8))&255;e.wv=true;}
    if(e.av&&e.wv){
     e.berr=mapped(e.wa&~7ull)?0:2;
     if(!e.berr)write64(e.wa&~7ull,e.wd,e.strb);
     if(n==2&&e.wa==0x12000104&&e.size==2&&!(e.strb&15))e.berr=0;
     if(n==2&&e.wa>=0x13000000&&e.wa+(1ull<<e.size)<=0x13000000+framebuffer.size()){
      for(unsigned byte=0;byte<8;byte++)if(e.strb>>byte&1)framebuffer[((e.wa-0x13000000)&~7ull)+byte]=e.wd>>(byte*8);
      e.berr=0;
     }
     if(n==3){
      uint64_t value=e.wd>>((e.wa&7)*8);
      unsigned mask=e.size<=3?((1u<<(1u<<e.size))-1u)<<(e.wa&7):0;
      e.berr=e.size<=3&&e.strb==mask&&block.access(e.wa,e.size,value,true)?0:2;
     }
     e.bv=true;e.av=false;e.wv=false;writes++;
    }
   }
#ifndef R64_TENSOR
   // Synchronous DMA is visible before the MMIO B response and IRQ. Invalidate
   // on this same edge so a subsequent CPU load cannot hit stale cache data.
   d.dma_invalidate_i=block_dma_written;
#else
   check(!block_dma_written,"external block DMA requires the ordinary system wrapper");
#endif
   d.external_irq_sources_i=block.irq()?4:0;
   if(d.uart_tx_valid_o){
    dut_uart.push_back(d.uart_tx_data_o);std::putchar(d.uart_tx_data_o);
    uart_tail+=char(d.uart_tx_data_o);if(uart_tail.size()>512)uart_tail.erase(0,uart_tail.size()-512);
    if(!expect.empty()&&uart_tail.find(expect)!=std::string::npos)expect_seen=true;
   }
   d.clk_i=1;d.eval();
#endif
   check(!d.protocol_error_o,"core AXI protocol fault");
   if(d.trace_valid_o==3)dual++;
   bool event=false;
   for(int l=0;l<2;l++)if(d.trace_valid_o>>l&1){
    uint64_t at=word(d.trace_pc_o,l),raw=word(d.trace_raw_o,l),next=word(d.trace_npc_o,l),value=word(d.trace_data_o,l);
    if(verbose)std::printf("C %llu pc=%016llx raw=%016llx next=%016llx rd=%d fp=%d data=%016llx\n",(long long)cycles,(long long)at,(long long)raw,(long long)next,(d.trace_rd_arch_o>>(l*5))&31,(d.trace_rd_fp_o>>l)&1,(long long)value);
    check(at==pc,"DUT noncontiguous retirement PC");
    if(d.trace_rd_write_o>>l&1){unsigned rd=(d.trace_rd_arch_o>>(l*5))&31;if(d.trace_rd_fp_o>>l&1)f[rd]=value;else if(rd)x[rd]=value;}
    ref.step(architecture,at,next,raw);pc=next;commits++;event=true;
   }
   if(d.trap_valid_o){
    traps++;
    if(verbose)std::printf("T %llu pc=%016llx cause=%u tval=%016llx target=%016llx\n",(long long)cycles,(long long)d.trap_pc_o,d.trap_cause_o,(long long)d.trap_tval_o,(long long)d.trap_target_o);
    bool semihost_marker=mapped(pc-4,12)&&uint32_t(read64(pc-4))==0x01f01013&&uint32_t(read64(pc+4))==0x40705013;
    bool explicit_ebreak=(uint32_t(d.trap_raw_o)==0x00100073)||
        (uint16_t(d.trap_raw_o)==0x9002&&d.trap_length_o==2);
    if(!system_mode&&d.trap_cause_o==3&&d.trap_tval_o==0&&explicit_ebreak&&!tohost&&!semihost_marker){
#ifdef R64_SYSTEM
     while(!reference_uart.empty()&&!dut_uart.empty()){
      check(reference_uart.front()==dut_uart.front(),"DUT/reference UART byte mismatch");
      reference_uart.pop_front();dut_uart.pop_front();
     }
     check(reference_uart.empty()&&dut_uart.empty(),"missing or extra UART bytes at program end");
#endif
     if(x[10]!=0){char msg[96];std::snprintf(msg,sizeof msg,"program returned failure a0=%llu",(long long)x[10]);fail(msg);}
#ifdef R64_TENSOR
     check(dma_reads>=16&&dma_writes>=16&&ref.extension_complete(),"tensor workload did not perform complete DMA");
     std::printf("TENSOR_DMA reads=%llu writes=%llu\n",(long long)dma_reads,(long long)dma_writes);
#endif
     std::printf("[PASS] r64_core_program commits=%llu cycles=%llu dual=%llu traps=%llu reads=%llu writes=%llu\n",(long long)commits,(long long)cycles,(long long)dual,(long long)traps,(long long)reads,(long long)writes);d.final();return 0;
    }
    check(d.trap_pc_o==pc,"trap at wrong architectural PC");ref.trap(architecture,pc,d.trap_target_o,d.trap_cause_o,d.trap_interrupt_o,d.trap_tval_o,d.trap_raw_o);pc=d.trap_target_o;event=true;
   }
   if(event){
    r64::CsrSnapshot snapshot{};
    for(size_t i=0;i<snapshot.size();i++)snapshot[i]=word(d.csr_snapshot_o,i);
    ref.check_csrs(pc,snapshot);
   }
#ifdef R64_SYSTEM
   while(!reference_uart.empty()&&!dut_uart.empty()){
    check(reference_uart.front()==dut_uart.front(),"DUT/reference UART byte mismatch");
    reference_uart.pop_front();dut_uart.pop_front();
   }
#endif
   #ifdef R64_SYSTEM
   // The device may signal before the store retires. Finish only after the
   // independent reference executes the same MMIO store and all state checks.
   if(system_mode&&syscon_events&&event&&ref.syscon_value()==syscon_value){
    check(reference_uart.empty()&&dut_uart.empty(),"missing or extra UART bytes at system end");
    check(uart_input==uart_inputs.size(),"system ended before consuming requested UART input");
    if(syscon_value==0x5555){
     check(expect.empty()||expect_seen,"system powered off without expected UART text");
     std::printf("[PASS] r64_system_poweroff commits=%llu cycles=%llu traps=%llu syscon_events=%u\n",
       (long long)commits,(long long)cycles,(long long)traps,syscon_events);d.final();return 0;
    }
    if(syscon_value==0x7777){std::printf("[REBOOT] r64_system\n");d.final();return 32;}
    fail("system reported failure through syscon");
   }
#endif
   if(tohost&&event&&read64(tohost)){
    uint64_t value=read64(tohost),reference_value=ref.read_memory(tohost,8);
    if(reference_value==value){
     if(value!=1){char msg[160];std::snprintf(msg,sizeof msg,"tohost failure value=%016llx test=%llu",(long long)value,(long long)(value>>1));fail(msg);}
#ifdef R64_TENSOR
     check(dma_reads>=16&&dma_writes>=16&&ref.extension_complete(),"tensor workload did not perform complete DMA");
     std::printf("TENSOR_DMA reads=%llu writes=%llu\n",(long long)dma_reads,(long long)dma_writes);
#endif
     std::printf("[PASS] r64_core_program commits=%llu cycles=%llu dual=%llu traps=%llu reads=%llu writes=%llu tohost=1\n",(long long)commits,(long long)cycles,(long long)dual,(long long)traps,(long long)reads,(long long)writes);d.final();return 0;
    }
   }
  }
  char msg[160];std::snprintf(msg,sizeof msg,"timeout: pc=%016llx ROB=%u commits=%llu",(long long)pc,d.rob_count_o,(long long)commits);fail(msg);
 }catch(const std::exception&e){std::fprintf(stderr,"[FAIL] core cycle=%llu commits=%llu: %s\n",(long long)cycles,(long long)commits,e.what());return 1;}
}
