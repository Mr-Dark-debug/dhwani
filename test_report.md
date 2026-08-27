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

## 2026-08-24 — Reliability mission baseline (v1.1.0+3)

### Repository and release state

- Local `main` and `origin/main` both pointed to `1a78018` (`v1.1.0`) after `git fetch --all --tags --prune`; the only initial working-tree addition was the new `GOAL.md` requested by the reliability mission.
- Published release: `Dhwani v1.1.0 — In-App Updater, Radial Sleep Dial & Glass Navbar`.
- Published asset: `dhwani-v1.1.0.apk`, 179,482,396 bytes, SHA-256 `F024C9E517F6BD4882D6647F0531AB5C4AF46CC3AD20757096A7372049BC045D`.
- Published APK signature: APK Signature Scheme v2 valid; certificate SHA-256 `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5` (`CN=Android Debug`). This is not a production signing identity.
- No GitHub Actions workflow existed at baseline.

### Environment baseline

- Flutter: 3.41.9 stable (`00b0c91f06`); the tool reported that a newer stable release exists.
- Dart: 3.11.5.
- Java: Temurin 21.0.11 LTS; Android Studio runtime 21.0.10.
- Android SDK: 37.0.0 installed; project compile/target SDK remains 36.
- `flutter doctor -v`: no issues found.
- Three configured API 36 AVDs remain available: compact phone, Pixel 10 approximation, and Pixel Tablet; none was running during this baseline command.

### Dependencies

- Command: `flutter pub outdated`.
- Result: the existing dependency set resolves. Riverpod 3.4.2 and several build/transitive updates are available, but no churn was accepted before reliability fixes and migration review.
- FFmpeg full 2.5.2 remains intentionally pinned because the previously tried audio-only variant lacked HTTPS protocol support.

### Static analysis and tests

- Command: `flutter analyze`.
- Baseline result: 2 warnings — unused `dart:io` in `app_update_sheet.dart` and unused Dio import in `app_update_service_test.dart`.
- Command: `flutter test`.
- Baseline result: 30 passed, 0 failed.
- Important gap: the passing suite did not exercise live-play Future completion, stale tune cancellation, runtime `errorStream`, rapid transport input, recording byte handshake, pagination, updater errors/checksums, or upgrade compatibility.

### Baseline builds

- `flutter build apk --debug`: passed in 201.6 seconds.
- `flutter build apk --release`: passed in 54.2 seconds; reported size 171.2 MB.
- Release build is debug-signed by the current Gradle configuration.

### Reproduced architectural defects

- Live playback awaited `_player.play()` both for resume and after `setUrl()`. A live stream can therefore keep UI/navigation Futures pending until the broadcast ends.
- Playback had no operation generation/cancellation guard. A late result for station A could overwrite a newer request for station B.
- Next/Previous changed `_index` before station cleanup and then called `selectStation`, making old/target session identity ambiguous.
- Each fallback could consume 15 seconds with no whole-station deadline; user-facing final errors appended raw exception text.
- Runtime errors relied on `playbackEventStream.onError`; player/metadata subscriptions were not retained for disposal.
- UI entry points independently selected the provider station, configured the queue, called the handler, and manually inserted history. The audio session callback could insert history again, producing duplicates/zero-duration plays.
- Recording changed to `recording` immediately after `executeAsync` returned, before FFmpeg liveness or output bytes were proven. Unexpected FFmpeg exit left a partial orphan and no finalization attempt.
- Radio Browser country loading was capped at 500 with no pagination, cancellation, failure scoring, or stale catalogue expiry.
- Updater hardcoded version/build, selected the first APK, returned `null` for both up-to-date and failure, had no cooldown/checksum/APK identity validation, and treated installer launch as success. Installer permission exceptions incorrectly defaulted to allowed.
- Automatic update checking ran from `PlayerScreen` mount without a durable cooldown.
- Android network security allowed cleartext globally while directory HTTP streams were rejected in Dart, an inconsistent compatibility policy.

# Dhwani v1.2.0 Final Reliability Verification

Date: 2026-08-24 (Europe/Berlin)

## Environment

- Flutter: 3.41.9 stable, revision `00b0c91f06`
- Dart: 3.11.5 stable, Windows x64
- Java: Eclipse Temurin OpenJDK 21.0.11 LTS
- Android SDK installed: 37; project compile/target SDK: 36
- Gradle: 8.14; Android Gradle Plugin: 8.12.1; Kotlin: 2.2.20

## Android device

- Device: `Dhwani_Pixel_10_Approx` / emulator-5554
- Manufacturer/model reported: Google / `sdk_gphone64_x86_64`
- Android: 16, SDK 36
- Resolution: 1280 x 2856
- Density: 480 dpi
- Physical Pixel 10: not connected; this remains an explicit approximation.

## Failure, diagnosis, and retest history

### Live playback startup budget

- Initial combined integration result: **FAILED**. Radio Swiss Jazz did not reach PLAYING before the six-second per-source timeout.
- Evidence: ExoPlayer initialization began around 01:46:53.581 and was released around 01:46:59.064, proving the application cancelled a still-initializing healthy source.
- Fix: 10-second per-source and 24-second whole-station budgets; unrelated Darbhanga fallback replaced by Radio Swiss Jazz AAC metadata fallback.
- Retest: `flutter test integration_test/live_playback_smoke_test.dart -d emulator-5554` passed; the final all-integration run also passed.

### Recording byte handshake

- Initial real-device result: **FAILED** at a ten-second startup handshake; the full native FFmpeg/TLS process had not flushed enough output bytes.
- Fix: bounded 25-second handshake plus packet-flush options; REC still requires an alive process and at least 2048 output bytes.
- Retest: real MP3 stream-copy and M4A conversion both passed with FFprobe durations and cleanup.

### Integration selector drift

- Initial onboarding integration result: **FAILED** because tests still searched for obsolete `Band filter` and direct `Station information` tooltips.
- Fix: tests use the current accessible `Filter by source / band` control, current menu labels, `More actions` -> `Station info`, and stable 48dp bottom-navigation keys.
- Retest: onboarding, custom station, and platform services all passed. This was test drift, not an application crash.

## Static analysis and deterministic tests

- Command: `dart format .`
- Result: 55 Dart files formatted; no pending formatter changes.
- Command: `flutter analyze`
- Result: **No issues found**.
- Command: `flutter test`
- Result: **59 passed, 0 failed**.
- New coverage includes non-completing live play Futures, stale tune completion, fallback, station deadline, offline, pause/resume/retry/stop, runtime reconnect, stale reconnect cancellation, 100 rapid intents, sanitized failures, one-row history, regional health evidence, 502-item pagination, recording process/byte/finalization behavior, installed-version update decisions, prerelease/malformed/ambiguous release handling, package/signature rejection and atomic verified download.

## Android integration tests

- Command: `flutter test integration_test -d emulator-5554`
- Final result: **7 passed, 0 failed** in 8 minutes 10 seconds.
- `controlled_stream_server_test.dart`: real Android decoder followed loopback HTTP 302, played generated WAV, terminated HTTP 404 as Unavailable, and rejected a delayed stale station operation.
- `custom_station_flow_test.dart`: created and reopened `Dadaji Radio`, 1296 kHz AM.
- `live_playback_smoke_test.dart`: real Radio Swiss Jazz reached PLAYING and then PAUSED.
- `onboarding_flow_test.dart`: Country -> India -> Bihar -> Darbhanga -> Akashvani -> band/favourite/Saved/search/info.
- `platform_services_test.dart`: Android equalizer and repeated reminder initialization.
- `recording_smoke_test.dart`: real HTTPS MP3 and M4A recording validation.
- `stress_navigation_test.dart`: 100 player transitions plus 20 Radio/Discover/Saved/Recordings switches.
- Final cleared logcat scan: no FATAL EXCEPTION, ANR, uncaught Dart, database exception, foreground-service-start failure or media-session illegal-state match.

## Live radio and background playback

### Radio Swiss Jazz

- Primary URL: `https://stream.srg-ssr.ch/m/rsj/mp3_128`
- Fallback metadata URL: `https://stream.srg-ssr.ch/rsj/aacp_96.m3u`
- Result: confirmed Android PLAYING, confirmed PAUSED, no endless awaited Future.
- Earlier manual API 36 verification also kept the media session PLAYING after Home/30 seconds; notification Pause/Play/Next/Previous updated media state and switched TORi-Live-8000 correctly.
- Audible: automated environment cannot make a subjective speaker claim; decoder, AudioTrack/media session, bytes and metadata are the evidence.

### Akashvani Darbhanga

- Metadata: 1296 kHz, Medium Wave/AM, Darbhanga, Bihar, Maithili/Hindi.
- Official source from the German network: unavailable/reset; legacy BitGravity source: HTTP 404.
- Result: bounded failure and honest non-LIVE UI. The upstream failure is not stored as a global-offline claim.

## Recording

- Station/source: Radio Swiss Jazz MP3 128 kbps over HTTPS.
- Original mode: MP3 stream copy; output exceeded 1024 bytes; FFprobe duration exceeded 8 seconds; format `mp3`.
- Converted mode: M4A; output exceeded 1024 bytes; FFprobe duration exceeded 6 seconds; format `m4a`.
- REC handshake: output must exceed 2048 bytes before status becomes recording.
- Cleanup: both temporary integration recordings deleted and database/library cleared.
- Prior v1.1 SAF export/replay remains valid and the export implementation was unchanged by the state-machine refactor.

## Upgrade and signing

- Old artifact: published v1.1.0, build 3.
- New artifact: final v1.2.0, build 4.
- Old UI was seeded with India -> Bihar -> Darbhanga, Akashvani 1296 and a saved favourite.
- `adb install -r` of the final v1.2 APK succeeded.
- `firstInstallTime` remained `2026-08-24 02:26:08`; `lastUpdateTime` advanced to `2026-08-24 02:29:13`.
- After upgrade, Akashvani Darbhanga 1296 restored and the favourite remained selected.
- APK Signature Scheme v2: valid; one signer; certificate SHA-256 `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5`.
- Secret-backed Gradle signing report resolved the CI release variant to the same certificate.

## Final Android artifacts

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`, 283,904,299 bytes.
- Release APK: `dist/release/Dhwani-v1.2.0-build4-android.apk`, 179,777,010 bytes.
- APK SHA-256: `8EE1927F0F40870BBC6299BAFD265C4805DBB3DD8D2D87324C5510546507CE48`.
- Release AAB: `dist/release/Dhwani-v1.2.0-build4-android.aab`, 111,581,045 bytes.
- AAB SHA-256: `ACFF86736EE25CE72843C1298A850A2C225EFC3AD345028E3F66D9EF949C8E19`.
- Package: `com.prashant.dhwani`; version 1.2.0; build 4; min SDK 24; target/compile SDK 36.
- `zipalign -c -P 16 -v 4`: verification successful.
- Final release APK install/launch: passed; process remained alive.

## Visual QA

- Reference and final Pixel screenshot were inspected side by side.
- Result: warm-white real app canvas, large frequency, red fixed needle, fine tuner strip, restrained rounded controls, clean status/navigation insets and preserved favourite state; no grey presentation canvas, overlap, clipping or gesture-bar collision.
- Screenshot: `screenshots/v1.2.0/pixel10-final-upgrade-preserved.png`.

## Windows

- Command: `flutter build windows --release`
- Result: passed in 54.6 seconds.
- Output: `build/windows/x64/runner/Release/dhwani.exe`.
- Hidden launch smoke: process remained alive for seven seconds and was intentionally stopped.

## Genuine remaining limitations

- No physical Pixel 10, Bluetooth accessory or human audible-output verification was available.
- Akashvani Darbhanga remains externally unavailable from the German network used here.
- The protected legacy signer preserves v1.1 -> v1.2 upgrades but is not a permanent Play production identity.
- Scheduled recording/alarm remain policy-aware user-visible reminders rather than a false unattended-capture guarantee.

## GitHub release verification

- Commits pushed: `cd4c1d4` (functional reliability) and `9267e00` (release/evidence).
- Tag: `v1.2.0`, pointing to `9267e00e7b15156b6e97f35079dabc908f2b0f12`.
- Workflow run: `32677620256`, **passed** in 10 minutes 40 seconds.
- CI gates passed: signer restore, dependency resolution, formatting, analyzer, 59 tests, signed APK/AAB build, deterministic naming/checksums, workflow artifact upload, GitHub Release publication.
- Release: `Dhwani v1.2.0 - Reliable Radio`, published 2026-08-24T00:54:47Z.
- URL: `https://github.com/Mr-Dark-debug/dhwani/releases/tag/v1.2.0`.
- Published APK: 179,776,922 bytes; SHA-256 `69DEB4518E54754C0DA34F835348694949ACB7C6359CE2E55781F8942C4F0FAA`.
- Published AAB: 111,563,230 bytes; SHA-256 `68C4EAF12733CE942B85AE1F84953377E6B2C3D9235C5D7E2BEB88143E4176B4`.
- Published APK was downloaded again and independently inspected: package/version/build matched, APK Signature Scheme v2 verified, signer count was one, and certificate SHA-256 matched the expected v1.1 lineage.
- Post-release maintenance: GitHub's Node 20 deprecation annotations were removed from future workflow source by selecting checkout v6, setup-java v5, upload-artifact v6, and authenticated `gh release` commands. The immutable v1.2.0 tag was not moved.

## Post-release workflow runtime verification

Date: 2026-08-24 (Europe/Berlin)

- Commit under test: `ac07c82d29e423f99177e955e7f2b07f27cd0c4c`.
- Workflow run: `32678362229`, manual `workflow_dispatch` on `main`.
- Result: **passed** in 10 minutes 23 seconds.
- Verified gates: checkout v6, setup-java v5, protected signer restore, dependency resolution, formatting, analyzer, 59 tests, signed APK/AAB builds, deterministic naming/checksums, and upload-artifact v6.
- The GitHub Release publication step was correctly skipped because this was a branch validation rather than a version tag.
- URL: `https://github.com/Mr-Dark-debug/dhwani/actions/runs/32678362229`.

## v1.4.1 fresh-sideload playback verification

Date: 2026-08-27 (Europe/Berlin)

- Device: physical Pixel 10, serial `62131VDCR000KJ`, Android API 36.
- `flutter analyze`: **No issues found**.
- `flutter test --exclude-tags integration`: **65 passed, 0 failed**.
- Fresh-install live playback: Radio Swiss Jazz reached **PLAYING**, then **PAUSED**, and stopped on the physical device.
- Playback started with `POST_NOTIFICATIONS` denied; the player no longer waits for that permission.
- A transient `ConnectivityResult.none` no longer vetoes a working transport or stops healthy audio.
- Android uses native ExoPlayer request headers instead of just_audio's localhost header proxy.
- Darbhanga probe terminated cleanly after trying `radio.wavespb.com` first and legacy `air.pc.cdn.bitgravity.com` second. Neither broadcaster endpoint served audio from the German test network.

### v1.4.1 local release candidate

- Package: `com.prashant.dhwani`; version `1.4.1`; build `7`; min SDK 24; target/compile SDK 36.
- Release APK: `dist/release/Dhwani-v1.4.1-build7-android.apk`, 179,842,771 bytes.
- APK SHA-256: `793C9A0E57CD5429BB298D9ACC4934D7992AB8021E7F1005E0049E42D89C19E7`.
- Release AAB: `dist/release/Dhwani-v1.4.1-build7-android.aab`, 111,631,381 bytes.
- AAB SHA-256: `353A1ACBBF01A04888C019DFDD228FDBA26FB93123BD99B8E85D9458C37ABCA6`.
- APK Signature Scheme v2: valid; one signer; certificate SHA-256 `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5`.
- `zipalign -c -P 16 -v 4`: verification successful.
- Installed release verification: install succeeded; package reported version 1.4.1/build 7; `INTERNET` was granted and `POST_NOTIFICATIONS` remained denied; launch succeeded and the process exposed the expected media session.
- Genuine boundary: Darbhanga's current upstream is discoverable and attempted correctly, but audible playback cannot be certified from the German network because the broadcaster did not deliver audio there.

## 2026-08-28 — v1.4.3 update detection and Darbhanga resolver

### Static and deterministic verification

- `dart format .`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: 99 passed, 0 failed.
- Updater coverage: cold start, resume, separate timestamp writes, ten-minute failed retry, one-hour successful cooldown, manual bypass, concurrent deduplication, once-per-tag presentation, semantic/build ordering, prerelease rejection, 403, 429, and timeout safety.
- Darbhanga coverage: structured channel `69` discovery, fresh-first ordering, seven-day last-known-good, three-failure invalidation, forced refresh, WAVES redirect capture, rotating CDN, stale/404 source recovery, bounded redirect loop, HLS validation, off-air, timeout, DNS, TLS/reset, page outage, deduplication, and non-Darbhanga stream-order identity.

### Android real-network integration

- Device: Pixel 10-equivalent API 36 emulator, serial `emulator-5554`.
- Radio Swiss Jazz reached PLAYING and PAUSED.
- Deutschlandfunk reached PLAYING.
- Akashvani Live News 24x7 reached PLAYING and delivered HLS media.
- Next, Previous, Play/Pause, and Recents passed in one queue regression.
- Real FFmpeg recording produced validated original and converted audio and passed cleanup.
- Retro tuner and player controls remained covered by the passing widget regression suite.

### Darbhanga real-network boundary

- Test time: 04:33 IST, outside a confirmed active-broadcast window.
- Official WAVES request: connection reset on the German route.
- Legacy BitGravity request: HTTP 404.
- Old direct CloudFront candidate did not produce media within the bounded station deadline.
- Result: terminal `unavailable`/network failure, no crash, no infinite loader, and no false LIVE state.
- Actual Darbhanga audio and media segments were **not** observed; active-broadcast PLAYING is not claimed.

### Permissions and isolation

- Android manifest retains INTERNET, network-state, wake-lock, media foreground-service, notification, boot, and package-installer declarations.
- INTERNET and network-state are install-time normal permissions. Playback is not blocked on the notification runtime prompt; reminders request notification permission contextually, and the updater opens unknown-app-source settings only when installation requires it.
- No dependency, general player, recording, navigation, UI theme, retro tuner, other-country, or other-station routing change was made.

### Local release candidate

- APK: `build/app/outputs/flutter-apk/app-release.apk`, 180,006,611 bytes, SHA-256 `AD97652554762E2418F11D2E8B0F31567A7A124DAD181481B48F78B44FA24659`.
- AAB: `build/app/outputs/bundle/release/app-release.aab`, 111,674,382 bytes, SHA-256 `CB0600CD612E1A5AA8B5197EEB70FB70680299E3E2E73585749A382E433F0241`.
- APK package `com.prashant.dhwani`, version `1.4.3`, build `9`, min SDK 24, target/compile SDK 36.
- APK Signature Scheme v2 verified with the existing lineage SHA-256 `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5`.
- `adb install -r` passed; Android reported version `1.4.3` / build `9` after installation.
- The protected GitHub tag workflow remains the source of the published APK/AAB and final public checksums.
