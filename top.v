// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    output HSYNC,
    output VSYNC,
    input RIN,
    output ROUT);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
    wire clk50;
    wire locked;
    pll pll_module (.clock_in(CLK), .clock_out(clk50), .locked(locked));
    ////////
    // make a simple VGA SYNC Driver
    ////////
    reg [9:0] hcount;     // VGA horizontal counter
    reg [9:0] vcount;     // VGA vertical counter

    wire hcount_ov;
    wire vcount_ov;
    wire videosignal_active;

    wire hsync;
    wire vsync;
    reg  vga_clk;

    reg [2:0] data;		  // RGB data

    // VGA mode parameters
    parameter hsync_end   = 10'd95,
       hdat_begin  = 10'd143,
       hdat_end  = 10'd783,
       hpixel_end  = 10'd799,
       vsync_end  = 10'd1,
       vdat_begin  = 10'd34,
       vdat_end  = 10'd514,
       vline_end  = 10'd524;


    always @(posedge clk50)
    begin
     vga_clk = ~vga_clk;
    end

    always @(posedge vga_clk)
    begin
     if (hcount_ov)
      hcount <= 10'd0;
     else
      hcount <= hcount + 10'd1;
    end

    assign hcount_ov = (hcount == hpixel_end);

    always @(posedge vga_clk)
    begin
     if (hcount_ov)
     begin
      if (vcount_ov)
       vcount <= 10'd0;
      else
       vcount <= vcount + 10'd1;
     end
    end


    ////////
    // make a simple blink circuit
    ////////

    // keep track of time and location in blink_pattern
    reg [25:0] blink_counter;

    // pattern that will be flashed over the LED over time
    wire [31:0] blink_pattern = 32'b101010001110111011100010101;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        blink_counter <= blink_counter + 1;
    end

    // generate "image"
    always @(posedge vga_clk)
    begin
      data <= (vcount[2:0] ^ hcount[2:0]);
    end

    // light up the LED according to the pattern
    assign LED = blink_pattern[blink_counter[25:21]];

    assign  vcount_ov = (vcount == vline_end);


    assign videosignal_active =    ((hcount >= hdat_begin) && (hcount < hdat_end))
         && ((vcount >= vdat_begin) && (vcount < vdat_end));

    assign hsync = (hcount > hsync_end);
    assign vsync = (vcount > vsync_end);
    assign red = (videosignal_active) ?  data[0] : 0;

    // send out our HSYNC and VSYNC values
    assign HSYNC = hsync;
    assign VSYNC = vsync;
    assign ROUT = RIN ? red : 0;
endmodule
