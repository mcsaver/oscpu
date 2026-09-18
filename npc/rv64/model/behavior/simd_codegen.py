"""GPU-oriented backend: fuse behavior cones, batch like rules, lane-owned next words.

All lanes cooperate on ONE model instance. This is not an instance-throughput
benchmark. Ordered always semantics are compiled by fused_rules.py; only pure
update rules are split into word work-items and grouped by expression structure.
"""
from collections import OrderedDict
from always_ir import Expr,const,ref
from fused_rules import fuse
from hlsl_codegen import HlslEmitter
from simd_values import canonical
from word_projection import word

class SimdEmitter(HlslEmitter):
    def __init__(self,model,lanes=None,wave_lanes=8,rules=None,storage_types=None,project_words=True):
        super().__init__(model,32)
        self.rules=rules if rules is not None else fuse(model);self.leaf_reader=None
        self.wave_lanes=wave_lanes
        if wave_lanes not in (None,8,16,32):raise ValueError("unsupported SIMD wave width")
        self.shader_target="cs_6_6" if wave_lanes else "cs_6_0"
        self.state_offsets={};self.input_offsets={};offset=0
        for n,w in (storage_types or model.states).items():self.state_offsets[n]=offset;offset+=(w+31)//32
        offset=1
        for n,w in model.inputs.items():self.input_offsets[n]=offset;offset+=(w+31)//32
        self.families=OrderedDict()
        def add(e,destination,error_code=0xffffffff):
            if e.op=="word":
                value=canonical(e.args[0])
                e=word(value,e.args[1].value//32) if project_words else Expr("word",32,(value,e.args[1]))
            else:e=Expr("resize",32,(canonical(e),))
            leaves=[]
            def shape(x):
                if x.op in ("ref","const","word_ref"):
                    leaves.append(x)
                    name=x.value[0] if x.op=="word_ref" else x.value
                    role="state" if name in self.state_offsets else "input"
                    return (x.op,x.width,role if x.op!="const" else None)
                return (x.op,x.width,x.value,tuple(shape(a) for a in x.args))
            key=shape(e)
            self.families.setdefault(key,[]).append((e,leaves,destination,error_code))
        for n,e in self.rules.next_state.items():
            for j in range((e.width+31)//32):
                add(Expr("word",32,(e,const(32*j,32))),self.state_offsets[n]+j)
        for phase,checks in ((0,self.rules.comb_checks),(1,self.rules.edge_checks)):
            for bid,e,_ in checks:add(Expr("resize",32,(e,)),0xffffffff,(phase<<24)|bid)
        self.logical_task_count=sum(len(v) for v in self.families.values())
        self.task_count=sum(((len(v)+wave_lanes-1)//wave_lanes)*wave_lanes for v in self.families.values()) if wave_lanes else self.logical_task_count
        needed=next((n for n in (32,64,128,256,512,1024) if n>=self.task_count),None)
        self.lanes=lanes or needed
        if self.lanes is None or self.lanes<self.task_count or self.lanes>1024:
            raise ValueError("update rules exceed this single-group backend capacity")
        self.shared_bytes=4*(self.state_words+1)
        if self.shared_bytes>32768:raise ValueError("state exceeds single-group shared memory")
        self.descriptors=[];self.descriptor_stride=0;self.family_info=[]

    def expr(self,e,locals=None):
        if e.op in ("const","ref","word_ref") and self.leaf_reader is not None:return next(self.leaf_reader)
        if e.op=="word_ref":
            name,j,w=e.value
            base=(self.state_offsets if name in self.state_offsets else self.input_offsets)[name]+j
            return self.load_value("state" if name in self.state_offsets else "input",32,str(base)+"u")
        if e.op=="onehot_word":
            a=[self.expr(x) for x in e.args]
            index=self.call("index",(e.args[0].width,),a[0]);part=self.call("index",(32,),a[1])
            key="onehot_project"
            if key not in self.helpers:self.helpers[key]="B32 onehot_project(uint index,uint part){B32 r;r.w[0]=(index/32==part)?(1u<<(index%32)):0u;return r;}"
            return f"onehot_project({index},{part})"
        if e.op=="ref":
            name=e.value
            return self.load_value("state" if name in self.state_offsets else "input",e.width,
                                   str(self.state_offsets[name] if name in self.state_offsets else self.input_offsets[name])+"u")
        if e.op in ("shr","extract"):
            a=[self.expr(x) for x in e.args]
            return self.call("slice",(e.width,e.args[0].width),a[0],self.call("index",(e.args[1].width,),a[1]))
        if e.op=="edge":
            return self.call("mux",(1,),f"(edge=={e.value}u)",self.literal(1,1),self.literal(0,1))
        if e.op in ("insert","word"):
            a=[self.expr(x) for x in e.args]
            if e.op=="insert":return self.call("put",(e.width,e.args[1].width),a[0],self.call("index",(e.args[2].width,),a[2]),a[1])
            return self.call("slice",(32,e.args[0].width),a[0],self.call("index",(32,),a[1]))
        # Static slice positions remain structural. Turning the slice value into
        # an index operand lets generated unrolled lanes share the same function.
        return super().expr(e,locals)

    def load_value(self,kind,width,base):
        name=f"read_{kind}_{width}"
        self.typ(width)
        if name not in self.helpers:
            source="state_data" if kind=="state" else "stimulus"
            offset="base" if kind=="state" else "input_base+base"
            reads="".join(f"r.w[{j}]={source}[{offset}+{j}];" for j in range((width+31)//32))
            self.helpers[name]=f"B{width} {name}(uint base,uint input_base){{B{width} r;{reads}return r;}}"
        return f"{name}({base},input_base)"

    def dag(self,e,lines,cache,bindings=None):
        if e.op in ("const","ref","word_ref"):
            text=next(bindings) if bindings is not None else self.expr(e)
            key=("leaf",e.width,text)
            if key not in cache:
                name="expression_"+str(len(cache))
                lines.append(f"B{e.width} {name}={text};");cache[key]=name
            return cache[key]
        args=[self.dag(x,lines,cache,bindings) for x in e.args]
        key=(e.op,e.width,e.value,tuple(args))
        if key not in cache:
            self.leaf_reader=iter(args)
            proxy=Expr(e.op,e.width,tuple(Expr("ref",x.width,value="bound") for x in e.args),e.value)
            value=self.expr(proxy);self.leaf_reader=None
            name="expression_"+str(len(cache))
            lines.append(f"B{e.width} {name}={value};");cache[key]=name
        return cache[key]

    def build_families(self):
        self.descriptors=[];self.family_info=[]
        body=[];family_cases=[];rows=[];cursor=0;maximum_parameters=0
        for family_index,family in enumerate(self.families.values()):
            expression,first_leaves,_,_=family[0]
            bindings=[];columns=[];bound_pool={}
            def column(values):
                if values not in columns:columns.append(values)
                return columns.index(values)
            for leaf_index,leaf in enumerate(first_leaves):
                values=[r[1][leaf_index] for r in family]
                if all(x==values[0] for x in values):
                    if leaf.op=="const":bindings.append(self.literal(leaf.value,leaf.width))
                    else:
                        bindings.append(self.expr(leaf))
                elif leaf.op in ("ref","word_ref"):
                    name=leaf.value[0] if leaf.op=="word_ref" else leaf.value
                    kind="state" if name in self.state_offsets else "input"
                    offsets=self.state_offsets if kind=="state" else self.input_offsets
                    parameter=column([offsets[x.value[0]]+x.value[1] if x.op=="word_ref" else offsets[x.value] for x in values])
                    bindings.append(self.load_value(kind,leaf.width,f"parameter_{parameter}"))
                else:
                    local=f"bound_{family_index}_{leaf_index}";self.typ(leaf.width)
                    parts=[]
                    for j in range((leaf.width+31)//32):
                        words=[(x.value>>(32*j))&0xffffffff for x in values]
                        if len(set(words))==1:parts.append(f"{local}.w[{j}]=0x{words[0]:x}u;")
                        else:
                            parameter=column(words)
                            parts.append(f"{local}.w[{j}]=parameter_{parameter};")
                    signature=(leaf.width,tuple(part.split("=",1)[1] for part in parts))
                    if signature in bound_pool:bindings.append(bound_pool[signature])
                    else:
                        binding=(local,f"B{leaf.width} {local};"+"".join(parts))
                        bound_pool[signature]=binding;bindings.append(binding)
            begin=cursor;cursor+=len(family)
            family_lines=[f"// SIMD family {family_index}: {len(family)} word/check rules",
                          f"if(lane>={begin}u && lane<{cursor}u){{"]
            for binding in dict.fromkeys(bindings):
                if isinstance(binding,tuple):family_lines.append(binding[1])
            operands=iter([x[0] if isinstance(x,tuple) else x for x in bindings])
            value=self.dag(expression,family_lines,{},operands)
            family_lines += [f"B32 computed={value};next_word=computed.w[0];","}"]
            family_cases.extend(family_lines)
            for ri,(_,_,dest,err) in enumerate(family):
                rows.append([dest,err]+[c[ri] for c in columns])
            parameter=len(columns)
            maximum_parameters=max(maximum_parameters,parameter)
            if self.wave_lanes:
                padding=(-cursor)%self.wave_lanes
                rows.extend([[0xffffffff,0xffffffff]]*padding);cursor+=padding
            self.family_info.append({"tasks":len(family),"parameters":parameter,"first_lane":begin})
        self.family_code=family_cases;self.maximum_parameters=maximum_parameters
        self.descriptor_stride=2+maximum_parameters
        for row in rows:self.descriptors.extend(row+[0]*(self.descriptor_stride-len(row)))
        return family_cases

    def emit(self):
        family_cases=self.build_families();maximum_parameters=self.maximum_parameters;body=[]
        # Trace is intentionally a correctness path. Its expressions read the same
        # fused snapshot as the fast path, without retained combinational arrays.
        record=["void record(uint offset,uint input_base,uint edge){"]
        ow=0;record_cache={}
        for e in list(self.rules.outputs.values())+[ref(n,w) for n,w in self.m.states.items()]:
            value=self.dag(canonical(e),record,record_cache)
            record.append(f"B{canonical(e).width} observed_{ow}={value};")
            for j in range((e.width+31)//32):record.append(f"result[offset+{ow+j}]=observed_{ow}.w[{j}];")
            ow+=(e.width+31)//32
        record.append("}")
        body+=record
        if self.wave_lanes:body.append(f"[WaveSize({self.wave_lanes})]")
        body += [f"[numthreads({self.lanes},1,1)]","void main(uint lane:SV_GroupIndex){",
                 f"uint descriptor=cycles*{self.inputs_words}+lane*{self.descriptor_stride};",
                 f"uint destination=lane<{self.task_count}?stimulus[descriptor]:0xffffffffu;",
                 f"uint error_code=lane<{self.task_count}?stimulus[descriptor+1]:0xffffffffu;"]
        for k in range(maximum_parameters):
            body.append(f"uint parameter_{k}=lane<{self.task_count}?stimulus[descriptor+{2+k}]:0u;")
        for n,w in self.m.states.items():
            for j in range((w+31)//32):
                at=self.state_offsets[n]+j
                body.append(f"if(lane=={at%self.lanes})state_data[{at}]=0x{(self.m.initial[n]>>(32*j))&0xffffffff:x}u;")
        body += ["if(lane==0){failed=0xffffffffu;result[0]=0;result[1]=0;result[2]=0;result[3]=0;}",
                 "GroupMemoryBarrierWithGroupSync();",
                 "[loop]for(uint cycle=0;cycle<cycles;++cycle){",
                 f"uint input_base=cycle*{self.inputs_words};uint edge=stimulus[input_base];",
                 "uint next_word=0;"]
        body+=family_cases
        body+=["if(error_code!=0xffffffffu && next_word==0){uint ignored;InterlockedMin(failed,error_code,ignored);}",
               f"if(trace_enabled && lane==0)record({4+self.state_words}+2*cycle*{self.observation_words},input_base,edge);",
               "// All rules have consumed the old snapshot before publication.",
               "GroupMemoryBarrierWithGroupSync();",
               "if(failed!=0xffffffffu){if(lane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=failed>>24;}break;}",
               "if(destination!=0xffffffffu)state_data[destination]=next_word;",
               "GroupMemoryBarrierWithGroupSync();"]
        if self.rules.comb_checks:
            body.append("if(lane==0){")
            for bid,e,_ in self.rules.comb_checks:
                cond=self.call("truth",(1,),self.expr(e))
                body.append(f"if(!{cond})failed=min(failed,{(2<<24)|bid}u);")
            body += ["}","GroupMemoryBarrierWithGroupSync();",
                     "if(failed!=0xffffffffu){if(lane==0){result[0]=1;result[1]=cycle;result[2]=failed&0xffffffu;result[3]=2;}break;}"]
        body += [f"if(trace_enabled && lane==0)record({4+self.state_words}+(2*cycle+1)*{self.observation_words},input_base,edge);",
                 "// Next iteration only reads state until its publication barrier.",
                 "}",f"for(uint k=lane;k<{self.state_words};k+={self.lanes})result[4+k]=state_data[k];","}"]
        decl=["// GPU SIMD behavior rules; one cooperating model instance.",
              "StructuredBuffer<uint> stimulus:register(t0);",
              "RWStructuredBuffer<uint> result:register(u0);",
              "cbuffer Parameters:register(b0){uint cycles;uint trace_enabled;};",
              f"groupshared uint state_data[{self.state_words}];","groupshared uint failed;"]
        decl += [f"struct B{w}{{uint w[{(w+31)//32}];}};" for w in sorted(self.widths)]
        for (value,w),name in self.constants.items():
            assigns="".join(f"r.w[{j}]=0x{(value>>(32*j))&0xffffffff:x}u;" for j in range((w+31)//32))
            decl.append(f"B{w} {name}(){{B{w} r;{assigns}return r;}}")
        return "\n".join(decl+list(self.helpers.values())+body)+"\n"

    def metadata(self):
        result=super().metadata()
        result.update(backend="fused-simd",state_word_rules=self.state_words,check_rules=self.logical_task_count-self.state_words,
                      simd_families=self.family_info,descriptor_words=len(self.descriptors),
                      barriers_per_edge=2+bool(self.rules.comb_checks),
                      retained_combinational_words=0,shared_candidate_words=0,
                      independent_simulation_instances=1,
                      wave_size=self.wave_lanes,scheduled_lanes=self.task_count,active_rules=self.logical_task_count)
        return result
