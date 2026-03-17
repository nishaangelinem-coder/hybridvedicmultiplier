*=============================================================================
* File: tb_mode_control.sp
* Description: Testbench for Mode Control Unit
*              Verifies all 4 mode encodings from MSB combinations
* Reference:   Section 3.2, Table 2, Fig. 2 of the paper
*=============================================================================

.include 'ptm_45nm.lib'
.include 'mode_control_unit.sp'

* ── Power Supply ──
.param VDD_VAL = 1.0
VDD vdd 0 DC VDD_VAL
VGND gnd 0 DC 0

* ── DUT ──
XMCU MSB_X MSB_Y M0 M1 SIGMA_X SIGMA_Y vdd gnd MODE_CONTROL

* ── Load ──
CL_M0 M0 0 2f
CL_M1 M1 0 2f
CL_SX SIGMA_X 0 2f
CL_SY SIGMA_Y 0 2f

* ══════════════════════════════════════════════════════════════════════════
*  Input Stimulus — cycle through all 4 MSB combinations
*
*  Time(ns)  MSB_X  MSB_Y  |  Mode  M1 M0  σx  σy
*  0-3        1      1     |  I     0  0    1   1
*  3-6        1      0     |  II    0  1    1   0
*  6-9        0      1     |  III   1  0    0   1
*  9-12       0      0     |  IV    1  1    0   0
* ══════════════════════════════════════════════════════════════════════════

V_MSB_X MSB_X 0 PWL(
+ 0n VDD_VAL  2.9n VDD_VAL
+ 3n VDD_VAL  5.9n VDD_VAL
+ 6n 0        8.9n 0
+ 9n 0        12n 0
+ )

V_MSB_Y MSB_Y 0 PWL(
+ 0n VDD_VAL  2.9n VDD_VAL
+ 3n 0        5.9n 0
+ 6n VDD_VAL  8.9n VDD_VAL
+ 9n 0        12n 0
+ )

* ── Analysis ──
.tran 10p 14n

* ── Measurements ──
.meas tran tpd_mode TRIG v(MSB_X) VAL='VDD_VAL/2' FALL=1
+                   TARG v(M1) VAL='VDD_VAL/2' RISE=1
.meas tran avg_power AVG POWER FROM=0n TO=12n

.control
run
plot v(MSB_X)+8 v(MSB_Y)+6 v(M1)+4 v(M0)+2 v(SIGMA_X) v(SIGMA_Y)-2
+ title 'Mode Control Unit — 4-Mode Classification'
write tb_mode_control.raw
.endc

.end
