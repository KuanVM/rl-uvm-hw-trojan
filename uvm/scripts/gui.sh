#!/usr/bin/env bash
# =============================================================================
# gui.sh: open ONE test in the Questa GUI, with every signal logged so any
# signal can be added to the Wave window after the run.
#
# Usage (from uvm/fifo_uvm):
#   make gui TESTNAME=fifo_test_fill_drain SEED=1 [BUG=BUG_FULL_EARLY] [WAVE=../doc/waves/W1.do]
#
# - Compiles into its own library (work_gui), so it never touches "work".
# - -assertdebug lets you add SVA assertions to the Wave window (pass/fail markers).
# - -onfinish stop keeps the GUI open when UVM calls $finish.
# - If WAVE is given, that saved wave layout (.do) is loaded after the run.
# =============================================================================
set -u
cd "$(dirname "$0")/../fifo_uvm"

T="${TESTNAME:-fifo_test_random}"
S="${SEED:-1}"
B="${BUG:-}"
W="${WAVE:-}"
LIB=work_gui_${TESTNAME:-x}_${SEED:-1}${BUG:+_$BUG}

rm -rf "$LIB" && vlib "$LIB" > /dev/null
{
  vlog -work "$LIB" -sv fifo_if.sv fifo_pkg.sv                            &&
  vlog -work "$LIB" -sv +cover=bcesft ${B:++define+$B} ../../rtl/sync_fifo.sv &&
  vlog -work "$LIB" -sv fifo_assertions.sv tb_top.sv
} > gui_compile.log 2>&1 || { echo "COMPILE FAILED, see uvm/fifo_uvm/gui_compile.log"; grep -m3 "Error" gui_compile.log; exit 1; }

DO="log -r /*; run -all"
[ -n "$W" ] && DO="$DO; do $W"

# Each session writes its own waveform database, so several GUIs can be open at
# once without fighting over a shared vsim.wlf ("Cannot lock WLF file").
TAG="${T}_s${S}${B:+_$B}"
mkdir -p out/gui
WLF="out/gui/$TAG.wlf"

echo "Opening GUI: test=$T seed=$S bug=${B:-none}  (waves: uvm/fifo_uvm/$WLF)"
vsim -voptargs=+acc -assertdebug -onfinish stop -coverage -lib "$LIB" tb_top \
     -wlf "$WLF" -sv_seed "$S" +UVM_TESTNAME="$T" -do "$DO"
