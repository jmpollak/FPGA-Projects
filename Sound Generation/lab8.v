`timescale 1ns / 1ps

module SongPlayer( input clock, input reset, input playSound, output reg audioOut, output wire aud_sd);
reg [19:0] counter;
reg [31:0] time1, noteTime;
reg [9:0] msec, number;	//millisecond counter, and sequence number of musical note.
wire [4:0] note, duration;
wire [19:0] notePeriod;
parameter clockFrequency = 100_000_000; 

assign aud_sd = 1'b1;

MusicSheet 	mysong(number, notePeriod, duration	);
always @ (posedge clock) 
  begin
	if(~playSound) //ORIGINAL (reset | ~playSound)
 		begin 
          counter <=0;  
          time1<=0;  
          number <=0;  
          audioOut <=1;	
     	end
    else 
        begin
            counter <= counter + 1; 
            time1<= time1+1;
            if( counter >= notePeriod) 
            begin
                counter <=0;  
                audioOut <= ~audioOut ; 
            end	//toggle audio output 	
            if( time1 >= noteTime) 
            begin	
                time1 <=0;  
                number <= number + 1; 
            end  //play next note
            if(number == 50) 
                number <=0; // Make the number reset at the end of the song Original was 48
        end
  end	
         
  always @(duration) 
    noteTime = duration * (clockFrequency/8); 
       //number of   FPGA clock periods in one note.
endmodule

module MusicSheet( input [9:0] number, 
	output reg [19:0] note, 
	output reg [4:0] duration);
parameter   EIGHTH = 5'b00001; // Added in for quicker times
parameter   QUARTER = 5'b00010; 
parameter	HALF = 5'b00100;
parameter	ONE = 2* HALF;
parameter	TWO = 2* ONE;
parameter	FOUR = 2* TWO;
parameter   C2 = 764409,
            C2S = 721501,
            D2 = 681013,
            D2S = 642839,
            E2 = 606722,
            F2 = 572672,
            F2S = 540541,
            G2 = 510204,
            G2S  = 481556,
            A2 = 454545,
            A2S = 429037,
            B2 = 404957,
            
            C3 = 382234,
            C3S = 360776,
            D3 = 340530,
            D3S = 321419,
            E3 = 303380,
            F3 = 286352,
            F3S = 270270,
            G3 = 255102,
            G3S  = 240790,
            A3 = 227273,
            A3S = 214519,
            B3 = 202478,
            
            C4 = 191111,
            C4S = 180388,
            D4 = 170265,
            D4S = 160705,
            E4 = 151685,
            F4 = 143172,
            F4S = 135139,
            G4 = 127511,
            G4S  = 120395,
            A4 = 113636,
            A4S = 107259,
            B4 = 101239,
            SP = 1;
// All of this was put in for messing with pitch
always @ (number) begin
case(number) //Mario Underground theme
//HIGH C3 C4 A3 A4 A3# A4# FIRST
0: 	begin note = C3; duration = QUARTER;end	
1: 	begin note = C4; duration = QUARTER;end	
2: 	begin note = A3; duration = QUARTER;end	
3: 	begin note = A4; duration = QUARTER;end	
4: 	begin note = A3S; duration = QUARTER;end	
5: 	begin note = A4S; duration = QUARTER;end	
//WAIT
6: 	begin note = SP; duration = ONE; 	end
//HIGH C3 C4 A3 A4 A3# A4# SECOND
7: 	begin note = C3; duration = QUARTER; 	end	
8: 	begin note = C4; duration = QUARTER; 	end	
9: 	begin note = A3; duration = QUARTER; 	end	
10: begin note = A4; duration = QUARTER; 	end
11: begin note = A3S; duration = QUARTER; 	end
12: begin note = A4S; duration = QUARTER; 	end
//WAIT
13: begin note = SP; duration = ONE;	end
//LOW F3 F4 D3 D4 D3# D4# FIRST
14: begin note = F3; duration = QUARTER; 	end
15: begin note = F4; duration = QUARTER; 	end
16: begin note = D3; duration = QUARTER;	end
17: begin note = D4; duration = QUARTER; 	end	
18: begin note = D3S; duration = QUARTER;   end	
19: begin note = D4S; duration = QUARTER; 	end	
//WAIT
20: begin note = SP; duration = ONE; 	end
//LOW F3 F4 D3 D4 D3# D4# SECOND
21: begin note = F3; duration = QUARTER; 	end
22: begin note = F4; duration = QUARTER; 	end
23: begin note = D3; duration = QUARTER; 	end
24: begin note = D4; duration = QUARTER; 	end	
25: begin note = D3S; duration = QUARTER; 	end	
26: begin note = D4S; duration = QUARTER; 	end
//WAIT
27:begin note = SP; duration = ONE;     end
//1 D4# D4 C4# FAST
28: begin note = D4S; duration = EIGHTH; 	end	
29: begin note = D4; duration = EIGHTH; 	end
30: begin note = C4S; duration = EIGHTH; 	end
//2 C4 D4# D4 G3# //NORMAL
31: begin note = C4; duration = QUARTER; 	end
32: begin note = D4S; duration = QUARTER; 	end
33: begin note = D4; duration = QUARTER; 	end
34: begin note = G3S; duration = QUARTER; 	end
//3 G3 C4#  //NORMAL 
35: begin note = G3; duration = QUARTER; 	end
36: begin note = C4S; duration = QUARTER; 	end
// C4 F4# F4 E4 A4# A4 //FAST
37: begin note = C4; duration = EIGHTH; 	end
38: begin note = F4S; duration = EIGHTH; 	end
39: begin note = F4; duration = EIGHTH; 	end
40: begin note = E4; duration = EIGHTH; 	end
41: begin note = A4S; duration = EIGHTH; 	end
42: begin note = A4; duration = EIGHTH; 	end
//4 G4# D4# B3 A3# A3 G3# //FAST
43: begin note = G4S; duration = EIGHTH; 	end
44: begin note = D4S; duration = EIGHTH; 	end
45: begin note = B3; duration = EIGHTH; 	end //Would like to make this go for slightly a little longer but cant
46: begin note = A3S; duration = EIGHTH; 	end	
47: begin note = A3; duration = EIGHTH; 	end	
48: begin note = G3S; duration = EIGHTH; 	end	
//WAIT TO RESET
49: begin note = SP; duration = ONE; 	end	
default: 	begin note = C4; duration = FOUR; 	end
endcase
end
endmodule