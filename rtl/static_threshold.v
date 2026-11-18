
module threshold_static (
    input [31:0] total_score,
    input [31:0] threshold,
    output anomaly_flag
);

    assign anomaly_flag = (total_score > threshold);

endmodule
