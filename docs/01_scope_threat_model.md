# Scope and Threat Model: RL-UVM Hardware Trojan Study

> **Document status:** Draft v0.2 (revised after advisor review of 2026-09-23)  
> **Last updated:** 2026-09-25  
> **Project phase:** Baseline setup → pre-registration (gate G0)  
> **Primary DUT:** RTL synchronous FIFO, used as MVP pipeline host only (multi-DUT suite in §3)  
> **Owner:** `[Name]`  
> **Repository commit:** `[Git commit hash]`

## Change log (Lịch sử thay đổi) — newest first

| Date | Version | Change |
|---|---|---|
| 2026-09-25 | v0.2 | Rewritten after advisor review (2026-09-23). FIFO demoted to MVP host. Added two-tier benchmark suite with published screening (§3), informed by Krieg (ICCAD 2023). Replaced FIFO-only profiles A0–A6 with a DUT-agnostic knob action space (§9). Added empirical rarity definition and rarity sweep (§5.3). Added pre-registration and role separation against rare-bin oracle leakage (§6.5). Added delayed/latent/flag/DoS payload classes so activation and detection separate (§5.2). Added black-box vs gray-box observability settings (§6). Gates are now G0–G4 (§13). Added publication-tier requirements (§14). |
| 2026-09-17 | v0.1 | Initial draft. |

---

## 0. What changed and why (short)

| Advisor point (2026-09-23) | Change in this document |
|---|---|
| AES-T\* mostly unsuitable; use multi-DUT third-party suite with public filtering | §3: Tier A (screened Trust-Hub) + Tier B (generated, rarity-controlled). Krieg (ICCAD 2023) reports only 3 of 83 Trust-Hub designs as effective Trojans, so screening is mandatory, not optional. |
| A0–A6 are FIFO-specific; reviewers will call results hand-engineered | §9: generic knobs over a per-DUT sequence library; A0–A6 become one FIFO instantiation of the knobs. |
| Define rarity empirically and sweep it | §5.3: per-test activation probability under the frozen baseline; sweep about 10⁻³ to 10⁻⁶. |
| Rare-bins written with Trojan knowledge leak the oracle | §6.5: spec-only coverage, frozen and hashed before any Trojan work; blue/red role separation; ablation without ΔR. |
| Immediate data-corruption payload makes TTD ≈ TTA | §5.2: payload classes P1–P4 (delayed, latent, flag, DoS) added; P0 kept only as control. |
| Six papers are too few; novelty is thin if it is "bandit over 7 profiles vs random" | Literature expanded in `02_literature_review.md`; candidate mechanism contribution defined as gray-box structural reward (§6.2, §9.3), to be validated in the G2 pilot. |

---

## 1. Research scope

### 1.1 Research objective (revised)

> Develop and evaluate a non-oracular, DUT-agnostic RL policy over UVM sequence knobs that activates rarer sequential-trigger RTL Trojans than conventional and adaptive baselines under the same budget, and detect their payloads with spec-derived monitors. Evaluation uses screened third-party Trojans and rarity-controlled generated Trojans on at least three DUTs.

### 1.2 Research questions

| ID | Question | Primary evidence |
|---|---|---|
| RQ1 | Under equal budget, does the policy activate rarer triggers than constrained-random, knob-space black-box search, and coverage-guided fuzzing? | Activation frontier (§11) and censored TTA across the rarity sweep |
| RQ2 | Which non-oracular feedback signals carry information about trigger reachability: spec coverage only (black-box) or automatically extracted RTL-structure probes (gray-box)? | Reward ablations; offline correlation on dev split only |
| RQ3 | For delayed, latent and masked payloads, how often and how late are activated Trojans detected? | Detection rate given activation; latency TTD − TTA; masking rate |
| RQ4 | Does one agent and one knob interface work on ≥3 DUTs without per-DUT action design? | Results per DUT; logged per-DUT engineering effort |
| RQ5 | What is the total cost, including agent and communication overhead? | Cycles, wall-clock, overhead breakdown |

**Pre-registered negative-result path.** If the G2 pilot (§13) shows no activation advantage and no reward–activation correlation, the paper claim changes to a characterization study: *when does adaptive stimulus help against rare RTL triggers, and when does it not?* This decision rule is fixed before the pilot runs.

### 1.3 Success criteria

The method is promising only if, under the frozen protocol, it:

- shifts the activation frontier toward rarer triggers, or reduces restricted-mean TTA, versus every baseline in the tier being claimed (§10);
- does so on at least three DUTs and on held-out Trojans (test split);
- keeps clean-DUT false-positive rate within the pre-registered bound;
- remains better after agent and communication overhead is counted.

---

## 2. Scope boundary

| Dimension | Included | Excluded |
|---|---|---|
| Design level | RTL (Verilog/SystemVerilog; VHDL if mixed-language simulation is licensed) | Gate-level-only netlists, layout, silicon measurement |
| DUTs | FIFO (MVP host) + ≥2 screened third-party hosts (§3) | SoC-scale DUTs in this paper |
| Threat | Functional, triggered RTL Trojans whose payload is observable at the DUT's functional interface | Side-channel, RF, leakage-current and parametric payloads; always-on Trojans (kept only as positive controls); Trojans needing extra ports |
| Stimulus | Knob vectors over a per-DUT UVM sequence library | Cycle-by-cycle or bit-level RL actions |
| Detection | Spec-derived scoreboard, interface SVA, liveness and protocol monitors | Automated source localization |
| Observability | Black-box (primary) and gray-box structural probes (secondary, labelled) | Any Trojan-specific knowledge online |
| RL maturity | Bandit and tabular Q-learning first | Deep RL unless a documented need appears after G2 |
| Evidence | Pre-registered, multi-seed, rarity-swept campaigns | Claims of industrial-scale universal applicability |

---

## 3. Benchmark suite

### 3.1 Why AES-T\* is not the primary benchmark

- **Trigger (advisor).** Many AES Trojans trigger on one specific 128-bit plaintext, which random or knob-level stimulus essentially cannot hit, or are always on, which leaves nothing to search for.
- **Payload (advisor).** Many AES payloads leak the key through power, RF or leakage current. A functional scoreboard never sees them.
- **Benchmark validity (literature).** Krieg (ICCAD 2023) classified every AES benchmark studied as ineffective. Reasons include extra files, modules and ports; latch-based triggers that behave differently after synthesis; and payload outputs left unconnected, which synthesis removes.

AES stays only as a possible filtered subset (§3.2), never as the primary evidence.

### 3.2 Tier A: third-party candidates (all require screening; none accepted yet)

The "prior finding" column records Krieg's published classification, not our result. We re-run screening ourselves (§3.3).

| Design | Trojans | HDL | Prior finding (Krieg, ICCAD 2023) | Intended use | Status |
|---|---|---|---|---|---|
| RS232 (UART) | T100–T901 (RTL) | Verilog | Host UART does not meet its own spec (cannot send data); malicious parts reported stealthy and persistent (T200 is rated non-malicious in Krieg's table) | Use only after repairing the host identically in clean and Trojan versions; publish the repair diff | Candidate |
| RS232 | T2100–T2400 | Verilog | Undocumented extra malicious behaviour | Include only if the extra behaviour is documented by us | Candidate, low priority |
| RS232 | T1000–T2000 | Tech netlist | Behaviour could not be verified | Exclude (not RTL) | Excluded |
| wb_conmax | T300 | Verilog | Rated effective | Candidate; confirm it is the RTL variant | Candidate |
| wb_conmax | T100 | Verilog | Trigger not satisfiable with a SAT solver | Exclude unless we prove reachability | Excluded pending proof |
| BasicRSA | T100 | VHDL | Rated effective | Candidate; needs mixed-language simulation | Candidate |
| BasicRSA | T300, T400 | VHDL | Correct, malicious, persistent; not stealthy | Candidate with stealth caveat | Candidate |
| memctrl | T100 | Verilog | Rated effective; combined hardware/software attack | Candidate; check stimulus requirements | Candidate |
| PIC16F84 | T100–T400 | Verilog | Counter trigger built from level-sensitive logic; trigger behaviour disappears after synthesis | RTL-simulation-only secondary set, flagged in every table | Secondary |
| AES | T2300–T2800 | Verilog | Payload XORs ciphertext LSB (functional) but triggers are weak or controlled by an external asynchronous reset | Possible low-rarity controls only | Candidate control |
| AES | all others | Verilog | Ineffective (see §3.1) | Exclude from main metrics | Excluded |

### 3.3 Screening protocol (results are published per Trojan)

| Step | Check | Who | Outcome recorded |
|---|---|---|---|
| S1 | RTL available; compiles in our simulator | Red | Pass/fail |
| S2 | Clean host passes our spec-based regression; else repair (same patch in clean and Trojan) or exclude | Red | Pass / repaired (diff) / excluded |
| S3 | Correctness, maliciousness, stealthiness, persistence re-checked (Yosys synthesis + post-synthesis simulation of the trigger) | Red | C/M/S/P flags; RTL-sim-only flag |
| S4 | Payload observable at the functional interface; no extra ports | Red | Pass/fail |
| S5 | Trigger reachable by a directed test from primary inputs | Red | Test ID, activation cycle |
| S6 | Empirical rarity p under the frozen baseline (§5.3) | Red | p estimate and interval, or upper bound |
| S7 | Inclusion decision with reason | Red + advisor | Included / excluded / control |

### 3.4 Tier B: generated, rarity-controlled Trojans

- **Source.** DTjRTL (Dai et al., GLSVLSI 2024) if the tool is obtainable; otherwise an in-house template generator. TRIT (Cruz et al., DATE 2018) works on netlists, so it is not the primary source.
- **Hosts.** FIFO plus the clean versions of at least two Tier-A hosts.
- **Grid.** Trigger class (§5.2) × rarity parameter × payload class (§5.2).
- **Acceptance test for every generated Trojan.** Flip-flop based (no inferred latches); trigger survives Yosys synthesis and post-synthesis simulation; no new ports, files or top modules; directed activation test passes; behaviour matches the clean host before activation (equivalence check or long co-simulation).
- **Split.** Generator seeds are divided into dev and test sets before generation (§9.4, protocol §5).

### 3.5 Role of the FIFO

The FIFO is the pipeline MVP and a Tier-B host. It is not standalone evidence. Gadde et al. (SMACD 2024) report that random and RL stimulus both closed FIFO code coverage in about 22–23 stimuli. FIFO coverage closure is therefore not an interesting RL target; the FIFO's value is as a host for Trojans with controlled rarity.

---

## 4. DUT specification

### 4.1 FIFO (MVP host)

| Parameter | Value |
|---|---|
| Top module | `sync_fifo` (`sync_fifo_clean.sv`) |
| FIFO type | Synchronous, single clock |
| Data width / depth | 8 bits / 32 entries (parameters `DATA_WIDTH`, `DEPTH`) |
| Clock | 100 MHz, rising edge |
| Reset | Synchronous, active-low `rst_n` |
| Inputs | `clk`, `rst_n`, `wr_en`, `rd_en`, `data_in[7:0]` |
| Outputs | `data_out[7:0]` (registered, 1-cycle latency), `full`, `empty` (combinational from `count`) |
| Clean RTL revision | `[path + commit]` |

### 4.2 Other DUTs

One table per DUT, same fields, filled after screening S1–S2.

### 4.3 Functional reference behaviour

Each DUT's scoreboard implements a spec-derived reference model covering ordering, occupancy or state, status flags, simultaneous operations, reset, and illegal-operation behaviour. Ambiguities are resolved from the spec and recorded in the decision log **before** G0.

---

## 5. Hardware Trojan threat model

### 5.1 Attacker model

The attacker is a third-party IP vendor or insider who modifies RTL before integration. Following Krieg (ICCAD 2023), the modified IP is a drop-in replacement: same ports and documented behaviour, no extra top modules. The attacker can deliberately activate the Trojan. Each Trojan has a trigger that is rare under ordinary verification traffic and a payload that changes functional behaviour.

### 5.2 Trojan taxonomy used in this study

**Trigger classes**

| ID | Class | Example structure |
|---|---|---|
| T-C | Counter | Event counter reaches threshold K |
| T-S | Transaction sequence | Ordered sequence of L transaction types or values |
| T-D | Data compare in window | b-bit match on data within a window of W transactions |
| T-F | FSM state | Rare state or transition of an existing controller |

**Payload classes**

| ID | Class | Why it matters | Expected detector |
|---|---|---|---|
| P0 | Immediate data corruption | Control case; TTD ≈ TTA | Scoreboard data |
| P1 | Delayed (armed, fires after D transactions) | Separates activation from detection in time | Scoreboard data |
| P2 | Latent storage corruption (visible only on readback; overwrite or reset can mask it) | Detection rate can be below activation rate | Scoreboard data |
| P3 | Status/flag corruption (full/empty, ready/valid) | Visible only when the flag matters | Scoreboard flag check, interface SVA |
| P4 | Availability / DoS (drop or stall) | Needs liveness checking | Liveness monitor |

"With memory" payloads (P1, P2, persistent P4) correspond to the sequential-payload classes of S3CBench (Veeranna and Schafer, 2017).

### 5.3 Rarity: empirical definition and sweep

**Definition.** For Trojan T, rarity is the per-test activation probability under the frozen baseline policy π₀:

```latex
p_{\mathrm{act}}(T) = \Pr_{\pi_0}\left[\,\text{trigger of } T \text{ becomes true within one test of } N \text{ transactions}\,\right]
```

Rarity is relative to π₀, test length N, and reset policy. All three are frozen at G0 before any calibration.

**Estimation.**

- Measure p directly by Monte Carlo where feasible. Reporting ±50% relative precision (95%) needs about 16 activations: roughly 1.5k tests at p = 10⁻², 15k at 10⁻³, and 150k at 10⁻⁴.
- If a run of n tests sees no activation, report the upper bound p < 3/n at 95% ("rule of three"). For example, 0 in 30,000 tests gives p < 10⁻⁴.
- For generated Trojans, calibrate the mapping from generator parameter to p at measurable levels and extrapolate. Extrapolated values are labelled as such in every table.

**Sweep.** Target levels are p ≈ 10⁻³, 10⁻⁴, 10⁻⁵, 10⁻⁶, optionally with 10⁻² as a sanity level. Tier-A Trojans are placed on the curve at their measured p; they are not tuned.

**Budget rule (advisor).** The budget should give the baseline about 10–90% activation at the easiest level and about 0% at the hardest. With B tests per run, P(activation) = 1 − (1 − p)^B. At p = 10⁻³ this band corresponds to B between 105 and 2,302 tests.

| p | B = 500 | B = 1,000 (default) | B = 2,000 |
|---|---:|---:|---:|
| 10⁻³ | 39% | 63% | 86% |
| 10⁻⁴ | 5% | 10% | 18% |
| 10⁻⁵ | 0.5% | 1% | 2% |
| 10⁻⁶ | 0.05% | 0.1% | 0.2% |

B = 1,000 tests is the provisional default, frozen at G0 after measuring cost per test.

### 5.4 Threats not modelled

Analog/RF Trojans; side-channel-only payloads; parametric Trojans; Trojans with no functional effect at the interface; self-destructing or post-silicon-only triggers; triggers requiring inaccessible environmental inputs; Trojans that need extra ports.

---

## 6. Defender model and observability

### 6.1 Setting BB: black-box (primary)

| Source | Permitted use |
|---|---|
| Transaction fields and knob settings | Stimulus control |
| Monitor transactions, interface outputs | Scoreboard, interface SVA, coverage |
| Spec-derived functional coverage and rare-bins | Online feedback and offline metrics |
| Detector events | Online feedback and offline metrics |
| Simulation cycles and runtime | Cost term and offline metrics |

### 6.2 Setting GB: gray-box (secondary, always labelled)

BB plus **RTL structural probes** extracted automatically and applied uniformly to the whole design:

- comparisons against constants, with progress measured as falling Hamming distance to the constant;
- counter registers, with progress measured as new maximum values;
- FSM state registers, with progress measured as new states or transitions;
- rarely toggling registers, with progress measured as novelty.

The extractor takes only the RTL as input, never Trojan metadata. Its output list and hash are frozen before evaluation. The defender has RTL in third-party IP integration, so this setting is realistic. It is reported separately because it uses more information than BB.

### 6.3 Privileged information prohibited from online control

Never present in any observation, reward, action rule, constraint, hyperparameter choice, or probe selection:

- the `trojan_activated` signal, Trojan location, trigger equation, threshold or payload logic;
- labels identifying malicious nets;
- future outputs not yet observable;
- **rare-bins, detectors or knobs written or edited with Trojan knowledge** (new);
- **hyperparameters or reward weights tuned on test-split Trojans** (new);
- **structural probes selected or weighted per Trojan** (new).

### 6.4 Evaluation oracle

```systemverilog
logic trojan_activated; // evaluation instrumentation only
```

The flag is logged per test after the run. It is never connected to the sequence, agent state, reward or monitor path. An interface audit (protocol §15) confirms this.

### 6.5 Pre-registration and role separation (new)

- **Blue team** owns the spec, coverage and rare-bins, detectors, knob library, agent, rewards and baselines. Blue never opens Trojan RTL, generator configurations or directed activation tests.
- **Red team** owns Trojan selection, screening, generation, directed activation tests, oracle logging, rarity calibration, and execution of test-split campaigns.
- **Freeze order per DUT.** Spec → functional coverage and rare-bins → detectors → knob set → reward formula and analysis plan. Each item is committed, tagged, and its hash recorded in the decision log **before** any Trojan for that DUT is authored, generated or screened.
- **Auditor.** The advisor signs the pre-registration record.
- **Knowledge-exposure log.** Blue records any Trojan detail they read, such as papers describing specific Trust-Hub triggers. Trojans exposed this way are flagged.
- **Optional technical control.** If the simulator licence supports IEEE 1735 protected IP, Trojan RTL is encrypted so that blue can simulate but not read it. Otherwise red runs all test-split campaigns.

---

## 7. Detection definition

An HT is **activated** when the oracle shows the trigger became true. It is **detected** when at least one pre-registered, spec-derived detector fires.

| Detector ID | Type | Property | Setting |
|---|---|---|---|
| `DET-SB-01` | Scoreboard | Read data differs from reference model | BB |
| `DET-SB-02` | Scoreboard | Status flag differs from reference occupancy/state | BB |
| `DET-SVA-xx` | Interface SVA | Spec temporal properties on ports only | BB |
| `DET-LIVE-01` | Liveness monitor | Accepted request not served within a spec bound | BB |
| `DET-MON-01` | Protocol monitor | Protocol violation at interface | BB |
| `DET-INT-xx` | Internal SVA (bound to internals) | White-box properties | GB only, labelled |

**Validity requirements**

- [ ] Every detector has a documented spec property and was frozen at G0.
- [ ] Directed Trojan tests cause the expected detector event.
- [ ] Matched clean-DUT traffic does not cause the event.
- [ ] Liveness timeouts are calibrated on the clean DUT so that clean FPR stays within the pre-registered bound.
- [ ] Every detector event is cycle-stamped.

**Masking rate** = P(no detection by budget end | activated). It is reported per payload class.

---

## 8. Coverage model and rare bins

- Functional coverage categories are unchanged from v0.1 (basic operation, boundaries, concurrency, transitions, reset interactions, data patterns).
- Rare-bins are **spec-derived only** and frozen at G0 (§6.5). The FIFO candidate list is in `FIFO_VERIFICATION_PLAN.md` §4.5.
- A rare-bin enters the metric denominator only after a blue-written directed test from the spec shows it is reachable.
- Rare coverage is a proxy for exploration. It is not evidence of activation or security.

---

## 9. Action space and policy interface

### 9.1 DUT-agnostic knobs

Each DUT's UVM agent provides a transaction item and a small library of primitive sequences; it has to exist for verification anyway. The policy never chooses DUT-specific scenarios. It sets a knob vector:

| Knob | Meaning | Levels (example) | Derived from |
|---|---|---|---|
| `k_mix` | Weights over transaction kinds | 3–5 presets | Enum "kind" field of the item |
| `k_burst` | Burst length distribution | short / medium / long | Generic |
| `k_gap` | Idle gap between transactions | none / short / long | Generic |
| `k_data` | Data mode per data field | uniform / corner values / repeat-last / reuse-from-history | Data fields of the item |
| `k_addr` | Address locality (addressed DUTs) | same / sequential / random | Address fields, if any |
| `k_reset` | Reset injection rate | none / rare / frequent | Generic |
| `k_replay` | Replay or perturb a recent subsequence | off / on | Generic |

- Knob applicability is derived from item field annotations, not hand-picked per DUT.
- Per-DUT engineering effort (agent code, annotations, hours) is logged and reported (RQ4).
- The FIFO profiles A0–A6 from v0.1 become named FIFO knob vectors. For example, A1 write-heavy is a `k_mix` preset, A5 is `k_reset`, and A6 is `k_data` = repeat-last.
- The knob set and levels are frozen at G0.

**Honest positioning.** Test-parameter tuning over knobs is established in coverage-directed test generation; see Huang et al. (DVCon 2022) and Gadde et al. (SMACD 2024). The knob layer answers the generality critique. It is not claimed as a contribution.

### 9.2 State features (BB)

Coverage bucket; uncovered reachable rare-bins; previous knob vector; recent coverage delta; recent detector summary; remaining budget.

### 9.3 Reward

BB:

```latex
r_t = \alpha\,\Delta C_t + \beta\,\Delta R_t + \gamma\,D_t - \lambda\,\mathrm{Cost}_t
```

GB adds a structural-progress term:

```latex
r_t^{\mathrm{GB}} = r_t + \delta\,\Delta S_t
```

ΔS is new progress on the frozen probe list (§6.2). All weights are tuned on the dev split only. The activation oracle is never included.

**Candidate mechanism contribution (for Q1, not yet claimed).** A trigger-agnostic, sequence-aware progress reward from RTL structure (comparison distance, counter progress, FSM novelty) that correlates with reachability of counter, sequence and compare triggers. It must be shown to differ from VGF value coverage, TGRL rareness and testability, DETERRENT rare-net compatibility, and Dai and Yavuz's static models (see literature review §6).

### 9.4 Dev/test split

- **Dev:** FIFO-hosted generated Trojans plus dev-seed generated Trojans on other hosts. Used for all design and tuning.
- **Test:** held-out generator seeds, plus at least one trigger class not used in dev, plus all Tier-A Trojans. Evaluated once with frozen configuration.

---

## 10. Baselines

| ID | Baseline | Tier needed |
|---|---|---|
| B0 | Constrained-random with frozen π₀ | Q2 |
| B1 | Uniform random knob selection | Q2 |
| B2 | Knob-space black-box optimizer on coverage (e.g. hill-climbing or evolutionary search) | Q2 |
| B3 | Coverage-guided mutational sequence fuzzer (corpus of transaction sequences; feedback = functional coverage plus value coverage in the style of VGF) | Q2 |
| B4 | Rare-event directed heuristic (MERO-style N-detect over spec rare-bins or GB probes) | Q1 |
| B5 | Published-RL adaptations to RTL: TGRL-style reward transplant; DETERRENT-inspired compatible-rare-condition sets. Adaptation fidelity documented. | Q1 |

All methods share the same DUTs, detectors, coverage, seeds, and budget in cycles and wall-clock.

---

## 11. Primary evaluation metrics

| Family | Metric | Interpretation |
|---|---|---|
| Activation | Activation rate at budget | Fraction of runs activating within B |
| Activation | **Activation frontier** | Rarity p at which a method's fitted activation rate crosses 50% within B (log₁₀ scale); compared across methods |
| Activation | Censored TTA; restricted-mean TTA (RMST) | Effort to first activation, handling no-event runs correctly |
| Detection | Detection rate given activation; detection latency TTD − TTA; masking rate | Per payload class |
| Exploration | Functional and rare-bin coverage (reachable denominators) | Proxy only |
| Cost | Cycles, tests, wall-clock; agent and IPC overhead | Practicality |
| Reliability | Clean-DUT FPR | Mandatory control |
| Generality | Per-DUT results; per-DUT engineering effort | RQ4 |
| Robustness | Per-seed points, CIs, effect sizes | Stability |

No-event runs are right-censored. They are never assigned an invented TTA or TTD.

---

## 12. Validity threats and mitigations

| Threat | Risk | Mitigation |
|---|---|---|
| Oracle leakage via rare-bins, detectors or knobs | Invalid results | Spec-only, frozen and hashed at G0; blue/red separation; ablation with β = 0 |
| Leakage via tuning | Inflated results | Dev/test split; test evaluated once |
| Ineffective benchmark Trojans (Krieg 2023) | Wrong conclusions | Screening S1–S7 published per Trojan |
| Host design bug (e.g. RS232 UART) | Clean FPR = 100%, or false detections | S2 repair applied identically to clean and Trojan; diff published |
| Easy or unreachable trigger | No gap, or impossible task | Rarity sweep; directed reachability |
| TTD ≈ TTA by construction | Empty activation/detection claim | Payload classes P1–P4 |
| Hand-designed action space | Not generalizable | Generic knobs; effort logged |
| Weak baselines | Rejected at Q1 | B2–B5 |
| Underpowered comparisons (10 seeds give wide CIs) | Inconclusive | Pooled analysis across Trojans and levels; 30 seeds where cheap (protocol §13) |
| RL has no signal and equals random | Negative result | Early G2 pilot with pre-registered pivot |
| Hidden overhead | Unrealistic claim | Separate simulator, agent and IPC costs |

---

## 13. Decision gates

| Gate | Pass condition |
|---|---|
| **G0 Pre-registration** (new) | Per DUT: spec, coverage and rare-bins, detectors, knob set, reward formula, π₀, N, B, metrics and analysis plan frozen, hashed, and signed by the advisor. No Trojan work on that DUT before G0. |
| **G1 Benchmark validity** | Clean regression passes; screening S1–S7 done; Tier-B acceptance tests pass; detectors validated clean vs Trojan; rarity calibrated. |
| **G2 Early pilot** (moved earlier) | On dev split only: FIFO + generated Trojans at two levels (10⁻², 10⁻³); B0, B1 and a bandit; 10 seeds. **Go** if the bandit beats B1 on RMST-TTA or activation at either level (CI excluding 0), or reward components correlate with activation (offline, dev only). **Otherwise** try GB reward once; if still null, take the characterization path (§1.2). |
| **G3 Evaluation readiness** | Action set frozen; baselines for the target tier implemented; oracle audit passed; compute budget confirmed. |
| **G4 Tier decision** | Q2 package complete. Decide whether to pursue Q1 items (§14). |

---

## 14. Publication-tier requirements (from advisor review 2026-09-23)

| Requirement | Tier | Where addressed |
|---|---|---|
| ≥3 DUTs; rarity sweep | Q2 | §3, §5.3 |
| ≥10 seeds, 95% CI and effect size | Q2 | Protocol §13 |
| Reward-component ablation (α, β, γ, λ) | Q2 | Protocol §14 |
| Oracle-leakage audit | Q2 | §6.5, protocol §15 |
| Strong baselines (fuzzing; published RL methods) | Q1 | §10 (B3–B5) |
| Mechanism contribution (reward or state representation) | Q1 | §9.3 candidate; validated at G2 |
| Evaluation on third-party Trojans | Q1 | §3.2 Tier A |

---

## 15. Approval record

| Decision | Owner | Date | Approved? | Notes |
|---|---|---|---|---|
| FIFO kept as MVP host only | Advisor | 2026-09-23 | Yes (review) | |
| Two-tier benchmark suite and screening S1–S7 | | | | Refines advisor list using Krieg (2023) |
| Generic knob action space | | | | |
| Empirical rarity definition; B = 1,000 default | | | | Freeze at G0 after cost measurement |
| Pre-registration and blue/red roles | | | | Advisor as auditor |
| Payload classes P0–P4 | | | | |
| BB primary, GB secondary | | | | |
| G2 pilot decision rule | | | | |
| Baseline set for Q2 (B0–B3) | | | | |
