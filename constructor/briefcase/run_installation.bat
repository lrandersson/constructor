@echo on
setlocal

set "SCRIPT_DIR=%~dp0"

rem Determine INSTDIR by locating the conda exe relative to this script
if exist "%SCRIPT_DIR%\{{ conda_exe_name }}" (
  set "INSTDIR=%SCRIPT_DIR%"
) else if exist "%SCRIPT_DIR%..\{{ conda_exe_name }}" (
  set "INSTDIR=%SCRIPT_DIR%.."
) else (
  echo [ERROR] Cannot locate {{ conda_exe_name }} relative to script dir: "%SCRIPT_DIR%"
  echo SCRIPT=%~f0
  echo CWD=%CD%
  dir "%SCRIPT_DIR%"
  exit /b 3
)

for %%I in ("%INSTDIR%") do set "INSTDIR=%%~fI"

set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

if defined POSTINSTALL_LOG (
  set "LOG=%POSTINSTALL_LOG%"
) else (
  set "LOG=%TEMP%\constructor-postinstall.log"
)

echo ==== run_installation start ==== >> "%LOG%"
echo SCRIPT=%~f0 >> "%LOG%"
echo CWD=%CD% >> "%LOG%"
echo INSTDIR=%INSTDIR% >> "%LOG%"
echo BASE_PATH=%BASE_PATH% >> "%LOG%"
echo CONDA_EXE=%CONDA_EXE% >> "%LOG%"
echo PAYLOAD_TAR=%PAYLOAD_TAR% >> "%LOG%"

echo Unpacking payload...
rem "%CONDA_EXE%" constructor extract --prefix "%INSTDIR%" --tar-from-stdin < "%PAYLOAD_TAR%" >> "%LOG%" 2>&1
"%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-tarball < "%PAYLOAD_TAR%" >> "%LOG%" 2>&1
if errorlevel 1 ( type "%LOG%" & exit /b %errorlevel% )

rem "%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs >> "%LOG%" 2>&1
"%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs >> "%LOG%" 2>&1
if errorlevel 1 ( type "%LOG%" & exit /b %errorlevel% )

if not exist "%BASE_PATH%\" (
    echo [ERROR] base not created: "%BASE_PATH%" >> "%LOG%"
    dir "%INSTDIR%" >> "%LOG%"
    dir "%INSTDIR%\.." >> "%LOG%"
    type "%LOG%"
    exit /b 2
)

set CONDA_PROTECT_FROZEN_ENVS=0
set "CONDA_ROOT_PREFIX=%BASE_PATH%"
set CONDA_SAFETY_CHECKS=disabled
set CONDA_EXTRA_SAFETY_CHECKS=no
set "CONDA_PKGS_DIRS=%BASE_PATH%\pkgs"

"%CONDA_EXE%" install --offline --file "%BASE_PATH%\conda-meta\initial-state.explicit.txt" -yp "%BASE_PATH%"
if errorlevel 1 exit /b %errorlevel%

rem Delete the payload to save disk space.
rem A truncated placeholder of 0 bytes is recreated during uninstall
rem because MSI expects the file to be there to clean the registry.
del "%PAYLOAD_TAR%"
