# RV64 Sv39 Bridge 与小型 Linux Boot 模拟

## 目标

- 在 `npc/rv64` OoO core 上推进真实 Linux 启动前置能力：补齐 Sv39 正常翻译路径，保持 CoreMark CPI 低于 `0.8`。
- 新增复杂 testbench，模拟 M-mode firmware handoff 到 S-mode、开启 `satp`、执行 `sfence.vma`、通过页表完成取指和数据访存、处理 delegated ecall 并 `sret` 返回。

## RTL 推导

1. 需求边界：Linux 早期进入 S-mode 后会打开 `satp.MODE=Sv39`，随后 IFU/LSU 必须按 PTE 翻译虚拟地址；本轮先实现 success path 与权限检查，不声称完整 Linux boot。
2. 协议与状态：IFU/LSU bridge 在 paging 关闭时保持原 cache 快路径；paging 开启时独占 AXI read channel 串行读取 PTE，再发起真实指令/数据访问，避免虚拟地址 tag cache alias。
3. 不变量：M-mode 访问不翻译；数据访存 privilege 使用 `MPRV/MPP`；Sv39 canonical VA、PTE invalid、leaf/non-leaf、superpage 对齐、A/D、U/S、MXR/SUM、X/R/W 权限都必须在 bridge 内被判定；fault 与 bus access error 分开回传。
4. 数据通路：`CsrFile` 导出 `mstatus`，`OooAluFetchCore` 导出 `priv_mode/mstatus/satp`，`NpcCoreTop` 接到 `OooFetchAxiBridge/OooMemAxiBridge`；后端通过新增 page-fault response 位区分 load/store page fault cause。

## 实现摘要

- `OooFetchAxiBridge` 增加 Sv39 instruction page walk，支持 1GB/2MB/4KB leaf 翻译、跨页 `pc+4` 单独翻译、page fault response 编码。
- `OooMemAxiBridge` 增加 Sv39 data page walk，支持 `MPRV/MPP` effective privilege、MXR/SUM、A/D、R/W/U 权限和 superpage 对齐检查，并新增 mem0/mem1 page-fault response。
- `OooAluFetchCore/OooAluCoreSlice/OooAluDecodeBackend/OooIntBackend/NpcCoreTop/CsrFile/define.v` 同步 page fault cause、CSR 状态导出与跨模块接线。
- 新增 `tb_ooo_sv39_boot`，覆盖 IFU/LSU 页表读取、S-mode `ld/sd`、delegated ecall handler、`sret` 后继续执行并 `ebreak` 退出。

## 验证证据

- `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot" RESULT_DIR=/tmp/rv64-sv39-boot run`：PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_sv39_boot tb_ooo_int_backend tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-sv39-focused run`：3/3 PASS。
- `make -C npc/sim BACKEND=rv64 lint`：PASS。
- `make -C npc/sim BACKEND=rv64 -j4`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`：40/40 PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`：CoreMark PASS，`cycles=247287514`、`commits=317356136`、`CPI=0.779`。

## 剩余风险

- 当前是 Sv39 success path 与小型 boot 模拟，真实 Linux 仍需要 page fault 精确进入 CSR trap/delegation、SBI/PLIC/virtio/DTB/真实镜像加载等平台能力。
- `npc/rv64/testbench` 全量 run 仍受旧 `tb_ooo_alu_fetch_core` 历史断言阻塞，已记录在 known issues。
