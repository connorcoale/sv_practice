//                              -*- Mode: Verilog -*-
// Filename        : spi_master.sv
// Description     : simple spi master module
// Author          : Connor Coale
// Created On      : Fri Mar  8 17:20:49 2024
// Last Modified By: Connor Coale
// Last Modified On: Fri Mar  8 17:20:49 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!
module spi_master #(parameter bit CPOL = 0,
                    parameter bit CPHA = 0,
                    parameter integer PACKET_WIDTH = 8,
                    parameter integer F_IN = 100_000_000, // 100MHz
                    parameter integer F_SCLK = 5_000_000  // 5MHz
                    )
                   (input logic                     clk,   // Input clock
                    input logic                     rstn, // Negedge reset

                   // System control signals
                    input logic                     start, // Tell SPI master to start a transition
                    output logic                    ready, // Indicate to system that SPI master is
                                                     // able to receive a byte for transmission
                    output logic                    done, // indicate to system tranmission is done
                    input logic [PACKET_WIDTH-1:0]  d_in, // Input dataword
                    output logic [PACKET_WIDTH-1:0] d_out, // Output dataword

                    // SPI output conrol signals
                    output logic                    sclk,
                    // output logic              cs, // wrapper will handle chip select.
                    output logic                    mosi,
                    input logic                     miso
                    ) ;

   // set how frequently to toggle sclk.
   localparam logic [$clog2(F_IN/F_SCLK)-1:0] DivBy = (F_IN/F_SCLK/2) - 1;

   typedef enum {
                 IDLE,
                 DRIVE,
                 SAMPLE
                 } state_t;
   state_t state, state_next;

   logic        sclk_reg, sclk_next;

   logic [$clog2(PACKET_WIDTH)-1:0] bit_cnt, bit_cnt_next; // regs and inputs for bit counter
   logic [$clog2(F_IN/F_SCLK)-1:0]  div_cnt, div_cnt_next; // regs and inputs for dvsr counter

   logic [PACKET_WIDTH-1:0]        d_in_reg;              // to hold input data on start
   logic [PACKET_WIDTH-1:0]        d_in_next;             // input d to registered d_in
   logic [PACKET_WIDTH-1:0]        d_out_next;            // input d to d_out reg output
   logic                           ready_next, done_next; // input d to ready and done signals

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         state <= IDLE;
         bit_cnt <= '0;
         div_cnt <= '0;
         d_in_reg <= '0;
         d_out <= '0;
         ready <= 1'b1;
         done <= 1'b0;
         sclk_reg <= 1'b0;
      end
      else begin
         state    <= state_next;
         bit_cnt  <= bit_cnt_next;
         div_cnt  <= div_cnt_next;
         d_in_reg <= d_in_next;
         d_out    <= d_out_next;
         ready    <= ready_next;
         done     <= done_next;
         sclk_reg <= sclk_next;
      end
   end

   always_comb begin
      // defaults
      state_next = state;
      bit_cnt_next = bit_cnt;
      div_cnt_next = div_cnt;
      d_in_next = d_in_reg;
      d_out_next = d_out;
      ready_next = '0;
      done_next  = '0;
      case (state)
        IDLE: begin
           ready_next = 1'b1;
           if (start) begin
              state_next = DRIVE;
              bit_cnt_next = '0;
              div_cnt_next = '0;
              d_in_next = d_in;   // register the input word
              ready_next = 1'b0;
           end
        end
        DRIVE: begin
           if (div_cnt == DivBy) begin
              state_next = SAMPLE;
              div_cnt_next = '0;
              d_out_next = {d_in_reg[PACKET_WIDTH-2:0], miso};
           end else begin
              div_cnt_next = div_cnt + 1;
           end
        end
        SAMPLE: begin
           if (div_cnt == DivBy) begin
              if (bit_cnt == (PACKET_WIDTH - 1)) begin
                 state_next = IDLE;
                 done_next = 1'b1; // indicate we received a full packet
              end else begin
                 state_next = DRIVE;
                 div_cnt_next = '0;
                 bit_cnt_next = bit_cnt + 1;
                 d_in_next = {d_in_reg[PACKET_WIDTH-2:0], 1'b0};
              end
           end else begin
              div_cnt_next = div_cnt + 1;
           end
        end
        default: state_next = IDLE;
      endcase // case (state)
   end

   always_comb begin
      case ({CPOL,CPHA})
        2'b00: begin
           sclk_next = (state_next == SAMPLE);
        end
        2'b01: begin
           sclk_next = ~(state_next == SAMPLE);
        end
        2'b10: begin
           sclk_next = (state_next == DRIVE);
        end
        2'b11: begin
           sclk_next = ~(state_next == DRIVE);
        end
        default: begin
           sclk_next = (state_next == SAMPLE);
        end
      endcase // case ({CPOL,CPHA})
   end

   assign mosi  = d_in_reg[7];
   assign sclk  = sclk_reg;
endmodule // spi_master

