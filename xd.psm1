Set-StrictMode -Version Latest

function Get-XdDataFile {
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return Join-Path $env:LOCALAPPDATA 'xd\aliases.json'
    }

    return Join-Path ([Environment]::GetFolderPath('UserProfile')) '.xd\aliases.json'
}

function Read-XdAliases {
    $aliases = [System.Collections.Specialized.OrderedDictionary]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $dataFile = Get-XdDataFile

    if (-not (Test-Path -LiteralPath $dataFile -PathType Leaf)) {
        return $aliases
    }

    try {
        $content = Get-Content -LiteralPath $dataFile -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            return $aliases
        }

        $savedAliases = ConvertFrom-Json -InputObject $content -ErrorAction Stop
        foreach ($property in $savedAliases.PSObject.Properties) {
            $aliases[$property.Name] = [string]$property.Value
        }
    }
    catch {
        throw "xd kayit dosyasi okunamadi: $dataFile`n$($_.Exception.Message)"
    }

    return $aliases
}

function Write-XdAliases {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Aliases
    )

    $dataFile = Get-XdDataFile
    $dataDirectory = Split-Path -Parent $dataFile
    New-Item -ItemType Directory -Path $dataDirectory -Force -ErrorAction Stop | Out-Null

    $serializable = [ordered]@{}
    foreach ($key in $Aliases.Keys) {
        $serializable[[string]$key] = [string]$Aliases[$key]
    }

    $json = ConvertTo-Json -InputObject $serializable -Depth 3
    $temporaryFile = "$dataFile.$PID.tmp"

    try {
        Set-Content -LiteralPath $temporaryFile -Value $json -Encoding UTF8 -ErrorAction Stop
        Move-Item -LiteralPath $temporaryFile -Destination $dataFile -Force -ErrorAction Stop
    }
    finally {
        if (Test-Path -LiteralPath $temporaryFile) {
            Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-XdHelp {
    @'
Kullanim:
  xd <ad>                 Kayitli klasore git
  xd -add <ad> <yol>      Yeni bir klasor adi kaydet veya guncelle
  xd -atf <ad>            Bulunulan klasoru kaydet (add this folder)
  xd -pwd <ad>            Bulunulan klasoru kaydet
  xd -remove <ad>         Kaydi sil
  xd -list                Tum kayitlari goster
  xd -help                Yardimi goster

Ornek:
  xd -add GDRS D:\Workspaces\EWARM_FS\GDRS_SERIE\GDRS
  xd -atf GDRS
  xd GDRS
'@
}

function xd {
    [CmdletBinding(DefaultParameterSetName = 'Go')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Go', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'Add')]
        [Alias('add')]
        [ValidateNotNullOrEmpty()]
        [string] $AddName,

        [Parameter(Mandatory, ParameterSetName = 'Add', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory, ParameterSetName = 'AddCurrent')]
        [Alias('atf', 'pwd')]
        [ValidateNotNullOrEmpty()]
        [string] $AddCurrentName,

        [Parameter(Mandatory, ParameterSetName = 'Remove')]
        [Alias('remove', 'rm')]
        [ValidateNotNullOrEmpty()]
        [string] $RemoveName,

        [Parameter(Mandatory, ParameterSetName = 'List')]
        [Alias('list', 'ls')]
        [switch] $ShowList,

        [Parameter(Mandatory, ParameterSetName = 'Help')]
        [Alias('help', 'h')]
        [switch] $ShowHelp
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Add' {
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
                throw "Klasor bulunamadi: $resolvedPath"
            }

            $resolvedPath = (Resolve-Path -LiteralPath $resolvedPath -ErrorAction Stop).ProviderPath
            $aliases = Read-XdAliases
            $aliases[$AddName] = $resolvedPath
            Write-XdAliases -Aliases $aliases
            Write-Host "Kaydedildi: $AddName -> $resolvedPath"
            return
        }

        'AddCurrent' {
            $currentLocation = Get-Location
            if ($currentLocation.Provider.Name -ne 'FileSystem') {
                throw 'Bulunulan konum bir dosya sistemi klasoru degil.'
            }

            $resolvedPath = $currentLocation.ProviderPath
            $aliases = Read-XdAliases
            $aliases[$AddCurrentName] = $resolvedPath
            Write-XdAliases -Aliases $aliases
            Write-Host "Kaydedildi: $AddCurrentName -> $resolvedPath"
            return
        }

        'Remove' {
            $aliases = Read-XdAliases
            if (-not $aliases.Contains($RemoveName)) {
                throw "Kayit bulunamadi: $RemoveName"
            }

            $aliases.Remove($RemoveName)
            Write-XdAliases -Aliases $aliases
            Write-Host "Silindi: $RemoveName"
            return
        }

        'List' {
            $aliases = Read-XdAliases
            if ($aliases.Count -eq 0) {
                Write-Host 'Henuz kayitli klasor yok.'
                return
            }

            foreach ($key in $aliases.Keys) {
                [PSCustomObject]@{
                    Name = $key
                    Path = $aliases[$key]
                }
            }
            return
        }

        'Help' {
            Show-XdHelp
            return
        }

        'Go' {
            $aliases = Read-XdAliases
            if (-not $aliases.Contains($Name)) {
                throw "Kayit bulunamadi: $Name. Kayitlari gormek icin 'xd -list' yazin."
            }

            $destination = [string]$aliases[$Name]
            if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
                throw "'$Name' icin kayitli klasor artik bulunamiyor: $destination"
            }

            Set-Location -LiteralPath $destination
        }
    }
}

Export-ModuleMember -Function xd
