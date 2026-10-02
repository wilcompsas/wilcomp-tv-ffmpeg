#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Compila FFmpeg (libavcodec, libavutil, libswresample estáticas) para las 4
# ABIs con el build_ffmpeg.sh de Media3, y verifica la licencia.
# Salida: work/ffmpeg/android-libs/<abi>/*.a
#
# Uso: NDK_PATH=~/android-ndk-r27b scripts/build_ffmpeg_libs.sh
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_ndk

[[ -f "$FFMPEG_SRC/configure" ]] || die "falta $FFMPEG_SRC; correr primero scripts/fetch_sources.sh"
LOG="$WORK_DIR/build_ffmpeg.log"

echo ">> Compilando FFmpeg (API $ANDROID_API_LEVEL, decoders: ${DECODERS[*]}); log en $LOG"
cd "$FFMPEG_MODULE/jni"
./build_ffmpeg.sh "$FFMPEG_MODULE" "$NDK_PATH" "$HOST_PLATFORM" "$ANDROID_API_LEVEL" "${DECODERS[@]}" > "$LOG" 2>&1 \
  || { tail -30 "$LOG"; die "falló la compilación de FFmpeg"; }

"$REPO_DIR/scripts/verify_lgpl.sh"
