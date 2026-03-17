*=============================================================================
* File: cmos_xor2.sp
* Description: 12-Transistor CMOS 2-input XOR gate
*              Building block for remainder generator and complement logic
* Reference:   Identical topology to XOR1 stage in Full Adder (Section 3)
* Pin Order: A B Y VDD GND
*=============================================================================

.include 'ptm_45nm.lib'

.subckt INV_XOR IN OUT VDD GND
MP OUT IN VDD VDD pmos_45n w=240n l=45n
MN OUT IN GND GND nmos_45n w=120n l=45n
.ends INV_XOR

*=============================================================================
* SUBCIRCUIT: CMOS XOR2 (12T)
*=============================================================================
.subckt CMOS_XOR2 A B Y VDD GND

* Generate complements
XINV_A A A_BAR VDD GND INV_XOR
XINV_B B B_BAR VDD GND INV_XOR

* PMOS pull-up: two series paths in parallel
* Path A: VDD → MP1(A) → mid_pa → MP3(B_BAR) → Y
MP1 mid_pa A     VDD    VDD pmos_45n w=480n l=45n
MP3 Y      B_BAR mid_pa VDD pmos_45n w=480n l=45n

* Path B: VDD → MP2(B) → mid_pb → MP4(A_BAR) → Y
MP2 mid_pb B     VDD    VDD pmos_45n w=480n l=45n
MP4 Y      A_BAR mid_pb VDD pmos_45n w=480n l=45n

* NMOS pull-down: two series paths in parallel
* Path A: Y → MN1(A) → mid_na → MN3(B) → GND
MN1 Y      A     mid_na GND nmos_45n w=240n l=45n
MN3 mid_na B     GND    GND nmos_45n w=240n l=45n

* Path B: Y → MN2(B_BAR) → mid_nb → MN4(A_BAR) → GND
MN2 Y      B_BAR mid_nb GND nmos_45n w=240n l=45n
MN4 mid_nb A_BAR GND    GND nmos_45n w=240n l=45n

.ends CMOS_XOR2
