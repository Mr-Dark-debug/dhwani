# Dhwani Test Report

This file is append-only. Failed runs remain recorded with their subsequent fixes and re-test results.

## 2026-08-16 — Initial state

- Project root: `D:\projects\radio`
- Git repository at start: no
- Existing project files at start: none
- Result: Flutter project created directly in the root; no wrapper directory.

## 2026-08-17 — Failures found and resolved

### Structured persistence

- Initial persistence test exposed favourite/custom rows being replaced by conflict inserts.
- Fix: explicit typed updates preserve independent favourite/custom flags.
- Re-test: passed.

### Windows Android build

- Initial Android build failed because the removed `permission_handler` module used an incompatible Kotlin DSL path and later because Kotlin incremental caches crossed C: and D: roots.
- Fix: removed the unused permission dependency; disabled Kotlin incremental compilation for deterministic cross-drive builds.
- Re-test: debug and release Android builds passed.

### Android integration semantics

- First onboarding integration run failed because the tuner exposed increase/decrease actions without a current semantic value. It also logged an empty media artwork URI.
- Fix: tuner now announces current/next/previous station values; media artwork is accepted only for a valid hosted URI.
- Re-test: onboarding integration passed.

### Cold start

- Manual cold install remained on the native splash because notification initialization blocked before `runApp`.
- Fix: non-blocking, idempotent reminder initialization; all reminder actions await the same future.
- Re-test: cold start reached the welcome UI within the observed five-second capture window.

### Landscape

- Pixel-class landscape screenshot showed `BOTTOM OVERFLOWED BY 36 PIXELS` on welcome.
- Fix: responsive two-column, scroll-safe landscape composition.
- Re-test: inspected screenshot `artifacts/screenshots/24-landscape-fixed.png`; no overflow.

# Dhwani Final Verification

Date: 2026-08-17 (Europe/Berlin)

## Environment

- Flutter: 3.41.9 stable, revision `00b0c91f06`
- Dart: 3.11.5 stable (Windows x64)
- Java: Eclipse Temurin OpenJDK 21.0.11 LTS
- Android SDK: compile/target API 36
- Git: 2.55.0.windows.1

## Android device

- Target: `Dhwani_Pixel_10_Approx` Google AVD (physical Pixel 10 was not connected)
- Reported model: `sdk_gphone64_x86_64`
- Android version: 16
- SDK: 36
- Resolution: 1280 × 2856
- Density: 480 dpi
- Navigation: gesture navigation

## Static analysis

- Command: `dart format .`
- Result: completed; working source formatted.
- Command: `flutter analyze`
- Result: **No issues found**.

## Unit and widget tests

- Command: `flutter test`
- Passed: 13
- Failed: 0
- Coverage areas: station/RF parsing, Radio Browser mapping, official Akashvani stream refresh, JSON round-trip, stream ranking, frequency ordering, queue widening, favourite/custom/history persistence, versioned backup structure, recording filenames, and brand semantics.

## Integration tests

- Device: emulator-5554, Android 16/API 36
- Command: `flutter test integration_test/onboarding_flow_test.dart -d emulator-5554`
- Result: 1 passed, 0 failed; Welcome → Country → India → Bihar → Darbhanga → Akashvani player, with 1296 and Play live asserted.
- Command: `flutter test integration_test/custom_station_flow_test.dart -d emulator-5554`
- Result: 1 passed, 0 failed; custom `Dadaji Radio` 1296 AM created, reopened after navigation, and read back from Drift.

## Live playback

### Akashvani Darbhanga

- URL tested: `https://radio.wavespb.com/live/8e074285599ed45d/8e074285599ed45d.m3u8`
- Result: TLS connection reset from the German test network.
- Startup time: bounded at 15 seconds per source before failover.
- Audible: no.
- Fallback required: yes; the discovery-feed BitGravity fallback returned HTTP 404.
- UI result: Connecting/failover/error path; never false LIVE.

### Radio Swiss Jazz

- URL tested: `https://stream.srg-ssr.ch/m/rsj/mp3_128`
- Result: Android media session reached PLAYING and buffered stream data.
- Metadata observed: ICY programme/track metadata (`Traffic Jam - Who's First`).
- Audible: emulator audio could not be heard by the automated environment; platform audio state, bytes, metadata, and AudioTrack/media-session diagnostics confirmed playback.
- Pause/resume/previous/next: exercised; pause/resume notification controls changed the Android media-session state correctly.

## Background playback

- Started Radio Swiss Jazz and pressed Home.
- Waited 12 seconds; `dumpsys media_session` remained PLAYING.
- Foreground service: active with `mediaPlayback` type, target SDK 36.
- Notification: station title and playback controls rendered.
- Notification pause: media session changed to PAUSED.
- Notification resume: media session changed to PLAYING.
- Background restore: app returned without crash.

## Recording

- Station: Radio Swiss Jazz
- Method: separate network connection, stream copy through audio-only FFmpeg 8.1.2
- Duration: 26 seconds displayed (FFprobe-backed metadata)
- File: `Dhwani_Radio-Swiss-Jazz_2026-08-17_00-26-42.mp3`
- Size: 485,262 bytes
- Playable: yes; local file opened through the central player and media session reached PLAYING.
- Export tested: yes; Android Storage Access Framework opened, Save completed, and MediaStore query confirmed `Download/Dhwani_Radio-Swiss-Jazz_2026-08-17_00-26-42.mp3` at 485,262 bytes.

## Visual and accessibility QA

- Inspected: splash, country, state, city, Darbhanga stations, player paused/live, notification, recording active, recordings, SAF export, settings dark mode, 1.3× font scaling, portrait, and landscape.
- Edge-to-edge: no controls behind gesture navigation/status bar after settled insets.
- Dark mode: deliberately themed charcoal/white/red UI verified.
- 1.3× text: welcome remained readable without overflow.
- Landscape: initial 36-pixel overflow fixed and re-inspected.
- Tuner semantics: current/next/previous station actions pass integration semantics.

## APK / AAB

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`; built and installed successfully.
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`; build succeeded.
- Release AAB: `build/app/outputs/bundle/release/app-release.aab`; build succeeded.
- Release signature: locally debug-signed (`CN=Android Debug`) because no private release keystore was supplied.
- Distribution APK: 148,688,988 bytes; SHA-256 `34F86747DC437C42F1AAEF147700141820E5B467D3A38239EF6972410EC558C7`.
- Distribution AAB: 96,250,863 bytes; SHA-256 `7D08D247480A3B4201C3E2ACC39834EDD9FA3D05DA4120CB03391463C6192B62`.
- Release APK install: succeeded; cold start reached the first-run UI and was visually inspected.
- APK signature verification: v2 signature valid; signer is the documented Android Debug certificate.
- `zipalign -c -P 16 -v 4`: verification successful; arm64-v8a, armeabi-v7a, and x86_64 native libraries are 16 KB aligned.

## Windows

- Command: `flutter build windows`
- Result: succeeded in 102.9 seconds.
- Output: `build/windows/x64/runner/Release/dhwani.exe`
- Launch smoke: process remained alive after five seconds, then was intentionally stopped; Windows audio/recording interaction was not the Android acceptance target.

## Known limitations

- Physical Pixel 10 was unavailable; API 36 Pixel-class AVD used.
- Current Darbhanga live sources were unavailable from the German verification network.
- Scheduled recording/alarm are notification-driven prepared actions, not falsely claimed unattended captures.
- Automated environment could not confirm human-audible speaker output.
- Production Play signing requires the owner's private upload key.
