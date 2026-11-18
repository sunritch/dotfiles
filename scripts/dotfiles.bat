@echo off
setlocal EnableExtensions DisableDelayedExpansion

if "%~2" NEQ "" goto :usage
if /i "%~1"=="install" (set "ACT=link") else if /i "%~1"=="remove" (set "ACT=unlink") else goto :usage

set "REPO=%DOTFILES_REPO%"
if not defined REPO for %%I in ("%~dp0..") do set "REPO=%%~fI"
for %%I in ("%REPO%") do set "REPO=%%~fI"

if not exist "%REPO%\.git" goto :norepo

set "RC=0"

call :%ACT% ".emacs.d\init.el"   "%APPDATA%\.emacs.d\init.el"
call :%ACT% ".emacs.d\site-lisp" "%APPDATA%\.emacs.d\site-lisp"
call :%ACT% ".config\nvim"       "%LOCALAPPDATA%\nvim"
call :%ACT% ".config\alacritty"  "%APPDATA%\alacritty"
rem call :%ACT% ".config\wezterm"    "%USERPROFILE%\.config\wezterm"
call :%ACT% ".vimrc"             "%USERPROFILE%\_vimrc"

exit /b %RC%

:usage
>&2 echo Usage: %~nx0 install^|remove
exit /b 2

:norepo
>&2 echo ERROR: Not a Git repository: "%REPO%"
exit /b 1

:link
set "SRC=%REPO%\%~1"
set "DST=%~2"

if not exist "%SRC%" goto :nosrc

call :target "%DST%"
if defined TARGET goto :check
if exist "%DST%" goto :conflict

if not exist "%~dp2" mkdir "%~dp2" 2>nul

if exist "%SRC%\." (mklink /D "%DST%" "%SRC%" >nul) else (mklink "%DST%" "%SRC%" >nul)
if errorlevel 1 goto :fail

echo LINKED          %DST%
exit /b 0

:check
if /i "%TARGET%"=="%SRC%" goto :ok
goto :conflict

:target
set "TARGET="
for /f "tokens=1* delims=[" %%A in ('dir /AL "%~dp1" 2^>nul ^| findstr /I /L /C:" %~nx1 ["') do set "TARGET=%%B"
if defined TARGET set "TARGET=%TARGET:~0,-1%"
exit /b 0

:nosrc
>&2 echo MISSING-SOURCE "%SRC%"
set "RC=1"
exit /b 0

:conflict
>&2 echo CONFLICT       "%DST%"
set "RC=1"
exit /b 0

:fail
>&2 echo FAILED-LINK    "%DST%"
set "RC=1"
exit /b 0

:ok
echo OK              %DST%
exit /b 0

:unlink
set "SRC=%REPO%\%~1"
set "DST=%~2"

call :target "%DST%"
if not defined TARGET goto :skip
if /i not "%TARGET%"=="%SRC%" goto :skip

if exist "%DST%\." (rmdir "%DST%") else (del /q "%DST%")
if errorlevel 1 goto :unfail

echo UNLINKED        %DST%
exit /b 0

:skip
echo SKIPPED         %DST%
exit /b 0

:unfail
>&2 echo FAILED-UNLINK "%DST%"
set "RC=1"
exit /b 0
