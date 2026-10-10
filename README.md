# Dino Pop — DE10-Lite bubble shooter

A VHDL arcade mini-project: aim coloured eggs, bounce shots off the walls, clear
connected groups of three, and drop eggs that lose their connection to the ceiling.
The ceiling descends every five completed shots. Clear the board before an egg
reaches the dashed danger line.

![Gameplay captured from the actual VHDL renderer](docs/images/gameplay.png)

## Status

- GHDL 6.0.0: controls, game engine, VGA and renderer regressions pass.
- Complete shots tested at all 17 aiming angles; four VGA frames captured.
- GHDL synthesis of the complete top-level design passes.
- **Quartus fitting, timing closure, and a hardware demo are NOT verified.**
  Installed Quartus 25.1 Lite cannot launch `ip-catalog.exe`: Windows Application
  Control blocks that installed helper. No `.sof` has been produced. See
  `docs/verification.md` for the precise blocker and remaining acceptance checks.

## Play

1. Connect a VGA monitor and power the DE10-Lite. Start with switches down.
2. After a successful Quartus build, program `quartus/output_files/dino_pop.sof`
   using Quartus Programmer and the USB-Blaster JTAG cable.
3. Toggle **SW1 up** to start. To restart, toggle SW1 down and up again.
4. Hold **KEY0** to aim left or **KEY1** to aim right. Holding both cancels aiming.
5. Toggle **SW0 up** to fire; return it down before the next shot. Busy-state
   fire events are discarded, not queued.
6. **SW9 up** holds reset; switch it down to return to the title screen.

Pink, cyan, gold, and lavender eggs have distinct markings. Matching earns 10
points per egg; disconnected eggs earn 20. The next egg preview automatically
changes if its colour disappears from the board.

## Build

Open `quartus/dino_pop.qpf` in Quartus Prime Lite with MAX 10 device support and
run **Processing > Start Compilation**. The device is **10M50DAF484C7G**.
Alternatively, in PowerShell from the project root:

```powershell
./scripts/build.ps1 -Quartus 'C:\path\to\quartus\bin64\quartus_sh.exe'
```

The script also detects Quartus on PATH and the existing local 25.1 installation.
The project uses VHDL-2008, a single 50 MHz clock, clock enables, and no IP cores,
external RAM, PLL, processor, or external controller. Physical pins are documented
in `docs/pin_sources.md`. Do not add VGA_CLK/BLANK/SYNC_N ports: this board has
RGB resistor DACs plus HS/VS.

## Simulate

Install GHDL 6.0.0 from its [official releases](https://github.com/ghdl/ghdl/releases/tag/v6.0.0)
and put its `bin` directory on PATH. Both LLVM and mcode backends are supported:

```powershell
./scripts/test.ps1
# Or explicitly choose a portable mcode installation:
./scripts/test.ps1 -Ghdl 'C:\path\to\ghdl\bin\ghdl.exe'
python scripts/render_previews.py
python scripts/waveform.py
```

On this machine the official portable mcode tool is available under
`build/tools/mcode/bin/ghdl.exe` (ignored build dependency, not part of the source
distribution). Some Windows Application Control configurations block generated
LLVM test executables; mcode runs the tests inside GHDL. Do not disable security
settings to run these tools.

The tests fail on any assertion. Outputs include `build/engine.vcd`,
`build/controls.vcd`, and four PPM frame captures. Python conversion scripts use
only the standard library. Open VCDs in GTKWave; `state_code` maps to the state
numbers in `docs/state_table.csv`. Fixture ports are enabled only by the testbench
generic; the top-level hardware has no fixture/debug input ports.

## Submission material

- `rtl/`: synthesizable game, controls, VGA, font and original dinosaur sprite ROM.
- `quartus/`: project, device pin assignments and 50 MHz timing constraints.
- `sim/`: assertion-based tests and renderer capture bench.
- `docs/report.md`: design report, state diagram, specifications and team roles.
- `docs/state_table.csv`: complete state table, including global transitions.
- `docs/verification.md`: measured test results and pending hardware checklist.
- `docs/images/`: simulated VGA screenshots and waveform illustration.

Run `python scripts/package.py` to create `build/dino-pop-source.zip`, excluding
compiler databases, downloaded tool binaries and other temporary files.

Add both students' names, actual development contributions, the successful
Quartus compile/timing reports, and real board/monitor photographs before handing
in. Simulated screenshots are explicitly labelled and are not hardware evidence.
