$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root 'codex-ime-enter-guard.pid'
$stopped = $false

if (Test-Path -LiteralPath $pidFile) {
    try {
        $existingPid = [int](Get-Content -LiteralPath $pidFile -Raw)
        $process = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $existingPid -Force
            Write-Host "Stopped Codex IME Enter Guard. PID=$existingPid"
            $stopped = $true
        }
    }
    finally {
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    }
}

if (-not $stopped) {
    $matches = Get-CimInstance Win32_Process |
        Where-Object { $_.CommandLine -like '*codex-ime-enter-guard.ps1*' }

    foreach ($match in $matches) {
        Stop-Process -Id $match.ProcessId -Force
        Write-Host "Stopped Codex IME Enter Guard. PID=$($match.ProcessId)"
        $stopped = $true
    }
}

if (-not $stopped) {
    Write-Host 'Codex IME Enter Guard was not running.'
}
