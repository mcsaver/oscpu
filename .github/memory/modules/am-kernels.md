# AM-Kernels 模块笔记

## 测试通过情况
<!-- 各测试集的通过状态 -->

## 基准测试结果
<!-- CoreMark/Dhrystone/MicroBench 性能数据 -->

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- hello/mainargs 调试时要区分平台：native 依赖宿主环境变量 mainargs；riscv32-nemu 与 npc 依赖镜像里的静态 mainargs 区域，改的是生成后的 bin，不是运行时环境。
