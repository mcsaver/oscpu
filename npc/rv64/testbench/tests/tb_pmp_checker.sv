`include "define.v"

module tb_pmp_checker;
  `include "tb_common.svh"

  localparam [7:0] PMP_CFG_TOR_RWX = 8'h0f;
  localparam [7:0] PMP_CFG_NA4_R = 8'h11;
  localparam [7:0] PMP_CFG_NAPOT_NONE = 8'h18;
  localparam [7:0] PMP_CFG_NAPOT_RWX = 8'h1f;
  localparam [7:0] PMP_CFG_NAPOT_LOCKED_NONE = 8'h98;

  reg [`XLEN-1:0] paddr;
  reg [3:0] access_size;
  reg [1:0] priv_mode;
  reg access_read;
  reg access_write;
  reg access_exec;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr;
  wire fault;

  PmpChecker dut (
    .paddr_i(paddr),
    .access_size_i(access_size),
    .priv_mode_i(priv_mode),
    .access_read_i(access_read),
    .access_write_i(access_write),
    .access_exec_i(access_exec),
    .pmpcfg_i(pmpcfg),
    .pmpaddr_i(pmpaddr),
    .fault_o(fault)
  );

  task automatic clear_pmp;
    begin
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
    end
  endtask

  task automatic set_entry;
    input integer entry_idx;
    input [7:0] cfg;
    input [`XLEN-1:0] addr;
    begin
      pmpcfg[entry_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W] = cfg;
      pmpaddr[entry_idx * `XLEN +: `XLEN] = addr;
    end
  endtask

  task automatic check_access;
    input [1023:0] what;
    input [`XLEN-1:0] addr;
    input [3:0] size;
    input [1:0] priv;
    input rd;
    input wr;
    input ex;
    input exp_fault;
    begin
      paddr = addr;
      access_size = size;
      priv_mode = priv;
      access_read = rd;
      access_write = wr;
      access_exec = ex;
      #1;
      tb_check1(what, fault, exp_fault);
    end
  endtask

  initial begin
    tb_errors = 0;
    clear_pmp();
    paddr = {`XLEN{1'b0}};
    access_size = 4'd4;
    priv_mode = `PRIV_M;
    access_read = 1'b0;
    access_write = 1'b0;
    access_exec = 1'b0;

    check_access("no-match M read passes", 64'h8000_0000, 4'd4,
                 `PRIV_M, 1'b1, 1'b0, 1'b0, 1'b0);
    check_access("no-match S read faults", 64'h8000_0000, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);
    check_access("no access request does not fault", 64'h8000_0000, 4'd4,
                 `PRIV_S, 1'b0, 1'b0, 1'b0, 1'b0);

    clear_pmp();
    set_entry(0, PMP_CFG_NAPOT_RWX, {`XLEN{1'b1}});
    check_access("all-space NAPOT allows S write", 64'h8000_1000, 4'd8,
                 `PRIV_S, 1'b0, 1'b1, 1'b0, 1'b0);
    check_access("access wrap always faults", 64'hffff_ffff_ffff_fffc, 4'd8,
                 `PRIV_M, 1'b1, 1'b0, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, PMP_CFG_TOR_RWX, 64'h1000); // [0x0, 0x4000)
    check_access("TOR full cover passes", 64'h0000_3000, 4'd8,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b0);
    check_access("TOR partial high edge faults", 64'h0000_3ffc, 4'd8,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);
    check_access("TOR upper bound no-match faults S", 64'h0000_4000, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, 8'h00, 64'h1000);          // TOR entry1 lower = 0x4000
    set_entry(1, PMP_CFG_TOR_RWX, 64'h2000); // [0x4000, 0x8000)
    check_access("TOR entry1 lower bound passes", 64'h0000_4000, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b0);
    check_access("TOR entry1 partial low edge faults", 64'h0000_3ffc, 4'd8,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, PMP_CFG_NA4_R, 64'h2000); // [0x8000, 0x8004)
    check_access("NA4 read passes", 64'h0000_8000, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b0);
    check_access("NA4 write permission faults", 64'h0000_8000, 4'd4,
                 `PRIV_S, 1'b0, 1'b1, 1'b0, 1'b1);
    check_access("NA4 partial cover faults", 64'h0000_8000, 4'd8,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);
    check_access("size zero is treated as one byte", 64'h0000_8003, 4'd0,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b0);

    clear_pmp();
    set_entry(0, PMP_CFG_NAPOT_RWX, 64'h2001); // 16B [0x8000, 0x8010)
    check_access("NAPOT 16B full cover passes", 64'h0000_8008, 4'd4,
                 `PRIV_S, 1'b0, 1'b0, 1'b1, 1'b0);
    check_access("NAPOT 16B partial high edge faults", 64'h0000_800e, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, PMP_CFG_NA4_R, 64'h2400);     // [0x9000, 0x9004)
    set_entry(1, PMP_CFG_NAPOT_RWX, 64'h2401); // lower-priority 16B allow
    check_access("first overlap priority beats later allow", 64'h0000_9000, 4'd4,
                 `PRIV_S, 1'b0, 1'b1, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, PMP_CFG_NAPOT_NONE, {`XLEN{1'b1}});
    check_access("unlocked M ignores PMP permissions", 64'h8000_0000, 4'd4,
                 `PRIV_M, 1'b1, 1'b0, 1'b0, 1'b0);
    clear_pmp();
    set_entry(0, PMP_CFG_NAPOT_LOCKED_NONE, {`XLEN{1'b1}});
    check_access("locked M enforces PMP permissions", 64'h8000_0000, 4'd4,
                 `PRIV_M, 1'b1, 1'b0, 1'b0, 1'b1);

    clear_pmp();
    set_entry(0, 8'h00, 64'h2000);
    set_entry(1, PMP_CFG_TOR_RWX, 64'h1000); // upper <= lower, inactive
    check_access("invalid TOR entry inactive for M", 64'h0000_5000, 4'd4,
                 `PRIV_M, 1'b1, 1'b0, 1'b0, 1'b0);
    check_access("invalid TOR entry inactive for S no-match", 64'h0000_5000, 4'd4,
                 `PRIV_S, 1'b1, 1'b0, 1'b0, 1'b1);

    tb_finish("tb_pmp_checker");
  end
endmodule
