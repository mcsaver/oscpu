# V11S dispatch log

## 主任务

- RTL 对象：
  `OooMulDivUnit.producer_id_q` 与
  `OooIntBackend.u_muldiv_unit` request/response transaction。
- 主分类：`verification`。
- 辅助分类：`tooling/workflow`、`documentation/metadata`。
- single-flight lane：
  Windows → WSL 工程命令始终由主 agent 串行持有；未启动 A4 或第二个
  WSL 工程进程。
- production RTL：
  `OooIntBackend.v`、`OooMulDivUnit.v`、`define.v` 均未修改。

## 独立 reviewer

- reviewer task：`v11s_muldiv_final_review`。
- 上下文模式：`fork_turns="none"`。
- 输入合同：
  `subagent-contracts/v11s-muldiv-producer-final-review.json`。
- 合同 SHA-256：
  `11c12f24688d9570081c3940ac04e9dbde7d21cb7860aa900986219816eba378`。
- review 对象：
  product instance dataflow、generation/index identity、exact-open
  completion、holder release、flush death、mutation stage binding 与
  ledger 单元边界。
- 输出：
  `final-review-result.md`。
- 结论：
  bounded PASS，blocker=0；未把当前局部结论外推到全核 architecture 或
  PPA。
- lane 归还：
  reviewer 完成后主 agent 继续持有唯一 WSL 工程命令 lane。

## 协调约束

- 技术正文使用 RV64 module/signal/transaction、cycle、TB/EDA marker 与
  SHA 描述；调度状态只记录在本文件与 JSON。
- 负向 RTL 版本必须 compile-success，且由目标 stage oracle 拒绝。
- 不用去重、skip、waiver 或 assertion 削弱制造 PASS。
- A3 原始 FAIL 只读保留；checker replay 是独立 evidence revision。

