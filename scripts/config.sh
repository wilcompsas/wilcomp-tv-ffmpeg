#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Versiones exactas usadas en Wilcomp TV "Wp v9". Todos los scripts leen
# este archivo; no cambiar sin recompilar y volver a verificar.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_DIR/work}"

# --- FFmpeg (LGPL 2.1 or later) ---
FFMPEG_VERSION="6.0.2"                 # archivo RELEASE del árbol
FFMPEG_BRANCH="release/6.0"
FFMPEG_COMMIT="110e2cd229d5acfdd950f5d09381afc41c263523"
FFMPEG_OFFICIAL_GIT="https://git.ffmpeg.org/ffmpeg.git"
FFMPEG_GITHUB_MIRROR="https://github.com/FFmpeg/FFmpeg.git"
FFMPEG_TARBALL="ffmpeg-6.0.2-110e2cd229d5.tar.xz"
FFMPEG_TARBALL_SHA256="2d2aae4d03d643a00a794f7e6c8202589211b082b93e5b4dc8c0de7aadbdecb7"
FFMPEG_TARBALL_URL="https://github.com/wilcompsas/wilcomp-tv-ffmpeg/releases/download/wp-v9/${FFMPEG_TARBALL}"

# --- AndroidX Media3 (Apache 2.0): extensión decoder_ffmpeg + wrapper JNI ---
MEDIA3_VERSION="1.8.0"
MEDIA3_GIT="https://github.com/androidx/media.git"

# --- Toolchain ---
NDK_REVISION="27.1.12297006"           # NDK r27b
ANDROID_API_LEVEL="21"                 # <= minSdk de la app (26)
HOST_PLATFORM="linux-x86_64"
ABIS=(armeabi-v7a arm64-v8a x86 x86_64)
DECODERS=(ac3 eac3 mp2 mp3)

# --- Rutas de trabajo ---
FFMPEG_SRC="$WORK_DIR/ffmpeg"
MEDIA3_SRC="$WORK_DIR/media"
FFMPEG_MODULE="$MEDIA3_SRC/libraries/decoder_ffmpeg/src/main"
OUT_DIR="$WORK_DIR/out"

die() { echo "ERROR: $*" >&2; exit 1; }

require_ndk() {
  [[ -n "${NDK_PATH:-}" ]] || die "definir NDK_PATH (NDK r27b para Linux, p.ej. ~/android-ndk-r27b)"
  [[ -d "$NDK_PATH/toolchains/llvm/prebuilt/$HOST_PLATFORM/bin" ]] || die "NDK_PATH no parece un NDK válido: $NDK_PATH"
  local rev
  rev="$(sed -n 's/^Pkg.Revision *= *//p' "$NDK_PATH/source.properties" 2>/dev/null | tr -d '\r')"
  if [[ "$rev" != "$NDK_REVISION" ]]; then
    echo "AVISO: NDK $rev, el build oficial usa $NDK_REVISION. El resultado puede diferir." >&2
  fi
  TOOLCHAIN="$NDK_PATH/toolchains/llvm/prebuilt/$HOST_PLATFORM/bin"
}
