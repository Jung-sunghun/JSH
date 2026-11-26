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
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select folder containing JPG, PNG, BMP files'; if ($d.ShowDialog() -eq 'OK') { $d.SelectedPath }"`) do set "TARGET_ARG=%%I"

:have_target
if not "%TARGET_ARG%"=="" goto :run_ocr
echo No folder selected. Exiting.
pause
exit /b 0

:run_ocr
set "PYSCRIPT=%CACHE_DIR%\ocr_img.py"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes('%CACHE_DIR%\ocr_img.py', [Convert]::FromBase64String('aW1wb3J0IHN5cywgb3MsIGlvCmZyb20gUElMIGltcG9ydCBJbWFnZSwgSW1hZ2VPcHMKZnJvbSByYXBpZG9jciBpbXBvcnQgRW5naW5lVHlwZSwgTW9kZWxUeXBlLCBPQ1JWZXJzaW9uLCBSYXBpZE9DUgoKdGFyZ2V0X2RpciA9IHN5cy5hcmd2WzFdCm91dF9kaXIgPSBvcy5wYXRoLmpvaW4odGFyZ2V0X2RpciwgIm1kX291dHB1dCIpCm9zLm1ha2VkaXJzKG91dF9kaXIsIGV4aXN0X29rPVRydWUpCgpwcmludCgiTG9hZGluZyBLb3JlYW4gT0NSIGVuZ2luZSAoUFAtT0NSdjUpLi4uIikKZW5naW5lID0gUmFwaWRPQ1IocGFyYW1zPXsKICAgICJEZXQubGltaXRfc2lkZV9sZW4iOiAxNjAwLAogICAgIlJlYy5lbmdpbmVfdHlwZSI6IEVuZ2luZVR5cGUuT05OWFJVTlRJTUUsCiAgICAiUmVjLmxhbmdfdHlwZSI6ICJrb3JlYW4iLAogICAgIlJlYy5tb2RlbF90eXBlIjogTW9kZWxUeXBlLk1PQklMRSwKICAgICJSZWMub2NyX3ZlcnNpb24iOiBPQ1JWZXJzaW9uLlBQT0NSVjUsCn0pCgpleHRzID0geyIuanBnIiwgIi5qcGVnIiwgIi5wbmciLCAiLmJtcCJ9CmZpbGVzID0gc29ydGVkKAogICAgZiBmb3IgZiBpbiBvcy5saXN0ZGlyKHRhcmdldF9kaXIpCiAgICBpZiBvcy5wYXRoLmlzZmlsZShvcy5wYXRoLmpvaW4odGFyZ2V0X2RpciwgZikpIGFuZCBvcy5wYXRoLnNwbGl0ZXh0KGYpWzFdLmxvd2VyKCkgaW4gZXh0cwopCgpwcmludChmIkZvdW5kIHtsZW4oZmlsZXMpfSBpbWFnZSBmaWxlcyAoLmpwZywgLnBuZywgLmJtcCkuIikKb2ssIGZhaWwgPSAwLCAwCgpkZWYgc29ydF9hbmRfam9pbihyZXMpOgogICAgaWYgbm90IHJlcyBvciBub3QgZ2V0YXR0cihyZXMsICJ0eHRzIiwgTm9uZSk6CiAgICAgICAgcmV0dXJuICIiCiAgICBib3hlcyA9IGdldGF0dHIocmVzLCAiYm94ZXMiLCBOb25lKQogICAgdHh0cyA9IGxpc3QocmVzLnR4dHMpCiAgICBpZiBib3hlcyBpcyBOb25lIG9yIGxlbihib3hlcykgIT0gbGVuKHR4dHMpOgogICAgICAgIHJldHVybiAiXG4iLmpvaW4odHh0cykKICAgIGl0ZW1zID0gW10KICAgIGZvciBib3gsIHR4dCBpbiB6aXAoYm94ZXMsIHR4dHMpOgogICAgICAgIHlzID0gW3BbMV0gZm9yIHAgaW4gYm94XQogICAgICAgIHhzID0gW3BbMF0gZm9yIHAgaW4gYm94XQogICAgICAgIHlfbWlkID0gKG1pbih5cykgKyBtYXgoeXMpKSAvIDIuMAogICAgICAgIGggPSBtYXgoMS4wLCBtYXgoeXMpIC0gbWluKHlzKSkKICAgICAgICB4X21pbiA9IG1pbih4cykKICAgICAgICBpdGVtcy5hcHBlbmQoKHlfbWlkLCBoLCB4X21pbiwgdHh0KSkKICAgIGl0ZW1zLnNvcnQoa2V5PWxhbWJkYSBpdDogaXRbMF0pCiAgICBsaW5lcyA9IFtdCiAgICBjdXJfbGluZSA9IFtdCiAgICBjdXJfeSA9IE5vbmUKICAgIGN1cl9oID0gMjAuMAogICAgZm9yIHlfbWlkLCBoLCB4X21pbiwgdHh0IGluIGl0ZW1zOgogICAgICAgIGlmIGN1cl95IGlzIE5vbmUgb3IgYWJzKHlfbWlkIC0gY3VyX3kpIDw9IG1heChjdXJfaCwgaCkgKiAwLjU6CiAgICAgICAgICAgIGN1cl9saW5lLmFwcGVuZCgoeF9taW4sIHR4dCkpCiAgICAgICAgICAgIGlmIGN1cl95IGlzIE5vbmU6CiAgICAgICAgICAgICAgICBjdXJfeSA9IHlfbWlkCiAgICAgICAgICAgICAgICBjdXJfaCA9IGgKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGN1cl95ID0gKGN1cl95ICsgeV9taWQpIC8gMi4wCiAgICAgICAgICAgICAgICBjdXJfaCA9IChjdXJfaCArIGgpIC8gMi4wCiAgICAgICAgZWxzZToKICAgICAgICAgICAgY3VyX2xpbmUuc29ydChrZXk9bGFtYmRhIHQ6IHRbMF0pCiAgICAgICAgICAgIGxpbmVzLmFwcGVuZCgiICIuam9pbih0WzFdIGZvciB0IGluIGN1cl9saW5lKSkKICAgICAgICAgICAgY3VyX2xpbmUgPSBbKHhfbWluLCB0eHQpXQogICAgICAgICAgICBjdXJfeSA9IHlfbWlkCiAgICAgICAgICAgIGN1cl9oID0gaAogICAgaWYgY3VyX2xpbmU6CiAgICAgICAgY3VyX2xpbmUuc29ydChrZXk9bGFtYmRhIHQ6IHRbMF0pCiAgICAgICAgbGluZXMuYXBwZW5kKCIgIi5qb2luKHRbMV0gZm9yIHQgaW4gY3VyX2xpbmUpKQogICAgcmV0dXJuICJcbiIuam9pbihsaW5lcykKCmZvciBpZHgsIG5hbWUgaW4gZW51bWVyYXRlKGZpbGVzLCAxKToKICAgIGltZ19wYXRoID0gb3MucGF0aC5qb2luKHRhcmdldF9kaXIsIG5hbWUpCiAgICBwcmludChmIlt7aWR4fS97bGVuKGZpbGVzKX1dIFByb2Nlc3Npbmc6IHtuYW1lfSIpCiAgICB0cnk6CiAgICAgICAgd2l0aCBJbWFnZS5vcGVuKGltZ19wYXRoKSBhcyBpbToKICAgICAgICAgICAgaW0gPSBJbWFnZU9wcy5leGlmX3RyYW5zcG9zZShpbSkuY29udmVydCgiUkdCIikKICAgICAgICAgICAgYnVmID0gaW8uQnl0ZXNJTygpCiAgICAgICAgICAgIGltLnNhdmUoYnVmLCBmb3JtYXQ9IlBORyIpCiAgICAgICAgICAgIHBuZ19ieXRlcyA9IGJ1Zi5nZXR2YWx1ZSgpCiAgICAgICAgcmVzID0gZW5naW5lKHBuZ19ieXRlcykKICAgICAgICB0ZXh0ID0gc29ydF9hbmRfam9pbihyZXMpCiAgICAgICAgc3RlbSA9IG9zLnBhdGguc3BsaXRleHQobmFtZSlbMF0KICAgICAgICBvdXRfcGF0aCA9IG9zLnBhdGguam9pbihvdXRfZGlyLCBzdGVtICsgIi5tZCIpCiAgICAgICAgd2l0aCBvcGVuKG91dF9wYXRoLCAidyIsIGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6CiAgICAgICAgICAgIGYud3JpdGUoZiIjIHtzdGVtfVxuXG57dGV4dH1cbiIpCiAgICAgICAgb2sgKz0gMQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgIGZhaWwgKz0gMQogICAgICAgIHByaW50KGYiICAtPiBGQUlMRUQ6IHtuYW1lfSAtIHtlfSIpCgpwcmludChmIlxuRG9uZSEgU3VjY2Vzczoge29rfSAvIEZhaWxlZDoge2ZhaWx9IikKcHJpbnQoZiJPdXRwdXQgZm9sZGVyOiB7b3V0X2Rpcn0iKQo='))"

echo [2/2] Running Korean Image OCR (JPG/PNG/BMP)... please wait on first run.
"%UV%" run --python 3.12 --with pillow --with "rapidocr>=3.10.0" --with onnxruntime "%PYSCRIPT%" "%TARGET_ARG%"

echo.
pause
