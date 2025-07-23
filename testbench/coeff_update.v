`timescale 1ns/1ps
module coeff_update #(parameter TAPS=128, BW=16)(
  input                      clk,
  input                      rst_n,
  input                      cfg_vld,
  input      [BW-1:0]        cfg_data,
  input                      cfg_done_in,
  output reg                 cfg_done_out
);

  reg signed [BW-1:0] coeffs [0:TAPS-1];
  reg [$clog2(TAPS):0] cfg_index;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cfg_index <= 0;
      cfg_done_out <= 0;
    end else begin
      if (cfg_vld) begin
        coeffs[cfg_index] <= cfg_data;
        cfg_index <= cfg_index + 1;

        if (cfg_index == TAPS-1) begin
          cfg_done_out <= 1;
        end else begin
          cfg_done_out <= 0;
        end
      end else if (cfg_done_in) begin
        cfg_done_out <= 0;
        cfg_index <= 0;
      end
    end
  end

endmodule
