# wilcomp-tv-ffmpeg

[Versión en español](README.md)

Source code and scripts to rebuild **`libffmpegJNI.so`**, the native library
of the **Wilcomp TV** Android app (version "Wp v9") that contains **FFmpeg**.
The app uses it, through the FFmpeg extension of
[AndroidX Media3](https://github.com/androidx/media), to decode **AC-3,
E-AC-3, MP2 and MP3** audio.

This repository exists to comply with FFmpeg's **LGPL 2.1** license. With
its contents anyone can rebuild the complete `libffmpegJNI.so` (FFmpeg + JNI
wrapper), with or without modifications to FFmpeg, and replace it in the app.

## How FFmpeg is linked

FFmpeg (`libavcodec`, `libavutil`, `libswresample`) is built as a **static
library** and is **statically linked into `libffmpegJNI.so`**, together with
the Media3 JNI wrapper. The app loads `libffmpegJNI.so` **dynamically** at
runtime (`System.loadLibrary`). `libffmpegJNI.so` only depends on system
libraries (`libandroid`, `liblog`, `libm`, `libdl`, `libc`).

To use a different FFmpeg you therefore rebuild and replace the whole
`libffmpegJNI.so`: this repository contains all of its parts (FFmpeg, JNI
wrapper, scripts and patches).

## Exact versions

| Component | Version |
|---|---|
| FFmpeg | **6.0.2** (`RELEASE` file), branch `release/6.0`, commit **`110e2cd229d5acfdd950f5d09381afc41c263523`** |
| Official FFmpeg origin | https://git.ffmpeg.org/ffmpeg.git (mirror: https://github.com/FFmpeg/FFmpeg) |
| AndroidX Media3 (`decoder_ffmpeg` extension + JNI wrapper) | **1.8.0** (tag `1.8.0` of https://github.com/androidx/media) |
| Android NDK | **r27b** (27.1.12297006) |
| `ANDROID_ABI` (minimum API of the binaries) | 21 |
| ABIs | `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64` |
| Decoders | `ac3`, `eac3`, `mp2`, `mp3` |
| For the `.aar` (optional) | JDK 17, Gradle 8.10.2 (Media3 wrapper), AGP 8.8.1, compileSdk 35 |

> The official repository has no `n6.0.2` tag: the tree used is the tip of
> the `release/6.0` branch at that commit, whose `RELEASE` file says `6.0.2`.
> That is why the commit is always quoted.

## FFmpeg source code

The exact FFmpeg tree is published as an asset of the
[`wp-v9` Release](https://github.com/wilcompsas/wilcomp-tv-ffmpeg/releases/tag/wp-v9):

| File | SHA-256 |
|---|---|
| `ffmpeg-6.0.2-110e2cd229d5.tar.xz` | `2d2aae4d03d643a00a794f7e6c8202589211b082b93e5b4dc8c0de7aadbdecb7` |

It was produced with `git archive` of commit
`110e2cd229d5acfdd950f5d09381afc41c263523`, **without modifications**.
`scripts/fetch_sources.sh` downloads it and checks the SHA-256 before use.

To check that it matches the official repository:

```bash
WORK_DIR=/tmp/tarball scripts/fetch_sources.sh              # from the tarball
WORK_DIR=/tmp/git     scripts/fetch_sources.sh --from-git   # from git, same commit
diff -r /tmp/tarball/ffmpeg /tmp/git/ffmpeg --exclude=.git && echo IDENTICAL
```

## Licenses

- **FFmpeg**: LGPL 2.1 or later ([`LICENSE`](LICENSE)).
- **Media3 JNI wrapper and scripts** (`jni/`) and the Media3 patch: Apache 2.0
  ([`LICENSE-APACHE-2.0`](LICENSE-APACHE-2.0)), © The Android Open Source Project.
- **This repository's scripts** (`scripts/`): Apache 2.0, © 2026 Wilcomp S.A.S.

Authors and origins in detail: [`NOTICE`](NOTICE).

**No GPL or nonfree components.** The configuration does **not** use
`--enable-gpl`, `--enable-nonfree` or `--enable-version3`. `configure`
reports `License: LGPL version 2.1 or later` for all 4 ABIs, and
`scripts/verify_lgpl.sh` checks it after every build (plus `CONFIG_GPL 0`,
`CONFIG_NONFREE 0`, `CONFIG_VERSION3 0` in `config.h`).

FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
Wilcomp S.A.S. is not the author or owner of FFmpeg.

## Contents

```
LICENSE                 LGPL 2.1 (FFmpeg's COPYING.LGPLv2.1)
LICENSE-APACHE-2.0      Apache 2.0 (Media3 JNI wrapper and scripts)
NOTICE                  copyright and origin of each part
jni/                    ffmpeg_jni.cc, CMakeLists.txt, build_ffmpeg.sh (Media3 1.8.0, unmodified)
patches/                media3-1.8.0-ndk-version.patch (the only change to Media3)
scripts/config.sh       versions, commit, SHA-256 and paths (read by every script)
scripts/fetch_sources.sh      downloads FFmpeg (verified tarball or git) and Media3 1.8.0
scripts/build_ffmpeg_libs.sh  builds FFmpeg for the 4 ABIs and verifies the license
scripts/verify_lgpl.sh        license and decoder checks
scripts/build_jni_so.sh       builds libffmpegJNI.so with the NDK only (no Gradle)
scripts/build_aar.sh          builds the Media3 .aar with Gradle (Linux)
scripts/build_aar.ps1         builds the Media3 .aar with Gradle (Windows, as done for the app)
```

## `configure` options

Taken from `jni/build_ffmpeg.sh` (the official Media3 1.8.0 script):

```
--target-os=android --enable-static --disable-shared --disable-doc
--disable-programs --disable-everything --disable-avdevice --disable-avformat
--disable-swscale --disable-postproc --disable-avfilter --disable-symver
--enable-swresample --extra-ldexeflags=-pie --disable-v4l2-m2m --disable-vulkan
--enable-decoder=ac3 --enable-decoder=eac3 --enable-decoder=mp2 --enable-decoder=mp3
```

Plus, per ABI:

| ABI | Options |
|---|---|
| `armeabi-v7a` | `--arch=arm --cpu=armv7-a --extra-cflags="-march=armv7-a -mfloat-abi=softfp" --extra-ldflags="-Wl,--fix-cortex-a8"` |
| `arm64-v8a` | `--arch=aarch64 --cpu=armv8-a` |
| `x86` | `--arch=x86 --cpu=i686 --disable-asm` |
| `x86_64` | `--arch=x86_64 --cpu=x86-64 --disable-asm` |

Compiler: NDK r27b clang (`<triple>21-clang`), with the NDK's `llvm-ar`,
`llvm-nm`, `llvm-ranlib` and `llvm-strip`.

## Requirements

- Linux x86_64 (**Ubuntu on WSL 2** was used). Packages:
  `sudo apt install build-essential pkg-config git curl xz-utils unzip`
- **Android NDK r27b for Linux**:
  ```bash
  curl -LO https://dl.google.com/android/repository/android-ndk-r27b-linux.zip
  unzip -q android-ndk-r27b-linux.zip -d ~
  export NDK_PATH=~/android-ndk-r27b
  ```
- Only for the `.aar`: JDK 17 and the Android SDK with NDK 27.1.12297006 and CMake.

## Build

```bash
git clone https://github.com/wilcompsas/wilcomp-tv-ffmpeg.git
cd wilcomp-tv-ffmpeg
export NDK_PATH=~/android-ndk-r27b

scripts/fetch_sources.sh        # FFmpeg (Release tarball, verified) + Media3 1.8.0 into work/
scripts/build_ffmpeg_libs.sh    # FFmpeg → work/ffmpeg/android-libs/<abi>/*.a (+ LGPL check)
scripts/build_jni_so.sh         # libffmpegJNI.so → work/out/jni/<abi>/libffmpegJNI.so
```

`build_ffmpeg_libs.sh` takes a few minutes (4 ABIs); the log is written to
`work/build_ffmpeg.log`. `build_jni_so.sh` compiles `jni/ffmpeg_jni.cc` and
links it with the FFmpeg libraries the same way as `jni/CMakeLists.txt`
(`-Wl,-z,max-page-size=16384` for 16 KB pages, `-Bsymbolic` on arm64).

### Optional: the complete `.aar` (as used by the app)

The app does not ship a loose `.so` but the Media3 extension `.aar`
(`media3-decoder-ffmpeg-1.8.0-wilcomp.aar`: Media3 Java classes +
`libffmpegJNI.so` for the 4 ABIs), built with Gradle:

- **Linux**: `ANDROID_HOME=~/Android/Sdk scripts/build_aar.sh`
- **Windows** (how the app's `.aar` was built), from PowerShell, with the
  sources already built in WSL:
  ```powershell
  .\scripts\build_aar.ps1 -WslWorkDir /home/<user>/wilcomp-tv-ffmpeg/work -BuildDir C:\wfb
  ```
  Use a short output folder (e.g. `C:\wfb`): Gradle generates very long paths
  and Windows has a 260-character limit.

## Replacing `libffmpegJNI.so` in the app

The app packages its native libraries **uncompressed and 16 KB aligned**
(`extractNativeLibs=false`), so the new `.so` must be *stored* and the APK
realigned with `zipalign -P 16`. Since the APK is modified, it must be
**signed with your own key**; Android will not install it over the original
(different signature), so the app has to be uninstalled first. Uninstalling
deletes its data: the app will ask to be activated again.

Tools: `zip`, plus `zipalign` and `apksigner` from the Android SDK
*build-tools*. Find the device ABI with
`adb shell getprop ro.product.cpu.abi` (e.g. `arm64-v8a`).

**If you have the APK** (`wilcomp-tv.apk`):

```bash
ABI=arm64-v8a
mkdir mod && cd mod
cp ../wilcomp-tv.apk app.apk
mkdir -p lib/$ABI && cp ../work/out/jni/$ABI/libffmpegJNI.so lib/$ABI/
zip -d app.apk 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.MF' || true   # v1 signature, if any
zip -0 app.apk lib/$ABI/libffmpegJNI.so                                  # -0 = stored
zipalign -f -P 16 4 app.apk app-aligned.apk
apksigner sign --ks ~/my-key.keystore --out app-mod.apk app-aligned.apk
adb uninstall com.iptvnative
adb install app-mod.apk
```

**If the app was installed from Google Play** (split APKs): native libraries
live in the ABI split.

```bash
adb shell pm path com.iptvnative          # lists base.apk and split_config.*.apk
adb pull <path>/base.apk && adb pull <path>/split_config.arm64_v8a.apk   # and the other splits
# replace lib/arm64-v8a/libffmpegJNI.so inside split_config.arm64_v8a.apk
# with the steps above (zip -0, zipalign -P 16), then sign ALL splits with
# the same key:
apksigner sign --ks ~/my-key.keystore base.apk
apksigner sign --ks ~/my-key.keystore split_config.arm64_v8a.apk   # etc.
adb uninstall com.iptvnative
adb install-multiple base.apk split_config.arm64_v8a.apk ...
```

## Using a modified FFmpeg

1. Run `scripts/fetch_sources.sh` and modify the code in `work/ffmpeg/` (or
   replace that folder with another FFmpeg 6.x tree).
2. If other decoders are needed, edit `DECODERS` in `scripts/config.sh`.
3. Run `scripts/build_ffmpeg_libs.sh` and `scripts/build_jni_so.sh`.
4. Replace `libffmpegJNI.so` as explained above.

The `jni/ffmpeg_jni.cc` wrapper uses the `libavcodec`/`libswresample` API;
the Media3 Java classes in the app call the JNI functions it exports. An
FFmpeg version with a compatible API (6.x) works without touching the
wrapper; other versions may require adapting it (it is Apache 2.0).

## Reproducibility check (2026-09-30)

From a clean copy of this repository, on WSL, using the Release tarball, the
libraries were built and compared with the `.aar` used by the app:

| | armeabi-v7a | arm64-v8a | x86 | x86_64 |
|---|---|---|---|---|
| `libffmpegJNI.so` in the app (bytes) | 799,816 | 962,648 | 923,916 | 995,160 |
| `.aar` rebuilt with `build_aar.ps1` | 799,816 | 962,648 | 923,916 | 995,160 |
| `.so` from `build_jni_so.sh` (NDK only) | 799,524 | 962,536 | 925,156 | 995,024 |

- Rebuilt `.aar` vs. the app's: same exported and total symbols, same
  `.text` section, same dependencies (`NEEDED`); `classes.jar`,
  `AndroidManifest.xml`, `R.txt` and `proguard.txt` byte-identical. The `.so`
  files differ in only **20 bytes: the build-id** (a SHA-1 the linker computes
  including debug information, which contains the build folder path).
- FFmpeg `.a` files: objects are identical once debug information is removed
  (only the embedded build paths differ).
- `.so` from `build_jni_so.sh`: same exported and total symbols, same `.text`
  section (x86: 48 bytes of difference due to compiler flags that differ from
  CMake's); sizes within ±0.15%.
