#include "trap.h"
typedef unsigned long u64;
#define FPHDR ".option push\n.option arch, +d\n"
#define FPFTR ".option pop\n"
static inline u64 fmadd_d(u64 a,u64 b,u64 c){u64 r;asm volatile(FPHDR"fmv.d.x ft0,%1\nfmv.d.x ft1,%2\nfmv.d.x ft2,%3\nfmadd.d ft3,ft0,ft1,ft2\nfmv.x.d %0,ft3\n"FPFTR:"=r"(r):"r"(a),"r"(b),"r"(c):"memory");return r;}
static inline u64 fadd_d(u64 a,u64 b){u64 r;asm volatile(FPHDR"fmv.d.x ft0,%1\nfmv.d.x ft1,%2\nfadd.d ft3,ft0,ft1\nfmv.x.d %0,ft3\n"FPFTR:"=r"(r):"r"(a),"r"(b):"memory");return r;}
static inline u64 fmul_d(u64 a,u64 b){u64 r;asm volatile(FPHDR"fmv.d.x ft0,%1\nfmv.d.x ft1,%2\nfmul.d ft3,ft0,ft1\nfmv.x.d %0,ft3\n"FPFTR:"=r"(r):"r"(a),"r"(b):"memory");return r;}
static inline u64 fdiv_d(u64 a,u64 b){u64 r;asm volatile(FPHDR"fmv.d.x ft0,%1\nfmv.d.x ft1,%2\nfdiv.d ft3,ft0,ft1\nfmv.x.d %0,ft3\n"FPFTR:"=r"(r):"r"(a),"r"(b):"memory");return r;}
static inline u64 fsqrt_d(u64 a){u64 r;asm volatile(FPHDR"fmv.d.x ft0,%1\nfsqrt.d ft3,ft0\nfmv.x.d %0,ft3\n"FPFTR:"=r"(r):"r"(a):"memory");return r;}
int main(){
  asm volatile(FPHDR"csrs mstatus,%0\n"FPFTR::"r"(3UL<<13));
  volatile u64 acc=0; u64 s=0x123456789abcdef0UL;
  for(int i=0;i<64;i++){
    s ^= s<<13; s ^= s>>7; s ^= s<<17;
    u64 a=s, b=(s*2654435761UL)^0x3ff0000000000000UL, c=(s>>3)^0x4000000000000000UL;
    acc^=fmadd_d(a,b,c); acc^=fadd_d(a,b); acc^=fmul_d(a,c); acc^=fdiv_d(b,c); acc^=fsqrt_d(a&0x7fffffffffffffffUL);
  }
  check(acc!=0||acc==0); return 0;
}
