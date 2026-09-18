"""Persistent single-instance GPU dataflow with materialized module boundary values.

Each dependency frontier runs SIMD word rules. Only true boundary dependencies
insert a device group barrier; the host never dispatches individual frontiers.
State publication still consumes a common old snapshot and is all-or-nothing.
"""
from dataclasses import replace
import re
from always_ir import ref
from fused_rules import fuse
from native_codegen import NativeEmitter
from simd_values import canonical

def references(e):
    if e.op=="ref":return {e.value}
    result=set()
    for a in e.args:result.update(references(a))
    return result

class DataflowEmitter:
    shader_target="cs_6_6"
    def __init__(self,model,lanes=None):
        self.m=model;self.rules=fuse(model,getattr(model,"materialize",()))
        values=self.rules.comb_values
        storage=dict(model.states);storage.update({n:model.wires[n] for n in values})
        pending=dict(values);done=set();self.frontiers=[]
        while pending:
            ready={n:e for n,e in pending.items() if (references(e)&set(values))<=done}
            if not ready:raise ValueError("cyclic materialized behavior")
            self.frontiers.append(ready);done.update(ready)
            for n in ready:del pending[n]
        self.stages=[]
        for frontier in self.frontiers:
            rules=replace(self.rules,next_state=frontier,comb_checks=[],edge_checks=[])
            self.stages.append(NativeEmitter(model,rules=rules,storage_types=storage))
        self.update=NativeEmitter(model,rules=self.rules,storage_types=storage)
        all_emitters=[*self.stages,self.update]
        self.lanes=lanes or max(e.lanes for e in all_emitters)
        if self.lanes<max(e.lanes for e in all_emitters) or self.lanes>1024:raise ValueError("dataflow group size is too small or exceeds 1024")
        self.state_words=self.update.state_words;self.inputs_words=self.update.inputs_words
        self.observation_words=self.update.observation_words
        self.storage_words=sum((w+31)//32 for w in storage.values())
        self.shared_bytes=4*(self.storage_words+1)
        if self.shared_bytes>32768:raise ValueError("dataflow exceeds 32 KiB shared storage")
        # Share code helpers and constant names across all frontiers.
        for e in self.stages:
            e.helpers=self.update.helpers;e.constants=self.update.constants;e.widths=self.update.widths
        self.descriptors=[];self.stage_info=[]

    def emit(self):
        self.descriptors=[];self.stage_info=[];functions=[];update_code=[]
        emitters=[*self.stages,self.update]
        for index,e in enumerate(emitters):
            code=e.build_families();offset=len(self.descriptors);self.descriptors+=e.descriptors
            # Different frontiers assign different families to the same lane.
            # Device descriptors carry the family identity explicitly.
            # Padding keeps each physical wave within a single rule family.
            family_offset=len(self.descriptors);family_ids=[0xffffffff]*e.task_count
            for family_id,info in enumerate(e.family_info):
                end=e.family_info[family_id+1]["first_lane"] if family_id+1<len(e.family_info) else e.task_count
                family_ids[info["first_lane"]:end]=[family_id]*(end-info["first_lane"])
            self.descriptors+=family_ids
            family_id=0
            for line_index,line in enumerate(code):
                if re.fullmatch(r"if\(lane>=\d+u && lane<\d+u\)\{",line):
                    code[line_index]=f"case {family_id}u:{{"
                    family_id+=1
            if family_id!=len(e.family_info):raise AssertionError("family dispatch layout changed")
            code=["switch(rule_family){"]+["break;}" if line=="}" else line for line in code]+["}"]
            setup=[f"uint descriptor=cycles*{self.inputs_words}+{offset}+lane*{e.descriptor_stride};",
                f"uint rule_family=lane<{e.task_count}?stimulus[cycles*{self.inputs_words}+{family_offset}+lane]:0xffffffffu;",
                f"uint destination=lane<{e.task_count}?stimulus[descriptor]:0xffffffffu;",
                f"uint error_code=lane<{e.task_count}?stimulus[descriptor+1]:0xffffffffu;"]
            setup += [f"uint parameter_{k}=lane<{e.task_count}?stimulus[descriptor+{2+k}]:0u;" for k in range(e.maximum_parameters)]
            setup += ["uint next_word=0;"]
            if index<len(self.stages):
                # Frontier destinations do not alias frontier inputs. Scatter
                # directly inside each case instead of merging all case values
                # into a giant SSA phi before a common store.
                scatter=[line.replace("next_word=computed.w[0];",
                    "if(destination!=0xffffffffu)state_data[destination]=computed.w[0];") for line in code]
                functions += [f"void frontier_{index}(uint lane,uint input_base,uint edge){{",*setup,*scatter,
                    "GroupMemoryBarrierWithGroupSync();","}"]
            else:update_code=setup+code
            self.stage_info.append({"kind":"comb" if index<len(self.stages) else "state",
                "word_or_check_rules":e.logical_task_count,"scheduled_lanes":e.task_count,"families":e.family_info})
        e=self.update
        record=["void record(uint offset,uint input_base,uint edge){"]
        at=0;cache={}
        for value in list(self.rules.outputs.values())+[ref(n,w) for n,w in self.m.states.items()]:
            c=canonical(value);v=e.dag(c,record,cache)
            record.append(f"B{c.width} observed_{at}={v};")
            for j in range((value.width+31)//32):record.append(f"result[offset+{at+j}]=observed_{at}.w[{j}];")
            at+=(value.width+31)//32
        record.append("}")
        frontiers=[f"frontier_{i}(lane,input_base,edge);" for i in range(len(self.stages))]
        body=functions+record+["[WaveSize(8)]",f"[numthreads({self.lanes},1,1)]","void main(uint lane:SV_GroupIndex){"]
        initial_words=[(self.m.initial[n]>>(32*j))&0xffffffff
                       for n,w in self.m.states.items() for j in range((w+31)//32)]
        body += [f"for(uint k=lane;k<{self.state_words};k+={self.lanes})state_data[k]=initial_state[k];"]
        post_needed="true" if self.rules.comb_checks else "trace_enabled"
        body += ["if(lane==0){failed=0xffffffffu;result[0]=0;result[1]=0;result[2]=0;result[3]=0;}",
                 "GroupMemoryBarrierWithGroupSync();",
                 f"uint passes={post_needed}?2u:1u;",
                 "[loop]for(uint step=0;step<cycles*passes;++step){",
                 "uint cycle=step/passes;bool after=(passes==2u)&&((step&1u)!=0u);",
                 f"uint input_base=cycle*{self.inputs_words};uint edge=stimulus[input_base];",*frontiers,
                 "if(after){"]
        if self.rules.comb_checks:
            body.append("if(lane==0){")
            for bid,check,_ in self.rules.comb_checks:
                condition=e.call("truth",(1,),e.expr(check))
                body.append(f"if(!{condition})failed=min(failed,{(2<<24)|bid}u);")
            body += ["}","GroupMemoryBarrierWithGroupSync();",
                "if(failed!=0xffffffffu){if(lane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=2;}break;}"]
        body += [f"if(trace_enabled && lane==0)record({4+self.state_words}+(2*cycle+1)*{self.observation_words},input_base,edge);",
                 "GroupMemoryBarrierWithGroupSync();continue;}",*update_code,
                 "if(error_code!=0xffffffffu && next_word==0){uint ignored;InterlockedMin(failed,error_code,ignored);}",
                 f"if(trace_enabled && lane==0)record({4+self.state_words}+2*cycle*{self.observation_words},input_base,edge);",
                 "GroupMemoryBarrierWithGroupSync();",
                 "if(failed!=0xffffffffu){if(lane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=failed>>24;}break;}",
                 "if(destination!=0xffffffffu)state_data[destination]=next_word;",
                 "GroupMemoryBarrierWithGroupSync();","}",
                 f"for(uint k=lane;k<{self.state_words};k+={self.lanes})result[4+k]=state_data[k];","}"]
        decl=["// Materialized behavior dataflow; one cooperating CPU-subsystem instance.",
            "StructuredBuffer<uint> stimulus:register(t0);","RWStructuredBuffer<uint> result:register(u0);",
            "cbuffer Parameters:register(b0){uint cycles;uint trace_enabled;};",
            f"groupshared uint state_data[{self.storage_words}];","groupshared uint failed;",
            f"static const uint initial_state[{self.state_words}]={{"+",".join(f"0x{x:x}u" for x in initial_words)+"};"]
        decl += [f"struct B{w}{{uint w[{(w+31)//32}];}};" for w in sorted(e.widths)]
        for (value,w),name in e.constants.items():
            assignments="".join(f"r.w[{j}]=0x{(value>>(32*j))&0xffffffff:x}u;" for j in range((w+31)//32))
            decl.append(f"B{w} {name}(){{B{w} r;{assignments}return r;}}")
        return "\n".join(decl+list(e.helpers.values())+body)+"\n"

    def metadata(self):
        return {"model":self.m.name,"backend":"materialized-dataflow-simd","lanes":self.lanes,"wave_size":8,
                "input_words":self.inputs_words,"state_words":self.state_words,"observation_words":self.observation_words,
                "shared_bytes":self.shared_bytes,"materialized_words":self.storage_words-self.state_words,
                "comb_frontiers":len(self.stages),"stages":self.stage_info,"descriptor_words":len(self.descriptors),
                "barriers_per_edge_without_trace":len(self.stages)+2+(len(self.stages)+2 if self.rules.comb_checks else 0),
                "independent_simulation_instances":1,"host_dispatches_per_run":1,
                "block_sources":self.rules.block_sources}
