# Dhwani Reliability Mission

## Primary goal

**Dhwani must never get stuck, lie about playback or recording state, or crash because a radio stream, network request, user interaction, database record, or update operation failed. Every operation must either succeed or terminate cleanly with useful UI feedback.**

## Measurable acceptance criteria

- Live playback start returns control immediately after a source is prepared; no UI or navigation path awaits an endless broadcast.
- Playback is a deterministic, generation-controlled state machine: the newest tune request wins and stale asynchronous work cannot change station, UI, history, or notification state.
- Per-source and whole-station startup are bounded; a dead station reaches a classified unavailable state within 24 seconds rather than spinning forever.
- Runtime decoder, HLS, transport, network-loss, unexpected-end, and reconnect failures are observed, classified, logged safely, and surfaced with short recovery actions.
- Next, Previous, Retry, Play, and Pause remain responsive under rapid repeated input; their visible state matches the active player operation.
- Recents, favourites, collections, search, tuner, restored station, custom stations, notifications, and reminders all route selection through one authoritative controller.
- Listening history is created only for confirmed playback and one listening session is counted once with measured duration.
- Recording shows REC only after FFmpeg stays alive and output bytes arrive; it records the active resolved stream, finalizes or deletes partial output safely, and never inserts corrupt/zero-byte files.
- Deterministic tests cover delayed, redirected, denied, missing, stalled, dropped, malformed, and successful stream/update operations; real MP3 and HLS/AAC smoke tests remain separate.
- Radio Browser country loading paginates beyond 500 stations, deduplicates results, remains lazy/responsive, caches safely, and expires obsolete non-user catalogue data without deleting user-owned records.
- Update checks use installed version/build metadata, distinguish no-update from failure, select deterministic release assets, download with progress/cancel/retry, verify SHA-256 and APK identity/version before opening the installer.
- Android signing compatibility is measured and documented; secrets remain outside Git. An old-to-new upgrade preserves favourites, custom stations, history, collections, recordings, and settings when certificate/version constraints permit.
- Pixel-class, compact-phone, tablet API 36 and Windows verification finish without reproducible crashes, analyzer errors, test failures, infinite spinners, fake LIVE, or fake REC.
- A 100-transition Android stress run has no fatal exception, uncaught Dart error, ANR, database corruption, foreground-service failure, or stale final station.
- Versioned APK/AAB artifacts, SHA-256 checksums, release notes, commits, tag, and GitHub Release are reproducible and published when authentication permits.
- `decision.md`, `research.md`, `test_report.md`, `known_issues.md`, `CHANGELOG.md`, and the release notes reflect failures, fixes, evidence, signing state, and genuine external limitations truthfully.
