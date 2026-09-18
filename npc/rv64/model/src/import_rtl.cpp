#include "decode.hpp"
#include <cstdio>
#include <iostream>
using namespace r64model;
// Import the existing full-DiffTest verbose stream. Preserve its exact dynamic
// instruction path and nondeterministic read outcomes without instrumenting RTL.
int main(int argc,char**argv){try{
 require(argc==3||argc==4,"usage: import-rtl TRACE CYCLES [--cycle-limit-status=FILE] < rtl.log");
 std::string option=argc==4?argv[3]:"";
 bool allow_limit=option.rfind("--cycle-limit-status=",0)==0;uint64_t limit_commits=0;
 require(argc==3||allow_limit,"unknown importer option");bool limited=false;
 std::ofstream out(argv[1],std::ios::binary),cycles(argv[2],std::ios::binary);
 require(bool(out)&&bool(cycles),"cannot create trace/cycle files");
 TraceHeader h;out.write(reinterpret_cast<char*>(&h),sizeof h);uint64_t x[32]={};bool pass=false;std::string s;
 while(std::getline(std::cin,s)){
  auto position=s.find("C ");
  if(position!=std::string::npos&&s.find(" pc=",position)!=std::string::npos){
   unsigned long long c,pc,raw,next,data;unsigned rd,fp;
   require(std::sscanf(s.c_str()+position,"C %llu pc=%llx raw=%llx next=%llx rd=%u fp=%u data=%llx",&c,&pc,&raw,&next,&rd,&fp,&data)==7,"bad RTL retirement line");
   Record r;r.pc=pc;r.next=next;r.raw=raw;auto d=decode(r.raw);
   r.a=x[d.rs1];r.b=x[d.rs2];if(d.kind==LOAD||d.kind==STORE)r.address=x[d.base]+d.offset;
   if(d.timing_csr||(d.kind==LOAD&&r.address<0x80000000))h.flags|=2;
   if(d.dst>=0&&d.dst<32){require(unsigned(d.dst)==rd&&!fp,"decoder/RTL integer destination mismatch");x[d.dst]=data;}
   if(d.dst>=32)require(unsigned(d.dst-32)==rd&&fp,"decoder/RTL FP destination mismatch");
   uint64_t cycle=c;cycles.write(reinterpret_cast<char*>(&cycle),8);
   out.write(reinterpret_cast<char*>(&r),sizeof r);h.count++;
  }else{
   if(s.find("T ")!=std::string::npos&&s.find("cause=")!=std::string::npos)require(s.find("cause=3 ")!=std::string::npos,"nonterminal trap not supported");
   if(s.find("[PASS] r64_core_program")!=std::string::npos)pass=true;
   if(s.find("[FAIL]")!=std::string::npos){
    require(allow_limit&&s.find("timeout: pc=")!=std::string::npos,"RTL validation failed");
    auto at=s.find("commits=");require(at!=std::string::npos,"cycle-limit lacks commit count");
    limit_commits=std::stoull(s.substr(at+8));
    limited=true;
   }
   std::cerr<<s<<"\n";
  }
 }
 if(allow_limit&&!pass){
  std::ifstream status(option.substr(21));require(bool(status),"cannot read RTL status");
  std::string line;
  while(std::getline(status,line)){
   if(line.find("[FAIL]")!=std::string::npos){
    require(line.find("timeout: pc=")!=std::string::npos,"RTL failure is not a cycle limit");
    auto at=line.find("commits=");require(at!=std::string::npos,"missing checked retirement count");
    limit_commits=std::stoull(line.substr(at+8));limited=true;
   }
  }
 }
 require((pass||limited)&&h.count>0,"missing successful terminal or explicit cycle-limit");
 if(limited)require(limit_commits==h.count,"cycle-limit commit count mismatch");
 if(pass)h.flags|=1;
 out.seekp(0);out.write(reinterpret_cast<char*>(&h),sizeof h);
 out.close();cycles.close();require(bool(out)&&bool(cycles),"output write failed");
 std::cerr<<(pass?"complete RTL trace: ":"bounded RTL prefix (full program incomplete): ")<<h.count<<" instructions\n";return 0;
 }catch(const std::exception&e){std::cerr<<"import error: "<<e.what()<<"\n";return 1;}}
