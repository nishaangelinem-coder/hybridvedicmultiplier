//============================================================================
// Module: remainder_generator
// Description: Complement-based remainder extraction from Yavadunam sutra
//              Extracts (N-1)-bit remainder Xr = |X - 2^(N-1)| for any X
// Reference:   Section 3.1, 3.4, Fig. 1, Fig. 3 of the paper
//
// Operation:
//   If σ = +1 (X >= 2^(N-1)):  Xr = X - 2^(N-1) = X[N-2:0]  (direct extraction)
//   If σ = -1 (X <  2^(N-1)):  Xr = 2^(N-1) - X  (two's complement)
//
// Key Property: Xr is always bounded to (N-1) bits, enabling deterministic
//               bit-width reduction (Fig. 1d, Fig. 3b)
//============================================================================

module remainder_generator #(
    parameter N = 32
)(
    input  wire [N-1:0]   operand,     // N-bit input operand (X or Y)
    input  wire           sigma,       // polarity from MCU (1=positive, 0=negative)
    output wire [N-2:0]   remainder    // (N-1)-bit unsigned remainder
);

    // NOTE: When operand=0 and sigma=0, the true remainder is B=2^(N-1)
    // which overflows (N-1) bits. The top-level module handles this via
    // zero-detect bypass (P=0 when either operand is 0).
    // For all non-zero operands, the remainder is guaranteed ≤ 2^(N-1)-1.

    wire [N-2:0] lower_bits;
    wire [N-2:0] complement;

    // Direct extraction: X - 2^(N-1) = X[N-2:0] when X >= 2^(N-1)
    assign lower_bits = operand[N-2:0];

    // Two's complement: 2^(N-1) - X = ~X[N-2:0] + 1 when X < 2^(N-1)
    assign complement = ~operand[N-2:0] + 1'b1;

    // MUX: select based on polarity σ
    assign remainder = sigma ? lower_bits : complement;

endmodule
