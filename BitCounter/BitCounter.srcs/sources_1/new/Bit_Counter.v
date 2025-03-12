`timescale 1ns / 1ps

module bit_counter (
    input clk,         // System clock (e.g., 50 MHz or similar)
    input reset,       // Reset button
    input start,       // Start button
    input [7:0] dataA,  // 8-bit input register for counting
    output reg done,        // Done flag
    output reg [3:0] dataB,     // 4-bit output to store count of '1's
    output reg [7:0] A      // Display register A on LEDs
);
    reg [1:0] state;       // FSM state
    wire clk_0_5Hz;         // 0.5 Hz clock
    
    //Create the 0.5 Hz Clock
    slowerClkGen myClock(clk, 1'b0, clk_0_5Hz);
    // State encoding
    parameter S1 = 2'b00, // Initialization
              S2 = 2'b01, // Counting loop
              S3 = 2'b10; // Done

    // FSM to count the '1's in register A
    always @(posedge clk_0_5Hz) begin
        if (reset) begin
            state <= S1;
            dataB <= 4'b0;
            A <= 8'b0;
            done <= 0;
        end else begin
            case (state)
                S1: begin
                    if (start) begin
                        A <= dataA; // Load A with input value
                        dataB <= 4'b0; // Reset B
                        done <= 0;
                        state <= S2;
                    end
                end
                S2: begin
                    if (A != 8'b0) begin
                        if (A[0] == 1) // Check LSB of A
                            dataB <= dataB + 1;
                        A <= A >> 1; // Right-shift A
                    end else begin
                        state <= S3; // Move to Done state
                    end
                end
                S3: begin
                    done <= 1; // Set done flag
                end
            endcase
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
