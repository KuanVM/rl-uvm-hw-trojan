# Research Protocol: Reinforcement Learning -Driven UVM Framework for Automated Hardware Trojan Activation and Detection

## 1. Project Objective
The primary objective of this research is to develop a closed-loop, Reinforcement Learning (RL)-driven Universal Verification Methodology (UVM) framework. By integrating a Q-learning agent directly into the UVM Sequencer via a real-time DPI-C bridge, this framework aims to autonomously generate targeted stimulus sequences to activate and detect rare Hardware Trojans, significantly outperforming traditional Constrained Random Verification (CRV).

## 2. Research Questions (RQs)
This study aims to answer the following quantifiable research questions:
* **RQ1 (Activation Efficiency):** Does RL-guided stimulus reduce the number of clock cycles or test cases required to trigger Hardware Trojans compared to CRV?
* **RQ2 (State-Space Exploration):** Does a reward function shaped by functional coverage enable the agent to navigate into rare state-spaces more effectively than rewards based strictly on toggle or code coverage?
* **RQ3 (Computational Overhead):** Is the simulation runtime cost of the online DPI-C architecture acceptable when compared to the benefits of accelerated Trojan activation and traditional offline vector generation?
* **RQ4 (Generalization):** Can the proposed RL-UVM methodology generalize across multiple classes of Trojans and different Design Under Test (DUT) architectures?

## 3. Hypotheses
* **$H_1$:** The RL-UVM framework will yield a statistically significant reduction in the median time-to-trigger (measured in clock cycles) compared to the CRV baseline.
* **$H_2$:** Under an identical simulation budget, RL-UVM will achieve a higher coverage percentage of predefined rare functional bins than CRV.
* **$H_3$:** The accelerated activation and detection benefits will remain consistent across at least two distinct DUTs (e.g., AES-128 and an IIR filter).
* **$H_4$:** The computational overhead introduced by the DPI-C bridge communication will not negate the overall simulation time saved by faster Trojan activation.

## 4. Evaluation Metrics
To ensure academic rigor, no single execution run will be reported. All configurations will be executed across 20 to 30 random seeds, prioritizing median and Interquartile Range (IQR) for central tendency analysis.

**4.1. Hardware & Simulation Metrics:**
* **Activation:** Cycles-to-trigger, tests-to-trigger, wall-clock simulation time.
* **Detection:** Detection latency (cycles), True-Positive Rate (TPR), False-Positive Rate (FPR).
* **Coverage:** Functional coverage, rare-bin coverage, cross coverage, and toggle coverage.
* **Computational Cost:** Simulator runtime, DPI-C transaction overhead, peak memory usage.
* **Physical PPA (FPGA):** LUT/ALM utilization, Flip-Flops, BRAM, Maximum Frequency ($F_{max}$), and power estimation.

**4.2. Reinforcement Learning Metrics:**
* Episodic reward, moving-average reward, attack success rate, and convergence episode.
* **Proposed Reward Function formulation:**
  $r_{t} = w_{c}\Delta C_{rare} + w_{n} + w_{t} \cdot \mathbb{1}(\text{triggered}) + w_{d} \cdot \mathbb{1}(\text{detected}) - w_{s}$
  *(Where $\Delta C_{rare}$ represents newly covered rare bins, and $w_s$ is a step penalty to encourage shorter activation sequences)*

## 5. Experimental Setup
* **Main DUT:** AES-128 Iterative Core (Secworks).
* **Secondary DUT:** Digital IIR/FIR Filter.
* **Threat Models (Trust-Hub Benchmarks):**
  * T1: Rare input pattern trigger (e.g., AES-T100).
  * T2: Long sequence/counter-based trigger (e.g., AES-T400).
  * T3: FSM-sequence-based trigger.
* **Verification Environment:** QuestaSim 2021 (UVM 1.2), standard DPI-C.
* **Physical Prototyping:** Terasic DE2i-150 (Intel Cyclone IV FPGA) integrated with NIOS II via Avalon-MM.

## 6. Baselines for Comparison
To validate the hypotheses, the proposed RL agent will be benchmarked against:
1. Standard CRV with reasonable constraints.
2. A Uniform Random policy (to address complex CRV biases).
3. A Random policy operating within the exact same action space as the RL agent.
4. An RL agent operating without coverage-directed reward shaping (Sparse reward only).