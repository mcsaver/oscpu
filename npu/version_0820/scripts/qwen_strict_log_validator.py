#!/usr/bin/env python3
"""Validate strict Qwen NPU preflight and per-dispatch ledger evidence.

This module is the importable counterpart of the strict smoke runner's original
inline validator.  The CLI preserves the frozen summary JSON schema and emits
the same NPU-STRICT-LEDGER PASS marker on success.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re

from qwen_graph_manifest import QWEN_RECURRENT_LAYERS


F32_ALU_TRANSACTIONS_PER_DISPATCH = 367
F32_ALU_ZERO_TRANSACTIONS_PER_STEADY_DISPATCH = 36
F32_ALU_BOOTSTRAP_FIRST_HOLDS = 367
F32_ALU_STEADY_FIRST_HOLDS = 331
F32_ALU_BOOTSTRAP_RAW_READ_BYTES = 211_292_672
F32_ALU_BOOTSTRAP_RAW_WRITE_BYTES = 115_820_800
F32_ALU_STEADY_RAW_READ_BYTES = 191_091_200
F32_ALU_STEADY_RAW_WRITE_BYTES = 95_619_328


def validate_strict_log(
    log_path: str | pathlib.Path,
    summary_path: str | pathlib.Path,
    expected_dispatches: int,
) -> tuple[dict[str, int], str]:
    """Validate log_path, write summary_path, and return summary plus marker."""
    log_path = pathlib.Path(log_path)
    summary_path = pathlib.Path(summary_path)
    expected_dispatches = int(expected_dispatches)
    lines = log_path.read_text(encoding="utf-8", errors="strict").splitlines()


    def die(message: str) -> None:
        raise SystemExit(f"strict log validation failed: {message}")

    field_token_re = re.compile(r"([a-z][a-z0-9_]*)=([0-9]+)")

    def fields(
        line: str,
        prefix: str,
        expected_fields: tuple[str, ...],
        marker: str,
    ) -> dict[str, int]:
        """Parse one ledger marker with a closed, fully consumed grammar.

        Ledger fields are executable evidence. Accepting a known subset would
        make a newly emitted ``future_error=1`` (or even ``future_error=0``)
        invisible to this validator. Consequently every character after the
        marker prefix must be one space-delimited unsigned-decimal field, and
        the observed field set must equal the frozen set for that marker.
        """
        field_prefix = prefix + " "
        if not line.startswith(field_prefix):
            die(f"{marker} malformed prefix: {line}")
        payload = line[len(field_prefix):]
        tokens = payload.split(" ")
        if not payload or any(not token for token in tokens):
            die(f"{marker} malformed field grammar: {line}")

        result: dict[str, int] = {}
        for token in tokens:
            match = field_token_re.fullmatch(token)
            if match is None:
                die(f"{marker} malformed field token {token!r}: {line}")
            key, value = match.groups()
            if key in result:
                die(f"{marker} duplicate field {key}: {line}")
            result[key] = int(value)

        expected = set(expected_fields)
        observed = set(result)
        unknown = sorted(observed - expected)
        missing = sorted(expected - observed)
        if unknown:
            die(f"{marker} unknown fields {unknown}: {line}")
        if missing:
            die(f"{marker} missing required fields {missing}: {line}")
        return result

    EXPECTED_NODES = 1714
    REQUIRED_PER_DISPATCH = 1080
    FROZEN_PORTAL_OWNER_TRANSACTIONS = {
        "f32_alu": F32_ALU_TRANSACTIONS_PER_DISPATCH,
        "q8_gemv": 187,
        "f32_mover": 91,
    }
    SAMPLER_ARGMAX_PER_DISPATCH = {
        "transactions": 1,
        "expected_transactions": 1,
        "elements": 248320,
        "expected_elements": 248320,
        "read_bytes": 993288,
        "expected_read_bytes": 993288,
        "scalar_write_bytes": 4,
        "expected_scalar_write_bytes": 4,
        "sampled_tokens": 1,
        "expected_sampled_tokens": 1,
        "host_scalar_copy_bytes": 4,
        "full_vocab_host_exports": 0,
        "full_vocab_host_export_bytes": 0,
        "cpu_candidate_scans": 0,
        "invalid_tokens": 0,
    }
    FROZEN_NONPORTAL_REQUIRED = (
        REQUIRED_PER_DISPATCH - sum(FROZEN_PORTAL_OWNER_TRANSACTIONS.values())
    )
    if FROZEN_NONPORTAL_REQUIRED != 435:
        die("internal frozen owner partition does not close to 1080")
    if ((SAMPLER_ARGMAX_PER_DISPATCH["elements"] * 4 + 4 + 7) & ~7) != \
            SAMPLER_ARGMAX_PER_DISPATCH["read_bytes"]:
        die("internal sampler ARGMAX byte contract does not close")

    sampler_ready = [
        line for line in lines if "[NPU-STRICT-SAMPLER][READY]" in line
    ]
    sampler_ready_suffix = (
        "[NPU-STRICT-SAMPLER][READY] mode=backend-greedy "
        "full_vocab_host_export=0 cpu_candidate_scan=0"
    )
    if len(sampler_ready) != 1 or not sampler_ready[0].endswith(
            sampler_ready_suffix):
        die(f"strict sampler READY marker count/content mismatch: {sampler_ready}")

    ready = [line for line in lines if line.startswith("[NPU-STRICT][READY]")]
    if ready != [
        "[NPU-STRICT][READY] backend=NPU candidates=1 audit_abi=v2 "
        "canonical_binding_abi=v1"
    ]:
        die(f"READY marker count/content mismatch: {ready}")

    strict_failures = [line for line in lines if line.startswith("[NPU-STRICT][FAIL]")]
    ledger_failures = [line for line in lines if line.startswith("[NPU-SYSTEM-LEDGER][FAIL]")]
    functional_failures = [
        line for line in lines
        if line.startswith("[NPU-FUNCTIONAL-COMMAND-LEDGER][FAIL]")
    ]
    raw32_failures = [
        line for line in lines
        if line.startswith("[NPU-RAW32-PORTAL-LEDGER][FAIL]")
    ]
    sampler_argmax_failures = [
        line for line in lines
        if line.startswith("[NPU-SAMPLER-ARGMAX-LEDGER][FAIL]")
    ]
    failure_markers = (
        strict_failures + ledger_failures + functional_failures + raw32_failures +
        sampler_argmax_failures
    )
    if failure_markers:
        die(f"failure marker observed: {failure_markers[:2]}")

    begin_re = re.compile(
        r"^\[NPU-STRICT\]\[PREFLIGHT-BEGIN\] graph=(\S+) cohort=([0-9]+) nodes=([0-9]+)$"
    )
    end_re = re.compile(
        r"^\[NPU-STRICT\]\[PREFLIGHT-END\] graph=(\S+) cohort=([0-9]+) "
        r"nodes=([0-9]+) required_seen=([0-9]+) supported=([0-9]+) "
        r"unsupported=([0-9]+) canonical_errors=([0-9]+)$"
    )
    manifest_re = re.compile(
        r"^\[NPU-STRICT\]\[MANIFEST\] graph=(\S+) cohort=([0-9]+) "
        r"node=([0-9]+) (canonical_id=([0-9a-f]{64}).* supported=([01]))$"
    )
    begin_marker = "[NPU-STRICT][PREFLIGHT-BEGIN]"

    def match_preflight_begin(line: str) -> re.Match[str] | None:
        """Match a BEGIN marker, including one coalesced after token stdout.

        llama-completion writes generated token text to stdout without forcing a
        newline.  The backend writes the next dispatch's preflight BEGIN to
        stderr, and the smoke runner merges both streams.  The kernel can
        therefore produce ``<token>[NPU-STRICT][PREFLIGHT-BEGIN] ...`` as one
        physical log line even though they are distinct logical records.

        Keep this exception narrow and fail-closed: only one exact, fully
        consumed BEGIN for a post-bootstrap dispatch may be de-framed, and its
        preceding model-output fragment may not contain another NPU marker.
        Cohort ordering and all 1080 manifest records are still checked below.
        """
        match = begin_re.fullmatch(line)
        if match is not None:
            return match
        occurrences = line.count(begin_marker)
        if occurrences == 0:
            return None
        if occurrences != 1:
            die(f"ambiguous coalesced preflight BEGIN marker: {line}")
        marker_offset = line.index(begin_marker)
        prefix = line[:marker_offset]
        candidate = line[marker_offset:]
        match = begin_re.fullmatch(candidate)
        if (
            not prefix
            or "[NPU-" in prefix
            or match is None
            or match.group(1) != "dispatch"
            or int(match.group(2)) < 5
        ):
            die(f"malformed coalesced preflight BEGIN marker: {line}")
        return match

    begins: dict[tuple[str, int], int] = {}
    ends: dict[tuple[str, int], tuple[int, int, int, int, int]] = {}
    # The raw descriptor deliberately keeps every semantic field after node=.
    # Comparing only canonical_id would miss name/op/type/shape/stride drift.
    manifests: dict[tuple[str, int], dict[int, tuple[str, str, int]]] = {}
    begin_order: list[tuple[str, int]] = []
    end_order: list[tuple[str, int]] = []
    manifest_cohort_order: list[tuple[str, int]] = []
    active_cohort: tuple[str, int] | None = None
    for line in lines:
        match = match_preflight_begin(line)
        if match:
            key = (match.group(1), int(match.group(2)))
            if key in begins:
                die(f"duplicate preflight BEGIN: {key}")
            if active_cohort is not None:
                die(f"overlapping preflight cohorts: {active_cohort} then {key}")
            begins[key] = int(match.group(3))
            begin_order.append(key)
            active_cohort = key
            continue
        match = end_re.fullmatch(line)
        if match:
            key = (match.group(1), int(match.group(2)))
            if key in ends:
                die(f"duplicate preflight END: {key}")
            if active_cohort != key:
                die(f"preflight END does not close active cohort: {key}")
            ends[key] = tuple(int(match.group(index)) for index in range(3, 8))
            end_order.append(key)
            active_cohort = None
            continue
        match = manifest_re.fullmatch(line)
        if match:
            key = (match.group(1), int(match.group(2)))
            if active_cohort != key:
                die(f"manifest is outside its active cohort: {key}")
            node_index = int(match.group(3))
            if not 0 <= node_index < EXPECTED_NODES:
                die(f"manifest node index is outside 0..1713: {node_index}")
            cohort = manifests.setdefault(key, {})
            if not cohort:
                manifest_cohort_order.append(key)
            if node_index in cohort:
                die(f"duplicate manifest node {node_index} in {key}")
            cohort[node_index] = (
                match.group(5), match.group(4), int(match.group(6))
            )
            continue
        if line.startswith((
            "[NPU-STRICT][PREFLIGHT-BEGIN]",
            "[NPU-STRICT][PREFLIGHT-END]",
            "[NPU-STRICT][MANIFEST]",
        )):
            die(f"malformed preflight marker: {line}")

    if expected_dispatches <= 0:
        die(f"invalid expected dispatch count: {expected_dispatches}")
    if active_cohort is not None:
        die(f"unterminated preflight cohort: {active_cohort}")
    if not begins or set(begins) != set(ends) or set(begins) != set(manifests):
        die("preflight BEGIN/END/manifest cohort sets differ or are empty")
    expected_cohort_order = [
        ("reserve", 1), ("reserve", 2), ("reserve", 3),
        *(("dispatch", cohort) for cohort in range(4, 4 + expected_dispatches)),
    ]
    if (begin_order != expected_cohort_order or
            end_order != expected_cohort_order or
            manifest_cohort_order != expected_cohort_order):
        die(
            "preflight cohort observation order/identity mismatch: "
            f"begin={begin_order} manifest={manifest_cohort_order} "
            f"end={end_order} expected={expected_cohort_order}"
        )
    canonical_sets: list[frozenset[str]] = []
    dispatch_preflights = 0
    reserve_preflights = 0
    for key in sorted(begins, key=lambda item: item[1]):
        node_count, required, supported, unsupported, canonical_errors = ends[key]
        if begins[key] != node_count or node_count != EXPECTED_NODES:
            die(f"node count changed within cohort {key}")
        if (required, supported, unsupported, canonical_errors) != (
            REQUIRED_PER_DISPATCH, REQUIRED_PER_DISPATCH, 0, 0
        ):
            die(f"1080/0 admission mismatch in {key}: {ends[key]}")
        cohort = manifests[key]
        if (len(cohort) != REQUIRED_PER_DISPATCH or
                any(supported_bit != 1
                    for _, _, supported_bit in cohort.values())):
            die(f"manifest support/cardinality mismatch in {key}")
        ids = frozenset(
            canonical_id for canonical_id, _, _ in cohort.values()
        )
        if len(ids) != REQUIRED_PER_DISPATCH:
            die(f"canonical IDs are not unique in {key}")
        canonical_sets.append(ids)
        dispatch_preflights += key[0] == "dispatch"
        reserve_preflights += key[0] == "reserve"
    if any(ids != canonical_sets[0] for ids in canonical_sets[1:]):
        die("canonical required-node set changed across preflight cohorts")
    if reserve_preflights != 3 or dispatch_preflights != expected_dispatches:
        die(
            f"preflight cardinality mismatch reserve={reserve_preflights} "
            f"dispatch={dispatch_preflights} expected_dispatch={expected_dispatches}"
        )

    # Reserve cohorts and dispatch 1 are the bootstrap graph.  Dispatch 2 and
    # every later dispatch are one frozen steady graph.  The only legal phase
    # delta is the 18-layer cache_r/cache_s SCALE pair becoming a zero-shape
    # no-op while retaining node index, canonical ID, name and owner profile.
    cache_scale_re = re.compile(
        r"^canonical_id=(?P<canonical_id>[0-9a-f]{64}) "
        r"name=cache_(?P<kind>[rs])_l(?P<layer>[0-9]+) "
        r"\(reshaped\) \(view\) \(view\) op=SCALE "
        r"dst_type=f32 dst_ne=(?P<dst_ne0>[0-9]+),1,1,1 "
        r"dst_nb=4,(?P<dst_nb1>[0-9]+),(?P<dst_nb2>[0-9]+),(?P<dst_nb3>[0-9]+) "
        r"src0_type=f32 src0_ne=(?P<src_ne0>[0-9]+),1,1,1 "
        r"src0_nb=4,(?P<src_nb1>[0-9]+),(?P<src_nb2>[0-9]+),(?P<src_nb3>[0-9]+) "
        r"supported=1$"
    )

    def cache_scale_identity(
        descriptor: str, *, zero: bool
    ) -> tuple[str, int, str] | None:
        match = cache_scale_re.fullmatch(descriptor)
        if match is None:
            return None
        kind = match.group("kind")
        layer = int(match.group("layer"))
        if layer not in QWEN_RECURRENT_LAYERS:
            return None
        full_ne0 = 18_432 if kind == "r" else 262_144
        full_nb1 = 73_728 if kind == "r" else 1_048_576
        expected_ne0 = 0 if zero else full_ne0
        expected_nb = (0, 0, 0) if zero else (full_nb1, full_nb1, full_nb1)
        actual = (
            int(match.group("dst_ne0")),
            int(match.group("src_ne0")),
            int(match.group("dst_nb1")),
            int(match.group("dst_nb2")),
            int(match.group("dst_nb3")),
            int(match.group("src_nb1")),
            int(match.group("src_nb2")),
            int(match.group("src_nb3")),
        )
        expected = (
            expected_ne0,
            expected_ne0,
            *expected_nb,
            *expected_nb,
        )
        if actual != expected:
            return None
        return kind, layer, match.group("canonical_id")

    bootstrap = manifests[("reserve", 1)]
    bootstrap_keys = set(bootstrap)
    for key in (("reserve", 2), ("reserve", 3), ("dispatch", 4)):
        if manifests[key] != bootstrap:
            die(f"bootstrap manifest node-index/descriptor mapping changed in {key}")

    steady: dict[int, tuple[str, str, int]] | None = None
    if expected_dispatches > 1:
        steady = manifests[("dispatch", 5)]
        if set(steady) != bootstrap_keys:
            die("steady manifest node-index set changed from bootstrap")
        changed = sorted(
            node for node in bootstrap_keys if bootstrap[node] != steady[node]
        )
        if len(changed) != 36:
            die(f"steady manifest delta is {len(changed)}, expected 36 SCALE nodes")
        seen_cache_owners: set[tuple[str, int]] = set()
        for node in changed:
            bootstrap_id, bootstrap_descriptor, bootstrap_supported = bootstrap[node]
            steady_id, steady_descriptor, steady_supported = steady[node]
            before = cache_scale_identity(bootstrap_descriptor, zero=False)
            after = cache_scale_identity(steady_descriptor, zero=True)
            if (before is None or after is None or before != after or
                    bootstrap_id != steady_id or
                    bootstrap_id != before[2] or
                    bootstrap_supported != 1 or steady_supported != 1):
                die(f"invalid bootstrap-to-steady SCALE delta at node {node}")
            seen_cache_owners.add((before[0], before[1]))
        expected_cache_owners = {
            (kind, layer)
            for kind in ("r", "s")
            for layer in QWEN_RECURRENT_LAYERS
        }
        if seen_cache_owners != expected_cache_owners:
            die(
                "steady zero SCALE owner census is not the frozen "
                f"cache_r/cache_s recurrent layer set {QWEN_RECURRENT_LAYERS}"
            )
        for dispatch in range(3, expected_dispatches + 1):
            key = ("dispatch", dispatch + 3)
            if manifests[key] != steady:
                die(f"steady manifest drifted after dispatch 2 in {key}")

    strict_lines = [line for line in lines if line.startswith("[NPU-STRICT][PASS]")]
    ledger_lines = [line for line in lines if line.startswith("[NPU-SYSTEM-LEDGER][PASS]")]
    functional_lines = [
        line for line in lines
        if line.startswith("[NPU-FUNCTIONAL-COMMAND-LEDGER][PASS]")
    ]
    raw32_lines = [
        line for line in lines
        if line.startswith("[NPU-RAW32-PORTAL-LEDGER][PASS]")
    ]
    sampler_argmax_lines = [
        line for line in lines
        if line.startswith("[NPU-SAMPLER-ARGMAX-LEDGER][PASS]")
    ]
    if not strict_lines or len(strict_lines) != dispatch_preflights:
        die(
            f"strict PASS count {len(strict_lines)} does not match dispatch "
            f"preflights {dispatch_preflights}"
        )

    strict_by_dispatch: dict[int, dict[str, int]] = {}
    for line in strict_lines:
        strict_required = (
            "dispatch", "required_seen", "assigned", "required_enqueued",
            "required_completed", "executed", "commands_accepted",
            "completion_success", "completion_failure", "coverage_missing",
            "coverage_duplicate", "coverage_hash_mismatch",
            "completion_identity_mismatch", "unsupported", "rtl_failures",
            "gmem_errors", "timeout_errors", "cpu_fallback_attempts",
            "host_tensor_arithmetic", "rtl_cycles", "gmem_read_bytes",
            "gmem_write_bytes", "vector_elements",
        )
        values = fields(
            line, "[NPU-STRICT][PASS]", strict_required, "NPU-STRICT PASS"
        )
        dispatch = values["dispatch"]
        if dispatch == 0 or dispatch in strict_by_dispatch:
            die(f"invalid/duplicate strict dispatch: {dispatch}")
        n = values["required_seen"]
        equal_n = (
            "assigned", "required_enqueued", "required_completed", "executed",
            "commands_accepted", "completion_success",
        )
        zero = (
            "completion_failure", "coverage_missing", "coverage_duplicate",
            "coverage_hash_mismatch", "completion_identity_mismatch", "unsupported",
            "rtl_failures", "gmem_errors", "timeout_errors",
            "cpu_fallback_attempts", "host_tensor_arithmetic",
        )
        if n != REQUIRED_PER_DISPATCH or any(values[key] != n for key in equal_n):
            die(f"strict required ledger mismatch dispatch={dispatch}: {values}")
        if any(values[key] != 0 for key in zero):
            die(f"strict error/fallback counter is nonzero dispatch={dispatch}: {values}")
        if any(values[key] <= 0 for key in (
            "rtl_cycles", "gmem_read_bytes", "gmem_write_bytes",
            "vector_elements",
        )):
            die(f"strict work counters are not positive dispatch={dispatch}: {values}")
        strict_by_dispatch[dispatch] = values

    ledger_by_dispatch: dict[int, dict[str, int]] = {}
    for line in ledger_lines:
        ledger_required = (
            "dispatch", "system_transactions", "required_seen",
            "system_cycles", "rtl_cycles", "cpu_config_commands",
            "cpu_tensor_commands", "cpu_terminals", "cpu_config_commits",
            "cpu_launch_commits", "public_commands", "public_completions",
            "public_errors", "required_issued", "required_completed",
            "cpu_pid_identity_mismatch", "macro_identity_mismatch",
            "cpu_memory_separate", "first_request_hold_cycles",
            "expected_first_request_hold_cycles", "q8_portal_transactions",
            "q8_portal_expected_transactions",
            "q8_portal_requests", "q8_portal_responses", "q8_portal_blocks",
            "q8_portal_bytes", "q8_portal_raw_copy_bytes",
            "q8_portal_first_hold_cycles", "q8_portal_expected_first_holds",
            "q8_portal_expected_requests",
            "q8_portal_expected_blocks", "q8_portal_expected_bytes",
            "q8_portal_protocol_errors", "q8_portal_latency_mismatches",
            "q8_portal_payload_stability_mismatches",
        )
        values = fields(
            line,
            "[NPU-SYSTEM-LEDGER][PASS]",
            ledger_required,
            "NPU-SYSTEM-LEDGER PASS",
        )
        dispatch = values["dispatch"]
        if dispatch == 0 or dispatch in ledger_by_dispatch:
            die(f"invalid/duplicate System ledger dispatch: {dispatch}")
        n = values["required_seen"]
        expected = {
            "system_transactions": n,
            "cpu_config_commands": 30 * n,
            "cpu_tensor_commands": 31 * n,
            "cpu_terminals": 31 * n,
            "cpu_config_commits": 30 * n,
            "cpu_launch_commits": n,
            "public_commands": n,
            "public_completions": n,
            "public_errors": 0,
            "required_issued": n,
            "required_completed": n,
            "cpu_pid_identity_mismatch": 0,
            "macro_identity_mismatch": 0,
            "cpu_memory_separate": n,
        }
        if (n != REQUIRED_PER_DISPATCH or
                any(values[key] != value for key, value in expected.items())):
            die(f"System transport ledger mismatch dispatch={dispatch}: {values}")
        if values["system_cycles"] <= 0 or values["rtl_cycles"] <= 0:
            die(f"System/RTL cycle counters are not positive dispatch={dispatch}")
        if (values["first_request_hold_cycles"] !=
                values["expected_first_request_hold_cycles"] or
                values["first_request_hold_cycles"] <= 0):
            die(f"System GMEM first-hold mismatch dispatch={dispatch}: {values}")
        q8_expected_transactions = FROZEN_PORTAL_OWNER_TRANSACTIONS["q8_gemv"]
        q8_zero = (
            "q8_portal_protocol_errors", "q8_portal_latency_mismatches",
            "q8_portal_payload_stability_mismatches",
        )
        if (values["q8_portal_transactions"] != q8_expected_transactions or
                values["q8_portal_expected_transactions"] !=
                    q8_expected_transactions or
                values["q8_portal_requests"] !=
                    values["q8_portal_expected_requests"] or
                values["q8_portal_responses"] !=
                    values["q8_portal_expected_requests"] or
                values["q8_portal_blocks"] !=
                    values["q8_portal_expected_blocks"] or
                values["q8_portal_bytes"] !=
                    values["q8_portal_expected_bytes"] or
                values["q8_portal_raw_copy_bytes"] !=
                    values["q8_portal_expected_bytes"] or
                values["q8_portal_first_hold_cycles"] !=
                    values["q8_portal_expected_first_holds"] or
                values["q8_portal_expected_first_holds"] >
                    values["q8_portal_transactions"] or
                values["q8_portal_bytes"] != values["q8_portal_blocks"] * 34 or
                any(values[key] != 0 for key in q8_zero) or
                any(values[key] <= 0 for key in (
                    "q8_portal_requests", "q8_portal_blocks", "q8_portal_bytes",
                ))):
            die(f"Q8 pure-RTL portal ledger mismatch dispatch={dispatch}: {values}")
        ledger_by_dispatch[dispatch] = values

    sampler_argmax_by_dispatch: dict[int, dict[str, int]] = {}
    for line in sampler_argmax_lines:
        values = fields(
            line,
            "[NPU-SAMPLER-ARGMAX-LEDGER][PASS]",
            ("dispatch", *SAMPLER_ARGMAX_PER_DISPATCH),
            "NPU-SAMPLER-ARGMAX-LEDGER PASS",
        )
        dispatch = values["dispatch"]
        if dispatch == 0 or dispatch in sampler_argmax_by_dispatch:
            die(f"invalid/duplicate sampler ARGMAX ledger dispatch: {dispatch}")
        mismatches = {
            key: (values[key], expected)
            for key, expected in SAMPLER_ARGMAX_PER_DISPATCH.items()
            if values[key] != expected
        }
        if mismatches:
            die(
                f"sampler ARGMAX ledger mismatch dispatch={dispatch}: "
                f"{mismatches}"
            )
        sampler_argmax_by_dispatch[dispatch] = values

    functional_by_dispatch: dict[int, dict[str, int]] = {}
    for line in functional_lines:
        functional_required = (
            "dispatch", "command_dispatches", "command_completions",
            "successes", "failures", "read_words", "write_words",
            "read_bytes", "write_bytes", "q8_blocks", "q8_macs",
            "vector_elements", "expected_read_words",
            "expected_write_words", "expected_read_bytes",
            "expected_write_bytes", "expected_q8_blocks",
            "expected_q8_macs", "expected_vector_elements",
            "callback_read_calls", "callback_write_calls",
            "callback_read_bytes", "callback_write_bytes", "callback_errors",
            "command_mismatches", "protocol_errors", "old_gmem_requests",
            "old_gmem_responses", "old_q8_portal_transactions",
            "old_f32_alu_portal_transactions",
            "old_f32_mover_portal_transactions",
        )
        values = fields(
            line,
            "[NPU-FUNCTIONAL-COMMAND-LEDGER][PASS]",
            functional_required,
            "NPU-FUNCTIONAL-COMMAND-LEDGER PASS",
        )
        dispatch = values["dispatch"]
        if dispatch == 0 or dispatch in functional_by_dispatch:
            die(f"invalid/duplicate functional command dispatch: {dispatch}")
        # This marker is a tripwire for the removed host-side Command-DPI compute
        # path.  Dispatch is marker identity; every other printed numeric field,
        # including any field added later, must remain exactly zero.
        nonidentity_values = {
            key: value for key, value in values.items() if key != "dispatch"
        }
        if any(value != 0 for value in nonidentity_values.values()):
            die(f"functional command path is not quiescent dispatch={dispatch}: {values}")
        functional_by_dispatch[dispatch] = values

    raw32_by_dispatch_owner: dict[tuple[int, str], dict[str, int]] = {}
    raw32_owner_re = re.compile(
        r"^\[NPU-RAW32-PORTAL-LEDGER\]\[PASS\] "
        r"owner=(f32_alu|f32_mover)(?: |$)"
    )
    raw32_required = (
        "dispatch", "transactions", "expected_transactions",
        "request_groups", "response_groups",
        "read_groups", "write_groups", "read_words", "write_words",
        "read_bytes", "write_bytes", "raw_read_copy_bytes",
        "raw_write_copy_bytes", "first_hold_cycles", "expected_first_holds",
        "expected_request_groups", "expected_response_groups",
        "expected_read_groups", "expected_write_groups", "expected_read_words",
        "expected_write_words", "expected_read_bytes", "expected_write_bytes",
        "protocol_errors", "latency_mismatches",
        "payload_stability_mismatches",
    )
    for line in raw32_lines:
        owner_match = raw32_owner_re.match(line)
        if owner_match is None:
            die(f"malformed raw32 owner marker: {line}")
        owner = owner_match.group(1)
        values = fields(
            line,
            f"[NPU-RAW32-PORTAL-LEDGER][PASS] owner={owner}",
            raw32_required,
            "NPU-RAW32-PORTAL-LEDGER PASS",
        )
        dispatch = values["dispatch"]
        key = (dispatch, owner)
        if dispatch == 0 or key in raw32_by_dispatch_owner:
            die(f"invalid/duplicate raw32 portal ledger: {key}")
        expected_transactions = FROZEN_PORTAL_OWNER_TRANSACTIONS[owner]
        actual_expected = (
            ("transactions", "expected_transactions"),
            ("request_groups", "expected_request_groups"),
            ("response_groups", "expected_response_groups"),
            ("read_groups", "expected_read_groups"),
            ("write_groups", "expected_write_groups"),
            ("read_words", "expected_read_words"),
            ("write_words", "expected_write_words"),
            ("read_bytes", "expected_read_bytes"),
            ("write_bytes", "expected_write_bytes"),
        )
        error_fields = (
            "protocol_errors", "latency_mismatches",
            "payload_stability_mismatches",
        )
        if (values["transactions"] != expected_transactions or
                values["expected_transactions"] != expected_transactions or
                any(values[actual] != values[expected]
                    for actual, expected in actual_expected) or
                values["response_groups"] != values["request_groups"] or
                values["request_groups"] !=
                    values["read_groups"] + values["write_groups"] or
                values["read_bytes"] != values["read_words"] * 4 or
                values["write_bytes"] != values["write_words"] * 4 or
                values["raw_read_copy_bytes"] != values["expected_read_bytes"] or
                values["raw_write_copy_bytes"] !=
                    values["expected_write_bytes"] or
                values["first_hold_cycles"] != values["expected_first_holds"] or
                values["expected_first_holds"] > values["transactions"] or
                any(values[field] != 0 for field in error_fields) or
                any(values[field] <= 0 for field in (
                    "request_groups", "read_words", "write_words",
                    "read_bytes", "write_bytes",
                ))):
            die(f"pure-RTL raw32 portal ledger mismatch {key}: {values}")
        if owner == "f32_alu":
            expected_first_holds = (
                F32_ALU_BOOTSTRAP_FIRST_HOLDS
                if dispatch == 1 else F32_ALU_STEADY_FIRST_HOLDS
            )
            expected_read_bytes = (
                F32_ALU_BOOTSTRAP_RAW_READ_BYTES
                if dispatch == 1 else F32_ALU_STEADY_RAW_READ_BYTES
            )
            expected_write_bytes = (
                F32_ALU_BOOTSTRAP_RAW_WRITE_BYTES
                if dispatch == 1 else F32_ALU_STEADY_RAW_WRITE_BYTES
            )
            if (values["first_hold_cycles"] != expected_first_holds or
                    values["raw_read_copy_bytes"] != expected_read_bytes or
                    values["raw_write_copy_bytes"] != expected_write_bytes):
                die(f"F32 ALU bootstrap/steady ledger mismatch {key}: {values}")
        raw32_by_dispatch_owner[key] = values

    dispatch_ids = set(strict_by_dispatch)
    expected_dispatch_ids = set(range(1, expected_dispatches + 1))
    if dispatch_ids != expected_dispatch_ids:
        die(
            f"strict dispatch IDs are not contiguous 1..{expected_dispatches}: "
            f"{sorted(dispatch_ids)}"
        )
    if (dispatch_ids != set(ledger_by_dispatch) or
            dispatch_ids != set(functional_by_dispatch) or
            dispatch_ids != set(sampler_argmax_by_dispatch)):
        die("strict/System/functional/sampler-ARGMAX dispatch ID sets differ")
    expected_raw32_keys = {
        (dispatch, owner)
        for dispatch in dispatch_ids
        for owner in ("f32_alu", "f32_mover")
    }
    if set(raw32_by_dispatch_owner) != expected_raw32_keys:
        die("raw32 portal owner/dispatch set is not exactly two pure-RTL owners")

    for dispatch in sorted(dispatch_ids):
        strict = strict_by_dispatch[dispatch]
        system = ledger_by_dispatch[dispatch]
        f32_alu = raw32_by_dispatch_owner[(dispatch, "f32_alu")]
        f32_mover = raw32_by_dispatch_owner[(dispatch, "f32_mover")]
        portal_owned = (system["q8_portal_transactions"] +
                        f32_alu["transactions"] + f32_mover["transactions"])
        if (strict["rtl_cycles"] != system["rtl_cycles"] or
                strict["commands_accepted"] != system["public_commands"] or
                strict["completion_success"] != system["public_completions"] or
                strict["required_enqueued"] != system["required_issued"] or
                strict["required_completed"] != system["required_completed"] or
                strict["required_seen"] - portal_owned !=
                    FROZEN_NONPORTAL_REQUIRED or
                strict["vector_elements"] <
                    f32_alu["write_words"] + f32_mover["write_words"]):
            die(f"cross-marker ledger mismatch dispatch={dispatch}")

        # strict.gmem_read_bytes is the semantic tensor payload seen by the NPU
        # command engine. q8_portal_raw_copy_bytes is physical portal traffic and
        # includes the frozen block/lane expansion, so the latter is intentionally
        # much larger and must not be ordered against the semantic byte counter.
        # Each quantity is already checked against its own exact expected ledger.

    dispatches = len(strict_by_dispatch)
    steady_dispatches = dispatches - 1
    f32_alu_bootstrap = raw32_by_dispatch_owner[(1, "f32_alu")]
    f32_alu_steady = [
        raw32_by_dispatch_owner[(dispatch, "f32_alu")]
        for dispatch in range(2, dispatches + 1)
    ]
    f32_alu_bootstrap_owner_transactions = f32_alu_bootstrap["transactions"]
    f32_alu_bootstrap_zero_transactions = 0
    f32_alu_bootstrap_nonempty_commands = f32_alu_bootstrap["first_hold_cycles"]
    f32_alu_bootstrap_raw_read_bytes = f32_alu_bootstrap["raw_read_copy_bytes"]
    f32_alu_bootstrap_raw_write_bytes = f32_alu_bootstrap["raw_write_copy_bytes"]
    f32_alu_steady_owner_transactions = sum(
        values["transactions"] for values in f32_alu_steady
    )
    f32_alu_steady_zero_transactions = (
        F32_ALU_ZERO_TRANSACTIONS_PER_STEADY_DISPATCH * steady_dispatches
    )
    f32_alu_steady_nonempty_commands = sum(
        values["first_hold_cycles"] for values in f32_alu_steady
    )
    f32_alu_steady_raw_read_bytes = sum(
        values["raw_read_copy_bytes"] for values in f32_alu_steady
    )
    f32_alu_steady_raw_write_bytes = sum(
        values["raw_write_copy_bytes"] for values in f32_alu_steady
    )
    if (
        f32_alu_bootstrap_owner_transactions
        != f32_alu_bootstrap_zero_transactions
        + f32_alu_bootstrap_nonempty_commands
        or f32_alu_steady_owner_transactions
        != f32_alu_steady_zero_transactions
        + f32_alu_steady_nonempty_commands
        or f32_alu_bootstrap_raw_read_bytes
        != F32_ALU_BOOTSTRAP_RAW_READ_BYTES
        or f32_alu_bootstrap_raw_write_bytes
        != F32_ALU_BOOTSTRAP_RAW_WRITE_BYTES
        or f32_alu_steady_raw_read_bytes
        != F32_ALU_STEADY_RAW_READ_BYTES * steady_dispatches
        or f32_alu_steady_raw_write_bytes
        != F32_ALU_STEADY_RAW_WRITE_BYTES * steady_dispatches
    ):
        die("F32 ALU bootstrap/steady phase totals do not close")
    f32_alu_first_holds = (
        f32_alu_bootstrap_nonempty_commands + f32_alu_steady_nonempty_commands
    )
    f32_alu_owner_transactions = (
        f32_alu_bootstrap_owner_transactions + f32_alu_steady_owner_transactions
    )
    f32_alu_zero_transactions = (
        f32_alu_bootstrap_zero_transactions + f32_alu_steady_zero_transactions
    )
    f32_alu_raw_read_bytes = (
        f32_alu_bootstrap_raw_read_bytes + f32_alu_steady_raw_read_bytes
    )
    f32_alu_raw_write_bytes = (
        f32_alu_bootstrap_raw_write_bytes + f32_alu_steady_raw_write_bytes
    )
    if (
        f32_alu_owner_transactions
        != F32_ALU_TRANSACTIONS_PER_DISPATCH * dispatches
        or f32_alu_zero_transactions
        != F32_ALU_ZERO_TRANSACTIONS_PER_STEADY_DISPATCH * steady_dispatches
        or f32_alu_first_holds
        != F32_ALU_BOOTSTRAP_FIRST_HOLDS
        + F32_ALU_STEADY_FIRST_HOLDS * steady_dispatches
    ):
        die("F32 ALU aggregate phase partition does not close")
    summary = {
        "preflight_cohorts": len(begins),
        "dispatches": dispatches,
        "bootstrap_dispatches": 1,
        "steady_dispatches": steady_dispatches,
        "required_per_dispatch": REQUIRED_PER_DISPATCH,
        "system_transactions": REQUIRED_PER_DISPATCH * dispatches,
        "cpu_config_commands": 30 * REQUIRED_PER_DISPATCH * dispatches,
        "cpu_tensor_commands": 31 * REQUIRED_PER_DISPATCH * dispatches,
        "cpu_terminals": 31 * REQUIRED_PER_DISPATCH * dispatches,
        "public_commands": REQUIRED_PER_DISPATCH * dispatches,
        "public_completions": REQUIRED_PER_DISPATCH * dispatches,
        "required_issued": REQUIRED_PER_DISPATCH * dispatches,
        "required_completed": REQUIRED_PER_DISPATCH * dispatches,
        "sampler_argmax_dispatches": len(sampler_argmax_by_dispatch),
        "sampler_argmax_transactions": sum(
            values["transactions"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_transactions_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["transactions"],
        "sampler_argmax_elements": sum(
            values["elements"] for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_elements_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["elements"],
        "sampler_argmax_read_bytes": sum(
            values["read_bytes"] for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_read_bytes_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["read_bytes"],
        "sampler_argmax_scalar_write_bytes": sum(
            values["scalar_write_bytes"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_scalar_write_bytes_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["scalar_write_bytes"],
        "sampler_argmax_sampled_tokens": sum(
            values["sampled_tokens"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_sampled_tokens_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["sampled_tokens"],
        "sampler_argmax_host_scalar_copy_bytes": sum(
            values["host_scalar_copy_bytes"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_host_scalar_copy_bytes_per_dispatch":
            SAMPLER_ARGMAX_PER_DISPATCH["host_scalar_copy_bytes"],
        "sampler_argmax_full_vocab_host_exports": sum(
            values["full_vocab_host_exports"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_full_vocab_host_export_bytes": sum(
            values["full_vocab_host_export_bytes"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_cpu_candidate_scans": sum(
            values["cpu_candidate_scans"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "sampler_argmax_invalid_tokens": sum(
            values["invalid_tokens"]
            for values in sampler_argmax_by_dispatch.values()
        ),
        "f32_alu_bootstrap_owner_transactions":
            f32_alu_bootstrap_owner_transactions,
        "f32_alu_bootstrap_zero_cardinality_transactions":
            f32_alu_bootstrap_zero_transactions,
        "f32_alu_bootstrap_nonempty_portal_commands":
            f32_alu_bootstrap_nonempty_commands,
        "f32_alu_bootstrap_portal_raw_read_copy_bytes":
            f32_alu_bootstrap_raw_read_bytes,
        "f32_alu_bootstrap_portal_raw_write_copy_bytes":
            f32_alu_bootstrap_raw_write_bytes,
        "f32_alu_steady_owner_transactions": f32_alu_steady_owner_transactions,
        "f32_alu_steady_zero_cardinality_transactions":
            f32_alu_steady_zero_transactions,
        "f32_alu_steady_nonempty_portal_commands":
            f32_alu_steady_nonempty_commands,
        "f32_alu_steady_portal_raw_read_copy_bytes":
            f32_alu_steady_raw_read_bytes,
        "f32_alu_steady_portal_raw_write_copy_bytes":
            f32_alu_steady_raw_write_bytes,
        "f32_alu_owner_transactions": f32_alu_owner_transactions,
        "f32_alu_zero_cardinality_transactions": f32_alu_zero_transactions,
        "f32_alu_nonempty_portal_commands": f32_alu_first_holds,
        "f32_alu_portal_first_hold_cycles": f32_alu_first_holds,
        "q8_gemv_owner_transactions": sum(
            values["q8_portal_transactions"] for values in ledger_by_dispatch.values()
        ),
        "f32_mover_owner_transactions": sum(
            raw32_by_dispatch_owner[(dispatch, "f32_mover")]["transactions"]
            for dispatch in strict_by_dispatch
        ),
        "nonportal_required": FROZEN_NONPORTAL_REQUIRED * dispatches,
        "q8_portal_raw_copy_bytes": sum(
            values["q8_portal_raw_copy_bytes"]
            for values in ledger_by_dispatch.values()
        ),
        "f32_alu_portal_raw_read_copy_bytes": f32_alu_raw_read_bytes,
        "f32_alu_portal_raw_write_copy_bytes": f32_alu_raw_write_bytes,
        "f32_mover_portal_raw_read_copy_bytes": sum(
            raw32_by_dispatch_owner[(dispatch, "f32_mover")]["raw_read_copy_bytes"]
            for dispatch in strict_by_dispatch
        ),
        "f32_mover_portal_raw_write_copy_bytes": sum(
            raw32_by_dispatch_owner[(dispatch, "f32_mover")]["raw_write_copy_bytes"]
            for dispatch in strict_by_dispatch
        ),
        "functional_command_dispatches": sum(
            values["command_dispatches"] for values in functional_by_dispatch.values()
        ),
        "functional_command_completions": sum(
            values["command_completions"] for values in functional_by_dispatch.values()
        ),
        "functional_read_bytes": sum(
            values["read_bytes"] for values in functional_by_dispatch.values()
        ),
        "functional_write_bytes": sum(
            values["write_bytes"] for values in functional_by_dispatch.values()
        ),
        "functional_q8_blocks": sum(
            values["q8_blocks"] for values in functional_by_dispatch.values()
        ),
        "functional_q8_macs": sum(
            values["q8_macs"] for values in functional_by_dispatch.values()
        ),
        "functional_vector_elements": sum(
            values["vector_elements"] for values in functional_by_dispatch.values()
        ),
        "old_gmem_requests": sum(
            values["old_gmem_requests"] for values in functional_by_dispatch.values()
        ),
        "old_gmem_responses": sum(
            values["old_gmem_responses"] for values in functional_by_dispatch.values()
        ),
        "old_q8_portal_transactions": sum(
            values["old_q8_portal_transactions"]
            for values in functional_by_dispatch.values()
        ),
        "old_f32_alu_portal_transactions": sum(
            values["old_f32_alu_portal_transactions"]
            for values in functional_by_dispatch.values()
        ),
        "old_f32_mover_portal_transactions": sum(
            values["old_f32_mover_portal_transactions"]
            for values in functional_by_dispatch.values()
        ),
    }
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    marker = (
        "[NPU-STRICT-LEDGER][PASS] "
        + " ".join(f"{key}={value}" for key, value in summary.items())
    )
    return summary, marker



def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate a strict Qwen NPU run log and write its ledger summary."
    )
    parser.add_argument("run_log", type=pathlib.Path)
    parser.add_argument("summary_json", type=pathlib.Path)
    parser.add_argument("expected_dispatches", type=int)
    args = parser.parse_args(argv)
    _, marker = validate_strict_log(
        args.run_log, args.summary_json, args.expected_dispatches
    )
    print(marker)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
