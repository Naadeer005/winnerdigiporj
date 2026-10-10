# Board verification and constraints

Pin assignments were checked against **Terasic, DE10-Lite User Manual, June 5,
2020**, the manufacturer-authored manual hosted by TI:

[Manual PDF](https://e2e.ti.com/cfs-file/__key/communityserver-discussions-components-files/73/DE10_2D00_Lite_5F00_User_5F00_Manual.pdf)

Reference tables: 3-2 (clock), 3-3 (buttons), 3-4 (switches), 3-11 (VGA).
The manufacturer's [download page](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021&PartNo=4)
also provides board resources. The course assignment is
[Mini Project: FSM + VGA](https://pruks-dev.github.io/digital-lab/mini-project/).

Machine-readable assignments are in `quartus/dino_pop.qsf`:

- 50 MHz: P11. Buttons KEY0/KEY1: B8/A7, active-low.
- SW0 through SW9: C10, C11, D12, C12, A12, B12, A13, A14, B14, F15.
- VGA red bits 0–3: AA1, V1, Y2, Y1.
- VGA green bits 0–3: W1, T2, R2, R1.
- VGA blue bits 0–3: P1, T1, P4, N2.
- HS: N3; VS: N1.

Use the board's 3.3 V I/O standards; buttons use the Schmitt-trigger standard
listed in the manual. DE10-Lite's VGA output uses a passive resistor DAC and does
not expose VGA_CLK, VGA_BLANK_N or VGA_SYNC_N FPGA signals. The course page's
generic signal list should not be copied into this board's pin constraints.

The SDC defines a 20 ns clock, automatic clock uncertainty, asynchronous cuts
only to the first input synchronizer stage, and explicit output delay bounds.
No game, synchronizer-stage-to-stage, or renderer path is false-pathed.
The VGA monitor is an analogue receiver; the 5 ns register-to-pad output budget
is a conservative design bound rather than a monitor-specified digital setup
time. A fitter/TimeQuest run is still required to verify all these constraints.
