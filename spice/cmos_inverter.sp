*=============================================================================
* File: cmos_inverter.sp
* Description: CMOS Inverter — fundamental gate for all multiplier sub-blocks
* Technology: 45nm CMOS (PTM)
*=============================================================================

.subckt CMOS_INV IN OUT VDD GND
+ wp=240n wn=120n lp=45n ln=45n

* PMOS: Source=VDD, Gate=IN, Drain=OUT
MP1 OUT IN VDD VDD pmos_45n w=wp l=lp

* NMOS: Source=GND, Gate=IN, Drain=OUT
MN1 OUT IN GND GND nmos_45n w=wn l=ln

.ends CMOS_INV
