//============================================================================
// Module: hybrid_mult_tb
// Description: Self-checking testbench for the hybrid Yavadunam-Karatsuba
//              multiplier — Verilog-2001 compatible (iverilog / Vivado / Xcelium)
// Reference:   Section 4.6 of the paper
//============================================================================

`timescale 1ns / 1ps

module hybrid_mult_tb;

    integer i, j, errors, total, seed;

    // ── 8-bit DUT ──
    reg  [7:0]  x8, y8;
    wire [15:0] p8;
    wire [1:0]  mode8;
    hybrid_yavadunam_karatsuba_mult #(.N(8), .USE_KARATSUBA(1)) u8 (
        .X(x8), .Y(y8), .P(p8), .mode(mode8));

    // ── 16-bit DUT ──
    reg  [15:0] x16, y16;
    wire [31:0] p16;
    wire [1:0]  mode16;
    hybrid_yavadunam_karatsuba_mult #(.N(16), .USE_KARATSUBA(1)) u16 (
        .X(x16), .Y(y16), .P(p16), .mode(mode16));

    // ── 32-bit DUT ──
    reg  [31:0] x32, y32;
    wire [63:0] p32;
    wire [1:0]  mode32;
    hybrid_yavadunam_karatsuba_mult #(.N(32), .USE_KARATSUBA(1)) u32 (
        .X(x32), .Y(y32), .P(p32), .mode(mode32));

    // ── IEEE-754 FP DUT ──
    reg  [31:0] fp_a, fp_b;
    wire [31:0] fp_result;
    wire fp_ovf, fp_udf, fp_nan, fp_inf, fp_zero;
    fp_multiplier_ieee754 #(.USE_KARATSUBA(1)) ufp (
        .FP_A(fp_a), .FP_B(fp_b), .FP_Result(fp_result),
        .overflow(fp_ovf), .underflow(fp_udf),
        .is_nan(fp_nan), .is_inf(fp_inf), .is_zero(fp_zero));

    // ── Temporaries ──
    reg [15:0] exp16;
    reg [31:0] exp32;
    reg [63:0] exp64;

    initial begin
        $dumpfile("hybrid_mult_tb.vcd");
        $dumpvars(0, hybrid_mult_tb);

        $display("");
        $display("================================================================");
        $display("  Hybrid Yavadunam-Karatsuba Multiplier Verification");
        $display("================================================================");

        x8=0; y8=0; x16=0; y16=0; x32=0; y32=0; fp_a=0; fp_b=0;
        #10;

        // ── TEST 1: 8-bit Exhaustive (65,536 vectors) ──
        $display("");
        $display("--- TEST 1: 8-bit Exhaustive (65,536 vectors) ---");
        errors = 0; total = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                x8 = i[7:0]; y8 = j[7:0]; #1;
                exp16 = i[7:0] * j[7:0];
                if (p8 !== exp16) begin
                    if (errors < 5)
                        $display("  FAIL: %0d x %0d = %0d (got %0d)", i, j, exp16, p8);
                    errors = errors + 1;
                end
                total = total + 1;
            end
        end
        if (errors == 0) $display("  PASS: %0d/%0d vectors correct", total, total);
        else $display("  FAIL: %0d errors in %0d vectors", errors, total);

        // ── TEST 2: 16-bit Random (10,000 vectors) ──
        $display("");
        $display("--- TEST 2: 16-bit Random (10,000 vectors) ---");
        errors = 0; seed = 42;
        for (i = 0; i < 10000; i = i + 1) begin
            x16 = $random(seed); y16 = $random(seed); #1;
            exp32 = x16 * y16;
            if (p16 !== exp32) begin
                if (errors < 5)
                    $display("  FAIL: 0x%04h x 0x%04h = 0x%08h (got 0x%08h)", x16, y16, exp32, p16);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("  PASS: 10000/10000 vectors correct");
        else $display("  FAIL: %0d errors", errors);

        // ── TEST 3: 32-bit Random (10,000 vectors) ──
        $display("");
        $display("--- TEST 3: 32-bit Random (10,000 vectors) ---");
        errors = 0; seed = 99;
        for (i = 0; i < 10000; i = i + 1) begin
            x32 = $random(seed); y32 = $random(seed); #1;
            exp64 = x32 * y32;
            if (p32 !== exp64) begin
                if (errors < 5)
                    $display("  FAIL: 0x%08h x 0x%08h", x32, y32);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("  PASS: 10000/10000 vectors correct");
        else $display("  FAIL: %0d errors", errors);

        // ── TEST 4: Mode Coverage (32-bit) ──
        $display("");
        $display("--- TEST 4: Mode Coverage (32-bit) ---");
        x32=32'hA5B3C2D1; y32=32'hB2C3D4E5; #1; exp64=x32*y32;
        $display("  Mode I   (++): mode=%0d %s", mode32, (p32===exp64)?"PASS":"FAIL");
        x32=32'h8A3F5B2C; y32=32'h4F2A3C1B; #1; exp64=x32*y32;
        $display("  Mode II  (+-): mode=%0d %s", mode32, (p32===exp64)?"PASS":"FAIL");
        x32=32'h3C2E1A5F; y32=32'hA5B3C2D1; #1; exp64=x32*y32;
        $display("  Mode III (-+): mode=%0d %s", mode32, (p32===exp64)?"PASS":"FAIL");
        x32=32'h3A4B5C6D; y32=32'h1234ABCD; #1; exp64=x32*y32;
        $display("  Mode IV  (--): mode=%0d %s", mode32, (p32===exp64)?"PASS":"FAIL");

        // ── TEST 5: Edge Cases ──
        $display("");
        $display("--- TEST 5: Edge Cases ---");
        x32=0; y32=0; #1; exp64=0;
        $display("  0 x 0     = %0d %s", p32, (p32===exp64)?"PASS":"FAIL");
        x32=0; y32=32'hFFFFFFFF; #1; exp64=0;
        $display("  0 x MAX   = %0d %s", p32, (p32===exp64)?"PASS":"FAIL");
        x32=1; y32=1; #1; exp64=1;
        $display("  1 x 1     = %0d %s", p32, (p32===exp64)?"PASS":"FAIL");
        x32=32'hFFFFFFFF; y32=32'hFFFFFFFF; #1; exp64=64'hFFFFFFFE00000001;
        $display("  MAX x MAX = 0x%h %s", p32, (p32===exp64)?"PASS":"FAIL");
        x32=32'h80000000; y32=1; #1; exp64=64'h80000000;
        $display("  2^31 x 1  = 0x%h %s", p32, (p32===exp64)?"PASS":"FAIL");

        // ── TEST 6: IEEE-754 FP ──
        $display("");
        $display("--- TEST 6: IEEE-754 FP Multiply ---");
        fp_a=32'h40000000; fp_b=32'h40400000; #1;  // 2.0 x 3.0 = 6.0
        $display("  2.0 x 3.0 = 0x%h %s", fp_result, (fp_result==32'h40C00000)?"PASS":"FAIL");
        fp_a=32'h00000000; fp_b=32'h3F800000; #1;  // 0 x 1 = 0
        $display("  0.0 x 1.0 = 0x%h %s", fp_result, (fp_result[30:0]==31'h0)?"PASS":"FAIL");
        fp_a=32'h3FC00000; fp_b=32'h3FC00000; #1;  // 1.5 x 1.5 = 2.25
        $display("  1.5 x 1.5 = 0x%h %s", fp_result, (fp_result==32'h40100000)?"PASS":"FAIL");
        fp_a=32'h7F800000; fp_b=32'h3F800000; #1;  // Inf x 1 = Inf
        $display("  Inf x 1.0 = 0x%h %s", fp_result, (fp_result==32'h7F800000)?"PASS":"FAIL");
        fp_a=32'h7FC00000; fp_b=32'h3F800000; #1;  // NaN x 1 = NaN
        $display("  NaN x 1.0 = nan=%b %s", fp_nan, fp_nan?"PASS":"FAIL");

        $display("");
        $display("================================================================");
        $display("  ALL TESTS COMPLETE");
        $display("================================================================");
        #10 $finish;
    end

endmodule
