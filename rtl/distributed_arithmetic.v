module distributed_arithmetic #(
    parameter TAPS = 128,           // Number of filter taps
    parameter DATA_WIDTH = 16,      // Input data bit width
    parameter COEFF_WIDTH = 16,     // Coefficient bit width  
    parameter INTERNAL_WIDTH = 24,  // Internal accumulator width
    parameter LUT_SIZE = 8,         // LUT address width (affects parallelism)
    parameter TAPS_PER_LUT = TAPS / (1 << LUT_SIZE) // Taps handled per LUT cycle
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,              // Begin computation
    input  wire [TAPS*DATA_WIDTH-1:0]   data_samples,       // All input samples
    input  wire                         data_valid,
    input  wire [COEFF_WIDTH-1:0]       coefficients,       // Coefficient from memory
    output reg  [6:0]                   coeff_addr,         // Address for coefficient memory
    output reg                          coeff_enable,       // Enable coefficient memory
    output reg  [INTERNAL_WIDTH-1:0]   result,             // Filter output
    output reg                          result_valid,       // Output valid signal
    output reg                          computation_done    // Computation cycle complete
);

// State machine for DA computation control
localparam IDLE = 3'b000,
           LOAD_COEFFS = 3'b001,
           COMPUTE_LUT = 3'b010, 
           BIT_SERIAL = 3'b011,
           ACCUMULATE = 3'b100,
           OUTPUT = 3'b101;

reg [2:0] state, next_state;

reg [INTERNAL_WIDTH-1:0] da_lut [0:(1<<LUT_SIZE)-1];
reg [INTERNAL_WIDTH-1:0] lut_out;

// Bit processing counters and control
reg [4:0] bit_counter;          // Tracks current bit position (0 to DATA_WIDTH-1)
reg [7:0] tap_group_counter;    // Tracks current group of taps being processed
reg [6:0] lut_addr_counter;     // Address counter for LUT population
reg lut_computation_done;

// Accumulator for final result assembly
reg [INTERNAL_WIDTH-1:0] partial_sum;
reg [INTERNAL_WIDTH-1:0] bit_weighted_sum;

// Coefficient storage for LUT generation
reg [COEFF_WIDTH-1:0] coeff_buffer [0:TAPS-1];
reg [6:0] coeff_load_addr;

// Extract specific data samples for current computation
wire [DATA_WIDTH-1:0] current_samples [0:TAPS-1];
genvar i;
generate
    for (i = 0; i < TAPS; i = i + 1) begin : sample_extract
        assign current_samples[i] = data_samples[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
    end
endgenerate

/**
 * State Machine Control Logic */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            if (start && data_valid)
                next_state = LOAD_COEFFS;
        end
        
        LOAD_COEFFS: begin
            if (coeff_load_addr == TAPS - 1)
                next_state = BIT_SERIAL;
        end
        
        BIT_SERIAL: begin
            if (lut_computation_done) begin
                if (bit_counter == DATA_WIDTH - 1)
                    next_state = OUTPUT;
                else
                    next_state = COMPUTE_LUT;
            end else begin
                next_state = COMPUTE_LUT;
            end
        end
        
        COMPUTE_LUT: begin
            if (lut_addr_counter == (1 << LUT_SIZE) - 1)
                next_state = ACCUMULATE;
        end
        
        ACCUMULATE: begin
            next_state = BIT_SERIAL;
        end
        
        OUTPUT: begin
            next_state = IDLE;
        end
    endcase
end

/**
 * Coefficient Loading Logic */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        coeff_load_addr <= 7'd0;
        coeff_enable <= 1'b0;
        coeff_addr <= 7'd0;
    end else begin
        case (state)
            IDLE: begin
                coeff_load_addr <= 7'd0;
                coeff_enable <= 1'b0;
                coeff_addr <= 7'd0;
            end
            
            LOAD_COEFFS: begin
                coeff_enable <= 1'b1;
                coeff_addr <= coeff_load_addr;
                
                if (coeff_load_addr > 0) begin
                    coeff_buffer[coeff_load_addr - 1] <= coefficients;
                end
                
                if (coeff_load_addr < TAPS - 1) begin
                    coeff_load_addr <= coeff_load_addr + 1;
                end else begin
                    // Store the last coefficient
                    coeff_buffer[TAPS - 1] <= coefficients;
                    coeff_enable <= 1'b0;
                end
            end
            
            default: begin
                coeff_enable <= 1'b0;
            end
        endcase
    end
end

/**
 * Distributed Arithmetic Lookup Table Generation */
integer j, k;
reg [LUT_SIZE-1:0] lut_address;
reg [INTERNAL_WIDTH-1:0] lut_entry_sum;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_addr_counter <= 8'd0;
        lut_computation_done <= 1'b0;
    end else begin
        case (state)
            COMPUTE_LUT: begin
                
                lut_entry_sum = {INTERNAL_WIDTH{1'b0}};
                
                for (j = 0; j < (1 << LUT_SIZE); j = j + 1) begin
                    if (lut_addr_counter == j) begin
                        for (k = 0; k < (1 << LUT_SIZE); k = k + 1) begin
                            // Check if bit k of the LUT address is set
                            if (j[k]) begin
                                // Add corresponding coefficient to the sum
                                lut_entry_sum = lut_entry_sum + 
                                    {{(INTERNAL_WIDTH-COEFF_WIDTH){coeff_buffer[tap_group_counter * (1<<LUT_SIZE) + k][COEFF_WIDTH-1]}},
                                     coeff_buffer[tap_group_counter * (1<<LUT_SIZE) + k]};
                            end
                        end
                        da_lut[j] <= lut_entry_sum;
                    end
                end
                
                if (lut_addr_counter < (1 << LUT_SIZE) - 1) begin
                    lut_addr_counter <= lut_addr_counter + 1;
                end else begin
                    lut_addr_counter <= 8'd0;
                    lut_computation_done <= 1'b1;
                end
            end
            
            ACCUMULATE: begin
                lut_computation_done <= 1'b0;
            end
            
            default: begin
                lut_addr_counter <= 8'd0;
                lut_computation_done <= 1'b0;
            end
        endcase
    end
end

/**
 * Bit-Serial Processing and Accumulation */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_counter <= 5'd0;
        tap_group_counter <= 8'd0;
        partial_sum <= {INTERNAL_WIDTH{1'b0}};
        bit_weighted_sum <= {INTERNAL_WIDTH{1'b0}};
    end else begin
        case (state)
            BIT_SERIAL: begin
                if (lut_computation_done) begin
                    // Form LUT address from current bit of samples in current group
                    for (j = 0; j < (1 << LUT_SIZE); j = j + 1) begin
                        lut_address[j] = current_samples[tap_group_counter * (1<<LUT_SIZE) + j][bit_counter];
                    end
                    
                    lut_out = da_lut[lut_address];
                    
                    bit_weighted_sum <= lut_out << bit_counter;
                    
                    if (tap_group_counter < (TAPS / (1 << LUT_SIZE)) - 1) begin
                        tap_group_counter <= tap_group_counter + 1;
                    end else begin
                        tap_group_counter <= 8'd0;
                        if (bit_counter < DATA_WIDTH - 1) begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
            end
            
            ACCUMULATE: begin
                partial_sum <= partial_sum + bit_weighted_sum;
            end
            
            IDLE: begin
                bit_counter <= 5'd0;
                tap_group_counter <= 8'd0;
                partial_sum <= {INTERNAL_WIDTH{1'b0}};
                bit_weighted_sum <= {INTERNAL_WIDTH{1'b0}};
            end
        endcase
    end
end

/**
 * Output Generation */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result <= {INTERNAL_WIDTH{1'b0}};
        result_valid <= 1'b0;
        computation_done <= 1'b0;
    end else begin
        case (state)
            OUTPUT: begin
                result <= partial_sum;
                result_valid <= 1'b1;
                computation_done <= 1'b1;
            end
            
            default: begin
                result_valid <= 1'b0;
                computation_done <= 1'b0;
            end
        endcase
    end
end

// Synthesis directives for optimal implementation
(* RAM_STYLE = "DISTRIBUTED" *) reg [INTERNAL_WIDTH-1:0] da_lut_synthesis [0:(1<<LUT_SIZE)-1];
(* MAX_FANOUT = 32 *) wire [LUT_SIZE-1:0] lut_addr_wire = lut_address;

// The distributed LUT implementation leverages FPGA LUT resources efficiently
// by storing the lookup tables in distributed RAM rather than block RAM,
// providing faster access times critical for high-speed operation.

endmodule
