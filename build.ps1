# Photon + Fullbright shaderpack'ini zip olarak paketler.
# Kullanim:  .\build.ps1            -> dist\Photon-Fullbright.zip olusturur
#            .\build.ps1 -Install   -> ayrica .minecraft\shaderpacks icine kopyalar ve Iris'te etkinlestirir
param(
    [switch]$Install,
    [string]$ShaderpacksDir = "$env:APPDATA\.minecraft\shaderpacks"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = $PSScriptRoot
$src  = Join-Path $root "photon-v1.4-fullbright"
$dist = Join-Path $root "dist"
$zip  = Join-Path $dist "Photon-Fullbright.zip"

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $zip) { Remove-Item $zip -Force }

# Onemli: PowerShell 5.1 Compress-Archive zip icindeki yollari ters slas (\) ile yazar
# ve Java/Iris zip icindeki dosyalari okuyamaz. Bu yuzden .NET ZipArchive ile
# tum yollari POSIX ileri slas (/) olarak paketliyoruz.
$zipStream = [System.IO.File]::Open($zip, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)

try {
    $shadersRoot = Join-Path $src "shaders"
    $files = Get-ChildItem -Path $shadersRoot -Recurse -File
    foreach ($file in $files) {
        $relPath = $file.FullName.Substring($src.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $file.FullName,
            $relPath,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }

    $licensePath = Join-Path $src "LICENSE"
    if (-not (Test-Path $licensePath)) {
        $licensePath = Join-Path (Join-Path $root "photon-fullbright") "LICENSE"
    }
    if (Test-Path $licensePath) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $licensePath,
            "LICENSE",
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
}
finally {
    $archive.Dispose()
    $zipStream.Dispose()
}

Write-Host "Olusturuldu: $zip"

if ($Install) {
    if (-not (Test-Path $ShaderpacksDir)) {
        New-Item -ItemType Directory -Force -Path $ShaderpacksDir | Out-Null
    }
    Copy-Item $zip -Destination $ShaderpacksDir -Force
    Write-Host "Kopyalandi: $ShaderpacksDir\Photon-Fullbright.zip"
}
