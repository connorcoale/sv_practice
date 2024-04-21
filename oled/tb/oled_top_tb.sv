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

module oled_top_tb #(TB_IMAGE_ADDR = "test_image.hex") () ;
   localparam CLK_HALF_CYCLE = 5;  // 5ns half cycle means 10ns period
   localparam PERIOD = CLK_HALF_CYCLE * 2; // 10ns



   logic cs, sdin, sclk, dc, res, vccen, pmoden;

   logic clk;
   logic [3:0] btn;
   oled_top `ifdef VERILATOR #(.TB_IMAGE_ADDR(TB_IMAGE_ADDR)) `endif oled_top
     (
      // Outputs
      .cs               (cs),
      .sdin             (sdin),
      .sclk             (sclk),
      .dc               (dc),
      .res              (res),
      .vccen            (vccen),
      .pmoden           (pmoden),
      // Inputs
      .clk              (clk),
      .btn              (btn[3:0])
      );

   always #CLK_HALF_CYCLE clk = ~clk;

   initial begin
      $dumpfile("trace.vcd");
      $dumpvars();

      clk = 1'b0;
      btn = 4'b0;

      // reset system
      btn[0] = 1'b1;
      #(110*PERIOD);
      btn[0] = 1'b0;

      // reset display
      btn[1] = 1'b1;
      #((2000+1500+1500+10000+1000)*PERIOD);
      btn[1] = 1'b0;

      // test_pattern
      btn[2] = 1'b1;
      #(10000*PERIOD);
      btn[2] = 1'b0;

      #(100*PERIOD);

      // test_image
      btn[3] = 1'b1;
      #(110*PERIOD);
      btn[3] = 1'b0;

      #(1800 * (96*64));
      $finish;
   end


endmodule // oled_top_tb

// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
