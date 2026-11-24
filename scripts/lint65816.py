#!/usr/bin/env python3
"""lint65816 - first-cut M/X register-size checker for ca65 65816 sources.

Usage: lint65816.py [-D NAME[=VAL]]... [-I DIR]... file.s ...

Each file is linted on its own (with its .includes). For every instruction
whose length depends on the register size (immediate operands), the size
the assembler was told (.a8/.a16/.i8/.i16, .smart) is compared with the
size the CPU is in, traced along every path through rep/sep/php/plp/xce
and branches.

Annotations (in comments):
  ;.a8 ;.a16 ;.a? ;.i8 ;.i16 ;.i?   set the traced size after this line
  ;.in a16 i8                       on a .proc/.macro/label line: sizes
                                    required on entry (8, 16 or *)
  ;.out a? i=                       on a .proc/.macro/label line: sizes on
                                    exit (8, 16, = unchanged, ? undefined)
  ;.noreturn                        on a .proc/.macro/label line: a call
                                    or use of it never returns (BRK-style
                                    error macros); brk itself ends a path
Defaults: entry to a proc/label = the declared size in force there; a
jsr/jsl/cop or macro leaves the sizes unchanged unless it has a ;.out.
"""

import os
import re
import sys

OPCODES = set("""
adc and asl bcc bcs beq bit bmi bne bpl bra brk brl bvc bvs clc cld cli clv
cmp cop cpx cpy dec dex dey eor inc inx iny jml jmp jsl jsr lda ldx ldy lsr
mvn mvp nop ora pea pei per pha phb phd phk php phx phy pla plb pld plp plx
ply rep rol ror rti rtl rts sbc sec sed sei sep sta stp stx sty stz tax tay
tcd tcs tdc trb tsb tsc tsx txa txs txy tya tyx wai wdm xba xce
""".split())
M_IMM = {"adc", "and", "bit", "cmp", "eor", "lda", "ora", "sbc"}
X_IMM = {"cpx", "cpy", "ldx", "ldy"}
COND_BR = {"bcc", "bcs", "beq", "bne", "bmi", "bpl", "bvc", "bvs"}
UNCOND = {"bra", "brl", "jmp", "jml"}
ENDS = {"rts", "rtl", "rti", "stp", "brk"}   # brk: BBC-style error
CALLS = {"jsr", "jsl"}
# things in a macro body that can change register sizes
SIZE_OPS = {".a8", ".a16", ".i8", ".i16", ".smart", "rep", "sep", "plp",
            "xce"}
DATA = {".byte", ".byt", ".word", ".addr", ".faraddr", ".dword", ".dbyt",
        ".asciiz", ".res", ".lobytes", ".hibytes", ".bankbytes"}

LABEL_RE = re.compile(r"^\s*(@?[A-Za-z_.][\w.]*|)\s*:(?![=:])")
ANN_SIZE_RE = re.compile(r"\.([ai])(8|16|\?)(?![\w])")
CONTRACT_RE = re.compile(r"\.(in|out)\s+((?:[ai](?:8|16|\*|=|\?)\s*)+)")


class Msg:
    def __init__(self, level, file, line, text):
        self.level, self.file, self.line, self.text = level, file, line, text

    def __str__(self):
        where = f"{self.file}:{self.line}" if self.line else self.file
        return f"{where}: {self.level}: {self.text}"


def split_comment(line):
    """Return (code, comment), ignoring ';' inside quotes."""
    q = None
    for i, c in enumerate(line):
        if q:
            if c == q:
                q = None
        elif c in "\"'":
            # 'x' char literal: skip it whole
            if c == "'" and i + 2 < len(line) and line[i + 2] == "'":
                q = None
                continue
            q = c
        elif c == ";":
            return line[:i], line[i + 1:]
    return line, ""


def ann_text(comment):
    """The annotation part of a comment: only ';' segments that start
    straight away with '.', e.g. ';.a8' or ';.in a16 ;.out a?'. Prose such
    as '; TODO: change to .a8' is ignored."""
    segs = ("" + comment).split(";")
    return " ".join(x for x in segs if x.startswith("."))


def parse_contract(comment):
    """-> {'in': {'a':..,'i':..}, 'out': {...}} for keywords present."""
    res = {}
    text = ann_text(comment)
    for kind, body in CONTRACT_RE.findall(text):
        d = {}
        for tok in body.split():
            d[tok[0]] = tok[1:]
        res[kind] = d
    if re.search(r"\.noreturn\b", text):
        res["noreturn"] = True
    return res


def parse_number(s):
    s = s.strip()
    try:
        if s.startswith("$"):
            return int(s[1:], 16)
        if s.startswith("%"):
            return int(s[1:], 2)
        return int(s, 0)
    except ValueError:
        return None


class Line:
    """One source line after include expansion and .if selection."""

    def __init__(self, file, lineno, label, op, operand, comment):
        self.file, self.lineno = file, lineno
        self.label, self.op, self.operand = label, op, operand
        self.word = op          # replaced by the source spelling below
        self.comment = comment


def read_lines(path, defines, incdirs, msgs, depth=0):
    """Expand .include and .if/.ifdef/.ifndef/.else/.elseif/.endif."""
    out = []
    try:
        with open(path, encoding="latin-1") as f:
            raw = f.read().splitlines()
    except OSError as e:
        msgs.append(Msg("error", path, 0, f"cannot read: {e.strerror}"))
        return out
    cond = []  # stack of [active, taken_already, parent_active]
    in_macro = False
    for n, text in enumerate(raw, 1):
        code, comment = split_comment(text)
        label = ""
        m = LABEL_RE.match(code)
        if m:
            label = m.group(1) or ":"
            code = code[m.end():]
        parts = code.strip().split(None, 1)
        op = parts[0].lower() if parts else ""
        operand = parts[1].strip() if len(parts) > 1 else ""
        active = all(c[0] for c in cond)

        if in_macro or (active and op in (".macro", ".mac")):
            # macro bodies are not traced; keep their .if lines as they
            # are rather than evaluating them (they may test .asize etc.)
            in_macro = op not in (".endmacro", ".endmac")
            out.append(Line(path, n, label, op, operand, comment))
            continue

        if op in (".if", ".ifdef", ".ifndef"):
            if op == ".ifdef":
                v = operand.split()[0] in defines
            elif op == ".ifndef":
                v = operand.split()[0] not in defines
            else:
                v = eval_if(operand, defines, msgs, path, n)
            cond.append([v, v, active])
            continue
        if op in (".elseif", ".else"):
            if not cond:
                msgs.append(Msg("error", path, n, f"{op} without .if"))
                continue
            c = cond[-1]
            if c[1]:
                c[0] = False
            else:
                v = True if op == ".else" else eval_if(operand, defines,
                                                       msgs, path, n)
                c[0] = c[1] = v
            continue
        if op == ".endif":
            if cond:
                cond.pop()
            continue
        if not active:
            continue

        if op == ".include":
            name = operand.strip().strip("\"'")
            found = None
            for d in [os.path.dirname(path)] + incdirs:
                cand = os.path.join(d, name)
                if os.path.isfile(cand):
                    found = cand
                    break
            if found is None:
                msgs.append(Msg("warning", path, n,
                                f"include not found: {name}"))
            elif depth > 16:
                msgs.append(Msg("error", path, n, "includes nested too deep"))
            else:
                out += read_lines(found, defines, incdirs, msgs, depth + 1)
            continue
        out.append(Line(path, n, label, op, operand, comment))
        out[-1].word = parts[0] if parts else ""
    return out


def eval_if(expr, defines, msgs, path, n):
    """Evaluate simple .if expressions: .defined(), !, &&, ||, numbers."""
    e = re.sub(r"\.defined\s*\(\s*(\w+)\s*\)",
               lambda m: "1" if m.group(1) in defines else "0", expr,
               flags=re.I)
    e = re.sub(r"\b[A-Za-z_]\w*\b",
               lambda m: str(defines.get(m.group(0), 0)), e)
    e = e.replace("&&", " and ").replace("||", " or ")
    e = re.sub(r"!(?!=)", " not ", e)
    e = e.replace("$", "0x")
    try:
        return bool(eval(e, {"__builtins__": {}}, {}))
    except Exception:
        msgs.append(Msg("warning", path, n,
                        f"cannot evaluate .if '{expr}', taken as false"))
        return False


class Unit:
    """One file plus its includes, ready for tracing."""

    def __init__(self, path, defines, incdirs):
        self.msgs = []
        lines = read_lines(path, defines, incdirs, self.msgs)
        self.ins = []          # instruction/macro-call entries
        self.labels = {}       # (scope, name) -> index into ins
        self.anon = []         # indexes of anonymous labels
        self.entries = []      # (index, declared a, i, contract)
        self.contracts = {}    # label key or macro name -> contract
        self.macros = {}       # name -> contract
        self.build(lines)

    def build(self, lines):
        a, i = 8, 8
        da = di = None         # Line that set the declared A/X size
        smart = False
        scopes = [""]
        cheap = 0
        in_macro = None
        pending = []           # labels waiting for their instruction
        pre_ann = []           # ;.a8 etc. on lines before the instruction
        data_line = None       # first data line since the last instruction
        for ln in lines:
            op = ln.op
            ann = ANN_SIZE_RE.findall(ann_text(ln.comment))
            if in_macro is not None:
                m = self.macros[in_macro]
                if op in (".endmacro", ".endmac"):
                    if m.get("_last") in ENDS | UNCOND:
                        m["noreturn"] = True    # body ends with rts, jmp..
                    if m["_sizes"] and "out" not in m \
                            and not m.get("noreturn"):
                        self.msgs.append(Msg(
                            "warning", m["_line"].file, m["_line"].lineno,
                            f"macro {m['_line'].operand.split()[0]} uses "
                            f"{', '.join(sorted(m['_sizes']))} but has no "
                            f";.out: callers assume it leaves the sizes "
                            f"unchanged"))
                    in_macro = None
                elif op and not op.startswith("."):
                    m["_code"] = True   # has an instruction or macro use
                    m["_last"] = op     # last instruction in the body
                if op in SIZE_OPS:
                    v = parse_number(ln.operand.lstrip("#"))
                    if op in ("rep", "sep") and v is not None \
                            and not v & 0x30:
                        continue        # flags only (e.g. sep #$40 = SEV)
                    m["_sizes"].add(op)
                    if op in (".a8", ".a16", ".i8", ".i16"):
                        m["_decl"][op[1]] = int(op[2:])
                continue
            if op in (".macro", ".mac"):
                name = ln.operand.split()[0].rstrip(",").lower()
                self.macros[name] = parse_contract(ln.comment)
                self.macros[name].update(_line=ln, _sizes=set(), _decl={},
                                         _code=False)
                in_macro = name
                continue

            if ln.label:
                if ln.label == ":":
                    pending.append(("anon", ln, None))
                else:
                    if not ln.label.startswith("@"):
                        cheap += 1
                    pending.append(("label", ln,
                                    self.key(scopes, cheap, ln.label)))

            if op == ".proc":
                name = ln.operand.split()[0].split(":")[0]
                pending.append(("proc", ln, self.key(scopes, cheap, name)))
                scopes.append(name)
                cheap += 1
                continue
            if op in (".scope",):
                scopes.append(ln.operand.split()[0] if ln.operand else "")
                continue
            if op in (".endproc", ".endscope"):
                if len(scopes) > 1:
                    scopes.pop()
                continue
            if op in (".a8", ".a16", ".i8", ".i16"):
                if op[1] == "a":
                    a, da = int(op[2:]), ln
                else:
                    i, di = int(op[2:]), ln
                continue
            if op == ".smart":
                smart = ln.operand.strip().lower() not in ("-", "off")
                continue
            # blank, other directives and data, or an assignment (x = 1,
            # x := 1): not code. Labels stay pending for the next
            # instruction.
            mac = self.macros.get(op) if op not in OPCODES else None
            data_macro = mac is not None and "_code" in mac \
                and not mac["_code"] \
                and not ({"in", "out", "noreturn"} & mac.keys())
            if data_macro and data_line is None:
                data_line = ln.lineno           # a macro that only emits data
            if op == "" or op.startswith(".") or data_macro or \
                    ln.operand.startswith(("=", ":=")):
                if op in ("", ".proc"):
                    pre_ann += ann
                if op in DATA and data_line is None:
                    data_line = ln.lineno
                continue

            if op not in OPCODES and op not in self.macros:
                # unknown word: treat as a macro defined elsewhere
                self.macros.setdefault(op, {})
            idx = len(self.ins)
            for kind, pl, key in pending:
                c = parse_contract(pl.comment)
                if kind == "anon":
                    self.anon.append(idx)
                    continue
                self.labels[key] = idx
                if c:
                    self.contracts[idx] = c
                if kind == "proc" or c.get("in"):
                    self.entries.append(idx)
            pending = []
            self.ins.append(dict(line=ln, op=op, arg=ln.operand, a=a, i=i,
                                 da=da, di=di,
                                 scopes=list(scopes), cheap=cheap,
                                 pre=pre_ann, ann=ann, data=data_line))
            pre_ann = []
            data_line = None
            mac = self.macros.get(op) if op not in OPCODES else None
            if mac:
                if "a" in mac.get("_decl", {}):
                    a, da = mac["_decl"]["a"], ln
                if "i" in mac.get("_decl", {}):
                    i, di = mac["_decl"]["i"], ln
            if smart and op in ("rep", "sep"):
                v = parse_number(ln.operand.lstrip("#"))
                if v is not None:
                    size = 16 if op == "rep" else 8
                    if v & 0x20:
                        a, da = size, ln
                    if v & 0x10:
                        i, di = size, ln

    @staticmethod
    def key(scopes, cheap, name):
        if name.startswith("@"):
            return f"@{cheap}:{name}"
        return "::".join(scopes[1:] + [name])

    def resolve(self, idx, arg):
        """Find the instruction index a branch/jump/call operand names."""
        tok = re.split(r"[\s,]", arg.strip(), 1)[0]
        tok = re.sub(r"^[afz]:", "", tok)
        if not tok or tok[0] in "([":
            return None
        ins = self.ins[idx]
        if re.fullmatch(r":[+-]+", tok):
            n = len(tok) - 1
            if tok[1] == "+":
                later = [x for x in self.anon if x > idx]
                return later[n - 1] if len(later) >= n else None
            earlier = [x for x in self.anon if x <= idx]
            return earlier[-n] if len(earlier) >= n else None
        if tok.startswith("@"):
            return self.labels.get(f"@{ins['cheap']}:{tok}")
        sc = ins["scopes"][1:]
        for k in range(len(sc), -1, -1):
            hit = self.labels.get("::".join(sc[:k] + [tok]))
            if hit is not None:
                return hit
        return None


def merge(x, y):
    """Combine the sizes arriving at a join. 8/16 known, None unknown,
    'D' = trust the declared size, 'C' = conflict (8 and 16 both arrive)."""
    if x == y:
        return x
    if "C" in (x, y) or (x in (8, 16) and y in (8, 16)):
        return "C"
    if "D" in (x, y):
        return "D"
    return None


def apply_out(a, i, oa, oi, contract, here):
    out = contract.get("out", {})
    if out.get("a", "=") != "=":
        a, oa = {"8": 8, "16": 16, "?": None}[out["a"]], here
    if out.get("i", "=") != "=":
        i, oi = {"8": 8, "16": 16, "?": None}[out["i"]], here
    return a, i, oa, oi


def check_in(unit, ins, state, contract, what, report):
    req = contract.get("in", {})
    for reg, cur in (("a", state[0]), ("i", state[1])):
        want = req.get(reg, "*")
        if want in ("8", "16") and cur in (8, 16) and cur != int(want):
            report("error", ins, f"{what} needs {reg.upper()} {want}-bit, "
                   f"CPU is {cur}-bit")


def lint(path, defines, incdirs):
    u = Unit(path, defines, incdirs)
    msgs = u.msgs
    seen = set()

    def report(level, ins, text):
        where = (ins["line"].file, ins["line"].lineno)
        if level == "warning" and (where, "error") in seen:
            return              # already explained by an error here
        k = (where, level)
        if k not in seen:
            seen.add(k)
            if level == "error":
                seen.add((where, "error"))
            msgs.append(Msg(level, ins["line"].file, ins["line"].lineno,
                            text))
            return msgs[-1]
        return None

    state_at = {}
    work = []
    joins = {}      # (idx, reg) -> (origin, origin) where 8 and 16 first met

    # A state is (a, i, ps, oa, oi): a/i are the sizes (8, 16, None, "D",
    # "C") and ps the saved (a, i) values for php/plp. oa/oi say where the
    # size came from: (kind, idx, call) with kind "set" (the instruction at
    # idx set it), "entry" or "join", and call the jsr/jsl it came in
    # through. Origins are for messages only: they are not compared, so
    # they don't cause re-tracing.

    def push(idx, st, frm=None):
        if idx is None or idx >= len(u.ins):
            return
        old = state_at.get(idx)
        if old is None:
            state_at[idx] = st
            work.append(idx)
            return
        a, oa = join_reg(idx, "a", old[0], st[0], old[3], st[3])
        i, oi = join_reg(idx, "i", old[1], st[1], old[4], st[4])
        ps = old[2] if old[2] == st[2] else ()
        if (a, i, ps) != old[:3]:
            state_at[idx] = (a, i, ps, oa, oi)
            work.append(idx)

    def join_reg(idx, reg, x, y, ox, oy):
        v = merge(x, y)
        if v == x:
            return x, ox
        if v == "C":
            if x == "C":
                return x, ox            # keep the first join's origin
            if y == "C":
                return y, oy
            if x in (8, 16) and y in (8, 16):
                joins.setdefault((idx, reg), (ox, oy))
            return v, ("join", idx, None)
        return v, oy

    def entry_state(idx):
        ins = u.ins[idx]
        c = u.contracts.get(idx, {}).get("in", {})
        a = int(c["a"]) if c.get("a") in ("8", "16") else ins["a"]
        i = int(c["i"]) if c.get("i") in ("8", "16") else ins["i"]
        return (a, i, (), ("entry", idx, None), ("entry", idx, None))

    # Entry points: the first instruction, labels with an ;.in contract,
    # and labels nothing in this file branches to, jumps to or calls (they
    # are reached from outside, so start from the declared size). Labels
    # that are targets get their state from the code that reaches them.
    targets = set()
    for k, ins in enumerate(u.ins):
        if ins["op"] in COND_BR | UNCOND | CALLS:
            t = u.resolve(k, ins["arg"])
            if t is not None:
                targets.add(t)
    labelled = set(u.labels.values()) | set(u.anon)
    seeds = sorted({0} | {x for x in u.entries if x in u.contracts}
                   | (labelled - targets)) if u.ins else []
    u.joins = joins
    u.join_msgs = {}       # (join idx, reg) -> [first Msg, further uses]
    u.data_hint = {}       # macro -> (first use, uses followed by data)
    while seeds:
        for s in seeds:
            if s not in state_at:
                push(s, entry_state(s))
        while work:
            idx = work.pop()
            step(u, idx, state_at[idx], push, report)
        # anything still unreached (e.g. only called from dead code)
        rest = sorted(x for x in labelled if x not in state_at)
        seeds = rest[:1]
    for key, g in u.join_msgs.items():
        _, ins, text = g["first"]
        n = g["n"] - 1
        if n:
            why = "after the same join" if key[0] == "join" else \
                "with the same size directive"
            text += f" (and {n} more {why}, up to line {g['last'][1]})"
        report("error", ins, text)
    for name, (ins, n) in u.data_hint.items():
        msgs.append(Msg("warning", ins["line"].file, ins["line"].lineno,
                        f"tracing falls through data after macro {ins['line'].word} "
                        f"({n} use{'s' if n > 1 else ''}); if it never "
                        f"returns, add ;.noreturn "
                        f"to its .macro line"))
    return msgs


def step(u, idx, st, push, report):
    ins = u.ins[idx]
    op, arg = ins["op"], ins["arg"]
    a, i, ps, oa, oi = st
    here = ("set", idx, None)

    a, i, oa, oi = annotate(ins["pre"], a, i, oa, oi, here)

    # check against contract if this is a contracted label reached by flow
    if idx in u.contracts:
        check_in(u, ins, (a, i), u.contracts[idx], "label", report)

    # the size check itself
    if arg.startswith("#"):
        if op in M_IMM:
            chk(u, ins, "A", "a", ins["a"], a, oa, report)
        elif op in X_IMM:
            chk(u, ins, "X", "i", ins["i"], i, oi, report)

    nxt = idx + 1
    if op == "rep" or op == "sep":
        v = parse_number(arg.lstrip("#"))
        size = 16 if op == "rep" else 8
        if v is None:
            a = i = None
            oa = oi = here
        else:
            if v & 0x20:
                a, oa = size, here
            if v & 0x10:
                i, oi = size, here
    elif op == "php":
        ps = (ps + ((a, i),))[-8:]
    elif op == "plp":
        if ps:
            a, i = ps[-1]
            ps = ps[:-1]
        else:
            # P was pushed somewhere we can't see (the caller, another
            # routine): trust the source's .aX/.iX until the next rep/sep
            a = i = "D"
        oa = oi = here
    elif op == "xce":
        a, i, oa, oi = 8, 8, here, here
    elif op in ENDS:
        return
    elif op in UNCOND:
        push(u.resolve(idx, arg), (a, i, ps, oa, oi), idx)
        return
    elif op in COND_BR:
        push(u.resolve(idx, arg), (a, i, ps, oa, oi), idx)
    elif op in CALLS:
        tgt = u.resolve(idx, arg)
        c = u.contracts.get(tgt, {}) if tgt is not None else {}
        check_in(u, ins, (a, i), c, f"{op} {arg}", report)
        if tgt is not None:
            # trace into the callee, remembering which call it came from
            push(tgt, (a, i, (), oa[:2] + (idx,), oi[:2] + (idx,)), idx)
        if c.get("noreturn"):
            return
        a, i, oa, oi = apply_out(a, i, oa, oi, c, here)
    elif op not in OPCODES:
        c = u.macros.get(op, {})
        check_in(u, ins, (a, i), c, f"macro {op}", report)
        if c.get("noreturn"):
            return
        if nxt < len(u.ins) and u.ins[nxt]["data"] is not None:
            u.data_hint.setdefault(op, (ins, 0))
            first, n = u.data_hint[op]
            u.data_hint[op] = (first, n + 1)
        a, i, oa, oi = apply_out(a, i, oa, oi, c, here)

    # line annotations override the traced state
    a, i, oa, oi = annotate(ins["ann"], a, i, oa, oi, here)
    push(nxt, (a, i, ps, oa, oi), idx)


def annotate(anns, a, i, oa, oi, here):
    for reg, val in anns:
        v = None if val == "?" else int(val)
        if reg == "a":
            a, oa = v, here
        else:
            i, oi = v, here
    return a, i, oa, oi


def where(u, ins, idx):
    """'123' for a line in the same file, 'file.inc:12' otherwise."""
    ln = u.ins[idx]["line"]
    if ln.file == ins["line"].file:
        return str(ln.lineno)
    return f"{os.path.basename(ln.file)}:{ln.lineno}"


def origin(u, ins, o):
    """Say where a size came from, e.g. 'sep at 12 (via jsr at 40)'."""
    kind, idx, call = o
    if kind == "set":
        t = f"{u.ins[idx]['op']} at {where(u, ins, idx)}"
    elif kind == "entry":
        t = f"entry at {where(u, ins, idx)}"
    else:
        t = f"an earlier join at {where(u, ins, idx)}"
    if call is not None:
        c = u.ins[call]
        tgt = re.split(r"[\s,]", c["arg"].strip(), 1)[0]
        t += f", via {c['op']} at {where(u, ins, call)}->{tgt}"
    return t


def declared_at(u, ins, r):
    """'.a16 at 3598' for the line that set the assembler's size."""
    ln = ins["da" if r == "a" else "di"]
    if ln is None:
        return "the default"
    w = str(ln.lineno) if ln.file == ins["line"].file else \
        f"{os.path.basename(ln.file)}:{ln.lineno}"
    return f"{ln.word or ln.op} at {w}"


def chk(u, ins, reg, r, declared, traced, o, report):
    if traced == "D":
        return
    decl = f"assembled as {declared}-bit by {declared_at(u, ins, r)}"
    if traced == "C":
        j = o[1]
        x, y = u.joins.get((j, r), (None, None))
        text = f"{ins['op']} #: {reg} may be 8 or 16-bit here ({decl})"
        if x is not None:
            text += (f"; paths meet at line {where(u, ins, j)}: one from "
                     f"{origin(u, ins, x)}, one from {origin(u, ins, y)}")
        key = ("join", j, r)
    elif traced is None:
        report("warning", ins, f"{ins['op']} #: {reg} size unknown here "
               f"({decl})")
        return
    elif traced != declared:
        text = (f"{ins['op']} #: {reg} is {traced}-bit (from "
                f"{origin(u, ins, o)}) but {decl}")
        # group mismatches caused by the same size directive
        key = ("decl", id(ins["da" if r == "a" else "di"]), r)
    else:
        return
    # Errors with the same cause (one join, or one size directive) are
    # grouped: the lowest line is reported, the rest are counted.
    pos = (ins["line"].file, ins["line"].lineno)
    g = u.join_msgs.setdefault(key, {"n": 0, "first": None, "last": pos})
    g["n"] += 1
    g["last"] = max(g["last"], pos)
    if g["first"] is None or pos < g["first"][0]:
        g["first"] = (pos, ins, text)


def main(argv):
    defines, incdirs, files = {}, [], []
    it = iter(argv)
    for arg in it:
        if arg.startswith("-D"):
            d = arg[2:] or next(it)
            k, _, v = d.partition("=")
            defines[k] = parse_number(v) if v else 1
        elif arg.startswith("-I"):
            incdirs.append(arg[2:] or next(it))
        else:
            files.append(arg)
    if not files:
        print(__doc__)
        return 2
    errors = 0
    for f in files:
        done = set()
        msgs = lint(f, defines, incdirs)
        msgs.sort(key=lambda m: (m.file, m.line))
        for m in msgs:
            text = str(m)
            if text in done:
                continue
            done.add(text)
            print(text)
            errors += m.level == "error"
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
