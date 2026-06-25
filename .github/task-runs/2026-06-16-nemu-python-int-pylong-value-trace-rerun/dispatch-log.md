# Dispatch Log: NEMU PyLong paddr snapshot/value trace

- 读取 `.github/AGENTS.md`、Copilot 规则、project status、known issues、NEMU/agent-system memory、agent e2e workflow 与 e2e README。
- 运行 no-prewarm full-lite wide-ifetch-off heavy：复现 `runtime-after-identity` PyLong `ob_size` 坏值。
- 增加 paddr arm/disarm snapshot，构建 NEMU，运行 `nemu-dev` 合同。
- 运行 snapshot heavy：证明失败对象 paddr arm 时 PMEM bytes 已为 `0100000000000080`。
- 增加 preparse 小整数 marker 与 stdout write-through，运行合同和 heavy；flush 后失败样本证明 `ARGS_LOOPS_PREPARSE_ID_MATCH=0` 且 argparse 返回坏对象。
- 增加 paddr value trace API 与 serial preparse arm，运行合同和 full-word/byte value trace heavy。
- 登记关键 evidence index，并补写本 report。
