---
description: "Use when editing npc/single RTL, Verilator simulation flow, or testbench files for the 8-instruction milestone. Focus on minimal, testable, in-scope changes."
name: "NPC Single 8-Instruction Stage"
applyTo: "npc/single/**"
---
# NPC Single Stage Guidelines

## Scope
- Prioritize changes inside `npc/single/vsrc/`, `npc/single/csrc/`, and `npc/single/Makefile`.
- Avoid modifying `nemu/`, `abstract-machine/`, or other subprojects unless explicitly requested.
- Keep changes minimal and milestone-oriented for the current 8-instruction stage.

## Build and Validation
- Keep `npc/single/Makefile` minimal and runnable; add only essential `sim` flow steps.
- Preserve tracer hook lines using `git_commit` in simulation targets.
- Prefer smallest validation first: module-level checks before wider integration.

## Coding Conventions
- Implement RTL in small, testable increments (e.g., regfile, decode, ALU path).
- Do not introduce broad refactors, new frameworks, or directory restructures.
- Follow existing naming/style in nearby files before introducing new patterns.

## Safety Checks
- If env-dependent commands are needed, remind user to ensure `NPC_HOME`/`NEMU_HOME`/`AM_HOME` are set.
- If `init.sh` changed env vars, remind user to run `source ~/.bashrc` before build/run.
