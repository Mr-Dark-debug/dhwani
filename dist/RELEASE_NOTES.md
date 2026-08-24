# Dhwani v1.2.0 - Reliable Radio

This release rebuilds Dhwani's critical paths around finite, truthful operations. A station may work, fail, redirect, stall, disappear, or be geo-blocked; the app now either confirms real playback/recording or reaches a useful terminal state without leaving an endless spinner or false LIVE/REC label.

## What's fixed

- Rapid station changes cannot let an old request replace the newest selection.
- Recents/history begins only after confirmed playback and one listening session updates one row.
- Saved, Search, Discover, tuner, custom stations, notifications and Car Mode use the same authoritative switching path.
- Network, decoder and source errors are classified into short user-facing recovery states with sanitized diagnostics.

## Playback

- Endless live broadcasts are started without awaiting playback completion.
- Explicit switching, connecting, buffering, playing, paused, reconnecting, offline, unavailable, geo-blocked and unsupported states.
- Ten-second per-source and 24-second whole-station startup budgets with ranked fallback streams.
- Bounded 1/2/4-second runtime reconnects; selecting another station cancels pending recovery.
- Real Radio Swiss Jazz playback, pause, background continuation and media controls verified on Android 16/API 36.

## Recording

- REC appears only after FFmpeg is alive and real output bytes exist.
- Owned-process cancellation, startup timeout, unexpected-exit finalization, corrupt-file deletion and FFprobe-derived duration/format.
- Real HTTPS MP3 stream-copy and M4A conversion recordings verified for more than six seconds each.

## Discovery

- Country station results paginate beyond 500 and cache progressively.
- Mirror selection tracks recent health/latency, backs off failing hosts and remains bounded/cancellable.
- Stale directory rows expire without deleting favourites or custom stations.

## Updates

- Installed version/build/package metadata replaces hardcoded app identity.
- Stable-only automatic checks use a 12-hour cooldown; manual checks distinguish current, network/API failure and incompatible releases.
- Exact versioned APK selection, byte progress, cancellation, `.part` cleanup, SHA-256 verification, native APK package/version/signature inspection and atomic rename.
- Android UI says Installer opened rather than claiming installation succeeded.

## Stability

- 59 unit/widget tests pass.
- Android integration passes for onboarding, custom persistence, platform services, real live playback, real MP3/M4A recording, and controlled redirect/delay/404/stale-operation behavior.
- A v1.1.0 build 3 to v1.2.0 build 4 in-place upgrade was accepted and preserved install/app state on the emulator.

## Tested on

- Flutter 3.41.9 / Dart 3.11.5 / Java 21.0.11.
- Android 16/API 36 Pixel 10 approximation, 1280x2856 at 480 dpi.
- Physical Pixel 10 hardware was not connected; no physical-device claim is made.

## Known limitations

- Akashvani Darbhanga's current official stream was unavailable from the German test network; Dhwani preserves accurate 1296 kHz metadata and reports the upstream failure honestly.
- The compatibility release retains v1.1.0's protected legacy Android debug signer. It supports the tested in-place upgrade but is not a permanent Play signing identity.
- Scheduled recording/radio alarm are honest user-visible reminders under modern Android background policy, not guaranteed silent unattended capture.
- Full FFmpeg protocol/codec support makes universal APKs large; the AAB permits ABI-specific delivery.
