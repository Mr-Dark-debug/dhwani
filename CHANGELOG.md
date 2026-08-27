# Changelog

All notable Dhwani changes are recorded here. Versions follow semantic versioning; Android build numbers remain strictly increasing.

## [1.4.1] - 2026-08-27

### Fixed

- Fresh sideloads start playback immediately instead of waiting for an unnecessary notification permission result.
- Transient Android connectivity `none` reports no longer veto a real stream request or interrupt healthy audio.
- Stream headers are sent directly by Android ExoPlayer instead of routing every station through a localhost proxy.
- Akashvani's `text/plain` JSON feed is decoded correctly on Android.
- The current official Akashvani Darbhanga WAVES HLS URL is retained, sent with official-page request context, and ranked ahead of BitGravity fallbacks.
- A temporary failure to fetch Akashvani's live HTML page no longer removes the known-current Darbhanga source.

### Verification

- Physical Pixel 10 clean-install Radio Swiss Jazz playback reached PLAYING and paused with notification permission unset.
- Physical Pixel 10 Darbhanga probe attempted WAVES first and BitGravity second, then reported bounded unavailable on the German route where both upstreams remain unreachable.
- Distributed HTTP probes, including Kolkata, reached the current WAVES endpoint; actual audio availability remains controlled by Akashvani and the listener's network.

### Compatibility

- Version `1.4.1+7`, Android min SDK 24, compile/target SDK 36.
- Retains the existing protected Android signing lineage for in-place upgrades.

## [1.2.0] - 2026-08-24

### Added

- Generation-controlled playback transactions with newest-intent-wins cancellation.
- Explicit selected, switching, connecting, buffering, playing, paused, reconnecting, offline, unavailable, geo-blocked, unsupported and error states.
- Typed/sanitized playback failure diagnostics and local station reliability evidence.
- Recording startup byte handshake, FFmpeg process ownership, partial-capture recovery and FFprobe-derived metadata.
- Paginated Radio Browser country loading, progressive caching, mirror health ranking and stale directory pruning.
- Installed-version update checks, automatic cooldown, deterministic GitHub assets, progress/cancel/retry, SHA-256 and native APK identity/signature verification.
- Secret-backed GitHub Actions APK/AAB release pipeline and controlled broken-radio decoder integration test.

### Fixed

- Live radio no longer awaits an endless broadcast Future.
- Rapid station changes and reconnect timers cannot let stale stations overwrite the newest selection.
- Next/Previous, notifications, tuner, Saved, Search, Discover, custom stations and reminders share one station-switch controller.
- History starts only after confirmed playback and updates one durable session row.
- REC is never shown before media bytes exist; failed captures do not leave database rows or zero-byte files.
- Country lists are no longer silently capped at 500 stations.
- Manual updater checks distinguish current, skipped and failed states; installer launch is no longer described as installation success.

### Compatibility

- Version `1.2.0+4`, Android min SDK 24, compile/target SDK 36.
- Retains the published v1.1.0 signing lineage for verified in-place upgrades.
- Physical Pixel 10 validation remains external; Android 16/API 36 Pixel-class emulator validation is documented.

## [1.1.0] - 2026-08-17

- Added the in-app updater, radial sleep timer, glass bottom navigation and stream reliability improvements.

## [1.0.0-preview.1] - 2026-08-16

- First installable Dhwani preview with discovery, live playback, background controls, favourites, history, custom stations, recording/export and responsive Android UI.
