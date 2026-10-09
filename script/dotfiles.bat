@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem dotfiles.cmd install | remove | status
rem Requires symlink privilege.

if defined DOTFILES_REPO (
    set "REPO=%DOTFILES_REPO%"
) else (
    for %%I in ("%~dp0..") do set "REPO=%%~fI"
)

set "HOME_DIR=%USERPROFILE%"
set "FILES=^
.emacs.d/init.el .emacs.d/site-lisp ^
.config/nvim ^
.config/helix ^
.config/alacritty ^
.config/wezterm ^
.vimrc"

set "CONFLICTS=0"
set "NOT_OK=0"

if /i "%~1"=="install" goto :do_install
if /i "%~1"=="remove"  goto :do_remove
if /i "%~1"=="status"  goto :do_status

echo usage: dotfiles.cmd install
echo        dotfiles.cmd remove
echo        dotfiles.cmd status
exit /b 1


:ensure_repo
if not exist "!REPO!\" (
    >&2 echo dotfiles: repository does not exist: !REPO!
    exit /b 1
)

for %%I in ("!REPO!") do set "REPO=%%~fI"

if not exist "!REPO!\.git" (
    >&2 echo dotfiles: not a git repository: !REPO!
    exit /b 1
)

exit /b 0


:get_link
set "IS_LINK=0"
set "LINK_ISDIR=0"
set "LINK_TARGET="
set "gl_line="

for %%I in ("%~1") do (
    set "gl_dir=%%~dpI"
    set "gl_name=%%~nxI"
)

for /f "delims=" %%L in ('dir /AL "!gl_dir!" 2^>nul ^| findstr /L /C:" !gl_name! ["') do (
    set "gl_line=%%L"
)

if not defined gl_line exit /b 0

set "IS_LINK=1"

for /f "tokens=2 delims=[]" %%T in ("!gl_line!") do (
    set "LINK_TARGET=%%T"
)

if not "!gl_line:<SYMLINKD>=!"=="!gl_line!" (
    set "LINK_ISDIR=1"
)

if not "!gl_line:<JUNCTION>=!"=="!gl_line!" (
    set "LINK_ISDIR=1"
)

exit /b 0


:exists
if exist "%~1" exit /b 0

call :get_link "%~1"

if "!IS_LINK!"=="1" exit /b 0

exit /b 1


:install_one
set "file=%~1"
set "rel=!file:/=\!"
set "source=!REPO!\!rel!"
set "target=!HOME_DIR!\!rel!"

call :exists "!source!"

if errorlevel 1 (
    >&2 echo MISSING-SOURCE  !source!
    set "CONFLICTS=1"
    exit /b 0
)

for %%I in ("!target!") do set "tdir=%%~dpI"

if not exist "!tdir!" (
    mkdir "!tdir!" >nul 2>&1

    if errorlevel 1 (
        >&2 echo FAILED          !tdir!
        set "CONFLICTS=1"
        exit /b 0
    )
)

call :exists "!target!"

if errorlevel 1 goto :io_link

call :get_link "!target!"

if "!IS_LINK!"=="0" (
    >&2 echo CONFLICT        !target!
    set "CONFLICTS=1"
    exit /b 0
)

if /i "!LINK_TARGET!"=="!source!" (
    echo OK              !target!
    exit /b 0
)

>&2 echo WRONG-LINK      !target! -^> !LINK_TARGET!
set "CONFLICTS=1"

exit /b 0


:io_link
set "opt="

if exist "!source!\" set "opt=/D"

mklink !opt! "!target!" "!source!" >nul

if errorlevel 1 (
    >&2 echo FAILED          !target!
    set "CONFLICTS=1"
    exit /b 0
)

echo LINKED          !target! -^> !source!

exit /b 0


:do_install
call :ensure_repo || exit /b 1

for %%F in (%FILES%) do (
    call :install_one "%%~F"
)

if not "!CONFLICTS!"=="0" (
    >&2 echo dotfiles: install completed with conflicts
    exit /b 1
)

echo dotfiles: install complete
exit /b 0


:remove_one
set "file=%~1"
set "rel=!file:/=\!"
set "source=!REPO!\!rel!"
set "target=!HOME_DIR!\!rel!"

call :exists "!target!"

if errorlevel 1 (
    echo MISSING         !target!
    exit /b 0
)

call :get_link "!target!"

if "!IS_LINK!"=="0" (
    echo NOT-LINKED      !target!
    set "NOT_OK=1"
    exit /b 0
)

if /i not "!LINK_TARGET!"=="!source!" (
    >&2 echo WRONG-LINK      !target! -^> !LINK_TARGET!
    set "NOT_OK=1"
    exit /b 0
)

if "!LINK_ISDIR!"=="1" (
    rmdir "!target!"
) else (
    del /f /q "!target!"
)

if errorlevel 1 (
    >&2 echo FAILED          !target!
    set "NOT_OK=1"
    exit /b 0
)

echo REMOVED         !target!

exit /b 0


:do_remove
call :ensure_repo || exit /b 1

for %%F in (%FILES%) do (
    call :remove_one "%%~F"
)

if not "!NOT_OK!"=="0" (
    >&2 echo dotfiles: remove completed with warnings
    exit /b 1
)

echo dotfiles: remove complete
exit /b 0


:status_one
set "file=%~1"
set "rel=!file:/=\!"
set "source=!REPO!\!rel!"
set "target=!HOME_DIR!\!rel!"

call :exists "!source!"

if errorlevel 1 (
    echo MISSING-SOURCE  !source!
    set "NOT_OK=1"
    exit /b 0
)

call :exists "!target!"

if errorlevel 1 (
    echo MISSING         !target!
    set "NOT_OK=1"
    exit /b 0
)

call :get_link "!target!"

if "!IS_LINK!"=="0" (
    echo NOT-LINKED      !target!
    set "NOT_OK=1"
    exit /b 0
)

if /i "!LINK_TARGET!"=="!source!" (
    echo OK              !target!
    exit /b 0
)

echo WRONG-LINK      !target! -^> !LINK_TARGET!
set "NOT_OK=1"

exit /b 0


:do_status
call :ensure_repo || exit /b 1

echo Repository: !REPO!
echo.

for %%F in (%FILES%) do (
    call :status_one "%%~F"
)

if not "!NOT_OK!"=="0" exit /b 1

exit /b 0
