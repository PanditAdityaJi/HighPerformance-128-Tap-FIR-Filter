import numpy as np

def load_data(filename):
    with open(filename, 'r') as f:
        return np.array([int(line.strip(), 16) for line in f])

def snr(signal, noise):
    power_signal = np.mean(signal**2)
    power_noise = np.mean((signal - noise)**2)
    return 10 * np.log10(power_signal / power_noise) if power_noise != 0 else np.inf

def analyze(ref_file, sim_file):
    ref = load_data(ref_file)
    sim = load_data(sim_file)
    
    if len(ref) != len(sim):
        min_len = min(len(ref), len(sim))
        ref, sim = ref[:min_len], sim[:min_len]

    mse = np.mean((ref - sim) ** 2)
    signal_snr = snr(ref, sim)
    delay = np.argmax(np.correlate(ref, sim, mode="full")) - (len(ref) - 1)

    print("=== Performance Report ===")
    print(f"Samples Compared : {len(ref)}")
    print(f"Mean Squared Error (MSE): {mse:.2f}")
    print(f"Signal-to-Noise Ratio  : {signal_snr:.2f} dB")
    print(f"Estimated Latency      : {delay} cycles")

if __name__ == "__main__":
    analyze("testbench/test_vectors/ref_output.hex", "testbench/test_vectors/sim_output.hex")
