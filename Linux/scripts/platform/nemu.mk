# NEMU RV64 Linux 参考平台的默认构建命名空间。
# 源码和下载缓存仍共享 Linux/env/src 与 Linux/env/downloads；
# 所有可写构建、镜像、日志产物默认落到 env/platforms/nemu。

LINUX_PLATFORM_DESC := NEMU RV64 Linux reference platform
PLATFORM_DEFAULT_MAX_CYCLES := 0
PLATFORM_OPENSBI_PROFILE := nemu
PLATFORM_OPENSBI_DISABLE_PMU := 1
