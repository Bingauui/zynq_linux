`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/11 15:46:53
// Design Name: 
// Module Name: led
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


module led(
    output reg led_o,
    input  clk
    );
    reg [31:0]count;
    reg [7:0]led_count;
    reg [7:0]led_duty;
    reg updown;
    initial begin
        count = 32'b0;
        led_count = 8'b0;
        led_duty = 8'b0;
        updown = 8'b1;
    end
    always @ (posedge clk)begin
    if(count<32'd50000000)
        count<=count+1;
    else
        count<=0;
    end
    
    always @ (posedge clk)begin
    if((count % 32'd250000) == 32'b0)
        if(updown)
            begin
                led_duty<=led_duty+1;
                if(led_duty==200)
                    updown<=0;
            end
        else
            begin
                led_duty<=led_duty-1;
                if(led_duty==1)
                    updown<=1;
            end
    end    
    always @ (posedge clk)begin 
    led_count<=count&8'hff;
    if(led_count<led_duty)
        led_o<=1;
    else
        led_o<=0;
    end
endmodule
