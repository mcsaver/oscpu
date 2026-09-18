#pragma once
#include <chrono>
#include <cstdint>
#include <cstdio>
// The same adapter is used for both engines. Functional checking and host
// device work stay in the original harness and outside the eval timer.
template<class Base> struct TimedDut : Base {
 using Clock=std::chrono::steady_clock;
 uint64_t eval_calls=0, eval_nanoseconds=0;
 void eval() {
  const auto start=Clock::now();
  Base::eval();
  eval_nanoseconds+=std::chrono::duration_cast<std::chrono::nanoseconds>(Clock::now()-start).count();
  ++eval_calls;
 }
 void final() {
  Base::final();
  std::fprintf(stderr,"R64_ENGINE_TIMING eval_calls=%llu eval_nanoseconds=%llu\n",
               (unsigned long long)eval_calls,(unsigned long long)eval_nanoseconds);
 }
};
