coefficient_memory #(
    .TAPS(TAPS),
    .COEFF_WIDTH(COEFF_WIDTH)
) u_coefficient_memory (
    .clk(clk),
    .rst_n(rst_n),
    
    // Programming interface
    .wr_en(coeff_wr_en),
    .wr_addr(coeff_addr),
    .wr_data(coeff_data),
    
    // Read interface for computation
    .rd_en(coeff_mem_enable),
    .rd_addr(coeff_mem_addr),
    .rd_data(coeff_mem_data)
);
