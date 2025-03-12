`timescale 1ns / 1ps
//Lab 9
//Main module
module mian(input CLK100MHZ, //System Clock
input [15:0]SW, //Switches
output [6:0]C, // Seven Segment Display
output DP, //Decimol point
output [7:0]AN, //the 8 SSGD
output LED,     //Used for if the alarm is on or off
output audioOut, //Outiod Out
output aud_sd, 
output [2:0]RGB1, //RGB LED 1
output [2:0]RGB2); //RGB LED 2
//INTERCONNECTIONS
//Digital Clock
wire clk400Hz, clk1Hz;
//For the counter for the clock
wire [5:0]seconds, minutes;
//For the digit separator of the clock numbers
wire [3:0]secOnes, secTens, minOnes, minTens;
//For the Display from the separator
wire [6:0]secOnesDis, secTensDis, minOnesDis, minTensDis;
//For the display for the Alarm in SSEG
wire [6:0]secOnesAlarm, secTensAlarm, minOnesAlarm, minTensAlarm;//Changing Display
wire [6:0]secOnesAlarmS, secTensAlarmS, minOnesAlarmS, minTensAlarmS;//Saved
//Alarm Signal
wire [3:0]secOnesAlarmSig, secTensAlarmSig, minOnesAlarmSig, minTensAlarmSig;
//Alarm Display
wire [3:0]secOnesAlarmDis, secTensAlarmDis, minOnesAlarmDis, minTensAlarmDis;
//Signals for strarting and stopping the alarm
wire ledSignal, signal, timer;
//IMPLEMENTING THE SUBMODULES
//Setting up the clock and the refresh rate
clockDivider createClocks(CLK100MHZ, clk400Hz, clk1Hz);
counter Clock(clk1Hz, SW[0], seconds, minutes);
//Separating the Sec and Min
digitSeparator sec(seconds, secTens, secOnes);
digitSeparator min(minutes, minTens, minOnes);
//Genarating the Display
bcd display1(secOnes, secOnesDis);
bcd display2(secTens, secTensDis);
bcd display3(minOnes, minOnesDis);
bcd display4(minTens, minTensDis);
//Alarm It outputs the changing displayed data and the saved data
SwitchDataSaver alarmSec1Set  (CLK100MHZ, SW[15:12], SW[8], secOnesAlarmDis ,secOnesAlarmSig);
SwitchDataSaver alarmSec10Set (CLK100MHZ, SW[15:12], SW[9], secTensAlarmDis ,secTensAlarmSig);
SwitchDataSaver alarmMin1Set  (CLK100MHZ, SW[15:12], SW[10], minOnesAlarmDis ,minOnesAlarmSig);
SwitchDataSaver alarmMin10Set (CLK100MHZ, SW[15:12], SW[11], minTensAlarmDis ,minTensAlarmSig);
//Comparing the Clock to the Alarm
checkAlarm check(CLK100MHZ, SW[1],
    secOnes, //Clock second ones
    secTens, //Clock second tens
    minOnes, //Clock minute ones
    minTens, //Clock minute tens
    secOnesAlarmSig, //Alarm second ones
    secTensAlarmSig, //Alarm second tens
    minOnesAlarmSig, //Alarm minute ones
    minTensAlarmSig, //Alarm minute tens
    ledSignal, signal);
//Extending the alarm signal to 10 sec
TenSecondPulse extend(clk1Hz, signal, timer);
//For the display of the Alarm SAVED DATA
bcd alarmSecOnesSaved(secOnesAlarmSig, secOnesAlarmS);//Seconds Ones
bcd alarmSecTensSaved(secTensAlarmSig, secTensAlarmS);//Seconds Tens
bcd alarmMinOnesSaved(minOnesAlarmSig, minOnesAlarmS);//Minutes Ones
bcd alarmMinTensSaved(minTensAlarmSig, minTensAlarmS);//Minutes Tens
//For the display of the Alarm CHANGING DATA
bcd alarmSecOnes(secOnesAlarmDis, secOnesAlarm);//Seconds Ones
bcd alarmSecTens(secTensAlarmDis, secTensAlarm);//Seconds Tens
bcd alarmMinOnes(minOnesAlarmDis, minOnesAlarm);//Minutes Ones
bcd alarmMinTens(minTensAlarmDis, minTensAlarm);//Minutes Tens
//Song
SongPlayer song(CLK100MHZ, timer, audioOut,  aud_sd);
//RGB
RGB_led Lights(clk1Hz, timer, RGB1, RGB2);
//LED
ledOn ledTurnOn(CLK100MHZ, ledSignal, LED);
//Controlling the Display
display myAlarmClock(clk400Hz, //POV Clock
    secOnesDis, secTensDis, minOnesDis, minTensDis, //For the normal clock
    secOnesAlarm, secTensAlarm, minOnesAlarm, minTensAlarm, //For displaying the changed alarm data
    secOnesAlarmS, secTensAlarmS, minOnesAlarmS, minTensAlarmS, //For setting the saved alarm data
    SW[6:2], //Switch to set the alarm
    C, DP, AN); //SSEG Display info
endmodule

//Sub Modules
module TenSecondPulse (
    input clk_1Hz,        // 1 Hz clock signal
    input signalIn,   // Start signal from another module
    output reg signalOut       // Output signal, high for 10 seconds
);
    reg [3:0] count = 0;       // 4-bit counter to count up to 10 seconds
    reg counting = 0;          // Flag indicating if counting is active

    // Counting logic
    always @(posedge clk_1Hz) 
    begin
         if (signalIn && !counting) 
         begin
            // Start counting when signalIn is high and counting is not active
            counting <= 1;
            signalOut <= 1;  // Set output high
            count <= 0;
        end 
        else if (counting) 
        begin
            // Increment count every 1 Hz clock cycle while counting
            if (count == 9) 
            begin
                count <= 0;      // Reset count after 10 seconds
                counting <= 0;   // Stop counting
                signalOut <= 0;  // Set output low after 10 seconds
            end 
            else 
            begin
                count <= count + 1;
            end
        end
    end
endmodule
//Inputing and saving swith data
module SwitchDataSaver(input clk,
input [3:0] inputSW,         // 4 switches representing binary data 0 to 9
input save_switch,           // Designated "save" switch to latch data
output reg [3:0] display,    // Output to display current switch positions
output reg [3:0] saved_data);// Register to hold saved data
reg save_switch_prev = 0; // Register to hold the previous state of save_switch

// Always block to monitor the save switch and latch data on rising edge
always @(posedge clk) 
begin
    display <= inputSW; // Continuously show current switch values on display

    // Detect rising edge of the save switch
    if (save_switch && !save_switch_prev)
    begin
        saved_data <= inputSW; // Save current switch values when triggered
    end

    save_switch_prev <= save_switch; // Update previous state of save switch
end

endmodule
//Checks for Alarm time is equal to the current time
module checkAlarm(input clock, input Switch, 
input [3:0]oneSecC, //Clock second ones
input [3:0]oneTenC, //Clock second tens
input [3:0]minOneC, //Clock minute ones
input [3:0]minTenC, //Clock minute tens
input [3:0]oneSecA, //Alarm second ones
input [3:0]oneTenA, //Alarm second tens
input [3:0]minSecA, //Alarm minute ones
input [3:0]minTenA, //Alarm minute tens
output reg LED, output reg alarm);
reg [15:0] clkTime;
reg [15:0] almTime;
always@(posedge clock)
begin
    clkTime = {minTenC, minOneC, oneTenC, oneSecC};
    almTime = {minTenA, minSecA, oneTenA, oneSecA};
    
    if(Switch == 1)
    begin
        LED = 1;
        if(clkTime == almTime)
        begin
            alarm = 1;
        end
        else
        begin
            alarm = 0;
        end
    end
    else
    begin
        LED = 0;
        alarm = 0;
    end
end
endmodule
//For creating the 2 clocks needed
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
//Used for creating the system clock
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
//Takes in the inuput and breaks it into Seven Segment or is a BCD to SSEG
module bcd(input [3:0]num, output reg [6:0]C);
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
        default: C = 7'b0000001; //0
        endcase
    end
endmodule
//Displaying to the SSD
module display(
input clk, //400Hz clock 
input [6:0]secOnes,  // Ones second Clock
input [6:0]secTens,  // Tens second Clock
input [6:0]minOnes,  // Ones minute Clock
input [6:0]minTens,  // Tens minute Clock
//For the changing of the alarm
input [6:0]secOnesA, // Ones second Alarm
input [6:0]secTensA, // Tens second Alarm
input [6:0]minOnesA, // Ones minute Alarm
input [6:0]minTensA, // Tens minute Alarm
//For the Saved alarm
input [6:0]secOnesS, // Ones second Alarm
input [6:0]secTensS, // Tens second Alarm
input [6:0]minOnesS, // Ones minute Alarm
input [6:0]minTensS, // Tens minute Alarm
input [4:0]SW,       // Switching between left and right 4 SSDISPLAYS
output reg[6:0]C,    // Seven Segments
output reg DP,       // Decimal Point
output reg [7:0]AN); // SSDisplay 
reg [1:0] patternState = 0;
always @ (posedge clk)
    begin
    patternState <= patternState + 1;
    case(patternState)
        2'b00: begin //Second Ones place
                   DP <= 1;
                   if(SW[0] == 0)
                   begin
                       C <= secOnes;
                       AN <= 8'b11111110;
                       end
                   else 
                   begin
                       if(SW[1] == 0) 
                       begin
                            C <= secOnesS; //Saved Alarm Data
                            AN <= 8'b11101111;
                       end
                       else
                       begin
                            C <= secOnesA;//Changable Alarm Data
                            AN <= 8'b11101111;
                       end
                   end   
               end
        2'b01: begin //Second Tens place
                   DP <= 1;
                   if(SW[0] == 0)
                    begin
                       C <= secTens; 
                       AN <= 8'b11111101;
                    end
                   else 
                   begin
                       if(SW[2] == 0) 
                       begin
                            C <= secTensS; //Saved Alarm Data
                            AN <= 8'b11011111;
                       end
                       else
                       begin
                            C <= secTensA;//Changable Alarm Data
                            AN <= 8'b11011111;
                       end
                   end   
               end
           2'b10: begin //Minute Ones place
               DP <= 0;
               if(SW[0] == 0)
               begin
                   C <= minOnes;
                   AN <= 8'b11111011;
               end
               else 
               begin
                   if(SW[3] == 0) 
                   begin
                        C <= minOnesS; //Saved Alarm Data
                        AN <= 8'b10111111;
                   end
                   else
                   begin
                        C <= minOnesA;//Changable Alarm Data
                        AN <= 8'b10111111;
                   end
               end   
           end
        2'b11: begin //Minute Tens Place
                   DP <= 1;
                   if(SW[0] == 0)
                    begin
                       C <= minTens;
                       AN <= 8'b11110111;
                    end
                   
                   else 
                   begin
                       if(SW[4] == 0) 
                       begin
                            C <= minTensS; //Saved Alarm Data
                            AN <= 8'b01111111;
                       end
                       else
                       begin
                            C <= minTensA;//Changable Alarm Data
                            AN <= 8'b01111111;
                       end
                   end   
               end
    endcase
   end
endmodule
//Sound Needs to change the timing but if not keep it
module SongPlayer( input clock, input playSound, output reg audioOut, output wire aud_sd);
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
	if(~playSound) 
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
parameter   C3 = 382234,
            D3 = 340530,
            D3S = 321419,
            F3 = 286352,
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
            G4S  = 120395,
            A4 = 113636,
            A4S = 107259,
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
//WAIT = ONE
6: 	begin note = SP; duration = HALF; 	end
//HIGH C3 C4 A3 A4 A3# A4# SECOND
7: 	begin note = C3; duration = QUARTER; 	end	
8: 	begin note = C4; duration = QUARTER; 	end	
9: 	begin note = A3; duration = QUARTER; 	end	
10: begin note = A4; duration = QUARTER; 	end
11: begin note = A3S; duration = QUARTER; 	end
12: begin note = A4S; duration = QUARTER; 	end
//WAIT
13: begin note = SP; duration = HALF;	end
//LOW F3 F4 D3 D4 D3# D4# FIRST
14: begin note = F3; duration = QUARTER; 	end
15: begin note = F4; duration = QUARTER; 	end
16: begin note = D3; duration = QUARTER;	end
17: begin note = D4; duration = QUARTER; 	end	
18: begin note = D3S; duration = QUARTER;   end	
19: begin note = D4S; duration = QUARTER; 	end	
//WAIT
20: begin note = SP; duration = HALF; 	end
//LOW F3 F4 D3 D4 D3# D4# SECOND
21: begin note = F3; duration = QUARTER; 	end
22: begin note = F4; duration = QUARTER; 	end
23: begin note = D3; duration = QUARTER; 	end
24: begin note = D4; duration = QUARTER; 	end	
25: begin note = D3S; duration = QUARTER; 	end	
26: begin note = D4S; duration = QUARTER; 	end
//WAIT
27:begin note = SP; duration = HALF;     end
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
//RGB
module RGB_led(input clock, input reset, output reg [2:0] RGB1, output reg [2:0]RGB2);
reg [4:0] count;     
always@(negedge reset, posedge clock)
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
        0: begin RGB1=1; RGB2=2; end
        2: begin RGB1=3; RGB2=4; end
        4: begin RGB1=5; RGB2=6; end
        6: begin RGB1=7; RGB2=1; end
        8: begin RGB1=1; RGB2=1; end
        default: begin RGB1=0; RGB2=0; end
       endcase
       count=count+1;
       if (count==9)
          count=0;
    end   
end   
endmodule
//LED
module ledOn(input clock, input reset, output reg LED);
always@(negedge reset, posedge clock)
begin
    if (~reset)
        LED = 0;
    else
        LED = 1;
end
endmodule