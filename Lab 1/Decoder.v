module Decoder(input[2:0] data, output reg[7:0]y);
    always @(data)
    begin
        y=0;
        y[data]=1;
    end
endmodule