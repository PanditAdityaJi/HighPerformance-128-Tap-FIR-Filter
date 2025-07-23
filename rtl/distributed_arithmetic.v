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
