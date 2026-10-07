# Literature Review: RL-UVM for Hardware Trojan Activation and Detection

> **Document status:** Draft v0.2 (revised after advisor review of 2026-09-23)  
> **Last updated:** 2026-09-25  
> **Scope:** RTL + UVM simulation-based pre-silicon verification  
> **Purpose:** Evidence-based positioning, terminology, gaps, and a testable novelty claim.

## Change log (Lịch sử thay đổi) — newest first

| Date | Version | Change |
|---|---|---|
| 2026-09-25 | v0.2 | Expanded from 6 to about 40 works in seven clusters (§4). Identified "Gadde et al." as arXiv:2405.19815 (SMACD 2024). Added benchmark-validity evidence (Krieg, ICCAD 2023). Removed novelty claims now covered by prior work (§6.3). Ranked candidate contributions (§7). Added search protocol and reading queue (§10). Every entry marks what was verified and from which source. |
| 2026-09-17 | v0.1 | Six supplied papers. |

---

## 1. Review question

> What remains unsolved, after existing RL/ML trigger-activation, RTL security-verification, hardware-fuzzing and ML-for-verification work, for an online, simulation-based RTL + UVM method that must activate rare **sequential** triggers and detect observable payloads without trigger-oracle feedback?

### Evidence rule

Each entry states its **verification level**:

- **V-full**: full text read for this review.
- **V-abs**: abstract or metadata page read.
- **V-cite**: known only from the reference list of a verified paper; must be read before being cited in a manuscript.

Details not confirmed are marked **not confirmed**. Do not fill them from memory.

---

## 2. Terminology glossary

| Vietnamese term | English term | Operational meaning in this project |
|---|---|---|
| Trojan phần cứng | Hardware Trojan (HT) | Malicious RTL modification with trigger and payload |
| Điều kiện kích hoạt | Trigger condition | Input, state, timing, counter or transaction sequence enabling the payload |
| Độ hiếm | Rarity p_act | Per-test activation probability under the frozen baseline π₀ (scope §5.3) |
| Biên kích hoạt | Activation frontier | Rarity at which a method's activation rate crosses 50% within budget B |
| Payload | Payload | Malicious behaviour after activation (classes P0–P4, scope §5.2) |
| Kích hoạt | Activation | Trigger true, measured by an offline oracle |
| Phát hiện | Detection | Spec-derived detector event |
| Tỉ lệ bị che | Masking rate | P(no detection by end of budget given activation) |
| Núm chỉnh | Knob | Generic stimulus parameter over a sequence library (scope §9.1) |
| Hộp đen / hộp xám | Black-box (BB) / gray-box (GB) | Interface + spec only / plus automatic RTL-structure probes |
| Rò rỉ oracle | Oracle leakage | Privileged Trojan knowledge entering online control, coverage design or tuning |
| Đăng ký trước | Pre-registration | Freezing and hashing coverage, detectors, knobs and analysis before Trojan work |
| Kiểm duyệt phải | Right censoring | Run ends without the event; true time only known to exceed budget |
| CDG | Coverage-directed test generation | Using coverage feedback to adapt stimulus |

---

## 3. Taxonomy

```text
HT security research
├── Static classification (RTL / netlist / LUT)                 → contrast only (§4.7)
├── Side-channel / physical                                      → out of scope
└── Dynamic test generation for trigger activation
    ├── Gate-level statistical / RL (rare nets, full scan)       → §4.2
    ├── RTL / HLS concolic, symbolic, formal                      → §4.3
    ├── Hardware fuzzing (coverage- or value-guided)             → §4.4
    └── ML/RL for coverage closure in verification (not HT)      → §4.5
        └── Proposed: transaction-level RL over UVM knobs,
            sequential triggers, pre-registered, rarity-swept
Benchmarks and Trojan generation                                  → §4.6
```

---

## 4. Literature matrix

### 4.1 Original six papers

| ID | Work | Verified | Level / method | Key facts | Relevance |
|---|---|---|---|---|---|
| P1 | Sarihi, Jamieson, Patooghy, Badawy. *Multi-Criteria Hardware Trojan Detection: A Reinforcement Learning Approach.* MWSCAS 2023, pp. 1093–1097 | Metadata V-cite (reference list of Trojan Playground) | Gate level; RL detector with multi-criteria reward | Toolchain, benchmarks and code availability **not confirmed**; the detector side of Trojan Playground (§4.2) | Related RL predecessor |
| P2 | *Intent-Level Attention-based MIL for Explainable HT Detection* | Metadata **not confirmed** | RTL; static classifier | Supplied notes: accuracy ≈ 96.8%, ROC-AUC ≈ 0.996 | Contrast; explainability motivation |
| P3 | *HT Detection at LUT: Structural Meets Behavioral* | Metadata **not confirmed** | FPGA LUT; random forest | Supplied notes: accuracy 99.986% | Contrast; different task |
| P4 | *System-Level HT Detection Using Side-Channel Power Analysis and ML* | Metadata **not confirmed** | Power side channel | Metrics **not confirmed** | Out of scope |
| P5 | *HT Detection Through RTL Features Extraction and ML* | Metadata **not confirmed** | RTL; supervised ML | Supplied notes: 22 + 22 circuits, ≈ 99.93% | Nearest static RTL comparator |
| P6 | Mondol, Vafaei, Azar, Farahmandi, Tehranipoor. *RL-TPG.* DATE 2024, pp. 1–6 | Metadata V-abs (dblp) | RTL dynamic; RL test-pattern generation with static analyzer, coverage and security-asset monitors | Supplied text: all embedded vulnerabilities triggered, ≈ 90% coverage, ≈ 192 s; manual security cover statements | Closest dynamic RTL RL work |

### 4.2 Gate-level trigger activation (statistical and RL)

| Work | Verified | Method | Key facts | What it does not cover (for us) |
|---|---|---|---|---|
| MERO. Chakraborty et al., CHES 2009 | V-cite | Tests that excite each rare net N times | Classic baseline; DETERRENT reports poor scaling to large designs | Sequential transaction-level triggers |
| TARMAC. Lyu and Mishra, IEEE TCAD 40(7), 2021 | V-cite | Maximal-clique sampling of rare nets | Sensitive to sampling randomness (per DETERRENT) | Same |
| TGRL. Pan and Mishra, ASP-DAC 2021, pp. 408–413, doi:10.1145/3394885.3431595 | V-abs | RL with SCOAP controllability/observability + signal rareness | Reports +14.5% trigger coverage and 6.5× faster test generation on average | Netlist-level; bit-flip actions; combinational trigger model |
| DETERRENT. Gohil, Patnaik, Guo, Kalathil, Rajendran, DAC 2022, doi:10.1145/3489517.3530518 | V-full | PPO selects sets of mutually compatible rare nets; SAT generates patterns; action masking | 169× fewer patterns, 95.75% coverage; rareness threshold 0.1; trigger width 4 ⇒ ≈ 10⁻⁴ random activation; **assumes full scan for sequential circuits**; code released | Full-scan assumption removes sequential depth; rarity parameterized by width × threshold (useful precedent for our sweep) |
| AdaTest. Chen, Zhang, Huang, Koushanfar, ACM TECS 22(2), 2023 | V-abs | RL + adaptive sampling; rare nodes via transition probability + SCOAP; on-chip emulation | Up to two orders of magnitude faster generation and smaller test sets | Netlist-level; hardware-accelerated |
| Trojan Playground. Sarihi, Patooghy, Jamieson, Badawy, *J. Supercomputing* 80:14295–14329, 2024 | V-abs | RL for both insertion and detection | ISCAS-85 (combinational); benchmark and test vectors on GitHub | Combinational gate-level only |

### 4.3 RTL / HLS dynamic, symbolic and formal

| Work | Verified | Method | Key facts | Relation to us |
|---|---|---|---|---|
| Ahmed, Farahmandi, Iskander, Mishra, ITC 2018 | V-abs | Concrete simulation interleaved with symbolic execution | Directed tests for rare branches and assignments in RTL | Formal/directed alternative; possible B-class comparator |
| Cruz, Farahmandi, Ahmed, Mishra, VLSID 2018 | V-cite | ATPG + model checking | RTL | Formal alternative |
| AFL-SHT. Le, Große, Bruns, Drechsler, DATE 2019 | V-cite | Coverage-guided fuzzing on SystemC HLS | Per FuCE, fails on complex comparator guards | Fuzzing lineage |
| SCT-HTD. Lin, Chen, Xie, DATE 2020 | V-cite | Selective concolic testing on SystemC | Per FuCE, memory blow-up on loops | Concolic lineage |
| FuCE. Debnath, Chowdhury, Saha, Sur-Kolay, arXiv:2111.00805 | V-full (preprint; venue **not confirmed**) | AFL + S2E concolic; detection by output comparison with a golden model | S3CBench SystemC; sequential Trojan types (SWM/SWOM) | HLS level; golden-model assumption; fuzzing-based baseline idea |
| Dai and Yavuz, *Detecting HTs using Model Guided Symbolic Execution*, GLSVLSI 2024, pp. 569–573 | V-abs | Fuzzing + static analysis build models of suspicious elements that guide symbolic execution | Average 445× speed-up for timing-based HTs and 27× for input-dependent HTs | **Strongest neighbour for sequential (timing-based) triggers at RTL.** Must read in full |
| Dai, Liu, Arias, Guo, Yavuz, *Evaluating the Effectiveness of HT Detection Approaches at RTL*, HOST 2025, pp. 250–260 | Metadata only (dblp) | Evaluation study | Content **not read** | **Highest-priority read**: may overlap our evaluation contribution |

### 4.4 Hardware fuzzing

| Work | Verified | Coverage signal | Relation |
|---|---|---|---|
| RFUZZ. Laeufer et al., ICCAD 2018 | V-cite | Mux-control coverage | Baseline lineage for B3 |
| DifuzzRTL. Hur et al., IEEE S&P 2021 | Not verified in this review | Register coverage | Same |
| Trippel et al., *Fuzzing Hardware Like Software*, arXiv:2102.02308 (published venue to verify) | V-cite (arXiv) | Software fuzzers on Verilator models | Same |
| VGF: Value-Guided Fuzzing. Dai et al., arXiv:2312.06580 | V-abs | Internal state/value coverage, HDL-agnostic via VPI/DPI/VHPI/FLI | **Close to our GB probe idea**; must differentiate |
| DirectFuzz; PROFUZZ (arXiv:2509.20808); TargetFuzz (arXiv:2509.26509) | V-abs (PROFUZZ, TargetFuzz) | Directed graybox fuzzing | Directed alternatives |

### 4.5 ML/RL for coverage closure in verification (not HT-specific)

| Work | Verified | Notes |
|---|---|---|
| Hughes et al., *Doing better than Random*, arXiv 2019 | V-cite | Supervised + Q-learning for functional coverage |
| Pfeifer et al., DATE 2020 | V-cite | RL for directed tests in shared-memory verification |
| Choi et al., DAC 2021 | V-cite | Deep RL for dynamic DRAM verification |
| VeRLPy. Shibu et al., arXiv 2021 | V-cite | Python RL library for verification (cocotb) |
| Dinu et al., *Micromachines* 2022 | V-abs | RL made affordable for verification engineers |
| Huang et al., *Test parameter tuning with black-box optimization*, DVCon US 2022 | V-cite | **Knob tuning precedent**; motivates baseline B2 |
| Tweehuysen et al., ETS 2023 | V-cite | Actor-critic stimulus generation, SV-UVM |
| Ohana, DVCon US 2023 | V-cite | Deep RL functional-coverage closure |
| **Gadde, Nalapat, Kumar, Lettnin, Kunz, Simon.** *Efficient Stimuli Generation using RL in Design Verification.* SMACD 2024, arXiv:2405.19815 | V-full | Design-agnostic: parses ports, auto-generates SV testbench and Gym env; RL ↔ simulator via DPI-C client socket; actions = port values per clock; reward ±1/0 on code-coverage change; PPO/A2C/DQN; six designs. **FIFO: 23 random stimuli vs 22–31 RL**, i.e. no gain |
| Review of ML for micro-electronic design verification, arXiv:2503.11687 | V-abs | Survey for the CDG section |

**This is the "Gadde et al." item the advisor could not verify.**

### 4.6 Benchmarks and Trojan generation

| Work | Verified | Key facts | Consequence for us |
|---|---|---|---|
| Shakya et al., *Benchmarking of HTs and Maliciously Affected Circuits*, JHSS 1(1), 2017 | V-cite | Trust-Hub benchmark paper | Cite as benchmark source |
| **Krieg, *Reflections on Trusting TrustHUB*, ICCAD 2023**, doi:10.1109/ICCAD57390.2023.10323782 | V-full | Correctness/Maliciousness/Stealthiness/Persistence framework; **only 3 of 83** designs effective (BasicRSA-T100, memctrl-T100, wb_conmax-T300). Many AES and all PIC16F84: trigger behaviour disappears after synthesis. RS232 RTL host UART cannot send data. Some netlist triggers unsatisfiable | Screening protocol (scope §3.3) is mandatory; refines the advisor's benchmark list |
| TRIT. Cruz, Huang, Mishra, Bhunia, DATE 2018 | V-abs | Netlist-level configurable insertion; activation probability configurable | Precedent for rarity control; not RTL |
| DTjRTL. Dai, Liu, Arias, Guo, Yavuz, GLSVLSI 2024, pp. 465–470 | V-abs | Automatic, configurable dynamic functional HT insertion at RTL | **Candidate source for Tier-B**; check tool availability |
| TrojanGYM. Sreekumar, Wang, et al., arXiv:2601.17178 (2026) | V-abs | LLM agents insert RTL HTs with GNN detectors in the loop; equivalence-gated | Source of diverse or adversarial Trojans; detectors are static |
| S3CBench. Veeranna and Schafer, JHSS 2017 | V-cite (via FuCE) | SystemC Trojans typed comb/seq trigger × with/without payload memory | Payload taxonomy precedent |
| SENTAUR. Bhandari et al., arXiv:2407.12352 | V-abs | LLM-based Trojan assessment; restates the Trust-Hub validity problem | Supporting citation |

### 4.7 Static classifiers (contrast only)

P2, P3, P5; TROJAN-GUARD (Thorat, Hasan, Ding, Shi, arXiv:2506.17894, 2025; GNN on RTL; precision 98.66%, recall 92.30% on a custom dataset; V-abs); code2vec attention detector (DATE 2026; V-abs). These classify designs and do not generate stimulus. Their accuracy is never compared with activation metrics.

---

## 5. Cross-paper metric map

| Metric family | Static classifiers | Gate-level RL | Fuzzing / CDG | This project |
|---|---|---|---|---|
| Accuracy / F1 / AUC | Common | Rare | No | Not a headline metric |
| Trigger coverage (fraction of sampled triggers hit) | No | Common (DETERRENT, TGRL) | No | Reported per rarity level as activation rate |
| Tests or time to activation | No | Partly | Time-to-bug | Primary, censored |
| Activation frontier across rarity | No | Partial (DETERRENT trigger width) | No | Primary summary |
| Detection separate from activation | No | No | No | Primary (payload classes) |
| Clean-DUT FPR | As classification FP | No | Rare | Mandatory |
| Coverage | No | No | Central | Secondary proxy |
| Overhead | Sometimes | Sometimes | Sometimes | Mandatory breakdown |
| Benchmark validity screening | No | No | No | Mandatory (Krieg) |

---

## 6. Gap synthesis

### 6.1 What the literature now establishes

1. RL can activate rare combinational triggers in gate-level netlists (TGRL, DETERRENT, AdaTest, Trojan Playground), usually with full-scan access and rare-net analysis.
2. RL can guide RTL security test generation with coverage and security monitors (RL-TPG).
3. Fuzzing and concolic methods reach deep conditions in RTL and HLS; model-guided symbolic execution handles timing-based Trojans at RTL (Dai and Yavuz 2024).
4. Design-agnostic RL stimulus generation with a DPI-C loop and coverage reward exists for coverage closure (Gadde 2024).
5. Knob-level test-parameter optimization exists in CDG (Huang, DVCon 2022).
6. Trust-Hub results are fragile: most benchmarks have undocumented defects (Krieg 2023).

### 6.2 What this review has not found (candidate gap, not a confirmed novelty)

No work found so far simultaneously:

- targets **sequential/temporal RTL triggers** through a **UVM transaction-level** policy, without scan access;
- uses **non-oracular, pre-registered** feedback with blue/red separation;
- evaluates on **screened third-party** plus **rarity-controlled generated** Trojans with a **rarity sweep** and activation frontier;
- separates **activation from detection** using delayed, latent and masked payloads;
- compares against CR, **knob-space black-box optimization** and **coverage-guided fuzzing** under one budget.

**Highest risks to this gap:** Dai et al. HOST 2025 (not yet read), Dai and Yavuz GLSVLSI 2024, VGF.

### 6.3 Claims removed because prior work covers them

| Previously considered claim | Covered by |
|---|---|
| "First to use RL at RTL for HT/security test generation" | TGRL, RL-TPG |
| "Closed-loop online UVM coverage-to-reward via DPI-C" as a contribution | Gadde 2024 (DPI-C socket, coverage reward) |
| "Design-agnostic RL stimulus generation" | Gadde 2024 (port-level) |
| "Knob/parameter-level adaptive stimulus" | Huang DVCon 2022 and CDG literature |

---

## 7. Candidate contributions, ranked by defensibility

| # | Candidate | Tier | Minimum evidence | Main risk |
|---|---|---|---|---|
| C1 | Rigorous evaluation protocol: screened Trojans, rarity sweep, pre-registration, activation/detection separation, censoring | Q2 | Public protocol, scripts, screening table, per-seed data | Dai et al. HOST 2025 overlap |
| C2 | Empirical result: transaction-level RL shifts the activation frontier for sequential triggers versus B0–B3 on ≥3 DUTs | Q2 | Frontier and RMST differences with CIs on test split | Null result (G2 pilot handles this) |
| C3 | Mechanism: trigger-agnostic, sequence-aware structural progress reward (GB) | Q1 | Ablation GB vs BB; beats B4–B5; differentiation from VGF, TGRL, DETERRENT, Dai and Yavuz | Too close to VGF value coverage |

### Weak claims to avoid

- "First RL for Trojan detection at RTL."
- "Our DPI-C coverage-reward loop is novel."
- Any comparison of activation metrics with classifier accuracy.
- Any Trust-Hub result without screening.

### Stronger, falsifiable candidate claim

> Under a pre-registered, non-oracular protocol, a transaction-level RL policy over DUT-agnostic UVM knobs activates sequential-trigger RTL Trojans at rarities X to Y orders of magnitude beyond constrained-random, knob-space black-box search and coverage-guided fuzzing, on screened third-party and generated Trojans across ≥3 DUTs, and detects delayed or latent payloads with latency Z.

X, Y and Z are placeholders until data exist.

---

## 8. Proposed research problem (revised)

> Given RTL IPs that may contain unknown, reachable, sequential-trigger Trojans, how can a policy set DUT-agnostic UVM knobs using only spec-level, and optionally automatically extracted structural, feedback so that it activates rarer triggers and detects their payloads within a fixed budget, compared with constrained-random, black-box knob search and coverage-guided fuzzing?

---

## 9. Evaluation criteria to carry forward

| Criterion | Operational test |
|---|---|
| Benchmark validity | Screening S1–S7 published per Trojan |
| Trigger reachability | Directed test by red team |
| Rarity | Empirical p under frozen π₀; sweep levels |
| Detection validity | Fires on Trojan; silent on matched clean traffic |
| Non-oracularity | Pre-registration hashes; blue/red separation; interface audit |
| Fairness | Same DUTs, detectors, coverage, seeds, cycle and wall-clock budget |
| Statistical validity | ≥10 seeds, per-seed data, CIs, effect sizes, censoring |
| Generalization | Dev/test split; held-out trigger class; ≥3 DUTs |
| Reproducibility | Versioned configs, logs, scripts, screening table |

---

## 10. Search protocol and reading queue

### 10.1 Search protocol (to run and log)

- **Databases:** IEEE Xplore, ACM DL, arXiv, dblp, Google Scholar; DVCon proceedings for CDG.
- **Strings:** ("hardware Trojan" OR "hardware trojan") AND ("reinforcement learning" OR fuzzing OR concolic OR "test generation") AND (RTL OR "register transfer"); ("coverage directed" OR "coverage closure") AND ("reinforcement learning" OR "black-box optimization") AND (UVM OR SystemVerilog); "Trojan insertion" AND (RTL OR automated OR LLM).
- **Window:** 2009–2026. Forward-citation check on TGRL, DETERRENT, RL-TPG, Gadde 2024, Krieg 2023.
- **Log:** date, database, string, hit count, included/excluded with reason.

### 10.2 Reading queue (priority order)

- [ ] Dai et al., HOST 2025: overlap with C1/C2
- [ ] Dai and Yavuz, GLSVLSI 2024: full text; how timing-based HTs are handled
- [ ] DTjRTL: tool availability, trigger/payload classes, rarity control
- [ ] VGF full text: differentiate from GB probes
- [ ] RL-TPG full text: state, action, reward; benchmarks
- [ ] Huang et al., DVCon 2022: knob-tuning method for baseline B2
- [ ] P2–P5 full metadata (authors, venue, year, DOI)
- [ ] TrojanGYM: usable Trojan set for a held-out test split?

---

## 11. Advisor-facing summary

1. The advisor's benchmark concern is confirmed and sharpened by Krieg (ICCAD 2023): most Trust-Hub designs need screening or repair before use.
2. "Gadde et al." is arXiv:2405.19815 (SMACD 2024). It removes two claims we previously considered: the DPI-C coverage-reward loop and design-agnostic RL stimulus.
3. Defensible contributions are an evaluation protocol plus an empirical frontier shift for sequential triggers (Q2). A structural-progress reward (gray-box) is the Q1 candidate, pending the G2 pilot and differentiation from VGF and Dai and Yavuz.

---

## References (links used in this review)

- Gadde et al., SMACD 2024: https://arxiv.org/abs/2405.19815
- Pan and Mishra, ASP-DAC 2021: https://www.doi.org/10.1145/3394885.3431595
- Gohil et al., DETERRENT, DAC 2022: https://arxiv.org/pdf/2208.12878
- Sarihi et al., Trojan Playground: https://link.springer.com/article/10.1007/s11227-024-05963-8
- Chen et al., AdaTest: https://arxiv.org/abs/2204.06117
- Debnath et al., FuCE: https://arxiv.org/pdf/2111.00805
- Dai and Yavuz, GLSVLSI 2024: https://par.nsf.gov/biblio/10548553
- Dai et al., DTjRTL, GLSVLSI 2024: https://par.nsf.gov/biblio/10548552
- Dai et al., VGF: https://arxiv.org/abs/2312.06580
- Krieg, ICCAD 2023: https://repositum.tuwien.at/bitstream/20.500.12708/191214/1/Krieg-2023-Reflections%20on%20Trusting%20TrustHUB-am.pdf
- Cruz et al., TRIT, DATE 2018: https://past.date-conference.com/proceedings-archive/2018/html/0176.html
- Sreekumar, Wang et al., TrojanGYM: https://arxiv.org/html/2601.17178
- Thorat et al., TROJAN-GUARD: https://arxiv.org/pdf/2506.17894
- Mondol et al., RL-TPG (dblp): https://dblp.org/pid/318/4499
- Dai et al., HOST 2025 (dblp): https://dblp.dagstuhl.de/pid/305/7308.html
