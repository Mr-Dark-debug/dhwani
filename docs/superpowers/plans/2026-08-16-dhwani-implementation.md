# Dhwani Implementation Plan

> **For agentic workers:** Execute inline in this session. Every task ends with tests and evidence updates.

**Goal:** Build and release a real, polished, local-first Flutter radio application that browses, plays, saves, records, exports, and manages live stations on modern Android.

**Architecture:** Feature-oriented Flutter UI over typed catalogue, persistence, playback, recording, platform, and settings services. Riverpod is the state boundary, GoRouter is navigation, Drift is structured storage, just_audio/audio_service/audio_session own media, and the LGPL FFmpeg audio bundle owns supported recording/remux validation.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Android API 36, Kotlin/Gradle, Riverpod 3, GoRouter 17, Dio 5, Drift 2, just_audio 0.10, audio_service 0.18, FFmpeg 8.1 audio bundle.

## Global Constraints

- Project files live directly in `D:\projects\radio`.
- Application ID is `com.prashant.dhwani`; product name is `Dhwani — Live Radio`.
- No fake frequencies, fake `LIVE`, microphone permission, GPS permission, broad storage permission, ads, accounts, analytics, or telemetry.
- Android 16 and Pixel-class edge-to-edge behavior are mandatory verification targets.
- `decision.md`, `research.md`, `test_report.md`, and `known_issues.md` remain append-only.

### Task 1: Foundation and identity

- [x] Audit the toolchains, root, Git state, reference asset, and Android images.
- [x] Initialize Flutter and Git directly in the root.
- [x] Generate and preserve logo source assets; configure icon and splash tooling.
- [ ] Install researched dependencies, configure Android API 36, and generate icons/splash.
- [ ] Run format, analysis, baseline tests, and commit.

### Task 2: Domain, persistence, and catalogue

- [ ] Define station, source, health, recording, settings, schedule, and queue models with exhaustive parsing tests.
- [ ] Build Drift tables and repositories for cache, favourites, history, custom stations, recordings, collections, health, and reports.
- [ ] Implement Radio Browser discovery/failover, Akashvani ingestion, curated Darbhanga metadata, cache refresh, and offline behavior.
- [ ] Implement hierarchy, search, sorting, tuner queue widening, source ranking, custom validation, and backup import/export with unit tests.

### Task 3: Playback and Android media

- [ ] Implement the central audio handler with HLS/direct-stream playback, redirects, metadata, errors, bounded reconnect, queue controls, volume, and source failover.
- [ ] Configure audio focus/noisy events and Android media playback service/notification permissions.
- [ ] Test state mapping and source failover, then prove a live public stream on Android.

### Task 4: Product UI

- [ ] Build the responsive light/dark design system and reusable shells, rows, empty/error states, artwork, and mini player.
- [ ] Build welcome, country, state, city, station list, search, discover, saved/history, custom station, recordings, settings, info, car mode, schedule/alarm, and backup flows.
- [ ] Build the reference-inspired player and semantic kinetic tuner with drag, inertia, snapping, haptics, scope widening, band filter, and immediate connection feedback.
- [ ] Add widget and integration tests for all critical flows.

### Task 5: Recording, export, and timers

- [ ] Implement supported live recording through FFmpeg stream copy, timer state, cancellation, FFprobe validation, and persistence.
- [ ] Implement recordings playback, rename, share, SAF export, delete, details, and storage accounting.
- [ ] Implement sleep timer, scheduled-recording preparation notifications, radio-alarm notifications, and honest platform limitations.
- [ ] Run a real ten-second Android recording/export/playback test.

### Task 6: Pixel and release verification

- [ ] Create and boot an Android 16 Pixel 9 Pro AVD as the closest installed Pixel 10 device profile.
- [ ] Run integration, responsive, theme, large-text, rotation, edge-to-edge, predictive-back, lifecycle, offline, retry, background audio, notification, media-session, and recording tests.
- [ ] Capture and inspect required screenshots; fix visual defects and repeat.
- [ ] Build debug/release APK and AAB, inspect native libraries for 16 KB readiness, install release, and verify icon/splash.
- [ ] Complete README/evidence/limitations, create meaningful commits, create the GitHub repository, push, and publish versioned release artifacts when authentication permits.
