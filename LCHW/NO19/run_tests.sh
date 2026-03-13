#!/usr/bin/env bash
# run_tests.sh - automated tests for ex19
# Executes several interaction scenarios and checks for expected output snippets.
set -euo pipefail

BIN=./ex19
if [ ! -x "$BIN" ]; then
  echo "Binary $BIN not found or not executable"
  exit 2
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Helper: run program with given input and save output
run_input() {
  local name=$1
  local input=$2
  local out="$TMPDIR/test_output_${name}.txt"
  printf "%b" "$input" | "$BIN" > "$out" 2>&1 || true
  echo "$out"
}

# Test 1: Start and immediately EOF (simulate Ctrl-D) -> expect startup description
out1=$(run_input "start_eof" "")
if ! grep -q "You enter the" "$out1"; then
  echo "[FAIL] Test 1: startup description not found"
  sed -n '1,200p' "$out1"
  exit 3
fi

echo "[PASS] Test 1: program starts and prints entrance"

# Test 2: List available directions from start ('l')
out2=$(run_input "list" "l\n")
if ! grep -q "You can go:" "$out2"; then
  echo "[FAIL] Test 2: list command didn't print 'You can go:'"
  sed -n '1,200p' "$out2"
  exit 4
fi

echo "[PASS] Test 2: list directions works"

# Test 3: Move north->west to arena and attack until monster dead
# Sequence: n (to throne), w (to arena), a repeated until "It is dead!" appears
# We'll run the program and feed a sequence of commands with some attacks.
# Provide many attacks to make monster death extremely likely despite randomness.
# (damage is rand % 4, so use many attempts)
INPUT_SEQ="n\nw\n"
for i in {1..50}; do
  INPUT_SEQ+="a\n"
done
out3=$(run_input "kill_mino" "$INPUT_SEQ")
if ! grep -q "The arena" "$out3" && ! grep -q "mino" "$out3"; then
  echo "[FAIL] Test 3: did not reach arena"
  sed -n '1,200p' "$out3"
  exit 5
fi
if ! grep -q "It is dead!" "$out3"; then
  echo "[FAIL] Test 3: monster was not killed (no 'It is dead!')"
  sed -n '1,400p' "$out3"
  exit 6
fi

echo "[PASS] Test 3: reached arena and killed monster"

# All tests passed
echo "All tests passed. Outputs saved under $TMPDIR (they were removed on exit)."
exit 0
