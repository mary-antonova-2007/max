param([string]$Path)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Path)) {
    Add-Type -AssemblyName System.Windows.Forms
    $picker = New-Object System.Windows.Forms.OpenFileDialog
    $picker.Title = 'Select a file to send to MAX'
    try {
        if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $Path = $picker.FileName
    } finally { $picker.Dispose() }
}
$file = Get-Item -LiteralPath $Path
if ($file.PSIsContainer) { throw 'Select a file.' }
$adb = Join-Path $PSScriptRoot 'sdk\platform-tools\adb.exe'
& $adb -s emulator-5580 push $file.FullName '/sdcard/Download/'
if ($LASTEXITCODE -ne 0) { throw 'File transfer failed.' }
$androidUri = 'file:///sdcard/Download/' + [Uri]::EscapeDataString($file.Name)
& $adb -s emulator-5580 shell am broadcast --receiver-include-background -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d $androidUri | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Warning 'File copied, but Android media refresh failed. Browse Downloads directly.' }
Write-Output 'Copied to Android Downloads. Select the file in MAX to send it.'
