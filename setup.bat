@echo off
echo Ethereum ノードセットアップツール
echo =============================
echo.
echo PowerShell スクリプトを実行します...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
pause