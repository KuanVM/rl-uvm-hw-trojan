# Literature Review: RL-UVM for Hardware Trojan Activation and Detection

> **Document status:** Draft v0.1  
> **Last updated:** 2026-09-17  
> **Scope:** RTL + UVM simulation-based pre-silicon verification  
> **Purpose:** Establish evidence-based research positioning, terminology, gaps, and a testable novelty claim for the project.

---

## 1. Review question

This review addresses the following question:

> What remains unsolved after existing ML/RL-based Hardware Trojan (HT) detection and RTL security verification work, specifically for an online, simulation-based RTL+UVM framework that must activate rare triggers and detect observable malicious payloads without direct trigger-oracle feedback?

### Inclusion set

This document is based on the six supplied papers:

1. **Multi-Criteria Hardware Trojan Detection: A Reinforcement Learning Approach**.
2. **Intent-Level Attention-based Multiple Instance Learning for Explainable Hardware Trojan Detection**.
3. **Hardware Trojan Detection at LUT: Where Structural Features Meet Behavioral Characteristics**.
4. **System-Level Hardware Trojan Detection Using Side-Channel Power Analysis and Machine Learning**.
5. **Hardware Trojans Detection Through RTL Features Extraction and Machine Learning**.
6. **RL-TPG: Automated Pre-Silicon Security Verification through Reinforcement Learning-Based Test Pattern Generation**.

> **Evidence rule:** Details not confirmed from the supplied paper text are marked **not confirmed**. Do not replace these entries with assumptions when writing the final paper.

---

## 2. Terminology glossary

| Vietnamese term | English term | Operational meaning in this project |
|---|---|---|
| Trojan phần cứng | Hardware Trojan (HT) | Malicious modification inserted into a hardware design, here modeled at RTL. |
| Điều kiện kích hoạt | Trigger condition | Input, state, timing, counter, or transaction sequence needed to enable the malicious payload. |
| Trigger hiếm | Rare trigger | A trigger condition reached rarely under conventional constrained-random verification. |
| Payload | Payload | Malicious behavior executed after trigger activation, such as corruption, leakage, or denial of service. |
| Kích hoạt | Activation | The trigger condition becomes true; measured by an offline oracle in benchmark evaluation. |
| Phát hiện | Detection | An observable detector event, e.g. assertion failure, scoreboard mismatch, or protocol-monitor alarm. |
| UVM | Universal Verification Methodology | SystemVerilog verification methodology built around transactions, sequences, drivers, monitors, agents, scoreboards and coverage. |
| Sequence | UVM sequence | A generator of transaction-level stimulus; a candidate level for RL actions. |
| Constraint profile | Constraint profile | A named set of transaction randomization constraints/distributions. |
| Functional coverage | Functional coverage | User-defined evidence that intended functional scenarios/crosses were exercised. |
| Rare-bin coverage | Rare-bin coverage | Fraction of predeclared, reachable rare coverage bins that were hit. |
| Coverage closure | Coverage closure | Process of reaching coverage targets with justified exclusions for unreachable bins. |
| Scoreboard | Scoreboard | Reference-model comparison mechanism that flags output mismatch. |
| Assertion | SystemVerilog Assertion (SVA) | Executable temporal property used to flag prohibited or required behavior. |
| Oracle leakage | Oracle leakage | Use of privileged knowledge, such as `trojan_activated`, in online state/reward/action selection that would not exist in a realistic unknown-HT setting. |
| Non-oracular feedback | Non-oracular feedback | Feedback available to a verification engineer: coverage deltas, monitor outputs, assertions, scoreboards and simulation cost. |
| Time-to-activation | TTA | First cycle/test at which the benchmark activation oracle becomes true. |
| Time-to-detection | TTD | First cycle/test at which a detector flags the HT payload. |
| Censoring | Right censoring | A run ends within budget without an event; its true event time is only known to exceed the budget. |
| Baseline | Baseline | A fair reference method, initially UVM constrained-random verification under the same budgets. |

---

## 3. Taxonomy of the supplied literature

```text
HT security research
├── Static classification/detection
│   ├── RTL feature extraction + supervised ML
│   ├── LUT structural + behavioral features + ML
│   └── Intent-level explainable MIL
├── Physical/system-level observation
│   └── Side-channel power + ML
└── Dynamic test generation / exploration
    ├── Multi-criteria RL for HT detection
    └── RL-TPG RTL security test-pattern generation
        └── Proposed project: non-oracular RL-guided UVM scenario/constraint adaptation
```

The proposed project belongs primarily to **dynamic, online, simulation-based security verification**, not static HT classification.

---

## 4. Literature Review Matrix

| ID | Work | Main problem | Abstraction / evidence | Method | Inputs / feedback | Output | Metrics/results mentioned in supplied text | Reproducibility notes | Strength | Limitation / unresolved issue | Relevance to proposed project |
|---|---|---|---|---|---|---|---|---|---|---|---|
| P1 | Multi-Criteria Hardware Trojan Detection: A Reinforcement Learning Approach | Guide HT detection using multiple criteria | HT detection; exact simulation abstraction **not confirmed from current extracted notes** | RL with tunable multi-criteria reward | Switching activity, controllability, observability | Test-generation/detection guidance | Supplied extraction notes report approximately 84.2% successful HT detection | Toolchain, benchmark split and code availability **not confirmed** | Establishes that RL reward can encode multiple HT-relevant signals | Does not by itself establish an end-to-end UVM sequence/constraint workflow, non-oracular policy design, or standardized activation-detection-cost evaluation | Related RL predecessor; must be cited and benchmarked conceptually |
| P2 | Intent-Level Attention-based Multiple Instance Learning for Explainable Hardware Trojan Detection | Explainable HT detection from RTL intent-level representation | RTL | Attention-based MIL | RTL decomposition and learned representation | Classification plus attention-based explanation | Supplied notes: accuracy about 96.8%; ROC-AUC about 0.996 | Dataset split, code and exact preprocessing must be verified from full paper | Explainability and RTL-level security analysis | Static supervised classification is not the same as online test exploration, trigger activation or UVM execution | Supports explainability motivation, but is not a direct baseline for test generation |
| P3 | Hardware Trojan Detection at LUT: Where Structural Features Meet Behavioral Characteristics | Detect HT using LUT-level structural/behavioral information | FPGA LUT / structural-behavioral level | Random Forest | Structural and behavioral LUT features | Binary/multiclass detection | Supplied notes: accuracy 99.986%, precision 100%, F1 99.769%; Trust-HUB benchmarks mentioned | Exact feature pipeline and split must be checked | Strong reported classification performance | Different abstraction, offline classifier setting; accuracy may not measure rare-trigger activation difficulty | Contrast work; do not compare raw accuracy against UVM activation metrics |
| P4 | System-Level Hardware Trojan Detection Using Side-Channel Power Analysis and Machine Learning | Detect HT with power side-channel and ML | System level / power side channel | ML on power-related data | Measured/simulated power features | HT classification/detection | Specific metric values **not confirmed from current notes** | Requires power-data acquisition/model and must be verified | Addresses a realistic physical observation channel | Does not provide RTL UVM test-sequence adaptation; may require golden/reference measurements | Out-of-scope baseline; motivates distinction from side-channel detection |
| P5 | Hardware Trojans Detection Through RTL Features Extraction and Machine Learning | Detect HT from extracted RTL features | RTL | Supervised ML | Handcrafted/extracted RTL features | HT classification | Supplied notes: 22 circuits for training, 22 for detection; average detection rate about 99.93% | Exact split/features/code must be verified | Directly uses RTL and ML | Offline feature classification does not prove a method can generate transactions that activate an unknown rare trigger | Important nearest static RTL comparator |
| P6 | RL-TPG: Automated Pre-Silicon Security Verification through Reinforcement Learning-Based Test Pattern Generation | Generate RTL test patterns targeting security properties, coverage and rare nodes | RTL pre-silicon dynamic simulation | RL test-pattern generation with static analyzer, observation/action fields and coverage/security feedback | Traditional coverage, rare-signal coverage and security asset monitor coverage | Intelligent test patterns; security-property violations/vulnerability triggering | Paper abstract/introduction reports all embedded vulnerabilities triggered, average 90% traditional coverage, average 192 s on experimental benchmarks; comparison with JasperGold is stated | Exact benchmark identity, tool flow, reward details, seeds and code availability need verification from full paper | Closest dynamic RTL RL security-verification work; combines security signals and coverage | Supplied text does not establish a UVM-native sequence/constraint policy, HT-specific activation vs payload detection separation, non-oracular evaluation, or standardized fair benchmark protocol | Direct novelty risk: proposed work must be clearly distinguished from RL-TPG |

---

## 5. Cross-paper metric map

| Metric family | Static RTL/LUT classifiers | Side-channel ML | Dynamic RL / proposed UVM work | Project decision |
|---|---|---|---|---|
| Accuracy | Common | Common | Usually insufficient alone | Do not use as headline metric for test generation |
| Precision / recall / F1 | Common | Applicable | Only applicable if detector makes repeated binary decisions on balanced, well-defined instances | Use only for detector-event classification if meaningful |
| ROC-AUC / PR-AUC | Common | Applicable | Not primary for sequential activation | Use only where probability-scored classifier exists |
| Activation rate | Generally absent | Generally absent | Essential | Primary metric |
| Tests-to-activation | Generally absent | Generally absent | Essential | Primary metric |
| Time-to-activation | Generally absent | Generally absent | Essential | Primary metric, with censoring |
| Detection rate | Classifier result | Classifier result | Essential post-payload metric | Primary metric |
| Time-to-detection | Generally absent | Generally absent | Essential | Primary metric, with censoring |
| Detection latency | Generally absent | Generally absent | Important after activation | Secondary metric |
| Functional coverage | Usually absent | Absent | Central in simulation verification | Secondary metric; never equate with security guarantee |
| Rare-bin coverage | Usually absent | Absent | Central for rare-trigger exploration | Primary supporting metric |
| Runtime / simulation cost | Sometimes reported | Sometimes reported | Essential for tool practicality | Primary efficiency metric |
| False-positive rate | Classification false positives | Classification false positives | Detector alarms on clean DUT | Mandatory clean-DUT control |
| Generalization | Cross-design/dataset split | Cross-chip/condition split | Cross-trigger and cross-DUT performance | Required before broad claims |
| Explainability | Attention/features may help | Feature attribution may help | Scenario, action and coverage attribution | Desirable extension; not a substitute for performance |

---

## 6. Research gap synthesis

### 6.1 What the current papers collectively establish

1. HTs can be studied at RTL, LUT and system levels using machine learning.
2. Static feature-based ML can obtain high classification scores on selected benchmark splits.
3. RL can guide exploration/test generation toward coverage, rare signals or security properties at RTL.
4. Explainability is relevant because a security engineer must understand why a design/test is suspicious.

### 6.2 What is not yet established by this review

The supplied evidence does **not** establish a standardized, reproducible framework that simultaneously:

- uses **UVM-native transaction sequences and constraint profiles** as controllable test-generation actions;
- treats HT activation and payload detection as distinct measured events;
- restricts online RL feedback to **non-oracular verification observables**;
- evaluates rare-trigger HTs under equal cycle/test/time budgets against constrained-random UVM baselines;
- reports censored no-activation/no-detection runs correctly;
- measures clean-DUT false alarms, cost, robustness across seeds, and cross-trigger generalization together;
- provides policy-level explanation, such as which sequence/constraint decisions created coverage progress or detector events.

This is a **potential research gap**, not a confirmed novelty claim. It must be revalidated through a broader literature search before submission.

---

## 7. Candidate novelty position

### Weak claim to avoid

> We are the first to use RL at RTL to generate tests for Hardware Trojan/security detection.

This claim is not defensible in light of P1 and especially P6 (RL-TPG).

### Stronger, falsifiable candidate claim

> We develop and evaluate a non-oracular RL-guided UVM policy that selects transaction-level sequences and constraint profiles to improve rare-trigger HT activation and monitor-based payload detection under fixed verification budgets.

### Evidence required before claiming contribution

| Candidate contribution | Minimum evidence required |
|---|---|
| UVM-native policy interface | Public architecture and code/config showing actions map to UVM sequences/constraints |
| Non-oracular RL | Audit showing `trojan_activated` and HT location are absent from state/reward/action logic |
| Better activation efficiency | Multiple independent seeds and same-budget comparison versus constrained-random and weighted-random UVM |
| Better detection | Payload detector validated on Trojan DUT and silent on clean DUT controls |
| Generalization | Results across at least multiple trigger classes and, preferably, more than one DUT |
| Explainability | Logged action ranking, coverage deltas and traceable scenario-to-event examples |
| Reproducible evaluation | Fixed versions, seeds, protocols, raw logs, scripts, exclusions and run registry |

---

## 8. Proposed research problem

> Given an RTL FIFO or protocol-level DUT that may contain an unknown but reachable rare-trigger Hardware Trojan, how can an agent adapt UVM transaction sequences and constraint profiles using only coverage, monitor, assertion, scoreboard and cost feedback to reduce the budget required to activate the HT and detect its observable payload relative to conventional constrained-random verification?

### Scope boundaries

- **Initial DUT:** FIFO.
- **Initial detector:** scoreboard mismatch plus selected assertions.
- **Initial RL method:** multi-armed bandit or tabular Q-learning, not deep RL.
- **Initial action space:** a small set of named traffic scenarios/constraint profiles, not bit-by-bit input generation.
- **Activation oracle:** offline evaluation only.

---

## 9. Evaluation criteria to carry forward

| Criterion | Required operational test |
|---|---|
| Trigger reachability | Directed test activates every benchmark HT before random/RL experiments |
| Detection validity | Detector flags known payload and remains silent on matched clean-DUT traffic |
| Fairness | Same DUT, detector, coverage model, simulator, budgets and seed list across methods |
| Non-oracularity | Code review and logged interface prove no trigger oracle is online feedback |
| Statistical validity | Multiple independent runs, per-seed reporting, CI/effect size, censored runs preserved |
| Coverage validity | Reachable rare bins documented; unreachable bins excluded with justification |
| Runtime validity | Separate simulation, agent, communication and postprocessing costs |
| Generalization | Train/tune and held-out trigger/DUT evaluations separated where possible |
| Reproducibility | Versioned scripts, configs, logs and run registry available |

---

## 10. Immediate literature tasks

- [ ] Extract full bibliographic metadata (authors, venue, year, DOI) for P1–P6.
- [ ] Verify each paper's benchmarks, toolchain, RL state/action/reward, train/test split and availability of artifacts.
- [ ] Search beyond IEEE Xplore for directly related work on RL-guided UVM, security verification, fuzzing and rare-event exploration.
- [ ] Record every additional paper in the literature matrix using the same columns.
- [ ] Update the novelty claim only after direct-neighbor methods are mapped.
- [ ] Cite P6/RL-TPG as the closest competing dynamic RTL RL work, not merely background.

---

## 11. Advisor-facing summary

1. The topic is viable, but generic claims of "RL for RTL HT test generation" are already crowded by prior RL work, including RL-TPG.
2. The defensible research opportunity is a rigorously evaluated, **non-oracular RL-UVM** workflow that uses transaction-level verification feedback and separates activation from detection.
3. The first milestone is not a sophisticated RL network; it is a valid FIFO UVM baseline with a reachable rare trigger, trustworthy detector and reproducible logging.
4. The final paper should not compare its activation metrics directly against static classifier accuracy; these solve different tasks.
