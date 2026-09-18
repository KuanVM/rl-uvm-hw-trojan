# Experiment Protocol: FIFO UVM Hardware Trojan Baseline

> **Document status:** Draft v0.1  
> **Last updated:** YYYY-MM-DD  
> **Owner:** [Name]  
> **Repository commit:** `[git commit hash]`

---

## 1. Purpose

This protocol defines a reproducible **UVM constrained-random baseline** for an RTL FIFO that may contain a rare-trigger Hardware Trojan (HT). The baseline establishes activation, detection, coverage, and simulation-cost measurements before any RL method is introduced.

## 2. Research objective and hypothesis

**Objective.** Measure how effectively conventional UVM constrained-random verification explores rare FIFO states, activates a reachable HT trigger, and detects observable payload behavior under a fixed simulation budget.

**Baseline hypothesis H0.** Under the fixed budget, constrained-random UVM achieves the measured activation/detection/coverage performance reported in this protocol.

**Future comparison hypothesis H1.** A non-oracular RL-guided UVM policy improves at least one preregistered primary metric against this baseline under the same budget and detector setup.

## 3. Scope and non-goals

### In scope
- RTL simulation.
- FIFO DUT: clean and Trojan-inserted versions.
- SystemVerilog/UVM constrained-random tests.
- Scoreboard, assertions, functional coverage, rare-bin coverage.
- Offline logging of HT activation oracle for evaluation only.

### Out of scope in this phase
- RL training/inference.
- Gate-level, FPGA, and side-channel measurement.
- Trojan source localization.
- Claims about undisclosed real-world Trojans.

## 4. Threat model

| Item | Definition for this experiment |
|---|---|
| Insertion level | RTL |
| Trigger class | `[counter / FSM-state / transaction-sequence / combinational]` |
| Trigger condition | `[precise, directed-test-validated condition]` |
| Payload class | `[output corruption / data leakage / DoS / protocol violation]` |
| Observable payload symptom | `[scoreboard mismatch / assertion failure / monitor event]` |
| Attacker knowledge available to agent | None: no trigger signal, HT location, or payload logic |
| Evaluation oracle | `trojan_activated` may be logged after each test/run but is never supplied as UVM constraint feedback or RL state/reward |

## 5. DUT and verification configuration

| Field | Clean DUT | Trojan DUT |
|---|---|---|
| RTL path | `[path]` | `[path]` |
| Top module | `[module]` | `[module]` |
| FIFO width/depth | `[W] / [D]` | `[W] / [D]` |
| Clock/reset | `[definition]` | `[definition]` |
| Commit hash | `[hash]` | `[hash]` |

### Required UVM components
- Sequencer, driver, monitor, agent, environment, test.
- Reference model and scoreboard.
- At least two relevant assertions.
- Functional covergroup and rare-bin covergroup.
- Per-test log writer.

## 6. Reachability and detector validation gates

Before running random tests, complete and record all checks below.

- [ ] Clean DUT passes directed functional tests.
- [ ] Trojan DUT behaves equivalently to clean DUT before trigger activation.
- [ ] Directed test proves trigger is reachable.
- [ ] Directed test proves payload occurs after trigger activation.
- [ ] Scoreboard or assertion detects the payload.
- [ ] Detection does not fire on clean DUT under equivalent directed traffic.
- [ ] Every reported rare bin is reachable or explicitly marked unreachable and excluded from the denominator.

Do not proceed to baseline data collection until every box is checked.

## 7. Test stimulus and controlled variables

### Baseline sequence
`[uvm_fifo_constrained_random_seq]`

### Randomized transaction fields
| Field | Distribution/constraint | Rationale |
|---|---|---|
| `write_en` | `[specify]` | `[reason]` |
| `read_en` | `[specify]` | `[reason]` |
| `data` | `[specify]` | `[reason]` |
| reset timing | `[specify]` | `[reason]` |
| burst length | `[specify]` | `[reason]` |

### Fixed controls
| Variable | Value |
|---|---|
| Simulator/version | `[tool and version]` |
| Compile options | `[options]` |
| UVM version | `[version]` |
| Host/OS | `[CPU, RAM, OS]` |
| Timeout per test | `[value]` |
| Cycles/test budget | `[value]` |
| Tests/seed | `[value]` |
| Number of independent seeds | `[value, recommended >= 10]` |
| Global simulation budget | `[value]` |

All future methods must retain the same DUT revision, detector, coverage model, seed set, stopping rule, and primary budget unless a documented ablation changes one factor.

## 8. Coverage model

### Functional coverage
| Coverpoint/cross | Intended behavior | Reachable? |
|---|---|---|
| write enable | write/no-write | `[Y/N]` |
| read enable | read/no-read | `[Y/N]` |
| full state | boundary behavior | `[Y/N]` |
| empty state | boundary behavior | `[Y/N]` |
| read/write cross | simultaneous operation | `[Y/N]` |
| boundary cross | state-transition corner cases | `[Y/N]` |

### Rare bins
| Rare-bin ID | Definition | Directed test ID | Included in metric? |
|---|---|---|---|
| `RB-01` | `[definition]` | `[test]` | `[Y/N]` |
| `RB-02` | `[definition]` | `[test]` | `[Y/N]` |
| `RB-03` | `[definition]` | `[test]` | `[Y/N]` |

## 9. Run procedure

For each seed in the preregistered seed list:

1. Check out the recorded commit and clean build directory.
2. Compile DUT and UVM environment using recorded commands.
3. Run the constrained-random test with the fixed seed and budget.
4. Preserve raw simulator log, coverage database, waveform on failures, and per-test structured log.
5. Record activation oracle only in the output log, not in online test selection.
6. Apply the stopping rule.
7. Validate row completeness and file hashes.

### Stopping rule
A run ends at the first of:
- fixed cycle budget reached;
- fixed test budget reached;
- wall-clock timeout reached;
- fatal simulation/infrastructure error.

A detected HT is **not** automatically a reason to stop unless this rule is used consistently for every compared method. Record the selected policy: `[continue / stop-on-detection]`.

## 10. Logging schema

One row per test (CSV or JSONL):

```text
run_id,method,seed,test_id,scenario,constraint_profile,
dut_version,git_commit,simulator_version,cycles,
wall_time_s,functional_coverage_pct,rare_bin_coverage_pct,
new_coverage_bins,new_rare_bins,assertion_failures,
scoreboard_mismatches,detector_event,trojan_activated_oracle,
trojan_detected,activation_cycle,detection_cycle,exit_reason,
raw_log_path,coverage_db_path,waveform_path
```

Use `NA` rather than `0` for an event time that did not occur.

## 11. Metric definitions

Let $N$ be the number of independent runs and $I_i^{A}$ and $I_i^{D}$ indicate whether activation and detection occur in run $i$.

### Primary metrics

$$
\text{Activation Rate} = \frac{1}{N}\sum_{i=1}^{N} I_i^{A}
$$

$$
\text{Detection Rate} = \frac{1}{N}\sum_{i=1}^{N} I_i^{D}
$$

$$
\text{Rare-bin Coverage} = \frac{\text{covered reachable rare bins}}{\text{total reachable rare bins}}
$$

### Time and effort metrics

$$
\text{TTA}_i = \text{first activation cycle or test in run } i
$$

$$
\text{TTD}_i = \text{first detection cycle or test in run } i
$$

$$
\text{Detection Latency}_i = \text{TTD}_i - \text{TTA}_i
$$

$$
\text{Functional Coverage} = \frac{\text{covered reachable bins}}{\text{total reachable bins}}
$$

### No-event (censored) runs
If activation/detection does not occur by the fixed budget, record the observation as **right-censored**, not as an arbitrary large event time. Report:
- event rate at the budget;
- median TTA/TTD among successful runs, clearly labeled conditional;
- time-to-event curve or restricted mean time-to-event where feasible;
- number of censored runs.

### False alarms
Run the same seed protocol on the clean DUT.

$$
\text{False Positive Rate} = \frac{\text{clean runs with detector event}}{\text{total clean runs}}
$$

## 12. Data quality checks

- [ ] Every run has a unique `run_id`.
- [ ] Seed, commit, simulator version, and budget are recorded.
- [ ] No missing raw log for completed run.
- [ ] Activation oracle is absent from sequence constraints/reward channels.
- [ ] Coverage denominator excludes documented unreachable bins.
- [ ] Clean-DUT runs are included for false-positive assessment.
- [ ] Failed infrastructure runs are separated from valid censored runs.

## 13. Statistical analysis plan

- Report mean, standard deviation, median, interquartile range, and 95% confidence interval across independent seeds.
- Report per-seed points; do not report only a best seed.
- Use the same seed list for paired baseline-vs-RL comparisons where possible.
- Report effect size and confidence interval, not only $p$-values.
- Predefine the test after selecting sample size: `[paired bootstrap / permutation test / Mann-Whitney U / survival-analysis comparison]`.
- Do not tune on the final held-out benchmark/seed set.

## 14. Result-table templates

### Summary by method
| Method | Runs | Activation rate | Detection rate | Median TTA | Median TTD | Rare-bin coverage | Functional coverage | Runtime/run | FPR on clean DUT |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| UVM constrained-random | | | | | | | | | |
| Future RL method | | | | | | | | | |

### Run validity
| Method | Planned runs | Valid runs | Censored activation | Censored detection | Infrastructure failures | Excluded runs and reason |
|---|---:|---:|---:|---:|---:|---|
| UVM constrained-random | | | | | | |

## 15. Deviations from protocol

Any deviation must be entered in `docs/04_lab_notebook.md` before interpreting results.

| Date | Deviation | Reason | Affected runs | Approved by | Effect on comparability |
|---|---|---|---|---|---|
| | | | | | |
