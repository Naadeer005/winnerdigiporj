param([string]$Quartus = '')
$ErrorActionPreference = 'Stop'
if (-not $Quartus) {
    $found = Get-Command quartus_sh -ErrorAction SilentlyContinue
    if ($found) { $Quartus = $found.Source }
    elseif (Test-Path 'C:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe') {
        $Quartus = 'C:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe'
    } else { throw 'Pass -Quartus with the full path to quartus_sh.exe.' }
}
Push-Location (Join-Path $PSScriptRoot '../quartus')
try {
    & $Quartus --flow compile dino_pop
    if ($LASTEXITCODE -ne 0) { throw "Quartus compile failed ($LASTEXITCODE)." }
} finally { Pop-Location }
