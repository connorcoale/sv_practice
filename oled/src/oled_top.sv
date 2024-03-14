//                              -*- Mode: Verilog -*-
// Filename        : oled_top.sv
// Description     : top module to interface with the oled pmod
// Author          : Connor Coale
// Created On      : Sat Mar  9 22:08:40 2024
// Last Modified By: Connor Coale
// Last Modified On: Sat Mar  9 22:08:40 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module oled_top #(
                  parameter integer PACKET_WIDTH = 8
                  )
                  (
                   input logic       clk,
                   input logic [3:0] btn,

                   output logic      cs, // 1
                   output logic      sdin, // 2
                   output logic      sclk, // 4
                   output logic      dc, // 7
                   output logic      res, // 8
                   output logic      vccen, // 9
                   output logic      pmoden // 10
                   );

`ifdef VERILATOR
   localparam integer                DebounceCount = 100;
`else
   localparam integer                DebounceCount = 100_000;
`endif

   // Debounce input buttons
   logic [3:0]                  btn_db; // debounced version of buttons
   logic [3:0]                  btn_mp; // monopulsed version of buttons
   genvar                       i;
   generate
      for (i = 0; i < 4; i++) begin : g_button_conditioners
         debouncer #(.N(DebounceCount)) debouncer
            (
             .out(btn_db[i]),
             .clk(clk),
             .reset(),
             .in(btn[i])
             );
         monopulser monopulser
            (
             .out(btn_mp[i]),
             .clk(clk),
             .reset(),
             .in(btn_db[i])
             );
      end
   endgenerate


   oled oled (
              .clk(clk),
              .reset(btn_db[0]),
              .reset_oled(btn_mp[1]),
              .test_pattern(btn_db[2]),
              .test_image(btn_db[3]),
              .cs(cs),
              .sdin(sdin),
              .sclk(sclk),
              .dc(dc),
              .res(res),
              .vccen(vccen),
              .pmoden(pmoden)
              );
endmodule // oled_top

// Local Variables:
// verilog-library-flags:("-y ../../spi/src -y ../../utils/src")
// End:
