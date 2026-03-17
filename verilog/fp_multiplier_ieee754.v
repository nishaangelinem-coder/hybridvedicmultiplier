//============================================================================
// Module: fp_multiplier_ieee754
// Description: IEEE-754 single-precision floating-point multiplier
//              Integrates the proposed hybrid multiplier at the mantissa stage
// Reference:   Section 4.2, Fig. 6 of the paper
//
// Pipeline stages (Fig. 6, Table 5):
//   (a) Input Unpacking:     Extract sign, exponent, mantissa fields
//   (b) Sign Computation:    S_result = S_A XOR S_B            (~0.2 ns)
//   (c) Exponent Processing: E_temp = E_A + E_B - 127          (~1.8 ns)
//   (d) Mantissa Multiply:   1.M_A × 1.M_B using proposed mult (~9.1 ns)
//   (e) Normalization:       Shift and adjust exponent          (~2.1 ns)
//   (f) Rounding:            Round-to-nearest-even              (~1.4 ns)
//   (g) Result Assembly:     Pack into 32-bit FP result
//   (h) Exception Handling:  Zero, Inf, NaN detection
//
// "Only the mantissa multiplication block was replaced with the proposed
//  hybrid Yavadunam-based architecture, while all other floating-point
//  stages were preserved." — Section 4.2
//============================================================================

module fp_multiplier_ieee754 #(
    parameter USE_KARATSUBA = 1     // 1 = proposed Karatsuba, 0 = direct
)(
    input  wire [31:0] FP_A,       // IEEE-754 single-precision operand A
    input  wire [31:0] FP_B,       // IEEE-754 single-precision operand B
    output reg  [31:0] FP_Result,  // IEEE-754 single-precision result
    output reg         overflow,
    output reg         underflow,
    output reg         is_nan,
    output reg         is_inf,
    output reg         is_zero
);

    // ════════════════════════════════════════════════════════════
    //  (a) Input Unpacking — Fig. 6(a)
    // ════════════════════════════════════════════════════════════
    wire        sign_a = FP_A[31];
    wire [7:0]  exp_a  = FP_A[30:23];
    wire [22:0] mant_a = FP_A[22:0];

    wire        sign_b = FP_B[31];
    wire [7:0]  exp_b  = FP_B[30:23];
    wire [22:0] mant_b = FP_B[22:0];

    // ════════════════════════════════════════════════════════════
    //  (h) Exception Detection — Fig. 6(h)
    // ════════════════════════════════════════════════════════════
    wire a_is_zero = (exp_a == 8'h00) && (mant_a == 23'h0);
    wire b_is_zero = (exp_b == 8'h00) && (mant_b == 23'h0);
    wire a_is_inf  = (exp_a == 8'hFF) && (mant_a == 23'h0);
    wire b_is_inf  = (exp_b == 8'hFF) && (mant_b == 23'h0);
    wire a_is_nan  = (exp_a == 8'hFF) && (mant_a != 23'h0);
    wire b_is_nan  = (exp_b == 8'hFF) && (mant_b != 23'h0);

    // ════════════════════════════════════════════════════════════
    //  (b) Sign Computation — Fig. 6(b)
    //      S_Result = S_A ⊕ S_B  (~0.2 ns)
    // ════════════════════════════════════════════════════════════
    wire result_sign = sign_a ^ sign_b;

    // ════════════════════════════════════════════════════════════
    //  (c) Exponent Processing — Fig. 6(c)
    //      E_temp = E_A + E_B - 127 (bias correction)  (~1.8 ns)
    // ════════════════════════════════════════════════════════════
    wire [9:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b};
    wire [9:0] exp_unbiased = exp_sum - 10'd127;

    // ════════════════════════════════════════════════════════════
    //  (d) Mantissa Multiplication — Fig. 6(d)
    //      Prepend implicit '1' → 24-bit × 24-bit = 48-bit product
    //      THIS IS THE PROPOSED HYBRID MULTIPLIER (N=24)
    //      Timing: ~9.1 ns (vs ~12.4 ns conventional)
    // ════════════════════════════════════════════════════════════
    wire [23:0] mant_a_full = {1'b1, mant_a};  // 1.M_A (24 bits)
    wire [23:0] mant_b_full = {1'b1, mant_b};  // 1.M_B (24 bits)

    wire [47:0] mant_product;
    wire [1:0]  mult_mode;  // debug: which mode was used

    // ★ Proposed Hybrid Yavadunam-Karatsuba Multiplier (N=24)
    hybrid_yavadunam_karatsuba_mult #(
        .N             (24),
        .USE_KARATSUBA (USE_KARATSUBA)
    ) u_mantissa_mult (
        .X    (mant_a_full),
        .Y    (mant_b_full),
        .P    (mant_product),
        .mode (mult_mode)
    );

    // ════════════════════════════════════════════════════════════
    //  (e) Normalization — Fig. 6(e)
    //      Check if product >= 2.0 (MSB of product is '1')
    //      If so, right-shift by 1 and increment exponent  (~2.1 ns)
    // ════════════════════════════════════════════════════════════
    wire        norm_shift = mant_product[47]; // product >= 2.0?
    wire [22:0] mant_normalized;
    wire [9:0]  exp_adjusted;
    wire        guard_bit, round_bit, sticky_bit;

    // If MSB=1: take bits [46:24] as mantissa, shift right
    // If MSB=0: take bits [45:23] as mantissa
    assign mant_normalized = norm_shift ? mant_product[46:24]
                                        : mant_product[45:23];

    assign exp_adjusted = norm_shift ? (exp_unbiased + 10'd1)
                                     : exp_unbiased;

    // Guard, round, sticky for rounding
    assign guard_bit  = norm_shift ? mant_product[23] : mant_product[22];
    assign round_bit  = norm_shift ? mant_product[22] : mant_product[21];
    assign sticky_bit = norm_shift ? (|mant_product[21:0]) : (|mant_product[20:0]);

    // ════════════════════════════════════════════════════════════
    //  (f) Rounding — Fig. 6(f)
    //      IEEE-754 round-to-nearest-even  (~1.4 ns)
    // ════════════════════════════════════════════════════════════
    wire round_up = guard_bit & (round_bit | sticky_bit | mant_normalized[0]);

    wire [23:0] mant_rounded = {1'b0, mant_normalized} + {23'b0, round_up};

    // Handle rounding overflow (mantissa becomes 1.000...0 → re-normalize)
    wire round_overflow = mant_rounded[23];
    wire [22:0] mant_final = round_overflow ? mant_rounded[23:1]
                                            : mant_rounded[22:0];
    wire [9:0]  exp_final  = round_overflow ? (exp_adjusted + 10'd1)
                                            : exp_adjusted;

    // ════════════════════════════════════════════════════════════
    //  (g) Result Assembly + (h) Exception Handling — Fig. 6(g,h)
    // ════════════════════════════════════════════════════════════
    always @(*) begin
        // Default: no exceptions
        overflow  = 1'b0;
        underflow = 1'b0;
        is_nan    = 1'b0;
        is_inf    = 1'b0;
        is_zero   = 1'b0;

        if (a_is_nan || b_is_nan) begin
            // NaN propagation
            FP_Result = {1'b0, 8'hFF, 23'h400000};  // Quiet NaN
            is_nan    = 1'b1;
        end
        else if (a_is_inf || b_is_inf) begin
            if (a_is_zero || b_is_zero) begin
                // 0 × Inf = NaN
                FP_Result = {1'b0, 8'hFF, 23'h400000};
                is_nan    = 1'b1;
            end else begin
                // Inf × finite = Inf
                FP_Result = {result_sign, 8'hFF, 23'h0};
                is_inf    = 1'b1;
            end
        end
        else if (a_is_zero || b_is_zero) begin
            // Anything × 0 = 0
            FP_Result = {result_sign, 8'h00, 23'h0};
            is_zero   = 1'b1;
        end
        else if (exp_final >= 10'd255) begin
            // Overflow → Infinity
            FP_Result = {result_sign, 8'hFF, 23'h0};
            overflow  = 1'b1;
            is_inf    = 1'b1;
        end
        else if (exp_final[9] == 1'b1 || exp_final == 10'd0) begin
            // Underflow → Zero (simplified: no denormalized support)
            FP_Result = {result_sign, 8'h00, 23'h0};
            underflow = 1'b1;
            is_zero   = 1'b1;
        end
        else begin
            // Normal result
            FP_Result = {result_sign, exp_final[7:0], mant_final};
        end
    end

endmodule
