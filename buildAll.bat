@echo off

SETLOCAL EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
if errorlevel 1 exit /B 2

set _f=UsbDk
set result=0
echo UsbDk target build: %1 %2

rem Keep local builds aligned with the upstream v1.00-22 source baseline.
rem CI or a release job can override these environment variables explicitly.
if not defined USBDK_MAJOR_VERSION set USBDK_MAJOR_VERSION=1
if not defined USBDK_MINOR_VERSION set USBDK_MINOR_VERSION=0
if not defined USBDK_BUILD_NUMBER set USBDK_BUILD_NUMBER=22

if /I "%1" == "MSIONLY" goto BUILD_MSI
if /I "%2" == "NOSIGN" (SET DEBUG_CFG=Debug_NoSign) ELSE (SET DEBUG_CFG=Debug)

call :clean_outputs
if !ERRORLEVEL! NEQ 0 exit /B 1

rem Windows 11 ARM64 uses an ARM64 kernel driver and emulated x86/x64 user mode.
rem The driver is never built for Win32/x64; those platforms are user mode only.
for %%y in (%DEBUG_CFG% Release) do (
  call :build_project "UsbDkHelper\UsbDkHelper.vcxproj" "Win10 %%y|Win32" "%%y_Win32"
  if !ERRORLEVEL! NEQ 0 exit /B 1
  call :build_project "UsbDkController\UsbDkController.vcxproj" "Win10 %%y|Win32" "%%y_Win32_Controller"
  if !ERRORLEVEL! NEQ 0 exit /B 1
  call :build_project "UsbDkInstHelper\UsbDkInstHelper.vcxproj" "Win10 %%y|Win32" "%%y_Win32_InstHelper"
  if !ERRORLEVEL! NEQ 0 exit /B 1

  call :build_project "UsbDkHelper\UsbDkHelper.vcxproj" "Win10 %%y|x64" "%%y_x64"
  if !ERRORLEVEL! NEQ 0 exit /B 1
  call :build_project "UsbDkController\UsbDkController.vcxproj" "Win10 %%y|x64" "%%y_x64_Controller"
  if !ERRORLEVEL! NEQ 0 exit /B 1
  call :build_project "UsbDkInstHelper\UsbDkInstHelper.vcxproj" "Win10 %%y|x64" "%%y_x64_InstHelper"
  if !ERRORLEVEL! NEQ 0 exit /B 1

  call :build_project "UsbDk\UsbDk.vcxproj" "Win10 %%y|ARM64" "%%y_ARM64_Driver"
  if !ERRORLEVEL! NEQ 0 exit /B 1
  call :stage_arm64_package "%%y"
  if !ERRORLEVEL! NEQ 0 exit /B 1
)

rem The x86/x64 roots are user-mode-only. Fail if a driver appears anywhere below them.
for %%R in ("Install\x86" "Install\x64" "Install_Debug\x86" "Install_Debug\x64") do (
  if exist "%%~R" (
    dir /b /s /a-d "%%~R\UsbDk.sys" >nul 2>nul
    if not errorlevel 1 (
      echo Unexpected non-ARM64 driver output below %%~R
      exit /B 1
    )
  )
)

call :generate_tmf
if !ERRORLEVEL! NEQ 0 exit /B 1

if /I "%1" == "NOMSI" goto NOMSI
goto BUILD_MSI

:build_project
for /F "tokens=1,2 delims=|" %%A in ("%~2") do (
  call tools\vs_run.bat "%~1" "%%A" "%%B" "build_%~3.log"
)
exit /B %ERRORLEVEL%

:stage_arm64_package
set "cfg=%~1"
set "root=Install"
if /I "%cfg%" == "Debug" set "root=Install_Debug"
if /I "%cfg%" == "Debug_NoSign" set "root=Install_Debug"
set "out=%root%\ARM64\Win10%cfg%"
set "x64out=%root%\x64\Win10%cfg%"
set "x86out=%root%\x86\Win10%cfg%"

if not exist "%out%\UsbDk.sys" (
  echo Missing ARM64 driver output: %out%\UsbDk.sys
  exit /B 1
)
for %%F in (UsbDkHelper.dll UsbDkController.exe UsbDkInstHelper.exe) do (
  if not exist "%x64out%\%%F" (
    echo Missing x64 user-mode output: %x64out%\%%F
    exit /B 1
  )
  if not exist "%x86out%\%%F" (
    echo Missing x86 user-mode output: %x86out%\%%F
    exit /B 1
  )
)
if exist "%x64out%\UsbDk.sys" (
  echo Unexpected x64 driver output: %x64out%\UsbDk.sys
  exit /B 1
)
if exist "%x86out%\UsbDk.sys" (
  echo Unexpected x86 driver output: %x86out%\UsbDk.sys
  exit /B 1
)

if not exist "%out%\UsbDk_Package" mkdir "%out%\UsbDk_Package"
if not exist "%out%\UsbDk_Package" (
  echo Failed to create package directory: %out%\UsbDk_Package
  exit /B 1
)
if exist "%out%\UsbDk_Package\x86" rmdir /S /Q "%out%\UsbDk_Package\x86"
mkdir "%out%\UsbDk_Package\x86"
if not exist "%out%\UsbDk_Package\x86" (
  echo Failed to create x86 package directory: %out%\UsbDk_Package\x86
  exit /B 1
)
del /Q "%out%\UsbDk_Package\*" >nul 2>nul
copy /Y "%out%\UsbDk.sys" "%out%\UsbDk_Package\UsbDk.sys" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "UsbDkHelper\UsbDk.inf" "%out%\UsbDk_Package\UsbDk.inf" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x64out%\UsbDkHelper.dll" "%out%\UsbDk_Package\UsbDkHelper.dll" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x64out%\UsbDkController.exe" "%out%\UsbDk_Package\UsbDkController.exe" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x64out%\UsbDkInstHelper.exe" "%out%\UsbDk_Package\UsbDkInstHelper.exe" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x86out%\UsbDkHelper.dll" "%out%\UsbDk_Package\x86\UsbDkHelper.dll" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x86out%\UsbDkController.exe" "%out%\UsbDk_Package\x86\UsbDkController.exe" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
copy /Y "%x86out%\UsbDkInstHelper.exe" "%out%\UsbDk_Package\x86\UsbDkInstHelper.exe" >nul
if !ERRORLEVEL! NEQ 0 exit /B 1
exit /B 0

:generate_tmf
call :generate_tmf_for_root "Install" "Release"
if !ERRORLEVEL! NEQ 0 exit /B 1
call :generate_tmf_for_root "Install_Debug" "%DEBUG_CFG%"
exit /B %ERRORLEVEL%

:generate_tmf_for_root
set "tmf_root=%~1"
set "tmf_cfg=%~2"
pushd "%tmf_root%"
if !ERRORLEVEL! NEQ 0 (
  echo Missing TMF output root: %tmf_root%
  exit /B 1
)
del /Q UsbDk.tmf UsbDk.mof >nul 2>nul
call :make1tmf "ARM64\Win10%tmf_cfg%"
set "tmf_result=!ERRORLEVEL!"
popd
exit /B !tmf_result!

:make1tmf
set "tmf_path=%~1"
if not exist "%tmf_path%" (
  echo Missing ARM64 trace output: %tmf_path%
  exit /B 1
)
pushd "%tmf_path%"
if !ERRORLEVEL! NEQ 0 exit /B 1
set "TRACEPDB_EXE="
for /F "delims=" %%I in ('where tracepdb.exe 2^>nul') do (
  set "TRACEPDB_EXE=%%I"
  goto :run_tracepdb
)
for /F "delims=" %%I in ('dir /b /s "%ProgramFiles(x86)%\Windows Kits\10\bin\tracepdb.exe" 2^>nul') do (
  set "TRACEPDB_EXE=%%I"
  goto :run_tracepdb
)
:run_tracepdb
if not defined TRACEPDB_EXE (
  echo tracepdb.exe not found; install the WDK trace tools before building the MSI.
  popd
  exit /B 1
)
echo Making TMF in %tmf_path%
"%TRACEPDB_EXE%" -s -o .\UsbDk.tmf
if !ERRORLEVEL! NEQ 0 (
  popd
  exit /B 1
)
if not exist UsbDk.tmf (
  echo tracepdb.exe did not create UsbDk.tmf in %tmf_path%
  popd
  exit /B 1
)
popd
type "%tmf_path%\UsbDk.tmf" >> UsbDk.tmf
del /Q "%tmf_path%\UsbDk.??f" >nul 2>nul
exit /B %ERRORLEVEL%

:clean_outputs
rem Keep only this build's bounded output roots; never recurse from C:\ or a shared-folder root.
for %%D in ("Install\x86" "Install\x64" "Install\ARM64" "Install_Debug\x86" "Install_Debug\x64" "Install_Debug\ARM64") do (
  if exist "%%~D" rmdir /S /Q "%%~D"
  if exist "%%~D" (
    echo Failed to clean output root: %%~D
    exit /B 1
  )
)
exit /B 0

:BUILD_MSI
pushd Tools\Installer
SET "UsbDkVersion=%USBDK_MAJOR_VERSION%.%USBDK_MINOR_VERSION%.%USBDK_BUILD_NUMBER%"
buildmsi.bat %2 ARM64
set result=%ERRORLEVEL%
popd
goto FINISH

:NOMSI
set result=0

:FINISH
popd
ENDLOCAL
exit /B %result%
