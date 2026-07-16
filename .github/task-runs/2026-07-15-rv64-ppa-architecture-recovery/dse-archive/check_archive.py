#!/usr/bin/env python3
"""Fail-closed checker for the non-normative RV64 DSE archive companion."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path, PurePosixPath
from typing import Any


REGISTRY_SCHEMA = "rv64-dse-archive-registry-v1"
POINT_SCHEMA = "rv64-dse-design-point-v1"
INVENTORY_SCHEMA = "rv64-required-test-inventory-v1"
EVENT_SCHEMA = "rv64-dse-ledger-event-v1"
POOLS = ("feasible_pareto", "development", "high_uncertainty", "diversity")
GATES = (
    "functional_correctness",
    "full_dual_issue",
    "full_ooo",
    "precise_exception_recovery",
    "real_dual_memory_datapath",
    "di_1_frontend_ii1",
    "di_2_width_continuity",
    "di_3_pair_matrix",
    "di_4_no_static_lane_semantics",
    "di_5_dual_memory_issue",
    "ooo_1_true_ooo_long_latency",
    "ooo_2_selective_scheduling",
    "ooo_3_memory_ordering",
    "ooo_4_speculation_recovery",
    "exact_5ns_200mhz",
)
EVALUATION_ORDER = (
    "same_design_provenance",
    "functional_hard_gates",
    "architecture_hard_gates",
    "exact_5ns_timing",
    "per_workload_worst_case",
    "area_and_power_qualification",
    "pareto_comparison",
    "scalar_order_within_front",
    "normative_promotion",
)
BRANCH_ROLES = {
    "performance_branch",
    "area_timing_branch",
    "power_branch",
    "global_thaw_combined",
}
THAW_BLOCKS = {
    "frontend_width_fetch_queue_predictor",
    "rob_prf_iq_commit_width",
    "dual_agu_translation_lsq_cache_banks_mshr",
    "issue_width_fu_ports_bypass",
}
SHA_RE = re.compile(r"^[0-9a-f]{64}$")


class DuplicateKey(ValueError):
    pass


def _pairs_no_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in pairs:
        if key in out:
            raise DuplicateKey(f"duplicate JSON key: {key}")
        out[key] = value
    return out


def load_json(path: Path) -> Any:
    def reject_constant(value: str) -> None:
        raise ValueError(f"non-finite JSON number: {value}")

    return json.loads(
        path.read_text(encoding="utf-8"),
        object_pairs_hook=_pairs_no_duplicates,
        parse_constant=reject_constant,
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def event_sha(event: dict[str, Any]) -> str:
    body = dict(event)
    body.pop("event_sha256", None)
    encoded = json.dumps(
        body, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def find_workspace_root(start: Path) -> Path:
    for candidate in (start, *start.parents):
        if (candidate / ".git").exists():
            return candidate.resolve()
    raise ValueError(f"cannot find workspace root above {start}")


class Checker:
    def __init__(self, registry_path: Path, workspace_root: Path | None = None):
        self.registry_path = registry_path.resolve()
        self.root = (workspace_root or find_workspace_root(self.registry_path.parent)).resolve()
        self.errors: list[str] = []
        self.required_workloads: dict[str, dict[str, Any]] = {}
        self.contract_test_count = 0
        self.inventory_drift = True

    def error(self, message: str) -> None:
        self.errors.append(message)

    def path(self, relative: Any, context: str) -> Path | None:
        if not isinstance(relative, str) or not relative:
            self.error(f"{context}: path must be a non-empty string")
            return None
        pure = PurePosixPath(relative)
        if pure.is_absolute() or ".." in pure.parts:
            self.error(f"{context}: path must be workspace-relative without '..': {relative!r}")
            return None
        candidate = self.root.joinpath(*pure.parts)
        try:
            resolved = candidate.resolve(strict=False)
            resolved.relative_to(self.root)
        except (OSError, ValueError):
            self.error(f"{context}: path escapes workspace: {relative!r}")
            return None
        cursor = self.root
        for part in pure.parts:
            cursor = cursor / part
            if cursor.is_symlink():
                self.error(f"{context}: symlinks are forbidden: {relative!r}")
                return None
        return candidate

    def file_ref(self, ref: Any, context: str, content_addressed: bool = False) -> Path | None:
        if not isinstance(ref, dict):
            self.error(f"{context}: expected file reference object")
            return None
        sha = ref.get("sha256")
        if not isinstance(sha, str) or not SHA_RE.fullmatch(sha):
            self.error(f"{context}: invalid lowercase SHA-256")
            return None
        path = self.path(ref.get("path"), context)
        if path is None:
            return None
        if not path.is_file():
            self.error(f"{context}: referenced regular file is missing: {ref.get('path')}")
            return None
        actual = sha256_file(path)
        if actual != sha:
            self.error(f"{context}: SHA-256 mismatch: expected {sha}, got {actual}")
        if content_addressed and not path.name.startswith(f"{sha}."):
            self.error(f"{context}: filename must start with its content SHA-256")
        return path

    def check_bindings(self, registry: dict[str, Any]) -> None:
        bindings = registry.get("bindings")
        if not isinstance(bindings, list) or not bindings:
            self.error("bindings: at least one immutable input/contract binding is required")
            return
        roles: set[str] = set()
        for index, binding in enumerate(bindings):
            context = f"bindings[{index}]"
            if not isinstance(binding, dict):
                self.error(f"{context}: expected object")
                continue
            role = binding.get("role")
            if not isinstance(role, str) or not role or role in roles:
                self.error(f"{context}: role must be non-empty and unique")
            else:
                roles.add(role)
            self.file_ref(binding, context)

    @staticmethod
    def derive_make_tests(makefile: Path) -> list[str]:
        lines = makefile.read_text(encoding="utf-8").splitlines()
        tests: list[str] = []
        collecting = False
        for line in lines:
            if not collecting:
                if re.match(r"^TESTS\s*:=", line):
                    collecting = True
                    tail = line.split(":=", 1)[1]
                else:
                    continue
            else:
                tail = line
            clean = tail.split("#", 1)[0].strip()
            continuation = clean.endswith("\\")
            clean = clean[:-1].strip() if continuation else clean
            if clean:
                tests.extend(clean.split())
            if collecting and not continuation:
                break
        if not tests:
            raise ValueError("TESTS := block not found or empty")
        if len(tests) != len(set(tests)):
            raise ValueError("TESTS := block contains duplicate names")
        return tests

    def check_inventory_contract(self, registry: dict[str, Any]) -> None:
        config = registry.get("required_test_inventory_contract")
        if not isinstance(config, dict):
            self.error("required_test_inventory_contract: expected object")
            return
        policy_path = self.file_ref(config.get("normative_policy"), "inventory normative_policy")
        makefile_path = self.file_ref(config.get("development_makefile"), "inventory development_makefile")
        if policy_path is None or makefile_path is None:
            return
        try:
            policy = load_json(policy_path)
            actual_contract = policy["functional"]["module_required"]
            tests = self.derive_make_tests(makefile_path)
        except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
            self.error(f"required_test_inventory_contract: cannot derive counts: {exc}")
            return
        stated_contract = config.get("contract_required_count")
        stated_dev = config.get("development_derived_count")
        if stated_contract != actual_contract:
            self.error(
                f"required_test_inventory_contract: contract count {stated_contract!r} != policy {actual_contract!r}"
            )
        if stated_dev != len(tests):
            self.error(
                f"required_test_inventory_contract: development count {stated_dev!r} != derived {len(tests)}"
            )
        self.contract_test_count = int(actual_contract)
        self.inventory_drift = actual_contract != len(tests)
        if config.get("drift_blocker_active") is not self.inventory_drift:
            self.error("required_test_inventory_contract: drift_blocker_active does not match derived drift")

    def check_ledger(self, registry: dict[str, Any]) -> tuple[dict[str, dict[str, Any]], int, bool, str | None]:
        ledger_meta = registry.get("ledger")
        if not isinstance(ledger_meta, dict):
            self.error("ledger: expected object")
            return {}, 0, False, None
        ledger_path = self.file_ref(ledger_meta, "ledger")
        if ledger_path is None:
            return {}, 0, False, None
        events: list[dict[str, Any]] = []
        try:
            for line_no, raw in enumerate(ledger_path.read_text(encoding="utf-8").splitlines(), 1):
                if not raw.strip():
                    self.error(f"ledger:{line_no}: blank lines are forbidden")
                    continue
                event = json.loads(
                    raw,
                    object_pairs_hook=_pairs_no_duplicates,
                    parse_constant=lambda value: (_ for _ in ()).throw(
                        ValueError(f"non-finite JSON number: {value}")
                    ),
                )
                if not isinstance(event, dict):
                    self.error(f"ledger:{line_no}: event must be an object")
                    continue
                events.append(event)
        except (ValueError, json.JSONDecodeError) as exc:
            self.error(f"ledger: invalid JSONL: {exc}")
        by_hash: dict[str, dict[str, Any]] = {}
        previous: str | None = None
        completed_since_thaw = 0
        completed_ids: set[str] = set()
        last_thaw: str | None = None
        k = registry.get("global_thaw", {}).get("k_completed_points")
        if k != 4:
            self.error("global_thaw.k_completed_points must be exactly 4")
            k = 4
        for sequence, event in enumerate(events):
            context = f"ledger event {sequence}"
            if event.get("event_schema") != EVENT_SCHEMA:
                self.error(f"{context}: wrong event_schema")
            if event.get("sequence") != sequence:
                self.error(f"{context}: sequence must be contiguous from zero")
            if event.get("previous_event_sha256") != previous:
                self.error(f"{context}: previous_event_sha256 breaks the append chain")
            actual = event_sha(event)
            if event.get("event_sha256") != actual:
                self.error(f"{context}: event_sha256 mismatch")
            if actual in by_hash:
                self.error(f"{context}: duplicate event hash")
            by_hash[actual] = event
            event_type = event.get("event_type")
            if sequence == 0 and event_type != "archive_initialized":
                self.error("ledger event 0 must be archive_initialized")
            if completed_since_thaw == k and event_type != "global_thaw_opened":
                self.error(f"{context}: global thaw is due before another ledger event")
            design_id = event.get("design_id")
            if event_type == "complete_point_evaluated":
                if not isinstance(design_id, str) or not design_id:
                    self.error(f"{context}: complete point event needs design_id")
                elif design_id in completed_ids:
                    self.error(f"{context}: complete design point counted more than once")
                else:
                    completed_ids.add(design_id)
                    completed_since_thaw += 1
            elif event_type == "global_thaw_opened":
                payload = event.get("payload")
                if completed_since_thaw != k:
                    self.error(f"{context}: global thaw may open only after exactly K complete points")
                if not isinstance(payload, dict):
                    self.error(f"{context}: thaw payload must be an object")
                else:
                    parents = payload.get("parent_design_ids")
                    blocks = payload.get("coupled_blocks")
                    if not isinstance(parents, list) or len(set(parents)) < 2:
                        self.error(f"{context}: thaw needs at least two distinct parent design points")
                    elif any(parent not in completed_ids for parent in parents):
                        self.error(f"{context}: thaw parent is not a completed point")
                    if not isinstance(blocks, list) or not blocks or any(block not in THAW_BLOCKS for block in blocks):
                        self.error(f"{context}: invalid/empty coupled_blocks")
                    if not isinstance(payload.get("completion_definition"), str) or not payload["completion_definition"].strip():
                        self.error(f"{context}: thaw completion_definition is required")
                completed_since_thaw = 0
                last_thaw = actual
            previous = actual
        if ledger_meta.get("event_count") != len(events):
            self.error("ledger.event_count does not match JSONL line count")
        if ledger_meta.get("head_event_sha256") != previous:
            self.error("ledger.head_event_sha256 does not match the chain head")
        thaw_due = completed_since_thaw == k
        thaw = registry.get("global_thaw", {})
        if thaw.get("completed_points_since_last_thaw") != completed_since_thaw:
            self.error("global_thaw.completed_points_since_last_thaw does not match ledger")
        if thaw.get("thaw_due") is not thaw_due:
            self.error("global_thaw.thaw_due does not match ledger")
        if thaw.get("last_thaw_event_sha256") != last_thaw:
            self.error("global_thaw.last_thaw_event_sha256 does not match ledger")
        return by_hash, completed_since_thaw, thaw_due, last_thaw

    def check_inventory(self, ref: Any, context: str) -> int | None:
        path = self.file_ref(ref, context, content_addressed=True)
        if path is None:
            return None
        try:
            inventory = load_json(path)
        except (ValueError, json.JSONDecodeError) as exc:
            self.error(f"{context}: invalid inventory JSON: {exc}")
            return None
        tests = inventory.get("tests") if isinstance(inventory, dict) else None
        if not isinstance(inventory, dict) or inventory.get("schema") != INVENTORY_SCHEMA:
            self.error(f"{context}: wrong inventory schema")
            return None
        if not isinstance(tests, list) or not tests or any(not isinstance(test, str) or not test for test in tests):
            self.error(f"{context}: tests must be a non-empty string array")
            return None
        if len(tests) != len(set(tests)):
            self.error(f"{context}: tests must be unique")
        if ref.get("derived_test_count") != len(tests):
            self.error(f"{context}: derived_test_count must equal the actual tests array length")
        return len(tests)

    def check_point(
        self,
        point: dict[str, Any],
        point_ref: dict[str, Any],
        events: dict[str, dict[str, Any]],
    ) -> dict[str, Any]:
        design_id = point.get("design_id")
        context = f"point {design_id!r}"
        state = point.get("state")
        if point.get("schema") != POINT_SCHEMA:
            self.error(f"{context}: wrong schema")
        if not isinstance(design_id, str) or not design_id or point_ref.get("design_id") != design_id:
            self.error(f"{context}: design_id is missing or differs from registry reference")
        if state not in {"intermediate_checkpoint", "complete_design_point"}:
            self.error(f"{context}: invalid state")
        completion = point.get("completion_definition")
        if not isinstance(completion, dict) or not completion.get("completion_conditions"):
            self.error(f"{context}: completion_definition with completion_conditions is required")
        event = events.get(point.get("ledger_event_sha256"))
        expected_event = "complete_point_evaluated" if state == "complete_design_point" else "checkpoint_recorded"
        if event is None or event.get("event_type") != expected_event or event.get("design_id") != design_id:
            self.error(f"{context}: ledger event does not bind this point/state")
        gates = point.get("hard_gates")
        evidence = point.get("evidence")
        if not isinstance(gates, dict):
            gates = {}
            self.error(f"{context}: hard_gates must be an object")
        if not isinstance(evidence, list):
            evidence = []
            self.error(f"{context}: evidence must be an array")
        evidence_kinds: set[str] = set()
        for index, item in enumerate(evidence):
            if isinstance(item, dict) and isinstance(item.get("kind"), str):
                evidence_kinds.add(item["kind"])
            self.file_ref(item, f"{context} evidence[{index}]")
        objectives = point.get("objectives")
        if not isinstance(objectives, dict):
            objectives = {}
            self.error(f"{context}: objectives must be an object")
        if state == "intermediate_checkpoint":
            if point.get("architecture_feasible") is not False:
                self.error(f"{context}: intermediate checkpoint cannot be architecture_feasible")
            for axis in ("performance", "area", "power"):
                metric = objectives.get(axis, {})
                if metric.get("qualification") != "unqualified" or metric.get("value") is not None:
                    self.error(f"{context}: intermediate {axis} must remain unqualified/null")
            return {"point": point, "feasible": False, "formal": False, "proxy": False}

        if tuple(point.get("evaluation_order", ())) != EVALUATION_ORDER:
            self.error(f"{context}: evaluation_order must preserve hard-gates-first ordering")
        if set(gates) != set(GATES):
            self.error(f"{context}: complete point must report exactly all hard gates")
        for gate in GATES:
            if gates.get(gate) not in {"pass", "fail"}:
                self.error(f"{context}: hard gate {gate} must be pass/fail")
            if f"hard_gate:{gate}" not in evidence_kinds:
                self.error(f"{context}: missing hashed evidence for hard gate {gate}")
        snapshot = point.get("immutable_source_snapshot")
        if not isinstance(snapshot, dict) or snapshot.get("immutable") is not True:
            self.error(f"{context}: complete point requires immutable source snapshot")
        else:
            self.file_ref(snapshot, f"{context} immutable source snapshot", content_addressed=True)
            # design_id 直接绑定完整 source/config bundle，防止同名候选替换底层设计。
            if design_id != f"sha256:{snapshot.get('sha256')}":
                self.error(f"{context}: complete design_id must equal sha256:<immutable source snapshot SHA-256>")
        inventory_count = self.check_inventory(point.get("required_test_inventory"), f"{context} test inventory")

        workloads = point.get("per_workload_metrics")
        if not isinstance(workloads, dict) or set(workloads) != set(self.required_workloads):
            self.error(f"{context}: complete point must report exactly all required workloads")
            workloads = workloads if isinstance(workloads, dict) else {}
        ratios: dict[str, float] = {}
        retired_ok = True
        for name, contract in self.required_workloads.items():
            metric = workloads.get(name, {})
            ratio = metric.get("throughput_ratio") if isinstance(metric, dict) else None
            if not isinstance(ratio, (int, float)) or isinstance(ratio, bool) or not math.isfinite(ratio) or ratio <= 0:
                self.error(f"{context}: workload {name} has invalid throughput_ratio")
                continue
            ratios[name] = float(ratio)
            expected_retired = contract["reference_retired_instructions"]
            retired = metric.get("retired_instructions")
            if isinstance(retired, bool) or retired != expected_retired:
                retired_ok = False
                self.error(f"{context}: workload {name} retired count differs from frozen image")
            if f"workload:{name}" not in evidence_kinds:
                self.error(f"{context}: missing hashed evidence for workload {name}")
        worst_ok = False
        minimum_ratio = None
        if ratios and len(ratios) == len(self.required_workloads):
            minimum_ratio = min(ratios.values())
            worst_names = {name for name, value in ratios.items() if math.isclose(value, minimum_ratio, abs_tol=1e-12)}
            worst = point.get("worst_workload")
            worst_ratio = worst.get("throughput_ratio") if isinstance(worst, dict) else None
            worst_ok = (
                isinstance(worst, dict)
                and worst.get("name") in worst_names
                and isinstance(worst_ratio, (int, float))
                and not isinstance(worst_ratio, bool)
                and math.isfinite(worst_ratio)
                and math.isclose(float(worst_ratio), minimum_ratio, abs_tol=1e-12)
            )
            if not worst_ok:
                self.error(f"{context}: worst_workload must equal the computed minimum ratio")

        performance = objectives.get("performance", {})
        area = objectives.get("area", {})
        power = objectives.get("power", {})
        performance_value = performance.get("value")
        perf_ok = (
            performance.get("qualification") == "qualified"
            and performance.get("aggregation") == "worst_case_min_ratio"
            and minimum_ratio is not None
            and isinstance(performance_value, (int, float))
            and not isinstance(performance_value, bool)
            and math.isfinite(performance_value)
            and math.isclose(float(performance_value), minimum_ratio, abs_tol=1e-12)
        )
        if not perf_ok:
            self.error(f"{context}: performance axis must be qualified computed worst-case ratio")
        area_value = area.get("value")
        area_qualified = (
            area.get("qualification") == "qualified"
            and isinstance(area_value, (int, float))
            and not isinstance(area_value, bool)
            and math.isfinite(area_value)
            and area_value > 0
        )
        power_value = power.get("value")
        activity_coverage = power.get("activity_coverage")
        activity_valid = (
            isinstance(activity_coverage, (int, float))
            and not isinstance(activity_coverage, bool)
            and math.isfinite(activity_coverage)
            and 0.0 <= activity_coverage <= 1.0
        )
        if power.get("qualification") == "qualified" and not activity_valid:
            self.error(f"{context}: qualified power activity_coverage must be finite numeric in [0,1]")
        power_qualified = (
            power.get("qualification") == "qualified"
            and isinstance(power_value, (int, float))
            and not isinstance(power_value, bool)
            and math.isfinite(power_value)
            and power_value > 0
            and activity_valid
            and activity_coverage >= 0.95
            and power.get("macro_model_complete") is True
        )
        if power.get("qualification") == "unqualified" and power_value is not None:
            self.error(f"{context}: unqualified power must have null value")
        feasible = (
            all(gates.get(gate) == "pass" for gate in GATES)
            and retired_ok
            and worst_ok
            and minimum_ratio is not None
            and minimum_ratio >= 0.995
        )
        if point.get("architecture_feasible") is not feasible:
            self.error(f"{context}: architecture_feasible does not match gates/workload floors")
        formal = (
            feasible
            and not self.inventory_drift
            and inventory_count == self.contract_test_count
            and perf_ok
            and area_qualified
            and area.get("scope") == "macro_inclusive_total"
            and power_qualified
        )
        proxy = (
            feasible
            and perf_ok
            and area_qualified
            and not formal
            and power.get("qualification") == "unqualified"
        )
        return {
            "point": point,
            "feasible": feasible,
            "formal": formal,
            "proxy": proxy,
            "vector": (float(performance_value or 0), float(area_value or math.inf), float(power_value or math.inf)),
            "proxy_vector": (float(performance_value or 0), float(area_value or math.inf)),
        }

    @staticmethod
    def nondominated(records: list[dict[str, Any]], vector_key: str) -> set[str]:
        result: set[str] = set()
        for candidate in records:
            cp, ca, *crest = candidate[vector_key]
            dominated = False
            for other in records:
                if other is candidate:
                    continue
                op, oa, *orest = other[vector_key]
                no_worse = op >= cp and oa <= ca
                strictly = op > cp or oa < ca
                if crest:
                    no_worse = no_worse and orest[0] <= crest[0]
                    strictly = strictly or orest[0] < crest[0]
                if no_worse and strictly:
                    dominated = True
                    break
            if not dominated:
                result.add(candidate["point"]["design_id"])
        return result

    def check_registry(self) -> None:
        try:
            registry = load_json(self.registry_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            self.error(f"registry: cannot load strict JSON: {exc}")
            return
        if not isinstance(registry, dict) or registry.get("schema") != REGISTRY_SCHEMA:
            self.error(f"registry.schema must be {REGISTRY_SCHEMA}")
            return
        self.check_bindings(registry)
        workload_contract = registry.get("workload_contract")
        if not isinstance(workload_contract, dict) or workload_contract.get("minimum_per_workload_ratio") != 0.995:
            self.error("workload_contract minimum ratio must be exactly 0.995")
        else:
            required = workload_contract.get("required_workloads")
            if not isinstance(required, dict) or not required:
                self.error("workload_contract.required_workloads must be non-empty")
            else:
                self.required_workloads = required
        self.check_inventory_contract(registry)
        events, _, _, _ = self.check_ledger(registry)

        refs = registry.get("point_manifests")
        if not isinstance(refs, list):
            self.error("point_manifests must be an array")
            refs = []
        records: dict[str, dict[str, Any]] = {}
        for index, ref in enumerate(refs):
            path = self.file_ref(ref, f"point_manifests[{index}]", content_addressed=True)
            if path is None:
                continue
            try:
                point = load_json(path)
            except (ValueError, json.JSONDecodeError) as exc:
                self.error(f"point_manifests[{index}]: invalid point JSON: {exc}")
                continue
            if not isinstance(point, dict):
                self.error(f"point_manifests[{index}]: point must be an object")
                continue
            design_id = point.get("design_id")
            if design_id in records:
                self.error(f"duplicate design_id: {design_id!r}")
                continue
            records[design_id] = self.check_point(point, ref, events)

        pools = registry.get("pools")
        if not isinstance(pools, dict) or set(pools) != set(POOLS):
            self.error(f"pools must contain exactly: {', '.join(POOLS)}")
            pools = {name: [] for name in POOLS}
        for name in POOLS:
            members = pools.get(name)
            if not isinstance(members, list) or len(members) != len(set(members)):
                self.error(f"pools.{name} must be a unique design-id array")
                continue
            unknown = set(members) - set(records)
            if unknown:
                self.error(f"pools.{name} references unknown points: {sorted(unknown)}")

        seed_id = registry.get("architecture_feasible_seed_id")
        if seed_id is not None:
            seed = records.get(seed_id)
            if (
                seed is None
                or seed["point"].get("state") != "complete_design_point"
                or seed["point"].get("role") != "architecture_feasible_seed"
                or not seed["feasible"]
                or seed["point"].get("parent_seed_id") is not None
            ):
                self.error("architecture_feasible_seed_id must bind a feasible complete seed point")
        for design_id, record in records.items():
            point = record["point"]
            if point.get("role") in BRANCH_ROLES:
                if seed_id is None or point.get("parent_seed_id") != seed_id:
                    self.error(f"point {design_id!r}: every optimization branch/checkpoint must bind the common feasible seed")
            memberships = {name for name in POOLS if design_id in pools.get(name, [])}
            if point.get("state") == "intermediate_checkpoint" and "feasible_pareto" in memberships:
                self.error(f"point {design_id!r}: intermediate checkpoint cannot enter feasible_pareto")
            if (point.get("state") == "intermediate_checkpoint" or not record["feasible"]) and "development" not in memberships:
                self.error(f"point {design_id!r}: intermediate/infeasible active point must remain development")
            if "development" in memberships and not point.get("next_compensation_experiment"):
                self.error(f"point {design_id!r}: development member needs next_compensation_experiment")
            if "high_uncertainty" in memberships:
                uncertainty = point.get("uncertainty", {})
                if uncertainty.get("kind") in {None, "none"} or not uncertainty.get("reduction_experiment"):
                    self.error(f"point {design_id!r}: high_uncertainty member needs evidence uncertainty and reduction experiment")
            if "diversity" in memberships:
                diversity = point.get("diversity", {})
                if not diversity.get("signature") or not diversity.get("distance_basis"):
                    self.error(f"point {design_id!r}: diversity member needs signature and distance_basis")

        formal_records = [record for record in records.values() if record["formal"] and (record["point"]["design_id"] == seed_id or record["point"].get("parent_seed_id") == seed_id)]
        expected_front = self.nondominated(formal_records, "vector") if seed_id is not None else set()
        actual_front = set(pools.get("feasible_pareto", []))
        if actual_front != expected_front:
            self.error(f"pools.feasible_pareto must equal computed qualified three-axis front: expected {sorted(expected_front)}")

        proxy_archive = registry.get("engineering_proxy_archive")
        if not isinstance(proxy_archive, dict):
            self.error("engineering_proxy_archive must be an object")
            proxy_archive = {"members": []}
        for forbidden in ("front_accepted", "canonical", "ppa_champion"):
            if proxy_archive.get(forbidden) is not False:
                self.error(f"engineering_proxy_archive.{forbidden} must stay false")
        proxy_members = proxy_archive.get("members", [])
        if not isinstance(proxy_members, list) or len(proxy_members) != len(set(proxy_members)):
            self.error("engineering_proxy_archive.members must be a unique array")
            proxy_members = []
        for design_id in proxy_members:
            if design_id not in records or not records[design_id]["proxy"]:
                self.error(f"engineering proxy member {design_id!r} is not eligible")
            if design_id in actual_front:
                self.error(f"engineering proxy member {design_id!r} cannot also be formal Pareto")
        for design_id, record in records.items():
            if record["point"].get("state") == "intermediate_checkpoint" and design_id in proxy_members:
                self.error(f"point {design_id!r}: intermediate checkpoint cannot enter proxy archive")

        promotions = registry.get("formal_promotions")
        if not isinstance(promotions, list) or len(promotions) != len(set(promotions)):
            self.error("formal_promotions must be a unique array")
            promotions = []
        if self.inventory_drift and promotions:
            self.error("formal promotions are blocked by required-test inventory drift")
        for design_id in promotions:
            record = records.get(design_id)
            if design_id not in actual_front or record is None:
                self.error(f"formal promotion {design_id!r} must be on the qualified Pareto front")
            elif record["point"].get("normative_promotion", {}).get("checker_status") != "pass":
                self.error(f"formal promotion {design_id!r} lacks normative checker PASS")
        for field in ("canonical_design_id", "ppa_champion_design_id"):
            value = registry.get(field)
            if value is not None and value not in promotions:
                self.error(f"{field} must be null or a formal promotion")
        if registry.get("ppa_champion_design_id") is not None and registry.get("ppa_champion_design_id") == seed_id:
            self.error("ppa_champion_design_id cannot be the one-time architecture-feasible seed")
        ranking = registry.get("scalar_ranking")
        if not isinstance(ranking, list):
            self.error("scalar_ranking must be an array")
        else:
            ranked = [item.get("design_id") for item in ranking if isinstance(item, dict)]
            if len(ranked) != len(ranking) or len(ranked) != len(set(ranked)) or any(item not in actual_front for item in ranked):
                self.error("scalar_ranking may contain unique members of the same feasible Pareto front only")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--workspace-root", type=Path)
    args = parser.parse_args(argv)
    checker = Checker(args.registry, args.workspace_root)
    checker.check_registry()
    if checker.errors:
        print(f"[DSE-ARCHIVE] FAIL errors={len(checker.errors)}")
        for index, error in enumerate(checker.errors, 1):
            print(f"{index}. {error}")
        return 1
    print("[DSE-ARCHIVE] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
