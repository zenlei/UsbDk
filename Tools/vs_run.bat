@echo off
setlocal EnableExtensions

rem Build one project with the VS2022 ARM64-hosted MSBuild. The old script
rem launched VS2015 devenv.exe, which is not present on the supported VM.
if "%~4"=="" (
  echo Usage: %~nx0 project configuration platform logfile
  exit /b 64
)

set "PROJECT=%~1"
set "CONFIGURATION=%~2"
set "PLATFORM=%~3"
set "LOGFILE=%~4"
for %%I in ("%~dp0..") do set "SOLUTION_DIR=%%~fI"

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSINSTALLDIR="
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do set "VSINSTALLDIR=%%I\"
)
if not defined VSINSTALLDIR if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" set "VSINSTALLDIR=%ProgramFiles%\Microsoft Visual Studio\2022\Community\"
if not defined VSINSTALLDIR (
  echo Visual Studio 2022 installation not found
  exit /b 1
)

set "VSDEVCMD=%VSINSTALLDIR%\Common7\Tools\VsDevCmd.bat"
set "MSBUILD=%VSINSTALLDIR%\MSBuild\Current\Bin\arm64\MSBuild.exe"
if not exist "%MSBUILD%" set "MSBUILD=%VSINSTALLDIR%\MSBuild\Current\Bin\MSBuild.exe"
if not exist "%MSBUILD%" (
  echo MSBuild not found under "%VSINSTALLDIR%"
  exit /b 2
)

if not exist "%VSDEVCMD%" (
  echo VsDevCmd not found: "%VSDEVCMD%"
  exit /b 3
)
call "%VSDEVCMD%" -arch=arm64 -host_arch=arm64 >nul
set "VSCMD_RESULT=%ERRORLEVEL%"
if not "%VSCMD_RESULT%"=="0" (
  echo Failed to initialize the VS2022 ARM64 build environment, exit %VSCMD_RESULT%
  exit /b 4
)

echo Building "%PROJECT%" [%CONFIGURATION% ^| %PLATFORM%]
echo MSBuild: "%MSBUILD%"
"%MSBUILD%" "%SOLUTION_DIR%\%PROJECT%" /t:Rebuild /p:Configuration="%CONFIGURATION%" /p:Platform="%PLATFORM%" /p:SolutionDir="%SOLUTION_DIR%/" /m:1 /nologo /fl /flp:LogFile="%SOLUTION_DIR%\%LOGFILE%";Verbosity=normal
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" (
  echo Build failed with exit code %RESULT%
)
endlocal & exit /b %RESULT%
