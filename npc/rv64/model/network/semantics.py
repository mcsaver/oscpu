"""Unsigned state transitions shared by C++ and Verilog emitters.

State references mean old-Q; next-state is assigned once. Combinational nodes
are topologically sorted and checked before either backend is emitted.
"""
from dataclasses import dataclass
import re


def bits(n):
    return max(1, n.bit_length())


@dataclass(frozen=True)
class Expr:
    width: int
    op: str
    args: tuple = ()
    value: object = None


class IR:
    def __init__(self):
        self.inputs = {}
        self.regs = {}
        self.wires = {}
        self.next = {}
        self.outputs = {}
        self.assertions = []
        self.serial = 0

    @staticmethod
    def check_width(width):
        if not isinstance(width, int) or isinstance(width, bool) or not 1 <= width <= 64:
            raise ValueError("only unsigned widths 1..64 are supported")

    def name(self, name):
        if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*", name):
            raise ValueError("invalid signal name: " + name)
        if name in self.inputs or name in self.regs or name in self.wires:
            raise ValueError("duplicate signal: " + name)

    def const(self, value, width=1):
        self.check_width(width)
        if not isinstance(value, int) or not 0 <= value < (1 << width):
            raise ValueError("constant does not fit its unsigned type")
        return Expr(width, "const", value=value)

    def input(self, name, width=1):
        self.check_width(width)
        self.name(name)
        self.inputs[name] = width
        return Expr(width, "ref", value=name)

    def reg(self, name, width=1):
        self.check_width(width)
        self.name(name)
        self.regs[name] = width
        return Expr(width, "ref", value=name)

    def wire(self, name, expr):
        self.name(name)
        self.wires[name] = expr
        return Expr(expr.width, "ref", value=name)

    def op(self, op, width, *args):
        self.check_width(width)
        if not all(isinstance(a, Expr) for a in args):
            raise TypeError("IR operands must be typed expressions")
        self.serial += 1
        return self.wire("w" + str(self.serial), Expr(width, op, args))

    def inv(self, a):
        return self.op("not", a.width, a)

    def all(self, *args):
        value = self.const(1)
        for a in args:
            if a.width != 1:
                raise ValueError("logical predicate must be one bit")
            value = self.op("and", 1, value, a)
        return value

    def any(self, *args):
        value = self.const(0)
        for a in args:
            if a.width != 1:
                raise ValueError("logical predicate must be one bit")
            value = self.op("or", 1, value, a)
        return value

    def eq(self, a, b):
        if a.width != b.width:
            raise ValueError("comparison requires equal widths")
        return self.op("eq", 1, a, b)

    def lt(self, a, b):
        if a.width != b.width:
            raise ValueError("comparison requires equal widths")
        return self.op("lt", 1, a, b)

    def resize(self, a, width):
        return a if a.width == width else self.op("resize", width, a)

    def add(self, a, b, width):
        return self.op("add", width, self.resize(a, width), self.resize(b, width))

    def sub(self, a, b, width):
        return self.op("sub", width, self.resize(a, width), self.resize(b, width))

    def mux(self, condition, yes, no):
        if condition.width != 1 or yes.width != no.width:
            raise ValueError("mux requires boolean condition and equal branch types")
        return self.op("mux", yes.width, condition, yes, no)

    def update(self, reg, expression, rst):
        if reg.op != "ref" or reg.value not in self.regs or reg.width != expression.width:
            raise ValueError("invalid next-state assignment")
        if reg.value in self.next:
            raise ValueError("multiple next-state assignments")
        self.next[reg.value] = self.mux(rst, self.const(0, reg.width), expression)

    def output(self, name, expression):
        if name in self.outputs:
            raise ValueError("duplicate output")
        if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*", name):
            raise ValueError("invalid output name")
        self.outputs[name] = expression

    def validate(self):
        known = dict(self.inputs, **self.regs)
        ordered, visiting, complete = [], set(), set()

        def check(expr):
            self.check_width(expr.width)
            if expr.op == "const":
                if not 0 <= expr.value < 1 << expr.width:
                    raise ValueError("invalid constant")
            elif expr.op == "ref":
                if expr.value in self.wires:
                    visit(expr.value)
                if known.get(expr.value) != expr.width:
                    raise ValueError("unknown or mistyped reference " + str(expr.value))
            else:
                if expr.op not in {"not", "and", "or", "eq", "lt", "resize", "add", "sub", "mux"}:
                    raise ValueError("unknown operation")
                arity = {"not":1, "resize":1, "mux":3}
                if len(expr.args) != arity.get(expr.op, 2):
                    raise ValueError("invalid expression arity")
                for arg in expr.args:
                    check(arg)
                widths = [a.width for a in expr.args]
                if expr.op in {"eq", "lt"}:
                    valid = expr.width == 1 and widths[0] == widths[1]
                elif expr.op == "mux":
                    valid = widths[0] == 1 and widths[1] == widths[2] == expr.width
                elif expr.op == "resize":
                    valid = True
                else:
                    valid = all(w == expr.width for w in widths)
                if not valid:
                    raise ValueError("invalid expression types")

        def visit(name):
            if name in visiting:
                raise ValueError("combinational dependency cycle at " + name)
            if name in complete:
                return
            visiting.add(name)
            check(self.wires[name])
            visiting.remove(name)
            complete.add(name)
            known[name] = self.wires[name].width
            ordered.append(name)

        for name in self.wires:
            visit(name)
        if set(self.next) != set(self.regs):
            raise ValueError("missing next-state")
        for expr in list(self.next.values()) + list(self.outputs.values()) + self.assertions:
            check(expr)
        needed = set()
        def reach(expr):
            if expr.op == "ref" and expr.value in self.wires and expr.value not in needed:
                needed.add(expr.value)
                reach(self.wires[expr.value])
            for arg in expr.args:
                reach(arg)
        for expr in list(self.next.values()) + list(self.outputs.values()) + self.assertions:
            reach(expr)
        return [name for name in ordered if name in needed]


def validate_config(cfg):
    if cfg.get("protocol") != "r64net-v0":
        raise ValueError("unsupported protocol")
    allowed = {"protocol", "owner_bits", "payload_bits", "cancel_ports", "inputs", "outputs", "nodes", "links"}
    if set(cfg) != allowed:
        raise ValueError("missing or unknown network fields")
    for field in ("owner_bits", "payload_bits"):
        IR.check_width(cfg[field])
    if type(cfg["cancel_ports"]) is not int or not 1 <= cfg["cancel_ports"] <= 4:
        raise ValueError("cancel_ports must be 1..4")
    inputs, outputs = cfg["inputs"], cfg["outputs"]
    if not 1 <= len(inputs) <= 8 or not 1 <= len(outputs) <= len(inputs):
        raise ValueError("network supports 1..8 inputs and 1..N outputs")
    nodes = cfg["nodes"]
    ids = inputs + outputs + [n["id"] for n in nodes]
    if len(set(ids)) != len(ids) or any(not re.fullmatch("[A-Za-z][A-Za-z0-9_]*", n) for n in ids):
        raise ValueError("invalid/duplicate network name")
    arbiters = [n for n in nodes if n["kind"] == "rr_hold"]
    queues = [n for n in nodes if n["kind"] == "queue"]
    if len(arbiters) != 1 or len(queues) != len(inputs) or len(nodes) != len(queues) + 1:
        raise ValueError("v0 requires one queue per input and one rr_hold")
    arb = arbiters[0]
    if set(arb) != {"id", "kind", "inputs", "outputs"} or arb["inputs"] != len(inputs) or arb["outputs"] != len(outputs):
        raise ValueError("arbiter port counts do not match")
    for q in queues:
        if set(q) != {"id", "kind", "depth"} or type(q["depth"]) is not int or not 1 <= q["depth"] <= 8:
            raise ValueError("queue depth must be 1..8")
    source_ports = set(inputs) | {q["id"] + ".out" for q in queues} | {
        arb["id"] + ".out" + str(i) for i in range(len(outputs))}
    dest_ports = set(outputs) | {q["id"] + ".in" for q in queues} | {
        arb["id"] + ".in" + str(i) for i in range(len(inputs))}
    forward, reverse = {}, {}
    for edge in cfg["links"]:
        if not isinstance(edge, list) or len(edge) != 2:
            raise ValueError("link must contain a source and destination")
        src, dst = edge
        if src not in source_ports or dst not in dest_ports or src in forward or dst in reverse:
            raise ValueError("unknown, multiply driven, or multiply consumed port")
        forward[src], reverse[dst] = dst, src
    if set(forward) != source_ports or set(reverse) != dest_ports:
        raise ValueError("unconnected port")
    # Reject unsupported feedback instead of silently inventing its schedule.
    queue_for_input, input_for_arb = [], []
    by_id = {q["id"]: q for q in queues}
    for name in inputs:
        dest = forward[name]
        qid = dest.removesuffix(".in")
        if dest != qid + ".in" or qid not in by_id:
            raise ValueError("each external source must connect to a queue")
        queue_for_input.append(qid)
    for i in range(len(inputs)):
        src = reverse[arb["id"] + ".in" + str(i)]
        qid = src.removesuffix(".out")
        if src != qid + ".out" or qid not in queue_for_input:
            raise ValueError("arbiter inputs must be queue outputs; unsupported topology/cycle")
        input_for_arb.append(queue_for_input.index(qid))
    sink_for_lane = []
    for i in range(len(outputs)):
        dst = forward[arb["id"] + ".out" + str(i)]
        if dst not in outputs:
            raise ValueError("arbiter outputs must connect to external sinks")
        sink_for_lane.append(outputs.index(dst))
    return {
        "n": len(inputs), "m": len(outputs), "depths": [by_id[q]["depth"] for q in queue_for_input],
        "input_for_arb": input_for_arb, "sink_for_lane": sink_for_lane,
        "owner_bits": cfg["owner_bits"], "payload_bits": cfg["payload_bits"],
        "cancel_ports": cfg["cancel_ports"],
    }


def build(cfg):
    layout = validate_config(cfg)
    n, m, depths = layout["n"], layout["m"], layout["depths"]
    tw, dw, cw = cfg["owner_bits"], cfg["payload_bits"], bits(sum(depths) + m)
    ir = IR()
    C, A, O, M = ir.const, ir.all, ir.any, ir.mux
    rst = ir.input("reset")
    enabled = ir.inv(rst)
    offer = [ir.input(f"src{i}_offer") for i in range(n)]
    owner = [ir.input(f"src{i}_owner", tw) for i in range(n)]
    data = [ir.input(f"src{i}_data", dw) for i in range(n)]
    sink_ready = [ir.input(f"sink{i}_ready") for i in range(m)]
    cancel = [(ir.input(f"cancel{i}_valid"), ir.input(f"cancel{i}_owner", tw))
              for i in range(cfg["cancel_ports"])]

    def killed(tag):
        return O(*(A(valid, ir.eq(tag, who)) for valid, who in cancel))

    count = [ir.reg(f"q{i}_count", bits(depths[i])) for i in range(n)]
    qt = [[ir.reg(f"q{i}_owner{j}", tw) for j in range(depths[i])] for i in range(n)]
    qd = [[ir.reg(f"q{i}_data{j}", dw) for j in range(depths[i])] for i in range(n)]
    hv = [ir.reg(f"hold{o}_valid") for o in range(m)]
    ht = [ir.reg(f"hold{o}_owner", tw) for o in range(m)]
    hd = [ir.reg(f"hold{o}_data", dw) for o in range(m)]
    rr = ir.reg("rr", bits(n - 1))
    qlive = [A(enabled, ir.inv(ir.eq(count[i], C(0, count[i].width))), ir.inv(killed(qt[i][0])))
             for i in range(n)]
    picks = [[C(0) for _ in range(n)] for _ in range(m)]
    chosen = [C(0) for _ in range(n)]
    pointer = rr
    rw = bits(2 * n)
    ranks = []
    for a in range(n):
        distance = ir.sub(C(a + n, rw), ir.resize(rr, rw), rw)
        ranks.append(M(ir.lt(distance, C(n, rw)), distance, ir.sub(distance, C(n, rw), rw)))
    for lane in range(m):
        candidates = [A(qlive[layout["input_for_arb"][a]], ir.inv(chosen[a])) for a in range(n)]
        for a in range(n):
            before = O(*(A(candidates[b], ir.lt(ranks[b], ranks[a])) for b in range(n) if b != a))
            picks[lane][a] = A(enabled, ir.inv(hv[lane]), candidates[a], ir.inv(before))
        for a in range(n):
            chosen[a] = O(chosen[a], picks[lane][a])
            pointer = M(picks[lane][a], C((a + 1) % n, rr.width), pointer)
    ir.update(rr, pointer, rst)
    qready = [chosen[layout["input_for_arb"].index(i)] for i in range(n)]
    cancel_count = C(0, cw)
    occupancy = C(0, cw)
    for i in range(n):
        depth, width = depths[i], count[i].width
        live_in = A(enabled, offer[i], ir.inv(killed(owner[i])))
        ready = A(enabled, ir.lt(count[i], C(depth, width)))
        push = A(live_in, ready)
        pop = A(qlive[i], qready[i])
        survived, positions = [], []
        size = C(0, width)
        for j in range(depth):
            occupied = ir.lt(C(j, width), count[i])
            dead = A(occupied, killed(qt[i][j]))
            cancel_count = ir.add(cancel_count, A(enabled, dead), cw)
            keep = A(occupied, ir.inv(dead), ir.inv(pop) if j == 0 else C(1))
            positions.append(size)
            survived.append(keep)
            size = ir.add(size, keep, width)
        next_size = ir.add(size, push, bits(depth + 1))
        ir.update(count[i], ir.resize(next_size, width), rst)
        ir.assertions.append(ir.inv(ir.lt(C(depth, next_size.width), next_size)))
        if depth < (1 << width) - 1:
            ir.assertions.append(ir.inv(ir.lt(C(depth, width), count[i])))
        for dest in range(depth):
            nt, nd = C(0, tw), C(0, dw)
            for src in range(depth):
                select = A(survived[src], ir.eq(positions[src], C(dest, width)))
                nt, nd = M(select, qt[i][src], nt), M(select, qd[i][src], nd)
            put = A(push, ir.eq(size, C(dest, width)))
            ir.update(qt[i][dest], M(put, owner[i], nt), rst)
            ir.update(qd[i][dest], M(put, data[i], nd), rst)
        for key, value in {"valid":live_in, "ready":ready, "fire":push,
                           "owner":M(live_in, owner[i], C(0, tw)),
                           "data":M(live_in, data[i], C(0, dw))}.items():
            ir.output(f"in{i}_{key}", value)
        for key, value in {"valid":qlive[i], "ready":qready[i], "fire":pop,
                           "owner":M(qlive[i], qt[i][0], C(0, tw)),
                           "data":M(qlive[i], qd[i][0], C(0, dw)), "count":count[i]}.items():
            ir.output(f"q{i}_{key}", value)
        occupancy = ir.add(occupancy, count[i], cw)
    for lane in range(m):
        sink = layout["sink_for_lane"][lane]
        live = A(enabled, hv[lane], ir.inv(killed(ht[lane])))
        take = O(*picks[lane])
        nt, nd = ht[lane], hd[lane]
        for a in range(n):
            src = layout["input_for_arb"][a]
            nt, nd = M(picks[lane][a], qt[src][0], nt), M(picks[lane][a], qd[src][0], nd)
        ir.update(hv[lane], O(A(live, ir.inv(sink_ready[sink])), take), rst)
        ir.update(ht[lane], nt, rst)
        ir.update(hd[lane], nd, rst)
        for key, value in {"valid":live, "ready":A(enabled, sink_ready[sink]),
                           "fire":A(live, sink_ready[sink]),
                           "owner":M(live, ht[lane], C(0, tw)),
                           "data":M(live, hd[lane], C(0, dw)), "occupied":hv[lane]}.items():
            ir.output(f"out{sink}_{key}", value)
        cancel_count = ir.add(cancel_count, A(enabled, hv[lane], killed(ht[lane])), cw)
        occupancy = ir.add(occupancy, hv[lane], cw)
    ir.output("cancelled", cancel_count)
    ir.output("inflight", occupancy)
    ir.output("arbiter_pointer", rr)
    ir.assertions.append(ir.lt(ir.resize(rr, bits(n)), C(n, bits(n))))
    ir.validate()
    return ir, layout
