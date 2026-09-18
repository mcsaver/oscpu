#pragma once
#include <array>
#include <cstddef>
#include <cstdint>

namespace r64 {
// DUT state reconstructed in architectural retirement order by the simulator.
struct ArchitecturalState {
 uint64_t x[32]={},f[32]={};
 uint64_t pc=0x80000000;
};
// Slot i is csr_snapshot_o[64*i +: 64]; the reference exports 32 slots,
// of which 0..26 are defined. The comparison policy remains in DiffTest.
using CsrSnapshot=std::array<uint64_t,27>;
struct ReferenceConfig {
 uint64_t memory_base;
 uint8_t* memory;
 size_t memory_size;
 const char* disk=nullptr;
 void (*serial_sink)(uint8_t)=nullptr;
 bool require_uart_input=false;
 bool require_syscon=false;
};

// NEMU interface and event/comparison policy. No Verilator/model types or
// simulator globals cross this boundary. Memory remains owned by the caller.
class DiffTest {
 public:
 explicit DiffTest(const char* path,const ReferenceConfig& config);
 DiffTest(const DiffTest&)=delete;
 DiffTest& operator=(const DiffTest&)=delete;
 void step(const ArchitecturalState& dut,uint64_t at,uint64_t next,uint64_t raw=0);
 void trap(const ArchitecturalState& dut,uint64_t at,uint64_t next,unsigned cause,
           bool interrupt,uint64_t tval,uint64_t raw);
 void check_csrs(uint64_t pc,const CsrSnapshot& dut);
 uint64_t read_memory(uint32_t address,int bytes) const {return peek(address,bytes);}
#ifdef R64_SYSTEM
 bool receive_serial(uint8_t byte) const {return serial_receive(byte);}
 uint32_t syscon_value() const {return read_syscon();}
#endif
#ifdef R64_TENSOR
 bool extension_complete() const {return descriptor_words==0;}
#endif
 private:
 struct Context {uint64_t x[32],pc;}; // NEMU difftest_regcpy ABI (GPR + PC).
 ReferenceConfig config_;
 void* handle;
 void (*init)(int);
 void (*copy)(uint32_t,void*,size_t,bool);
 void (*regs)(void*,bool);
 void (*exec)(uint64_t);
 void (*csrs)(void*);
 void (*fprs)(void*);
 void (*raise)(uint64_t);
 void (*exception)(uint64_t,uint64_t);
 void (*set_gpr)(unsigned,uint64_t);
 uint64_t (*peek)(uint32_t,int);
#ifdef R64_SYSTEM
 bool (*serial_receive)(uint8_t);
 uint32_t (*read_syscon)();
#endif
#ifdef R64_TENSOR
 std::array<uint64_t,30> descriptor{};
 unsigned descriptor_words=0;
 void extension(const ArchitecturalState& dut,uint64_t at,uint64_t next,
                uint64_t raw,const Context& before);
 bool mapped(uint64_t address,size_t bytes) const;
 uint64_t read64(uint64_t address) const;
#endif
 void compare(const ArchitecturalState& dut,uint64_t at,uint64_t next);
};
} // namespace r64
