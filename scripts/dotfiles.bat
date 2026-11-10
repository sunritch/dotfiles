@echo off
setlocal EnableExtensions

set "REPO=%DOTFILES_REPO%"
if not defined REPO for %%I in ("%~dp0..") do set "REPO=%%~fI"

if not exist "%REPO%\.git" goto :norepo

set "RC=0"

call :link ".emacs.d\init.el"   "%USERPROFILE%\.emacs.d\init.el"
call :link ".emacs.d\site-lisp" "%USERPROFILE%\.emacs.d\site-lisp"
call :link ".config\nvim"       "%LOCALAPPDATA%\nvim"
call :link ".config\alacritty"  "%APPDATA%\alacritty"
call :link ".config\wezterm"    "%USERPROFILE%\.config\wezterm"
call :link ".vimrc"             "%USERPROFILE%\.vimrc"

exit /b %RC%

:norepo
>&2 echo ERROR: not a Git repository: "%REPO%"
exit /b 1

:link
set "SRC=%REPO%\%~1"
set "DST=%~2"

if not exist "%SRC%" goto :nosrc

rem Do not overwrite existing files, directories, or links
if exist "%DST%" goto :exists

rem Create the destination parent directory if necessary
for %%I in ("%DST%") do set "PARENT=%%~dpI"
if not exist "%PARENT%" mkdir "%PARENT%" 2>nul
if not exist "%PARENT%" goto :faildir

rem Use a directory symlink for directory sources
set "OPT="
if exist "%SRC%\." set "OPT=/D"

rem Keep mklink error messages visible
mklink %OPT% "%DST%" "%SRC%" >nul
if errorlevel 1 goto :fail

echo LINKED          %DST%
exit /b 0

:nosrc
>&2 echo MISSING-SOURCE "%SRC%"
set "RC=1"
exit /b 0

:exists
echo SKIPPED         %DST%
exit /b 0

:faildir
>&2 echo FAILED-DIR    "%PARENT%"
set "RC=1"
exit /b 0

:fail
>&2 echo FAILED-LINK   "%DST%"
set "RC=1"
exit /b 0
