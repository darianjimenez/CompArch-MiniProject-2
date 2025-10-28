// Fade

module fade #(
    parameter INC_DEC_INTERVAL = 10000,                 // CLK frequency is 12MHz, so 12,000 cycles is 1ms
    parameter INC_DEC_MAX = 200,                        // Transition to next state after 200 increments / decrements, which is 0.2s
    parameter PWM_INTERVAL = 1200,                      // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX. // Duty increment per step
)(
    input logic clk, 
    // PWM outputs for RGB
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value,
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_g,
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_b
);
    localparam DUTY_MAX = PWM_INTERVAL - 1;

    // Declare variables for timing state transitions
    logic [$clog2(INC_DEC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(INC_DEC_MAX) - 1:0] inc_dec_count = 0;
    logic time_to_inc_dec = 1'b0;
    logic time_to_transition = 1'b0;

    // 6 state HSV sequence (0 - 360 degrees)
    typedef enum logic [2:0] {
        S0_RG_UP, S1_RDN, S2_B_UP, S3_GDN, S4_R_UP, S5_BDN
    } seg_t;
    seg_t current_state = S0_RG_UP;
    seg_t next_state;

    logic [$clog2(PWM_INTERVAL) - 1:0] ramp = 0;

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1) begin
            count <= 0;
            time_to_inc_dec <= 1'b1;
        end else begin
            count <= count + 1'b1;
            time_to_inc_dec <= 1'b0;
        end
    end

    // Implement counter for timing state transitions
    always_ff @(posedge clk) begin
        time_to_transition <= 1'b0;
        if (time_to_inc_dec) begin
            if (inc_dec_count == INC_DEC_MAX - 1) begin
                inc_dec_count <= 0;
                time_to_transition <= 1'b1;
            end else begin
                inc_dec_count <= inc_dec_count + 1'b1;
            end
        end
    end

    // Implement logic for next state 
    always_comb begin
        unique case (current_state)
            S0_RG_UP: next_state = S1_RDN;
            S1_RDN:   next_state = S2_B_UP;
            S2_B_UP:  next_state = S3_GDN;
            S3_GDN:   next_state = S4_R_UP;
            S4_R_UP:  next_state = S5_BDN;
            default:  next_state = S0_RG_UP;
        endcase
    end

    // Increment / Decrement PWM value as appropriate given current state
    always_ff @(posedge clk) begin
        if (time_to_transition) begin
            current_state <= next_state;
            ramp <= 0;
        end else if (time_to_inc_dec) begin
            if (ramp + INC_DEC_VAL >= DUTY_MAX) ramp <= DUTY_MAX;
            else ramp <= ramp + INC_DEC_VAL;
        end
    end

    // Map state and ramp to RGB duties
    always_comb begin 
        logic [$clog2(PWM_INTERVAL) - 1:0] R, G, B;
        R = 0;
        G = 0;
        B = 0;
        case (current_state)
            S0_RG_UP: begin R = DUTY_MAX;        G = ramp;            B = 0;              end
            S1_RDN: begin R = DUTY_MAX - ramp;   G = DUTY_MAX;        B = 0;              end
            S2_B_UP: begin R = 0;                G = DUTY_MAX;        B = ramp;           end
            S3_GDN: begin R = 0;                 G = DUTY_MAX - ramp; B = DUTY_MAX;       end
            S4_R_UP: begin R = ramp;             G = 0;               B = DUTY_MAX;       end
            S5_BDN: begin R = DUTY_MAX;          G = 0;               B = DUTY_MAX -ramp; end
        endcase
        pwm_value = R;
        pwm_value_g = G;
        pwm_value_b = B;
    end
endmodule
