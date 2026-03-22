# Copilot instructions for ysyx-workbench

## Big picture
- This is a YSYX lab workspace with multiple subprojects; do not assume a single build system.
- [nemu/](nemu/) is the full-system emulator; it can run standalone or integrate with AbstractMachine when `CONFIG_TARGET_AM` is enabled (see [nemu/Makefile](nemu/Makefile)).
- [abstract-machine/](abstract-machine/) provides the hardware abstraction layer (AM) used by kernels and NEMU AM-target builds.
- [am-kernels/](am-kernels/) contains bare-metal kernels and benchmarks built against AM.
- [npc/](npc/) is a separate hardware/RTL project; active student work is commonly under [npc/single/](npc/single/).
- Many subprojects use their own `build/` directories; avoid mixing artifacts across subprojects.

## Critical workflows
- Initialize subprojects via [init.sh](init.sh); it clones the expected upstream repos and sets env vars in `~/.bashrc` (e.g. `NEMU_HOME`, `AM_HOME`, `NAVY_HOME`, `NPC_HOME`).
- NEMU configuration uses Kconfig; if `.config` is missing, run `make menuconfig` in [nemu/](nemu/) (see [nemu/scripts/config.mk](nemu/scripts/config.mk)).
- Build NEMU with `make` in [nemu/](nemu/); run via `make run` and pass an image with `IMG=...` (targets are defined in [nemu/scripts/native.mk](nemu/scripts/native.mk)).
- For AM-based projects, set `ARCH=...` and build `image` (default target) in [abstract-machine/](abstract-machine/) or kernel directories (see [abstract-machine/Makefile](abstract-machine/Makefile)).
- If environment variables are updated by `init.sh`, remind user to run `source ~/.bashrc` before build/run.

## Project-specific conventions
- The top-level [Makefile](Makefile) defines a tracer git-commit workflow used by subprojects; keep its `git_commit` calls intact (e.g. in [npc/single/Makefile](npc/single/Makefile)).
- NEMU build flags come from `.config` and auto-generated headers in `include/config/` and `include/generated/`; don’t edit those directly.
- NEMU’s `run` uses differential testing when configured (see `tools/difftest.mk` usage in [nemu/scripts/native.mk](nemu/scripts/native.mk)).

## Current focus: NPC 8-instruction RTL stage
- Scope changes to [npc/single/](npc/single/) first, especially [npc/single/vsrc/](npc/single/vsrc/) and [npc/single/csrc/](npc/single/csrc/); avoid unrelated edits in `nemu/` or `abstract-machine/` unless explicitly requested.
- Keep [npc/single/Makefile](npc/single/Makefile) minimal and runnable for this stage: preserve tracer commit hook, add only essential simulation targets.
- Prefer small, testable RTL increments (decode/ALU/regfile path) and verify each change with the smallest available simulation target.
- Do not introduce broad refactors, new directory layouts, or nonessential framework code before the 8-instruction milestone is stable.

## Build hints for this stage
- NEMU quick check: `cd nemu && make menuconfig && make`.
- AM quick check: `cd am-kernels/kernels/hello && ARCH=riscv32-nemu make`.
- NPC current skeleton has placeholder targets in [npc/single/Makefile](npc/single/Makefile); implement `sim` flow incrementally and keep target names consistent with existing file layout.

## When editing
- Prefer changes inside the relevant subproject (e.g. [nemu/src/](nemu/src/) or [abstract-machine/](abstract-machine/)) rather than cross-cutting edits.
- Keep make targets and env variable checks consistent with existing Makefiles; many sanity checks rely on `NEMU_HOME`/`AM_HOME` being set.
- For partial-lab progress, bias toward minimal fixes that unblock current milestone instead of completing future stages in advance.
