$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'downloads') | Out-Null
$apk = Join-Path $PSScriptRoot 'downloads\MAX.apk'
curl.exe -fL --retry 3 -o $apk 'https://download.max.ru/android/release/google/MAX.apk'
if ($LASTEXITCODE -ne 0) { throw 'Download failed.' }
& (Join-Path $PSScriptRoot 'sdk\platform-tools\adb.exe') -s emulator-5580 install -r $apk
if ($LASTEXITCODE -ne 0) { throw 'Installation failed.' }
& (Join-Path $PSScriptRoot 'start.ps1')
