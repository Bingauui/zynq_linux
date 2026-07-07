`timescale 1ns / 1ps

module clock_en (
    input  wire  clk_in,
    input  wire  clk_en,
    output wire  clk_out
);
    
    BUFGCE BUFGCE_inst (
        .O  (clk_out),
        .CE (clk_en),
        .I  (clk_in)
    );
    
endmodule