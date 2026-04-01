# Abstract Machine 模块笔记

## 当前状态
<!-- 已实现的 API (TRM/IOE/CTE/VME/MPE) -->
- klib-macros.h 提供地址对齐、数组长度、区间构造、字符串化、拼接、IO 设备读写、静态断言与 panic 封装，广泛依赖 GNU statement expression 扩展。
- io_read/io_write 通过 am/include/amdev.h 中 AM_DEVREG 生成的 `AM_xxx_T` 类型包装 `ioe_read/ioe_write`。
- panic_on 最终走 putstr/putch 输出错误，再调用 halt(1) 终止；不同平台的 putch/halt 在各自 trm.c 中实现。
- hello 等 AM 程序的 mainargs 在不同平台采用不同传递方式：nemu/npc 在 trm.c 中放置 MAINARGS_PLACEHOLDER 静态字符串，链接后由 tools/insert-arg.py 直接回写到镜像；native 则在 constructor 中通过 getenv("mainargs") 读取宿主环境变量，再手动调用用户 main。

## klib 实现进度
<!-- 已实现的标准库函数 -->

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- klib/src/stdio.c 当前的 kvsnprintf 只实现了 `%d`、`%s`、`%c`、`%%` 四类格式；遇到 `%02d` 这类带宽度/补零标志的格式会走未知格式分支，导致格式串被近似原样输出。
