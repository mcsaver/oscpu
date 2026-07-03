# rv64dv —— riscv-dv 压测 NEMU 的 RV64 准确性

用 [chipsalliance/riscv-dv](https://github.com/chipsalliance/riscv-dv) 生成**约束随机**的 RV64
指令流，逐条比对 NEMU 与 Spike，把 arch-test（定向用例）覆盖不到的组合空间也压一遍。

## 定位

- **平台无关的重型压测**，引入 am-kernels，作为 arch-test 之后更狠的一层。
- **仅 NEMU**：暂不接 NPC（NPC 自身有 bug）。先用 riscv-dv 死磕 NEMU 的准确性、把 NEMU
  确立为可信金标准，之后再做 NPC↔NEMU 的 difftest。
- **判定比 tohost 自检更强**：riscv-dv 生成的程序不是自检的，靠外部逐指令比对。这里直接
  复用 NEMU 自带的 difftest —— DUT=NEMU、REF=`spike-diff`，每条指令后逐寄存器 + PC 比对，
  任何行为差异立即报 mismatch。一个测试 **PASS 的充要条件 = 干净 `HIT GOOD TRAP` 且全程零 mismatch**。

## 流程

```
riscv-dv pyflow 生成随机 .S  →  riscv-none-elf-gcc 编译  →  NEMU difftest(-d spike-so)
```

## 用法

前置（一次）：

```sh
make -C ../../nemu                                        # NEMU 解释器
make -C ../../nemu/tools/spike-diff GUEST_ISA=riscv64     # spike-diff ref-so (riscv64)
```

跑：

```sh
make run          # 冒烟：arithmetic basic x2 迭代，difftest vs spike
make run-all      # 多测试类型全跑（arithmetic / rand_instr / rand_jump / loop）
make robustness   # 只跑 NEMU 单机（不比对 spike），快速看崩不崩
```

可调变量（见 `scripts/rv64dv-run.sh` 头部）：`RV64DV_TEST` / `RV64DV_ITER` /
`RV64DV_TARGET`（pyflow 仅提供 `rv64imafdc`）/ `RV64DV_MAXI` / `RV64DV_OUT` / `RV64DV_NODIFF`。

## 已发现并修复的 NEMU 准确性 bug

rv64dv 首轮压测即在 NEMU 上定位了两个真 bug（均 arch-test / Linux / CoreMark 未暴露）：

1. **`csrw misa` 被误判 illegal**。misa 是 WARL，写非法位应当被忽略而非抛非法指令异常。
   riscv-dv 的 boot code 在设 mtvec 之前 `csrw misa`，NEMU 抛非法 → trap 到 mtvec=0 → 跑飞到
   pc=0。修：`nemu/.../inst/csr.c` 的 `csr_write` 补 `CSR_MISA` 的 WARL 写（接受并忽略）。
2. **write-back dcache 的 store 绕过 tohost 退出检测**。NEMU 是真 write-back dcache，走 dcache
   的 store 只落 dirty 行、不到 pmem，绕过了 `paddr_write()` 里的 tohost 检查；而检查又用
   `pmem_read` 读 tohost（stale 0）。于是 `write_tohost` 退出——尤其反复写 tohost 的 self-loop
   ——被彻底漏判，NEMU 不停机跑满 max-insts。修：`dcache_write` 写后补 `paddr_tohost_check_write`，
   且检查改用 `dcache_peek_read` 一致视图读 tohost（与 Sv39 walker 读 PTE 同源的 dcache↔直读一致性坑）。

## 重建 riscv-dv 与 venv（未入库）

`riscv-dv/`（生成器）与 `venv/`（python 依赖）体积大（~278M），已在 `.gitignore` 排除。重建：

```sh
git clone https://github.com/chipsalliance/riscv-dv riscv-dv
python3 -m venv venv && . venv/bin/activate
pip install pyvsc pyyaml bitstring pandas tabulate
# Python 3.12 兼容：riscv-dv 的 pygen/pygen_src/.../riscv_instr.py
#   把 `from imp import reload` 改成 `from importlib import reload`
deactivate
```

生成器 target 用 `rv64imafdc`（pyflow 未提供 rv64gc target）。

## pyflow 生成器的已知限制

`riscv_arithmetic_basic_test` 可稳定生成；但 `riscv_rand_instr_test` / `riscv_rand_jump_test` /
`riscv_loop_test` 等依赖复杂 directed-stream（`riscv_hazard_instr_stream` /
`riscv_multi_page_load_store_instr_stream` / `riscv_mem_region_stress_test` 等）的测试，pyflow
（纯 Python 后端）实现不完整，gen 会报 `Test-generation jobs failed`。**这是 riscv-dv pyflow 的
限制，与 NEMU 无关**；要跑这些类型需切 riscv-dv 的 SystemVerilog+UVM 生成后端（依赖商业仿真器）。
因此 `make run-all` 聚焦 `arithmetic_basic` 多迭代（不同随机 seed）覆盖更多随机程序。
