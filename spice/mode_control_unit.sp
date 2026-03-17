*=============================================================================
* File: mode_control_unit.sp
* Description: 2-bit Mode Control Unit using MSB comparison logic
*              Classifies operand pairs into 4 modes via AND/INV gates
* Reference:   Section 3.2, Table 2, Fig. 2 of the paper
*
* Inputs:  MSB_X, MSB_Y (single-bit MSBs of operands)
* Outputs: M0, M1 (mode encoding), SIGMA_X, SIGMA_Y (polarity)
*
* Mode encoding:
*   M1=0, M0=0 → Mode I   (X≥B, Y≥B)  →  σx=+1, σy=+1
*   M1=0, M0=1 → Mode II  (X≥B, Y<B)  →  σx=+1, σy=-1
*   M1=1, M0=0 → Mode III (X<B, Y≥B)  →  σx=-1, σy=+1
*   M1=1, M0=1 → Mode IV  (X<B, Y<B)  →  σx=-1, σy=-1
*
* Pin Order: MSB_X MSB_Y M0 M1 SIGMA_X SIGMA_Y VDD GND
*=============================================================================

.include 'ptm_45nm.lib'

*=============================================================================
* SUBCIRCUIT: Mode Control Unit
*=============================================================================
.subckt MODE_CONTROL MSB_X MSB_Y M0 M1 SIGMA_X SIGMA_Y VDD GND

* ── Polarity signals ──
* σx = MSB_X directly (1 when X ≥ 2^(N-1), 0 otherwise)
* σy = MSB_Y directly
* Buffer for driving:
MP_BUF_SX SIGMA_X_BAR MSB_X VDD VDD pmos_45n w=240n l=45n
MN_BUF_SX SIGMA_X_BAR MSB_X GND GND nmos_45n w=120n l=45n
MP_BUF_SX2 SIGMA_X SIGMA_X_BAR VDD VDD pmos_45n w=240n l=45n
MN_BUF_SX2 SIGMA_X SIGMA_X_BAR GND GND nmos_45n w=120n l=45n

MP_BUF_SY SIGMA_Y_BAR MSB_Y VDD VDD pmos_45n w=240n l=45n
MN_BUF_SY SIGMA_Y_BAR MSB_Y GND GND nmos_45n w=120n l=45n
MP_BUF_SY2 SIGMA_Y SIGMA_Y_BAR VDD VDD pmos_45n w=240n l=45n
MN_BUF_SY2 SIGMA_Y SIGMA_Y_BAR GND GND nmos_45n w=120n l=45n

* ── Mode bits ──
* M1 = NOT(MSB_X) — inverted MSB of X
* M0 = NOT(MSB_Y) — inverted MSB of Y
* This gives: {M1,M0} = {~MSB_X, ~MSB_Y}

* M1 = INV(MSB_X) — already have SIGMA_X_BAR
MP_M1 M1 SIGMA_X_BAR VDD VDD pmos_45n w=240n l=45n
MN_M1 M1 SIGMA_X_BAR GND GND nmos_45n w=120n l=45n

* M0 = INV(MSB_Y) — already have SIGMA_Y_BAR
MP_M0 M0 SIGMA_Y_BAR VDD VDD pmos_45n w=240n l=45n
MN_M0 M0 SIGMA_Y_BAR GND GND nmos_45n w=120n l=45n

.ends MODE_CONTROL
