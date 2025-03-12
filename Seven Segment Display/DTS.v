`timescale 1ns / 1ps

module DTS(input [3:0]data, output [6:0]C, output [7:0]AN);
assign AN = 8'b11111110;
wire [15:0]y; //Connecting the decoder to the controller

Decoder myDecoder(data, y);
Controller myController(y, C);

endmodule
//This is a Binary to Decimal conversion
module Decoder(input[3:0]data, output reg[15:0]y);
    always @(data)
    begin
        y=0;
        y[data]=1;
    end
endmodule
//Switch case that that used the BCD and converts it to Comman Cathode SSegDis
module Controller(input[15:0]y, output reg[6:0]C);
always @*
//Used HEX for swithc cases for ease of translation
    case(y)
     16'h1   : C = 7'b0000001; //0
     16'h2   : C = 7'b1001111; //1
     16'h4   : C = 7'b0010010; //2
     16'h8   : C = 7'b0000110; //3
     16'h10  : C = 7'b1001100; //4
     16'h20  : C = 7'b0100100; //5
     16'h40  : C = 7'b0100000; //6
     16'h80  : C = 7'b0001111; //7
     16'h100 : C = 7'b0000000; //8
     16'h200 : C = 7'b0000100; //9
     16'h400 : C = 7'b0001000; //A
     16'h800 : C = 7'b1100000; //b
     16'h1000: C = 7'b0110001; //c;
     16'h2000: C = 7'b1000010; //d
     16'h4000: C = 7'b0110000; //E
     16'h8000: C = 7'b0111000; //F
    endcase
endmodule