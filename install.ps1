[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$moduleName = 'xd'
$moduleVersion = '0.1.0'
$sourceDirectory = $PSScriptRoot
$documentsDirectory = [Environment]::GetFolderPath('MyDocuments')
$moduleDirectory = Join-Path $documentsDirectory "PowerShell\Modules\$moduleName\$moduleVersion"

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $moduleDirectory = Join-Path $documentsDirectory "WindowsPowerShell\Modules\$moduleName\$moduleVersion"
}

New-Item -ItemType Directory -Path $moduleDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceDirectory 'xd.psm1') -Destination $moduleDirectory -Force
Copy-Item -LiteralPath (Join-Path $sourceDirectory 'xd.psd1') -Destination $moduleDirectory -Force

Import-Module (Join-Path $moduleDirectory 'xd.psd1') -Force

Write-Host "xd $moduleVersion kuruldu: $moduleDirectory"
Write-Host "Komut hazir. Ornek: xd -add GDRS D:\Workspaces\EWARM_FS\GDRS_SERIE\GDRS"
