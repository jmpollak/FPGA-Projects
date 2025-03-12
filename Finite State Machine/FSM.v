`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2024 01:12:42 PM
// Design Name: 
// Module Name: FSM
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


module FSM(input clk, input reset, input level, output tickMoore, output tickMealy);

edge_detect_moore edgMoore(clk, reset, level, tickMoore);
edge_detect_mealy edgMealy(clk, reset, level, tickMealy);

endmodule

//Given to us 
module edge_detect_moore (input wire clk, reset, level, output reg tick);
localparam [1:0] zero=2'b00, edg=2'b01, one=2'b10;
reg [1:0] state_reg, state_next;
//This is where the state is changing
always @(posedge clk, posedge reset)
    if (reset)
        state_reg<=zero;
    else
        state_reg<=state_next;
//This is the code used to define what the next state will be from input   
always@*
begin
    state_next=state_reg;
    tick=1'b0; //default output
    case (state_reg)
        zero:
        begin
        tick=1'b0;
        if (level)
            state_next=edg;
        end
        edg:
        begin
            tick=1'b1;
            if (level)
                state_next=one;
        else
            state_next=zero;
        end
        one:
            if (~level)
                state_next=zero;
        default: state_next=zero;
    endcase
end
endmodule

//Given to us
module edge_detect_mealy (input wire clk, reset, level, output reg tick);
localparam zero=1'b0, one=1'b1;
reg state_reg, state_next;

always @(posedge clk, posedge reset)
    if (reset)
        state_reg<=zero;
    else
        state_reg<=state_next;
        
always@*
begin
    state_next=state_reg;
    tick=1'b0;
    case (state_reg)
    zero:
        if (level)
        begin
            tick=1'b1; //this change is immediate
            state_next=one;
        end
    one:
        if (~level)
            state_next=zero;
    default:
        state_next=zero;
    endcase
end
endmodule
