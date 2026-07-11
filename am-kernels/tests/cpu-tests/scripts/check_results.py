#!/usr/bin/env python3
"""校验 cpu-tests 汇总结果是否完整且全部通过。"""

import argparse
from collections import Counter, defaultdict
from pathlib import Path
import re
import sys


ANSI_RE = re.compile(r"\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
RESULT_RE = re.compile(
  r"^\[\s*(?P<name>[^\]\s]+)\s*\]\s+"
  r"(?P<status>PASS|\*\*\*FAIL\*\*\*)$")
SUMMARY_FIELDS = ("failed", "missing", "duplicate", "unexpected", "malformed")


def check_result_file(path, expected):
  """读取真实结果文件，返回固定字段顺序的完整性摘要。"""
  records = defaultdict(list)
  malformed = []
  for lineno, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
    line = ANSI_RE.sub("", raw_line)
    match = RESULT_RE.fullmatch(line)
    if match is None:
      malformed.append(f"{lineno}: {line!r}")
      continue
    records[match.group("name")].append(match.group("status"))

  expected_set = set(expected)
  counts = Counter({name: len(statuses) for name, statuses in records.items()})
  return {
    "failed": sorted(name for name, statuses in records.items()
                     if "***FAIL***" in statuses),
    "missing": sorted(expected_set - records.keys()),
    "duplicate": sorted(name for name, count in counts.items() if count > 1),
    "unexpected": sorted(records.keys() - expected_set),
    "malformed": malformed,
  }


def _parser():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--result", required=True, type=Path)
  parser.add_argument("--expected", required=True, nargs="+")
  return parser


def main(argv=None):
  args = _parser().parse_args(argv)
  duplicate_expected = sorted(
    name for name, count in Counter(args.expected).items() if count > 1)
  if duplicate_expected:
    print("error: duplicate --expected test(s): " + ", ".join(duplicate_expected),
          file=sys.stderr)
    return 2

  try:
    summary = check_result_file(args.result, args.expected)
  except (OSError, UnicodeError) as error:
    print(f"error: cannot read result file {args.result}: {error}", file=sys.stderr)
    return 2

  # 固定输出全部类别，确保 CI 不会因摘要缺字段而误判异常类型。
  if any(summary[field] for field in SUMMARY_FIELDS):
    print("result check failed")
    for field in SUMMARY_FIELDS:
      print(f"{field}: {', '.join(summary[field]) or '-'}")
    return 1

  print(f"result check passed: {len(args.expected)} test(s)")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
