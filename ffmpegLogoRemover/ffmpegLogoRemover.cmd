@echo off
echo    ________________
echo  > ffmpeg logo remover
echo.
setlocal enabledelayedexpansion

:: ============================================================
:: DEFAULT CONFIGURATION
:: ============================================================
set "X1=862" & set "Y1=626" & set "W1=227" & set "H1=31" & set "T1=23.5"
set "X2=1102" & set "Y2=661" & set "W2=133" & set "H2=16"
set "OFFSET=3"
set "VLC_PATH=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "INPUT_FILE="

:: ============================================================
:: INPUT PARAMETER ANALYSIS
:: ============================================================
if "%~1" == "" goto :usage

:parse_loop
if "%~1" == "" goto :validate
set "PARAM=%~1"
if /I "!PARAM!" == "/?" goto :usage
if /I "!PARAM!" == "/help" goto :usage
if /I "!PARAM!" == "/T1"   (set "T1=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/CORR" (set "OFFSET=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/X1"   (set "X1=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/Y1"   (set "Y1=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/W1"   (set "W1=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/H1"   (set "H1=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/X2"   (set "X2=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/Y2"   (set "Y2=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/W2"   (set "W2=%~2" & shift & shift & goto :parse_loop)
if /I "!PARAM!" == "/H2"   (set "H2=%~2" & shift & shift & goto :parse_loop)

if not defined INPUT_FILE (
    set "INPUT_FILE=%~f1"
    set "FILE_DIR=%~dp1"
    set "FILE_NAME=%~n1"
    set "FILE_EXT=%~x1"
)
shift
goto :parse_loop

:validate
if not defined INPUT_FILE goto :usage
where ffmpeg >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERRORE] FFmpeg not found. Download it from https://ffmpeg.org/
    exit /b 1
)
if not exist "!INPUT_FILE!" (
    echo [ERRORE] File not found: "!INPUT_FILE!"
    exit /b 1
)

:: ============================================================
:: OUTPUT FILE MANAGEMENT AND DUPLICATES
:: ============================================================
set "BASE_OUT=!FILE_DIR!!FILE_NAME!-LogoRemoved"
set "OUTPUT_FILE=!BASE_OUT!!FILE_EXT!"

if exist "!OUTPUT_FILE!" (
    echo [WARNING] The file already exists: "!OUTPUT_FILE!"
    echo.
	echo Options:
	echo [O] Overwrite
	echo [N] New Version
	echo [C] Cancel
	choice /C ONC /N /M "Select option (O/N/C): "

    if errorlevel 3 (
        echo.
        echo. & echo [INFO] Elaboration cancelled. & exit /b 0
        exit /b 0
    )
    if errorlevel 2 (
        set "FF_OVERWRITE=-n"
        goto :generate_version
    )
    if errorlevel 1 (
        set "FF_OVERWRITE=-y"
        echo. & echo [INFO] The file will be overwritten.
        goto :process
    )
) else (
    set "FF_OVERWRITE=-y"
    goto :process
)

:generate_version
set /a i=2
:check_version_loop
set "OUTPUT_FILE=!BASE_OUT!-!i!!FILE_EXT!"
if exist "!OUTPUT_FILE!" (
    set /a i+=1
    goto :check_version_loop
)
echo. & echo [INFO] Version creation: "!OUTPUT_FILE!"

:process
:: ============================================================
:: COORDINATES CALCULATION AND EXECUTION
:: ============================================================
set /a X1_C=X1-OFFSET, Y1_C=Y1-OFFSET, W1_C=W1+(OFFSET*2), H1_C=H1+(OFFSET*2)
set /a X2_C=X2-OFFSET, Y2_C=Y2-OFFSET, W2_C=W2+(OFFSET*2), H2_C=H2+(OFFSET*2)

echo.
echo Source file: "!INPUT_FILE!"
echo Configuration: OFFSET=!OFFSET!px ^| T1=!T1!s
echo.

ffmpeg -i "!INPUT_FILE!" -vf "delogo=x=%X1_C%:y=%Y1_C%:w=%W1_C%:h=%H1_C%:enable='between(t,0,%T1%)',delogo=x=%X2_C%:y=%Y2_C%:w=%W2_C%:h=%H2_C%:enable='gt(t,%T1%)'" -c:a copy %FF_OVERWRITE% "!OUTPUT_FILE!"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo [OK] Operation completed successfully!
    echo [OK] Output: "!OUTPUT_FILE!"
    echo ============================================================
    echo.
    echo Do you want to view the file generated with VLC now?
    choice /C YN /N /M "[Y] Yes, [N] No: "

    if errorlevel 2 (
        echo [INFO] Script close.
    ) else if errorlevel 1 (
        if exist "!VLC_PATH!" (
            echo [INFO] Opening VLC...
            start "" "!VLC_PATH!" "!OUTPUT_FILE!"
        ) else (
            echo [ERRORE] VLC not found in: "!VLC_PATH!"
        )
    )
) else (
    echo. & echo [ERRORE] FFmpeg processing failed.
)

exit /b

:usage
echo.
echo VIDEO LOGO REMOVAL (FFmpeg-based)
echo.
echo SYNTAX:
echo   VLC-LOGO "input_file" [/CORR value] [/T1 seconds] [Coordinates]
echo.
echo PARAMETERS:
echo   input_file      Video file path (use quotes if path contains spaces).
echo   /CORR           Pixel correction value (e.g., 1 expands area by 1px).
echo   /T1             Logo position change time (Default: 23.5).
echo.
echo COORDINATES (Optional - override defaults):
echo   /X1, /Y1, /W1, /H1   Initial area (from 0 to T1)
echo   /X2, /Y2, /W2, /H2   Final area (from T1 onwards)
echo.
echo EXAMPLES:
echo   1. Standard usage with default values:
echo      vlc-logo-cmd "C:\Video\Lecture.mp4"
echo.
echo   2. Usage with 1-pixel correction (recommended for clean edges):
echo      vlc-logo-cmd "Video.mp4" /CORR 1
echo.
echo   3. Changing switch time and first area coordinates:
echo      vlc-logo-cmd "Video.mp4" /T1 15.0 /X1 800 /Y1 600
echo.
echo   4. Example using default values with all parameters explicitly specified:
echo      vlc-logo-cmd "C:\Video.mp4" /T1 23.5 /CORR 0 /X1 862 /Y1 626 /W1 227 /H1 31 /X2 1102 /Y2 661 /W2 133 /H2 16
echo        - "C:\Video.mp4": File to process (use quotes for spaces).
echo        - /T1 23.5: At 23.5 seconds the logo changes position.
echo        - /CORR 0: No area expansion (uses exact coordinates).
echo        - /X1 862 /Y1 626 /W1 227 /H1 31: Initial area (Start -> 23.5s).
echo        - /X2 1102 /Y2 661 /W2 133 /H2 16: Final area (23.5s -> End).
echo      Default values are for NotebookLM "Overview video"
echo.
exit /b 0
