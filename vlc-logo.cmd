@echo off
echo    _______________
echo  > VLC remove logo
echo.
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIGURAZIONE VALORI PREDEFINITI
:: ============================================================
set "X1=862" & set "Y1=626" & set "W1=227" & set "H1=31" & set "T1=23.5"
set "X2=1102" & set "Y2=661" & set "W2=133" & set "H2=16"
set "OFFSET=3"
set "VLC_PATH=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "INPUT_FILE="

:: ============================================================
:: ANALISI PARAMETRI DI INPUT
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
    echo [ERRORE] FFmpeg non trovato. Scaricalo da https://ffmpeg.org/
    exit /b 1
)
if not exist "!INPUT_FILE!" (
    echo [ERRORE] File non trovato: "!INPUT_FILE!"
    exit /b 1
)

:: ============================================================
:: GESTIONE FILE DI OUTPUT E DUPLICATI
:: ============================================================
set "BASE_OUT=!FILE_DIR!!FILE_NAME!-noLogoNotebookLM"
set "OUTPUT_FILE=!BASE_OUT!!FILE_EXT!"

if exist "!OUTPUT_FILE!" (
    echo [ATTENZIONE] Il file esiste gia': "!OUTPUT_FILE!"
    echo.
	echo Opzioni:
	echo [S] Sovrascrivere
	echo [N] Nuova Versione
	echo [A] Annulla
	choice /C SNA /N /M "Seleziona opzione (S/N/A): "

    if errorlevel 3 (
        echo.
        echo. & echo [INFO] Operazione annullata. & exit /b 0
        exit /b 0
    )
    if errorlevel 2 (
        set "FF_OVERWRITE=-n"
        goto :generate_version
    )
    if errorlevel 1 (
        set "FF_OVERWRITE=-y"
        echo. & echo [INFO] Il file sara' sovrascritto.
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
echo. & echo [INFO] Creazione versione: "!OUTPUT_FILE!"

:process
:: ============================================================
:: CALCOLO COORDINATE E ESECUZIONE
:: ============================================================
set /a X1_C=X1-OFFSET, Y1_C=Y1-OFFSET, W1_C=W1+(OFFSET*2), H1_C=H1+(OFFSET*2)
set /a X2_C=X2-OFFSET, Y2_C=Y2-OFFSET, W2_C=W2+(OFFSET*2), H2_C=H2+(OFFSET*2)

echo.
echo Elaborazione: "!INPUT_FILE!"
echo Configurazione: OFFSET=!OFFSET!px ^| T1=!T1!s
echo.

ffmpeg -i "!INPUT_FILE!" -vf "delogo=x=%X1_C%:y=%Y1_C%:w=%W1_C%:h=%H1_C%:enable='between(t,0,%T1%)',delogo=x=%X2_C%:y=%Y2_C%:w=%W2_C%:h=%H2_C%:enable='gt(t,%T1%)'" -c:a copy %FF_OVERWRITE% "!OUTPUT_FILE!"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo [OK] Operazione completata con successo!
    echo [OK] Output: "!OUTPUT_FILE!"
    echo ============================================================
    echo.
    echo Vuoi visualizzare il file generato con VLC ora?
    choice /C SN /N /M "[S] Si, [N] No: "

    if errorlevel 2 (
        echo [INFO] Chiusura script.
    ) else if errorlevel 1 (
        if exist "!VLC_PATH!" (
            echo [INFO] Apertura VLC in corso...
            start "" "!VLC_PATH!" "!OUTPUT_FILE!"
        ) else (
            echo [ERRORE] VLC non trovato in: "!VLC_PATH!"
        )
    )
) else (
    echo. & echo [ERRORE] Elaborazione FFmpeg fallita.
)

exit /b

:usage
echo.
echo RIMOZIONE LOGO VIDEO (Basato su FFmpeg)
echo.
echo SINTASSI:
echo   VLC-LOGO "file_input" [/CORR valore] [/T1 secondi] [Coordinate]
echo.
echo PARAMETRI:
echo   file_input      Percorso del video (usare virgolette se ci sono spazi).
echo   /CORR           Valore di correzione pixel (es: 1 espande l'area di 1px).
echo   /T1             Tempo di cambio posizione logo (Default: 23.5).
echo.
echo COORDINATE (Opzionali - sovrascrivono i default):
echo   /X1, /Y1, /W1, /H1   Area iniziale (da 0 a T1)
echo   /X2, /Y2, /W2, /H2   Area finale (da T1 in poi)
echo.
echo ESEMPI:
echo   1. Uso standard con valori predefiniti:
echo      vlc-logo-cmd "C:\Video\Lezione.mp4"
echo.
echo   2. Uso con correzione di 1 pixel (consigliato per bordi puliti):
echo      vlc-logo-cmd "Video.mp4" /CORR 1
echo.
echo   3. Cambio del tempo di switch e coordinate prima area:
echo      vlc-logo-cmd "Video.mp4" /T1 15.0 /X1 800 /Y1 600
echo.
echo   4. Esempio che usa i valori predefiniti con tutti i parametri esplicitati:
echo      vlc-logo-cmd "C:\Video.mp4" /T1 23.5 /CORR 0 /X1 862 /Y1 626 /W1 227 /H1 31 /X2 1102 /Y2 661 /W2 133 /H2 16
echo        - "C:\Video.mp4": File da elaborare (con virgolette per spazi).
echo        - /T1 23.5: Al secondo 23.5 il logo cambia posizione.
echo        - /CORR 0: Nessuna espansione dell'area (usa coordinate esatte).
echo        - /X1 862 /Y1 626 /W1 227 /H1 31: Area iniziale (Inizio -^> 23.5s).
echo        - /X2 1102 /Y2 661 /W2 133 /H2 16: Area finale (23.5s -^> Fine).
echo      i valori predefiniti sono per "Overview video" di NotebookLM
echo.
exit /b 0
