#!/usr/bin/env bash
# =============================================================================
# run_one.sh: run ONE test with ONE seed and collect a complete result set.
#
# Usage (from uvm/fifo_uvm):
#   make result TESTNAME=fifo_test_random SEED=3 [BUG=BUG_COUNT_RW]
#
# Output folder: uvm/fifo_uvm/out/runs/<test>_s<seed>[_<bug>]/
#   run_info.txt   test, seed, bug define, date, tool version, PASS/FAIL + reason
#   result.txt     UVM report counts, scoreboard summary, SVA failures, first error
#   run.log        full simulator transcript
#   cov.ucdb       coverage database of this run
#   coverage.txt   coverage summary (code + covergroup + assertions)
#   dump.vcd       waveform (all of tb_top)
# =============================================================================
set -u
cd "$(dirname "$0")/../fifo_uvm"

T="${TESTNAME:-fifo_test_random}"
S="${SEED:-1}"
B="${BUG:-}"
TAG="${T}_s${S}${B:+_$B}"
D="out/runs/$TAG"
LIB="work_run"

rm -rf "$D" "$LIB" && mkdir -p "$D"
vlib "$LIB" > /dev/null
{
  vlog -work "$LIB" -sv fifo_if.sv fifo_pkg.sv                                   &&
  vlog -work "$LIB" -sv +cover=bcesft ${B:++define+$B} ../../rtl/sync_fifo.sv       &&
  vlog -work "$LIB" -sv fifo_assertions.sv tb_top.sv
} > "$D/compile.log" 2>&1 || {
  echo "COMPILE FAILED: $D/compile.log"
  grep -A1 -m3 "\*\* Error" "$D/compile.log"
  exit 1
}

vsim -c -lib "$LIB" tb_top -coverage -sv_seed "$S" +UVM_TESTNAME="$T" \
     -do "coverage save -onexit $D/cov.ucdb; run -all; quit -f" > "$D/run.log" 2>&1
[ -f dump.vcd ] && mv dump.vcd "$D/dump.vcd"

# ---- verdict ---------------------------------------------------------------
r=""
grep -qE "UVM_ERROR :\s+0$" "$D/run.log"        || r+="uvm_error "
grep -qE "UVM_FATAL :\s+0$" "$D/run.log"        || r+="uvm_fatal "
grep -qE "^# \*\* Error" "$D/run.log"           && r+="sva/sim_error "
grep -q  "SCOREBOARD CHECK PASSED" "$D/run.log" || r+="scoreboard "
VERDICT=$([ -z "$r" ] && echo PASS || echo "FAIL (${r% })")

{
  echo "test     : $T"
  echo "seed     : $S"
  echo "bug      : ${B:-none (clean RTL)}"
  echo "date     : $(date '+%F %T')"
  echo "tool     : $(vsim -version 2>/dev/null | head -1)"
  echo "verdict  : $VERDICT"
} > "$D/run_info.txt"

{
  echo "== UVM report counts =="
  grep -E "^# UVM_(INFO|WARNING|ERROR|FATAL) :" "$D/run.log"
  echo; echo "== Scoreboard summary =="
  grep -E "Configured DEPTH|Total Writes|Total Reads|Data Matches|Data Mismatches|Flag Mismatches|Hold Mismatches|Unread Items|Reset cycles|SCOREBOARD CHECK" "$D/run.log" \
    | sed 's/.*\] *//'
  echo; echo "== SVA failures (assertion: count) =="
  grep -oE "Scope: [^ ]*sva_inst\.[A-Z0-9_]+" "$D/run.log" | sed 's/.*sva_inst\.//' | sort | uniq -c \
    | awk '{print $2": "$1}' | grep . || echo "none"
  echo; echo "== First 5 errors =="
  grep -m5 -A1 -E "^# \*\* Error|^# UVM_ERROR .*@" "$D/run.log" || echo "none"
  echo; echo "== End of simulation =="
  grep -E "^#\s+Time: .*Instance: /tb_top" "$D/run.log" | tail -1
} > "$D/result.txt"

vcover report -summary "$D/cov.ucdb" 2>/dev/null | sed -n '/Enabled Coverage/,/Total coverage/p' > "$D/coverage.txt"
echo >> "$D/coverage.txt"
vcover report -details -cvg "$D/cov.ucdb" 2>/dev/null | grep -E "Coverpoint|Cross" | sort -u >> "$D/coverage.txt"

rm -rf "$LIB"
echo "$VERDICT  ->  $D"
cat "$D/run_info.txt"
