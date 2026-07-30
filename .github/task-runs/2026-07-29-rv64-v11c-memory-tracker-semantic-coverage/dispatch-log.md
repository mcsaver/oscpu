# V11C 协作与执行记录

## 预审节点

- 合同：
  `subagent-contracts/v11c-memory-tracker-semantic-pre-review.json`
- 合同 SHA-256：
  `388882c1daf6b3ade38b1762f9c874be8b212f321c404ef36406a0d1891c5637`
- 只读结论：合法二态 RTL 未见功能反例；旧 TB 对 live set、map hold、
  distinct-PID same-edge token reuse 与 X-known 保持 GAP。

## 主节点

1. 保持 `OooMemOwnerTracker.v` 不变。
2. 新增 verification-only semantic checker。
3. 给既有 TB 加入独立 exact state model 与 exact/bulk edge-old 轨迹。
4. attempt-1 首次 2/2 + 4/4 + 9/9 PASS，但因不必要的 Makefile
   source coupling 会破坏 V9R current binding，保留原始产物、不晋级。
5. 撤销仅该 Makefile 行，runner 改为命令行注入 checker source。
6. attempt-2 重新绑定并成为 canonical evidence。
7. ledger 更新为 5 PASS / 39 GAP，cursor 与整体保持 GAP。

## 终审节点

- 合同：
  `subagent-contracts/v11c-memory-tracker-semantic-final-review.json`
- 合同 SHA-256：
  `8ed5f78978c53d2c39cbcbb778c56b3319ac0f26795bce7dfcaf23e479ed2729`
- 结论：bounded APPROVE，blocker=0；不覆盖 cursor、生产尺寸扫描/
  公平性、whole architecture 或 PPA。

所有 Windows→WSL 工程命令均 single-flight；两个只读节点结束时均明确
归还执行权，无遗留工程进程。
