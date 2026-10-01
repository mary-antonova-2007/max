@echo off
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0send-file.ps1" -Path "%~1"
pause
