param(
    [ValidateSet('composition', 'plain', 'all')]
    [string]$Mode = 'composition',

    [switch]$VerboseGuard
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$guard = Join-Path $root 'codex-ime-enter-guard.ps1'
$pidFile = Join-Path $root 'codex-ime-enter-guard.pid'

if (Test-Path -LiteralPath $pidFile) {
    try {
        $existingPid = [int](Get-Content -LiteralPath $pidFile -Raw)
        if (Get-Process -Id $existingPid -ErrorAction SilentlyContinue) {
            Write-Host "Codex IME Enter Guard is already running. PID=$existingPid"
            return
        }
    }
    catch {
    }
}

$argumentList = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Mode {1} -PidFile "{2}"' -f $guard, $Mode, $pidFile
if ($VerboseGuard) {
    $argumentList += ' -VerboseGuard'
}

$process = Start-Process -FilePath 'powershell.exe' -ArgumentList $argumentList -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 700

if (Test-Path -LiteralPath $pidFile) {
    $runningPid = Get-Content -LiteralPath $pidFile -Raw
    Write-Host "Codex IME Enter Guard started. PID=$runningPid Mode=$Mode"
}
elseif (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
    Write-Host "Codex IME Enter Guard process started. PID=$($process.Id) Mode=$Mode"
}
else {
    throw 'Codex IME Enter Guard did not stay running.'
}
