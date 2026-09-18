# Lab Notebook: FIFO UVM Hardware Trojan Study

> **Project:** RL-guided UVM for rare-trigger Hardware Trojan activation and detection  
> **Current phase:** UVM constrained-random baseline  
> **Notebook owner:** [Name]  
> **Repository:** `[URL/path]`  
> **Rule:** Record facts, commands, versions, and decisions. Do not overwrite old observations; append corrections with dates.

---

## 0. Project identity and reproducibility record

| Field | Value |
|---|---|
| Project ID | `[e.g., RL-UVM-HT-2026]` |
| Main branch / commit | `[hash]` |
| Simulator/version | `[tool/version]` |
| UVM version | `[version]` |
| OS and host | `[OS, CPU, RAM]` |
| Python/RL environment | `[N/A in baseline or version]` |
| DUT | `FIFO` |
| DUT parameters | `[width, depth, reset style]` |
| Clean RTL path | `[path]` |
| Trojan RTL path | `[path]` |
| Protocol version | `[docs/03... commit/hash]` |
| Dataset/results location | `[path]` |

## 1. Current study status

| Work package | Owner | Status | Due date | Evidence / link |
|---|---|---|---|---|
| Threat model frozen | | `[Not started/In progress/Done/Blocked]` | | |
| Clean FIFO tests | | | | |
| Trojan insertion | | | | |
| Trigger reachability test | | | | |
| Scoreboard validation | | | | |
| Assertion validation | | | | |
| Coverage model validation | | | | |
| Baseline random campaign | | | | |
| Result analysis | | | | |

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

# B. Experiment registry and per-run log

## B1. Experiment registry

Use one entry per planned experiment campaign, not one per simulator invocation.

| Experiment ID | Objective | DUT | Method | Seed set | Budget | Protocol version | Status |
|---|---|---|---|---|---|---|---|
| `EXP-001` | Validate clean FIFO | Clean | Directed UVM | `[list]` | `[budget]` | `[hash]` | |
| `EXP-002` | Prove HT trigger reachable | Trojan | Directed UVM | `[list]` | `[budget]` | `[hash]` | |
| `EXP-003` | Baseline campaign | Trojan | Constrained-random UVM | `[list]` | `[budget]` | `[hash]` | |
| `EXP-004` | False-positive campaign | Clean | Constrained-random UVM | `[list]` | `[budget]` | `[hash]` | |

## B2. Per-run template

### Run ID: `[EXP-003-SEED-0001-TEST-0001]`

| Field | Value |
|---|---|
| Date/time | `[ISO 8601]` |
| Operator | `[name]` |
| Git commit | `[hash]` |
| DUT version | `[clean/trojan]` |
| Test/UVM class | `[name]` |
| Method | `constrained-random` |
| Random seed | `[integer]` |
| Scenario / constraint profile | `[name/details]` |
| Cycle budget | `[value]` |
| Wall-time timeout | `[value]` |
| Simulator command | `[exact command or link]` |
| Exit reason | `[completed/timeout/fatal]` |

### Outcomes
| Metric | Value | Notes |
|---|---:|---|
| Functional coverage (%) | | |
| Rare-bin coverage (%) | | |
| New regular bins | | |
| New rare bins | | |
| Assertion failures | | |
| Scoreboard mismatches | | |
| Detector event | `[Y/N]` | |
| Trojan activated oracle | `[Y/N]` | Offline evaluation only |
| Activation cycle/test | `[value/NA]` | |
| Trojan detected | `[Y/N]` | |
| Detection cycle/test | `[value/NA]` | |
| Runtime (s) | | |

### Artifact paths and validation
- Raw simulation log: `[path]`
- Coverage database/report: `[path]`
- Structured CSV/JSON row: `[path]`
- Waveform, if needed: `[path]`
- [ ] Required artifacts exist.
- [ ] Run metadata matches protocol.
- [ ] Oracle was not used in test-selection feedback.
- [ ] Result row passed schema validation.

---

# C. Decision log

Record decisions that affect experiment interpretation, design, comparability, or scope.

## DEC-[NNN]: [Decision title]

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

### Example decision titles
- `DEC-001: Select FIFO as initial DUT`
- `DEC-002: Define activation oracle as evaluation-only`
- `DEC-003: Exclude unreachable rare bin RB-05 from coverage denominator`
- `DEC-004: Fix baseline budget before RL implementation`

---

# D. Issue and failure log

Do not delete failed runs. Classify them and preserve evidence.

## ISSUE-[NNN]: [Short problem title]

| Field | Entry |
|---|---|
| Date discovered | `[YYYY-MM-DD]` |
| Reporter | `[name]` |
| Severity | `[blocker/high/medium/low]` |
| Category | `[RTL/UVM/scoreboard/assertion/coverage/simulator/data/RL/protocol]` |
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
| `PROTO` | Protocol deviation | Retain record; label non-comparable |
| `DATA` | Missing/corrupt log or schema error | Recover or exclude with reason |

---

# E. Trojan and detector validation record

| Validation ID | Clean DUT result | Trojan DUT pre-trigger | Directed activation | Payload observed | Detector fires | False alarm on clean DUT | Evidence |
|---|---|---|---|---|---|---|---|
| `VAL-001` | | | | | | | |

Required before baseline campaign:
- [ ] Trigger condition is precisely documented.
- [ ] Directed test activates it.
- [ ] Payload is observable at DUT interface/monitor level.
- [ ] Scoreboard/assertion detects payload.
- [ ] Same detector remains silent on clean DUT under matched traffic.
- [ ] `trojan_activated` is evaluation-only and not exposed to online policy feedback.

---

# F. Weekly review

## Week `[NN]`: `[date range]`

### Completed evidence
- [ ] `[artifact/result]`

### Metrics snapshot
| Metric | This week | Cumulative | Interpretation |
|---|---:|---:|---|
| Valid baseline runs | | | |
| Activation rate | | | |
| Detection rate | | | |
| Functional coverage | | | |
| Rare-bin coverage | | | |
| Clean-DUT false-positive rate | | | |
| Infrastructure failure rate | | | |

### What was learned
- `[evidence-based statement]`

### Risks
| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|
| Trigger too easy or unreachable | | | | |
| Detector false positives | | | | |
| Coverage misalignment with trigger | | | | |
| Simulator/runtime constraint | | | | |

### Next-week commitments
- [ ] `[task]` - Owner: `[name]` - Due: `[date]`

---

# G. Pre-analysis checklist

Before plotting or comparing results:

- [ ] Protocol version and Git commit are known for every valid run.
- [ ] All methods use identical or explicitly documented budgets.
- [ ] Clean-DUT control runs exist.
- [ ] No-event runs are marked as censored, not converted to fabricated TTA/TTD values.
- [ ] Infrastructure failures are distinct from valid no-detection runs.
- [ ] Coverage denominators include only reachable documented bins.
- [ ] Per-seed raw points are retained.
- [ ] Deviations and data exclusions are documented.
- [ ] No conclusion is based solely on the best seed or a single run.
