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
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select a PDF file'; $d.Filter = 'PDF files (*.pdf)|*.pdf'; if ($d.ShowDialog() -eq 'OK') { $d.FileName }"`) do set "TARGET_ARG=%%I"

:have_target
if not "%TARGET_ARG%"=="" goto :run_ocr
echo No file selected. Exiting.
pause
exit /b 0

:run_ocr
set "PYSCRIPT=%CACHE_DIR%\ocr_single_pdf.py"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes('%CACHE_DIR%\ocr_single_pdf.py', [Convert]::FromBase64String('aW1wb3J0IHN5cywgb3MKaW1wb3J0IGZpdHoKZnJvbSByYXBpZG9jciBpbXBvcnQgRW5naW5lVHlwZSwgTW9kZWxUeXBlLCBPQ1JWZXJzaW9uLCBSYXBpZE9DUgoKcGRmX3BhdGggPSBzeXMuYXJndlsxXQpvdXRfcGF0aCA9IG9zLnBhdGguc3BsaXRleHQocGRmX3BhdGgpWzBdICsgIi50eHQiCgpwcmludCgiTG9hZGluZyBLb3JlYW4gT0NSIGVuZ2luZS4uLiIpCmVuZ2luZSA9IFJhcGlkT0NSKHBhcmFtcz17CiAgICAiUmVjLmVuZ2luZV90eXBlIjogRW5naW5lVHlwZS5PTk5YUlVOVElNRSwKICAgICJSZWMubGFuZ190eXBlIjogImtvcmVhbiIsCiAgICAiUmVjLm1vZGVsX3R5cGUiOiBNb2RlbFR5cGUuTU9CSUxFLAogICAgIlJlYy5vY3JfdmVyc2lvbiI6IE9DUlZlcnNpb24uUFBPQ1JWNSwKfSkKCnByaW50KGYiUHJvY2Vzc2luZzoge29zLnBhdGguYmFzZW5hbWUocGRmX3BhdGgpfSIpCmRvYyA9IGZpdHoub3BlbihwZGZfcGF0aCkKdG90YWwgPSBsZW4oZG9jKQpwYWdlc190ZXh0ID0gW10KZm9yIGksIHBhZ2UgaW4gZW51bWVyYXRlKGRvYyk6CiAgICBwcmludChmIiAgUGFnZSB7aSArIDF9L3t0b3RhbH0uLi4iKQogICAgdCA9IHBhZ2UuZ2V0X3RleHQoInRleHQiKS5zdHJpcCgpCiAgICBpZiBsZW4odCkgPj0gMjA6CiAgICAgICAgcGFnZXNfdGV4dC5hcHBlbmQodCkKICAgIGVsc2U6CiAgICAgICAgcGl4ID0gcGFnZS5nZXRfcGl4bWFwKGRwaT0yMDApCiAgICAgICAgcmVzID0gZW5naW5lKHBpeC50b2J5dGVzKCJwbmciKSkKICAgICAgICBpZiByZXMgYW5kIHJlcy50eHRzOgogICAgICAgICAgICBwYWdlc190ZXh0LmFwcGVuZCgiXG4iLmpvaW4ocmVzLnR4dHMpKQogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHBhZ2VzX3RleHQuYXBwZW5kKCIiKQoKd2l0aCBvcGVuKG91dF9wYXRoLCAidyIsIGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6CiAgICBmLndyaXRlKCJcblxuLS0tIFBhZ2UgQnJlYWsgLS0tXG5cbiIuam9pbihwYWdlc190ZXh0KSkKCnByaW50KGYiXG5Eb25lISBTYXZlZCB0bzoge291dF9wYXRofSIpCg=='))"

echo [2/2] Running Korean PDF OCR... please wait on first run.
"%UV%" run --python 3.12 --with pymupdf --with "rapidocr>=3.10.0" --with onnxruntime "%PYSCRIPT%" "%TARGET_ARG%"

echo.
pause
