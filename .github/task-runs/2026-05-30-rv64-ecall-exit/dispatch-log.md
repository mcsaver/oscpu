# Dispatch Log

1. 读取 `.github/AGENTS.md`、copilot instructions、project/memory 与 RTL 工作流，确认 RV64 已固定为 OoO/superscalar 路径。
2. 梳理 `DecodeUnit` 到 `OooAluFetchCore` 的 SYSTEM 指令流：`ECALL` 已被译码为合法 SYSTEM，但 OoO fetch core 只把 `EBREAK` 作为退出边界，`ECALL` 会落入 unsupported trap。
3. 采用前端精确边界方案，而不是把 SYSTEM uop 放入 OoO 后端：退出指令不写 ROB/PRF，只等待更老项 drain 后向仿真壳报告退出原因。
4. 修改 RTL 并加中文注释，新增 `ECALL/EBREAK` 统一 exit cause。
5. 更新 focused test 的 ECALL/MRET 覆盖，并通过对照实验确认 rv64 旧模块 testbench 的 JALR/访存失败是既有 RV64 不适配，不是本轮 ECALL 改动引入。
6. 完成验证：rv64 lint PASS、rv64 build PASS、最小 ECALL 镜像 `exit via ecall, code=0`、`riscv64-npc` cpu-tests 40/40 PASS。
