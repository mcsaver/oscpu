#!/usr/bin/env python3
"""Stable, artifact-legal identifiers shared by NPU compiler passes.

Buffer identifiers are the lowercase, unpadded RFC 4648 Base32 encoding of a
complete SHA-256 digest.  The node and external namespaces use different hash
domains, so equal identity bytes cannot alias across kinds.
"""

from __future__ import annotations

import base64
import hashlib
import json
import re
from collections.abc import Mapping
from typing import Any


_NODE_BUFFER_DOMAIN = b"npu.graph-ir.node-buffer.v1\x00"
_EXTERNAL_BUFFER_DOMAIN = b"npu.graph-ir.external-buffer.v1\x00"
_CANONICAL_ID_RE = re.compile(r"[0-9a-f]{64}\Z")
_DIGEST_BASE32_LENGTH = 52


def _canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def _digest_id(prefix: str, domain: bytes, identity: Any) -> str:
    digest = hashlib.sha256(domain + _canonical_bytes(identity)).digest()
    encoded = base64.b32encode(digest).decode("ascii").rstrip("=").lower()
    # A SHA-256 digest always occupies 52 unpadded Base32 characters.  Keep
    # this invariant explicit so a future digest/encoding change cannot
    # silently shorten an identity.
    if len(encoded) != _DIGEST_BASE32_LENGTH:
        raise AssertionError("complete SHA-256 Base32 encoding must be 52 characters")
    return f"{prefix}.{encoded}"


def node_buffer_id(canonical_id: str) -> str:
    """Return the stable GraphIR BufferId for one canonical manifest node."""

    if (
        not isinstance(canonical_id, str)
        or _CANONICAL_ID_RE.fullmatch(canonical_id) is None
    ):
        raise ValueError("canonical_id must be 64 lowercase hexadecimal characters")
    return _digest_id(
        "n",
        _NODE_BUFFER_DOMAIN,
        {"canonical_id": canonical_id},
    )


def external_buffer_id(index: int, descriptor: Mapping[str, Any]) -> str:
    """Return the stable GraphIR BufferId for one external tensor identity."""

    if type(index) is not int or index < 0:
        raise ValueError("external tensor index must be a non-negative integer")
    if not isinstance(descriptor, Mapping):
        raise TypeError("external tensor descriptor must be a mapping")
    return _digest_id(
        "e",
        _EXTERNAL_BUFFER_DOMAIN,
        {"index": index, "descriptor": dict(descriptor)},
    )


__all__ = ["external_buffer_id", "node_buffer_id"]
