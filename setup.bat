@echo off
echo Ethereum Node Setup Tool
echo =============================
echo.
echo Running PowerShell script...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup_fixed.ps1"

echo.
pause