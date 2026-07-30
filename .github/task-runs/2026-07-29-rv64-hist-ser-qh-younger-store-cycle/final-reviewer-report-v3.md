# HIST-SER-QH-YOUNGER-STORE-CYCLE 独立终审

## 标准化裁决

`APPROVED_FOR_BOUNDED_VD3`

RV64 RTL 对象为
`OooIntBackend.mem_idle_o/mem_retire_quiet_o`
→ `OooRob.head0_csr_mem_hold_w`；周期/配置为
`current_owner_guard / historical_fixed / historical_cycle`
× assertion on/off 的 C0/C1/C2。Icarus 证据为 6/6 编译成功、
4/4 正向 PASS、2/2 专用根窗口动态拒绝。

该裁决只把 `HIST-SER-QH-YOUNGER-STORE-CYCLE` 提升为限域 VD3；
整体 ledger 仍为 GAP。

## 产品路径与 backend 判别边界

- 产品 glue TB 的三条 commit 路径与两条 selective-kill 路径均观察到
  `birth=1, lane1_fire=0`。
- backend 双派发 CSR+younger STORE 是 root-cone 判别输入，不代表当前
  frontend 能自然形成该 pair。
- backend 原始计数直接取 acceptance edge，无 sticky/去重：
  CSR/STORE dispatch 各 1、SQ allocation 1、probe request/response
  各 1、精确 STORE token/ProducerId owner 1、physical write 0。

## 三种语义的逐拍结果

- `historical_fixed`：
  `root_window=1`，C0 commit/barrier 各 1；TB 注入的 C1 flush 为 1，
  并清 SQ/ROB/owner；C2 无重复 C0，physical write 仍为 0。
- `historical_cycle`：
  连续 4 拍保持
  `C0=0, mem_idle=1, mem_retire_quiet=0, hold=1, sq_count=1,
  owner_live=1, physical_write=0`，只在专用 `[EXPECTED-FAIL]`
  marker 终止。
- `current_owner_guard`：
  当前 owner-lifetime 语义令 `mem_idle=0`、C0=0；它只作为当前
  backend-only 注入状态的 guard，不能替代历史 fixed progress。

## 历史版本与身份绑定

- production `OooIntBackend.v`：
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`。
- `historical_fixed`：
  `9e14f616cb0911a091caccff12a9065e3680cb45ccdba452cb365f56f2ad86e3`；
  diff
  `ff961348602e3a5c31a1b04990c6cbcc8a8c7b3c2821e1d727dc9411bc6d59df`。
  唯一 anchor 删除当前 `mem_idle_o` 的 owner-live/terminal-pending
  附加约束，保留 transient transport holder。
- `historical_cycle`：
  `6e8e597e2000bdecfef4a538e95bff15b3b7887dec8ac7615d8cf5be31da87bc`；
  diff
  `a1a1877be9ecd21d767bd6bc26f5f67d019fdbe31a851602206d1ad18a4c2f3b`。
  它只在 fixed 上恢复历史
  `.mem_quiet_i(mem_idle_o && mem_retire_quiet_o)`。
- `git show 7f66f9d9d4badc08e0c51dc65c4db2b99683de46` 独立确认原修复
  正是把历史 AND 门改为单独 `mem_idle_o`。两个变体是
  root-cone-equivalent reconstruction，不是完整历史快照。
- assertion-on/off 分别编译并生成独立日志；cycle case 的
  `driver_rc=2` 是 make 包装预期仿真非零退出，编译 image 存在且无
  `SETUP-FAIL`、`CHECK-FAIL` 或 `FATAL`。
- 146-file design-id 保持
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。

## 保留边界

- backend reconstruction 的 C1 是 TB 外部注入；真实 typed C1 由产品
  glue scoreboard 独立覆盖，不能合并描述为一条完整历史端到端波形。
- `diagnostic-t3u` 的三个旧 admission 预期失败，说明 IntBackend 本身不保证
  “非队头 younger memory 不准入”；当前产品不可达性归于 frontend
  `head0_csr_inflight/stop_pending` 边界。
- 负向观测是 4 拍有界重建，不是形式化无限期 liveness 证明。
- `OooRob.v` 端口附近仍有一处旧注释把
  `mem_quiet` 写成 `mem_idle && mem_retire_quiet`，与当前连线和后部
  INV-4 注释不一致；这是非阻塞文档债务，本轮不改 production RTL。
- `HIST-SER-QH-STOP-HOLD-DROP` 仍为 VD1，缺少删除
  `head0_csr_inflight` hold 的可编译负向 RTL、真实 younger lane1 CSR
  overlap，以及 assertion on/off 原始计数。

## 审查节点状态

- reviewer contract：
  `.github/task-runs/2026-07-29-rv64-hist-ser-qh-younger-store-cycle/subagent-contracts/hist-qh-younger-store-final-evidence-review-v3.json`
- contract SHA-256：
  `4d20cf8e613066b2907e26ac8e855f951122de6d11b2fa9517342d9c3e025729`
- 审查节点只读，未修改文件，已归还唯一 WSL 工程命令执行权。
- 不授予 architecture freeze、PPA qualification 或 A3 新系统运行结论。
