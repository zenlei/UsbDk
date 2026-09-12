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

rem Windows blocks TESTSIGNING while UEFI Secure Boot is enabled. Detect it
rem before changing certificate stores so the failure is actionable.
set "SECURE_BOOT_STATE=-1"
for /F "delims=" %%S in ('powershell -NoProfile -Command "try { Write-Output ([int](Confirm-SecureBootUEFI)) } catch { Write-Output -1 }" 2^>nul') do set "SECURE_BOOT_STATE=%%S"
if "%SECURE_BOOT_STATE%" == "1" (
  echo UEFI Secure Boot is enabled. Disable Secure Boot in the VM firmware,
  echo reboot Windows, then run this script again.
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
