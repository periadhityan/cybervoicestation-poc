# Windows counterpart to native/mac/run-native.sh -- same steps: create/
# reuse a plain virtualenv, install requirements-app.txt into it, start the
# app. No conda, no WSL, no bash required.
#
# This script lives at native\windows\ -- go up two levels to reach the
# project root (native\windows\ -> native\ -> project root), where app\ and
# requirements-app.txt actually live. The app itself isn't duplicated here;
# this is just the Windows entry point into the one shared copy.
#
# Run from a PowerShell window:
#   .\native\windows\run-native.ps1
#
# If PowerShell refuses to run it ("running scripts is disabled on this
# system"), that's the default execution policy blocking unsigned scripts --
# run it this way instead, which only bypasses the policy for this one
# process, not machine-wide:
#   powershell -ExecutionPolicy Bypass -File .\native\windows\run-native.ps1

$ErrorActionPreference = "Stop"

# $PSScriptRoot is this script's own folder (native\windows\); go up two.
$Project = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$VenvPython = Join-Path $Project ".venv\Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    $python = Get-Command python -ErrorAction SilentlyContinue

    if (-not $pyLauncher -and -not $python) {
        Write-Host "Could not find Python on PATH." -ForegroundColor Red
        Write-Host "Install Python 3.9+ from https://www.python.org/downloads/windows/"
        Write-Host "Be sure to check 'Add python.exe to PATH' during setup, then try again."
        Read-Host "Press Enter to close"
        exit 1
    }

    if ($pyLauncher) {
        & py -3 -m venv (Join-Path $Project ".venv")
    } else {
        & python -m venv (Join-Path $Project ".venv")
    }
}

if (-not (Test-Path $VenvPython)) {
    Write-Host "Virtual environment creation failed -- see any error above." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

& $VenvPython -m pip install --quiet --upgrade pip
& $VenvPython -m pip install --quiet -r (Join-Path $Project "requirements-app.txt")

Set-Location (Join-Path $Project "app")
& $VenvPython app.py
