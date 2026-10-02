#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Arma el .aar de la extensión FFmpeg de Media3 (Java + libffmpegJNI.so de
# las 4 ABIs) con Gradle, en Linux. Es el mismo artefacto que usa la app
# (media3-decoder-ffmpeg-1.8.0-wilcomp.aar).
# Requiere: JDK 17, Android SDK con NDK 27.1.12297006 y CMake 3.22+
# (ANDROID_HOME), y haber corrido scripts/build_ffmpeg_libs.sh.
# En Windows usar scripts/build_aar.ps1 (así se armó el .aar de la app).
#
# Uso: ANDROID_HOME=~/Android/Sdk scripts/build_aar.sh
set -euo pipefail
source "$(dirname "$0")/config.sh"

[[ -n "${ANDROID_HOME:-}" ]] || die "definir ANDROID_HOME"
[[ -f "$FFMPEG_SRC/android-libs/arm64-v8a/libavcodec.a" ]] || die "faltan las libs de FFmpeg; correr scripts/build_ffmpeg_libs.sh"

echo "sdk.dir=$ANDROID_HOME" > "$MEDIA3_SRC/local.properties"
cd "$MEDIA3_SRC"
./gradlew --no-daemon :lib-decoder-ffmpeg:assembleRelease

mkdir -p "$OUT_DIR"
cp libraries/decoder_ffmpeg/buildout/outputs/aar/lib-decoder-ffmpeg-release.aar \
   "$OUT_DIR/media3-decoder-ffmpeg-$MEDIA3_VERSION-wilcomp.aar"
echo ">> Listo: $OUT_DIR/media3-decoder-ffmpeg-$MEDIA3_VERSION-wilcomp.aar"
