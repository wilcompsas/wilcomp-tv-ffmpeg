#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Prepara work/ con el código fuente exacto:
#   work/ffmpeg  FFmpeg en el commit usado por la app
#   work/media   AndroidX Media3 1.8.0 + parche + wrapper JNI de este repo
#
# Uso:
#   scripts/fetch_sources.sh                  descarga el tarball del Release y verifica SHA-256
#   scripts/fetch_sources.sh --tarball FILE   usa un tarball local (también se verifica)
#   scripts/fetch_sources.sh --from-git       baja el commit desde git (mirror de GitHub del
#                                             repo oficial) en vez del tarball
set -euo pipefail
source "$(dirname "$0")/config.sh"

MODE="download"
TARBALL=""
case "${1:-}" in
  "") ;;
  --tarball) MODE="local"; TARBALL="${2:?falta la ruta del tarball}" ;;
  --from-git) MODE="git" ;;
  *) die "opción desconocida: $1" ;;
esac

[[ -e "$FFMPEG_SRC" || -e "$MEDIA3_SRC" ]] && die "$WORK_DIR ya tiene fuentes; borrarlo o usar otro WORK_DIR"
mkdir -p "$WORK_DIR/downloads"

# ---------- FFmpeg ----------
if [[ "$MODE" == "git" ]]; then
  echo ">> FFmpeg $FFMPEG_COMMIT desde $FFMPEG_GITHUB_MIRROR (mirror de $FFMPEG_OFFICIAL_GIT)"
  git init -q "$FFMPEG_SRC"
  git -C "$FFMPEG_SRC" fetch -q --depth 1 "$FFMPEG_GITHUB_MIRROR" "$FFMPEG_COMMIT"
  git -C "$FFMPEG_SRC" checkout -q FETCH_HEAD
else
  if [[ "$MODE" == "download" ]]; then
    TARBALL="$WORK_DIR/downloads/$FFMPEG_TARBALL"
    echo ">> Descargando $FFMPEG_TARBALL_URL"
    curl -fL --retry 3 -o "$TARBALL" "$FFMPEG_TARBALL_URL"
  fi
  echo ">> Verificando SHA-256 de $TARBALL"
  echo "$FFMPEG_TARBALL_SHA256  $TARBALL" | sha256sum -c -
  mkdir -p "$FFMPEG_SRC"
  tar -xJf "$TARBALL" -C "$FFMPEG_SRC" --strip-components=1
fi
[[ "$(tr -d '\n' < "$FFMPEG_SRC/RELEASE")" == "$FFMPEG_VERSION" ]] || die "RELEASE de FFmpeg no es $FFMPEG_VERSION"

# ---------- Media3 ----------
echo ">> AndroidX Media3 $MEDIA3_VERSION"
# Sparse: se omiten los assets de test (~cientos de MB), no hacen falta para compilar.
git clone -q --depth 1 --branch "$MEDIA3_VERSION" --filter=blob:none --no-checkout "$MEDIA3_GIT" "$MEDIA3_SRC"
git -C "$MEDIA3_SRC" sparse-checkout set --no-cone '/*' '!/libraries/test_data/src/test/assets/'
git -C "$MEDIA3_SRC" checkout -q "$MEDIA3_VERSION"
git -C "$MEDIA3_SRC" apply "$REPO_DIR/patches/media3-1.8.0-ndk-version.patch"

# Wrapper JNI y build_ffmpeg.sh de este repo (idénticos a Media3 1.8.0;
# si alguien los modifica, se usan los de acá).
cp "$REPO_DIR"/jni/{ffmpeg_jni.cc,CMakeLists.txt,build_ffmpeg.sh} "$FFMPEG_MODULE/jni/"
chmod +x "$FFMPEG_MODULE/jni/build_ffmpeg.sh"
ln -sfn "$FFMPEG_SRC" "$FFMPEG_MODULE/jni/ffmpeg"

echo ">> Listo: $WORK_DIR"
