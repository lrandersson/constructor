@echo {{ 'on' if add_debug else 'off' }}
setlocal

{%- macro error_block(message, code) -%}
echo [ERROR] {{ message }}
{%- if add_debug %}
>> "%LOG%" echo [ERROR] {{ message }}
{%- endif %}
exit /b {{ code }}
{%- endmacro -%}

rem Assign INSTDIR and normalize the path
set "INSTDIR=%~dp0.."
for %%I in ("%INSTDIR%") do set "INSTDIR=%%~fI"

set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

set CONDA_EXTRA_SAFETY_CHECKS=no
set CONDA_PROTECT_FROZEN_ENVS=0
set CONDA_REGISTER_ENVS={{ register_envs }}
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

rem Consistency checks
if not exist "%CONDA_EXE%" (
  {{ error_block('CONDA_EXE not found: "%CONDA_EXE%"', 10) }}
)
if not exist "%PAYLOAD_TAR%" (
  {{ error_block('PAYLOAD_TAR not found: "%PAYLOAD_TAR%"', 11) }}
)

echo Unpacking payload...
%CONDA_EXE%" constructor extract --prefix "%INSTDIR%" --tar-from-stdin < "%PAYLOAD_TAR%"{{ redir }}
rem "%CONDA_EXE%" constructor --prefix "%INSTDIR%" --extract-tarball < "%PAYLOAD_TAR%"{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

"%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs{{ redir }}
rem "%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

if not exist "%BASE_PATH%" (
  {{ error_block('"%BASE_PATH%" not found!', 12) }}
)

"%CONDA_EXE%" install --offline --file "%BASE_PATH%\conda-meta\initial-state.explicit.txt" -yp "%BASE_PATH%"{{ redir }}
if errorlevel 1 ( {{ dump_and_exit }} )

rem Delete the payload to save disk space.
rem A truncated placeholder of 0 bytes is recreated during uninstall
rem because MSI expects the file to be there to clean the registry.
del "%PAYLOAD_TAR%"
if errorlevel 1 ( {{ dump_and_exit }} )

exit /b 0
