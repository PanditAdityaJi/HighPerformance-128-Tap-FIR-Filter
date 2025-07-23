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
