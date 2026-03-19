# EmlakMaster Web — IIS'e tek komutla dağıtım.
# build\web içeriğini IIS sitenizin kök dizinine kopyalar.
# Kullanım (Windows'ta, proje kökünden):
#   .\scripts\deploy_to_iis.ps1
#   .\scripts\deploy_to_iis.ps1 -Destination "D:\Sites\emlakmaster"
# Önce web build: flutter build web --base-href "/"
param([string]$Destination = "C:\inetpub\wwwroot")
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path $ProjectRoot)) { $ProjectRoot = (Get-Location).Path }
$BuildWeb = Join-Path $ProjectRoot "build\web"
$ReleaseIis = Join-Path $ProjectRoot "release_iis"
$Source = if (Test-Path $ReleaseIis) { $ReleaseIis } else { $BuildWeb }

if (-not (Test-Path $Source)) {
  Write-Host "Build bulunamadi. Calistiriliyor: flutter build web --base-href \"/\""
  Set-Location $ProjectRoot
  & flutter build web --base-href "/"
  $Source = $BuildWeb
  if (-not (Test-Path $Source)) { Write-Error "Build sonrasi da build\web olusmadi." }
}

if (-not (Test-Path $Destination)) {
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}
Write-Host "Kopyalaniyor: $Source -> $Destination"
Get-ChildItem -Path $Source -Recurse | ForEach-Object {
  $rel = $_.FullName.Substring($Source.Length).TrimStart("\")
  $destPath = Join-Path $Destination $rel
  if ($_.PSIsContainer) {
    if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
  } else {
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item -Path $_.FullName -Destination $destPath -Force
  }
}
Write-Host "IIS hedefi guncellendi: $Destination"
