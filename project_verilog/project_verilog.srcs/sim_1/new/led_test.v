`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/11 17:40:20
// Design Name: 
// Module Name: led_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led_test();
    reg clk;
    wire led_out;
    initial begin
        clk = 1'b0;
    end
    always #1 clk = ~clk;
    led led_1(
        .clk(clk),
        .led_o(led_out)
    );
endmodule
