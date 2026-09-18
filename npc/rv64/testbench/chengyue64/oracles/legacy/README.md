# 测试专用的旧译码对照

这里保存当前测试实际使用的三个旧实现，源码从已封存的 rv64core 原样提取：

- `OooRvcDecompressor.v`：供 `tb_r64_rvc` 对照压缩指令展开结果。
- `DecodeUnit.v`、`OooFpDecode.v`：供 `tb_r64_decode` 对照整数与浮点译码。

这些文件只进入测试的 `TEST_ORACLES` 清单，使用当前共享 `vsrc/include/define.v` 定义。
生产仿真、模型和综合均使用 [主线源码清单](../../../../vsrc/filelist.mk)，不编译这些对照实现。
旧核完整 RTL 保存在 [封存包](../../../../../pack/rv64core-legacy-20260916/README.md)。
