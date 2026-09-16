# AxiPlic contract

## Scope

`AxiPlic` implements sources 1..31 with M/S enable and threshold contexts,
pending/in-service state, priority arbitration, claim/complete side effects and
a registered merged external interrupt output. Source 0 is permanently zero.

## AXI and state rules

- AR is accepted only when no R response is held. A claim read returns the
  current winner and, on the same edge, clears its pending bit and sets its
  in-service bit.
- AW and W may arrive independently. A write is applied after both are held;
  B is then held until accepted.
- Pending first accumulates asserted level sources not already in service.
  Claim then removes the selected source. Software pending writes and complete
  retain their existing later-assignment priority; complete re-pends an asserted
  level source.
- `external_irq_o` remains a one-cycle registered projection of whether either
  context has a nonzero claim candidate. Claim/complete timing is not changed
  by that output register.

## Priority and threshold WARL

- Priority and threshold remain 32-bit MMIO fields, but the platform default is
  `PRIORITY_BITS=3`, implementing values 0..7.
- Writes to unimplemented high bits are ignored and reads return those bits as
  zero. Byte strobes merge the 32-bit view before truncation, so a write only to
  an unimplemented high byte preserves the implemented low bits.
- Priority zero is inactive. A source is eligible only when pending, enabled,
  not in service, nonzero priority, and priority is strictly greater than the
  context threshold.
- Higher priority wins. Every reduction stage selects its upper input only for
  a strict `>` comparison, so equal priorities deterministically choose the
  lower source ID.
- `PRIORITY_BITS` may be configured from 1 through 32. A 32-bit configuration
  retains the former full-width behavior; the synthesized NPC platform uses the
  default 3-bit WARL implementation.

The three-bit default exactly covers the repository Linux driver's priority
0/1 and threshold 0/7 policy and all existing directed values 0..7. The PLIC
architecture permits the number of priority levels to be implementation-defined.

## Timing topology

The claim side-effect path is intentionally zero-additional-latency:

`priority/threshold -> candidate -> five winner levels -> claim ID -> dynamic
pending/in-service bit update`.

Therefore priority storage, threshold storage, and every winner-priority level
must use `PRIORITY_BITS`; silently retaining a 32-bit intermediate violates this
contract even if MMIO readback appears WARL-correct.

## Verification

- Directed TB must cover high-bit write-ignore/read-zero, byte-strobe preserve,
  priorities/thresholds 0..7, equal-priority low-ID tie-break, claim/complete,
  level re-pend and registered IRQ visibility.
- A source audit must reject default-width restoration, any 32-bit winner-prio
  intermediate, non-zero-extended readback, or loss of WSTRB merge.
- Fresh synthesis and exact 5.000ns STA must prove the former threshold bits
  29/31 no longer exist and report global WNS/TNS honestly.
