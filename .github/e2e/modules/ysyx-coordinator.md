# ysyx-coordinator E2E Contract

本 profile 只验证 coordinator 入口与显式 profile root 可用，不自动执行 discovery 或全 workspace 审计。
协调时以 primary objective、acceptance criteria、实际 worktree、hard constraints 和当前证据决定是否需要
跨模块委派；没有真实依赖或共享资源冲突时允许并行。

完成判定直接对应 acceptance criteria。选图说明、dispatch-log、manifest 与 task-run 都是复杂显式 E2E、
持久化长跑或发布场景的可选产物，不能反向成为普通 inspect/edit/build/test 的许可门。
