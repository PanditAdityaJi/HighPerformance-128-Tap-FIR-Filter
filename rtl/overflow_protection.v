module overflow_protection #(
    parameter INPUT_WIDTH = 24,   // Internal accumulator width
    parameter OUTPUT_WIDTH = 16   // Final output data width
)(
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Data interface
    input  wire [INPUT_WIDTH-1:0]    data_in,      // Internal filter result
    input  wire                      data_valid,   // Input data valid
    
    // Control interface  
    input  wire [1:0]                overflow_mode, // 00: saturate, 01: wrap, 10: flag, 11: bypass
    
    // Output interface
    output reg  [OUTPUT_WIDTH-1:0]   data_out,     // Protected output
    output reg                       data_ready,   // Output valid signal
    output reg                       overflow_flag // Overflow detection flag
);

// Internal signals for overflow detection
wire signed [INPUT_WIDTH-1:0]    signed_input;
wire signed [OUTPUT_WIDTH-1:0]   saturated_positive;
wire signed [OUTPUT_WIDTH-1:0]   saturated_negative;
wire                             positive_overflow;
wire                             negative_overflow;
wire                             any_overflow;

// Type casting for signed arithmetic
assign signed_input = data_in;
assign saturated_positive = {1'b0, {(OUTPUT_WIDTH-1){1'b1}}}; // Maximum positive value
assign saturated_negative = {1'b1, {(OUTPUT_WIDTH-1){1'b0}}}; // Maximum negative value

assign positive_overflow = (signed_input > {{(INPUT_WIDTH-OUTPUT_WIDTH){1'b0}}, saturated_positive});
assign negative_overflow = (signed_input < {{(INPUT_WIDTH-OUTPUT_WIDTH){1'b1}}, saturated_negative});
assign any_overflow = positive_overflow | negative_overflow;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= {OUTPUT_WIDTH{1'b0}};
        data_ready <= 1'b0;
        overflow_flag <= 1'b0;
    end else begin
        if (data_valid) begin
            case (overflow_mode)
                2'b00: begin // Saturation mode
                    if (positive_overflow) begin
                        data_out <= saturated_positive;
                        overflow_flag <= 1'b1;
                    end else if (negative_overflow) begin
                        data_out <= saturated_negative;  
                        overflow_flag <= 1'b1;
                    end else begin
                        data_out <= signed_input[OUTPUT_WIDTH-1:0];
                        overflow_flag <= 1'b0;
                    end
                    data_ready <= 1'b1;
                end
                
                2'b01: begin // Wrap-around mode
                    data_out <= signed_input[OUTPUT_WIDTH-1:0];  // Natural truncation
                    overflow_flag <= any_overflow;  // Flag overflow but don't correct
                    data_ready <= 1'b1;
                end
                
                2'b10: begin // Flag mode
                    data_out <= signed_input[OUTPUT_WIDTH-1:0];
                    overflow_flag <= any_overflow;
                    data_ready <= 1'b1;
                end
                
                2'b11: begin // Bypass mode (for debugging)
                    data_out <= signed_input[OUTPUT_WIDTH-1:0];
                    overflow_flag <= 1'b0;  // No overflow checking
                    data_ready <= 1'b1;
                end
            endcase
        end else begin
            data_ready <= 1'b0;
            // Maintain overflow flag until next valid data
        end
    end
end


reg [31:0] total_samples;        // Total samples processed
reg [31:0] positive_overflow_count; // Count of positive overflows
reg [31:0] negative_overflow_count; // Count of negative overflows
reg [15:0] consecutive_overflows;    // Consecutive overflow counter

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        total_samples <= 32'd0;
        positive_overflow_count <= 32'd0;
        negative_overflow_count <= 32'd0;
        consecutive_overflows <= 16'd0;
    end else begin
        if (data_valid) begin
            total_samples <= total_samples + 1;
            
            if (positive_overflow) begin
                positive_overflow_count <= positive_overflow_count + 1;
                consecutive_overflows <= consecutive_overflows + 1;
            end else if (negative_overflow) begin
                negative_overflow_count <= negative_overflow_count + 1;
                consecutive_overflows <= consecutive_overflows + 1;
            end else begin
                consecutive_overflows <= 16'd0;
            end
        end
    end
end


// Overflow severity analysis for adaptive systems
wire [3:0] overflow_magnitude;
assign overflow_magnitude = positive_overflow ? 
    (signed_input[INPUT_WIDTH-1:OUTPUT_WIDTH-1] > 4'd15 ? 4'd15 : signed_input[INPUT_WIDTH-1:OUTPUT_WIDTH-1]) :
    (negative_overflow ? 
     ((-signed_input[INPUT_WIDTH-1:OUTPUT_WIDTH-1]) > 4'd15 ? 4'd15 : (-signed_input[INPUT_WIDTH-1:OUTPUT_WIDTH-1])) :
     4'd0);

// Peak detection for dynamic range analysis
reg [OUTPUT_WIDTH-1:0] peak_positive;
reg [OUTPUT_WIDTH-1:0] peak_negative;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        peak_positive <= {OUTPUT_WIDTH{1'b0}};
        peak_negative <= {1'b1, {(OUTPUT_WIDTH-1){1'b0}}};
    end else begin
        if (data_valid && !any_overflow) begin
            if (signed_input > 0 && signed_input[OUTPUT_WIDTH-1:0] > peak_positive) begin
                peak_positive <= signed_input[OUTPUT_WIDTH-1:0];
            end else if (signed_input < 0 && signed_input[OUTPUT_WIDTH-1:0] < peak_negative) begin
                peak_negative <= signed_input[OUTPUT_WIDTH-1:0];
            end
        end
    end
end

// Synthesis optimization attributes
(* KEEP = "TRUE" *)     // Preserve overflow detection logic
(* MAX_FANOUT = 10 *)   // Limit fanout for timing

endmodule
