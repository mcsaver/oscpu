#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path


MARKER = "[FETCH-BRANCH-TARGET-EQUIV]"
PREMISE = "[T3L-NEGATIVE-PREMISE]"
DONE = "[T3L-NEGATIVE-DONE]"


class NegativeLogError(RuntimeError):
    pass


def classify(text: str, compile_rc: int, sim_rc: int) -> None:
    if compile_rc != 0:
        raise NegativeLogError(f"compile_rc={compile_rc}")
    if sim_rc != 0:
        raise NegativeLogError(f"sim_rc={sim_rc}")
    if text.count(PREMISE) != 1:
        raise NegativeLogError(f"premise_count={text.count(PREMISE)}")
    if text.count(MARKER) != 1:
        raise NegativeLogError(f"marker_count={text.count(MARKER)}")
    if text.count(DONE) != 1:
        raise NegativeLogError(f"done_count={text.count(DONE)}")
    for forbidden in ("[CHECK-FAIL]", "[T3L-SOURCE-CONTRACT] FALSE-GREEN"):
        if forbidden in text:
            raise NegativeLogError(f"forbidden={forbidden}")


def selftest() -> None:
    good = f"{PREMISE}\nERROR {MARKER}\n{DONE}\n"
    classify(good, 0, 0)
    bad_cases = {
        "missing": good.replace(f"ERROR {MARKER}\n", ""),
        "duplicate": good.replace(f"ERROR {MARKER}\n", f"ERROR {MARKER}\nERROR {MARKER}\n"),
        "missing_premise": good.replace(f"{PREMISE}\n", ""),
        "missing_done": good.replace(f"{DONE}\n", ""),
        "false_green": good + "[CHECK-FAIL]\n",
    }
    for name, text in bad_cases.items():
        try:
            classify(text, 0, 0)
        except NegativeLogError:
            continue
        raise SystemExit(f"[T3L-NEGATIVE-LOG-SELFTEST] FALSE-GREEN case={name}")
    for name, compile_rc, sim_rc in (("compile", 1, 0), ("sim", 0, 1)):
        try:
            classify(good, compile_rc, sim_rc)
        except NegativeLogError:
            continue
        raise SystemExit(f"[T3L-NEGATIVE-LOG-SELFTEST] FALSE-GREEN case={name}")
    print("[T3L-NEGATIVE-LOG-SELFTEST] PASS cases=7")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("log", type=Path, nargs="?")
    parser.add_argument("--compile-rc", type=int, default=0)
    parser.add_argument("--sim-rc", type=int, default=0)
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
        return 0
    if args.log is None or not args.log.is_file():
        print("[T3L-NEGATIVE-LOG-CHECK] FAIL missing log")
        return 2
    try:
        classify(args.log.read_text(errors="replace"), args.compile_rc, args.sim_rc)
    except NegativeLogError as exc:
        print(f"[T3L-NEGATIVE-LOG-CHECK] FAIL {exc}")
        return 1
    print(
        f"[T3L-NEGATIVE-LOG-CHECK] PASS marker={MARKER} "
        f"premise={PREMISE} compile_rc={args.compile_rc} sim_rc={args.sim_rc}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
