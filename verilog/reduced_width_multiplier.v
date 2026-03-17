//============================================================================
// Module: reduced_width_multiplier
// Description: (N-1) × (N-1) bit multiplier core that computes XrYr
//              Supports both direct multiplication and Karatsuba decomposition
// Reference:   Section 3.5, Fig. 5(d) of the paper
//
// "A single (N-1) × (N-1) bit multiplier that computes XrYr. This block can
//  be implemented using either a conventional structure (for fair comparison)
//  or the Karatsuba decomposition shown in Figure 4."
//
// Parameter USE_KARATSUBA selects the implementation:
//   0 = Direct (N-1)×(N-1) multiply (for fair baseline comparison)
//   1 = Karatsuba-inspired 3-multiplier decomposition (Fig. 4)
//============================================================================

module reduced_width_multiplier #(
    parameter N             = 32,
    parameter USE_KARATSUBA = 1      // 1 = Karatsuba, 0 = direct multiply
)(
    input  wire [N-2:0]        Xr,          // (N-1)-bit remainder
    input  wire [N-2:0]        Yr,          // (N-1)-bit remainder
    output wire [2*(N-1)-1:0]  XrYr         // (2N-2)-bit product
);

    generate
        if (USE_KARATSUBA) begin : gen_karatsuba
            karatsuba_submult #(
                .REM_WIDTH(N-1)
            ) u_kara (
                .Xr      (Xr),
                .Yr      (Yr),
                .product (XrYr)
            );
        end else begin : gen_direct
            // Direct combinational multiply — for baseline comparison
            assign XrYr = Xr * Yr;
        end
    endgenerate

endmodule
