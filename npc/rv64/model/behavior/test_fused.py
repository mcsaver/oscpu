#!/usr/bin/env python3
"""Independent ordered-IR oracle checks for the GPU fusion and word projection."""
import random,sys,unittest
sys.dont_write_bytecode=True
from always_ir import *
from fused_rules import fuse,evaluate
from simd_values import canonical
from word_projection import word
from counter import counter
from lsu_queue import request_queue
from test_codegen import semantics_model
from test_queue import sequence

class FusedTest(unittest.TestCase):
    def test_fused_and_projected_rules_match_ordered_interpreter(self):
        for model in (counter(),request_queue(data_w=193,age_w=32,prepared_cancel=True),semantics_model()):
            with self.subTest(model=model.name):
                rules=fuse(model);rng=random.Random(571)
                if model.name=="R64LsuRequestQueue":rows=sequence(model,cycles=150)[0]
                else:rows=[{n:rng.getrandbits(w) for n,w in model.inputs.items()} for _ in range(80)]
                model.state=dict(model.initial)
                for cycle,inputs in enumerate(rows):
                    edge=cycle%2 if model.name=="semantics" else 0
                    env=dict(model.state,**inputs);memo={}
                    direct={n:evaluate(e,env,edge,memo) for n,e in rules.next_state.items()}
                    projected={n:sum(evaluate(word(canonical(e),j),env,edge,memo)<<(32*j)
                                     for j in range((model.states[n]+31)//32)) for n,e in rules.next_state.items()}
                    model.step(inputs,"negedge" if edge else "posedge")
                    self.assertEqual(direct,model.state)
                    self.assertEqual(projected,model.state)

    def test_guarded_checks_keep_phase_and_old_state(self):
        model=Model("checks",{"enable":1},{"q":1},{},[
            Block("edge","posedge",(If(ref("enable"),(
                nba("q",const(1)),Check(eq(ref("q"),const(0)),"old q"))),))
        ])
        rules=fuse(model)
        for row,old,want in (({"enable":0},1,1),({"enable":1},0,1),({"enable":1},1,0)):
            self.assertEqual(evaluate(rules.edge_checks[0][1],dict(q=old,**row),0),want)
            self.assertEqual(evaluate(rules.edge_checks[0][1],dict(q=old,**row),1),1)

    def test_full_width_blocking_alias_and_dynamic_nba_address(self):
        model=Model("alias",{"index":65},{"q":130},{"view":130},[
            Block("comb","comb",(blocking("view",ref("q",130)),
                blocking("view",ref("view",130),low=ref("index",65),width=130))),
            Block("edge","posedge",(
                blocking("at",ref("index",65)),
                nba("q",const(511,9),low=ref("at",65),width=9),
                blocking("at",const(0,65)),
                nba("q",ref("view",130),low=ref("at",65),width=130)),locals={"at":65})
        ],initial={"q":(1<<129)|9},outputs={"view":ref("view",130)})
        rules=fuse(model)
        for index in (0,1,31,32,63,64,129,130,1<<64):
            env=dict(model.state,index=index);memo={}
            before=evaluate(rules.outputs["view"],env,0,memo)
            self.assertEqual(before,model.observe({"index":index})["view"])
            expected=evaluate(rules.next_state["q"],env,0,memo)
            model.step({"index":index});self.assertEqual(expected,model.state["q"])
if __name__=="__main__":unittest.main(verbosity=2)
