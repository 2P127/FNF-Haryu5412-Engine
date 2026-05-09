@echo off
setlocal EnableExtensions

title Haxe 4.2.5 setup

set "HAXE_VERSION=4.2.5"
set "HAXE_URL=https://github.com/HaxeFoundation/haxe/releases/download/4.2.5/haxe-4.2.5-win.exe"
set "INSTALLER=%TEMP%\haxe-%HAXE_VERSION%-win.exe"
set "HAXE_EXE=C:\HaxeToolkit\haxe\haxe.exe"
set "HAXELIB_EXE=C:\HaxeToolkit\haxe\haxelib.exe"
set "HAXELIB_REPO=C:\HaxeToolkit\haxe\lib"

echo.
echo === Haxe %HAXE_VERSION% setup ===
echo.

set "CURRENT_HAXE="
where haxe >nul 2>nul
if not errorlevel 1 (
	for /f "delims=" %%V in ('haxe --version 2^>nul') do set "CURRENT_HAXE=%%V"
)

if "%CURRENT_HAXE%"=="%HAXE_VERSION%" (
	echo Haxe %HAXE_VERSION% is already active.
	call :setupHaxelib || goto :fail
	exit /b 0
)

echo Downloading Haxe %HAXE_VERSION% installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%HAXE_URL%' -OutFile '%INSTALLER%'"
if errorlevel 1 goto :fail

echo.
echo Starting installer. Approve the Windows UAC prompt if it appears.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%INSTALLER%' -ArgumentList '/S' -Verb RunAs -Wait"
if errorlevel 1 goto :fail

call :setupHaxelib || goto :fail

echo.
echo Haxe setup finished.
echo Open a new terminal, then run setup\setup.bat.
exit /b 0

:setupHaxelib
echo.
echo Initializing haxelib repository at %HAXELIB_REPO%
if not exist "%HAXELIB_REPO%" mkdir "%HAXELIB_REPO%"
if exist "%HAXELIB_EXE%" (
	"%HAXELIB_EXE%" setup "%HAXELIB_REPO%" >nul 2>nul
	if errorlevel 1 exit /b 1
	exit /b 0
)

where haxelib >nul 2>nul
if not errorlevel 1 (
	haxelib setup "%HAXELIB_REPO%" >nul 2>nul
	if errorlevel 1 exit /b 1
	exit /b 0
)

echo haxelib.exe was not found after installation.
exit /b 1

:fail
echo.
echo Haxe setup failed.
exit /b 1
