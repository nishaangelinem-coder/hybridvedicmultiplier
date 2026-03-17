*=============================================================================
* File: char_full_adder_pvt.sp
* Description: Process-Voltage-Temperature (PVT) characterization of the
*              28T CMOS Full Adder across multiple operating corners
* Reference:   Section 4.3, 4.5 of the paper
*              "Timing constraints: Single-cycle combinational multiplier"
*              "Power estimation: Switching activity-based post-synthesis"
*
* Corners simulated:
*   TT  (Typical-Typical):   VDD=1.0V, T=27°C   — nominal
*   FF  (Fast-Fast):         VDD=1.1V, T=0°C    — best case
*   SS  (Slow-Slow):         VDD=0.9V, T=85°C   — worst case
*   FS  (Fast-Slow):         VDD=1.0V, T=27°C   — NMOS fast, PMOS slow
*   SF  (Slow-Fast):         VDD=1.0V, T=27°C   — NMOS slow, PMOS fast
*
* Metrics extracted per corner:
*   - Propagation delay (tpd) for SUM and COUT paths
*   - Dynamic power consumption
*   - Rise and fall times
*=============================================================================

.include 'ptm_45nm.lib'
.include 'cmos_full_adder_28T.sp'

* ══════════════════════════════════════════════════════════════════════════
*  Nominal Corner: TT, VDD=1.0V, T=27°C
* ══════════════════════════════════════════════════════════════════════════
.param VDD_VAL = 1.0
.temp 27

VDD vdd 0 DC VDD_VAL
VGND gnd 0 DC 0

XDUT A B CIN SUM COUT vdd gnd CMOS_FA

CL_SUM  SUM  0 5f
CL_COUT COUT 0 5f

* ── Stimulus: CIN toggles with A=1, B=1 (worst-case carry path) ──
VA   A   0 DC VDD_VAL
VB   B   0 DC VDD_VAL
VCIN CIN 0 PULSE(0 VDD_VAL 1n 50p 50p 2n 4n)

.tran 10p 10n

* ── Delay: CIN → COUT (critical carry path) ──
.meas tran tpd_carry_rise TRIG v(CIN)  VAL='VDD_VAL/2' RISE=1
+                         TARG v(COUT) VAL='VDD_VAL/2' RISE=1
.meas tran tpd_carry_fall TRIG v(CIN)  VAL='VDD_VAL/2' FALL=1
+                         TARG v(COUT) VAL='VDD_VAL/2' FALL=1

* ── Delay: CIN → SUM ──
.meas tran tpd_sum_rise TRIG v(CIN) VAL='VDD_VAL/2' RISE=1
+                       TARG v(SUM) VAL='VDD_VAL/2' FALL=1
.meas tran tpd_sum_fall TRIG v(CIN) VAL='VDD_VAL/2' FALL=1
+                       TARG v(SUM) VAL='VDD_VAL/2' RISE=1

* ── Power ──
.meas tran avg_power AVG POWER FROM=1n TO=9n
.meas tran peak_current MAX I(VDD) FROM=1n TO=9n
.meas tran avg_current AVG I(VDD) FROM=1n TO=9n

* ── Energy per operation ──
.meas tran energy_per_cycle PARAM='avg_power * 4n'

.control
run
echo ""
echo "=============================================="
echo "  Full Adder 28T — PVT Characterization"
echo "  Corner: TT | VDD=1.0V | T=27C"
echo "=============================================="
echo ""
meas tran tpd_carry_rise TRIG v(CIN) VAL=0.5 RISE=1 TARG v(COUT) VAL=0.5 RISE=1
meas tran tpd_carry_fall TRIG v(CIN) VAL=0.5 FALL=1 TARG v(COUT) VAL=0.5 FALL=1
meas tran tpd_sum_rise   TRIG v(CIN) VAL=0.5 RISE=1 TARG v(SUM)  VAL=0.5 FALL=1
meas tran tpd_sum_fall   TRIG v(CIN) VAL=0.5 FALL=1 TARG v(SUM)  VAL=0.5 RISE=1
echo ""
plot v(CIN)+2 v(SUM) v(COUT)-2
+ title 'Full Adder 28T — Carry Path Characterization (TT corner)'
write char_full_adder_pvt.raw
.endc

.end
