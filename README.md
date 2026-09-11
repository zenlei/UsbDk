[![Build Status](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)

# UsbDk

> **Development status: experimental Windows 11 on ARM64 port**
>
> This `arm64-port` branch is under active development and is **not recommended
> for normal or production use**. It targets a native ARM64 `UsbDk.sys` driver
> with x64 and x86 user-mode binaries for Windows on ARM64. Driver signing,
> hardware enumeration, USB transfer coverage, and MSI packaging are not yet a
> production acceptance baseline.

[中文说明](README.zh-CN.md)

UsbDk (USB Development Kit) is a open-source library for Windows meant
to provide user mode applications with direct and exclusive access to
USB devices by detaching those from Windows PNP manager and device drivers
and providing user mode with API for USB-specific operations on the device.

The library is intended to be as generic as possible, support  all types of
USB devices, bulk and isochronous transfers, composite devices etc.

The upstream project supports Windows versions starting from Windows XP/2003.
This branch intentionally narrows the build target to Windows 10/11 on ARM64;
legacy Win7/Win8/XP build configurations are not maintained here.

## Documentation

* See ARCHITECTURE document in the source tree root.
* See Documentation folder in the source tree root.
* See UsbDkHelper\UsbDkHelper.h UsbDkHelper\UsbDkHelperHider.h for API documentation

## Building

**Tools required for the Windows on ARM64 target:**

* Visual Studio 2022 with Desktop development with C++
* MSVC ARM64 plus x86/x64 tools and libraries
* Matching Windows 10 SDK and WDK (10.0.26100 was used for validation)
* WiX Toolset v3 (only for building the MSI installer)

***Compilation***

There is no standalone Makefile. The supported build entry point is
`buildAll.bat`, which performs a serial build of the target matrix:

* `UsbDk.sys`: ARM64 only
* `UsbDkHelper.dll`, `UsbDkController.exe`, `UsbDkInstHelper.exe`: Win32 and x64

From a VS2022 Developer Command Prompt or PowerShell, run:

```cmd
buildAll.bat NOMSI NOSIGN
```

The ARM64 package is written to
`Install\ARM64\Win10Release\UsbDk_Package`. Its root contains the ARM64 driver,
INF, and x64 user-mode binaries; the `x86` subdirectory contains the x86
user-mode binaries. No x86/x64 `UsbDk.sys` is produced. Omit `NOMSI` after
installing WiX to build the ARM64 MSI packages.

### Current validation status

On September 11, 2026, `buildAll.bat NOMSI NOSIGN` completed in a Windows 11
ARM64 VM with 14 successful build targets and no reported warnings or errors.
The generated images reported `AA64` for `UsbDk.sys`, `8664` for x64 user-mode
binaries, and `014C` for x86 user-mode binaries. Both emulated user-mode
controller binaries started with `-h`, and no x86/x64 output directory contained
`UsbDk.sys`.

This is build and smoke-test evidence only. Runtime installation was blocked by
Windows Code Integrity because the VM was not using test signing or a trusted
production signature. USB device enumeration, exclusive access, transfer
coverage, rollback, and the ARM64 MSI still require separate validation.

## Installing and running

Use UsbDkController.exe to install/uninstall and verify basic operation.
Run UsbDkController.exe without parameters for command line options.

## Known issues

* Installation on 64-bit versions of Windows 7 fails if security update
  [3033929](https://technet.microsoft.com/en-us/library/security/3033929)
  is not installed. Reason: UsbDk driver is signed by SHA-256 certificate. Without this update
  Windows 7 does not recognize the signature properly and fails to load the driver.
