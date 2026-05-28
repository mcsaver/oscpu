# Source this file from your shell startup file or project bootstrap script.

export YSYX_HOME="$HOME/path/to/ysyx-workbench"
export NEMU_HOME="$YSYX_HOME/nemu"
export AM_HOME="$YSYX_HOME/abstract-machine"
export NPC_HOME="$YSYX_HOME/npc"
export LOCAL_BIN="$HOME/.local/bin"

# Optional, if your project uses a user-managed RISC-V toolchain.
export RISCV_TOOLCHAIN_ROOT="$HOME/riscv-toolchain"
export PATH="$LOCAL_BIN:$RISCV_TOOLCHAIN_ROOT/riscv/bin:$PATH"

# Fill these into the template docs before asking agents to modify ysyxSoC integration.
export YSYX_ID_TOP="ysyx_XXXXXXXX"
export YSYX_ID_NUM="XXXXXXXX"
