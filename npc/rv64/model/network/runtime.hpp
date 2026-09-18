#pragma once
#include <chrono>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <stdexcept>
#include <string>
#include "network_types.hpp"

namespace net {
struct Traffic {
  Inputs in{};
  uint64_t random=0x6370756e6574776fULL, sequence=1;
  uint64_t rand() {
    random^=random<<13; random^=random>>7; random^=random<<17;
    return random;
  }
  Inputs next(uint64_t cycle) {
    in[I_reset]=0;
    for(unsigned i=0;i<N;i++) {
      if(!in[SRC_OFFER[i]] && (rand()&3)!=0) {
        in[SRC_OFFER[i]]=1;
        in[SRC_OWNER[i]]=(sequence++)&OWNER_MASK;
        in[SRC_DATA[i]]=rand()&DATA_MASK;
      }
    }
    for(unsigned i=0;i<M;i++)
      in[SINK_READY[i]]=(cycle%257>=40) && ((rand()&7)!=0);
    for(unsigned i=0;i<CANCEL_PORTS;i++) {
      in[CANCEL_VALID[i]]=(cycle%47==0);
      in[CANCEL_OWNER[i]]=(sequence-1-i)&OWNER_MASK;
    }
    return in;
  }
  void feedback(const Outputs& out) {
    for(unsigned i=0;i<N;i++) {
      bool cancel=false;
      for(unsigned j=0;j<CANCEL_PORTS;j++)
        cancel|=in[CANCEL_VALID[j]] && in[CANCEL_OWNER[j]]==in[SRC_OWNER[i]];
      if(out[IN_FIRE[i]] || cancel) in[SRC_OFFER[i]]=0;
    }
  }
};
template<class Engine>
int run(int argc,char** argv) {
  try {
    const auto init_start=std::chrono::steady_clock::now();
    Engine engine;
    Inputs reset{}; reset[I_reset]=1;
    engine.step(reset); // Shared synchronous initialization, outside execution timing.
    const double init_seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-init_start).count();
    if(argc==4 && std::string(argv[1])=="--trace") {
      std::ifstream input(argv[2]);
      std::ofstream output(argv[3]);
      if(!input || !output) throw std::runtime_error("cannot open trace files");
      uint64_t count=0;
      while(true) {
        Inputs values{};
        if(!(input>>std::hex>>values[0])) {
          if(!input.eof()) throw std::runtime_error("invalid trace");
          break;
        }
        for(size_t i=1;i<values.size();i++)
          if(!(input>>std::hex>>values[i])) throw std::runtime_error("truncated input cycle");
        const auto result=engine.step(values);
        for(auto v:result) output<<std::hex<<v<<' ';
        output<<'\n'; count++;
      }
      if(!output) throw std::runtime_error("output write failed");
      std::cout<<"{\"cycles\":"<<count<<"}\n";
      return 0;
    }
    if(argc==3 && std::string(argv[1])=="--bench") {
      const auto cycles=std::stoull(argv[2]);
      if(!cycles) throw std::runtime_error("benchmark needs cycles");
      Traffic traffic;
      uint64_t checksum=UINT64_C(1469598103934665603),accepted=0;
      const auto start=std::chrono::steady_clock::now();
      for(uint64_t cycle=0;cycle<cycles;cycle++) {
        const auto result=engine.step(traffic.next(cycle));
        traffic.feedback(result);
        for(auto v:result) { checksum^=v; checksum*=UINT64_C(1099511628211); }
        for(auto index:IN_FIRE) accepted+=result[index];
      }
      const double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
      std::cout<<std::setprecision(12)<<"{\"cycles\":"<<cycles<<",\"accepted\":"<<accepted
               <<",\"checksum\":"<<checksum<<",\"initialization_seconds\":"<<init_seconds
               <<",\"execution_seconds\":"<<seconds<<"}\n";
      return 0;
    }
    throw std::runtime_error("usage: --trace INPUT OUTPUT | --bench CYCLES");
  } catch(const std::exception& e) {
    std::cerr<<e.what()<<'\n'; return 2;
  }
}
}
