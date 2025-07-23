# ===============================
# FIR Filter DC Synthesis Script
# ===============================

# === Setup ===
set DESIGN "firmac"
set TOP_MODULE $DESIGN
set RTL_PATH "../src"
set SDC_FILE "constraints.sdc"
set REPORT_DIR "reports"
set NETLIST_DIR "netlist"

# === Libraries ===
set target_library "typical.db"
set link_library "* typical.db"

# === Design Compiler Initialization ===
set_app_var hdlin_auto_save_templates true
set_app_var sh_enable_page_mode true
set_app_var hdlin_infer_multibit true

# === Read Design ===
read_verilog $RTL_PATH/firmac.v
read_verilog $RTL_PATH/coeff_update.v
current_design $TOP_MODULE
link

# === Check Design ===
check_design
check_timing

# === Compile ===
compile_ultra

# === Reports ===
file mkdir $REPORT_DIR
report_area        > $REPORT_DIR/area.rpt
report_power       > $REPORT_DIR/power.rpt
report_timing      > $REPORT_DIR/timing.rpt
report_utilization > $REPORT_DIR/utilization.rpt

# === Write Netlist ===
file mkdir $NETLIST_DIR
write -format verilog -hierarchy -output $NETLIST_DIR/${DESIGN}_synth.v
write_sdf -version 3.0 $NETLIST_DIR/${DESIGN}.sdf
write_sdc $NETLIST_DIR/${DESIGN}.sdc

# === Save Design State ===
write -format ddc -hierarchy -output $NETLIST_DIR/${DESIGN}.ddc

echo "[INFO] Synthesis Complete for $TOP_MODULE"
