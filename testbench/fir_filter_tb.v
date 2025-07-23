`timescale 1ns/1ps
module fir_filter_tb;

  parameter TAPS = 128;
  parameter BW = 16;
  parameter ACCW = 32;

  reg clk, rst_n;
  reg signed [BW-1:0] din;
  reg din_vld;
  wire signed [ACCW-1:0] dout;
  wire dout_vld;

  integer infile, i;
  reg signed [BW-1:0] stim_mem [0:1023];

  firmac #(TAPS, BW, ACCW) DUT (
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .din_vld(din_vld),
    .dout(dout),
    .dout_vld(dout_vld)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $readmemh("testbench/test_vectors/input_data.hex", stim_mem);
    rst_n = 0; din = 0; din_vld = 0;
    #20 rst_n = 1;

    for (i = 0; i < 1024; i = i + 1) begin
      @(posedge clk);
      din <= stim_mem[i];
      din_vld <= 1;
    end

    din_vld <= 0;
    #1000 $finish;
  end

endmodule
