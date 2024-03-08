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
    parameter integer GLOBAL_CLOCK_RATE = 100_000_000,
    parameter integer REFRESH_RATE = 200
    ) (
       input logic        clk,
       input logic        reset,
       input logic        en,
       input [3:0]        dig0, // rightmost digit (least significant)
       input [3:0]        dig1, // most significant
       output logic [6:0] cat,
       output logic       an
       );

   logic [6:0]                                        bcd0_to_7seg;
   logic [6:0]                                        bcd1_to_7seg;
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

   localparam integer DivBy = GLOBAL_CLOCK_RATE/REFRESH_RATE;
   // Assume clock on Arty is 100MHz
   logic                  an_next;
   logic [6:0]            cat_next;
   logic                  refresh;
   logic [$clog2(GLOBAL_CLOCK_RATE/REFRESH_RATE)-1:0] refresh_counter;
   logic [$clog2(GLOBAL_CLOCK_RATE/REFRESH_RATE)-1:0] refresh_counter_next;

   // Clocked logic
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         refresh_counter <= 'd0;
         an <= 'd0;
         cat <= 'd0;
      end else begin
         refresh_counter <= refresh_counter_next;
         an <= an_next;
         cat <= cat_next;
      end
   end

   always_comb begin
      refresh_counter_next = refresh_counter + 1; // increment counter
      an_next = an; // normally stay the same

      if (refresh_counter == DivBy) begin // Need to flip which digit and reset counter!
         an_next = ~an;
         refresh_counter_next = 'd0;
      end

      if (en) cat_next = an ? bcd0_to_7seg : bcd1_to_7seg;
      else    cat_next = 7'b111_1111; // when not enabled, cathodes all get 1s to be off.
   end
endmodule


