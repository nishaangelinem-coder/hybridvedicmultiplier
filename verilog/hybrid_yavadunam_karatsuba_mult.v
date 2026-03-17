//============================================================================
// Module: hybrid_yavadunam_karatsuba_mult
// Description: Top-level N-bit hybrid Yavadunam-Karatsuba Vedic multiplier
//              Deterministically reduces N-bit multiplication to (N-1)-bit
// Reference:   Section 3.5, Fig. 5 of the paper
//
// ★ FIX: Added zero-detect bypass — when either operand is 0, P=0 directly.
//         This avoids the remainder overflow when 2^(N-1) - 0 = 2^(N-1)
//         exceeds (N-1)-bit width. For all non-zero operands, the remainder
//         is guaranteed ≤ 2^(N-1)-1.
//============================================================================

module hybrid_yavadunam_karatsuba_mult #(
    parameter N             = 32,
    parameter USE_KARATSUBA = 1
)(
    input  wire [N-1:0]    X,
    input  wire [N-1:0]    Y,
    output wire [2*N-1:0]  P,
    output wire [1:0]      mode
);

    // ── Zero-detect bypass ──
    wire x_is_zero = (X == {N{1'b0}});
    wire y_is_zero = (Y == {N{1'b0}});
    wire bypass_zero = x_is_zero | y_is_zero;

    // ── Internal signals ──
    wire        sigma_x, sigma_y;
    wire        add_sub, comp_en, sign_sel;    // legacy MCU outputs (unused by ACU now)
    wire [N-2:0] Xr, Yr;
    wire [2*(N-1)-1:0] XrYr;
    wire [2*N-1:0] P_computed;

    // ════════════════════════════════════════════════════════════
    //  (b) Mode Control Unit
    // ════════════════════════════════════════════════════════════
    mode_control_unit #(.N(N)) u_mcu (
        .X        (X),
        .Y        (Y),
        .mode     (mode),
        .sigma_x  (sigma_x),
        .sigma_y  (sigma_y),
        .add_sub  (add_sub),
        .comp_en  (comp_en),
        .sign_sel (sign_sel)
    );

    // ════════════════════════════════════════════════════════════
    //  (c) Remainder Generation
    // ════════════════════════════════════════════════════════════
    remainder_generator #(.N(N)) u_rem_x (
        .operand   (X),
        .sigma     (sigma_x),
        .remainder (Xr)
    );

    remainder_generator #(.N(N)) u_rem_y (
        .operand   (Y),
        .sigma     (sigma_y),
        .remainder (Yr)
    );

    // ════════════════════════════════════════════════════════════
    //  (d) Reduced-Width Multiplier Core
    // ════════════════════════════════════════════════════════════
    reduced_width_multiplier #(
        .N             (N),
        .USE_KARATSUBA (USE_KARATSUBA)
    ) u_mult (
        .Xr   (Xr),
        .Yr   (Yr),
        .XrYr (XrYr)
    );

    // ════════════════════════════════════════════════════════════
    //  (e) Arithmetic Combination Unit — now takes mode directly
    // ════════════════════════════════════════════════════════════
    arithmetic_combination_unit #(.N(N)) u_acu (
        .Xr       (Xr),
        .Yr       (Yr),
        .XrYr     (XrYr),
        .mode     (mode),
        .P        (P_computed)
    );

    // ════════════════════════════════════════════════════════════
    //  (g) Output with zero-detect bypass
    // ════════════════════════════════════════════════════════════
    assign P = bypass_zero ? {(2*N){1'b0}} : P_computed;

endmodule
