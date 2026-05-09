@echo off
setlocal EnableExtensions EnableDelayedExpansion

title FNF 2P Engine haxelib setup

set "ROOT=%~dp0.."
pushd "%ROOT%" >nul

echo.
echo === FNF 2P Engine haxelib setup ===
echo.

call :require haxe || goto :fail
call :require haxelib || goto :fail
call :require git || goto :fail

set "HAXE_VERSION="
for /f "delims=" %%V in ('haxe --version 2^>nul') do set "HAXE_VERSION=%%V"

if not "%HAXE_VERSION%"=="4.2.5" (
	echo Expected Haxe 4.2.5, but found "%HAXE_VERSION%".
	echo Run "%~dp0setup-haxe-4.2.5.bat" first, then open a new terminal and rerun this file.
	goto :fail
)

haxelib config >nul 2>nul
if errorlevel 1 (
	set "HAXELIB_REPO=C:\HaxeToolkit\haxe\lib"
	echo Initializing haxelib repository at !HAXELIB_REPO!
	if not exist "!HAXELIB_REPO!" mkdir "!HAXELIB_REPO!"
	haxelib setup "!HAXELIB_REPO!" || goto :fail
)

call :installVersion hxcpp 4.2.1 || goto :fail
call :installVersion lime 8.0.0 || goto :fail
call :installVersion openfl 9.2.0 || goto :fail
call :installVersion flixel 4.11.0 || goto :fail
call :installVersion flixel-addons 2.11.0 || goto :fail
call :installVersion flixel-ui 2.5.0 || goto :fail
call :installVersion hscript 2.5.0 || goto :fail
call :installVersion flxanimate 4.0.0 || goto :fail
call :installVersion hxWindowColorMode 0.1.5 || goto :fail

call :installGit discord_rpc https://github.com/Aidan63/linc_discord-rpc 2d83fa863ef0c1eace5f1cf67c3ac315d1a3a8a5 || goto :fail
call :installGit faxe https://github.com/uhrobots/faxe 89be1d2f82f65a94ee3e0e8a01681fe1f0332228 || goto :fail
call :installGit hxCodec https://github.com/polybiusproxy/hxCodec 0a51aed0d9523d22a83e453ce7b593ec7fed4742 || goto :fail
call :applyPatch hxCodec "%~dp0patches\hxcodec-flxvideosprite-end.patch" || goto :fail
call :installGit linc_luajit https://github.com/superpowers04/linc_luajit 633fcc051399afed6781dd60cbf30ed8c3fe2c5a || goto :fail

echo.
echo Active haxelib list:
haxelib list

echo.
echo Setup complete.
popd >nul
exit /b 0

:require
where "%~1" >nul 2>nul
if errorlevel 1 (
	echo Missing required command: %~1
	exit /b 1
)
exit /b 0

:installVersion
set "LIB=%~1"
set "VERSION=%~2"
echo.
echo Installing %LIB% %VERSION%
haxelib --always install "%LIB%" "%VERSION%"
if errorlevel 1 exit /b 1
haxelib set "%LIB%" "%VERSION%"
if errorlevel 1 exit /b 1
exit /b 0

:installGit
set "LIB=%~1"
set "URL=%~2"
set "REF=%~3"
set "LIBPATH="

echo.
echo Installing %LIB% from %URL%

for /f "delims=" %%P in ('haxelib libpath "%LIB%" 2^>nul') do set "LIBPATH=%%P"

if not defined LIBPATH (
	haxelib git "%LIB%" "%URL%"
	if errorlevel 1 exit /b 1
	for /f "delims=" %%P in ('haxelib libpath "%LIB%" 2^>nul') do set "LIBPATH=%%P"
)

if not defined LIBPATH (
	echo Could not find haxelib path for %LIB%.
	exit /b 1
)

if exist "!LIBPATH!\.git" (
	git -C "!LIBPATH!" remote set-url origin "%URL%" >nul 2>nul
	git -C "!LIBPATH!" submodule update --init --recursive

	set "HEAD="
	for /f "delims=" %%H in ('git -C "!LIBPATH!" rev-parse HEAD 2^>nul') do set "HEAD=%%H"

	if /I not "!HEAD!"=="%REF%" (
		git -C "!LIBPATH!" diff --quiet >nul 2>nul
		if errorlevel 1 (
			echo %LIB% has local changes. Keeping current checkout at !HEAD!.
			echo Remove it with "haxelib remove %LIB%" and rerun this setup to force %REF%.
		) else (
			git -C "!LIBPATH!" fetch --all --tags
			if errorlevel 1 exit /b 1
			git -C "!LIBPATH!" checkout "%REF%"
			if errorlevel 1 exit /b 1
			git -C "!LIBPATH!" submodule update --init --recursive
		)
	)
)

haxelib set "%LIB%" git >nul
if errorlevel 1 exit /b 1
exit /b 0

:applyPatch
set "LIB=%~1"
set "PATCH_FILE=%~2"
set "LIBPATH="

echo.
echo Applying %LIB% patch

if not exist "%PATCH_FILE%" (
	echo Patch file not found: %PATCH_FILE%
	exit /b 1
)

for /f "delims=" %%P in ('haxelib libpath "%LIB%" 2^>nul') do set "LIBPATH=%%P"
if not defined LIBPATH (
	echo Could not find haxelib path for %LIB%.
	exit /b 1
)

findstr /C:"public var onEndReached:Void->Void = null;" "!LIBPATH!\src\hxcodec\flixel\FlxVideoSprite.hx" >nul 2>nul
if not errorlevel 1 (
	findstr /C:"bitmap = new FlxVideo();" "!LIBPATH!\src\hxcodec\flixel\FlxVideoSprite.hx" >nul 2>nul
	if not errorlevel 1 (
		echo Patch already applied.
		exit /b 0
	)
)

git -C "!LIBPATH!" apply --check "%PATCH_FILE%" >nul 2>nul
if not errorlevel 1 (
	git -C "!LIBPATH!" apply "%PATCH_FILE%"
	if errorlevel 1 exit /b 1
	exit /b 0
)

git -C "!LIBPATH!" apply --reverse --check "%PATCH_FILE%" >nul 2>nul
if not errorlevel 1 (
	echo Patch already applied.
	exit /b 0
)

echo Patch could not be applied cleanly to %LIB%.
exit /b 1

:fail
echo.
echo Setup failed.
popd >nul
exit /b 1
