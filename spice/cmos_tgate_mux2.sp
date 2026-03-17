*=============================================================================
* File: cmos_tgate_mux2.sp
* Description: Transmission-Gate based 2:1 MUX — mode selection switch
*              Used in MCU for selecting add/sub/complement paths
* Reference:   Section 3.2, Fig. 5(b) of the paper
*              "Library: hybridVM_lib | Cell: tgate_mux2 | 6T | 45nm"
*
* Truth Table:
*   SEL=0 → OUT = IN0
*   SEL=1 → OUT = IN1
*
* Pin Order: IN0 IN1 SEL OUT VDD GND
*=============================================================================

.include 'ptm_45nm.lib'

* ── Inverter subcircuit ──
.subckt INV_MUX IN OUT VDD GND
MP OUT IN VDD VDD pmos_45n w=240n l=45n
MN OUT IN GND GND nmos_45n w=120n l=45n
.ends INV_MUX

*=============================================================================
* SUBCIRCUIT: Transmission-Gate 2:1 MUX
*=============================================================================
.subckt TGATE_MUX2 IN0 IN1 SEL OUT VDD GND

* Generate complement of select
XINV_S SEL SEL_BAR VDD GND INV_MUX

* ══════════════════════════════════════════════════════════════════════════
*  Transmission Gate 0 (passes IN0 when SEL=0)
*  PMOS: gate = SEL (ON when SEL=0)
*  NMOS: gate = SEL_BAR (ON when SEL_BAR=1, i.e., SEL=0)
* ══════════════════════════════════════════════════════════════════════════
MP_TG0 IN0 SEL     OUT VDD pmos_45n w=240n l=45n
MN_TG0 IN0 SEL_BAR OUT GND nmos_45n w=120n l=45n

* ══════════════════════════════════════════════════════════════════════════
*  Transmission Gate 1 (passes IN1 when SEL=1)
*  PMOS: gate = SEL_BAR (ON when SEL=1)
*  NMOS: gate = SEL (ON when SEL=1)
* ══════════════════════════════════════════════════════════════════════════
MP_TG1 IN1 SEL_BAR OUT VDD pmos_45n w=240n l=45n
MN_TG1 IN1 SEL     OUT GND nmos_45n w=120n l=45n

.ends TGATE_MUX2
