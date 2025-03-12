// Listing 14.10
module pong_top
   (
    input wire clock, reset,
    input wire [1:0] btn,
    output wire hsync, vsync,
    output wire [11:0] rgb
   );

   // symbolic state declaration
   localparam  [1:0]
      newgame = 2'b00,
      play    = 2'b01,
      newball = 2'b10,
      over    = 2'b11;

   // signal declaration
   reg [1:0] state_reg, state_next;
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick, graph_on, hit, miss;
   wire [3:0] text_on;
   wire [2:0] graph_rgb, text_rgb;
   reg [11:0] rgb_reg, rgb_next;
   wire [3:0] dig0, dig1;
   reg gra_still, d_inc, d_clr, timer_start;
   wire timer_tick, timer_up;
   reg [1:0] ball_reg, ball_next;
   wire clk;

   //=======================================================
   // instantiation
   //=======================================================
   // instantiate vga sync circuit
   clk_50m_generator myclk(clock, reset_clk, clk);
   // instantiate video synchronization unit
   vga_sync vsync_unit
      (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));
   // instantiate text module
   pong_text text_unit
      (.clk(clk),
       .pix_x(pixel_x), .pix_y(pixel_y),
       .dig0(dig0), .dig1(dig1), .ball(ball_reg),
       .text_on(text_on), .text_rgb(text_rgb));
   // instantiate graph module
   pong_graph graph_unit
      (.clk(clk), .reset(reset), .btn(btn),
       .pix_x(pixel_x), .pix_y(pixel_y),
       .gra_still(gra_still), .hit(hit), .miss(miss),
       .graph_on(graph_on), .graph_rgb(graph_rgb));
   // instantiate 2 sec timer
   // 60 Hz tick
   assign timer_tick = (pixel_x==0) && (pixel_y==0);
   timer timer_unit
      (.clk(clk), .reset(reset), .timer_tick(timer_tick),
       .timer_start(timer_start), .timer_up(timer_up));
   // instantiate 2-digit decade counter
   m100_counter counter_unit
      (.clk(clk), .reset(reset), .d_inc(d_inc), .d_clr(d_clr),
       .dig0(dig0), .dig1(dig1));
   //=======================================================
   // FSMD
   //=======================================================
   // FSMD state & data registers
    always @(posedge clk, posedge reset)
       if (reset)
          begin
             state_reg <= newgame;
             ball_reg <= 0;
             rgb_reg <= 0;
          end
       else
          begin
            state_reg <= state_next;
            ball_reg <= ball_next;
            if (pixel_tick)
               rgb_reg <= rgb_next;
          end
   // FSMD next-state logic
   always @*
   begin
      gra_still = 1'b1;
      timer_start = 1'b0;
      d_inc = 1'b0;
      d_clr = 1'b0;
      state_next = state_reg;
      ball_next = ball_reg;
      case (state_reg)
         newgame:
            begin
               ball_next = 2'b11; // three balls
               d_clr = 1'b1;      // clear score
               if (btn != 2'b00)  // button pressed
                  begin
                     state_next = play;
                     ball_next = ball_reg - 1;
                  end
            end
         play:
            begin
               gra_still = 1'b0;  // animated screen
               if (hit)
                  d_inc = 1'b1;   // increment score
               else if (miss)
                  begin
                     if (ball_reg==0)
                        state_next = over;
                     else
                        state_next = newball;
                     timer_start = 1'b1;  // 2 sec timer
                     ball_next = ball_reg - 1;
                  end
            end
         newball:
            // wait for 2 sec and until button pressed
            if (timer_up && (btn != 2'b00))
                state_next = play;
         over:
            // wait for 2 sec to display game over
            if (timer_up)
                state_next = newgame;
       endcase
    end
   //=======================================================
   // rgb multiplexing circuit
   //=======================================================
   always @*
      if (~video_on)
         rgb_next = "000"; // blank the edge/retrace
      else
         // display score, rule, or game over
         if (text_on[3] ||
               ((state_reg==newgame) && text_on[1]) || // rule
               ((state_reg==over) && text_on[0]))
            rgb_next = text_rgb;
         else if (graph_on)  // display graph
           rgb_next = graph_rgb;
         else if (text_on[2]) // display logo
           rgb_next = text_rgb;
         else
           rgb_next = 3'b110; // yellow background
   // output
   assign rgb = rgb_reg;
endmodule

//Creates the clock 
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

//VGA synch
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