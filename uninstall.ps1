[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$documentsDirectory = [Environment]::GetFolderPath('MyDocuments')
$moduleRoot = Join-Path $documentsDirectory 'PowerShell\Modules\xd'

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $moduleRoot = Join-Path $documentsDirectory 'WindowsPowerShell\Modules\xd'
}

if (-not (Test-Path -LiteralPath $moduleRoot)) {
    Write-Host 'xd kurulu degil.'
    return
}

if ($PSCmdlet.ShouldProcess($moduleRoot, 'xd modulunu kaldir')) {
    Remove-Item -LiteralPath $moduleRoot -Recurse -Force
    Remove-Module xd -Force -ErrorAction SilentlyContinue
    Write-Host 'xd kaldirildi. Kayitli klasorler korunmustur.'
}
