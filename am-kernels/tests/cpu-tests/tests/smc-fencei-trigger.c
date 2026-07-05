// smc-fencei-trigger.c — fence.i / SMC 触发微测 (Step A: 先证据)
// ---------------------------------------------------------------------------
// 目的: 证明本核 fence.i 是 no-op、且对"已进 ROB 的陈旧 uop"零保护, 从而在
// 运行期自修改代码(SMC)时静默错执, 与 NEMU 参考发散。
//
// 与既有 SMC 测试(riscv-tests fence_i.S / cpu-tests fence-i.c)的本质区别:
// 那两个用例都通过【间接 jalr】到达被改写的代码 —— 目标在 store 退休【之后】
// 才被取指, 因此 store→fetch-packet-cache 失效(NpcCoreTop: ooo_icache_
// invalidate on store fire)就足以喂到新字节, 与 fence.i 是否 flush 无关,
// 于是即便 fence.i 是 no-op 也能过。它们【测不到】本核真正的缺口。
//
// 本测把被改写指令 L 放在 store+fence.i 的【直线 fall-through】路径上, 且紧邻
// fence.i(同 8B 取指包 / 下一包)。宽/流水取指远跑在前, 在 store 把新字节写回
// 内存【之前】就把 L 以【旧字节】译码进了 ROB。store fire 只失效 fetch-packet
// cache(L 早已离开取指级), fence.i 退休又不 flush 流水 → 陈旧 L 直接提交。
//   正确机器(NEMU / 修后 DUT): L 重取 = 新指令 addi a0,a0,2 → 返回 seed+2
//   现状 DUT(bug):             L 陈旧   = 旧指令 addi a0,a0,1 → 返回 seed+1
// difftest 在 L 的提交拍比对架构寄存器即发散; 独立跑则 check() 失败 BAD TRAP。
//
// 修复(GAP-6/#3B: fence.i 真 flush)后, 两变体均收敛且 GOOD TRAP —— 本测直接
// 转为回归护栏。
// ---------------------------------------------------------------------------
#include "trap.h"

#if defined(__ISA_RISCV64__)

// 旧字节(汇编期落地): addi a0, a0, 1  = 0x00150513
// 新字节(运行期 SMC store 覆写): addi a0, a0, 2 = 0x00250513
// li 立即数用新编码; 目标标号处汇编旧编码。

unsigned long smc_fencei_probe_samepkt(unsigned long seed);  // 变体(a): L 与 fence.i 同 8B 包
unsigned long smc_fencei_probe_nextpkt(unsigned long seed);  // 变体(b): L 在 fence.i 的下一包

asm(
".text\n"
".option push\n"
".option norvc\n"                 // 强制 4B 指令: 保证取指包/对齐计算精确
// ---- 变体(a): fence.i 对齐到 8B 边界, L 落在同一取指包的 +4 处 ----
".p2align 3\n"
".globl smc_fencei_probe_samepkt\n"
"smc_fencei_probe_samepkt:\n"
"  la    t0, 1f\n"               // t0 = 被改写指令 L 的地址
"  li    t1, 0x00250513\n"       // 新指令: addi a0,a0,2
"  sw    t1, 0(t0)\n"            // SMC store: 用新字节覆写 L
"  .p2align 3\n"                 // 让 fence.i 落在 8B 边界(取指包偏移 0)
"  fence.i\n"                     // [pkt+0] 架构语义: 此后应重取
"1:\n"
"  addi  a0, a0, 1\n"            // [pkt+4] 与 fence.i 同 8B 包; 汇编=旧(+1), SMC=新(+2)
"  ret\n"
// ---- 变体(b): L 对齐到 8B 边界(新包起点), fence.i 在其前一包 ----
".globl smc_fencei_probe_nextpkt\n"
"smc_fencei_probe_nextpkt:\n"
"  la    t0, 2f\n"
"  li    t1, 0x00250513\n"
"  sw    t1, 0(t0)\n"
"  fence.i\n"                     // 位于 2f 前一取指包
"  .p2align 3\n"                 // L 起于新的 8B 取指包
"2:\n"
"  addi  a0, a0, 1\n"            // 下一包; 汇编=旧(+1), SMC=新(+2)
"  ret\n"
".option pop\n"
);

int main(void) {
  // 变体(a): 同包。旧(+1) vs 新(+2)。期望新语义 → seed+2。
  check(smc_fencei_probe_samepkt(100) == 102);
  // 变体(b): 下一包。同上。
  check(smc_fencei_probe_nextpkt(200) == 202);
  return 0;
}

#else

int main(void) { return 0; }  // 仅 rv64 有意义

#endif
