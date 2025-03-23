@echo off
setlocal EnableDelayedExpansion

:: Initialize variables
set "ERROR_COUNT=0"
set "SUCCESS_COUNT=0"
set "total_plugins=0"

:: Get current date and time for backup folder
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "YYYY=%datetime:~0,4%"
set "MM=%datetime:~4,2%"
set "DD=%datetime:~6,2%"
set "HH=%datetime:~8,2%"
set "Min=%datetime:~10,2%"

:: Convert to 12-hour format for display
set /a "HH12=1%HH% %% 100"
if %HH12% gtr 12 set /a "HH12-=12"
if %HH12% equ 0 set "HH12=12"
if %HH% geq 12 (set "AMPM=PM") else (set "AMPM=AM")

:: Set paths
pushd "%~dp0"
set "SCRIPT_DIR=%CD%"
popd
set "SOURCE_DIR=%SCRIPT_DIR%\source"
set "INCLUDE_DIR=%SCRIPT_DIR%\include"
set "COMPILED_DIR=%SCRIPT_DIR%\compiled"
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "BACKUP_DIR=%SCRIPT_DIR%\backup\%YYYY%-%MM%-%DD%_%HH12%-%Min%-%AMPM%"

:: Header
echo === NansSurf Plugin Compiler ===
echo.

:: Create directories if they don't exist
if not exist "%COMPILED_DIR%" mkdir "%COMPILED_DIR%" 2>nul
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" 2>nul
if not exist "%SOURCE_DIR%" mkdir "%SOURCE_DIR%" 2>nul
if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%" 2>nul

:: Backup existing plugins if they exist
if exist "%COMPILED_DIR%\*.smx" (
    echo Creating backup of existing files...
    
    :: Create backup subdirectories
    if not exist "%BACKUP_DIR%\compiled" mkdir "%BACKUP_DIR%\compiled" 2>nul
    if not exist "%BACKUP_DIR%\source" mkdir "%BACKUP_DIR%\source" 2>nul
    if not exist "%BACKUP_DIR%\include" mkdir "%BACKUP_DIR%\include" 2>nul
    
    :: Copy compiled plugins
    xcopy /Y "%COMPILED_DIR%\*.smx" "%BACKUP_DIR%\compiled\" > nul 2>&1
    
    :: Copy source files if they exist
    if exist "%SOURCE_DIR%\*.sp" (
        xcopy /Y "%SOURCE_DIR%\*.sp" "%BACKUP_DIR%\source\" > nul 2>&1
    )
    
    :: Copy include files if they exist
    if exist "%INCLUDE_DIR%\*.inc" (
        xcopy /Y "%INCLUDE_DIR%\*.inc" "%BACKUP_DIR%\include\" > nul 2>&1
    )
    
    echo Backup created: %BACKUP_DIR%
    
    :: Clean compiled directory
    del /Q "%COMPILED_DIR%\*.smx" > nul 2>&1
)

:: Create log file name
set "LOG_FILE=%LOG_DIR%\compiled-%YYYY%-%MM%-%DD%_%HH12%-%Min%-%AMPM%.md"

:: Set SourceMod path
set "SOURCEMOD_PATH=K:\Program Files\sourcemod"
set "SOURCEMOD_DIR=%SOURCEMOD_PATH%"
set "COMPILER=%SOURCEMOD_DIR%\addons\sourcemod\scripting\spcomp.exe"

echo === Build Configuration ===
echo SourceMod: %SOURCEMOD_PATH%
echo Compiler: %COMPILER%
echo Source Dir: %SOURCE_DIR%
echo Include Dir: %INCLUDE_DIR%
echo Output Dir: %COMPILED_DIR%
echo Backup Dir: %BACKUP_DIR%
echo Log File: %LOG_FILE%
echo.

:: Verify compiler exists
if not exist "%COMPILER%" (
    echo Error: Compiler not found at %COMPILER%
    echo Please check your SourceMod installation.
    exit /b 1
)

:: Verify source files exist
if not exist "%SOURCE_DIR%\*.sp" (
    echo Error: No source files found!
    echo Please add .sp files to: %SOURCE_DIR%
    exit /b 1
)

:: Add compiler to PATH
echo %PATH% | findstr /i /c:"%SOURCEMOD_DIR%\addons\sourcemod\scripting" > nul
if errorlevel 1 (
    set "PATH=%PATH%;%SOURCEMOD_DIR%\addons\sourcemod\scripting"
    echo Added compiler to PATH
)

:: Create markdown log file
(
echo # 🔧 SourceMod Plugin Compilation Log
echo.
echo ## 📊 Build Information
echo.
echo ^| Category ^| Value ^|
echo ^|----------|--------|
echo ^| 📅 Date ^| %MM%/%DD%/%YYYY% ^|
echo ^| ⏰ Time ^| %HH12%:%Min% %AMPM% ^|
echo ^| 🔨 Compiler ^| SourcePawn 1.12.0.7195 ^|
echo.
echo ## 🛠️ Environment
echo.
echo ^| Directory ^| Path ^|
echo ^|-----------|------|
echo ^| 📁 Source ^| %SOURCE_DIR% ^|
echo ^| 📚 Include ^| %INCLUDE_DIR% ^|
echo ^| 📦 Output ^| %COMPILED_DIR% ^|
echo ^| 💾 Backup ^| %BACKUP_DIR% ^|
echo ^| 🔧 SourceMod ^| %SOURCEMOD_DIR% ^|
echo.
echo ## 📝 Compilation Results
echo.
) > "%LOG_FILE%"

:: Copy include files
echo === Copying Include Files ===
if exist "%INCLUDE_DIR%\*.inc" (
    echo Copying include files to SourceMod...
    (
    echo ### 📚 Include Files
    echo ```plaintext
    ) >> "%LOG_FILE%"
    xcopy /Y "%INCLUDE_DIR%\*.inc" "%SOURCEMOD_DIR%\addons\sourcemod\scripting\include\" >> "%LOG_FILE%" 2>&1
    (
    echo ```
    echo.
    ) >> "%LOG_FILE%"
)

:: Compile plugins
echo === Starting Compilation ===
echo.

:: Compile each plugin
for %%f in ("%SOURCE_DIR%\*.sp") do (
    echo Compiling: %%~nxf
    (
    echo ### 🔨 %%~nxf
    echo ```plaintext
    ) >> "%LOG_FILE%"
    
    "%COMPILER%" "%%~f" -i:"%INCLUDE_DIR%" -o:"%COMPILED_DIR%\%%~nf.smx" >> "%LOG_FILE%" 2>&1
    
    echo ```>> "%LOG_FILE%"
    
    if !ERRORLEVEL! equ 0 (
        echo ✓ Success: %%~nf.smx
        set /a SUCCESS_COUNT+=1
        (
        echo ✅ **Status:** Compilation successful
        echo - 📦 **Output:** %COMPILED_DIR%\%%~nf.smx
        echo - 📊 **Size:** %%~zf bytes
        echo - 💾 **Backup:** %BACKUP_DIR%\compiled\%%~nf.smx
        ) >> "%LOG_FILE%"
    ) else (
        echo ✗ Failed: %%~nf
        set /a ERROR_COUNT+=1
        (
        echo ❌ **Status:** Compilation failed
        ) >> "%LOG_FILE%"
    )
    echo.>> "%LOG_FILE%"
    set /a total_plugins+=1
)

:: Summary
(
echo ## 📊 Summary
echo.
echo ^| Category ^| Count ^|
echo ^|----------|--------|
echo ^| Total Plugins ^| %total_plugins% ^|
echo ^| ✅ Successful ^| %SUCCESS_COUNT% ^|
echo ^| ❌ Failed ^| %ERROR_COUNT% ^|
echo.
echo ## 📋 Next Steps
echo 1. 📦 Check compiled plugins in `%COMPILED_DIR%`
echo 2. 🔍 Review any warnings or errors above
echo 3. 🎮 Test the plugins in your CS2 server
echo 4. 💾 Backup available in `%BACKUP_DIR%`:
echo    - Compiled plugins: `%BACKUP_DIR%\compiled`
echo    - Source files: `%BACKUP_DIR%\source`
echo    - Include files: `%BACKUP_DIR%\include`
echo.
) >> "%LOG_FILE%"

echo === Compilation Summary ===
echo Total: %total_plugins%
echo Success: %SUCCESS_COUNT%
echo Failed: %ERROR_COUNT%
echo.
echo Log: %LOG_FILE%
echo Backup: %BACKUP_DIR%
echo.

if %ERROR_COUNT% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)