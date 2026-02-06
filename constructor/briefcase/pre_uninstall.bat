set "INSTDIR=%cd%"
set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

rem Recreate an empty payload tar. This file was deleted during installation but the
rem MSI installer expects it to exist.
type nul > "%PAYLOAD_TAR%"
