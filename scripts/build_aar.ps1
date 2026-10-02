# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Arma el .aar de la extensión FFmpeg de Media3 en Windows, a partir de las
# fuentes preparadas en WSL (scripts/fetch_sources.sh + build_ffmpeg_libs.sh).
# Es el procedimiento con el que se armó el .aar de Wilcomp TV.
#
# Requiere en Windows: JDK 17 (JAVA_HOME) y Android SDK con NDK
# 27.1.12297006 y CMake (Android Studio > SDK Manager > SDK Tools).
#
# Uso (PowerShell):
#   .\scripts\build_aar.ps1 -WslWorkDir /home/<usuario>/wilcomp-tv-ffmpeg/work `
#                           -BuildDir C:\wilcomp-ffmpeg-build `
#                           -AndroidSdk $env:LOCALAPPDATA\Android\Sdk
param(
  [Parameter(Mandatory = $true)] [string] $WslWorkDir,
  [Parameter(Mandatory = $true)] [string] $BuildDir,
  [string] $AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
  [string] $WslDistro = ""
)
$ErrorActionPreference = 'Stop'

# En Windows PowerShell 5.1, con 'Stop', cualquier línea que un ejecutable
# escriba en stderr (p.ej. un warning de Gradle) corta el script. Los comandos
# nativos se juzgan por su código de salida.
function Invoke-Native([scriptblock] $block, [string] $what) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & $block 2>&1 | ForEach-Object { "$_" } } finally { $ErrorActionPreference = $prev }
  if ($LASTEXITCODE -ne 0) { throw "falló: $what (código $LASTEXITCODE)" }
}

function Invoke-Wsl([string] $script) {
  if ($WslDistro) {
    Invoke-Native { wsl -d $WslDistro -- bash -c $script } $script
  } else {
    Invoke-Native { wsl -- bash -c $script } $script
  }
}

if (Test-Path $BuildDir) { throw "$BuildDir ya existe; usar una carpeta nueva" }
New-Item -ItemType Directory -Force "$BuildDir\media" | Out-Null
$winBuild = (& wsl wslpath -a ($BuildDir -replace '\\', '/')).Trim()
$jniRel = 'libraries/decoder_ffmpeg/src/main/jni'

# 1) Media3 (sin .git, sin assets de test ni el symlink a ffmpeg). Se copia con
#    tar desde WSL: robocopy por \\wsl.localhost es lentísimo con miles de archivos.
Write-Host '>> Copiando Media3 desde WSL'
Invoke-Wsl "tar -C '$WslWorkDir/media' --exclude=.git --exclude=libraries/test_data/src/test/assets --exclude=$jniRel/ffmpeg -cf - . | tar -xf - -C '$winBuild/media'"

# 2) FFmpeg: solo headers + librerías estáticas compiladas (lo que usa CMakeLists.txt).
Write-Host '>> Copiando headers y android-libs de FFmpeg'
Invoke-Wsl "mkdir -p '$winBuild/media/$jniRel/ffmpeg' && cd '$WslWorkDir/ffmpeg' && find . \( -name '*.h' -o -path './android-libs/*' \) -print0 | tar --null -cf - -T - | tar -xf - -C '$winBuild/media/$jniRel/ffmpeg'"

# 3) SDK
$sdkEscaped = $AndroidSdk -replace '\\', '\\' -replace ':', '\:'
Set-Content -Encoding ascii "$BuildDir\media\local.properties" "sdk.dir=$sdkEscaped"

# 4) Build
Write-Host '>> Gradle :lib-decoder-ffmpeg:assembleRelease'
Push-Location "$BuildDir\media"
try {
  Invoke-Native { .\gradlew.bat --no-daemon :lib-decoder-ffmpeg:assembleRelease } 'Gradle'
} finally { Pop-Location }

New-Item -ItemType Directory -Force "$BuildDir\out" | Out-Null
$aar = "$BuildDir\out\media3-decoder-ffmpeg-1.8.0-wilcomp.aar"
Copy-Item "$BuildDir\media\libraries\decoder_ffmpeg\buildout\outputs\aar\lib-decoder-ffmpeg-release.aar" $aar
Write-Host ">> Listo: $aar"
