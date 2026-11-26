@echo off
setlocal

set "CACHE_DIR=%LOCALAPPDATA%\PickleOCR"
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

set "UV=%~dp0uv.exe"
if exist "%UV%" goto :have_uv
set "UV=%CACHE_DIR%\uv.exe"
if exist "%UV%" goto :have_uv

echo [1/2] Downloading portable engine to %CACHE_DIR%...
curl.exe -L -f --progress-bar -o "%CACHE_DIR%\uv.zip" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip"
if exist "%CACHE_DIR%\uv.zip" goto :extract_uv
echo Retrying with PowerShell...
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip' -OutFile '%CACHE_DIR%\uv.zip'"

:extract_uv
if not exist "%CACHE_DIR%\uv.zip" goto :dl_fail
powershell -NoProfile -Command "Expand-Archive -Path '%CACHE_DIR%\uv.zip' -DestinationPath '%CACHE_DIR%\uv_tmp' -Force; Get-ChildItem -Path '%CACHE_DIR%\uv_tmp' -Filter 'uv.exe' -Recurse | Select-Object -First 1 | Move-Item -Destination '%CACHE_DIR%\uv.exe' -Force; Remove-Item '%CACHE_DIR%\uv.zip', '%CACHE_DIR%\uv_tmp' -Recurse -Force"
if exist "%UV%" goto :have_uv

:dl_fail
echo [ERROR] Failed to download uv.exe. Check internet connection.
pause
exit /b 1

:have_uv
set "TARGET_ARG=%~1"
if not "%TARGET_ARG%"=="" goto :have_target
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select an image file (JPG, PNG, BMP)'; $d.Filter = 'Image Files (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp|All Files (*.*)|*.*'; if ($d.ShowDialog() -eq 'OK') { $d.FileName }"`) do set "TARGET_ARG=%%I"

:have_target
if not "%TARGET_ARG%"=="" goto :run_ocr
echo No file selected. Exiting.
pause
exit /b 0

:run_ocr
set "PYSCRIPT=%CACHE_DIR%\ocr_img_single.py"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes('%CACHE_DIR%\ocr_img_single.py', [Convert]::FromBase64String('aW1wb3J0IHN5cywgb3MsIGlvCmZyb20gUElMIGltcG9ydCBJbWFnZSwgSW1hZ2VPcHMKZnJvbSByYXBpZG9jciBpbXBvcnQgRW5naW5lVHlwZSwgTW9kZWxUeXBlLCBPQ1JWZXJzaW9uLCBSYXBpZE9DUgoKaW1nX3BhdGggPSBzeXMuYXJndlsxXQppZiBub3Qgb3MucGF0aC5pc2ZpbGUoaW1nX3BhdGgpOgogICAgcHJpbnQoZiJGaWxlIG5vdCBmb3VuZDoge2ltZ19wYXRofSIpCiAgICBzeXMuZXhpdCgxKQoKcHJpbnQoIkxvYWRpbmcgS29yZWFuIE9DUiBlbmdpbmUgKFBQLU9DUnY1KS4uLiIpCmVuZ2luZSA9IFJhcGlkT0NSKHBhcmFtcz17CiAgICAiRGV0LmxpbWl0X3NpZGVfbGVuIjogMTYwMCwKICAgICJSZWMuZW5naW5lX3R5cGUiOiBFbmdpbmVUeXBlLk9OTlhSVU5USU1FLAogICAgIlJlYy5sYW5nX3R5cGUiOiAia29yZWFuIiwKICAgICJSZWMubW9kZWxfdHlwZSI6IE1vZGVsVHlwZS5NT0JJTEUsCiAgICAiUmVjLm9jcl92ZXJzaW9uIjogT0NSVmVyc2lvbi5QUE9DUlY1LAp9KQoKZGVmIHNvcnRfYW5kX2pvaW4ocmVzKToKICAgIGlmIG5vdCByZXMgb3Igbm90IGdldGF0dHIocmVzLCAidHh0cyIsIE5vbmUpOgogICAgICAgIHJldHVybiAiIgogICAgYm94ZXMgPSBnZXRhdHRyKHJlcywgImJveGVzIiwgTm9uZSkKICAgIHR4dHMgPSBsaXN0KHJlcy50eHRzKQogICAgaWYgYm94ZXMgaXMgTm9uZSBvciBsZW4oYm94ZXMpICE9IGxlbih0eHRzKToKICAgICAgICByZXR1cm4gIlxuIi5qb2luKHR4dHMpCiAgICBpdGVtcyA9IFtdCiAgICBmb3IgYm94LCB0eHQgaW4gemlwKGJveGVzLCB0eHRzKToKICAgICAgICB5cyA9IFtwWzFdIGZvciBwIGluIGJveF0KICAgICAgICB4cyA9IFtwWzBdIGZvciBwIGluIGJveF0KICAgICAgICB5X21pZCA9IChtaW4oeXMpICsgbWF4KHlzKSkgLyAyLjAKICAgICAgICBoID0gbWF4KDEuMCwgbWF4KHlzKSAtIG1pbih5cykpCiAgICAgICAgeF9taW4gPSBtaW4oeHMpCiAgICAgICAgaXRlbXMuYXBwZW5kKCh5X21pZCwgaCwgeF9taW4sIHR4dCkpCiAgICBpdGVtcy5zb3J0KGtleT1sYW1iZGEgaXQ6IGl0WzBdKQogICAgbGluZXMgPSBbXQogICAgY3VyX2xpbmUgPSBbXQogICAgY3VyX3kgPSBOb25lCiAgICBjdXJfaCA9IDIwLjAKICAgIGZvciB5X21pZCwgaCwgeF9taW4sIHR4dCBpbiBpdGVtczoKICAgICAgICBpZiBjdXJfeSBpcyBOb25lIG9yIGFicyh5X21pZCAtIGN1cl95KSA8PSBtYXgoY3VyX2gsIGgpICogMC41OgogICAgICAgICAgICBjdXJfbGluZS5hcHBlbmQoKHhfbWluLCB0eHQpKQogICAgICAgICAgICBpZiBjdXJfeSBpcyBOb25lOgogICAgICAgICAgICAgICAgY3VyX3kgPSB5X21pZAogICAgICAgICAgICAgICAgY3VyX2ggPSBoCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBjdXJfeSA9IChjdXJfeSArIHlfbWlkKSAvIDIuMAogICAgICAgICAgICAgICAgY3VyX2ggPSAoY3VyX2ggKyBoKSAvIDIuMAogICAgICAgIGVsc2U6CiAgICAgICAgICAgIGN1cl9saW5lLnNvcnQoa2V5PWxhbWJkYSB0OiB0WzBdKQogICAgICAgICAgICBsaW5lcy5hcHBlbmQoIiAiLmpvaW4odFsxXSBmb3IgdCBpbiBjdXJfbGluZSkpCiAgICAgICAgICAgIGN1cl9saW5lID0gWyh4X21pbiwgdHh0KV0KICAgICAgICAgICAgY3VyX3kgPSB5X21pZAogICAgICAgICAgICBjdXJfaCA9IGgKICAgIGlmIGN1cl9saW5lOgogICAgICAgIGN1cl9saW5lLnNvcnQoa2V5PWxhbWJkYSB0OiB0WzBdKQogICAgICAgIGxpbmVzLmFwcGVuZCgiICIuam9pbih0WzFdIGZvciB0IGluIGN1cl9saW5lKSkKICAgIHJldHVybiAiXG4iLmpvaW4obGluZXMpCgpuYW1lID0gb3MucGF0aC5iYXNlbmFtZShpbWdfcGF0aCkKcHJpbnQoZiJQcm9jZXNzaW5nOiB7bmFtZX0iKQp3aXRoIEltYWdlLm9wZW4oaW1nX3BhdGgpIGFzIGltOgogICAgaW0gPSBJbWFnZU9wcy5leGlmX3RyYW5zcG9zZShpbSkuY29udmVydCgiUkdCIikKICAgIGJ1ZiA9IGlvLkJ5dGVzSU8oKQogICAgaW0uc2F2ZShidWYsIGZvcm1hdD0iUE5HIikKICAgIHBuZ19ieXRlcyA9IGJ1Zi5nZXR2YWx1ZSgpCgpyZXMgPSBlbmdpbmUocG5nX2J5dGVzKQp0ZXh0ID0gc29ydF9hbmRfam9pbihyZXMpCnN0ZW0gPSBvcy5wYXRoLnNwbGl0ZXh0KG5hbWUpWzBdCm91dF9wYXRoID0gb3MucGF0aC5qb2luKG9zLnBhdGguZGlybmFtZShpbWdfcGF0aCksIHN0ZW0gKyAiLm1kIikKd2l0aCBvcGVuKG91dF9wYXRoLCAidyIsIGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6CiAgICBmLndyaXRlKGYiIyB7c3RlbX1cblxue3RleHR9XG4iKQoKcHJpbnQoZiJcbkRvbmUhIFNhdmVkOiB7b3V0X3BhdGh9IikK'))"

echo [2/2] Running Korean Image OCR (Single File)... please wait on first run.
"%UV%" run --python 3.12 --with pillow --with "rapidocr>=3.10.0" --with onnxruntime "%PYSCRIPT%" "%TARGET_ARG%"

echo.
pause
