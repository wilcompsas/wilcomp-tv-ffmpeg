#!/bin/bash
# Copyright 2026 Wilcomp S.A.S.
# SPDX-License-Identifier: Apache-2.0
#
# Verifica que el build de FFmpeg sea LGPL 2.1 (sin GPL, nonfree ni
# version3) y que las librerías tengan los decoders esperados.
# Uso: NDK_PATH=... scripts/verify_lgpl.sh
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_ndk

LOG="$WORK_DIR/build_ffmpeg.log"
fail=0
check() { if eval "$2"; then echo "  OK   $1"; else echo "  FAIL $1"; fail=1; fi; }

echo ">> Flags prohibidos en los scripts de build"
check "sin --enable-gpl / --enable-nonfree / --enable-version3" \
  "! grep -nE -- '--enable-(gpl|nonfree|version3)' '$FFMPEG_MODULE/jni/build_ffmpeg.sh' '$REPO_DIR/jni/build_ffmpeg.sh'"

echo ">> Licencia informada por configure (una por ABI)"
check "4 x 'License: LGPL version 2.1 or later'" \
  "[[ \$(grep -c '^License: LGPL version 2.1 or later' '$LOG') -eq ${#ABIS[@]} ]]"
check "ninguna otra licencia" "! grep '^License:' '$LOG' | grep -v 'LGPL version 2.1 or later' > /dev/null"

echo ">> config.h (último configure)"
for flag in GPL NONFREE VERSION3 GPLV3 LGPLV3; do
  check "CONFIG_$flag 0" "grep -q '^#define CONFIG_$flag 0' '$FFMPEG_SRC/config.h'"
done

echo ">> Librerías y decoders por ABI"
for abi in "${ABIS[@]}"; do
  dir="$FFMPEG_SRC/android-libs/$abi"
  for lib in libavcodec.a libavutil.a libswresample.a; do
    check "$abi/$lib" "[[ -s '$dir/$lib' ]]"
  done
  for dec in "${DECODERS[@]}"; do
    # Sin grep -q: con pipefail, grep -q corta el pipe y llvm-nm muere por SIGPIPE.
    check "$abi ff_${dec}_decoder" "'$TOOLCHAIN/llvm-nm' --defined-only '$dir/libavcodec.a' 2>/dev/null | grep -E ' [DRdr] ff_${dec}_decoder\$' > /dev/null"
  done
done

[[ $fail -eq 0 ]] && echo ">> Verificación LGPL: OK" || die "verificación LGPL con errores"
