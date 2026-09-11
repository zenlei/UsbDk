@echo off
setlocal EnableExtensions

if "%~1"=="" (
  echo Usage: %~nx0 path\to\UsbDk.cer
  exit /B 2
)

set "CERT=%~1"
if not exist "%CERT%" (
  echo Certificate not found: "%CERT%"
  exit /B 2
)

fltmc >nul 2>&1
if errorlevel 1 (
  echo Run this script from an elevated Administrator command prompt.
  exit /B 1
)

certutil -addstore -f Root "%CERT%"
if errorlevel 1 exit /B 1
certutil -addstore -f TrustedPublisher "%CERT%"
if errorlevel 1 exit /B 1
bcdedit /set testsigning on
if errorlevel 1 exit /B 1

echo Test signing is enabled. Reboot Windows before installing the MSI.
exit /B 0
