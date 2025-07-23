import numpy as np
import os

# === Parameters ===
TAPS = 128
COEFF_WIDTH = 16  # bits
INPUT_FILE = "../test_vectors/input_data.hex"
OUTPUT_FILE = "output_ref.txt"
COEFF_FILE = "coefficients.txt"  # Optional: user-defined coefficients

# === Helper Functions ===
def read_hex_file(file_path):
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            data = [int(line.strip(), 16) for line in lines if line.strip()]
        return np.array(data, dtype=np.int16)
    except FileNotFoundError:
        raise FileNotFoundError(f"Missing file: {file_path}")

# === Read Input Stimuli ===
print("[INFO] Reading input vector...")
input_data = read_hex_file(INPUT_FILE)

# === Load or Initialize FIR Coefficients ===
if os.path.exists(COEFF_FILE):
    print(f"[INFO] Using coefficients from '{COEFF_FILE}'")
    coeff_data = np.loadtxt(COEFF_FILE, dtype=np.int16)
    if len(coeff_data) != TAPS:
        raise ValueError(f"Coefficient file must contain exactly {TAPS} values.")
else:
    print(f"[INFO] Using default unity coefficients (all 1s)")
    coeff_data = np.ones(TAPS, dtype=np.int16)

# === FIR Filtering (Direct Form for Golden Ref) ===
print("[INFO] Performing convolution...")
filtered_output = np.convolve(input_data, coeff_data, mode='full')[:len(input_data)]

# === Save Output ===
np.savetxt(OUTPUT_FILE, filtered_output.astype(np.int32), fmt="%d")
print(f"[DONE] Filtered output written to '{OUTPUT_FILE}'")
