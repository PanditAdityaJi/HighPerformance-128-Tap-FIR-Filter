
create_clock -name clk -period 1.0 [get_ports clk]   ;# 1 GHz clock

# === Input Delay ===
set_input_delay 0.1 -clock clk [get_ports din]
set_input_delay 0.1 -clock clk [get_ports din_vld]

# === Output Delay ===
set_output_delay 0.1 -clock clk [get_ports dout]
set_output_delay 0.1 -clock clk [get_ports dout_vld]

# === False Paths ===
# set_false_path -from [get_ports rst_n]

# === Max Transition Time (optional) ===
# set_max_transition 0.2 [all_outputs]

# === Driving & Load Conditions ===
set_driving_cell -lib_cell INVX1 -pin Y [get_ports din]
set_load 0.01 [get_ports dout]

