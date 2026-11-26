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
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip' -OutFile '%CACHE_DIR%\uv.zip'"

:extract_uv
if not exist "%CACHE_DIR%\uv.zip" goto :dl_fail
powershell -NoProfile -Command "Expand-Archive -Path '%CACHE_DIR%\uv.zip' -DestinationPath '%CACHE_DIR%\uv_tmp' -Force; Get-ChildItem -Path '%CACHE_DIR%\uv_tmp' -Filter 'uv.exe' -Recurse | Select-Object -First 1 | Move-Item -Destination '%CACHE_DIR%\uv.exe' -Force; Remove-Item '%CACHE_DIR%\uv.zip', '%CACHE_DIR%\uv_tmp' -Recurse -Force"
if exist "%UV%" goto :have_uv

:dl_fail
echo [ERROR] Failed to download uv.exe.
pause
exit /b 1

:have_uv
set "BAT_SELF=%~f0"
set "PYSCRIPT=%CACHE_DIR%\pdf_split_safe_45mb.py"
powershell -NoProfile -Command "$lines = Get-Content -LiteralPath $env:BAT_SELF; $idx = [Array]::IndexOf($lines, ':: ===PY_B64==='); $b64 = ($lines[($idx+1)..($lines.Length-1)] -join '').Trim(); [IO.File]::WriteAllBytes($env:PYSCRIPT, [Convert]::FromBase64String($b64))"
if errorlevel 1 goto :extract_fail

set "LAST_DIR="
set "TARGET_ARG=%~1"
if defined TARGET_ARG goto :run_split
goto :pick_file

:extract_fail
echo [ERROR] Failed to extract script.
pause
exit /b 1

:pick_file
set "TARGET_ARG="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select PDF file to split safely into 45MB parts'; $d.Filter = 'PDF files (*.pdf)|*.pdf'; if ($env:LAST_DIR -and (Test-Path -LiteralPath $env:LAST_DIR)) { $d.InitialDirectory = $env:LAST_DIR }; if ($d.ShowDialog() -eq 'OK') { $d.FileName }"`) do set "TARGET_ARG=%%I"
if not defined TARGET_ARG goto :no_file
goto :run_split

:no_file
echo No file selected.
goto :ask_next

:run_split
echo.
echo [Splitting Safely] %TARGET_ARG%
"%UV%" run --python 3.12 --with pymupdf "%PYSCRIPT%" "%TARGET_ARG%"
for %%F in ("%TARGET_ARG%") do set "LAST_DIR=%%~dpF"

:ask_next
echo.
echo ==========================================================
echo  [Enter] : Select another PDF
echo  [Esc]   : Quit
echo ==========================================================
powershell -NoProfile -Command "while ($true) { $k = [Console]::ReadKey($true); if ($k.Key -eq 'Escape') { exit 1 } elseif ($k.Key -eq 'Enter' -or $k.Key -eq 'Spacebar') { exit 0 } }"
if errorlevel 1 goto :done
goto :pick_file

:done
exit /b 0

:: ===PY_B64===
aW1wb3J0IHN5cywgb3MsIHRpbWUsIGdjLCBpbwppbXBvcnQgZml0egoKTUFYX0JZVEVTID0gNDUg
KiAxMDI0ICogMTAyNCAgIyA0NSBNQiBzYWZlIGNhcCB1bmRlciA2NCBNaUIgbGltaXQKCmRlZiBy
ZW5kZXJfcGFnZXNfcGRmKHNyYywgc3RhcnQsIGVuZCwgZHBpPTE1MCwgcXVhbGl0eT04NSk6CiAg
ICBkb2MgPSBmaXR6Lm9wZW4oKQogICAgZm9yIHBubyBpbiByYW5nZShzdGFydCwgZW5kICsgMSk6
CiAgICAgICAgcGFnZSA9IHNyY1twbm9dCiAgICAgICAgcGl4ID0gcGFnZS5nZXRfcGl4bWFwKGRw
aT1kcGksIGFscGhhPUZhbHNlKQogICAgICAgIGltZ19ieXRlcyA9IHBpeC50b2J5dGVzKCJqcGVn
IiwganBnX3F1YWxpdHk9cXVhbGl0eSkKICAgICAgICByZWN0ID0gZml0ei5SZWN0KDAsIDAsIHBh
Z2UucmVjdC53aWR0aCwgcGFnZS5yZWN0LmhlaWdodCkKICAgICAgICBuZXdfcGFnZSA9IGRvYy5u
ZXdfcGFnZSh3aWR0aD1yZWN0LndpZHRoLCBoZWlnaHQ9cmVjdC5oZWlnaHQpCiAgICAgICAgbmV3
X3BhZ2UuaW5zZXJ0X2ltYWdlKHJlY3QsIHN0cmVhbT1pbWdfYnl0ZXMpCiAgICAgICAgcGl4ID0g
Tm9uZQogICAgICAgIGlmIChwbm8gLSBzdGFydCkgJSAyMCA9PSAxOToKICAgICAgICAgICAgZ2Mu
Y29sbGVjdCgpCiAgICByZXR1cm4gZG9jCgpkZWYgYnVpbGRfY2h1bmtfYnl0ZXMoc3JjLCBzdGFy
dCwgZW5kLCBmb3JjZV9yYXN0ZXI9RmFsc2UpOgogICAgaWYgbm90IGZvcmNlX3Jhc3RlcjoKICAg
ICAgICBjaHVuayA9IGZpdHoub3BlbigpCiAgICAgICAgY2h1bmsuaW5zZXJ0X3BkZihzcmMsIGZy
b21fcGFnZT1zdGFydCwgdG9fcGFnZT1lbmQpCiAgICAgICAgYnVmID0gaW8uQnl0ZXNJTygpCiAg
ICAgICAgY2h1bmsuc2F2ZShidWYsIGRlZmxhdGU9VHJ1ZSwgZ2FyYmFnZT0zKQogICAgICAgIGNo
dW5rLmNsb3NlKCkKICAgICAgICBkYXRhID0gYnVmLmdldHZhbHVlKCkKICAgICAgICBwYWdlX2Nv
dW50ID0gZW5kIC0gc3RhcnQgKyAxCiAgICAgICAgIyBEZXRlY3Qgc3VzcGljaW91cyBlbXB0eS9i
cm9rZW4gcGFnZXMgKDwgMi41IEtCL3BhZ2Ugb24gbXVsdGktcGFnZSkgb3Igb3ZlcnNpemVkIHNp
bmdsZSBwYWdlCiAgICAgICAgaWYgcGFnZV9jb3VudCA+IDEgYW5kIGxlbihkYXRhKSA8IHBhZ2Vf
Y291bnQgKiAyNTAwOgogICAgICAgICAgICBmb3JjZV9yYXN0ZXIgPSBUcnVlCiAgICAgICAgZWxp
ZiBwYWdlX2NvdW50ID09IDEgYW5kIGxlbihkYXRhKSA+IE1BWF9CWVRFUzoKICAgICAgICAgICAg
Zm9yY2VfcmFzdGVyID0gVHJ1ZQogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHJldHVybiBkYXRh
LCBGYWxzZQoKICAgICMgRmFsbGJhY2s6IHNhZmUgcmFzdGVyaXplZCBQREYgKGZpeGVzIGJyb2tl
biB4cmVmICYgaHVnZSBzaW5nbGUgcGFnZXMpCiAgICBmb3IgZHBpLCBxIGluIFsoMTUwLCA4NSks
ICgxMjAsIDc4KSwgKDk2LCA3MCldOgogICAgICAgIGRvYyA9IHJlbmRlcl9wYWdlc19wZGYoc3Jj
LCBzdGFydCwgZW5kLCBkcGk9ZHBpLCBxdWFsaXR5PXEpCiAgICAgICAgYnVmID0gaW8uQnl0ZXNJ
TygpCiAgICAgICAgZG9jLnNhdmUoYnVmLCBkZWZsYXRlPVRydWUpCiAgICAgICAgZG9jLmNsb3Nl
KCkKICAgICAgICBnYy5jb2xsZWN0KCkKICAgICAgICBkYXRhID0gYnVmLmdldHZhbHVlKCkKICAg
ICAgICBpZiBsZW4oZGF0YSkgPD0gTUFYX0JZVEVTIG9yIChlbmQgPT0gc3RhcnQgYW5kIGRwaSA9
PSA5Nik6CiAgICAgICAgICAgIHJldHVybiBkYXRhLCBUcnVlCiAgICByZXR1cm4gZGF0YSwgVHJ1
ZQoKZGVmIHNwbGl0X3BkZihwZGZfcGF0aCk6CiAgICB0MCA9IHRpbWUudGltZSgpCiAgICBwZGZf
cGF0aCA9IG9zLnBhdGguYWJzcGF0aChwZGZfcGF0aCkKICAgIGJhc2VfZGlyID0gb3MucGF0aC5k
aXJuYW1lKHBkZl9wYXRoKQogICAgc3RlbSA9IG9zLnBhdGguc3BsaXRleHQob3MucGF0aC5iYXNl
bmFtZShwZGZfcGF0aCkpWzBdCiAgICBvdXRfZGlyID0gb3MucGF0aC5qb2luKGJhc2VfZGlyLCBm
IntzdGVtfV9zcGxpdCIpCiAgICBvcy5tYWtlZGlycyhvdXRfZGlyLCBleGlzdF9vaz1UcnVlKQoK
ICAgIGZpdHouVE9PTFMubXVwZGZfZGlzcGxheV9lcnJvcnMoRmFsc2UpCiAgICBzcmMgPSBmaXR6
Lm9wZW4ocGRmX3BhdGgpCiAgICB0b3RhbF9wYWdlcyA9IGxlbihzcmMpCiAgICBmaWxlX3NpemUg
PSBvcy5wYXRoLmdldHNpemUocGRmX3BhdGgpCiAgICBwcmludChmIkZpbGU6IHtvcy5wYXRoLmJh
c2VuYW1lKHBkZl9wYXRoKX0gKHtmaWxlX3NpemUvMTAyNC8xMDI0Oi4xZn0gTUIsIHt0b3RhbF9w
YWdlc30gcGFnZXMpIikKCiAgICBpZiBmaWxlX3NpemUgPD0gTUFYX0JZVEVTOgogICAgICAgIG91
dF9wYXRoID0gb3MucGF0aC5qb2luKG91dF9kaXIsIGYie3N0ZW19X3BhcnQwMS5wZGYiKQogICAg
ICAgIHNyYy5zYXZlKG91dF9wYXRoLCBkZWZsYXRlPVRydWUsIGdhcmJhZ2U9MykKICAgICAgICBz
cmMuY2xvc2UoKQogICAgICAgIHByaW50KGYiQWxyZWFkeSB1bmRlciA0NSBNQiEgU2F2ZWQ6IHtv
dXRfcGF0aH0iKQogICAgICAgIHJldHVybgoKICAgIGF2Z19ieXRlcyA9IG1heCgxLCBmaWxlX3Np
emUgLyB0b3RhbF9wYWdlcykKICAgIGVzdF9wYWdlcyA9IG1heCgxLCBtaW4oNjAsIGludCgoTUFY
X0JZVEVTICogMC44MCkgLyBhdmdfYnl0ZXMpKSkKCiAgICBwYXJ0X251bSA9IDEKICAgIHN0YXJ0
ID0gMAogICAgd2hpbGUgc3RhcnQgPCB0b3RhbF9wYWdlczoKICAgICAgICBlbmQgPSBtaW4odG90
YWxfcGFnZXMgLSAxLCBzdGFydCArIGVzdF9wYWdlcyAtIDEpCiAgICAgICAgd2hpbGUgVHJ1ZToK
ICAgICAgICAgICAgZGF0YSwgdXNlZF9yYXN0ZXIgPSBidWlsZF9jaHVua19ieXRlcyhzcmMsIHN0
YXJ0LCBlbmQpCiAgICAgICAgICAgIHN6ID0gbGVuKGRhdGEpCiAgICAgICAgICAgIGlmIHN6IDw9
IE1BWF9CWVRFUyBvciBlbmQgPT0gc3RhcnQ6CiAgICAgICAgICAgICAgICBvdXRfcGF0aCA9IG9z
LnBhdGguam9pbihvdXRfZGlyLCBmIntzdGVtfV9wYXJ0e3BhcnRfbnVtOjAyZH0ucGRmIikKICAg
ICAgICAgICAgICAgIHdpdGggb3BlbihvdXRfcGF0aCwgIndiIikgYXMgZjoKICAgICAgICAgICAg
ICAgICAgICBmLndyaXRlKGRhdGEpCiAgICAgICAgICAgICAgICB0YWcgPSAiIFtyZXBhaXJlZC9j
b21wcmVzc2VkXSIgaWYgdXNlZF9yYXN0ZXIgZWxzZSAiIgogICAgICAgICAgICAgICAgcHJpbnQo
ZiIgIFBhcnQge3BhcnRfbnVtOjAyZH06IHBhZ2VzIHtzdGFydCsxfS17ZW5kKzF9ICh7c3ovMTAy
NC8xMDI0Oi4xZn0gTUIpe3RhZ30iKQogICAgICAgICAgICAgICAgYnJlYWsKICAgICAgICAgICAg
cmF0aW8gPSAoTUFYX0JZVEVTICogMC44NSkgLyBzegogICAgICAgICAgICBuZXdfY291bnQgPSBt
YXgoMSwgaW50KChlbmQgLSBzdGFydCArIDEpICogcmF0aW8pKQogICAgICAgICAgICBlbmQgPSBz
dGFydCArIG5ld19jb3VudCAtIDEKICAgICAgICBzdGFydCA9IGVuZCArIDEKICAgICAgICBwYXJ0
X251bSArPSAxCiAgICAgICAgZ2MuY29sbGVjdCgpCgogICAgc3JjLmNsb3NlKCkKICAgIHByaW50
KGYiRG9uZSBpbiB7dGltZS50aW1lKCktdDA6LjFmfXMhIENyZWF0ZWQge3BhcnRfbnVtLTF9IHBh
cnRzIGluOiB7b3V0X2Rpcn0iKQoKaWYgX19uYW1lX18gPT0gIl9fbWFpbl9fIjoKICAgIHNwbGl0
X3BkZihzeXMuYXJndlsxXSkK
