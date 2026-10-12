`ifndef R64_PROTOCOL_VH
`define R64_PROTOCOL_VH
// Public domain protocols, version 2. No private backend UOP layout belongs here.
// Public Fetch -> Lifecycle facts, per lane. Canonical is {legal,RV32 encoding}.
// Control bits are immutable instruction facts, never live privilege decisions.
`define R64_FETCH_CANONICAL_W 33
`define R64_FETCH_CONTROL_W 35
`define R64_FETCH_CLASS 2:0
`define R64_FETCH_RD_WRITE 3
`define R64_FETCH_RD_FP 4
`define R64_FETCH_SRC_FP 7:5
`define R64_FETCH_SRC_USED 10:8
`define R64_FETCH_FUNC 18:11
`define R64_FETCH_FLAGS 22:19
`define R64_FETCH_KIND 30:23
`define R64_FETCH_ARG_KIND 33:31
`define R64_FETCH_LEGAL 34
// Request admission uses fire=offer&credit; completion holds until ready or cancel.
// Full tags identify instruction lifetimes; memory tokens are opaque to callers.
`define R64_PROTOCOL_VERSION 2
`define R64_MEM_CMD_W 205
`define R64_MEM_BASE 63:0
`define R64_MEM_OFFSET 127:64
`define R64_MEM_DATA 191:128
`define R64_MEM_FUNC 199:192
`define R64_MEM_AMO 204:200
// The following offsets are relative to the extracted FUNC8 field.
// FUNC[4:3] reserved zero; AMO5 uses ISA funct5 encoding.
`define R64_MEM_FUNC_SIZE 1:0
`define R64_MEM_FUNC_UNSIGNED 2
`define R64_MEM_FUNC_STORE 5
`define R64_MEM_FUNC_FP 6
`define R64_MEM_FUNC_ATOMIC 7
`define R64_FP_CMD_W 32
`define R64_SERIAL_CMD_W 217
`define R64_SERIAL_PC 63:0
`define R64_SERIAL_INST 127:64
`define R64_SERIAL_OPERAND 191:128
`define R64_SERIAL_ASID 207:192
`define R64_SERIAL_KIND 215:208
`define R64_SERIAL_PAIR 216
// Recovery record for a domain with N instruction slots:
// [N+66] redirect; [N+65:N+2] redirect PC;
// [N+1] full flush; [N] selective event active; [N-1:0] candidate victims.
// Source revokes lifecycle authority at t0; service inboxes deliver at t1.
// Birth is fenced at t0/t1, including zero-victim events.
// Consumers form their local kill mask = candidates & {N{active}}.
// Candidates alone are a preparation hint and never cancel an owner.
`define R64_RECOVERY_W(N) ((N)+67)
`define R64_RECOVERY_ACTIVE(N) (N)
`define R64_RECOVERY_FLUSH(N) ((N)+1)
`define R64_RECOVERY_PC(N) ((N)+65):((N)+2)
`define R64_RECOVERY_REDIRECT(N) ((N)+66)
// Serial and memory use separate authorization records.
// Memory permission is a registered full-tag lease until terminal completion.
// Permits never authorize a different tag.
`define R64_EFFECT_W(T) ((T)+3)
`define R64_EFFECT_PRESENT(T) (T)
`define R64_EFFECT_MEMORY(T) ((T)+1)
`define R64_EFFECT_SERIAL(T) ((T)+2)
// Accepted retirement event: low two bits are the dense fire prefix, then tags.
`define R64_RETIRE_W(T) ((2*(T))+2)
`define R64_META_W 204
`define R64_M_PC 63:0
`define R64_M_RAW 127:64
`define R64_M_NPC 191:128
`define R64_M_LEN 195:192
`define R64_M_KIND 203:196
`define R64_RESULT_W 140
`define R64_R_DATA 63:0
`define R64_R_EXCEPTION 64
`define R64_R_CAUSE 70:65
`define R64_R_TVAL 134:71
`define R64_R_FFLAGS 139:135
`define R64_K_NORMAL 8'd0
`define R64_K_BRANCH 8'd1
`define R64_K_LOAD 8'd2
`define R64_K_STORE 8'd3
`define R64_K_AMO 8'd4
`define R64_K_FP 8'd5
`define R64_K_CSR 8'd6
`define R64_K_ECALL 8'd7
`define R64_K_EBREAK 8'd8
`define R64_K_MRET 8'd9
`define R64_K_SRET 8'd10
`define R64_K_WFI 8'd11
`define R64_K_FENCE 8'd12
`define R64_K_FENCEI 8'd13
`define R64_K_SFENCE 8'd14
`define R64_K_TENSOR 8'd15
`define R64_K_FAULT 8'd16
`endif
