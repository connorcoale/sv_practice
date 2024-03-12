//                              -*- Mode: Verilog -*-
// Filename        : debouncer.sv
// Description     : debounce circuit for general usage
// Author          : Connor Coale
// Created On      : Mon Mar 11 18:19:17 2024
// Last Modified By: Connor Coale
// Last Modified On: Mon Mar 11 18:19:17 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module debouncer #(parameter integer WIDTH = 32,
                   parameter integer N = 1000 // debounce count limit
                   )
                  (
                   input logic  clk,
                   input logic  reset,
                   input logic  in,
                   output logic out
                   ) ;

   logic [WIDTH-1:0]            count, count_next;

   always @(posedge clk or posedge reset) begin
      if (reset) begin
         count <= '0;
         out <= '0;
      end
      else begin
         count <= count_next;
         out <= (count >= N);
      end
   end

   always_comb begin
      if (in) begin
         if (count >= N) count_next = count;
         else count_next = count + 1;
      end
      else count_next = '0;
   end
endmodule // debouncer
