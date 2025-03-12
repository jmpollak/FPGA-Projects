`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2024 02:31:41 PM
// Design Name: 
// Module Name: db_fsm
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
//Test case given from the book
module debounce_test(input wire clk, 
[1:0] bnt, 
output wire [7:0] AN, 
[7:0] sseg);
//Signal Declaration
reg [7:0] b_reg, d_reg;
wire [7:0] b_next, d_next;
reg bnt_reg, db_reg;
wire db_level, db_tick, bnt_tick, clr;
//Insatiate 7-seg LED display time-multiplexing module
disp_hex_mux disp_unit(clk, reset, b_reg[7:4], b_reg[3:0], 
                       d_reg[7:4], d_reg[3:0], 8'b11111011, AN, sseg);
//module disp_hex_mux(input wire clk, reset,
//input wire [3:0] hex3, hex2, hex1, hex0, // Hex digits
//input wire [7:0] dp_in,                  // 8 Decimal points
//output reg [7:0] an,                     // Enable 1 out of 4
//output reg [7:0] sseg);                  //LED segments                   
////Insantiate debouncing circuit
db_fsm db_unit(clk, reset, bnt[1], db_level);
//edge detection circuits
always @(posedge clk)
    begin
        bnt_reg <= bnt[1];
        db_reg <= db_level;
    end
assign bnt_tick = ~bnt_reg & bnt[1];
assign db_tick = ~db_reg & db_level;
                   
//two counters
assign clr = bnt[0];
always @(posedge clk)
    begin
        b_reg <= b_next;
        d_reg <= d_next;
    end
assign b_next = (clr)      ? 8'b0 :
                (bnt_tick) ? b_reg +1 : b_reg;
assign d_next = (clr)      ? 8'b0 :
                (db_tick) ? d_reg +1 : d_reg;
                
endmodule
//This was given from the book
module db_fsm(input wire clk,
    reset,
    sw,
    output reg db);
    //Symbolic state declaration
    localparam [2:0]
    zero    = 3'b000,
    wait1_1 = 3'b001,
    wait1_2 = 3'b010,
    wait1_3 = 3'b011,
    one     = 3'b100,
    wait0_1 = 3'b101,
    wait0_2 = 3'b110,
    wait0_3 = 3'b111;
    //Number of counter bits (2^n * 20ns = 10ms tick)
    localparam N = 19;
    //Signal declaration
    reg [N-1:0] q_reg;
    wire [N-1:0] q_next;
    wire m_tick;
    reg [2:0] state_reg, state_next;
    
    //Body
    /*
        Counter to generate 10 ms tick
    */
    always @(posedge clk)
        q_reg <= q_next;
    //next-state logic
    assign q_next = q_reg + 1;
    //output tick
    assign m_tick = (q_reg == 0) ? 1'b1 : 1'b0;
    /*
        debouncing FSM
    */
    //state register
    always @(posedge clk, posedge reset)
        if(reset)
            state_reg <= zero;
        else
            state_reg <= state_next;
    //Next_state logic and output logic
    always @*
    begin
        state_next = state_reg; //Defualt state: the same
        db = 1'b0;              //Defualt output: 0
        case(state_reg)
            zero:
                if(sw)
                    state_next = wait1_1;
            wait1_1:
                if(~sw)
                    state_next = zero;
                else
                    if(m_tick)
                        state_next = wait1_2;
            wait1_2:
                if(~sw)
                    state_next = zero;
                else
                    if(m_tick)
                        state_next = wait1_3;
            wait1_3:
                if(~sw)
                    state_next = zero;
                else
                    if(m_tick)
                        state_next = one;
            one:
                begin
                    db = 1'b1;
                    if(~sw)
                        state_next = wait0_1;
                end
            wait0_1:
                begin
                    db = 1'b1;
                    if(sw)
                        state_next = one;
                    else
                        if(m_tick)
                            state_next = wait0_2;
                end
            wait0_2:
                begin
                    db = 1'b1;
                    if(sw)
                        state_next = one;
                    else
                        if(m_tick)
                            state_next = wait0_3;
                end
            wait0_3:
                begin
                    db = 1'b1;
                    if(sw)
                        state_next = one;
                    else
                        if(m_tick)
                            state_next = zero;
                end
            default: state_next = zero;
        endcase
    end
    
endmodule

//Given from book Pg 137
module disp_hex_mux(input wire clk, reset,
input wire [3:0] hex3, hex2, hex1, hex0, // Hex digits
input wire [7:0] dp_in,                  // 8 Decimal points
output reg [7:0] an,                     // Enable 1 out of 4
output reg [7:0] sseg);                  //LED segments
//Constant declaration
//Refreshing rate around 800 Hz (50 MH.z/2"16) 
 localparam N = 18; // internal signal declaration 
 reg [N-1:0] q_reg; 
 wire [N-1:0] q_next; 
 reg [3:0] hex_in; 
 reg dp;
 // N-bit counter 
 // register 
 always @(posedge clk, posedge reset)
    if (reset) 
        q_reg <= 0; 
    else 
        q_reg <= q_next; 
    // next-state logic 
    assign q_next = q_reg + 1; 
    // 2 MSBs of counter to control 4-to-l multiplexing 
    // and to generate active-low enable signal 
    always @* 
    case (q_reg [N-1: N-2])
     2'b00: begin 
     an = 8'b11111110; 
     hex_in = hex0;
     dp = dp_in [0] ; end 
     2'b01: begin 
     an = 8'b11111101; 
     hex_in = hex1; 
     dp = dp_in [1] ; end 
     2'b10: begin 
     an = 8'b11111011; 
     hex_in = hex2; 
     dp = dp_in [2] ; end 
     default: begin 
     an = 8'b11110111; 
     hex_in = hex3; 
     dp = dp_in [3] ; end
    endcase 
    // hex to seven-segment led display 
    always @*
    begin 
        case (hex_in) 
            4'h0 : sseg [6:0] = 7'b0000001;
            4'h1 : sseg [6:0] = 7'b1001111; 
            4'h2 : sseg [6:0] = 7'b0010010; 
            4'h3 : sseg [6:0] = 7'b0000110; 
            4'h4 : sseg [6:0] = 7'b1001100; 
            4'h5 : sseg [6:0] = 7'b0100100; 
            4'h6 : sseg [6:0] = 7'b0100000;
            4'h7 : sseg [6:0] = 7'b0001111; 
            4'h8 : sseg [6:0] = 7'b0000000;
            4'h9 : sseg [6:0] = 7'b0000100; 
            4'ha : sseg [6:0] = 7'b0001000; 
            4'hb : sseg [6:0] = 7'b1100000; 
            4'hc : sseg [6:0] = 7'b0110001; 
            4'hd : sseg [6:0] = 7'b1000010; 
            4'he : sseg [6:0] = 7'b0110000; 
            default: sseg [6:0] = 7'b0111000; //4'hf 
            endcase 
            sseg [7] = dp; 
    end 
endmodule

