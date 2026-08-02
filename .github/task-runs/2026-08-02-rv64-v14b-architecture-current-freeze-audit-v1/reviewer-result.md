# V14B independent RV64 RTL review

RV64 RTL 结论｜对象=OooIntBackend/OooMemInflightQueue memory terminal lifecycle、
OooMemAxiBridge PTW PTE WRITE PMP 与 task-local evidence｜周期/配置=current production
design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`、
完整 source-set=146、pre/post source map 相同｜TB/EDA 观测=正向 TB 4/4、共享回归
113/113、compile-success mutation 39/39 rejected、独立 checker replay PASS、九项 directed
checker GREEN｜范围=PASS（`APPROVED_CURRENT_SCOPE`；仅 MEM-ISSUE-G1 与 PTW-PMP-G1
current dynamic scope）

- 原始 `p0-direct-rebind-1.status` 的 FAIL 可归类为 legacy canonical unit-test scope mismatch；
  必须原样保留，不得把 checker replay 冒充原 runner PASS。
- 当前 task-local `lsu_disable_write_request` 反例属于 28/28 compile-success/dynamic-rejected
  closure；旧单测报告来自旧 canonical summary。
- current source-set、正向语义观测、39 个动态反例与独立 checker replay 共同支持两个 P0
  的限定结论；不支持完整架构或 PPA 晋级。
- unknowns：mutation 唯一 ID/内容哈希/target-to-observation 未逐项内联；未证明形式覆盖率、
  token/epoch 回绕、reset、分裂 AW/W 并发、同周期 flush/request-fire/B-terminal 与任意多 owner
  时序；审查节点按合同未读取工作区文件。
- `scope_extension_request: none`，前提是结论严格保持上述限定范围。
