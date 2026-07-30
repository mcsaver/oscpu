# V11B 协作与执行记录

## 本地 RV64 review 节点

预审节点只读取合同列出的本地 RTL、census、instance graph 和 evidence 文件，
未继承父任务完整对话。其初始结论是 44 个单元均缺少足够的逐实例语义闭环；
该反例驱动本轮建立显式 coverage ledger，而不是把已有 candidate evidence
批量追认为 PASS。

## 主节点闭环

1. 建立 44 单元 × 17 instance 的 coverage ledger。
2. 区分 current、historical、RTL stale、TB drift 与 no-candidate 状态。
3. 对 terminal collector 增加 assertion-only identity-known 检查。
4. 增加双 lane 非对称 turnover/hold TB 轨迹和 raw-fire oracle。
5. 建立静态 12+2 lane checker 与 6 个正/负向单测。
6. attempt-1 因 mutator anchor 不成立而保留失败。
7. attempt-2 暴露 same-edge 变异未同时切断 pending guard，保留失败。
8. attempt-3 修正反例后，2/2 profile、unknown negative、3/3 mutation
   rejection 和 lane contract 全部 PASS。
9. currentness rebind attempt-21 保留原始 FAIL：10 个 canonical closed debt
   仍报告 `semantic_evidence:GAP`，未用 ledger 或文档覆盖该结果。

## 协调边界

所有 Windows→WSL 工程命令保持 single-flight。未启动并行的第二个 WSL
仿真、elaboration 或证据工程进程。

## 独立终审

final reviewer 使用合同
`subagent-contracts/v11b-holder-semantic-coverage-final-review.json`
只读复核后批准 collector 3-unit bounded PASS，并归还 shell ownership。
其发现的 policy unit rebind 反例已转成 exact collector unit-set 负向单测；
修订后 16/16 semantic/lane tests PASS，41/44 GAP 不变。
