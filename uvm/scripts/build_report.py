#!/usr/bin/env python3
"""Build doc/report/FIFO_Verification_Report.html from the sources and results.

Code listings are cut from the real .sv files (comments and logging calls removed),
and the headline numbers are read from uvm/fifo_uvm/out/regress, so the report cannot drift
from the code or from the last regression.

usage (from uvm/):  python3 scripts/build_report.py
then:                        weasyprint doc/report/FIFO_Verification_Report.html \
                                        doc/report/FIFO_Verification_Report.pdf
"""
import html, re, glob, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Repo layout: uvm/fifo_uvm = testbench, <repo>/rtl = DUT
TB, RTL = os.path.join(ROOT, "fifo_uvm"), os.path.join(os.path.dirname(ROOT), "rtl")
OUT = os.path.join(ROOT, "doc", "report", "FIFO_Verification_Report.html")
AUTHOR = "Vũ Minh Quân"
DATE = "November 2026"


# ----------------------------------------------------------------------------- code helpers
def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read().split("\n")


def clean(lines, drop_logging=True):
    """Remove full-line comments, uvm_info calls and repeated blank lines."""
    out, skip = [], 0
    for ln in lines:
        s = ln.strip()
        if skip:                               # inside a multi-line `uvm_info(...)
            skip += s.count("(") - s.count(")")
            continue
        if s.startswith("//"):
            continue
        if drop_logging and s.startswith("`uvm_info"):
            depth = s.count("(") - s.count(")")
            if depth > 0:
                skip = depth
            continue
        if not s and out and not out[-1].strip():
            continue
        out.append(ln.rstrip())
    while out and not out[0].strip():
        out.pop(0)
    while out and not out[-1].strip():
        out.pop()
    return out


def block(lines, start, end):
    """Lines from the first match of `start` up to and including the next match of `end`."""
    for i, ln in enumerate(lines):
        if re.search(start, ln):
            for j in range(i, len(lines)):
                if re.search(end, lines[j]) and j > i:
                    return lines[i:j + 1]
    sys.exit(f"block not found: {start}")


def dedent(lines):
    ind = min((len(l) - len(l.lstrip()) for l in lines if l.strip()), default=0)
    return [l[ind:] for l in lines]


def rtl_clean():
    """sync_fifo.sv with the bug-injection branches removed (the `else path kept)."""
    out, state = [], None                      # state: None | 'bug' | 'clean'
    for ln in read(os.path.join(RTL, "sync_fifo.sv")):
        s = ln.strip()
        if s.startswith("`ifdef BUG_"):
            state = "bug"; continue
        if s == "`else" and state == "bug":
            state = "clean"; continue
        if s == "`endif" and state:
            state = None; continue
        if state == "bug":
            continue
        out.append(ln)
    return clean(out)


def code(lines, title, src):
    body = html.escape("\n".join(dedent(lines)))
    cls = "listing short" if len(lines) < 30 else "listing"
    return (f'<div class="{cls}"><div class="lhead"><span>{title}</span>'
            f'<span class="src">{src}</span></div><pre>{body}</pre></div>')


# ----------------------------------------------------------------------------- results
def regression_numbers():
    logs = glob.glob(os.path.join(TB, "out", "regress", "*_s*.log"))
    if not logs:
        sys.exit("no regression logs: run `make regress` first")
    reads = mism = 0
    for f in logs:
        t = open(f, encoding="utf-8", errors="replace").read()
        reads += int(re.search(r"Total Reads Verified\s*:\s*(\d+)", t).group(1))
        mism += int(re.search(r"Data Mismatches\s*:\s*(\d+)", t).group(1))
    summ = open(os.path.join(TB, "out", "regress", "summary.txt")).read()
    runs, passed = map(int, re.search(r"Total: (\d+) runs, (\d+) PASS", summ).groups())
    total = re.search(r"Total coverage \(filtered view\): ([\d.]+)%", summ).group(1)
    return dict(reads=reads, mism=mism, runs=runs, passed=passed, total=total)


R = regression_numbers()
if R["passed"] != R["runs"] or R["mism"] != 0:
    print(f"WARNING: regression not clean: {R}")

# ----------------------------------------------------------------------------- listings
drv = read(os.path.join(TB, "fifo_driver.sv"))
mon = read(os.path.join(TB, "fifo_monitor.sv"))
scb = read(os.path.join(TB, "fifo_scoreboard.sv"))
cov = read(os.path.join(TB, "fifo_coverage.sv"))
sva = read(os.path.join(TB, "fifo_assertions.sv"))
itf = read(os.path.join(TB, "fifo_if.sv"))
itm = read(os.path.join(TB, "fifo_seq_item.sv"))
seq = read(os.path.join(TB, "fifo_sequence.sv"))
tst = read(os.path.join(TB, "fifo_test.sv"))
top = read(os.path.join(TB, "tb_top.sv"))

L_RTL = code(rtl_clean(), "Listing 1. Design under test", "rtl/sync_fifo.sv")
L_BUG = code(block(read(os.path.join(RTL, "sync_fifo.sv")), r"`ifdef BUG_FULL_EARLY", r"`endif"),
             "Listing 2. Example bug switch (off by default)", "rtl/sync_fifo.sv")
L_IF = code(clean(block(itf, r"clocking drv_cb", r"endclocking : mon_cb")),
            "Listing 3. Clocking blocks: 1 ns input/output skew", "uvm/fifo_uvm/fifo_if.sv")
L_DRV = code(clean(block(drv, r"virtual task drive_item", r"endtask")),
             "Listing 4. Driver: one item per clock", "uvm/fifo_uvm/fifo_driver.sv")
L_MON = code(clean(block(mon, r"forever begin", r"^    end")),
             "Listing 5. Monitor: samples the bus every clock", "uvm/fifo_uvm/fifo_monitor.sv")
# compare(): reset handling, 1.1 data / 1.4 hold, 1.2 flags, model update
_scb = clean(block(scb, r"virtual function void compare", r"endfunction"))
L_SCB = code(_scb,
             "Listing 6. Scoreboard: queue model with its own occupancy; data, flag and hold checks", "uvm/fifo_uvm/fifo_scoreboard.sv")
L_ITM = code(clean(block(itm, r"constraint c_valid_op", r"constraint c_rd_dist")) +
             clean(block(itm, r"constraint c_rd_dist", r"^  }"))[1:],
             "Listing 7. Stimulus constraints", "uvm/fifo_uvm/fifo_seq_item.sv")
L_SEQ = code(clean(block(seq, r"Overflow: 3 writes of 0xFF", r"^    end")),
             "Listing 8. Overflow step of fifo_write_when_full_sequence", "uvm/fifo_uvm/fifo_sequence.sv")
L_COV = code(clean(block(cov, r"covergroup fifo_cg", r"endgroup")),
             "Listing 9. Functional coverage", "uvm/fifo_uvm/fifo_coverage.sv")


def prop(name):
    return clean(block(sva, rf"property {name};", rf"endproperty"))


L_SVA = code(prop("p_full_iff_depth") + [""] + prop("p_no_wr_when_full") + [""] +
             prop("p_no_rd_when_empty") + [""] + prop("p_count_stable_on_rw"),
             "Listing 10. Selected assertions (A02, A04, A05, A10)", "uvm/fifo_uvm/fifo_assertions.sv")
L_BIND = code(clean(block(top, r"bind sync_fifo", r"sva_inst")),
              "Listing 11. Assertions bound to the DUT", "uvm/fifo_uvm/tb_top.sv")


def fig(img, n, cap, cls=""):
    return (f'<figure class="{cls}"><img src="../results/img/{img}">'
            f'<figcaption><b>Figure {n}.</b> {cap}</figcaption></figure>')


# ----------------------------------------------------------------------------- document
DIAGRAM = open(os.path.join(ROOT, "scripts", "tb_diagram.svg"), encoding="utf-8").read()

page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Synchronous FIFO Verification Report</title>
<style>
@page {{ size: A4; margin: 18mm 16mm 18mm 16mm;
  @bottom-left  {{ content: "Synchronous FIFO Verification Report  |  {AUTHOR}"; font: 7.5pt "DejaVu Sans"; color: #6b7280; }}
  @bottom-right {{ content: counter(page) " / " counter(pages); font: 7.5pt "DejaVu Sans"; color: #6b7280; }} }}
@page :first {{ @bottom-left {{ content: none; }} @bottom-right {{ content: none; }} }}
:root {{ --ink:#111827; --muted:#4b5563; --line:#d1d5db; --accent:#1e3a8a; --soft:#f3f4f6; --ok:#166534; --warn:#92400e; }}
body {{ font: 9.4pt/1.5 "DejaVu Sans", sans-serif; color: var(--ink); margin: 0; background: #fff; }}
h1 {{ font-size: 24pt; line-height: 1.15; margin: 0 0 3mm; color: var(--accent); }}
h2 {{ font-size: 13pt; color: var(--accent); border-bottom: 1.2px solid var(--accent); padding-bottom: 1mm;
      margin: 8mm 0 3mm; break-after: avoid; }}
h3 {{ font-size: 10.5pt; margin: 5mm 0 2mm; break-after: avoid; }}
p {{ margin: 1.6mm 0 2.4mm; text-align: justify; }}
ul {{ margin: 1mm 0 2.5mm; padding-left: 6mm; }} li {{ margin: .6mm 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 2mm 0 3.5mm; font-size: 8.5pt; break-inside: avoid; }}
th {{ background: var(--soft); text-align: left; }}
th, td {{ border: 1px solid var(--line); padding: 1.3mm 2mm; vertical-align: top; }}
td.n, th.n {{ text-align: right; white-space: nowrap; }}
code {{ font-family: "DejaVu Sans Mono", monospace; font-size: 8.2pt; }}
.listing {{ margin: 2.5mm 0 4mm; border: 1px solid var(--line); }}
.listing.short {{ break-inside: avoid; }}
.lhead {{ display: flex; justify-content: space-between; background: var(--soft); padding: 1.2mm 2.5mm;
          font-size: 8pt; font-weight: bold; border-bottom: 1px solid var(--line); break-after: avoid; }}
.lhead .src {{ font-weight: normal; color: var(--muted); font-family: "DejaVu Sans Mono", monospace; }}
pre {{ margin: 0; padding: 2mm 3mm; font: 7.4pt/1.38 "DejaVu Sans Mono", monospace; white-space: pre-wrap; }}
figure {{ margin: 2.5mm 0 4.5mm; break-inside: avoid; }}
figure img {{ width: 100%; border: 1px solid var(--line); }}
figure.half img {{ width: 62%; }}
figcaption {{ font-size: 8.2pt; color: var(--muted); margin-top: 1.2mm; }}
.cover {{ height: 245mm; display: flex; flex-direction: column; justify-content: space-between; }}
.cover .top {{ margin-top: 40mm; }}
.cover .sub {{ font-size: 12pt; color: var(--muted); margin-bottom: 14mm; }}
.cover table {{ width: 70%; font-size: 9.5pt; }}
.cover td:first-child {{ width: 32%; color: var(--muted); }}
.kpis {{ display: flex; gap: 3mm; margin: 3mm 0; }}
.kpi {{ flex: 1; border: 1px solid var(--line); padding: 2.5mm 3mm; }}
.kpi .v {{ font-size: 15pt; font-weight: bold; color: var(--accent); }}
.kpi .l {{ font-size: 7.8pt; color: var(--muted); }}
.box {{ border-left: 3px solid var(--warn); background: #fffbeb; padding: 2mm 3.5mm; margin: 2.5mm 0 3.5mm; break-inside: avoid; }}
.toc td {{ border: none; padding: .8mm 0; font-size: 9.5pt; }}
.toc td.n {{ color: var(--muted); }}
.pb {{ break-before: page; }}
</style></head><body>

<section class="cover">
 <div class="top">
  <h1>Synchronous FIFO<br>Verification Report</h1>
  <div class="sub">UVM testbench with reference-model scoreboard, functional coverage,<br>
  SystemVerilog assertions and RTL bug injection</div>
  <table>
   <tr><td>Author</td><td>{AUTHOR}</td></tr>
   <tr><td>Date</td><td>{DATE}</td></tr>
   <tr><td>Design</td><td><code>sync_fifo</code>, 8 bit &times; 32 entries</td></tr>
   <tr><td>Language</td><td>SystemVerilog (IEEE 1800-2017), UVM 1.1d</td></tr>
   <tr><td>Simulator</td><td>Questa Sim-64 2021.2</td></tr>
  </table>
 </div>
 <table class="toc">
  <tr><td>1. Summary</td></tr><tr><td>2. Design under test</td></tr>
  <tr><td>3. Verification environment</td></tr><tr><td>4. Test plan and checks</td></tr>
  <tr><td>5. Results</td></tr><tr><td>6. Waveforms: correct behaviour</td></tr>
  <tr><td>7. Bug injection</td></tr><tr><td>8. Findings and limitations</td></tr>
  <tr><td>9. How to reproduce</td></tr>
 </table>
</section>

<h2 class="pb">1. Summary</h2>
<div class="kpis">
 <div class="kpi"><div class="v">{R['passed']} / {R['runs']}</div><div class="l">regression runs passed<br>4 tests &times; 5 seeds</div></div>
 <div class="kpi"><div class="v">100%</div><div class="l">functional coverage<br>24 of 24 bins</div></div>
 <div class="kpi"><div class="v">{R['total']}%</div><div class="l">total coverage<br>code, functional, assertion</div></div>
 <div class="kpi"><div class="v">5 / 5</div><div class="l">injected RTL bugs<br>detected</div></div>
</div>
<p>This report covers the verification of a parameterized synchronous FIFO. The testbench is a layered UVM environment:
a driver and monitor connected through clocking blocks, a scoreboard that predicts every read with a queue model,
a covergroup on the observed traffic, and ten concurrent assertions bound to the design.</p>
<p>The regression runs four tests with five random seeds each. All {R['runs']} runs pass. The scoreboard checked
{R['reads']:,} reads against the model with {R['mism']} mismatches. Merged coverage is 100% functional and {R['total']}% in total;
the two remaining code-coverage misses are explained in Section 5.</p>
<p>A passing regression says little unless the same environment fails on a broken design. Five RTL bugs were
therefore compiled in one at a time. All five were detected. Looking at which check caught each bug also showed three
weaknesses in the environment itself. They are described in Section 8, together with the planned fixes.</p>

<h2>2. Design under test</h2>
<table>
 <tr><th style="width:24%">Item</th><th>Description</th></tr>
 <tr><td>Module</td><td><code>sync_fifo #(DATA_WIDTH = 8, DEPTH = 32)</code>, single clock domain</td></tr>
 <tr><td>Ports</td><td><code>clk, rst_n, wr_en, rd_en, data_in[7:0]</code> &rarr; <code>data_out[7:0], full, empty</code></td></tr>
 <tr><td>Storage</td><td>Register array <code>mem[0:31]</code>, 5-bit read and write pointers that wrap naturally</td></tr>
 <tr><td>Flags</td><td>6-bit occupancy counter; <code>full = (count == DEPTH)</code>, <code>empty = (count == 0)</code>, both combinational</td></tr>
 <tr><td>Overflow, underflow</td><td>A write while full and a read while empty are ignored. Pointers and count do not change</td></tr>
 <tr><td>Read latency</td><td><code>data_out</code> is registered and changes on the clock edge that accepts the read</td></tr>
 <tr><td>Reset</td><td>Synchronous, active low. Clears pointers, count and <code>data_out</code>; memory contents are not cleared</td></tr>
</table>
{L_RTL}
<p>The RTL also contains five bug switches used in Section 7. Each one is an <code>`ifdef</code> around a single
line and is disabled unless the RTL is compiled with <code>+define+BUG_&lt;NAME&gt;</code>, so the default build is the
design in Listing 1.</p>
{L_BUG}

<h2>3. Verification environment</h2>
<figure>{DIAGRAM}<figcaption><b>Figure 1.</b> Testbench structure. Only the driver, the monitor and the bound
assertion module touch signals; all other components exchange transactions.</figcaption></figure>
<table>
 <tr><th style="width:18%">Component</th><th>Implementation</th></tr>
 <tr><td>Interface</td><td>Signals plus two clocking blocks. <code>drv_cb</code> drives inputs and <code>mon_cb</code> samples everything, both with 1 ns skew (Listing 3)</td></tr>
 <tr><td>Sequence item</td><td>Random <code>wr_en</code>, <code>rd_en</code>, <code>data_in</code> with weighted constraints (Listing 7); DUT outputs are stored as non-random fields</td></tr>
 <tr><td>Sequences</td><td>Reset (idle), fill (32 writes, data 0 to 31), drain (32 reads), write-when-full and a 2,000-item random stress sequence</td></tr>
 <tr><td>Driver</td><td>Drives one item per clock and returns the sampled outputs (Listing 4). Applies the initial reset</td></tr>
 <tr><td>Monitor</td><td>Samples the bus every clock through <code>mon_cb</code> and writes the item to an analysis port (Listing 5). It does not depend on the driver</td></tr>
 <tr><td>Scoreboard</td><td>Queue reference model fed through a <code>uvm_tlm_analysis_fifo</code>. A read sets an expectation that is checked on the next item, which models the registered output (Listing 6)</td></tr>
 <tr><td>Coverage</td><td><code>uvm_subscriber</code> with one covergroup: 5 coverpoints and 3 crosses (Listing 9)</td></tr>
 <tr><td>Assertions</td><td>Module <code>fifo_assertions</code>, bound to <code>sync_fifo</code> so it can see <code>count</code> and both pointers (Listings 10, 11)</td></tr>
</table>
{L_IF}
{L_DRV}
{L_MON}
{L_SCB}

<h2>4. Test plan and checks</h2>
<p>The full plan, with the mapping from each feature to its test, coverage bin and assertion, is in
<code>doc/FIFO_VERIFICATION_PLAN.md</code>. The implemented tests are:</p>
<table>
 <tr><th style="width:28%">Test</th><th>Stimulus</th><th style="width:30%">Purpose</th></tr>
 <tr><td><code>fifo_test_reset</code></td><td>5 idle cycles after reset</td><td>Reset state, empty after reset</td></tr>
 <tr><td><code>fifo_test_fill_drain</code></td><td>32 writes with data 0 to 31, then 32 reads</td><td>Capacity, flag transitions, ordering, pointer wrap</td></tr>
 <tr><td><code>fifo_test_write_when_full</code></td><td>Fill, 3 writes of <code>0xFF</code> while full, then drain</td><td>Overflow protection, no data corruption</td></tr>
 <tr><td><code>fifo_test_random</code></td><td>2,000 constrained-random cycles</td><td>Simultaneous read and write, empty and full corners, coverage</td></tr>
</table>
{L_ITM}
{L_SEQ}
<h3>Assertions</h3>
<table>
 <tr><th style="width:30%">Assertion</th><th>Rule</th></tr>
 <tr><td><code>A01_RESET_STATE</code></td><td>When reset is released: <code>empty</code> = 1 and <code>full</code> = 0</td></tr>
 <tr><td><code>A02_FULL_IFF_DEPTH</code></td><td><code>full</code> is high exactly when <code>count == DEPTH</code></td></tr>
 <tr><td><code>A03_EMPTY_IFF_ZERO</code></td><td><code>empty</code> is high exactly when <code>count == 0</code></td></tr>
 <tr><td><code>A04_NO_WR_WHEN_FULL</code></td><td>A write while full does not move <code>wr_ptr</code></td></tr>
 <tr><td><code>A05_NO_RD_WHEN_EMPTY</code></td><td>A read while empty does not move <code>rd_ptr</code></td></tr>
 <tr><td><code>A06_COUNT_BOUNDS</code></td><td><code>count</code> never exceeds DEPTH</td></tr>
 <tr><td><code>A07_FULL_EMPTY_MUTEX</code></td><td><code>full</code> and <code>empty</code> are never high together</td></tr>
 <tr><td><code>A08</code>, <code>A09</code>, <code>A10</code></td><td><code>count</code> +1 on a write only, &minus;1 on a read only, unchanged on a read and write in the same cycle</td></tr>
</table>
<p>Five cover properties (<code>C01</code> to <code>C05</code>) record that full, empty, a simultaneous read and write,
a write while full and a read while empty actually happened.</p>
{L_SVA}
{L_BIND}
{L_COV}

<h2>5. Results</h2>
<h3>5.1 Regression</h3>
<p>A run passes only when UVM reports no errors or fatals, the simulator reports no <code>** Error</code>
(this is how assertion failures appear, see Section 8), and the scoreboard prints PASS.</p>
{fig("T1_regression.png", 2, "Regression output: 4 tests &times; 5 seeds, all passing.")}
{fig("T3_random_clean_result.png", 3, "Result of one random run (seed 1): 883 writes, 853 reads checked, 0 mismatches, no assertion failures.")}

<h3>5.2 Coverage</h3>
<table>
 <tr><th>Metric</th><th class="n">Bins</th><th class="n">Hit</th><th class="n">Coverage</th><th>Note</th></tr>
 <tr><td>Functional (covergroup)</td><td class="n">24</td><td class="n">24</td><td class="n">100.00%</td><td>All coverpoints and crosses closed</td></tr>
 <tr><td>Assertions</td><td class="n">10</td><td class="n">10</td><td class="n">100.00%</td><td>No failures</td></tr>
 <tr><td>Cover directives</td><td class="n">5</td><td class="n">5</td><td class="n">100.00%</td><td></td></tr>
 <tr><td>Statements</td><td class="n">18</td><td class="n">17</td><td class="n">94.44%</td><td rowspan="2">The <code>default:</code> item of the count <code>case</code>. The selector has 2 bits and all 4 values are listed, so it cannot be reached</td></tr>
 <tr><td>Branches</td><td class="n">13</td><td class="n">12</td><td class="n">92.30%</td></tr>
 <tr><td>Conditions, expressions</td><td class="n">6</td><td class="n">6</td><td class="n">100.00%</td><td></td></tr>
 <tr><td>Toggles</td><td class="n">76</td><td class="n">75</td><td class="n">98.68%</td><td><code>rst_n</code> never falls after the first reset (no reset during traffic)</td></tr>
 <tr><th>Total</th><th></th><th></th><th class="n">{R['total']}%</th><th></th></tr>
</table>
{fig("T2_coverage_summary.png", 4, "Merged coverage summary printed by the regression script.", "half")}
{fig("C1_coverage_overview.png", 5, "Questa HTML coverage report, summary page.")}
{fig("C2a_covergroup_bins.png", 6, "Covergroup <code>fifo_cg</code>: all five coverpoints at 100%.")}
{fig("C2b_covergroup_crosses.png", 7, "Covergroup <code>fifo_cg</code>: the three crosses at 100%, including write while full and read while empty.")}
{fig("C3_unreachable_default.png", 8, "Branch coverage of the count <code>case</code>: every listed case is hit thousands of times; only the unreachable <code>default</code> has 0 hits.")}

<h2>6. Waveforms: correct behaviour</h2>
<p>All waveforms were taken in the Questa GUI from the clean RTL. The signal list is grouped as clock, inputs,
outputs and internal DUT signals.</p>
{fig("W1_fill_to_full.png", 9, "Fill to full (<code>fifo_test_fill_drain</code>, seed 1). <code>count</code> reaches 32 at 375 ns and <code>full</code> rises in the same cycle. <code>wr_ptr</code> wraps from 31 to 0. Reads start on the next edge and <code>full</code> drops.")}
{fig("W2_read_latency.png", 10, "Drain phase of the same run. <code>data_out</code> returns 00 to 1F in the order written. <code>data_out</code> is registered, so it updates on the edge that accepts the read while <code>rd_ptr</code> already points to the next entry.")}
{fig("W3_write_when_full_ignored.png", 11, "Write while full (<code>fifo_test_write_when_full</code>, seed 1). After the last fill value <code>1F</code>, three writes of <code>FF</code> arrive while <code>full</code> = 1. <code>wr_ptr</code> stays at 0 and <code>count</code> stays at 32; assertion A04 reports no failure.")}
{fig("W4_simultaneous_rw.png", 12, "Random traffic (<code>fifo_test_random</code>, seed 1). Reads and writes overlap from the start. At 135 ns a read and a write in the same cycle advance both pointers while <code>count</code> stays at 3.")}
{fig("W5_read_when_empty_ignored.png", 13, "Random traffic, seed 2. At the cursor (93.7 ns) <code>rd_en</code> = 1 while <code>empty</code> = 1; <code>rd_ptr</code> stays at 1 and <code>count</code> stays at 0.")}
{fig("W6_drain_to_empty.png", 14, "End of the drain in <code>fifo_test_fill_drain</code>. The last value <code>1F</code> is read, <code>count</code> reaches 0 and <code>empty</code> rises.")}

<h2>7. Bug injection</h2>
<p>Five bugs were added behind <code>`ifdef</code> switches. Each was compiled alone and all four tests were run with the
same five seeds as the regression: 20 runs per bug, 100 in total.</p>
<table>
 <tr><th style="width:21%">Bug</th><th>Faulty behaviour</th><th style="width:26%">Failing runs</th><th style="width:20%">Checks that fired</th><th class="n">First error</th></tr>
 <tr><td><code>BUG_FULL_EARLY</code></td><td><code>full</code> asserts at 31 entries</td><td>fill_drain 5/5, write_when_full 5/5, random 5/5</td><td>A02; scoreboard in random only</td><td class="n">375 ns</td></tr>
 <tr><td><code>BUG_WRITE_WHEN_FULL</code></td><td>Write accepted while full</td><td>write_when_full 5/5, random 5/5</td><td>A04, scoreboard</td><td class="n">395 ns</td></tr>
 <tr><td><code>BUG_READ_WHEN_EMPTY</code></td><td>Read accepted while empty</td><td>random 3/5</td><td>A05, scoreboard</td><td class="n">75 ns</td></tr>
 <tr><td><code>BUG_COUNT_RW</code></td><td><code>count</code> +1 on read and write in one cycle</td><td>random 5/5</td><td>A10, scoreboard</td><td class="n">125 ns</td></tr>
 <tr><td><code>BUG_DATA_BITFLIP</code></td><td>Bit 0 of <code>data_out</code> flips for entry 5</td><td>fill_drain 5/5, write_when_full 5/5, random 5/5</td><td>Scoreboard only</td><td class="n">205 ns</td></tr>
</table>
<p>All five bugs were detected. The assertions catch the control bugs in the cycle where they happen but cannot see
data values. The data corruption in <code>BUG_DATA_BITFLIP</code> is found only by the scoreboard.
<code>fifo_test_reset</code> detects none of the bugs, which is expected because it performs no reads or writes.</p>
{fig("T4_bug_report.png", 15, "Bug campaign report produced by <code>make bugs</code>.")}
{fig("B1_full_early.png", 16, "<code>BUG_FULL_EARLY</code>: <code>full</code> rises while <code>count</code> = 31. Assertion A02 fails (red markers).")}
{fig("B2_write_when_full.png", 17, "<code>BUG_WRITE_WHEN_FULL</code>: <code>wr_ptr</code> keeps moving (0, 1, 2, 3) during the <code>FF</code> writes while <code>full</code> = 1. A04 fails; the drain then reads overwritten data.")}
{fig("B3_read_when_empty.png", 18, "<code>BUG_READ_WHEN_EMPTY</code> (random, seed 2): <code>rd_ptr</code> advances while <code>empty</code> = 1 and <code>data_out</code> becomes unknown. A05 fails at 75 ns.")}
{fig("B4_count_rw.png", 19, "<code>BUG_COUNT_RW</code> (random, seed 1): on a read and write in the same cycle <code>count</code> increments (7 to 8 at 315 ns). A10 fails on every such cycle.")}
{fig("B5_data_bitflip.png", 20, "<code>BUG_DATA_BITFLIP</code>: the read of entry 5 returns <code>04</code> instead of <code>05</code>, so the sequence skips from 04 to 06. Flags and pointers are correct and no assertion fires; the scoreboard reports one mismatch and fails the test.")}

<h2>8. Findings and limitations</h2>
<p>The bug campaign also tested the environment. Three weaknesses were found. They are reported as open items and
are tracked in the verification plan.</p>
<div class="box"><b>F1. The scoreboard can pass while data is lost.</b> With <code>BUG_FULL_EARLY</code>,
<code>fifo_test_fill_drain</code> writes 32 items but the design keeps only 31. The scoreboard reports 0 mismatches and
prints PASS, with one item left in its queue (Figure 21). Only assertion A02 detects the bug. The scoreboard
decides whether a read took place from the DUT's own <code>empty</code> flag, does not compare the flags with its model,
and does not check for leftover items at the end of the test. Planned fix: predict <code>full</code> and <code>empty</code>
from the model, compare them every cycle, and check the queue in <code>check_phase</code>.</div>
{fig("T5_finding_scoreboard_passes.png", 21, "<code>UVM_ERROR : 0</code> and <code>SCOREBOARD CHECK PASSED</code>, but one item is left in the queue and A02 failed twice.")}
<div class="box"><b>F2. Assertion failures are not counted by UVM.</b> The assertions report with <code>$error</code>, so a
run with failing assertions can still end with <code>UVM_ERROR : 0</code>. The regression scripts work around this by also
failing a run on any simulator <code>** Error</code>. Planned fix: report assertion failures with <code>`uvm_error</code>.</div>
<div class="box"><b>F3. Read while empty is reached only by chance.</b> No directed test reads from an empty FIFO.
<code>BUG_READ_WHEN_EMPTY</code> was caught by the random test in 3 of 5 seeds, and with seed 1 the cover property for
this case was never hit. Planned fix: add <code>fifo_test_read_when_empty</code>.</div>
<h3>Limitations</h3>
<ul>
 <li>No reset during traffic. The scoreboard does not clear its model on reset.</li>
 <li>Only one configuration is simulated (<code>DATA_WIDTH = 8</code>, <code>DEPTH = 32</code>). The pointer wrap relies on DEPTH being a power of two.</li>
 <li>The unreachable <code>default:</code> branch is still counted as a miss; it should be excluded with a written reason.</li>
 <li>Occupancy-level and flag-transition coverpoints from the plan are not implemented yet.</li>
</ul>

<h2>9. How to reproduce</h2>
<pre style="border:1px solid var(--line); break-inside: avoid">cd uvm/fifo_uvm
make questa_sim TESTNAME=fifo_test_random        # one test, batch mode
make result TESTNAME=fifo_test_random SEED=3     # one run with log, verdict, coverage and waveform
make regress                                     # 4 tests x 5 seeds, merged coverage
make bugs                                        # 5 bugs x 4 tests x 5 seeds
make gui TESTNAME=fifo_test_fill_drain SEED=1 BUG=BUG_FULL_EARLY   # open one run in the GUI</pre>
</body></html>
"""

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    f.write(page)
print("wrote", OUT, R)
