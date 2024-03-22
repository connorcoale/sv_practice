//                              -*- Mode: Verilog -*-
// Filename        : oled.sv
// Description     : oled module
// Author          : Connor Coale
// Created On      : Tue Mar 12 21:46:33 2024
// Last Modified By: Connor Coale
// Last Modified On: Tue Mar 12 21:46:33 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module oled #(
              // Probably want to override this generic at the compilation stage for synthesis
              // and/or simulation.
              parameter string TEST_IMAGE_ADDR = "test_image.hex"
              )
             (
             // Inputs to control abstracted pmod
             input logic  clk,
             input logic  reset,
             input logic  reset_oled,
             input logic  test_pattern,
             input logic  test_image,

             // Outputs to pmod
             // PMOD location:
             output logic cs, //     1
             output logic sdin, //   2
             output logic sclk, //   4
             output logic dc, //     7
             output logic res, //    8
             output logic vccen, //  9
             output logic pmoden // 10
             );

   localparam logic [7:0] DisplayOn = 8'hAF;
`ifdef VERILATOR
   localparam integer Delay3v3          = 2_000;//  20us at 100MHz
   localparam integer StartupDCDelay    = 1_500;//  15us  .
   localparam integer StartupResetDelay = 1_500;//  15us  .
   localparam integer ComSegDelay       = 10_000;// 100us .
`else
   localparam integer Delay3v3          = 2_000_000; //  20ms at 100MHz
   localparam integer StartupDCDelay    = 1500; //       15us  .
   localparam integer StartupResetDelay = 1500; //       15us  .
   localparam integer ComSegDelay       = 10_000_000; // 100ms .
`endif

   logic ready, done, start;
   logic [7:0] d_in;
   spi_master    #(.CPOL(1), .CPHA(1))
      spi_master
         (
          // Outputs
          .ready                        (ready),
          .done                         (done),
          .d_out                        (),  // no miso
          .sclk                         (sclk),
          .mosi                         (sdin),
          // Inputs
          .clk                          (clk),
          .rstn                         (~reset),
          .start                        (start),
          .d_in                         (d_in[7:0]),
          .miso                         ()); // no miso

   typedef enum
      {
       IDLE,                // 0
       STARTUP_3V3_DELAY,   // 1 20ms delay for 3.3V rail stabilization
       STARTUP_DC_DELAY,    // 2 15us to bring reset low
       STARTUP_RESET_DELAY, // 3 15us settle time for after reset goes back high
       DISP_ON,             // 4 issue command to turn display on
       COM_SEG_DELAY,       // 5 100ms to let com/seg come up
       SET_256_MODE1,       // 6
       SET_256_MODE2,       // 7
       SEND_COLORS,         // 8
       TEST_IMAGE_COMMANDS, // 9
       TEST_IMAGE,          // 10
       SEND_COMMAND,        // 11
       SEND_DATA            // 12
       } state_t;

   always_ff @(posedge clk or posedge reset) begin
      if (reset) begin
         state       <= IDLE;
         d_in        <= 1'b0;
         start       <= 1'b0;
         start_delay <= 1'b0;
         dc          <= 1'b0;
         res <= 1'b0;
         vccen      <= 1'b0;
         pmoden     <= 1'b0;
         cs          <= 1'b1;
         count       <= 0;
      end else begin
         state       <= state_next;
         d_in        <= d_in_next;
         start       <= start_next;
         start_delay <= start_delay_next;
         dc          <= dc_next;
         res <= res_next;
         vccen      <= vccen_next;
         pmoden     <= pmoden_next;
         cs          <= cs_next;
         count       <= count_next;
      end
   end

   state_t                  state, state_next;
   logic                    start_next;
   logic                    dc_next, res_next, vccen_next, pmoden_next, cs_next;

   logic                    send_command, send_data;

   logic [7:0] d_in_next;
   logic [13:0]              count, count_next;


   always_comb begin
      // defaults
      state_next = state;
      d_in_next = d_in;
      start_next = 1'b0;
      start_delay_next = 1'b0;
      dc_next = 1'b0;
      res_next = res;
      vccen_next = vccen;
      pmoden_next = pmoden;
      cs_next = 1'b1;
      n_delay = '0;
      count_next = '0;
      case (state)
        IDLE: begin
           if (reset_oled) begin
              state_next = STARTUP_3V3_DELAY;
              start_delay_next = 1'b1;
           end
           else if (send_command) state_next = SEND_COMMAND;
           else if (send_data) state_next = SEND_DATA;
           else if (test_pattern) state_next = SEND_COLORS;
           else if (test_image) state_next = TEST_IMAGE_COMMANDS;
        end
        STARTUP_3V3_DELAY: begin
           // Start with reset high (active low reset)
           dc_next             = 1'b0;
           res_next            = 1'b1;
           vccen_next          = 1'b0;
           pmoden_next         = 1'b0;
           // delay 20ms
           n_delay = Delay3v3;
           if (delay_done) begin
              state_next = STARTUP_DC_DELAY;
              start_delay_next = 1'b1;
           end
        end
        STARTUP_DC_DELAY: begin
           // res goes low
           dc_next              = 1'b0;
           res_next     = 1'b0;
           vccen_next          = 1'b0;
           pmoden_next         = 1'b0;
           // delay 15us
           n_delay = StartupDCDelay;
           if (delay_done) begin
              state_next = STARTUP_RESET_DELAY;
              start_delay_next = 1'b1;
           end
        end
        STARTUP_RESET_DELAY: begin
           // res goes back high
           // along with vccen and pmoden
           dc_next              = 1'b0;
           res_next     = 1'b1;
           vccen_next          = 1'b1;
           pmoden_next         = 1'b1;
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
           if (delay_done) state_next = SET_256_MODE1;
        end
        SET_256_MODE1: begin
           cs_next = 1'b0;
           if (ready) begin
              d_in_next = 8'hA0; // Send driver remap/color depth command
              start_next = 1'b1;
           end
           if (done)state_next = SET_256_MODE2;
        end
        SET_256_MODE2: begin
           cs_next = 1'b0;
           if (ready) begin
              d_in_next = 8'h20; // Set to 256 color format (bits 7 and 6 must be 0)
              start_next = 1'b1;
           end
           if (done) state_next = IDLE;
           end
        SEND_COLORS: begin
           cs_next = 1'b0;
           dc_next = 1'b1;
           count_next = count + done;
           if (ready) begin
              d_in_next = count; // send an incrementing counter as data
              start_next = 1'b1;
           end
           if (done) state_next = test_pattern ? SEND_COLORS : IDLE;
        end
        TEST_IMAGE_COMMANDS: begin
           cs_next = 1'b0;
           dc_next = 1'b0;
           count_next = count + done;
           if (ready) begin
              d_in_next = pre_frame_commands[count];
              start_next = 1'b1;
           end
           if (done && (count == 10-1)) begin
              state_next = TEST_IMAGE;
              count_next = '0;
           end
        end
        TEST_IMAGE: begin
           cs_next = 1'b0;
           dc_next = 1'b1;
           count_next = count + done;
           if (ready) begin
              d_in_next = image[count]; // send an incrementing counter as data
              start_next = 1'b1;
           end
           if (done && (count == (96*64-1))) state_next = IDLE;
        end
        SEND_COMMAND: begin
           dc_next = 0;
        end
        SEND_DATA: begin
           dc_next = 1;
        end
        default: state_next = IDLE;
      endcase // case (state)
   end

   logic [7:0] pre_frame_commands [10];
   assign pre_frame_commands = {8'hA1, 8'h00, 8'hA2, 8'h00, 8'h15, 8'd0, 8'd95, 8'h75, 8'd0, 8'd63 };
   logic [32-1:0] n_delay; // use default width of 32 bits.
   logic          start_delay, start_delay_next, delay_done;

   delay_counter delay_counter(
                   .done                (delay_done),
                   .clk                 (clk),
                   .reset               (reset),
                   .enable              (start_delay),
                   .n                   (n_delay));

   logic [7:0]    image [96*64];
   initial $readmemh(TEST_IMAGE_ADDR, image);

endmodule // oled

// Local Variables:
// verilog-library-flags:("-y ../../spi/src -y ../../utils/src")
// End:
