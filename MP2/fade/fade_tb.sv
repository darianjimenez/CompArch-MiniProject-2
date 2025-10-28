`timescale 10ns/10ps
`include "top.sv"

module fade_tb;
    parameter PWM_INTERVAL = 1200;
    parameter INC_DEC_MAX = 200;
    parameter INC_DEC_INTERVAL = 10000;

    logic clk = 1'b0;
    logic RGB_R, RGB_G, RGB_B;

    top # (
        .PWM_INTERVAL     (PWM_INTERVAL),
        .INC_DEC_MAX      (INC_DEC_MAX),
        .INC_DEC_INTERVAL (INC_DEC_INTERVAL)
    ) u0 (
        .clk       (clk), 
        .RGB_R     (RGB_R),
        .RGB_G     (RGB_G),
        .RGB_B     (RGB_B)
    );

    initial begin
        $dumpfile("fade.vcd");
        $dumpvars(0, fade_tb); 
        #120000000;
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end
endmodule
