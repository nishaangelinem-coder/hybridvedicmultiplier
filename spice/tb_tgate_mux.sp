*=============================================================================
* File: tb_tgate_mux.sp
* Description: Testbench for CMOS Transmission-Gate 2:1 MUX
*              Verifies both select states and measures delay/power
* Reference:   Section 3.2 of the paper
*=============================================================================

.include 'ptm_45nm.lib'
.include 'cmos_tgate_mux2.sp'

* ── Power Supply ──
.param VDD_VAL = 1.0
VDD vdd 0 DC VDD_VAL
VGND gnd 0 DC 0

* ── DUT ──
XMUX IN0 IN1 SEL OUT vdd gnd TGATE_MUX2

* ── Load ──
CL_OUT OUT 0 5f

* ══════════════════════════════════════════════════════════════════════════
*  Input Stimulus
*  SEL toggles at 5ns: first half selects IN0, second half selects IN1
*  IN0 = 500MHz square wave  (period 2ns)
*  IN1 = 250MHz square wave  (period 4ns)
* ══════════════════════════════════════════════════════════════════════════

* SEL: 0 for 0-5ns, 1 for 5-10ns
VSEL SEL 0 PWL(0n 0  4.9n 0  5.0n VDD_VAL  10n VDD_VAL)

* IN0: toggles every 1ns
VIN0 IN0 0 PULSE(0 VDD_VAL 0.5n 50p 50p 0.95n 2n)

* IN1: toggles every 2ns
VIN1 IN1 0 PULSE(0 VDD_VAL 0.5n 50p 50p 1.95n 4n)

* ── Analysis ──
.tran 10p 12n

* ── Measurements ──
.meas tran tpd_mux_rise TRIG v(SEL) VAL='VDD_VAL/2' RISE=1
+                       TARG v(OUT) VAL='VDD_VAL/2' RISE=1
.meas tran avg_power AVG POWER FROM=0n TO=10n

.control
run
plot v(SEL)+4 v(IN0)+2 v(IN1) v(OUT)-2
+ title 'TGATE MUX 2:1 — SEL=0 passes IN0, SEL=1 passes IN1'
write tb_tgate_mux.raw
.endc

.end
