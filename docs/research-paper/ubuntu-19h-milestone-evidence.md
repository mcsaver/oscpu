# NPC Ubuntu 22.04 十九小时 A3 里程碑证据

## 1. 结论先行

2026-07-27 19:16:03（+08:00）启动的 A3 长跑，把 design-id
`sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
绑定的 NPC/Verilator 设计推进到了一个此前没有被同等级证据覆盖的系统节点：

```text
OpenSBI
  -> Linux 6.6
  -> virtio-blk /dev/vda
  -> ext4 根文件系统
  -> Ubuntu 22.04 / systemd PID1
  -> root 身份下的严格检查
  -> rootfs 写入、sync、回读
  -> virtio direct read 与 IRQ 增长
  -> systemd 发起并完成有序关机
  -> SBI system reset / syscon poweroff
  -> Verilator clean exit
```

原始 live run 仍然必须保留为 `FAIL`：17 个 strict label 中只有 16 个
打印 PASS，旧检查器把内核的 benign 文本 `printk: debug:` 中的 `bug`
误识别为 `BUG:`。冻结日志上的 oracle 重放证明这是检查器假阳性，并把系统事务分类为
`COMPLETE_WITH_LEGACY_ORACLE_FALSE_POSITIVE`；但重放不改写原始状态，也不构成
raw 17/17 recertification PASS、architecture freeze 或 PPA qualification。

## 2. 时间口径

| 时间对象 | 原始值 | 解释 |
|---|---:|---|
| A3 启动 | `2026-07-27T19:16:03.507791071+08:00` | `launched-at.txt` |
| 状态文件写入 | `2026-07-28 14:30:46.585031091 +0800` | `stat` 读取 A3 status mtime |
| 整条流水线墙钟时间 | 约 `19 h 14 min 43 s` | 启动到 fail-closed 状态落盘，含准备和收尾 |
| simulator 自报 host time | `67,702,309,461 us` | 约 `18 h 48 min 22 s`，是主仿真耗时 |
| guest 关机时间戳 | `49.720532 s` | guest 的虚拟时间，不是宿主墙钟时间 |

因此，“十九小时 Ubuntu 启动”应解释为：宿主机用约十九小时完成了一次约
49.7 guest-second 的 RTL 系统事务。它既证明了验证深度，也暴露了当前
Verilator 路径约三位数量级的实时减速，不能写成 Ubuntu 在 guest 中连续运行了十九小时。

## 3. 原始数据流证据

原始 console：

`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/guest/console.log`

console SHA-256：

`4cd087fc5ef5d466d6232987fecaf3765db5dc93dfe28366401e2da4501c60f0`

| console 行 | marker | 能够支持的结论 |
|---:|---|---|
| 25 | `OpenSBI v1.8` | 固件入口和下一阶段交接开始 |
| 88 | `Linux version 6.6.0` | Linux 内核执行 |
| 170–171 | `virtio_blk virtio0`、`[vda] 4194304 ...` | guest 驱动识别 2 GiB virtio block |
| 178 | `Mounted root (ext4 filesystem) on device 254:0` | 根文件系统从 block device 挂载 |
| 212 | `systemd 249.11-0ubuntu3.21 running in system mode` | PID1 进入 Ubuntu systemd 用户空间 |
| 418 | `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0` | PID1 下的早期自动检查完成 |
| 468–502 | riscv64、Ubuntu 22.04、root、shell、systemd、vda、virtio-blk PASS | 用户空间身份、程序和设备驱动均被 guest 脚本读取 |
| 532–537 | `/dev/root:254:0:254:0`、`ext4:rw` | `/` 与 vda 主次设备号一致，且可写挂载 |
| 554 | `rootfs-write-sync-readback` | guest 写入、`sync` 和回读闭环 |
| 565、576、596–597 | IRQ 基线、direct read、`537->672` | direct I/O 后 virtio IRQ 计数增长 |
| 613–615 | `printk: debug...`、`dmesg-no-critical` FAIL、strict `rc=1` | 唯一 live strict 缺口及其现场证据 |
| 859–862 | `Power down`、syscon、`GOOD TRAP`、system-reset code 0 | guest systemd 发起的有序关机事务传到仿真终端并干净退出 |
| 863–867 | host time、commits、cycles、CPI | 仿真成本与执行规模 |

终点统计为：

```text
cycles  = 5,071,521,696
commits = 1,223,536,213
CPI     = 4.145
speed   = 18,072 inst/s
```

## 4. 17 项 strict gate 与唯一假阳性

结构化解析文件：

`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/systemd-transaction-evidence.json`

解析器记录：

- preflight：6/6，`PASS`；
- autocheck：6/6，`PASS`；
- strict：16/17，`FAIL`；
- strict 唯一缺失项：`dmesg-no-critical`；
- strict 唯一 FAIL marker：`__NPC_CHECK_FAIL__:dmesg-no-critical`；
- historical strict done：`rc=1`。

旧 rootfs 中冻结的检查器使用：

```sh
kernel panic|oops|BUG:|bad trap|illegal instruction|segfault|I/O error|Buffer I/O error|EXT4-fs error
```

同时使用 `grep -i`。大小写不敏感且没有 token 边界时，`debug:` 的末尾
`bug:` 会命中 `BUG:`。修正后的 production regex 为：

```sh
kernel panic|oops|(^|[^[:alnum:]_])BUG:|bad trap|illegal instruction|segfault|I/O error|Buffer I/O error|EXT4-fs error
```

边界 `(^|[^[:alnum:]_])` 要求 `BUG:` 位于行首或前接非字母、数字、下划线字符：
`debug:` 不再命中，而真实 `BUG: unable to handle page fault` 仍会被拒绝。

定向单测：

`Linux/scripts/tests/test_npc_systemd_strict_check.py`

保存结果：

`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/test-strict-checker-current.log`

结果为 `Ran 3 tests ... OK`，其中包含：

1. `printk: debug:` 和标识符内的 `BUG` 不得误报；
2. kernel panic、Oops、独立 `BUG:`、bad trap、illegal instruction、
   I/O error 和 EXT4 error 必须继续命中；
3. 去掉 token 边界的 mutation 必须复现 A3 假红。

冻结 A3 console 上的 `legacy_matches=2` 来自两条内容完全相同的
`printk: debug: ignoring loglevel setting.`，不是两个独立内核故障；strict
历史中唯一缺失的 label 仍是 `dmesg-no-critical`。

## 5. 冻结 oracle 重放

重放 run：

`.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/`

DB-first 回查：

```bash
python3 scripts/github_index_db.py evidence \
  --run-id 2026-07-28-rv64-v10f-a3-checker-replay-v2 \
  --json
```

关键结果：

```text
legacy_matches=2
current_matches=0
printk_debug=ACCEPT
real_bug=REJECT
terminal=6/6
cycles=5071521696
commits=1223536213
PASS
APPROVED_NOT_PROMOTION_ELIGIBLE
source_status=FAIL_PRESERVED
a4=INTERRUPTED_NOT_PASS
architecture=GAP
ppa=UNQUALIFIED
```

“冻结 oracle 重放”是对同一 SHA-bound 原始 console 重新运行旧、新判定规则。
它隔离的是 oracle 变化，不重新执行 RTL，因而可以回答“旧规则是否误判”，不能回答
“修正规则后的一次新 live run 是否已得到 17/17”。原始 A3 status 保持：

```text
FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0
```

A4 status 为：

```text
FAIL rc=143 stage=systemd-strict-guest evidence_complete=0
cleanup_rc=143 signal=TERM
```

## 6. 身份与环境约束

A3 并非只保存 UART 文本。`binding.txt`、`post-binding.txt` 和
`rootfs-binding.txt` 还证明：

- design-id 前后均为 `c1b531...bb594`；
- simulator 前后 SHA 均为 `dc8a175a...91f218`；
- Linux Image、OpenSBI、DTB、NPC config、Makefile 和 Verilator manifest
  前后哈希一致；
- `OOO_CSR_QUEUE_HEAD=1`、`OOO_ASSERT=1`、
  `OOO_TERMINAL_HOLDER_ASSERT=1`；
- `uart_rx_bytes=0`，没有通过 host UART 注入命令伪造交互结果；
- rootfs template 和 run image 的 pre-run SHA 相同；
- template 的 pre/post SHA 相同，guest 写入发生在隔离工作副本；
- RTL assertion failure 文件为空。

这些约束把“启动了 Ubuntu”拆成了可追踪的数据流、设计身份、guest oracle、
终端事务和发布状态。里程碑的工程价值不仅在于 Linux 输出更深，还在于一个十九小时
结果没有因为最后的检查器缺陷而被粗暴压缩成“全成”或“全败”。

## 7. 可发表边界

可以写：

- A3 在指定 design-id 和配置下，从 OpenSBI 运行到 Ubuntu 22.04 systemd、
  rootfs/virtio 严格检查和 systemd 发起并完成的有序关机；
- raw guest 行为完成 16/17 strict labels，并闭合 6/6 terminal events；
- 冻结 oracle 重放证明唯一缺口是旧 `BUG:` regex 对 `debug:` 的假阳性；
- 原始 FAIL 被保留，重放结论不具备 promotion 资格。

不能写：

- A3 是 raw 17/17 live system recertification PASS；
- A4 是完成证据；
- 该 run 证明当前更新后的全部 RTL 仍有同一系统结果；
- 该 run 关闭了 `SERIALIZE-G1`、完成 architecture freeze 或 PPA/STA signoff；
- Ubuntu 在 guest 中连续运行了十九小时。
