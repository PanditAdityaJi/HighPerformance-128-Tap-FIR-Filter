module fir_filter_top #(
    parameter TAPS = 128,           // Number of filter taps
    parameter DATA_WIDTH = 16,      // Input/output data width
    parameter COEFF_WIDTH = 16,     // Coefficient width
    parameter INTERNAL_WIDTH = 24,  // Internal computation width for precision
    parameter DA_LUT_SIZE = 8       // Distributed arithmetic LUT address width
)(
    // Clock and reset
    input  wire                    clk,
    input  wire                    rst_n,
    
    // Data interface
    input  wire [DATA_WIDTH-1:0]   data_in,      // Input data samples
    input  wire                    data_valid,   // Input data valid signal
    output wire [DATA_WIDTH-1:0]   data_out,     // Filtered output
    output wire                    data_ready,   // Output data ready
    
    // Coefficient programming interface
    input  wire                    coeff_wr_en,  // Coefficient write enable
    input  wire [6:0]              coeff_addr,   // Coefficient address (0-127)
    input  wire [COEFF_WIDTH-1:0]  coeff_data,   // Coefficient data
    
    // Control and status
    input  wire [1:0]              overflow_mode, // 00: saturate, 01: wrap, 10: flag
    output wire                    overflow_flag, // Overflow detection flag
    output wire                    filter_busy    // Filter processing status
);

// Internal signals connecting major blocks
wire [DATA_WIDTH-1:0]     buffer_data_out;
wire                      buffer_data_valid;
wire [COEFF_WIDTH-1:0]    coeff_mem_data;
wire [6:0]                coeff_mem_addr;
wire [INTERNAL_WIDTH-1:0] da_result;
wire                      da_result_valid;
wire [DATA_WIDTH-1:0]     protected_result;
wire                      protection_overflow;

// Control signals from the main control unit
wire                      start_computation;
wire                      computation_done;
wire                      buffer_select;
wire                      coeff_mem_enable;
