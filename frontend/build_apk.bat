@echo off
setlocal ENABLEDELAYEDEXPANSION

cd /d "%~dp0"

if not exist pubspec.yaml (
  echo [ERROR] pubspec.yaml no encontrado. Ejecuta este script desde frontend/.
  exit /b 1
)

set "APP_VERSION="
for /f "tokens=2 delims=: " %%v in ('findstr /b /c:"version:" pubspec.yaml') do (
  set "APP_VERSION=%%v"
)

if "%APP_VERSION%"=="" (
  echo [ERROR] No se pudo leer la version desde pubspec.yaml
  exit /b 1
)

set "SAFE_VERSION=%APP_VERSION:+=_%"

echo [1/3] flutter pub get
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get fallo.
  exit /b 1
)

echo [2/3] flutter build apk --release
call flutter build apk --release
if errorlevel 1 (
  echo [ERROR] flutter build apk fallo.
  exit /b 1
)

if not exist apk mkdir apk

echo [3/3] copiando artefactos a frontend\apk\
copy /Y build\app\outputs\flutter-apk\app-release.apk apk\latest-release.apk >nul
copy /Y build\app\outputs\flutter-apk\app-release.apk "apk\symmetry-news-v%SAFE_VERSION%-release.apk" >nul

echo [OK] APK generado:
echo      - apk\latest-release.apk
echo      - apk\symmetry-news-v%SAFE_VERSION%-release.apk

exit /b 0
