"""Wave-cooperative behavior execution with lane-owned registers and no group barriers.

A single CPU/module instance is distributed over SIMD lanes. State is exchanged
only by converged WaveReadLaneAt calls; no shuffle reads an inactive source lane.
Requires Shader Model 6.6 WaveSize(32), checked by pipeline creation.
"""
import re
from simd_codegen import SimdEmitter
from simd_values import canonical

class WaveEmitter(SimdEmitter):
    def __init__(self,model):
        super().__init__(model,wave_lanes=None)
        self.shader_target="cs_6_6"
    def emit(self):
        base=super().emit()
        old_helpers=set(self.helpers);old_constants=set(self.constants);old_widths=set(self.widths)
        prefix=base[:base.index(f"[numthreads({self.lanes},1,1)]")]
        prefix=prefix.replace(f"groupshared uint state_data[{self.state_words}];",
                              f"static uint state_data[{self.state_words}];")
        prefix=prefix.replace("groupshared uint failed;","")
        rounds=(self.task_count+31)//32
        destinations=[self.descriptors[j*self.descriptor_stride] for j in range(self.task_count)]
        owner={dest:j for j,dest in enumerate(destinations) if dest!=0xffffffff}
        assert set(owner)==set(range(self.state_words))
        bindings={};family_code=[]
        pattern=re.compile(r"read_state_(\d+)\(([^,]+),input_base\)")
        for line in self.family_code:
            def replace(match):
                key=(int(match[1]),match[2])
                if key not in bindings:bindings[key]=len(bindings)
                return "wave_operand_"+str(bindings[key])
            family_code.append(pattern.sub(replace,line))
        prefix+="\nuint state_owner(uint word){switch(word){"+"".join(f"case {word}:return {task}u;" for word,task in owner.items())+"default:return 0;}}\n"
        main=["[WaveSize(32)]","[numthreads(32,1,1)]","void main(uint threadLane:SV_GroupIndex){"]
        initial=[]
        for n,w in self.m.states.items():
            initial.extend((self.m.initial[n]>>(32*j))&0xffffffff for j in range((w+31)//32))
        for r in range(rounds):
            main += [f"uint logical_{r}=threadLane+{32*r};",
                     f"uint descriptor_{r}=cycles*{self.inputs_words}+logical_{r}*{self.descriptor_stride};",
                     f"uint destination_{r}=logical_{r}<{self.task_count}?stimulus[descriptor_{r}]:0xffffffffu;",
                     f"uint error_code_{r}=logical_{r}<{self.task_count}?stimulus[descriptor_{r}+1]:0xffffffffu;",
                     f"uint owned_{r}=0;"]
            for wi,value in enumerate(initial):
                if value:main.append(f"if(destination_{r}=={wi})owned_{r}=0x{value:x}u;")
            for k in range(self.maximum_parameters):
                main.append(f"uint operand_{r}_{k}=logical_{r}<{self.task_count}?stimulus[descriptor_{r}+{2+k}]:0;")
            for (width,base),bi in bindings.items():
                base=re.sub(r"parameter_(\d+)",lambda m:f"operand_{r}_{m[1]}",base)
                for j in range((width+31)//32):main.append(f"uint source_{r}_{bi}_{j}=state_owner({base}+{j}u);")
        main += ["if(threadLane==0){result[0]=0;result[1]=0;result[2]=0;result[3]=0;}",
                 "[loop]for(uint cycle=0;cycle<cycles;++cycle){",
                 f"uint input_base=cycle*{self.inputs_words};uint edge=stimulus[input_base];"]
        def gather():
            # The arguments are register values, never shared-memory communication.
            # These intrinsics occur outside all per-lane branches, with 32 active lanes.
            for word,task in sorted(owner.items()):
                main.append(f"state_data[{word}]=WaveReadLaneAt(owned_{task//32},{task%32}u);")
        main.append("uint lane_error=0xffffffffu;")
        for r in range(rounds):
            main += [f"uint next_{r}=0;",
                     "{",f"uint lane=logical_{r};uint next_word=0;"]
            for k in range(self.maximum_parameters):main.append(f"uint parameter_{k}=operand_{r}_{k};")
            for (width,base),bi in bindings.items():
                main.append(f"B{width} wave_operand_{bi};")
                for j in range((width+31)//32):
                    source=f"source_{r}_{bi}_{j}"
                    for k in range(rounds):main.append(f"uint gathered_{bi}_{j}_{k}=WaveReadLaneAt(owned_{k},{source}%32u);")
                    selected=f"gathered_{bi}_{j}_{rounds-1}"
                    for k in reversed(range(rounds-1)):selected=f"({source}/32u=={k}?gathered_{bi}_{j}_{k}:{selected})"
                    main.append(f"wave_operand_{bi}.w[{j}]={selected};")
            main += family_code
            main += [f"next_{r}=next_word;",
                     f"if(error_code_{r}!=0xffffffffu && next_word==0)lane_error=min(lane_error,error_code_{r});","}"]
        main.append("if(trace_enabled){");gather()
        main += [f"if(threadLane==0)record({4+self.state_words}+2*cycle*{self.observation_words},input_base,edge);","}",
                 "uint failed=WaveActiveMin(lane_error);",
                 "if(failed!=0xffffffffu){if(threadLane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=failed>>24;}break;}"]
        for r in range(rounds):main.append(f"if(destination_{r}!=0xffffffffu)owned_{r}=next_{r};")
        if self.rules.comb_checks:
            gather();main.append("lane_error=0xffffffffu;")
            for ci,(bid,e,_) in enumerate(self.rules.comb_checks):
                # These expressions contain only local snapshot loads, never wave intrinsics.
                lines=[];value=self.dag(canonical(e),lines,{})
                main.append(f"if(threadLane=={ci%32}){{");main+=lines
                main.append(f"if({value}.w[0]==0)lane_error=min(lane_error,{(2<<24)|bid}u);}}")
            main += ["failed=WaveActiveMin(lane_error);",
                     "if(failed!=0xffffffffu){if(threadLane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=2;}break;}"]
        main.append("if(trace_enabled){")
        gather()
        main += [f"if(threadLane==0)record({4+self.state_words}+(2*cycle+1)*{self.observation_words},input_base,edge);",
                 "}","}"]
        for r in range(rounds):main.append(f"if(destination_{r}!=0xffffffffu)result[4+destination_{r}]=owned_{r};")
        main.append("}")
        extras=[f"struct B{w}{{uint w[{(w+31)//32}];}};" for w in sorted(self.widths-old_widths)]
        for (value,w),name in self.constants.items():
            if (value,w) not in old_constants:
                assignments="".join(f"r.w[{j}]=0x{(value>>(32*j))&0xffffffff:x}u;" for j in range((w+31)//32))
                extras.append(f"B{w} {name}(){{B{w} r;{assignments}return r;}}")
        extras += [code for name,code in self.helpers.items() if name not in old_helpers]
        return prefix+"\n"+"\n".join(extras+main)+"\n"
    def metadata(self):
        result=super().metadata()
        result.update(backend="wave-simd",lanes=32,shared_bytes=0,barriers_per_edge=0,
                      state_register_rounds=(self.task_count+31)//32,
                      wave_size=32,shader_target=self.shader_target)
        return result
