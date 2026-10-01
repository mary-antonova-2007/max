@echo off
if not exist "%~dp0outbox" mkdir "%~dp0outbox"
"%~dp0sdk\platform-tools\adb.exe" -s emulator-5580 pull /sdcard/Download/. "%~dp0outbox"
if errorlevel 1 (
    echo File transfer failed. Check that MAX Android is running.
    pause
    exit /b 1
)
start "" explorer.exe "%~dp0outbox"
pause
