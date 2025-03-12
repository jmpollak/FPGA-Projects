`timescale 1ns / 1ps
//Main
module Lab5(input CLK100MHZ, input resetCLK, input resetCount, output [6:0]C, output [7:0]AN);
assign AN = 8'b11111110;
//For the upcounter
wire clock;
//For the Decoder
wire [2:0]data;
wire [7:0]y; 

//My Sub modules
slowerClkGen myClock(CLK100MHZ, resetCLK, clock);
upcounter myCounter(resetCount, clock, 1, data); //Set the enable to 1 for always being active
Decoder myDecoder(data, y);
Controller myController(y, C);

endmodule

//Sub
module slowerClkGen(clk, resetSW, outsignal);
    input clk;
    input resetSW;
    output outsignal;
    reg [26:0] counter;
    reg outsignal;
        always @ (posedge clk)
        begin
            if (resetSW)
            begin
                counter=0;
                outsignal=0;
            end
            else
            begin
                counter = counter +1;
                if (counter == 50_000_000) //1Hz
                begin
                    outsignal=~outsignal;
                    counter =0;
                end
            end
        end
endmodule

module upcounter (Resetn, Clock, E, Q);
    input Resetn, Clock, E;
    output reg [2:0] Q;
    always @(negedge Resetn, posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= Q + 1;
endmodule

//This is a Binary to Decimal conversion
module Decoder(input[2:0]data, output reg[7:0]y);
    always @(data)
    begin
        y=0;
        y[data]=1;
    end
endmodule

module Controller(input[7:0]y, output reg[6:0]C);
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
    endcase
endmodule