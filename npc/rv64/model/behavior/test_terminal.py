#!/usr/bin/env python3
"""Independent production-Verilog oracle for the connected LSU terminal slice."""
import random,re,subprocess,sys,tempfile,unittest
from pathlib import Path
sys.dont_write_bytecode=True
from always_ir import *
from compose import Network
from lsu_terminal import terminal
from test_always import ROOT,command

RTL=ROOT/"npc/rv64/vsrc/lsu"

def original_statement(source,lhs):
    match=re.search(r"assign\s+"+re.escape(lhs)+r"\s*=\s*[^;]+;",source)
    if not match:raise ValueError("production statement missing: "+lhs)
    return match[0]

def rtl_wrapper(model):
    """Retain production selector/completion and verbatim parent glue/functions.

    Only boundary wiring and debug exposure are authored here. This oracle never
    consumes behavioral update expressions and never uses generated model RTL.
    """
    tw=model.parameters["TAG_W"];rw=model.parameters["ROB_W"];pc=model.parameters["PREPARED_CANCEL"]
    source=(RTL/"R64Lsu.v").read_text()
    declarations=[*(f"input [{w-1}:0] {n}" for n,w in model.inputs.items()),
                  *(f"output [{e.width-1}:0] {n}" for n,e in model.outputs.items()),"input clk_i"]
    lines=["module TerminalRtl("+",".join(declarations)+");",
           f"localparam TAG_W={tw},ROB_W={rw},PREPARED_CANCEL={pc},R=140,RAW_W=152;",
           "genvar g,e,z;",
           "wire [1:0] completion_credit_w;reg [1:0] completion_fire_w;",
           "reg [2*TAG_W-1:0] completion_tag_w;reg [2*R-1:0] completion_result_w;",
           "wire [(1<<ROB_W)-1:0] completion_reuse_w;wire completion_idle_w;",
           "wire [5:0] event_valid_w;wire [TAG_W-1:0] event_tag_w[0:5];",
           "wire [R-1:0] event_result_w[0:5];reg [5:0] event_grant_w;"]
    for index,(name,width) in enumerate((("raw",152),("fault",70),("forward",77))):
        lines += [f"wire [1:0] {name}_valid_w;wire [2*TAG_W-1:0] {name}_tags_w;",
                  f"wire [{2*width-1}:0] {name}_payload_w;",
                  f"wire [(1<<ROB_W)-1:0] {name}_reuse_w;wire {name}_idle_w;",
                  f"R64LsuRequestQueue #(.DATA_W({width}),.TAG_W(TAG_W),.ROB_W(ROB_W),.PREPARED_CANCEL(PREPARED_CANCEL)) {name}(",
                  ".clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),",
                  ".cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),",
                  f".in_fire_i({name}_fire_i),.in_ready_o({name}_ready_o),.in_tag_i({name}_tag_i),.in_data_i({name}_data_i),",
                  ".in_age_i(2'b0),.age_clear_i(1'b0),.out_age_o(),.held_age_o(),.out_occupied_o(),",
                  f".out_valid_o({name}_valid_w),.out_ready_i(event_grant_w[{index*2}+:2]),",
                  f".out_tag_o({name}_tags_w),.out_data_o({name}_payload_w),.reuse_block_o({name}_reuse_w),.idle_o({name}_idle_w));"]
    lines += ["wire [2*RAW_W-1:0] raw_data_w=raw_payload_w;wire [2*TAG_W-1:0] raw_tag_w=raw_tags_w;",
              "wire [1:0] fault_queue_valid_w=fault_valid_w;wire [139:0] fault_data_w=fault_payload_w;",
              "wire [2*TAG_W-1:0] fault_tag_w=fault_tags_w;",
              "wire [1:0] forward_valid_q=forward_valid_w;wire [1:0] forward_killed_w;",
              "wire [TAG_W-1:0] forward_tag_q[0:1];wire [63:0] forward_data_q[0:1];",
              "wire [4:0] forward_func_q[0:1],forward_amo_q[0:1];wire [2:0] forward_offset_q[0:1];",
              "wire [127:0] response_data_w,response_va_w;wire [1:0] response_zero_w,response_error_w;",
              "wire [5:0] response_load_offset_w,response_offset_w;wire [9:0] response_amo_w,response_func_w;",
              "wire [11:0] response_cause_w;wire [63:0] formatted_response_w[0:1];"]
    function=re.search(r"function \[63:0\] load_value;.*?endfunction",source,re.S)[0]
    lines += [function,"generate for(g=0;g<2;g=g+1)begin:formats"]
    for name,low,width in (("response_data_w",0,64),("response_zero_w",64,1),("response_load_offset_w",65,3),
                           ("response_amo_w",68,5),("response_func_w",73,5),("response_va_w",78,64),
                           ("response_cause_w",142,6),("response_error_w",148,1),("response_offset_w",149,3)):
        lhs=name+("[g]" if width==1 else f"[g*{width}+:{width}]")
        lines.append(original_statement(source,lhs))
    lines += [original_statement(source,"formatted_response_w[g]"),
              original_statement(source,"forward_tag_q[g]"),
              re.search(r"assign \{forward_offset_q\[g\].*?;",source,re.S)[0],"end endgenerate",
              "generate for(e=0;e<2;e=e+1)begin:events"]
    for lhs in ("event_valid_w[e]","event_tag_w[e]","event_result_w[e]","event_valid_w[2+e]",
                "event_tag_w[2+e]","event_result_w[2+e]","forward_killed_w[e]","event_valid_w[4+e]",
                "event_tag_w[4+e]","event_result_w[4+e]"):
        lines.append(original_statement(source,lhs))
    lines.append("end endgenerate")
    start=source.index(" wire [5:0] event_first_w,event_second_w;")
    end=source.index(" // Program age belongs to dispatch reserve",start)
    lines.append(source[start:end])
    # Retain the production parent count assertion alongside child assertions.
    count_assert=re.search(r"if\(\(\{event_two_w,\|event_valid_w\}.*?\$fatal\(1,\"R64Lsu event count changed completion acceptance\"\);",source,re.S)[0]
    lines += ["always @(posedge clk_i)if(!rst_i)begin",count_assert,"end",
              "assign event_grant_o=event_grant_w;assign event_valid_o=event_valid_w;",
              "assign completion_fire_o=completion_fire_w;assign completion_credit_o=completion_credit_w;",
              "assign reuse_block_o=raw_reuse_w|fault_reuse_w|forward_reuse_w|completion_reuse_w;",
              "assign idle_o=raw_idle_w&&fault_idle_w&&forward_idle_w&&completion_idle_w;","endmodule"]
    return "\n".join(lines)+"\n"

def rtl_run(model,cases,directory,expect_failure=False):
    root=Path(directory);root.mkdir(parents=True,exist_ok=True)
    (root/"terminal.sv").write_text(rtl_wrapper(model))
    inp=root/"inputs.txt";inp.write_text("\n".join(" ".join(f"{r[n]:x}" for n in model.inputs) for _,r in cases)+"\n")
    lines=["module tb;reg clk_i=0;"]
    lines += [f"reg [{w-1}:0] {n};" for n,w in model.inputs.items()]
    lines += [f"wire [{e.width-1}:0] {n};" for n,e in model.outputs.items()]
    lines += ["TerminalRtl d(.*);integer f,r;initial begin"]
    lines += [f"d.{model.rtl_state_paths[n]}={w}'h{model.initial[n]:x};" for n,w in model.states.items()]
    names=list(model.inputs)
    lines += [f'f=$fopen("{inp}","r");while(!$feof(f))begin',
              'r=$fscanf(f,"'+" ".join("%h" for _ in names)+'",'+",".join(names)+");",
              f"if(r=={len(names)})begin clk_i=0;#1;"]
    obs=list(model.outputs)+["d."+model.rtl_state_paths[n] for n in model.states]
    display='$display("'+" ".join("%h" for _ in obs)+'",'+",".join(obs)+");"
    lines += [display,"clk_i=1;#1;",display,"end end $finish;end endmodule"]
    (root/"tb.sv").write_text("\n".join(lines))
    command(["iverilog","-g2012","-DR64_ASSERT","-I",ROOT/"npc/rv64/vsrc/backend",
             "-s","tb","-o",root/"sim",root/"tb.sv",root/"terminal.sv",
             RTL/"R64LsuRequestQueue.v",RTL/"R64LsuCompletion.v",RTL/"R64LsuOrderSelect.v"])
    result=subprocess.run(["vvp",str(root/"sim")],capture_output=True,text=True,timeout=60)
    if expect_failure:
        if result.returncode==0 or "FATAL:" not in result.stdout:raise AssertionError("RTL accepted illegal input")
        return result.stdout
    if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    return [tuple(int(x,16) for x in line.split()) for line in result.stdout.splitlines() if "$finish" not in line]

def sequence(model,cycles=1200,seed=916):
    rng=random.Random(seed);model.state=dict(model.initial);rows=[];expected=[]
    coverage={n:0 for n in ("six_sources","dual_capture","backpressure","same_edge_push_pop","kill_resident","flush_resident","priority_wrap","skid_shift")}
    order=[b.name for b in model.blocks if b.kind=="posedge"]
    def observation(row):return tuple(model.observe(row).values())+tuple(model.state.values())
    for cycle in range(cycles):
        row={n:rng.getrandbits(w) for n,w in model.inputs.items()}
        row.update(rst_i=int(cycle==0 or cycle%251==0),flush_i=int(cycle>0 and rng.randrange(53)==0),
                   cancel_active_i=int(rng.randrange(7)==0),out_ready_i=rng.randrange(4))
        row["kill_mask_i"]=row["cancel_candidates_i"] if row["cancel_active_i"] else 0
        if cycle<36:
            row.update(rst_i=int(cycle==0),flush_i=0,cancel_active_i=0,kill_mask_i=0,
                       out_ready_i=0 if cycle<12 else 3)
        if cycle>=cycles-24:
            row.update(rst_i=0,flush_i=0,kill_mask_i=0,cancel_active_i=0,out_ready_i=3)
        for n in ("raw","fault","forward"):row[n+"_fire_i"]=0
        pre=model.observe(row)
        for n in ("raw","fault","forward"):
            want=3 if cycle<30 else rng.randrange(4)
            if cycle>=cycles-24:want=0
            row[n+"_fire_i"]=want&pre[n+"_ready_o"]
        pre=model.observe(row);old=dict(model.state)
        coverage["six_sources"]+=int(pre["event_valid_o"]==63)
        coverage["dual_capture"]+=int(pre["completion_fire_o"]==3)
        coverage["backpressure"]+=int(pre["event_valid_o"]!=0 and pre["completion_credit_o"]==0)
        coverage["same_edge_push_pop"]+=sum((row[n+"_fire_i"]&(pre["event_grant_o"]>>(2*i))).bit_count() for i,n in enumerate(("raw","fault","forward")))
        coverage["kill_resident"]+=int(bool(row["kill_mask_i"]&pre["reuse_block_o"]))
        coverage["flush_resident"]+=int(row["flush_i"] and not pre["idle_o"])
        coverage["skid_shift"]+=int(bool(old["completion__back_q"]&old["completion__front_q"]&row["out_ready_i"]))
        expected.append(observation(row));rng.shuffle(order)
        patches=model.prepare(row,order=order);rng.shuffle(patches);model.commit(patches)
        expected.append(observation(row));rows.append(("posedge",row))
        coverage["priority_wrap"]+=int(old["events__event_before_q"]!=0 and model.state["events__event_before_q"]==0 and not row["rst_i"])
    if cycles>=100 and not all(coverage.values()):raise AssertionError(("coverage",coverage))
    if cycles>=100 and not model.observe(rows[-1][1])["idle_o"]:raise AssertionError("terminal did not drain")
    return rows,expected,coverage

class TerminalTest(unittest.TestCase):
    def test_connected_slice_against_production_rtl(self):
        for cfg in ({},{"tag_w":12,"rob_w":6,"prepared_cancel":True}):
            with self.subTest(config=cfg),tempfile.TemporaryDirectory(prefix="r64-terminal-rtl-") as d:
                m=terminal(**cfg);rows,expected,coverage=sequence(m,cycles=1200)
                actual=rtl_run(m,rows,d)
                self.assertEqual(len(actual),len(expected))
                for index,(a,b) in enumerate(zip(actual,expected)):self.assertEqual(a,b,("observation",index))
                print("TERMINAL_RTL_PASS",cfg,coverage,flush=True)

    def test_materialized_frontiers_match_ordered_network(self):
        from dataflow_codegen import DataflowEmitter
        from fused_rules import evaluate
        m=terminal();cases,_,_=sequence(m,cycles=120)
        e=DataflowEmitter(m);m.state=dict(m.initial)
        for edge,row in cases:
            env=dict(m.state,**row)
            for frontier in e.frontiers:
                env.update({n:evaluate(v,env) for n,v in frontier.items()})
            values={n:evaluate(v,env) for n,v in e.rules.outputs.items()}
            self.assertEqual(values,m.observe(row))
            pending={n:evaluate(v,env) for n,v in e.rules.next_state.items()}
            for _,check,_ in e.rules.edge_checks:self.assertEqual(evaluate(check,env),1)
            m.step(row,edge);self.assertEqual(pending,m.state)

    def test_connection_validation(self):
        child=Model("q",{"d":1},{"q":1},{},[Block("reg","posedge",(nba("q",ref("d")),))])
        net=Network("feedback",{}).add("a",child).add("b",child)
        net.connect("a","d",net.port("b","q"));net.connect("b","d",net.port("a","q"))
        m=net.build({"a":net.port("a","q"),"b":net.port("b","q")})
        m.state["a__q"]=1;m.step({});self.assertEqual(m.state,{"a__q":0,"b__q":1})
        with self.assertRaisesRegex(ValueError,"unbound"):Network("bad",{}).add("a",child).build({})
        with self.assertRaisesRegex(ValueError,"width"):Network("bad",{}).add("a",child).connect("a","d",const(0,2))
        comb=Model("comb",{"d":1},{},{"q":1},[Block("pass","comb",(blocking("q",ref("d")),))],outputs={"q":ref("q")})
        loop=Network("loop",{}).add("a",comb).add("b",comb)
        loop.connect("a","d",loop.port("b","q"));loop.connect("b","d",loop.port("a","q"))
        with self.assertRaisesRegex(ValueError,"cycl"):loop.build({"q":loop.port("a","q")})
if __name__=="__main__":unittest.main(verbosity=2)
