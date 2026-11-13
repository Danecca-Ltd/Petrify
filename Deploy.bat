@echo off
REM ============================================================
REM Petrify - deploy the add-in to Fusion
REM Double-click this file to copy Petrify.bundle into ApplicationPlugins.
REM robocopy overwrites in place and never deletes the destination first.
REM
REM Before v2.0.0 the add-in was called Shrinkwrap. Its old Shrinkwrap.bundle
REM uses the same button IDs, so it is removed here: with both loaded, every
REM click would run twice.
REM ============================================================

setlocal

set "SCRIPT_DIR=%~dp0"
set "PLUGINS=%APPDATA%\Autodesk\ApplicationPlugins"
set "SOURCE_PATH=%SCRIPT_DIR%Petrify.bundle"
set "DEPLOY_PATH=%PLUGINS%\Petrify.bundle"
set "LEGACY_PATH=%PLUGINS%\Shrinkwrap.bundle"

if not exist "%SOURCE_PATH%" (
    echo ERROR: Source bundle not found: %SOURCE_PATH%
    goto :end
)

echo Source:      %SOURCE_PATH%
echo Destination: %DEPLOY_PATH%
echo.

REM /E include subdirs  /IS /IT overwrite same/tweaked files  /XD __pycache__
robocopy "%SOURCE_PATH%" "%DEPLOY_PATH%" /E /IS /IT /XD __pycache__ /NFL /NDL /NJH /NJS /NP >NUL
if errorlevel 8 (
    echo ERROR: Copy failed. The previous install was not deleted.
    goto :end
)
echo Deployed Petrify.

if exist "%LEGACY_PATH%" (
    rmdir /S /Q "%LEGACY_PATH%"
    if exist "%LEGACY_PATH%" (
        echo WARNING: Could not remove the old %LEGACY_PATH%. Close Fusion and delete it by hand.
    ) else (
        echo Removed the old Shrinkwrap add-in.
    )
)

echo.
echo Restart Fusion to load Petrify.

:end
echo.
pause
