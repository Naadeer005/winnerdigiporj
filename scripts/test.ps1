param([string]$Ghdl = 'ghdl')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $root
try {
    $tool = (Get-Command $Ghdl).Source
    $env:PATH = (Split-Path $tool) + ';' + $env:PATH
    New-Item -ItemType Directory -Force build | Out-Null
    $isMcode = ((& $tool --version) -join ' ') -match 'mcode'
    $work = if ($isMcode) { 'build/mcode' } else { 'build/llvm' }
    New-Item -ItemType Directory -Force $work | Out-Null
    $sources = @('rtl/game_pkg.vhd','rtl/graphics_pkg.vhd','rtl/controls.vhd','rtl/vga_timing.vhd',
        'rtl/game_engine.vhd','rtl/renderer.vhd','rtl/dino_pop.vhd',
        'sim/tb_engine.vhd','sim/tb_controls.vhd','sim/tb_vga.vhd','sim/tb_render.vhd')
    & $tool -a --std=08 "--workdir=$work" @sources
    if ($LASTEXITCODE -ne 0) { throw 'VHDL analysis failed.' }
    foreach ($test in @('tb_controls','tb_engine','tb_vga','tb_render')) {
        $runArgs = @('--assert-level=error')
        if ($test -eq 'tb_engine') { $runArgs += '--vcd=build/engine.vcd' }
        if ($test -eq 'tb_controls') { $runArgs += '--vcd=build/controls.vcd' }
        if ($isMcode) {
            & $tool -r --std=08 "--workdir=$work" $test @runArgs
        } else {
            & $tool -e --std=08 "--workdir=$work" -o "build/$test.exe" $test
            if ($LASTEXITCODE -ne 0) { throw "Elaboration failed: $test" }
            & "./build/$test.exe" @runArgs
        }
        if ($LASTEXITCODE -ne 0) { throw "Test failed: $test" }
    }
} finally { Pop-Location }
