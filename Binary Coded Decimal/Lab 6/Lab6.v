`timescale 1ns / 1ps
//Top module
module Lab6(input clk,output [6:0]C, output [7:0]AN);
wire clk400Hz;
wire clkHalfHz;
wire [6:0]p1;
wire [6:0]p2;
wire [6:0]p3;
wire [6:0]p4;
//My sub modules
clockDivider myClocks(clk, clk400Hz, clkHalfHz);
patternGen myPatterns(clkHalfHz, p1, p2, p3, p4);
display myDisplay(clk400Hz, p1, p2, p3, p4, C, AN);

endmodule
//All Sub modules
module clockDivider(input systemClk, output reg clk1, output reg clk2);
reg [26:0] counter1;
reg [26:0] counter2;
    always @ (posedge systemClk)
    begin
        counter1 = counter1 + 1;
        counter2 = counter2 + 1;
        if (counter1 == 125_000) //125,000 = 100,000,000Hz/(2*400Hz)
        begin
            clk1=~clk1;
            counter1 = 0;
        end
        if (counter2 == 100_000_000)//0.5Hz
        begin
            clk2=~clk2;
            counter2 = 0;
        end
    end
endmodule
//Generates patterns
module patternGen(input clk, output reg [6:0]p1, output reg [6:0]p2, output reg [6:0]p3, output reg [6:0]p4);
reg [1:0] patternState = 0;// State to track which pattern is being displayed
always @ (posedge clk)
    begin
    case(patternState)
        2'b00: begin //0123
               p1 = 7'b0000001;
               p2 = 7'b1001111;
               p3 = 7'b0010010;
               p4 = 7'b0000110;
               end
        2'b01: begin //5678
               p1 = 7'b0100100;
               p2 = 7'b0100000;
               p3 = 7'b0001111;
               p4 = 7'b0000000;
               end
        2'b10: begin //9Abc
               p1 = 7'b0000100;
               p2 = 7'b0001000;
               p3 = 7'b1100000;
               p4 = 7'b0110001;
               end
        2'b11: begin //DEFoff
               p1 = 7'b1000010;
               p2 = 7'b0110000;
               p3 = 7'b0111000;
               p4 = 7'b1111111;
               end
    endcase
    patternState <= patternState + 1;// Switch to the next pattern every 2 seconds
   end
endmodule
//Used to diplsay onto the Seven Segment Displays
module display(input clk, input [6:0] p1, input [6:0] p2, input [6:0] p3, input [6:0] p4, output reg[6:0]C, output reg [7:0]An);
reg [1:0]counter = 0; //2-bit counter
always @ (posedge clk) 
    begin
        counter <= counter + 1;
        //4-to-1 Mux
        case(counter)
        2'b00: begin
               C = p1;
               An <= 8'b11111110;
               end
        2'b01: begin
               C = p2; 
               An <= 8'b11111101;
               end
        2'b10: begin
               C = p3;
               An <= 8'b11111011;
               end
        2'b11: begin
               C = p4; 
               An <= 8'b11110111;
               end
        endcase
    end
endmodule