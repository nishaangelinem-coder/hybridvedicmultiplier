*=============================================================================
* File: tb_full_adder.sp
* Description: Testbench for 28T CMOS Full Adder
*              Transient simulation with all 8 input combinations
*              Measures propagation delay, power consumption, rise/fall times
* Reference:   Section 3, Table 2 (timing data), Section 4.5 (metrics)
*
* Simulator:   HSPICE / ngspice / Cadence Spectre / LTspice
* Run:         ngspice tb_full_adder.sp
*              hspice tb_full_adder.sp
*=============================================================================

.include 'ptm_45nm.lib'
.include 'cmos_full_adder_28T.sp'

* ══════════════════════════════════════════════════════════════════════════
*  Power Supply
* ══════════════════════════════════════════════════════════════════════════
.param VDD_VAL = 1.0
VDD   vdd 0 DC VDD_VAL
VGND  gnd 0 DC 0

* ══════════════════════════════════════════════════════════════════════════
*  DUT: Full Adder Instance
* ══════════════════════════════════════════════════════════════════════════
XDUT A B CIN SUM COUT vdd gnd CMOS_FA

* ══════════════════════════════════════════════════════════════════════════
*  Load Capacitances (typical fanout-of-4 for 45nm)
* ══════════════════════════════════════════════════════════════════════════
CL_SUM  SUM  0 5f
CL_COUT COUT 0 5f

* ══════════════════════════════════════════════════════════════════════════
*  Input Stimulus — all 8 combinations cycled
*  Period = 2ns per combination, total = 16ns
*
*  Time(ns)  A  B  CIN  |  Expected SUM  COUT
*  0-2       0  0   0   |     0          0
*  2-4       0  0   1   |     1          0
*  4-6       0  1   0   |     1          0
*  6-8       0  1   1   |     0          1
*  8-10      1  0   0   |     1          0
*  10-12     1  0   1   |     0          1
*  12-14     1  1   0   |     0          1
*  14-16     1  1   1   |     1          1
* ══════════════════════════════════════════════════════════════════════════

* Input A: 0000 1111 (changes at 8ns)
VA A 0 PWL(
+ 0.0n 0  7.9n 0  8.0n VDD_VAL  16.0n VDD_VAL
+ )

* Input B: 0011 0011 (changes at 4ns, 8ns, 12ns)
VB B 0 PWL(
+ 0.0n 0  3.9n 0  4.0n VDD_VAL  7.9n VDD_VAL
+ 8.0n 0  11.9n 0  12.0n VDD_VAL  16.0n VDD_VAL
+ )

* Input CIN: 0101 0101 (toggles every 2ns)
VCIN CIN 0 PWL(
+ 0.0n 0  1.9n 0  2.0n VDD_VAL  3.9n VDD_VAL
+ 4.0n 0  5.9n 0  6.0n VDD_VAL  7.9n VDD_VAL
+ 8.0n 0  9.9n 0  10.0n VDD_VAL  11.9n VDD_VAL
+ 12.0n 0  13.9n 0  14.0n VDD_VAL  16.0n VDD_VAL
+ )

* ══════════════════════════════════════════════════════════════════════════
*  Analysis Commands
* ══════════════════════════════════════════════════════════════════════════

.tran 10p 18n

* ── Delay Measurements ──
* Measure propagation delay: 50% input → 50% output
.meas tran tpd_sum_rise   TRIG v(CIN) VAL='VDD_VAL/2' RISE=1
+                         TARG v(SUM) VAL='VDD_VAL/2'  RISE=1
.meas tran tpd_sum_fall   TRIG v(CIN) VAL='VDD_VAL/2' FALL=1
+                         TARG v(SUM) VAL='VDD_VAL/2'  FALL=1
.meas tran tpd_cout_rise  TRIG v(B) VAL='VDD_VAL/2'   RISE=1
+                         TARG v(COUT) VAL='VDD_VAL/2' RISE=1
.meas tran tpd_cout_fall  TRIG v(B) VAL='VDD_VAL/2'   FALL=1
+                         TARG v(COUT) VAL='VDD_VAL/2' FALL=1

* ── Average propagation delay ──
.meas tran tpd_sum_avg PARAM='(tpd_sum_rise+tpd_sum_fall)/2'
.meas tran tpd_cout_avg PARAM='(tpd_cout_rise+tpd_cout_fall)/2'

* ── Power Measurement ──
.meas tran avg_power AVG POWER FROM=0n TO=16n
.meas tran avg_current AVG I(VDD) FROM=0n TO=16n

* ── Rise/Fall Time ──
.meas tran tr_sum TRIG v(SUM) VAL='0.1*VDD_VAL' RISE=1
+                 TARG v(SUM) VAL='0.9*VDD_VAL' RISE=1
.meas tran tf_sum TRIG v(SUM) VAL='0.9*VDD_VAL' FALL=1
+                 TARG v(SUM) VAL='0.1*VDD_VAL' FALL=1

* ══════════════════════════════════════════════════════════════════════════
*  Output
* ══════════════════════════════════════════════════════════════════════════
.option post=2
.print tran v(A) v(B) v(CIN) v(SUM) v(COUT) v(P)

.control
run
plot v(A)+6 v(B)+4 v(CIN)+2 v(SUM) v(COUT)-2
+ title 'Full Adder 28T — Transient Response'
+ xlabel 'Time (ns)' ylabel 'Voltage (V)'
meas tran tpd_sum_rise TRIG v(CIN) VAL=0.5 RISE=1 TARG v(SUM) VAL=0.5 RISE=1
meas tran tpd_cout_rise TRIG v(B) VAL=0.5 RISE=1 TARG v(COUT) VAL=0.5 RISE=1
print all
write tb_full_adder.raw
.endc

.end
