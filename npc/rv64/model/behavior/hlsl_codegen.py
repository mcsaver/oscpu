#!/usr/bin/env python3
"""Behavior AST -> resident HLSL compute shader, using only 32-bit integer words."""
import argparse,json
from pathlib import Path
import sys
sys.dont_write_bytecode=True
from always_ir import Assign,If,Check,Expr,mask
from cuda_codegen import CudaEmitter

class HlslEmitter:
    def __init__(self,model,lanes=32):
        if lanes not in (8,16,32,64,128):raise ValueError("unsupported thread-group size")
        self.m=model;self.lanes=lanes
        schedule=CudaEmitter(model)
        self.levels=schedule.levels;self.edges=schedule.edges
        self.names={n:"v"+str(i) for i,n in enumerate(model.types)}
        self.widths=set(model.types.values())|{1,32}
        self.helpers={};self.constants={}
        self.inputs_words=1+sum((w+31)//32 for w in model.inputs.values())
        self.state_words=sum((w+31)//32 for w in model.states.values())
        self.observation_words=self.state_words+sum((e.width+31)//32 for e in model.outputs.values())
        self.shared_bytes=4*(self.inputs_words-1+2*self.state_words+
            sum((w+31)//32 for w in model.wires.values())+
            sum((model.states[n]+31)//32 for bid in self.edges for n in model.analysis[model.blocks[bid].name].writes)+
            len(model.blocks)+1)
        if self.shared_bytes>32768:raise ValueError("single-group HLSL exceeds 32 KiB shared storage")
    def typ(self,w):self.widths.add(w);return f"B{w}"
    def symbol(self,n,locals=None):
        return locals[n] if locals and n in locals else self.names[n]
    def literal(self,v,w):
        self.typ(w);key=(v,w)
        if key not in self.constants:self.constants[key]="constant_"+str(len(self.constants))
        return self.constants[key]+"()"
    def helper(self,kind,widths):
        widths=tuple(widths);name=kind+"_"+"_".join(map(str,widths))
        if name in self.helpers:return name
        for w in widths:self.typ(w)
        W=widths[0];N=(W+31)//32
        trim=f"r.w[{N-1}]&={hex(mask(W%32))+'u' if W%32 else '0xffffffffu'};"
        # Insert after dependent helpers: definitions precede calls in the shader.
        if kind=="truth":
            code=f"bool {name}(B{W} a){{uint r=0;[unroll]for(uint j=0;j<{N};++j)r|=a.w[j];return r!=0;}}"
        elif kind=="index":
            code=f"uint {name}(B{W} a){{[unroll]for(uint j=1;j<{N};++j)if(a.w[j]!=0)return 0xffffffffu;return a.w[0];}}"
        elif kind in ("resize","slice"):
            A=widths[1];AN=(A+31)//32
            if kind=="resize":
                code=f"B{W} {name}(B{A} a){{B{W} r=(B{W})0;[unroll]for(uint j=0;j<{min(N,AN)};++j)r.w[j]=a.w[j];{trim}return r;}}"
            else:
                code=f"""B{W} {name}(B{A} a,uint low){{B{W} r=(B{W})0;if(low>={A})return r;
uint word=low/32,shift=low%32;[unroll]for(uint j=0;j<{N};++j){{uint k=word+j;
if(k<{AN})r.w[j]=a.w[k]>>shift;if(shift!=0 && k+1<{AN})r.w[j]|=a.w[k+1]<<(32-shift);
}}{trim}return r;}}"""
        elif kind=="put":
            V=widths[1];cut=self.helper("slice",(32,V))
            code=f"""B{W} {name}(B{W} target,uint low,B{V} value){{if(low>={W})return target;
uint end=min(low+{V}u,{W}u);
[loop]for(uint word=low/32;word<{N} && word*32<end;++word){{
 uint base=word*32,start=max(low,base),stop=min(end,base+32),span=stop-start;
 uint bits=span==32?0xffffffffu:((1u<<span)-1u),offset=start-base,wm=bits<<offset;
 B32 part={cut}(value,start-low);uint chunk=part.w[0]<<offset;
 target.w[word]=(target.w[word]&~wm)|(chunk&wm);
}}return target;}}"""
        elif kind=="cat":
            A,B=widths[1:];rz=self.helper("resize",(W,B));put=self.helper("put",(W,A))
            code=f"B{W} {name}(B{A} a,B{B} b){{return {put}({rz}(b),{B}u,a);}}"
        elif kind in ("and","or","xor","inv"):
            sign={"and":"&","or":"|","xor":"^","inv":"~"}[kind]
            arg="" if kind=="inv" else f",B{W} b"
            expr="~a.w[j]" if kind=="inv" else f"a.w[j]{sign}b.w[j]"
            code=f"B{W} {name}(B{W} a{arg}){{B{W} r;[unroll]for(uint j=0;j<{N};++j)r.w[j]={expr};{trim}return r;}}"
        elif kind in ("add","sub"):
            if kind=="add":
                inner="uint t=a.w[j]+b.w[j],c=uint(t<a.w[j]),u=t+carry;r.w[j]=u;carry=c|uint(u<t);"
            else:
                inner="uint t=a.w[j]-b.w[j],c=uint(a.w[j]<b.w[j]),u=t-carry;r.w[j]=u;carry=c|uint(t<carry);"
            code=f"B{W} {name}(B{W} a,B{W} b){{B{W} r;uint carry=0;[unroll]for(uint j=0;j<{N};++j){{{inner}}}{trim}return r;}}"
        elif kind in ("eq","lt"):
            init="1" if kind=="eq" else "0"
            body="r.w[0]=0;return r;" if kind=="eq" else "r.w[0]=uint(a.w[j]<b.w[j]);return r;"
            code=f"B1 {name}(B{W} a,B{W} b){{B1 r;r.w[0]={init};[unroll]for(int j={N-1};j>=0;--j)if(a.w[j]!=b.w[j]){{{body}}}return r;}}"
        elif kind=="shl":
            code=f"""B{W} {name}(B{W} a,uint shift){{B{W} r=(B{W})0;if(shift>={W})return r;
uint word=shift/32,bits=shift%32;[unroll]for(int j={N-1};j>=0;--j)if(uint(j)>=word){{
r.w[j]=a.w[j-word]<<bits;if(bits!=0 && uint(j)>word)r.w[j]|=a.w[j-word-1]>>(32-bits);
}}{trim}return r;}}"""
        elif kind=="mux":
            code=f"B{W} {name}(bool c,B{W} a,B{W} b){{if(c)return a;return b;}}"
        else:raise ValueError(kind)
        self.helpers[name]=code;return name
    def call(self,kind,widths,*args):
        return self.helper(kind,widths)+"("+",".join(args)+")"
    def truth(self,e):return self.call("truth",(e.width,),self.expr(e))
    def expr(self,e,locals=None):
        if e.op=="const":return self.literal(e.value,e.width)
        if e.op=="ref":return self.symbol(e.value,locals)
        a=[self.expr(x,locals) for x in e.args];widths=[x.width for x in e.args]
        if e.op=="concat":
            r=a[0];w=widths[0]
            for value,vw in zip(a[1:],widths[1:]):r=self.call("cat",(w+vw,w,vw),r,value);w+=vw
            return r
        if e.op in ("slice","indexed"):
            low=f"{e.value}u" if e.op=="slice" else self.call("index",(widths[1],),a[1])
            return self.call("slice",(e.width,widths[0]),a[0],low)
        if e.op=="resize":return self.call("resize",(e.width,widths[0]),a[0])
        if e.op=="bool":
            return self.call("mux",(1,),self.call("truth",(widths[0],),a[0]),self.literal(1,1),self.literal(0,1))
        if e.op=="mux":return self.call("mux",(e.width,),self.call("truth",(1,),a[0]),a[1],a[2])
        if e.op=="shl":return self.call("shl",(e.width,),a[0],self.call("index",(widths[1],),a[1]))
        return self.call(e.op,(widths[0],),*a)
    def candidate(self,bid,n):return f"pending_{bid}_{self.names[n]}"
    def statements(self,body,bid,locals,indent=" "):
        lines=[]
        for s in body:
            if isinstance(s,If):
                cond=self.call("truth",(1,),self.expr(s.condition,locals))
                lines.append(indent+f"if({cond}){{")
                lines+=self.statements(s.yes,bid,locals,indent+" ")
                if s.no:lines.append(indent+"}else{");lines+=self.statements(s.no,bid,locals,indent+" ")
                lines.append(indent+"}")
            elif isinstance(s,Check):
                cond=self.call("truth",(1,),self.expr(s.condition,locals))
                lines.append(indent+f"if(!{cond})errors[{bid}]=1;")
            elif isinstance(s,Assign):
                t=s.target;dest=self.candidate(bid,t.name) if s.mode=="nba" else self.symbol(t.name,locals)
                rhs=self.expr(s.value,locals);full=self.m.types.get(t.name,self.m.blocks[bid].locals.get(t.name))
                if t.low==0 and s.value.width==full:line=f"{dest}={rhs};"
                else:
                    low=self.call("index",(t.low.width,),self.expr(t.low,locals)) if isinstance(t.low,Expr) else str(t.low)+"u"
                    line=f"{dest}={self.call('put',(full,s.value.width),dest,low,rhs)};"
                lines.append(indent+line)
        return lines
    def emit(self):
        m=self.m;body=[]
        for bid,b in enumerate(m.blocks):
            body.append(f"// {b.name}: {b.kind}; {b.source}")
            body.append(f"void block_{bid}(uint edge){{")
            locals={n:"temporary_"+str(j) for j,n in enumerate(b.locals)}
            for n,w in b.locals.items():body.append(f"{self.typ(w)} {locals[n]}=({self.typ(w)})0;")
            if b.kind!="comb":
                for n in m.analysis[b.name].writes:body.append(f"{self.candidate(bid,n)}={self.names[n]};")
                body.append(f"if(edge!={int(b.kind=='negedge')})return;")
            body+=self.statements(b.body,bid,locals);body.append("}")
        body.append("void record(uint offset){")
        ow=0
        for expr in list(m.outputs.values())+[Expr("ref",w,value=n) for n,w in m.states.items()]:
            body.append(f"{self.typ(expr.width)} observed_{ow}={self.expr(expr)};")
            for j in range((expr.width+31)//32):body.append(f"result[offset+{ow+j}]=observed_{ow}.w[{j}];")
            ow+=(expr.width+31)//32
        body.append("}")
        body.append("void commit_field(uint field){switch(field){")
        for si,(n,w) in enumerate(m.states.items()):
            used=0;terms=[]
            for bid in self.edges:
                bits=m.analysis[m.blocks[bid].name].writes.get(n,0)
                if bits:used|=bits;terms.append(self.call("and",(w,),self.candidate(bid,n),self.literal(bits,w)))
            value=self.call("and",(w,),self.names[n],self.literal(mask(w)^used,w))
            for term in terms:value=self.call("or",(w,),value,term)
            body.append(f"case {si}:next_{self.names[n]}={value};break;")
        body+=["}}",f"[numthreads({self.lanes},1,1)]","void main(uint lane:SV_GroupIndex){"]
        for si,(n,w) in enumerate(m.states.items()):body.append(f"if(lane=={si%self.lanes}){self.names[n]}={self.literal(m.initial[n],w)};")
        body+=["if(lane==0){result[0]=0;result[1]=0;result[2]=0;result[3]=0;}","GroupMemoryBarrierWithGroupSync();","[loop]for(uint cycle=0;cycle<cycles;++cycle){",
               f"uint edge=stimulus[cycle*{self.inputs_words}];",
               f"for(uint k=lane;k<{len(m.blocks)};k+={self.lanes})errors[k]=0;"]
        offset=1
        for fi,(n,w) in enumerate(m.inputs.items()):
            for j in range((w+31)//32):body.append(f"if(lane=={fi%self.lanes}){self.names[n]}.w[{j}]=stimulus[cycle*{self.inputs_words}+{offset+j}];")
            offset+=(w+31)//32
        body.append("GroupMemoryBarrierWithGroupSync();")
        def phase(bids):
            for j,bid in enumerate(bids):body.append(f"if(lane=={j%self.lanes})block_{bid}(edge);")
            body.append("GroupMemoryBarrierWithGroupSync();")
        def check(phase):
            body.append(f"if(lane==0){{failure=0;for(uint k=0;k<{len(m.blocks)};++k)if(errors[k]){{failure=k+1;break;}}}}")
            body.append("GroupMemoryBarrierWithGroupSync();")
            body.append(f"if(failure){{if(lane==0){{result[0]=1;result[1]=cycle;result[2]=failure-1;result[3]={phase};}}break;}}")
        for level in self.levels:phase(level)
        check(0)
        body.append(f"if(lane==0 && trace_enabled)record({4+self.state_words}+2*cycle*{self.observation_words});")
        phase(self.edges);check(1)
        body.append(f"for(uint k=lane;k<{len(m.states)};k+={self.lanes})commit_field(k);")
        body.append("GroupMemoryBarrierWithGroupSync();")
        for si,n in enumerate(m.states):body.append(f"if(lane=={si%self.lanes}){self.names[n]}=next_{self.names[n]};")
        body.append("GroupMemoryBarrierWithGroupSync();")
        for level in self.levels:phase(level)
        check(2)
        body.append(f"if(lane==0 && trace_enabled)record({4+self.state_words}+(2*cycle+1)*{self.observation_words});")
        body+=["GroupMemoryBarrierWithGroupSync();","}"]
        offset=4
        for si,(n,w) in enumerate(m.states.items()):
            for j in range((w+31)//32):body.append(f"if(lane=={si%self.lanes})result[{offset+j}]={self.names[n]}.w[{j}];")
            offset+=(w+31)//32
        body.append("}")
        declarations=["// Direct behavior lowering: integer values, ordered statements, NBA commit.",
                      "StructuredBuffer<uint> stimulus:register(t0);",
                      "RWStructuredBuffer<uint> result:register(u0);",
                      "cbuffer Parameters:register(b0){uint cycles;uint trace_enabled;};"]
        declarations += [f"struct B{w}{{uint w[{(w+31)//32}];}};" for w in sorted(self.widths)]
        for n,w in m.types.items():declarations.append(f"groupshared B{w} {self.names[n]};")
        for n,w in m.states.items():declarations.append(f"groupshared B{w} next_{self.names[n]};")
        for bid in self.edges:
            for n in m.analysis[m.blocks[bid].name].writes:declarations.append(f"groupshared B{m.states[n]} {self.candidate(bid,n)};")
        declarations += [f"groupshared uint errors[{len(m.blocks)}];","groupshared uint failure;"]
        for (value,w),name in self.constants.items():
            assignments="".join(f"r.w[{i}]=0x{(value>>(i*32))&0xffffffff:x}u;" for i in range((w+31)//32))
            declarations.append(f"B{w} {name}(){{B{w} r;{assignments}return r;}}")
        return "\n".join(declarations+list(self.helpers.values())+body)+"\n"
    def metadata(self):
        return {"model":self.m.name,"input_words":self.inputs_words,"state_words":self.state_words,
                "observation_words":self.observation_words,"lanes":self.lanes,"shared_bytes":self.shared_bytes,
                "inputs":self.m.inputs,"outputs":{n:e.width for n,e in self.m.outputs.items()},
                "states":self.m.states,"blocks":[{"name":b.name,"source":b.source} for b in self.m.blocks]}

def main():
    from counter import counter
    from lsu_queue import request_queue
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--model",choices=("counter","lsu-queue"),default="counter")
    p.add_argument("--out",type=Path,required=True);a=p.parse_args()
    emitter=HlslEmitter(counter() if a.model=="counter" else request_queue())
    a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(emitter.emit())
    a.out.with_suffix(".json").write_text(json.dumps(emitter.metadata(),indent=2)+"\n")
if __name__=="__main__":main()
