//                              -*- Mode: Verilog -*-
// Filename        : monopulser.sv
// Description     : monopulser circuit for general use
// Author          : Connor Coale
// Created On      : Mon Mar 11 18:39:12 2024
// Last Modified By: Connor Coale
// Last Modified On: Mon Mar 11 18:39:12 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module monopulser (input logic  clk,
                   input logic  reset,
                   input logic  in,
                   output logic out
                   ) ;
   typedef enum {
                 WAIT_HIGH,
                 PULSE,
                 WAIT_LOW
                 } state_t;

   state_t state, state_next;
   always @(posedge clk or posedge reset) begin
      if (reset) begin
         out <= '0;
         state <= WAIT_HIGH;
      end
      else begin
         out <= (state == PULSE);
         state <= state_next;
      end
   end

   always_comb begin
      state_next = state;
      case (state)
        WAIT_HIGH: begin
           // transition only if we see input HIGH
           if (in) state_next = PULSE;
        end
        PULSE: begin
           // immediately, after 1 cycle, transition out of pulse state.
           state_next = WAIT_LOW;
        end
        WAIT_LOW: begin
           // transition only if we see input LOW
           if (~in) state_next = WAIT_HIGH;
        end
        default: begin
           state_next = WAIT_HIGH;
        end
      endcase // case (state)
   end

endmodule // monopulser
