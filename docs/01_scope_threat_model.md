# Scope and Threat Model: RL-UVM Hardware Trojan Study

> **Document status:** Draft v0.1  
> **Last updated:** 2026-09-17  
> **Project phase:** Baseline setup  
> **Primary DUT:** RTL synchronous FIFO  
> **Owner:** `[Name]`  
> **Repository commit:** `[Git commit hash]`

---

## 1. Research scope

This project studies **simulation-based, pre-silicon Hardware Trojan (HT) activation and detection at RTL**. It uses a SystemVerilog/UVM environment and later introduces an RL policy that selects transaction-level scenarios and constraint profiles.

### 1.1 Research objective

> Develop and evaluate a non-oracular RL-guided UVM verification workflow that improves exploration of rare, reachable behaviors and reduces the verification budget needed to activate a rare-trigger HT and detect its observable payload.

### 1.2 Initial research problem

> Given an RTL FIFO that may contain an unknown but reachable HT with a rare trigger, how can UVM test scenarios and constraint profiles be selected using only verification-observable feedback to improve HT activation and monitor-based payload detection under a fixed simulation budget?

### 1.3 Initial success criteria

The proposed method is considered promising only if, under a fair fixed-budget comparison with UVM constrained-random baselines, it improves one or more of:

- activation rate;
- tests-to-activation or time-to-activation;
- detection rate or time-to-detection;
- reachable rare-bin coverage;
- efficiency after including simulation and policy overhead.

It must not create an unacceptable false-positive rate on clean-DUT controls.

---

## 2. Scope boundary

| Dimension | Included | Excluded in initial study |
|---|---|---|
| Design level | RTL | Gate-level, layout, silicon measurement |
| Verification | Dynamic simulation with UVM | Full formal verification replacement |
| First DUT | Synchronous FIFO | SoC-scale DUT initially |
| Threat | RTL-inserted rare-trigger HT | Naturally occurring unknown field vulnerabilities |
| Stimulus | Transaction sequence/constraint profiles | Cycle-by-cycle or bit-by-bit RL actions |
| Detection | Assertion, scoreboard, protocol/behavior monitor | Automated source-code localization |
| RL maturity | Bandit or tabular Q-learning first | DQN/PPO/transformer before baseline exists |
| Evidence | Controlled benchmarks and seed campaigns | Claims of industrial-scale universal applicability |

---

## 3. DUT specification

| Parameter | Chosen value / placeholder |
|---|---|
| DUT name | `fifo` |
| Top module | `[fifo_top]` |
| FIFO type | `[synchronous / asynchronous]` |
| Data width | `[W]` bits |
| Depth | `[D]` entries |
| Clock | `[clock period and edge]` |
| Reset | `[synchronous/asynchronous; active polarity]` |
| Main inputs | `[write_en, read_en, data_in, reset, ...]` |
| Main outputs | `[data_out, full, empty, valid, ...]` |
| Clean RTL revision | `[path + commit]` |
| Trojan RTL revision | `[path + commit]` |

### Functional reference behavior

The scoreboard/reference model shall define expected FIFO behavior for all allowed transactions, including:

- ordering of read data;
- pointer/count behavior;
- full and empty behavior;
- simultaneous read/write behavior;
- reset behavior;
- specified behavior for invalid read/write attempts.

Any ambiguity must be resolved from the FIFO specification before data collection.

---

## 4. Hardware Trojan threat model

### 4.1 Attacker model

The attacker is assumed able to insert a small RTL modification into a third-party or otherwise untrusted FIFO implementation before verification. The modification contains:

1. a **trigger**, which is hard to reach under ordinary constrained-random traffic; and
2. a **payload**, which changes observable functional or security behavior after activation.

### 4.2 Initial Trojan instance

| Field | Definition |
|---|---|
| Trojan ID | `HT-FIFO-01` |
| Insertion point | `[module/logic region - evaluation metadata only]` |
| Trigger family | `[transaction-sequence / counter / FSM-state / combinational]` |
| Exact trigger condition | `[write a precise Boolean/temporal description]` |
| Trigger persistence | `[one-cycle / latched / counter state]` |
| Payload family | `[data corruption / leakage / denial-of-service / protocol violation]` |
| Payload behavior | `[precise observable effect]` |
| Expected detector | `[scoreboard / assertion / monitor]` |
| Directed trigger test ID | `[test name]` |

### 4.3 Recommended first implementation

Use a **transaction-sequence or counter-based trigger** that is:

- reachable by a directed test;
- unlikely but not impossible under constrained-random tests;
- unrelated to any direct `trojan_activated` feedback supplied to the agent;
- followed by a payload observable at the DUT interface or monitor level.

Example structure only; customize before implementation:

```text
Trigger: a specified sequence of writes/reads and data classes occurs within a bounded window.
Payload: the next eligible read produces an incorrect data word or a protocol-inconsistent flag.
Detector: scoreboard mismatch and/or assertion failure.
```

Do not claim that this toy HT represents all real HTs. It is a controlled benchmark instance.

### 4.4 Threats intentionally not modeled initially

- Analog/RF Trojan behavior;
- side-channel-only payloads;
- malicious logic that has no observable RTL functional effect;
- self-destructing or post-silicon-only triggers;
- Trojans requiring inaccessible environmental inputs.

---

## 5. Defender model and observability

### 5.1 Defender capabilities

The verification environment may observe:

| Signal/source | Permitted use |
|---|---|
| Transaction fields | UVM sequence constraints and scenario selection |
| Monitor transactions | Scoreboard and coverage |
| DUT interface outputs | Monitor, assertion, scoreboard |
| Functional coverage | Online feedback and offline metrics |
| Rare-bin coverage | Online feedback and offline metrics |
| Assertion outcomes | Online feedback and offline metrics |
| Scoreboard mismatches | Online feedback and offline metrics |
| Simulation time/cycles | Cost penalty and offline metrics |

### 5.2 Privileged information prohibited from online control

The following must never appear in an RL observation, reward, action-selection rule, or UVM constraint-selection rule:

- `trojan_activated` signal;
- Trojan source location;
- trigger equation or counter threshold;
- payload implementation details;
- labels identifying malicious internal nets;
- future outputs not yet observable at decision time.

This constraint prevents **oracle leakage**.

### 5.3 Evaluation oracle

For controlled benchmark evaluation only, the inserted HT may export or log an internal activation flag:

```systemverilog
logic trojan_activated; // evaluation instrumentation only
```

Rules:

- It is recorded after each test/run to calculate activation metrics.
- It is not connected to the UVM sequence, agent state, agent reward or monitor decision path.
- Its use is documented in the experiment logs.
- An audit test/code review confirms it is absent from online feedback interfaces.

---

## 6. Detection definition

An HT is **activated** when the benchmark's trigger condition becomes true, verified by the evaluation oracle.

An HT is **detected** when at least one predeclared, externally observable detector fires after or during payload manifestation:

| Detector ID | Detector type | Property/event | Detection criterion |
|---|---|---|---|
| `DET-SB-01` | Scoreboard | FIFO output differs from reference model | At least one confirmed mismatch |
| `DET-SVA-01` | SVA | `[property name]` | Assertion failure |
| `DET-MON-01` | Monitor | `[protocol/behavior anomaly]` | Monitor event emitted |

### Detection validity requirements

- [ ] Every detector has a documented intended property.
- [ ] A directed Trojan test causes the expected detector event.
- [ ] Equivalent clean-DUT traffic does not cause the event.
- [ ] Any detector false alarm is logged and included in the false-positive assessment.
- [ ] A detector event must be timestamped/cycle-stamped.

---

## 7. Coverage model and rare states

### 7.1 Functional coverage categories

| Category | Examples |
|---|---|
| Basic operation | read, write, idle |
| Boundary states | full, empty, almost-full, almost-empty if implemented |
| Concurrency | simultaneous read/write |
| State transitions | empty-to-nonempty, full-to-not-full |
| Reset interactions | reset during idle/active operation |
| Data behavior | repeated patterns, alternating patterns, boundary values |

### 7.2 Rare-bin register

A rare bin is eligible for quantitative evaluation only after a directed test shows it is reachable.

| ID | Rare behavior | Reachability test | Include? | Relationship to trigger |
|---|---|---|---|---|
| `RB-01` | `[e.g., simultaneous read/write at boundary]` | `[test]` | `[Y/N]` | `[supporting/none]` |
| `RB-02` | `[e.g., reset after burst]` | `[test]` | `[Y/N]` | `[supporting/none]` |
| `RB-03` | `[e.g., data-pattern sequence]` | `[test]` | `[Y/N]` | `[supporting/direct]` |

Rare coverage is a proxy for exploration. It is not proof of HT activation or security.

---

## 8. Baseline and future policy interface

### 8.1 Baseline

Initial baseline: **UVM constrained-random sequence** with a fixed, documented distribution.

Optional fair baselines after initial validation:

- weighted constrained-random UVM;
- deterministic coverage-directed heuristic;
- random selection among named scenario profiles.

### 8.2 Future RL action space

The agent should choose among a small number of interpretable UVM-level actions.

| Action ID | Scenario / constraint profile | Intent |
|---|---|---|
| `A0` | Normal random traffic | Broad exploration |
| `A1` | Write-heavy traffic | Approach full/boundary behavior |
| `A2` | Read-heavy traffic | Approach empty/boundary behavior |
| `A3` | Simultaneous read/write stress | Explore concurrency |
| `A4` | Boundary-state stress | Visit full/empty transitions |
| `A5` | Reset-interleaving traffic | Explore temporal corner cases |
| `A6` | Repeated/structured data patterns | Explore data-trigger conditions |

The final action set must be frozen before comparative experiments.

### 8.3 Future non-oracular state and reward candidates

Permitted state features:

- current coverage bucket;
- currently uncovered reachable rare bins;
- previous scenario;
- recent coverage delta;
- recent detector event summary;
- remaining budget.

Permitted reward form:

$$
r_t = \alpha \Delta C_t + \beta \Delta R_t + \gamma D_t - \lambda \cdot \text{Cost}_t
$$

where $Delta C_t$ is functional coverage gain, $Delta R_t$ is rare-bin gain, $D_t$ is an observable detector event, and cost is cycles/runtime/tests. The activation oracle must not be included.

---

## 9. Primary evaluation metrics

| Family | Metric | Interpretation |
|---|---|---|
| Activation | Activation rate | Fraction of independent runs reaching trigger within budget |
| Activation | TTA / tests-to-activation | Effort until first oracle-confirmed activation |
| Detection | Detection rate | Fraction of independent runs producing a valid detector event |
| Detection | TTD | Effort until first detector event |
| Detection | Detection latency | $TTD - TTA$ for runs with both events |
| Exploration | Functional coverage | Fraction of reachable functional bins hit |
| Exploration | Rare-bin coverage | Fraction of reachable rare bins hit |
| Cost | Cycles, tests, runtime | Resources consumed |
| Reliability | FPR on clean DUT | Detector alarms on clean control runs |
| Robustness | Mean, median, variance, confidence interval | Stability across seeds |

No-event runs at the predefined budget are right-censored; they must not be assigned an invented TTA/TTD value.

---

## 10. Validity threats and mitigations

| Threat | Risk | Mitigation |
|---|---|---|
| Oracle leakage | Artificially strong RL performance | Interface audit and strict signal separation |
| Easy trigger | No meaningful gap versus random baseline | Use rare but reachable trigger; pilot campaign |
| Unreachable trigger/bin | Impossible experiment falsely appears unsuccessful | Directed reachability validation |
| Detector defect | False conclusion of detection/non-detection | Clean/Trojan validation suite |
| Coverage proxy mismatch | Optimizing coverage does not help activation | Log activation offline; inspect correlation and ablations |
| Single seed/cherry-picking | Unstable conclusion | Fixed multi-seed campaign and per-seed reporting |
| Unequal budgets | Unfair baseline comparison | Freeze equivalent budgets and stopping rules |
| Overfitting to one HT | Weak generalization | Add held-out trigger class/DUT after MVP |
| Runtime overhead hidden | Unrealistic practical claim | Report simulator, agent and communication costs separately |

---

## 11. Decision gates

### Gate G1: Benchmark validity
Proceed only when directed tests prove clean correctness, trigger reachability, payload observability and detector validity.

### Gate G2: Baseline gap
Proceed to RL only if constrained-random results show a meaningful unresolved gap: low/inconsistent activation, slow activation, weak rare-bin exploration, or costly detection under fixed budget.

### Gate G3: RL evaluation readiness
Proceed to comparison only when state/action/reward are non-oracular, the action set is frozen, and all methods share a documented protocol.

---

## 12. Approval record

| Decision | Owner | Date | Approved? | Notes |
|---|---|---|---|---|
| FIFO selected as initial DUT | | | | |
| HT-FIFO-01 threat model accepted | | | | |
| Detector set accepted | | | | |
| Rare-bin set accepted | | | | |
| Baseline budget frozen | | | | |
