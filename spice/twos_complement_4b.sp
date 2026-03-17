*=============================================================================
* File: twos_complement_4b.sp
* Description: 4-bit 2's Complement Generator — transistor-level
*              XOR-based inversion + ripple carry increment (Cin=1)
*              Core of complement-based remainder computation
* Reference:   Section 3.4, Fig. 3 of the paper
*              "Library: hybridVM_lib | Cell: twos_complement_4b | 32T | 45nm"
*
* Operation:  OUT[3:0] = ~A[3:0] + 1  (bit inversion + increment)
*             Equivalent to: OUT = -A (in 2's complement)
*             Used in remainder extraction: Xr = 2^(N-1) - X
*
* Architecture:
*   Each bit stage: XOR(A[i], 1) = NOT(A[i]) for inversion
*   Half-adder chain for +1 increment with ripple carry
*
* Pin Order: A0 A1 A2 A3 OUT0 OUT1 OUT2 OUT3 VDD GND
*=============================================================================

.include 'ptm_45nm.lib'
.include 'cmos_xor2.sp'

* ── Half Adder subcircuit (XOR + AND) ──
.subckt HALF_ADDER A B SUM COUT VDD GND

* SUM = A XOR B
XXOR A B SUM VDD GND CMOS_XOR2

* COUT = A AND B (CMOS NAND + INV)
* NAND gate
MP_NAND1 NAND_OUT A VDD     VDD pmos_45n w=240n l=45n
MP_NAND2 NAND_OUT B VDD     VDD pmos_45n w=240n l=45n
MN_NAND1 NAND_OUT A net_and GND nmos_45n w=240n l=45n
MN_NAND2 net_and  B GND     GND nmos_45n w=240n l=45n

* INV to get AND from NAND
MP_INV COUT NAND_OUT VDD VDD pmos_45n w=240n l=45n
MN_INV COUT NAND_OUT GND GND nmos_45n w=120n l=45n

.ends HALF_ADDER

*=============================================================================
* SUBCIRCUIT: 4-bit 2's Complement Generator
*=============================================================================
.subckt TWOS_COMP_4B A0 A1 A2 A3 OUT0 OUT1 OUT2 OUT3 VDD GND

* ── Step 1: Bit Inversion (XOR with '1') ──
* Tying one XOR input to VDD (logic '1') creates an inverter
* INV_A[i] = A[i] XOR 1 = NOT(A[i])

* Inverters for each bit
MP_INV0 INV_A0 A0 VDD VDD pmos_45n w=240n l=45n
MN_INV0 INV_A0 A0 GND GND nmos_45n w=120n l=45n

MP_INV1 INV_A1 A1 VDD VDD pmos_45n w=240n l=45n
MN_INV1 INV_A1 A1 GND GND nmos_45n w=120n l=45n

MP_INV2 INV_A2 A2 VDD VDD pmos_45n w=240n l=45n
MN_INV2 INV_A2 A2 GND GND nmos_45n w=120n l=45n

MP_INV3 INV_A3 A3 VDD VDD pmos_45n w=240n l=45n
MN_INV3 INV_A3 A3 GND GND nmos_45n w=120n l=45n

* ── Step 2: Ripple Increment (+1) using half-adder chain ──
* Carry-in = 1 (VDD) for the +1 increment
* Stage 0: OUT0 = INV_A0 XOR 1,  C0 = INV_A0 AND 1 = INV_A0
XHA0 INV_A0 VDD OUT0 C0 VDD GND HALF_ADDER

* Stage 1: OUT1 = INV_A1 XOR C0,  C1 = INV_A1 AND C0
XHA1 INV_A1 C0 OUT1 C1 VDD GND HALF_ADDER

* Stage 2: OUT2 = INV_A2 XOR C1,  C2 = INV_A2 AND C1
XHA2 INV_A2 C1 OUT2 C2 VDD GND HALF_ADDER

* Stage 3: OUT3 = INV_A3 XOR C2  (carry-out not needed for 4-bit)
XHA3 INV_A3 C2 OUT3 C3_UNUSED VDD GND HALF_ADDER

.ends TWOS_COMP_4B
