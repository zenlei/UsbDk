/**********************************************************************
* Copyright (c) 2013-2014  Red Hat, Inc.
*
* Developed by Daynix Computing LTD.
*
* Authors:
*     Dmitry Fleytman <dmitry@daynix.com>
*     Pavel Gurvich <pavel@daynix.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
**********************************************************************/

#include "stdafx.h"

bool IsNativeArm64Windows()
{
    using IsWow64Process2Fn = BOOL(WINAPI *)(HANDLE, USHORT *, USHORT *);

    auto kernel32 = GetModuleHandle(TEXT("kernel32.dll"));
    auto isWow64Process2 = reinterpret_cast<IsWow64Process2Fn>(
        GetProcAddress(kernel32, "IsWow64Process2"));
    if (isWow64Process2 == nullptr)
    {
        return false;
    }

    USHORT processMachine = IMAGE_FILE_MACHINE_UNKNOWN;
    USHORT nativeMachine = IMAGE_FILE_MACHINE_UNKNOWN;
    if (!isWow64Process2(GetCurrentProcess(), &processMachine, &nativeMachine))
    {
        return false;
    }

    return nativeMachine == IMAGE_FILE_MACHINE_ARM64;
}

void UsbDkHandleHolder<SC_HANDLE>::Close()
{
    CloseServiceHandle(m_Handle);
}

void UsbDkHandleHolder<HANDLE>::Close()
{
    CloseHandle(m_Handle);
}
