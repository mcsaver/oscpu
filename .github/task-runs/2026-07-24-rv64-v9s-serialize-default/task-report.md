# RV64 V9S SERIALIZE-G1 default-configuration report

## Status

`in_progress`

## Current evidence

- current design:
  `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`
- flag-on focused/config: 3/3 PASS
- module inventory: 110/110 PASS
- full-state riscv-tests: 330/330 PASS
- current-design functional aggregate: module 110/110, official 177/177,
  AM 59/59, DiffTest mismatch 0, CoreMark CRC `0xfcaf`, Dhrystone 10000
- current defaults: `OOO_CSR_QUEUE_HEAD=0` in both NPC and Linux Makefiles

## Current action

Run the current design with `OOO_CSR_QUEUE_HEAD=1`,
`OOO_TERMINAL_HOLDER_ASSERT=1`, Ubuntu rootfs, strict guest checks, and natural
poweroff. Do not change defaults before this gate returns PASS.

The first run in `rootfs-csr-qh-on-current/` used a 21600-second host budget
and was intentionally stopped after 10M retired instructions because its
measured 13.8k inst/s rate projected fewer than 300M instructions before host
timeout, while the same systemd route historically needed about 340M. It is
classified as `host_budget_forecast_insufficient`, not as an RTL or rootfs
functional failure.

The replacement run uses the same RTL configuration and boot artifacts in
`rootfs-csr-qh-on-current-10h/`, with a 36000-second host budget.

Replacement-run binding:

- simulator SHA-256:
  `1dcc360162ff8f336d2ed81bbac310db44c095367231fff9466b7951584c24b8`
- Linux Image SHA-256:
  `c26b967e40137f7e932f7434d1f7ea82858cebe09d6c95e5090647c30793dc6a`
- OpenSBI firmware SHA-256:
  `2f15419f76e03cf2acb8d09298aafd4c19b77060b7934505794d1fac39ac4ac9`
- DTB SHA-256:
  `dc058a1bb9443b884ce47035ef992198eafae30b9f148dd72211ea2741be7a5a`
- rootfs SHA-256:
  `4fe2464bd1b94af95833e437f74ee259991195485d4e7833fc5d9fe13dc65055`

The first-run milestones were OpenSBI completion, Linux 6.6 S-mode entry, and
`Initmem setup node 0`. The Verilator command line contains
`+define+OOO_CSR_QUEUE_HEAD=1`, `+define+OOO_TERMINAL_HOLDER_ASSERT`, and
`+define+OOO_ASSERT`. These are bounded intermediate observations only; the
rootfs gate remains `UNRESOLVED` until the replacement run returns a terminal
result.

Replacement-run progress: 20,000,000 retired instructions at
`pc=0xffffffff8062d386`; the latest reported interval reached about
25.5k inst/s. No RTL assertion termination has been observed. This remains a
non-terminal progress record, not a rootfs PASS.

Later replacement-run progress: 30,000,000 retired instructions, kernel memory
availability published, RISC-V local interrupt controller and PLIC mapped,
clocksource/scheduler initialized, and LSM initialization entered. No RTL
assertion termination has been observed. The rootfs gate is still
`UNRESOLVED`.

Latest replacement-run progress: 55,000,001 retired instructions at
`pc=0xffffffff8026d8ac`. Linux initialized the clocksource, core
memory-management tables, I/O scheduler, and 8250/16550 serial driver,
enumerated the `virtio_blk` device as `vda` with 4,194,304 512-byte blocks,
completed EXT4 recovery, mounted that filesystem read/write, and mounted it as
the VFS root on device `254:0`; `devtmpfs` is also mounted. The kernel then
freed init memory and executed
`/usr/local/sbin/ysyx-npc-systemd-wrapper` as the init process, crossing into
the configured userspace validation path. The simulator remains running at
full host-core utilization, and no RTL assertion termination has been
observed. At commit `60,495,804`, the simulator recorded
`pc=0x0000003f9c782620`, `priv=0`, followed by
`[ysyx-npc-systemd-wrapper] begin`; this proves that the configured userspace
wrapper executed in U-mode rather than merely being selected by the kernel.
By 65,000,001 retired instructions, the wrapper reported PASS for the Ubuntu
22.04 identity, `/bin/sh`, `/bin/bash`, the systemd binary, the systemd
autocheck script, and the wrapper preflight; it then emitted
`__NPC_SYSTEMD_CHECK_DONE__ rc=0`, the console prompt marker, and executed
`/lib/systemd/systemd`. The result proves the strict preflight path but is
still a non-terminal milestone; the rootfs gate remains `UNRESOLVED` until
systemd completes the prescribed userspace check and the guest reaches natural
poweroff.

After the systemd exec, retirement continued through 345,000,000 instructions.
Periodic U-mode samples remained continuous through commits `100,987,116`,
`105,987,116`, `110,987,116`, `115,987,117`, `120,989,144`, `125,989,206`,
`130,989,206`, `135,989,206`, `140,989,206`, and `145,989,206`; the latest
observed samples then continued at approximately each 5M interval through
commit `346,494,668`. PID 1 reported
`System time before build time, advancing clock`, then systemd
`249.11-0ubuntu3.21` running in system mode, detected `riscv64`, emitted the
Ubuntu 22.04.5 LTS welcome banner, and set the hostname to
`ysyx-ubuntu2204`. This provides direct evidence that the systemd main process
entered platform initialization. The complete driver log still contained no
RTL assertion termination. These observations prove forward execution in the
systemd phase but do not replace the final userspace marker or
natural-poweroff conditions.

Between about 291M and 300M retired instructions, systemd queued the default
`Graphical Interface` target, created the modprobe and user/session slices,
started the console and wall password-request watches, reached Local File
Systems, Path Units, Slice Units, Swaps, Local Verity Protected Volumes, and
Socket Units, and opened the initctl, journal, and udev sockets. The final
5M interval during this UART-heavy phase reported about 15.7k inst/s. PID 1
then began loading the `configfs` kernel module. These are direct
default-target startup milestones; the rootfs gate remains `UNRESOLVED` until
the console-ready marker, strict guest result, natural poweroff, and runner
return code are all observed.

By about 336M retired instructions, systemd had started the
`YSYX NPC automated root console shell`. The runner matched
`__NPC_CONSOLE_SHELL_READY__` at commit `343,782,292`, completed the configured
20,000,000-cycle settle interval, and released the 4,834-byte UART command
stream at commit `347,510,149`. The observed initial UART bytes match the
expected shell-command prefix. The command stream is still being delivered at
the configured 10,000-cycle byte gap. During delivery, retirement continued
through 375,000,001 instructions with the simulator process remaining in the
running state at full host-core utilization. This is a direct
console-handshake and UART-delivery milestone rather than the final
strict-guest result.

The run then advanced through 540,000,001 retired instructions without an RTL
assertion or simulator termination. The latest sampled PCs map through the
current Linux `System.map` to `handle_exception`, `handle_riscv_irq`,
`generic_handle_domain_irq`, `riscv_intc_irq`, and `plic_handle_irq`. No newer
U-mode sample or second `__NPC_SYSTEMD_CHECK_BEGIN__` marker has appeared after
the UART release: all 39 progress samples from 350M through 540M fall in the
serial8250/exception/PLIC/IRQ entry or exit path, while the last U-mode sample
remains commit 346,494,668. Therefore this remains a live UART/PLIC interrupt-delivery
phase, not a CSR queue-head assertion failure and not a strict-rootfs PASS.
The terminal decision still requires the exact UART result marker, natural
syscon poweroff, and the runner return code.

If the host budget expires while the same interrupt-delivery signature remains
active, the next attempt will keep every strict guest check and the same final
markers but reduce the number of UART-delivered command bytes by invoking a
rootfs-resident strict-check helper. This is a test-platform transport
correction, not a relaxation of the Linux gate and not evidence for flipping
the RTL default by itself.

## Zero-UART systemd-strict attempt and fail-closed correction

The rootfs-resident strict helper route bound the same RTL design id with
`OOO_CSR_QUEUE_HEAD=1`, `OOO_TERMINAL_HOLDER_ASSERT=1`,
`NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict`, and zero UART RX bytes.
It reached 320,000,000 retired instructions at
`pc=0x0000003f8eeca18a`; PID 1 had queued the Graphical Interface target,
reached Local File Systems, and opened journal/udev sockets. No RTL assertion,
kernel panic, Oops, or bad trap appeared.

The run did not reach the strict helper result or natural poweroff.
`driver.log:440-441` records `Hangup` for the child and outer `make`, while
the guest log lacks the actual runtime markers:

- `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0`
- `__NPC_SYSTEMD_UART_CHECK_DONE__ rc=0`
- `__NPC_SYSTEMD_POWEROFF_BEGIN__`
- `HIT GOOD TRAP`

The former runner nevertheless wrote `PASS` from its `EXIT` trap because it
used only `$?` and had no explicit evidence-complete state. This is classified
as `runner_status_false_green`, not as a system gate pass. The original status
text and all content hashes are preserved in
`rootfs-csr-qh-on-current-systemd-strict/false-pass-classification.md`; the
canonical status has been corrected to fail-closed `FAIL`.

The reusable repair is now active:

- `scripts/task-run-status.sh` authorizes `PASS` only when
  evidence-complete=1, command rc=0, cleanup rc=0, and no signal was observed.
- both v9s system runners record stage and `HUP/INT/TERM`;
- `scripts/tests/test-task-run-status.sh` passes normal completion,
  clean early-exit, command failure, cleanup failure, and `HUP` cases;
- the `agent-system` profile discovers and executes
  `task-run-status-fail-closed`;
- replacement runs use distinct labels and a detached single-flight launcher,
  so failed evidence is not overwritten.

The first replacement label,
`rootfs-csr-qh-on-current-systemd-strict-rerun1`, was deliberately terminated
during early OpenSBI execution after its binding showed that the shared strict
ext4 had changed from `d4cda5...` to `d5126b...`. The CPIO remained unchanged,
so the difference came from reusing a guest-writable block image rather than
from a new rootfs source. This run is `INCONCLUSIVE` for RTL behavior and is
classified in
`rootfs-csr-qh-on-current-systemd-strict-rerun1/rootfs-provenance-classification.md`.
The fail-closed status correctly records `signal=TERM`.

The stable correction adds
`Linux/scripts/prepare-npc-rootfs-run-image.sh` and explicit Makefile/checker
plumbing. Each evidence run now rebuilds and content-checks the pristine
template, creates a unique writable ext4 under `.github/runtime-artifacts`,
binds the template and work-copy pre-run hashes, mounts only the work copy,
and requires the template post-run hash to remain unchanged. Positive copy,
mismatched-template-SHA negative, RV64 Linux contract, all-profile binding,
shell syntax, and diff checks pass. The next qualified label is
`rootfs-csr-qh-on-current-systemd-strict-rerun3`.

`rerun2` stopped before RTL compilation at `stage=rootfs-template-rebuild`.
The fresh strict ext4 and CPIO hashes were respectively `2e2328...` and
`5f79ce...`, rather than the historical `d4cda5...` and `ec6a1b...`.
`build-ubuntu-rootfs.sh` creates the image with `mkfs.ext4 -F -d` and archives
the staged tree with `cpio`; UUID and file-time metadata are not normalized,
so a historical binary hash is not a valid clean-build invariant. The runner
now records each run's template, CPIO, and builder-input hashes after the
strict static content check, requires the work-copy pre-hash to equal that
fresh template, and still requires template/CPIO pre/post hashes to remain
unchanged. This changes provenance binding only; no RTL setting, assertion,
guest transaction, or natural-poweroff criterion was relaxed.

The rootfs gate remains `UNRESOLVED`, defaults remain zero, and no PPA
promotion statement is authorized.

## Declaration boundary

This task covers head0 non-FP CSR queue-head retirement only. It does not claim
that ECALL, xRET, FENCE, SFENCE/SINVAL, WFI, IRQ, or other SYSTEM operations
have been converted into ROB-resident uops. Full-core architecture freeze and
formal PPA promotion remain separate gates.
