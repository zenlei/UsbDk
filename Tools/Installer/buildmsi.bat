SETLOCAL EnableExtensions EnableDelayedExpansion

IF NOT DEFINED USBDK_MAJOR_VERSION SET USBDK_MAJOR_VERSION=1
IF NOT DEFINED USBDK_MINOR_VERSION SET USBDK_MINOR_VERSION=0
IF NOT DEFINED USBDK_BUILD_NUMBER SET USBDK_BUILD_NUMBER=22
IF NOT DEFINED UsbDkVersion SET "UsbDkVersion=%USBDK_MAJOR_VERSION%.%USBDK_MINOR_VERSION%.%USBDK_BUILD_NUMBER%"
IF "%UsbDkVersion%" == ".." SET "UsbDkVersion=%USBDK_MAJOR_VERSION%.%USBDK_MINOR_VERSION%.%USBDK_BUILD_NUMBER%"

if [%1] EQU [NOSIGN] (SET DEBUG_CFG=Debug_NoSign) ELSE (SET DEBUG_CFG=Debug)

set ARCH_LIST=ARM64
if not [%2] EQU [] set ARCH_LIST=%2

set "WIX_CANDLE=%WIX%bin\candle.exe"
set "WIX_LIGHT=%WIX%bin\light.exe"
if exist "%~dp0..\Wix314\candle.exe" (
  set "WIX_CANDLE=%~dp0..\Wix314\candle.exe"
  set "WIX_LIGHT=%~dp0..\Wix314\light.exe"
)

for %%A in (%ARCH_LIST%) do (
  call :build_arch %%A
  if !ERRORLEVEL! NEQ 0 exit /B 1
)

echo SUCCEEDED
exit /B 0

:build_arch
set "MSI_ARCH=%~1"
if /I not "%MSI_ARCH%" == "ARM64" (
  echo Unsupported MSI architecture: %MSI_ARCH% ^(only ARM64 is supported by this target^)
  exit /B 2
)
call :build_msi "Install_Debug\ARM64" "UsbDk_Debug_%UsbDkVersion%_ARM64.msi" "%DEBUG_CFG%" "-dUsbDkARM64=1"
if !ERRORLEVEL! NEQ 0 exit /B 1
call :build_msi "Install\ARM64" "UsbDk_%UsbDkVersion%_ARM64.msi" "Release" "-dUsbDkARM64=1"
if !ERRORLEVEL! NEQ 0 exit /B 1
exit /B 0

:build_msi
pushd ..\..\%~1
if !ERRORLEVEL! NEQ 0 exit /B 1

del *.msi *.wixobj *.wixpdb

"%WIX_CANDLE%" ..\..\Tools\Installer\UsbDkInstaller.wxs -out UsbDk.wixobj -dUsbDkVersion=%UsbDkVersion% -dConfig=%~3 %~4
if !ERRORLEVEL! NEQ 0 exit /B 1
"%WIX_LIGHT%" UsbDk.wixobj -out %~2 -sw1076
if !ERRORLEVEL! NEQ 0 exit /B 1

rem Keep the WDK test certificate beside the MSI for VM test setup. This is
rem intentionally a sidecar, not an automatic certificate-trust action.
set "CERT_DIR=Win10%~3"
if exist "%CERT_DIR%\UsbDk.cer" (
  set "MSI_BASENAME=%~n2"
  copy /Y "%CERT_DIR%\UsbDk.cer" "!MSI_BASENAME!.cer" >nul
  if !ERRORLEVEL! NEQ 0 exit /B 1
)

popd
exit /B 0
