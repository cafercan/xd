$ErrorActionPreference = 'Stop'

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "xd-tests-$PID"
$testLocalAppData = Join-Path $testRoot 'data'
$destination = Join-Path $testRoot 'destination'
$originalLocalAppData = $env:LOCALAPPDATA
$originalLocation = Get-Location

try {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $env:LOCALAPPDATA = $testLocalAppData
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'xd.psd1') -Force

    xd -add GDRS $destination

    $dataFile = Join-Path $testLocalAppData 'xd\aliases.json'
    if (-not (Test-Path -LiteralPath $dataFile -PathType Leaf)) {
        throw 'Kayit dosyasi olusturulmadi.'
    }

    xd gdrs
    if ((Get-Location).Path -ne (Resolve-Path -LiteralPath $destination).ProviderPath) {
        throw 'xd kayitli klasore gecemedi.'
    }

    $listed = @(xd -list)
    if ($listed.Count -ne 1 -or $listed[0].Name -ne 'GDRS') {
        throw 'xd -list beklenen kaydi dondurmedi.'
    }

    Set-Location -LiteralPath $destination
    xd -atf GDMP
    xd -pwd GDMP2

    Set-Location -LiteralPath $originalLocation
    xd gdmp
    if ((Get-Location).Path -ne (Resolve-Path -LiteralPath $destination).ProviderPath) {
        throw 'xd -atf bulunulan klasoru kaydedemedi.'
    }

    Set-Location -LiteralPath $originalLocation
    xd gdmp2
    if ((Get-Location).Path -ne (Resolve-Path -LiteralPath $destination).ProviderPath) {
        throw 'xd -pwd bulunulan klasoru kaydedemedi.'
    }

    $openFailed = $false
    try {
        xd -o kayitli-olmayan-ad
    }
    catch {
        $openFailed = $true
    }
    if (-not $openFailed) {
        throw 'xd -o bilinmeyen kayit icin hata vermedi.'
    }

    xd -remove gdmp
    xd -remove gdmp2

    xd -remove gdrs
    if (@(xd -list).Count -ne 0) {
        throw 'xd -remove kaydi silemedi.'
    }

    Write-Host 'Tum xd testleri basarili.' -ForegroundColor Green
}
finally {
    Set-Location $originalLocation
    $env:LOCALAPPDATA = $originalLocalAppData
    Remove-Module xd -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
