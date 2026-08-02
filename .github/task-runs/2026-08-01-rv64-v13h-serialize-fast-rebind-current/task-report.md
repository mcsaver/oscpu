# V13H SERIALIZE-G1 当前设计快速重绑定报告

本轮在不修改 production RTL 的前提下，把 `SERIALIZE-G1` 的定向事务和完整功能证据
重绑定到当前设计
`sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44`。

## 已闭合范围

- queue-head CSR：2/2 正向 profile、2/2 production RTL 负向版本和 1/1
  verification-only `CsrFile` TB-wiring 负向版本，6 次提交事务、4 次 selective kill，
  PASS；24 个运行时对象已清理，保留 0 个临时对象。
- pending-SYSTEM：3/3 baseline、15/15 可编译 RTL 负向版本且 15/15 动态拒绝，PASS；
  88 个运行时对象已清理，保留 0 个临时对象。
- 完整功能队列：113/113 module、177/177 official、61/61 AM、DiffTest mismatch=0、
  11/11 证据变体；CoreMark 10 次 CRC=`0xfcaf`，Dhrystone 10000 次，均各出现一次
  GOOD TRAP。
- 功能执行输入 pre/post 完全一致；冻结 simulator/reference/configuration 与聚合结果均由
  `run-result.json` 哈希绑定；未保留 `.vvp` 或 `.o`，也没有写全局 current 指针。
- 146 个 production RTL 文件的 pre/post manifest 逐字节相同。

## 判定器修复

原 checker 只接受 V11Y 的历史 checker-replay schema，无法消费本轮直接 PASS 的新鲜功能
证据。V13H 将其扩展为同时接受旧 replay 与直接执行格式；直接格式额外核验输入前后绑定、
聚合结果、CoreMark/Dhrystone 终端语义、DiffTest、冻结对象和零编译中间物。14 项正负向
单测全部通过，旧 replay 格式继续兼容；checker 还会拒绝把 verification-only TB-wiring
负向版本误分类为 production RTL mutation。

## 不得越级的边界

`currentness-decision.json` 的 PASS 仅表示当前设计快速门与完整功能门有效。唯一完整
Linux/systemd 事务仍是旧设计 `c1b531...` 上的 A3；其原始 FAIL 和修正后的 checker-replay
均原样保留。当前设计没有完整系统事务，因此：

- `SERIALIZE-G1=STALE_EVIDENCE`；
- `serialize_g1_current_design_bound=false`；
- architecture freeze=`GAP`；
- PPA=`UNPROMOTED`；
- promotion eligible=`false`；
- 完整系统重认证处于 `PENDING_USER_AUTHORIZATION`，本轮未启动长时仿真。

本轮没有增加终端事件去重，也没有削弱 RTL 断言。三个证据生成命令曾因
PowerShell→Bash 变量引用发生无害重试；工程仿真、编译与 checker 命令均无失败，重试没有
改变 RTL 或验证语义。

`OooRob.v` 接口附近仍有一段历史注释把 `mem_quiet_i` 描述为包含 SQ empty；当前实际接线与
同文件断言注释均明确它只接 `mem_idle`。本轮不改该 production RTL 注释，因为当前 design-id
按原始 RTL 文件字节计算，注释改动也会使刚完成的定向与完整功能证据全部失配。该注释债务保留到
下一次 production RTL 身份自然变化时一并修正并重跑门禁，不影响本轮组合/时序语义。

本轮最初按 `verification` 启动轻量 agent-flow；发现 direct-evidence checker 缺口并修改脚本后，
该分类按设计拒绝 source modification。原始 BLOCKED 分类记录保留，随后用实际的 `development`
分类重放相同路径、PASS/GAP 证据和 reviewer 反例，收尾 PASS。该过程没有运行额外 guard，门禁
开销观测为 0%，也没有把分类提示传播为长期目标阻塞。
