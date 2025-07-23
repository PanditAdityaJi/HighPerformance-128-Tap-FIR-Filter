ping_pong_buffer #(
    .TAPS(TAPS),
    .DATA_WIDTH(DATA_WIDTH)
) u_ping_pong_buffer (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_valid(data_valid),
    .buffer_select(buffer_select),          // Controlled by main control unit
    .start_computation(start_computation),   // Trigger for computation cycle
    .data_out(buffer_data_out),
    .data_valid_out(buffer_data_valid)
);
