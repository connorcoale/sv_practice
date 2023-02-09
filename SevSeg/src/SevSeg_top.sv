`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2023 11:48:31 AM
// Design Name: 
// Module Name: SevSeg_top
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


module SevSeg_top(
    input  logic CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [1:0] btn,
    output logic [7:0] ja
    );
    
    logic [3:0] dig0;
    logic [3:0] dig1;
    
    SevSeg display1(.clk(CLK100MHZ), .dig0(dig0), .dig1(dig1), .cat(ja[6:0]), .an(ja[7]));
    
    always_ff @(posedge CLK100MHZ) begin
        dig0 <= btn[0] ? sw : dig0; // I think the buttons are active low
        dig1 <= btn[1] ? sw : dig1;
    end
endmodule
