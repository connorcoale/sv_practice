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
   localparam logic [7:0]       DisplayOn = 8'hAF;
   localparam Delay3v3          = 2_000_000;  // 20ms at 100MHz
   localparam StartupDCDelay    = 1500;       // 15us  .
   localparam StartupResetDelay = 1500;       // 15us  .
   localparam ComSegDelay       = 10_000_000; // 100ms .

   // Need to debounce and monopulse the reset_display input.
   logic              reset_display, reset_display_db;
   localparam integer DebounceCount = 100_000; // 1ms at 10MHz
   debouncer  #(.N(DebounceCount)) debouncer
                         (
                          .out       (reset_display_db),
                          .clk       (clk),
                          .reset     (reset),
                          .in        (reset_display_raw)
                         );
   monopulser monopulser (
                          .clk       (clk),
                          .reset     (reset),
                          .in        (reset_display_db),
                          .out       (reset_display)
                          );

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
                         .ready                 (ready),
                         .done                  (done),
                         .d_out                 (),              // Templated
                         .sclk                  (sclk),
                         .mosi                  (mosi),
                         // Inputs
                         .clk                   (clk),
                         .rstn                  (~reset),        // Templated
                         .start                 (start),
                         .d_in                  (d_in[PACKET_WIDTH-1:0]),
                         .miso                  ());              // Templated

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
         d_in        <= 1'b0;
         start       <= 1'b0;
         start_delay <= 1'b0;
         dc          <= 1'b0;
         power_reset <= 1'b0;
         vcc_en      <= 1'b0;
         pmod_en     <= 1'b0;
         cs          <= 1'b1;
      end else begin
         state       <= state_next;
         d_in        <= d_in_next;
         start       <= start_next;
         start_delay <= start_delay_next;
         dc          <= dc_next;
         power_reset <= power_reset_next;
         vcc_en      <= vcc_en_next;
         pmod_en     <= pmod_en_next;
         cs          <= cs_next;
      end
   end

   state_t                  state, state_next;
   logic                    start_next;
   logic                    dc_next, power_reset_next, vcc_en_next, pmod_en_next, cs_next;

   logic                    send_command, send_data;

   logic [PACKET_WIDTH-1:0] d_in_next;

   assign led = {4'b0000, state[3:0]};

   always_comb begin
      // defaults
      state_next = state;
      d_in_next = d_in;
      start_next = 1'b0;
      start_delay_next = 1'b0;
      dc_next = 1'b0;
      power_reset_next = power_reset;
      vcc_en_next = vcc_en;
      pmod_en_next = pmod_en;
      cs_next = 1'b1;
      n_delay = '0;
      case (state)
        IDLE: begin
           if (reset_display) begin
              state_next = STARTUP_3V3_DELAY;
              start_delay_next = 1'b1;
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
           n_delay = Delay3v3;
           if (delay_done) begin
              state_next = STARTUP_DC_DELAY;
              start_delay_next = 1'b1;
           end
        end
        STARTUP_DC_DELAY: begin
           // power_reset goes low
           dc_next              = 1'b0;
           power_reset_next     = 1'b0;
           vcc_en_next          = 1'b0;
           pmod_en_next         = 1'b0;
           // delay 15us
           n_delay = StartupDCDelay;
           if (delay_done) begin
              state_next = STARTUP_RESET_DELAY;
              start_delay_next = 1'b1;
           end
        end
        STARTUP_RESET_DELAY: begin
           // power_reset goes back high
           // along with vcc_en and pmod_en
           dc_next              = 1'b0;
           power_reset_next     = 1'b1;
           vcc_en_next          = 1'b1;
           pmod_en_next         = 1'b1;
           // delay 15us
           n_delay = StartupResetDelay;
           if (delay_done) state_next = DISP_ON;
        end
        DISP_ON: begin
           cs_next = 1'b0;
           if (ready) begin
              d_in_next = DisplayOn; // Send display on command
              start_next = 1'b1;
           end
           if (done) begin // transition once transaction sent
              state_next = COM_SEG_DELAY;
              start_delay_next = 1'b1;
           end
        end
        COM_SEG_DELAY: begin
           // delay 100ms
           n_delay = ComSegDelay;
           if (delay_done) state_next = IDLE;
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

   logic [32-1:0] n_delay; // use defualt width of 32 bits.
   logic          start_delay, start_delay_next;
   logic          delay_done;

   /* counter AUTO_TEMPLATE (
    .done(delay_done),
    .n(n_delay),
    .enable(start_delay),
    );
    */
   counter counter(/*AUTOINST*/
                   // Outputs
                   .done                (delay_done),            // Templated
                   // Inputs
                   .clk                 (clk),
                   .reset               (reset),
                   .enable              (start_delay),           // Templated
                   .n                   (n_delay));               // Templated



endmodule // oled_top

// Local Variables:
// verilog-library-flags:("-y ../../spi/src -y ../../utils/src")
// End:
