# Dhwani Playback and Darbhanga Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Dhwani 1.4.1+7 so a clean sideload starts radio playback without a permission or connectivity false-negative gate and Akashvani Darbhanga uses the current official stream with bounded fallbacks.

**Architecture:** Keep Android permissions declarative and contextual: install-time network permissions remain in the manifest, media playback never waits for notification permission, and reminders request notification permission when scheduled. Make the player transport authoritative, send headers through ExoPlayer rather than just_audio's localhost proxy, and merge the official Darbhanga URL ahead of feed and seed fallbacks.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Riverpod, just_audio/ExoPlayer, audio_service, Dio, Drift, Android API 24-36.

## Global Constraints

- Preserve application ID `com.prashant.dhwani` and the existing signing lineage.
- Android min SDK remains 24; compile and target SDK remain 36.
- Do not request microphone, location, contacts, or broad storage access.
- A failed or geo-blocked stream must terminate with a truthful state within the existing 24-second station budget.
- Publish APK, AAB, SHA-256 files, release notes, tag, and GitHub Release only after tests and physical-device verification pass.

---

### Task 1: Remove fresh-install playback gates

**Files:**
- Modify: `lib/app/providers.dart`
- Modify: `lib/core/audio/dhwani_audio_handler.dart`
- Test: `test/audio_handler_test.dart`
- Test: `integration_test/live_playback_smoke_test.dart`

**Interfaces:**
- Consumes: `NotificationService.requestPermission()`, `Connectivity.checkConnectivity()`.
- Produces: `playWithMediaNotification()` and `StationPlaybackController.tune()` that start audio without awaiting notification permission; connectivity `none` remains advisory unless Wi-Fi-only policy is enabled.

- [x] **Step 1: Change the live integration smoke test to call `StationPlaybackController.tune(..., autoplay: true)` on a clean install.**
- [x] **Step 2: Remove playback-time calls to `requestPermission()` while preserving reminder-time permission requests.**
- [x] **Step 3: Add unit coverage proving `ConnectivityResult.none` does not veto a working stream or interrupt healthy playback.**
- [x] **Step 4: Run `flutter test test/audio_handler_test.dart` and expect all state-machine cases to pass.**
- [ ] **Step 5: Commit the verified playback-gate changes with the release fixes.**

### Task 2: Use native Android stream requests

**Files:**
- Modify: `lib/core/audio/dhwani_audio_engine.dart`
- Modify: `lib/core/audio/dhwani_audio_handler.dart`
- Test: `test/audio_handler_test.dart`

**Interfaces:**
- Consumes: `AudioPlayer(useProxyForRequestHeaders:)` and `DhwaniAudioEngine.setUrl(String, {Map<String, String>? headers})`.
- Produces: ExoPlayer-native request headers, including Akashvani Origin and Referer headers for `wavespb.com`.

- [x] **Step 1: Add a failing fake-engine assertion for Akashvani request headers.**
- [x] **Step 2: Set `useProxyForRequestHeaders: false` in `JustAudioEngine`.**
- [x] **Step 3: Generate WAVES-specific Origin and Referer headers in `_streamHeadersFor()`.**
- [x] **Step 4: Run the handler tests and confirm header/fallback cases pass.**
- [ ] **Step 5: Commit the native-request change with Task 1.**

### Task 3: Repair Akashvani Darbhanga discovery

**Files:**
- Modify: `lib/data/datasources/akashvani_api.dart`
- Modify: `lib/data/repositories/catalogue_repository.dart`
- Test: `test/akashvani_api_test.dart`
- Create: `test/catalogue_repository_test.dart`
- Create: `integration_test/darbhanga_live_probe_test.dart`

**Interfaces:**
- Consumes: `AkashvaniApi.stations()` and `CatalogueRepository.bootstrap()`.
- Produces: `AkashvaniApi.currentDarbhangaStreamUrl`, JSON text/list parsing, live-page refresh with release fallback, and current-first stream merge order.

- [x] **Step 1: Reproduce Android's `FormatException` when the GitHub JSON feed arrives as `text/plain`.**
- [x] **Step 2: Decode a raw JSON string before validating the station list.**
- [x] **Step 3: Remove the blanket `wavespb.com` filter and put newer source URLs before cached/seed fallbacks.**
- [x] **Step 4: Add the current official Darbhanga URL as a fallback when live-page refresh fails.**
- [x] **Step 5: Run unit tests and the physical-device Darbhanga probe; expect the official host first and a bounded terminal result.**
- [ ] **Step 6: Commit the discovery repair with Tasks 1 and 2.**

### Task 4: Verify the release candidate

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`
- Modify: `research.md`
- Modify: `decision.md`
- Modify: `test_report.md`
- Modify: `known_issues.md`

**Interfaces:**
- Consumes: all fixed application code and tests.
- Produces: Dhwani `1.4.1+7` evidence and release documentation.

- [x] **Step 1: Set `version: 1.4.1+7` and document the fixes.**
- [x] **Step 2: Run `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test`; expect zero failures.**
- [x] **Step 3: Run the clean-install Radio Swiss Jazz integration smoke test; expect PLAYING then PAUSED without notification permission.**
- [x] **Step 4: Build `flutter build apk --release` and `flutter build appbundle --release`; expect signed artifacts.**
- [x] **Step 5: Install the release APK on device `62131VDCR000KJ`, verify version/permissions/signature, and rerun real playback.**

### Task 5: Publish Dhwani 1.4.1

**Files:**
- Modify: `dist/RELEASE_NOTES.md`
- Create: `dist/release/Dhwani-v1.4.1-build7-android.apk`
- Create: `dist/release/Dhwani-v1.4.1-build7-android.apk.sha256`
- Create: `dist/release/Dhwani-v1.4.1-build7-android.aab`
- Create: `dist/release/Dhwani-v1.4.1-build7-SHA256SUMS.txt`

**Interfaces:**
- Consumes: verified release APK/AAB and GitHub CLI authentication.
- Produces: commit, annotated `v1.4.1` tag, GitHub Actions verification, and public release assets.

- [x] **Step 1: Copy release outputs to deterministic versioned names and calculate SHA-256 checksums.**
- [ ] **Step 2: Commit all source, tests, plan, and evidence as `fix: make sideloaded playback reliable`.**
- [ ] **Step 3: Tag `v1.4.1` and push `main` plus the tag to `origin`.**
- [ ] **Step 4: Wait for the Release Android workflow and require a successful conclusion.**
- [ ] **Step 5: Inspect the public GitHub Release and verify the APK, checksum, AAB, and checksum manifest are downloadable.**
