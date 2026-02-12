@echo {{ 'on' if add_debug else 'off' }}
setlocal

rem Assign INSTDIR and normalize the path
set "INSTDIR=%~dp0.."
for %%I in ("%INSTDIR%") do set "INSTDIR=%%~fI"

set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

set CONDA_EXTRA_SAFETY_CHECKS=no
set CONDA_PROTECT_FROZEN_ENVS=0
set CONDA_SAFETY_CHECKS=disabled
set "CONDA_ROOT_PREFIX=%BASE_PATH%"
set "CONDA_PKGS_DIRS=%BASE_PATH%\pkgs"

{%- if add_debug %}
rem Get the name of the install directory
for %%I in ("%INSTDIR%") do set "APPNAME=%%~nxI"
set "LOG=%TEMP%\%APPNAME%-postinstall.log"

echo ==== run_installation start ==== >> "%LOG%"
echo SCRIPT=%~f0 >> "%LOG%"
echo CWD=%CD% >> "%LOG%"
echo INSTDIR=%INSTDIR% >> "%LOG%"
echo BASE_PATH=%BASE_PATH% >> "%LOG%"
echo CONDA_EXE=%CONDA_EXE% >> "%LOG%"
echo PAYLOAD_TAR=%PAYLOAD_TAR% >> "%LOG%"
{%- endif %}

{%- set redir = ' >> "%LOG%" 2>&1' if add_debug else '' %}
{%- set dump_and_exit = 'type "%LOG%" & exit /b %errorlevel%' if add_debug else 'exit /b %errorlevel%' %}

rem Sanity checks
if not exist "%CONDA_EXE%" (
  {% if add_debug %}echo [ERROR] CONDA_EXE not found: "%CONDA_EXE%" >> "%LOG%" & type "%LOG%" & {% endif %}exit /b 10
)
if not exist "%PAYLOAD_TAR%" (
  {% if add_debug %}echo [ERROR] PAYLOAD_TAR not found: "%PAYLOAD_TAR%" >> "%LOG%" & type "%LOG%" & {% endif %}exit /b 11
)

echo Unpacking payload...
rem "%CONDA_EXE%" constructor extract --prefix "%INSTDIR%" --tar-from-stdin < "%PAYLOAD_TAR%"{{ redir }}
"%CONDA_EXE%" constructor --prefix "%INSTDIR%" --extract-tarball < "%PAYLOAD_TAR%"{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

rem "%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs{{ redir }}
"%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

if not exist "%BASE_PATH%" (
  {% if add_debug %}echo [ERROR] "%BASE_PATH%" not found! >> "%LOG%" & type "%LOG%" & {% endif %}exit /b 12
)

"%CONDA_EXE%" install --offline --file "%BASE_PATH%\conda-meta\initial-state.explicit.txt" -yp "%BASE_PATH%"{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

rem Delete the payload to save disk space.
rem A truncated placeholder of 0 bytes is recreated during uninstall
rem because MSI expects the file to be there to clean the registry.
del "%PAYLOAD_TAR%"
