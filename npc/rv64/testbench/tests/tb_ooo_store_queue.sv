`include "define.v"

// T4N focused unit test: probe fill, physical request fire, B/probe terminal,
// and ROB release are separate events.  It also covers VA!=PA ownership,
// physical-head ordering, branch survival, global speculative squash, and
// request at-most-once behavior.
module tb_ooo_store_queue;
  `include "tb_common.svh"

  localparam ENTRY_COUNT_W = 2;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W;

  reg clk;
  reg rst;
  reg flush_valid;
  reg flush_all;
  reg [ROB_INDEX_W-1:0] flush_rob_head;
  reg [ROB_INDEX_W-1:0] flush_boundary_rob;
  reg rob_head_valid;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg [PRODUCER_ID_W-1:0] rob_head_producer_id;
  reg rob_head_owner_open;
  reg rob_head_launch_open;
  reg alloc0_valid;
  reg [ROB_INDEX_W-1:0] alloc0_rob_idx;
  reg [PRODUCER_ID_W-1:0] alloc0_producer_id;
  reg alloc1_valid;
  reg [ROB_INDEX_W-1:0] alloc1_rob_idx;
  reg [PRODUCER_ID_W-1:0] alloc1_producer_id;
  reg owner_bind_valid;
  reg [ROB_INDEX_W-1:0] owner_bind_rob_idx;
  reg [PRODUCER_ID_W-1:0] owner_bind_producer_id;
  reg [1:0] owner_bind_kind;
  reg [4:0] owner_bind_token;
  reg [1:0] owner_bind_mmu_epoch;
  reg [`XLEN-1:0] owner_bind_fault_tval;
  reg owner_bind1_valid;
  reg [ROB_INDEX_W-1:0] owner_bind1_rob_idx;
  reg [PRODUCER_ID_W-1:0] owner_bind1_producer_id;
  reg [1:0] owner_bind1_kind;
  reg [4:0] owner_bind1_token;
  reg [1:0] owner_bind1_mmu_epoch;
  reg [`XLEN-1:0] owner_bind1_fault_tval;
  reg fill0_valid;
  reg [ROB_INDEX_W-1:0] fill0_rob_idx;
  reg [1:0] fill0_owner_kind;
  reg [4:0] fill0_owner_token;
  reg [1:0] fill0_mmu_epoch;
  reg [`XLEN-1:0] fill0_fault_tval;
  reg [`XLEN-1:0] fill0_vaddr;
  reg [`XLEN-1:0] fill0_paddr;
  reg fill0_attr_valid;
  reg [1:0] fill0_class;
  reg fill0_cacheable;
  reg [`XLEN-1:0] fill0_data;
  reg [`STRB_W-1:0] fill0_strb;
  reg fill1_valid;
  reg [ROB_INDEX_W-1:0] fill1_rob_idx;
  reg [1:0] fill1_owner_kind;
  reg [4:0] fill1_owner_token;
  reg [1:0] fill1_mmu_epoch;
  reg [`XLEN-1:0] fill1_fault_tval;
  reg [`XLEN-1:0] fill1_vaddr;
  reg [`XLEN-1:0] fill1_paddr;
  reg fill1_attr_valid;
  reg [1:0] fill1_class;
  reg fill1_cacheable;
  reg [`XLEN-1:0] fill1_data;
  reg [`STRB_W-1:0] fill1_strb;
  reg terminal_valid;
  reg [ROB_INDEX_W-1:0] terminal_rob_idx;
  reg [1:0] terminal_owner_kind;
  reg [4:0] terminal_owner_token;
  reg [1:0] terminal_mmu_epoch;
  reg [`XLEN-1:0] terminal_fault_tval;
  reg terminal1_valid;
  reg [ROB_INDEX_W-1:0] terminal1_rob_idx;
  reg [1:0] terminal1_owner_kind;
  reg [4:0] terminal1_owner_token;
  reg [1:0] terminal1_mmu_epoch;
  reg [`XLEN-1:0] terminal1_fault_tval;
  reg release_valid;
  reg [ROB_INDEX_W-1:0] release_rob_idx;
  reg [PRODUCER_ID_W-1:0] release_producer_id;
  reg req_fire;
  reg query0_valid;
  reg [PRODUCER_ID_W-1:0] query0_producer_id;
  reg [`XLEN-1:0] query0_paddr;
  reg query0_attr_valid;
  reg [1:0] query0_class;
  reg [`STRB_W-1:0] query0_strb;
  reg query1_valid;
  reg [PRODUCER_ID_W-1:0] query1_producer_id;
  reg [`XLEN-1:0] query1_paddr;
  reg query1_attr_valid;
  reg [1:0] query1_class;
  reg [`STRB_W-1:0] query1_strb;

  wire alloc0_ready;
  wire alloc1_ready;
  wire release_ready;
  wire release_fire;
  wire req_valid;
  wire [ROB_INDEX_W-1:0] req_rob_idx;
  wire [PRODUCER_ID_W-1:0] req_producer_id;
  wire [1:0] req_owner_kind;
  wire [4:0] req_owner_token;
  wire [1:0] req_mmu_epoch;
  wire [`XLEN-1:0] req_fault_tval;
  wire [`XLEN-1:0] req_vaddr;
  wire [`XLEN-1:0] req_paddr;
  wire req_attr_valid;
  wire [1:0] req_class;
  wire req_cacheable;
  wire [`XLEN-1:0] req_data;
  wire [`STRB_W-1:0] req_strb;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_valid;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_paddr;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_attr_valid;
  wire [(1 << ENTRY_COUNT_W) * 2 - 1:0] snoop_class;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_cacheable;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data;
  wire [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb;
  wire [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx;
  wire [(1 << ENTRY_COUNT_W) * PRODUCER_ID_W - 1:0]
      snoop_producer_id;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_owner_valid;
  wire [(1 << ENTRY_COUNT_W) * 5 - 1:0] snoop_owner_token;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_request_sent;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_terminal;
  wire [ENTRY_COUNT_W-1:0] snoop_head;
  wire [ENTRY_COUNT_W:0] count;
  wire [31:0] owner_release_mask;
  wire query0_allow;
  wire query0_forward;
  wire query0_replay;
  wire [`XLEN-1:0] query0_forward_data;
  wire query1_allow;
  wire query1_forward;
  wire query1_replay;
  wire [`XLEN-1:0] query1_forward_data;

  OooStoreQueue #(
    .ENTRY_COUNT_W(ENTRY_COUNT_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(flush_valid),
    .flush_all_i(flush_all),
    .flush_rob_head_i(flush_rob_head),
    .flush_boundary_rob_i(flush_boundary_rob),
    .rob_head_valid_i(rob_head_valid),
    .rob_head_idx_i(rob_head_idx),
    .rob_head_producer_id_i(rob_head_producer_id),
    .rob_head_owner_open_i(rob_head_owner_open),
    .rob_head_launch_open_i(rob_head_launch_open),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_rob_idx_i(alloc0_rob_idx),
    .alloc0_producer_id_i(alloc0_producer_id),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_rob_idx_i(alloc1_rob_idx),
    .alloc1_producer_id_i(alloc1_producer_id),
    .owner_bind_valid_i(owner_bind_valid),
    .owner_bind_rob_idx_i(owner_bind_rob_idx),
    .owner_bind_producer_id_i(owner_bind_producer_id),
    .owner_bind_kind_i(owner_bind_kind),
    .owner_bind_token_i(owner_bind_token),
    .owner_bind_mmu_epoch_i(owner_bind_mmu_epoch),
    .owner_bind_fault_tval_i(owner_bind_fault_tval),
    .owner_bind1_valid_i(owner_bind1_valid),
    .owner_bind1_rob_idx_i(owner_bind1_rob_idx),
    .owner_bind1_producer_id_i(owner_bind1_producer_id),
    .owner_bind1_kind_i(owner_bind1_kind),
    .owner_bind1_token_i(owner_bind1_token),
    .owner_bind1_mmu_epoch_i(owner_bind1_mmu_epoch),
    .owner_bind1_fault_tval_i(owner_bind1_fault_tval),
    .fill0_valid_i(fill0_valid),
    .fill0_rob_idx_i(fill0_rob_idx),
    .fill0_owner_kind_i(fill0_owner_kind),
    .fill0_owner_token_i(fill0_owner_token),
    .fill0_mmu_epoch_i(fill0_mmu_epoch),
    .fill0_fault_tval_i(fill0_fault_tval),
    .fill0_vaddr_i(fill0_vaddr),
    .fill0_paddr_i(fill0_paddr),
    .fill0_attr_valid_i(fill0_attr_valid),
    .fill0_class_i(fill0_class),
    .fill0_cacheable_i(fill0_cacheable),
    .fill0_data_i(fill0_data),
    .fill0_strb_i(fill0_strb),
    .fill1_valid_i(fill1_valid),
    .fill1_rob_idx_i(fill1_rob_idx),
    .fill1_owner_kind_i(fill1_owner_kind),
    .fill1_owner_token_i(fill1_owner_token),
    .fill1_mmu_epoch_i(fill1_mmu_epoch),
    .fill1_fault_tval_i(fill1_fault_tval),
    .fill1_vaddr_i(fill1_vaddr),
    .fill1_paddr_i(fill1_paddr),
    .fill1_attr_valid_i(fill1_attr_valid),
    .fill1_class_i(fill1_class),
    .fill1_cacheable_i(fill1_cacheable),
    .fill1_data_i(fill1_data),
    .fill1_strb_i(fill1_strb),
    .terminal_valid_i(terminal_valid),
    .terminal_rob_idx_i(terminal_rob_idx),
    .terminal_owner_kind_i(terminal_owner_kind),
    .terminal_owner_token_i(terminal_owner_token),
    .terminal_mmu_epoch_i(terminal_mmu_epoch),
    .terminal_fault_tval_i(terminal_fault_tval),
    .terminal1_valid_i(terminal1_valid),
    .terminal1_rob_idx_i(terminal1_rob_idx),
    .terminal1_owner_kind_i(terminal1_owner_kind),
    .terminal1_owner_token_i(terminal1_owner_token),
    .terminal1_mmu_epoch_i(terminal1_mmu_epoch),
    .terminal1_fault_tval_i(terminal1_fault_tval),
    .release_valid_i(release_valid),
    .release_rob_idx_i(release_rob_idx),
    .release_producer_id_i(release_producer_id),
    .release_ready_o(release_ready),
    .release_fire_o(release_fire),
    .req_valid_o(req_valid),
    .req_rob_idx_o(req_rob_idx),
    .req_producer_id_o(req_producer_id),
    .req_owner_kind_o(req_owner_kind),
    .req_owner_token_o(req_owner_token),
    .req_mmu_epoch_o(req_mmu_epoch),
    .req_fault_tval_o(req_fault_tval),
    .req_vaddr_o(req_vaddr),
    .req_paddr_o(req_paddr),
    .req_attr_valid_o(req_attr_valid),
    .req_class_o(req_class),
    .req_cacheable_o(req_cacheable),
    .req_data_o(req_data),
    .req_strb_o(req_strb),
    .req_fire_i(req_fire),
    .owner_release_mask_o(owner_release_mask),
    .snoop_valid_o(snoop_valid),
    .snoop_addr_valid_o(snoop_addr_valid),
    .snoop_addr_o(snoop_addr),
    .snoop_paddr_o(snoop_paddr),
    .snoop_attr_valid_o(snoop_attr_valid),
    .snoop_class_o(snoop_class),
    .snoop_cacheable_o(snoop_cacheable),
    .snoop_data_o(snoop_data),
    .snoop_strb_o(snoop_strb),
    .snoop_rob_idx_o(snoop_rob_idx),
    .snoop_producer_id_o(snoop_producer_id),
    .snoop_owner_valid_o(snoop_owner_valid),
    .snoop_owner_token_o(snoop_owner_token),
    .snoop_request_sent_o(snoop_request_sent),
    .snoop_terminal_o(snoop_terminal),
    .snoop_head_o(snoop_head),
    .query0_valid_i(query0_valid),
    .query0_producer_id_i(query0_producer_id),
    .query0_paddr_i(query0_paddr),
    .query0_attr_valid_i(query0_attr_valid),
    .query0_class_i(query0_class),
    .query0_strb_i(query0_strb),
    .query0_allow_o(query0_allow),
    .query0_forward_o(query0_forward),
    .query0_replay_o(query0_replay),
    .query0_forward_data_o(query0_forward_data),
    .query1_valid_i(query1_valid),
    .query1_producer_id_i(query1_producer_id),
    .query1_paddr_i(query1_paddr),
    .query1_attr_valid_i(query1_attr_valid),
    .query1_class_i(query1_class),
    .query1_strb_i(query1_strb),
    .query1_allow_o(query1_allow),
    .query1_forward_o(query1_forward),
    .query1_replay_o(query1_replay),
    .query1_forward_data_o(query1_forward_data),
    .count_o(count)
  );

  task automatic check64;
    input string name;
    input [63:0] got;
    input [63:0] expected;
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=0x%016h expected=0x%016h",
                 name, got, expected);
        tb_errors = tb_errors + 1;
      end
    end
  endtask

  function automatic [`XLEN-1:0] owner_tval_for_rob;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      case (ridx)
        4'd3: owner_tval_for_rob = 64'h0000_0000_0000_1000;
        4'd4: owner_tval_for_rob = 64'h0000_0000_0000_2000;
        4'd6: owner_tval_for_rob = 64'h0000_0000_0000_3000;
        4'd15: owner_tval_for_rob = 64'h0000_0000_0000_5000;
        default: owner_tval_for_rob =
            {{(`XLEN-ROB_INDEX_W-12){1'b0}}, ridx, 12'b0};
      endcase
    end
  endfunction

  // Keep the low ROB slot constant while making the allocation generation
  // explicit.  v8g checks below deliberately flip only the generation field.
  function automatic [PRODUCER_ID_W-1:0] producer_id_for_rob;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      producer_id_for_rob = {
          {`OOO_PRODUCER_GEN_W{1'b1}}, ridx};
    end
  endfunction

  function automatic [PRODUCER_ID_W-1:0] wrong_generation_for_rob;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      wrong_generation_for_rob = producer_id_for_rob(ridx);
      wrong_generation_for_rob[ROB_INDEX_W] =
          !wrong_generation_for_rob[ROB_INDEX_W];
    end
  endfunction

  task automatic bind_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      owner_bind_valid = 1'b1;
      owner_bind_rob_idx = ridx;
      owner_bind_producer_id = producer_id_for_rob(ridx);
      owner_bind_kind = 2'b01;
      owner_bind_token = ridx;
      owner_bind_mmu_epoch = ridx[1:0];
      owner_bind_fault_tval = owner_tval_for_rob(ridx);
      `TB_TICK(clk);
      owner_bind_valid = 1'b0;
    end
  endtask

  task automatic alloc_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob_idx = ridx;
      alloc0_producer_id = producer_id_for_rob(ridx);
      `TB_TICK(clk);
      alloc0_valid = 1'b0;
      bind_one(ridx);
    end
  endtask

  task automatic fill_one;
    input [ROB_INDEX_W-1:0] ridx;
    input [`XLEN-1:0] va;
    input [`XLEN-1:0] pa;
    input [`XLEN-1:0] data;
    begin
      fill0_valid = 1'b1;
      fill0_rob_idx = ridx;
      fill0_owner_kind = 2'b01;
      fill0_owner_token = ridx;
      fill0_mmu_epoch = ridx[1:0];
      fill0_fault_tval = owner_tval_for_rob(ridx);
      fill0_vaddr = va;
      fill0_paddr = pa;
      fill0_attr_valid = 1'b1;
      fill0_class = `OOO_MEM_CLASS_CACHED;
      fill0_cacheable = 1'b1;
      fill0_data = data;
      fill0_strb = 8'hff;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
      fill0_attr_valid = 1'b0;
      fill0_class = `OOO_MEM_CLASS_RSVD;
      fill0_cacheable = 1'b0;
    end
  endtask

  task automatic fill_one_typed;
    input [ROB_INDEX_W-1:0] ridx;
    input [`XLEN-1:0] pa;
    input [`XLEN-1:0] data;
    input [`STRB_W-1:0] strb;
    input attr_valid;
    input [1:0] mem_class;
    begin
      fill0_valid = 1'b1;
      fill0_rob_idx = ridx;
      fill0_owner_kind = 2'b01;
      fill0_owner_token = ridx;
      fill0_mmu_epoch = ridx[1:0];
      fill0_fault_tval = owner_tval_for_rob(ridx);
      fill0_vaddr = pa ^ 64'h0000_0000_4000_0000;
      fill0_paddr = pa;
      fill0_attr_valid = attr_valid;
      fill0_class = mem_class;
      fill0_cacheable = attr_valid &&
                        (mem_class == `OOO_MEM_CLASS_CACHED);
      fill0_data = data;
      fill0_strb = strb;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
      fill0_attr_valid = 1'b0;
      fill0_class = `OOO_MEM_CLASS_RSVD;
      fill0_cacheable = 1'b0;
    end
  endtask

  task automatic query_ports_idle;
    begin
      query0_valid = 1'b0;
      query0_producer_id = '0;
      query0_paddr = '0;
      query0_attr_valid = 1'b0;
      query0_class = `OOO_MEM_CLASS_RSVD;
      query0_strb = '0;
      query1_valid = 1'b0;
      query1_producer_id = '0;
      query1_paddr = '0;
      query1_attr_valid = 1'b0;
      query1_class = `OOO_MEM_CLASS_RSVD;
      query1_strb = '0;
    end
  endtask

  task automatic clear_speculative_sq;
    begin
      query_ports_idle();
      flush_valid = 1'b1;
      flush_all = 1'b1;
      flush_rob_head = rob_head_idx;
      `TB_TICK(clk);
      flush_valid = 1'b0;
      flush_all = 1'b0;
      #1;
      tb_check32("F3 query fixture clears SQ", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic drive_query0;
    input [ROB_INDEX_W-1:0] load_rob;
    input [`XLEN-1:0] pa;
    input [`STRB_W-1:0] strb;
    begin
      query0_valid = 1'b1;
      query0_producer_id = producer_id_for_rob(load_rob);
      query0_paddr = pa;
      query0_attr_valid = 1'b1;
      query0_class = `OOO_MEM_CLASS_CACHED;
      query0_strb = strb;
      #1;
    end
  endtask

  task automatic send_terminal;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      terminal_valid = 1'b1;
      terminal_rob_idx = ridx;
      terminal_owner_kind = 2'b01;
      terminal_owner_token = ridx;
      terminal_mmu_epoch = ridx[1:0];
      terminal_fault_tval = owner_tval_for_rob(ridx);
      `TB_TICK(clk);
      terminal_valid = 1'b0;
    end
  endtask

  task automatic release_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      release_valid = 1'b1;
      release_rob_idx = ridx;
      release_producer_id = producer_id_for_rob(ridx);
      #1;
      tb_check1("precise release emits owner token", owner_release_mask[ridx], 1'b1);
      `TB_TICK(clk);
      release_valid = 1'b0;
      #1;
      tb_check32("owner release pulse is exactly once", owner_release_mask, 32'd0);
    end
  endtask

  task automatic request_sent_global_flush_survival;
    input [ROB_INDEX_W-1:0] ridx;
    input b_error_case;
    reg [`XLEN-1:0] va;
    reg [`XLEN-1:0] pa;
    begin
      va = owner_tval_for_rob(ridx);
      pa = 64'h0000_0000_8000_0000 | va;
      alloc_one(ridx);
      fill_one(ridx, va, pa, 64'hb000_0000_0000_0000 | ridx);
      rob_head_valid = 1'b1;
      rob_head_idx = ridx;
      rob_head_producer_id = producer_id_for_rob(ridx);
      rob_head_owner_open = 1'b1;
      rob_head_launch_open = 1'b1;
      #1;
      tb_check1("request_sent flush setup request", req_valid, 1'b1);
      req_fire = 1'b1;
      `TB_TICK(clk);
      req_fire = 1'b0;
      flush_valid = 1'b1;
      flush_all = 1'b1;
      flush_rob_head = ridx;
      #1;
      tb_check32("request_sent global flush emits no raw release",
                 owner_release_mask, 32'd0);
      `TB_TICK(clk);
      flush_valid = 1'b0;
      flush_all = 1'b0;
      #1;
      tb_check32("request_sent global flush keeps count", {28'b0, count}, 32'd1);
      tb_check1("request_sent global flush keeps physical owner",
                snoop_request_sent[snoop_head], 1'b1);
      tb_check32("request_sent global flush keeps token",
                 {27'b0, req_owner_token}, ridx);
      tb_check32("request_sent global flush keeps epoch",
                 {30'b0, req_mmu_epoch}, ridx[1:0]);
      check64("request_sent global flush keeps tval", req_fault_tval, va);
      check64("request_sent global flush keeps PA", req_paddr, pa);
      send_terminal(ridx);
      release_one(ridx);
      #1;
      tb_check32("request_sent post-B release empty", {28'b0, count}, 32'd0);
      if (b_error_case)
        $display("[S2-G1-SQ-GLOBAL-SURVIVE-BERR] exact error-B terminal retained owner until release PASS");
      else
        $display("[S2-G1-SQ-GLOBAL-SURVIVE-BOK] exact success-B terminal retained owner until release PASS");
    end
  endtask

  // V11G closes only the resident StoreQueue ProducerId/owner-token holder
  // lifecycle.  The expected state below is owned by the testbench stimulus;
  // DUT raw Q state is observation-only and never feeds the model.
  reg v11g_expected_valid [0:3];
  reg [PRODUCER_ID_W-1:0] v11g_expected_pid [0:3];
  reg v11g_expected_owner_valid [0:3];
  reg [1:0] v11g_expected_owner_kind [0:3];
  reg [4:0] v11g_expected_owner_token [0:3];
  reg [1:0] v11g_expected_owner_epoch [0:3];
  reg v11g_expected_filled [0:3];
  reg v11g_expected_request_sent [0:3];
  reg v11g_expected_terminal [0:3];
  reg [ENTRY_COUNT_W-1:0] v11g_expected_head;
  reg [ENTRY_COUNT_W-1:0] v11g_expected_tail;
  integer v11g_expected_count;
  integer v11g_i;

  function automatic [PRODUCER_ID_W-1:0] v11g_pid;
    input [ROB_INDEX_W-1:0] ridx;
    input [31:0] generation_seed;
    begin
      v11g_pid = {
          generation_seed[`OOO_PRODUCER_GEN_W-1:0], ridx};
    end
  endfunction

  function automatic [PRODUCER_ID_W-1:0] v11g_other_generation;
    input [PRODUCER_ID_W-1:0] pid;
    begin
      v11g_other_generation = pid;
      v11g_other_generation[ROB_INDEX_W] =
          !v11g_other_generation[ROB_INDEX_W];
    end
  endfunction

  function automatic [`XLEN-1:0] v11g_tval;
    input [PRODUCER_ID_W-1:0] pid;
    begin
      v11g_tval = 64'h0000_0000_6000_0000 |
          {{(`XLEN-PRODUCER_ID_W-4){1'b0}}, pid, 4'b0};
    end
  endfunction

  task automatic v11g_fail;
    input [1023:0] label;
    begin
      tb_errors = tb_errors + 1;
      $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s", label);
    end
  endtask

  task automatic v11g_model_clear;
    begin
      v11g_expected_head = {ENTRY_COUNT_W{1'b0}};
      v11g_expected_tail = {ENTRY_COUNT_W{1'b0}};
      v11g_expected_count = 0;
      for (v11g_i = 0; v11g_i < 4; v11g_i = v11g_i + 1) begin
        v11g_expected_valid[v11g_i] = 1'b0;
        v11g_expected_pid[v11g_i] = {PRODUCER_ID_W{1'b0}};
        v11g_expected_owner_valid[v11g_i] = 1'b0;
        v11g_expected_owner_kind[v11g_i] = 2'b00;
        v11g_expected_owner_token[v11g_i] = 5'd0;
        v11g_expected_owner_epoch[v11g_i] = 2'b00;
        v11g_expected_filled[v11g_i] = 1'b0;
        v11g_expected_request_sent[v11g_i] = 1'b0;
        v11g_expected_terminal[v11g_i] = 1'b0;
      end
    end
  endtask

  task automatic v11g_check_raw_state;
    input [1023:0] label;
    begin
      if (dut.head_q !== v11g_expected_head) begin
        $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s head got=%0d expected=%0d",
                 label, dut.head_q, v11g_expected_head);
        tb_errors = tb_errors + 1;
      end
      if (dut.tail_q !== v11g_expected_tail) begin
        $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s tail got=%0d expected=%0d",
                 label, dut.tail_q, v11g_expected_tail);
        tb_errors = tb_errors + 1;
      end
      if (dut.count_q !== v11g_expected_count[ENTRY_COUNT_W:0]) begin
        $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s count got=%0d expected=%0d",
                 label, dut.count_q, v11g_expected_count);
        tb_errors = tb_errors + 1;
      end
      for (v11g_i = 0; v11g_i < 4; v11g_i = v11g_i + 1) begin
        if (dut.valid_q[v11g_i] !== v11g_expected_valid[v11g_i]) begin
          $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s valid[%0d] got=%b expected=%b",
                   label, v11g_i, dut.valid_q[v11g_i],
                   v11g_expected_valid[v11g_i]);
          tb_errors = tb_errors + 1;
        end
        if (dut.owner_valid_q[v11g_i] !==
            v11g_expected_owner_valid[v11g_i]) begin
          $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s owner_valid[%0d] got=%b expected=%b",
                   label, v11g_i, dut.owner_valid_q[v11g_i],
                   v11g_expected_owner_valid[v11g_i]);
          tb_errors = tb_errors + 1;
        end
        if (dut.filled_q[v11g_i] !== v11g_expected_filled[v11g_i]) begin
          $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s filled[%0d] got=%b expected=%b",
                   label, v11g_i, dut.filled_q[v11g_i],
                   v11g_expected_filled[v11g_i]);
          tb_errors = tb_errors + 1;
        end
        if (dut.request_sent_q[v11g_i] !==
            v11g_expected_request_sent[v11g_i]) begin
          $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s request_sent[%0d] got=%b expected=%b",
                   label, v11g_i, dut.request_sent_q[v11g_i],
                   v11g_expected_request_sent[v11g_i]);
          tb_errors = tb_errors + 1;
        end
        if (dut.terminal_q[v11g_i] !==
            v11g_expected_terminal[v11g_i]) begin
          $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s terminal[%0d] got=%b expected=%b",
                   label, v11g_i, dut.terminal_q[v11g_i],
                   v11g_expected_terminal[v11g_i]);
          tb_errors = tb_errors + 1;
        end
        if (v11g_expected_valid[v11g_i]) begin
          if (^dut.producer_id_q[v11g_i] === 1'bx) begin
            $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s raw PID unknown entry=%0d",
                     label, v11g_i);
            tb_errors = tb_errors + 1;
          end else if (dut.producer_id_q[v11g_i] !==
                       v11g_expected_pid[v11g_i]) begin
            $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s PID[%0d] got=%h expected=%h",
                     label, v11g_i, dut.producer_id_q[v11g_i],
                     v11g_expected_pid[v11g_i]);
            tb_errors = tb_errors + 1;
          end
          if (dut.rob_idx_q[v11g_i] !==
              v11g_expected_pid[v11g_i][ROB_INDEX_W-1:0]) begin
            $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s ROB[%0d] got=%h expected=%h",
                     label, v11g_i, dut.rob_idx_q[v11g_i],
                     v11g_expected_pid[v11g_i][ROB_INDEX_W-1:0]);
            tb_errors = tb_errors + 1;
          end
        end
        if (v11g_expected_owner_valid[v11g_i]) begin
          if ((^dut.owner_kind_q[v11g_i] === 1'bx) ||
              (^dut.owner_token_q[v11g_i] === 1'bx) ||
              (^dut.mmu_epoch_q[v11g_i] === 1'bx)) begin
            $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s raw owner tuple unknown entry=%0d",
                     label, v11g_i);
            tb_errors = tb_errors + 1;
          end else if ((dut.owner_kind_q[v11g_i] !==
                        v11g_expected_owner_kind[v11g_i]) ||
                       (dut.owner_token_q[v11g_i] !==
                        v11g_expected_owner_token[v11g_i]) ||
                       (dut.mmu_epoch_q[v11g_i] !==
                        v11g_expected_owner_epoch[v11g_i])) begin
            $display("[V11G-SQ-HOLDER-ORACLE][FAIL] %0s owner tuple[%0d] got={%h,%h,%h} expected={%h,%h,%h}",
                     label, v11g_i, dut.owner_kind_q[v11g_i],
                     dut.owner_token_q[v11g_i], dut.mmu_epoch_q[v11g_i],
                     v11g_expected_owner_kind[v11g_i],
                     v11g_expected_owner_token[v11g_i],
                     v11g_expected_owner_epoch[v11g_i]);
            tb_errors = tb_errors + 1;
          end
        end
      end
    end
  endtask

  task automatic v11g_model_allocate;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input dual;
    reg [ENTRY_COUNT_W-1:0] idx0;
    reg [ENTRY_COUNT_W-1:0] idx1;
    begin
      idx0 = v11g_expected_tail;
      idx1 = v11g_expected_tail + 1'b1;
      v11g_expected_valid[idx0] = 1'b1;
      v11g_expected_pid[idx0] = pid0;
      v11g_expected_owner_valid[idx0] = 1'b0;
      v11g_expected_filled[idx0] = 1'b0;
      v11g_expected_request_sent[idx0] = 1'b0;
      v11g_expected_terminal[idx0] = 1'b0;
      if (dual) begin
        v11g_expected_valid[idx1] = 1'b1;
        v11g_expected_pid[idx1] = pid1;
        v11g_expected_owner_valid[idx1] = 1'b0;
        v11g_expected_filled[idx1] = 1'b0;
        v11g_expected_request_sent[idx1] = 1'b0;
        v11g_expected_terminal[idx1] = 1'b0;
      end
      v11g_expected_tail = v11g_expected_tail + 1'b1 + dual;
      v11g_expected_count = v11g_expected_count + 1 + dual;
    end
  endtask

  task automatic v11g_model_bind;
    input [PRODUCER_ID_W-1:0] pid;
    input [4:0] token;
    input [1:0] epoch;
    integer bind_i;
    reg found;
    begin
      found = 1'b0;
      for (bind_i = 0; bind_i < 4; bind_i = bind_i + 1) begin
        if (v11g_expected_valid[bind_i] &&
            !v11g_expected_owner_valid[bind_i] &&
            (v11g_expected_pid[bind_i] == pid)) begin
          v11g_expected_owner_valid[bind_i] = 1'b1;
          v11g_expected_owner_kind[bind_i] = 2'b01;
          v11g_expected_owner_token[bind_i] = token;
          v11g_expected_owner_epoch[bind_i] = epoch;
          found = 1'b1;
        end
      end
      if (!found)
        v11g_fail("expected model bind found no exact PID");
    end
  endtask

  task automatic v11g_model_fill;
    input [ROB_INDEX_W-1:0] ridx;
    input [4:0] token;
    input [1:0] epoch;
    integer fill_i;
    reg found;
    begin
      found = 1'b0;
      for (fill_i = 0; fill_i < 4; fill_i = fill_i + 1) begin
        if (v11g_expected_valid[fill_i] &&
            v11g_expected_owner_valid[fill_i] &&
            !v11g_expected_filled[fill_i] &&
            (v11g_expected_pid[fill_i][ROB_INDEX_W-1:0] == ridx) &&
            (v11g_expected_owner_kind[fill_i] == 2'b01) &&
            (v11g_expected_owner_token[fill_i] == token) &&
            (v11g_expected_owner_epoch[fill_i] == epoch)) begin
          v11g_expected_filled[fill_i] = 1'b1;
          found = 1'b1;
        end
      end
      if (!found)
        v11g_fail("expected model fill found no exact owner");
    end
  endtask

  task automatic v11g_model_request_head;
    begin
      if (!v11g_expected_valid[v11g_expected_head])
        v11g_fail("expected model request head invalid");
      else
        v11g_expected_request_sent[v11g_expected_head] = 1'b1;
    end
  endtask

  task automatic v11g_model_terminal;
    input [ROB_INDEX_W-1:0] ridx;
    input [4:0] token;
    input [1:0] epoch;
    integer terminal_i;
    reg found;
    begin
      found = 1'b0;
      for (terminal_i = 0; terminal_i < 4;
           terminal_i = terminal_i + 1) begin
        if (v11g_expected_valid[terminal_i] &&
            v11g_expected_owner_valid[terminal_i] &&
            !v11g_expected_terminal[terminal_i] &&
            (v11g_expected_pid[terminal_i][ROB_INDEX_W-1:0] == ridx) &&
            (v11g_expected_owner_kind[terminal_i] == 2'b01) &&
            (v11g_expected_owner_token[terminal_i] == token) &&
            (v11g_expected_owner_epoch[terminal_i] == epoch)) begin
          v11g_expected_terminal[terminal_i] = 1'b1;
          found = 1'b1;
        end
      end
      if (!found)
        v11g_fail("expected model terminal found no exact owner");
    end
  endtask

  task automatic v11g_model_release_head;
    begin
      if (!v11g_expected_valid[v11g_expected_head])
        v11g_fail("expected model released invalid head");
      v11g_expected_valid[v11g_expected_head] = 1'b0;
      v11g_expected_owner_valid[v11g_expected_head] = 1'b0;
      v11g_expected_filled[v11g_expected_head] = 1'b0;
      v11g_expected_request_sent[v11g_expected_head] = 1'b0;
      v11g_expected_terminal[v11g_expected_head] = 1'b0;
      v11g_expected_head = v11g_expected_head + 1'b1;
      v11g_expected_count = v11g_expected_count - 1;
    end
  endtask

  task automatic v11g_model_flush;
    input flush_all_model;
    input [ROB_INDEX_W-1:0] flush_head_model;
    input [ROB_INDEX_W-1:0] boundary_model;
    input release_head_model;
    reg keep [0:3];
    reg [ROB_INDEX_W-1:0] boundary_dist;
    reg [ROB_INDEX_W-1:0] entry_dist;
    reg [ENTRY_COUNT_W-1:0] old_head;
    integer keep_count;
    integer flush_i;
    begin
      old_head = v11g_expected_head;
      keep_count = 0;
      boundary_dist = boundary_model - flush_head_model;
      for (flush_i = 0; flush_i < 4; flush_i = flush_i + 1) begin
        entry_dist =
            v11g_expected_pid[flush_i][ROB_INDEX_W-1:0] -
            flush_head_model;
        keep[flush_i] = v11g_expected_valid[flush_i] &&
            (v11g_expected_request_sent[flush_i] ||
             (!flush_all_model && (entry_dist <= boundary_dist)));
        if (keep[flush_i])
          keep_count = keep_count + 1;
      end
      if (release_head_model && keep[old_head])
        keep_count = keep_count - 1;
      for (flush_i = 0; flush_i < 4; flush_i = flush_i + 1) begin
        if (v11g_expected_valid[flush_i] &&
            (!keep[flush_i] ||
             (release_head_model &&
              (flush_i[ENTRY_COUNT_W-1:0] == old_head)))) begin
          v11g_expected_valid[flush_i] = 1'b0;
          v11g_expected_owner_valid[flush_i] = 1'b0;
          v11g_expected_filled[flush_i] = 1'b0;
          v11g_expected_request_sent[flush_i] = 1'b0;
          v11g_expected_terminal[flush_i] = 1'b0;
        end
      end
      v11g_expected_head = old_head + release_head_model;
      v11g_expected_count = keep_count;
      v11g_expected_tail = v11g_expected_head +
          keep_count[ENTRY_COUNT_W-1:0];
    end
  endtask

  task automatic v11g_drive_allocate;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input dual;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob_idx = pid0[ROB_INDEX_W-1:0];
      alloc0_producer_id = pid0;
      alloc1_valid = dual;
      alloc1_rob_idx = pid1[ROB_INDEX_W-1:0];
      alloc1_producer_id = pid1;
      #1;
      if (alloc0_ready !== 1'b1)
        v11g_fail("accepted allocation lane0 not ready");
      if (dual && (alloc1_ready !== 1'b1))
        v11g_fail("accepted allocation lane1 not ready");
      `TB_TICK(clk);
      alloc0_valid = 1'b0;
      alloc1_valid = 1'b0;
      v11g_model_allocate(pid0, pid1, dual);
      #1;
      v11g_check_raw_state("post allocation");
    end
  endtask

  task automatic v11g_drive_bind_pair;
    input [PRODUCER_ID_W-1:0] pid0;
    input [4:0] token0;
    input [1:0] epoch0;
    input [PRODUCER_ID_W-1:0] pid1;
    input [4:0] token1;
    input [1:0] epoch1;
    input dual;
    begin
      owner_bind_valid = 1'b1;
      owner_bind_rob_idx = pid0[ROB_INDEX_W-1:0];
      owner_bind_producer_id = pid0;
      owner_bind_kind = 2'b01;
      owner_bind_token = token0;
      owner_bind_mmu_epoch = epoch0;
      owner_bind_fault_tval = v11g_tval(pid0);
      owner_bind1_valid = dual;
      owner_bind1_rob_idx = pid1[ROB_INDEX_W-1:0];
      owner_bind1_producer_id = pid1;
      owner_bind1_kind = 2'b01;
      owner_bind1_token = token1;
      owner_bind1_mmu_epoch = epoch1;
      owner_bind1_fault_tval = v11g_tval(pid1);
      `TB_TICK(clk);
      owner_bind_valid = 1'b0;
      owner_bind1_valid = 1'b0;
      v11g_model_bind(pid0, token0, epoch0);
      if (dual)
        v11g_model_bind(pid1, token1, epoch1);
      #1;
      v11g_check_raw_state("post owner bind");
    end
  endtask

  task automatic v11g_drive_fill_pair;
    input [PRODUCER_ID_W-1:0] pid0;
    input [4:0] token0;
    input [1:0] epoch0;
    input [PRODUCER_ID_W-1:0] pid1;
    input [4:0] token1;
    input [1:0] epoch1;
    begin
      // Deliberately route the younger owner through fill0 and the older
      // owner through fill1; holder identity must not depend on fill lane.
      fill0_valid = 1'b1;
      fill0_rob_idx = pid1[ROB_INDEX_W-1:0];
      fill0_owner_kind = 2'b01;
      fill0_owner_token = token1;
      fill0_mmu_epoch = epoch1;
      fill0_fault_tval = v11g_tval(pid1);
      fill0_vaddr = 64'h1000_0000 | pid1;
      fill0_paddr = 64'h8000_0000 | pid1;
      fill0_attr_valid = 1'b1;
      fill0_class = `OOO_MEM_CLASS_CACHED;
      fill0_cacheable = 1'b1;
      fill0_data = 64'h1111_0000 | pid1;
      fill0_strb = 8'hff;
      fill1_valid = 1'b1;
      fill1_rob_idx = pid0[ROB_INDEX_W-1:0];
      fill1_owner_kind = 2'b01;
      fill1_owner_token = token0;
      fill1_mmu_epoch = epoch0;
      fill1_fault_tval = v11g_tval(pid0);
      fill1_vaddr = 64'h2000_0000 | pid0;
      fill1_paddr = 64'h9000_0000 | pid0;
      fill1_attr_valid = 1'b1;
      fill1_class = `OOO_MEM_CLASS_NC;
      fill1_cacheable = 1'b0;
      fill1_data = 64'h2222_0000 | pid0;
      fill1_strb = 8'hff;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
      fill1_valid = 1'b0;
      fill0_attr_valid = 1'b0;
      fill1_attr_valid = 1'b0;
      fill0_class = `OOO_MEM_CLASS_RSVD;
      fill1_class = `OOO_MEM_CLASS_RSVD;
      fill0_cacheable = 1'b0;
      fill1_cacheable = 1'b0;
      v11g_model_fill(pid1[ROB_INDEX_W-1:0], token1, epoch1);
      v11g_model_fill(pid0[ROB_INDEX_W-1:0], token0, epoch0);
      #1;
      v11g_check_raw_state("post out-of-order fill");
    end
  endtask

  task automatic v11g_drive_request;
    input [PRODUCER_ID_W-1:0] pid;
    input [4:0] token;
    begin
      rob_head_valid = 1'b1;
      rob_head_idx = pid[ROB_INDEX_W-1:0];
      rob_head_owner_open = 1'b1;
      rob_head_launch_open = 1'b1;
      rob_head_producer_id = v11g_other_generation(pid);
      #1;
      if (req_valid !== 1'b0)
        v11g_fail("wrong-generation ROB head authorized request");
      rob_head_producer_id = pid;
      #1;
      if (req_valid !== 1'b1)
        v11g_fail("exact full-P ROB head did not authorize request");
      if ((req_producer_id !== pid) || (req_owner_token !== token))
        v11g_fail("request carrier changed full-P or owner token");
      req_fire = 1'b1;
      `TB_TICK(clk);
      req_fire = 1'b0;
      v11g_model_request_head();
      #1;
      v11g_check_raw_state("post physical request");
    end
  endtask

  task automatic run_v11g_store_queue_holder_lifecycle;
    reg [PRODUCER_ID_W-1:0] pid0;
    reg [PRODUCER_ID_W-1:0] pid1;
    reg [PRODUCER_ID_W-1:0] pid2;
    reg [PRODUCER_ID_W-1:0] pid3;
    reg [PRODUCER_ID_W-1:0] pid4;
    reg [PRODUCER_ID_W-1:0] pid5;
    reg [PRODUCER_ID_W-1:0] pid6;
    reg [PRODUCER_ID_W-1:0] pid7;
    reg [PRODUCER_ID_W-1:0] pid8;
    reg [PRODUCER_ID_W-1:0] pid9;
    reg [PRODUCER_ID_W-1:0] pid10;
    begin
      pid0 = v11g_pid(4'd3, 32'hb);
      pid1 = v11g_pid(4'd4, 32'h5);
      pid2 = v11g_pid(4'd5, 32'hc);
      pid3 = v11g_pid(4'd6, 32'h3);
      pid4 = v11g_pid(4'd3, 32'ha);
      pid5 = v11g_pid(4'd6, 32'hd);
      pid6 = v11g_pid(4'd7, 32'h2);
      pid7 = v11g_pid(4'd8, 32'h7);
      pid8 = v11g_pid(4'd9, 32'h9);
      pid9 = v11g_pid(4'd10, 32'h6);
      pid10 = v11g_pid(4'd11, 32'he);

      v11g_model_clear();
      v11g_check_raw_state("reset");

      v11g_drive_allocate(pid0, pid1, 1'b1);
      v11g_drive_bind_pair(
          pid0, 5'd19, 2'b01, pid1, 5'd6, 2'b11, 1'b1);
      v11g_drive_allocate(pid2, pid3, 1'b1);
      v11g_drive_bind_pair(
          pid2, 5'd23, 2'b10, pid3, 5'd2, 2'b00, 1'b1);
      alloc0_valid = 1'b1;
      alloc0_rob_idx = pid4[ROB_INDEX_W-1:0];
      alloc0_producer_id = pid4;
      #1;
      if (alloc0_ready !== 1'b0)
        v11g_fail("full queue accepted allocation");
      `TB_TICK(clk);
      alloc0_valid = 1'b0;
      #1;
      v11g_check_raw_state("full queue hold");
      v11g_drive_fill_pair(
          pid0, 5'd19, 2'b01, pid1, 5'd6, 2'b11);
      $display("[V11G-SQ-BIRTH-BIND] GEN_W=%0d dual/full/asymmetric-tuple PASS",
               `OOO_PRODUCER_GEN_W);

      v11g_drive_request(pid0, 5'd19);
      terminal_valid = 1'b1;
      terminal_rob_idx = pid0[ROB_INDEX_W-1:0];
      terminal_owner_kind = 2'b01;
      terminal_owner_token = 5'd19;
      terminal_mmu_epoch = 2'b01;
      terminal_fault_tval = v11g_tval(pid0);
      `TB_TICK(clk);
      terminal_valid = 1'b0;
      v11g_model_terminal(pid0[ROB_INDEX_W-1:0], 5'd19, 2'b01);
      #1;
      v11g_check_raw_state("terminal retains holders");
      release_rob_idx = pid0[ROB_INDEX_W-1:0];
      release_producer_id = v11g_other_generation(pid0);
      #1;
      if (release_ready !== 1'b0)
        v11g_fail("wrong-generation release was authorized");
      release_producer_id = pid0;
      release_valid = 1'b1;
      alloc0_valid = 1'b1;
      alloc0_rob_idx = pid4[ROB_INDEX_W-1:0];
      alloc0_producer_id = pid4;
      #1;
      if (release_ready !== 1'b1)
        v11g_fail("exact terminal head release not ready");
      if (alloc0_ready !== 1'b0)
        v11g_fail("full+release borrowed edge-new capacity");
      if (owner_release_mask !== (32'b1 << 19))
        v11g_fail("release token mask did not use asymmetric owner token");
      `TB_TICK(clk);
      release_valid = 1'b0;
      alloc0_valid = 1'b0;
      v11g_model_release_head();
      #1;
      if (owner_release_mask !== 32'd0)
        v11g_fail("release token mask was not exactly one cycle");
      v11g_check_raw_state("post exact release");
      v11g_drive_allocate(pid4, {PRODUCER_ID_W{1'b0}}, 1'b0);
      v11g_drive_bind_pair(
          pid4, 5'd11, 2'b11,
          {PRODUCER_ID_W{1'b0}}, 5'd0, 2'b00, 1'b0);
      $display("[V11G-SQ-REQUEST-TERMINAL] GEN_W=%0d wrong-gen/resident/release/reuse PASS",
               `OOO_PRODUCER_GEN_W);

      // Request the second physical owner, then selectively retain the exact
      // boundary entry while killing the younger suffix (including reused slot0).
      v11g_drive_request(pid1, 5'd6);
      flush_valid = 1'b1;
      flush_all = 1'b0;
      flush_rob_head = pid1[ROB_INDEX_W-1:0];
      flush_boundary_rob = pid2[ROB_INDEX_W-1:0];
      #1;
      if (owner_release_mask !==
          ((32'b1 << 2) | (32'b1 << 11)))
        v11g_fail("selective flush token death mask mismatch");
      `TB_TICK(clk);
      flush_valid = 1'b0;
      v11g_model_flush(
          1'b0, pid1[ROB_INDEX_W-1:0],
          pid2[ROB_INDEX_W-1:0], 1'b0);
      #1;
      v11g_check_raw_state("selective inclusive-prefix flush");

      terminal_valid = 1'b1;
      terminal_rob_idx = pid1[ROB_INDEX_W-1:0];
      terminal_owner_kind = 2'b01;
      terminal_owner_token = 5'd6;
      terminal_mmu_epoch = 2'b11;
      terminal_fault_tval = v11g_tval(pid1);
      `TB_TICK(clk);
      terminal_valid = 1'b0;
      v11g_model_terminal(pid1[ROB_INDEX_W-1:0], 5'd6, 2'b11);
      #1;
      v11g_check_raw_state("second owner terminal");

      // At count=2, one terminal release and two edge-old allocations are
      // independent: old(2)-release(1)+alloc(2)=3.
      release_valid = 1'b1;
      release_rob_idx = pid1[ROB_INDEX_W-1:0];
      release_producer_id = pid1;
      alloc0_valid = 1'b1;
      alloc0_rob_idx = pid5[ROB_INDEX_W-1:0];
      alloc0_producer_id = pid5;
      alloc1_valid = 1'b1;
      alloc1_rob_idx = pid6[ROB_INDEX_W-1:0];
      alloc1_producer_id = pid6;
      #1;
      if (!release_ready || !alloc0_ready || !alloc1_ready)
        v11g_fail("release+dual-allocation readiness mismatch");
      if (owner_release_mask !== (32'b1 << 6))
        v11g_fail("release+dual-allocation token mask mismatch");
      `TB_TICK(clk);
      release_valid = 1'b0;
      alloc0_valid = 1'b0;
      alloc1_valid = 1'b0;
      v11g_model_release_head();
      v11g_model_allocate(pid5, pid6, 1'b1);
      #1;
      v11g_check_raw_state("release plus dual allocation");
      v11g_drive_bind_pair(
          pid5, 5'd28, 2'b01, pid6, 5'd14, 2'b10, 1'b1);

      // The remaining old boundary store becomes the accepted physical owner.
      fill0_valid = 1'b1;
      fill0_rob_idx = pid2[ROB_INDEX_W-1:0];
      fill0_owner_kind = 2'b01;
      fill0_owner_token = 5'd23;
      fill0_mmu_epoch = 2'b10;
      fill0_fault_tval = v11g_tval(pid2);
      fill0_vaddr = 64'h3000_0000 | pid2;
      fill0_paddr = 64'ha000_0000 | pid2;
      fill0_attr_valid = 1'b1;
      fill0_class = `OOO_MEM_CLASS_CACHED;
      fill0_cacheable = 1'b1;
      fill0_data = 64'h3333_0000 | pid2;
      fill0_strb = 8'hff;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
      fill0_attr_valid = 1'b0;
      fill0_class = `OOO_MEM_CLASS_RSVD;
      fill0_cacheable = 1'b0;
      v11g_model_fill(pid2[ROB_INDEX_W-1:0], 5'd23, 2'b10);
      #1;
      v11g_check_raw_state("third owner fill");
      v11g_drive_request(pid2, 5'd23);

      flush_valid = 1'b1;
      flush_all = 1'b1;
      flush_rob_head = pid2[ROB_INDEX_W-1:0];
      #1;
      if (owner_release_mask !==
          ((32'b1 << 28) | (32'b1 << 14)))
        v11g_fail("global flush killed wrong owner tokens");
      `TB_TICK(clk);
      flush_valid = 1'b0;
      flush_all = 1'b0;
      v11g_model_flush(
          1'b1, pid2[ROB_INDEX_W-1:0],
          pid2[ROB_INDEX_W-1:0], 1'b0);
      #1;
      v11g_check_raw_state("global flush request_sent survives");

      terminal_valid = 1'b1;
      terminal_rob_idx = pid2[ROB_INDEX_W-1:0];
      terminal_owner_kind = 2'b01;
      terminal_owner_token = 5'd23;
      terminal_mmu_epoch = 2'b10;
      terminal_fault_tval = v11g_tval(pid2);
      release_valid = 1'b1;
      release_rob_idx = pid2[ROB_INDEX_W-1:0];
      release_producer_id = pid2;
      flush_valid = 1'b1;
      flush_all = 1'b1;
      flush_rob_head = pid2[ROB_INDEX_W-1:0];
      #1;
      if (!release_ready)
        v11g_fail("same-cycle terminal release bypass missing");
      if (owner_release_mask !== (32'b1 << 23))
        v11g_fail("terminal+release+flush token mask mismatch");
      `TB_TICK(clk);
      terminal_valid = 1'b0;
      release_valid = 1'b0;
      flush_valid = 1'b0;
      flush_all = 1'b0;
      v11g_model_terminal(pid2[ROB_INDEX_W-1:0], 5'd23, 2'b10);
      v11g_model_flush(
          1'b1, pid2[ROB_INDEX_W-1:0],
          pid2[ROB_INDEX_W-1:0], 1'b1);
      #1;
      v11g_check_raw_state("terminal release global flush");
      $display("[V11G-SQ-RECOVERY] GEN_W=%0d selective/global/request-sent PASS",
               `OOO_PRODUCER_GEN_W);

      // Bind, local terminal and ROB release share one edge.  Token 19 is
      // intentionally reused only after its previous holder died.
      v11g_drive_allocate(pid7, {PRODUCER_ID_W{1'b0}}, 1'b0);
      rob_head_valid = 1'b1;
      rob_head_idx = pid7[ROB_INDEX_W-1:0];
      rob_head_producer_id = pid7;
      owner_bind_valid = 1'b1;
      owner_bind_rob_idx = pid7[ROB_INDEX_W-1:0];
      owner_bind_producer_id = pid7;
      owner_bind_kind = 2'b01;
      owner_bind_token = 5'd19;
      owner_bind_mmu_epoch = 2'b00;
      owner_bind_fault_tval = v11g_tval(pid7);
      terminal1_valid = 1'b1;
      terminal1_rob_idx = pid7[ROB_INDEX_W-1:0];
      terminal1_owner_kind = 2'b01;
      terminal1_owner_token = 5'd19;
      terminal1_mmu_epoch = 2'b00;
      terminal1_fault_tval = v11g_tval(pid7);
      release_valid = 1'b1;
      release_rob_idx = pid7[ROB_INDEX_W-1:0];
      release_producer_id = pid7;
      #1;
      if (!release_ready)
        v11g_fail("bind+terminal release bypass missing");
      if (owner_release_mask !== (32'b1 << 19))
        v11g_fail("bind+release mask bypass missing");
      `TB_TICK(clk);
      owner_bind_valid = 1'b0;
      terminal1_valid = 1'b0;
      release_valid = 1'b0;
      v11g_model_bind(pid7, 5'd19, 2'b00);
      v11g_model_terminal(pid7[ROB_INDEX_W-1:0], 5'd19, 2'b00);
      v11g_model_release_head();
      #1;
      v11g_check_raw_state("bind terminal release bypass");

      v11g_drive_allocate(pid8, pid9, 1'b1);
      v11g_drive_bind_pair(
          pid8, 5'd25, 2'b01, pid9, 5'd4, 2'b10, 1'b1);
      terminal_valid = 1'b1;
      terminal_rob_idx = pid8[ROB_INDEX_W-1:0];
      terminal_owner_kind = 2'b01;
      terminal_owner_token = 5'd25;
      terminal_mmu_epoch = 2'b01;
      terminal_fault_tval = v11g_tval(pid8);
      terminal1_valid = 1'b1;
      terminal1_rob_idx = pid9[ROB_INDEX_W-1:0];
      terminal1_owner_kind = 2'b01;
      terminal1_owner_token = 5'd4;
      terminal1_mmu_epoch = 2'b10;
      terminal1_fault_tval = v11g_tval(pid9);
      `TB_TICK(clk);
      terminal_valid = 1'b0;
      terminal1_valid = 1'b0;
      v11g_model_terminal(pid8[ROB_INDEX_W-1:0], 5'd25, 2'b01);
      v11g_model_terminal(pid9[ROB_INDEX_W-1:0], 5'd4, 2'b10);
      #1;
      v11g_check_raw_state("dual terminal holders remain resident");

      release_valid = 1'b1;
      release_rob_idx = pid8[ROB_INDEX_W-1:0];
      release_producer_id = pid8;
      #1;
      if (owner_release_mask !== (32'b1 << 25))
        v11g_fail("dual-terminal first release token mismatch");
      `TB_TICK(clk);
      release_valid = 1'b0;
      v11g_model_release_head();
      release_valid = 1'b1;
      release_rob_idx = pid9[ROB_INDEX_W-1:0];
      release_producer_id = pid9;
      #1;
      if (owner_release_mask !== (32'b1 << 4))
        v11g_fail("dual-terminal second release token mismatch");
      `TB_TICK(clk);
      release_valid = 1'b0;
      v11g_model_release_head();
      #1;
      v11g_check_raw_state("dual terminal ordered release");

      v11g_drive_allocate(pid10, {PRODUCER_ID_W{1'b0}}, 1'b0);
      v11g_drive_bind_pair(
          pid10, 5'd30, 2'b11,
          {PRODUCER_ID_W{1'b0}}, 5'd0, 2'b00, 1'b0);
      rst = 1'b1;
      `TB_TICK(clk);
      rst = 1'b0;
      v11g_model_clear();
      #1;
      v11g_check_raw_state("dirty-state reset");
      $display("[V11G-SQ-SAME-EDGE] GEN_W=%0d release-alloc/terminal-release/bind-terminal/dual-terminal PASS",
               `OOO_PRODUCER_GEN_W);
      $display("[V11G-SQ-ALL] GEN_W=%0d stimulus-owned raw-Q model PASS",
               `OOO_PRODUCER_GEN_W);
    end
  endtask

  task automatic final_pa_query_matrix;
    begin
      // Start the final-PA matrix from a deterministic physical SQ ring
      // position so hierarchical four-state injections target entry 0.
      query_ports_idle();
      rst = 1'b1;
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
      tb_check32("F3 query fixture reset is empty", {28'b0, count}, 32'd0);
      tb_check32("F3 query fixture reset head is zero",
                 {30'b0, snoop_head}, 32'd0);
      rob_head_valid = 1'b1;
      rob_head_idx = 4'd0;
      rob_head_producer_id = producer_id_for_rob(4'd0);
      rob_head_launch_open = 1'b0;
      query_ports_idle();

      // No older store: memory admission is legal.
      drive_query0(4'd4, 64'h0000_0000_9000_0000, 8'hff);
      tb_check32("F3 empty SQ query is onehot allow",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      query_ports_idle();

      // Known-invalid typed metadata and an empty byte mask are never an
      // optimistic memory admission, even when the SQ is empty.
      query0_valid = 1'b1;
      query0_producer_id = producer_id_for_rob(4'd4);
      query0_paddr = 64'h0000_0000_9000_0100;
      query0_attr_valid = 1'b0;
      query0_class = `OOO_MEM_CLASS_CACHED;
      query0_strb = 8'hff;
      #1;
      tb_check32("F3 invalid query attr replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      query0_attr_valid = 1'b1;
      query0_class = `OOO_MEM_CLASS_RSVD;
      #1;
      tb_check32("F3 reserved query class replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      query0_class = `OOO_MEM_CLASS_CACHED;
      query0_strb = 8'h00;
      #1;
      tb_check32("F3 empty query byte mask replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      query0_attr_valid = 1'bx;
      query0_strb = 8'hff;
      #1;
      tb_check32("F3 unknown typed-valid replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      query_ports_idle();

      // A shifted load view must compare byte addresses, not word tags.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_0000,
                     64'h8877_6655_4433_2211, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9000_0002, 8'h0f);
      tb_check32("F3 shifted full cover is onehot forward",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      check64("F3 shifted forward byte placement", query0_forward_data,
              64'h0000_0000_6655_4433);
      clear_speculative_sq();

      // Exercise the opposite alignment direction: the store begins after
      // the load base, so its low bytes land in higher load byte lanes.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_0102,
                     64'h0000_0000_0000_bbaa, 8'h03, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9000_0100, 8'h0c);
      tb_check32("F3 forward-start offset is onehot forward",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      check64("F3 forward-start byte placement", query0_forward_data,
              64'h0000_0000_bbaa_0000);
      clear_speculative_sq();

      // The independently implemented bank1 cone must apply the same
      // store-after-load alignment, not merely inherit bank0 coverage.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_0182,
                     64'h0000_0000_0000_ddcc, 8'h03, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd4);
      query1_paddr = 64'h0000_0000_9000_0180;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'h0c;
      #1;
      tb_check32("F3 bank1 forward-start offset is onehot forward",
                 {29'b0, query1_replay, query1_forward, query1_allow}, 32'd2);
      check64("F3 bank1 forward-start byte placement", query1_forward_data,
              64'h0000_0000_ddcc_0000);
      clear_speculative_sq();

      // Bank1 also owns an independent store-before-query right-shift cone.
      // A full-cover placement oracle prevents a symmetric-direction typo
      // from surviving behind the bank0 checks.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_01c0,
                     64'h8877_6655_4433_2211, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd4);
      query1_paddr = 64'h0000_0000_9000_01c2;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'h0f;
      #1;
      tb_check32("F3 bank1 backward offset is onehot forward",
                 {29'b0, query1_replay, query1_forward, query1_allow}, 32'd2);
      check64("F3 bank1 backward byte placement", query1_forward_data,
              64'h0000_0000_6655_4433);
      clear_speculative_sq();

      // Exactly one byte-window apart is non-overlapping; the offset network
      // must not turn an adjacent store into a false partial-overlap replay.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_0208,
                     64'h8877_6655_4433_2211, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9000_0200, 8'hff);
      tb_check32("F3 adjacent byte window is onehot allow",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      clear_speculative_sq();

      // Internal SQ state participates in a conservative ordering decision.
      // Any four-state uncertainty that could denote an older, non-terminal
      // overlapping store must select replay instead of optimistic allow or
      // forwarding.  No clock edge occurs while a field is deposited with X;
      // each hierarchical testbench assignment is restored immediately.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9000_0300,
                     64'h8877_6655_4433_2211, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9000_0300, 8'hff);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd5);
      query1_paddr = 64'h0000_0000_9000_0300;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'hff;
      #1;
      tb_check32("F3 both queries forward before X injection",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h12);

      dut.valid_q[0] = 1'bx;
      #1;
      tb_check32("F3 unknown entry valid replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.valid_q[0] = 1'b1;
      #1;

      dut.terminal_q[0] = 1'bx;
      #1;
      tb_check32("F3 unknown entry terminal state replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.terminal_q[0] = 1'b0;
      #1;

      dut.rob_idx_q[0] = {ROB_INDEX_W{1'bx}};
      #1;
      tb_check32("F3 unknown entry age basis replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.rob_idx_q[0] = 4'd1;
      #1;

      dut.filled_q[0] = 1'bx;
      #1;
      tb_check32("F3 unknown entry fill state replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.filled_q[0] = 1'b1;
      #1;

      dut.paddr_q[0] = {`XLEN{1'bx}};
      #1;
      tb_check32("F3 unknown entry physical address replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.paddr_q[0] = 64'h0000_0000_9000_0300;
      #1;

      dut.strb_q[0] = {`STRB_W{1'bx}};
      #1;
      tb_check32("F3 unknown entry byte mask replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.strb_q[0] = 8'hff;
      #1;

      dut.data_q[0] = {`XLEN{1'bx}};
      #1;
      tb_check32("F3 unknown overlapping store data replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.data_q[0] = 64'h8877_6655_4433_2211;
      #1;

      dut.head_q = {ENTRY_COUNT_W{1'bx}};
      #1;
      tb_check32("F3 unknown physical SQ head replays both queries",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h24);
      dut.head_q = {ENTRY_COUNT_W{1'b0}};
      #1;

      // Fail-closed must not become over-conservative: once an entry is
      // provably terminal or younger, its unrelated payload may be unknown.
      dut.terminal_q[0] = 1'b1;
      dut.rob_idx_q[0] = {ROB_INDEX_W{1'bx}};
      dut.paddr_q[0] = {`XLEN{1'bx}};
      dut.data_q[0] = {`XLEN{1'bx}};
      #1;
      tb_check32("F3 terminal entry ignores unknown payload",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h09);
      dut.terminal_q[0] = 1'b0;
      dut.rob_idx_q[0] = 4'd6;
      #1;
      tb_check32("F3 known younger entry ignores unknown payload",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h09);
      dut.valid_q[0] = 1'b0;
      dut.terminal_q[0] = 1'bx;
      dut.rob_idx_q[0] = {ROB_INDEX_W{1'bx}};
      dut.filled_q[0] = 1'bx;
      dut.attr_valid_q[0] = 1'bx;
      dut.class_q[0] = 2'bxx;
      dut.strb_q[0] = {`STRB_W{1'bx}};
      #1;
      tb_check32("F3 known invalid entry ignores unknown payload",
                 {26'b0, query1_replay, query1_forward, query1_allow,
                  query0_replay, query0_forward, query0_allow}, 32'h09);
      dut.valid_q[0] = 1'b1;
      dut.terminal_q[0] = 1'b0;
      dut.rob_idx_q[0] = 4'd1;
      dut.filled_q[0] = 1'b1;
      dut.paddr_q[0] = 64'h0000_0000_9000_0300;
      dut.attr_valid_q[0] = 1'b1;
      dut.class_q[0] = `OOO_MEM_CLASS_CACHED;
      dut.data_q[0] = 64'h8877_6655_4433_2211;
      dut.strb_q[0] = 8'hff;
      #1;
      clear_speculative_sq();

      // Full ProducerId age is circular around the edge-old ROB head.  A
      // store at slot15 is older than a load at slot1 when head=14; reversing
      // the two slots makes the store younger and therefore invisible.
      rob_head_idx = 4'd14;
      rob_head_producer_id = producer_id_for_rob(4'd14);
      alloc_one(4'd15);
      fill_one_typed(4'd15, 64'h0000_0000_9050_0000,
                     64'h1111_2222_3333_4444, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd1, 64'h0000_0000_9050_0000, 8'hff);
      tb_check32("F3 ROB-wrap older store forwards",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      clear_speculative_sq();
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9050_0080,
                     64'h5555_6666_7777_8888, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd15, 64'h0000_0000_9050_0080, 8'hff);
      tb_check32("F3 ROB-wrap younger store is excluded",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      clear_speculative_sq();
      rob_head_idx = 4'd0;
      rob_head_producer_id = producer_id_for_rob(4'd0);

      // Equal full ProducerId is not an older store.  This is a no-live-reuse
      // defensive boundary and must not become <= age look-through.
      alloc_one(4'd4);
      fill_one_typed(4'd4, 64'h0000_0000_9050_0100,
                     64'h9999_aaaa_bbbb_cccc, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9050_0100, 8'hff);
      tb_check32("F3 same PID store is excluded",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      clear_speculative_sq();

      // A recycled ProducerId generation at the same ROB slot is distinct,
      // but its circular distance is still equal.  Equality must not be
      // interpreted as an older store.
      alloc_one(4'd4);
      fill_one_typed(4'd4, 64'h0000_0000_9050_0180,
                     64'hdddd_eeee_ffff_0001, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      query0_valid = 1'b1;
      query0_producer_id = wrong_generation_for_rob(4'd4);
      query0_paddr = 64'h0000_0000_9050_0180;
      query0_attr_valid = 1'b1;
      query0_class = `OOO_MEM_CLASS_CACHED;
      query0_strb = 8'hff;
      #1;
      tb_check32("F3 same-age different-generation store is excluded",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      clear_speculative_sq();

      // Multiple older stores may assemble coverage; the younger older store
      // overwrites bytes selected earlier in the head-to-tail walk.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9100_0000,
                     64'h0000_0000_4433_2211, 8'h0f, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      alloc_one(4'd2);
      fill_one_typed(4'd2, 64'h0000_0000_9100_0002,
                     64'h0000_0000_0000_bbaa, 8'h03, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9100_0000, 8'h0f);
      tb_check32("F3 merged youngest cover is onehot forward",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      check64("F3 merged youngest bytes win", query0_forward_data,
              64'h0000_0000_bbaa_2211);
      clear_speculative_sq();

      // Partial overlap cannot read memory and merge later.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9200_0000,
                     64'h0000_0000_0000_2211, 8'h03, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9200_0000, 8'h0f);
      tb_check32("F3 partial overlap is onehot replay",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      clear_speculative_sq();

      // Unknown address/provenance and IO ordering are fail-closed.
      alloc_one(4'd1);
      drive_query0(4'd4, 64'h0000_0000_9300_0000, 8'hff);
      tb_check32("F3 unfilled older store replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      clear_speculative_sq();
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9300_3000,
                     64'h2222_2222_2222_2222, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_IO);
      drive_query0(4'd4, 64'h0000_0000_9300_4000, 8'hff);
      tb_check32("F3 older IO store replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      clear_speculative_sq();

      // Typed memory class is part of the forwarding identity.  NC/CACHED
      // overlap cannot borrow bytes across classes, and an IO query serializes
      // against an older ordinary store even without address overlap.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9300_5000,
                     64'h4444_4444_4444_4444, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_NC);
      drive_query0(4'd4, 64'h0000_0000_9300_5000, 8'hff);
      tb_check32("F3 NC/CACHED overlap replays",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      clear_speculative_sq();
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9300_6000,
                     64'h5555_5555_5555_5555, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      query0_valid = 1'b1;
      query0_producer_id = producer_id_for_rob(4'd4);
      query0_paddr = 64'h0000_0000_9300_7000;
      query0_attr_valid = 1'b1;
      query0_class = `OOO_MEM_CLASS_IO;
      query0_strb = 8'hff;
      #1;
      tb_check32("F3 IO query serializes against older cached store",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      clear_speculative_sq();

      // A terminal store is no longer an ordering/forwarding source.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9400_0000,
                     64'h3333_3333_3333_3333, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      send_terminal(4'd1);
      drive_query0(4'd4, 64'h0000_0000_9400_0000, 8'hff);
      tb_check32("F3 terminal older store is excluded",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd1);
      clear_speculative_sq();

      // The two banks are independent: one may forward while the other
      // conservatively replays on partial coverage in the same cycle.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9500_0000,
                     64'h8877_6655_4433_2211, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9500_0000, 8'hff);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd5);
      query1_paddr = 64'h0000_0000_9500_0006;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'h0f;
      #1;
      tb_check32("F3 dual bank0 forwards",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      tb_check32("F3 dual bank1 replays",
                 {29'b0, query1_replay, query1_forward, query1_allow}, 32'd4);
      check64("F3 dual bank0 full data", query0_forward_data,
              64'h8877_6655_4433_2211);
      clear_speculative_sq();

      // Both bank query faces can forward asymmetric payloads in the same
      // cycle.  This catches query1 PA/data aliases to query0.
      alloc_one(4'd1);
      fill_one_typed(4'd1, 64'h0000_0000_9580_0000,
                     64'h0123_4567_89ab_cdef, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      alloc_one(4'd2);
      fill_one_typed(4'd2, 64'h0000_0000_9580_0080,
                     64'hfedc_ba98_7654_3210, 8'hff, 1'b1,
                     `OOO_MEM_CLASS_CACHED);
      drive_query0(4'd4, 64'h0000_0000_9580_0000, 8'hff);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd5);
      query1_paddr = 64'h0000_0000_9580_0080;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'hff;
      #1;
      tb_check32("F3 dual forward bank0 onehot",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd2);
      tb_check32("F3 dual forward bank1 onehot",
                 {29'b0, query1_replay, query1_forward, query1_allow}, 32'd2);
      check64("F3 dual forward bank0 data", query0_forward_data,
              64'h0123_4567_89ab_cdef);
      check64("F3 dual forward bank1 data", query1_forward_data,
              64'hfedc_ba98_7654_3210);
      clear_speculative_sq();

      // One unknown older placeholder must independently replay both bank
      // faces; neither decision may borrow peer query metadata.
      alloc_one(4'd1);
      drive_query0(4'd4, 64'h0000_0000_9590_0000, 8'hff);
      query1_valid = 1'b1;
      query1_producer_id = producer_id_for_rob(4'd5);
      query1_paddr = 64'h0000_0000_9590_0080;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = 8'hff;
      #1;
      tb_check32("F3 dual retry bank0 onehot",
                 {29'b0, query0_replay, query0_forward, query0_allow}, 32'd4);
      tb_check32("F3 dual retry bank1 onehot",
                 {29'b0, query1_replay, query1_forward, query1_allow}, 32'd4);
      clear_speculative_sq();
      $display("[V8T-F3-SQ-QUERY] allow/dual-offset/typed/merge/youngest/partial/x-poison/x-ignore3/terminal/dual PASS");
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    flush_valid = 1'b0;
    flush_all = 1'b0;
    flush_rob_head = '0;
    flush_boundary_rob = '0;
    rob_head_valid = 1'b0;
    rob_head_idx = '0;
    rob_head_producer_id = '0;
    rob_head_owner_open = 1'b0;
    rob_head_launch_open = 1'b0;
    alloc0_valid = 1'b0;
    alloc0_rob_idx = '0;
    alloc0_producer_id = '0;
    alloc1_valid = 1'b0;
    alloc1_rob_idx = '0;
    alloc1_producer_id = '0;
    owner_bind_valid = 1'b0;
    owner_bind_rob_idx = '0;
    owner_bind_producer_id = '0;
    owner_bind_kind = 2'b01;
    owner_bind_token = 5'd0;
    owner_bind_mmu_epoch = 2'b00;
    owner_bind_fault_tval = '0;
    owner_bind1_valid = 1'b0;
    owner_bind1_rob_idx = '0;
    owner_bind1_producer_id = '0;
    owner_bind1_kind = 2'b01;
    owner_bind1_token = 5'd0;
    owner_bind1_mmu_epoch = 2'b00;
    owner_bind1_fault_tval = '0;
    fill0_valid = 1'b0;
    fill0_rob_idx = '0;
    fill0_owner_kind = 2'b01;
    fill0_owner_token = 5'd0;
    fill0_mmu_epoch = 2'b00;
    fill0_fault_tval = '0;
    fill0_vaddr = '0;
    fill0_paddr = '0;
    fill0_attr_valid = 1'b0;
    fill0_class = `OOO_MEM_CLASS_RSVD;
    fill0_cacheable = 1'b0;
    fill0_data = '0;
    fill0_strb = '0;
    fill1_valid = 1'b0;
    fill1_rob_idx = '0;
    fill1_owner_kind = 2'b01;
    fill1_owner_token = 5'd0;
    fill1_mmu_epoch = 2'b00;
    fill1_fault_tval = '0;
    fill1_vaddr = '0;
    fill1_paddr = '0;
    fill1_attr_valid = 1'b0;
    fill1_class = `OOO_MEM_CLASS_RSVD;
    fill1_cacheable = 1'b0;
    fill1_data = '0;
    fill1_strb = '0;
    terminal_valid = 1'b0;
    terminal_rob_idx = '0;
    terminal_owner_kind = 2'b01;
    terminal_owner_token = 5'd0;
    terminal_mmu_epoch = 2'b00;
    terminal_fault_tval = '0;
    terminal1_valid = 1'b0;
    terminal1_rob_idx = '0;
    terminal1_owner_kind = 2'b01;
    terminal1_owner_token = 5'd0;
    terminal1_mmu_epoch = 2'b00;
    terminal1_fault_tval = '0;
    release_valid = 1'b0;
    release_rob_idx = '0;
    release_producer_id = '0;
    req_fire = 1'b0;
    query_ports_idle();
    repeat (2) `TB_TICK(clk);
    rst = 1'b0;
    #1;

    tb_check32("reset count", {28'b0, count}, 32'd0);
    tb_check1("reset request invalid", req_valid, 1'b0);

    if ($test$plusargs("V11G_SQ_HOLDER_ONLY")) begin
      run_v11g_store_queue_holder_lifecycle();
      tb_finish("tb_ooo_store_queue_v11g_holder_lifecycle");
    end

    // Four stores, with the first two allocated together.
    alloc0_valid = 1'b1; alloc0_rob_idx = 4'd3;
    alloc0_producer_id = producer_id_for_rob(4'd3);
    alloc1_valid = 1'b1; alloc1_rob_idx = 4'd4;
    alloc1_producer_id = producer_id_for_rob(4'd4);
    `TB_TICK(clk);
    alloc0_valid = 1'b0; alloc1_valid = 1'b0;
    owner_bind_valid = 1'b1;
    owner_bind_rob_idx = 4'd3;
    owner_bind_producer_id = producer_id_for_rob(4'd3);
    owner_bind_kind = 2'b01;
    owner_bind_token = 5'd3;
    owner_bind_mmu_epoch = 2'b11;
    owner_bind_fault_tval = owner_tval_for_rob(4'd3);
    owner_bind1_valid = 1'b1;
    owner_bind1_rob_idx = 4'd4;
    owner_bind1_producer_id = producer_id_for_rob(4'd4);
    owner_bind1_kind = 2'b01;
    owner_bind1_token = 5'd4;
    owner_bind1_mmu_epoch = 2'b00;
    owner_bind1_fault_tval = owner_tval_for_rob(4'd4);
    `TB_TICK(clk);
    owner_bind_valid = 1'b0;
    owner_bind1_valid = 1'b0;
    #1;
    tb_check32("dual bind creates both exact owners",
               {30'b0, snoop_owner_valid[1:0]}, 32'd3);
    tb_check32("dual bind bank0 token",
               {27'b0, snoop_owner_token[0*5 +: 5]}, 32'd3);
    tb_check32("dual bind bank1 token",
               {27'b0, snoop_owner_token[1*5 +: 5]}, 32'd4);
    $display("[V8P-SQ-DUAL-BIND] two exact STORE owners bound on one edge PASS");
    alloc_one(4'd6);
    alloc_one(4'd9);
    #1;
    tb_check32("full count", {28'b0, count}, 32'd4);
    tb_check1("full blocks alloc0", alloc0_ready, 1'b0);

    // Out-of-order fill.  The request face must retain both original VA and PA.
    fill1_valid = 1'b1; fill1_rob_idx = 4'd4;
    fill1_owner_kind = 2'b01;
    fill1_owner_token = 5'd4;
    fill1_mmu_epoch = 2'b00;
    fill1_fault_tval = owner_tval_for_rob(4'd4);
    fill1_vaddr = 64'h0000_0000_0000_2000;
    fill1_paddr = 64'h0000_0000_8000_2000;
    fill1_attr_valid = 1'b1;
    fill1_class = `OOO_MEM_CLASS_NC;
    fill1_cacheable = 1'b0;
    fill1_data = 64'h4444_4444_4444_4444;
    fill1_strb = 8'hff;
    fill0_valid = 1'b1; fill0_rob_idx = 4'd6;
    fill0_owner_kind = 2'b01;
    fill0_owner_token = 5'd6;
    fill0_mmu_epoch = 2'b10;
    fill0_fault_tval = owner_tval_for_rob(4'd6);
    fill0_vaddr = 64'h0000_0000_0000_3000;
    fill0_paddr = 64'h0000_0000_8000_3000;
    fill0_attr_valid = 1'b1;
    fill0_class = `OOO_MEM_CLASS_CACHED;
    fill0_cacheable = 1'b1;
    fill0_data = 64'h6666_6666_6666_6666;
    fill0_strb = 8'hff;
    `TB_TICK(clk);
    fill0_valid = 1'b0; fill1_valid = 1'b0;
    fill0_attr_valid = 1'b0; fill1_attr_valid = 1'b0;
    fill0_class = `OOO_MEM_CLASS_RSVD;
    fill1_class = `OOO_MEM_CLASS_RSVD;
    fill0_cacheable = 1'b0; fill1_cacheable = 1'b0;
    fill_one(4'd3, 64'h0000_0000_0000_1000,
             64'h0000_0000_8000_1000, 64'h3333_3333_3333_3333);

    rob_head_valid = 1'b1;
    rob_head_idx = 4'd4;
    rob_head_producer_id = producer_id_for_rob(4'd4);
    rob_head_owner_open = 1'b1;
    rob_head_launch_open = 1'b1;
    #1;
    tb_check1("physical head mismatch blocks request", req_valid, 1'b0);
    rob_head_idx = 4'd3;
    rob_head_producer_id = wrong_generation_for_rob(4'd3);
    #1;
    tb_check1("same ROB slot wrong generation blocks request", req_valid, 1'b0);
    rob_head_producer_id = producer_id_for_rob(4'd3);
    #1;
    tb_check1("head match exposes request", req_valid, 1'b1);
    tb_check32("head request ROB", {28'b0, req_rob_idx}, 32'd3);
    tb_check32("head request full producer ID",
               {{(32-PRODUCER_ID_W){1'b0}}, req_producer_id},
               {{(32-PRODUCER_ID_W){1'b0}}, producer_id_for_rob(4'd3)});
    tb_check32("head snoop full producer ID",
               {{(32-PRODUCER_ID_W){1'b0}},
                snoop_producer_id[0*PRODUCER_ID_W +: PRODUCER_ID_W]},
               {{(32-PRODUCER_ID_W){1'b0}}, producer_id_for_rob(4'd3)});
    tb_check32("head request owner kind", {30'b0, req_owner_kind}, 32'd1);
    tb_check32("head request owner token", {27'b0, req_owner_token}, 32'd3);
    tb_check32("head request owner epoch", {30'b0, req_mmu_epoch}, 32'd3);
    check64("head request owner fault_tval", req_fault_tval,
            64'h0000_0000_0000_1000);
    check64("request retains VA", req_vaddr, 64'h0000_0000_0000_1000);
    check64("request uses PA", req_paddr, 64'h0000_0000_8000_1000);
    tb_check1("request retains post-translate cacheable class",
              req_cacheable, 1'b1);
    tb_check1("request typed attr valid", req_attr_valid, 1'b1);
    tb_check32("request typed CACHED class", {30'b0, req_class},
               {30'b0, `OOO_MEM_CLASS_CACHED});
    check64("physical snoop view uses PA",
            snoop_paddr[0*`XLEN +: `XLEN],
            64'h0000_0000_8000_1000);
    tb_check1("physical snoop cacheable class visible",
              snoop_cacheable[0], 1'b1);
    tb_check1("physical snoop typed attr visible",
              snoop_attr_valid[0], 1'b1);
    tb_check32("physical snoop CACHED class visible",
               {30'b0, snoop_class[0*2 +: 2]},
               {30'b0, `OOO_MEM_CLASS_CACHED});

    // Event 1: physical request fire.  Owner/count/forwarding remain; no duplicate.
    req_fire = 1'b1;
    `TB_TICK(clk);
    req_fire = 1'b0;
    #1;
    tb_check32("request fire keeps owner", {28'b0, count}, 32'd4);
    tb_check1("request at-most-once", req_valid, 1'b0);
    tb_check1("request-sent visible", snoop_request_sent[0], 1'b1);
    tb_check1("request-sent is not terminal", snoop_terminal[0], 1'b0);
    release_rob_idx = 4'd3;
    release_producer_id = producer_id_for_rob(4'd3);
    #1;
    tb_check1("pre-B release blocked", release_ready, 1'b0);
    $display("[V8G-SQ-POST-LAUNCH] request_sent retains live nonterminal full-PID owner until exact B PASS");
    check64("forwarding VA persists", snoop_addr[0*`XLEN +: `XLEN],
            64'h0000_0000_0000_1000);

`ifdef V9L_SQ_OWNER_OPEN_NEGATIVE
    // Compile-success negative stimulus: an issued physical write remains
    // nonterminal, but its exact ROB owner authorization is withdrawn.  The
    // production post-launch assertion must reject this edge before the
    // ordinary selective-recovery scenario below can continue.
    rob_head_owner_open = 1'b0;
    #1;
    $display("[V9L-SQ-OWNER-OPEN-NEGATIVE-STIMULUS] nonterminal issued store owner authorization closed");
    `TB_TICK(clk);
    $display("[V9L-SQ-OWNER-OPEN-NEGATIVE-STIMULUS][FAIL] production assertion accepted a closed owner");
    $fatal;
`endif

    // Active owner survives a branch flush; only strictly younger-than-boundary
    // suffix (rob9) is removed.  A real ROB recovery closes first-launch
    // admission for several cycles, but must not revoke the exact older owner
    // of an already-issued physical write.
    rob_head_launch_open = 1'b0;
    flush_valid = 1'b1;
    flush_all = 1'b0;
    flush_rob_head = 4'd3;
    flush_boundary_rob = 4'd6;
    #1;
    tb_check32("branch flush raw owner release mask", owner_release_mask,
               32'h0000_0200);
    `TB_TICK(clk);
    flush_valid = 1'b0;
    #1;
    tb_check32("branch flush keeps active prefix", {28'b0, count}, 32'd3);
    tb_check1("active owner survives branch", snoop_request_sent[0], 1'b1);
    tb_check1("younger suffix removed", snoop_valid[3], 1'b0);
    repeat (2) `TB_TICK(clk);
    tb_check1("selective recovery retains exact physical owner",
              snoop_request_sent[0], 1'b1);
    rob_head_launch_open = 1'b1;
    $display("[V9L-SQ-RECOVERY-OWNER] launch admission closed while exact issued owner remained open PASS");

    // Event 2: B response terminal.  Owner still resident and becomes releasable.
    send_terminal(4'd3);
    #1;
    tb_check32("B terminal keeps owner", {28'b0, count}, 32'd3);
    tb_check1("terminal visible", snoop_terminal[0], 1'b1);
    release_rob_idx = 4'd3;
    release_producer_id = wrong_generation_for_rob(4'd3);
    #1;
    tb_check1("same ROB slot wrong generation blocks release",
              release_ready, 1'b0);
    release_producer_id = producer_id_for_rob(4'd3);
    #1;
    tb_check1("terminal enables release", release_ready, 1'b1);
    $display("[V8G-SQ-FULL-PID] bind/request/release full generation contract PASS");

    // Event 3: ROB commit/release.  Only now does the physical head advance.
    release_one(4'd3);
    #1;
    tb_check32("ROB release removes owner", {28'b0, count}, 32'd2);
    rob_head_idx = 4'd4;
    rob_head_producer_id = producer_id_for_rob(4'd4);
    #1;
    tb_check1("second store follows physical order", req_valid, 1'b1);
    tb_check32("second request ROB", {28'b0, req_rob_idx}, 32'd4);
    check64("second request PA", req_paddr, 64'h0000_0000_8000_2000);
    tb_check1("second request retains NC/IO class", req_cacheable, 1'b0);
    tb_check1("second request typed attr valid", req_attr_valid, 1'b1);
    tb_check32("second request retains exact NC class",
               {30'b0, req_class}, {30'b0, `OOO_MEM_CLASS_NC});

    req_fire = 1'b1; `TB_TICK(clk); req_fire = 1'b0;
    send_terminal(4'd4);
    release_one(4'd4);
    #1;
    tb_check32("second store released", {28'b0, count}, 32'd1);

    // Probe fault terminal can arrive without fill/request, and same-cycle
    // terminal+ROB release is accepted through the terminal bypass.
    rob_head_idx = 4'd6;
    rob_head_producer_id = producer_id_for_rob(4'd6);
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd6;
    terminal_owner_kind = 2'b01;
    terminal_owner_token = 5'd6;
    terminal_mmu_epoch = 2'b10;
    terminal_fault_tval = owner_tval_for_rob(4'd6);
    release_valid = 1'b1;
    release_rob_idx = 4'd6;
    release_producer_id = producer_id_for_rob(4'd6);
    #1;
    tb_check1("same-cycle terminal release ready", release_ready, 1'b1);
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    release_valid = 1'b0;
    #1;
    tb_check32("fault store released", {28'b0, count}, 32'd0);

    // Global flush is only used with speculative entries; no live physical owner
    // may be silently nuked.
    alloc_one(4'd10);
    alloc_one(4'd11);
    flush_valid = 1'b1;
    flush_all = 1'b1;
    flush_rob_head = 4'd10;
    #1;
    tb_check32("global flush raw owner release mask", owner_release_mask,
               32'h0000_0c00);
    `TB_TICK(clk);
    flush_valid = 1'b0;
    flush_all = 1'b0;
    #1;
    tb_check32("global flush clears speculation", {28'b0, count}, 32'd0);
    tb_check1("empty request invalid", req_valid, 1'b0);

    // An accepted physical STORE is nokill.  Global flush before B must keep
    // the complete owner and must not emit a squash release; success/error B
    // share the same exact SQ terminal and release boundary.
    request_sent_global_flush_survival(4'd8, 1'b0);
    request_sent_global_flush_survival(4'd7, 1'b1);

    // Reviewer event algebra: one terminal head release and two fresh dispatch
    // allocations are independent ports.  Occupancy is old(1)-release(1)+alloc(2).
    alloc_one(4'd12);
    send_terminal(4'd12);
    release_valid = 1'b1;
    release_rob_idx = 4'd12;
    release_producer_id = producer_id_for_rob(4'd12);
    alloc0_valid = 1'b1;
    alloc0_rob_idx = 4'd13;
    alloc0_producer_id = producer_id_for_rob(4'd13);
    alloc1_valid = 1'b1;
    alloc1_rob_idx = 4'd14;
    alloc1_producer_id = producer_id_for_rob(4'd14);
    #1;
    tb_check1("release+alloc release ready", release_ready, 1'b1);
    tb_check1("release+alloc alloc0 ready", alloc0_ready, 1'b1);
    tb_check1("release+alloc alloc1 ready", alloc1_ready, 1'b1);
    `TB_TICK(clk);
    release_valid = 1'b0;
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    bind_one(4'd13);
    bind_one(4'd14);
    #1;
    tb_check32("release+dual-alloc count", {28'b0, count}, 32'd2);
    tb_check1("release+dual-alloc new head valid", snoop_valid[snoop_head], 1'b1);
    tb_check32("release+dual-alloc new head ROB",
               {{(32-ROB_INDEX_W){1'b0}},
                snoop_rob_idx[snoop_head*ROB_INDEX_W +: ROB_INDEX_W]},
               32'd13);
    $display("[T4N-SQ-RELEASE-DUAL-ALLOC] count=2 head_rob=13 PASS");

    // 两个不同 terminal tag 同拍各命中一次，不能由单 tag mux 丢掉一路。
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd13;
    terminal_owner_kind = 2'b01;
    terminal_owner_token = 5'd13;
    terminal_mmu_epoch = 2'b01;
    terminal_fault_tval = owner_tval_for_rob(4'd13);
    terminal1_valid = 1'b1;
    terminal1_rob_idx = 4'd14;
    terminal1_owner_kind = 2'b01;
    terminal1_owner_token = 5'd14;
    terminal1_mmu_epoch = 2'b10;
    terminal1_fault_tval = owner_tval_for_rob(4'd14);
`ifdef T4N_DUAL_TERMINAL_SAME_TAG_NEGATIVE
    terminal1_rob_idx = 4'd13;
    $display("[T4N-DUAL-TERMINAL-SAME-TAG-NEGATIVE] forced both terminal tags to rob13");
`endif
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    terminal1_valid = 1'b0;
    #1;
    tb_check1("dual terminal marks head",
              snoop_terminal[snoop_head], 1'b1);
    tb_check1("dual terminal marks next",
              snoop_terminal[snoop_head + 1'b1], 1'b1);
    release_one(4'd13);
    release_one(4'd14);
    #1;
    tb_check32("dual terminal pair releases in order", {28'b0, count}, 32'd0);
    $display("[T4N-SQ-DUAL-TERMINAL] distinct ROB tags both sticky PASS");

    // Terminal+B, ROB release and global flush may coincide for the accepted
    // physical head.  Same-cycle terminal bypass authorizes release, and the
    // flush keep/release algebra must leave neither a ghost nor a nuke error.
    alloc_one(4'd15);
    fill_one(4'd15, 64'h0000_0000_0000_5000,
             64'h0000_0000_8000_5000, 64'hf5f5_f5f5_f5f5_f5f5);
    rob_head_valid = 1'b1;
    rob_head_idx = 4'd15;
    rob_head_producer_id = producer_id_for_rob(4'd15);
    rob_head_owner_open = 1'b1;
    rob_head_launch_open = 1'b1;
    #1;
    tb_check1("terminal+release+flush request visible", req_valid, 1'b1);
    req_fire = 1'b1;
    `TB_TICK(clk);
    req_fire = 1'b0;
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd15;
    terminal_owner_kind = 2'b01;
    terminal_owner_token = 5'd15;
    terminal_mmu_epoch = 2'b11;
    terminal_fault_tval = owner_tval_for_rob(4'd15);
    release_valid = 1'b1;
    release_rob_idx = 4'd15;
    release_producer_id = producer_id_for_rob(4'd15);
    flush_valid = 1'b1;
    flush_all = 1'b1;
    flush_rob_head = 4'd15;
    #1;
    tb_check1("terminal+release+flush same-cycle ready", release_ready, 1'b1);
    tb_check32("terminal+release+flush exact owner release mask",
               owner_release_mask, 32'h0000_8000);
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    release_valid = 1'b0;
    flush_valid = 1'b0;
    flush_all = 1'b0;
    #1;
    tb_check32("terminal+release+flush leaves empty", {28'b0, count}, 32'd0);
    tb_check1("terminal+release+flush no ghost request", req_valid, 1'b0);
    tb_check32("terminal+release+flush no ghost owner",
               {28'b0, snoop_request_sent}, 32'd0);
    $display("[T4N-SQ-TERMINAL-RELEASE-GLOBAL-FLUSH] accepted owner released exactly once PASS");

    // Capture-time local exception: owner bind and terminal1 arrive together,
    // and the existing same-cycle terminal→release bypass must remain exact.
    alloc0_valid = 1'b1;
    alloc0_rob_idx = 4'd1;
    alloc0_producer_id = producer_id_for_rob(4'd1);
    `TB_TICK(clk);
    alloc0_valid = 1'b0;
    owner_bind_valid = 1'b1;
    owner_bind_rob_idx = 4'd1;
    owner_bind_producer_id = producer_id_for_rob(4'd1);
    owner_bind_kind = 2'b01;
    owner_bind_token = 5'd1;
    owner_bind_mmu_epoch = 2'b01;
    owner_bind_fault_tval = owner_tval_for_rob(4'd1);
    terminal1_valid = 1'b1;
    terminal1_rob_idx = 4'd1;
    terminal1_owner_kind = 2'b01;
    terminal1_owner_token = 5'd1;
    terminal1_mmu_epoch = 2'b01;
    terminal1_fault_tval = owner_tval_for_rob(4'd1);
    release_valid = 1'b1;
    release_rob_idx = 4'd1;
    release_producer_id = producer_id_for_rob(4'd1);
    #1;
    tb_check1("bind+terminal1 release ready", release_ready, 1'b1);
    tb_check32("bind+terminal1 exact owner mask", owner_release_mask, 32'h0000_0002);
    `TB_TICK(clk);
    owner_bind_valid = 1'b0;
    terminal1_valid = 1'b0;
    release_valid = 1'b0;
    #1;
    tb_check32("bind+terminal1 release leaves empty", {28'b0, count}, 32'd0);
    $display("[S2-G1-SQ-BIND-TERMINAL1] same-cycle exact owner terminal/release PASS");

    final_pa_query_matrix();
`ifdef V8T_X_FAULT_INJECTION
    // Negative nonvacuity profile: an exact query face may not contain an
    // unknown ProducerId.  OOO_ASSERT must terminate on the named oracle.
    query_ports_idle();
    query0_valid = 1'b1;
    query0_producer_id = {PRODUCER_ID_W{1'bx}};
    query0_paddr = 64'h0000_0000_95f0_0000;
    query0_attr_valid = 1'b1;
    query0_class = `OOO_MEM_CLASS_CACHED;
    query0_strb = 8'hff;
    `TB_TICK(clk);
`endif
    tb_finish("tb_ooo_store_queue");
  end
endmodule
