`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2023 11:05:56 AM
// Design Name: 
// Module Name: SevSeg
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


module SevSeg
    #(
    parameter GLOBAL_CLOCK_RATE = 100_000_000,
    parameter REFRESH_RATE = 200
    ) (
    input  logic clk,
    input  [3:0] dig0, // rightmost digit (least significant)
    input  [3:0] dig1, // most significant
    output logic [6:0] cat,
    output logic an
    );
    
    // Assume clock on Arty is 100MHz
    logic refresh;
    logic [$clog2(GLOBAL_CLOCK_RATE/REFRESH_RATE)-1:0] refresh_counter;
    localparam DIV_BY = GLOBAL_CLOCK_RATE/REFRESH_RATE;
    
    logic [6:0] bcd0_to_7seg;
    logic [6:0] bcd1_to_7seg;
    
    // Clocked logic
    always_ff @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        
        if (refresh_counter == DIV_BY) begin
            an <= ~an;
            refresh_counter <= 0;
        end
        
        cat <= (an) ? bcd0_to_7seg : bcd1_to_7seg;
    end
    
    // digit to BCD
    always_comb begin
        case (dig0)
                                     //gfedcba
            4'h0:    bcd0_to_7seg = 7'b1000000;
            4'h1:    bcd0_to_7seg = 7'b1111001;
            4'h2:    bcd0_to_7seg = 7'b0100100;
            4'h3:    bcd0_to_7seg = 7'b0110000;
            4'h4:    bcd0_to_7seg = 7'b0011001;
            4'h5:    bcd0_to_7seg = 7'b0010010;
            4'h6:    bcd0_to_7seg = 7'b0000010;
            4'h7:    bcd0_to_7seg = 7'b1111000;
            4'h8:    bcd0_to_7seg = 7'b0000000;
            4'h9:    bcd0_to_7seg = 7'b0010000;
            4'hA:    bcd0_to_7seg = 7'b0001000;
            4'hb:    bcd0_to_7seg = 7'b0000011;
            4'hC:    bcd0_to_7seg = 7'b1000110;
            4'hd:    bcd0_to_7seg = 7'b0100001;
            4'hE:    bcd0_to_7seg = 7'b0000110;
            4'hF:    bcd0_to_7seg = 7'b0001110;
            default: bcd0_to_7seg = 7'b1111111;
        endcase
        
        case (dig1)
            4'h0:    bcd1_to_7seg = 7'b1000000;
            4'h1:    bcd1_to_7seg = 7'b1111001;
            4'h2:    bcd1_to_7seg = 7'b0100100;
            4'h3:    bcd1_to_7seg = 7'b0110000;
            4'h4:    bcd1_to_7seg = 7'b0011001;
            4'h5:    bcd1_to_7seg = 7'b0010010;
            4'h6:    bcd1_to_7seg = 7'b0000010;
            4'h7:    bcd1_to_7seg = 7'b1111000;
            4'h8:    bcd1_to_7seg = 7'b0000000;
            4'h9:    bcd1_to_7seg = 7'b0010000;
            4'hA:    bcd1_to_7seg = 7'b0001000;
            4'hb:    bcd1_to_7seg = 7'b0000011;
            4'hC:    bcd1_to_7seg = 7'b1000110;
            4'hd:    bcd1_to_7seg = 7'b0100001;
            4'hE:    bcd1_to_7seg = 7'b0000110;
            4'hF:    bcd1_to_7seg = 7'b0001110;
            default: bcd1_to_7seg = 7'b1111111;
        endcase
    end
    
    
    
endmodule


