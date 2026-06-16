#!/usr/bin/env python3
"""NEMU full-rootfs PyLong/int preflight probe.

The shell gates run this inside the guest.  It intentionally prints the same
markers as the historical inline probe so old logs and e2e checks remain
comparable, while keeping the probe as a small reusable artifact.
"""

import argparse
import sys
import traceback

_PYLONG_LAYOUT = None
_PYLONG_LAYOUT_READY = False


def emit(name, value):
    try:
        text = str(value)
    except BaseException as exc:  # pragma: no cover - guest corruption path
        print("__PYTHON_INT_PREFLIGHT_%s_STR_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        print("__PYTHON_INT_PREFLIGHT_%s_TYPE__:%s" % (
            name, type(value).__name__))
        if isinstance(value, int):
            try:
                print("__PYTHON_INT_PREFLIGHT_%s_BIT_LENGTH__:%s" % (
                    name, value.bit_length()))
            except BaseException as bit_exc:
                print("__PYTHON_INT_PREFLIGHT_%s_BIT_LENGTH_ERROR__:%s:%s" % (
                    name, type(bit_exc).__name__, bit_exc))
            emit_pylong_object(
                "STR_ERROR_%s" % name, value, enforce=False,
                include_repr=False)
        return
    print("__PYTHON_INT_PREFLIGHT_%s__:%s" % (name, text))


def emit_call(name, fn):
    try:
        value = fn()
    except BaseException as exc:  # pragma: no cover - guest corruption path
        print("__PYTHON_INT_PREFLIGHT_%s_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        traceback.print_exc()
        return None
    emit(name, value)
    return value


def _pylong_layout():
    global _PYLONG_LAYOUT, _PYLONG_LAYOUT_READY
    if _PYLONG_LAYOUT_READY:
        return _PYLONG_LAYOUT

    _PYLONG_LAYOUT_READY = True
    if getattr(sys.implementation, "name", "") != "cpython":
        return None

    import ctypes

    digit_size = sys.int_info.sizeof_digit
    if digit_size == 4:
        digit_type = ctypes.c_uint32
    elif digit_size == 2:
        digit_type = ctypes.c_uint16
    else:
        raise AssertionError("unsupported PyLong digit size: %r" % digit_size)

    layout_mode = "compact" if sys.version_info >= (3, 12) else "legacy"

    if layout_mode == "compact":
        class PyLongHead(ctypes.Structure):
            _fields_ = [
                ("ob_refcnt", ctypes.c_ssize_t),
                ("ob_type", ctypes.c_void_p),
                ("lv_tag", ctypes.c_size_t),
            ]
    else:
        class PyLongHead(ctypes.Structure):
            _fields_ = [
                ("ob_refcnt", ctypes.c_ssize_t),
                ("ob_type", ctypes.c_void_p),
                ("ob_size", ctypes.c_ssize_t),
            ]

    if ctypes.sizeof(ctypes.c_void_p) != ctypes.sizeof(ctypes.c_ssize_t):
        raise AssertionError("unexpected CPython pointer/ssize_t layout")

    _PYLONG_LAYOUT = (ctypes, PyLongHead, digit_type, layout_mode)
    return _PYLONG_LAYOUT


def emit_pylong_layout():
    emit("PYLONG_LAYOUT_IMPLEMENTATION", getattr(sys.implementation, "name", ""))
    emit("PYLONG_LAYOUT_BITS_PER_DIGIT", sys.int_info.bits_per_digit)
    emit("PYLONG_LAYOUT_SIZEOF_DIGIT", sys.int_info.sizeof_digit)
    try:
        layout = _pylong_layout()
    except BaseException as exc:  # pragma: no cover - guest corruption path
        print("__PYTHON_INT_PREFLIGHT_PYLONG_LAYOUT_ERROR__:%s:%s" % (
            type(exc).__name__, exc))
        traceback.print_exc()
        return None
    if layout is None:
        emit("PYLONG_LAYOUT_AVAILABLE", 0)
        return None

    ctypes, PyLongHead, digit_type, layout_mode = layout
    emit("PYLONG_LAYOUT_AVAILABLE", 1)
    emit("PYLONG_LAYOUT_MODE", layout_mode)
    emit("PYLONG_LAYOUT_HEAD_SIZE", ctypes.sizeof(PyLongHead))
    emit("PYLONG_LAYOUT_SSIZE_T_SIZE", ctypes.sizeof(ctypes.c_ssize_t))
    emit("PYLONG_LAYOUT_VOID_P_SIZE", ctypes.sizeof(ctypes.c_void_p))
    emit("PYLONG_LAYOUT_DIGIT_CTYPE", getattr(digit_type, "__name__", digit_type))
    return layout


def _expected_pylong_digits(value):
    bits = sys.int_info.bits_per_digit
    mask = (1 << bits) - 1
    magnitude = abs(value)
    digits = []
    while magnitude:
        digits.append(magnitude & mask)
        magnitude >>= bits
    if not digits:
        digits.append(0)
    return digits


def emit_pylong_object(name, value, expected=None, enforce=True,
                       include_repr=True):
    problems = []
    emit("PYLONG_%s_TYPE" % name, type(value).__name__)
    emit_call("PYLONG_%s_ID" % name, lambda: "0x%x" % id(value))
    emit_call("PYLONG_%s_SIZEOF" % name, lambda: sys.getsizeof(value))
    if include_repr:
        emit_call("PYLONG_%s_REPR" % name, lambda: repr(value))
    emit_call("PYLONG_%s_BIT_LENGTH" % name, lambda: value.bit_length())

    try:
        layout = _pylong_layout()
        if layout is None:
            problems.append("layout-unavailable")
            emit("PYLONG_%s_LAYOUT_AVAILABLE" % name, 0)
            if enforce:
                raise AssertionError("PyLong layout unavailable")
            return False

        ctypes, PyLongHead, digit_type, layout_mode = layout
        head = PyLongHead.from_address(id(value))
        if layout_mode == "compact":
            lv_tag = head.lv_tag
            tag_sign = lv_tag & 3
            digit_count_from_header = lv_tag >> 3
            ob_size = (1 - tag_sign) * digit_count_from_header
            emit("PYLONG_%s_LV_TAG" % name, lv_tag)
            emit("PYLONG_%s_TAG_SIGN" % name, tag_sign)
            emit("PYLONG_%s_DIGIT_COUNT" % name, digit_count_from_header)
        else:
            ob_size = head.ob_size
            digit_count_from_header = abs(ob_size)
        digit_count = max(1, abs(ob_size))
        if expected is not None:
            digit_count = max(digit_count, len(_expected_pylong_digits(expected)))
        digit_count = min(digit_count, 4)
        DigitArray = digit_type * digit_count
        digits = list(DigitArray.from_address(id(value) + ctypes.sizeof(PyLongHead)))

        emit("PYLONG_%s_LAYOUT_AVAILABLE" % name, 1)
        emit("PYLONG_%s_REFCOUNT" % name, head.ob_refcnt)
        emit("PYLONG_%s_TYPE_PTR" % name, "0x%x" % (head.ob_type or 0))
        emit("PYLONG_%s_INT_TYPE_PTR" % name, "0x%x" % id(int))
        emit("PYLONG_%s_TYPE_MATCH" % name, int(head.ob_type == id(int)))
        emit("PYLONG_%s_OB_SIZE" % name, ob_size)
        for index, digit in enumerate(digits):
            emit("PYLONG_%s_OB_DIGIT%d" % (name, index), digit)

        if head.ob_refcnt <= 0:
            problems.append("non-positive-refcnt")
        if head.ob_type != id(int):
            problems.append("type-ptr-mismatch")

        if expected is not None:
            expected_digits = _expected_pylong_digits(expected)
            if expected == 0:
                expected_ob_size = 0
            else:
                sign = -1 if expected < 0 else 1
                expected_ob_size = sign * len(expected_digits)

            emit("PYLONG_%s_EXPECTED_OB_SIZE" % name, expected_ob_size)
            for index, digit in enumerate(expected_digits[:4]):
                emit("PYLONG_%s_EXPECTED_DIGIT%d" % (name, index), digit)

            if ob_size != expected_ob_size:
                problems.append("ob-size")
            if expected != 0:
                for index, digit in enumerate(expected_digits[:len(digits)]):
                    if digits[index] != digit:
                        problems.append("digit%d" % index)

        if problems:
            emit("PYLONG_%s_MISMATCH" % name, ",".join(problems))
            if enforce:
                raise AssertionError(
                    "PyLong %s layout mismatch: %s" % (
                        name, ",".join(problems)))
            return False

        emit("PYLONG_%s_OK" % name, 1)
        return True
    except BaseException as exc:  # pragma: no cover - guest corruption path
        print("__PYTHON_INT_PREFLIGHT_PYLONG_%s_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        traceback.print_exc()
        if enforce:
            raise
        return False


def check_int_value(name, value, expected, emit_layout=False):
    emit(name, value)
    try:
        bit_length = value.bit_length()
    except BaseException as exc:  # pragma: no cover - guest corruption path
        print("__PYTHON_INT_PREFLIGHT_%s_BIT_LENGTH_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        emit_pylong_object(
            "BIT_LENGTH_ERROR_%s" % name, value, expected=expected,
            enforce=False, include_repr=False)
        raise

    emit("%s_BIT_LENGTH" % name, bit_length)
    if bit_length != expected.bit_length():
        emit("%s_EXPECTED_BIT_LENGTH" % name, expected.bit_length())
        emit_pylong_object(
            "BIT_LENGTH_MISMATCH_%s" % name, value, expected=expected,
            enforce=False, include_repr=False)
        raise AssertionError("%s bit_length=%r expected=%r" % (
            name, bit_length, expected.bit_length()))

    if value != expected:
        emit_pylong_object(
            "VALUE_MISMATCH_%s" % name, value, expected=expected,
            enforce=False, include_repr=False)
        raise AssertionError("%s=%r expected=%r" % (name, value, expected))

    if emit_layout:
        emit_pylong_object(
            "%s_LAYOUT" % name, value, expected=expected,
            include_repr=False)


def emit_pylong_baseline(args_loops, loop_stop):
    layout = emit_pylong_layout()
    if layout is None:
        raise AssertionError("CPython PyLong layout is unavailable")
    for name, value, expected in (
        ("CONST_ZERO", 0, 0),
        ("CONST_ONE", 1, 1),
        ("CONST_TWO", 2, 2),
        ("CONST_NEG_ONE", -1, -1),
        ("CONST_U32_MAX", 4294967295, 4294967295),
        ("ARGS_LOOPS", args_loops, args_loops),
        ("ARGS_LOOP_STOP", loop_stop, loop_stop),
    ):
        emit_pylong_object(name, value, expected=expected)


def run_once(iteration):
    try:
        for text, expected in (
            ("0", 0),
            ("2", 2),
            ("169", 169),
            ("254", 254),
            ("4294967295", 4294967295),
        ):
            emit("TEXT_%s_REPR" % text, repr(text))
            emit("TEXT_%s_LEN" % text, len(text))
            emit("TEXT_%s_ORDS" % text, ",".join(str(ord(ch)) for ch in text))
            value = int(text, 10)
            check_int_value(
                "VALUE_%s" % text, value, expected,
                emit_layout=(iteration == 1 and text in ("2", "4294967295")))

        octets = [169, 254, 0, 0]
        octet_bytes = bytes(octets)
        emit("OCTET_BYTES_HEX", octet_bytes.hex())
        for name, source in (
            ("BYTES", octet_bytes),
            ("LIST", octets),
            ("MAP", map(lambda octet: octet, octets)),
        ):
            value = int.from_bytes(source, "big")
            check_int_value(
                "INT_FROM_BYTES_%s" % name, value, 2851995648,
                emit_layout=(iteration == 1 and name == "BYTES"))
        print("__PYTHON_INT_PREFLIGHT_OK__")
        print("__PYTHON_INT_PREFLIGHT_ITER_OK__:%d" % iteration)
        return 0
    except BaseException:
        traceback.print_exc()
        return 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", default="focused")
    parser.add_argument("--loops", type=int, default=5)
    args = parser.parse_args()

    print("__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__:%s" % args.tag)
    emit("ARGS_TAG", args.tag)
    emit("ARGS_LOOPS_TYPE", type(args.loops).__name__)
    emit_call("ARGS_LOOPS_REPR", lambda: repr(args.loops))
    emit_call("ARGS_LOOPS_BIT_LENGTH", lambda: args.loops.bit_length())
    loop_stop = emit_call("ARGS_LOOPS_PLUS_ONE", lambda: args.loops + 1)
    if loop_stop is None:
        return 1
    try:
        emit_pylong_baseline(args.loops, loop_stop)
    except BaseException:
        traceback.print_exc()
        return 1

    ok = True
    for iteration in range(1, loop_stop):
        rc = run_once(iteration)
        print("__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:%s:%d:%d" % (
            args.tag, iteration, rc))
        if rc != 0:
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
