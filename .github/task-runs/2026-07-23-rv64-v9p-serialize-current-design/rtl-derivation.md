# V9P RTL derivation

## 阶段 0：接口契约冻结（初稿）

| 契约 | 当前待复核内容 |
| --- | --- |
| 握手 | 合法 head0 CSR 只在 lane0 单发 dispatch fire；`head0_csr_inflight_q` 从该沿保持到精确 commit/full flush，或在更老 branch/JALR selective recovery 杀死该 CSR 后释放 |
| 反压 | CSR inflight 保持 `stop_pending`；ROB head 在 `mem_idle_i=0` 时不得产生 commit0 fire |
| flush/redirect | C0 阻止新 dispatch/issue/completion/memory owner；C1 `CSR_COMMIT` apply 清年轻状态并从 commit next-PC 重取 |
| 异常序 | 非法 CSR 留在 precise trap 路；合法 CSR 只在 ROB head commit；FP CSR 保留 pending-system owner |
| 访存序 | older memory owner 先完成；younger store/load 不得成为 CSR commit 的必要等待，C0/C1 后取消或重取 |
| 单一真源 | ROB full pregrant 是 CSR C0 request；apply sequencer 是 C0→C1 owner；`CsrFile` 只消费精确 commit pulse |

## 阶段 1：需求

- 选择并默认启用已实现的 head0 非 FP CSR queue-head 路径；
- 不改变尚未队头化 system/FP CSR 的产品语义；
- 默认值改变后重新建立 current-design 全功能与恢复证据。

## 阶段 2a：协议规则

- `dispatch0_valid && dispatch0_ready && dispatch0_csr` 是 CSR inflight birth；
- inflight 期间不得接受会覆写单 pending-system owner 的年轻 system 事务；
- `commit0_fire && head0_is_csr && mem_idle_i` 形成 CSR C0；
- C1 apply 才驱动 backend/front-end full-event 状态更新；
- CSR architectural write 与 head0 commit 同拍可见，不能由年轻 flush 撤销。

## 阶段 2b：状态机

当前不新增独立 FSM；复用三段状态：

1. frontend `head0_csr_inflight_q`；
2. ROB edge-old CSR head；
3. `OooControlEventApplySequencer` C0 capture / C1 apply。

## 阶段 2c：不变量

- CSR inflight 有且仅有一个合法 head0 CSR owner；
- queue-head CSR dispatch 后年轻指令停止进入；因此 inflight 期间发生的 branch/JALR
  redirect/misaligned resolve 必属更老控制流，并必须同步释放已被 ROB walk 杀死的 CSR owner；
- `head0_csr_commit_w` 与 CSR typed C0 pregrant 双向一致；
- `mem_idle_i=0` 时 CSR 不退休；
- CSR C0 周期不建立新年轻 owner，已寄存 older owner只允许完成；
- FP CSR/pending-system owner 不能被 head0 CSR 的类型或 ProducerId 覆写。

## 阶段 2d：数据通路

`FetchHeadPairGate/FrontendDispatchGate`
→ `OooRob.inst_q/rd/CSR metadata`
→ `head0 CSR pregrant`
→ `OooControlEventApplySequencer`
→ `OooCoreTopGlue` typed C1
→ `NpcCoreTop.CsrFile`
→ frontend next-PC refetch。

## 阶段 2e：RTL 拓扑自审状态

独立只读 reviewer 已完成，结论为 `GAP`：更老长延迟 branch/JALR 可在年轻 queue-head
CSR dispatch 后才 resolve，ROB selective walk 会杀死 CSR，但旧
`head0_csr_inflight_q` 没有对应 clear，形成永久 stop owner。

修复后拓扑：

`core_branch_resolve_valid_w && (mispredict || misaligned)`
→ `head0_csr_older_control_kill_w`
→ `head0_csr_inflight_q` clear。

定向 branch 与 JALR 两条序列均观测到 CSR dispatch、selective recovery、下一拍 owner
clear、错误路径 CSR 不提交、目标路径退休；RED 版本四项失败，GREEN 版本全部通过。

## 阶段 2f：全状态验证追加闭环

1. virtual-memory 测试环境会在 `misa.V=0` 时保存/恢复 `mstatus.VS`；特权架构允许该
   状态字段存在。`CsrFile` 现经 mstatus/sstatus 保存 VS，SD 汇总 FS/VS Dirty，VS
   仍在 DiffTest 中精确比较。
2. IFU 完成 PTE.A 写回后，两个 D-cache 可能保留旧页表行。IFU 在 A-update B terminal
   发出维护脉冲，双访存桥在同拍屏蔽并清除两份 D-cache valid 状态。
3. 修复后的 full-state riscv-tests：177 个 p 环境 + 153 个 v 环境，共 330/330 PASS。
