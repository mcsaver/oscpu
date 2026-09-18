"""Behavioral always-block IR and a correctness-only interpreter.

No netlist, logic synthesis, gate mapping, thread pool or GPU timing model.
First subset: unsigned 1..4096-bit values, acyclic combinational blocks,
single-clock edge blocks, local blocking temporaries and packed-vector slices.
"""
from dataclasses import dataclass, field, asdict
from collections import defaultdict
import re

def mask(width):
    if not isinstance(width,int) or isinstance(width,bool) or not 1 <= width <= 4096:
        raise ValueError("supported unsigned widths are 1..4096")
    return (1 << width)-1

@dataclass(frozen=True)
class Expr:
    op: str
    width: int
    args: tuple = ()
    value: object = None

def const(value,width=1):
    if not isinstance(value,int) or not 0 <= value <= mask(width):
        raise ValueError("constant does not fit")
    return Expr("const",width,value=value)

def ref(name,width=1):return Expr("ref",width,value=name)
def op(kind,width,*args):return Expr(kind,width,tuple(args))
def bit_slice(a,low,width=1):return Expr("slice",width,(a,),low)
def indexed(a,index,width=1):return Expr("indexed",width,(a,index))
def shl(a,amount):return op("shl",a.width,a,amount)
def nonzero(a):return op("bool",1,a)
def resize(a,width):return a if a.width==width else op("resize",width,a)
def concat(*args):return Expr("concat",sum(a.width for a in args),tuple(args))
def add(a,b):return op("add",a.width,a,b)
def sub(a,b):return op("sub",a.width,a,b)
def eq(a,b):return op("eq",1,a,b)
def band(a,b):return op("and",a.width,a,b)
def bor(a,b):return op("or",a.width,a,b)
def inv(a):return op("inv",a.width,a)
def mux(c,a,b):return op("mux",a.width,c,a,b)

@dataclass(frozen=True)
class Target:
    name: str
    low: int | Expr = 0
    width: int | None = None

@dataclass(frozen=True)
class Assign:
    target: Target
    value: Expr
    mode: str = "nba"

def nba(name,value,low=0,width=None):
    return Assign(Target(name,low,width),value,"nba")

def blocking(name,value,low=0,width=None):
    return Assign(Target(name,low,width),value,"blocking")

@dataclass(frozen=True)
class If:
    condition: Expr
    yes: tuple
    no: tuple = ()

@dataclass(frozen=True)
class Check:
    condition: Expr
    message: str

@dataclass(frozen=True)
class Block:
    name: str
    kind: str
    body: tuple
    locals: dict = field(default_factory=dict)
    source: str = ""

@dataclass(frozen=True)
class Patch:
    target: str
    bits: int
    value: int
    writer: str

@dataclass
class Analysis:
    reads: set = field(default_factory=set)
    writes: dict = field(default_factory=dict)

class Model:
    def __init__(self,name,inputs,states,wires,blocks,outputs=None,initial=None):
        self.name=name;self.inputs=dict(inputs);self.states=dict(states);self.wires=dict(wires)
        self.blocks=tuple(blocks);self.outputs=outputs or {n:ref(n,w) for n,w in states.items()}
        self.types={}
        for group in (self.inputs,self.states,self.wires):
            for n,w in group.items():
                mask(w)
                if n in self.types or not re.fullmatch(r"[A-Za-z_]\w*",n):
                    raise ValueError("duplicate or invalid signal: "+n)
                self.types[n]=w
        initial=initial or {}
        if set(initial)-set(states):raise ValueError("initial value for unknown state")
        for n,v in initial.items():
            if not isinstance(v,int) or not 0<=v<=mask(states[n]):raise ValueError("invalid initial state")
        self.initial={n:initial.get(n,0) for n in states}
        self.state=dict(self.initial)
        self.analysis={};self.comb_order=[]
        self.validate()

    def validate_expr(self,e,types,defined,reads):
        mask(e.width)
        if e.op=="const":
            if not isinstance(e.value,int) or not 0<=e.value<=mask(e.width):raise ValueError("invalid constant")
            return
        if e.op=="ref":
            if types.get(e.value)!=e.width:raise ValueError("unknown or mistyped reference: "+str(e.value))
            if e.value not in defined:reads.add(e.value)
            return
        arities={"concat":len(e.args),"slice":1,"resize":1,"inv":1,"bool":1,"mux":3,
                 "indexed":2,"shl":2,"add":2,"sub":2,"and":2,"or":2,"xor":2,"eq":2,"lt":2}
        if e.op not in arities or len(e.args)!=arities[e.op]:raise ValueError("unsupported expression: "+e.op)
        for a in e.args:self.validate_expr(a,types,defined,reads)
        ws=[a.width for a in e.args]
        if e.op=="concat":valid=bool(ws) and sum(ws)==e.width
        elif e.op in ("eq","lt"):valid=e.width==1 and ws[0]==ws[1]
        elif e.op=="mux":valid=ws[0]==1 and ws[1]==ws[2]==e.width
        elif e.op=="slice":valid=isinstance(e.value,int) and e.value>=0 and e.value+e.width<=ws[0]
        elif e.op=="indexed":valid=e.width<=ws[0]
        elif e.op=="shl":valid=e.width==ws[0]
        elif e.op=="resize":valid=True
        elif e.op=="bool":valid=e.width==1
        else:valid=all(w==e.width for w in ws)
        if not valid:raise ValueError("invalid typed expression: "+e.op)

    def target_mask(self,t,types=None):
        full=(types or self.types)[t.name]
        width=full if t.width is None else t.width
        if not isinstance(width,int) or width<1 or width>full:raise ValueError("invalid assignment width")
        if isinstance(t.low,Expr):
            if t.width is None:raise ValueError("dynamic write requires an explicit width")
            return width,mask(full)  # Conservative ownership; runtime mask is exact.
        if not isinstance(t.low,int) or t.low<0 or t.low+width>full:raise ValueError("invalid static assignment slice")
        return width,mask(width)<<t.low

    def runtime_target(self,t,env,types=None):
        types=types or self.types
        width,_=self.target_mask(t,types)
        low=self.evaluate(t.low,env) if isinstance(t.low,Expr) else t.low
        # Two-state packed selects: out-of-range destination bits are ignored.
        bits=0 if low>=types[t.name] else (mask(width)<<low)&mask(types[t.name])
        return low,bits

    def validate(self):
        names=set();owners=defaultdict(list);wire_owner={}
        for b in self.blocks:
            if b.name in names:raise ValueError("duplicate block")
            names.add(b.name)
            if b.kind not in ("comb","posedge","negedge"):raise ValueError("unsupported trigger")
            if set(b.locals)&set(self.types):raise ValueError("local shadows design signal")
            for w in b.locals.values():mask(w)
            types=dict(self.types,**b.locals);a=Analysis()
            def expr(e,defined):
                reads=set();self.validate_expr(e,types,defined,reads)
                if reads&set(b.locals):raise ValueError("read of uninitialized local")
                a.reads.update(reads)
            def sequence(statements,defined):
                defined=set(defined)
                for s in statements:
                    if isinstance(s,If):
                        if s.condition.width!=1:raise ValueError("if condition must be one bit")
                        expr(s.condition,defined)
                        yes=sequence(s.yes,defined);no=sequence(s.no,defined)
                        defined=yes&no
                    elif isinstance(s,Check):
                        if s.condition.width!=1:raise ValueError("check must be one bit")
                        expr(s.condition,defined)
                    elif isinstance(s,Assign):
                        expr(s.value,defined);t=s.target
                        if isinstance(t.low,Expr):expr(t.low,defined)
                        if s.mode=="nba":
                            if b.kind=="comb" or t.name not in self.states:raise ValueError("NBA requires edge-owned state")
                            width,bits=self.target_mask(t)
                            if s.value.width!=width:raise ValueError("explicit assignment width required")
                            a.writes[t.name]=a.writes.get(t.name,0)|bits
                        elif s.mode=="blocking":
                            allowed=b.locals if b.kind!="comb" else dict(self.wires,**b.locals)
                            if t.name not in allowed:
                                raise ValueError("blocking writes require a local or combinational output")
                            width,bits=self.target_mask(t,types)
                            if s.value.width!=width:raise ValueError("blocking width mismatch")
                            partial=isinstance(t.low,Expr) or bits!=mask(allowed[t.name])
                            if partial and t.name not in defined:
                                raise ValueError("partial blocking write before whole-value initialization")
                            defined.add(t.name)
                            if t.name in self.wires:a.writes[t.name]=mask(allowed[t.name])
                        else:raise ValueError("unknown assignment mode")
                    else:raise ValueError("unsupported statement")
                return defined
            defined=sequence(b.body,set())
            if b.kind=="comb":
                if set(a.writes)-defined:raise ValueError("incomplete combinational assignment (latch)")
                if a.reads&set(a.writes):raise ValueError("combinational output read before definition")
                for n in a.writes:
                    if n in wire_owner:raise ValueError("multiple combinational writers")
                    wire_owner[n]=b.name
            else:
                for n,bits in a.writes.items():
                    for other,used in owners[n]:
                        if bits&used:raise ValueError(f"overlapping state writers: {other}, {b.name}, {n}")
                    owners[n].append((b.name,bits))
            self.analysis[b.name]=a
        if set(wire_owner)!=set(self.wires):raise ValueError("undriven combinational signal")
        if set(owners)!=set(self.states):raise ValueError("state without an edge writer")
        pending={b.name:b for b in self.blocks if b.kind=="comb"}
        done=set()
        while pending:
            ready=[b for b in pending.values() if
                   {wire_owner[n] for n in self.analysis[b.name].reads if n in self.wires}<=done]
            if not ready:raise ValueError("combinational dependency cycle")
            for b in ready:self.comb_order.append(b);done.add(b.name);del pending[b.name]
        for e in self.outputs.values():self.validate_expr(e,self.types,set(),set())

    @staticmethod
    def evaluate(e,env):
        if e.op=="const":return e.value
        if e.op=="ref":return env[e.value]
        a=[Model.evaluate(x,env) for x in e.args]
        if e.op=="concat":
            v=0
            for part,value in zip(e.args,a):v=(v<<part.width)|value
        elif e.op=="slice":v=a[0]>>e.value
        elif e.op=="indexed":v=0 if a[1]>=e.args[0].width else a[0]>>a[1]
        elif e.op=="shl":v=0 if a[1]>=e.width else a[0]<<a[1]
        elif e.op=="resize":v=a[0]
        elif e.op=="inv":v=~a[0]
        elif e.op=="bool":v=int(bool(a[0]))
        elif e.op=="mux":v=a[1] if a[0] else a[2]
        elif e.op=="add":v=a[0]+a[1]
        elif e.op=="sub":v=a[0]-a[1]
        elif e.op=="and":v=a[0]&a[1]
        elif e.op=="or":v=a[0]|a[1]
        elif e.op=="xor":v=a[0]^a[1]
        elif e.op=="eq":v=int(a[0]==a[1])
        elif e.op=="lt":v=int(a[0]<a[1])
        else:raise ValueError("unsupported expression")
        return v&mask(e.width)

    def execute(self,b,snapshot):
        # Each block owns a local procedural environment. NBA writes never
        # enter that environment, even when a later RHS reads the same target.
        env=dict(snapshot);patches={};comb={};types=dict(self.types,**b.locals)
        def statements(body):
            for s in body:
                if isinstance(s,If):statements(s.yes if self.evaluate(s.condition,env) else s.no)
                elif isinstance(s,Check):
                    if not self.evaluate(s.condition,env):raise AssertionError(b.name+": "+s.message)
                else:
                    value=self.evaluate(s.value,env);t=s.target
                    low,bits=self.runtime_target(t,env,types)
                    if s.mode=="blocking":
                        env[t.name]=(env.get(t.name,0)&~bits)|((value<<low)&bits) if bits else env.get(t.name,0)
                        if t.name in self.wires:comb[t.name]=env[t.name]
                    else:
                        old=patches.get(t.name,Patch(t.name,0,0,b.name))
                        # Ordered masked writes: the last overlapping NBA wins.
                        patches[t.name]=Patch(t.name,old.bits|bits,
                            (old.value&~bits)|(((value<<low)&bits) if bits else 0),b.name)
        statements(b.body)
        return comb,list(patches.values())

    def snapshot(self,inputs):
        if set(inputs)!=set(self.inputs):raise ValueError("input names must match exactly")
        for n,v in inputs.items():
            if not isinstance(v,int) or not 0<=v<=mask(self.inputs[n]):raise ValueError("input width violation")
        env=dict(self.state,**inputs)
        for b in self.comb_order:
            outputs,_=self.execute(b,env);env.update(outputs)
        return env

    def observe(self,inputs):
        env=self.snapshot(inputs)
        return {n:self.evaluate(e,env) for n,e in self.outputs.items()}

    def prepare(self,inputs,edge="posedge",order=None):
        if edge not in ("posedge","negedge"):raise ValueError("unknown edge")
        env=self.snapshot(inputs);blocks=[b for b in self.blocks if b.kind==edge]
        by_name={b.name:b for b in blocks}
        if order is not None:
            if len(order)!=len(by_name) or set(order)!=set(by_name):raise ValueError("edge block order is not a permutation")
            blocks=[by_name[n] for n in order]
        patches=[]
        for b in blocks:
            _,writes=self.execute(b,env);patches.extend(writes)
        return patches

    def commit(self,patches):
        next_state=dict(self.state);used=defaultdict(int)
        for p in patches:
            if p.target not in self.states or p.bits&~mask(self.states[p.target]) or p.value&~p.bits:
                raise ValueError("invalid state patch")
            if used[p.target]&p.bits:raise ValueError("conflicting block writes")
            used[p.target]|=p.bits
            next_state[p.target]=(next_state[p.target]&~p.bits)|p.value
        self.state=next_state

    def step(self,inputs,edge="posedge",order=None):
        self.commit(self.prepare(inputs,edge,order))
        return self.observe(inputs)

    def manifest(self):
        return {"model":self.name,"representation":"ordered behavioral always blocks",
                "execution":"backend-neutral AST; Python semantic oracle; separate CUDA source generator",
                "inputs":self.inputs,"states":self.states,"wires":self.wires,
                "blocks":[{"name":b.name,"trigger":b.kind,"source":b.source,
                           "reads":sorted(self.analysis[b.name].reads),
                           "writes":self.analysis[b.name].writes} for b in self.blocks]}

    def program(self):
        result=self.manifest()
        result["schema_version"]=1
        if hasattr(self,"parameters"):result["parameters"]=self.parameters
        result["initial_state"]=self.initial
        result["outputs"]={n:asdict(e) for n,e in self.outputs.items()}
        result["behavior"]=[asdict(b) for b in self.blocks]
        return result
