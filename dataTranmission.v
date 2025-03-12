`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2024 11:57:04 AM
// Design Name: 
// Module Name: dataTranmission
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

module dataTranmission(input CLK100MHZ, input [8:0]SW, output [9:0]LED);
//    input CLK100MHZ;
//    input [8:0] SW;
//    output reg [9:0]LED;
    wire Clock;
    
    //Create the 0.5 Hz Clock
    slowerClkGen myClock(CLK100MHZ, 1'b0, Clock);
    
    //Odd parity bit
    Parity check(1'b0, Clock, SW[8], SW[7:0], LED[8:1], LED[0], LED[9]);
    
endmodule

module Parity(w, Clock, LorS, R, Q, serial, parity);
    input w; //Serial input *which we are not using*
    input Clock; //System clcok
    input LorS; //Load or Shift
    input [7:0] R; //Parallell Load Data
    output reg [7:0] Q; // Output Data
    output reg serial; // Output the leeast significant bit
    output reg parity; // Holds the parity bit

    always @(posedge Clock)
     begin
        if (LorS==1)
         begin
            Q = R; //Load R into Q
            parity=~^R;// Calculate the parity based on R
            //parity=~^Q;// Calculate the parity based on Q
            Q[7]=parity; // Assign parity bit to Q[7]
         end
        else
         begin
            serial=Q[0];
            Q={w,Q[7:1]};
         end
     end
endmodule

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
                if (counter == 100_000_000) //0.5Hz
                begin
                    outsignal=~outsignal;
                    counter =0;
                end
            end
        end
endmodule