`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/26 01:09:14
// Design Name: 
// Module Name: led_axi_lite
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

module led_axi (
    // AXI-Lite 接口
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // LED 输出
    output reg         led_o,
    output wire        usb_clk_reset
);

    // AXI 寄存器地址定义
    localparam LED_DUTY_ADDR = 32'h40000000;
    localparam CLK_24M_RESET_ADDR = 32'h40001000;
    
    // AXI 状态机状态
    localparam IDLE   = 2'b00,
               WRITE  = 2'b01,
               READ   = 2'b10;
    
    reg [1:0] aw_state;
    reg [1:0] ar_state;
    reg [1:0] w_state;
    reg [1:0] r_state;
    
    // 寄存器
    reg [31:0] count;
    reg [7:0]  led_count;
    reg [7:0]  led_duty_reg;    // AXI可配置的占空比寄存器
    reg [7:0]  led_duty;        // 实际使用的占空比
    reg usb_clk_reset_reg;
    // AXI 信号
    reg        awready;
    reg        wready;
    reg        bvalid;
    reg [1:0]  bresp;
    reg        arready;
    reg        rvalid;
    reg [1:0]  rresp;
    reg [31:0] rdata;
    
    // 写地址通道
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_state <= IDLE;
            awready <= 1'b0;
        end else begin
            case (aw_state)
                IDLE: begin
                    if (s_axi_awvalid) begin
                        awready <= 1'b1;
                        aw_state <= WRITE;
                    end else begin
                        awready <= 1'b0;
                    end
                end
                WRITE: begin
                    awready <= 1'b0;
                    aw_state <= IDLE;
                end
            endcase
        end
    end
    
    // 写数据通道
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            w_state <= IDLE;
            wready <= 1'b0;
        end else begin
            case (w_state)
                IDLE: begin
                    if (s_axi_wvalid) begin
                        wready <= 1'b1;
                        w_state <= WRITE;
                    end else begin
                        wready <= 1'b0;
                    end
                end
                WRITE: begin
                    wready <= 1'b0;
                    w_state <= IDLE;
                    // 写寄存器逻辑
                    if (s_axi_awaddr == LED_DUTY_ADDR) begin
                        // 只取低8位作为占空比，范围0-255
                        led_duty_reg <= s_axi_wdata[7:0];
                    end
                    if (s_axi_awaddr == CLK_24M_RESET_ADDR) begin
                        usb_clk_reset_reg <= s_axi_wdata[0];
                    end
                end
            endcase
        end
    end
    
    reg [1:0] b_state;
    // 写响应通道
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            b_state <= IDLE;
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end else begin
            case (b_state)
                IDLE: begin
                    if (awready && wready) begin
                        bvalid <= 1'b1;
                        bresp <= 2'b00; // OKAY
                        b_state <= WRITE;
                    end else begin
                        bvalid <= 1'b0;
                    end
                end
                WRITE: begin
                    if (s_axi_bready) begin
                        bvalid <= 1'b0;
                        b_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 读地址通道
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            ar_state <= IDLE;
            arready <= 1'b0;
        end else begin
            case (ar_state)
                IDLE: begin
                    if (s_axi_arvalid) begin
                        arready <= 1'b1;
                        ar_state <= READ;
                    end else begin
                        arready <= 1'b0;
                    end
                end
                READ: begin
                    arready <= 1'b0;
                    ar_state <= IDLE;
                end
            endcase
        end
    end
    
    // 读数据通道
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            r_state <= IDLE;
            rvalid <= 1'b0;
            rresp <= 2'b00;
            rdata <= 32'b0;
        end else begin
            case (r_state)
                IDLE: begin
                    if (arready) begin
                        rvalid <= 1'b1;
                        rresp <= 2'b00; // OKAY
                        // 读取寄存器
                        if (s_axi_araddr == LED_DUTY_ADDR) begin
                            rdata <= {24'b0, led_duty_reg};
                        end else begin
                            rdata <= 32'b0;
                        end
                        if (s_axi_araddr == CLK_24M_RESET_ADDR) begin
                            rdata <= {31'b0, usb_clk_reset_reg};
                        end
                        r_state <= READ;
                    end else begin
                        rvalid <= 1'b0;
                    end
                end
                READ: begin
                    if (s_axi_rready) begin
                        rvalid <= 1'b0;
                        r_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // LED 控制逻辑
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            count <= 32'b0;
            led_count <= 8'b0;
            led_duty <= 8'd50;  // 默认占空比50%
            led_o <= 1'b0;
        end else begin
            // 每1ms更新一次占空比（50MHz时钟，计数值50000）
            if (count < 32'd50000) begin
                count <= count + 1;
            end else begin
                count <= 32'b0;
                // 从寄存器更新占空比
                led_duty <= led_duty_reg;
            end
            
            // PWM生成
            led_count <= count[7:0];  // 取计数值低8位
            if (led_count < led_duty) begin
                led_o <= 1'b1;
            end else begin
                led_o <= 1'b0;
            end
        end
    end
    
    // AXI 输出信号连接
    assign s_axi_awready = awready;
    assign s_axi_wready  = wready;
    assign s_axi_bvalid  = bvalid;
    assign s_axi_bresp   = bresp;
    assign s_axi_arready = arready;
    assign s_axi_rvalid  = rvalid;
    assign s_axi_rresp   = rresp;
    assign s_axi_rdata   = rdata;
    
    assign usb_clk_reset = usb_clk_reset_reg;

endmodule