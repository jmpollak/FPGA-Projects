`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2024 01:41:08 PM
// Design Name: 
// Module Name: RGB_led
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
module RGB_led(clock, reset, RGB1, RGB2);
input clock, reset;
output reg [2:0]RGB1;
output reg [2:0]RGB2;
wire trigger;
reg [4:0] count;
slowerClkGen clk1Hz(clock, reset, trigger);
     
always@(negedge reset, posedge trigger)
begin
   if (~reset)
    begin
        count=0;
        RGB1=0;
        RGB2=0;
    end
   else
    begin
       case(count)
        1: begin RGB1=1; RGB2=1; end
        4: begin RGB1=2; RGB2=2; end
        7: begin RGB1=3; RGB2=3; end
        10:begin RGB1=4; RGB2=4; end
        13:begin RGB1=5; RGB2=5; end
        16:begin RGB1=6; RGB2=6; end
        19:begin RGB1=7; RGB2=7; end
        default: begin RGB1=0; RGB2=0; end
       endcase
       count=count+1;
       if (count==20)
          count=0;
    end
    
end
     
endmodule
module slowerClkGen(clk, resetSW, outsignal);
    input clk;
    input resetSW;
    output  outsignal;
reg [26:0] counter;  
reg outsignal;
    always @ (posedge clk)
    begin
if (~resetSW)
  begin
counter=0;
outsignal=0;
  end
else
  begin
  counter = counter +1;
  if (counter == 50_000_000)  //1 Hz clock
begin
outsignal=~outsignal;
counter =0;
end
 end
   end
endmodule

