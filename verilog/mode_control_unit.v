//============================================================================
// Module: mode_control_unit
// Description: Determines operational mode from MSB comparison of X and Y
//              Generates control signals for arithmetic combination unit
// Reference:   Section 3.2, Table 2, Fig. 2 of the paper
//
// Mode Classification (Table 2):
//   Mode I   (2'b00): X >= 2^(N-1), Y >= 2^(N-1) → σx=+1, σy=+1
//   Mode II  (2'b01): X >= 2^(N-1), Y <  2^(N-1) → σx=+1, σy=-1
//   Mode III (2'b10): X <  2^(N-1), Y >= 2^(N-1) → σx=-1, σy=+1
//   Mode IV  (2'b11): X <  2^(N-1), Y <  2^(N-1) → σx=-1, σy=-1
//============================================================================

module mode_control_unit #(
    parameter N = 32
)(
    input  wire [N-1:0] X,
    input  wire [N-1:0] Y,
    output wire [1:0]   mode,       // 2-bit mode encoding
    output wire         sigma_x,    // 1 = positive remainder, 0 = negative
    output wire         sigma_y,    // 1 = positive remainder, 0 = negative
    output wire         add_sub,    // 1 = addition of scaled remainders, 0 = subtraction
    output wire         comp_en,    // 1 = complement XrYr product
    output wire         sign_sel    // sign select for output assembly
);

    // MSB extraction — simple threshold comparison against 2^(N-1)
    // X >= 2^(N-1) iff X[N-1] == 1 (MSB is set)
    wire msb_x = X[N-1];
    wire msb_y = Y[N-1];

    // Polarity determination (Eq. 1)
    //   σx = +1 when X >= 2^(N-1)  →  msb_x = 1
    //   σx = -1 when X <  2^(N-1)  →  msb_x = 0
    assign sigma_x = msb_x;
    assign sigma_y = msb_y;

    // Mode encoding: {~msb_x, ~msb_y}
    //   Mode I   (00): both MSBs = 1  → both >= base
    //   Mode II  (01): msb_x=1, msb_y=0
    //   Mode III (10): msb_x=0, msb_y=1
    //   Mode IV  (11): both MSBs = 0  → both < base
    assign mode = {~msb_x, ~msb_y};

    // Control signal generation for Arithmetic Combination Unit
    // From Equations 3-6:
    //   Mode I:   P = B² + B(Xr + Yr) + XrYr  → add, no complement
    //   Mode II:  P = B² + B(Xr - Yr) - XrYr  → sub, complement product
    //   Mode III: P = B² - B(Xr - Yr) - XrYr  → sub, complement product
    //   Mode IV:  P = B² - B(Xr + Yr) + XrYr  → add, no complement

    // add_sub: 1 = add (Xr+Yr), 0 = subtract (Xr-Yr)
    // Modes I and IV use addition; Modes II and III use subtraction
    assign add_sub = (mode == 2'b00) || (mode == 2'b11);

    // comp_en: 1 = negate XrYr product (subtract instead of add)
    // Modes II and III negate the product
    assign comp_en = (mode == 2'b01) || (mode == 2'b10);

    // sign_sel: determines sign of B·(σxXr ± σyYr) term
    // Modes I and II: positive coefficient on B term
    // Modes III and IV: negative coefficient on B term
    assign sign_sel = ~msb_x;  // negative when X < base

endmodule
