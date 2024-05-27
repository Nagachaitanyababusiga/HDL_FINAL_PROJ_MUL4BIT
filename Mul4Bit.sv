`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.05.2024 10:57:28
// Design Name: 
// Module Name: Mul4Bit
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


module Mul4Bit(input clk,reset,input[3:0] a,b, output reg[7:0] out);

//intermediate helpers
reg[3:0] m0;reg[4:0] m1;reg[5:0] m2;reg[6:0] m3;

//intermediate sums
reg[7:0] s1,s2,s3;

always @(posedge clk) begin
    if(reset==0) begin
        m0={4{a[0]}}& b[3:0];
        m1={4{a[1]}}& b[3:0];
        m2={4{a[2]}}& b[3:0];
        m3={4{a[3]}}& b[3:0];
        
        s1=m0+(m1<<1);
        s2=s1+(m2<<2);
        s3=s2+(m3<<3);
        
        out=s3;
    end
    else begin
        out<=0;
    end
end

endmodule
