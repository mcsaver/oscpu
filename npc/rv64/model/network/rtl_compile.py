#!/usr/bin/env python3
"""Lower a single-clock word-level RTL network to a statically scheduled CPU model.

No Verilator/CXXRTL runtime, ISA trace, or measured latency table is used.
The supported cell vocabulary is checked before generating executable code.
Unknown initialization is concretized to zero, matching the baseline Verilator
configuration; this is a two-state simulator, not a four-state proof.
"""
import argparse
from collections import Counter, defaultdict, deque
import json
from pathlib import Path

SEQ = {"$dff", "$dffe", "$sdff", "$sdffe", "$sdffce"}
COMB = {"$mux", "$pmux", "$bmux", "$demux", "$bwmux",
        "$and", "$or", "$xor", "$not", "$logic_and", "$logic_or", "$logic_not",
        "$reduce_and", "$reduce_or", "$reduce_bool", "$reduce_xor",
        "$eq", "$ne", "$eqx", "$nex", "$lt", "$le", "$gt", "$ge",
        "$add", "$sub", "$mul", "$neg", "$shl", "$shr", "$sshl", "$sshr",
        "$shift", "$shiftx"}

def integer(value):
    return int(value, 2) if isinstance(value, str) else value

def literal(value):
    return f"0x{value:x}ULL"

def mask(width):
    return literal((1 << width) - 1)

def chunks(bits):
    return [bits[i:i+64] for i in range(0, len(bits), 64)]

class Compiler:
    def __init__(self, module):
        self.module = module
        self.cells = module["cells"]
        self.ports = module["ports"]
        self.clock = self.ports["clk_i"]["bits"]
        if len(self.clock) != 1:
            raise ValueError("one scalar clk_i is required")
        self.bits = {}
        self.words = []
        self.output_words = {}
        self.memories = {}
        self.state_words = []
        self.memory_words = 0
        self.initial = []
        self.parts = []
        self.group_methods=[]
        self.word_users=defaultdict(set)
        self.local_words = set()
        self.alloc_inputs()
        self.alloc_cells()

    def alloc(self, bits, owner):
        result = []
        for chunk in chunks(bits):
            index = len(self.words)
            self.words.append((owner, len(chunk)))
            result.append(index)
            for k, bit in enumerate(chunk):
                if isinstance(bit, int):
                    if bit in self.bits:
                        raise ValueError(f"multiple drivers for bit {bit}: {owner}")
                    self.bits[bit] = (index, k)
        return result

    def alloc_inputs(self):
        for name, port in self.ports.items():
            if port["direction"] == "input":
                self.output_words[("input", name)] = self.alloc(port["bits"], None)

    def alloc_cells(self):
        for name, cell in self.cells.items():
            typ, conn, par = cell["type"], cell["connections"], cell["parameters"]
            if typ not in COMB | SEQ | {"$mem_v2", "$check", "$scopeinfo"}:
                raise ValueError(f"unsupported cell {typ}: {name}")
            if typ in SEQ:
                if conn["CLK"] != self.clock or integer(par["CLK_POLARITY"]) != 1:
                    raise ValueError(f"unsupported clock: {name}")
            if typ == "$mem_v2":
                self.alloc_memory(name, cell)
                continue
            for port, direction in cell["port_directions"].items():
                if direction == "output":
                    indices = self.alloc(conn[port], name)
                    self.output_words[(name, port)] = indices
                    if typ in SEQ:
                        self.state_words.extend(indices)
            if typ == "$check":
                if par["FLAVOR"] != "assert" or integer(par["TRG_ENABLE"]) != 1 or \
                   integer(par["TRG_POLARITY"]) not in (0,1) or conn["TRG"] != self.clock:
                    raise ValueError(f"unsupported assertion trigger: {name}")
        for name, net in self.module["netnames"].items():
            if "init" in net["attributes"]:
                raise ValueError(f"explicit register initialization needs lowering: {name}")

    def alloc_memory(self, name, cell):
        p, c = cell["parameters"], cell["connections"]
        width, size = integer(p["WIDTH"]), integer(p["SIZE"])
        nr, nw = integer(p["RD_PORTS"]), integer(p["WR_PORTS"])
        for key in ("RD_CLK_ENABLE", "RD_WIDE_CONTINUATION", "WR_WIDE_CONTINUATION"):
            if integer(p[key]):
                raise ValueError(f"{name}: unsupported {key}")
        if any(bit != "0" for bit in c["RD_ARST"]+c["RD_SRST"]):
            raise ValueError(f"{name}: asynchronous read reset")
        if integer(p["WR_CLK_ENABLE"]) != (1 << nw)-1 or \
           integer(p["WR_CLK_POLARITY"]) != (1 << nw)-1 or \
           c["WR_CLK"] != self.clock*nw:
            raise ValueError(f"{name}: unsupported write clock")
        # Yosys ports are ordered so that later ports override earlier ports.
        # Reject priorities that cannot be represented by that sequential fold.
        priority = integer(p["WR_PRIORITY_MASK"])
        for port in range(nw):
            if (priority >> (port*nw)) & ~((1 << port)-1) & ((1 << nw)-1):
                raise ValueError(f"{name}: nonmonotonic memory write priority")
        stride = (width+63)//64
        self.memories[name] = (self.memory_words, width, size, stride)
        init = p["INIT"][::-1]
        for address in range(size):
            for k in range(stride):
                digits = init[address*width+k*64:address*width+min(width,(k+1)*64)]
                value = int((digits[::-1] or "0").replace("x","0").replace("z","0"), 2)
                if value:
                    self.initial.append((self.memory_words+address*stride+k, value))
        self.memory_words += size*stride
        # Align individual memory read ports, including non-power-of-two widths.
        for port in range(nr):
            self.output_words[(name, port)] = self.alloc(c["RD_DATA"][port*width:(port+1)*width], (name,port))

    def var(self, index):
        return f"t{index}" if index in self.local_words else f"v[{index}]"

    def signal(self, bits):
        """Produce one <=64-bit unsigned word from packed wires and constants."""
        if len(bits) > 64:
            raise ValueError("signal slice exceeds native word")
        if not bits:
            return "0ULL"
        terms, constant, pos = [], 0, 0
        while pos < len(bits):
            bit = bits[pos]
            if isinstance(bit, str):
                if bit == "1":
                    constant |= 1 << pos
                elif bit not in ("0", "x", "z"):
                    raise ValueError(f"invalid constant {bit}")
                pos += 1
                continue
            if bit not in self.bits:
                raise ValueError(f"undriven signal bit {bit}")
            index, start = self.bits[bit]
            length = 1
            while pos+length < len(bits) and self.bits.get(bits[pos+length]) == (index, start+length):
                length += 1
            term = self.var(index)
            if start:
                term = f"({term} >> {start})"
            if length < self.words[index][1]-start:
                term = f"({term} & {mask(length)})"
            if pos:
                term = f"({term} << {pos})"
            terms.append(term)
            pos += length
        if constant:
            terms.append(literal(constant))
        if not terms:
            return "0ULL"
        return terms[0] if len(terms)==1 else "("+" | ".join(terms)+")"

    def ext(self, bits, width, signed=False):
        if len(bits) >= width:
            return bits[:width]
        return bits + ([bits[-1]] if signed else ["0"])*(width-len(bits))

    def boolean(self, bits):
        return "("+" | ".join(self.signal(c) for c in chunks(bits))+")"

    def signed(self, bits):
        if len(bits)>64:
            raise ValueError("signed scalar exceeds 64 bits")
        value=self.signal(bits)
        return f"sign_extend({value}, {len(bits)})"

    def destination(self, name, port="Y"):
        return self.output_words[(name, port)]

    def assign(self, indices, expressions, width):
        if len(indices)!=len(expressions):
            raise ValueError("output shape")
        return [f"{self.var(i)} = ({e})"+(f" & {mask(width-k*64)}" if width-k*64<64 else "")+";"
                for k,(i,e) in enumerate(zip(indices,expressions))]

    def comb(self, name):
        if isinstance(name,tuple):
            return self.memory_read(name[0],self.cells[name[0]],name[1])
        cell=self.cells[name]; typ=cell["type"]; c=cell["connections"]; p=cell["parameters"]
        y=c["Y"]; width=len(y); out=self.destination(name)
        a,b=c.get("A",[]),c.get("B",[])
        signed=bool(integer(p.get("A_SIGNED",0)) and integer(p.get("B_SIGNED",0)))
        if typ in ("$mux", "$bwmux"):
            aa,bb=chunks(self.ext(a,width)),chunks(self.ext(b,width))
            if typ=="$mux":
                s=self.boolean(c["S"])
                expressions=[f"{s} ? {self.signal(b)} : {self.signal(a)}" for a,b in zip(aa,bb)]
            else:
                expressions=[f"({self.signal(s)} & {self.signal(b)}) | (~{self.signal(s)} & {self.signal(a)})"
                             for a,b,s in zip(aa,bb,chunks(c["S"]))]
            return self.assign(out,expressions,width)
        if typ in ("$and","$or","$xor","$not"):
            aa=chunks(self.ext(a,width, bool(integer(p.get("A_SIGNED",0))) if typ=="$not" else signed))
            bb=chunks(self.ext(b,width,signed))
            op={"$and":"&","$or":"|","$xor":"^","$not":"~"}[typ]
            expr=[f"~{self.signal(x)}" for x in aa] if typ=="$not" else [
                f"{self.signal(x)} {op} {self.signal(z)}" for x,z in zip(aa,bb)]
            return self.assign(out,expr,width)
        if typ.startswith("$logic") or typ in ("$reduce_or","$reduce_bool"):
            x=self.boolean(a)
            expr={"$logic_and":lambda:f"bool({x}) && bool({self.boolean(b)})",
                  "$logic_or":lambda:f"bool({x}) || bool({self.boolean(b)})",
                  "$logic_not":lambda:f"!{x}"}.get(typ,lambda:f"bool({x})")()
            return self.assign(out,[expr],width)
        if typ in ("$reduce_and","$reduce_xor"):
            if typ=="$reduce_and":
                expr=" && ".join(f"({self.signal(x)} == {mask(len(x))})" for x in chunks(a))
            else:
                expr=" ^ ".join(f"__builtin_parityll({self.signal(x)})" for x in chunks(a))
            return self.assign(out,[expr],width)
        if typ in ("$eq","$ne","$eqx","$nex","$lt","$le","$gt","$ge"):
            w=max(len(a),len(b));aa=self.ext(a,w,signed);bb=self.ext(b,w,signed)
            pairs=list(zip(chunks(aa),chunks(bb)))
            equal=" && ".join(f"({self.signal(x)} == {self.signal(z)})" for x,z in pairs)
            if typ in ("$eq","$eqx"):expr=equal
            elif typ in ("$ne","$nex"):expr=f"!({equal})"
            else:
                # Lexicographic comparison of unsigned chunks, with sign first.
                less="false"
                for x,z in pairs:
                    xs,zs=self.signal(x),self.signal(z)
                    less=f"({xs} < {zs} || ({xs} == {zs} && {less}))"
                if signed:
                    sa,sb=self.signal([aa[-1]]),self.signal([bb[-1]])
                    less=f"({sa} != {sb} ? bool({sa}) : {less})"
                expr={"$lt":less,"$le":f"({less} || ({equal}))",
                      "$gt":f"!({less} || ({equal}))","$ge":f"!{less}"}[typ]
            return self.assign(out,[expr],width)
        if typ in ("$add","$sub","$mul","$neg"):
            if width>128:
                raise ValueError(f"arithmetic >128 bits: {name}")
            sa=bool(integer(p.get("A_SIGNED",0))) if typ=="$neg" else signed
            aa=self.ext(a,width,sa);bb=self.ext(b,width,signed)
            def wide(bits):
                cs=chunks(bits);e=f"u128({self.signal(cs[0])})"
                if len(cs)>1:e=f"({e} | (u128({self.signal(cs[1])}) << 64))"
                return e
            if width<=64:
                x,z=self.signal(aa),self.signal(bb)
            else:x,z=wide(aa),wide(bb)
            expr=f"-{x}" if typ=="$neg" else f"{x} "+{"$add":"+","$sub":"-","$mul":"*"}[typ]+f" {z}"
            if width<=64:return self.assign(out,[expr],width)
            return ["{",f"u128 t = {expr};"]+self.assign(out,["uint64_t(t)","uint64_t(t >> 64)"],width)+["}"]
        if typ=="$pmux":
            lines=self.assign(out,[self.signal(x) for x in chunks(a)],width)
            # Exactly one S may be active; synth semantics OR selected words.
            lines=["{","bool selected = false;"]+lines
            for k,bit in enumerate(c["S"]):
                lines.append(f"if ({self.signal([bit])}) {{")
                vals=[self.signal(x) for x in chunks(b[k*width:(k+1)*width])]
                for index,value in zip(out,vals):
                    lines.append(f"{self.var(index)} = selected ? {self.var(index)} | {value} : {value};")
                lines+=["selected = true;","}"]
            return lines+["}"]
        if typ=="$bmux":
            lines=[f"switch ({self.signal(c['S'])}) {{"]
            for k in range(len(a)//width):
                lines.append(f"case {k}:")
                lines+=self.assign(out,[self.signal(x) for x in chunks(a[k*width:(k+1)*width])],width)+["break;"]
            return lines+["default:"]+self.assign(out,["0ULL"]*len(out),width)+["break;","}"]
        if typ=="$demux":
            aw=len(a);s=self.signal(c["S"])
            expressions=[]
            # Construct chunks directly; cells used here have compact outputs.
            for start in range(0,width,64):
                bits=[]
                for pos in range(start,min(start+64,width)):
                    bits.append((pos//aw,pos%aw))
                terms=[]
                for lane in sorted(set(x[0] for x in bits)):
                    lo=max(start,lane*aw);hi=min(start+64,(lane+1)*aw,width)
                    val=self.signal(a[lo-lane*aw:hi-lane*aw])
                    if lo>start:val=f"({val} << {lo-start})"
                    terms.append(f"({s} == {lane} ? {val} : 0ULL)")
                expressions.append(" | ".join(terms))
            return self.assign(out,expressions,width)
        if typ in ("$shl","$shr","$sshl","$sshr","$shift","$shiftx"):
            # A chunk array permits arbitrary indexed part-selects without
            # compiler-dependent shifts by 64 or a negative amount.
            aw=max(len(a),width) if typ!="$shiftx" else len(a)
            aa=self.ext(a,aw,bool(integer(p.get("A_SIGNED",0))) and typ!="$shiftx")
            bsigned=bool(integer(p.get("B_SIGNED",0))) and typ in ("$shift","$shiftx")
            shift=self.signed(b) if bsigned else f"int64_t({self.signal(b)})"
            if typ in ("$shl","$sshl"):shift=f"-({shift})"
            lines=["{",f"const uint64_t a[] = {{{', '.join(self.signal(x) for x in chunks(aa))}}};",
                   f"int64_t shift = {shift};"]
            signfill=typ=="$sshr" and bool(integer(p.get("A_SIGNED",0)))
            expressions=[f"extract(a, {aw}, shift + {k*64}, "+("true" if signfill else "false")+")" for k in range(len(out))]
            return lines+self.assign(out,expressions,width)+["}"]
        raise ValueError(f"no lowering for {typ}: {name}")

    def memory_read(self, name, cell, read_port):
        p,c=cell["parameters"],cell["connections"]
        base,width,size,stride=self.memories[name]
        abits,offset=integer(p["ABITS"]),integer(p["OFFSET"])
        if offset>=1<<31:offset-=1<<32
        lines=[]
        for port in [read_port]:
            addr=self.signal(c["RD_ADDR"][port*abits:(port+1)*abits])
            expressions=[f"address < {size} ? m[{base+k} + address*{stride}] : 0ULL" for k in range(stride)]
            lines+=["{",f"uint64_t address = {addr} - ({offset}LL);"]
            lines+=self.assign(self.destination(name,port),expressions,width)+["}"]
        return lines

    def sequential(self, name):
        cell=self.cells[name];typ=cell["type"];c=cell["connections"];p=cell["parameters"]
        if typ=="$check":
            where=cell["attributes"].get("src",name)
            return [f"if ({self.boolean(c['EN'])} && !{self.boolean(c['A'])}) fail({json.dumps(where)});"]
        if typ=="$mem_v2":
            base,width,size,stride=self.memories[name]
            abits,offset=integer(p["ABITS"]),integer(p["OFFSET"])
            if offset>=1<<31:offset-=1<<32
            lines=[]
            for port in range(integer(p["WR_PORTS"])):
                enables=c["WR_EN"][port*width:(port+1)*width]
                if all(bit=="0" for bit in enables):continue
                address=self.signal(c["WR_ADDR"][port*abits:(port+1)*abits])
                data=c["WR_DATA"][port*width:(port+1)*width]
                lines += [f"if ({self.boolean(enables)}) {{",
                          f"uint64_t address = {address} - ({offset}LL);",
                          f"if (address < {size}) {{"]
                for k,(en,da) in enumerate(zip(chunks(enables),chunks(data))):
                    if all(bit=="0" for bit in en):continue
                    index=f"{base+k} + address*{stride}"
                    lines+=[f"uint64_t e{k} = {self.signal(en)};",
                            f"uint64_t updated{k} = (m[{index}] & ~e{k}) | ({self.signal(da)} & e{k});",
                            f"if(m[{index}]!=updated{k}){{m[{index}]=updated{k};"+
                            "".join(self.notify_group(g) for g in self.memory_groups[name])+"}"]
                lines+=["}","}"]
            return lines
        indices=self.destination(name,"Q");width=len(c["Q"])
        vals=[self.signal(x) for x in chunks(c["D"])]
        if "EN" in c:
            en=self.boolean(c["EN"])
            if not integer(p["EN_POLARITY"]):en="!"+en
        if "SRST" in c:
            rst=self.boolean(c["SRST"])
            if not integer(p["SRST_POLARITY"]):rst="!"+rst
            value=integer(p["SRST_VALUE"].replace("x","0").replace("z","0"))
        lines=[]
        for k,(i,v) in enumerate(zip(indices,vals)):
            reset=literal((value>>(k*64))&((1<<min(64,width-k*64))-1)) if "SRST" in c else None
            expr=v
            if typ in ("$dffe","$sdffe"):expr=f"({en} ? {expr} : v[{i}])"
            if "SRST" in c:expr=f"({rst} ? {reset} : {expr})"
            if typ=="$sdffce":expr=f"({en} ? {expr} : v[{i}])"
            lines.append(f"n[{self.state_words.index(i)}] = {expr};")
        return lines

    def schedule(self):
        nodes=[n for n,c in self.cells.items() if c["type"] in COMB]
        nodes += [(n,p) for n,c in self.cells.items() if c["type"]=="$mem_v2"
                  for p in range(integer(c["parameters"]["RD_PORTS"]))]
        node_set=set(nodes); deps={}; users=defaultdict(list)
        for name in nodes:
            cell=self.cells[name[0] if isinstance(name,tuple) else name];cs=cell["connections"]
            if isinstance(name,tuple):
                ab=integer(cell["parameters"]["ABITS"])
                cs={"RD_ADDR":cs["RD_ADDR"][name[1]*ab:(name[1]+1)*ab]}
                ports=["RD_ADDR"]
            else:
                ports=[p for p,d in cell["port_directions"].items() if d=="input"]
            ds=set()
            for port in ports:
                for bit in cs[port]:
                    if isinstance(bit,int):
                        if bit not in self.bits:raise ValueError(f"undriven input in {name}: {bit}")
                        owner=self.words[self.bits[bit][0]][0]
                        if owner in node_set:ds.add(owner)
            deps[name]=ds
            for d in ds:users[d].append(name)
        pending={n:len(d) for n,d in deps.items()}
        ready=deque(n for n in nodes if not pending[n]);order=[]
        while ready:
            name=ready.popleft();order.append(name)
            for user in users[name]:
                pending[user]-=1
                if not pending[user]:ready.append(user)
        if len(order)!=len(nodes):
            raise ValueError("combinational cycle: "+repr([n for n in nodes if pending[n]][:8]))
        self.dependencies=deps
        self.node_inputs={}
        for name in nodes:
            cell=self.cells[name[0] if isinstance(name,tuple) else name]
            if isinstance(name,tuple):
                ab=integer(cell["parameters"]["ABITS"])
                wires=cell["connections"]["RD_ADDR"][name[1]*ab:(name[1]+1)*ab]
            else:
                wires=[b for p,d in cell["port_directions"].items() if d=="input" for b in cell["connections"][p]]
            self.node_inputs[name]={self.bits[b][0] for b in wires if isinstance(b,int)}
        visited=set();ordered=[]
        for root in nodes:
            if root in visited:continue
            stack=[(root,False)]
            while stack:
                node,expanded=stack.pop()
                if expanded:
                    ordered.append(node);continue
                if node in visited:continue
                visited.add(node);stack.append((node,True))
                stack.extend((dep,False) for dep in sorted(deps[node],key=str,reverse=True) if dep not in visited)
        # Cross edges to a gray node are impossible after the cycle check above.
        positions={n:i for i,n in enumerate(ordered)}
        if any(positions[d]>=positions[n] for n in ordered for d in deps[n]):
            raise ValueError("internal topological scheduling error")
        return ordered

    def emit_parts(self, out, family, blocks, max_lines=2500):
        groups=[];group=[];depth=0
        for block in blocks:
            for line in block:
                group.append(line)
                depth += line.count("{")-line.count("}")
                if depth==0 and len(group)>=max_lines:
                    groups.append(group);group=[]
        if depth:raise ValueError("unbalanced generated block")
        if group:groups.append(group)
        names=[]
        for k,lines in enumerate(groups):
            method=f"{family}_{k}";names.append(method);self.parts.append(method)
            code='#include "model.h"\nvoid NetworkDut::'+method+'(){\nauto* v=values.data(); auto* n=next.data(); auto* m=memory.data();\n'
            (out/(method+".cpp")).write_text(code+"\n".join(lines)+"\n}\n")
        return names

    def notify_word(self, index, exclude=None):
        return "".join(self.notify_group(g) for g in sorted(self.word_users[index]) if g!=exclude)

    def notify_group(self, group):
        return f"dirty[{group}]=1;"

    def group_enter(self, group):
        return f"dirty[{group}]=0; ++evaluated_groups;"

    def partition(self, order, size):
        return [order[i:i+size] for i in range(0,len(order),size)]

    def event_groups(self, out, order, size=256):
        groups=self.partition(order,size)
        node_group={n:g for g,nodes in enumerate(groups) for n in nodes}
        self.node_group=node_group
        for g,nodes in enumerate(groups):
            for n in nodes:
                for index in self.node_inputs[n]:self.word_users[index].add(g)
        self.memory_groups={name:sorted({node_group[(name,p)] for p in range(integer(self.cells[name]["parameters"]["RD_PORTS"]))})
                            for name in self.memories}
        self.group_count=len(groups)
        persistent=set()
        for port in self.ports.values():
            if port["direction"]=="output":
                persistent.update(self.bits[b][0] for b in port["bits"] if isinstance(b,int))
        for cell in self.cells.values():
            if cell["type"] not in SEQ|{"$check","$mem_v2"}:continue
            for port,direction in cell["port_directions"].items():
                if direction!="input":continue
                if cell["type"]=="$mem_v2" and not port.startswith("WR_"):continue
                persistent.update(self.bits[b][0] for b in cell["connections"][port] if isinstance(b,int))
        local_count=0
        sources=[];unit=[];lines_in_unit=0
        def flush():
            nonlocal unit,lines_in_unit
            if not unit:return
            source=f"events_{len(sources)}"
            (out/(source+".cpp")).write_text('#include "model.h"\n'+"\n".join(unit))
            sources.append(source);unit=[];lines_in_unit=0
        for g,nodes in enumerate(groups):
            output_indices=[i for n in nodes for key,indices in
                            ([(None,self.destination(n[0],n[1]))] if isinstance(n,tuple) else
                             [(None,self.destination(n))]) for i in indices]
            boundary={i for i in output_indices if any(t!=g for t in self.word_users[i])}
            lines=[f"void NetworkDut::group_{g}(){{",
                   "auto* v=values.data();auto* m=memory.data();",
                   self.group_enter(g)]
            self.local_words=set(output_indices)-boundary-persistent
            local_count+=len(self.local_words)
            lines += [f"uint64_t t{i};" for i in sorted(self.local_words)]
            lines += [f"const uint64_t old_{i}=v[{i}];" for i in sorted(boundary)]
            for n in nodes:lines+=self.comb(n)
            self.local_words=set()
            downstream=defaultdict(list)
            for i in sorted(boundary):
                for target in self.word_users[i]:
                    if target!=g:downstream[target].append(i)
            for target,indices in sorted(downstream.items()):
                lines.append("if ("+" || ".join(f"old_{i}!=v[{i}]" for i in indices)+") "+self.notify_group(target))
            lines+=["}"]
            if unit and lines_in_unit+len(lines)>3000:flush()
            unit.append("\n".join(lines)+"\n");lines_in_unit+=len(lines)
            self.group_methods.append(f"group_{g}")
        flush()
        self.parts.extend(sources)
        self.local_count=local_count
        return [f"if(dirty[{g}])group_{g}();" for g in range(len(groups))]

    def emit(self, out, group_size=256):
        out=Path(out);out.mkdir(parents=True,exist_ok=True)
        order=self.schedule()
        comb=self.event_groups(out,order,size=group_size)
        seq_names=[n for n,c in self.cells.items() if c["type"] in SEQ|{"$mem_v2","$check"}]
        negative=[n for n in seq_names if self.cells[n]["type"]=="$check" and not integer(self.cells[n]["parameters"]["TRG_POLARITY"])]
        seq_names=[n for n in seq_names if n not in set(negative)]
        seq=self.emit_parts(out,"edge",(self.sequential(n) for n in seq_names))
        neg=self.emit_parts(out,"fall",(self.sequential(n) for n in negative))
        header=r'''#pragma once
#include <array>
#include <vector>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <cstdio>
using u128=__uint128_t;
struct NetworkDut {
 std::vector<uint64_t> values, next, memory;
 std::vector<uint8_t> dirty;
 uint64_t evaluated_groups=0, settle_calls=0;
 bool clock_previous=false, initialized=false;
 uint64_t target_edges=0;
 static int64_t sign_extend(uint64_t x,unsigned n) {
  if(n==64)return int64_t(x);
  const uint64_t sign=uint64_t(1)<<(n-1);
  return int64_t((x^sign)-sign);
 }
 static uint64_t extract(const uint64_t* a,unsigned width,int64_t start,bool sign) {
  if(start <= -64)return 0;
  if(start<0)return extract(a,width,0,sign)<<unsigned(-start);
  const bool negative=sign && ((a[(width-1)/64]>>((width-1)%64))&1);
  if(uint64_t(start)>=width)return negative?~0ULL:0;
  unsigned word=unsigned(start)/64, offset=unsigned(start)%64;
  uint64_t result=a[word]>>offset;
  if(offset && (word+1)*64<width)result |= a[word+1]<<(64-offset);
  unsigned valid=width-unsigned(start);
  if(negative && valid<64)result |= ~0ULL<<valid;
  return result;
 }
 [[noreturn]] void fail(const char* source) {
  throw std::runtime_error("RTL assertion at edge "+std::to_string(target_edges)+": "+source);
 }
 NetworkDut();
 void eval();
 void final(){}
'''
        for name,port in self.ports.items():
            width=len(port["bits"])
            if width<=64:
                typ=next(x for x in (8,16,32,64) if x>=width)
                header+=f" uint{typ}_t {name}=0;\n"
            else:header+=f" std::array<uint32_t,{(width+31)//32}> {name}{{}};\n"
        header+=" void settle(); void advance();\n"
        header+="".join(" void "+p+"();\n" for p in self.parts if not p.startswith("events_"))+"".join(" void "+p+"();\n" for p in self.group_methods)+"};\n"
        (out/"model.h").write_text(header)
        main=['#include "model.h"',f"NetworkDut::NetworkDut():values({len(self.words)}),next({len(self.state_words)}),memory({self.memory_words}),dirty({self.group_count},1)"+"{"]
        main += [f"memory[{i}]={literal(v)};" for i,v in self.initial]+["}"]
        main+=["void NetworkDut::settle(){ ++settle_calls;"]+comb+["}"]
        main+=["void NetworkDut::advance(){"]+[f"{p}();" for p in seq]
        main += [f"if(values[{i}]!=next[{k}]){{values[{i}]=next[{k}];"+self.notify_word(i)+"}" for k,i in enumerate(self.state_words)]+["++target_edges;","}"]
        main+=["void NetworkDut::eval(){","auto* v=values.data();","bool first=!initialized;"]
        for name,port in self.ports.items():
            if port["direction"]!="input":continue
            width=len(port["bits"])
            for k,index in enumerate(self.destination("input",name)):
                if width<=64:expr=name
                else:
                    expr=f"uint64_t({name}[{k*2}])"
                    if k*64+32<width:expr+=f" | (uint64_t({name}[{k*2+1}]) << 32)"
                expr=f"({expr}) & {mask(min(64,width-k*64))}"
                main+=[f"{{uint64_t x={expr}; if(v[{index}]!=x){{v[{index}]=x;"+self.notify_word(index)+"}}"]
        main+=["settle();","if(clk_i && !clock_previous){ advance(); settle(); }",
               "if(!clk_i && clock_previous){"+ "".join(p+"();" for p in neg)+"}",
               "clock_previous=clk_i; initialized=true;"]
        for name,port in self.ports.items():
            if port["direction"]!="output":continue
            width=len(port["bits"])
            if width<=64:main.append(f"{name}={self.signal(port['bits'])};")
            else:
                for k in range(0,width,32):
                    main.append(f"{name}[{k//32}]=uint32_t({self.signal(port['bits'][k:k+32])});")
        main+=["}"]
        (out/"model.cpp").write_text("\n".join(main)+"\n")
        report={"cells":dict(Counter(c["type"] for c in self.cells.values())),
                "combinational_nodes":len(order),"state_words":len(self.state_words),
                "memory_words":self.memory_words,"value_words":len(self.words),
                "translation_units":len(self.parts)+1,"event_groups":self.group_count,"local_intermediate_words":self.local_count,
                "scheduler":"topological dirty groups; changes propagate at word boundaries",
                "assertions":sum(c["type"]=="$check" for c in self.cells.values()),
                "clock":"single positive edge clk_i","initialization":"two-state zero",
                "sources":[p+".cpp" for p in self.parts]+["model.cpp"]}
        (out/"network-report.json").write_text(json.dumps(report,indent=2)+"\n")
        return report

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("design",type=Path)
    parser.add_argument("--out",type=Path,required=True)
    parser.add_argument("--top",default="R64SystemTestTop")
    args=parser.parse_args()
    design=json.loads(args.design.read_text())
    report=Compiler(design["modules"][args.top]).emit(args.out)
    print(json.dumps({k:v for k,v in report.items() if k!="sources"},indent=2))

if __name__=="__main__":
    main()
