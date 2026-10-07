# Experiment Protocol: RL-UVM Hardware Trojan Study

> **Document status:** Draft v0.2 (revised after advisor review of 2026-09-23)  
> **Last updated:** 2026-09-25  
> **Owner:** `[Name]`  
> **Repository commit:** `[git commit hash]`  
> **Companion documents:** `01_scope_threat_model.md` (definitions), `04_lab_notebook.md` (records)

## Change log (Lịch sử thay đổi) — newest first

| Date | Version | Change |
|---|---|---|
| 2026-09-25 | v0.2 | Scope widened from a FIFO-only baseline to the full campaign. Added pre-registration package (§4), benchmark screening and generation (§5), rarity calibration (§6), budget rule (§7), method list (§8), extended logging schema (§11), activation frontier and RMST (§12), a statistics plan with power caveats (§13), ablations (§14), oracle audit (§15), G2 pilot decision rule (§16), and a compute worksheet (§17). |
| — | v0.1 | Baseline-only protocol for the FIFO. |

---

## 1. Purpose

This protocol defines reproducible procedures for:

1. pre-registering each DUT's coverage, detectors, knobs and analysis;
2. screening and generating Trojans;
3. calibrating rarity;
4. running baselines and, after gate G2, RL methods;
5. analyzing results.

RL training runs only after gate G2 (scope §13).

## 2. Hypotheses

| ID | Hypothesis | Primary endpoint |
|---|---|---|
| H0 | Baseline characterization: B0 activation follows 1 − (1 − p)^B within calibration error | Observed vs predicted activation per level |
| H1 (primary) | The RL method shifts the activation frontier toward rarer triggers vs each baseline in the claimed tier | Frontier difference in log₁₀ p (95% CI) |
| H1b | The RL method reduces restricted-mean TTA vs each baseline | RMST difference (95% CI) |
| H2 | The GB reward improves over the BB reward | Frontier and RMST difference, GB − BB |
| H3 | Detection latency and masking differ by payload class | Latency distribution; masking rate |

All hypotheses, endpoints and tests are frozen at G0. Changes are logged as deviations (§20).

## 3. Scope and non-goals

**In scope:** RTL simulation; FIFO + ≥2 screened hosts; Tier-A and Tier-B Trojans; spec-derived detectors; BB and GB settings; offline oracle.

**Out of scope:** gate-level, FPGA and side-channel measurement; localization; claims about undisclosed real-world Trojans.

---

## 4. Pre-registration package (gate G0, per DUT)

Freeze in this order. Commit each item, tag it `prereg/<dut>/<item>`, and record its SHA in the lab notebook §H. **No Trojan for a DUT may be authored, generated or screened before that DUT's G0 is signed.**

| # | Artifact | Owner |
|---|---|---|
| 1 | Spec and reference-model decisions | Blue |
| 2 | Functional covergroups and rare-bin register (spec-only) | Blue |
| 3 | Detector set, including liveness bounds | Blue |
| 4 | Knob set and levels; FIFO named vectors | Blue |
| 5 | Baseline policy π₀, test length N, reset policy | Blue |
| 6 | Reward formulas (BB, GB) and GB probe extractor version | Blue |
| 7 | Metrics, statistical tests, G2 decision rule, FPR bound | Blue + advisor |
| 8 | Dev/test split rule and generator seed lists | Red |

**Auditor sign-off:** the advisor signs the G0 record.

---

## 5. Benchmark preparation

### 5.1 Tier A screening

Apply S1–S7 (scope §3.3) to each candidate. Record the result in the screening table:

| Trojan | S1 compile | S2 host (pass/repaired/excluded) | C | M | S | P | RTL-sim only | S4 interface payload | S5 directed test | S6 p (interval) | S7 decision | Reason |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

If a host is repaired, apply the same patch to clean and Trojan versions. Store the diff under `benchmarks/<design>/repair.patch` and note it in the decision log.

### 5.2 Tier B generation

1. Red chooses a trigger class, rarity parameter, payload class and host from the pre-registered grid.
2. Generate the Trojan (DTjRTL, or in-house generator `[version]`).
3. Run the acceptance test: no latches; Yosys synthesis + post-synthesis trigger simulation; no new ports, files or top modules; directed activation; pre-trigger equivalence with the clean host.
4. Record generator seed, parameters, hashes and acceptance results.

### 5.3 Dev/test split

- **Dev:** FIFO-hosted Trojans + dev-seed Trojans on other hosts.
- **Test:** held-out seeds + ≥1 trigger class absent from dev + all Tier-A Trojans.
- The test split is used once, with the frozen configuration. Red executes test-split campaigns.

---

## 6. Rarity calibration

1. Fix π₀, N and reset policy (from G0).
2. For each Trojan, run M independent baseline tests and count activations k.
3. Report p̂ = k/M with a Wilson or Clopper–Pearson 95% interval. If k = 0, report the upper bound p < 3/M.
4. Target precision: ±50% relative (95%), which needs about 16 activations. That is about 1.5k tests at 10⁻², 15k at 10⁻³ and 150k at 10⁻⁴.
5. For Tier-B levels below direct reach, fit log p against the generator parameter at measurable levels and extrapolate. Label extrapolated values in every table and verify with the rule-of-three bound.

| Trojan | Level target | M tests | k | p̂ | 95% interval / bound | Extrapolated? |
|---|---|---:|---:|---:|---|---|

---

## 7. Budget and stopping rule

- **Budget:** B tests of N transactions per run. Default B = 1,000 (scope §5.3 table), frozen at G0 after measuring cost per test.
- Report equivalent budgets in simulated cycles and wall-clock. Every method is capped by the same cycle budget, and wall-clock overhead is reported.
- **Stopping rule:** a run ends at the first of B tests reached, the cycle cap, the wall-clock timeout, or a fatal infrastructure error. Runs **continue after detection** so that coverage and cost remain comparable across methods (`[confirm: continue]`).

---

## 8. Methods compared

| ID | Method | Action space | Setting |
|---|---|---|---|
| B0 | Constrained-random, frozen π₀ | Fixed knobs | BB |
| B1 | Uniform random knob selection per test | Knobs | BB |
| B2 | Knob-space black-box optimizer on coverage | Knobs | BB |
| B3 | Coverage-guided mutational sequence fuzzer (VGF-style value coverage + functional coverage) | Sequence mutation | BB (value coverage labelled) |
| B4 | Rare-event directed heuristic (MERO-style) | Knobs | BB / GB |
| B5 | Published-RL adaptations (TGRL-style reward; DETERRENT-inspired sets) | Knobs | GB |
| M1 | Contextual bandit over knobs | Knobs | BB |
| M2 | Tabular Q-learning over knobs | Knobs | BB |
| M3 | M1 or M2 with GB reward | Knobs | GB |

Q2 requires B0–B3 against M1/M2. Q1 adds B4, B5 and M3. B3 uses a different action space; this is declared in every table.

---

## 9. Controlled variables

| Variable | Value |
|---|---|
| Simulator / version | Questa 2021.2 (primary) `[confirm licence: UVM, mixed-language, IEEE 1735]` |
| UVM version | `[version]` |
| Compile options | `[options]` |
| Host / OS | `[CPU, RAM, OS]` |
| Python / RL stack | `[version]` |
| N (transactions per test) | `[value, frozen at G0]` |
| B (tests per run) | 1,000 default `[frozen at G0]` |
| Cycle cap per run | `[value]` |
| Seeds per cell | ≥10; 30 where cost allows (§13) |
| Seed list | `[file + hash]`, shared across methods (paired) |

All methods keep the same DUT revision, detectors, coverage model, seed list, stopping rule and budget unless a documented ablation changes one factor.

---

## 10. Run procedure

For each (DUT, Trojan, method, seed):

1. Check out the recorded commit; clean build.
2. Compile with recorded commands.
3. Run with the fixed seed and budget. The agent process has no read access to oracle outputs.
4. Preserve the raw log, coverage database, per-test structured log, and waveforms on detector events.
5. Write oracle activation to a separate file that the agent process cannot read.
6. Apply the stopping rule.
7. Validate row completeness and file hashes.

Clean-DUT runs use the same seeds for the false-positive campaign.

---

## 11. Logging schema (one row per test; CSV or JSONL)

```text
run_id, method, method_version, config_hash, prereg_hash, observability_setting,
dut_id, dut_version, trojan_id, tier, split, trigger_class, payload_class,
rarity_level_target, p_act_est, p_act_extrapolated,
seed, test_id, knob_vector, action_id,
reward_total, reward_dC, reward_dR, reward_D, reward_cost, reward_dS,
git_commit, simulator_version, cycles, wall_time_s, agent_time_s, ipc_time_s,
functional_coverage_pct, rare_bin_coverage_pct, new_coverage_bins, new_rare_bins,
det_sb_data, det_sb_flag, det_sva, det_live, det_mon, detector_event,
trojan_activated_oracle, activation_cycle, detection_cycle,
exit_reason, raw_log_path, coverage_db_path, waveform_path
```

Use `NA`, never `0`, for event times that did not occur. Oracle columns are joined offline from the separate oracle file.

---

## 12. Metrics

Let N_r be the number of runs in a cell, and I_i^A, I_i^D indicate activation and detection in run i.

```latex
\text{Activation rate} = \frac{1}{N_r}\sum_i I_i^A \qquad
\text{Detection rate} \mid A = \frac{\sum_i I_i^A I_i^D}{\sum_i I_i^A}
```

```latex
\text{Masking rate} = 1 - \text{Detection rate} \mid A \qquad
\text{Latency}_i = \mathrm{TTD}_i - \mathrm{TTA}_i
```

**Activation frontier.** For each method, fit a logistic model of activation against log₁₀ p across rarity levels, pooling Trojans. The frontier is the log₁₀ p at which the fitted activation probability equals 0.5 within budget B. A method with a frontier further toward small p activates rarer triggers.

**Restricted-mean TTA (RMST).** The area under the Kaplan–Meier survival curve of TTA up to B. It handles censored runs without inventing values.

**Other metrics:** functional and rare-bin coverage (reachable denominators); cycles, wall-clock, agent and IPC time; clean-DUT FPR; per-DUT engineering effort (lines of agent code, annotation count, hours).

---

## 13. Statistical analysis plan

**Why 10 seeds per cell are not enough for per-cell claims.** 95% Wilson intervals for an activation rate:

| Observed | 10 runs | 30 runs |
|---|---|---|
| 0% | 0–28% | 0–11% |
| 50% | 24–76% | 33–67% |
| 100% | 72–100% | 89–100% |

A single cell with 10 runs cannot separate 30% from 60%. Therefore:

- **Minimum:** 10 seeds per (Trojan, level, method), as the advisor requires; 30 where a run costs under `[threshold]`.
- **Primary analysis pools across Trojans and levels:**
  - Mixed-effects logistic regression: activation ~ method × log₁₀ p + (1 | DUT/Trojan). Frontier differences come with bootstrap 95% CIs (resampling Trojans, then seeds).
  - Kaplan–Meier curves per method; RMST difference with bootstrap CI; log-rank test as secondary.
- Paired seeds across methods wherever possible.
- **Multiple comparisons:** Holm correction across baselines within each hypothesis.
- **Effect sizes:** frontier shift in decades of p; RMST ratio; risk difference.
- Report every per-seed point. Never report only the best seed.
- Tune nothing on the test split.

---

## 14. Ablations (Q2 requires reward-component ablations)

| Ablation | Change | Question |
|---|---|---|
| A-α, A-β, A-γ, A-λ | Set each weight to 0 in turn | Contribution of each reward term |
| A-noR | β = 0 (no rare-bin term) | Does performance depend on rare-bins? Leakage sanity check |
| A-GB | M3 vs M1/M2 | Value of structural probes |
| A-knob | Remove one knob at a time | Which knobs matter per trigger class |
| A-leak (optional) | Rare-bins written post hoc with Trojan knowledge | How much leakage would inflate results; demonstrates why G0 matters |

---

## 15. Oracle-leakage audit

- [ ] Static check: no reference to `trojan_activated`, Trojan module names or oracle file paths in agent, sequence, coverage or reward code (scripted grep in CI).
- [ ] Interface check: the agent process lacks read permission to the oracle directory.
- [ ] Pre-registration hashes match the artifacts used in each run (`prereg_hash` column).
- [ ] The knowledge-exposure log has been reviewed; exposed Trojans are flagged in results.
- [ ] Code review signed by the red owner and the advisor.

---

## 16. G2 pilot (dev split only)

- **Setup:** FIFO + generated Trojans at p ≈ 10⁻² and 10⁻³; trigger classes T-C and T-S; methods B0, B1, M1; 10 seeds each.
- **Go:** M1 beats B1 on RMST-TTA or activation at either level (95% CI excludes 0), **or** reward components correlate with activation (offline, dev only).
- **Else:** run M3 (GB reward) once with the same setup. If still null, switch to the characterization path (scope §1.2) and record the decision in the lab notebook.

---

## 17. Compute worksheet

```text
runs = Σ_DUT Σ_Trojan Σ_level  (methods × seeds)
cost_per_run ≈ B × N × cycles_per_transaction / sim_speed  +  agent_overhead
```

| Item | Value |
|---|---|
| Measured sim speed (cycles/s) on FIFO with UVM | `[measure]` |
| Measured cost per test | `[measure]` |
| Planned runs (Q2 package) | `[compute]` |
| Estimated CPU-hours | `[compute]` |
| Available machines / licences | `[fill]` |

Freeze B and seed counts only after filling this table.

---

## 18. Data quality checks

- [ ] Unique `run_id`; `config_hash` and `prereg_hash` present.
- [ ] Seed, commit, simulator version and budget recorded.
- [ ] No missing raw log for a completed run.
- [ ] Oracle absent from online paths (§15).
- [ ] Coverage denominators exclude documented unreachable bins.
- [ ] Clean-DUT runs exist for every DUT.
- [ ] Infrastructure failures separated from censored runs.
- [ ] Test-split runs executed once with frozen config.

## 19. Result-table templates

### Summary by method (per DUT and pooled)

| Method | Runs | Frontier log₁₀ p (CI) | RMST-TTA (CI) | Activation @10⁻³ | Activation @10⁻⁴ | Detection given A | Masking | Rare-bin cov. | Runtime/run | Clean FPR |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|

### Run validity

| Method | Planned | Valid | Censored A | Censored D | Infra failures | Excluded (reason) |
|---|---:|---:|---:|---:|---:|---|

## 20. Deviations from protocol

Enter every deviation in `04_lab_notebook.md` before interpreting results.

| Date | Deviation | Reason | Affected runs | Approved by | Effect on comparability |
|---|---|---|---|---|---|
