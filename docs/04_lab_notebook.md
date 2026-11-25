# Lab Notebook: RL-UVM Hardware Trojan Study

> **Project:** RL-guided UVM for rare-trigger Hardware Trojan activation and detection  
> **Current phase:** Pre-registration (G0) and benchmark preparation  
> **Notebook owner:** `[Name]`  
> **Repository:** `[URL/path]`  
> **Rule:** Record facts, commands, versions and decisions. Do not overwrite old observations; append corrections with dates.

## Change log (Lịch sử thay đổi) — newest first

| Date | Change |
|---|---|
| 2026-11-25 | §1 rewritten as one tracklist (testbench / plan and decisions / RL loop / Trojans) with due dates from the weekly plan. Scoreboard replaced by the PR #1 model (v1.2). ISSUE-009 and ISSUE-010 resolved (leftover-item check still open as FIFO plan O1). §1 updated; daily-log entry 2026-11-25. Weekly plan: `notes/week_2026-11-25_plan.md`. |
| 2026-11-16 | Handwritten UVM testbench (`tb_top`, `fifo_assertions`, 4 tests) merged with the RL loop; FIFO plan v1.1 + results in `uvm/doc/`. ISSUE-008 resolved for `tb_top`; ISSUE-009 added (scoreboard flag/hold checks). Later the same day: §0 filled; §1 status table re-checked against the code; ISSUE-010…ISSUE-014 added; EXP-001 marked done and EXP-001b added; daily-log entry 2026-11-16. |
| 2026-10-26 | Updated §1 study status after PR #1 merge. ISSUE-001/002 marked resolved; added ISSUE-008 (SVA not bound). |
| 2026-10-24 | Added daily-log entry "RL loop infrastructure validated on Windows / Questa 2024.1" (pseudo-target RB-01; not a research result). |
| 2026-09-25 | Scope renamed from FIFO-only to multi-DUT study. Added daily-log entry for the advisor review. Filled decision register DEC-001…DEC-013 and issue register ISSUE-001…ISSUE-007. Added sections H (pre-registration record), I (knowledge-exposure log) and J (advisor review record). Updated the experiment registry and work packages. Templates kept unchanged. |
| — | Initial template (FIFO baseline). |

---

## 0. Project identity and reproducibility record

| Field | Value |
|---|---|
| Project ID | `[e.g., RL-UVM-HT-2026]` |
| Main branch / commit | `main` @ `947a871` (2026-11-16, after PR #2) |
| Simulator / version | Questa 2021.2_1 on Linux (handwritten regression, bug injection); Questa 2024.1 on Windows (RL runs of 2026-10-24). Two versions in use: see ISSUE-013 |
| UVM version | UVM 1.1d (built into both Questa versions) |
| OS and host | `[OS, CPU, RAM]` |
| Python / RL environment | `[N/A until G2]` |
| DUTs | FIFO (MVP host); Tier-A hosts after screening; Tier-B generated Trojans |
| FIFO parameters | 8-bit × 32, synchronous active-low reset |
| Clean FIFO RTL path | `rtl/sync_fifo_clean.sv` (RL flow); `rtl/sync_fifo.sv` = same RTL + 5 `ifdef BUG_*` switches, all off by default (handwritten flow) |
| Protocol version | `03_experiment_protocol.md` v0.2 `[hash]` |
| Scope version | `01_scope_threat_model.md` v0.2 `[hash]` |
| Dataset / results location | Handwritten testbench: `uvm/doc/results/`, `uvm/doc/report/` (tracked). RL loop: `results/rl/` (local, not tracked) |
| Blue owner / Red owner | `[name]` / `[name]` |

## 1. Current study status

**As of 2026-11-25.** `main` @ `947a871`; scoreboard change (v1.2) done locally, not yet committed. Task IDs W-xx, D-xx, RL-xx refer to `notes/week_2026-11-25_plan.md`. Owner "Đức (proposed)" means not yet agreed with Đức.

### 1.1 Testbench (FIFO)

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| Clean FIFO RTL | | Done | | `rtl/sync_fifo_clean.sv`; bug-switch copy `rtl/sync_fifo.sv` |
| `fifo_if.sv` compiles cleanly | Blue | Done (ISSUE-001, ISSUE-002) | | `uvm/fifo_uvm/fifo_if.sv` |
| Handwritten UVM testbench (`tb_top`, agent, scoreboard, coverage, SVA A01–A10, 4 tests) | Quân | Done 2026-11-05; re-run 2026-11-16 and 2026-11-25: 20/20 PASS, functional cov 100 %, total 98.17 % | | FIFO plan §9; `uvm/doc/results/regression_summary.txt` |
| Bug-injection validation (5 RTL bugs × 4 tests × 5 seeds) | Quân | Done; 5/5 detected; re-run 2026-11-25 with the v1.2 scoreboard | | `uvm/doc/results/bug_report.txt` |
| Scoreboard v1.2: PR #1 model (own occupancy; data, flag, hold checks; reset) | Quân | Done locally 2026-11-25 (ISSUE-009, ISSUE-010 resolved); **not committed** | | FIFO plan §3.2, §9.3; §A 2026-11-25 |
| `rtl/sync_fifo_clean.sv` local module rename (`sync_fifo` → `sync_fifo_clean`) breaks the RL flow if committed alone | Quân | **Open: decide** (W-03) | 2026-11-25 | `git diff rtl/` |
| PR for scoreboard v1.2 + docs; inform Đức (`fifo_rl_test.sv` changed) | Quân | Not started (W-04), after W-03 | 2026-11-26 | |
| Untrack build artifacts (27 files: `work/`, `transcript`, `vsim.wlf`, `fifo_dump.vcd`, `modelsim.ini`) | Quân | Not started (W-05, RL-00) | 2026-11-30 | |
| One top for both flows; RL loop runs with SVA (ISSUE-014) | Quân + Đức (proposed) | Not started (W-06) | 2026-12-01 | |
| SVA labelled interface-only (BB) vs internal (GB) (ISSUE-011, O9) | Quân | Not started (W-07) | 2026-12-01 | Scope §7 |
| Directed read-when-empty test T07 (O3; `BUG_READ_WHEN_EMPTY` only 3/5) | Quân | Not started (W-08) | 2026-12-01 | FIFO plan §9.3 |
| SVA failures counted by UVM; `det_sva` column in RL CSV (O2) | Quân + Đức (proposed) | Not started (W-09) | 2026-12-02 | |
| Leftover items at end of test fail the run (O1 remainder) | Quân | Open | | FIFO plan §9.4 |
| Other testbench open items: O4 occupancy/transition coverage, O5 `default:` waiver, O6 second DEPTH, O7 mid-test reset test | Quân | Open | | FIFO plan §9.4 |
| End-of-test objection issue (total 1999 instead of 2000) | Quân | Old testbench replaced; re-check on the new one | | §A 2026-10-24 |

### 1.2 Plan, documents and decisions

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| Study the project and RL basics (`notes/00_doc_truoc_tien.md`, `rl_study_guide.md` Module 1–4, Sutton & Barto ch. 2) | Quân | Not started | 2026-11-28 | Weekly plan 26–28/11 |
| Four open decisions: meaning of "RL-written UVM"; role of the handwritten suite (baseline B-H?); handwritten suites for FIFO only or all DUTs; who is Red | Quân → team + advisor | Open; answers due | 2026-11-28 | `notes/00_doc_truoc_tien.md` §7 |
| Revise `docs/01` (RQs, §10 baselines) and `docs/03` (§8, §19) after the decisions | Quân | Blocked by the four decisions (D-01) | 2026-12-03 | |
| Record the decisions as DEC-014…DEC-017 | Quân | Blocked (D-02) | 2026-12-03 | §C1 |
| Tag the handwritten suite as a G0 artifact (`prereg/fifo/handwritten-suite`) | Quân | Blocked by decision 2 + advisor (D-03) | | |
| One FIFO plan of record: merge old §0, §3.7, §3.8, §4.5 (`89ae1f3`) into the FIFO plan v1.3 (ISSUE-012) | Quân | Not started (W-10) | 2026-12-02 | |
| FIFO spec decisions + reference-model rules | Quân | Rules implemented in scoreboard v1.2; still to be written into plan v1.3 (ISSUE-003, W-10) | 2026-12-02 | old plan `89ae1f3` §3.8 |
| Assign Blue / Red owners | Team + advisor | Open (D-05, DEC-008) | 2026-12-04 | |
| Advisor confirmation of DEC-003…DEC-013 | Team | Open | | §C1 |
| FIFO pre-registration G0 (coverage, rare-bins, detectors, knobs, π₀, c / ε, B, N) | Quân + Đức | Not started; draft `docs/prereg/fifo_g0_draft.md` planned | 2026-12-05 (draft start) | §H |
| Literature reading queue | | In progress | | Lit review §10.2 |

### 1.3 RL loop

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| RL loop infrastructure (knobs, knob seq, bandit, RL observer, CSV logger) | Đức | Done (PR #1); ported 2026-11-16 (PR #2); 2026-11-25 `det_sb_flag`/`det_sb_hold` filled again | | §A 2026-10-24, 2026-11-16, 2026-11-25 |
| RB-01 matrix re-run on one machine (Linux 2021.2) and one π₀; per-seed stats in `rl_summary.py` (ISSUE-013) | Đức (proposed) | Not started (RL-06); results of 2026-10-24 not comparable | 2026-12-04 | §A 2026-10-24 |
| Reward v0.2 (ΔC, ΔR, D, Cost), novelty reward, rare-bin DRAFT | Đức (proposed) | Not started (RL-01/02/03), after W-09 and W-10 | | Weekly plan §3.3 |
| Hyperparameter sweep on pseudo-targets; compute measurement; fix N, B | Đức (proposed) | Not started (RL-04/05/09) | | |
| CSV traceability columns (`git_commit`, `simulator_version`, reward components) | Đức (proposed) | Not started (RL-08) | | Protocol §11 |
| Design note M1/M2; action space choice | Đức (proposed) | Not started (RL-10/12) | | |

### 1.4 Trojans and campaigns (after G0)

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| Tier-A screening S1–S7 | Red (unassigned) | Not started | | Protocol §5.1 |
| Tier-B generator (DTjRTL or in-house) | Red (unassigned) | Not started | | |
| Rarity calibration | Red (unassigned) | Not started | | Protocol §6 |
| G2 pilot | Blue + Red | Not started | | Protocol §16 |

---

# A. Daily log

## YYYY-MM-DD - [Short title]

**Author:** `[name]`  
**Time spent:** `[hours]`  
**Phase:** `[design / UVM / baseline / analysis / documentation]`

### Goal for today
- [ ] `[goal 1]`
- [ ] `[goal 2]`

### Work completed
- `[factual action and outcome]`

### Commands executed
```bash
[exact command]
```

### Files created or changed
| Path | Change | Commit/hash |
|---|---|---|
| | | |

### Observations
- `[coverage, failure, waveform, timing, or other factual observation]`

### Evidence
- Raw log: `[path]`
- Waveform: `[path]`
- Coverage database/report: `[path]`
- Screenshot/figure: `[path]`

### Open issues and next action
- `[issue] -> [specific next action + owner]`

---

## 2026-09-25 - Advisor review processed; documents revised to v0.2

**Author:** `[name]`  
**Time spent:** `[hours]`  
**Phase:** documentation

### Goal for today
- [x] Analyze advisor review of 2026-09-23 point by point.
- [x] Verify literature cited by the advisor and identify "Gadde et al."
- [x] Revise scope, literature review, protocol, FIFO plan and this notebook.

### Work completed
- Advisor review (TS. Nguyễn Hoàng Dũng, 2026-09-23) mapped to changes; see §J and `05_advisor_response.md`.
- "Gadde et al." identified as arXiv:2405.19815, SMACD 2024 (design-agnostic RL stimulus; DPI-C socket; code-coverage reward).
- Krieg, *Reflections on Trusting TrustHUB* (ICCAD 2023) read in full. It reports 3 of 83 Trust-Hub designs as effective; this informs Tier-A screening.
- Documents revised: `01` v0.2, `02` v0.2, `03` v0.2, `FIFO_VERIFICATION_PLAN.md` v1.1, this notebook.

### Commands executed
```bash
# none (documentation only)
```

### Files created or changed
| Path | Change | Commit/hash |
|---|---|---|
| `docs/01_scope_threat_model.md` | v0.2 rewrite | `[hash]` |
| `docs/02_literature_review.md` | v0.2 rewrite | `[hash]` |
| `docs/03_experiment_protocol.md` | v0.2 rewrite | `[hash]` |
| `docs/04_lab_notebook.md` | Appended sections C, D, H, I, J | `[hash]` |
| `docs/05_advisor_response.md` | New | `[hash]` |
| `FIFO_VERIFICATION_PLAN.md` | v1.1 | `[hash]` |

### Observations
- Gadde et al. report 23 random stimuli vs 22–31 RL stimuli to reach 100% FIFO code coverage: no RL gain on FIFO coverage.
- DETERRENT assumes full-scan access for sequential circuits (stated in its setup section).
- Two neighbouring works not yet read in full: Dai and Yavuz (GLSVLSI 2024) and Dai et al. (HOST 2025).

### Open issues and next action
- ISSUE-001/002 → fix `fifo_if.sv` → Blue.
- Decisions DEC-003…DEC-013 need advisor confirmation → send `05_advisor_response.md` → `[owner]`.
- Assign blue and red owners → team.

---

## 2026-10-24 - RL loop infrastructure validated on Windows / Questa 2024.1

**Author:** Minh Đức  
**Time spent:** `[hours]`  
**Phase:** UVM / baseline

> Loop check only. RB-01 is a spec-derived pseudo-target, not a Trojan. Nothing below is a research result.

### Goal for today
- [x] Run the original FIFO testbench on Windows with Questa 2024.1.
- [x] Apply the RL infrastructure package (knobs, knob sequence, bandit, RL observer, CSV logger, loop test).
- [x] Run the RL loop with B0 (fixed A0), B1 (uniform random), UCB1 and ε-greedy on RB-01, 10 seeds.

### Work completed
- Toolchain on Windows: Questa Sim-64 2024.1 (win64), UVM-1.1d built-in (same UVM as the Linux host). ModelSim Intel FPGA Starter 2020.1 was first on PATH; Questa moved ahead of it.
- Added `run.do` and `run_rl.do`. Windows has no `make`, and these work on Windows and Linux.
- Original `fifo_random_test`: 0 data and 0 flag mismatches; total 1999 (known end-of-test objection issue). Covergroup 90% with seed 1, 100% with seed 2.
- Found that the original Makefile never set the seed: `+ntb_random_seed` is VCS syntax and Questa ignores it; plusargs with whitespace before `=` were split (see `transcript`, vsim-3369). Fixed in the RL package Makefile (`-sv_seed`).
- RL package applied on branch `rl-infra`. With monitor, scoreboard and driver changes, every RL run reports 0 data, 0 flag and 0 hold (new check 1.4) mismatches.

### Commands executed
```powershell
vsim -c -do "set SEED 2; do run.do"
vsim -c -do run_rl.do                                                   # fixed, random, ucb1; binary
vsim -c -do "set POLICIES {random ucb1 egreedy}; set REWARD graded; do run_rl.do"
python scripts\rl_summary.py results\rl
```

Settings: B = 200 tests per simulation, N = 40 transactions per test, 2 reset cycles at the start of each test, seeds 1–10, UCB1 c = 1.0, ε = 0.1. Arms = presets A0–A9.

### Files created or changed
| Path | Change | Commit/hash |
|---|---|---|
| `uvm/fifo_uvm/fifo_knobs.sv`, `fifo_knob_seq.sv`, `fifo_rl_observer.sv`, `rl_bandit.sv`, `rl_csv_logger.sv`, `fifo_rl_test.sv` | New | `[hash]` |
| `uvm/fifo_uvm/fifo_seq_item.sv`, `fifo_if.sv`, `fifo_driver.sv`, `fifo_monitor.sv`, `fifo_scoreboard.sv`, `fifo_sequence.sv`, `fifo_test.sv`, `fifo_env.sv`, `fifo_pkg.sv`, `fifo_top.sv` | Changed (headers list each change) | `[hash]` |
| `Makefile` | Seed and plusarg fixes; RL targets | `[hash]` |
| `run.do`, `run_rl.do`, `scripts/rl_summary.py` | New | `[hash]` |
| `results/rl/*.csv`, `results/rl/*.log` | Run outputs | `[hash]` |

### Observations

RB-01 = at least 3 consecutive cycles with `wr_en=1` while the spec occupancy model is full. 10 seeds per row.

| Policy | Reward | First-hit test (median) | Seeds without a hit | Hit tests / 200 (mean, min–max) | Pulls of A1 (of 2000) |
|---|---|---|---|---|---|
| fixed (A0) | binary | NA | 10 | 0.0 (0–0) | 0 |
| random | binary | 19.5 | 0 | 5.5 (3–11) | 194 |
| random | graded | 19.5 | 0 | 5.5 (3–11) | 194 |
| ucb1 | binary | 47.0 | 0 | 7.0 (2–14) | 301 |
| ucb1 | graded | 44.5 | 0 | 9.4 (2–15) | 364 |
| egreedy | graded | 21.5 | 0 | 20.1 (1–29) | 1184 |

- B0 never reaches RB-01 at N = 40, as predicted offline. B1 hit count matches the offline estimate (about 2.5% per test).
- random/graded is identical to random/binary. The random policy ignores reward, so the same seed gives the same trajectory. This confirms run-to-run reproducibility.
- First-hit test does not separate random from UCB1 (binary: permutation test p ≈ 0.29, 10 seeds). Seeds range from 4 to about 150.
- UCB1 with c = 1 barely exploits in 200 tests. The best arm (A1) reaches RB-01 in about 16% of tests and the others in about 0%, so the gap in mean reward is about 0.16. The exploration bonus sqrt(2 ln t / n) is about 0.73 at t = 200, n = 20. UCB1 therefore stays close to round-robin. This is the known UCB1 weakness with sparse, small rewards.
- ε-greedy with graded reward concentrates on A1 (59% of pulls) and A4, and gets about 3.7× the hit tests of random. One seed got only 1 hit test: greedy can lock onto a weak arm early. ε-greedy/binary was not run, so reward effect and policy effect are not separated yet.
- Implication for the real study: a binary "activated or not" reward gives almost no learning signal for rare triggers. This supports a dense reward (new bins, rare-bins), already planned in scope §9.3.

### Evidence
- CSV and logs: `results/rl/rl_<policy>_<reward>_s<seed>.csv` / `.log`
- Summary: output of `python scripts\rl_summary.py results\rl` (table above)

### Open issues and next action
- Run ε-greedy/binary to separate reward and policy effects → Minh Đức.
- Fix UCB1 c and ε before any Trojan work (pre-registration). Do not tune them on Trojan results → team.
- Report per-seed hit counts and add a test on hit tests, not only first-hit → update `rl_summary.py`.
- ISSUE-001/002 appear fixed in the current `fifo_if.sv` (`endclocking: mon_cb`; `rst_n` in `mon_cb`) → confirm and update the issue register.
- Original testbench issue 1 (SVA not bound; `error(` typo; vacuous `|| !full`) still open.


---

## 2026-11-25 - Scoreboard replaced by the PR #1 reference model

**Author:** Vũ Minh Quân  
**Phase:** UVM

> Testbench validation only. Nothing below is a research result.

### Work completed
- `fifo_scoreboard.sv` replaced by the PR #1 version (`2a4f920`, Minh Đức): own-occupancy queue model, checks 1.1 data, 1.2 `full`/`empty`, 1.4 `data_out` hold; reset clears the model. Adapted: port `mon_fifo`, DEPTH from config_db, per-line summary with the labels the scripts grep, `SCOREBOARD CHECK PASSED/FAILED`, comments in English.
- `fifo_rl_test.sv`: `det_sb_data/flag/hold` from `failed/flag/hold_mismatch_count` (no longer `NA`).
- `uvm/scripts/bugs.sh`, `run_one.sh`, `build_report.py` adapted to the scoreboard messages.

### Commands executed
```bash
cd uvm/fifo_uvm
make regress
make bugs
```

### Observations
- Regression 20/20 PASS; `summary.txt` identical to 2026-11-05 (reads checked seed 1: 0/32/32/853; total coverage 98.17 %). Flag and hold checks: 0 false failures on the clean RTL.
- Bug injection: 5/5 detected, same tests, seeds and first-error times as before. The scoreboard now also fails `BUG_FULL_EARLY` (flag + data) in fill_drain and write_when_full, where v1.1 passed (finding F1). `BUG_READ_WHEN_EMPTY` still only in random 3/5 (O3).
- RL loop (ucb1 100 tests; fixed A5, A9 with mid-test resets): 0 errors; RL_SUMMARY same as 2026-11-16; flag/hold columns 0.

### Evidence
- `uvm/doc/results/bug_report.txt` (updated), `uvm/doc/results/regression_summary.txt` (unchanged)

### Open issues and next action
- Local edit renames the module in `rtl/sync_fifo_clean.sv`; resolve before the PR (plan W-03) → Quân.
- Open the scoreboard PR and inform Đức (`fifo_rl_test.sv` changed) → Quân.

---

## 2026-11-16 - Handwritten UVM testbench merged; RL loop ported

**Author:** Vũ Minh Quân  
**Phase:** UVM / documentation

> Testbench validation only. The 5 injected bugs are always-active RTL defects, not Trojans. Nothing below is a research result.

### Work completed
- The handwritten UVM testbench (developed in a separate `00_uvm_fifo` tree, executed 2026-11-05) replaced the previous agent, scoreboard, coverage and tests in `uvm/fifo_uvm/`. Plan v1.1, report and results are in `uvm/doc/`.
- RL loop files adapted to the new class names (PR #2, merged as `947a871`): `rst_req`/`rst_n` in the item, 1-cycle reset in the driver, scoreboard clears its model on reset, RL test owns `rl_obs` and `vif`.
- Re-ran the full regression and bug campaign on `947a871` with Questa 2021.2_1 (Linux).

### Commands executed
```bash
cd uvm/fifo_uvm
make regress     # 4 tests x 5 seeds
make bugs        # 5 bugs x 4 tests x 5 seeds
```

### Observations
- Regression: 20/20 PASS. Merged coverage: covergroup 24/24 bins, assertions 10/10, statements 94.44 %, branches 92.30 %, toggles 98.68 %, total 98.17 %. Same as 2026-11-05.
- Bug report identical to `uvm/doc/results/bug_report.txt`: 5/5 detected; `BUG_READ_WHEN_EMPTY` only by the random test in 3/5 seeds.
- RL loop, ucb1, 100 tests, N = 40, seed 1: CSV identical to the previous `main` in every metric column except `cycles` (+1 per test). Fixed arms A5/A9 (mid-test resets): 0 errors, 0 mismatches.
- Review against the study documents found ISSUE-010…ISSUE-014 (see §D1).

### Evidence
- `uvm/fifo_uvm/out/regress/summary.txt`, `uvm/fifo_uvm/out/bugs/bug_report.txt` (local)
- `uvm/doc/results/` (tracked)

### Open issues and next action
- ISSUE-009/010: bring the scoreboard to the old plan §3.8 rules → Blue.
- ISSUE-012: decide which document is the FIFO plan of record before G0 → team.
- ISSUE-013: re-run RB-01 on the new testbench, one simulator version → Đức.

---

# B. Experiment registry and per-run log

## B1. Experiment registry

One entry per planned campaign, not per simulator invocation.

| Experiment ID | Objective | DUT | Method | Seed set | Budget | Protocol version | Status |
|---|---|---|---|---|---|---|---|
| `EXP-000` | Pre-registration freeze (G0) | Each DUT | — | — | — | v0.2 | Not started |
| `EXP-001` | Validate clean FIFO (handwritten suite; plan T01–T10, 4 tests implemented) | FIFO clean | Directed + constrained-random UVM | seeds 1–5 | 4 tests × 5 seeds | FIFO plan v1.1 (`uvm/doc`) | Done 2026-11-05; re-run 2026-11-16 (20/20 PASS) |
| `EXP-001b` | Testbench validation by bug injection | FIFO + 5 bug switches | Same suite | seeds 1–5 | 5 bugs × 4 tests × 5 seeds | FIFO plan v1.1 §9.3 | Done; 5/5 detected |
| `EXP-002` | Tier-A screening S1–S7 | Tier-A hosts | Directed + synthesis | — | — | v0.2 | Not started |
| `EXP-003` | Tier-B generation + acceptance | FIFO + hosts | Generator | `[gen seeds]` | — | v0.2 | Not started |
| `EXP-004` | Rarity calibration | All Trojans | B0 | `[list]` | Per protocol §6 | v0.2 | Not started |
| `EXP-005` | G2 pilot (dev split) | FIFO Tier B | B0, B1, M1 (+M3) | 10 seeds | B | v0.2 | Not started |
| `EXP-006` | Main campaign (test split) | All | B0–B3, M1/M2 (+B4, B5, M3) | ≥10 seeds | B | v0.2 | Not started |
| `EXP-007` | False-positive campaign | Clean DUTs | All methods | Same seeds | B | v0.2 | Not started |
| `EXP-008` | Ablations | Dev + test | Protocol §14 | ≥10 seeds | B | v0.2 | Not started |

## B2. Per-run template

### Run ID: `[EXP-006-DUT-TROJAN-METHOD-SEED]`

| Field | Value |
|---|---|
| Date/time | `[ISO 8601]` |
| Operator | `[name]` (red for test split) |
| Git commit / config_hash / prereg_hash | `[hash]` |
| DUT / Trojan / tier / split | `[values]` |
| Trigger class / payload class / rarity target / p̂ | `[values]` |
| Method / version / observability | `[values]` |
| Random seed | `[integer]` |
| B, N, cycle cap, wall-time timeout | `[values]` |
| Simulator command | `[exact command or link]` |
| Exit reason | `[completed/timeout/fatal]` |

### Outcomes
| Metric | Value | Notes |
|---|---:|---|
| Functional coverage (%) | | |
| Rare-bin coverage (%) | | |
| Detector events (SB data / SB flag / SVA / live / mon) | | |
| Trojan activated oracle | `[Y/N]` | Offline only |
| Activation cycle/test | `[value/NA]` | |
| Trojan detected | `[Y/N]` | |
| Detection cycle/test | `[value/NA]` | |
| Runtime: sim / agent / IPC (s) | | |

### Artifact paths and validation
- Raw simulation log: `[path]`
- Coverage database/report: `[path]`
- Structured CSV/JSON rows: `[path]`
- Oracle file (separate): `[path]`
- [ ] Required artifacts exist.
- [ ] Run metadata matches protocol and prereg hash.
- [ ] Oracle was not readable by the agent process.
- [ ] Rows passed schema validation.

---

# C. Decision log

## C1. Decision register

Status: **accepted** = required by advisor or already agreed; **proposed** = awaiting advisor/team confirmation.

| ID | Date | Decision | Status | Evidence / rationale | Affected docs |
|---|---|---|---|---|---|
| DEC-001 | 2026-09-25 | FIFO kept only as MVP pipeline host and Tier-B host, not standalone evidence | Accepted (advisor 2026-09-23) | Advisor review §1; Gadde 2024 FIFO result | 01 §3.5; FIFO plan §0 |
| DEC-002 | 2026-09-25 | Activation oracle is evaluation-only (retained from v0.1) | Accepted | Scope §6.4 | 01, 03 §15 |
| DEC-003 | 2026-09-25 | Two-tier benchmark suite: Tier A screened Trust-Hub + Tier B generated with rarity control | Proposed | Advisor §1; Krieg 2023 | 01 §3 |
| DEC-004 | 2026-09-25 | AES excluded from main metrics; T2300–T2800 only as possible controls | Proposed | Advisor §1; Krieg 2023 | 01 §3.1–3.2 |
| DEC-005 | 2026-09-25 | Screening S1–S7 published per Trojan; host repairs applied identically to clean and Trojan versions | Proposed | Krieg 2023 (RS232 host defect) | 01 §3.3; 03 §5.1 |
| DEC-006 | 2026-09-25 | DUT-agnostic knob action space; A0–A6 become FIFO knob vectors | Proposed | Advisor §1 | 01 §9; FIFO plan §3.7 |
| DEC-007 | 2026-09-25 | Rarity = per-test activation probability under frozen π₀; sweep 10⁻³…10⁻⁶; default B = 1,000 | Proposed | Advisor §2 | 01 §5.3; 03 §6–7 |
| DEC-008 | 2026-09-25 | Pre-registration per DUT (G0) + blue/red roles + advisor audit | Accepted in principle (advisor §2); roles to assign | Advisor §2 | 01 §6.5; 03 §4 |
| DEC-009 | 2026-09-25 | Payload classes P0–P4; P0 only as control | Accepted in principle (advisor §2) | Advisor §2 | 01 §5.2 |
| DEC-010 | 2026-09-25 | Baselines: Q2 = B0–B3; Q1 adds B4, B5 | Proposed | Advisor §4 table | 01 §10; 03 §8 |
| DEC-011 | 2026-09-25 | G2 pilot moved early with pre-registered go/pivot rule | Proposed | Advisor §4 table | 01 §13; 03 §16 |
| DEC-012 | 2026-09-25 | Dev/test split; test evaluated once | Proposed | Leakage via tuning | 01 §9.4; 03 §5.3 |
| DEC-013 | 2026-09-25 | Drop "DPI-C coverage-to-reward loop" and "design-agnostic RL" as novelty claims | Accepted | Gadde 2024 | 02 §6.3 |

## C2. Full decision entry template

### DEC-[NNN]: [Decision title]

| Field | Entry |
|---|---|
| Date | `[YYYY-MM-DD]` |
| Decision owner | `[name]` |
| Status | `[proposed/accepted/superseded]` |
| Context | `[what prompted the decision]` |
| Options considered | `[A, B, C]` |
| Decision | `[chosen option]` |
| Evidence/rationale | `[data, paper, advisor feedback]` |
| Risks/trade-offs | `[what is lost or threatened]` |
| Affected files/runs | `[paths/experiment IDs]` |
| Approval | `[advisor/team]` |
| Follow-up | `[task, owner, due date]` |

---

# D. Issue and failure log

## D1. Issue register

| ID | Date | Severity | Category | Summary | Resolution |
|---|---|---|---|---|---|
| ISSUE-001 | 2026-09-19 | Blocker | UVM | `fifo_if.sv`: `endclocking: mon_cb_cb` does not match block name `mon_cb`; compile error | Resolved (2026-10-26: `endclocking: mon_cb` in `2a4f920`) |
| ISSUE-002 | 2026-09-19 | High | UVM | `fifo_if.sv`: `mon_cb` lacks `rst_n`, so the monitor/scoreboard cannot see reset; `rst_n` driven outside the clocking block (race risk) | Resolved (2026-10-26: `rst_n` in `mon_cb` and `drv_cb` in `2a4f920`) |
| ISSUE-008 | 2026-10-26 | High | Assertion | `fifo_sva.sv` is not bound in `fifo_top.sv`, so no assertion runs; line 43 `error(` should be `$error(`; line 60 `full \|=> $stable(wr_ptr) \|\| !full` can pass vacuously (see ISSUE-004) | Resolved for `tb_top` (2026-11-16): `fifo_assertions.sv` bound via `bind sync_fifo`; `fifo_sva.sv` kept but superseded. `fifo_top` (RL) still unbound |
| ISSUE-009 | 2026-11-16 | Medium | Scoreboard | The handwritten scoreboard checks data only: no `full`/`empty` check, no `data_out` hold check, no leftover-item check (plan O1). RL CSV columns `det_sb_flag`/`det_sb_hold` are written as `NA` until these checks exist | Resolved 2026-11-25: PR #1 scoreboard model reused (1.2 flag, 1.4 hold checks); RL CSV `det_sb_flag`/`det_sb_hold` filled again. Leftover-item check still open (FIFO plan O1) |
| ISSUE-010 | 2026-11-16 | High | Scoreboard | `fifo_scoreboard` gates reads on the DUT's sampled `empty` (`rd_en && !item.empty`) instead of its own occupancy. Old plan §3.8 requires the model never to trust DUT flags. A Trojan that corrupts `empty` can therefore steer the model | Resolved 2026-11-25: reads and writes accepted from the model's own occupancy |
| ISSUE-011 | 2026-11-16 | High | Assertion | A02–A06 and A08–A10 in `fifo_assertions.sv` read internal signals (`count`, `wr_ptr`, `rd_ptr`). Scope §7 and old plan §0 count these as white-box (`DET-INT`, GB only). Only A01 and A07 are interface-only. Internal names may also differ in Trojan RTL | Open |
| ISSUE-012 | 2026-11-16 | Medium | Protocol | Two different documents are labelled "FIFO plan v1.1": the study plan (`89ae1f3`, deleted from `main`: §0 role, §3.7 knobs, §3.8 scoreboard rules, §4.5 rare-bin register) and the executed handwritten plan (`uvm/doc/`). Scope §8, DEC-006 and ISSUE-003 cite sections that exist only in the old one | Open |
| ISSUE-013 | 2026-11-16 | Medium | Protocol | Baseline π₀ changed: the new `fifo_seq_item` adds `c_valid_op` (80 % of cycles have `wr_en` or `rd_en`), so A0 and `fifo_test_random` no longer have the distribution used for the 2026-10-24 RB-01 runs. Those runs also used Questa 2024.1, the regression used 2021.2_1 | Open |
| ISSUE-014 | 2026-11-16 | Medium | UVM | Two tops: `tb_top` (SVA bound, 1 ms watchdog, always dumps VCD) and `fifo_top` (no SVA, 100 ms watchdog, `+NODUMP`). RL and handwritten runs therefore use different detector sets | Open |
| ISSUE-003 | 2026-09-25 | High | Scoreboard | FIFO plan R5 says "process write before read"; wrong if the scoreboard does not gate by flags (empty + both enables → RTL writes only). Rule must gate by sampled `full`/`empty` | Fixed in FIFO plan v1.1 §3.8 |
| ISSUE-004 | 2026-09-25 | Medium | Assertion | A04/A05 consequents `$stable(ptr) \|\| !flag` can pass vacuously when a read clears the flag; use `full \|=> $stable(wr_ptr)` and `empty \|=> $stable(rd_ptr)` | Fixed in FIFO plan v1.1 §5 |
| ISSUE-007 | 2026-09-25 | Medium | Assertion | A01 `$rose(rst_n) \|=> (empty && !full)` fails falsely if a write occurs in the reset-release cycle; use `\|->` | Fixed in FIFO plan v1.1 §5 |
| ISSUE-005 | 2026-09-25 | High | Benchmark | Krieg 2023 reports RS232 RTL host UART cannot send data; clean-DUT regression would fail | Open; screening S2 |
| ISSUE-006 | 2026-09-25 | Medium | Toolchain | BasicRSA is VHDL; needs a mixed-language licence or exclusion | Open; confirm licence |

## D2. Full issue template

### ISSUE-[NNN]: [Short problem title]

| Field | Entry |
|---|---|
| Date discovered | `[YYYY-MM-DD]` |
| Reporter | `[name]` |
| Severity | `[blocker/high/medium/low]` |
| Category | `[RTL/UVM/scoreboard/assertion/coverage/simulator/data/RL/protocol/benchmark]` |
| Affected experiment IDs | `[IDs]` |
| Reproducible? | `[Y/N/unknown]` |
| Exact command/seed | `[command and seed]` |
| Expected behavior | `[text]` |
| Actual behavior | `[text]` |
| Evidence | `[log/waveform/link]` |
| Root cause | `[confirmed/suspected/unknown]` |
| Fix attempted | `[text]` |
| Fix commit | `[hash]` |
| Verification after fix | `[test/run]` |
| Resolution | `[open/mitigated/resolved/won't fix]` |
| Effect on prior data | `[none / invalidate runs ...]` |

### Failure classification
| Code | Meaning | Treatment |
|---|---|---|
| `INFRA` | Compile/license/filesystem/tool failure | Exclude from performance metric; report count |
| `RTL` | DUT implementation defect | Fix; invalidate affected runs |
| `TB` | Testbench/reference-model defect | Fix; invalidate affected runs |
| `DET` | Detector/assertion issue | Fix and rerun clean/Trojan validation |
| `COV` | Coverage bin unreachable/misdefined | Document and revise denominator |
| `BENCH` | Benchmark defect (host bug, ineffective Trojan) | Repair identically or exclude; record in screening table |
| `LEAK` | Possible oracle leakage | Stop; audit; label or rerun affected runs |
| `PROTO` | Protocol deviation | Retain record; label non-comparable |
| `DATA` | Missing/corrupt log or schema error | Recover or exclude with reason |

---

# E. Trojan screening and detector validation record

Tier-A screening results go in the table of protocol §5.1 (one row per Trojan). Tier-B acceptance results go below.

| Validation ID | Trojan | Clean result | Pre-trigger equivalence | Directed activation | Payload observed | Detector fires | Silent on clean | Synthesis/persistence | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| `VAL-001` | | | | | | | | | |

Required before any campaign on a Trojan:
- [ ] Trigger condition documented (red only).
- [ ] Directed test activates it.
- [ ] Payload observable at the interface.
- [ ] A pre-registered detector flags the payload.
- [ ] The detector is silent on the clean DUT under matched traffic.
- [ ] `trojan_activated` is evaluation-only.

---

# F. Weekly review

## Week `[NN]`: `[date range]`

### Completed evidence
- [ ] `[artifact/result]`

### Metrics snapshot
| Metric | This week | Cumulative | Interpretation |
|---|---:|---:|---|
| Valid runs | | | |
| Activation rate by level | | | |
| Detection rate given activation | | | |
| Functional / rare-bin coverage | | | |
| Clean-DUT false-positive rate | | | |
| Infrastructure failure rate | | | |

### What was learned
- `[evidence-based statement]`

### Risks
| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|
| Trojan ineffective or unreachable | | | Screening S1–S7 | Red |
| Oracle leakage | | | G0 + audit | Blue + advisor |
| RL equals random (no signal) | | | G2 pilot rule | Team |
| Simulator/runtime or licence limits | | | Compute worksheet | |

### Next-week commitments
- [ ] `[task]` - Owner: `[name]` - Due: `[date]`

---

# G. Pre-analysis checklist

- [ ] Protocol version, commit, config and prereg hash known for every valid run.
- [ ] Identical or documented budgets across methods (cycles and wall-clock).
- [ ] Clean-DUT control runs exist for every DUT.
- [ ] No-event runs censored, not given invented TTA/TTD values.
- [ ] Infrastructure failures distinct from valid no-detection runs.
- [ ] Coverage denominators include only reachable documented bins.
- [ ] Per-seed raw points retained.
- [ ] Deviations, exclusions and exposed Trojans documented.
- [ ] Test split used once; no tuning on it.
- [ ] No conclusion based solely on the best seed or a single run.

---

# H. Pre-registration record (gate G0)

| DUT | Artifact | Tag | SHA | Frozen on | Signed by advisor |
|---|---|---|---|---|---|
| FIFO | Spec decisions | `prereg/fifo/spec` | | | |
| FIFO | Covergroups + rare-bins | `prereg/fifo/coverage` | | | |
| FIFO | Detectors | `prereg/fifo/detectors` | | | |
| FIFO | Knobs | `prereg/fifo/knobs` | | | |
| FIFO | π₀, N, reset policy | `prereg/fifo/baseline` | | | |
| FIFO | Reward + GB extractor | `prereg/fifo/reward` | | | |
| FIFO | Analysis plan + G2 rule + FPR bound | `prereg/fifo/analysis` | | | |
| All | Dev/test split + generator seeds | `prereg/split` | | | |

---

# I. Knowledge-exposure log (blue team)

| Date | Blue member | Trojan / source | What was seen | Action (flag / exclude from test split) |
|---|---|---|---|---|
| 2026-09-25 | `[name]` | Krieg 2023 (AES-T800 trigger listing); DETERRENT; FuCE examples | Specific published trigger details | AES excluded anyway; flag any Trojan whose trigger was read |

---

# J. Advisor review record

| Date | Reviewer | Point | Response | Status |
|---|---|---|---|---|
| 2026-09-23 | TS. Nguyễn Hoàng Dũng | Q2 feasible with rigour; not yet Q1 | Q2 package as committed target; Q1 items gated at G4 | Accepted |
| 2026-09-23 | " | FIFO MVP fine; AES problematic; use multi-DUT suite; publish filtering | Tier A/B + S1–S7; Krieg evidence added | Proposed (DEC-003/004/005) |
| 2026-09-23 | " | A0–A6 FIFO-specific | Generic knobs (DEC-006) | Proposed |
| 2026-09-23 | " | Define rarity empirically; sweep 10⁻³–10⁻⁶ | DEC-007 | Proposed |
| 2026-09-23 | " | Oracle leakage via rare-bins; pre-register; separate authors; ablation without ΔR | DEC-008; ablation A-noR | Accepted in principle |
| 2026-09-23 | " | TTD ≈ TTA; add delayed/masked payloads | DEC-009 | Accepted in principle |
| 2026-09-23 | " | Six papers too few; verify Gadde et al. | Lit review v0.2; Gadde identified | Done |
| 2026-09-23 | " | Risk table and tier requirements | Scope §12, §14; protocol §8, §13–16 | Proposed |
