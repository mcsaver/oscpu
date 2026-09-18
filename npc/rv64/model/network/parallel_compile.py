#!/usr/bin/env python3
"""Cycle-exact shared-old-state backend with dependency stages and disjoint writes.

This is a CPU-thread implementation of the parallel schedule, not a GPU backend.
Arithmetic/cell semantics are shared with rtl_compile; scheduling is independent.
"""
from collections import Counter, defaultdict
import json
from pathlib import Path
from rtl_compile import Compiler, SEQ, integer, literal, mask

class ParallelCompiler(Compiler):
    def __init__(self, module, parallel_min_nodes=1024, partition_style="cones"):
        super().__init__(module)
        self.parallel_min_nodes=parallel_min_nodes
        self.partition_style=partition_style
        self.phases=[]

    def notify_group(self, group):
        # Multiple independent producers may notify one future group.
        return f"dirty[{group}].store(1,std::memory_order_relaxed);"

    def group_enter(self, group):
        return f"dirty[{group}].store(0,std::memory_order_relaxed);"

    def partition(self, order, size):
        if self.partition_style=="levels":return self.level_partition(order,size)
        return self.cone_partition(order,size)

    def level_partition(self, order, size):
        level={}
        layers=defaultdict(list)
        for node in order:
            level[node]=1+max((level[d] for d in self.dependencies[node]),default=-1)
            layers[level[node]].append(node)
        groups=[]; narrow=[]
        def append(nodes,parallel):
            begin=len(groups)
            groups.extend(nodes[i:i+size] for i in range(0,len(nodes),size))
            self.phases.append({"begin":begin,"end":len(groups),"parallel":parallel,"nodes":len(nodes)})
        for depth in range(len(layers)):
            nodes=layers[depth]
            if len(nodes)>=self.parallel_min_nodes:
                if narrow:append(narrow,False);narrow=[]
                append(nodes,True)
            else:narrow.extend(nodes)
        if narrow:append(narrow,False)
        # Validate the actual emitted task graph, including serial-chain phases.
        location={n:(phase,g) for phase,p in enumerate(self.phases)
                  for g in range(p["begin"],p["end"]) for n in groups[g]}
        for n in order:
            phase,group=location[n]
            for dep in self.dependencies[n]:
                dp,dg=location[dep]
                if dp>phase or (dp==phase and self.phases[phase]["parallel"] and dg!=group) or (dp==phase and dg>group):
                    raise ValueError("illegal concurrent producer/consumer")
        self.level_widths=[len(layers[k]) for k in range(len(layers))]
        return groups

    def cone_partition(self,order,size):
        # Greedy independent cones: a node may join a current task only when
        # all its unfinished producers already belong to that same task.
        # Joins of distinct tasks move to the next phase. Keep the original
        # topological order within each cone so intermediate words stay local.
        remaining=list(order);done=set();groups=[];location={}
        level={}
        for n in order:level[n]=1+max((level[d] for d in self.dependencies[n]),default=-1)
        widths=Counter(level.values())
        self.level_widths=[widths[k] for k in range(len(widths))]
        while remaining:
            owners={};batch=[];deferred=[];free_group=None
            for n in remaining:
                deps=self.dependencies[n]-done
                if any(d not in owners for d in deps):deferred.append(n);continue
                producers={owners[d] for d in deps}
                if len(producers)>1:deferred.append(n);continue
                if producers:
                    g=next(iter(producers))
                    if len(batch[g])>=size:deferred.append(n);continue
                else:
                    if free_group is None or len(batch[free_group])>=size:
                        free_group=len(batch);batch.append([])
                    g=free_group
                batch[g].append(n);owners[n]=g
            if not owners:raise ValueError("parallel partition made no progress")
            begin=len(groups);phase=len(self.phases);groups.extend(batch)
            location.update({n:(phase,begin+g) for n,g in owners.items()})
            self.phases.append({"begin":begin,"end":len(groups),"parallel":True,"nodes":len(owners)})
            done.update(owners);remaining=deferred
        for n in order:
            for dep in self.dependencies[n]:
                a,b=location[dep],location[n]
                if a[0]>b[0] or (a[0]==b[0] and a[1]!=b[1]):
                    raise ValueError("dependency crosses concurrent cones")
        return groups

    def emit_state_tasks(self,out):
        """A memory and all its write ports have one owner; never split ports."""
        tasks=[]; registers=[]
        for name,cell in self.cells.items():
            if cell["type"] in SEQ:
                registers.append(name)
            elif cell["type"]=="$mem_v2":
                tasks.append([name])
        tasks.extend(registers[i:i+128] for i in range(0,len(registers),128))
        names=[];sources=[];unit=[];size=0
        def flush():
            nonlocal unit,size
            if not unit:return
            source=f"state_tasks_{len(sources)}"
            (out/(source+".cpp")).write_text('#include "model.h"\n'+"\n".join(unit))
            sources.append(source);unit=[];size=0
        for k,nodes in enumerate(tasks):
            name=f"state_task_{k}";names.append(name)
            lines=[f"void NetworkDut::{name}(){{",
                   "auto* v=values.data();auto* n=next.data();auto* m=memory_next.data();"]
            for node in nodes:
                if node in self.memories:
                    base,width,count,stride=self.memories[node]
                    lines.append(f"std::copy_n(memory.data()+{base},{count*stride},m+{base});")
                lines+=self.sequential(node)
            lines.append("}")
            if unit and size+len(lines)>3000:flush()
            unit.append("\n".join(lines));size+=len(lines)
        flush()
        self.state_tasks=names
        self.state_sources=sources
        return sources

    def emit(self,out,group_size=512):
        out=Path(out);out.mkdir(parents=True,exist_ok=True)
        order=self.schedule()
        self.event_groups(out,order,group_size)
        positive=[n for n,c in self.cells.items() if c["type"]=="$check" and integer(c["parameters"]["TRG_POLARITY"])]
        negative=[n for n,c in self.cells.items() if c["type"]=="$check" and not integer(c["parameters"]["TRG_POLARITY"])]
        checks=self.emit_parts(out,"check",(self.sequential(n) for n in positive))
        falls=self.emit_parts(out,"fall",(self.sequential(n) for n in negative))
        state_sources=self.emit_state_tasks(out)
        header=r'''#pragma once
#include "parallel_runtime.hpp"
#include <algorithm>
#include <array>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>
using u128=__uint128_t;
struct NetworkDut {
 std::vector<uint64_t> values,next,memory,memory_next;
 std::vector<std::atomic<uint8_t>> dirty;
 struct alignas(64) LaneStats {uint64_t evaluated=0;};
 StagePool pool;
 std::vector<LaneStats> stats;
 uint64_t evaluated_groups=0,settle_calls=0,target_edges=0,parallel_jobs=0;
 bool clock_previous=false,initialized=false;
 static int64_t sign_extend(uint64_t x,unsigned n) {
  if(n==64)return int64_t(x);
  const uint64_t sign=uint64_t(1)<<(n-1);return int64_t((x^sign)-sign);
 }
 static uint64_t extract(const uint64_t* a,unsigned width,int64_t start,bool sign) {
  if(start<=-64)return 0;
  if(start<0)return extract(a,width,0,sign)<<unsigned(-start);
  const bool negative=sign && ((a[(width-1)/64]>>((width-1)%64))&1);
  if(uint64_t(start)>=width)return negative?~0ULL:0;
  unsigned word=unsigned(start)/64,offset=unsigned(start)%64;
  uint64_t result=a[word]>>offset;
  if(offset && (word+1)*64<width)result|=a[word+1]<<(64-offset);
  unsigned valid=width-unsigned(start);
  if(negative && valid<64)result|=~0ULL<<valid;
  return result;
 }
 [[noreturn]] void fail(const char* source) {
  throw std::runtime_error("RTL assertion at edge "+std::to_string(target_edges)+": "+source);
 }
 NetworkDut();
 void eval();void settle();void advance();
 void final() {
  std::fprintf(stderr,"R64_PARALLEL threads=%u jobs=%llu groups=%llu edges=%llu\n",
      pool.size(),(unsigned long long)parallel_jobs,(unsigned long long)evaluated_groups,
      (unsigned long long)target_edges);
 }
 using Method=void(NetworkDut::*)();
 static void comb_job(void*,unsigned,unsigned,StagePool&);
 static void state_job(void*,unsigned,unsigned,StagePool&);
'''
        for name,port in self.ports.items():
            width=len(port["bits"])
            if width<=64:
                typ=next(x for x in (8,16,32,64) if x>=width)
                header+=f" uint{typ}_t {name}=0;\n"
            else:header+=f" std::array<uint32_t,{(width+31)//32}> {name}{{}};\n"
        methods=self.group_methods+checks+falls+self.state_tasks
        header+="".join(f" void {m}();\n" for m in methods)+"};\n"
        (out/"model.h").write_text(header)
        main=['#include "model.h"',
              f"NetworkDut::NetworkDut():values({len(self.words)}),next({len(self.state_words)}),"
              f"memory({self.memory_words}),memory_next({self.memory_words}),dirty({self.group_count}),stats(pool.size())"+"{"]
        main += [f"memory[{i}]={literal(v)};" for i,v in self.initial]
        main += ["for(auto& d:dirty)d.store(1,std::memory_order_relaxed);","}"]
        main += ["namespace {",
                 "const NetworkDut::Method groups[]={"+",".join("&NetworkDut::"+m for m in self.group_methods)+"};",
                 "const NetworkDut::Method state_tasks[]={"+",".join("&NetworkDut::"+m for m in self.state_tasks)+"};",
                 "struct Phase {unsigned begin,end;bool parallel;};",
                 "const Phase phases[]={"+",".join("{%d,%d,%s}"%(p["begin"],p["end"],str(p["parallel"]).lower()) for p in self.phases)+"};",
                 "}"]
        main += [r'''void NetworkDut::comb_job(void* context,unsigned lane,unsigned lanes,StagePool& pool){
 auto& self=*static_cast<NetworkDut*>(context);
 uint64_t evaluated=0;
 for(const auto& p:phases){
  if(p.parallel){
   for(unsigned g=p.begin+lane;g<p.end;g+=lanes)
    if(self.dirty[g].load(std::memory_order_relaxed)){auto method=groups[g];(self.*method)();++evaluated;}
  }else if(lane==0){
   for(unsigned g=p.begin;g<p.end;++g)
    if(self.dirty[g].load(std::memory_order_relaxed)){auto method=groups[g];(self.*method)();++evaluated;}
  }
  pool.barrier();
 }
 self.stats[lane].evaluated=evaluated;
}
void NetworkDut::state_job(void* context,unsigned lane,unsigned lanes,StagePool&){
 auto& self=*static_cast<NetworkDut*>(context);
 for(unsigned k=lane;k<sizeof(state_tasks)/sizeof(*state_tasks);k+=lanes){auto method=state_tasks[k];(self.*method)();}
}
void NetworkDut::settle(){
 ++settle_calls;
 bool active=false;
 for(auto& d:dirty)if(d.load(std::memory_order_relaxed)){active=true;break;}
 if(!active)return;
 ++parallel_jobs;pool.run(comb_job,this);
 for(const auto& lane:stats)evaluated_groups+=lane.evaluated;
}
void NetworkDut::advance(){
''']
        main += [m+"();" for m in checks]
        main += ["++parallel_jobs;pool.run(state_job,this);","memory.swap(memory_next);"]
        main += [f"if(values[{i}]!=next[{k}]){{values[{i}]=next[{k}];"+self.notify_word(i)+"}" for k,i in enumerate(self.state_words)]
        main += ["++target_edges;","}","void NetworkDut::eval(){auto* v=values.data();"]
        for name,port in self.ports.items():
            if port["direction"]!="input":continue
            width=len(port["bits"])
            for k,index in enumerate(self.destination("input",name)):
                if width<=64:expr=name
                else:
                    expr=f"uint64_t({name}[{k*2}])"
                    if k*64+32<width:expr+=f" | (uint64_t({name}[{k*2+1}]) << 32)"
                expr=f"({expr}) & {mask(min(64,width-k*64))}"
                main += [f"{{uint64_t x={expr};if(v[{index}]!=x){{v[{index}]=x;"+self.notify_word(index)+"}}"]
        main += ["settle();",
                 "if(clk_i && !clock_previous){advance();settle();}",
                 "if(!clk_i && clock_previous){"+"".join(m+"();" for m in falls)+"}",
                 "clock_previous=clk_i;initialized=true;"]
        for name,port in self.ports.items():
            if port["direction"]!="output":continue
            width=len(port["bits"])
            if width<=64:main.append(f"{name}={self.signal(port['bits'])};")
            else:
                for k in range(0,width,32):
                    main.append(f"{name}[{k//32}]=uint32_t({self.signal(port['bits'][k:k+32])});")
        main += ["}"]
        (out/"model.cpp").write_text("\n".join(main)+"\n")
        report={"backend":"cpu_parallel_state_transitions","gpu_execution":False,
                "combinational_nodes":len(order),"dependency_layers":len(self.level_widths),
                "level_widths":self.level_widths,"phases":self.phases,
                "parallel_min_nodes":self.parallel_min_nodes,"partition":self.partition_style,"group_size":group_size,
                "event_groups":self.group_count,"state_tasks":len(self.state_tasks),
                "state_words":len(self.state_words),"memory_words":self.memory_words,
                "memories":len(self.memories),"local_intermediate_words":self.local_count,
                "assertions":len(positive)+len(negative),"initialization":"two-state zero",
                "scheduler":"dependency-safe parallel phases; shared old state; disjoint next state; per-memory ordered writes",
                "sources":[p+".cpp" for p in self.parts+state_sources]+["model.cpp"]}
        (out/"network-report.json").write_text(json.dumps(report,indent=2)+"\n")
        return report
