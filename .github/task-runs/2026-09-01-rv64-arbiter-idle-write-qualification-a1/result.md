# RV64 dual-memory arbiter IDLE write admission：资格化结果

资格化通过，并授权下一项本地实验候选 `dual-mem-arbiter-idle-write-admission-v1`。fresh diagnostic
build 绑定 retained crossbar candidate 的 production identity；probe 对功能行为透明。

| workload | ROI cycles / retired | IDLE write events | source 11/10/01/00 | downstream READY 11/10/01/00 | strict |
|---|---:|---:|---:|---:|---:|
| CoreMark | 4,667,639 / 3,183,617 | 144,201 | 144,201 / 0 / 0 / 0 | 144,201 / 0 / 0 / 0 | 144,201 |
| Dhrystone | 7,891,545 / 4,250,000 | 600,000 | 600,000 / 0 / 0 / 0 | 600,000 / 0 / 0 / 0 | 600,000 |

两项均为 GOOD TRAP、DiffTest ON、code 0；ROI/full cycles、retired/commits、功能输出及 SQ receipt
与 retained predecessor完全一致。probe complete/available、overflow/invalid=0，source、READY与 lane
winner全部守恒；当前 workload 均只有 lane0 winner且无双 lane contention。

这些数据只证明在当前 production identity 上，registered IDLE write选择拍有 144,201/600,000 次
完整且 downstream可接受的结构机会。probe 的 `xbar_head*_wr_rsp` 位于更后的 xbar grant拍，不能被
改名成 arbiter capture head-critical事实。因此不预支一比一 CPI；功能候选必须以当前 ROI
4,667,639 / 7,891,545 为 exact predecessor做 A/B。

独立架构审查确认最窄 write-only admission 不建立 READY环：arbiter downstream READY来自 adapter
本地 holder/state，而不读取 target READY。风险在于正向 payload路径合并为
bridge Q → arbiter owner select → adapter align/shift → xbar input Q。故功能实现前后均固定
`PPA=UNQUALIFIED`；CPI通过后仍需 fresh mapped synthesis/STA 才能讨论频率、面积或功耗。

