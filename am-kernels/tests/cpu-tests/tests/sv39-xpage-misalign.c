#include "trap.h"

// 定向验证: rtl-ground-truth §3.1 #2 修复(OooIntBackend.v 跨页 misaligned plain 访存精确异常)。
// 分页(Sv39)开启下,跨 4KB 页的 misaligned plain store 应产生精确 STORE_ADDR_MISALIGN(cause 6),
// stval=EA(faulting VA)。修复前: 桥按起始 PA 物理连续静默写坏相邻物理页且不 trap → 本测试 FAIL;
// 修复后: 发射拍精确 trap(预占翻译,不发桥请求) → 本测试 GOOD。
// 注: 本测试自检独立跑,不挂 difftest —— NEMU 对同一跨页 misaligned 是静默按字节仿真、不 trap(参考模型有意分歧)。

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S    (1ul << 11)
#define SATP_MODE_SV39   (8ul << 60)
// leaf PTE flags V|R|W|X|A|D: A/D 预置(本核 SW-managed A/D, 否则首访 page fault 而非本测试要的 misaligned)。
#define PTE_LEAF_AD      0xcful
#define VPN2(va)         (((uintptr_t)(va) >> 30) & 0x1fful)
#define SYSCON           0x00100000ul   // reset_syscon (SiFive Test Finisher): 0x5555=GOOD

static uintptr_t xpage_root[512] __attribute__((aligned(4096)));
// 8KB 且 4KB 对齐 → 内部有一个 4KB 页界(buf+0x1000);&buf[0xFFC] 的 8 字节访问跨越该页界且非对齐。
static char xpage_buf[8192] __attribute__((aligned(4096)));
uintptr_t xpage_satp;
uintptr_t xpage_store_va;   // = &xpage_buf[0xFFC]

extern void xpage_trap(void);
extern void xpage_s_entry(void);

// 退出=AM 约定的 ebreak+a0(a0==0→GOOD TRAP, 否则 BAD;见 trm.c npc_trap)。ebreak→仿真停机。
asm(
".align 2\n"
".globl xpage_trap\n"
"xpage_trap:\n"                 // M 态 trap handler(MPRV=0, 物理访存)
"  csrr t4, mcause\n"
"  csrr t5, mtval\n"
"  la   t0, xpage_store_va\n"
"  ld   t2, 0(t0)\n"           // 期望 mtval = 跨页 store 的 VA
"  li   t1, 6\n"               // EXC_STORE_ADDR_MISALIGN
"  bne  t4, t1, xpage_bad\n"   // cause 必须 = 6
"  bne  t5, t2, xpage_bad\n"   // mtval 必须 = 跨页 store VA
"  li   a0, 0\n"               // GOOD
"  ebreak\n"
"xpage_bad:\n"
"  mv   a0, t4\n"              // 失败码=mcause(非 0)
"  ori  a0, a0, 0x100\n"       // 确保非 0
"  ebreak\n"

".align 2\n"
".globl xpage_s_entry\n"
"xpage_s_entry:\n"             // S 态: 开分页后做跨页 misaligned store
"  la   t0, xpage_satp\n"
"  ld   t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
"  la   t0, xpage_store_va\n"
"  ld   t0, 0(t0)\n"          // t0 = &xpage_buf[0xFFC]
"  li   t1, 0x1122334455667788\n"
"  sd   t1, 0(t0)\n"          // 8B 跨页 misaligned store → 应精确 trap(cause 6)
"  li   a0, 0x99\n"           // 到这里说明没 trap(bug) → FAIL
"  ebreak\n"
);

static inline void write_csr_mtvec(uintptr_t v)   { asm volatile("csrw mtvec, %0"   :: "r"(v) : "memory"); }
static inline void write_csr_medeleg(uintptr_t v) { asm volatile("csrw medeleg, %0" :: "r"(v) : "memory"); }
static inline void write_csr_mepc(uintptr_t v)    { asm volatile("csrw mepc, %0"    :: "r"(v) : "memory"); }
static inline uintptr_t read_csr_mstatus(void)    { uintptr_t v; asm volatile("csrr %0, mstatus" : "=r"(v)); return v; }
static inline void write_csr_mstatus(uintptr_t v) { asm volatile("csrw mstatus, %0" :: "r"(v) : "memory"); }

static void enter_s_mode(void) {
  uintptr_t s = read_csr_mstatus();
  s = (s & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(s);
  write_csr_mepc((uintptr_t)xpage_s_entry);
  asm volatile("mret" ::: "memory");
}

int main(void) {
  for (int i = 0; i < 512; i++) xpage_root[i] = 0;
  // 1GiB 超页恒等映射整个低 DRAM 区(代码/栈/页表/buf 全在 0x80000000 区),供 S 态运行与访存。
  // (跨页 misaligned 在发射拍预占翻译, 映射到哪并不影响 trap; 恒等超页只为让 S 态代码能跑。)
  uintptr_t base = (uintptr_t)0x80000000ul;
  xpage_root[VPN2(base)] = ((base >> 12) << 10) | PTE_LEAF_AD;
  xpage_store_va = (uintptr_t)&xpage_buf[0xFFC];
  xpage_satp = SATP_MODE_SV39 | ((uintptr_t)xpage_root >> 12);

  write_csr_mtvec((uintptr_t)xpage_trap);
  write_csr_medeleg(0);   // misaligned 不委托 → 进 M 态
  asm volatile("sfence.vma" ::: "memory");
  enter_s_mode();
  halt(1);   // 不应到达
  return 1;
}

#else

int main(void) { halt(0); return 0; }

#endif
