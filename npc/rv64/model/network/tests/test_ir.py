import copy
import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from semantics import IR, Expr, build, validate_config


class Contracts(unittest.TestCase):
    def setUp(self):
        self.cfg=json.loads((Path(__file__).resolve().parents[1]/"completion.json").read_text())

    def test_no_combinational_cycle(self):
        ir=IR()
        ir.wire("cycle",Expr(1,"ref",value="cycle"))
        with self.assertRaisesRegex(ValueError,"cycle"): ir.validate()

    def test_state_assignment_and_types(self):
        ir=IR(); reset=ir.input("reset"); q=ir.reg("q",2)
        with self.assertRaises(ValueError): ir.update(q,ir.const(1),reset)
        ir.update(q,ir.const(1,2),reset)
        with self.assertRaisesRegex(ValueError,"multiple"): ir.update(q,q,reset)
        with self.assertRaises(ValueError): ir.const(256,8)
        with self.assertRaises(ValueError): ir.mux(reset,ir.const(0,3),ir.const(0,4))

    def test_malformed_expression_rejected(self):
        ir=IR()
        ir.wire("bad",Expr(1,"eq",(ir.const(0,1),ir.const(0,2))))
        with self.assertRaisesRegex(ValueError,"types"): ir.validate()
        ir=IR()
        ir.wire("bad",Expr(1,"mux",(ir.const(1),)))
        with self.assertRaisesRegex(ValueError,"arity"): ir.validate()

    def test_ports_are_closed(self):
        cfg=copy.deepcopy(self.cfg)
        cfg["links"][-1][1]=cfg["links"][-2][1]
        with self.assertRaisesRegex(ValueError,"port"): validate_config(cfg)
        cfg=copy.deepcopy(self.cfg);cfg["links"].pop()
        with self.assertRaisesRegex(ValueError,"unconnected"): validate_config(cfg)

    def test_unsupported_topology_rejected(self):
        cfg=copy.deepcopy(self.cfg)
        cfg["links"][0][1],cfg["links"][3][1]=cfg["links"][3][1],cfg["links"][0][1]
        with self.assertRaises(ValueError): validate_config(cfg)

    def test_permutation_changes_real_mapping(self):
        cfg=copy.deepcopy(self.cfg)
        cfg["links"][3][1],cfg["links"][5][1]=cfg["links"][5][1],cfg["links"][3][1]
        cfg["links"][-1][1],cfg["links"][-2][1]=cfg["links"][-2][1],cfg["links"][-1][1]
        _,layout=build(cfg)
        self.assertEqual(layout["input_for_arb"],[2,1,0])
        self.assertEqual(layout["sink_for_lane"],[1,0])

    def test_invalid_capacity_and_width(self):
        for field,value in (("owner_bits",65),("payload_bits",0),("cancel_ports",0)):
            cfg=copy.deepcopy(self.cfg);cfg[field]=value
            with self.assertRaises(ValueError): validate_config(cfg)
        cfg=copy.deepcopy(self.cfg);cfg["nodes"][0]["depth"]=0
        with self.assertRaises(ValueError): validate_config(cfg)

if __name__=="__main__":
    unittest.main()
