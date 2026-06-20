$ErrorActionPreference = 'Stop'

# Determine if we are on Windows safely for PowerShell 5.1 and Core
$isWindowsSystem = $false
if ($null -ne $IsWindows) {
    $isWindowsSystem = $IsWindows
} elseif ($PSVersionTable.PSEdition -eq 'Desktop') {
    $isWindowsSystem = $true
} else {
    try {
        $isWindowsSystem = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
    } catch {
        # Fallback if RuntimeInformation is missing
        $isWindowsSystem = ($env:OS -like '*Windows*')
    }
}

if (-not $isWindowsSystem) {
    Write-Host "Skipping tests: not running on Windows."
    exit 0
}

$root = $PSScriptRoot
if (-not $root) {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$guard = Join-Path $root 'codex-ime-enter-guard.ps1'

Write-Host "Running smoke tests..."
$testsFailed = 0

# Test 1: SelfTest mode
Write-Host "Test 1: SelfTest mode"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $guard -SelfTest

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Error "SelfTest failed with exit code $LASTEXITCODE"
    $testsFailed++
} elseif ($output -notmatch 'self-test OK') {
    Write-Error "SelfTest output did not match expected 'self-test OK'. Output: $output"
    $testsFailed++
} else {
    Write-Host "Test 1 passed."
}

if ($testsFailed -gt 0) {
    Write-Error "$testsFailed smoke test(s) failed."
    exit 1
}

Write-Host "Smoke tests passed."
exit 0
