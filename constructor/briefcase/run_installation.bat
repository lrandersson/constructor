set "INSTDIR=%cd%"
set "BASE_PATH=%INSTDIR%\base"
set "PREFIX=%BASE_PATH%"
set "CONDA_EXE=%INSTDIR%\{{ conda_exe_name }}"
set "PAYLOAD_TAR=%INSTDIR%\{{ archive_name }}"

echo "Unpacking payload..."
"%CONDA_EXE%" constructor extract --prefix "%INSTDIR%" --tar-from-stdin < "%PAYLOAD_TAR%"
"%CONDA_EXE%" constructor --prefix "%BASE_PATH%" --extract-conda-pkgs

set CONDA_PROTECT_FROZEN_ENVS=0
set "CONDA_ROOT_PREFIX=%BASE_PATH%"
set CONDA_SAFETY_CHECKS=disabled
set CONDA_EXTRA_SAFETY_CHECKS=no
set "CONDA_PKGS_DIRS=%BASE_PATH%\pkgs"

"%CONDA_EXE%" install --offline --file "%BASE_PATH%\conda-meta\initial-state.explicit.txt" -yp "%BASE_PATH%"

rem Delete the payload to save disk space.
rem A truncated placeholder of 0 bytes is recreated during uninstall
rem because MSI expects the file to be there to clean the registry.
del "%PAYLOAD_TAR%"
