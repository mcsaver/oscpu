"""Direct ordered behavior of R64LsuRequestQueue; no synthesis/netlist import."""
from always_ir import *

SOURCE="npc/rv64/vsrc/lsu/R64LsuRequestQueue.v"

def request_queue(data_w=157,tag_w=9,rob_w=5,age_w=1,prepared_cancel=False,assertions=True):
    if not 1<=rob_w<=10 or tag_w<rob_w or min(data_w,age_w)<1:
        raise ValueError("invalid queue configuration")
    slots=1<<rob_w
    inputs={"rst_i":1,"flush_i":1,"kill_mask_i":slots,"cancel_candidates_i":slots,
            "cancel_active_i":1,"in_fire_i":2,"in_tag_i":2*tag_w,"in_data_i":2*data_w,
            "in_age_i":2*age_w,"age_clear_i":age_w,"out_ready_i":2}
    states={"valid_q0":2,"valid_q1":2,"head_q":2}
    for lane in range(2):
        for slot in range(2):
            for field,width in (("tag",tag_w),("rob_slot",slots),("data",data_w),("age",age_w)):
                states[f"{field}_q{lane}_{slot}"]=width
    output_types={"in_ready_o":2,"out_occupied_o":2,"out_valid_o":2,"out_tag_o":2*tag_w,
                  "out_data_o":2*data_w,"out_age_o":2*age_w,"reuse_block_o":slots,
                  "held_age_o":age_w,"idle_o":1}
    wires={**output_types,"write_slot_w":2,"valid_d0":2,"valid_d1":2,"head_d":2}
    if assertions:wires["reference_reuse_r"]=slots
    types={**inputs,**states,**wires}
    r=lambda name:ref(name,types[name])
    bit=lambda name,index:bit_slice(r(name),index)
    def all_of(*values):
        v=const(1)
        for x in values:v=band(v,x)
        return v
    def any_of(*values):
        v=const(0)
        for x in values:v=bor(v,x)
        return v
    def resident(lane,field):
        return mux(bit("head_q",lane),r(f"{field}_q{lane}_1"),r(f"{field}_q{lane}_0"))
    def cancelled(tag):
        index=bit_slice(tag,0,rob_w)
        return band(r("cancel_active_i"),indexed(r("cancel_candidates_i"),index)) if prepared_cancel else indexed(r("kill_mask_i"),index)
    occupied=[indexed(r(f"valid_q{lane}"),bit("head_q",lane)) for lane in range(2)]
    valid=[all_of(occupied[lane],inv(r("rst_i")),inv(r("flush_i")),inv(cancelled(resident(lane,"tag")))) for lane in range(2)]
    ready=[all_of(inv(eq(r(f"valid_q{lane}"),const(3,2))),inv(r("rst_i")),inv(r("flush_i"))) for lane in range(2)]
    assignments=[
        blocking("write_slot_w",concat(bit("valid_q1",0),bit("valid_q0",0))),
        blocking("in_ready_o",concat(*reversed(ready))),
        blocking("out_occupied_o",concat(*reversed(occupied))),
        blocking("out_valid_o",concat(*reversed(valid))),
        blocking("out_tag_o",concat(resident(1,"tag"),resident(0,"tag"))),
        blocking("out_data_o",concat(resident(1,"data"),resident(0,"data"))),
        blocking("out_age_o",concat(resident(1,"age"),resident(0,"age"))),
        blocking("idle_o",all_of(inv(nonzero(r("valid_q0"))),inv(nonzero(r("valid_q1"))))),
    ]
    blocks=[Block("continuous_ports","comb",tuple(assignments),source=SOURCE+":37")]
    for lane in range(2):
        for slot in range(2):
            write=all_of(inv(bit(f"valid_q{lane}",slot)),eq(bit("write_slot_w",lane),const(slot)))
            age=band(bit_slice(r("in_age_i"),lane*age_w,age_w),inv(r("age_clear_i")))
            capture=(
                nba(f"tag_q{lane}_{slot}",bit_slice(r("in_tag_i"),lane*tag_w,tag_w)),
                nba(f"rob_slot_q{lane}_{slot}",shl(const(1,slots),bit_slice(r("in_tag_i"),lane*tag_w,rob_w))),
                nba(f"data_q{lane}_{slot}",bit_slice(r("in_data_i"),lane*data_w,data_w)),
                nba(f"age_q{lane}_{slot}",age))
            retain=(nba(f"age_q{lane}_{slot}",band(r(f"age_q{lane}_{slot}"),inv(r("age_clear_i")))),)
            blocks.append(Block(f"g_lane{lane}_g_storage{slot}","posedge",
                (If(inv(r("rst_i")),(If(write,capture,retain),)),),source=SOURCE+":48"))
    body=[blocking("reuse_block_o",const(0,slots)),blocking("held_age_o",const(0,age_w)),
          blocking("head_d",r("head_q"))]
    for lane in range(2):
        body.append(blocking(f"valid_d{lane}",r(f"valid_q{lane}")))
        for slot in range(2):
            body += [
                If(bit(f"valid_q{lane}",slot),(
                    blocking("reuse_block_o",bor(r("reuse_block_o"),r(f"rob_slot_q{lane}_{slot}"))),
                    blocking("held_age_o",bor(r("held_age_o"),r(f"age_q{lane}_{slot}"))))),
                If(any_of(r("flush_i"),cancelled(r(f"tag_q{lane}_{slot}"))),
                    (blocking(f"valid_d{lane}",const(0),low=slot,width=1),))]
        pop=all_of(bit("out_valid_o",lane),bit("out_ready_i",lane))
        body += [
            If(pop,(blocking(f"valid_d{lane}",const(0),low=bit("head_q",lane),width=1),)),
            If(bit("in_fire_i",lane),(blocking(f"valid_d{lane}",const(1),low=bit("write_slot_w",lane),width=1),)),
            If(inv(nonzero(r(f"valid_q{lane}"))),(blocking("head_d",const(0),low=lane,width=1),),
               (If(any_of(r("flush_i"),cancelled(resident(lane,"tag")),pop),
                   (blocking("head_d",inv(bit("head_q",lane)),low=lane,width=1),)),))]
    blocks.append(Block("occupancy_next","comb",tuple(body),source=SOURCE+":61"))
    blocks.append(Block("occupancy_registers","posedge",
        (If(r("rst_i"),tuple(nba(n,const(0,2)) for n in ("valid_q0","valid_q1","head_q")),
            (nba("valid_q0",r("valid_d0")),nba("valid_q1",r("valid_d1")),nba("head_q",r("head_d")))),),
        source=SOURCE+":83"))
    if assertions:
        if prepared_cancel:
            blocks.append(Block("g_cancel_contract","posedge",
                (If(inv(r("rst_i")),(Check(eq(r("kill_mask_i"),mux(r("cancel_active_i"),r("cancel_candidates_i"),const(0,slots))),
                                               "prepared cancel differs from canonical mask"),)),),source=SOURCE+":89"))
        for lane in range(2):
            h=bit("head_q",lane);d=r(f"valid_d{lane}")
            old_next=mux(all_of(inv(indexed(d,h)),indexed(d,inv(h))),inv(h),h)
            blocks.append(Block(f"g_head_equivalence{lane}","posedge",
                (If(all_of(inv(r("rst_i")),nonzero(d)),(Check(eq(bit("head_d",lane),old_next),
                                                                   "Q-head changed occupied owner order"),)),),source=SOURCE+":97"))
        lease=[blocking("reference_reuse_r",const(0,slots))]
        for lane in range(2):
            for slot in range(2):
                lease.append(If(bit(f"valid_q{lane}",slot),(
                    blocking("reference_reuse_r",const(1),low=bit_slice(r(f"tag_q{lane}_{slot}"),0,rob_w),width=1),)))
        blocks.append(Block("reference_reuse","comb",tuple(lease),source=SOURCE+":102"))
        occupied_head=all_of(*(bor(inv(nonzero(r(f"valid_q{lane}"))),occupied[lane]) for lane in range(2)))
        blocks.append(Block("protocol_checks","posedge",(If(inv(r("rst_i")),(
            Check(eq(r("reuse_block_o"),r("reference_reuse_r")),"reuse projection"),
            Check(eq(band(r("in_fire_i"),inv(r("in_ready_o"))),const(0,2)),"credit violation"),
            Check(occupied_head,"oldest slot not occupied"))),),source=SOURCE+":109"))
    model=Model("R64LsuRequestQueue",inputs,states,wires,blocks,
                outputs={n:r(n) for n in output_types})
    model.parameters={"DATA_W":data_w,"TAG_W":tag_w,"ROB_W":rob_w,"AGE_W":age_w,
                      "PREPARED_CANCEL":int(prepared_cancel)}
    model.rtl_state_paths={n:(f"valid_q[{n[-1]}]" if n.startswith("valid_q") else
                             "head_q" if n=="head_q" else
                             n.rsplit("q",1)[0]+"q["+n.rsplit("q",1)[1].replace("_","][")+"]")
                           for n in states}
    return model
