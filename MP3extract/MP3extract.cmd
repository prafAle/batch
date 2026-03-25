@echo off
setlocal enabledelayedexpansion
cls

:: ============================================================================
::  FILENAME:   extractMP3Adv.cmd
::  PURPOSE:    Extract MP3 audio from MP4 files with merge/split modes,
::               dynamic bitrate calculation, presets, color output,
::               output directory option, ffmpeg checks and modern UI.
::  VERSION:    2026-03-25
::
::  USAGE:
::      extractMP3Adv.cmd  <input_path>  [/mode:merge|split]
::                                         [/preset:HQ|MED|LOW|SIZE]
::                                         [/out:"C:\OutputFolder"]
::
::  DEFAULTS:
::      mode    = merge
::      preset  = MED
::      threads = auto (ffmpeg default)
::      outdir  = current folder
::
::  EXAMPLES:
::      extractMP3Adv.cmd "D:\Videos"
::      extractMP3Adv.cmd "D:\Videos" /mode:split
::      extractMP3Adv.cmd "D:\Videos" /mode:merge /preset:HQ
::      extractMP3Adv.cmd "file.mp4"  /mode:split
:: ============================================================================
:: Enable ANSI escape sequences for colors
for /f "tokens=2 delims=: " %%a in ('reg query HKCU\Console ^| find "VirtualTerminalLevel"') do set ANSI=%%a >nul 2>&1
if "%ANSI%" neq "0x1" reg add HKCU\Console /f /v VirtualTerminalLevel /t REG_DWORD /d 1 >nul

:: CMD default colors
color 07

:: ANSI color definitions
set C_RED=[91m
set C_GREEN=[92m
set C_YELLOW=[93m
set C_BLUE=[94m
set C_MAGENTA=[95m
set C_CYAN=[96m
set C_RESET=[0m

:: ============================================================================
:: HELP
:: ============================================================================
if "%~1"=="" goto :HELP
if /I "%~1"=="/help" goto :HELP
if /I "%~1"=="-help" goto :HELP


:PARSE_ARGS
set "INPUT=%~1"
set "MODE=merge"
set "PRESET=MED"
set "OUTDIR=%cd%"

shift
:ARGLOOP
if "%~1"=="" goto :AFTER_PARSE

if /I "%~1"=="/mode:merge" set MODE=merge
if /I "%~1"=="/mode:split" set MODE=split

if /I "%~1"=="/preset:HQ" set PRESET=HQ
if /I "%~1"=="/preset:MED" set PRESET=MED
if /I "%~1"=="/preset:LOW" set PRESET=LOW
if /I "%~1"=="/preset:SIZE" set PRESET=SIZE

echo %~1 | findstr /I "^/out:" >nul && (
    set "OUTDIR=%~1"
    set "OUTDIR=!OUTDIR:/out:=!"
    set "OUTDIR=!OUTDIR:"=!"
)

shift
goto :ARGLOOP


:AFTER_PARSE

:: ============================================================================
:: CHECK FFMPEG / FFPROBE
:: ============================================================================
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo %C_RED%ERROR:%C_RESET% ffmpeg is not installed or not in PATH.
    echo Install ffmpeg from: https://ffmpeg.org/
    echo Then re-run this script.
    pause
    exit /b
)

where ffprobe >nul 2>&1
if errorlevel 1 (
    echo %C_RED%ERROR:%C_RESET% ffprobe is not installed or not in PATH.
    echo Install ffmpeg tools from: https://ffmpeg.org/
    echo Then re-run this script.
    pause
    exit /b
)

:: ============================================================================
:: VALIDATE INPUT PATH
:: ============================================================================
if not exist "%INPUT%" (
    echo %C_RED%ERROR:%C_RESET% Input path does not exist:
    echo        "%INPUT%"
    pause
    exit /b 1
)

set "IS_DIR=false"
if exist "%INPUT%\*" set "IS_DIR=true"


:: ============================================================================
:: GENERATE TIMESTAMP
:: ============================================================================
for /f "tokens=1-6 delims=/:., " %%a in ("%date% %time%") do (
    set YYYY=%%c
    set MM=%%b
    set DD=%%a
    set HH=%%d
    set Min=%%e
    set Sec=%%f
)
if %MM% lss 10 set MM=0%MM%
if %DD% lss 10 set DD=0%DD%
if %HH% lss 10 set HH=0%HH%
if %Min% lss 10 set Min=0%Min%
if %Sec% lss 10 set Sec=0%Sec%

set TIMESTAMP=%YYYY%%MM%%DD%_%HH%%Min%%Sec%


:: ============================================================================
:: COUNT FILES
:: ============================================================================
set FILECOUNT=0

if "%IS_DIR%"=="true" (
    for %%I in ("%INPUT%\*.mp4") do set /a FILECOUNT+=1
) else (
    set FILECOUNT=1
)

if %FILECOUNT%==0 (
    echo %C_RED%ERROR:%C_RESET% No MP4 files found.
    pause
    exit /b
)

if /I "%MODE%"=="merge" (
    if %FILECOUNT% LSS 2 (
        echo %C_RED%ERROR:%C_RESET% Merge mode requires at least 2 files.
        echo Found only %FILECOUNT% MP4 file(s). Use /mode:split instead.
        pause
        exit /b
    )
)


:: ============================================================================
:: PRESET MODIFIERS (Preset B)
::   HQ   = x1.5   (capped at 320 kbps)
::   MED  = x1.0
::   LOW  = x0.6
::   SIZE = x1.0 (keeps default dynamic size logic)
:: ============================================================================
set MULTIPLIER=1.0
if /I "%PRESET%"=="HQ" set MULTIPLIER=1.5
if /I "%PRESET%"=="MED" set MULTIPLIER=1.0
if /I "%PRESET%"=="LOW" set MULTIPLIER=0.6
if /I "%PRESET%"=="SIZE" set MULTIPLIER=1.0


:: ============================================================================
:: SPLIT MODE
:: ============================================================================
if /I "%MODE%"=="split" goto :SPLIT_MODE


:: ============================================================================
:: MERGE MODE
:: ============================================================================
:MERGE_MODE

set "TEMP=%tmp%\%TIMESTAMP%_merge"
set "LIST_FILE=%TEMP%\list.txt"

mkdir "%TEMP%" >nul 2>&1
break>"%LIST_FILE%"

for %%I in ("%INPUT%\*.mp4") do (
    echo file '%%~fI' >> "%LIST_FILE%"
)

:: Calculate total duration
set total_duration=0

for /f "tokens=*" %%F in ("%LIST_FILE%") do (
    for /f "tokens=2 delims='" %%A in ("%%F") do (
        for /f "tokens=* " %%D in ('ffprobe -v error -show_entries format^=duration -of csv=p=0 "%%A"') do (
            set /a total_duration+=%%D
        )
    )
)

:: Dynamic bitrate for size limit (199 MB max)
set /a bitrate=(199*1024*8)/!total_duration!

:: Apply preset multiplier
set /a bitrate=bitrate*MULTIPLIER

if %bitrate% GTR 320 set bitrate=320
if %bitrate% LSS 32 set bitrate=32

echo.
echo %C_CYAN%Merging files...%C_RESET%
echo Bitrate: %bitrate% kbps
echo Output folder: "%OUTDIR%"


ffmpeg -f concat -safe 0 -i "%LIST_FILE%" ^
       -b:a %bitrate%k -hide_banner -stats ^
       "%TEMP%\merged.mp3"

move "%TEMP%\merged.mp3" "%OUTDIR%\%TIMESTAMP%_MergedAudio.mp3" >nul
echo.
echo %C_GREEN%MERGE COMPLETED.%C_RESET%

rd /s /q "%TEMP%"
pause
exit /b


:: ============================================================================
:: SPLIT MODE
:: ============================================================================
:SPLIT_MODE
echo %C_CYAN%Split mode active.%C_RESET%

if "%IS_DIR%"=="true" (
    for %%I in ("%INPUT%\*.mp4") do (
        echo Extracting: %%~nxI
        ffmpeg -hide_banner -loglevel error -i "%%I" ^
               -vn -acodec libmp3lame -b:a 128k ^
               "%OUTDIR%\%%~nI.mp3"
    )
) else (
    echo Extracting single file...
    ffmpeg -hide_banner -loglevel error -i "%INPUT%" ^
           -vn -acodec libmp3lame -b:a 128k ^
           "%OUTDIR%\%~n1.mp3"
)

echo.
echo %C_GREEN%SPLIT COMPLETED.%C_RESET%
pause
exit /b


:: ============================================================================
:: HELP
:: ============================================================================
:HELP
echo.
echo --------------------- HELP -----------------------
echo extractMP3Adv.cmd ^<input_path^> [/mode:merge^|split] [/preset:HQ^|MED^|LOW^|SIZE] [/out:"folder"]
echo.
echo Extract MP3 audio from MP4 files with merge/split modes,
echo dynamic bitrate calculation, presets, color output,
echo output directory option, ffmpeg checks and modern UI.
echo.
echo Modes:
echo   merge   = Combine multiple MP4 files into ONE MP3
echo   split   = Produce one MP3 per MP4
echo.
echo Presets:
echo   HQ    = 1.5x bitrate (max 320 kbps)
echo   MED   = 1.0x (default)
echo   LOW   = 0.6x bitrate
echo   SIZE  = size‑optimized automatic calculation
echo.
echo Example:
echo   extractMP3Adv.cmd "D:\clips" /mode:merge /preset:HQ /out:"D:\audio"
echo ---------------------------------------------------
exit /b
