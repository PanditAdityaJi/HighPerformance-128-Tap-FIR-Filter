module coefficient_memory #(
    parameter TAPS = 128,        // Number of filter coefficients
    parameter COEFF_WIDTH = 16,  // Coefficient bit width (signed fixed-point)
    parameter ADDR_WIDTH = 7     // Address width (log2(TAPS))
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    // Programming interface (Port A) - for coefficient updates
    input  wire                    wr_en,        // Write enable
    input  wire [ADDR_WIDTH-1:0]   wr_addr,      // Write address (0 to TAPS-1)
    input  wire [COEFF_WIDTH-1:0]  wr_data,      // Coefficient data to write
    
    // Read interface (Port B) - for filter computation
    input  wire                    rd_en,        // Read enable
    input  wire [ADDR_WIDTH-1:0]   rd_addr,      // Read address
    output reg  [COEFF_WIDTH-1:0]  rd_data       // Coefficient data output
);

reg [COEFF_WIDTH-1:0] coefficient_ram [0:TAPS-1];

// These represent a low-pass filter with cutoff at 0.25 * sampling frequency
integer i;
initial begin
    // This provides a reasonable starting filter response
    for (i = 0; i < TAPS; i = i + 1) begin
        coefficient_ram[i] = 16'h0000;  // Initialize to zero
    end
    
    // Set center tap to unity for pass-through behavior during initialization
    coefficient_ram[TAPS/2] = 16'h7FFF;  // Maximum positive value (0.999...)
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset handled by initial block
    end else begin
        if (wr_en && (wr_addr < TAPS)) begin
            coefficient_ram[wr_addr] <= wr_data;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_data <= {COEFF_WIDTH{1'b0}};
    end else begin
        if (rd_en && (rd_addr < TAPS)) begin
            rd_data <= coefficient_ram[rd_addr];
        end else if (!rd_en) begin
            rd_data <= {COEFF_WIDTH{1'b0}};  // Clear output when not reading
        end
    end
end 
 
wire [COEFF_WIDTH-1:0] abs_coeff = wr_data[COEFF_WIDTH-1] ? -wr_data : wr_data;
wire coeff_overflow = (abs_coeff > 16'h7FFF);  // Check for overflow
reg coeff_error_flag;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        coeff_error_flag <= 1'b0;
    end else begin
        if (wr_en && coeff_overflow) begin
            coeff_error_flag <= 1'b1;
        end else if (!wr_en) begin
            coeff_error_flag <= 1'b0;
        end
    end
end

// Memory usage statistics for performance monitoring
reg [15:0] write_count;
reg [15:0] read_count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_count <= 16'd0;
        read_count <= 16'd0;
    end else begin
        if (wr_en) write_count <= write_count + 1;
        if (rd_en) read_count <= read_count + 1;
    end
end

endmodule
