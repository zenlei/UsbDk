@echo off
setlocal EnableExtensions

fltmc >nul 2>&1
if errorlevel 1 (
  echo Run this script from an elevated Administrator command prompt.
  exit /B 1
)

bcdedit /set testsigning off
if errorlevel 1 exit /B 1

echo Test signing is disabled. Reboot Windows to return to normal enforcement.
exit /B 0
