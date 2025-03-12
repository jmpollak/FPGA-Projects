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
module VGA_top(
    input wire clk, reset, reset_clk,
    output wire hsync, vsync,
    output wire [11:0] rgb
    );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [11:0] rgb_reg;
   wire [11:0] rgb_next;
   // body
   // instantiate vga sync circuit
   wire clk_50m;
   clk_50m_generator myclk(clk, reset_clk, clk_50m);

   vga_sync vsync_unit //Determines where the pixels are at
      (.clk(clk_50m), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));
   // instantiate graphic generator
   pong_graph_st pong_grf_unit
      (.video_on(video_on), .pix_x(pixel_x), .pix_y(pixel_y),
       .graph_rgb(rgb_next));
   // rgb buffer
   always @(posedge clk_50m)
      if (pixel_tick)
        begin
         rgb_reg <= rgb_next;
        end
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

module pong_graph_st
   (
    input wire video_on,
    input wire [9:0] pix_x, pix_y,
    output reg [11:0] graph_rgb
    );

   // constant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   //--------------------------------------------
   // vertical stripe as a wall
   //--------------------------------------------
   // wall left, right boundary
   localparam WALL_X_L = 32;
   localparam WALL_X_R = 35;
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
    // x, y coordinates (0,0) to (639,479)
    
   // bar left, right boundary
   localparam BAR_X_SIZE = 72;
   localparam BAR_X_L = MAX_X/2-BAR_X_SIZE/2;
   localparam BAR_X_R = BAR_X_L+BAR_X_SIZE-1;
   
   // bar top, bottom boundary
   localparam BAR_Y_SIZE = 3;
   localparam BAR_Y_T = 450; //204
   localparam BAR_Y_B = 453;
   
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 8;
   // ball left, right boundary
   localparam BALL_X_L = MAX_X/2-BALL_SIZE/2;
   localparam BALL_X_R = BALL_X_L+BALL_SIZE-1;
   // ball top, bottom boundary
   localparam BALL_Y_T = 425;
   localparam BALL_Y_B = BALL_Y_T+BALL_SIZE-1;
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
   // Diamond ball image ROM
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
   //--------------------------------------------
   // round ball image ROM
   //--------------------------------------------    
   /*always @*
   case(rom_addr)
    3'h0: rom_data = 8'b00111100;   //   ****  
    3'h1: rom_data = 8'b01111110;   //  ****** 
    3'h2: rom_data = 8'b11111111;   // ******** 
    3'h3: rom_data = 8'b11111111;   // ******** 
    3'h4: rom_data = 8'b11111111;   // ******** 
    3'h5: rom_data = 8'b11111111;   // ******** 
    3'h6: rom_data = 8'b01111110;   //  ****** 
    3'h7: rom_data = 8'b00111100;   //   ****  
    endcase*/
   //--------------------------------------------
   // (wall) left vertical strip
   //--------------------------------------------
   // pixel within wall
   //assign wall_on = (WALL_X_L<=pix_x) && (pix_x<=WALL_X_R); //Need to change to focus on Y
   assign wall_on = (WALL_X_L<=pix_y) && (pix_y<=WALL_X_R); //Need to change to focus on Y
   // wall rgb output
   assign wall_rgb = 12'b111100001111; // 
   //assign wall_rgb = 12'b000000001111; // blue
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // pixel within bar
   assign bar_on = (BAR_X_L<=pix_x) && (pix_x<=BAR_X_R) &&
                   (BAR_Y_T<=pix_y) && (pix_y<=BAR_Y_B);  
   // bar rgb output
   assign bar_rgb = 12'b000000000000; // red
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   // pixel within squared ball
   assign sq_ball_on =
            (BALL_X_L<=pix_x) && (pix_x<=BALL_X_R) &&
             (BALL_Y_T<=pix_y) && (pix_y<=BALL_Y_B);
             
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[2:0] - BALL_Y_T[2:0];
   assign rom_col = pix_x[2:0] - BALL_X_L[2:0];
   assign rom_bit = rom_data[rom_col];
   // pixel within ball
   assign rd_ball_on = sq_ball_on & rom_bit;
   // ball rgb output        
   assign ball_rgb = 12'b111100000000;   // red
   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 12'b0; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (bar_on)
            graph_rgb = bar_rgb;
         else if (rd_ball_on)
            graph_rgb = ball_rgb;
         else
            graph_rgb = 12'b111111111111; // white background
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