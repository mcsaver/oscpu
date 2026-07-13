#!/usr/bin/env python3
"""T3K CSR probe isolation source-contract helpers.

The parser is intentionally small and fail-closed.  It understands only the
Verilog constructs used by the five modules in this slice; unsupported or
ambiguous source is rejected instead of being guessed through.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterable


class ContractError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def require(condition: bool, code: str, message: str) -> None:
    if not condition:
        raise ContractError(code, message)


def strip_comments(text: str) -> str:
    """Remove Verilog comments while preserving strings and line numbers."""

    out: list[str] = []
    index = 0
    state = "code"
    while index < len(text):
        char = text[index]
        pair = text[index : index + 2]
        if state == "code":
            if pair == "//":
                out.extend("  ")
                index += 2
                state = "line"
                continue
            if pair == "/*":
                out.extend("  ")
                index += 2
                state = "block"
                continue
            out.append(char)
            if char == '"':
                state = "string"
            index += 1
            continue
        if state == "line":
            out.append("\n" if char == "\n" else " ")
            if char == "\n":
                state = "code"
            index += 1
            continue
        if state == "block":
            if pair == "*/":
                out.extend("  ")
                index += 2
                state = "code"
            else:
                out.append("\n" if char == "\n" else " ")
                index += 1
            continue
        out.append(char)
        if char == "\\" and index + 1 < len(text):
            out.append(text[index + 1])
            index += 2
        else:
            if char == '"':
                state = "code"
            index += 1
    require(state != "block", "E_PARSE_COMMENT", "unterminated block comment")
    require(state != "string", "E_PARSE_STRING", "unterminated string literal")
    return "".join(out)


def matching(text: str, start: int, opening: str = "(", closing: str = ")") -> int:
    require(start < len(text) and text[start] == opening, "E_PARSE_BALANCE", f"expected {opening} at {start}")
    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth == 0:
                return index
    raise ContractError("E_PARSE_BALANCE", f"unbalanced {opening}{closing} starting at {start}")


TOKEN_RE = re.compile(
    r"(?:\\[!-~]+)|(?:`[A-Za-z_][A-Za-z0-9_$]*)|(?:[A-Za-z_][A-Za-z0-9_$]*)|"
    r"(?:\d+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+)|(?:\d+)|"
    r"(?:===|!==|==|!=|&&|\|\||<=|>=|<<|>>|\+:|-:)|(?:\S)"
)


def tokens(expression: str) -> list[str]:
    return TOKEN_RE.findall(expression)


def compact(expression: str) -> str:
    return "".join(tokens(expression))


def unwrap(expression: str) -> str:
    current = expression.strip()
    while current.startswith("("):
        end = matching(current, 0)
        if end != len(current) - 1:
            break
        current = current[1:-1].strip()
    return current


def split_top(expression: str, operator: str) -> list[str]:
    """Split an expression on a top-level textual operator."""

    result: list[str] = []
    start = 0
    depth = 0
    index = 0
    while index < len(expression):
        char = expression[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
            require(depth >= 0, "E_PARSE_EXPR", f"unbalanced expression: {expression}")
        elif depth == 0 and expression.startswith(operator, index):
            result.append(expression[start:index].strip())
            index += len(operator)
            start = index
            continue
        index += 1
    require(depth == 0, "E_PARSE_EXPR", f"unbalanced expression: {expression}")
    result.append(expression[start:].strip())
    return result


def associative_terms(expression: str, operator: str) -> list[str]:
    result: list[str] = []
    for term in split_top(unwrap(expression), operator):
        nested = split_top(unwrap(term), operator)
        if len(nested) > 1:
            result.extend(associative_terms(term, operator))
        else:
            result.append(unwrap(term))
    return result


def split_args(argument_text: str) -> list[str]:
    return split_top(argument_text, ",") if argument_text.strip() else []


def exact_call(expression: str, function_name: str) -> list[str] | None:
    raw = unwrap(expression)
    match = re.fullmatch(rf"{re.escape(function_name)}\s*\((.*)\)", raw, flags=re.DOTALL)
    if not match:
        return None
    open_at = raw.find("(")
    if matching(raw, open_at) != len(raw) - 1:
        return None
    return [unwrap(item) for item in split_args(match.group(1))]


def identifiers(expression: str) -> set[str]:
    result: set[str] = set()
    for token in tokens(expression):
        if token.startswith("`") or token.startswith("\\"):
            continue
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", token):
            if token not in {"if", "else", "begin", "end", "wire", "reg"}:
                result.add(token)
    return result


@dataclass(frozen=True)
class ModuleSource:
    path: Path
    name: str
    raw: str
    source: str
    header: str

    @classmethod
    def load(cls, path: Path, name: str) -> "ModuleSource":
        raw = path.read_text(encoding="utf-8")
        source = strip_comments(raw)
        match = re.search(rf"\bmodule\s+{re.escape(name)}\b", source)
        require(match is not None, "E_MODULE_MISSING", f"module {name} missing in {path}")
        cursor = match.end()
        parameter_match = re.match(r"\s*#\s*", source[cursor:])
        if parameter_match is not None:
            parameter_open = source.find("(", cursor + parameter_match.end())
            require(parameter_open >= 0, "E_MODULE_PARAMETER", f"module {name} has malformed parameters")
            cursor = matching(source, parameter_open) + 1
        open_at = source.find("(", cursor)
        require(open_at >= 0, "E_MODULE_HEADER", f"module {name} lacks an ANSI port list")
        close_at = matching(source, open_at)
        semicolon = source.find(";", close_at)
        require(semicolon >= 0, "E_MODULE_HEADER", f"module {name} header lacks semicolon")
        end_match = re.search(r"\bendmodule\b", source[semicolon + 1 :])
        require(end_match is not None, "E_MODULE_END", f"module {name} lacks endmodule")
        end_at = semicolon + 1 + end_match.end()
        return cls(path.resolve(), name, raw, source[match.start() : end_at], source[open_at + 1 : close_at])

    def require_port(self, direction: str, name: str) -> None:
        declarations = re.findall(rf"\b{direction}\b([^,;()]*)\b{re.escape(name)}\b", self.header)
        require(
            len(declarations) == 1,
            "E_PORT",
            f"{self.name} must declare exactly one {direction} {name}, got {len(declarations)}",
        )

    def assignments(self) -> dict[str, str]:
        found: dict[str, list[str]] = {}
        for match in re.finditer(r"\bassign\s+([A-Za-z_][A-Za-z0-9_$]*)\s*=", self.source):
            semicolon = self.source.find(";", match.end())
            require(semicolon >= 0, "E_ASSIGN_END", f"unterminated assign {match.group(1)} in {self.path}")
            found.setdefault(match.group(1), []).append(self.source[match.end() : semicolon].strip())
        wire_pattern = re.compile(
            r"\bwire\s+(?:\[[^;]+?\]\s*)?([A-Za-z_][A-Za-z0-9_$]*)\s*=([^;]+);",
            flags=re.DOTALL,
        )
        for match in wire_pattern.finditer(self.source):
            found.setdefault(match.group(1), []).append(match.group(2).strip())
        duplicates = {name: values for name, values in found.items() if len(values) != 1}
        require(not duplicates, "E_ASSIGN_DUPLICATE", f"ambiguous continuous assignments in {self.path}: {list(duplicates)}")
        return {name: values[0] for name, values in found.items()}

    def assignment(self, name: str) -> str:
        value = self.assignments().get(name)
        require(value is not None, "E_ASSIGN_MISSING", f"{self.name} lacks one continuous assignment for {name}")
        return value

    def instance_connections(self, module_name: str) -> dict[str, str]:
        pattern = re.compile(rf"\b{re.escape(module_name)}\b\s+(?:#\s*\()?")
        starts = list(pattern.finditer(self.source))
        require(len(starts) == 1, "E_INSTANCE_COUNT", f"{self.name} must instantiate {module_name} exactly once, got {len(starts)}")
        cursor = starts[0].end()
        if "#" in starts[0].group(0):
            parameter_open = self.source.find("(", starts[0].start())
            cursor = matching(self.source, parameter_open) + 1
        instance_match = re.match(r"\s*[A-Za-z_][A-Za-z0-9_$]*\s*", self.source[cursor:])
        require(instance_match is not None, "E_INSTANCE_NAME", f"cannot parse {module_name} instance in {self.path}")
        cursor += instance_match.end()
        open_at = self.source.find("(", cursor)
        require(open_at >= 0, "E_INSTANCE_PORTS", f"cannot parse {module_name} ports in {self.path}")
        close_at = matching(self.source, open_at)
        body = self.source[open_at + 1 : close_at]
        connections: dict[str, str] = {}
        for item in split_top(body, ","):
            item = item.strip()
            match = re.fullmatch(r"\.([A-Za-z_][A-Za-z0-9_$]*)\s*\((.*)\)", item, flags=re.DOTALL)
            require(match is not None, "E_INSTANCE_NAMED_PORT", f"non-named or malformed port in {module_name}: {item}")
            port = match.group(1)
            require(port not in connections, "E_INSTANCE_PORT_DUP", f"duplicate .{port} on {module_name}")
            connections[port] = match.group(2).strip()
        return connections

    def functions(self, name: str) -> list[str]:
        result: list[str] = []
        for match in re.finditer(r"\bfunction\b", self.source):
            end_match = re.search(r"\bendfunction\b", self.source[match.end() :])
            require(end_match is not None, "E_FUNCTION_END", f"unterminated function in {self.path}")
            end_at = match.end() + end_match.end()
            block = self.source[match.start() : end_at]
            header = block[: block.find(";") + 1]
            if re.search(rf"\b{re.escape(name)}\b", header):
                result.append(block)
        return result

    def dependency_closure(self, roots: Iterable[str]) -> set[str]:
        assignments = self.assignments()
        seen: set[str] = set()
        pending = list(roots)
        while pending:
            name = pending.pop()
            if name in seen:
                continue
            seen.add(name)
            if name in assignments:
                pending.extend(sorted(identifiers(assignments[name]) - seen))
        return seen


@dataclass(frozen=True)
class T3KSource:
    mux: ModuleSource
    control: ModuleSource
    glue: ModuleSource
    top: ModuleSource
    csr: ModuleSource

    @classmethod
    def load(
        cls,
        mux: Path,
        control: Path,
        glue: Path,
        top: Path,
        csr: Path,
    ) -> "T3KSource":
        return cls(
            ModuleSource.load(mux, "OooCsrAccessRequestMux"),
            ModuleSource.load(control, "OooControlPlane"),
            ModuleSource.load(glue, "OooCoreTopGlue"),
            ModuleSource.load(top, "NpcCoreTop"),
            ModuleSource.load(csr, "CsrFile"),
        )


def source_paths(root: Path) -> tuple[Path, Path, Path, Path, Path]:
    vsrc = root / "npc/rv64/vsrc"
    return (
        vsrc / "control/OooCsrAccessRequestMux.v",
        vsrc / "control/OooControlPlane.v",
        vsrc / "core/OooCoreTopGlue.v",
        vsrc / "core/NpcCoreTop.v",
        vsrc / "core/CsrFile.v",
    )


def replace_unique(source: str, old: str, new: str, code: str = "E_MUTATION_REPLACE") -> str:
    count = source.count(old)
    require(count == 1, code, f"replacement premise count={count}, wanted 1: {old}")
    return source.replace(old, new, 1)
