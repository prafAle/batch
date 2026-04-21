@echo off
setlocal EnableExtensions EnableDelayedExpansion
title extractMP3Adv - Professional Audio Extractor

:: ============================================================================
::  FILENAME:   extractMP3Adv.cmd
::  PURPOSE:    Extract audio from MP4 files with single/split/merge modes,
::               silence removal, codec-aware dynamic bitrate calculation,
::               quality presets, colored output, output directory support,
::               ffmpeg/ffprobe validation and modern CLI UI.
::  VERSION:    2026-04-21
::
::  USAGE:
::      extractMP3Adv.cmd  <input_path> [/mode:merge|split]
::                                        [/preset:HQ|MED|LOW|SIZE]
::                                        [/codec:mp3|aac|opus]
::                                        [/out:"C:\OutputFolder"]
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
:: SILENCE REMOVAL CONFIGURATION (SINGLE / SPLIT ONLY)
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
:: DEFAULTS
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
    echo %C_WARN%[WARN]%C_RESET% Previous execution lock found. Removing stale lock...
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

if /I "%~1"=="/preset:HQ"   set PRESET=HQ
if /I "%~1"=="/preset:MED"  set PRESET=MED
if /I "%~1"=="/preset:LOW"  set PRESET=LOW
if /I "%~1"=="/preset:SIZE" set PRESET=SIZE

if /I "%~1"=="/codec:mp3"   set CODEC=mp3
if /I "%~1"=="/codec:aac"   set CODEC=aac
if /I "%~1"=="/codec:opus"  set CODEC=opus

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

:: ---------------------------------------------------------------------------
:: DEPENDENCY CHECKS
:: ---------------------------------------------------------------------------
where ffmpeg >nul 2>&1 || (
    echo %C_ERR%[ERROR]%C_RESET% ffmpeg not found in PATH
    goto :CLEAN_EXIT
)

where ffprobe >nul 2>&1 || (
    echo %C_ERR%[ERROR]%C_RESET% ffprobe not found in PATH
    goto :CLEAN_EXIT
)

:: ---------------------------------------------------------------------------
:: INPUT VALIDATION
:: ---------------------------------------------------------------------------
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
:: TIMESTAMP
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
:: FILE COUNT & MODE RESOLUTION
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
if "!CODEC!"=="aac"  set ACODEC=aac&        set EXT=m4a
if "!CODEC!"=="opus" set ACODEC=libopus&    set EXT=opus

:: ============================================================================
:: STATIC BITRATE PRESETS (SINGLE / SPLIT)
:: ============================================================================
set BITRATE_STATIC=128k
if /I "!PRESET!"=="LOW" set BITRATE_STATIC=96k
if /I "!PRESET!"=="MED" set BITRATE_STATIC=128k
if /I "!PRESET!"=="HQ"  set BITRATE_STATIC=192k

if /I "!CODEC!"=="aac" (
    if "!PRESET!"=="LOW" set BITRATE_STATIC=80k
    if "!PRESET!"=="MED" set BITRATE_STATIC=112k
    if "!PRESET!"=="HQ"  set BITRATE_STATIC=160k
)

if /I "!CODEC!"=="opus" (
    if "!PRESET!"=="LOW" set BITRATE_STATIC=64k
    if "!PRESET!"=="MED" set BITRATE_STATIC=80k
    if "!PRESET!"=="HQ"  set BITRATE_STATIC=96k
)

:: ============================================================================
:: SINGLE MODE
:: ============================================================================
if "!MODE!"=="single" (
    echo %C_INFO%[INFO]%C_RESET% Mode: SINGLE
    echo %C_INFO%[INFO]%C_RESET% Audio preset: !PRESET!  ^(bitrate: !BITRATE_STATIC!^)
    if "%REMOVE_SILENCE%"=="1" echo %C_INFO%[INFO]%C_RESET% Silence removal ENABLED

    set OUTFILE=%OUTDIR%\!TS!_!INPUT_BASENAME!.!EXT!

    if "%REMOVE_SILENCE%"=="1" (
        ffmpeg -hide_banner -loglevel error -stats -threads 0 ^
            -i "%INPUT%" -vn -c:a !ACODEC! -b:a !BITRATE_STATIC! ^
            -af "silenceremove=stop_periods=-1:stop_duration=%SILENCE_DURATION%:stop_threshold=%SILENCE_THRESHOLD%" ^
            "!OUTFILE!"
    ) else (
        ffmpeg -hide_banner -loglevel error -stats -threads 0 ^
            -i "%INPUT%" -vn -c:a !ACODEC! -b:a !BITRATE_STATIC! "!OUTFILE!"
    )
    goto :SUMMARY
)

:: ============================================================================
:: SPLIT MODE
:: ============================================================================
if "!MODE!"=="split" (
    echo %C_INFO%[INFO]%C_RESET% Mode: SPLIT
    echo %C_INFO%[INFO]%C_RESET% Audio preset: !PRESET!  ^(bitrate: !BITRATE_STATIC!^)
    if "%REMOVE_SILENCE%"=="1" echo %C_INFO%[INFO]%C_RESET% Silence removal ENABLED

    for %%F in ("%INPUT%\*.mp4") do (
        set OUTFILE=%OUTDIR%\!TS!_%%~nF.!EXT!
        if "%REMOVE_SILENCE%"=="1" (
            ffmpeg -hide_banner -loglevel error -stats -threads 0 ^
                -i "%%F" -vn -c:a !ACODEC! -b:a !BITRATE_STATIC! ^
                -af "silenceremove=stop_periods=-1:stop_duration=%SILENCE_DURATION%:stop_threshold=%SILENCE_THRESHOLD%" ^
                "!OUTFILE!"
        ) else (
            ffmpeg -hide_banner -loglevel error -stats -threads 0 ^
                -i "%%F" -vn -c:a !ACODEC! -b:a !BITRATE_STATIC! "!OUTFILE!"
        )
        set OUTPUT_LIST=!OUTPUT_LIST!|!OUTFILE!
    )
    goto :SUMMARY
)

:: ============================================================================
:: MERGE MODE — DYNAMIC BITRATE ENGINE (199 MB TARGET)
:: ============================================================================
echo %C_INFO%[INFO]%C_RESET% Mode: MERGE
echo %C_INFO%[INFO]%C_RESET% Calculating total duration...

set TEMP=%temp%\%APP_NAME%_%TS%
set LIST=%TEMP%\list.txt
mkdir "%TEMP%" >nul
break>"%LIST%"

for %%F in ("%INPUT%\*.mp4") do echo file '%%~fF'>>"%LIST%"

set TOTAL_DURATION=0
for %%F in ("%INPUT%\*.mp4") do (
    for /f "tokens=1 delims=." %%D in ('
        ffprobe -v error -show_entries format^=duration -of csv^=p^=0 "%%F"
    ') do set /a TOTAL_DURATION+=%%D
)

if !TOTAL_DURATION! LEQ 0 (
    echo %C_ERR%[ERROR]%C_RESET% Failed to calculate duration.
    goto :CLEAN_EXIT
)

:: Dynamic bitrate (199 MB target)
set TARGET_MB=199
set /a BITRATE_DYNAMIC=(%TARGET_MB%*1024*8)/!TOTAL_DURATION!

:: Preset multipliers (MERGE only)
if /I "!PRESET!"=="HQ"   set /a BITRATE_DYNAMIC=BITRATE_DYNAMIC*15/10
if /I "!PRESET!"=="LOW"  set /a BITRATE_DYNAMIC=BITRATE_DYNAMIC*6/10
if /I "!PRESET!"=="SIZE" set /a BITRATE_DYNAMIC=BITRATE_DYNAMIC

if !BITRATE_DYNAMIC! GTR 320 set BITRATE_DYNAMIC=320
if !BITRATE_DYNAMIC! LSS 32  set BITRATE_DYNAMIC=32

echo %C_INFO%[INFO]%C_RESET% Dynamic bitrate: !BITRATE_DYNAMIC!k

set OUTFILE=%OUTDIR%\!TS!_Merged.!EXT!

ffmpeg -hide_banner -loglevel error -stats -threads 0 ^
    -f concat -safe 0 -i "%LIST%" -vn -c:a !ACODEC! -b:a !BITRATE_DYNAMIC!k ^
    "!OUTFILE!"

set OUTPUT_LIST=!OUTFILE!

:: ============================================================================
:: GET FILE SIZE IN MB (one decimal, comma separated)
:: Input : FILE_PATH
:: Output: FILE_SIZE_MB
:: ============================================================================
set FILE_SIZE_MB=

for %%S in ("%FILE_PATH%") do set FILE_SIZE_BYTES=%%~zS

set /a FILE_SIZE_MB_INT=FILE_SIZE_BYTES/1048576
set /a FILE_SIZE_MB_DEC=(FILE_SIZE_BYTES%%1048576)*10/1048576

set FILE_SIZE_MB=!FILE_SIZE_MB_INT!,!FILE_SIZE_MB_DEC!MB

:: ============================================================================
:: SUMMARY
:: ============================================================================
:SUMMARY
echo.
echo %C_OK%==================== SUMMARY =====================%C_RESET%
echo  %C_LABEL%Mode        :%C_RESET% !MODE!
echo  %C_LABEL%Codec       :%C_RESET% !CODEC!
if "!MODE!"=="merge" (
    echo  %C_LABEL%Preset      :%C_RESET% !PRESET!  ^(dynamic bitrate^)
) else (
    echo  %C_LABEL%Preset      :%C_RESET% !PRESET!  ^(bitrate: !BITRATE_STATIC!^)
)
echo  %C_LABEL%Input       :%C_RESET% %INPUT%
echo  %C_LABEL%Output Dir  :%C_RESET% %OUTDIR%
echo.
echo  %C_LABEL%Generated Files:%C_RESET%

if "!MODE!"=="single" (
    set FILE_PATH=!OUTFILE!
    call :GET_FILE_STATS
    set FILE_PATH=!OUTFILE!
    call :GET_FILE_STATS
    echo    %C_OK%[!FILE_SIZE_MB! !FILE_DURATION!] !OUTFILE!%C_RESET%
) else (
    for %%O in (!OUTPUT_LIST:^|= ! ) do (
        if not "%%O"=="" (
            set FILE_PATH=%%O
            call :GET_FILE_STATS
            echo    %C_OK%[\!FILE_SIZE_MB! \!FILE_DURATION!\] %%O%C_RESET%
        )
    )
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
:: GET FILE SIZE (MB) AND DURATION (HH:MM:SS)
:: Input : FILE_PATH
:: Output: FILE_SIZE_MB , FILE_DURATION
:: ============================================================================
:GET_FILE_STATS

:: --- File size ---
for %%S in ("%FILE_PATH%") do set FILE_SIZE_BYTES=%%~zS
set /a FILE_SIZE_MB_INT=FILE_SIZE_BYTES/1048576
set /a FILE_SIZE_MB_DEC=(FILE_SIZE_BYTES%%1048576)*10/1048576
set FILE_SIZE_MB=!FILE_SIZE_MB_INT!,!FILE_SIZE_MB_DEC!MB

:: --- Audio duration (seconds, integer) ---
set FILE_DURATION=
for /f "tokens=1 delims=." %%D in ('
    ffprobe -v error -show_entries format^=duration -of csv^=p^=0 "%FILE_PATH%"
') do set DURATION_SEC=%%D

:: --- Convert seconds to HH:MM:SS ---
set /a H=DURATION_SEC/3600
set /a M=(DURATION_SEC%%3600)/60
set /a S=DURATION_SEC%%60

if !H! LSS 10 set H=0!H!
if !M! LSS 10 set M=0!M!
if !S! LSS 10 set S=0!S!

set FILE_DURATION=!H!:!M!:!S!
exit /b

:: ============================================================================
:: HELP
:: ============================================================================
:HELP
echo.
echo %C_INFO%----------------------------------------------------------------------------
echo   extractMP3Adv   ::     Advanced MP4 → Audio Extractor
echo ----------------------------------------------------------------------------%C_RESET%
echo.
echo   Extracts high-quality audio from MP4 files and converts it to
echo   MP3, AAC or OPUS, with automatic mode detection and smart processing.
echo   Long silence removal is applied automatically
echo   in %C_LABEL%SINGLE%C_RESET% and %C_LABEL%SPLIT%C_RESET% modes to keep the audio fluent and natural.
echo.
echo %C_LABEL%:: Supported input%C_RESET%
echo      - A single MP4 video file
echo      - A folder containing multiple MP4 files
echo.
echo %C_LABEL%:: Operating modes (auto-detected)%C_RESET%
echo      %C_OK%SINGLE%C_RESET% :: One MP4 file to one audio file
echo      %C_OK%SPLIT %C_RESET% :: Folder to one audio file per MP4
echo      %C_OK%MERGE %C_RESET% :: Folder to all MP4 files merged into one audio file
echo.
echo   Note:
echo   - SINGLE mode is selected automatically for a single input file
echo   - MERGE requires a folder with at least two MP4 files
echo.
echo %C_LABEL%:: Audio codecs%C_RESET%
echo      %C_OK%mp3%C_RESET%   :: Universal compatibility (default)
echo      %C_OK%aac%C_RESET%   :: Better quality at lower bitrate (m4a)
echo      %C_OK%opus%C_RESET%  :: Best efficiency for speech
echo.
echo %C_LABEL%:: Audio presets%C_RESET%
echo      %C_OK%LOW%C_RESET%   :: Smaller files, lower bitrate
echo      %C_OK%MED%C_RESET%   :: Balanced quality (default)
echo      %C_OK%HQ %C_RESET%   :: Higher quality
echo      %C_OK%SIZE%C_RESET%  :: Size-based dynamic bitrate (MERGE only)
echo.
echo   Preset behavior:
echo   - In %C_LABEL%SINGLE%C_RESET% and %C_LABEL%SPLIT%C_RESET% modes:
echo     presets map to fixed, speech-optimized bitrates
echo   - In %C_LABEL%MERGE%C_RESET% mode:
echo     bitrate is calculated dynamically to stay below ~199 MB
echo.
echo %C_LABEL%:: Command-line options%C_RESET%
echo     %C_OK%/mode:C_RESET%%C_OK%split%C_RESET%      Force split mode
echo     %C_OK%/mode:C_RESET%%C_OK%merge%C_RESET%      Force merge mode
echo.
echo     %C_OK%/codec:C_RESET%%C_OK%mp3%C_RESET%     MP3 output (default)
echo     %C_OK%/codec:C_RESET%%C_OK%aac%C_RESET%     AAC output (m4a)
echo     %C_OK%/codec:C_RESET%%C_OK%opus%C_RESET%     OPUS output
echo.
echo     %C_OK%/preset:C_RESET%%C_OK%HQ^|MED^|LOW^|SIZE%C_RESET%    Audio quality preset
echo.
echo     %C_OK%/out:C_RESET%%C_OK%"folder"%C_RESET%       Output directory
echo.
echo %C_LABEL%:: Technical notes%C_RESET%
echo   - Uses FFmpeg and FFprobe (must be available in PATH)
echo   - Uses multi-threaded encoding (-threads 0)
echo   - Console logging only (no log files created)
echo   - ANSI-colored output (Windows 10/11 recommended)
echo.

echo %C_LABEL%:: Usage examples%C_RESET%
echo.
echo   %C_OK%:: Single file examples%C_RESET%
echo      extractMP3Adv video.mp4
echo      extractMP3Adv video.mp4 /preset:LOW
echo      extractMP3Adv video.mp4 /codec:opus
echo.
echo   %C_OK%:: Split mode (one audio per video)%C_RESET%
echo      extractMP3Adv D:\Videos /mode:split
echo      extractMP3Adv D:\Videos /mode:split /preset:HQ
echo      extractMP3Adv D:\Videos /mode:split /codec:aac /out:"D:\Audio"
echo.
echo   %C_OK%:: Merge mode (dynamic bitrate)%C_RESET%
echo      extractMP3Adv D:\Videos /mode:merge
echo      extractMP3Adv D:\Videos /mode:merge /preset:HQ
echo.
echo   %C_OK%:: Size-optimized merge (target ~199 MB)%C_RESET%
echo      extractMP3Adv D:\Videos /mode:merge /preset:SIZE
echo      extractMP3Adv D:\Videos /mode:merge /preset:SIZE /codec:opus
echo.
echo   %C_OK%:: Advanced combinations%C_RESET%
echo      extractMP3Adv D:\Videos /mode:merge /codec:opus /preset:HQ
echo      extractMP3Adv D:\Videos /mode:merge /codec:aac /preset:SIZE /out:"D:\Audio"
echo.
exit /b
