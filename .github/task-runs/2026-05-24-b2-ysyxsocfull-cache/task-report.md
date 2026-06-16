# B2 ysyxSoCFull Cache Closure

## 任务

- 完成 B2 相关内容，交付前关闭 ChipLink。
- 复查旧 bug：`riscv32-ysyxsoc` reset PC 在 MROM `0x20000000`，栈/数据在 SRAM `0x0f000000`，旧 `mem-test` 未覆盖 DCache cacheable 命中/回写。
- 特别关注跳转 cache 的取值，以及取数据的地址。

## 根因

- Full SoC 原 harness 不能直接加载 AM MROM 镜像，也缺少统一退出观测，无法稳定跑 B2 smoke。
- AM ysyxSoC UART init 写 divisor latch，但 UART 仿真未区分 DLAB，导致 DLL 写入可能被当作 THR 字符。
- RVC 跳转到半字地址时，uncached/MROM 取指路径容易丢失原 PC byte offset；cache line fill 地址和最终选字节地址必须分开处理。
- LSU 普通内存访问需要 word-aligned 地址配合 lane 提取，但 UART/MMIO 需要保留真实 byte register address。
- 旧 `mem-test` 只在 SRAM 上验证 byte lane/sign extension，不能证明 DCache write-back 或 dirty refill 正确。
- ysyxSoCFull 仿真中的 PSRAM QSPI shell 没有实际存储 backing，DCache dirty victim 写回后重读会失败。

## 改动

- `npc/soc` 增加 `soc-run`，ysyxSoCFull harness 支持加载 image、MROM/Flash DPI backing store、commit/exit DPI 和超时诊断。
- AM ysyxSoC 平台新增 16550 UART 初始化与 TX helper；`npc/soc` UART、ysyxSoC APB UART 修正 DLAB/enable-phase 行为，`npc/single` 保持平台无关 UART 实现。
- `npc/soc` ICache 将 MROM 纳入 cacheable 范围，line fill 使用对齐行地址，响应数据仍按原 PC offset 选择；`npc/single` ICache 仍只按基础 `0x8...` cacheable 范围工作。
- `npc/soc` I/D cache line 从 64B 调整为 32B，line 数从 64 调整为 128，总容量保持各 4KB，以匹配 ysyxSoC/ChipLink 侧 32B cache block 语义；`npc/single` 保持 4KB、64B line、64 lines。
- `npc/soc` LSUDataPath 对 MMIO 使用 byte address，对普通内存使用 word-aligned address；SoC AXI bridge 对 UART 读写选择 byte size。
- `mem-test` 新增 `0x80000000`/`0x80001000` cacheable PSRAM 检查，覆盖 DCache hit/miss/dirty writeback/refill。
- `ysyxSoC/perip/psram/psram_top_apb.v` 在 `ifndef SYNTHESIS` 下提供 Verilator APB behavioral PSRAM。

## 验证

- `make -C npc/soc soc-lint` PASS。
- `make -C npc/soc soc` PASS。
- `make -C npc/soc soc-run RUN_ARGS='--max-cycles 10000'`：内建 smoke GOOD TRAP，PC `0x20000004`。
- `make -C npc/soc soc-run IMG=/home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests/build/char-test-riscv32-ysyxsoc.bin RUN_ARGS='--max-cycles 2000000'`：串口输出 `putch path` 和 `AM_UART_TX path` 两行，GOOD TRAP。
- `make -C npc/soc soc-run IMG=/home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests/build/mem-test-riscv32-ysyxsoc.bin RUN_ARGS='--max-cycles 10000000'`：GOOD TRAP，PC `0x200002c6`。
- `git diff --name-only -- npc/single`：无输出，确认 SoC 地址图、MROM cacheable、UART DLAB 和 32B cache line 改动未残留到 single。
- `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-platform-guard-build RESULT_DIR=/tmp/npc-single-platform-guard-tests run`：26/26 PASS，验证 single 仍按平台无关核配置工作。
- `ARCH=riscv32-ysyxsoc ALL=mem-test YSYXSOC_RUN_ARGS='--no-diff --no-progress -m 0'`：PASS，DCache `access=12, hit=9, miss=3, writeback=16`。
- `git diff --check` PASS。
- `ysyxSoC/src/Top.scala` 确认 `hasChipLink=false`、`sdramUseAXI=false`；宿主进程检查未发现 ChipLink。

## 追加：2-way set-associative cache

### 需求与边界

- 用户要求先在 `npc/single` 继续开发核心，把 I/D cache 做成组相联结构；验证成功后应用到 `npc/soc`。
- 对外 CPU/cache 端口、AXI-like miss/refill/writeback 端口、cacheable/uncacheable 分流不改变。
- 总容量保持不变：`npc/single` 为 64B line、32 sets、2 ways；`npc/soc` 为 32B line、64 sets、2 ways；两边 ICache/DCache 均仍为各 4KB。
- `npc/soc` 继续保留 B2 修复中的 ICache MROM cacheable 规则；DCache 不缓存 UART/MMIO。

### RTL 推导

- 协议：lookup 同拍读出当前 set 的所有 way metadata/data，逐 way 比较 `valid && tag`；hit 直接返回对应 way，miss 进入 refill 或 writeback/refill；uncached 仍走原单拍外部读写序列。
- FSM：ICache 保持 idle/lookup/miss/refill/done 思路，miss 时先清 victim valid，整条 line 填完后一次性置 valid/tag；DCache 保持 lookup/miss/writeback/refill/flush 路径，flush 扫描所有 set/way/word 后 clear。
- 不变量：同一 set 内只允许命中 tag 相等且 valid 的 way；refill 中 victim way 不可被误命中；dirty victim 必须完整写回后才能被新 line 覆盖；`fence.i` 完成时 DCache dirty 数据已落到下级，I/D cache valid 已失效。
- 数据通路：tag/valid/dirty/data SRAM row 由 single-way 扩展为 packed ways；victim 选择 invalid-first，否则用每 set 1-bit pseudo-LRU；hit/refill 后更新 pseudo-LRU，使下一次替换优先淘汰较久未使用的另一路。

### 改动

- `npc/single/vsrc/include/define.v`、`npc/soc/vsrc/include/define.v` 新增 `ICACHE/DCACHE_WAY_COUNT=2` 和 `WAY_BITS=1`，同时把 set 数减半以保持容量不变。
- `npc/single/vsrc/cache/ICache.v`、`npc/soc/vsrc/cache/ICache.v` 改为 2-way tag/data 存储、逐 way 命中选择、invalid-first/pseudo-LRU victim 选择；SoC 版保留 MROM cacheable。
- `npc/single/vsrc/cache/DCache.v`、`npc/soc/vsrc/cache/DCache.v` 改为 2-way write-back/write-allocate，dirty victim writeback、store byte mask 更新、flush scan 都携带 way 维度。
- `npc/{single,soc}/testbench/tests/tb_icache.sv` 覆盖同 index 不同 tag 两路共存；`tb_dcache.sv` 覆盖两路共存、LRU dirty eviction 和 flush 多 way 脏行。

### 验证

- `make -B -C npc/single/testbench BUILD_DIR=/tmp/npc-setassoc-single-cache-tb2 RESULT_DIR=/tmp/npc-setassoc-single-cache-results2 .../tb_icache.log .../tb_dcache.log`：PASS。
- `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-setassoc-single-full-tb RESULT_DIR=/tmp/npc-setassoc-single-full-results run`：26/26 PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-setassoc-single-pipe-tb PIPE_RESULT_DIR=/tmp/npc-setassoc-single-pipe-results pipe_test`：PASS。
- `make -C npc/single -j4`：PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=mem-test NPC_SIM_BACKEND=single NPC_RUN_ARGS='--no-diff --no-progress -m 0' run`：PASS，GOOD TRAP，ICache `access=521, hit=510, miss=11`，DCache `access=76, hit=72, miss=4`。
- `make -C npc/soc lint`、`make -C npc/soc soc-lint`、`make -C npc/soc -j4`、`make -C npc/soc soc`：PASS。
- `make -B -C npc/soc/testbench BUILD_DIR=/tmp/npc-setassoc-soc-cache-tb2 RESULT_DIR=/tmp/npc-setassoc-soc-cache-results2 .../tb_icache.log .../tb_dcache.log`：PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=mem-test YSYXSOC_RUN_ARGS='--no-diff --no-progress -m 0' run`：PASS，GOOD TRAP，ICache `access=550, hit=528, miss=22`，DCache `access=12, hit=10, miss=2`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=char-test YSYXSOC_RUN_ARGS='--no-diff --no-progress -m 0' run`：PASS，串口两条路径输出完整。
- `make -C npc/soc/testbench BUILD_DIR=/tmp/npc-setassoc-soc-full-tb RESULT_DIR=/tmp/npc-setassoc-soc-full-results run`：非 cache 项失败，停在既有 `tb_uart` 期望 `status read got=0x00006000 expected=0x00006001` 和 `tx valid got=x expected=1`；cache 专项 I/D testbench 已单独通过。
- `git diff --check`：PASS。

## 结论

旧 bug 已修复：当前 `mem-test` 不再只测 SRAM，而是显式落到 `0x80000000` cacheable PSRAM 并触发 DCache 写回；Full ysyxSoCFull 也能用同一镜像跑通。追加组相联改造后，`npc/single` 和 `npc/soc` 均已切到 2-way set-associative cache，容量和外部协议保持不变；SoC 程序路径 `mem-test/char-test` 继续通过。ChipLink 交付时保持关闭。
