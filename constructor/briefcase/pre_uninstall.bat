@echo {{ 'on' if add_debug else 'off' }}
setlocal

rem Assign INSTDIR and normalize the path
set "INSTDIR=%~dp0.."
for %%I in ("%INSTDIR%") do set "INSTDIR=%%~fI"

set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

{%- if add_debug %}
rem Get the name of the install directory
for %%I in ("%INSTDIR%") do set "APPNAME=%%~nxI"
set "LOG=%TEMP%\%APPNAME%-preuninstall.log"

echo ==== pre_uninstall start ==== >> "%LOG%"
echo SCRIPT=%~f0 >> "%LOG%"
echo CWD=%CD% >> "%LOG%"
echo INSTDIR=%INSTDIR% >> "%LOG%"
echo BASE_PATH=%BASE_PATH% >> "%LOG%"
echo CONDA_EXE=%CONDA_EXE% >> "%LOG%"
echo PAYLOAD_TAR=%PAYLOAD_TAR% >> "%LOG%"
"%CONDA_EXE%" --version >> "%LOG%" 2>&1
{%- endif %}

{%- set redir = ' >> "%LOG%" 2>&1' if add_debug else '' %}
{%- set dump_and_exit = 'type "%LOG%" & exit /b %errorlevel%' if add_debug else 'exit /b %errorlevel%' %}

rem Sanity checks
if not exist "%CONDA_EXE%" (
  {% if add_debug %}echo [ERROR] CONDA_EXE not found: "%CONDA_EXE%" >> "%LOG%" & type "%LOG%" & {% endif %}exit /b 10
)

rem Recreate an empty payload tar. This file was deleted during installation but the
rem MSI installer expects it to exist.
type nul > "%PAYLOAD_TAR%"
if errorlevel 1 (
  {% if add_debug %}echo [ERROR] Failed to create "%PAYLOAD_TAR%" >> "%LOG%" & type "%LOG%" & {% endif %}exit /b %errorlevel%
)

"%CONDA_EXE%" constructor uninstall --prefix "%BASE_PATH%"{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

exit /b 0
