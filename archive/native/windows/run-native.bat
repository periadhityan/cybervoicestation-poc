@echo off
setlocal

rem Windows counterpart to native/mac/run-native.sh -- same steps: create/
rem reuse a plain virtualenv, install requirements-app.txt into it, start
rem the app. No conda, no WSL, no bash required. Double-click this file
rem from Explorer, or run it from a Command Prompt / PowerShell window.
rem
rem This script lives at native\windows\ -- go up two levels to reach the
rem project root (native\windows\ -> native\ -> project root), where app\
rem and requirements-app.txt actually live. The app itself isn't duplicated
rem here; this is just the Windows entry point into the one shared copy.

rem %~dp0 is this script's own folder (native\windows\), trailing backslash.
set "PROJECT=%~dp0..\.."
for %%I in ("%PROJECT%") do set "PROJECT=%%~fI"

if not exist "%PROJECT%\.venv\Scripts\python.exe" (
    where py >nul 2>nul
    if errorlevel 1 (
        where python >nul 2>nul
        if errorlevel 1 (
            echo Could not find Python on PATH.
            echo Install Python 3.9+ from https://www.python.org/downloads/windows/
            echo Be sure to check "Add python.exe to PATH" during setup, then try again.
            pause
            exit /b 1
        )
        python -m venv "%PROJECT%\.venv"
    ) else (
        py -3 -m venv "%PROJECT%\.venv"
    )
)

set "VENV_PY=%PROJECT%\.venv\Scripts\python.exe"

if not exist "%VENV_PY%" (
    echo Virtual environment creation failed -- see any error above.
    pause
    exit /b 1
)

"%VENV_PY%" -m pip install --quiet --upgrade pip
"%VENV_PY%" -m pip install --quiet -r "%PROJECT%\requirements-app.txt"

cd /d "%PROJECT%\app"
"%VENV_PY%" app.py

rem If app.py exits (Ctrl+C, or an error on startup), keep the window open
rem so any error message is readable instead of the console vanishing.
pause
