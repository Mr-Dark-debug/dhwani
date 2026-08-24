# Changelog

All notable Dhwani changes are recorded here. Versions follow semantic versioning; Android build numbers remain strictly increasing.

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
