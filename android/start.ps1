$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$env:ANDROID_HOME = Join-Path $root 'sdk'
$env:ANDROID_AVD_HOME = Join-Path $root 'avd'
$env:ANDROID_USER_HOME = Join-Path $root 'home'
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$serial = 'emulator-5580'
New-Item -ItemType Directory -Force (Join-Path $root 'logs') | Out-Null
$qtSettings = 'HKCU:\Software\Android Open Source Project\Emulator\set'
New-Item -Path $qtSettings -Force | Out-Null
New-ItemProperty -Path $qtSettings -Name clipboardSharing -Value 'false' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $qtSettings -Name forwardShortcutsToDevice -Value 'true' -PropertyType String -Force | Out-Null
$devices = (& $adb devices) -join "`n"
if ($devices -notmatch "$serial\s+device") {
    $arguments = @('-avd','MAX-Sandbox','-port','5580','-dns-server','1.1.1.1,8.8.8.8','-no-boot-anim','-no-audio','-camera-back','none','-camera-front','none','-no-location-ui','-no-snapshot','-gpu','software','-memory','2048','-feature','QtRawKeyboardInput,-KeycodeForwarding')
    $localConfigPath = Join-Path $root 'config.local.json'
    if (Test-Path -LiteralPath $localConfigPath) {
        $localConfig = Get-Content -LiteralPath $localConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($localConfig.PhoneNumber) {
            if ($localConfig.PhoneNumber -notmatch '^\+?[0-9]{7,15}$') { throw 'Invalid PhoneNumber in config.local.json.' }
            $arguments += @('-phone-number', [string]$localConfig.PhoneNumber)
        }
    }
    Start-Process (Join-Path $env:ANDROID_HOME 'emulator\emulator.exe') -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root 'logs\emulator.log') -RedirectStandardError (Join-Path $root 'logs\emulator-error.log') | Out-Null
}
$deadline = (Get-Date).AddMinutes(4)
do {
    Start-Sleep -Seconds 2
    $booted = & $adb -s $serial shell getprop sys.boot_completed 2>&1
    if ((Get-Date) -gt $deadline) { throw 'Android did not boot. See android/logs.' }
} until ($booted -match '^1')
& $adb -s $serial shell input keyevent 82
foreach ($op in @('CAMERA','RECORD_AUDIO','READ_CONTACTS','WRITE_CONTACTS','READ_CALL_LOG','WRITE_CALL_LOG','READ_SMS','SEND_SMS','ACCESS_FINE_LOCATION','ACCESS_COARSE_LOCATION')) {
    & $adb -s $serial shell cmd appops set ru.oneme.app $op ignore 2>$null | Out-Null
}
& $adb -s $serial shell am start -W -n ru.oneme.app/one.me.android.MainActivity | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'MAX launch failed.' }
