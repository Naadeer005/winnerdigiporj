# Verification record — 11 October 2026

## Confirmed results

**GHDL 6.0.0, mcode backend:** all four benches pass. Full transcript is retained
in [evidence/regression.log](evidence/regression.log).

- `tb_controls`: power-on reset; rejection of short bounce; one rising-edge event
  per switch activation; no held-fire repeat; left/right hold repeat and release;
  reset assertion/release. Debounce/repeat constants are shortened in simulation.
- `tb_engine`: title/start/reset/restart; aim bounds and opposing keys; ignored
  busy input; movement gated by frame tick; both wall reflections; ceiling and
  occupied-cell attachment; row-major tie break; blocked attachment loss; two-egg
  non-match; staggered-row match; disconnected falling eggs and support retention;
  extinct colour filtering; score accumulation/saturation; full 120-cell flood
  fill; fifth-shot ceiling progression; all-clear precedence; danger-line loss;
  complete shots at all 17 launch directions; symmetric bounded neighbour graph.
- `tb_vga`: 420,000 pixels over a complete frame; 800 × 525 coordinate sequence;
  96-pixel horizontal and two-line vertical active-low sync; 307,200 visible
  pixels; black RGB during blanking; one frame tick at (0,480); frame wrap.
- `tb_render`: title, gameplay, win and lose PPM captures from the actual VHDL
  renderer. The PNGs are format conversions, not alternate UI mockups. Screens
  were visually inspected for readability, clipping, egg alignment and overlays.

GHDL's synthesis backend also accepts the complete `dino_pop` top level. The
only expected attribute warning concerns Quartus's vendor-specific synchronizer
annotation. GHDL synthesis is **not evidence of MAX 10 fitting or timing closure**.

Reproduce in PowerShell:

```powershell
./scripts/test.ps1 -Ghdl ./build/tools/mcode/bin/ghdl.exe
./build/tools/mcode/bin/ghdl.exe --synth --std=08 --workdir=build/mcode dino_pop > build/synth.vhd
python scripts/render_previews.py
python scripts/waveform.py
```

The portable tool path is local to this workspace's ignored build directory.
Another machine can use any GHDL 6.0.0 installation as described in the README.

## Waveform evidence

The test script writes `build/engine.vcd` and `build/controls.vcd`. Open them in
GTKWave. The report's SVG is generated from the engine VCD, covering 50.5–170 us:
matching, clearing, support scan, falling animation, scoring and return to AIM.
Gzip-compressed copies of both passing-run VCD files are included under
`docs/evidence/`; decompress them to inspect the saved waveforms without rerunning.

The VCD includes scalar `state_code` because enumeration and array support in
VCD is limited. Board contents and neighbour outcomes are checked by assertions;
the scalar outputs provide the visible state/score/projectile evidence.
The engine bench uses shortened synthetic frame intervals; real frame timing is
verified separately by `tb_vga` at 50 MHz. Fixture loading is not a physical input.

## Quartus blocker

The complete source and the QPF/QSF/SDC project were passed to installed
**Quartus Prime Lite 25.1std.0 Build 1129**. The tool recognized the VHDL units,
but cannot finish elaboration because its installed helper is blocked:

```text
Error (112002): Cannot start the command line
  c:/altera_lite/25.1std/quartus//sopc_builder/bin/ip-catalog.exe
Error (12153): Can't elaborate top-level user hierarchy
```

Direct helper invocation confirms **“An Application Control policy has blocked
this file.”** Running the compile outside the tool sandbox does not resolve the
Windows policy block. The relevant build transcript is
[evidence/quartus-blocked.log](evidence/quartus-blocked.log).

No `.sof` file, fitter utilization, post-fit timing result or programming claim
is provided. Use an administrator-approved repair or a working trusted Quartus
installation; rerun `scripts/build.ps1` and resolve any actual synthesis/fitting
or timing errors before programming. No security protections were disabled.

## Required hardware acceptance — not yet performed

1. Run a full Quartus compile for 10M50DAF484C7G. Save compiler summary, fitter
   utilization and TimeQuest reports; verify setup/hold at 50 MHz and inspect
   unconstrained paths and all warnings. Confirm every port's physical pin.
2. Program the generated `.sof` through USB-Blaster JTAG and connect a VGA monitor.
   Record monitor model and confirm stable 640 × 480 output at about 60 Hz.
3. Demonstrate title/start, held aim buttons, both wall bounces, fire toggle,
   matching, disconnected drops, the fifth-shot descent, win/loss and restart.
4. Hold SW0 high across a shot: no extra shot should launch. Toggle it while busy:
   the event must not be queued. Restart during flight/fall; reset in each screen.
5. Photograph the actual board and monitor, plus gameplay and end screens. Place
   photographs in a separate `docs/hardware/` folder and label them as hardware.
6. Record actual results and both students' names/contributions in the report.
   Both students explain the whole circuit at the scheduled demonstration.

The project is ready for these remaining checks, but the course's hardware
acceptance criteria are not yet satisfied.
