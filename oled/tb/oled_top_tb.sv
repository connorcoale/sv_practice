//                              -*- Mode: Verilog -*-
// Filename        : oled_top_tb.sv
// Description     : tb for oled top level
// Author          : Connor Coale
// Created On      : Sun Mar 10 12:20:43 2024
// Last Modified By: Connor Coale
// Last Modified On: Sun Mar 10 12:20:43 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

`timescale 1ns/100ps

module oled_top_tb () ;
   localparam CLK_HALF_CYCLE = 5;  // 5ns half cycle means 10ns period
   localparam PERIOD = CLK_HALF_CYCLE * 2; // 10ns

   logic clk, reset, reset_display_raw, btn2_raw;

   logic dc, power_reset, vcc_en, pmod_en, cs, mosi, sclk;
   logic [7:0] led;

   oled_top oled_top (/*AUTOINST*/
                      // Outputs
                      .led              (led[7:0]),
                      .dc               (dc),
                      .power_reset      (power_reset),
                      .vcc_en           (vcc_en),
                      .pmod_en          (pmod_en),
                      .cs               (cs),
                      .mosi             (mosi),
                      .sclk             (sclk),
                      // Inputs
                      .clk              (clk),
                      .reset            (reset),
                      .reset_display_raw(reset_display_raw),
                      .btn2_raw         (btn2_raw));

   always #CLK_HALF_CYCLE clk = ~clk;

   initial begin
      $dumpfile("trace.vcd");
      $dumpvars();

      clk = 1'b0;
      reset = 1'b1;
      reset_display_raw = 0;

      #(2*PERIOD);
      reset = 1'b0;
      reset_display_raw = 1'b1;
      #(20_000*PERIOD);
      reset_display_raw = 1'b0;
      #1ms;
      btn2_raw = 1'b1;
      #30us;
      btn2_raw = 1'b0;
      #30us;
      $finish;
   end


endmodule // oled_top_tb

// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
