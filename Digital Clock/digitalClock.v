`timescale 1ns / 1ps
//Main module
module digitalClock(input CLK100MHZ, input R, output [6:0]C, output [7:0]AN);
wire clk400Hz;
wire clk1Hz;
//For the counter
wire [5:0]seconds;
wire [5:0]minutes;
//For the digit separator
wire [3:0]secOnes;
wire [3:0]secTens;
wire [3:0]minOnes;
wire [3:0]minTens;
//For the Display
wire [6:0]secOnesDis;
wire [6:0]secTensDis;
wire [6:0]minOnesDis;
wire [6:0]minTensDis;
//Setting up the clock and the refresh rate
clockDivider createClocks(CLK100MHZ, clk400Hz, clk1Hz);
counter Clock(clk1Hz, R, seconds, minutes);
//Separating the Sec and Min
digitSeparator sec(seconds, secTens, secOnes);
digitSeparator min(minutes, minTens, minOnes);
//Genarating the Display
displayController display1(secOnes, secOnesDis);
displayController display2(secTens, secTensDis);
displayController display3(minOnes, minOnesDis);
displayController display4(minTens, minTensDis);
//Controlling the Display
display myDisplay(clk400Hz, secOnesDis, secTensDis, minOnesDis, minTensDis, C, AN);

endmodule

//Sub module
module clockDivider(input systemClk, output reg clk400Hz, output reg clk1Hz);
reg [26:0] counter1;
reg [26:0] counter2;
    always @ (posedge systemClk)
    begin
        counter1 = counter1 + 1;
        counter2 = counter2 + 1;
        if (counter1 == 125_000) //125,000 = 100,000,000Hz/(2*400Hz)
        begin
            clk400Hz=~clk400Hz;
            counter1 = 0;
        end
        if (counter2 == 50_000_000)//50,000,000 = 100,000,000Hz/(2*1Hz)
        begin
            clk1Hz=~clk1Hz;
            counter2 = 0;
        end
    end
endmodule

module counter(input clock, input R, output reg [5:0]seconds, output reg [5:0]minute); 
    always @ (negedge R, posedge clock)
    begin
    if(!R)
    begin
        seconds <= 0;
        minute <= 0;
    end
    else
    begin
        seconds <= seconds + 1;
        if(seconds == 59)
            begin
                seconds <= 0;
                minute <= minute + 1;
                if(minute == 59)
                minute <= 0;
            end
        end
    end
endmodule

//Takes in a numnber and seperates tens and ones place
module digitSeparator(input [5:0]number, output reg [3:0]tens, output reg [3:0]ones);
always @ number
    begin
        tens = number/10;
        ones = number%10;
    end
endmodule

//Takes in the inuput and breaks it into Seven Segment
module displayController(input [3:0]num, output reg [6:0]C);
always @ num
    begin
        case(num)
        0: C = 7'b0000001; //0
        1: C = 7'b1001111; //1
        2: C = 7'b0010010; //2
        3: C = 7'b0000110; //3
        4: C = 7'b1001100; //4
        5: C = 7'b0100100; //5
        6: C = 7'b0100000; //6
        7: C = 7'b0001111; //7
        8: C = 7'b0000000; //8
        9: C = 7'b0000100; //9
        endcase
    end
endmodule

//Displaying to the SSD
module display(
input clk, //400Hz clock 
input [6:0]secOnes,  // Ones second
input [6:0]secTens,  // Tens second
input [6:0]minOnes,  // Ones minute
input [6:0]minTens,  // Tens minute
output reg[6:0]C,    // Seven Segments
output reg [7:0]AN); // SSDisplay
reg [1:0] patternState = 0;
always @ (posedge clk)
    begin
    patternState <= patternState + 1;
    case(patternState)
        2'b00: begin
               C = secOnes;
               AN <= 8'b11111110;
               end
        2'b01: begin
               C = secTens; 
               AN <= 8'b11111101;
               end
        2'b10: begin
               C = minOnes;
               AN <= 8'b11111011;
               end
        2'b11: begin
               C = minTens; 
               AN <= 8'b11110111;
               end
    endcase
   end
endmodule

