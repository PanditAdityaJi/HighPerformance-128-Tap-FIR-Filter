# synthesis_script.tcl - FIR Filter Synthesis Flow for Synopsys Design Compiler

# Output directories
set OUTDIR ./outputs
set NETLIST ${OUTDIR}/netlists/fir128_da_syn.v
set SDF     ${OUTDIR}/sdf/fir128_da_syn.sdf
set DDC     ${OUTDIR}/fir_filter_128_tap.ddc
set REPORTS ${OUTDIR}/reports

file mkdir -p $OUTDIR/netlists
file mkdir -p $OUTDIR/sdf
file mkdir -p $REPORTS

# Define top module
set TOP_MODULE fir_filter_top

# Read RTL
read_file -format verilog {
    ../rtl/fir_filter_top.v
    ../rtl/distributed_arithmetic.v
    ../rtl/ping_pong_buffer.v
    ../rtl/overflow_protection.v
    ../rtl/clock_domain_crossing.v
    ../rtl/coefficient_memory.v
}

# Elaborate
current_design $TOP_MODULE
elaborate $TOP_MODULE
link

# Read constraints
source ../synthesis/constraints.sdc

# Set operating conditions
set_operating_conditions -library typical -analysis_type single -corner slow

# Design compiler optimizations
set_max_area 0
set_max_delay 1.0

# Clock gating & retiming (optional)
set_clock_gating_style -positive_edge_logic {integrated}
set_power_collapse true

# Compile
compile_ultra -gate_clock

# Write outputs
write -format verilog -hierarchy -output $NETLIST
write_sdf $SDF
write_file -format ddc -hierarchy -output $DDC
write_sdc $OUTDIR/netlists/fir128_da_constraints.sdc

# Reports
report_timing > ${REPORTS}/timing_report.txt
report_area   > ${REPORTS}/area_report.txt
report_power  > ${REPORTS}/power_report.txt
report_qor    > ${REPORTS}/qor_report.txt

# Exit DC
exit
