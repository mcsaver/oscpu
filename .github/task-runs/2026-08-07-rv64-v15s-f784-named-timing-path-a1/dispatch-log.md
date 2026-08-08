# V15S RTL review dispatch log

- `v15s-f784-owner-to-fetch-path-review-v1`：工作区只读审查节点被中止，未形成可用回执，不作为结论依据。
- `v15s-owner-any-live-material-review-v2`：合同 SHA-256 `1fd8032fc9a250e13e55b7b9f57d1a41846bdaf82143addfa974a020ce0cf207`；provenance 把 `OooMemOwnerTracker.v` 错列到 `vsrc/execute`，结果仅作 candidate-only 推理记录。
- `v15s-owner-any-live-material-review-v3`：合同 SHA-256 `386947f5e5c6d310098aa2dec9d835c7f6a48b7c43edc53758fd072e1bbaa754`；技术结论与后续 v4 一致，但派发文本与 canonical render 存在 Markdown 标识格式漂移，仅作 candidate-only 记录。
- `v15s-owner-any-live-material-review-v4`：合同路径 `.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/subagent-contracts/v15s-owner-any-live-material-review-v4.json`，SHA-256 `3cd430bf41d526c352fb3ffde58014681ccc40ea5b132b789163b72052a2c2a9`；使用 exact render 的 self-contained no-tools 限定材料复核，正式结论为 `RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE`，5ns hard gate 保持 GAP。

可操作反例登记：production 32-token 动态 full 边界、四态 X-clean 与全局 holder 完备性不阻塞 engineering-candidate 保留；若候选升级为 canonical/signoff，应转化为 production 参数 TB 或形式证明，不得用本轮局部等价结论代替。

候选后 current-design verify：直接 non-login WSL 环境首次 PASS；两次通过 `bash -lc` 写日志的运行因 PATH 多出 `/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-gcc` 而 FAIL，日志分别保留为 `post-candidate-current-verify.log` 与 `post-candidate-current-verify-replay-v1.log`。v2 runner 使用原执行同构的 non-login PATH，`post-candidate-current-verify-replay-v2.status=PASS`；该结果只说明 toolchain 输入集合与 e7da RTL 仍精确匹配，不把不同 login-shell 输入追认为 PASS。
