 */
control_unit #(
    .TAPS(TAPS)
) u_control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .data_valid(data_valid),
    .computation_done(computation_done),
    .coeff_programming(coeff_wr_en),
    .start_computation(start_computation),
    .buffer_select(buffer_select),
    .filter_busy(filter_busy)
);

// Output assignments
assign data_out = protected_result;
assign overflow_flag = protection_overflow;


(* KEEP_HIERARCHY = "TRUE" *) // Maintain module boundaries for timing analysis
(* MAX_FANOUT = 50 *)         // Limit fanout for timing closure

endmodule
