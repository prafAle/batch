@echo off
setlocal EnableExtensions EnableDelayedExpansion
title extractMP3Adv - Professional Audio Extractor

:: ============================================================================
::  FILENAME:   extractMP3Adv.cmd
::  PURPOSE:    Extract audio from MP4 files with single/split/merge modes,
::               silence removal, codec-aware dynamic bitrate calculation,
::               quality presets, colored output, output directory support,
::               ffmpeg validation and modern command-line UI.
::  VERSION:    2026-04-21
::
::  USAGE:
::      extractMP3Adv.cmd  <input_path>  [/mode:merge|split]
::                                       [/preset:HQ|MED|LOW]
::                                       [/codec:mp3|aac|opus]
::                                       [/out:"C:\OutputFolder"]
::
::  DEFAULTS:
::      mode            = auto (single/split/merge)
::      preset          = MED
::      codec           = mp3
::      silence removal = enabled (single & split only)
::      outdir          = current folder
::
::  EXAMPLES:
::      extractMP3Adv.cmd "D:\Videos"
::      extractMP3Adv.cmd "D:\Videos" /mode:split
::      extractMP3Adv.cmd "D:\Videos" /mode:merge /preset:HQ
::      extractMP3Adv.cmd "file.mp4"
:: ============================================================================

:: ============================================================================
:: ANSI COLORS
:: ============================================================================
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set C_INFO=%ESC%[94m
set C_WARN=%ESC%[93m
set C_ERR=%ESC%[91m
set C_OK=%ESC%[92m
set C_LABEL=%ESC%[96m
set C_RESET=%ESC%[0m

:: ============================================================================
:: SILENCE REMOVAL CONFIGURATION
:: ============================================================================
set REMOVE_SILENCE=1
set SILENCE_THRESHOLD=-30dB
set SILENCE_DURATION=1.0

:: ============================================================================
:: APPLICATION INFO
:: ============================================================================
set APP_NAME=extractMP3Adv
set APP_VER=2026.04.21

:: ============================================================================
:: DEFAULT VALUES
:: ============================================================================
set MODE=merge
set PRESET=MED
set CODEC=mp3
set OUTDIR=%cd%
set INPUT=
set INPUT_BASENAME=
set OUTPUT_LIST=

:: ============================================================================
:: HELP
:: ============================================================================
if "%~1"=="/help" goto :HELP
if "%~1"=="-help" goto :HELP
if "%~1"=="/?" goto :HELP
if "%~1"=="-?" goto :HELP

:: ============================================================================
:: SINGLE INSTANCE LOCK
:: ============================================================================
set LOCKFILE=%temp%\extractMP3Adv.lock

if exist "%LOCKFILE%" (
    echo %C_WARN%[WARN]%C_RESET% A previous execution lock was found.
    echo %C_WARN%[WARN]%C_RESET% Removing stale lock and continuing...
    del "%LOCKFILE%" >nul 2>&1
)

echo %date% %time% > "%LOCKFILE%"

:: ============================================================================
:: ARGUMENT PARSING
:: ============================================================================
if "%~1"=="" (
    set INPUT=%cd%
) else (
    set INPUT=%~1
    shift
)

:ARG_LOOP
if "%~1"=="" goto :START

if /I "%~1"=="/mode:merge" set MODE=merge
if /I "%~1"=="/mode:split" set MODE=split

if /I "%~1"=="/preset:HQ"  set PRESET=HQ
if /I "%~1"=="/preset:MED" set PRESET=MED
if /I "%~1"=="/preset:LOW" set PRESET=LOW

if /I "%~1"=="/codec:mp3"  set CODEC=mp3
if /I "%~1"=="/codec:aac"  set CODEC=aac
if /I "%~1"=="/codec:opus" set CODEC=opus

echo %~1 | findstr /I "^/out:" >nul && (
    set OUTDIR=%~1
    set OUTDIR=!OUTDIR:/out:=!
    set OUTDIR=!OUTDIR:"=!
)

shift
goto :ARG_LOOP

:: ============================================================================
:: START
:: ============================================================================
:START
echo.
echo %C_INFO%===================================================%C_RESET%
echo   %APP_NAME% v%APP_VER%
echo %C_INFO%===================================================%C_RESET%
echo.

where ffmpeg >nul 2>&1 || (
    echo %C_ERR%[ERROR]%C_RESET% ffmpeg was not found in PATH
    goto :CLEAN_EXIT
)

if not exist "%INPUT%" (
    echo %C_ERR%[ERROR]%C_RESET% Invalid input path: "%INPUT%"
    goto :CLEAN_EXIT
)

set IS_DIR=false
if exist "%INPUT%\*" set IS_DIR=true

if "!IS_DIR!"=="false" (
    for %%F in ("%INPUT%") do set INPUT_BASENAME=%%~nF
)

:: ============================================================================
:: TIMESTAMP GENERATION
:: ============================================================================
for /f "tokens=1-6 delims=/:., " %%a in ("%date% %time%") do (
    set DD=%%a
    set MM=%%b
    set YYYY=%%c
    set HH=%%d
    set MN=%%e
    set SS=%%f
)
if !HH! LSS 10 set HH=0!HH!
if !MN! LSS 10 set MN=0!MN!
if !SS! LSS 10 set SS=0!SS!
set TS=!YYYY!!MM!!DD!_!HH!!MN!!SS!

:: ============================================================================
:: FILE COUNT AND MODE RESOLUTION
:: ============================================================================
set FILECOUNT=0
if "!IS_DIR!"=="true" (
    for %%F in ("%INPUT%\*.mp4") do set /a FILECOUNT+=1
) else (
    set FILECOUNT=1
)

if !FILECOUNT! EQU 1 set MODE=single

:: ============================================================================
:: CODEC SELECTION
:: ============================================================================
if "!CODEC!"=="mp3"  set ACODEC=libmp3lame& set EXT=mp3
if "!CODEC!"=="aac"  set ACODEC=aac& set EXT=m4a
if "!CODEC!"=="opus" set ACODEC=libopus& set EXT=opus

:: ============================================================================
:: PRESET → BASE BITRATE (MP3 REFERENCE)
:: ============================================================================
set BITRATE_MP3=128k
if /I "!PRESET!"=="LOW" set BITRATE_MP3=96k
if /I "!PRESET!"=="MED" set BITRATE_MP3=128k
if /I "!PRESET!"=="HQ"  set BITRATE_MP3=192k

:: ============================================================================
:: BITRATE ADJUSTMENT PER CODEC (PERCEIVED QUALITY)
:: ============================================================================
set BITRATE=!BITRATE_MP3!

if /I "!CODEC!"=="aac" (
    if "!PRESET!"=="LOW" set BITRATE=80k
    if "!PRESET!"=="MED" set BITRATE=112k
    if "!PRESET!"=="HQ"  set BITRATE=160k
)

if /I "!CODEC!"=="opus" (
    if "!PRESET!"=="LOW" set BITRATE=64k
    if "!PRESET!"=="MED" set BITRATE=80k
    if "!PRESET!"=="HQ"  set BITRATE=96k
)

:: ============================================================================
:: SINGLE MODE
:: ============================================================================
if "!MODE!"=="single" (
    echo %C_INFO%[INFO]%C_RESET% Mode: SINGLE
    if "%REMOVE_SILENCE%"=="1" echo %C_INFO%[INFO]%C_RESET% Silence removal ENABLED
    echo %C_INFO%[INFO]%C_RESET% Audio preset: !PRESET!  ^(bitrate: !BITRATE!^)

    set OUTFILE=%OUTDIR%\!TS!_!INPUT_BASENAME!.!EXT!

    if "%REMOVE_SILENCE%"=="1" (
        ffmpeg -hide_banner -loglevel error -stats ^
            -i "%INPUT%" -vn -c:a !ACODEC! -b:a !BITRATE! ^
            -af "silenceremove=stop_periods=-1:stop_duration=%SILENCE_DURATION%:stop_threshold=%SILENCE_THRESHOLD%" ^
            "!OUTFILE!"
    ) else (
        ffmpeg -hide_banner -loglevel error -stats ^
            -i "%INPUT%" -vn -c:a !ACODEC! -b:a !BITRATE! "!OUTFILE!"
    )
    goto :SUMMARY
)

:: ============================================================================
:: SPLIT MODE
:: ============================================================================
if "!MODE!"=="split" (
    echo %C_INFO%[INFO]%C_RESET% Mode: SPLIT
    if "%REMOVE_SILENCE%"=="1" echo %C_INFO%[INFO]%C_RESET% Silence removal ENABLED
    echo %C_INFO%[INFO]%C_RESET% Audio preset: !PRESET!  ^(bitrate: !BITRATE!^)

    for %%F in ("%INPUT%\*.mp4") do (
        set OUTFILE=%OUTDIR%\!TS!_%%~nF.!EXT!
        if "%REMOVE_SILENCE%"=="1" (
            ffmpeg -hide_banner -loglevel error -stats ^
                -i "%%F" -vn -c:a !ACODEC! -b:a !BITRATE! ^
                -af "silenceremove=stop_periods=-1:stop_duration=%SILENCE_DURATION%:stop_threshold=%SILENCE_THRESHOLD%" ^
                "!OUTFILE!"
        ) else (
            ffmpeg -hide_banner -loglevel error -stats ^
                -i "%%F" -vn -c:a !ACODEC! -b:a !BITRATE! "!OUTFILE!"
        )
        set OUTPUT_LIST=!OUTPUT_LIST!|!OUTFILE!
    )
    goto :SUMMARY
)

:: ============================================================================
:: MERGE MODE
:: ============================================================================
echo %C_INFO%[INFO]%C_RESET% Mode: MERGE
echo %C_INFO%[INFO]%C_RESET% Audio preset: !PRESET!  ^(bitrate: !BITRATE!^)

set TEMP=%temp%\%APP_NAME%_%TS%
set LIST=%TEMP%\list.txt
mkdir "%TEMP%" >nul
break>"%LIST%"
for %%F in ("%INPUT%\*.mp4") do echo file '%%~fF'>>"%LIST%"

set OUTFILE=%OUTDIR%\!TS!_Merged.!EXT!
ffmpeg -hide_banner -loglevel error -stats ^
    -f concat -safe 0 -i "%LIST%" -vn -c:a !ACODEC! -b:a !BITRATE! "!OUTFILE!"
set OUTPUT_LIST=!OUTFILE!

:: ============================================================================
:: SUMMARY
:: ============================================================================
:SUMMARY
echo.
echo %C_OK%==================== SUMMARY =====================%C_RESET%
echo  %C_LABEL%Mode        :%C_RESET% !MODE!
echo  %C_LABEL%Codec       :%C_RESET% !CODEC!
echo  %C_LABEL%Preset      :%C_RESET% !PRESET!  ^(bitrate: !BITRATE!^)
echo  %C_LABEL%Input       :%C_RESET% %INPUT%
echo  %C_LABEL%Output Dir  :%C_RESET% %OUTDIR%
echo.
echo  %C_LABEL%Generated Files:%C_RESET%

if "!MODE!"=="single" (
    echo    %C_OK%- !OUTFILE!%C_RESET%
) else (
    for %%O in (!OUTPUT_LIST:^|= ! ) do if not "%%O"=="" echo    %C_OK%- %%O%C_RESET%
)

echo.
echo  %C_OK%Status      : COMPLETED SUCCESSFULLY%C_RESET%
echo %C_OK%=================================================%C_RESET%

:: ============================================================================
:: CLEAN EXIT
:: ============================================================================
:CLEAN_EXIT
del "%LOCKFILE%" >nul 2>&1
exit /b

:: ============================================================================
:: HELP
:: ============================================================================
:HELP
echo.
echo %C_INFO%----------------------------------------------------------------------------
echo   extractMP3Adv   ::     Advanced audio extractor for MP4 files
echo ----------------------------------------------------------------------------%C_RESET%
echo.
echo   Extracts audio from MP4 files and converts it to MP3, AAC or OPUS.
echo   Supports single files, folder split, and merge operations.
echo   %C_OK%Long silence removal is automatically applied in SINGLE and SPLIT modes%C_RESET%
echo.
echo %C_LABEL%:: Supported inputs%C_RESET%
echo      - A single MP4 file
echo      - A folder containing multiple MP4 files
echo.
echo %C_LABEL%:: Operating modes%C_RESET%
echo      %C_OK%SINGLE%C_RESET% :: Automatic extraction from a single file
echo      %C_OK%SPLIT %C_RESET% :: One audio file per video
echo      %C_OK%MERGE %C_RESET% :: All videos merged into a single audio file
echo.
echo %C_LABEL%:: Options%C_RESET%
echo     %C_OK%/mode%C_RESET%   :: split             One audio per MP4
echo     %C_OK%/mode%C_RESET%   :: merge             Merge all MP4 files
echo.
echo     %C_OK%/codec%C_RESET%  :: mp3               MP3 output (default)
echo     %C_OK%/codec%C_RESET%  :: aac               AAC output (m4a)
echo     %C_OK%/codec%C_RESET%  :: opus              OPUS output
echo.
echo     %C_OK%/preset%C_RESET% :: HQ^|MED^|LOW        Audio quality preset
echo.
echo     %C_OK%/out%C_RESET%    :: "folder"          Output directory
echo.
echo %C_LABEL%:: Examples%C_RESET%
echo      %C_OK%extractMP3Adv video.mp4%C_RESET%
echo      %C_OK%extractMP3Adv video.mp4 /preset:LOW%C_RESET%
echo      %C_OK%extractMP3Adv D:\Videos /mode:merge /codec:opus%C_RESET%
echo      %C_OK%extractMP3Adv D:\Videos /mode:split /out:"D:\Audio"%C_RESET%
echo.
exit /b
