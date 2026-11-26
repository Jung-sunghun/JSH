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
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select folder containing PDF files'; if ($d.ShowDialog() -eq 'OK') { $d.SelectedPath }"`) do set "TARGET_ARG=%%I"

:have_target
if not "%TARGET_ARG%"=="" goto :run_ocr
echo No folder selected. Exiting.
pause
exit /b 0

:run_ocr
set "PYSCRIPT=%CACHE_DIR%\ocr_pdf.py"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes('%CACHE_DIR%\ocr_pdf.py', [Convert]::FromBase64String('aW1wb3J0IHN5cywgb3MsIGdsb2IKaW1wb3J0IGZpdHoKZnJvbSByYXBpZG9jciBpbXBvcnQgRW5naW5lVHlwZSwgTW9kZWxUeXBlLCBPQ1JWZXJzaW9uLCBSYXBpZE9DUgoKdGFyZ2V0X2RpciA9IHN5cy5hcmd2WzFdCm91dF9kaXIgPSBvcy5wYXRoLmpvaW4odGFyZ2V0X2RpciwgInR4dF9vdXRwdXQiKQpvcy5tYWtlZGlycyhvdXRfZGlyLCBleGlzdF9vaz1UcnVlKQoKcHJpbnQoIkxvYWRpbmcgS29yZWFuIE9DUiBlbmdpbmUuLi4iKQplbmdpbmUgPSBSYXBpZE9DUihwYXJhbXM9ewogICAgIlJlYy5lbmdpbmVfdHlwZSI6IEVuZ2luZVR5cGUuT05OWFJVTlRJTUUsCiAgICAiUmVjLmxhbmdfdHlwZSI6ICJrb3JlYW4iLAogICAgIlJlYy5tb2RlbF90eXBlIjogTW9kZWxUeXBlLk1PQklMRSwKICAgICJSZWMub2NyX3ZlcnNpb24iOiBPQ1JWZXJzaW9uLlBQT0NSVjUsCn0pCgpwZGZzID0gc29ydGVkKGdsb2IuZ2xvYihvcy5wYXRoLmpvaW4odGFyZ2V0X2RpciwgIioucGRmIikpKQpwcmludChmIkZvdW5kIHtsZW4ocGRmcyl9IFBERiBmaWxlcy4iKQpvaywgZmFpbCA9IDAsIDAKZm9yIHBkZl9wYXRoIGluIHBkZnM6CiAgICBuYW1lID0gb3MucGF0aC5iYXNlbmFtZShwZGZfcGF0aCkKICAgIHByaW50KGYiUHJvY2Vzc2luZzoge25hbWV9IikKICAgIHRyeToKICAgICAgICBkb2MgPSBmaXR6Lm9wZW4ocGRmX3BhdGgpCiAgICAgICAgdG90YWwgPSBsZW4oZG9jKQogICAgICAgIHBhZ2VzX3RleHQgPSBbXQogICAgICAgIGZvciBpLCBwYWdlIGluIGVudW1lcmF0ZShkb2MpOgogICAgICAgICAgICBwcmludChmIiAgUGFnZSB7aSArIDF9L3t0b3RhbH0uLi4iKQogICAgICAgICAgICB0ID0gcGFnZS5nZXRfdGV4dCgidGV4dCIpLnN0cmlwKCkKICAgICAgICAgICAgaWYgbGVuKHQpID49IDIwOgogICAgICAgICAgICAgICAgcGFnZXNfdGV4dC5hcHBlbmQodCkKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHBpeCA9IHBhZ2UuZ2V0X3BpeG1hcChkcGk9MjAwKQogICAgICAgICAgICAgICAgcmVzID0gZW5naW5lKHBpeC50b2J5dGVzKCJwbmciKSkKICAgICAgICAgICAgICAgIGlmIHJlcyBhbmQgcmVzLnR4dHM6CiAgICAgICAgICAgICAgICAgICAgcGFnZXNfdGV4dC5hcHBlbmQoIlxuIi5qb2luKHJlcy50eHRzKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgcGFnZXNfdGV4dC5hcHBlbmQoIiIpCiAgICAgICAgb3V0X3BhdGggPSBvcy5wYXRoLmpvaW4ob3V0X2Rpciwgb3MucGF0aC5zcGxpdGV4dChuYW1lKVswXSArICIudHh0IikKICAgICAgICB3aXRoIG9wZW4ob3V0X3BhdGgsICJ3IiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoKICAgICAgICAgICAgZi53cml0ZSgiXG5cbi0tLSBQYWdlIEJyZWFrIC0tLVxuXG4iLmpvaW4ocGFnZXNfdGV4dCkpCiAgICAgICAgb2sgKz0gMQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgIGZhaWwgKz0gMQogICAgICAgIHByaW50KGYiICAtPiBGQUlMRUQ6IHtuYW1lfSAtIHtlfSIpCgpwcmludChmIlxuRG9uZSEgU3VjY2Vzczoge29rfSAvIEZhaWxlZDoge2ZhaWx9IikKcHJpbnQoZiJPdXRwdXQgZm9sZGVyOiB7b3V0X2Rpcn0iKQo='))"

echo [2/2] Running Korean PDF OCR... please wait on first run.
"%UV%" run --python 3.12 --with pymupdf --with "rapidocr>=3.10.0" --with onnxruntime "%PYSCRIPT%" "%TARGET_ARG%"

echo.
pause
