*=============================================================================
* File: tb_twos_complement.sp
* Description: Testbench for 4-bit 2's Complement Generator
*              Verifies: OUT = -A (2's complement) for selected inputs
* Reference:   Section 3.4, Fig. 3 of the paper
*=============================================================================

.include 'ptm_45nm.lib'
.include 'twos_complement_4b.sp'

* ── Power Supply ──
.param VDD_VAL = 1.0
VDD vdd 0 DC VDD_VAL
VGND gnd 0 DC 0

* ── DUT ──
XDUT A0 A1 A2 A3 OUT0 OUT1 OUT2 OUT3 vdd gnd TWOS_COMP_4B

* ── Load Capacitances ──
CL0 OUT0 0 2f
CL1 OUT1 0 2f
CL2 OUT2 0 2f
CL3 OUT3 0 2f

* ══════════════════════════════════════════════════════════════════════════
*  Input Stimulus — test 5 key values
*  Each held for 4ns (sufficient for ripple settle through 4 stages)
*
*  Time(ns)  A[3:0]  |  Expected OUT[3:0] = ~A+1
*  0-4       0101=5  |  1011 = 11 (-5 in 4-bit 2's complement)
*  4-8       0011=3  |  1101 = 13 (-3)
*  8-12      1000=8  |  1000 = 8  (-8)
*  12-16     0001=1  |  1111 = 15 (-1)
*  16-20     0000=0  |  0000 = 0  (edge case)
* ══════════════════════════════════════════════════════════════════════════

* A0 (LSB): 1,1,0,1,0
VA0 A0 0 PWL(
+ 0n VDD_VAL 3.9n VDD_VAL
+ 4n VDD_VAL  7.9n VDD_VAL
+ 8n 0        11.9n 0
+ 12n VDD_VAL 15.9n VDD_VAL
+ 16n 0       20n 0
+ )

* A1: 0,1,0,0,0
VA1 A1 0 PWL(
+ 0n 0        3.9n 0
+ 4n VDD_VAL  7.9n VDD_VAL
+ 8n 0        11.9n 0
+ 12n 0       15.9n 0
+ 16n 0       20n 0
+ )

* A2: 1,0,0,0,0
VA2 A2 0 PWL(
+ 0n VDD_VAL  3.9n VDD_VAL
+ 4n 0        7.9n 0
+ 8n 0        11.9n 0
+ 12n 0       15.9n 0
+ 16n 0       20n 0
+ )

* A3 (MSB): 0,0,1,0,0
VA3 A3 0 PWL(
+ 0n 0        3.9n 0
+ 4n 0        7.9n 0
+ 8n VDD_VAL  11.9n VDD_VAL
+ 12n 0       15.9n 0
+ 16n 0       20n 0
+ )

* ── Analysis ──
.tran 10p 22n

* ── Measurements ──
.meas tran tpd_comp TRIG v(A0) VAL='VDD_VAL/2' RISE=1
+                   TARG v(OUT0) VAL='VDD_VAL/2' FALL=1
.meas tran avg_power AVG POWER FROM=0n TO=20n

.control
run
plot v(A3)+10 v(A2)+8 v(A1)+6 v(A0)+4 v(OUT3)+2 v(OUT2) v(OUT1)-2 v(OUT0)-4
+ title "4-bit 2's Complement Generator — Transient Response"
write tb_twos_complement.raw
.endc

.end
