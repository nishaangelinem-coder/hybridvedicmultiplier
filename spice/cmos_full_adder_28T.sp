*=============================================================================
* File: cmos_full_adder_28T.sp
* Description: 28-Transistor CMOS Full Adder — core cell of all multipliers
*              Matches the CORRECTED transistor-level schematic (Section 3)
* Reference:   Section 3, Fig. 5 of paper
*              "Library: hybridVM_lib | Cell: cmos_full_adder | 28T | 45nm"
*
* Architecture:
*   Stage 1 — XOR1: A ⊕ B = P  (propagate)          [12T: MP1-MP4, MN1-MN4]
*   Stage 2 — XOR2: P ⊕ Cin = SUM                    [12T: MP5-MP8, MN5-MN8]
*   Stage 3 — CARRY: Cout = A·B + Cin·P              [12T: MP9-MP12, MN9-MN12]
*              Total: 28 unique transistors + 4 shared inverter transistors
*
* Pin Order: A B CIN SUM COUT VDD GND
*=============================================================================

.include 'ptm_45nm.lib'

* ── Inverter for complement signals ──
.subckt INV IN OUT VDD GND
MP_inv OUT IN VDD VDD pmos_45n w=240n l=45n
MN_inv OUT IN GND GND nmos_45n w=120n l=45n
.ends INV

*=============================================================================
* SUBCIRCUIT: 28T CMOS Full Adder
*=============================================================================
.subckt CMOS_FA A B CIN SUM COUT VDD GND

* ── Generate complement signals ──
XINV_A  A   A_BAR   VDD GND  INV
XINV_B  B   B_BAR   VDD GND  INV
XINV_C  CIN CIN_BAR VDD GND  INV

* ══════════════════════════════════════════════════════════════════════════
*  STAGE 1: XOR1  —  P = A ⊕ B
*
*  PMOS pull-up (two series paths in parallel):
*    Path A:  VDD → MP1(gate=A)  → net_pa → MP3(gate=B_BAR) → P
*    Path B:  VDD → MP2(gate=B)  → net_pb → MP4(gate=A_BAR) → P
*
*  NMOS pull-down (two series paths in parallel):
*    Path A:  P → MN1(gate=A) → net_na → MN3(gate=B) → GND
*    Path B:  P → MN2(gate=B_BAR) → net_nb → MN4(gate=A_BAR) → GND
* ══════════════════════════════════════════════════════════════════════════

* PMOS Path A: VDD → MP1 → net_pa → MP3 → P
MP1 net_pa A     VDD    VDD pmos_45n w=480n l=45n
MP3 P      B_BAR net_pa VDD pmos_45n w=480n l=45n

* PMOS Path B: VDD → MP2 → net_pb → MP4 → P
MP2 net_pb B     VDD    VDD pmos_45n w=480n l=45n
MP4 P      A_BAR net_pb VDD pmos_45n w=480n l=45n

* NMOS Path A: P → MN1 → net_na → MN3 → GND
MN1 P      A     net_na GND nmos_45n w=240n l=45n
MN3 net_na B     GND    GND nmos_45n w=240n l=45n

* NMOS Path B: P → MN2 → net_nb → MN4 → GND
MN2 P      B_BAR net_nb GND nmos_45n w=240n l=45n
MN4 net_nb A_BAR GND    GND nmos_45n w=240n l=45n

* ── Generate P complement for Stage 2 and Stage 3 ──
XINV_P  P  P_BAR  VDD GND  INV

* ══════════════════════════════════════════════════════════════════════════
*  STAGE 2: XOR2  —  SUM = P ⊕ Cin
*
*  Same topology as XOR1, inputs P and Cin
* ══════════════════════════════════════════════════════════════════════════

* PMOS Path A: VDD → MP5 → net_pc → MP7 → SUM
MP5 net_pc P       VDD    VDD pmos_45n w=480n l=45n
MP7 SUM    CIN_BAR net_pc VDD pmos_45n w=480n l=45n

* PMOS Path B: VDD → MP6 → net_pd → MP8 → SUM
MP6 net_pd CIN     VDD    VDD pmos_45n w=480n l=45n
MP8 SUM    P_BAR   net_pd VDD pmos_45n w=480n l=45n

* NMOS Path A: SUM → MN5 → net_nc → MN7 → GND
MN5 SUM    P       net_nc GND nmos_45n w=240n l=45n
MN7 net_nc CIN     GND    GND nmos_45n w=240n l=45n

* NMOS Path B: SUM → MN6 → net_nd → MN8 → GND
MN6 SUM    CIN_BAR net_nd GND nmos_45n w=240n l=45n
MN8 net_nd P_BAR   GND    GND nmos_45n w=240n l=45n

* ══════════════════════════════════════════════════════════════════════════
*  STAGE 3: CARRY  —  Cout = A·B + Cin·P
*
*  PMOS pull-up for Cout_bar = (A_BAR + B_BAR) · (P_BAR + CIN_BAR):
*    Top group (parallel):    MP9(A_BAR) ‖ MP10(B_BAR)     → net_carry_mid
*    Bottom group (parallel): MP11(P_BAR) ‖ MP12(CIN_BAR)  → COUT_BAR
*    Two groups in SERIES via net_carry_mid
*
*  NMOS pull-down for Cout = A·B + Cin·P:
*    Path A (series):  COUT_BAR → MN9(A) → net_ne → MN10(B) → GND
*    Path B (series):  COUT_BAR → MN11(CIN) → net_nf → MN12(P) → GND
*    Paths A and B in PARALLEL
* ══════════════════════════════════════════════════════════════════════════

* PMOS Top parallel pair: VDD → MP9(A_BAR) → net_carry_mid, VDD → MP10(B_BAR) → net_carry_mid
MP9  net_carry_mid A_BAR   VDD           VDD pmos_45n w=360n l=45n
MP10 net_carry_mid B_BAR   VDD           VDD pmos_45n w=360n l=45n

* PMOS Bottom parallel pair: net_carry_mid → MP11(P_BAR) → COUT_BAR, ... → MP12(CIN_BAR) → COUT_BAR
MP11 COUT_BAR     P_BAR   net_carry_mid VDD pmos_45n w=360n l=45n
MP12 COUT_BAR     CIN_BAR net_carry_mid VDD pmos_45n w=360n l=45n

* NMOS Path A (series): COUT_BAR → MN9(A) → net_ne → MN10(B) → GND
MN9  COUT_BAR A     net_ne GND nmos_45n w=180n l=45n
MN10 net_ne   B     GND    GND nmos_45n w=180n l=45n

* NMOS Path B (series): COUT_BAR → MN11(Cin) → net_nf → MN12(P) → GND
MN11 COUT_BAR CIN   net_nf GND nmos_45n w=180n l=45n
MN12 net_nf   P     GND    GND nmos_45n w=180n l=45n

* Output inverter: COUT_BAR → COUT (restoring logic)
XINV_COUT COUT_BAR COUT VDD GND INV

.ends CMOS_FA
