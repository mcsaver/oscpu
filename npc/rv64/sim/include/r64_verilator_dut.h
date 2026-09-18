#pragma once
#ifdef R64_TENSOR
#include "VR64TensorTestTop.h"
using Dut=VR64TensorTestTop;
#elif defined(R64_SYSTEM)
#include "VR64SystemTestTop.h"
using Dut=VR64SystemTestTop;
#else
#include "VR64CoreTestTop.h"
using Dut=VR64CoreTestTop;
#endif
#include "verilated.h"
#ifndef R64_HOST_THREADS
#define R64_HOST_THREADS 1
#endif
namespace r64 {
inline void initialize_dut(int argc,char** argv){
 // Match generated model threads, avoiding idle workers in short regressions.
 Verilated::threadContextp()->threads(R64_HOST_THREADS);
 Verilated::commandArgs(argc,argv);
}
} // namespace r64
