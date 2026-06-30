# RV64 CoreMark 串口输出缺失 — DPI pmem/device 地址别名

## 目标
定位并修复 known-issues [T2]:`am-kernels/benchmarks/coremark && make ARCH=riscv64-npc run` 无任何 guest banner、`CoreMark PASS` 不打印的根因(此前仅记录为「未闭合缺口:putch 的 `sb 0xa00003f8` 已提交但宿主 stdout 无字符」)。

## 调用链 / 数据流(先摸清再动手)
guest `putch` → `sb a0,1016(a5)` 写 `0xa00003f8`(AM `SERIAL_PORT = DEVICE_BASE+0x3f8`)
→ RTL `OooExecuteBackend`→`OooMemAxiBridge`(S_WRITE_REQ 发 AW/W)→ `AxiLiteXbar`(译码 LEGACY_MMIO idx12,优先于重叠 SDRAM idx13)→ `AxiDpiSlave u_legacy_mmio_slave` → DPI `npc_mem_write`(dpi.c:317)
→ `npc_paddr_write`(paddr.c)→ **应** `npc_mmio_write`→`serial_write_cb`→`npc_log_putchar`(无条件 `fputc`+`fflush`)。

## 定位过程(分层探针,非纯静态推理)
1. 静态走通 C 侧 + RTL Xbar + cacheable 分类,均正确 → 怀疑动态层。
2. **误判并证伪**:疑 store 写回解耦提交 `042b147e1`(`bpend_q` 单跟踪器记账两个 outstanding B)。A/B 实验把 `store_decouple_w` 强制为 `1'b0` 重新 clean+build+run → **仍无输出**,证伪。
3. **决定性分层探针**(C 侧打点):
   - `npc_mem_write`(所有 DPI slave 必经)对 `0xa000_0000~0xa000_1000` 段打印 → **命中 458 次**,addr=0xa00003f8,data 拼出 "Running CoreMark…"(store 确实到达 DPI)。
   - `serial_write_cb` 打印 → **命中 0 次**;日志无 `out of bound`/`mmio write failed`。
   - 结论:store 到 DPI 后被**静默吞掉,从未进入 MMIO 分发**。

## 根因
`csrc/include/utils.h`:`NPC_PMEM_BASE=0x80000000`、`NPC_PMEM_SIZE=1 GiB`(注释「对齐 Linux DTS 1 GiB RAM」)→ host pmem 区间 `[0x80000000,0xbfffffff]` **别名覆盖 `NPC_DEVICE_BASE=0xa0000000` 设备窗口**。`npc_paddr_write/read`(paddr.c)**先判 `npc_in_pmem(addr)` 命中即写 host 数组并 return,永不走 `npc_mmio_write`**。故 `npc_in_pmem(0xa00003f8)=true`(offset 0x200003f8 < 0x40000000),串口/RTC 等设备访问被当普通内存吞掉。这也解释「PMEM store(0x8xxx)正常、设备段 store/读丢失」。

## 修复(仅 1 文件 `csrc/memory/paddr.c`,22 行)
`npc_paddr_write` 与 `npc_paddr_read` 对 `addr >= NPC_DEVICE_BASE` 的访问**优先尝试 MMIO**(命中走设备回调 + `npc_difftest_skip_ref()`,miss 才回落 pmem;读路径保持 ifetch 不穿设备)。语义与 RTL `AxiLiteXbar` 中 LEGACY_MMIO 译码优先于重叠 SDRAM 完全一致;保留 1 GiB pmem 不动,Linux RAM 语义不受影响(设备窗内字节本就是设备、非 RAM)。附带修复 RTC(0xa0000048)读从 pmem 垃圾值恢复为真实计时。

## 验证
`make ARCH=riscv64-npc clean && make ARCH=riscv64-npc ITERATIONS=1 run NPC_RUN_ARGS="--max-cycles 20000000"`:
- 完整 banner 恢复:`Running CoreMark for 1 iterations` … `CoreMark PASS       1 Marks`(含 seedcrc/crclist/crcmatrix/crcstate/crcfinal 全部打印)。
- `HIT GOOD TRAP` pc=0x80001fd8、exit code=0、cycles=370320、commits=350766、CPI≈1.056。

## 未完成 / 风险
- 全量 AM(57)/difftest(41)/官方 riscv-tests 回归未在本轮重跑;提交前建议补跑确认 MMIO 优先改动无回归(理论上只影响设备段,difftest MMIO 已 skip_ref)。
- 更深层是内存图设计冲突:设备 base 0xa0000000 与 1 GiB pmem / RTL SDRAM(0xa0000000-0xbfffffff)地址重叠,本修复用「设备优先」化解(同 RTL Xbar),非重排内存图。
