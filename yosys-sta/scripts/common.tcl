set PROJ_HOME "[file dirname [info script]]/.."
source $PROJ_HOME/scripts/pdk/$PDK.tcl

# EXTRA_LIB_FILES:在 PDK 标准单元库之外额外加载的 liberty 文件列表(空格分隔,
# 环境变量传入,默认空——与 KEEP_HIERARCHY_MODULES 同哲学)。典型用途:黑盒宏
# (SRAM/OOC 冻结宏)的 non-signoff 占位 .lib,让 STA 时序图闭合;占位数字不做签核。
set EXTRA_LIB_FILES [list]
if {[info exists env(EXTRA_LIB_FILES)]} {
  set EXTRA_LIB_FILES $::env(EXTRA_LIB_FILES)
}
