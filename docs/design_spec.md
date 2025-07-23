# 📐 Design Specification – 128-Tap FIR Filter with Distributed Arithmetic

This document outlines the architecture, features, and interface details for the high-performance 128-tap FIR filter optimized for 1 GSPS operation using distributed arithmetic (DA).

---

## 📊 High-Level Specs

| Parameter           | Value                        |
|--------------------|------------------------------|
| Filter Type        | FIR (Distributed Arithmetic) |
| Taps               | 128                          |
| Input Width        | 16-bit signed                |
| Coefficient Width  | 16-bit signed (programmable) |
| Output Width       | 32-bit signed                |
| Throughput         | 1 GSPS                       |
| Latency            | 8 cycles                     |
| Clock Domains      | 1 GHz system, 100 MHz coeff  |
| Process Node       | 32nm                         |

---

## 🧱 Architecture Overview

### Block Diagram
> *(Add `docs/block_diagram.png` if available)*

### Key Components:
- **Input Buffering**: Ping-pong style registers
- **DA LUT Banks**: 4 banks for parallel access
- **Accumulator Tree**: Multi-operand, carry-select optimized
- **Coefficient Memory**: Dual-port RAM, supports runtime update
- **Control Logic**: FSM and clock domain synchronizers

---

## 🔄 Coefficient Update Specs

| Feature            | Value                    |
|-------------------|--------------------------|
| Clock             | 100 MHz                  |
| Update Latency    | <1.3 µs (128 updates)    |
| Glitch Isolation  | <1 ns                    |
| Runtime Impact    | Zero processing delay    |

---

## 🧩 Interface Signals

| Signal         | Dir | Width | Description                       |
|----------------|-----|-------|-----------------------------------|
| `clk_sys`      | In  | 1     | System clock (1 GHz)              |
| `clk_coeff`    | In  | 1     | Coefficient clock (100 MHz)       |
| `reset_n`      | In  | 1     | Active-low async reset            |
| `data_in`      | In  | 16    | 16-bit input samples              |
| `data_out`     | Out | 32    | 32-bit output result              |
| `coeff_in`     | In  | 16    | Coefficient input                 |
| `coeff_addr`   | In  | 7     | Coefficient address (128 depth)   |
| `coeff_wr_en`  | In  | 1     | Write enable for coefficient RAM  |
| `valid_out`    | Out | 1     | Output valid signal               |

---

## 📏 Constraints & Compliance

- Target Fmax: **1 GHz** (1 ns cycle)
- Hold margins: >50 ps across corners
- IEEE 754 Bit-accurate verified
- Power Budget: ≤ 1.3W
- RTL and CDC lint clean
- Synthesis with Synopsys Design Compiler

---
