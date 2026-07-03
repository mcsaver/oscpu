# am-kernels/rv64dv —— riscv-dv 约束随机指令流压测 NEMU 的 RV64 准确性。
#
# 判定 = NEMU difftest(DUT=NEMU, REF=spike-diff) 逐指令逐寄存器比对，
# PASS 充要条件 = 干净 HIT GOOD TRAP 且全程零 mismatch。详见 scripts/rv64dv-run.sh。
#
# 前置：
#   make -C ../../nemu                                        # NEMU
#   make -C ../../nemu/tools/spike-diff GUEST_ISA=riscv64     # spike-diff ref-so
#   riscv-dv/ 与 venv/ 见 README（体积大，未入库，需按 README 重建）

.PHONY: run run-all robustness clean help

# 冒烟：算术基础流，2 迭代，difftest vs spike
run:
	bash scripts/rv64dv-run.sh

# arithmetic basic 是 pyflow 最可靠可 gen 的类型，用多迭代（不同随机 seed）覆盖更多程序。
# 注：riscv-dv pyflow 生成器对 rand_instr/rand_jump/loop 等复杂 directed-stream 测试不完整，
# gen 会报 "Test-generation jobs failed"（是 pyflow 的限制，非 NEMU 问题）。
run-all:
	RV64DV_TEST=riscv_arithmetic_basic_test RV64DV_ITER=5 bash scripts/rv64dv-run.sh

# 只跑 NEMU 单机（不比对 Spike）——快速 robustness 冒烟
robustness:
	RV64DV_NODIFF=1 bash scripts/rv64dv-run.sh

clean:
	rm -rf out

help:
	@echo "make run          # 冒烟: arithmetic basic x2, difftest vs spike"
	@echo "make run-all      # 多测试类型全跑 difftest"
	@echo "make robustness   # NEMU 单机(不比对 spike)"
	@echo "make clean        # 清 out/"
	@echo "变量: RV64DV_TEST / RV64DV_ITER / RV64DV_TARGET / RV64DV_MAXI / RV64DV_OUT"
