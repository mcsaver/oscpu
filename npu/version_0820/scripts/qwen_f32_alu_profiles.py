#!/usr/bin/env python3
"""Qwen canonical F32 ALU 的 19-row 机器 profile 与 manifest oracle。

本工具只处理 descriptor metadata、raw op-parameter bytes、整数 span/counter 与
canonical identity；它不读取 tensor 数值，不执行 host floating-point arithmetic。
"""

from __future__ import annotations

import argparse
import copy
import dataclasses
import hashlib
import json
import pathlib
import re
import sys
from typing import Any, Iterable, Mapping, Sequence


SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
import qwen_graph_manifest  # noqa: E402


MANIFEST_SHA256 = (
    "92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e"
)
RAW_SHA256 = (
    "a144ef45f25e8f7a754ddd16faea09422b175d443538bf884964b2ff3685f112"
)
CANONICAL_IDENTITY_SET_SHA256 = (
    "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385"
)
F32_CANONICAL_ALLOWLIST_SHA256 = (
    "4ff853015890ec5d6744485f6da76b74c4c91292b2afc83c358990713835a2f3"
)
ZERO_OP_PARAMS = "00" * 64
SCALE_3DB504F3_OP_PARAMS = "f304b53d" + "00" * 60
UINT64_MAX = (1 << 64) - 1
PROFILE_COUNT = 19
ELIGIBLE_IDENTITY_COUNT = 367
PREDECESSOR_REPRESENTATIVE_TRANSACTIONS_PASSED = 1
VERIFIED_CANONICAL_IDENTITIES_COMPLETED = 0
REMAINING_NONMETADATA_GAP = 1080
GMEM_RESPONSE_BOUND = 16
F32_CHILD_BOUND = 512
FIXED_CYCLE_MARGIN = 32
CHILD_COMMAND_TIMEOUT = 200_000_000
HARNESS_CYCLE_LIMIT = 220_000_000
REPRESENTATIVE_COMMAND_FLAGS = 0x00000010
REPRESENTATIVE_CONTEXT_BASE = 0x52500000
REPRESENTATIVE_SEQUENCE_BASE = 0x5250524550000000
REPRESENTATIVE_PRODUCER_BASE = 0x5250524F44000000
REPRESENTATIVE_USER_TAG_BASE = 0x5250544147000000
REPRESENTATIVE_NODE_HASH_LO_BASE = 0x9E3779B97F4A7C15
REPRESENTATIVE_NODE_HASH_HI_BASE = 0xD1B54A32D192ED03
REPRESENTATIVE_STAGES = (
    "command_accepted",
    "completion_emitted",
    "completion_accepted",
    "raw_destination_committed",
    "representative_coverage_closed",
)


class ProfileError(RuntimeError):
    """Profile table 或 canonical manifest 不满足 exact contract。"""


def canonical_bytes(value: Any) -> bytes:
    """与 raw-graph validator 相同、但在本工具内独立实现的 canonical JSON。"""

    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def representative_identity(profile_id: int) -> dict[str, Any]:
    if type(profile_id) is not int or not 0 <= profile_id < PROFILE_COUNT:
        raise ProfileError(f"representative profile out of range: {profile_id}")
    repeated_profile = (profile_id << 32) | profile_id
    return {
        "namespace": f"rep:qwen-f32-alu:v4:P{profile_id:02d}",
        "profile_id": profile_id,
        "vector_flags": profile_id,
        "command_flags": REPRESENTATIVE_COMMAND_FLAGS,
        "context_id": REPRESENTATIVE_CONTEXT_BASE | profile_id,
        "sequence_id": REPRESENTATIVE_SEQUENCE_BASE | profile_id,
        "producer_id": REPRESENTATIVE_PRODUCER_BASE | profile_id,
        "user_tag": REPRESENTATIVE_USER_TAG_BASE | profile_id,
        "covered_node_count": 1,
        "node_hash_lo": REPRESENTATIVE_NODE_HASH_LO_BASE ^ profile_id,
        "node_hash_hi": REPRESENTATIVE_NODE_HASH_HI_BASE ^ repeated_profile,
    }


def representative_identity_audit(
    records: Sequence[Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    expected = [representative_identity(index) for index in range(PROFILE_COUNT)]
    actual = expected if records is None else [dict(record) for record in records]
    if actual != expected:
        raise ProfileError("representative identity ordered-set mismatch")
    namespace_set = {record["namespace"] for record in actual}
    hardware_set = {
        (
            record["context_id"],
            record["sequence_id"],
            record["producer_id"],
            record["user_tag"],
            record["node_hash_lo"],
            record["node_hash_hi"],
            record["vector_flags"],
        )
        for record in actual
    }
    if len(namespace_set) != PROFILE_COUNT or len(hardware_set) != PROFILE_COUNT:
        raise ProfileError("representative namespace/hardware identity collision")
    if any(re.fullmatch(r"[0-9a-f]{64}", value) for value in namespace_set):
        raise ProfileError("representative namespace aliases canonical ID syntax")
    if any(record["command_flags"] & 1 for record in actual):
        raise ProfileError("representative REQUIRED bit is set")
    return {
        "schema": "qwen-f32-alu-representative-identities-v4",
        "count": PROFILE_COUNT,
        "exact_profile_mask": (1 << PROFILE_COUNT) - 1,
        "required_bit": 0,
        "identity_set_sha256": canonical_sha256(actual),
        "records": actual,
    }


def audit_representative_stage_sets(
    stages: Mapping[str, Sequence[Mapping[str, Any]]],
) -> dict[str, Any]:
    if set(stages) != set(REPRESENTATIVE_STAGES):
        raise ProfileError("representative stage key mismatch")
    stage_audits: dict[str, dict[str, Any]] = {}
    for stage in REPRESENTATIVE_STAGES:
        stage_audits[stage] = representative_identity_audit(stages[stage])
    return {
        "schema": "qwen-f32-alu-representative-stage-ledger-v4",
        "stage_count": len(REPRESENTATIVE_STAGES),
        "exact_profile_mask": (1 << PROFILE_COUNT) - 1,
        "identity_set_sha256": stage_audits[REPRESENTATIVE_STAGES[0]][
            "identity_set_sha256"
        ],
        "stages": {
            stage: audit["count"] for stage, audit in stage_audits.items()
        },
    }


def representative_stage_mutation_self_test() -> dict[str, Any]:
    baseline = [representative_identity(index) for index in range(PROFILE_COUNT)]
    baseline_stages = {stage: copy.deepcopy(baseline) for stage in REPRESENTATIVE_STAGES}
    audit_representative_stage_sets(baseline_stages)

    fixtures: list[tuple[str, dict[str, list[dict[str, Any]]]]] = []

    duplicate = copy.deepcopy(baseline_stages)
    duplicate["completion_accepted"].append(copy.deepcopy(duplicate["completion_accepted"][0]))
    fixtures.append(("duplicate_replay", duplicate))

    wrong_profile = copy.deepcopy(baseline_stages)
    wrong_profile["completion_emitted"][0]["profile_id"] = 1
    fixtures.append(("wrong_profile", wrong_profile))

    missing = copy.deepcopy(baseline_stages)
    missing["raw_destination_committed"].pop()
    fixtures.append(("missing", missing))

    extra = copy.deepcopy(baseline_stages)
    extra_record = copy.deepcopy(extra["representative_coverage_closed"][-1])
    extra_record["namespace"] = "rep:qwen-f32-alu:v4:P19"
    extra_record["profile_id"] = 19
    extra["representative_coverage_closed"].append(extra_record)
    fixtures.append(("extra", extra))

    substitution = copy.deepcopy(baseline_stages)
    first = substitution["completion_accepted"][0]
    second = substitution["completion_accepted"][1]
    first["node_hash_lo"], second["node_hash_lo"] = (
        second["node_hash_lo"],
        first["node_hash_lo"],
    )
    first["node_hash_hi"], second["node_hash_hi"] = (
        second["node_hash_hi"],
        first["node_hash_hi"],
    )
    fixtures.append(("profile_identity_substitution", substitution))

    reordered = copy.deepcopy(baseline_stages)
    reordered["completion_emitted"][0], reordered["completion_emitted"][1] = (
        reordered["completion_emitted"][1],
        reordered["completion_emitted"][0],
    )
    fixtures.append(("reordered_profile_collision", reordered))

    required = copy.deepcopy(baseline_stages)
    required["command_accepted"][0]["command_flags"] = 0x11
    fixtures.append(("required_namespace_pollution", required))

    rejected: list[str] = []
    for name, fixture in fixtures:
        try:
            audit_representative_stage_sets(fixture)
        except ProfileError:
            rejected.append(name)
        else:
            raise ProfileError(
                "representative stage mutation unexpectedly accepted: " + name
            )
    return {
        "schema": "qwen-f32-alu-representative-stage-mutations-v4",
        "baseline_count": PROFILE_COUNT,
        "rejected_mutations": rejected,
        "rejected_mutation_count": len(rejected),
    }


@dataclasses.dataclass(frozen=True)
class TensorSpec:
    ne: tuple[int, int, int, int]
    nb: tuple[int, int, int, int]
    view_off: int = 0
    view: bool = False


@dataclasses.dataclass(frozen=True)
class Profile:
    profile_id: int
    count: int
    op: str
    vector_op: int
    dst: TensorSpec
    src0: TensorSpec
    src1: TensorSpec | None
    scalar0: int = 0

    @property
    def name(self) -> str:
        return f"P{self.profile_id:02d}"

    @property
    def scale(self) -> bool:
        return self.op == "SCALE"

    @property
    def elements(self) -> int:
        return checked_product(self.dst.ne, f"{self.name}.elements")

    @property
    def outer_count(self) -> int:
        return checked_product(self.dst.ne[1:], f"{self.name}.outer_count")

    @property
    def op_params_hex(self) -> str:
        if self.scalar0 == 0:
            return ZERO_OP_PARAMS
        if self.scalar0 == 0x3DB504F3:
            return SCALE_3DB504F3_OP_PARAMS
        raise ProfileError(f"{self.name}: unsupported raw scalar0")

    @property
    def permissions(self) -> tuple[int, int, int]:
        return (1, 0 if self.scale else 1, 2)

    @property
    def read_bytes(self) -> int:
        factor = 8 if self.scale else 16
        return checked_u64(factor * self.elements, f"{self.name}.read_bytes")

    @property
    def write_bytes(self) -> int:
        return checked_u64(4 * self.elements, f"{self.name}.write_bytes")

    @property
    def cycle_upper_bound(self) -> int:
        per_element = (
            1
            + (1 + GMEM_RESPONSE_BOUND)
            + (0 if self.scale else (1 + GMEM_RESPONSE_BOUND))
            + (1 + F32_CHILD_BOUND)
            + (1 + GMEM_RESPONSE_BOUND)
        )
        return checked_u64(
            FIXED_CYCLE_MARGIN + per_element * self.elements,
            f"{self.name}.cycle_upper_bound",
        )


def tensor(
    ne: Sequence[int],
    nb: Sequence[int],
    *,
    off: int = 0,
    view: bool = False,
) -> TensorSpec:
    if len(ne) != 4 or len(nb) != 4:
        raise ProfileError("tensor spec must have four ne and four nb values")
    return TensorSpec(tuple(ne), tuple(nb), off, view)  # type: ignore[arg-type]


T16 = tensor((16, 1, 1, 1), (4, 64, 64, 64))
T1024 = tensor((1024, 1, 1, 1), (4, 4096, 4096, 4096))
T128_128_16 = tensor(
    (128, 128, 16, 1), (4, 512, 65536, 1048576)
)
T128_1_16 = tensor((128, 1, 16, 1), (4, 512, 512, 8192))
T128_16 = tensor((128, 16, 1, 1), (4, 512, 8192, 8192))


PROFILES: tuple[Profile, ...] = (
    Profile(0, 18, "ADD", 1, T16, dataclasses.replace(T16, view=True), T16),
    Profile(1, 30, "ADD", 1, T1024, T1024, T1024),
    Profile(
        2, 18, "ADD", 1, T1024, dataclasses.replace(T1024, view=True), T1024
    ),
    Profile(3, 18, "ADD", 1, T128_128_16, T128_128_16, T128_128_16),
    Profile(4, 18, "MUL", 2, T16, T16, T16),
    Profile(5, 49, "MUL", 2, T1024, T1024, T1024),
    Profile(
        6,
        36,
        "MUL",
        2,
        T128_128_16,
        T128_128_16,
        tensor((128, 1, 16, 1), (4, 8192, 512, 8192), view=True),
    ),
    Profile(
        7,
        18,
        "MUL",
        2,
        T128_1_16,
        T128_1_16,
        tensor((1, 1, 16, 1), (4, 4, 4, 64), view=True),
    ),
    Profile(
        8,
        18,
        "MUL",
        2,
        T128_128_16,
        T128_128_16,
        tensor((1, 128, 16, 1), (512, 4, 512, 8192), view=True),
    ),
    Profile(
        9,
        18,
        "MUL",
        2,
        T128_128_16,
        dataclasses.replace(T128_128_16, view=True),
        tensor((1, 1, 16, 1), (4, 4, 4, 64)),
    ),
    Profile(
        10,
        18,
        "MUL",
        2,
        T128_16,
        T128_16,
        tensor((128, 1, 1, 1), (4, 512, 512, 512)),
    ),
    Profile(11, 18, "MUL", 2, T128_16, T128_16, T128_16),
    Profile(
        12,
        6,
        "MUL",
        2,
        tensor((2048, 1, 1, 1), (4, 8192, 8192, 8192)),
        tensor((2048, 1, 1, 1), (4, 8192, 8192, 8192)),
        tensor((2048, 1, 1, 1), (4, 8192, 8192, 8192)),
    ),
    Profile(
        13,
        6,
        "MUL",
        2,
        tensor((256, 2, 1, 1), (4, 1024, 2048, 2048)),
        tensor((256, 2, 1, 1), (4, 1024, 2048, 2048)),
        tensor((256, 1, 1, 1), (4, 1024, 1024, 1024)),
    ),
    Profile(
        14,
        6,
        "MUL",
        2,
        tensor((256, 8, 1, 1), (4, 1024, 8192, 8192)),
        tensor((256, 8, 1, 1), (4, 1024, 8192, 8192)),
        tensor((256, 1, 1, 1), (4, 1024, 1024, 1024)),
    ),
    Profile(
        15,
        18,
        "SUB",
        3,
        T128_1_16,
        tensor(
            (128, 1, 16, 1),
            (4, 24576, 512, 24576),
            off=16384,
            view=True,
        ),
        tensor((128, 1, 16, 1), (4, 4, 512, 8192), view=True),
    ),
    Profile(16, 18, "SCALE", 4, T128_16, T128_16, None, 0x3DB504F3),
    Profile(
        17,
        18,
        "SCALE",
        4,
        tensor((18432, 1, 1, 1), (4, 73728, 73728, 73728), view=True),
        tensor((18432, 1, 1, 1), (4, 73728, 73728, 73728), view=True),
        None,
        0,
    ),
    Profile(
        18,
        18,
        "SCALE",
        4,
        tensor(
            (262144, 1, 1, 1),
            (4, 1048576, 1048576, 1048576),
            view=True,
        ),
        tensor(
            (262144, 1, 1, 1),
            (4, 1048576, 1048576, 1048576),
            view=True,
        ),
        None,
        0,
    ),
)


def checked_u64(value: int, label: str) -> int:
    if not isinstance(value, int) or value < 0 or value > UINT64_MAX:
        raise ProfileError(f"{label}: unsigned 64-bit overflow/value error: {value}")
    return value


def checked_product(values: Iterable[int], label: str) -> int:
    result = 1
    for index, value in enumerate(values):
        checked_u64(value, f"{label}[{index}]")
        result = checked_u64(result * value, label)
    return result


def source_span(spec: TensorSpec) -> dict[str, int]:
    logical_hi = checked_u64(spec.view_off, "view_off")
    for dimension, (ne_value, nb_value) in enumerate(zip(spec.ne, spec.nb)):
        if ne_value <= 0:
            raise ProfileError(f"source ne[{dimension}] must be positive")
        if nb_value < 0:
            raise ProfileError(f"source nb[{dimension}] must be nonnegative")
        term = checked_u64((ne_value - 1) * nb_value, f"span.term[{dimension}]")
        logical_hi = checked_u64(logical_hi + term, "span.logical_hi")
    logical_hi = checked_u64(logical_hi + 4, "span.logical_hi_plus_f32")
    beat_lo = spec.view_off & ~7
    beat_hi = checked_u64((logical_hi + 7) & ~7, "span.beat_hi")
    if beat_lo >= beat_hi:
        raise ProfileError("source beat span must be nonempty")
    return {
        "logical_hi": logical_hi,
        "beat_lo": beat_lo,
        "beat_hi": beat_hi,
        "copy_bytes": beat_hi - beat_lo,
        "region_size": beat_hi,
    }


def tensor_record(spec: TensorSpec) -> dict[str, Any]:
    record: dict[str, Any] = {
        "ne": list(spec.ne),
        "nb": list(spec.nb),
        "view_off": spec.view_off,
        "view": spec.view,
    }
    record["span"] = source_span(spec)
    return record


def profile_record(profile: Profile) -> dict[str, Any]:
    return {
        "profile": profile.name,
        "profile_id": profile.profile_id,
        "count": profile.count,
        "op": profile.op,
        "vector_op": profile.vector_op,
        "vector_flags": profile.profile_id,
        "dst": tensor_record(profile.dst),
        "src0": tensor_record(profile.src0),
        "src1": None if profile.src1 is None else tensor_record(profile.src1),
        "permissions": {
            "src0": profile.permissions[0],
            "src1": profile.permissions[1],
            "dst": profile.permissions[2],
        },
        "scalar0": profile.scalar0,
        "scalar1": 0,
        "op_params_hex": profile.op_params_hex,
        "element_count": profile.dst.ne[0],
        "outer_count": profile.outer_count,
        "src0_stride": profile.src0.nb[1],
        "src1_stride": 0 if profile.src1 is None else profile.src1.nb[1],
        "dst_stride": profile.dst.nb[1],
        "elements": profile.elements,
        "read_bytes": profile.read_bytes,
        "write_bytes": profile.write_bytes,
        "cycle_upper_bound": profile.cycle_upper_bound,
    }


def profile_signature(profile: Profile) -> tuple[Any, ...]:
    return (
        profile.op,
        profile.vector_op,
        profile.dst,
        profile.src0,
        profile.src1,
        profile.scalar0,
    )


def validate_profiles(profiles: Sequence[Profile] = PROFILES) -> dict[str, Any]:
    if len(profiles) != PROFILE_COUNT:
        raise ProfileError(f"profile count mismatch: {len(profiles)}")
    ids = [profile.profile_id for profile in profiles]
    if ids != list(range(PROFILE_COUNT)):
        raise ProfileError(f"profile IDs are not exact 0..18: {ids}")
    signatures = [profile_signature(profile) for profile in profiles]
    if len(set(signatures)) != len(signatures):
        raise ProfileError("profile descriptor collision")
    if sum(profile.count for profile in profiles) != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError("profile row counts do not sum to 367")

    op_counts: dict[str, int] = {}
    maximum_bound = 0
    maximum_profiles: list[str] = []
    for profile in profiles:
        if profile.op not in {"ADD", "MUL", "SUB", "SCALE"}:
            raise ProfileError(f"{profile.name}: unsupported op")
        if profile.scale != (profile.src1 is None):
            raise ProfileError(f"{profile.name}: SCALE/empty-src1 mismatch")
        if profile.permissions != ((1, 0, 2) if profile.scale else (1, 1, 2)):
            raise ProfileError(f"{profile.name}: permission mutation")
        if profile.scale:
            if profile.scalar0 not in {0, 0x3DB504F3}:
                raise ProfileError(f"{profile.name}: SCALE scalar mutation")
        elif profile.scalar0 != 0 or profile.op_params_hex != ZERO_OP_PARAMS:
            raise ProfileError(f"{profile.name}: binary op_params mutation")
        source_span(profile.src0)
        if profile.src1 is not None:
            source_span(profile.src1)
        if profile.cycle_upper_bound >= CHILD_COMMAND_TIMEOUT:
            raise ProfileError(f"{profile.name}: child command timeout too small")
        if profile.cycle_upper_bound >= HARNESS_CYCLE_LIMIT:
            raise ProfileError(f"{profile.name}: harness cycle limit too small")
        op_counts[profile.op] = op_counts.get(profile.op, 0) + profile.count
        if profile.cycle_upper_bound > maximum_bound:
            maximum_bound = profile.cycle_upper_bound
            maximum_profiles = [profile.name]
        elif profile.cycle_upper_bound == maximum_bound:
            maximum_profiles.append(profile.name)
    if op_counts != {"ADD": 84, "MUL": 211, "SUB": 18, "SCALE": 54}:
        raise ProfileError(f"op census mismatch: {op_counts}")
    p18 = profiles[18]
    if p18.elements != 262144 or p18.cycle_upper_bound != 143654944:
        raise ProfileError("P18 element/cycle bound mismatch")
    return {
        "profile_count": len(profiles),
        "eligible_identity_count": sum(profile.count for profile in profiles),
        "op_counts": op_counts,
        "maximum_cycle_upper_bound": maximum_bound,
        "maximum_cycle_profiles": maximum_profiles,
        "p18_cycle_upper_bound": p18.cycle_upper_bound,
        "child_command_timeout": CHILD_COMMAND_TIMEOUT,
        "harness_cycle_limit": HARNESS_CYCLE_LIMIT,
    }


def permission_accepted(profile: Profile, src0: int, src1: int, dst: int) -> bool:
    for value in (src0, src1, dst):
        if value < 0 or value > 3:
            return False
    return (src0, src1, dst) == profile.permissions


def permission_truth_table(profiles: Sequence[Profile] = PROFILES) -> dict[str, Any]:
    rows: dict[str, list[list[int]]] = {}
    for profile in profiles:
        accepted: list[list[int]] = []
        for src0 in range(4):
            for src1 in range(4):
                for dst in range(4):
                    if permission_accepted(profile, src0, src1, dst):
                        accepted.append([src0, src1, dst])
        expected = [[1, 0 if profile.scale else 1, 2]]
        if accepted != expected:
            raise ProfileError(f"{profile.name}: permission truth table drift")
        rows[profile.name] = accepted
    return {"rows_per_profile": 64, "accepted": rows}


def _descriptor_matches(
    descriptor: Mapping[str, Any],
    spec: TensorSpec,
    *,
    check_op_params: str | None = None,
) -> bool:
    if descriptor.get("type_name") != "f32":
        return False
    if descriptor.get("ne") != list(spec.ne) or descriptor.get("nb") != list(spec.nb):
        return False
    if descriptor.get("view_offs") != spec.view_off:
        return False
    if (descriptor.get("view_src") is not None) != spec.view:
        return False
    if check_op_params is not None and descriptor.get("op_params_hex") != check_op_params:
        return False
    return True


def matching_profiles(node: Mapping[str, Any], profiles: Sequence[Profile] = PROFILES) -> list[Profile]:
    descriptor = node.get("descriptor")
    sources = node.get("sources")
    if not isinstance(descriptor, Mapping) or not isinstance(sources, list):
        return []
    matches: list[Profile] = []
    for profile in profiles:
        if descriptor.get("op_name") != profile.op:
            continue
        if not _descriptor_matches(
            descriptor, profile.dst, check_op_params=profile.op_params_hex
        ):
            continue
        expected_sources = 1 if profile.src1 is None else 2
        if len(sources) != expected_sources:
            continue
        ordered = sorted(sources, key=lambda item: item.get("slot", -1))
        if [item.get("slot") for item in ordered] != list(range(expected_sources)):
            continue
        src0 = ordered[0].get("descriptor")
        if not isinstance(src0, Mapping) or not _descriptor_matches(src0, profile.src0):
            continue
        if profile.src1 is not None:
            src1 = ordered[1].get("descriptor")
            if not isinstance(src1, Mapping) or not _descriptor_matches(src1, profile.src1):
                continue
        matches.append(profile)
    return matches


def audit_manifest_object(
    envelope: Mapping[str, Any],
    profiles: Sequence[Profile] = PROFILES,
) -> dict[str, Any]:
    table_audit = validate_profiles(profiles)
    if envelope.get("schema") != "qwen-npu-graph-manifest-envelope-v2":
        raise ProfileError("manifest envelope schema mismatch")
    claimed_manifest_sha256 = envelope.get("manifest_sha256")
    if not isinstance(claimed_manifest_sha256, str) or re.fullmatch(
        r"[0-9a-f]{64}", claimed_manifest_sha256
    ) is None:
        raise ProfileError("manifest identity field malformed")
    manifest = envelope.get("manifest")
    if not isinstance(manifest, Mapping):
        raise ProfileError("manifest payload missing")
    if manifest.get("schema") != "qwen-npu-graph-manifest-v2":
        raise ProfileError("manifest schema mismatch")
    if manifest.get("raw_sha256") != RAW_SHA256:
        raise ProfileError("manifest raw source identity mismatch")
    counts = manifest.get("counts")
    if counts != {
        "compute": 960,
        "external_tensors": 375,
        "metadata": 634,
        "mover": 120,
        "source_edges": 2474,
        "total": 1714,
    }:
        raise ProfileError(f"manifest global census mismatch: {counts}")
    nodes = manifest.get("nodes")
    if not isinstance(nodes, list) or len(nodes) != 1714:
        raise ProfileError("manifest node list cardinality mismatch")

    eligible_ops = {"ADD", "MUL", "SUB", "SCALE"}
    rows: dict[str, list[dict[str, Any]]] = {
        profile.name: [] for profile in profiles
    }
    seen_ids: set[str] = set()
    id_pattern = re.compile(r"^[0-9a-f]{64}$")
    candidate_count = 0
    for node in nodes:
        if not isinstance(node, Mapping):
            raise ProfileError("manifest node is not an object")
        descriptor = node.get("descriptor")
        if not isinstance(descriptor, Mapping):
            raise ProfileError("manifest node descriptor missing")
        if node.get("classification") != "compute" or descriptor.get("op_name") not in eligible_ops:
            continue
        candidate_count += 1
        matches = matching_profiles(node, profiles)
        if len(matches) != 1:
            raise ProfileError(
                f"node index={node.get('index')} exact profile matches={len(matches)}"
            )
        canonical_id = node.get("canonical_id")
        if not isinstance(canonical_id, str) or id_pattern.fullmatch(canonical_id) is None:
            raise ProfileError(f"node index={node.get('index')} invalid canonical_id")
        recomputed_canonical_id = canonical_sha256(node.get("semantic_key"))
        if canonical_id != recomputed_canonical_id:
            raise ProfileError(
                f"node index={node.get('index')} canonical_id recompute mismatch"
            )
        descriptor_sha256 = node.get("descriptor_sha256")
        recomputed_descriptor_sha256 = canonical_sha256(
            {"descriptor": descriptor, "sources": node.get("sources")}
        )
        if descriptor_sha256 != recomputed_descriptor_sha256:
            raise ProfileError(
                f"node index={node.get('index')} descriptor_sha256 recompute mismatch"
            )
        if canonical_id in seen_ids:
            raise ProfileError(f"duplicate canonical_id={canonical_id}")
        seen_ids.add(canonical_id)
        profile = matches[0]
        semantic_key = node.get("semantic_key")
        path = semantic_key.get("path") if isinstance(semantic_key, Mapping) else None
        rows[profile.name].append(
            {
                "canonical_id": canonical_id,
                "index": node.get("index"),
                "descriptor_sha256": descriptor_sha256,
                "semantic_path": path,
            }
        )

    if candidate_count != ELIGIBLE_IDENTITY_COUNT or len(seen_ids) != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError(
            f"eligible candidate/identity mismatch: {candidate_count}/{len(seen_ids)}"
        )
    for profile in profiles:
        if len(rows[profile.name]) != profile.count:
            raise ProfileError(
                f"{profile.name}: row count {len(rows[profile.name])} != {profile.count}"
            )

    identity_digest = hashlib.sha256()
    for canonical_id in sorted(seen_ids):
        identity_digest.update((canonical_id + "\n").encode("ascii"))
    identity_set_sha256 = identity_digest.hexdigest()
    if identity_set_sha256 != CANONICAL_IDENTITY_SET_SHA256:
        raise ProfileError(
            "canonical identity-set digest mismatch: " + identity_set_sha256
        )
    recomputed_manifest_sha256 = canonical_sha256(manifest)
    if recomputed_manifest_sha256 != claimed_manifest_sha256:
        raise ProfileError("manifest payload hash does not match envelope field")
    if recomputed_manifest_sha256 != MANIFEST_SHA256:
        raise ProfileError("manifest payload identity mismatch")
    return {
        "schema": "qwen-f32-alu-profile-census-v4",
        "raw_sha256": RAW_SHA256,
        "manifest_sha256": recomputed_manifest_sha256,
        "manifest_payload_recomputed": True,
        "eligible_canonical_ids_recomputed": ELIGIBLE_IDENTITY_COUNT,
        "eligible_descriptor_hashes_recomputed": ELIGIBLE_IDENTITY_COUNT,
        "global_counts": dict(counts),
        "profile_table_audit": table_audit,
        "permission_truth_table": permission_truth_table(profiles),
        "representative_identity_audit": representative_identity_audit(),
        "profile_count": PROFILE_COUNT,
        "eligible_identity_count": ELIGIBLE_IDENTITY_COUNT,
        "representative_transactions_planned": PROFILE_COUNT,
        "predecessor_representative_transactions_passed": (
            PREDECESSOR_REPRESENTATIVE_TRANSACTIONS_PASSED
        ),
        "verified_canonical_node_identities_completed": (
            VERIFIED_CANONICAL_IDENTITIES_COMPLETED
        ),
        "remaining_nonmetadata_gap": REMAINING_NONMETADATA_GAP,
        "canonical_identity_set_sha256": identity_set_sha256,
        "profiles": [
            {**profile_record(profile), "canonical_nodes": rows[profile.name]}
            for profile in profiles
        ],
    }


def audit_manifest_bundle_object(
    bootstrap_envelope: Mapping[str, Any],
    steady_envelope: Mapping[str, Any],
) -> dict[str, Any]:
    """Join the exact F32 owner table to the audited dispatch phase bundle."""

    bootstrap_census = audit_manifest_object(bootstrap_envelope)
    bundle_result = qwen_graph_manifest.audit_manifest_bundle_objects(
        bootstrap_envelope, steady_envelope
    )
    zero_rows = bundle_result.envelope["bundle"]["zero_scale_nodes"]
    zero_by_id = {row["canonical_id"]: row for row in zero_rows}
    if len(zero_by_id) != 36:
        raise ProfileError("steady zero SCALE canonical identity count mismatch")

    bootstrap_nodes = bootstrap_envelope["manifest"]["nodes"]
    eligible_rows: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for profile_row in bootstrap_census["profiles"]:
        profile_id = profile_row["profile_id"]
        for canonical in profile_row["canonical_nodes"]:
            canonical_id = canonical["canonical_id"]
            index = canonical["index"]
            if (
                type(index) is not int
                or index < 0
                or index >= len(bootstrap_nodes)
            ):
                raise ProfileError(f"canonical graph index out of range: {index}")
            node = bootstrap_nodes[index]
            if node.get("canonical_id") != canonical_id or node.get("index") != index:
                raise ProfileError(
                    f"canonical ID/index binding mismatch at graph node {index}"
                )
            sources = node.get("sources")
            if not isinstance(sources, list):
                raise ProfileError(f"canonical graph node {index} sources missing")
            ordered_sources = sorted(sources, key=lambda item: item.get("slot", -1))
            if not ordered_sources or ordered_sources[0].get("slot") != 0:
                raise ProfileError(f"canonical graph node {index} src0 missing")
            descriptor = node.get("descriptor")
            src0_descriptor = ordered_sources[0].get("descriptor")
            if not isinstance(descriptor, Mapping) or not isinstance(
                src0_descriptor, Mapping
            ):
                raise ProfileError(f"canonical graph node {index} descriptor missing")
            zero = zero_by_id.get(canonical_id)
            zero_allowed = zero is not None
            if zero_allowed:
                if profile_id not in {17, 18}:
                    raise ProfileError(
                        f"non-P17/P18 zero cardinality owner at graph node {index}"
                    )
                if (
                    zero["index"] != index
                    or zero["profile_id"] != profile_id
                    or zero["dst_name"] != descriptor.get("name")
                    or zero["src0_name"] != src0_descriptor.get("name")
                ):
                    raise ProfileError(
                        f"zero cardinality ID/index/profile/name binding mismatch at graph node {index}"
                    )
            row = {
                "canonical_id": canonical_id,
                "graph_node_index": index,
                "profile_id": profile_id,
                "dst_name": descriptor.get("name"),
                "src0_name": src0_descriptor.get("name"),
                "zero_cardinality_allowed": zero_allowed,
            }
            if not isinstance(row["dst_name"], str) or not isinstance(
                row["src0_name"], str
            ):
                raise ProfileError(f"canonical graph node {index} name missing")
            if canonical_id in seen_ids:
                raise ProfileError(f"duplicate F32 canonical ID {canonical_id}")
            seen_ids.add(canonical_id)
            eligible_rows.append(row)

    eligible_rows.sort(key=lambda row: row["graph_node_index"])
    if len(eligible_rows) != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError(
            f"F32 canonical allowlist count mismatch: {len(eligible_rows)}"
        )
    if len({row["graph_node_index"] for row in eligible_rows}) != len(
        eligible_rows
    ):
        raise ProfileError("duplicate F32 canonical graph index")
    zero_eligible = [
        row for row in eligible_rows if row["zero_cardinality_allowed"]
    ]
    if len(zero_eligible) != 36:
        raise ProfileError("F32 zero allowlist must contain exactly 36 rows")
    if {
        profile_id: sum(row["profile_id"] == profile_id for row in zero_eligible)
        for profile_id in (17, 18)
    } != {17: 18, 18: 18}:
        raise ProfileError("F32 zero allowlist P17/P18 census mismatch")
    allowlist_sha256 = canonical_sha256(eligible_rows)
    if allowlist_sha256 != F32_CANONICAL_ALLOWLIST_SHA256:
        raise ProfileError(
            "F32 canonical allowlist digest mismatch: " + allowlist_sha256
        )
    return {
        "schema": "qwen-f32-alu-canonical-bundle-v1",
        "bootstrap_manifest_sha256": MANIFEST_SHA256,
        "steady_manifest_sha256": qwen_graph_manifest.STEADY_MANIFEST_SHA256,
        "bundle_sha256": bundle_result.bundle_sha256,
        "canonical_allowlist_sha256": allowlist_sha256,
        "canonical_node_count": len(eligible_rows),
        "zero_cardinality_count": len(zero_eligible),
        "zero_profile_counts": {"P17": 18, "P18": 18},
        "canonical_nodes": eligible_rows,
    }


def render_canonical_header(bundle: Mapping[str, Any]) -> str:
    rows = bundle.get("canonical_nodes")
    if not isinstance(rows, list) or len(rows) != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError("cannot render malformed F32 canonical bundle")
    lines = [
        "// Generated by scripts/qwen_f32_alu_profiles.py; do not edit.",
        "#ifndef QWEN_F32_ALU_MANIFEST_GENERATED_H",
        "#define QWEN_F32_ALU_MANIFEST_GENERATED_H",
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "",
        "namespace ggml_npu_generated {",
        "",
        "struct qwen_f32_alu_canonical_node {",
        "    const char * canonical_id_hex;",
        "    std::uint64_t graph_node_index;",
        "    std::uint32_t profile_id;",
        "    const char * dst_name;",
        "    const char * src0_name;",
        "    bool zero_cardinality_allowed;",
        "};",
        "",
        f"inline constexpr std::size_t kQwenF32AluCanonicalNodeCount = {ELIGIBLE_IDENTITY_COUNT}ULL;",
        "inline constexpr std::size_t kQwenF32AluZeroCardinalityCount = 36ULL;",
        f"inline constexpr char kQwenF32AluBootstrapManifestSha256[] = \"{MANIFEST_SHA256}\";",
        f"inline constexpr char kQwenF32AluSteadyManifestSha256[] = \"{qwen_graph_manifest.STEADY_MANIFEST_SHA256}\";",
        f"inline constexpr char kQwenF32AluCanonicalAllowlistSha256[] = \"{bundle['canonical_allowlist_sha256']}\";",
        "",
        f"inline constexpr std::array<qwen_f32_alu_canonical_node, {ELIGIBLE_IDENTITY_COUNT}> kQwenF32AluCanonicalNodes = {{{{",
    ]
    for row in rows:
        lines.append(
            "    {"
            f"{json.dumps(row['canonical_id'])}, "
            f"{row['graph_node_index']}ULL, "
            f"{row['profile_id']}U, "
            f"{json.dumps(row['dst_name'])}, "
            f"{json.dumps(row['src0_name'])}, "
            f"{str(row['zero_cardinality_allowed']).lower()}"
            "},"
        )
    lines.extend([
        "}};",
        "",
        "static_assert(kQwenF32AluCanonicalNodes.size() == kQwenF32AluCanonicalNodeCount);",
        "",
        "} // namespace ggml_npu_generated",
        "",
        "#endif",
        "",
    ])
    return "\n".join(lines)


def load_manifest(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ProfileError(f"cannot load manifest {path}: {error}") from error
    if not isinstance(payload, dict):
        raise ProfileError("manifest envelope must be an object")
    return payload


def _first_candidate(envelope: Mapping[str, Any], op: str | None = None) -> dict[str, Any]:
    nodes = envelope["manifest"]["nodes"]
    for node in nodes:
        node_op = node.get("descriptor", {}).get("op_name")
        if node_op in {"ADD", "MUL", "SUB", "SCALE"} and (op is None or node_op == op):
            return node
    raise ProfileError("mutation fixture candidate missing")


def mutation_self_test(envelope: Mapping[str, Any]) -> dict[str, Any]:
    baseline = audit_manifest_object(envelope)
    if baseline["eligible_identity_count"] != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError("mutation baseline failed")

    mutations: list[tuple[str, Any]] = []

    missing = copy.deepcopy(envelope)
    missing_nodes = missing["manifest"]["nodes"]
    victim = _first_candidate(missing)
    missing_nodes.remove(victim)
    mutations.append(("missing", missing))

    extra = copy.deepcopy(envelope)
    extra_node = copy.deepcopy(_first_candidate(extra))
    extra_node["canonical_id"] = "f" * 64
    extra_node["index"] = 999999
    extra["manifest"]["nodes"].append(extra_node)
    mutations.append(("extra", extra))

    duplicate = copy.deepcopy(envelope)
    duplicate_candidates = [
        node for node in duplicate["manifest"]["nodes"]
        if node.get("descriptor", {}).get("op_name") in {"ADD", "MUL", "SUB", "SCALE"}
    ]
    duplicate_candidates[1]["canonical_id"] = duplicate_candidates[0]["canonical_id"]
    mutations.append(("duplicate", duplicate))

    op_mutation = copy.deepcopy(envelope)
    _first_candidate(op_mutation, "ADD")["descriptor"]["op_name"] = "MUL"
    mutations.append(("op", op_mutation))

    shape = copy.deepcopy(envelope)
    _first_candidate(shape)["descriptor"]["ne"][0] += 1
    mutations.append(("shape", shape))

    stride = copy.deepcopy(envelope)
    _first_candidate(stride)["descriptor"]["nb"][0] += 4
    mutations.append(("nb", stride))

    view = copy.deepcopy(envelope)
    view_descriptor = _first_candidate(view)["descriptor"]
    view_descriptor["view_src"] = (
        None if view_descriptor.get("view_src") is not None else {"index": 0, "kind": "external"}
    )
    mutations.append(("view", view))

    offset = copy.deepcopy(envelope)
    _first_candidate(offset)["descriptor"]["view_offs"] += 4
    mutations.append(("view_off", offset))

    op_params = copy.deepcopy(envelope)
    _first_candidate(op_params)["descriptor"]["op_params_hex"] = "01" + "00" * 63
    mutations.append(("op_params", op_params))

    source_shape = copy.deepcopy(envelope)
    _first_candidate(source_shape)["sources"][0]["descriptor"]["ne"][0] += 1
    mutations.append(("source_shape", source_shape))

    payload_stale = copy.deepcopy(envelope)
    payload_stale["manifest"]["header"]["bindings"]["profile"] += "-tampered"
    mutations.append(("payload_stale_envelope_hash", payload_stale))

    raw_source_hash = copy.deepcopy(envelope)
    raw_source_hash["manifest"]["raw_sha256"] = "0" * 64
    mutations.append(("raw_source_hash", raw_source_hash))

    semantic_key = copy.deepcopy(envelope)
    semantic_node = _first_candidate(semantic_key)
    semantic_node["semantic_key"]["path"] += ".tampered"
    mutations.append(("semantic_key", semantic_key))

    descriptor_source = copy.deepcopy(envelope)
    _first_candidate(descriptor_source)["sources"][0]["descriptor"]["nb"][0] += 4
    mutations.append(("descriptor_source", descriptor_source))

    stale_descriptor_hash = copy.deepcopy(envelope)
    _first_candidate(stale_descriptor_hash)["descriptor_sha256"] = "0" * 64
    mutations.append(("stale_descriptor_sha256", stale_descriptor_hash))

    fake_identities = copy.deepcopy(envelope)
    fake_index = 0
    for node in fake_identities["manifest"]["nodes"]:
        if node.get("classification") == "compute" and node.get(
            "descriptor", {}
        ).get("op_name") in {"ADD", "MUL", "SUB", "SCALE"}:
            node["canonical_id"] = hashlib.sha256(
                f"v4-fake-canonical-id:{fake_index}".encode("ascii")
            ).hexdigest()
            fake_index += 1
    if fake_index != ELIGIBLE_IDENTITY_COUNT:
        raise ProfileError("fake identity mutation fixture cardinality mismatch")
    mutations.append(("fake_distinct_identities", fake_identities))

    identity_substitution = copy.deepcopy(envelope)
    substitution_candidates = [
        node
        for node in identity_substitution["manifest"]["nodes"]
        if node.get("classification") == "compute"
        and node.get("descriptor", {}).get("op_name")
        in {"ADD", "MUL", "SUB", "SCALE"}
    ]
    substitution_candidates[0]["canonical_id"], substitution_candidates[1][
        "canonical_id"
    ] = (
        substitution_candidates[1]["canonical_id"],
        substitution_candidates[0]["canonical_id"],
    )
    mutations.append(("profile_identity_substitution", identity_substitution))

    rejected: list[str] = []
    for name, mutated in mutations:
        try:
            audit_manifest_object(mutated)
        except ProfileError:
            rejected.append(name)
        else:
            raise ProfileError(f"manifest mutation unexpectedly accepted: {name}")

    collision_profiles = list(PROFILES)
    collision_profiles[-1] = dataclasses.replace(
        collision_profiles[-1],
        profile_id=18,
        op=collision_profiles[-2].op,
        vector_op=collision_profiles[-2].vector_op,
        dst=collision_profiles[-2].dst,
        src0=collision_profiles[-2].src0,
        src1=collision_profiles[-2].src1,
        scalar0=collision_profiles[-2].scalar0,
    )
    try:
        validate_profiles(collision_profiles)
    except ProfileError:
        rejected.append("profile_collision")
    else:
        raise ProfileError("profile collision mutation unexpectedly accepted")

    for profile in PROFILES:
        expected = profile.permissions
        mutated = (expected[0] ^ 1, expected[1], expected[2])
        if permission_accepted(profile, *mutated):
            raise ProfileError(f"{profile.name}: permission mutation accepted")
    rejected.append("permission")

    return {
        "schema": "qwen-f32-alu-profile-mutation-self-test-v4",
        "baseline_eligible": baseline["eligible_identity_count"],
        "baseline_identity_set_sha256": baseline[
            "canonical_identity_set_sha256"
        ],
        "rejected_mutations": rejected,
        "rejected_mutation_count": len(rejected),
        "representative_stage_mutations": (
            representative_stage_mutation_self_test()
        ),
    }


def write_json(path: pathlib.Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8"
    )


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    if argv and argv[0] == "emit-header":
        parser = argparse.ArgumentParser()
        parser.add_argument("command")
        parser.add_argument(
            "--bootstrap-manifest", type=pathlib.Path, required=True
        )
        parser.add_argument("--steady-manifest", type=pathlib.Path, required=True)
        parser.add_argument("--output", type=pathlib.Path, required=True)
        return parser.parse_args(argv)
    parser = argparse.ArgumentParser()
    parser.set_defaults(command="legacy-audit")
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--mutation-output", type=pathlib.Path)
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if arguments.command == "emit-header":
            bootstrap = load_manifest(arguments.bootstrap_manifest)
            steady = load_manifest(arguments.steady_manifest)
            bundle = audit_manifest_bundle_object(bootstrap, steady)
            output = arguments.output.resolve()
            output.parent.mkdir(parents=True, exist_ok=True)
            temporary = output.with_suffix(output.suffix + ".tmp")
            temporary.write_text(render_canonical_header(bundle), encoding="utf-8")
            temporary.replace(output)
            print(
                "[NPU-QWEN-F32-ALU-CANONICAL][PASS] "
                f"nodes={bundle['canonical_node_count']} "
                f"zero={bundle['zero_cardinality_count']} "
                "p17=18 p18=18 "
                f"allowlist_sha256={bundle['canonical_allowlist_sha256']} "
                f"bundle_sha256={bundle['bundle_sha256']}"
            )
            return 0
        envelope = load_manifest(arguments.manifest)
        census = audit_manifest_object(envelope)
        write_json(arguments.output, census)
        if arguments.self_test:
            mutation = mutation_self_test(envelope)
            if arguments.mutation_output is None:
                raise ProfileError("--self-test requires --mutation-output")
            write_json(arguments.mutation_output, mutation)
    except ProfileError as error:
        print(f"[NPU-QWEN-F32-ALU-PROFILES][FAIL] {error}", file=sys.stderr)
        return 1
    print(
        "[NPU-QWEN-F32-ALU-PROFILES][PASS] "
        f"profiles={PROFILE_COUNT} eligible={ELIGIBLE_IDENTITY_COUNT} "
        "ops=84+211+18+54 permissions=binary-01/01/10,scale-01/00/10 "
        f"identity_set_sha256={CANONICAL_IDENTITY_SET_SHA256} "
        "predecessor_representative_passed="
        f"{PREDECESSOR_REPRESENTATIVE_TRANSACTIONS_PASSED} "
        "verified_canonical_completed="
        f"{VERIFIED_CANONICAL_IDENTITIES_COMPLETED} "
        f"remaining={REMAINING_NONMETADATA_GAP}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
