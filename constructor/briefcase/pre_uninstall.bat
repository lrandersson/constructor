rem Assign INSTDIR and normalize the path
set "INSTDIR=%~dp0.."
for %%I in ("%INSTDIR%") do set "INSTDIR=%%~fI"

set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

rem Recreate an empty payload tar. This file was deleted during installation but the
rem MSI installer expects it to exist.
type nul > "%PAYLOAD_TAR%"
if errorlevel 1 (
  echo [ERROR] Failed to create "%PAYLOAD_TAR%"
  exit /b %errorlevel%
)

rem "%CONDA_EXE%" menuinst --prefix "%BASE_PATH%" --remove
rem if errorlevel 1 (
rem     echo [ERROR] %CONDA_EXE% failed with exit code %errorlevel%.
rem     exit /b %errorlevel%
rem )

if defined PREUNINSTALL_LOG (
  set "LOG=%PREUNINSTALL_LOG%"
) else (
  set "LOG=%TEMP%\constructor-preuninstall.log"
)

"%CONDA_EXE%" constructor uninstall --prefix "%BASE_PATH%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"

if not "%RC%"=="0" (
  echo [ERROR] %CONDA_EXE% failed with exit code %RC%.
  exit /b %RC%
)