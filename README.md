# wilcomp-tv-ffmpeg

[English version](README.en.md)

Código fuente y scripts para recompilar **`libffmpegJNI.so`**, la biblioteca
nativa de la app Android **Wilcomp TV** (versión "Wp v9") que contiene
**FFmpeg**. La app la usa, a través de la extensión FFmpeg de
[AndroidX Media3](https://github.com/androidx/media), para decodificar audio
**AC-3, E-AC-3, MP2 y MP3**.

Este repositorio existe para cumplir la licencia **LGPL 2.1** de FFmpeg. Con
lo que hay acá cualquier persona puede recompilar `libffmpegJNI.so` completo
(FFmpeg + wrapper JNI), con o sin modificaciones a FFmpeg, y reemplazarlo en
la app.

## Cómo está enlazado FFmpeg

FFmpeg (`libavcodec`, `libavutil`, `libswresample`) se compila como
**biblioteca estática** y queda **enlazado estáticamente dentro de
`libffmpegJNI.so`**, junto con el wrapper JNI de Media3. La app carga
`libffmpegJNI.so` **dinámicamente** en tiempo de ejecución
(`System.loadLibrary`). `libffmpegJNI.so` solo depende de bibliotecas del
sistema (`libandroid`, `liblog`, `libm`, `libdl`, `libc`).

Por eso, para usar otra versión de FFmpeg se recompila y se reemplaza
`libffmpegJNI.so` entero: este repositorio trae todas sus partes (FFmpeg,
wrapper JNI, scripts y parches).

## Versiones exactas

| Componente | Versión |
|---|---|
| FFmpeg | **6.0.2** (archivo `RELEASE`), rama `release/6.0`, commit **`110e2cd229d5acfdd950f5d09381afc41c263523`** |
| Origen oficial de FFmpeg | https://git.ffmpeg.org/ffmpeg.git (mirror: https://github.com/FFmpeg/FFmpeg) |
| AndroidX Media3 (extensión `decoder_ffmpeg` + wrapper JNI) | **1.8.0** (tag `1.8.0` de https://github.com/androidx/media) |
| Android NDK | **r27b** (27.1.12297006) |
| `ANDROID_ABI` (API mínima de los binarios) | 21 |
| ABIs | `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64` |
| Decoders | `ac3`, `eac3`, `mp2`, `mp3` |
| Para el `.aar` (opcional) | JDK 17, Gradle 8.10.2 (wrapper de Media3), AGP 8.8.1, compileSdk 35 |

> En el repositorio oficial no existe un tag `n6.0.2`: el árbol usado es la
> punta de la rama `release/6.0` en ese commit, cuyo archivo `RELEASE` dice
> `6.0.2`. Por eso siempre se cita el commit.

## Código fuente de FFmpeg

El árbol exacto de FFmpeg se publica como asset del
[Release `wp-v9`](https://github.com/wilcompsas/wilcomp-tv-ffmpeg/releases/tag/wp-v9):

| Archivo | SHA-256 |
|---|---|
| `ffmpeg-6.0.2-110e2cd229d5.tar.xz` | `2d2aae4d03d643a00a794f7e6c8202589211b082b93e5b4dc8c0de7aadbdecb7` |

Se generó con `git archive` del commit
`110e2cd229d5acfdd950f5d09381afc41c263523`, **sin modificaciones**.
`scripts/fetch_sources.sh` lo descarga y verifica el SHA-256 antes de usarlo.

Para comprobar que coincide con el repositorio oficial:

```bash
WORK_DIR=/tmp/tarball scripts/fetch_sources.sh              # desde el tarball
WORK_DIR=/tmp/git     scripts/fetch_sources.sh --from-git   # desde git, mismo commit
diff -r /tmp/tarball/ffmpeg /tmp/git/ffmpeg --exclude=.git && echo IGUALES
```

## Licencias

- **FFmpeg**: LGPL 2.1 o posterior ([`LICENSE`](LICENSE)).
- **Wrapper JNI y scripts de Media3** (`jni/`) y el parche de Media3: Apache 2.0
  ([`LICENSE-APACHE-2.0`](LICENSE-APACHE-2.0)), © The Android Open Source Project.
- **Scripts de este repositorio** (`scripts/`): Apache 2.0, © 2026 Wilcomp S.A.S.

Detalle de autores y orígenes en [`NOTICE`](NOTICE).

**Sin componentes GPL ni nonfree.** La configuración **no** usa
`--enable-gpl`, `--enable-nonfree` ni `--enable-version3`. `configure`
informa `License: LGPL version 2.1 or later` para las 4 ABIs, y
`scripts/verify_lgpl.sh` lo comprueba después de cada compilación (además de
`CONFIG_GPL 0`, `CONFIG_NONFREE 0`, `CONFIG_VERSION3 0` en `config.h`).

FFmpeg es una marca registrada de Fabrice Bellard, creador del proyecto
FFmpeg. Wilcomp S.A.S. no es autor ni propietario de FFmpeg.

## Contenido

```
LICENSE                 LGPL 2.1 (COPYING.LGPLv2.1 de FFmpeg)
LICENSE-APACHE-2.0      Apache 2.0 (wrapper JNI de Media3 y scripts)
NOTICE                  copyright y origen de cada parte
jni/                    ffmpeg_jni.cc, CMakeLists.txt, build_ffmpeg.sh (Media3 1.8.0, sin cambios)
patches/                media3-1.8.0-ndk-version.patch (única modificación a Media3)
scripts/config.sh       versiones, commit, SHA-256 y rutas (lo leen todos los scripts)
scripts/fetch_sources.sh      descarga FFmpeg (tarball verificado o git) y Media3 1.8.0
scripts/build_ffmpeg_libs.sh  compila FFmpeg para las 4 ABIs y verifica la licencia
scripts/verify_lgpl.sh        verificación de licencia y decoders
scripts/build_jni_so.sh       arma libffmpegJNI.so solo con el NDK (sin Gradle)
scripts/build_aar.sh          arma el .aar de Media3 con Gradle (Linux)
scripts/build_aar.ps1         arma el .aar de Media3 con Gradle (Windows, como se hizo para la app)
```

## Opciones de `configure`

Salen de `jni/build_ffmpeg.sh` (el script oficial de Media3 1.8.0):

```
--target-os=android --enable-static --disable-shared --disable-doc
--disable-programs --disable-everything --disable-avdevice --disable-avformat
--disable-swscale --disable-postproc --disable-avfilter --disable-symver
--enable-swresample --extra-ldexeflags=-pie --disable-v4l2-m2m --disable-vulkan
--enable-decoder=ac3 --enable-decoder=eac3 --enable-decoder=mp2 --enable-decoder=mp3
```

Además, por ABI:

| ABI | Opciones |
|---|---|
| `armeabi-v7a` | `--arch=arm --cpu=armv7-a --extra-cflags="-march=armv7-a -mfloat-abi=softfp" --extra-ldflags="-Wl,--fix-cortex-a8"` |
| `arm64-v8a` | `--arch=aarch64 --cpu=armv8-a` |
| `x86` | `--arch=x86 --cpu=i686 --disable-asm` |
| `x86_64` | `--arch=x86_64 --cpu=x86-64 --disable-asm` |

Compilador: clang del NDK r27b (`<triple>21-clang`), con `llvm-ar`, `llvm-nm`,
`llvm-ranlib` y `llvm-strip` del NDK.

## Requisitos

- Linux x86_64 (se usó **Ubuntu en WSL 2**). Paquetes:
  `sudo apt install build-essential pkg-config git curl xz-utils unzip`
- **Android NDK r27b para Linux**:
  ```bash
  curl -LO https://dl.google.com/android/repository/android-ndk-r27b-linux.zip
  unzip -q android-ndk-r27b-linux.zip -d ~
  export NDK_PATH=~/android-ndk-r27b
  ```
- Solo para armar el `.aar`: JDK 17 y Android SDK con NDK 27.1.12297006 y CMake.

## Compilar

```bash
git clone https://github.com/wilcompsas/wilcomp-tv-ffmpeg.git
cd wilcomp-tv-ffmpeg
export NDK_PATH=~/android-ndk-r27b

scripts/fetch_sources.sh        # FFmpeg (tarball del Release, verificado) + Media3 1.8.0 en work/
scripts/build_ffmpeg_libs.sh    # FFmpeg → work/ffmpeg/android-libs/<abi>/*.a (+ verificación LGPL)
scripts/build_jni_so.sh         # libffmpegJNI.so → work/out/jni/<abi>/libffmpegJNI.so
```

`build_ffmpeg_libs.sh` tarda unos minutos (4 ABIs); el log queda en
`work/build_ffmpeg.log`. `build_jni_so.sh` compila `jni/ffmpeg_jni.cc` y lo
enlaza con las bibliotecas de FFmpeg igual que `jni/CMakeLists.txt`
(`-Wl,-z,max-page-size=16384` para páginas de 16 KB, `-Bsymbolic` en arm64).

### Opcional: el `.aar` completo (como en la app)

La app no usa el `.so` suelto sino el `.aar` de la extensión de Media3
(`media3-decoder-ffmpeg-1.8.0-wilcomp.aar`: clases Java de Media3 +
`libffmpegJNI.so` de las 4 ABIs), armado con Gradle:

- **Linux**: `ANDROID_HOME=~/Android/Sdk scripts/build_aar.sh`
- **Windows** (así se armó el de la app), desde PowerShell, con las fuentes ya
  compiladas en WSL:
  ```powershell
  .\scripts\build_aar.ps1 -WslWorkDir /home/<usuario>/wilcomp-tv-ffmpeg/work -BuildDir C:\wfb
  ```
  Usar una carpeta de salida corta (p.ej. `C:\wfb`): Gradle genera rutas muy
  largas y Windows tiene un límite de 260 caracteres.

## Reemplazar `libffmpegJNI.so` en la app

La app empaqueta las bibliotecas nativas **sin comprimir y alineadas a 16 KB**
(`extractNativeLibs=false`), así que el `.so` nuevo tiene que ir *stored* y
el APK se realinea con `zipalign -P 16`. Como el APK queda modificado, hay que
**firmarlo con tu propia llave**; Android no permite instalarlo encima del
original (firma distinta), así que primero hay que desinstalar la app. Al
desinstalarla se borran sus datos: la app pedirá activarse de nuevo.

Herramientas: `zip`, y `zipalign` y `apksigner` de las *build-tools* del
Android SDK. Averiguar la ABI del equipo:
`adb shell getprop ro.product.cpu.abi` (p.ej. `arm64-v8a`).

**Si tienes el APK** (`wilcomp-tv.apk`):

```bash
ABI=arm64-v8a
mkdir mod && cd mod
cp ../wilcomp-tv.apk app.apk
mkdir -p lib/$ABI && cp ../work/out/jni/$ABI/libffmpegJNI.so lib/$ABI/
zip -d app.apk 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.MF' || true   # firma v1, si existe
zip -0 app.apk lib/$ABI/libffmpegJNI.so                                  # -0 = sin comprimir
zipalign -f -P 16 4 app.apk app-aligned.apk
apksigner sign --ks ~/mi-llave.keystore --out app-mod.apk app-aligned.apk
adb uninstall com.iptvnative
adb install app-mod.apk
```

**Si la app se instaló desde Google Play** (APKs divididos): las bibliotecas
nativas están en el split de la ABI.

```bash
adb shell pm path com.iptvnative          # lista base.apk y split_config.*.apk
adb pull <ruta>/base.apk && adb pull <ruta>/split_config.arm64_v8a.apk   # y demás splits
# reemplazar lib/arm64-v8a/libffmpegJNI.so dentro de split_config.arm64_v8a.apk
# con los mismos pasos de arriba (zip -0, zipalign -P 16), y firmar TODOS los
# splits con la misma llave:
apksigner sign --ks ~/mi-llave.keystore base.apk
apksigner sign --ks ~/mi-llave.keystore split_config.arm64_v8a.apk   # etc.
adb uninstall com.iptvnative
adb install-multiple base.apk split_config.arm64_v8a.apk ...
```

## Usar una versión modificada de FFmpeg

1. `scripts/fetch_sources.sh` y modificar el código en `work/ffmpeg/` (o
   reemplazar esa carpeta por otro árbol de FFmpeg 6.x).
2. Si se necesitan otros decoders, editar `DECODERS` en `scripts/config.sh`.
3. `scripts/build_ffmpeg_libs.sh` y `scripts/build_jni_so.sh`.
4. Reemplazar `libffmpegJNI.so` como se explica arriba.

El wrapper `jni/ffmpeg_jni.cc` usa la API de `libavcodec`/`libswresample`;
las clases Java de Media3 en la app llaman a las funciones JNI que exporta.
Una versión de FFmpeg con API compatible (6.x) funciona sin tocar el wrapper;
para otras versiones puede hacer falta adaptarlo (es Apache 2.0).

## Verificación de reproducibilidad (2026-09-30)

Desde una copia limpia de este repositorio, en WSL, con el tarball del
Release, se compilaron las bibliotecas y se compararon con el `.aar` que usa
la app:

| | armeabi-v7a | arm64-v8a | x86 | x86_64 |
|---|---|---|---|---|
| `libffmpegJNI.so` en la app (bytes) | 799 816 | 962 648 | 923 916 | 995 160 |
| `.aar` rearmado con `build_aar.ps1` | 799 816 | 962 648 | 923 916 | 995 160 |
| `.so` de `build_jni_so.sh` (solo NDK) | 799 524 | 962 536 | 925 156 | 995 024 |

- `.aar` rearmado vs. el de la app: mismos símbolos exportados y totales,
  misma sección `.text`, mismas dependencias (`NEEDED`); `classes.jar`,
  `AndroidManifest.xml`, `R.txt` y `proguard.txt` idénticos byte a byte. Los
  `.so` difieren solo en **20 bytes: el build-id** (hash SHA-1 que el linker
  calcula incluyendo la información de debug, que contiene la ruta de la
  carpeta de compilación).
- `.a` de FFmpeg: los objetos son idénticos una vez quitada la información de
  debug (difieren solo las rutas de compilación embebidas).
- `.so` de `build_jni_so.sh`: mismos símbolos exportados y totales, misma
  sección `.text` (x86: 48 bytes de diferencia por flags de compilación
  distintas a las de CMake); tamaños dentro de ±0,15 %.
