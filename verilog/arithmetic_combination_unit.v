//============================================================================
// Module: arithmetic_combination_unit
// Description: Mode-specific product formulation using Equations 3-6
//              Combines B², B·Xr, B·Yr, and XrYr with mode-dependent signs
// Reference:   Section 3.3, 3.5, Fig. 5(e) of the paper
//
// ★ FIX: Each term computed as unsigned, then added/subtracted per mode.
//         Eliminates signed subtraction wrap bug in (Xr - Yr).
//
// Equations expanded:
//   Mode I   (00): P = B² + B·Xr + B·Yr + XrYr      (Eq. 3)
//   Mode II  (01): P = B² + B·Xr - B·Yr - XrYr      (Eq. 4)
//   Mode III (10): P = B² - B·Xr + B·Yr - XrYr      (Eq. 5)
//   Mode IV  (11): P = B² - B·Xr - B·Yr + XrYr      (Eq. 6)
//============================================================================

module arithmetic_combination_unit #(
    parameter N = 32
)(
    input  wire [N-2:0]        Xr,          // (N-1)-bit remainder of X
    input  wire [N-2:0]        Yr,          // (N-1)-bit remainder of Y
    input  wire [2*(N-1)-1:0]  XrYr,        // (2N-2)-bit remainder product
    input  wire [1:0]          mode,        // 2-bit mode from MCU
    output wire [2*N-1:0]      P            // 2N-bit final product
);

    localparam W = 2 * N;

    // ── Term 1: B² = 2^(2(N-1)) ──
    wire [W-1:0] term_B2 = {{(W - 2*(N-1) - 1){1'b0}}, 1'b1, {(2*(N-1)){1'b0}}};

    // ── Term 2: B · Xr = Xr << (N-1) ──
    wire [W-1:0] term_BXr = {{(N+1){1'b0}}, Xr} << (N-1);

    // ── Term 3: B · Yr = Yr << (N-1) ──
    wire [W-1:0] term_BYr = {{(N+1){1'b0}}, Yr} << (N-1);

    // ── Term 4: XrYr ──
    wire [W-1:0] term_XrYr = {{2{1'b0}}, XrYr};

    // ── Mode-dependent combination ──
    reg [W-1:0] P_reg;

    always @(*) begin
        case (mode)
            2'b00: P_reg = term_B2 + term_BXr + term_BYr + term_XrYr;  // Eq. 3
            2'b01: P_reg = term_B2 + term_BXr - term_BYr - term_XrYr;  // Eq. 4
            2'b10: P_reg = term_B2 - term_BXr + term_BYr - term_XrYr;  // Eq. 5
            2'b11: P_reg = term_B2 - term_BXr - term_BYr + term_XrYr;  // Eq. 6
        endcase
    end

    assign P = P_reg;

endmodule
