$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$packages = @(
    @{Name='platform-tools'; Hash='e03e78b1d80b396f1c3358e31251cb31740e1110'; Destination='sdk'},
    @{Name='emulator'; Hash='54fa750822ff462d57e04fc8e98e60f08df2bb61'; Destination='sdk'},
    @{Name='system'; Hash='6ae21030eaadc041078444d3798e4b399f3e787d'; Destination='sdk\system-images\android-30\google_apis'}
)
foreach ($package in $packages) {
    $archive = Join-Path $root ('downloads\' + $package.Name + '.zip')
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA1).Hash -ne $package.Hash) { throw "Invalid archive: $archive" }
    Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $root $package.Destination) -Force
}
$avd = Join-Path $root 'avd\MAX-Sandbox.avd'
New-Item -ItemType Directory -Force $avd,(Join-Path $root 'home'),(Join-Path $root 'outbox') | Out-Null
$ini = "avd.ini.encoding=UTF-8`npath=$avd`ntarget=android-30`n"
[IO.File]::WriteAllText((Join-Path $root 'avd\MAX-Sandbox.ini'),$ini,[Text.UTF8Encoding]::new($false))
$config = @'
AvdId=MAX-Sandbox
avd.ini.displayname=MAX Sandbox
avd.ini.encoding=UTF-8
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=2
hw.ramSize=2048
hw.lcd.width=540
hw.lcd.height=960
hw.lcd.density=240
hw.keyboard=yes
hw.gpu.enabled=yes
hw.gpu.mode=software
hw.camera.back=none
hw.camera.front=none
hw.audioInput=no
hw.audioOutput=no
hw.gps=no
hw.sensors.orientation=no
hw.sensors.proximity=no
hw.sdCard=no
disk.dataPartition.size=4G
image.sysdir.1=system-images/android-30/google_apis/x86_64/
tag.id=google_apis
tag.display=Google APIs
PlayStore.enabled=false
showDeviceFrame=no
fastboot.forceColdBoot=yes
'@
[IO.File]::WriteAllText((Join-Path $avd 'config.ini'),$config,[Text.UTF8Encoding]::new($false))
& (Join-Path $root 'sdk\emulator\emulator.exe') -accel-check
if ($LASTEXITCODE -ne 0) { throw 'Windows Hypervisor Platform is unavailable.' }
