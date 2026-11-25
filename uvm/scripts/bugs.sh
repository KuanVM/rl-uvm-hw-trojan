#!/usr/bin/env bash
# =============================================================================
# bugs.sh: check that the environment catches injected RTL bugs.
#
# Usage (from uvm/fifo_uvm):   make bugs  [BUGS="BUG_FULL_EARLY ..."] [SEEDS="1 2 3"]
#
# For each bug: recompile the DUT with +define+<BUG>, run every test with every
# seed (same seeds as the regression), and record which checks fired.
# A bug counts as DETECTED if at least one run fails. A bug that no run detects
# is a hole in the testbench. "n/N seeds" shows how reliably a test catches it.
#
# Outputs (in uvm/fifo_uvm/out/bugs/):
#   <bug>/<test>_s<seed>.log   per-run logs
#   bug_report.txt             detection table (copy to uvm/doc/results/)
# =============================================================================
set -u
cd "$(dirname "$0")/../fifo_uvm"

BUGS="${BUGS:-BUG_FULL_EARLY BUG_WRITE_WHEN_FULL BUG_READ_WHEN_EMPTY BUG_COUNT_RW BUG_DATA_BITFLIP}"
TESTS="${TESTS:-fifo_test_reset fifo_test_fill_drain fifo_test_write_when_full fifo_test_random}"
SEEDS="${SEEDS:-1 2 3 4 5}"
OUT=out/bugs
rm -rf "$OUT" && mkdir -p "$OUT"
NSEEDS=$(echo $SEEDS | wc -w)

run_failed() {   # $1 = log ; returns 0 if the run FAILED
  ! { grep -qE "UVM_ERROR :\s+0$" "$1" && grep -qE "UVM_FATAL :\s+0$" "$1" &&
      ! grep -qE "^# \*\* Error" "$1" && grep -q "SCOREBOARD CHECK PASSED" "$1"; }
}
# Which checks fired: SVA assertion names + scoreboard error ids
checks_fired() {
  local f=$1
  grep -oE "Scope: [^ ]*sva_inst\.[A-Z0-9_]+" "$f" | sed 's/.*sva_inst\.//'
  grep -q  "FIFO_DATA_OUT_CHK\] FAIL" "$f"  && echo "SCB_DATA"
  grep -q  "FIFO_FLAG_CHK\] FAIL" "$f"      && echo "SCB_FLAG"
  grep -q  "FIFO_DOUT_HOLD_CHK\] FAIL" "$f" && echo "SCB_HOLD"
  grep -qE "UVM_FATAL :\s+[1-9]" "$f" && echo "UVM_FATAL"
}
# Time of the first error in ns (SVA prints "Time: N ns", UVM prints "@ N" in ps)
first_error_ns() {
  local sva uvm
  sva=$(grep -m1 -A1 "^# \*\* Error" "$1" | grep -oE "Time: [0-9]+ ns" | grep -oE "[0-9]+")
  uvm=$(grep -m1 -E "^# UVM_ERROR .*@ [0-9]+" "$1" | grep -oE "@ [0-9]+" | grep -oE "[0-9]+")
  [ -n "$uvm" ] && uvm=$((uvm / 1000))
  if   [ -n "$sva" ] && [ -n "$uvm" ]; then echo $(( sva < uvm ? sva : uvm ))
  elif [ -n "$sva" ]; then echo "$sva"
  elif [ -n "$uvm" ]; then echo "$uvm"
  fi
}

REPORT="$OUT/bug_report.txt"
{
  echo "Bug injection report: sync_fifo ($(date +%F), seeds: $SEEDS)"
  echo "A run FAILS if UVM_ERROR/UVM_FATAL > 0, any '** Error' (SVA), or no scoreboard PASS."
  echo "FIRST_ERR = earliest error time (ns) over the failing seeds."
  echo
} > "$REPORT"

for b in $BUGS; do
  LIB=work_$b
  mkdir -p "$OUT/$b"; rm -rf "$LIB"; vlib "$LIB" > /dev/null
  if ! { vlog -work "$LIB" -sv fifo_if.sv fifo_pkg.sv &&
         vlog -work "$LIB" -sv +define+"$b" ../../rtl/sync_fifo.sv &&
         vlog -work "$LIB" -sv fifo_assertions.sv tb_top.sv; } > "$OUT/$b/compile.log" 2>&1; then
    echo "$b: COMPILE FAILED" | tee -a "$REPORT"; continue
  fi
  detected=0
  echo "=== $b ===" | tee -a "$REPORT"
  printf "  %-28s %-16s %-10s %s\n" "TEST" "FAILED" "FIRST_ERR" "CHECKS FIRED" | tee -a "$REPORT"
  for t in $TESTS; do
    nfail=0; first=""; checks=""
    for s in $SEEDS; do
      log="$OUT/$b/${t}_s${s}.log"
      vsim -c -lib "$LIB" tb_top -sv_seed "$s" +UVM_TESTNAME="$t" \
           -do "run -all; quit -f" > "$log" 2>&1
      if run_failed "$log"; then
        nfail=$((nfail+1)); detected=1
        tt=$(first_error_ns "$log")
        [ -n "$tt" ] && { [ -z "$first" ] || [ "$tt" -lt "$first" ]; } && first=$tt
        checks+="$(checks_fired "$log")"$'\n'
      fi
    done
    printf "  %-28s %-16s %-10s %s\n" "$t" "$nfail/$NSEEDS seeds" "${first:+$first ns}" \
      "$(echo "$checks" | grep -v '^$' | sort -u | tr '\n' ' ')" | tee -a "$REPORT"
  done
  [ $detected -eq 1 ] && echo "  => DETECTED" | tee -a "$REPORT" \
                      || echo "  => NOT DETECTED (testbench hole)" | tee -a "$REPORT"
  echo | tee -a "$REPORT"
  rm -rf "$LIB"
done
