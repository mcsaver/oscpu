"""Manual behavior description of production R64Counter, preserving all 22 edge blocks."""
from always_ir import Block, Model, If, const, ref, bit_slice, resize, add, sub, eq, band, bor, mux, nba, blocking, concat

SOURCE="npc/rv64/vsrc/chengyue64/control/R64Counter.v"
def counter():
    inputs={"rst_i":1,"enable_i":1,"increment_i":2,"write_i":1,"write_value_i":64}
    states={"value_o":64,**{f"near_q{bank}":3 for bank in range(1,8)}}
    wires={"step_w":2,**{f"next_byte{bank}":8 for bank in range(8)}}
    wires.update({f"{mode}_near{bank}_{offset}":1
                  for mode in ("running","writing") for bank in range(1,8) for offset in range(3)})
    r=lambda n:ref(n,{**inputs,**states,**wires}[n])
    blocks=[Block("step_select","comb",(blocking("step_w",mux(r("enable_i"),r("increment_i"),const(0,2))),),
                  source=SOURCE+":9"),
            Block("low_byte","comb",(blocking("next_byte0",add(bit_slice(r("value_o"),0,8),resize(r("step_w"),8))),),
                  source=SOURCE+":21")]
    for bank in range(1,8):
        n=bank*8;near=r(f"near_q{bank}");step=r("step_w")
        nonzero=bor(eq(step,const(1,2)),bor(eq(step,const(2,2)),eq(step,const(3,2))))
        carry=bor(band(nonzero,bit_slice(near,0)),
                  bor(band(bit_slice(step,1),bit_slice(near,1)),band(eq(step,const(3,2)),bit_slice(near,2))))
        blocks.append(Block(f"next_bank{bank}","comb",
            (blocking(f"next_byte{bank}",add(bit_slice(r("value_o"),n,8),resize(carry,8))),),source=SOURCE+":29"))
        for offset in range(3):
            for mode,value,amount in (("running",r("value_o"),r("step_w")),("writing",r("write_value_i"),const(0,2))):
                threshold=sub(const(7-offset,3),resize(amount,3))
                near_expr=band(eq(bit_slice(value,3,n-3),const((1<<(n-3))-1,n-3)),
                               eq(bit_slice(value,0,3),threshold))
                blocks.append(Block(f"{mode}_summary{bank}_{offset}","comb",
                    (blocking(f"{mode}_near{bank}_{offset}",near_expr),),
                    source="npc/rv64/vsrc/chengyue64/control/R64CounterNear.v:8"))
            def put(expr):return nba(f"near_q{bank}",expr,low=offset,width=1)
            body=(If(r("rst_i"),(put(const(0)),),
                     (If(r("write_i"),(put(r(f"writing_near{bank}_{offset}")),),
                         (put(r(f"running_near{bank}_{offset}")),)),)),)
            blocks.append(Block(f"g_bank{bank}_g_near{offset}","posedge",body,source=SOURCE+":33"))
    update=(nba("value_o",concat(*(r(f"next_byte{bank}") for bank in reversed(range(8))))),)
    blocks.append(Block("value_register","posedge",
        (If(r("rst_i"),(nba("value_o",const(0,64)),),
            (If(r("write_i"),(nba("value_o",r("write_value_i")),),update),)),),source=SOURCE+":40"))
    return Model("R64Counter",inputs,states,wires,blocks)
