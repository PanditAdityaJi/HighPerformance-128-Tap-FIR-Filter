`timescale 1ns/1ps
module firmac #(parameter TAPS=128, BW=16, ACCW=32)(
  input                     clk,
  input                     rst_n,
  input signed [BW-1:0]     din,
  input                     din_vld,
  output reg signed [ACCW-1:0] dout,
  output reg                dout_vld
);

  // Coefficient RAM
  reg signed [BW-1:0] coeffs [0:TAPS-1];

  // Shift Register for Input Samples (Ping-Pong)
  reg signed [BW-1:0] sample_buf [0:TAPS-1];
  integer i;

  // Accumulator
  reg signed [ACCW-1:0] acc;
  
  // State machine
  reg [$clog2(TAPS):0] tap_index;

  // Control logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < TAPS; i = i + 1)
        sample_buf[i] <= 0;
      tap_index <= 0;
      dout <= 0;
      acc <= 0;
      dout_vld <= 0;
    end else begin
      if (din_vld) begin
        // Shift in new sample
        for (i = TAPS-1; i > 0; i = i - 1)
          sample_buf[i] <= sample_buf[i-1];
        sample_buf[0] <= din;

        // Start accumulation
        acc <= 0;
        for (i = 0; i < TAPS; i = i + 1)
          acc <= acc + coeffs[i] * sample_buf[i];

        // Output result
        dout <= acc;
        dout_vld <= 1;
      end else begin
        dout_vld <= 0;
      end
    end
  end

endmodule
