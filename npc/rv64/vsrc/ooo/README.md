# RV64 OoO RTL 目录

`ooo/` 按乱序超标量内部职责分层：

- `frontend/`：取指包消费、压缩指令解压、控制流预测/恢复、精确停顿边界。
- `backend/`：译码到后端、dispatch、整数执行、LSU 请求与写回仲裁。
- `rename/`：rename map、free list、busy table 等寄存器重命名状态。
- `issue/`：整数 issue queue。
- `commit/`：ROB 与按序退休状态。
- `regfile/`：物理寄存器堆与架构寄存器观测镜像。

新增 OoO helper module 时优先放入对应子目录，并在 `vsrc/filelist.mk` 中以
同名 `RTL_OOO_*` 变量显式登记，避免继续把可独立分析的逻辑塞回大顶层。
