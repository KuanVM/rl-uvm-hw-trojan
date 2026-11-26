# Experiment Protocol: RL-UVM Hardware Trojan Study

> **Document status:** Draft v0.3 (evaluation and interpretation rules added; thresholds are proposals until G0)  
> **Last updated:** 2026-11-25  
> **Owner:** `[Name]`  
> **Repository commit:** `[git commit hash]`  
> **Companion documents:** `01_scope_threat_model.md` (definitions), `04_lab_notebook.md` (records)

## Change log (Lịch sử thay đổi) — newest first

| Date | Version | Change |
|---|---|---|
| 2026-11-25 | v0.3 | Added smallest effects of interest to the hypotheses (§2); handwritten-suite baseline B-H as a proposal (§7.1, §8); derived quantities: effective rarity, amplification factor, budget-to-50 % speed-up, cost-normalized activation, FPR bound (§12.1); SESOI and equivalence, power and sample size, interpretation categories, qualifiers and invalidating conditions (§13.1–§13.5); claim–evidence map for necessity and superiority (§21); outcome scenarios and what each allows the paper to claim (§22). All thresholds marked *proposed* are frozen only at G0 with advisor sign-off. |
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

| ID | Hypothesis | Primary endpoint | Smallest effect of interest (SESOI, proposed) |
|---|---|---|---|
| H0 | Baseline characterization: B0 activation follows 1 − (1 − p)^B within calibration error | Observed vs predicted activation per level | Predicted value inside the 95 % interval at every level |
| H0b | *(Proposed; depends on the decision about B-H.)* A coverage-closed handwritten suite (functional coverage 100 %) does not activate triggers at p ≤ 10⁻⁴ within its native budget | Activation rate of B-H(native) per level | Descriptive; no test (§21, claim N) |
| H1 (primary) | The RL method shifts the activation frontier toward rarer triggers vs each baseline in the claimed tier | Frontier difference Δ in decades of p (95 % CI) | Δ = 0.5 decade (amplification ≈ 3.2×) |
| H1b | The RL method reduces restricted-mean TTA vs each baseline | RMST ratio method / baseline (95 % CI) | Ratio ≤ 0.67 (≥ 33 % fewer tests) |
| H2 | The GB reward improves over the BB reward | Frontier and RMST difference, GB − BB | Same as H1, H1b |
| H3 | Detection latency and masking differ by payload class | Latency distribution; masking rate | Descriptive per class |
| H4 | The H1 advantage survives cost accounting | Activations per CPU-hour, method / baseline | Ratio ≥ 2 |

The SESOI is the smallest difference that would change what a verification engineer does. The argument for 0.5 decade: an advantage below about 3× can be matched by running the baseline about 3× longer, which costs nothing but compute and needs no new method. Effects below the SESOI are reported, but they do not support a superiority claim (§13.3).

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

### 7.1 Budget for the handwritten suite (B-H, proposed)

The handwritten suite is a finite list of tests. Its directed part is deterministic: running it again gives the same stimulus. Two budgets are therefore reported:

- **B-H(native):** the suite as an engineer runs it (FIFO: 4 tests × 5 seeds, about 2.1k cycles per seed). This answers "what does normal verification practice achieve".
- **B-H(matched):** the directed tests once, then the suite's constrained-random test with new seeds until the common cycle budget is used. Its random part is π₀, so at matched budget B-H differs from B0 only by the directed tests. This answers "does expert-written stimulus add anything at equal cost".

B-H is valid only with the same frozen checker set as every other method (scope §7, lab notebook ISSUE-014).

## 8. Methods compared

| ID | Method | Action space | Setting |
|---|---|---|---|
| B-H | *(Proposed)* Handwritten verification suite (directed + constrained-random), frozen before any Trojan exists | Fixed tests | BB |
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

### 12.1 Derived quantities for interpretation

These make results comparable across Trojans of different rarity and readable for non-specialists.

**Effective rarity and amplification factor.** For a baseline with i.i.d. tests, A(B) = 1 − (1 − p)^B. Inverting the observed activation rate Â at budget B gives the per-test probability that would produce it:

```latex
p_{\mathrm{eff}} = 1 - (1 - \hat{A})^{1/B} \qquad
k = \frac{p_{\mathrm{eff}}(\text{method})}{p_{\mathrm{eff}}(\text{baseline})}
```

k reads as "the method makes this trigger behave as if it were k times more frequent". An adaptive policy's tests are not i.i.d., so p_eff is a summary of the whole run, not a per-test probability. k is undefined when Â is 0 or 1; report a bound instead (for Â = 0 use the rule of three on runs, for Â = 1 use the lower confidence limit). A frontier shift of one decade corresponds to k ≈ 10, half a decade to k ≈ 3.2.

**Budget-to-50 % speed-up.** B50 is the budget at which half of the runs have activated: the Kaplan–Meier median TTA. For the i.i.d. baseline, B50 = ln 0.5 / ln(1 − p) ≈ 0.69 / p. Speed-up = B50(baseline) / B50(method). If a method never reaches 50 %, B50 is censored at B and the speed-up is reported as a bound.

**Cost of brute force.** For the baseline to activate with 95 % probability needs B95 = ln 0.05 / ln(1 − p) ≈ 3 / p tests. With N transactions per test and measured simulation speed (§17), this converts to CPU-hours. It is the number the paper uses to show why the problem needs something better than more random simulation: at p = 10⁻⁵, B95 ≈ 300,000 tests.

**Cost-normalized activation.** Activations per CPU-hour, counting simulator, agent and communication time (H4). Overhead ratio = (agent + IPC time) / simulator time.

**Clean false-positive bound.** With zero detector events in n clean runs, report FPR < 3/n (95 %). A detection claim needs this bound below the pre-registered FPR bound.

**Coverage is a proxy.** Functional and rare-bin coverage are reported for every method but are never a primary endpoint. Gadde et al. (SMACD 2024) show no RL gain on FIFO coverage closure, and coverage closure does not imply activation (§21, claim N).

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

### 13.1 SESOI and equivalence

- The SESOI per hypothesis is in §2. Superiority needs the effect to be both statistically and practically meaningful (§13.3).
- A negative claim ("RL is no better than B1") is made only with an equivalence test (two one-sided tests, TOST) using the same margin: the 90 % CI of Δ must lie inside (−SESOI, +SESOI). A non-significant difference alone is **not** evidence of no effect.

### 13.2 Power and sample size

- **Two units of replication.** Seeds measure stochastic variation of a method on one Trojan. Trojans measure generalization. A claim about Trojans in general needs many Trojans; more seeds on one Trojan do not substitute.
- **Per cell (one Trojan, one level, one method).** With 10 runs, Fisher's exact test separates 0/10 from 5/10 (two-sided p ≈ 0.03) but not 0/10 from 4/10 (p ≈ 0.09). To separate 10 % from 40 % activation with α = 0.05 and power 0.8 needs about 32 runs per method. Per-cell claims therefore need 30 seeds; the primary analysis pools (§13).
- **Number of Trojans.** Proposed minimum on the test split: ≥ 3 Trojans per rarity level per DUT, at ≥ 3 levels inside the informative band (§13.5) `[confirm at G0]`.
- **Choosing seeds by simulation.** After the G2 pilot, re-sample the pilot data with an injected true effect equal to the SESOI and run the planned analysis; pick the smallest seed count with P(CI excludes 0) ≥ 0.8. Record the result in §17.
- **Optional two-stage design.** An interim look at half the seeds is allowed only if pre-registered, with an alpha-spending rule. Adding seeds after seeing results without such a rule is a protocol deviation (§20) and invalidates the comparison.

### 13.3 Interpretation categories (per hypothesis and comparison)

Δ is the effect with "positive = method better" (for H1: decades of frontier shift), after Holm correction, on the test split.

| Category | Condition on the 95 % CI of Δ | Meaning | What may be written |
|---|---|---|---|
| **Robust superiority** | Lower limit ≥ SESOI | Better, and by a practically relevant amount | "outperforms … by at least …" |
| **Supported superiority** | Lower limit > 0 and point estimate ≥ SESOI | Better; size uncertain but plausibly relevant | "outperforms …; estimated …" with the CI |
| **Real but small** | Lower limit > 0 and upper limit < SESOI | A difference exists, too small to justify the method | "statistically detectable but below practical relevance" |
| **Promising, underpowered** | Includes 0; point estimate ≥ SESOI | Possible effect; not enough data | Exploratory only; more seeds/Trojans only via a pre-registered extension |
| **Inconclusive** | Includes 0 and extends beyond ±SESOI | No conclusion possible | "inconclusive"; never "no difference" |
| **Equivalent** | 90 % CI inside (−SESOI, +SESOI) (TOST) | No practically meaningful difference | "equivalent within ±SESOI"; triggers the characterization path (scope §1.2) |
| **Inferior** | Upper limit < 0 | Method worse | Reported as is |

### 13.4 Qualifiers that limit a claim

A result in a superiority category is narrowed, not discarded, when:

| Condition | Consequence |
|---|---|
| Only on the dev split | Exploratory; not a paper claim |
| Only on the FIFO | Pilot result (DEC-001); not standalone evidence |
| Beats B0 but not B1 | Shows that **stimulus diversity** helps, not that **learning** helps |
| Beats B0 and B1 but not B2/B3 | Shows that adaptive knob search helps; does not show that RL is needed |
| Only in the GB setting | Labelled as a GB result; BB claim not supported |
| Only for one trigger class or payload class | Claim restricted to that class |
| Direction differs between DUTs | Report heterogeneity; no general claim |
| Wall-clock ratio fails H4 | Claim limited to "fewer tests", not "cheaper" |
| Only Tier-B (generated) Trojans | Claim limited to generated Trojans until Tier-A results exist |

### 13.5 Invalidating conditions (results not usable as evidence)

Any of the following makes the affected comparison invalid. It is logged in lab notebook §D and either rerun or excluded with a reason.

- **Leakage:** a `LEAK` finding in the audit (§15); rare-bins, detectors, knobs, rewards or hyperparameters written or tuned with knowledge of an evaluated Trojan; the test split used more than once.
- **Unequal conditions:** methods differ in DUT revision, checker set, coverage model, seed list, reset policy, budget or simulator version (lab notebook ISSUE-013, ISSUE-014).
- **Benchmark defects:** a Trojan that fails screening S1–S7; a trigger not reachable by a directed test (every method at 0 % carries no information); an always-on trigger (every method at 100 %).
- **Uninformative levels:** at a rarity level where every method is at 0 % or 100 %, no per-level comparison may be reported. Such levels stay in the frontier fit only as anchors.
- **Detector validity:** clean FPR above the bound, or a detector that does not fire on the directed activation test.
- **Reporting:** best-seed-only results; endpoints, SESOI or analysis changed after seeing data; infrastructure failures counted as non-activation.
- **Wrong evidence type:** pseudo-target results (RB-xx, loop checks only); coverage gains presented as security gains; activation presented as detection.

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
- **Reading the pilot:** "Go" needs at least the *promising* category of §13.3 on dev data. It is a development decision, not a paper claim; pilot data never enter the test-split analysis.
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

| Method | Runs | Frontier log₁₀ p (CI) | Δ vs strongest baseline, decades (CI) | Amplification k (CI) | RMST-TTA (CI) | Activation @10⁻³ | Activation @10⁻⁴ | Detection given A | Masking | Rare-bin cov. | Activations / CPU-h | Clean FPR (bound) | Category (§13.3) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|

### Run validity

| Method | Planned | Valid | Censored A | Censored D | Infra failures | Excluded (reason) |
|---|---:|---:|---:|---:|---:|---|

## 20. Deviations from protocol

Enter every deviation in `04_lab_notebook.md` before interpreting results.

| Date | Deviation | Reason | Affected runs | Approved by | Effect on comparability |
|---|---|---|---|---|---|

---

## 21. Claim–evidence map: necessity and superiority

The paper must establish the claims below in this order. Each row says which experiment gives the evidence, which number is read, and what counts as a good result.

| Claim | Question | Experiment | Metric | Good result | Weak or meaningless result |
|---|---|---|---|---|---|
| **N. Necessity** | Does normal verification practice miss rare-trigger Trojans? | B-H(native) *(proposed)* and B0 on the clean coverage model and on the Trojan set; cost of brute force (§12.1) | Functional/code coverage of B-H; activation per level; B95 in CPU-hours | B-H reaches coverage closure yet activates ≈ 0 % at p ≤ 10⁻⁴; B95 at the hardest levels exceeds a realistic budget | B-H coverage not closed ("they just tested too little"); only easy Trojans; necessity argued from B0 alone (rarity is defined under π₀, so B0 failing at low p is true by construction) |
| **S1. Learning helps** | Is the gain due to learning, not to stimulus diversity? | RL vs B1 (same knobs, no learning) | Δfrontier, RMST ratio, k | Robust or supported superiority (§13.3) | Beats B0 only |
| **S2. RL is the right tool** | Does RL beat competent non-RL adaptive search? | RL vs B2, B3 (Q1: B4, B5) with equal tuning budget | Same | Superiority vs the strongest of them | Baselines not tuned with the same budget (straw man) |
| **M. Mechanism** | Which signal causes the gain? | Ablations §14; reward–activation correlation (dev) | Change of Δ when a term is removed | Removing the key term removes most of the gain; A-noR shows the gain is not from rare-bins alone | Gain unchanged by every ablation (signal not understood) |
| **G. Generality** | Does it hold beyond one DUT and the dev set? | ≥ 3 DUTs; held-out trigger class; Tier-A Trojans | Per-DUT Δ; heterogeneity; pooled Δ | Same sign on every DUT; pooled CI excludes 0 | FIFO-only or dev-only |
| **D. Detection** | Does activation turn into detection? | Payload classes P0–P4 with the shared detector set | P(D \| A); TTD − TTA; masking | High P(D \| A) for P0–P3; masking explained by payload design | Activation reported as detection |
| **P. Practicality** | Is it worth using? | Wall-clock accounting; engineering effort | Activations per CPU-hour; overhead ratio; LOC/hours (B-H vs knob annotation) | H4 holds; overhead small; effort per new DUT lower than writing a handwritten suite | Gain disappears after wall-clock normalization |
| **R. Reliability** | Are detections real? | Clean-DUT campaign, all methods, same seeds | FPR bound | Below the pre-registered bound | Above the bound: detection claims void |

## 22. Outcome scenarios and what the paper may claim

| Scenario (test split, all validity checks passed) | Paper claim | Tier |
|---|---|---|
| RL robust/supported superiority vs B1, B2, B3 on ≥ 3 DUTs; H4 holds | Main claim C2 (lit review §7): RL shifts the activation frontier by Δ decades | Q2 |
| As above, plus GB ablation and B4/B5 | Adds mechanism claim C3 | Q1 |
| RL beats B0 and B1, not B2/B3 | Adaptive knob search helps; RL not required. Comparative study with the protocol (C1) as main contribution | Q2 (weaker) |
| RL beats B0 only | Stimulus diversity helps; learning not shown. Characterization paper | Q2 at best |
| RL equivalent to B1 (TOST) on all classes | Pre-registered negative result: when adaptive stimulus does not help against rare RTL triggers; per trigger class analysis | Q2 (characterization) |
| Inconclusive on the planned sample | Report as inconclusive; no claim. Extend only through a pre-registered extension | — |
| Gains only on FIFO or only on dev | Pilot report; not the main claim | — |
| Any invalidating condition (§13.5) | No claim from the affected comparison until rerun | — |

