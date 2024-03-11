//                              -*- Mode: Verilog -*-
// Filename        : spi_master_tb.sv
// Description     : Testbench for spi master
// Author          : Connor Coale
// Created On      : Sat Mar  9 13:58:00 2024
// Last Modified By: Connor Coale
// Last Modified On: Sat Mar  9 13:58:00 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

// `timescale 1ns/100ps

module spi_master_tb (/*AUTOARG*/) ;
   parameter integer PACKET_WIDTH = 8;
   parameter integer CLK_HALF_CYCLE = 10/2; //5ns half period results in 10ns period. 

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic [PACKET_WIDTH-1:0] d_out;               // From spi_master of spi_master.v
   logic                 done;                   // From spi_master of spi_master.v
   logic                mosi;                   // From spi_master of spi_master.v
   logic                 ready;                  // From spi_master of spi_master.v
   logic                sclk;                   // From spi_master of spi_master.v
   // End of automatics


   spi_master spi_master (/*AUTOINST*/
                          // Outputs
                          .ready                (ready),
                          .done                 (done),
                          .d_out                (d_out[PACKET_WIDTH-1:0]),
                          .sclk                 (sclk),
                          .mosi                 (mosi),
                          // Inputs
                          .clk                  (clk),
                          .rstn                 (rstn),
                          .start                (start),
                          .d_in                 (d_in[PACKET_WIDTH-1:0]),
                          .miso                 (miso));

   // stimulus to spi master module
   logic                clk, rstn, start, miso;
   logic [7:0]          d_in;

   always #CLK_HALF_CYCLE clk = ~clk;

   task static startup;
      begin
         clk = 1'b0;
         rstn = 1'b0;
         start = 1'b0;
         miso = 1'b0;
         d_in = '0;
      end
   endtask // startup

   task static transmitByte(input logic [7:0] data);
     begin
        d_in = data;
        start = 1;
        d_in = data;
        @(posedge clk) start = 0;
     end
   endtask

   initial begin
      $dumpfile("trace.vcd");
      $dumpvars();
      startup();
      repeat (10) @(posedge clk);
      rstn = 1'b1;

      @(posedge clk);
        transmitByte(8'b10100101);
      @(negedge done);

      @(posedge clk);
        transmitByte(8'b11110000);
      @(negedge done);

      $finish;
   end
endmodule // spi_master_tb

// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
