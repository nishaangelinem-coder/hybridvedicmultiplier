//============================================================================
// Baseline multiplier architectures for fair comparison
// Reference: Section 4.4 of the paper
//
// "For fair benchmarking, the following multiplier architectures were
//  implemented using the same HDL style and synthesis constraints"
//============================================================================


//────────────────────────────────────────────────────────────────────────────
// 1. Conventional Array Multiplier
//    Full-width NxN partial-product generation with ripple-carry addition
//────────────────────────────────────────────────────────────────────────────
module array_multiplier #(
    parameter N = 32
)(
    input  wire [N-1:0]    X,
    input  wire [N-1:0]    Y,
    output wire [2*N-1:0]  P
);

    // Partial product generation and accumulation
    // Structural: each row generates AND partial products, then ripple-adds
    wire [2*N-1:0] partial_products [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_pp
            // Partial product row i: (Y[i] AND X) shifted left by i
            assign partial_products[i] = ({2*N{Y[i]}} & {{N{1'b0}}, X}) << i;
        end
    endgenerate

    // Ripple accumulation of partial products
    // Using ripple-carry for fair comparison (Section 4.1)
    reg [2*N-1:0] sum;
    integer j;

    always @(*) begin
        sum = {2*N{1'b0}};
        for (j = 0; j < N; j = j + 1)
            sum = sum + partial_products[j];
    end

    assign P = sum;

endmodule


//────────────────────────────────────────────────────────────────────────────
// 2. Urdhva-Tiryakbhyam Vedic Multiplier
//    Cross-product parallel generation (recursive 2-way split)
//    References [9-11, 13, 16] in the paper
//────────────────────────────────────────────────────────────────────────────
module urdhva_multiplier #(
    parameter N = 32
)(
    input  wire [N-1:0]    X,
    input  wire [N-1:0]    Y,
    output wire [2*N-1:0]  P
);

    generate
        if (N <= 4) begin : base_case
            // Base case: direct multiply for small widths
            assign P = X * Y;
        end else begin : recursive_case
            localparam HALF = N / 2;

            wire [HALF-1:0] Xl = X[HALF-1:0];
            wire [HALF-1:0] Xh = X[N-1:HALF];
            wire [HALF-1:0] Yl = Y[HALF-1:0];
            wire [HALF-1:0] Yh = Y[N-1:HALF];

            // Four cross-products (Urdhva-Tiryakbhyam pattern)
            wire [2*HALF-1:0] P_ll, P_hh;
            wire [2*HALF-1:0] P_lh, P_hl;

            urdhva_multiplier #(.N(HALF)) u_ll (.X(Xl), .Y(Yl), .P(P_ll));
            urdhva_multiplier #(.N(HALF)) u_hh (.X(Xh), .Y(Yh), .P(P_hh));
            urdhva_multiplier #(.N(HALF)) u_lh (.X(Xl), .Y(Yh), .P(P_lh));
            urdhva_multiplier #(.N(HALF)) u_hl (.X(Xh), .Y(Yl), .P(P_hl));

            // Combine: P = P_hh·2^N + (P_lh + P_hl)·2^(N/2) + P_ll
            wire [2*N-1:0] cross_sum = {{HALF{1'b0}}, P_lh, {HALF{1'b0}}}
                                      + {{HALF{1'b0}}, P_hl, {HALF{1'b0}}};

            assign P = {P_hh, {(2*HALF){1'b0}}} + cross_sum + {{(2*HALF){1'b0}}, P_ll};
        end
    endgenerate

endmodule


//────────────────────────────────────────────────────────────────────────────
// 3. Karatsuba Recursive Multiplier
//    O(N^1.58) complexity via 3-multiplication decomposition
//    Reference [5] in the paper
//────────────────────────────────────────────────────────────────────────────
module karatsuba_multiplier #(
    parameter N = 32
)(
    input  wire [N-1:0]    X,
    input  wire [N-1:0]    Y,
    output wire [2*N-1:0]  P
);

    generate
        if (N <= 4) begin : base_case
            assign P = X * Y;
        end else begin : recursive_case
            localparam HALF = N / 2;

            wire [HALF-1:0] Xl = X[HALF-1:0];
            wire [HALF-1:0] Xh = X[N-1:HALF];
            wire [HALF-1:0] Yl = Y[HALF-1:0];
            wire [HALF-1:0] Yh = Y[N-1:HALF];

            // Three recursive multiplications (Karatsuba trick)
            wire [2*HALF-1:0] Z0, Z2;
            wire [2*(HALF+1)-1:0] Z1_raw;

            // Z0 = Xl × Yl
            karatsuba_multiplier #(.N(HALF)) u_z0 (.X(Xl), .Y(Yl), .P(Z0));

            // Z2 = Xh × Yh
            karatsuba_multiplier #(.N(HALF)) u_z2 (.X(Xh), .Y(Yh), .P(Z2));

            // Z1 = (Xh + Xl)(Yh + Yl) — needs (HALF+1) bits for sums
            wire [HALF:0] sum_x = {1'b0, Xh} + {1'b0, Xl};
            wire [HALF:0] sum_y = {1'b0, Yh} + {1'b0, Yl};

            karatsuba_multiplier #(.N(HALF+1)) u_z1 (
                .X(sum_x), .Y(sum_y), .P(Z1_raw)
            );

            // Cross term: Z1 = Z1_raw - Z0 - Z2
            wire [2*(HALF+1)-1:0] Z0_ext = {{2{1'b0}}, Z0};
            wire [2*(HALF+1)-1:0] Z2_ext = {{2{1'b0}}, Z2};
            wire [2*(HALF+1)-1:0] Z1 = Z1_raw - Z0_ext - Z2_ext;

            // Final: P = Z2·2^(2·HALF) + Z1·2^HALF + Z0
            wire [2*N-1:0] term_z2 = {{(2*N-2*HALF){1'b0}}, Z2} << (2*HALF);
            wire [2*N-1:0] term_z1 = {{(2*N-2*(HALF+1)){1'b0}}, Z1} << HALF;
            wire [2*N-1:0] term_z0 = {{(2*N-2*HALF){1'b0}}, Z0};

            assign P = term_z2 + term_z1 + term_z0;
        end
    endgenerate

endmodule
