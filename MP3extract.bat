@cls
@echo off
echo ==================================================
echo               MP4 to MP3 CONVERTER
echo ==================================================
echo.
setlocal enabledelayedexpansion

:: Debug mode flag - set to "true" for detailed output
set "debugging=false"

:: =======================================================
:: DEPENDENCY CHECK - Verify FFmpeg/FFprobe are available
:: =======================================================
where ffmpeg >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] FFmpeg not found! Please download from https://ffmpeg.org/
    echo [ERROR] Ensure ffmpeg.exe and ffprobe.exe are in system PATH
    pause
    exit /b 1
)

where ffprobe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] FFprobe not found! This is part of FFmpeg package.
    echo [ERROR] Reinstall FFmpeg to get ffprobe.exe
    pause
    exit /b 1
)

:: =======================================================
:: GENERATE YYYYMMDD_hhmmss TIMESTAMP and OUTPUT FILENAME 
:: =======================================================
if "%debugging%"=="true" echo __________________________________________________Generating output filename
for /f "tokens=1-6 delims=/:., " %%a in ("%date% %time%") do (
    set bYYYY=%%c
    set bMM=%%b
    set bDD=%%a
    set bHH=%%d
    set bMin=%%e
    set bSec=%%f
)

:: Ensure all values have 2 digits
if %bMM% lss 10 set bMM=0%bMM%
if %bDD% lss 10 set bDD=0%bDD%
if %bHH% lss 10 set bHH=0%bHH%
if %bMin% lss 10 set bMin=0%bMin%
if %bSec% lss 10 set bSec=0%bSec%

set "bTIMESTAMP=%bYYYY%%bMM%%bDD%_%bHH%%bMin%%bSec%"

:: Output filename with timestamp
set "bOutput_FILE=%bTIMESTAMP%_source.mp3"

if "%debugging%"=="true" echo __________________________________________________ - %bOutput_FILE%
if "%debugging%"=="true" pause

:: ==============================================================
::    AUDIO MERGE FOR NOTEBOOKLM %bYYYY%-%bMM%-%bDD% %bHH%:%bMin%:%bSec%
:: ==============================================================

:: Configuration paths
set "MP4_SOURCE_DIR=mp4b"
set "TEMP_DIR=%tmp%\%bTIMESTAMP%_audio_merge"
set "LIST_FILE=%TEMP_DIR%\%bTIMESTAMP%_list.txt"

if "%debugging%"=="true" echo __________________________________________________Configuration paths
if "%debugging%"=="true" echo __________________________________________________ - %MP4_SOURCE_DIR%
if "%debugging%"=="true" echo __________________________________________________ - %TEMP_DIR%
if "%debugging%"=="true" echo __________________________________________________ - %LIST_FILE%

:: Create temporary directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Check if MP4 source directory exists
if not exist "%MP4_SOURCE_DIR%" (
    echo [ERROR] Directory "%MP4_SOURCE_DIR%" not found!
    echo [INFO]  Create a folder named "mp4b" and place your MP4 files in it
    pause
    exit /b 1
)

:: Check if there are MP4 files in the directory
dir "%MP4_SOURCE_DIR%\*.mp4" >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] No MP4 files found in "%MP4_SOURCE_DIR%\"
    echo [INFO]  Please add MP4 files to the mp4b folder
    pause
    exit /b 1
)

:: Calculate total size of MP4 files
set total_size=0
for %%I in ("%MP4_SOURCE_DIR%\*.mp4") do (
    set /a total_size+=%%~zI
)
set /a total_size_mb=!total_size!/1048576

echo ==================================================
echo                   MP4 FILE ANALYSIS
echo ==================================================
echo    Date and Time:       %bYYYY%-%bMM%-%bDD% %bHH%:%bMin%:%bSec%
echo    Source Directory:    %MP4_SOURCE_DIR%
echo    Total Size:          !total_size_mb!MB
echo.

:: Calculate total duration using ffprobe
set total_duration=0
for %%I in ("%MP4_SOURCE_DIR%\*.mp4") do (
    for /f "tokens=*" %%D in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%%I" 2^>^&1') do (
        set /a total_duration+=%%D
    )
)

:: Calculate optimal bitrate (target 199MB)
if %total_duration% equ 0 (
    echo [ERROR] Could not calculate total duration of MP4 files
    echo [INFO]  Ensure all MP4 files have valid audio streams
    pause
    exit /b 1
)

set /a target_bitrate=(199*1024*8)/!total_duration!
if !target_bitrate! gtr 128 set target_bitrate=128
if !target_bitrate! lss 32 set target_bitrate=32

:: Calculate duration in minutes
set /a total_minutes=!total_duration!/60
set /a total_seconds=!total_duration!%%60

echo Total Duration: !total_duration! seconds (!total_minutes!m !total_seconds!s)
echo Calculated Bitrate: !target_bitrate!kbps
echo.

:: Create file list for ffmpeg with correct paths
echo Creating file list for merge...
break > "%LIST_FILE%"
for %%I in ("%MP4_SOURCE_DIR%\*.mp4") do (
    echo file '%%~fI' >> "%LIST_FILE%"
)

echo MP4 files found:
dir "%MP4_SOURCE_DIR%\*.mp4" /b /on
echo.

:: Verify the list was created correctly
if "%debugging%"=="true" (
    echo List contents:
    type "%LIST_FILE%"
    echo.
)

:: Execute merge
echo Merging files at !target_bitrate!kbps...
echo This may take several minutes depending on file sizes...
echo.

ffmpeg -f concat -safe 0 -i "%LIST_FILE%" -b:a !target_bitrate!k -hide_banner -stats "%TEMP_DIR%\temp_merged.mp3"

if errorlevel 1 (
    echo [ERROR] FFmpeg processing failed!
    echo [INFO]  Check if MP4 files contain valid audio streams
    goto :cleanup
)

if exist "%TEMP_DIR%\temp_merged.mp3" (
    :: Move the merged file to current directory
    move "%TEMP_DIR%\temp_merged.mp3" "%bOutput_FILE%" >nul 2>nul
    
    :: Verify final file size
    for %%I in ("%bOutput_FILE%") do (
        set /a final_size_mb=%%~zI/1048576
    )
    
    echo.
    echo ==================================================
    echo                 MERGE COMPLETED!
    echo ==================================================
    echo Output File:    %bOutput_FILE%
    echo File Size:      !final_size_mb!MB
    echo Bitrate:        !target_bitrate!kbps
    echo Duration:       !total_minutes!m !total_seconds!s
    echo Timestamp:      %bTIMESTAMP%
    echo __________________________________________________
    echo.
) else (
    echo [ERROR] Merge operation failed!
    echo [INFO]  Check temporary directory: %TEMP_DIR%
)

:cleanup
:: Cleanup temporary files
if exist "%TEMP_DIR%" (
    if "%debugging%"=="false" (
        del "%TEMP_DIR%\*" /q >nul 2>nul
        rd "%TEMP_DIR%" >nul 2>nul
    ) else (
        echo [DEBUG] Temporary directory preserved: %TEMP_DIR%
    )
)
