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
                   input logic  clk,
                   input logic  reset,
                   input logic  reset_display_raw,

                   output logic [7:0] led,

                   // To the pmod
                   output logic dc, // data/command select
                   output logic power_reset,
                   output logic vcc_en,
                   output logic pmod_en,
                     // SPI connections to OLED
                   output logic cs,
                     // input logic miso, // no miso
                   output logic mosi,
                   output logic sclk
                 );



   //  TODO: Move to package?

   // Display on (need to wait 25ms before doing this)
   localparam logic [7:0]       DisplayOn = 8'hAF;

   // Need to debounce and monopulse the reset_display input.
   logic                  reset_display, reset_display_db, reset_display_mp;
   // 100_000 10ns clock periods fit in 1ms.
   localparam integer     DebounceCount = 100_000;
   logic [$clog2(DebounceCount)-1:0] db_counter, db_counter_next;
   always @(posedge clk or posedge reset) begin
      if (reset) begin
         db_counter <= '0;
         reset_display_db <= '0;
      end
      else begin
         db_counter <= db_counter_next;
         reset_display_db <= (db_counter >= DebounceCount);
      end
   end
   always_comb begin
      if (reset_display_raw) begin
         if (db_counter >= DebounceCount) db_counter_next = db_counter;
         else db_counter_next = db_counter + 1;
      end
      else db_counter_next = '0;
   end

   logic [1:0] mp_state, mp_state_next; // 00 = awaiting press, 01 = pulsing for 1 cycle, 10 = awaiting release.
   always @(posedge clk or posedge reset) begin
      if (reset) begin
         reset_display_mp <= '0;
         mp_state <= 2'b00;
      end
      else begin
         reset_display_mp <= (mp_state == 2'b01);
         mp_state <= mp_state_next;
      end
   end

   always_comb begin
      mp_state_next = mp_state;
      case (mp_state)
        2'b00: begin
           // transition only if we see a debounce button PRESSED
           if (reset_display_db) mp_state_next = 2'b01;
        end
        2'b01: begin
           // immediately, after 1 cycle, transition out of pulse state.
           mp_state_next = 2'b10;
        end
        2'b10: begin
           // transition only if we see debounce button RELEASED
           if (~reset_display_db) mp_state_next = 2'b00;
        end
        default: begin
           mp_state_next = 2'b00;
        end
      endcase // case (mp_state)
   end

   assign reset_display = reset_display_mp;

   logic ready, done, start;
   logic [PACKET_WIDTH-1:0] d_in;
   /* spi_master AUTO_TEMPLATE (
    .d_out(),
    .miso(),
    .rstn(~reset),
    );
    */
   spi_master            #(.CPOL(1), .CPHA(1))
              spi_master
                        (/*AUTOINST*/
                         // Outputs
                         .ready               (ready),
                         .done                (done),
                         .d_out               (),              // Templated
                         .sclk                (sclk),
                         .mosi                (mosi),
                         // Inputs
                         .clk                 (clk),
                         .rstn                (~reset),        // Templated
                         .start               (start),
                         .d_in                (d_in[PACKET_WIDTH-1:0]),
                         .miso                ());              // Templated

   typedef enum {
                 IDLE,                // 0
                 STARTUP_3V3_DELAY,   // 1 20ms delay for 3.3V rail stabilization
                 STARTUP_DC_DELAY,    // 2 15us to bring reset low
                 STARTUP_RESET_DELAY, // 3 15us settle time for after reset goes back high
                 DISP_ON,             // 4 issue command to turn display on
                 COM_SEG_DELAY,       // 5 100ms to let com/seg come up
                 SEND_COMMAND,        // 6
                 SEND_DATA            // 7
                 } state_t;


   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         state       <= IDLE;
         startup_cnt <= 1'b0;
         d_in        <= 1'b0;
         start       <= 1'b0;
         dc          <= 1'b0;
         power_reset <= 1'b0;
         vcc_en      <= 1'b0;
         pmod_en     <= 1'b0;
         cs          <= 1'b1;
      end else begin
         state       <= state_next;
         startup_cnt <= startup_cnt_next;
         d_in        <= d_in_next;
         start       <= start_next;
         dc          <= dc_next;
         power_reset <= power_reset_next;
         vcc_en      <= vcc_en_next;
         pmod_en     <= pmod_en_next;
         cs          <= cs_next;
      end
   end

   state_t                  state, state_next;
   logic                    start_next;
   logic [5:0]              startup_cnt, startup_cnt_next;
   logic                    dc_next, power_reset_next, vcc_en_next, pmod_en_next, cs_next;

   logic                    startup_3v3_delay_done, startup_dc_delay_done,
                              startup_reset_delay_done, com_seg_delay_done;

   logic                    send_command, send_data;

   logic [PACKET_WIDTH-1:0] d_in_next;

   assign led = {4'b0000, state[3:0]};

   always_comb begin
      // defaults
      state_next = state;
      d_in_next = d_in;
      startup_cnt_next = startup_cnt;
      start_next = 1'b0;
      startup_3v3_delay = 1'b0;
      startup_dc_delay = 1'b0;
      startup_reset_delay = 1'b0;
      com_seg_delay = 1'b0;
      dc_next = 1'b0;
      power_reset_next = power_reset;
      vcc_en_next = vcc_en;
      pmod_en_next = pmod_en;
      cs_next = 1'b1;
      case (state)
        IDLE: begin
           if (reset_display) begin
              state_next = STARTUP_3V3_DELAY;
              startup_cnt_next = '0;
           end
           else if (send_command) state_next = SEND_COMMAND;
           else if (send_data) state_next = SEND_DATA;
        end
        STARTUP_3V3_DELAY: begin
           // Start with reset high (active low reset)
           dc_next              = 1'b0;
           power_reset_next     = 1'b1;
           vcc_en_next          = 1'b0;
           pmod_en_next         = 1'b0;

           // delay 20ms
           startup_3v3_delay = 1'b1;
           if (startup_3v3_delay_done) state_next = STARTUP_DC_DELAY;
        end
        STARTUP_DC_DELAY: begin
           // power_reset goes low
           dc_next              = 1'b0;
           power_reset_next     = 1'b0;
           vcc_en_next          = 1'b0;
           pmod_en_next         = 1'b0;

           // delay 3us
           startup_dc_delay     = 1'b1;
           if (startup_dc_delay_done) state_next = STARTUP_RESET_DELAY;
        end
        STARTUP_RESET_DELAY: begin
           // power_reset goes back high
           // along with vcc_en and pmod_en
           dc_next              = 1'b0;
           power_reset_next     = 1'b1;
           vcc_en_next          = 1'b1;
           pmod_en_next         = 1'b1;

           // delay 3us
           startup_reset_delay     = 1'b1;
           if (startup_reset_delay_done) state_next = DISP_ON;
        end
        DISP_ON: begin
           cs_next = 1'b0;
           if (ready) begin
              d_in_next = DisplayOn; // Send display on command
              start_next = 1'b1;
           end
           // transition once the spi transaction is done
           if (done) state_next = COM_SEG_DELAY;
        end
        COM_SEG_DELAY: begin
           com_seg_delay = 1'b1;
           if (com_seg_delay_done) state_next = IDLE;
        end
        SEND_COMMAND: begin
           dc_next = 0;
        end
        SEND_DATA: begin
           dc_next = 1;
        end
        default: begin
           state_next = IDLE;
        end
      endcase // case (state)
   end


   // Delay counters. Modularize?
   localparam Delay3v3 = 2_000_000; // 20ms
   logic [$clog2(Delay3v3)-1:0] startup_3v3_delay_cnt;
   logic startup_3v3_delay;
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         startup_3v3_delay_cnt <= '0;
         startup_3v3_delay_done <= '0;
      end
      else begin
         if (startup_3v3_delay)  startup_3v3_delay_cnt <= (startup_3v3_delay_cnt == Delay3v3) ? '0
                                  : startup_3v3_delay_cnt + startup_3v3_delay;
         else startup_3v3_delay_cnt <= '0;
         startup_3v3_delay_done <= (startup_3v3_delay_cnt == Delay3v3);
      end
   end

   localparam StartupDCDelay = 1500; // 15us
   logic [$clog2(StartupDCDelay)-1:0] startup_dc_delay_cnt;
   logic startup_dc_delay;
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         startup_dc_delay_cnt <= '0;
         startup_dc_delay_done <= '0;
      end
      else begin
         if (startup_dc_delay) startup_dc_delay_cnt <= (startup_dc_delay_cnt == StartupDCDelay) ? '0
                                 : startup_dc_delay_cnt + startup_dc_delay;
         else startup_dc_delay_cnt <= '0;
         startup_dc_delay_done <= (startup_dc_delay_cnt == StartupDCDelay);
      end
   end

   localparam StartupResetDelay = 1500; // 15us
   logic [$clog2(StartupResetDelay)-1:0] startup_reset_delay_cnt;
   logic startup_reset_delay;
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         startup_reset_delay_cnt <= '0;
         startup_reset_delay_done <= '0;
      end
      else begin
         if (startup_reset_delay) startup_reset_delay_cnt <= (startup_reset_delay_cnt == StartupResetDelay) ? '0
                                    : startup_reset_delay_cnt + startup_reset_delay;
         else startup_reset_delay_cnt <= '0;
         startup_reset_delay_done <= (startup_reset_delay_cnt == StartupResetDelay);
      end
   end

   localparam ComSegDelay = 10_000_000; // 100ms
   logic [$clog2(ComSegDelay)-1:0] com_seg_delay_cnt;
   logic com_seg_delay;
   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         com_seg_delay_cnt <= '0;
         com_seg_delay_done <= '0;
      end
      else begin
         if (com_seg_delay)
           com_seg_delay_cnt <= (com_seg_delay_cnt == ComSegDelay) ? '0
                              : com_seg_delay_cnt + com_seg_delay;
         else
           com_seg_delay_cnt <= '0;
         com_seg_delay_done <= (com_seg_delay_cnt == ComSegDelay);
      end
   end

endmodule // oled_top

// Local Variables:
// verilog-library-flags:("-y ../../spi/src")
// End:
