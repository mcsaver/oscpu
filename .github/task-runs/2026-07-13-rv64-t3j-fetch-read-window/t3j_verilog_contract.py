#!/usr/bin/env python3
"""T3J source-contract parser shared by structure, proof and mutation gates.

This is intentionally a small fail-closed parser for the Verilog subset used by
the T3J contract.  It strips comments, walks module/instance structure and
parses logical expressions into an AST; a textual token hit is never accepted
as proof that a signal actually drives the required port or assignment.
"""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
import re
from pathlib import Path
from typing import Iterable, Iterator, Mapping, Sequence


class ContractError(RuntimeError):
    """A fail-closed source-contract extraction or validation failure."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def require(condition: bool, code: str, message: str) -> None:
    if not condition:
        raise ContractError(code, message)


@dataclass(frozen=True)
class Token:
    value: str
    start: int
    end: int


@dataclass(frozen=True)
class LocatedExpr:
    text: str
    start: int
    end: int


@dataclass(frozen=True)
class Expr:
    op: str
    args: tuple[object, ...]


def ident(name: str) -> Expr:
    return Expr("id", (name,))


def const(text: str) -> Expr:
    return Expr("const", (text,))


def unary(op: str, item: Expr) -> Expr:
    return Expr(op, (item,))


def binary(op: str, left: Expr, right: Expr) -> Expr:
    return Expr(op, (left, right))


TOKEN_RE = re.compile(
    r'''\s+|"(?:\\.|[^"\\])*"|'''
    r"(?:\d+)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+|"
    r"'[01xXzZ]|\d+|"
    r"`?[A-Za-z_$][A-Za-z0-9_$]*|"
    r"&&|\|\||==|!=|<=|>=|<<|>>|"
    r".",
    re.DOTALL,
)


def strip_comments(text: str) -> str:
    """Remove comments while preserving byte offsets and line boundaries."""

    chars = list(text)
    index = 0
    in_string = False
    escaped = False
    while index < len(chars):
        char = chars[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            index += 1
            continue
        if char == "/" and index + 1 < len(chars) and chars[index + 1] == "/":
            chars[index] = chars[index + 1] = " "
            index += 2
            while index < len(chars) and chars[index] not in "\r\n":
                chars[index] = " "
                index += 1
            continue
        if char == "/" and index + 1 < len(chars) and chars[index + 1] == "*":
            chars[index] = chars[index + 1] = " "
            index += 2
            closed = False
            while index < len(chars):
                if chars[index] == "*" and index + 1 < len(chars) and chars[index + 1] == "/":
                    chars[index] = chars[index + 1] = " "
                    index += 2
                    closed = True
                    break
                if chars[index] not in "\r\n":
                    chars[index] = " "
                index += 1
            require(closed, "E_PARSE_COMMENT", "unterminated block comment")
            continue
        index += 1
    require(not in_string, "E_PARSE_STRING", "unterminated string literal")
    return "".join(chars)


def tokenize(text: str, offset: int = 0) -> list[Token]:
    result: list[Token] = []
    for match in TOKEN_RE.finditer(text):
        value = match.group(0)
        if value.isspace():
            continue
        result.append(Token(value, offset + match.start(), offset + match.end()))
    return result


def is_identifier(value: str) -> bool:
    return re.fullmatch(r"`?[A-Za-z_$][A-Za-z0-9_$]*", value) is not None


def matching_token(tokens: Sequence[Token], start: int, opener: str, closer: str) -> int:
    require(tokens[start].value == opener, "E_PARSE_DELIMITER", f"expected {opener}")
    depth = 0
    for index in range(start, len(tokens)):
        value = tokens[index].value
        if value == opener:
            depth += 1
        elif value == closer:
            depth -= 1
            if depth == 0:
                return index
            require(depth >= 0, "E_PARSE_DELIMITER", f"unbalanced {opener}{closer}")
    raise ContractError("E_PARSE_DELIMITER", f"unterminated {opener}{closer}")


def find_semicolon(tokens: Sequence[Token], start: int) -> int:
    for index in range(start, len(tokens)):
        if tokens[index].value == ";":
            return index
    raise ContractError("E_PARSE_STATEMENT", "unterminated Verilog statement")


class ExprParser:
    def __init__(self, tokens: Sequence[Token]):
        self.tokens = list(tokens)
        self.index = 0

    def peek(self) -> str | None:
        if self.index >= len(self.tokens):
            return None
        return self.tokens[self.index].value

    def consume(self, expected: str | None = None) -> Token:
        require(self.index < len(self.tokens), "E_EXPR_EOF", "unexpected end of expression")
        token = self.tokens[self.index]
        if expected is not None:
            require(token.value == expected, "E_EXPR_TOKEN", f"expected {expected}, got {token.value}")
        self.index += 1
        return token

    def parse(self) -> Expr:
        expression = self.parse_or()
        require(self.peek() is None, "E_EXPR_TRAILING", f"unsupported trailing token {self.peek()}")
        return expression

    def parse_or(self) -> Expr:
        result = self.parse_and()
        while self.peek() == "||":
            self.consume()
            result = binary("or", result, self.parse_and())
        return result

    def parse_and(self) -> Expr:
        result = self.parse_equality()
        while self.peek() == "&&":
            self.consume()
            result = binary("and", result, self.parse_equality())
        return result

    def parse_equality(self) -> Expr:
        result = self.parse_unary()
        while self.peek() in ("==", "!="):
            operator = self.consume().value
            result = binary("eq" if operator == "==" else "ne", result, self.parse_unary())
        return result

    def parse_unary(self) -> Expr:
        if self.peek() == "!":
            self.consume()
            return unary("not", self.parse_unary())
        return self.parse_primary()

    def parse_primary(self) -> Expr:
        value = self.peek()
        require(value is not None, "E_EXPR_PRIMARY", "missing expression operand")
        if value == "(":
            self.consume()
            result = self.parse_or()
            self.consume(")")
            return result
        token = self.consume()
        if is_identifier(token.value):
            return ident(token.value)
        if re.fullmatch(r"(?:\d+)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+|'[01xXzZ]|\d+", token.value):
            return const(token.value)
        raise ContractError("E_EXPR_PRIMARY", f"unsupported expression token {token.value}")


def parse_expr(text: str) -> Expr:
    return ExprParser(tokenize(text)).parse()


def expr_canonical(expression: Expr) -> str:
    if expression.op in ("id", "const"):
        return str(expression.args[0])
    if expression.op == "not":
        return f"(!{expr_canonical(expression.args[0])})"
    symbol = {"and": "&&", "or": "||", "eq": "==", "ne": "!="}[expression.op]
    return f"({expr_canonical(expression.args[0])}{symbol}{expr_canonical(expression.args[1])})"


def flatten(expression: Expr, operator: str) -> list[Expr]:
    if expression.op != operator:
        return [expression]
    return flatten(expression.args[0], operator) + flatten(expression.args[1], operator)


def normalized_commutative(expression: Expr) -> str:
    if expression.op in ("and", "or"):
        members = sorted(normalized_commutative(item) for item in flatten(expression, expression.op))
        return f"{expression.op}({','.join(members)})"
    if expression.op in ("eq", "ne"):
        members = sorted(normalized_commutative(item) for item in expression.args)
        return f"{expression.op}({','.join(members)})"
    if expression.op == "not":
        return f"not({normalized_commutative(expression.args[0])})"
    return expr_canonical(expression)


def substitute(expression: Expr, replacements: Mapping[str, Expr]) -> Expr:
    if expression.op == "id" and expression.args[0] in replacements:
        return replacements[str(expression.args[0])]
    if expression.op in ("id", "const"):
        return expression
    return Expr(expression.op, tuple(substitute(item, replacements) for item in expression.args))


def verilog_int(text: str) -> int:
    raw = text.replace("_", "")
    if raw.startswith("'") and len(raw) == 2:
        require(raw[1].lower() not in ("x", "z"), "E_CONST_XZ", f"unknown literal {text}")
        return int(raw[1])
    if "'" not in raw:
        return int(raw, 10)
    _width, digits = raw.split("'", 1)
    if digits and digits[0] in "sS":
        digits = digits[1:]
    require(len(digits) >= 2, "E_CONST_LITERAL", f"malformed literal {text}")
    base_char, value = digits[0].lower(), digits[1:]
    require(not set(value.lower()) & {"x", "z", "?"}, "E_CONST_XZ", f"unknown literal {text}")
    base = {"b": 2, "o": 8, "d": 10, "h": 16}.get(base_char)
    require(base is not None, "E_CONST_BASE", f"unsupported literal {text}")
    return int(value, base)


@dataclass
class VerilogModule:
    path: Path
    source: str
    clean: str
    name: str
    start: int
    end: int
    tokens: list[Token]

    @classmethod
    def load(cls, path: Path, name: str) -> "VerilogModule":
        source = path.read_text(encoding="utf-8")
        clean = strip_comments(source)
        all_tokens = tokenize(clean)
        matches: list[tuple[int, int]] = []
        for index, token in enumerate(all_tokens[:-1]):
            if token.value == "module" and all_tokens[index + 1].value == name:
                for end_index in range(index + 2, len(all_tokens)):
                    if all_tokens[end_index].value == "endmodule":
                        matches.append((index, end_index))
                        break
        require(len(matches) == 1, "E_MODULE_COUNT", f"expected one module {name}, found {len(matches)}")
        begin_index, end_index = matches[0]
        start = all_tokens[begin_index].start
        end = all_tokens[end_index].end
        tokens = [token for token in all_tokens if start <= token.start and token.end <= end]
        return cls(path, source, clean, name, start, end, tokens)

    def text(self, located: LocatedExpr) -> str:
        return self.source[located.start:located.end]

    def assignments(self) -> dict[str, LocatedExpr]:
        found: dict[str, list[LocatedExpr]] = {}
        tokens = self.tokens
        index = 0
        while index < len(tokens):
            kind = tokens[index].value
            if kind not in ("assign", "wire"):
                index += 1
                continue
            end_index = find_semicolon(tokens, index + 1)
            statement = tokens[index + 1:end_index]
            equal_positions = [pos for pos, token in enumerate(statement) if token.value == "="]
            if equal_positions:
                require(len(equal_positions) == 1, "E_ASSIGN_SHAPE", f"multiple = tokens after {kind}")
                equal_position = equal_positions[0]
                lhs_ids = [token.value for token in statement[:equal_position] if is_identifier(token.value)]
                require(lhs_ids, "E_ASSIGN_LHS", f"missing LHS after {kind}")
                name = lhs_ids[-1]
                rhs_tokens = statement[equal_position + 1:]
                require(rhs_tokens, "E_ASSIGN_RHS", f"missing RHS for {name}")
                located = LocatedExpr(
                    self.source[tokens[index + 1 + equal_position].end:tokens[end_index].start],
                    tokens[index + 1 + equal_position].end,
                    tokens[end_index].start,
                )
                found.setdefault(name, []).append(located)
            index = end_index + 1
        duplicates = {name: len(items) for name, items in found.items() if len(items) != 1}
        require(not duplicates, "E_ASSIGN_DUPLICATE", f"duplicate continuous assignments: {duplicates}")
        return {name: items[0] for name, items in found.items()}

    def numeric_localparams(self) -> dict[str, int]:
        result: dict[str, int] = {}
        tokens = self.tokens
        index = 0
        while index < len(tokens):
            if tokens[index].value != "localparam":
                index += 1
                continue
            end_index = find_semicolon(tokens, index + 1)
            statement = tokens[index + 1:end_index]
            equal_positions = [pos for pos, token in enumerate(statement) if token.value == "="]
            if len(equal_positions) == 1:
                eq_pos = equal_positions[0]
                lhs_ids = [token.value for token in statement[:eq_pos] if is_identifier(token.value)]
                rhs = statement[eq_pos + 1:]
                if lhs_ids and len(rhs) == 1:
                    try:
                        result[lhs_ids[-1]] = verilog_int(rhs[0].value)
                    except (ContractError, ValueError):
                        pass
            index = end_index + 1
        return result

    def reg_width(self, signal: str) -> int:
        pattern = re.compile(
            rf"\breg\s*\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*{re.escape(signal)}\b"
        )
        matches = list(pattern.finditer(self.clean[self.start:self.end]))
        require(len(matches) == 1, "E_REG_WIDTH", f"expected one constant-width declaration for {signal}")
        high, low = int(matches[0].group(1)), int(matches[0].group(2))
        return abs(high - low) + 1

    def ansi_ports(self) -> Counter[tuple[str, str]]:
        tokens = self.tokens
        module_index = next(index for index, token in enumerate(tokens) if token.value == "module")
        index = module_index + 2
        if tokens[index].value == "#":
            require(tokens[index + 1].value == "(", "E_PORT_HEADER", "malformed parameter list")
            index = matching_token(tokens, index + 1, "(", ")") + 1
        require(tokens[index].value == "(", "E_PORT_HEADER", "ANSI port list missing")
        close = matching_token(tokens, index, "(", ")")
        segments: list[list[Token]] = []
        current: list[Token] = []
        depth = 0
        for token in tokens[index + 1:close]:
            if token.value in ("(", "[", "{"):
                depth += 1
            elif token.value in (")", "]", "}"):
                depth -= 1
            if token.value == "," and depth == 0:
                segments.append(current)
                current = []
            else:
                current.append(token)
        segments.append(current)
        result: Counter[tuple[str, str]] = Counter()
        for segment in segments:
            directions = [token.value for token in segment if token.value in ("input", "output", "inout")]
            ids = [token.value for token in segment if is_identifier(token.value)]
            if directions and ids:
                result[(directions[-1], ids[-1])] += 1
        return result

    def instance_connections(self, module_type: str, instance_name: str) -> dict[str, LocatedExpr]:
        tokens = self.tokens
        candidates: list[int] = []
        for index, token in enumerate(tokens):
            if token.value != module_type:
                continue
            cursor = index + 1
            if cursor < len(tokens) and tokens[cursor].value == "#":
                require(cursor + 1 < len(tokens) and tokens[cursor + 1].value == "(", "E_INSTANCE_PARAM", f"malformed {module_type} parameters")
                cursor = matching_token(tokens, cursor + 1, "(", ")") + 1
            if cursor + 1 < len(tokens) and tokens[cursor].value == instance_name and tokens[cursor + 1].value == "(":
                candidates.append(cursor + 1)
        require(len(candidates) == 1, "E_INSTANCE_COUNT", f"expected one {module_type} {instance_name}, found {len(candidates)}")
        open_index = candidates[0]
        close_index = matching_token(tokens, open_index, "(", ")")
        result: dict[str, LocatedExpr] = {}
        cursor = open_index + 1
        while cursor < close_index:
            if tokens[cursor].value == ",":
                cursor += 1
                continue
            require(tokens[cursor].value == ".", "E_INSTANCE_PORT", f"expected named port in {instance_name}")
            require(cursor + 2 < close_index and is_identifier(tokens[cursor + 1].value), "E_INSTANCE_PORT", f"malformed named port in {instance_name}")
            port = tokens[cursor + 1].value
            require(tokens[cursor + 2].value == "(", "E_INSTANCE_PORT", f"missing ( for port {port}")
            port_close = matching_token(tokens, cursor + 2, "(", ")")
            require(port_close <= close_index, "E_INSTANCE_PORT", f"port {port} crosses instance boundary")
            require(port not in result, "E_INSTANCE_PORT_DUP", f"duplicate port {port} in {instance_name}")
            start = tokens[cursor + 2].end
            end = tokens[port_close].start
            result[port] = LocatedExpr(self.source[start:end], start, end)
            cursor = port_close + 1
        return result

    def nonblocking_assignments(self, signal: str) -> list[tuple[int, LocatedExpr]]:
        result: list[tuple[int, LocatedExpr]] = []
        tokens = self.tokens
        for index in range(len(tokens) - 2):
            if tokens[index].value != signal or tokens[index + 1].value != "<=":
                continue
            end_index = find_semicolon(tokens, index + 2)
            start = tokens[index + 1].end
            end = tokens[end_index].start
            result.append((tokens[index].start, LocatedExpr(self.source[start:end], start, end)))
        return result

    def exact_if_begin_block(self, condition: Expr) -> tuple[int, int]:
        tokens = self.tokens
        matches: list[tuple[int, int]] = []
        wanted = normalized_commutative(condition)
        for index, token in enumerate(tokens[:-3]):
            if token.value != "if" or tokens[index + 1].value != "(":
                continue
            close = matching_token(tokens, index + 1, "(", ")")
            try:
                actual = ExprParser(tokens[index + 2:close]).parse()
            except ContractError:
                continue
            if normalized_commutative(actual) != wanted:
                continue
            require(close + 1 < len(tokens) and tokens[close + 1].value == "begin", "E_IF_BLOCK", f"if ({expr_canonical(condition)}) must use begin/end")
            depth = 0
            block_end = -1
            for cursor in range(close + 1, len(tokens)):
                if tokens[cursor].value == "begin":
                    depth += 1
                elif tokens[cursor].value == "end":
                    depth -= 1
                    if depth == 0:
                        block_end = cursor
                        break
            require(block_end >= 0, "E_IF_BLOCK", f"unterminated if block for {expr_canonical(condition)}")
            matches.append((tokens[close + 1].start, tokens[block_end].end))
        require(len(matches) == 1, "E_IF_BLOCK_COUNT", f"expected one exact if ({expr_canonical(condition)}) block, found {len(matches)}")
        return matches[0]


@dataclass
class T3JSource:
    bridge: VerilogModule
    cache: VerilogModule
    bridge_assignments: dict[str, LocatedExpr]
    cache_assignments: dict[str, LocatedExpr]
    cache_connections: dict[str, LocatedExpr]
    sram_connections: dict[str, LocatedExpr]

    @classmethod
    def load(cls, bridge_path: Path, cache_path: Path) -> "T3JSource":
        bridge = VerilogModule.load(bridge_path, "OooFetchAxiBridge")
        cache = VerilogModule.load(cache_path, "OooFetchPacketCache")
        return cls(
            bridge,
            cache,
            bridge.assignments(),
            cache.assignments(),
            bridge.instance_connections("OooFetchPacketCache", "u_fetch_packet_cache"),
            cache.instance_connections("Sram4096x199", "u_payload_sram"),
        )

    def bridge_assignment(self, name: str) -> LocatedExpr:
        require(name in self.bridge_assignments, "E_BRIDGE_ASSIGNMENT", f"bridge assignment {name} missing")
        return self.bridge_assignments[name]

    def cache_assignment(self, name: str) -> LocatedExpr:
        require(name in self.cache_assignments, "E_CACHE_ASSIGNMENT", f"cache assignment {name} missing")
        return self.cache_assignments[name]

    def bridge_port(self, name: str) -> LocatedExpr:
        require(name in self.cache_connections, "E_BRIDGE_CACHE_PORT", f"bridge cache port {name} missing")
        return self.cache_connections[name]

    def resolved_bridge_port(self, name: str) -> tuple[Expr, LocatedExpr]:
        located = self.bridge_port(name)
        expression = parse_expr(located.text)
        seen: set[str] = set()
        while expression.op == "id" and str(expression.args[0]) in self.bridge_assignments:
            alias = str(expression.args[0])
            require(alias not in seen, "E_ALIAS_CYCLE", f"bridge alias cycle at {alias}")
            seen.add(alias)
            located = self.bridge_assignments[alias]
            expression = parse_expr(located.text)
        return expression, located


def replace_located(source: str, located: LocatedExpr, replacement: str) -> str:
    require(0 <= located.start <= located.end <= len(source), "E_MUTATION_SPAN", "invalid replacement span")
    return source[:located.start] + replacement + source[located.end:]


def expected_state_term(name: str) -> str:
    return normalized_commutative(binary("eq", ident("state_q"), ident(name)))


def exact_terms(expression: Expr, operator: str) -> Counter[str]:
    return Counter(normalized_commutative(item) for item in flatten(expression, operator))


def source_paths(repo_root: Path) -> tuple[Path, Path]:
    return (
        repo_root / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
        repo_root / "npc/rv64/vsrc/cache/OooFetchPacketCache.v",
    )
