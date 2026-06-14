# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-riscv-nemu-imbc`
- `task_slug`: `riscv-nemu-imbc`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

---

### [2026-05-19 13:05] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求实现 NEMU IMBC 扩展与 Kconfig 编译器同步控制
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、project/memory、NEMU/AM 源码
- `action`: 读取工程规则、NEMU Kconfig、`inst.c`、AM RISC-V Makefile 和平台运行链路
- `outputs`: 确认现状为 NEMU 只暴露 `RV64/RVE`，`inst.c` 无条件实现部分 M，AM 硬编码 `-march=rv32im_zicsr`
- `evidence`: `rg`/`sed` 调研输出
- `handoff_to`: `config-compiler-bridge`
- `next_step`: 新增扩展配置与编译参数桥接
- `notes`: 任务跨 NEMU/AM/am-kernels，按图任务记录

### [2026-05-19 13:20] `config-compiler-bridge` - `completed`

- `owner_agent`: Codex
- `trigger`: 配置和 guest 编译器脱节
- `depends_on`: `recall`
- `inputs`: `nemu/src/isa/riscv32/Kconfig`、`abstract-machine/scripts/riscv32*-nemu.mk`
- `action`: 新增 `RISCV_EXT_M/B/C`；新增 `riscv-nemu-ext.mk` 从 `auto.conf` 拼接 `-march/-mabi`；为 AM 对象规则增加 `EXTRA_DEPS`
- `outputs`: Kconfig 与 AM guest 编译器使用同一组扩展配置；关闭 M 后仍链接 libgcc 软件乘除
- `evidence`: `readelf -A` 在不同配置下显示对应 ISA 属性
- `handoff_to`: `nemu-imbc-impl`
- `next_step`: 实现条件译码
- `notes`: B 使用 `_zba_zbb_zbc_zbs`，因为本机 GCC 13 不接受裸 `b`

### [2026-05-19 13:35] `nemu-imbc-impl` - `completed`

- `owner_agent`: Codex
- `trigger`: NEMU 需要按 Kconfig 实际接受或拒绝扩展指令
- `depends_on`: `config-compiler-bridge`
- `inputs`: `nemu/src/isa/riscv32/inst.c`
- `action`: 拆分 RV32I/M/B OP 表，补 `mulhsu`；实现 Zba/Zbb/Zbc/Zbs；新增 RV32C 可变长度取指和压缩整数指令；同步 `misa/mepc` 和反汇编 C 模式
- `outputs`: NEMU RV32 IMBC 扩展实现
- `evidence`: `make -C nemu -j4` 通过
- `handoff_to`: `verify`
- `next_step`: 多配置验证
- `notes`: 未实现浮点压缩和 RV64C 编码，遇到这些编码仍走 illegal trap

### [2026-05-19 13:50] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要证明默认配置、M 关闭、B/C 开启三类行为
- `depends_on`: `nemu-imbc-impl`
- `inputs`: 本地 `.config` 备份、AM cpu-tests、手写 `/tmp/riscv-bc-smoke.S`
- `action`: 默认配置构建+`add`；临时关闭 M 跑 `mul-longlong`；临时开启 M+B+C 跑 `add` 和 B/C 裸 smoke；最后恢复 `.config`
- `outputs`: 四条验证证据
- `evidence`: `add PASS`；`mul-longlong PASS` with `rv32i_zicsr`；M+B+C `add PASS` with `rv32imc_zicsr_zba_zbb_zbc_zbs`；裸 smoke `HIT GOOD TRAP`
- `handoff_to`: `record`
- `next_step`: 写 memory
- `notes`: 裸 smoke 临时关闭 difftest，因为裸镜像未同步 Spike PC，AM 程序 difftest 路径仍正常

### [2026-05-19 13:58] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 代码和验证完成
- `depends_on`: `verify`
- `inputs`: 验证输出和改动清单
- `action`: 更新 project-status、modules/nemu、modules/abstract-machine、modules/am-kernels，并新增 task report/dispatch log
- `outputs`: 本目录记录与 memory 追加条目
- `evidence`: 文件已落盘
- `handoff_to`: 无
- `next_step`: 向用户汇报
- `notes`: 保留既有用户/前序任务脏文件，不做回退

### [2026-05-19 14:05] `difftest-root-cause` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户反馈“difftest 跑不过”
- `depends_on`: `verify`
- `inputs`: M+B+C+DIFFTEST 配置、cpu-tests 失败日志、反汇编
- `action`: 复现全量 cpu-tests difftest 失败，按失败 PC 反汇编定位第一类 C 分支跳远和第二类 B 指令 REF illegal trap
- `outputs`: root cause 拆成 `c_imm_b()` 位拼接错误、Spike so 未依赖配置、PA Spike 未编入 B 指令列表
- `evidence`: `leap-year/string` 在 `c.bnez` 后 PC mismatch；`shuixianhua/bit` 在 `sh2add/bext` 后 REF PC 变为 0
- `handoff_to`: `spike-ref-fix`
- `next_step`: 修 NEMU C 分支立即数与 Spike REF 构建链路
- `notes`: 失败不是单一 NEMU 语义错误，REF 构建内容也与 ISA 字符串脱节

### [2026-05-19 14:20] `spike-ref-fix` - `completed`

- `owner_agent`: Codex
- `trigger`: Spike REF 对 B 指令 illegal trap
- `depends_on`: `difftest-root-cause`
- `inputs`: `nemu/src/isa/riscv32/inst.c`、`nemu/tools/spike-diff/Makefile`、Spike `repo/build/riscv.mk`
- `action`: 修正 `c_imm_b()`；让 `riscv32-spike-so` 依赖 `auto.conf/autoconf.h`；在 Spike build 中把 `riscv_insn_ext_b` 加回 `riscv_insn_list` 并去掉 phony Spike 依赖
- `outputs`: NEMU/REF 在 C 分支和 B 指令上重新一致，避免并发测试重链 so 造成 `dlopen` 失败
- `evidence`: `make -C nemu -j4` 通过；`make -C nemu/tools/spike-diff GUEST_ISA=riscv32` 重建后 `insn_list.h` 含 `sh2add/bext/...`
- `handoff_to`: `full-difftest-regression`
- `next_step`: 针对性与全量 difftest 验证
- `notes`: 首次重新编译 Spike B 指令对象较慢，后续 stamp 生效后不再重复重编

### [2026-05-19 14:34] `full-difftest-regression` - `completed`

- `owner_agent`: Codex
- `trigger`: 修复完成后需要验证用户的 difftest 问题
- `depends_on`: `spike-ref-fix`
- `inputs`: M+B+C+DIFFTEST 配置、AM cpu-tests
- `action`: 先跑 `leap-year/string/shuixianhua/bit/mul-longlong` 针对性测试，再跑 cpu-tests 全量回归
- `outputs`: difftest 失败消失
- `evidence`: `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 结果 35/35 PASS
- `handoff_to`: `record`
- `next_step`: 更新 memory 并向用户汇报
- `notes`: 当前 `.config` 与进入本轮调试前保存的配置一致，均为 M+B+C+DIFFTEST 开启
