
module control_unit #(
    parameter TAPS = 128,                    // Filter length
    parameter COMPUTATION_CYCLES = 256       // Cycles needed for DA computation
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Data flow control
    input  wire        data_valid,           // New sample available
    input  wire        computation_done,     // DA engine completed processing
    input  wire        coeff_programming,    // Coefficient update in progress
    
    // Control outputs
    output reg         start_computation,    // Trigger DA engine
    output reg         buffer_select,        // Ping-pong buffer control
    output reg         filter_busy          // System busy indicator
);

// State machine definitions
localparam IDLE = 4'b0000,
           WAIT_BUFFER_FILL = 4'b0001,
           START_COMPUTATION = 4'b0010,
           COMPUTING = 4'b0011,
           SWITCH_BUFFERS = 4'b0100,
           ERROR_RECOVERY = 4'b0101,
           COEFF_UPDATE = 4'b0110;

reg [3:0] state, next_state;

// Internal counters and flags
reg [6:0] sample_counter;        // Track samples in current buffer
reg [8:0] computation_timer;     // Monitor computation duration
reg buffer_ready;                // Current buffer has TAPS samples
reg computation_timeout;         // DA engine took too long
reg system_error;                // General error condition


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
            if (data_valid && !coeff_programming) begin
                next_state = WAIT_BUFFER_FILL;
            end else if (coeff_programming) begin
                next_state = COEFF_UPDATE;
            end
        end
        
        WAIT_BUFFER_FILL: begin
            if (buffer_ready && !coeff_programming) begin
                next_state = START_COMPUTATION;
            end else if (coeff_programming) begin
                next_state = COEFF_UPDATE;
            end else if (system_error) begin
                next_state = ERROR_RECOVERY;
            end
        end
        
        START_COMPUTATION: begin
            next_state = COMPUTING;
        end
        
        COMPUTING: begin
            if (computation_done) begin
                next_state = SWITCH_BUFFERS;
            end else if (computation_timeout) begin
                next_state = ERROR_RECOVERY;
            end
        end
        endmodule 
