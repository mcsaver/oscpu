"""Connect behavioral module instances without host-time module scheduling.

Every instance keeps its ordered blocks and named state. Input connections are
combinational aliases, so all edge blocks observe the same pre-edge snapshot.
Model validation rejects width mismatches, unbound ports and combinational loops.
"""
from dataclasses import replace
from always_ir import Model,Expr,Assign,If,Check,Block,ref,blocking

class Network:
    def __init__(self,name,inputs):
        self.name=name;self.inputs=dict(inputs);self.instances={};self.bindings={}

    def add(self,name,model):
        if not name.isidentifier() or name in self.instances:raise ValueError("invalid or duplicate instance")
        self.instances[name]=model;return self

    def rename_expr(self,name,e):
        return Expr(e.op,e.width,tuple(self.rename_expr(name,a) for a in e.args),
                    name+"__"+e.value if e.op=="ref" else e.value)

    def port(self,name,output):
        return self.rename_expr(name,self.instances[name].outputs[output])

    def connect(self,name,port,value):
        key=(name,port)
        if key in self.bindings:raise ValueError("input already connected")
        if self.instances[name].inputs.get(port)!=value.width:raise ValueError("port width mismatch")
        self.bindings[key]=value;return self

    def build(self,outputs):
        states={};wires={};initial={};blocks=[];paths={}
        for name,m in self.instances.items():
            prefix=name+"__";rename=lambda n:prefix+n
            expr=lambda e:self.rename_expr(name,e)
            for n,w in m.states.items():
                states[rename(n)]=w;initial[rename(n)]=m.initial[n]
                if hasattr(m,"rtl_state_paths"):paths[rename(n)]=name+"."+m.rtl_state_paths[n]
            wires.update({rename(n):w for n,w in {**m.inputs,**m.wires}.items()})
            for port in m.inputs:
                if (name,port) not in self.bindings:raise ValueError("unbound port: "+name+"."+port)
                blocks.append(Block(rename("bind_"+port),"comb",
                    (blocking(rename(port),self.bindings[name,port]),),source="connection:"+name+"."+port))
            def statement(s):
                if isinstance(s,Assign):
                    low=expr(s.target.low) if isinstance(s.target.low,Expr) else s.target.low
                    return replace(s,target=replace(s.target,name=rename(s.target.name),low=low),value=expr(s.value))
                if isinstance(s,If):return If(expr(s.condition),tuple(map(statement,s.yes)),tuple(map(statement,s.no)))
                if isinstance(s,Check):return Check(expr(s.condition),name+": "+s.message)
                raise TypeError(s)
            for b in m.blocks:
                blocks.append(Block(rename(b.name),b.kind,tuple(map(statement,b.body)),
                                    {rename(n):w for n,w in b.locals.items()},b.source))
        model=Model(self.name,self.inputs,states,wires,blocks,outputs,initial)
        model.instances={n:{"model":m.name,"parameters":getattr(m,"parameters",{})} for n,m in self.instances.items()}
        model.rtl_state_paths=paths
        return model
