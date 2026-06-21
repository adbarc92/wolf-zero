# Mobile Export (Android / iOS)

Wolf-Zero is configured for mobile export via [`export_presets.cfg`](../export_presets.cfg)
(committed). The presets are **template-based** (`gradle_build/use_gradle_build=false`), so a
debug build needs only the Godot export templates + the Android SDK signing tools — **no
Gradle, no Android Studio, no JDK 17**.

> Verified 2026-06-20 producing a signed debug APK (`com.adbarc92.wolfzero`, v0.1.0,
> arm64-v8a/armeabi-v7a/x86_64, minSdk 24 / target 35) with Godot 4.6.1 on Windows.

## Presets
| Preset | Platform | Notes |
|--------|----------|-------|
| `Android` | Android | Template export, signed with the editor's debug keystore. Buildable on any OS. |
| `iOS` | iOS | Config only — **building an `.ipa`/Xcode project requires macOS + Xcode.** |

`export_path` defaults to `build/` (gitignored).

## One-time machine setup
These are **per-developer / editor-level** settings (not committed), configured under
*Editor → Editor Settings → Export → Android*:

| Setting | Value used |
|---------|-----------|
| `android_sdk_path` | Android SDK root (e.g. `%LOCALAPPDATA%\Android\Sdk`) with `build-tools` + a `platforms` SDK installed |
| `java_sdk_path` | Any modern JDK (used to run `apksigner`; JDK 17 only needed for Gradle custom builds, which we don't use) |
| `debug_keystore` | Path to a debug keystore (alias `androiddebugkey`) |
| `debug_keystore_pass` | `android` |

A debug keystore is the standard Android one (`~/.android/debug.keystore`, created by the
Android SDK). If you don't have one:
```
keytool -genkeypair -v -keystore debug.keystore -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

Also install the Godot **export templates** matching your engine version
(*Editor → Manage Export Templates*), or place them in
`%APPDATA%\Godot\export_templates\<version>\`.

## Build a debug APK (headless / CI)
```sh
# from the project root
godot --headless --path . --export-debug "Android" build/wolf-zero-debug.apk
```
On this machine the Godot binary is `C:\Godot\Godot_v4.6.1-stable_win64_console.exe`
(use the `_console` build for stdout).

## Verify the APK
```sh
# signature (set JAVA_HOME to a valid JDK first)
"$ANDROID_SDK/build-tools/35.0.0/apksigner" verify --print-certs build/wolf-zero-debug.apk
# manifest (package id, version, sdk levels, ABIs)
"$ANDROID_SDK/build-tools/35.0.0/aapt2" dump badging build/wolf-zero-debug.apk
```

## Install / run on a device
```sh
adb install -r build/wolf-zero-debug.apk     # adb lives in $ANDROID_SDK/platform-tools
```
No physical device or emulator was available during verification, so on-device runtime
(frame pacing, touch latency) is still **unconfirmed** — that's the next step once hardware
is on hand. See the audit notes in [`docs/CODEBASE-DIGEST.md`](CODEBASE-DIGEST.md) for touch
input caveats (parry currently has no gesture binding).

## Notes
- A release build (`--export-release`) needs a real signing keystore, not the debug one.
- The headless export prints `ERROR: Cannot set object script ...` during the filesystem
  scan; this is a benign editor-scan message — the export still completes and signs.
- iOS: `--export-debug "iOS"` only produces an Xcode project and must be run on macOS with
  Xcode + a provisioning profile / team id filled into the `iOS` preset.
