# Dhwani Known Issues

Only verified unresolved limitations belong here. Resolved entries remain and are marked `RESOLVED`.

## 2026-08-17 — Android cold start stayed on native splash

Status: **RESOLVED**

Awaiting reminder plug-in initialization before `runApp` could stall a real cold install. Initialization is now idempotent and non-blocking for the first frame; reminder operations await the same future.

## 2026-08-17 — Landscape welcome overflowed by 36 pixels

Status: **RESOLVED**

The welcome screen now uses a scroll-safe two-column landscape composition. Re-inspected on the API 36 emulator with no overflow.

## 2026-08-17 — Akashvani Darbhanga upstream unavailable from Germany

Status: Open (upstream/network)

The current URL discovered from the official Akashvani live page reset TLS from the German test network. The older BitGravity discovery URL returned HTTP 404. Dhwani preserves the verified 1296 kHz metadata, performs bounded failover, and reports unavailable rather than false LIVE. Playback was independently verified with Radio Swiss Jazz.

## 2026-08-17 — Physical Pixel 10 not connected

Status: Open (test equipment)

Acceptance testing used `Dhwani_Pixel_10_Approx`, a Google Pixel-class Android 16/API 36 x86_64 AVD at 1280×2856 and 480 dpi. A physical Pixel 10 remains desirable for speaker audibility, Bluetooth hardware, OEM battery policy, launcher monochrome icon, and final lock-screen QA.

## 2026-08-17 — Scheduled capture requires a prepared user action

Status: Open (platform policy)

This release schedules visible one-time and selected-weekday alarm/recording reminders using inexact-while-idle delivery. Modern Android can block arbitrary unattended foreground-service starts, so Dhwani does not promise silent background playback or recording. Guaranteed unattended capture is not claimed.

## 2026-08-17 — Release signing key unavailable

Status: Open (owner secret required)

Release APK/AAB compilation succeeds, but local release outputs use the Android debug certificate. A private upload/release keystore and protected credentials are required before store publication; they must not be generated as an unprotected repository secret or committed.

## 2026-08-17 — Automated environment cannot hear emulator speakers

Status: Open (test equipment)

Playback evidence includes network bytes, buffered audio, ICY metadata, active AudioTrack/media session, background continuation, and notification state transitions. Final subjective audibility should be confirmed on the physical phone.

## 2026-08-17 — Audio-only FFmpeg binary lacked HTTPS

Status: **RESOLVED**

Fresh API 36 integration testing found that the selected audio-only FFmpeg native binary returned `https protocol not found`. Dhwani now uses the non-GPL full 2.5.2 variant with TLS and audio libraries. Real HTTPS MP3 stream-copy and M4A conversion recordings both passed with FFprobe validation; temporary test recordings were deleted.

## 2026-08-24 — Legacy signer is protected but not a production identity

Status: Open (release lineage)

The matching v1.1.0 signer is now stored only in encrypted GitHub repository secrets and the v1.2.0 upgrade path is verified. Its certificate is still `CN=Android Debug`, so it is not a suitable permanent Play signing identity. Moving to a dedicated production key will require a documented one-time reinstall unless a store-managed signing migration is available. No keystore or password is committed.

## 2026-08-24 — Six-second source timeout rejected a healthy live stream

Status: **RESOLVED**

The first combined integration run cancelled Radio Swiss Jazz while ExoPlayer was still initializing. Per-source startup is now bounded at 10 seconds with a 24-second whole-station budget. The real Android smoke retest reached PLAYING in 15 seconds including app/test startup and then paused cleanly.
