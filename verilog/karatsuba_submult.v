//============================================================================
// Module: karatsuba_submult
// Description: Single-level Karatsuba-inspired decomposition of (N-1)-bit
//              remainder product XrYr, using 3 sub-multiplications
// Reference:   Section 3.4, Fig. 4 of the paper
//
// Decomposition (Fig. 4b):
//   Let k = ceil((N-1)/2)
//   Xr = Xrh·2^k + Xrl,  Yr = Yrh·2^k + Yrl
//
//   P1 = Xrh × Yrh
//   P3 = Xrl × Yrl
//   P2 = (Xrh + Xrl)(Yrh + Yrl) - P1 - P3   (cross term)
//
//   XrYr = P1·2^(2k) + P2·2^k + P3
//
// This is a FLAT, single-level decomposition (no recursion) — Fig. 4c
//============================================================================

module karatsuba_submult #(
    parameter REM_WIDTH = 31    // (N-1) bits, e.g., 31 for N=32
)(
    input  wire [REM_WIDTH-1:0]     Xr,
    input  wire [REM_WIDTH-1:0]     Yr,
    output wire [2*REM_WIDTH-1:0]   product     // (2*(N-1))-bit product
);

    // Half-width parameter: k = ceil(REM_WIDTH / 2)
    localparam K  = (REM_WIDTH + 1) / 2;        // high half width
    localparam KL = REM_WIDTH - K;               // low half width (may differ by 1)

    // ── (a) Remainder Partition (Fig. 4a) ──
    wire [K-1:0]   Xrh = Xr[REM_WIDTH-1 : KL];   // High bits
    wire [KL-1:0]  Xrl = Xr[KL-1 : 0];            // Low bits
    wire [K-1:0]   Yrh = Yr[REM_WIDTH-1 : KL];
    wire [KL-1:0]  Yrl = Yr[KL-1 : 0];

    // ── Pre-addition for cross term (Fig. 4c) ──
    // (Xrh + Xrl) and (Yrh + Yrl) — may produce (K+1)-bit sums
    wire [K:0] sum_x = {1'b0, Xrh} + {{(K-KL+1){1'b0}}, Xrl};
    wire [K:0] sum_y = {1'b0, Yrh} + {{(K-KL+1){1'b0}}, Yrl};

    // ── (b) Three parallel multiplications (Fig. 4c) ──
    // P1 = Xrh × Yrh   (K×K → 2K bits)
    wire [2*K-1:0] P1 = Xrh * Yrh;

    // P3 = Xrl × Yrl   (KL×KL → 2KL bits)
    wire [2*KL-1:0] P3 = Xrl * Yrl;

    // P_cross = (Xrh+Xrl) × (Yrh+Yrl)   ((K+1)×(K+1) → 2(K+1) bits)
    wire [2*(K+1)-1:0] P_cross = sum_x * sum_y;

    // ── Cross-term subtraction (Fig. 4c SUB block) ──
    // P2 = P_cross - P1 - P3
    wire [2*(K+1)-1:0] P1_ext = {{2{1'b0}}, P1};
    wire [2*(K+1)-1:0] P3_ext = {{(2*(K+1)-2*KL){1'b0}}, P3};
    wire [2*(K+1)-1:0] P2 = P_cross - P1_ext - P3_ext;

    // ── Final assembly with shifts (Fig. 4c) ──
    // XrYr = P1 << 2*KL  +  P2 << KL  +  P3
    wire [2*REM_WIDTH-1:0] P1_shifted = {{(2*REM_WIDTH-2*K){1'b0}}, P1} << (2*KL);
    wire [2*REM_WIDTH-1:0] P2_shifted = {{(2*REM_WIDTH-2*(K+1)){1'b0}}, P2} << KL;
    wire [2*REM_WIDTH-1:0] P3_extended = {{(2*REM_WIDTH-2*KL){1'b0}}, P3};

    assign product = P1_shifted + P2_shifted + P3_extended;

endmodule
