module ping_pong_buffer #(
    parameter TAPS = 128,       // Filter length (buffer depth)
    parameter DATA_WIDTH = 16   // Data sample bit width
)(
    input  wire                         clk,
    input  wire                         rst_n,
    
    // Input data interface
    input  wire [DATA_WIDTH-1:0]        data_in,        // Incoming data samples
    input  wire                         data_valid,     // Input data valid signal
    
    // Control interface
    input  wire                         buffer_select,  // 0: ping active, 1: pong active
    input  wire                         start_computation, // Trigger for computation cycle
    
    // Output data interface  
    output wire [TAPS*DATA_WIDTH-1:0]   data_out,       // All samples for DA engine
    output wire                         data_valid_out  // Output data valid
);

// Dual buffer memory arrays - implemented as shift registers for FPGA efficiency
reg [DATA_WIDTH-1:0] ping_buffer [0:TAPS-1];
reg [DATA_WIDTH-1:0] pong_buffer [0:TAPS-1];

// Buffer management signals
reg ping_active;           // 1 when ping buffer is being filled
reg pong_active;           // 1 when pong buffer is being filled
reg [6:0] write_pointer;   // Current write position in active buffer
reg buffer_full;           // Active buffer is full and ready for computation
reg computation_in_progress; // DA engine is processing stable buffer

// Output multiplexing - select which buffer feeds the DA engine
wire [DATA_WIDTH-1:0] stable_buffer [0:TAPS-1];  // Buffer being processed
reg output_valid;

genvar i;
generate
    for (i = 0; i < TAPS; i = i + 1) begin : output_concat
        assign data_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = stable_buffer[i];
    end
endgenerate

generate
    for (i = 0; i < TAPS; i = i + 1) begin : buffer_mux
        assign stable_buffer[i] = buffer_select ? ping_buffer[i] : pong_buffer[i];
    end
endgenerate

assign data_valid_out = output_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ping_active <= 1'b1;       // Start with ping buffer active
        pong_active <= 1'b0;
        write_pointer <= 7'd0;
        buffer_full <= 1'b0;
        computation_in_progress <= 1'b0;
        output_valid <= 1'b0;
    end else begin
        // Handle incoming data samples
        if (data_valid && !buffer_full) begin
            write_pointer <= write_pointer + 1;
            
            // Check if current buffer is now full
            if (write_pointer == TAPS - 1) begin
                buffer_full <= 1'b1;
                write_pointer <= 7'd0;
                output_valid <= 1'b1;
            end
        end
        
        // Handle computation start
        if (start_computation && buffer_full && !computation_in_progress) begin
            computation_in_progress <= 1'b1;
            buffer_full <= 1'b0;
            
            // Swap active buffers
            ping_active <= ~ping_active;
            pong_active <= ~pong_active;
        end
        
        // This would typically be controlled by the main control unit
        if (computation_in_progress && !start_computation) begin
            computation_in_progress <= 1'b0;
            output_valid <= 1'b0;
        end
    end
end

integer j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < TAPS; j = j + 1) begin
            ping_buffer[j] <= {DATA_WIDTH{1'b0}};
        end
    end else begin
        if (data_valid && ping_active && !buffer_full) begin
            // Shift register operation: new sample enters at position 0
            ping_buffer[0] <= data_in;
            
            // Shift all existing samples to higher indices
            for (j = 1; j < TAPS; j = j + 1) begin
                ping_buffer[j] <= ping_buffer[j-1];
            end
        end
    end
end

integer k;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < TAPS; k = k + 1) begin
            pong_buffer[k] <= {DATA_WIDTH{1'b0}};
        end
    end else begin
        if (data_valid && pong_active && !buffer_full) begin
            // Shift register operation: new sample enters at position 0
            pong_buffer[0] <= data_in;
            
            // Shift all existing samples to higher indices  
            for (k = 1; k < TAPS; k = k + 1) begin
                pong_buffer[k] <= pong_buffer[k-1];
            end
        end
    end
end


// Buffer status monitoring for debugging and performance analysis
reg [31:0] samples_processed;
reg [15:0] buffer_switches;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        samples_processed <= 32'd0;
        buffer_switches <= 16'd0;
    end else begin
        if (data_valid) begin
            samples_processed <= samples_processed + 1;
        end
        
        if (start_computation) begin
            buffer_switches <= buffer_switches + 1;
        end
    end
end

// Synthesis optimization attributes
// These directives help achieve timing closure at high clock rates
(* RAM_STYLE = "REGISTERS" *) // Force register implementation for shift registers
(* SHREG_EXTRACT = "YES" *)   // Allow shift register inference
(* MAX_FANOUT = 16 *)         // Limit fanout for timing

endmodule
// This design pattern is widely applicable in streaming DSP applications where
// processing latency must not interrupt the input data flow.

endmodule
