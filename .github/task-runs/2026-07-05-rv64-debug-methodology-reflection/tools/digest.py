#!/usr/bin/env python3
# 把 rv64core 相关 Claude Code 会话 jsonl 压成 (1) 精简 timeline (2) 量化指标表
import json, os, sys, glob, re
from datetime import datetime

SRC = "/home/lyg/.claude/projects/-home-lyg-PA-ysyx-workbench"
OUT = "/home/lyg/.claude/jobs/4ec33c7a/tmp/digest"
os.makedirs(OUT, exist_ok=True)

def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None

def clip(s, n):
    s = re.sub(r"\s+", " ", (s or "").strip())
    return s[:n]

# Bash command 分类：揭示 RTL debug 循环结构
def classify_cmd(c):
    c = c.lower()
    if re.search(r"\b(make|verilator|iverilog|vcs|build|cmake|g\+\+|gcc)\b", c) and "clean" not in c[:20]:
        if re.search(r"verilator|iverilog|vcs|\.v\b|obj_dir|npc|rv64", c):
            return "COMPILE"
    if re.search(r"difftest|make run|\brun\b|sim|arch=|coremark|riscv-tests|\bam\b|\./build", c):
        return "RUNTEST"
    if re.search(r"git (checkout|reset|stash|revert|restore)", c):
        return "REVERT"
    if re.search(r"\b(grep|rg|find|jq|awk|sed|cat|head|tail|wc|ls|vcd|wave|gtkwave)\b", c):
        return "PROBE"
    return "OTHER"

metrics = []
files = sorted(glob.glob(os.path.join(SRC, "*.jsonl")), key=lambda p: os.path.getmtime(p))
for path in files:
    sz = os.path.getsize(path)
    if sz < 40000:   # 跳过太小的空会话
        continue
    sid = os.path.basename(path).split(".")[0][:8]
    lines_out = []
    tss = []
    n = dict(user=0, atext=0, think=0, COMPILE=0, RUNTEST=0, REVERT=0, PROBE=0, OTHER=0,
             Edit=0, Write=0, Read=0, tool=0)
    first_user = ""
    real_user_inputs = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                o = json.loads(line)
            except Exception:
                continue
            t = o.get("type")
            ts = parse_ts(o.get("timestamp", ""))
            if ts: tss.append(ts)
            if t == "user":
                c = o.get("message", {}).get("content")
                if isinstance(c, str):
                    s = c.strip()
                    if s.startswith("<") or s.startswith("Caveat:") or "command-name>" in s:
                        continue
                    if "# Autonomous loop check" in s or "autonomous-loop" in s:
                        lines_out.append("[U:auto] (autonomous loop tick)")
                        continue
                    n["user"] += 1
                    if not first_user:
                        first_user = clip(s, 200)
                    real_user_inputs.append(clip(s, 300))
                    lines_out.append("[U] " + clip(s, 500))
                # array user content = tool_result, skip body
            elif t == "assistant":
                for part in o.get("message", {}).get("content", []) or []:
                    pt = part.get("type")
                    if pt == "text":
                        txt = clip(part.get("text", ""), 500)
                        if txt:
                            n["atext"] += 1
                            lines_out.append("[A] " + txt)
                    elif pt == "thinking":
                        n["think"] += 1
                    elif pt == "tool_use":
                        n["tool"] += 1
                        nm = part.get("name", "?")
                        inp = part.get("input", {}) or {}
                        if nm == "Bash":
                            cmd = inp.get("command", "")
                            cat = classify_cmd(cmd)
                            n[cat] += 1
                            lines_out.append(f"[T:{cat}] " + clip(cmd, 110))
                        elif nm in ("Edit", "Write", "Read"):
                            n[nm] += 1
                            fp = os.path.basename(inp.get("file_path", ""))
                            lines_out.append(f"[T:{nm}] {fp}")
                        elif nm in ("Task", "Agent"):
                            lines_out.append(f"[T:Agent] " + clip(inp.get("description", "") or inp.get("prompt", ""), 80))
                        elif nm == "Workflow":
                            lines_out.append(f"[T:Workflow] " + clip(str(inp.get("name", "") or inp.get("script", ""))[:80], 80))
                        else:
                            lines_out.append(f"[T:{nm}]")
    dur = 0
    start = end = ""
    if tss:
        tss.sort()
        dur = (tss[-1] - tss[0]).total_seconds() / 60.0
        start = tss[0].strftime("%m-%d %H:%M")
        end = tss[-1].strftime("%m-%d %H:%M")
    header = (f"### SESSION {sid} | {start} -> {end} | dur={dur:.0f}min | "
              f"user={n['user']} Atext={n['atext']} think={n['think']} | "
              f"COMPILE={n['COMPILE']} RUNTEST={n['RUNTEST']} Edit={n['Edit']} "
              f"REVERT={n['REVERT']} PROBE={n['PROBE']}\n"
              f"# FIRST USER: {first_user}\n")
    with open(os.path.join(OUT, f"{sid}.txt"), "w", encoding="utf-8") as fo:
        fo.write(header + "\n".join(lines_out))
    metrics.append(dict(sid=sid, start=start, end=end, dur=round(dur), sz_mb=round(sz/1e6,1),
                        **{k: n[k] for k in ("user","atext","think","COMPILE","RUNTEST","Edit","Write","REVERT","PROBE")},
                        first=first_user))

# 指标表
metrics.sort(key=lambda m: m["start"])
cols = ["sid","start","end","dur","sz_mb","user","atext","think","COMPILE","RUNTEST","Edit","Write","REVERT","PROBE"]
with open("/home/lyg/.claude/jobs/4ec33c7a/tmp/metrics.tsv","w") as f:
    f.write("\t".join(cols) + "\tfirst_user\n")
    for m in metrics:
        f.write("\t".join(str(m[c]) for c in cols) + "\t" + m["first"] + "\n")

# 汇总
tot = {k: sum(m[k] for m in metrics) for k in ("dur","COMPILE","RUNTEST","Edit","REVERT","PROBE","user")}
print(f"处理会话数: {len(metrics)}")
print(f"总时长: {tot['dur']} 分钟 = {tot['dur']/60:.1f} 小时")
print(f"总 COMPILE={tot['COMPILE']} RUNTEST={tot['RUNTEST']} Edit={tot['Edit']} REVERT={tot['REVERT']} PROBE={tot['PROBE']} 真实user输入={tot['user']}")
print(f"digest 输出目录: {OUT}")
print("\n== 每会话 timeline 文件大小 ==")
for m in metrics:
    p = os.path.join(OUT, f"{m['sid']}.txt")
    print(f"{m['sid']}  {m['start']}  dur={m['dur']:>4}min  {os.path.getsize(p)//1024:>4}KB  C={m['COMPILE']:>3} R={m['RUNTEST']:>3} E={m['Edit']:>3} REV={m['REVERT']:>2}")
