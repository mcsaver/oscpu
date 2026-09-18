"""Compile ordered always behaviors into typed, pure state-update rules.

This is procedural SSA/inlining, not synthesis or a gate netlist. The original
Model remains the source of truth. NBA RHS always reads the procedural environment,
never an earlier pending NBA. Combinational values are fused into their consumers.
"""
from dataclasses import dataclass
from always_ir import Expr,Assign,If,Check,const,ref,mux,band,bor,inv,mask

def choose(c,a,b):
    if a==b:return a
    if c.op=="const":return a if c.value else b
    return mux(c,a,b)

def boolean_and(a,b):
    if a==const(0) or b==const(0):return const(0)
    if a==const(1):return b
    if b==const(1):return a
    return band(a,b)

def invert(a):
    return const(1-a.value) if a.op=="const" and a.width==1 else inv(a)

def substitute(e,env):
    if e.op=="ref":return env[e.value]
    if not e.args:return e
    return Expr(e.op,e.width,tuple(substitute(a,env) for a in e.args),e.value)

def insert(old,value,low):
    if low==const(0,low.width) and old.width==value.width:return value
    return Expr("insert",old.width,(old,value,low))

@dataclass
class FusedRules:
    model: object
    next_state: dict
    outputs: dict
    comb_checks: list
    edge_checks: list
    block_sources: list
    comb_values: dict = None

def fuse(model, materialize=()):
    env={n:ref(n,w) for n,w in {**model.inputs,**model.states}.items()}
    comb_checks=[];edge_checks=[];comb_values={};materialize=set(materialize)
    if materialize-set(model.wires):raise ValueError("only combinational wires may be materialized")
    ids={b.name:i for i,b in enumerate(model.blocks)}
    def compile_block(block,start):
        pending={};checks=[]
        def sequence(body,local,updates,guard):
            local=dict(local);updates=dict(updates)
            for s in body:
                if isinstance(s,Assign):
                    v=substitute(s.value,local);t=s.target
                    low=substitute(t.low,local) if isinstance(t.low,Expr) else const(t.low,32)
                    if s.mode=="blocking":
                        if t.low==0 and s.value.width=={**model.types,**block.locals}[t.name]:local[t.name]=v
                        else:local[t.name]=insert(local[t.name],v,low)
                    else:
                        old=updates.get(t.name,env[t.name])
                        updates[t.name]=insert(old,v,low)
                elif isinstance(s,If):
                    c=substitute(s.condition,local)
                    yes,yup=sequence(s.yes,local,updates,boolean_and(guard,c))
                    no,nup=sequence(s.no,local,updates,boolean_and(guard,invert(c)))
                    # Values only defined inside one arm are not visible afterwards.
                    # Validated Model guarantees that any later read is definitely assigned.
                    for n in set(yes)&set(no):local[n]=choose(c,yes[n],no[n])
                    for n in set(yup)|set(nup):
                        updates[n]=choose(c,yup.get(n,updates.get(n,env[n])),nup.get(n,updates.get(n,env[n])))
                elif isinstance(s,Check):
                    condition=substitute(s.condition,local)
                    passed=choose(guard,condition,const(1))
                    checks.append((ids[block.name],passed,s.message))
                else:raise TypeError(s)
            return local,updates
        local,pending=sequence(block.body,start,{},const(1))
        return local,pending,checks
    for block in model.comb_order:
        local,_,checks=compile_block(block,env)
        for n in model.analysis[block.name].writes:
            if n in materialize:
                comb_values[n]=local[n];env[n]=ref(n,model.wires[n])
            else:env[n]=local[n]
        comb_checks.extend(checks)
    outputs={n:substitute(e,env) for n,e in model.outputs.items()}
    next_state={n:ref(n,w) for n,w in model.states.items()}
    for block in model.blocks:
        if block.kind=="comb":continue
        _,pending,checks=compile_block(block,env)
        trigger=Expr("edge",1,value=int(block.kind=="negedge"))
        for n,v in pending.items():
            bits=model.analysis[block.name].writes[n];w=model.states[n]
            updated=bor(band(next_state[n],const(mask(w)^bits,w)),band(v,const(bits,w)))
            next_state[n]=choose(trigger,updated,next_state[n])
        edge_checks.extend((bid,choose(trigger,check,const(1)),message) for bid,check,message in checks)
    return FusedRules(model,next_state,outputs,comb_checks,edge_checks,
                      [{"name":b.name,"source":b.source} for b in model.blocks],comb_values)

def evaluate(expr,env,edge=0,memo=None):
    from always_ir import Model
    if memo is None:memo={}
    if expr in memo:return memo[expr]
    if expr.op=="ref":value=env[expr.value]
    elif expr.op=="const":value=expr.value
    elif expr.op=="edge":value=int(edge==expr.value)
    elif expr.op=="word_ref":value=env[expr.value[0]]>>(32*expr.value[1])
    elif expr.op in ("shr","word","extract"):
        data,index=(evaluate(a,env,edge,memo) for a in expr.args)
        value=0 if index>=expr.args[0].width else data>>index
    elif expr.op=="onehot_word":
        index,part=(evaluate(a,env,edge,memo) for a in expr.args)
        value=(1<<(index%32)) if index//32==part else 0
    elif expr.op=="insert":
        old,data,low=(evaluate(a,env,edge,memo) for a in expr.args)
        bits=0 if low>=expr.width else (mask(expr.args[1].width)<<low)&mask(expr.width)
        value=(old&~bits)|((data<<low)&bits) if bits else old
    else:
        values=tuple(const(evaluate(a,env,edge,memo),a.width) for a in expr.args)
        value=Model.evaluate(Expr(expr.op,expr.width,values,expr.value),{})
    value &= mask(expr.width);memo[expr]=value;return value
