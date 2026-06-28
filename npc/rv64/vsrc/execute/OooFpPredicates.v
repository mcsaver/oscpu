// OooFpPredicates.v — FP execute 子系统共享谓词函数（NaN / sNaN / NaN-box 判定）。
// 这些是纯组合判定，从 OooFpPendingExec 巨石抽出的各 FP owner（compare/minmax/
// convert/fma 等）共用；用 `include 注入到各模块 scope，避免逐模块复制实现。
// 约定：单精度操作数按 RV64 NaN-box（高 32 位全 1）；未正确 box 的单精度视为 NaN。
// 注意 Verilator 的 `define 跨文件全局，故本头不用 `ifndef guard（否则只有首个
// include 的模块拿到函数声明）；调用方需保证每个模块对本头只 include 一次。
function fp_is_nan_s_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_nan_s_value =
        (value[63:32] != 32'hffff_ffff) ||
        ((value[30:23] == 8'hff) && (value[22:0] != 23'b0));
  end
endfunction

function fp_is_nan_d_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_nan_d_value =
        (value[62:52] == 11'h7ff) && (value[51:0] != 52'b0);
  end
endfunction

function fp_is_boxed_s_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_boxed_s_value = (value[63:32] == 32'hffff_ffff);
  end
endfunction

function fp_is_snan_s_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_snan_s_value =
        fp_is_boxed_s_value(value) &&
        (value[30:23] == 8'hff) &&
        (value[22:0] != 23'b0) &&
        !value[22];
  end
endfunction

function fp_is_snan_d_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_snan_d_value =
        (value[62:52] == 11'h7ff) &&
        (value[51:0] != 52'b0) &&
        !value[51];
  end
endfunction

function fp_is_inf_s_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_inf_s_value =
        fp_is_boxed_s_value(value) &&
        (value[30:23] == 8'hff) &&
        (value[22:0] == 23'b0);
  end
endfunction

function fp_is_zero_s_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_zero_s_value =
        fp_is_boxed_s_value(value) &&
        (value[30:23] == 8'h00) &&
        (value[22:0] == 23'b0);
  end
endfunction

function fp_is_inf_d_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_inf_d_value =
        (value[62:52] == 11'h7ff) &&
        (value[51:0] == 52'b0);
  end
endfunction

function fp_is_zero_d_value;
  input [`XLEN-1:0] value;
  begin
    fp_is_zero_d_value =
        (value[62:52] == 11'h000) &&
        (value[51:0] == 52'b0);
  end
endfunction
