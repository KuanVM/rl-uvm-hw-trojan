#!/usr/bin/env bash
# =============================================================================
# regress.sh: run every test with several seeds, collect and merge coverage.
#
# Usage (from uvm/fifo_uvm):   make regress  [SEEDS="1 2 3 4 5"]
#
# A run PASSES only if ALL of these hold in its log:
#   - UVM_ERROR = 0 and UVM_FATAL = 0
#   - no Questa "** Error" line   (SVA failures use $error, which UVM does not count)
#   - the scoreboard printed "SCOREBOARD CHECK PASSED"
#
# Outputs (in uvm/fifo_uvm/out/regress/):
#   <test>_s<seed>.log / .ucdb   per-run log and coverage database
#   merged.ucdb                  all runs merged
#   summary.txt                  PASS/FAIL table + coverage summary
# HTML coverage report: uvm/fifo_uvm/covhtmlreport/index.html
# =============================================================================
set -u
cd "$(dirname "$0")/../fifo_uvm"

TESTS="${TESTS:-fifo_test_reset fifo_test_fill_drain fifo_test_write_when_full fifo_test_random}"
SEEDS="${SEEDS:-1 2 3 4 5}"
LIB=work_reg
OUT=out/regress

rm -rf "$LIB" "$OUT" && mkdir -p "$OUT"
vlib "$LIB" > /dev/null

echo "== Compile (coverage on DUT) =="
{
  vlog -work "$LIB" -sv fifo_if.sv fifo_pkg.sv                         &&
  vlog -work "$LIB" -sv +cover=bcesft ../../rtl/sync_fifo.sv              &&
  vlog -work "$LIB" -sv fifo_assertions.sv tb_top.sv
} > "$OUT/compile.log" 2>&1 || { echo "COMPILE FAILED, see $OUT/compile.log"; grep -A1 -m3 "\*\* Error" "$OUT/compile.log"; exit 1; }

check_log() {   # $1 = log file ; prints PASS or FAIL(<reason>)
  local f=$1 r=""
  grep -qE "UVM_ERROR :\s+0$" "$f"        || r+="uvm_error "
  grep -qE "UVM_FATAL :\s+0$" "$f"        || r+="uvm_fatal "
  grep -qE "^# \*\* Error" "$f"           && r+="sva/sim_error "
  grep -q  "SCOREBOARD CHECK PASSED" "$f" || r+="scoreboard "
  [ -z "$r" ] && echo "PASS" || echo "FAIL(${r% })"
}

pass=0; fail=0
printf "\n%-28s %-6s %s\n" "TEST" "SEED" "RESULT" | tee "$OUT/summary.txt"
printf "%-28s %-6s %s\n"   "----" "----" "------" | tee -a "$OUT/summary.txt"
for t in $TESTS; do
  for s in $SEEDS; do
    tag="${t}_s${s}"
    vsim -c -lib "$LIB" tb_top -coverage -sv_seed "$s" +UVM_TESTNAME="$t" \
         -do "coverage save -onexit $OUT/$tag.ucdb; run -all; quit -f" \
         > "$OUT/$tag.log" 2>&1
    res=$(check_log "$OUT/$tag.log")
    [ "$res" = "PASS" ] && pass=$((pass+1)) || fail=$((fail+1))
    printf "%-28s %-6s %s\n" "$t" "$s" "$res" | tee -a "$OUT/summary.txt"
  done
done
printf "\nTotal: %d runs, %d PASS, %d FAIL\n" $((pass+fail)) $pass $fail | tee -a "$OUT/summary.txt"

echo -e "\n== Merge coverage =="
vcover merge "$OUT/merged.ucdb" "$OUT"/*_s*.ucdb > "$OUT/merge.log" 2>&1
{
  echo -e "\n== Coverage summary (merged) =="
  vcover report -summary "$OUT/merged.ucdb"
} | tee -a "$OUT/summary.txt"
vcover report -details -cvg "$OUT/merged.ucdb"            > "$OUT/coverage_cvg.txt"    2>&1
vcover report -details -assert -directive "$OUT/merged.ucdb" > "$OUT/coverage_assert.txt" 2>&1
vcover report -details -code bcefst "$OUT/merged.ucdb"    > "$OUT/coverage_code.txt"   2>&1
rm -rf covhtmlreport
vcover report -html -output covhtmlreport -details -assert -directive -cvg -code bcefst \
       "$OUT/merged.ucdb" > "$OUT/html.log" 2>&1

[ $fail -eq 0 ]
