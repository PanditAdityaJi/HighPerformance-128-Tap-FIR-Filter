# High-Performance 128-Tap FIR Filter with Distributed Arithmetic

## 🧠 Project Overview

This project implements a high-throughput Finite Impulse Response (FIR) filter with **128 taps** using **Distributed Arithmetic (DA)**. It is optimized for **1 GSPS** operation with **16-bit coefficient precision**, making it ideal for high-performance **FPGA-based DSP applications** such as Software-Defined Radio (SDR).

---

## 🚀 Key Features

- **Filter Order**: 128 taps
- **Sample Rate**: 1 GSPS
- **Coefficient Precision**: 16-bit signed fixed-point
- **Architecture**: Distributed Arithmetic (DA)
- **Overflow Protection**: Saturation, wrap-around, error-flagging
- **Power/Area Efficiency**: ~40% hardware reduction vs traditional FIR
- **Adaptability**: Real-time coefficient updates via control logic

---

## 📐 Architecture Overview

### 🔁 Distributed Arithmetic Principle

Traditional FIR:
