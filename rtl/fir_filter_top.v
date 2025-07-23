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

ping_pong_buffer #(
    .TAPS(TAPS),
    .DATA_WIDTH(DATA_WIDTH)
) u_ping_pong_buffer (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_valid(data_valid),
    .buffer_select(buffer_select),          // Controlled by main control unit
    .start_computation(start_computation),   // Trigger for computation cycle
    .data_out(buffer_data_out),
    .data_valid_out(buffer_data_valid)
);


coefficient_memory #(
    .TAPS(TAPS),
    .COEFF_WIDTH(COEFF_WIDTH)
) u_coefficient_memory (
    .clk(clk),
    .rst_n(rst_n),
    
    // Programming interface
    .wr_en(coeff_wr_en),
    .wr_addr(coeff_addr),
    .wr_data(coeff_data),
    
    // Read interface for computation
    .rd_en(coeff_mem_enable),
    .rd_addr(coeff_mem_addr),
    .rd_data(coeff_mem_data)
);


distributed_arithmetic #(
    .TAPS(TAPS),
    .DATA_WIDTH(DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .INTERNAL_WIDTH(INTERNAL_WIDTH),
    .LUT_SIZE(DA_LUT_SIZE)
) u_distributed_arithmetic (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_computation),
    .data_samples(buffer_data_out),
    .data_valid(buffer_data_valid),
    .coefficients(coeff_mem_data),
    .coeff_addr(coeff_mem_addr),
    .coeff_enable(coeff_mem_enable),
    .result(da_result),
    .result_valid(da_result_valid),
    .computation_done(computation_done)
);


overflow_protection #(
    .INPUT_WIDTH(INTERNAL_WIDTH),
    .OUTPUT_WIDTH(DATA_WIDTH)
) u_overflow_protection (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(da_result),
    .data_valid(da_result_valid),
    .overflow_mode(overflow_mode),
    .data_out(protected_result),
    .data_ready(data_ready),
    .overflow_flag(protection_overflow)
);


control_unit #(
    .TAPS(TAPS)
) u_control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .data_valid(data_valid),
    .computation_done(computation_done),
    .coeff_programming(coeff_wr_en),
    .start_computation(start_computation),
    .buffer_select(buffer_select),
    .filter_busy(filter_busy)
);

// Output assignments
assign data_out = protected_result;
assign overflow_flag = protection_overflow;

(* KEEP_HIERARCHY = "TRUE" *) // Maintain module boundaries for timing analysis
(* MAX_FANOUT = 50 *)         // Limit fanout for timing closure

endmodule
