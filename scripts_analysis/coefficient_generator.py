import numpy as np

TAPS = 128
BITS = 16
SCALE = 2**(BITS - 1) - 1

def sinc_lowpass(fc, num_taps):
    n = np.arange(num_taps) - (num_taps - 1) / 2
    h = np.sinc(2 * fc * n)
    w = np.hamming(num_taps)
    return h * w

def quantize_coeffs(coeffs):
    scaled = coeffs / np.max(np.abs(coeffs)) * SCALE
    return np.round(scaled).astype(np.int16)

def save_hex(coeffs, filename):
    with open(filename, 'w') as f:
        for coeff in coeffs:
            f.write(f"{coeff & 0xFFFF:04X}\n")

def save_txt(coeffs, filename):
    with open(filename, 'w') as f:
        for coeff in coeffs:
            f.write(f"{coeff}\n")

if __name__ == "__main__":
    fc = 0.1  # Cutoff freq (normalized: 0 < fc < 0.5)
    coeffs = sinc_lowpass(fc, TAPS)
    q_coeffs = quantize_coeffs(coeffs)
    
    save_hex(q_coeffs, "testbench/test_vectors/coeffs.hex")
    save_txt(q_coeffs, "testbench/test_vectors/coeffs.txt")
    print("[✓] FIR coefficients generated.")
