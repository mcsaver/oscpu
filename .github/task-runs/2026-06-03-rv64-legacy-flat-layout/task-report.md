# RV64 Legacy Layout Flatten

## 背景

用户指出上一轮把未使用模块放入 `vsrc/legacy/cache/common/core/...` 这种镜像子目录后，反而和 `vsrc/cache/common/core/...` 活动目录重复，视觉和维护上更混乱。

## 调整

- 将 `npc/rv64/vsrc/legacy/{cache,common,core,execute,frontend,memory,pipeline}` 下的旧模块全部收敛到单层 `npc/rv64/vsrc/legacy/`。
- 删除空的 legacy 子目录。
- 更新 `npc/rv64/vsrc/filelist.mk`，所有 legacy 变量直接指向 `$(RTL_LEGACY_DIR)/<file>.v`。
- 更新 `npc/rv64/vsrc/legacy/README.md` 和 memory/task-run 文档，明确 legacy 不再镜像活动目录。

## 验证

- `rg "legacy/(cache|common|core|execute|frontend|memory|pipeline)" ...` 无残留路径。
- `git diff --check` PASS。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64/testbench run TESTS="tb_cache_control tb_memory_stage_control tb_pipeline_control"` PASS。
