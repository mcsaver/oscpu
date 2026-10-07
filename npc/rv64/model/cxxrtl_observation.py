"""Simulation-only observation ports preserve existing cross-module assertions.

Applied to generated copies only. No production RTL edits or timing changes.
"""

import re

ROB_FIELDS = {
    "valid_q": ("[N-1:0]", ""),
    "done_q": ("[N-1:0]", ""),
    "rd_write_q": ("[N-1:0]", ""),
    "rd_fp_q": ("[N-1:0]", ""),
    "generation_q": ("[GEN_W-1:0]", "[0:N-1]"),
    "pnew_q": ("[PREG_W-1:0]", "[0:N-1]"),
}


def sub_once(pattern, replacement, data):
    # 仅允许唯一结构锚点；排版变化不能静默丢失观测连接。
    result, count = re.subn(pattern, replacement, data)
    if count != 1:
        raise ValueError(f"Expected one RTL anchor, found {count}: {pattern}")
    return result


def ports(fields, prefix, direction="output"):
    return "\n".join(f" {direction} {w} {prefix}{n}{dim}," for n, (w, dim) in fields.items()) + "\n"


def connection(fields, output_prefix, wire_prefix):
    return "".join(f".{output_prefix}{n}({wire_prefix}{n})," for n in fields)


def insert_port(data, decl):
    at = data.index(" input ")
    return data[:at] + decl + data[at:]


def end_assign(data, decl):
    at = data.rindex("endmodule")
    return data[:at] + decl + "\n" + data[at:]


def adapt_checks(data, name):
    backend_fields = {
        n: (
            w.replace("GEN_W", "(TAG_W-ROB_W)").replace("PREG_W", "6").replace("N", "(1<<ROB_W)"),
            dim.replace("N", "(1<<ROB_W)"),
        )
        for n, (w, dim) in ROB_FIELDS.items()
    }
    if name == "R64Rob.v":
        data = insert_port(data, ports(ROB_FIELDS, "model_"))
        data = end_assign(data, "\n".join(f" assign model_{n}={n};" for n in ROB_FIELDS))
    elif name == "R64RegRead.v":
        data = insert_port(data, " output [31:0] model_serial_owner_count,\n")
        data = end_assign(data, " assign model_serial_owner_count=serial_owner_count;")
    elif name == "R64Backend.v":
        data = insert_port(
            data,
            ports(backend_fields, "model_rob_")
            + " output [1:0] model_birth_w,\n output [31:0] model_serial_owner_count,\n",
        )
        data = sub_once(
            r"\brob\s*\(", lambda m: m[0] + connection(ROB_FIELDS, "model_", "model_rob_"), data
        )
        data = sub_once(
            r"\bregisters\s*\(",
            lambda m: m[0] + ".model_serial_owner_count(model_serial_owner_count),",
            data,
        )
        for field in ROB_FIELDS:
            data = data.replace("rob." + field, "model_rob_" + field)
        data = data.replace("registers.serial_owner_count", "model_serial_owner_count")
        data = end_assign(data, " assign model_birth_w=birth_w;")
    elif name == "R64CoreTop.v":
        core_fields = {
            n: (
                w.replace("(1<<ROB_W)", "32").replace("(TAG_W-ROB_W)", "4"),
                dim.replace("(1<<ROB_W)", "32"),
            )
            for n, (w, dim) in backend_fields.items()
        }
        decl = ports(core_fields, "model_rob_", "wire").replace(",\n", ";\n")
        decl += " wire [1:0] model_birth_w;\n wire [31:0] model_serial_owner_count;\n"
        end = data.index(");") + 2
        data = data[:end] + "\n" + decl + data[end:]
        data = sub_once(
            r"\bbackend\s*\(",
            lambda m: m[0]
            + connection(ROB_FIELDS, "model_rob_", "model_rob_")
            + ".model_birth_w(model_birth_w),.model_serial_owner_count(model_serial_owner_count),",
            data,
        )
        for field in ROB_FIELDS:
            data = data.replace("backend.rob." + field, "model_rob_" + field)
        data = data.replace("backend.birth_w", "model_birth_w").replace(
            "backend.registers.serial_owner_count", "model_serial_owner_count"
        )
    elif name == "R64LsuRequestQueue.v":
        fields = {
            "tag_q": ("[TAG_W-1:0]", "[0:1][0:1]"),
            "data_q": ("[DATA_W-1:0]", "[0:1][0:1]"),
            "valid_q": ("[1:0]", "[0:1]"),
        }
        data = insert_port(data, ports(fields, "model_"))
        data = end_assign(data, "\n".join(f" assign model_{n}={n};" for n in fields))
    elif name == "R64Lsu.v":
        # XREQUEST_W is a localparam, so declarations belong just before the instance.
        marker = r"(?m)^[ \t]*R64LsuRequestQueue\s*#\(\s*\.PREPARED_CANCEL\s*\(\s*PREPARED_CANCEL\s*\)\s*,\s*\.DATA_W\s*\(\s*XREQUEST_W\s*\)\s*,"
        data = sub_once(
            marker,
            lambda m: " wire [TAG_W-1:0] model_x_tag_q[0:1][0:1];\n"
            " wire [XREQUEST_W-1:0] model_x_data_q[0:1][0:1];\n"
            " wire [1:0] model_x_valid_q[0:1];\n" + m[0],
            data,
        )
        data = sub_once(
            r"\btranslation_queue\s*\(",
            lambda m: m[0]
            + ".model_tag_q(model_x_tag_q),.model_data_q(model_x_data_q),.model_valid_q(model_x_valid_q),",
            data,
        )
        for n in ("tag_q", "data_q", "valid_q"):
            data = data.replace("translation_queue." + n, "model_x_" + n)
    return data
