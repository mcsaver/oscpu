# RV64 FP divider shift-register cleanup dispatch log

- 需求：在 `OooFpDivIter` 已串行化 FDIV 的基础上，继续去掉运行态 `divisor << bit_idx_q` 与 quotient bit 动态移位，避免综合成每拍宽桶形移位器；同时补齐 div/sqrt 迭代单元模块级 testbench。
- 协议：`start_i && !busy_q` 才捕获新请求；busy 期间新 start 被忽略；`done_o` 单拍有效；`rst`/`flush_i` 清空 busy、done、partial remainder/quotient/result。
- 状态机：维持 idle/busy/done-pulse 三态语义，`bit_idx_q` 仍从最高 quotient bit 递减到 0。
- 不变量：
  - 每拍只提交一个 quotient bit。
  - 当前 compare/subtract 使用的 shifted divisor 与本拍移入的 quotient bit 对齐。
  - flush 后不能残留 partial shifted divisor、quotient 或 remainder。
  - 对 `OooAluFetchCore` 的外部接口时序不变，FDIV/FSQRT architectural latency 不变。
- 数据通路约束：
  - start 时常量定位 `shifted_divisor_q = divisor_ext << LAST_QUOTIENT_BIT`。
  - busy 期间只做 `shifted_divisor_q >> 1`、一次 compare/subtract、quotient 左移移入 `subtract_step_w`。
  - 不再保留运行态 `<< bit_idx_q`、`quotient_bit_w` 或未使用的 `divisor_q`。
- 验证证据：见 `task-report.md`。
