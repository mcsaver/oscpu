# HIST-SER-QH-YOUNGER-STORE-CYCLE evidence identity v2 终审

## 标准化裁决

`APPROVED_FOR_BOUNDED_VD3`

RV64 RTL 对象为
`OooIntBackend.mem_idle_o/mem_retire_quiet_o`
→ `OooRob.head0_csr_mem_hold_w` 及 historical-reconstruction evidence；
周期/配置为
`current_owner_guard / historical_fixed / historical_cycle`
× assertion on/off 的根窗口→C0→C1→C2。Icarus 观测为 6/6
elaboration 成功、4/4 正向 PASS、2/2 专用根窗口拒绝，产品 3 commit
+ 2 kill 均 `lane1_fire=0`。

范围只批准 `HIST-SER-QH-YOUNGER-STORE-CYCLE` 限域 VD3。

## 根因与六组原始观测

- 当前 RTL 为 `.mem_quiet_i(mem_idle_o)`；`git show 7f66f9...`
  确认历史修复正是删除 `&& mem_retire_quiet_o`。
- 负向重建恢复该 AND 后，CSR 等待包含 `sq_empty` 的退休侧静默；
  younger STORE 又等待 CSR retirement/flush，形成闭环。
- current guard on/off：
  `mem_idle=0, C0=0, owner_live=1, physical_write=0`，2/2 PASS。
- historical fixed on/off：
  `root_window=1, C0=1, C1=1, C2_quiet=1, physical_write=0`，
  2/2 PASS。
- historical cycle on/off：
  `root_window=4, C0=0, mem_idle=1, mem_retire_quiet=0, hold=1,
  SQ=1, owner_live=1`，2/2 `EXPECTED_REJECTION`。
- `driver_rc=2` 来自预期仿真失败包装；六个 VVP image 均存在且非空，
  无 `SETUP-FAIL`、`CHECK-FAIL` 或 `FATAL`。

## Evidence identity v2

- 六个 `compile-image-receipt.json` 均保留最终 replay 的
  `size_bytes`、`raw_sha256` 与 `normalized_sha256`。
- normalizer 只机械替换匹配
  `(?<=[A-Za-z_])0x[0-9a-fA-F]+` 的 pointer-like token。
- 定向测试
  `test_vvp_pointer_ids_do_not_change_normalized_identity` 与
  `test_vvp_semantic_content_changes_normalized_identity` 2/2 OK；
  `C4<1010>→C4<1011>` 仍改变 SHA。
- 两次完整 replay 的 summary SHA 均为
  `a7c15649be90432aa6961671b10e1be06ade4ddef18e8e06846fb6f3cd7b9fa0`
  且 byte-equal；normalized identity 与 log identity 均 6/6 稳定，
  raw image 6/6 因 allocator 地址变化而不同。
- RTL SHA、日志 SHA、oracle result 和原始 marker 仍独立保留；
  normalized SHA 没有替代这些身份。

## 产品边界与设计身份

- `tb_ooo_core_top_glue_v9o_csr_qh.log` 的 ecall、older-store、
  CSR/JALR 三条 commit 路及两条 wrong-path kill 路均为
  `birth=1, lane1_fire=0`，最终 `[RESULT] PASS`。
- backend CSR+younger STORE 是历史根锥输入，不代表当前 frontend
  可自然形成该 pair。
- production `OooIntBackend.v` replay 前后均为
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`；
  scoped `git diff` 中 `OooIntBackend.v/OooRob.v` 无漂移。
- `current-design-id.txt`、ledger 与 round-state 均为 146-file
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。

## Ledger 与保留边界

- ledger `valid=true, errors=[]`；
  `VD0=0, VD1=1, VD3=2, VD4=2`。
- 唯一 blocker 为 `HIST-SER-QH-STOP-HOLD-DROP`；定向 ledger 单测
  4/4 OK。
- normalizer 两项测试是代表性敏感性证明，不是对未来所有 VVP 语法的
  形式化完备证明。
- 第一次 replay 的 raw digest 未单独持久化；稳定性 receipt 只保留
  “与第二次不同”的结果及第二次逐 case raw receipt。source/log/oracle
  与最终 raw receipt 未被 normalized SHA 取代，因此不阻塞当前限域 VD3。
- 历史变体只是 root-cone-equivalent reconstruction；backend C1 为
  TB 外部注入，产品 typed C1 另由 glue scoreboard 覆盖。
- 四拍拒绝不是无限期形式化活性证明。
- 不外推 architecture freeze、PPA qualification 或 A3 新系统运行。
- `scope_extension_request=none`。

## 审查节点状态

- contract：
  `subagent-contracts/hist-qh-younger-store-final-evidence-review-v4.json`
- contract SHA-256：
  `b10cb173f390f7ae84f5dc6d4801aa7d2ddf2cad6a100f32c0a946654ffd5435`
- 置信度：高，仅限上述 VD3 边界。
- 审查节点只读、无文件写入或遗留工程进程，已归还 WSL shell
  ownership。
