#!/usr/bin/env python3
"""Lower ordered always behaviors directly to one device-resident CUDA kernel.

This is a single-CTA correctness prototype, not a whole-CPU GPU performance claim.
The CPU supplies a chunk of edge inputs; all behavioral phases and cycle advancement
within that chunk happen on-device. Host functions exist only as a semantic oracle.
"""
import argparse
from pathlib import Path
import sys
sys.dont_write_bytecode=True
from always_ir import Assign, If, Check, Expr, mask

class CudaEmitter:
    def __init__(self,model):
        self.m=model
        self.ids={b.name:i for i,b in enumerate(model.blocks)}
        self.signals={n:"v"+str(i) for i,n in enumerate(model.types)}
        self.output_ids={n:"o"+str(i) for i,n in enumerate(model.outputs)}
        owner={n:b.name for b in model.comb_order for n in model.analysis[b.name].writes}
        depths={}
        self.levels=[]
        for b in model.comb_order:
            depth=1+max((depths[owner[n]] for n in model.analysis[b.name].reads
                         if n in owner),default=-1)
            depths[b.name]=depth
            while len(self.levels)<=depth:self.levels.append([])
            self.levels[depth].append(self.ids[b.name])
        self.edges=[self.ids[b.name] for b in model.blocks if b.kind!="comb"]

    @staticmethod
    def literal(value,width):
        words=",".join(f"0x{(value>>(i*32))&0xffffffff:x}u" for i in range((width+31)//32))
        return f"Bits<{width}>{{{{{words}}}}}"

    def name(self,n,locals=None):
        if locals and n in locals:return locals[n]
        if n in self.m.inputs:prefix="in"
        elif n in self.m.states:prefix="s"
        else:prefix="w"
        return prefix+"."+self.signals[n]

    def expr(self,e,locals=None):
        if e.op=="const":return self.literal(e.value,e.width)
        if e.op=="ref":return self.name(e.value,locals)
        a=[self.expr(x,locals) for x in e.args]
        if e.op=="concat":
            result=a[0]
            for part in a[1:]:result=f"cat({result},{part})"
            return result
        if e.op in ("slice","indexed"):
            low=str(e.value)+"u" if e.op=="slice" else f"index({a[1]})"
            return f"slice<{e.width}>({a[0]},{low})"
        if e.op=="resize":return f"resize<{e.width}>({a[0]})"
        if e.op=="mux":return f"(truth({a[0]})?{a[1]}:{a[2]})"
        if e.op=="shl":return f"shift_left({a[0]},index({a[1]}))"
        if e.op=="bool":return f"boolean(truth({a[0]}))"
        fn={"inv":"invert","and":"band","or":"bor","xor":"bxor",
            "add":"add","sub":"sub","eq":"equal","lt":"less"}[e.op]
        return f"{fn}({','.join(a)})"

    def candidate(self,bid,name):
        return f"p.b{bid}_{self.signals[name]}"

    def statements(self,body,bid,locals,indent="    "):
        lines=[]
        for stmt in body:
            if isinstance(stmt,If):
                lines.append(indent+f"if(truth({self.expr(stmt.condition,locals)})) {{")
                lines.extend(self.statements(stmt.yes,bid,locals,indent+"    "))
                if stmt.no:
                    lines.append(indent+"} else {")
                    lines.extend(self.statements(stmt.no,bid,locals,indent+"    "))
                lines.append(indent+"}")
            elif isinstance(stmt,Check):
                lines.append(indent+f"if(!truth({self.expr(stmt.condition,locals)})) errors[{bid}]=1;")
            elif isinstance(stmt,Assign):
                target=stmt.target
                dest=(self.candidate(bid,target.name) if stmt.mode=="nba"
                      else self.name(target.name,locals))
                low=(f"index({self.expr(target.low,locals)})" if isinstance(target.low,Expr)
                     else f"{target.low}u")
                # Arguments are evaluated before put mutates its destination.
                lines.append(indent+f"put({dest},{low},{self.expr(stmt.value,locals)});")
        return lines

    def emit(self):
        m=self.m
        lines=['// Generated from ordered behavior AST; no synthesis or gate mapping.',
               '#pragma once','#include "device_bits.hpp"','#include <cstddef>',
               'namespace r64_generated {','using namespace r64_behavior;']
        def struct(name,fields):
            lines.append(f"struct {name} {{")
            for n,w in fields:lines.append(f"    Bits<{w}> {n};")
            lines.append("};")
        for title,group in (("Inputs",m.inputs),("State",m.states),("Wires",m.wires)):
            struct(title,[(self.signals[n],w) for n,w in group.items()])
        struct("Candidates",[(f"b{bid}_{self.signals[n]}",m.states[n])
                            for bid in self.edges
                            for n in m.analysis[m.blocks[bid].name].writes])
        struct("Outputs",[(self.output_ids[n],e.width) for n,e in m.outputs.items()])
        lines.extend([
            "struct Stimulus { Inputs inputs; unsigned edge; }; // 0=posedge, 1=negedge",
            "struct Observation { State state; Outputs outputs; };",
            "struct Failure { uint64_t cycle; unsigned block; unsigned phase; };",
            f"static constexpr unsigned block_count={len(m.blocks)};",
            "struct Frame { State states[2]; Wires wires; Candidates candidates;",
            "    unsigned errors[block_count]; unsigned failed; };",
            "// Keep a conservative portable shared-memory budget; never silently spill.",
            'static_assert(sizeof(Frame)<=48*1024,"single-CTA model exceeds 48 KiB shared storage");',
            "R64_HD State initial_state() { State s{};"
        ])
        for n,w in m.states.items():
            lines.append(f"    s.{self.signals[n]}={self.literal(m.initial[n],w)};")
        lines.extend(["    return s;","}"])
        for bid,b in enumerate(m.blocks):
            lines.append(f"// Block {bid}: {b.name} ({b.kind})")
            lines.append(f"R64_HD void block_{bid}(const Inputs& in,const State& s,Wires& w,"
                         "Candidates& p,unsigned* errors,unsigned edge) {")
            locals={n:"local_"+str(i) for i,n in enumerate(b.locals)}
            for n,w in b.locals.items():lines.append(f"    Bits<{w}> {locals[n]}{{}};")
            if b.kind!="comb":
                for n in m.analysis[b.name].writes:
                    lines.append(f"    {self.candidate(bid,n)}=s.{self.signals[n]};")
                lines.append(f"    if(edge!={int(b.kind=='negedge')}u) return;")
            lines.extend(self.statements(b.body,bid,locals))
            lines.append("}")
        lines.append("R64_HD void dispatch(unsigned bid,const Inputs& in,const State& s,"
                     "Wires& w,Candidates& p,unsigned* errors,unsigned edge) { switch(bid) {")
        for bid in range(len(m.blocks)):
            lines.append(f"    case {bid}:block_{bid}(in,s,w,p,errors,edge);break;")
        lines.extend(["} }",
                      "R64_HD void commit_state(unsigned field,const State& s,State& next,"
                      "const Candidates& p) { switch(field) {"])
        for si,(n,w) in enumerate(m.states.items()):
            terms=[];used=0
            for bid in self.edges:
                bits=m.analysis[m.blocks[bid].name].writes.get(n,0)
                if bits:
                    used|=bits
                    terms.append(f"band({self.candidate(bid,n)},{self.literal(bits,w)})")
            value=f"band(s.{self.signals[n]},{self.literal(mask(w)^used,w)})"
            for term in terms:value=f"bor({value},{term})"
            lines.append(f"    case {si}:next.{self.signals[n]}={value};break;")
        lines.extend(["} }",
                      "R64_HD Observation observe(const Inputs& in,const State& s,const Wires& w) {",
                      "    Observation o{};o.state=s;"])
        for n,e in m.outputs.items():
            lines.append(f"    o.outputs.{self.output_ids[n]}={self.expr(e)};")
        lines.extend(["    return o;","}",
                      "R64_HD unsigned first_error(const unsigned* errors) {",
                      "    for(unsigned k=0;k<block_count;++k) if(errors[k]) return k+1;",
                      "    return 0;","}",
                      "// Sequential adapter checks generated expressions, not CUDA concurrency.",
                      "inline void host_settle(const Inputs& in,const State& s,Frame& f,unsigned edge) {"])
        for level in self.levels:
            for bid in level:lines.append(f"    block_{bid}(in,s,f.wires,f.candidates,f.errors,edge);")
        lines.extend(["}",
                      "inline bool host_edge(Frame& f,const Stimulus& input,Observation& before,"
                      "Observation& after,unsigned& failure_phase) {",
                      "    for(auto& e:f.errors)e=0;",
                      "    const auto& in=input.inputs;const unsigned edge=input.edge;",
                      "    host_settle(in,f.states[0],f,edge);",
                      "    if(first_error(f.errors)){failure_phase=0;return false;}",
                      "    before=observe(in,f.states[0],f.wires);"])
        for bid in self.edges:
            lines.append(f"    block_{bid}(in,f.states[0],f.wires,f.candidates,f.errors,edge);")
        lines.extend(["    if(first_error(f.errors)){failure_phase=1;return false;}",
                      f"    for(unsigned k=0;k<{len(m.states)};++k)"
                      "commit_state(k,f.states[0],f.states[1],f.candidates);",
                      "    f.states[0]=f.states[1];host_settle(in,f.states[0],f,edge);",
                      "    if(first_error(f.errors)){failure_phase=2;return false;}",
                      "    after=observe(in,f.states[0],f.wires);return true;","}",
                      "#ifdef __CUDACC__",
                      "// Exactly one CTA per simulation instance; no host calls inside the cycle loop.",
                      "static __global__ void resident_kernel(const Stimulus* input,size_t count,"
                      "Observation* trace,State* final_state,Failure* failure) {",
                      "    if(blockIdx.x || blockIdx.y || blockIdx.z) return;",
                      "    __shared__ Frame f;",
                      "    const unsigned lane=threadIdx.x;",
                      "    if(lane==0){f.states[0]=initial_state();"
                      "*failure=Failure{~uint64_t(0),0,0};}",
                      "    __syncthreads();",
                      "    unsigned current=0;",
                      "    for(size_t cycle=0;cycle<count;++cycle) {",
                      "        for(unsigned k=lane;k<block_count;k+=blockDim.x)f.errors[k]=0;",
                      "        __syncthreads();",
                      "        const auto& in=input[cycle].inputs;",
                      "        const unsigned edge=input[cycle].edge;",
                      "        const State& s=f.states[current];"])
        def gpu_phase(bids,indent="        "):
            lines.append(indent+f"for(unsigned task=lane;task<{len(bids)};task+=blockDim.x) {{")
            lines.append(indent+"    switch(task) {")
            for k,bid in enumerate(bids):
                lines.append(indent+f"    case {k}:block_{bid}(in,s,f.wires,f.candidates,f.errors,edge);break;")
            lines.extend([indent+"    }",indent+"}",indent+"__syncthreads();"])
        def gpu_check(phase):
            lines.extend(["        if(lane==0)f.failed=first_error(f.errors);",
                          "        __syncthreads();",
                          "        if(f.failed){if(lane==0){"
                          f"*failure=Failure{{cycle,f.failed-1,{phase}}};"
                          "*final_state=f.states[current];}return;}"])
        for level in self.levels:gpu_phase(level)
        gpu_check(0)
        lines.append("        if(lane==0 && trace)trace[2*cycle]=observe(in,s,f.wires);")
        # No barrier needed here: edge blocks read the same snapshot and never alter wires.
        gpu_phase(self.edges)
        gpu_check(1)
        lines.extend([f"        for(unsigned k=lane;k<{len(m.states)};k+=blockDim.x)",
                      "            commit_state(k,s,f.states[1-current],f.candidates);",
                      "        __syncthreads();",
                      "        current=1-current;"])
        # Rebind s in a nested scope so post-edge combinational blocks use the NEW snapshot.
        lines.extend(["        { const State& s=f.states[current];"])
        for level in self.levels:gpu_phase(level,"            ")
        lines.extend(["            if(lane==0 && trace)trace[2*cycle+1]=observe(in,s,f.wires);","        }"])
        gpu_check(2)
        lines.extend(["        __syncthreads();","    }",
                      "    if(lane==0)*final_state=f.states[current];","}","#endif",
                      "} // namespace r64_generated"])
        return "\n".join(lines)+"\n"

def main():
    from counter import counter
    from lsu_queue import request_queue
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model",choices=("counter","lsu-queue"),default="counter")
    destination=parser.add_mutually_exclusive_group(required=True)
    destination.add_argument("--out",type=Path)
    destination.add_argument("--driver-dir",type=Path)
    args=parser.parse_args()
    model=counter() if args.model=="counter" else request_queue()
    if args.driver_dir:
        from runner_codegen import write_driver
        write_driver(model,args.driver_dir)
    else:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(CudaEmitter(model).emit())

if __name__=="__main__":main()
