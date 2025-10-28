`include "fade.sv"
`include "pwm.sv"

// Fade top level module

module top #(
    parameter PWM_INTERVAL = 1200, // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_DEC_MAX = 200,
    parameter INC_DEC_INTERVAL = 10000
)(
    input  logic clk, 
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    // Duty counts for RGB channels
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value;
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_g;
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_b;

    // PWM outputs before inversion 
    logic pwm_out;
    logic pwm_out_g;
    logic pwm_out_b;

    // HSV duty generator
    fade #(
        .INC_DEC_INTERVAL  (INC_DEC_INTERVAL),
        .INC_DEC_MAX       (INC_DEC_MAX),
        .PWM_INTERVAL      (PWM_INTERVAL)
    ) u1 (
        .clk            (clk), 
        .pwm_value      (pwm_value),
        .pwm_value_g    (pwm_value_g),
        .pwm_value_b    (pwm_value_b)
    );

    // Declare 3 PWM channels, one per color
    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2_r (
        .clk            (clk), 
        .pwm_value      (pwm_value), 
        .pwm_out        (pwm_out)
    );
    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2_g (
        .clk            (clk), 
        .pwm_value      (pwm_value_g), 
        .pwm_out        (pwm_out_g)
    );
    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2_b (
        .clk            (clk), 
        .pwm_value      (pwm_value_b), 
        .pwm_out        (pwm_out_b)
    );

    assign RGB_R = ~pwm_out;
    assign RGB_G = ~pwm_out_g;
    assign RGB_B = ~pwm_out_b;
endmodule
