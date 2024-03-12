//                              -*- Mode: Verilog -*-
// Filename        : counter.sv
// Description     : Counter which will count up to a specified input value and then send a
//                 : single pulse back to indicated it's done.
// Author          : Connor Coale
// Created On      : Mon Mar 11 17:22:35 2024
// Last Modified By: Connor Coale
// Last Modified On: Mon Mar 11 17:22:35 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module counter #(parameter integer WIDTH = 32)
   (
    input logic             clk,
    input logic             reset,
    input logic             enable,
    input logic [WIDTH-1:0] n, // n clk ticks to count
    output logic            done
    ) ;

   typedef enum             {
                             IDLE,
                             COUNT,
                             DONE
                             } state_t;
   state_t state, state_next;

   logic [WIDTH-1:0] n_reg;
   logic [WIDTH-1:0] count, count_next;
   logic             done_next;
   
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         state <= IDLE;
         count <= '0;
         done  <= '0;
         n_reg <= '0;
      end else begin
         state <= state_next;
         count <= count_next;
         done  <= done_next;
         n_reg <= n;
         
      end
   end

   always_comb begin
      // defaults
      state_next = state;
      count_next = '0;
      done_next = '0;

      case (state)
        IDLE: begin
           if (enable) begin
              state_next = COUNT;
              count_next = count + 1'b1;
           end
        end
        COUNT: begin
           count_next = count + 1'b1;
           if (count_next == n_reg) state_next = DONE;
        end
        DONE: begin
           done_next = 1'b1;
           state_next = IDLE;
        end
        default: begin
           state_next = IDLE;
        end
      endcase // case (state)
   end
endmodule // counter

