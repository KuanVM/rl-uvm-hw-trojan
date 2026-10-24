# Lab Notebook: RL-UVM Hardware Trojan Study

> **Project:** RL-guided UVM for rare-trigger Hardware Trojan activation and detection  
> **Current phase:** Pre-registration (G0) and benchmark preparation  
> **Notebook owner:** `[Name]`  
> **Repository:** `[URL/path]`  
> **Rule:** Record facts, commands, versions and decisions. Do not overwrite old observations; append corrections with dates.

## Change log (Lịch sử thay đổi) — newest first

| Date | Change |
|---|---|
| 2026-10-24 | Added daily-log entry "RL loop infrastructure validated on Windows / Questa 2024.1" (pseudo-target RB-01; not a research result). |
| 2026-09-25 | Scope renamed from FIFO-only to multi-DUT study. Added daily-log entry for the advisor review. Filled decision register DEC-001…DEC-013 and issue register ISSUE-001…ISSUE-007. Added sections H (pre-registration record), I (knowledge-exposure log) and J (advisor review record). Updated the experiment registry and work packages. Templates kept unchanged. |
| — | Initial template (FIFO baseline). |

---

## 0. Project identity and reproducibility record

| Field | Value |
|---|---|
| Project ID | `[e.g., RL-UVM-HT-2026]` |
| Main branch / commit | `[hash]` |
| Simulator / version | Questa 2021.2 (primary); iverilog + GTKWave (backup) — from FIFO verification plan v1.0 |
| UVM version | `[version]` |
| OS and host | `[OS, CPU, RAM]` |
| Python / RL environment | `[N/A until G2]` |
| DUTs | FIFO (MVP host); Tier-A hosts after screening; Tier-B generated Trojans |
| FIFO parameters | 8-bit × 32, synchronous active-low reset |
| Clean FIFO RTL path | `sync_fifo_clean.sv` `[commit]` |
| Protocol version | `03_experiment_protocol.md` v0.2 `[hash]` |
| Scope version | `01_scope_threat_model.md` v0.2 `[hash]` |
| Dataset / results location | `[path]` |
| Blue owner / Red owner | `[name]` / `[name]` |

## 1. Current study status

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| Clean FIFO RTL | | Done | | `sync_fifo_clean.sv` |
| `fifo_if.sv` compiles cleanly | Blue | Blocked (ISSUE-001, ISSUE-002) | | |
| FIFO spec decisions + reference model rules | Blue | In progress (ISSUE-003) | | FIFO plan v1.1 |
| FIFO pre-registration G0 (coverage, rare-bins, detectors, knobs) | Blue | Not started | | §H |
| UVM skeleton (M3) | Blue | Not started | | |
| Tier-A screening S1–S7 | Red | Not started | | Protocol §5.1 |
| Tier-B generator (DTjRTL or in-house) | Red | Not started | | |
| Rarity calibration | Red | Not started | | Protocol §6 |
| G2 pilot | Blue + Red | Not started | | Protocol §16 |
| Literature reading queue | | In progress | | Lit review §10.2 |

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

# B. Experiment registry and per-run log

## B1. Experiment registry

One entry per planned campaign, not per simulator invocation.

| Experiment ID | Objective | DUT | Method | Seed set | Budget | Protocol version | Status |
|---|---|---|---|---|---|---|---|
| `EXP-000` | Pre-registration freeze (G0) | Each DUT | — | — | — | v0.2 | Not started |
| `EXP-001` | Validate clean FIFO (directed T01–T14) | FIFO clean | Directed UVM | `[list]` | `[budget]` | v0.2 | Not started |
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
| ISSUE-001 | 2026-09-19 | Blocker | UVM | `fifo_if.sv`: `endclocking: mon_cb_cb` does not match block name `mon_cb`; compile error | Open |
| ISSUE-002 | 2026-09-19 | High | UVM | `fifo_if.sv`: `mon_cb` lacks `rst_n`, so the monitor/scoreboard cannot see reset; `rst_n` driven outside the clocking block (race risk) | Open |
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
