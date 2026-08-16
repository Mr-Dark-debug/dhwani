# Dhwani — Live Radio: implementation design

The user's 145-part master prompt is the approved product specification. This document fixes the implementation interpretation used for the build.

## Product shape

Dhwani is a local-first Flutter radio application. It opens cached content immediately, merges Akashvani and Radio Browser catalogues behind one repository, preserves terrestrial frequency only as metadata, and treats confirmed player state as the sole source of truth for `LIVE`.

The core flow is Country → State/region → City/area → Stations → Player. Radio, Discover, Saved, and Recordings remain reachable through adaptive bottom navigation. The player uses the supplied reference's white mobile surface, oversized frequency, moving scale, fixed red needle, and bold transport controls without reproducing its grey presentation canvas, premium promotion, or fake programme metadata.

## Architecture

Features own their UI and coordination. Core services own audio, recording, persistence, network behavior, file export, notifications, and logging. Typed repositories merge independent remote and local sources. Riverpod supplies observable state and dependency injection; GoRouter owns navigation; Drift stores structured user and cache data; SharedPreferences stores only small settings.

The audio handler is the single playback authority. It owns queue navigation, source failover, audio focus, media-session state, notification controls, ICY metadata, and truthful connection status. The recorder invokes the maintained LGPL audio-only FFmpegKit fork, stream-copies when possible, validates with FFprobe, and records only after the app can name a supported output container. Playback and recording use separate source connections when the broadcaster supports them; failure is explicit.

## Android policy

Android 16 / API 36 is the acceptance environment, with min SDK 24. Media playback uses a `mediaPlayback` foreground service and media session. Notifications are requested in context. Recordings stay in app-scoped storage until the user exports through the Storage Access Framework or shares them. No microphone, location, broad storage, advertising, analytics, login, or telemetry permissions are used.

Scheduled recording and radio alarms use exact-alarm-capable notifications as the reliable baseline. The app never promises unattended playback when Android policy or device power controls disallow it; the notification opens the prepared station/recording action. Manual recording, sleep timers, background playback, and media controls remain full features.

## Failure behavior

Every network operation has a deadline and bounded retry. Radio Browser mirrors fail over. Malformed catalogue entries are ignored individually. Playback tries health-ranked URLs, refreshes remote station metadata once, and presents retry/alternative/next actions. Offline mode uses cached catalogue and all local data; live controls explain that internet is required. Recording success requires a non-empty, FFprobe-recognized file and stored metadata.

## Verification

Pure logic receives unit tests; screens and state transitions receive widget tests; Android integration covers onboarding, player actions, persistence, and navigation. Real-network smoke tests prove catalogue and stream behavior. A Pixel 9 Pro AVD running Android 16 is the documented closest available Pixel 10 approximation unless a physical Pixel 10 connects. ADB evidence covers layout, media session, foreground notification, background/lock lifecycle, recording file validity, export UI, and screenshots in both themes.
