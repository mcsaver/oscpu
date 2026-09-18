"""Ordered behavior of production R64LsuCompletion, including free payload writes."""
from always_ir import *
SOURCE="npc/rv64/vsrc/chengyue64/lsu/R64LsuCompletion.v"
RESULT_W=140

def all_of(*xs):
    value=const(1)
    for x in xs:value=band(value,x)
    return value

def any_of(*xs):
    value=const(0)
    for x in xs:value=bor(value,x)
    return value

def completion(tag_w=9,rob_w=5):
    if not 1<=rob_w<=10 or tag_w<rob_w:raise ValueError("invalid completion configuration")
    R=RESULT_W;slots=1<<rob_w
    inputs={"rst_i":1,"flush_i":1,"kill_mask_i":slots,"in_fire_i":2,"in_tag_i":2*tag_w,"in_result_i":2*R,"out_ready_i":2}
    states={"front_q":2,"back_q":2,"turn_q":1}
    for g in range(2):
        for side in ("front","back"):
            states[f"{side}_tag_q{g}"]=tag_w;states[f"{side}_result_q{g}"]=R
    wires={"free_w":2,"first_w":1,"in_ready_o":2,"idle_o":1,"out_valid_o":2,
           "out_request_o":2,"out_tag_o":2*tag_w,"out_result_o":2*R,"reuse_block_o":slots}
    types={**inputs,**states,**wires};r=lambda n:ref(n,types[n]);bit=lambda n,g:bit_slice(r(n),g)
    free=inv(r("back_q"));first=mux(indexed(free,r("turn_q")),r("turn_q"),inv(r("turn_q")))
    ready=band(concat(eq(free,const(3,2)),nonzero(free)),
               mux(any_of(r("rst_i"),r("flush_i")),const(0,2),const(3,2)))
    blocks=[Block("credit","comb",(blocking("free_w",free),blocking("first_w",first),
        blocking("in_ready_o",ready),blocking("idle_o",inv(nonzero(bor(r("front_q"),r("back_q")))))),source=SOURCE+":20")]
    valids=[];requests=[]
    for g in range(2):
        killed=lambda side:indexed(r("kill_mask_i"),bit_slice(r(f"{side}_tag_q{g}"),0,rob_w))
        front=bit("front_q",g);back=bit("back_q",g)
        remove=all_of(front,any_of(bit("out_ready_i",g),r("flush_i"),killed("front")))
        cancel=any_of(r("flush_i"),killed("back"))
        input_lane=inv(eq(r("first_w"),const(g)))
        take=any_of(all_of(bit("in_fire_i",0),inv(input_lane)),all_of(bit("in_fire_i",1),input_lane))
        front_input=all_of(take,any_of(inv(front),remove))
        back_input=all_of(take,front,inv(remove))
        shift=all_of(remove,back)
        tag=mux(input_lane,bit_slice(r("in_tag_i"),tag_w,tag_w),bit_slice(r("in_tag_i"),0,tag_w))
        result=mux(input_lane,bit_slice(r("in_result_i"),R,R),bit_slice(r("in_result_i"),0,R))
        valids.append(all_of(front,inv(r("flush_i")),inv(killed("front")),inv(r("rst_i"))))
        requests.append(any_of(front,back,take))
        blocks.append(Block(f"lane{g}","posedge",(
            If(r("rst_i"),(nba("front_q",const(0),g,1),nba("back_q",const(0),g,1)),(
                nba("front_q",any_of(all_of(front,inv(remove)),all_of(remove,back,inv(cancel)),front_input),g,1),
                nba("back_q",any_of(all_of(back,inv(remove),inv(cancel)),back_input),g,1),
                If(any_of(inv(front),remove),(
                    nba(f"front_tag_q{g}",mux(back,r(f"back_tag_q{g}"),tag)),
                    nba(f"front_result_q{g}",mux(back,r(f"back_result_q{g}"),result)))),
                If(all_of(inv(back),front,inv(remove)),(
                    nba(f"back_tag_q{g}",tag),nba(f"back_result_q{g}",result))))),
            If(inv(r("rst_i")),(Check(inv(all_of(front_input,shift)),"incompatible writes"),))
        ),source=SOURCE+":65"))
    blocks.append(Block("ports","comb",(
        blocking("out_valid_o",concat(*reversed(valids))),
        blocking("out_tag_o",concat(r("front_tag_q1"),r("front_tag_q0"))),
        blocking("out_result_o",concat(r("front_result_q1"),r("front_result_q0")))),source=SOURCE+":25"))
    blocks.append(Block("request","comb",(blocking("out_request_o",concat(*reversed(requests))),),source=SOURCE+":48"))
    reuse=[blocking("reuse_block_o",const(0,slots))]
    for g in range(2):
        for side in ("front","back"):
            reuse.append(If(bit(side+"_q",g),(blocking("reuse_block_o",const(1),
                low=bit_slice(r(f"{side}_tag_q{g}"),0,rob_w),width=1),)))
    blocks.append(Block("reuse","comb",tuple(reuse),source=SOURCE+":31"))
    blocks.append(Block("turn","posedge",(If(r("rst_i"),(nba("turn_q",const(0)),),
        (If(bit("in_fire_i",0),(nba("turn_q",inv(r("first_w"))),)),)),),source=SOURCE+":85"))
    blocks.append(Block("protocol","posedge",(If(inv(r("rst_i")),(
        Check(all_of(eq(band(r("in_fire_i"),inv(r("in_ready_o"))),const(0,2)),inv(eq(r("in_fire_i"),const(2,2)))),"credit/prefix violation"),
        Check(eq(band(r("back_q"),inv(r("front_q"))),const(0,2)),"hole"))),),source=SOURCE+":90"))
    m=Model("R64LsuCompletion",inputs,states,wires,blocks,
        outputs={n:r(n) for n in ("in_ready_o","out_valid_o","out_request_o","out_tag_o","out_result_o","reuse_block_o","idle_o")})
    m.parameters={"TAG_W":tag_w,"ROB_W":rob_w}
    m.rtl_state_paths={n:(n[:-1]+"["+n[-1]+"]" if n[-1].isdigit() else n) for n in states}
    return m
