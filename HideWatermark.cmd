@echo off
:: ============================================================================
::  Hide Windows Watermark
::  Hides the "Activate Windows" desktop watermark WITHOUT activating Windows.
::  It only changes two registry values and keeps a backup so you can undo.
::
::  Usage:  HideWatermark.cmd [/hide | /restore | /status | /help]
::          (no option = interactive menu)
:: ============================================================================
setlocal EnableExtensions DisableDelayedExpansion
title Hide Windows Watermark

set "APP_VER=1.0.0"
set "ACT_KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Activation"
set "DSK_KEY=HKCU\Control Panel\Desktop"
set "DATA_DIR=%ProgramData%\HideWatermark"
set "BACKUP_FILE=%ProgramData%\HideWatermark\backup.txt"

set "ARG1=%~1"
set "ARG2=%~2"

if /i "%ARG1%"=="/help"  goto :usage
if /i "%ARG1%"=="-h"     goto :usage
if /i "%ARG1%"=="--help" goto :usage

:: ---------------------------------------------------------------------------
::  Require administrator rights (relaunch elevated if needed)
:: ---------------------------------------------------------------------------
fltmc >nul 2>&1
if not errorlevel 1 goto :is_admin

echo.
echo  Administrator rights are required. Requesting elevation...
if "%ARG1%"=="" goto :elevate_menu
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%ARG1% /elevated' -Verb RunAs" >nul 2>&1
goto :elevate_check
:elevate_menu
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
:elevate_check
if errorlevel 1 (
    echo.
    echo  [ERROR] Elevation was cancelled or failed.
    echo          Right-click the file and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)
exit /b 0

:is_admin
if "%ARG1%"=="" goto :menu
if /i "%ARG1%"=="/hide"    goto :cli_hide
if /i "%ARG1%"=="/restore" goto :cli_restore
if /i "%ARG1%"=="/status"  goto :cli_status
echo.
echo  [ERROR] Unknown option: %ARG1%
call :usage
exit /b 1

:cli_hide
call :banner
call :do_hide
goto :cli_end
:cli_restore
call :banner
call :do_restore
goto :cli_end
:cli_status
call :banner
call :do_status
goto :cli_end
:cli_end
set "RC=%errorlevel%"
if /i "%ARG2%"=="/elevated" (
    echo.
    pause
)
exit /b %RC%

:: ---------------------------------------------------------------------------
::  Interactive menu
:: ---------------------------------------------------------------------------
:menu
cls
call :banner
call :get_state
echo   Watermark hiding : %STATE_TXT%
echo.
echo   [1] Hide the "Activate Windows" watermark
echo   [2] Restore original settings - undo
echo   [3] Show activation status
echo   [4] Restart the computer now
echo   [0] Exit
echo.
choice /c 12340 /n /m "  Select an option: "
set "SEL=%errorlevel%"
if "%SEL%"=="1" goto :m_hide
if "%SEL%"=="2" goto :m_restore
if "%SEL%"=="3" goto :m_status
if "%SEL%"=="4" goto :m_reboot
exit /b 0

:m_hide
call :do_hide
goto :m_back
:m_restore
call :do_restore
goto :m_back
:m_status
call :do_status
goto :m_back
:m_reboot
echo.
choice /c YN /m "  Restart the computer now"
if errorlevel 2 goto :menu
shutdown /r /t 5 /c "Restarting to apply watermark settings"
echo  The computer will restart in 5 seconds...
exit /b 0
:m_back
echo.
pause
goto :menu

:: ---------------------------------------------------------------------------
::  Actions
:: ---------------------------------------------------------------------------
:do_hide
echo.
echo  [*] Saving a backup of the current settings...
call :backup
if errorlevel 1 exit /b 1
echo  [*] Turning off automatic activation prompts...
reg add "%ACT_KEY%" /v Manual /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 goto :hide_fail
echo  [*] Hiding the desktop version text...
reg add "%DSK_KEY%" /v PaintDesktopVersion /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 goto :hide_fail
echo.
echo  [OK] Done. RESTART your computer to apply the change.
exit /b 0
:hide_fail
echo.
echo  [ERROR] Could not write to the registry. Make sure you run as administrator.
exit /b 1

:do_restore
echo.
if not exist "%BACKUP_FILE%" goto :restore_default
set "B_MANUAL=none"
set "B_PDV=none"
for /f "usebackq tokens=1,2 delims==" %%A in ("%BACKUP_FILE%") do set "B_%%A=%%B"
echo  [*] Restoring settings from the backup...
call :restore_value "%ACT_KEY%" Manual "%B_MANUAL%" || goto :restore_fail
call :restore_value "%DSK_KEY%" PaintDesktopVersion "%B_PDV%" || goto :restore_fail
del /f /q "%BACKUP_FILE%" >nul 2>&1
goto :restore_ok
:restore_default
echo  [*] No backup found - restoring the Windows default...
call :restore_value "%ACT_KEY%" Manual "none" || goto :restore_fail
:restore_ok
echo.
echo  [OK] Settings restored. RESTART your computer to apply the change.
exit /b 0
:restore_fail
echo.
echo  [ERROR] Could not restore the registry values. Make sure you run as administrator.
exit /b 1

:do_status
echo.
echo  ----------------- System -----------------
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul`) do echo   OS       : %%A
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul ^| find /i "DisplayVersion"') do echo   Version  : %%A
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul ^| find /i "CurrentBuild"') do echo   Build    : %%A
echo.
echo  --------------- Activation ---------------
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /xpr
echo.
echo  ---------------- This tool ---------------
call :read_dword "%ACT_KEY%" Manual CUR_MANUAL
call :read_dword "%DSK_KEY%" PaintDesktopVersion CUR_PDV
echo   Manual              : %CUR_MANUAL%   (1 = watermark hiding is ON)
echo   PaintDesktopVersion : %CUR_PDV%
if exist "%BACKUP_FILE%" (
    echo   Backup file         : %BACKUP_FILE%
) else (
    echo   Backup file         : none
)
exit /b 0

:: ---------------------------------------------------------------------------
::  Helpers
:: ---------------------------------------------------------------------------
:backup
if exist "%BACKUP_FILE%" (
    echo      A backup already exists - keeping the original values.
    exit /b 0
)
if not exist "%DATA_DIR%\" mkdir "%DATA_DIR%" >nul 2>&1
call :read_dword "%ACT_KEY%" Manual ORIG_MANUAL
call :read_dword "%DSK_KEY%" PaintDesktopVersion ORIG_PDV
(
    echo MANUAL=%ORIG_MANUAL%
    echo PDV=%ORIG_PDV%
) > "%BACKUP_FILE%" 2>nul
if not exist "%BACKUP_FILE%" (
    echo  [ERROR] Could not create the backup file: %BACKUP_FILE%
    exit /b 1
)
echo      Backup saved to: %BACKUP_FILE%
exit /b 0

:: :read_dword <key> <value-name> <out-var>   -> number, or "none" if missing
:read_dword
set "%~3=none"
for /f "tokens=3" %%A in ('reg query "%~1" /v "%~2" 2^>nul ^| find /i "%~2"') do set /a "%~3=%%A" >nul 2>&1
exit /b 0

:: :restore_value <key> <value-name> <number|none>
:restore_value
if "%~3"=="none" (
    reg query "%~1" /v "%~2" >nul 2>&1 || exit /b 0
    reg delete "%~1" /v "%~2" /f >nul 2>&1
    exit /b
)
reg add "%~1" /v "%~2" /t REG_DWORD /d %~3 /f >nul 2>&1
exit /b

:get_state
call :read_dword "%ACT_KEY%" Manual CUR_MANUAL
if "%CUR_MANUAL%"=="1" (set "STATE_TXT=ON") else (set "STATE_TXT=OFF")
exit /b 0

:banner
echo.
echo  ==============================================
echo        Hide Windows Watermark   v%APP_VER%
echo  ==============================================
echo.
exit /b 0

:usage
echo.
echo  Hide Windows Watermark v%APP_VER%
echo.
echo  Usage: HideWatermark.cmd [option]
echo.
echo    (no option)   Open the interactive menu
echo    /hide         Hide the watermark
echo    /restore      Undo the changes
echo    /status       Show activation and tool status
echo    /help         Show this help
echo.
exit /b 0
