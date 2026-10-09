// Diagnostic: serialized cache-resident loads expose response-to-use latency.
// Both full programs remain the performance acceptance workloads.
.section .text
.globl _start
.option norelax
_start:
  la t0, node0
  li t1, 512
.globl load_chain_begin
load_chain_begin:
  .rept 16
  ld t0, 0(t0)
  .endr
  addi t1, t1, -1
  bnez t1, load_chain_begin
.globl load_chain_end
load_chain_end:
  la t2, node0
  bne t0, t2, fail
  li a0, 0
  ebreak
fail:
  li a0, 1
  ebreak

.section .data
.balign 64
node0: .dword node1
node1: .dword node2
node2: .dword node3
node3: .dword node4
node4: .dword node5
node5: .dword node6
node6: .dword node7
node7: .dword node8
node8: .dword node9
node9: .dword node10
node10: .dword node11
node11: .dword node12
node12: .dword node13
node13: .dword node14
node14: .dword node15
node15: .dword node0
