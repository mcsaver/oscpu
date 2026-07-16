# RV64 T3V — registered predecode and memory dataplane cut

目标：同时切断 T3U 精确 5 ns STA 暴露的两条独立长链：

1. fetch packet FIFO 头部 live Decode/ImmGen 经 backend admission 返回 frontend；
2. IntIssueQueue 经 PRF/AGU/LSU/class/order/request 组合写入 MemInflightQueue。

本目录只记录本轮可复现的命令、fresh synthesis 冻结审计、精确全局 OpenSTA 与功能证据。
探索性 what-if 不能替代 fresh netlist 的 sign-off 结论。

## 预期验证

- packet FIFO/HeadMux/Frontend 定向与 `OOO_ASSERT` coherence；
- IntBackend/IntIssueQueue/LRSC 定向；
- 全模块回归、真实 CoreMark、受保护日志校验；
- fresh 200 MHz synthesis，输入前后 SHA-256 一致；
- exact 5.0 ns global OpenSTA：`WNS >= 0`、`TNS >= 0`、combinational loops = 0。

## Seed dataplane 删除的受约束等价证据

生产前端中 fallthrough capture、branch-prefetch hit-to-FIFO 与 JALR-prefetch
hit 三个旧 seed owner 均为结构常量 0。运行：

```bash
python3 .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/check_seed_clear_equivalence.py
```

脚本穷举其余 20 个控制位的全部 `2^20 = 1,048,576` 种组合，要求旧编码器
`seed_valid` 恒 0，且旧 `clear` 与 T3V clear-only 编码器逐组合相等。冻结输出见
[`evidence/seed-clear-equivalence.txt`](./evidence/seed-clear-equivalence.txt)。

## 独立审查补强：memory owner 生命周期

T3V 功能审查发现并修复三类 request/metadata 守恒反例：

1. reservation 已交给 plain-memory buffer 后，younger branch kill 若发生在
   buffer fire 之前，旧实现不会再选择性清除该 owner；
2. backend 在 MIQ old-full + head-pop 同拍错误暴露 refill credit，而 MIQ 本体的
   old-full `push_fire` 不接受该 push，形成 bridge request 无 metadata；
3. LR reservation 只保存对齐地址、不保存 size，且 matching misaligned SC 的本地
   异常路径不会清 reservation。

修正后，buffer 按 ROB 环形年龄选择性 kill；同拍 fire 只把 owner 移交给 MIQ 的
same-cycle push-kill，未 fire 项直接清除。MIQ 满拍采用最小安全 parent backpressure，
下一拍空位可见后再发。LR 同时保存 address/size，SC 需二者均匹配，且任意 SC consume
均清 reservation。

可复现 focused gate：

```bash
.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/run-review-fixes-focused.sh
```

脚本使用独立 `BUILD_DIR` / `RESULT_DIR`，并冻结以下证据：

- [`tb_ooo_int_backend.log`](./evidence/review-fixes/tb_ooo_int_backend.log)：
  buffer selective kill、MIQ full+pop backpressure、双向 LR/SC size mismatch、
  matching misaligned SC clear，以及 released younger ALU exactly-once fire/commit；
- [`tb_ooo_int_issue_queue.log`](./evidence/review-fixes/tb_ooo_int_issue_queue.log)：
  IQ oldest/sticky/kill 合同回归；
- [`verilator-lint.log`](./evidence/review-fixes/verilator-lint.log)、
  [`rtl-style.log`](./evidence/review-fixes/rtl-style.log)、
  [`contract.log`](./evidence/review-fixes/contract.log) 与
  [`diff-check.log`](./evidence/review-fixes/diff-check.log)。

本节只签收功能与结构合同；200 MHz 仍必须由修正后 RTL 的 fresh synthesis / exact
5.0 ns global OpenSTA 单独裁决。

## Fetch fault 预译码集成证据

`tb_ooo_core_top_glue` 使用非零 `fault_addr=0x8000_0010` 注入 lane1
instruction access fault。测试要求 `OooFetchPacketDecode` 将 raw 写寄存器指令净化为
NOP，fault provenance 与预译码 bundle 一起进入并到达 registered FIFO head；随后由真实
CSR handler 读回 `mcause=1`、`mepc=mtval=0x8000_0010`，同时同包 lane0 older 指令提交，
fault raw 指令和 younger 指令均无副作用。冻结正向日志与摘要见
[`evidence/fetch-fault-predecode-v1`](./evidence/fetch-fault-predecode-v1/)。

## Coherence assertion mutation-negative

运行：

```bash
.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/run-predecode-coherence-mutation-negative.sh
```

脚本只在 workspace `tmp/` 创建 `OooFrontend.v` 临时副本，并在 lane1 fault 包入队时翻转
stored lane0 `rd` 的最低位；正式 RTL 不变。负向运行必须且仅一次命中
`T3V-PREDECODE-COHERENCE` lane0 签名，并由测试结果检查器判为 FAIL。冻结 mutation diff、
日志、SHA-256 与摘要见
[`evidence/predecode-coherence-mutation-negative-v1`](./evidence/predecode-coherence-mutation-negative-v1/)。
