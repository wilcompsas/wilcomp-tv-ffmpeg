#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Compila libffmpegJNI.so (wrapper JNI de Media3 + FFmpeg estático) para las
# 4 ABIs usando solo el NDK, sin Gradle ni Android SDK. Replica lo que hace
# jni/CMakeLists.txt. Es el camino más corto para obtener un .so y
# reemplazarlo dentro del APK (ver README).
# Requiere haber corrido scripts/build_ffmpeg_libs.sh.
# Salida: work/out/jni/<abi>/libffmpegJNI.so (sin símbolos de debug)
#
# Uso: NDK_PATH=~/android-ndk-r27b scripts/build_jni_so.sh
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_ndk

JNI_DIR="$FFMPEG_MODULE/jni"
[[ -f "$FFMPEG_SRC/android-libs/arm64-v8a/libavcodec.a" ]] || die "faltan las libs de FFmpeg; correr scripts/build_ffmpeg_libs.sh"

target_for() {
  case "$1" in
    armeabi-v7a) echo "armv7a-linux-androideabi$ANDROID_API_LEVEL" ;;
    arm64-v8a)   echo "aarch64-linux-android$ANDROID_API_LEVEL" ;;
    x86)         echo "i686-linux-android$ANDROID_API_LEVEL" ;;
    x86_64)      echo "x86_64-linux-android$ANDROID_API_LEVEL" ;;
  esac
}

for abi in "${ABIS[@]}"; do
  out="$OUT_DIR/jni/$abi"
  mkdir -p "$out"
  libs="$FFMPEG_SRC/android-libs/$abi"
  extra=()
  # Igual que CMakeLists.txt: -Bsymbolic solo en arm64-v8a.
  [[ "$abi" == "arm64-v8a" ]] && extra+=("-Wl,-Bsymbolic")
  [[ "$abi" == "armeabi-v7a" ]] && extra+=("-mthumb")

  echo ">> $abi"
  "$TOOLCHAIN/clang++" --target="$(target_for "$abi")" \
    -std=c++11 -fPIC -O2 -DNDEBUG -DANDROID \
    -ffunction-sections -fdata-sections -fstack-protector-strong \
    -I"$FFMPEG_SRC" \
    -shared -o "$out/libffmpegJNI.so" "$JNI_DIR/ffmpeg_jni.cc" \
    "$libs/libswresample.a" "$libs/libavcodec.a" "$libs/libavutil.a" \
    -landroid -llog -lm \
    -static-libstdc++ \
    -Wl,--no-undefined -Wl,--gc-sections -Wl,--build-id=sha1 \
    -Wl,-z,max-page-size=16384 \
    "${extra[@]}"
  "$TOOLCHAIN/llvm-strip" --strip-unneeded "$out/libffmpegJNI.so"
  ls -l "$out/libffmpegJNI.so"
done
echo ">> Listo: $OUT_DIR/jni"
