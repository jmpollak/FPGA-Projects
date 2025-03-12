`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2024 08:12:52 PM
// Design Name: 
// Module Name: VGA_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module pong_top_an
   (
    input wire clk, reset, reset_clk,
    input wire [1:0] btn,
    output wire hsync, vsync,
    output wire [11:0] rgb
   );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [11:0] rgb_reg;
   wire [11:0] rgb_next;
   wire clk_50m;

   // body
   // instantiate vga sync circuit
   clk_50m_generator myclk(clk, reset_clk, clk_50m);
   
   // instantiate vga sync circuit
   vga_sync vsync_unit
      (.clk(clk_50m), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));

   // instantiate graphic generator
   pong_graph_animate pong_graph_an_unit
      (.clk(clk_50m), .reset(reset), .btn(btn),
       .video_on(video_on), .pix_x(pixel_x),
       .pix_y(pixel_y), .graph_rgb(rgb_next));

   // rgb buffer
   always @(posedge clk_50m)
      if (pixel_tick)
         rgb_reg <= rgb_next;
   // output
   assign rgb = rgb_reg;

endmodule

module clk_50m_generator(clk, reset_clk, clk_50m);
    input wire clk, reset_clk;
    output wire clk_50m;
    reg [1:0] counter;  
    reg clk_reg;
    wire clk_next;
    
    always @(posedge clk, posedge reset_clk)
          if (reset_clk)
             begin
                clk_reg <= 1'b0;
             end
          else
             begin
                clk_reg <= clk_next;
             end
    
       assign clk_next = ~clk_reg;
       assign clk_50m = clk_reg;
endmodule


module pong_graph_animate
   (
    input wire clk, reset,
    input wire video_on,
    input wire [1:0] btn,
    input wire [9:0] pix_x, pix_y,
    output reg [11:0] graph_rgb
   );

   // constant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   wire refr_tick;
   //--------------------------------------------
   // vertical stripe as a wall
   //--------------------------------------------
   // wall left, right boundary
   localparam WALL_X_L = 0;
   localparam WALL_X_R = 600;
   
   //wall top, bottom bounds
   localparam WALL_Y_T = 32;
   localparam WALL_Y_B = 35;
   //--------------------------------------------
   // Bar
   //--------------------------------------------
   // bar top, bottom boundary
   localparam BAR_Y_T = 450;
   localparam BAR_Y_B = 453;
   // bar left, right boundary
   wire [9:0] bar_x_l, bar_x_r;
   localparam BAR_X_SIZE = 72;
   // register to track top boundary  (y position is fixed)
   reg [9:0] bar_x_reg, bar_x_next;
   // bar moving velocity when a button is pressed
   localparam BAR_V = 4;
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 8;
   // ball left, right boundary
   wire [9:0] ball_x_l, ball_x_r;
   // ball top, bottom boundary
   wire [9:0] ball_y_t, ball_y_b;
   // reg to track left, top position
   reg [9:0] ball_x_reg, ball_y_reg;
   wire [9:0] ball_x_next, ball_y_next;
   // reg to track ball speed
   reg [9:0] x_delta_reg, x_delta_next;
   reg [9:0] y_delta_reg, y_delta_next;
   // ball velocity can be pos or neg)
   localparam BALL_V_P = 2;
   localparam BALL_V_N = -2;
   //--------------------------------------------
   // round ball
   //--------------------------------------------
   wire [2:0] rom_addr, rom_col;
   reg [7:0] rom_data;
   wire rom_bit;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire wall_on, bar_on, sq_ball_on, rd_ball_on;
   wire [11:0] wall_rgb, bar_rgb, ball_rgb;

   // body
   //--------------------------------------------
   // round ball image ROM
   //--------------------------------------------
   
   always @*
   case(rom_addr)
    3'h0: rom_data = 8'b00011000;   //    **  
    3'h1: rom_data = 8'b00111100;   //   **** 
    3'h2: rom_data = 8'b01111110;   //  ****** 
    3'h3: rom_data = 8'b11111111;   // ******** 
    3'h4: rom_data = 8'b11111111;   // ******** 
    3'h5: rom_data = 8'b01111110;   //  ****** 
    3'h6: rom_data = 8'b00111100;   //   **** 
    3'h7: rom_data = 8'b00011000;   //    **  
    endcase

   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            bar_x_reg <= 0;
            ball_x_reg <= 0;
            ball_y_reg <= 0;
            x_delta_reg <= 10'h004;
            y_delta_reg <= 10'h004;
         end
      else
         begin
            bar_x_reg <= bar_x_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
         end

   // refr_tick: 1-clock tick asserted at start of v-sync
   //            i.e., when the screen is refreshed (60 Hz)
   assign refr_tick = (pix_y==481) && (pix_x==0);

   //--------------------------------------------
   // (wall) left vertical strip
   //--------------------------------------------
   // pixel within wall
   assign wall_on = (WALL_Y_T<=pix_y) && (pix_y<=WALL_Y_B);
   // wall rgb output
   assign wall_rgb = 12'hF0F; // Purple
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // boundary
   assign bar_x_l = bar_x_reg;
   assign bar_x_r = bar_x_l + BAR_X_SIZE - 1;
   // pixel within bar
   assign bar_on = (BAR_Y_T<=pix_y) && (pix_y<=BAR_Y_B) &&
                   (bar_x_l<=pix_x) && (pix_x<=bar_x_r);
   // bar rgb output
   assign bar_rgb = 12'h0F4; // green
   // new bar y-position
   always @*
   begin
      bar_x_next = bar_x_reg; // no move
      if (refr_tick)
         if (btn[1] & (bar_x_r < (MAX_X-1-BAR_V)))
            bar_x_next = bar_x_reg + BAR_V; // move right
         else if (btn[0] & (bar_x_l > BAR_V))
            bar_x_next = bar_x_reg - BAR_V; // move left
   end

   //--------------------------------------------
   // square ball
   //--------------------------------------------
   // boundary
   assign ball_x_l = ball_x_reg;
   assign ball_y_t = ball_y_reg;
   assign ball_x_r = ball_x_l + BALL_SIZE - 1;
   assign ball_y_b = ball_y_t + BALL_SIZE - 1;
   // pixel within ball
   assign sq_ball_on =
            (ball_x_l<=pix_x) && (pix_x<=ball_x_r) &&
            (ball_y_t<=pix_y) && (pix_y<=ball_y_b);
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
   assign rom_col = pix_x[2:0] - ball_x_l[2:0];
   assign rom_bit = rom_data[rom_col];
   // pixel within ball
   assign rd_ball_on = sq_ball_on & rom_bit;
   // ball rgb output
   assign ball_rgb = 12'h000;   // black
   // new ball position
   assign ball_x_next = (refr_tick) ? ball_x_reg+x_delta_reg :
                        ball_x_reg ;
   assign ball_y_next = (refr_tick) ? ball_y_reg+y_delta_reg :
                        ball_y_reg ;
   // new ball velocity
   always @*
   begin
      x_delta_next = x_delta_reg;
      y_delta_next = y_delta_reg;
      if (ball_x_l < 1) // reach max left
         x_delta_next = BALL_V_P;
      else if (ball_x_r > (MAX_X-1)) // reach max right
         x_delta_next = BALL_V_N;
      else if (ball_y_t <= WALL_Y_B) // reach wall
         y_delta_next = BALL_V_P;    // bounce back
      else if ((BAR_Y_T<=ball_y_b) && (ball_y_b<=BAR_Y_B) &&
               (bar_x_l<=ball_x_r) && (ball_x_l<=bar_x_r))
         // reach x of right bar and hit, ball bounce back
         y_delta_next = BALL_V_N;
   end
   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 12'h000; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (bar_on)
            graph_rgb = bar_rgb;
         else if (rd_ball_on)
            graph_rgb = ball_rgb;
         else
            graph_rgb = 12'hfff; // white background
endmodule

module vga_sync
   (
    input wire clk, reset,
    output wire hsync, vsync, video_on, p_tick,
    output wire [9:0] pixel_x, pixel_y
   );

   // constant declaration
   // VGA 640-by-480 sync parameters
   localparam HD = 640; // horizontal display area
   localparam HF = 48 ; // h. front (left) border
   localparam HB = 16 ; // h. back (right) border
   localparam HR = 96 ; // h. retrace
   localparam VD = 480; // vertical display area
   localparam VF = 10;  // v. front (top) border
   localparam VB = 29;  // v. back (bottom) border
   localparam VR = 2;   // v. retrace

   // mod-2 counter
   reg mod2_reg;
   wire mod2_next;
   // sync counters
   reg [9:0] h_count_reg, h_count_next;
   reg [9:0] v_count_reg, v_count_next;
   // output buffer
   reg v_sync_reg, h_sync_reg;
   wire v_sync_next, h_sync_next;
   // status signal
   wire h_end, v_end, pixel_tick;

   // body
   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            mod2_reg <= 1'b0;
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 1'b0;
            h_sync_reg <= 1'b0;
         end
      else
         begin
            mod2_reg <= mod2_next;
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= v_sync_next;
            h_sync_reg <= h_sync_next;
         end

   // mod-2 circuit to generate 25 MHz enable tick
   assign mod2_next = ~mod2_reg;
   assign pixel_tick = mod2_reg;

   // status signals
   // end of horizontal counter (799)
   assign h_end = (h_count_reg==(HD+HF+HB+HR-1));
   // end of vertical counter (524)
   assign v_end = (v_count_reg==(VD+VF+VB+VR-1));

   // next-state logic of mod-800 horizontal sync counter
   always @*
      if (pixel_tick)  // 25 MHz pulse
         if (h_end)
            h_count_next = 0;
         else
            h_count_next = h_count_reg + 1;
      else
         h_count_next = h_count_reg;

   // next-state logic of mod-525 vertical sync counter
   always @*
      if (pixel_tick & h_end)
         if (v_end)
            v_count_next = 0;
         else
            v_count_next = v_count_reg + 1;
      else
         v_count_next = v_count_reg;

   // horizontal and vertical sync, buffered to avoid glitch
   // h_sync_next asserted between 656 and 751
   assign h_sync_next = (h_count_reg>=(HD+HB) &&
                         h_count_reg<=(HD+HB+HR-1));
   // vh_sync_next asserted between 490 and 491
   assign v_sync_next = (v_count_reg>=(VD+VB) &&
                         v_count_reg<=(VD+VB+VR-1));

   // video on/off
   assign video_on = (h_count_reg<HD) && (v_count_reg<VD);

   // output
   assign hsync = h_sync_reg;
   assign vsync = v_sync_reg;
   assign pixel_x = h_count_reg;
   assign pixel_y = v_count_reg;
   assign p_tick = pixel_tick;
endmodule