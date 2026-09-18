#pragma once
#include <array>
#include <cstdint>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>
namespace r64model {
inline void require(bool ok,const std::string& message){if(!ok)throw std::runtime_error(message);}
struct TraceHeader {char magic[8]={'R','6','4','T','R','C','1','\0'};uint64_t count=0,flags=0;};
// Little-endian ABI. Flags: natural ebreak=1, environment/timing reads=2.
struct Record {uint64_t pc=0,next=0,address=0,a=0,b=0;uint32_t raw=0,reserved=0;};
static_assert(sizeof(TraceHeader)==24&&sizeof(Record)==48);
inline std::vector<Record> read_trace(const std::string& path,TraceHeader& h){
 uint16_t endian=1;require(*reinterpret_cast<uint8_t*>(&endian)==1,"requires little endian");
 std::ifstream in(path,std::ios::binary);require(bool(in),"cannot open trace");
 in.read(reinterpret_cast<char*>(&h),sizeof h);
 require(bool(in)&&std::string(h.magic,8)==std::string("R64TRC1\0",8),"bad trace header");
 require(h.count>0&&h.count<=1000000000,"invalid trace length");
 in.seekg(0,std::ios::end);require(uint64_t(in.tellg())==sizeof h+h.count*sizeof(Record),"truncated/extra trace data");
 in.seekg(sizeof h);std::vector<Record> r(h.count);
 in.read(reinterpret_cast<char*>(r.data()),r.size()*sizeof(Record));require(bool(in),"trace read failed");return r;
}
}
